#!/usr/bin/env bash
# ai 컨테이너에 Glimmer llama.cpp 서버를 systemd 서비스로 배포한다
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# 모델 가중치는 이 스크립트가 받지 않는다. 17GB 라 회선을 오래 점유하므로
# 시점과 속도 제한을 사람이 정한다 — download.sh 를 따로 실행한다.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="ai"
MODEL="/mnt/data/models/Muse-Glimmer-30B-KQuant-17GB-Q4_K_M.gguf"
DRAFT="/mnt/data/models/dflash-Muse-Glimmer-30B-Q4_K_M.gguf"
BIN="/opt/llama.cpp/build/bin/llama-server"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# ── 전제 확인 ───────────────────────────────────────────────────────

incus exec "$CONTAINER" -- test -x "$BIN" \
  || die "llama-server not built. See build.sh"
incus exec "$CONTAINER" -- test -s "$MODEL" \
  || die "Model missing: ${MODEL}. Run download.sh first."
incus exec "$CONTAINER" -- test -s "$DRAFT" \
  || die "Draft model missing: ${DRAFT}. Run download.sh first."

log "Prerequisites OK"

# ── 유닛 배포 ───────────────────────────────────────────────────────

log "Deploying systemd unit"
incus file push "${SCRIPT_DIR}/glimmer.service" \
  "${CONTAINER}/etc/systemd/system/glimmer.service"
incus exec "$CONTAINER" -- systemctl daemon-reload

# 수동 실행 중인 프로세스가 있으면 포트가 겹친다.
if incus exec "$CONTAINER" -- pgrep -f "llama-server" >/dev/null 2>&1; then
  if incus exec "$CONTAINER" -- systemctl is-active --quiet glimmer; then
    log "Restarting glimmer.service"
    incus exec "$CONTAINER" -- systemctl restart glimmer
  else
    warn "A manually started llama-server is running. Stopping it."
    incus exec "$CONTAINER" -- pkill -f "llama-server" || true
    sleep 3
    incus exec "$CONTAINER" -- systemctl start glimmer
  fi
else
  incus exec "$CONTAINER" -- systemctl start glimmer
fi

incus exec "$CONTAINER" -- systemctl enable glimmer >/dev/null 2>&1

# ── 기동 대기 ───────────────────────────────────────────────────────
# 17GB 를 VRAM 에 올리므로 시간이 걸린다.

log "Waiting for the model to load (up to 5 minutes)"
for _ in $(seq 1 60); do
  if incus exec "$CONTAINER" -- curl -fso /dev/null http://10.10.10.14:8081/v1/models; then
    READY=1
    break
  fi
  sleep 5
done
[ -n "${READY:-}" ] \
  && log "Glimmer is up" \
  || die "Glimmer did not come up. Check: incus exec ${CONTAINER} -- journalctl -u glimmer"

# ── 결과 ────────────────────────────────────────────────────────────

echo
incus exec "$CONTAINER" -- systemctl is-enabled glimmer | sed 's/^/  boot: /'
incus exec "$CONTAINER" -- sh -c \
  "awk '{printf \"  VRAM: %.0f MiB used\n\", \$1/1024/1024}' /sys/class/drm/card1/device/mem_info_vram_used"

echo
log "Done."
echo "  API: http://10.10.10.14:8081/v1  (ci container and Tailscale clients)"
