#!/usr/bin/env bash
# core 컨테이너에 Uptime Kuma 를 Quadlet 서비스로 배포한다 (계획 §1-3)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# 관리자 계정은 첫 웹 접속 때 만든다 — Forgejo 처럼 CLI 로 만들 방법이 없다.
# 이후 push 모니터를 만들어 URL 을 /etc/gem12-healthcheck.env 에 넣는다
# (healthcheck/deploy.sh 참조).

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

require_root
require_incus

container_exists core || die "core container missing. Run 03-containers.sh first."
ensure_running core

# ── Quadlet 배포 ────────────────────────────────────────────────────

log "Deploying quadlet unit"
incus exec core -- mkdir -p /mnt/data/uptime-kuma /etc/containers/systemd
incus file push "${SCRIPT_DIR}/uptime-kuma.container" core/etc/containers/systemd/uptime-kuma.container
incus exec core -- systemctl daemon-reload

log "Starting uptime-kuma.service (first run pulls the image)"
incus exec core -- systemctl start uptime-kuma

# ── 기동 대기 ───────────────────────────────────────────────────────

log "Waiting for HTTP on :3001"
for _ in $(seq 1 30); do
  if incus exec core -- curl -fso /dev/null http://localhost:3001; then
    HTTP_OK=1
    break
  fi
  sleep 3
done
[ -n "${HTTP_OK:-}" ] || die "Uptime Kuma did not come up. Check: incus exec core -- journalctl -u uptime-kuma"

echo
log "Done."
echo "  Web UI : https://gem12.tail4555a7.ts.net:3001  (tailscale-serve/deploy.sh 재실행 필요)"
echo
echo "  첫 접속 때 웹 UI 에서 마저 할 일:"
echo "    1. 관리자 계정 생성"
echo "    2. 알림 채널 등록 (Settings → Notifications)"
echo "    3. Push 모니터 생성 — 이름 gem12-health, 하트비트 주기 300초, 재시도 2"
echo "       → push URL 을 /etc/gem12-healthcheck.env 에 기록 (healthcheck/deploy.sh)"
