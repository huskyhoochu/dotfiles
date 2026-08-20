#!/usr/bin/env bash
# 호스트 상태 점검 → Uptime Kuma push (계획 §1-3 의 최소 알림 목록)
#
# 호스트에서 root 로 실행한다. healthcheck.timer 가 5분마다 부른다. 수동 실행도 안전하다.
#   sudo ./healthcheck.sh
#
# deploy.sh 가 /usr/local/sbin/gem12-healthcheck 로 복사해 설치한다 — /root 아래는
# SELinux(admin_home_t)가 systemd 의 실행을 막는다(실측). 그래서 이 파일은
# lib.sh 를 source 하지 않고 자립한다.
#
# 점검을 7개 그룹(host·backup·core·apps·ci·ai·media)으로 나눠 각각 별도의 Kuma
# push 모니터에 신고한다. 그룹이 통과하면 up 을, 걸리면 실패 목록과 함께 down 을
# 보낸다. 매 실행마다 **7개 전부**에 신고한다 — 실패한 그룹만 보내면 나머지는
# 하트비트가 끊겨 오탐이 되기 때문이다. 스크립트 자체가 죽으면 7개가 동시에
# 하트비트를 잃어 Kuma 가 down 으로 처리한다 (dead-man switch).
#
# 나누는 이유는 실측이다 (2026-08-20): 단일 모니터 + 집계 status 구조에서는
# 이미 down 인 상태에 새 장애가 겹쳐도 status 가 그대로라 Kuma 가 상태 변화로
# 보지 않는다. 08-19 17:13 의 restic 락으로 down 인 동안 dGPU 가 죽었는데
# 이력에 아무 흔적이 남지 않았다 — 먼저 난 장애가 뒤에 난 장애를 가렸다.
#
# 호스트 전체가 죽는 경우는 §7 장애 대비대로 원격 감지를 포기한다 — Kuma 도
# 같은 호스트에 있다.
#
# 온도 센서는 hwmon 인덱스가 부팅마다 바뀔 수 있어 칩 이름 + 라벨로 찾는다.
# amdgpu 가 2개(7900 XTX, 780M)인데 junction/mem 라벨은 XTX 만 내주므로
# 라벨 매칭이 dGPU 를 고른다.

set -euo pipefail

ENV_FILE=/etc/gem12-healthcheck.env
# shellcheck source=/dev/null
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

# 임계값 (계획 §1-3)
DISK_MAX=85           # %
MEM_MAX=90            # %
CPU_MAX=95            # °C — k10temp Tctl
GPU_JUNCTION_MAX=105  # °C — 7900 XTX 스로틀 한계 110°C
GPU_VRAM_MAX=100      # °C
NVME_MAX=70           # °C — Composite
NVME_DEV=/dev/nvme0n1

# 그룹별 실패 목록. fail <그룹> <이름> 으로 쌓는다.
# 이름을 CHECK_GROUPS 로 두는 이유: GROUPS 는 bash 특수 변수(현재 사용자의 GID
# 배열)라 대입해도 셸이 덮어쓴다. 실측 2026-08-20 — 첫 배포에서 그룹 대신
# GID 3개(1000 985 10)를 돌았다.
CHECK_GROUPS=(host backup core apps ci ai media)
declare -A FAILS=()
fail() { FAILS[$1]+="${FAILS[$1]:+ }$2"; }

# 컨테이너 RUNNING 여부를 그룹별로 나눠 담기 위해 한 번만 조회한다.
declare -A CT_STATE=()
while IFS=, read -r name state; do
  CT_STATE[$name]="$state"
done < <(incus list -c ns -f csv)

# ct_check <컨테이너> — RUNNING 이 아니면 같은 이름의 그룹에 실패를 적는다.
ct_check() {
  [ "${CT_STATE[$1]:-missing}" = RUNNING ] || fail "$1" "container:${CT_STATE[$1]:-missing}"
}

# ── 디스크 / RAM ────────────────────────────────────────────────────

