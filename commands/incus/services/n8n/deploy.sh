#!/usr/bin/env bash
# apps 컨테이너에 n8n 을 Docker 로 배포한다 (계획 §12 4단계의 재현성 회수, §10 원칙 2)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다 — 컨테이너가 있으면 건드리지 않는다.
#   sudo ./deploy.sh
#
# 인자는 2026-08-18 가동 중인 컨테이너의 docker inspect 실측값 그대로다.
# - N8N_SECURE_COOKIE=false: tailscale serve(HTTPS 종단이 프록시) 뒤에서 필수
# - /mnt/data/sqlite 를 /data/arxiv/sqlite 로 겹쳐 마운트: 워크플로가 DB 를 상대경로로 본다

source "$(dirname "$0")/../../lib.sh"

CONTAINER="apps"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

incus exec "$CONTAINER" -- command -v docker >/dev/null \
  || die "docker not installed in ${CONTAINER}. Run 04-runtime.sh first."

# ── 배포 ────────────────────────────────────────────────────────────

if incus exec "$CONTAINER" -- docker inspect n8n >/dev/null 2>&1; then
  skip "n8n container already exists"
else
  log "Creating n8n container"
  incus exec "$CONTAINER" -- docker run -d --name n8n \
    --restart unless-stopped \
    -p 5678:5678 \
    -e N8N_SECURE_COOKIE=false \
    -e N8N_RUNNERS_ENABLED=true \
    -e GENERIC_TIMEZONE=Asia/Seoul \
    -e TZ=Asia/Seoul \
    -v /mnt/data/arxiv:/data/arxiv \
    -v /mnt/data/sqlite:/data/arxiv/sqlite \
    -v /mnt/data/n8n:/home/node/.n8n \
    docker.n8n.io/n8nio/n8n
fi

# ── 검증 ────────────────────────────────────────────────────────────

for _ in $(seq 1 12); do
  if incus exec "$CONTAINER" -- curl -fso /dev/null http://localhost:5678; then
    READY=1
    break
  fi
  sleep 5
done
[ -n "${READY:-}" ] \
  && log "n8n is up" \
  || die "n8n did not come up. Check: incus exec ${CONTAINER} -- docker logs n8n"

echo
log "Done."
echo "  Web: https://gem12.tail4555a7.ts.net:5678  (tailscale serve)"
