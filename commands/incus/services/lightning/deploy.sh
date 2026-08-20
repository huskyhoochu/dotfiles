#!/usr/bin/env bash
# ai 컨테이너에 Nemotron 3.5 Lightning llama.cpp 서버를 systemd 서비스로 배포한다
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# Glimmer 와 상호 배타(Conflicts=)라, 이 서비스를 켜면 glimmer.service 가
# 내려간다. 전환:  systemctl start lightning  /  systemctl start glimmer
#
# 모델 가중치는 이 스크립트가 받지 않는다 — download.sh 를 따로 실행한다.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="ai"
MODEL="/mnt/data/models/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-Q4_0.gguf"
BIN="/opt/llama.cpp/build/bin/llama-server"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# ── 전제 확인 ───────────────────────────────────────────────────────

incus exec "$CONTAINER" -- test -x "$BIN" \
  || die "llama-server not built. See ../glimmer/build.sh"
incus exec "$CONTAINER" -- test -s "$MODEL" \
  || die "Model missing: ${MODEL}. Run download.sh first."

log "Prerequisites OK"

# ── 유닛 배포 ───────────────────────────────────────────────────────

log "Deploying systemd unit"
incus file push "${SCRIPT_DIR}/lightning.service" \
  "${CONTAINER}/etc/systemd/system/lightning.service"
incus exec "$CONTAINER" -- systemctl daemon-reload

# Conflicts=glimmer.service 라 start 가 glimmer 를 내린다 — 의도된 동작
log "Starting lightning.service (glimmer 가 켜져 있으면 내려간다)"
incus exec "$CONTAINER" -- systemctl restart lightning

# 부팅 기본은 여전히 glimmer 다. lightning 은 수동 전환 전용이므로 enable 하지 않는다.

# ── 기동 대기 ───────────────────────────────────────────────────────

log "Waiting for the model to load (up to 5 minutes)"
for _ in $(seq 1 60); do
  if incus exec "$CONTAINER" -- curl -fso /dev/null http://10.10.10.14:8082/v1/models; then
    READY=1
    break
  fi
  sleep 5
done
[ -n "${READY:-}" ] \
  && log "Lightning is up" \
  || die "Lightning did not come up. Check: incus exec ${CONTAINER} -- journalctl -u lightning"

# ── 결과 ────────────────────────────────────────────────────────────

echo
incus exec "$CONTAINER" -- sh -c \
  "awk '{printf \"  VRAM: %.0f MiB used\n\", \$1/1024/1024}' /sys/class/drm/card1/device/mem_info_vram_used"

echo
log "Done."
echo "  API: http://10.10.10.14:8082/v1"
echo "  Glimmer 복귀: incus exec ${CONTAINER} -- systemctl start glimmer"