usage=$(df --output=pcent / | tail -1 | tr -dc '0-9')
[ "$usage" -le "$DISK_MAX" ] || fail host "disk:${usage}%"

read -r mem_total mem_avail < <(awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print t, a}' /proc/meminfo)
mem_pct=$(((mem_total - mem_avail) * 100 / mem_total))
[ "$mem_pct" -le "$MEM_MAX" ] || fail host "ram:${mem_pct}%"

# ── btrfs 체크섬 / NVMe SMART ───────────────────────────────────────
# --check 는 오류 카운터가 하나라도 0 이 아니면 비0 으로 끝난다.
# 디스크가 1개라 자동 복구가 없으므로 즉시 알아야 한다 (§1-3).

btrfs device stats --check / >/dev/null 2>&1 || fail host "btrfs-errors"
smartctl -H "$NVME_DEV" 2>/dev/null | grep -q PASSED || fail host "smart"

# ── 온도 (hwmon) ────────────────────────────────────────────────────

# hwmon_temp <칩 이름> <라벨> → 밀리도 출력. 못 찾으면 비0.
hwmon_temp() {
  local chip="$1" label="$2" h l
  for h in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$h/name" 2>/dev/null)" = "$chip" ] || continue
    for l in "$h"/temp*_label; do
      [ -f "$l" ] || continue
      if [ "$(cat "$l")" = "$label" ]; then
        cat "${l%_label}_input"
        return 0
      fi
    done
  done
  return 1
}

# temp_check <표시 이름> <칩> <라벨> <임계값 °C> — 전부 host 그룹이다.
temp_check() {
  local val
  if val=$(hwmon_temp "$2" "$3"); then
    [ $((val / 1000)) -le "$4" ] || fail host "$1:$((val / 1000))C"
  else
    fail host "$1:sensor-missing"
  fi
}

temp_check cpu k10temp Tctl "$CPU_MAX"
temp_check gpu-junction amdgpu junction "$GPU_JUNCTION_MAX"
temp_check gpu-vram amdgpu mem "$GPU_VRAM_MAX"
temp_check nvme-temp nvme Composite "$NVME_MAX"

# ── 네트워크 / 서비스 ───────────────────────────────────────────────

# Wi-Fi 가 끊기면 기본 라우트가 사라진다. Kuma 는 incusbr0 로 닿으므로
# 오프라인이어도 이 결과는 기록된다 — 알림은 회복 후에 나간다.
[ -n "$(ip route show default)" ] || fail host "no-default-route"

curl -fsm 5 http://10.10.10.11:3000/api/healthz >/dev/null || fail core "forgejo"

# litestream 은 2026-08-20 호스트로 옮겼다 — 컨테이너 안에서는 다른 컨테이너의
# DB 에 닿을 수 없어 9개 중 2개만 복제되고 있었다(gitea.db 누락).
systemctl is-active --quiet litestream || fail host "litestream"

# 서비스가 살아 있어도 복제가 멈출 수 있다. 최근 sync 로그가 없으면 실패로 본다
# — 백업에서 배운 것과 같다: "돌고 있다"와 "일하고 있다"는 다르다.
[ "$(journalctl -u litestream --since '2 minutes ago' -o cat 2>/dev/null \
  | grep -c 'replica sync')" -gt 0 ] || fail host "litestream-idle"

# rclone→Drive 실패는 backup.service 의 마지막 실행 결과로 잡는다.
[ "$(systemctl show backup.service -P Result)" = "success" ] || fail backup "backup-result"
systemctl is-active --quiet backup.timer || fail backup "backup-timer"

# ── 컨테이너·서비스 전수 ────────────────────────────────────────────
# 컨테이너 상태는 같은 이름의 그룹으로 들어간다 — core 가 멈추면 gem12-core 만
# 빨갛고 나머지 그룹은 자기 판정을 그대로 유지한다.

for ct in core apps ci ai media; do ct_check "$ct"; done

