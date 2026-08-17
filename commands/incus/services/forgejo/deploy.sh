#!/usr/bin/env bash
# core 컨테이너에 Forgejo 를 Quadlet 서비스로 배포한다
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADMIN_USER="${ADMIN_USER:-b95labs}"
# 개인 인프라이므로 개인 이메일을 쓴다. 회사 이메일(dev@bfai.ai)을 넣지 않는다.
ADMIN_EMAIL="${ADMIN_EMAIL:-dfg1499@gmail.com}"

require_root
require_incus

container_exists core || die "core container missing. Run 03-containers.sh first."
ensure_running core

# ── Quadlet 배포 ────────────────────────────────────────────────────

log "Deploying quadlet unit"
incus exec core -- mkdir -p /mnt/data/forgejo /etc/containers/systemd
incus file push "${SCRIPT_DIR}/forgejo.container" core/etc/containers/systemd/forgejo.container
incus exec core -- systemctl daemon-reload

log "Starting forgejo.service (first run pulls the image)"
incus exec core -- systemctl start forgejo

# ── 기동 대기 ───────────────────────────────────────────────────────

log "Waiting for HTTP on :3000"
for _ in $(seq 1 30); do
  if incus exec core -- curl -fso /dev/null http://localhost:3000; then
    HTTP_OK=1
    break
  fi
  sleep 3
done
[ -n "${HTTP_OK:-}" ] || die "Forgejo did not come up. Check: incus exec core -- journalctl -u forgejo"

# ── 관리자 계정 ─────────────────────────────────────────────────────
# 마법사를 잠갔으므로 CLI로 만든다. 임시 비밀번호가 출력되며 첫 로그인 때
# 변경을 강제한다.

if incus exec core -- podman exec --user git forgejo forgejo admin user list \
  | awk '{print $2}' | grep -qx "$ADMIN_USER"; then
  skip "admin user ${ADMIN_USER} already exists"
else
  log "Creating admin user ${ADMIN_USER} (temporary password below)"
  incus exec core -- podman exec --user git forgejo \
    forgejo admin user create --admin \
    --username "$ADMIN_USER" --email "$ADMIN_EMAIL" \
    --random-password --must-change-password
fi

echo
log "Done."
echo "  Web UI : http://10.10.10.11:3000  (Tailscale required)"
echo "  Git SSH: ssh://git@10.10.10.11:2222"
