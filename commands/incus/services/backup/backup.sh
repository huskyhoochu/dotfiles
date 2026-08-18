#!/usr/bin/env bash
# 백업 파이프라인 본체 — btrfs 스냅샷 + restic → Google Drive (계획 §8, §1-1)
#
# 호스트에서 root 로 실행한다. backup.timer 가 매시 부른다. 수동 실행도 안전하다.
#   sudo ./backup.sh
#
# 1. 루트 서브볼륨을 읽기전용 스냅샷으로 뜬다 (/mnt/data 는 루트 서브볼륨 위의
#    일반 디렉토리라 여기 함께 잡힌다. 컨테이너 루트fs 는 별도 서브볼륨이라
#    안 잡힌다 — 그쪽은 Incus 내장 스냅샷 스케줄의 몫, deploy.sh 참조)
# 2. 스냅샷에서 restic 백업 — SQLite(WAL)를 멈추지 않고 crash-consistent 하게 뜬다
# 3. ai(모델 가중치)·ci(CI 캐시)는 §8 교리대로 제외한다
#
# 시크릿: /root/.restic-password (op://Personal/GEM12_RESTIC_PASSWORD),
#         /root/.config/rclone/rclone.conf 의 [gdrive] (op://Personal/GEM12_RCLONE_DRIVE_TOKEN)

source "$(dirname "$0")/../../lib.sh"

SNAP_DIR="/.snapshots"
SNAP_KEEP_HOURS=24
BIND="/run/backup-src"
export RESTIC_REPOSITORY="rclone:gdrive:gem12-backup"
export RESTIC_PASSWORD_FILE="/root/.restic-password"

require_root

# 타이머 주기보다 백업이 오래 걸리면 겹친다. 잠금이 있으면 조용히 물러난다.
exec 9>/run/backup.lock
flock -n 9 || { skip "Another backup is running"; exit 0; }

# ── 1. btrfs 스냅샷 ─────────────────────────────────────────────────

mkdir -p "$SNAP_DIR"
SNAP_NAME="auto-$(date +%Y%m%d-%H%M%S)"
btrfs subvolume snapshot -r / "${SNAP_DIR}/${SNAP_NAME}" >/dev/null
log "Snapshot created: ${SNAP_NAME}"

# 이름의 타임스탬프로 24시간 지난 스냅샷을 지운다. 더 오랜 이력은 restic 이 맡는다.
CUTOFF="auto-$(date -d "${SNAP_KEEP_HOURS} hours ago" +%Y%m%d-%H%M%S)"
for path in "$SNAP_DIR"/auto-*; do
  [ -d "$path" ] || continue
  if [[ "$(basename "$path")" < "$CUTOFF" ]]; then
    btrfs subvolume delete "$path" >/dev/null
    log "Snapshot pruned: $(basename "$path")"
  fi
done

# ── 2. restic 백업 (스냅샷에서) ─────────────────────────────────────
# 경로를 bind mount 로 고정해 restic 이 매번 같은 경로를 보게 한다
# (스냅샷 이름이 경로에 들어가면 스냅샷마다 다른 백업 세트로 갈라진다).

mkdir -p "$BIND"
mountpoint -q "$BIND" && umount "$BIND"
mount --bind "${SNAP_DIR}/${SNAP_NAME}" "$BIND"
trap 'umount "$BIND" 2>/dev/null || true' EXIT

restic backup "${BIND}/mnt/data" \
  --exclude "${BIND}/mnt/data/ai" \
  --exclude "${BIND}/mnt/data/ci" \
  --tag auto --quiet
log "restic backup done"

# ── 3. 보존 정책 ────────────────────────────────────────────────────
# forget 은 태그만 정리한다. 실제 데이터 회수(prune)는 주 1회 backup-prune 이 한다.

restic forget --keep-hourly 24 --keep-daily 7 --keep-weekly 8 --quiet

log "Done."