# ai 의 llama.cpp 는 glimmer(:8081)·lightning(:8082)이 GPU 를 두고 교대한다
# (agent-run.sh 가 전환) — 어느 쪽이든 하나 살아 있으면 추론 계층은 정상이다.
curl -fsm 5 http://10.10.10.14:8081/health >/dev/null \
  || curl -fsm 5 http://10.10.10.14:8082/health >/dev/null \
  || fail ai "llm"
curl -fsm 5 -o /dev/null http://10.10.10.13:5678/ || fail apps "n8n"
curl -fsm 5 http://10.10.10.13:8080/api/v1/health >/dev/null || fail apps "nocodb"
incus exec ci -- systemctl is-active --quiet forgejo-runner 2>/dev/null || fail ci "runner"
curl -fsm 5 http://10.10.10.15:2283/api/server/ping >/dev/null || fail media "immich"
curl -fsm 5 http://10.10.10.15:8096/health >/dev/null || fail media "jellyfin"
curl -fsm 5 http://10.10.10.14:8188/system_stats >/dev/null || fail ai "comfyui"

# ── GitHub 미러 push ────────────────────────────────────────────────
# push mirror 의 last_error 를 Forgejo API 로 본다. FORGEJO_TOKEN 은
# read:repository 스코프 — deploy.sh 가 발급·기입하고, 잃으면 core 에서 재발급:
#   podman exec --user git forgejo forgejo admin user generate-access-token \
#     --username b95labs --token-name gem12-healthcheck --scopes read:repository

if [ -n "${FORGEJO_TOKEN:-}" ]; then
  if mirror_errs=$(FORGEJO_TOKEN="$FORGEJO_TOKEN" python3 - <<'PY'
import json, os, urllib.request
base = "http://10.10.10.11:3000/api/v1"
tok = os.environ["FORGEJO_TOKEN"]
def get(path):
    req = urllib.request.Request(base + path, headers={"Authorization": "token " + tok})
    with urllib.request.urlopen(req, timeout=5) as r:
        return json.load(r)
bad = []
for repo in get("/repos/search?limit=50")["data"]:
    full = repo["full_name"]
    for m in get("/repos/%s/push_mirrors" % full):
        if m.get("last_error"):
            bad.append(full)
print(",".join(sorted(set(bad))))
PY
  ); then
    [ -z "$mirror_errs" ] || fail backup "mirror:${mirror_errs}"
  else
    fail backup "mirror-api"
  fi
else
  fail backup "mirror-token-missing"
fi

# ── Kuma push ───────────────────────────────────────────────────────
# 그룹마다 KUMA_PUSH_URL_<그룹> 을 ENV_FILE 에서 읽어 신고한다. 실패한 그룹만
# 보내면 나머지가 하트비트를 잃어 오탐이 되므로 매번 7개 전부 보낸다.
#
# curl 실패가 스크립트를 세우면 뒤 그룹이 신고를 못 하므로 개별로 흡수한다.
# URL 이 없는 그룹은 로그만 남긴다 — 모니터를 아직 안 만든 동안에도 나머지는 돈다.

overall=0
for g in "${CHECK_GROUPS[@]}"; do
  if [ -z "${FAILS[$g]:-}" ]; then
    status=up msg=OK
  else
    status=down msg="${FAILS[$g]}"
    overall=1
    echo "DOWN[${g}]: ${msg}" >&2
  fi

  url_var="KUMA_PUSH_URL_${g^^}"
  url="${!url_var:-}"
  if [ -z "$url" ]; then
    echo "${url_var} not set in ${ENV_FILE} — ${g}=${status} (${msg}) log only" >&2
    continue
  fi

  curl -fsSm 10 --get "$url" \
    --data-urlencode "status=${status}" \
    --data-urlencode "msg=${msg}" >/dev/null \
    || echo "push failed: ${g}" >&2
done

# 하나라도 down 이면 유닛도 실패로 남겨 journal/systemctl 에서 보이게 한다.
[ "$overall" -eq 0 ] || exit 1
echo "OK"
