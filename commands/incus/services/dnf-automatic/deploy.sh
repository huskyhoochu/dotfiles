#!/usr/bin/env bash
# 자동 보안 업데이트를 호스트와 전 컨테이너에 배포한다 (계획 §1-4)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# Fedora 44 는 dnf5 라 패키지가 dnf5-plugin-automatic, 타이머가
# dnf5-automatic.timer 다 (dnf-automatic 이름은 호환 심볼릭). 설정 오버라이드는
# /etc/dnf/automatic.conf — automatic.conf 참조.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

require_root
require_incus

setup_host() {
  log "host: installing dnf5-plugin-automatic"
  dnf install -y -q dnf5-plugin-automatic
  install -m 644 "${SCRIPT_DIR}/automatic.conf" /etc/dnf/automatic.conf
  systemctl enable --now dnf5-automatic.timer >/dev/null 2>&1
}

setup_container() {
  local name="$1"
  container_exists "$name" || die "${name} container missing. Run 03-containers.sh first."
  ensure_running "$name"
  log "${name}: installing dnf5-plugin-automatic"
  incus exec "$name" -- dnf install -y -q dnf5-plugin-automatic
  incus file push "${SCRIPT_DIR}/automatic.conf" "${name}/etc/dnf/automatic.conf"
  incus exec "$name" -- systemctl enable --now dnf5-automatic.timer
}

setup_host
# incus exec 가 루프의 stdin 을 삼켜 다음 줄을 잃는다 — </dev/null 로 끊는다.
while read -r NAME _; do
  setup_container "$NAME" </dev/null
done < <(read_containers)

# ── 검증 ────────────────────────────────────────────────────────────

echo
systemctl list-timers dnf5-automatic.timer --no-pager | sed 's/^/  /'
while read -r NAME _; do
  printf '  %-6s %s\n' "$NAME" "$(incus exec "$NAME" -- systemctl is-enabled dnf5-automatic.timer </dev/null)"
done < <(read_containers)

echo
log "Done."
