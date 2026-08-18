#!/usr/bin/env bash
# ai 컨테이너에 ComfyUI 를 systemd 서비스로 배포한다 (계획 §1-2)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# 설치는 build.sh 가 먼저 한다. API 키는 이 스크립트가 만들지 않는다 —
# ai 의 /etc/comfyui.env (root 600) 를 사람이 채운다. env.example 참조 (원칙 5).

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="ai"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# ── 전제 확인 ───────────────────────────────────────────────────────

incus exec "$CONTAINER" -- test -x /opt/comfyui/venv/bin/python \
  || die "ComfyUI not built. Run build.sh first."
incus exec "$CONTAINER" -- test -f /opt/comfyui/main.py \
  || die "ComfyUI source missing. Run build.sh first."
incus exec "$CONTAINER" -- test -s /etc/comfyui.env \
  || die "/etc/comfyui.env missing in ${CONTAINER}. See env.example."

log "Prerequisites OK"

# ── 유닛 배포 ───────────────────────────────────────────────────────

log "Deploying systemd unit"
incus exec "$CONTAINER" -- mkdir -p /mnt/data/comfyui/output
incus file push "${SCRIPT_DIR}/comfyui.service" "${CONTAINER}/etc/systemd/system/comfyui.service"

# 기본 워크플로 (웹 UI 사이드바의 Workflows 에 나타난다) — t2i·t2v 정본
incus exec "$CONTAINER" -- mkdir -p /opt/comfyui/user/default/workflows
for wf in "${SCRIPT_DIR}"/workflows/*.json; do
  incus file push "$wf" "${CONTAINER}/opt/comfyui/user/default/workflows/$(basename "$wf")"
done
log "Default workflows deployed (t2i-seedream, t2v-seedance)"
incus exec "$CONTAINER" -- systemctl daemon-reload
incus exec "$CONTAINER" -- systemctl restart comfyui
incus exec "$CONTAINER" -- systemctl enable comfyui >/dev/null 2>&1

# ── 기동 대기 ───────────────────────────────────────────────────────

log "Waiting for /system_stats on :8188"
for _ in $(seq 1 24); do
  if incus exec "$CONTAINER" -- curl -fso /dev/null http://10.10.10.14:8188/system_stats; then
    HTTP_OK=1
    break
  fi
  sleep 5
done
[ -n "${HTTP_OK:-}" ] || die "ComfyUI did not come up. Check: incus exec ${CONTAINER} -- journalctl -u comfyui"

echo
log "Done."
echo "  Web UI : https://gem12.tail4555a7.ts.net:8188  (tailscale-serve/deploy.sh 재실행 필요)"
echo
echo "  §1-2 검증: 웹 UI 에서 OpenRouter 노드 워크플로로 이미지 1장 생성"
echo "  (모델 google/gemini-2.5-flash-image 계열, 프롬프트는 \"Generate an image of ...\" 로 시작)"
