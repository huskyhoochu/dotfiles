#!/usr/bin/env bash
# media 컨테이너에 Jellyfin 을 Quadlet 서비스로 배포한다 (계획 §1-2)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# 전제 단계로 mesa-va-drivers-freeworld 를 설치한다. Fedora 기본 mesa 는 특허
# 문제로 H.264/HEVC VAAPI 코덱이 빠져 있어(실측: JPEG/VP9/AV1 만) RPM Fusion
# 리빌드가 필수다. 04-runtime.sh 의 swap 은 리빌드 지연 시 warn 으로 넘어가는
# 구조라, 여기서 보장한다 — vainfo 에 H264/HEVC 가 없으면 배포를 멈춘다.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="media"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# ── 전제: freeworld VAAPI 드라이버 ──────────────────────────────────

if incus exec "$CONTAINER" -- rpm -q mesa-va-drivers-freeworld >/dev/null 2>&1; then
  skip "mesa-va-drivers-freeworld already installed"
elif incus exec "$CONTAINER" -- rpm -q mesa-va-drivers >/dev/null 2>&1; then
  log "Swapping mesa-va-drivers → freeworld"
  incus exec "$CONTAINER" -- dnf swap -y -q mesa-va-drivers mesa-va-drivers-freeworld \
    || die "freeworld swap failed — RPM Fusion rebuild lag. See 04-runtime.sh comments."
else
  log "Installing mesa-va-drivers-freeworld"
  incus exec "$CONTAINER" -- dnf install -y -q mesa-va-drivers-freeworld \
    || die "freeworld install failed — RPM Fusion rebuild lag. See 04-runtime.sh comments."
fi

# H.264/HEVC 프로파일 등장이 §1-2 체크박스의 완료 판정이다.
incus exec "$CONTAINER" -- bash -c 'vainfo 2>/dev/null | grep -qE "H264|HEVC"' \
  || die "vainfo has no H264/HEVC profiles — freeworld driver is not effective."
log "VAAPI H.264/HEVC profiles present"

# ── Quadlet 배포 ────────────────────────────────────────────────────

log "Deploying quadlet unit"
incus exec "$CONTAINER" -- mkdir -p \
  /mnt/data/jellyfin/config /mnt/data/jellyfin/cache /mnt/data/jellyfin/media \
  /etc/containers/systemd
incus file push "${SCRIPT_DIR}/jellyfin.container" "${CONTAINER}/etc/containers/systemd/jellyfin.container"
incus exec "$CONTAINER" -- systemctl daemon-reload

log "Starting jellyfin.service (first run pulls the image)"
incus exec "$CONTAINER" -- systemctl start jellyfin

# ── 기동 대기 ───────────────────────────────────────────────────────

log "Waiting for /health on :8096"
for _ in $(seq 1 24); do
  if incus exec "$CONTAINER" -- curl -fso /dev/null http://localhost:8096/health; then
    HTTP_OK=1
    break
  fi
  sleep 5
done
[ -n "${HTTP_OK:-}" ] || die "Jellyfin did not come up. Check: incus exec ${CONTAINER} -- journalctl -u jellyfin"

echo
log "Done."
echo "  Web UI : https://gem12.tail4555a7.ts.net:8096  (tailscale-serve/deploy.sh 재실행 필요)"
echo
echo "  첫 접속 때 웹 UI 에서 마저 할 일:"
echo "    1. 초기 마법사 (관리자 계정, 라이브러리는 /media 아래 경로로)"
echo "    2. 대시보드 → 재생 → 트랜스코딩 → VAAPI, 장치 /dev/dri/renderD129"
