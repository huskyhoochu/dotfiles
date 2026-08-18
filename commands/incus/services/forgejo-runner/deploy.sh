#!/usr/bin/env bash
# ci 컨테이너에 Forgejo Actions runner 를 systemd 서비스로 배포한다 (계획 §12 4단계의 재현성 회수)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# 등록(register)은 이 스크립트가 하지 않는다 — 등록 토큰은 Forgejo 웹
# (사이트 관리 → Actions → Runners → 등록 토큰)에서 사람이 발급한다:
#   incus exec ci -- sh -c 'cd /var/lib/forgejo-runner && forgejo-runner register \
#     --no-interactive --instance http://10.10.10.11:3000 --token <토큰> \
#     --name gem12-ci --labels ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-22.04,node-24:docker://node:24-bookworm,docker:docker://node:24-bookworm'
# (라벨은 2026-08-18 가동 중인 .runner 실측값 그대로)
# 등록 결과(.runner)가 이미 있으면 그대로 쓴다.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="ci"
WORKDIR="/var/lib/forgejo-runner"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# ── 전제 확인 ───────────────────────────────────────────────────────

incus exec "$CONTAINER" -- test -x /usr/local/bin/forgejo-runner \
  || die "forgejo-runner binary missing. Install from https://code.forgejo.org/forgejo/runner/releases"
incus exec "$CONTAINER" -- test -s "${WORKDIR}/.runner" \
  || die "Runner not registered (${WORKDIR}/.runner missing). See the register command in this script's header."

log "Prerequisites OK"

# ── 유닛 배포 ───────────────────────────────────────────────────────

incus file push "${SCRIPT_DIR}/forgejo-runner.service" \
  "${CONTAINER}/etc/systemd/system/forgejo-runner.service"
incus exec "$CONTAINER" -- systemctl daemon-reload
incus exec "$CONTAINER" -- systemctl enable --now forgejo-runner >/dev/null 2>&1

# ── 검증 ────────────────────────────────────────────────────────────

sleep 2
incus exec "$CONTAINER" -- systemctl is-active --quiet forgejo-runner \
  || die "forgejo-runner is not running. Check: incus exec ${CONTAINER} -- journalctl -u forgejo-runner"

echo
log "Done."
