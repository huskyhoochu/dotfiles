#!/usr/bin/env bash
# 호스트 상태 점검 타이머를 배포한다 (계획 §1-3)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# backup 과 같은 이유로 유닛이 호스트에 놓인다 — hwmon·btrfs·smartctl·incus 는
# 호스트 권한으로만 닿는다. Kuma push URL 은 /etc/gem12-healthcheck.env 에 두고,
# 비어 있으면 push 없이 journal 기록만 한다 (Kuma 웹 UI 설정 전에도 배포 가능).

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE=/etc/gem12-healthcheck.env

require_root
require_incus
command -v smartctl >/dev/null || die "smartctl not installed. Run 02-host.sh first."

# ── 배포 ────────────────────────────────────────────────────────────

log "Deploying healthcheck script and systemd units"
# /root 아래 두면 SELinux(admin_home_t)가 systemd 실행을 막는다 —
# /usr/local/sbin 으로 복사해 bin_t 컨텍스트를 얻는다.
install -m 755 "${SCRIPT_DIR}/healthcheck.sh" /usr/local/sbin/gem12-healthcheck
cp "${SCRIPT_DIR}/healthcheck.service" /etc/systemd/system/healthcheck.service
cp "${SCRIPT_DIR}/healthcheck.timer" /etc/systemd/system/healthcheck.timer

if [ -f "$ENV_FILE" ]; then
  skip "${ENV_FILE} already present"
else
  install -m 600 "${SCRIPT_DIR}/env.example" "$ENV_FILE"
  warn "${ENV_FILE} created empty — Kuma push 모니터 URL 을 넣어야 알림이 붙는다"
fi

# Forgejo API 토큰 (미러 push 감시) — 없으면 CLI 로 발급해 기입한다.
if grep -q '^FORGEJO_TOKEN=.\+' "$ENV_FILE"; then
  skip "FORGEJO_TOKEN already present"
else
  log "Generating Forgejo access token (gem12-healthcheck, read:repository)"
  if TOKEN=$(incus exec core -- podman exec --user git forgejo \
      forgejo admin user generate-access-token --username b95labs \
      --token-name gem12-healthcheck --scopes read:repository </dev/null \
      | awk 'END{print $NF}') && [ -n "$TOKEN" ]; then
    sed -i '/^FORGEJO_TOKEN=/d' "$ENV_FILE"
    printf 'FORGEJO_TOKEN=%s\n' "$TOKEN" >>"$ENV_FILE"
    log "FORGEJO_TOKEN written to ${ENV_FILE}"
  else
    warn "token generation failed — 같은 이름의 토큰이 남아 있으면 Forgejo 설정에서 지우고 재실행"
  fi
fi

systemctl daemon-reload
systemctl enable --now healthcheck.timer >/dev/null 2>&1

# ── 첫 실행으로 검증 ────────────────────────────────────────────────

log "Running the first check"
systemctl start healthcheck.service \
  || warn "First check reported DOWN. Check: journalctl -u healthcheck --no-pager -n 20"

echo
systemctl list-timers healthcheck.timer --no-pager | sed 's/^/  /'
journalctl -u healthcheck --no-pager -n 5 -o cat | sed 's/^/  /'

echo
log "Done."
