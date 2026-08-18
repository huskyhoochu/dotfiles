#!/usr/bin/env bash
# apps 컨테이너에 NocoDB 를 Docker 로 배포한다 (계획 §12 4단계의 재현성 회수, §10 원칙 2)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다 — 컨테이너가 있으면 건드리지 않는다.
#   sudo ./deploy.sh
#
# 인자는 2026-08-18 가동 중인 컨테이너의 docker inspect 실측값 그대로다.
# 어드민 비밀번호는 이 스크립트가 만들지 않는다 — apps 의 /etc/nocodb.env (root 600)
# 를 사람이 채운다. env.example 참조 (원칙 5).
# /mnt/data/sqlite 마운트: base `arxiv` 가 외부 SQLite(arxiv-candidates.db)를 절대경로로 연다.

source "$(dirname "$0")/../../lib.sh"

CONTAINER="apps"
ENV_FILE="/etc/nocodb.env"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

incus exec "$CONTAINER" -- command -v docker >/dev/null \
  || die "docker not installed in ${CONTAINER}. Run 04-runtime.sh first."

# ── 배포 ────────────────────────────────────────────────────────────

if incus exec "$CONTAINER" -- docker inspect nocodb >/dev/null 2>&1; then
  skip "nocodb container already exists"
else
  incus exec "$CONTAINER" -- test -s "$ENV_FILE" \
    || die "${ENV_FILE} missing in ${CONTAINER}. See env.example."
  log "Creating nocodb container"
  incus exec "$CONTAINER" -- docker run -d --name nocodb \
    --restart unless-stopped \
    -p 8080:8080 \
    --env-file "$ENV_FILE" \
    -e NC_DISABLE_TELE=true \
    -v /mnt/data/nocodb:/usr/app/data \
    -v /mnt/data/sqlite:/mnt/data/sqlite \
    nocodb/nocodb:latest
fi

# ── 검증 ────────────────────────────────────────────────────────────

for _ in $(seq 1 12); do
  if incus exec "$CONTAINER" -- curl -fso /dev/null http://localhost:8080; then
    READY=1
    break
  fi
  sleep 5
done
[ -n "${READY:-}" ] \
  && log "nocodb is up" \
  || die "nocodb did not come up. Check: incus exec ${CONTAINER} -- docker logs nocodb"

echo
log "Done."
echo "  Web: https://gem12.tail4555a7.ts.net:8080  (tailscale serve)"
