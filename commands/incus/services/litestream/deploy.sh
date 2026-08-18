#!/usr/bin/env bash
# apps 컨테이너에 Litestream 설정을 배포한다 (계획 §8, §12 4단계의 재현성 회수)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# Litestream 자체(RPM)와 systemd 유닛은 RPM 패키지가 제공한다. 이 스크립트는
# 설정 파일만 관장한다 — 서버에서 수동으로 만든 설정을 Git 으로 회수한 것 (§10 원칙 2).

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="apps"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# ── 전제 확인 ───────────────────────────────────────────────────────

incus exec "$CONTAINER" -- command -v litestream >/dev/null \
  || die "litestream not installed in ${CONTAINER}. Install the RPM from https://github.com/benbjohnson/litestream/releases"

log "Prerequisites OK"

# ── 설정 배포 ───────────────────────────────────────────────────────

incus file push "${SCRIPT_DIR}/litestream.yml" "${CONTAINER}/etc/litestream.yml"
incus exec "$CONTAINER" -- systemctl restart litestream
incus exec "$CONTAINER" -- systemctl enable litestream >/dev/null 2>&1

# ── 검증 ────────────────────────────────────────────────────────────

sleep 2
incus exec "$CONTAINER" -- systemctl is-active --quiet litestream \
  || die "litestream is not running. Check: incus exec ${CONTAINER} -- journalctl -u litestream"

echo
incus exec "$CONTAINER" -- litestream databases | sed 's/^/  /'

echo
log "Done."
