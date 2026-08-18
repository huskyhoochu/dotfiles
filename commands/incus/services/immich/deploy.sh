#!/usr/bin/env bash
# media 컨테이너에 Immich 를 Quadlet 서비스로 배포한다 (계획 §1-2)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# 구성: server + PostgreSQL(VectorChord) + Valkey — Quadlet 3개 + 네트워크 1개.
# ML 컨테이너는 배포하지 않는다 (사용자 결정, immich-server.container 주석 참조).
# DB 비밀번호는 이 스크립트가 만들지 않는다 — media 의 /etc/immich.env (root 600)
# 를 사람이 채운다. env.example 참조 (원칙 5).

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="media"
UNITS=(immich.network immich-postgres.container immich-valkey.container immich-server.container)

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

incus exec "$CONTAINER" -- test -s /etc/immich.env \
  || die "/etc/immich.env missing in ${CONTAINER}. See env.example."

# ── Quadlet 배포 ────────────────────────────────────────────────────

log "Deploying quadlet units"
incus exec "$CONTAINER" -- mkdir -p \
  /mnt/data/immich/library /mnt/data/immich/postgres /etc/containers/systemd
for unit in "${UNITS[@]}"; do
  incus file push "${SCRIPT_DIR}/${unit}" "${CONTAINER}/etc/containers/systemd/${unit}"
done
incus exec "$CONTAINER" -- systemctl daemon-reload

log "Starting immich-server.service (Requires 가 postgres·valkey 를 견인, 첫 실행은 이미지 pull)"
incus exec "$CONTAINER" -- systemctl start immich-server

# ── 기동 대기 ───────────────────────────────────────────────────────
# 첫 회차는 이미지 3개 pull + DB 마이그레이션이라 오래 걸린다.

log "Waiting for HTTP on :2283 (up to ~3.5 min)"
for _ in $(seq 1 40); do
  if incus exec "$CONTAINER" -- curl -fso /dev/null http://localhost:2283/api/server/ping; then
    HTTP_OK=1
    break
  fi
  sleep 5
done
[ -n "${HTTP_OK:-}" ] || die "Immich did not come up. Check: incus exec ${CONTAINER} -- journalctl -u immich-server; podman logs immich-server"

echo
log "Done."
echo "  Web UI : https://gem12.tail4555a7.ts.net:2283  (tailscale-serve/deploy.sh 재실행 필요)"
echo
echo "  첫 접속 때 웹 UI 에서 마저 할 일:"
echo "    1. 관리자 계정 생성"
echo "    2. 관리 → 설정 → Machine Learning 비활성화 (ML 컨테이너 미배포 — 로그 소음 방지)"
echo "    3. 사진 1장 업로드가 §1-2 의 검증 기준"
