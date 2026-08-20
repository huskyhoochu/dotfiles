#!/usr/bin/env bash
# 호스트에 Litestream 설정을 배포한다 (계획 §7 백업)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# Litestream 자체(RPM)와 systemd 유닛은 RPM 패키지가 제공한다. 이 스크립트는
# 설정 파일만 관장한다 (§10 원칙 2 재현성).
#
# 2026-08-20 호스트로 이전했다 — 이전 배치(apps 컨테이너)는 다른 컨테이너의
# DB 에 구조적으로 닿을 수 없어 9개 중 2개만 복제되고 있었다. 근거는
# litestream.yml 머리말.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG=/etc/litestream.yml
REPLICA_DIR=/mnt/data/backup/litestream

require_root

# ── 전제 확인 ───────────────────────────────────────────────────────

command -v litestream >/dev/null \
  || die "litestream not installed. RPM: https://github.com/benbjohnson/litestream/releases (litestream-<ver>-linux-x86_64.rpm)"

# 컨테이너 안에 옛 인스턴스가 남아 있으면 같은 DB 를 두 프로세스가 잡는다.
if incus exec apps -- systemctl is-active --quiet litestream 2>/dev/null; then
  die "apps 컨테이너의 litestream 이 아직 돈다 — 이중 복제가 된다. 먼저 정지: incus exec apps -- systemctl disable --now litestream"
fi

log "Prerequisites OK"

# ── 설정 배포 ───────────────────────────────────────────────────────

mkdir -p "$REPLICA_DIR"
install -m 644 "${SCRIPT_DIR}/litestream.yml" "$CONFIG"

systemctl restart litestream
systemctl enable litestream >/dev/null 2>&1

# ── 검증 ────────────────────────────────────────────────────────────
# databases 는 설정을 읽을 뿐이므로, 복제가 실제로 도는지는 로그로 본다.

sleep 3
systemctl is-active --quiet litestream \
  || die "litestream is not running. Check: journalctl -u litestream -n 30"

echo
litestream databases | sed 's/^/  /'

echo
CONFIGURED=$(grep -c '^  - path:' "$CONFIG")
SYNCED=$(journalctl -u litestream --since '30 seconds ago' -o cat 2>/dev/null \
  | grep -c 'replica sync' || true)
log "설정 대상 ${CONFIGURED}개, 최근 30초 sync 로그 ${SYNCED}건"
[ "$SYNCED" -gt 0 ] || warn "sync 로그가 없다 — journalctl -u litestream 을 확인하라"

echo
log "Done."
