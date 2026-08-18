#!/usr/bin/env bash
# 백업 파이프라인 배포 — 스냅샷·restic 타이머(호스트) + Incus 스냅샷 스케줄 (계획 §1-1)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# 다른 서비스와 달리 유닛이 컨테이너가 아니라 호스트에 놓인다 — btrfs 스냅샷과
# incus 명령, 전 컨테이너 데이터(/mnt/data/*)는 호스트 권한으로만 닿는다.
#
# 시크릿은 이 스크립트가 만들지 않는다. 실행 전에 사람이 준비한다:
#   1. rclone Drive 토큰 — 맥북에서 `rclone authorize "drive"` (계획 §6),
#      토큰은 op://Personal/GEM12_RCLONE_DRIVE_TOKEN 에 보관,
#      호스트 /root/.config/rclone/rclone.conf 의 [gdrive] remote 로 등록 (600)
#   2. restic 비밀번호 — op://Personal/GEM12_RESTIC_PASSWORD 에 보관,
#      호스트 /root/.restic-password 에 배치 (600). 이 비밀번호를 잃으면
#      백업 전체를 잃는다 — 1Password 밖에 두지 않는다.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UNITS=(backup.service backup.timer backup-prune.service backup-prune.timer)
export RESTIC_REPOSITORY="rclone:gdrive:gem12-backup"
export RESTIC_PASSWORD_FILE="/root/.restic-password"

require_root
require_incus

# ── 전제 확인 ───────────────────────────────────────────────────────

command -v restic >/dev/null || die "restic not installed. Run 02-host.sh first."
command -v rclone >/dev/null || die "rclone not installed. Run 02-host.sh first."

rclone listremotes | grep -qx 'gdrive:' \
  || die "rclone remote 'gdrive' missing. See the secret steps in this script's header."

[ -s "$RESTIC_PASSWORD_FILE" ] \
  || die "${RESTIC_PASSWORD_FILE} missing. See the secret steps in this script's header."
chmod 600 "$RESTIC_PASSWORD_FILE"

log "Prerequisites OK"

# ── restic 저장소 초기화 ────────────────────────────────────────────

if restic cat config >/dev/null 2>&1; then
  skip "restic repository already initialized"
else
  log "Initializing restic repository at ${RESTIC_REPOSITORY}"
  restic init
fi

# ── 유닛 배포 (호스트) ──────────────────────────────────────────────

log "Deploying systemd units"
for unit in "${UNITS[@]}"; do
  cp "${SCRIPT_DIR}/${unit}" "/etc/systemd/system/${unit}"
done
systemctl daemon-reload
systemctl enable --now backup.timer backup-prune.timer >/dev/null 2>&1

# ── Incus 컨테이너 스냅샷 스케줄 ────────────────────────────────────
# 컨테이너 루트fs 는 btrfs 루트 스냅샷에 안 잡힌다(별도 서브볼륨).
# Incus 내장 스케줄로 매일 04:00 스냅샷, 7일 보존.

incus profile set default snapshots.schedule "0 4 * * *"
incus profile set default snapshots.expiry "7d"
log "Incus snapshot schedule set (daily 04:00, keep 7d)"

# ── 첫 백업 실행 ────────────────────────────────────────────────────

log "Running the first backup (may take a while on the initial run)"
systemctl start backup.service \
  || die "First backup failed. Check: journalctl -u backup"

# ── 결과 ────────────────────────────────────────────────────────────

echo
restic snapshots --latest 1 --compact | sed 's/^/  /'
systemctl list-timers backup.timer backup-prune.timer --no-pager | sed 's/^/  /'

echo
log "Done."
echo "  Restore rehearsal: restic -r ${RESTIC_REPOSITORY} restore latest --target <dir>"
