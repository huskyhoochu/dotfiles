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
# 모든 점검을 통과하면 Kuma push 모니터에 up 을, 하나라도 걸리면 실패 목록과
# 함께 down 을 보낸다. 스크립트 자체가 죽으면 하트비트가 끊겨 Kuma 가 down 으로
# 처리한다 (dead-man switch). 호스트 전체가 죽는 경우는 §7 장애 대비대로
# 원격 감지를 포기한다 — Kuma 도 같은 호스트에 있다.
#
# 온도 센서는 hwmon 인덱스가 부팅마다 바뀔 수 있어 칩 이름 + 라벨로 찾는다.
# amdgpu 가 2개(7900 XTX, 780M)인데 junction/mem 라벨은 XTX 만 내주므로
# 라벨 매칭이 dGPU 를 고른다.
#
# §1-3 목록 중 "GitHub 미러 push 실패"는 Forgejo API 토큰이 필요해 아직 없다 —
# 계획 문서의 남은 항목 참조.

set -euo pipefail

ENV_FILE=/etc/gem12-healthcheck.env

# 임계값 (계획 §1-3)
DISK_MAX=85           # %
MEM_MAX=90            # %
CPU_MAX=95            # °C — k10temp Tctl
GPU_JUNCTION_MAX=105  # °C — 7900 XTX 스로틀 한계 110°C
GPU_VRAM_MAX=100      # °C
NVME_MAX=70           # °C — Composite
NVME_DEV=/dev/nvme0n1

FAILS=()
fail() { FAILS+=("$1"); }

# ── 디스크 / RAM ────────────────────────────────────────────────────

usage=$(df --output=pcent / | tail -1 | tr -dc '0-9')
[ "$usage" -le "$DISK_MAX" ] || fail "disk:${usage}%"

read -r mem_total mem_avail < <(awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print t, a}' /proc/meminfo)
mem_pct=$(((mem_total - mem_avail) * 100 / mem_total))
[ "$mem_pct" -le "$MEM_MAX" ] || fail "ram:${mem_pct}%"

# ── btrfs 체크섬 / NVMe SMART ───────────────────────────────────────
# --check 는 오류 카운터가 하나라도 0 이 아니면 비0 으로 끝난다.
# 디스크가 1개라 자동 복구가 없으므로 즉시 알아야 한다 (§1-3).

btrfs device stats --check / >/dev/null 2>&1 || fail "btrfs-errors"
smartctl -H "$NVME_DEV" 2>/dev/null | grep -q PASSED || fail "smart"

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

# temp_check <표시 이름> <칩> <라벨> <임계값 °C>
temp_check() {
  local val
  if val=$(hwmon_temp "$2" "$3"); then
    [ $((val / 1000)) -le "$4" ] || fail "$1:$((val / 1000))C"
  else
    fail "$1:sensor-missing"
  fi
}

temp_check cpu k10temp Tctl "$CPU_MAX"
temp_check gpu-junction amdgpu junction "$GPU_JUNCTION_MAX"
temp_check gpu-vram amdgpu mem "$GPU_VRAM_MAX"
temp_check nvme-temp nvme Composite "$NVME_MAX"

# ── 네트워크 / 서비스 ───────────────────────────────────────────────

# Wi-Fi 가 끊기면 기본 라우트가 사라진다. Kuma 는 incusbr0 로 닿으므로
# 오프라인이어도 이 결과는 기록된다 — 알림은 회복 후에 나간다.
[ -n "$(ip route show default)" ] || fail "no-default-route"

curl -fsm 5 http://10.10.10.11:3000/api/healthz >/dev/null || fail "forgejo"

incus exec apps -- systemctl is-active --quiet litestream 2>/dev/null || fail "litestream"

# rclone→Drive 실패는 backup.service 의 마지막 실행 결과로 잡는다.
[ "$(systemctl show backup.service -P Result)" = "success" ] || fail "backup-result"
systemctl is-active --quiet backup.timer || fail "backup-timer"

# ── Kuma push ───────────────────────────────────────────────────────

if [ ${#FAILS[@]} -eq 0 ]; then
  status=up msg=OK
else
  status=down msg="${FAILS[*]}"
fi

# shellcheck source=/dev/null
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

if [ -n "${KUMA_PUSH_URL:-}" ]; then
  curl -fsSm 10 --get "$KUMA_PUSH_URL" \
    --data-urlencode "status=${status}" \
    --data-urlencode "msg=${msg}" >/dev/null
else
  echo "KUMA_PUSH_URL not set in ${ENV_FILE} — log only" >&2
fi

# down 이면 유닛도 실패로 남겨 journal/systemctl 에서 보이게 한다.
if [ "$status" = down ]; then
  echo "DOWN: ${msg}" >&2
  exit 1
fi
echo "OK"
