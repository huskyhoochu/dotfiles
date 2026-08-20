#!/usr/bin/env bash
# 백업 파이프라인 본체 — btrfs 스냅샷 + restic → Google Drive (계획 §8, §1-1)
#
# 호스트에서 root 로 실행한다. backup.timer 가 매시 부른다. 수동 실행도 안전하다.
#   sudo ./backup.sh
#
# deploy.sh 가 /usr/local/sbin/gem12-backup 으로 복사해 설치한다 — /root 아래는
# SELinux(admin_home_t)가 systemd 의 실행을 막는다(실측). 그래서 이 파일은
# lib.sh 를 source 하지 않고 자립한다.
#
# 1. 루트 서브볼륨을 읽기전용 스냅샷으로 뜬다 (/mnt/data 는 루트 서브볼륨 위의
#    일반 디렉토리라 여기 함께 잡힌다. 컨테이너 루트fs 는 별도 서브볼륨이라
#    안 잡힌다 — 그쪽은 Incus 내장 스냅샷 스케줄의 몫, deploy.sh 참조)
# 2. 스냅샷에서 restic 백업 — SQLite(WAL)를 멈추지 않고 crash-consistent 하게 뜬다
# 3. ai(모델 가중치)·ci(CI 캐시)·jellyfin 미디어(원본이 외장 SSD)는 §8 교리대로 제외한다
#
# 시크릿: /root/.restic-password (op://Personal/GEM12_RESTIC_PASSWORD),
#         /root/.config/rclone/rclone.conf 의 [gdrive] (op://Personal/GEM12_RCLONE_DRIVE_TOKEN)

set -euo pipefail

log()  { printf '\033[34m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$1"; }
die()  { printf '\033[31m[ERROR]\033[0m %s\n' "$1" >&2; exit 1; }
skip() { printf '\033[90m[SKIP]\033[0m %s\n' "$1"; }

require_root() {
  [ "$(id -u)" -eq 0 ] || die "Must run as root. Use sudo or log in as root."
}

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

# 사진·영화 원본은 외장 SSD 에 있고 용량이 Drive 백업에 맞지 않는다 (사용자 결정
# 2026-08-18). Immich 는 원본 라이브러리만 빼고 DB(postgres — 앨범·메타)는 남긴다.
#
# 업로드 상한 4 MiB/s(≈32 Mbps): 평상시 매시 백업은 수 MB 라 상한에 닿지 않고, 저장소
# 이관 같은 대량 유입 때만 작동해 공유 Wi-Fi 점유를 막는다 (사용자 결정 2026-08-19).
#
# tpslimit 은 Drive 분당 쿼터를 넘지 않기 위한 값이다. 402MB 유입 때 백업이 세 번
# 죽었는데, 오류를 유형별로 세어 보니 rateLimitExceeded 22 : 500 이 11 이었다 —
# 500 은 쿼터 초과의 파생이고 근본은 분당 요청 수다. 동시성(connections)이나
# 대역(limit-upload)을 낮춰도 총 요청 수는 그대로라 쿼터는 똑같이 소진된다.
# 초당 트랜잭션 자체를 묶어야 넘어간다(2026-08-19 실측, 당시 값 4).
#
# 2026-08-20 개인 client_id 로 전환하면서 10 으로 완화했다. 공용 client_id 는 분당
# 쿼터를 전 세계 rclone 사용자와 나누는 구조였고, 전환 직후 실측에서 매시 백업이
# 88초 → 34초로 줄고 rateLimitExceeded·500·재시도가 전부 0건이 됐다. 개인 쿼터도
# 무한은 아니므로 대량 유입 때 429 가 보이면 이 값을 먼저 내린다.
restic backup "${BIND}/mnt/data" \
  --exclude "${BIND}/mnt/data/ai" \
  --exclude "${BIND}/mnt/data/ci" \
  --exclude "${BIND}/mnt/data/media/jellyfin/media" \
  --exclude "${BIND}/mnt/data/media/immich/library" \
  --limit-upload 4096 \
  -o rclone.connections=2 \
  -o rclone.args="serve restic --stdio --tpslimit 10 --tpslimit-burst 5 --drive-pacer-min-sleep 200ms --retries 20 --low-level-retries 20" \
  --tag auto --quiet
log "restic backup done"

# ── 3. 보존 정책 ────────────────────────────────────────────────────
# forget 은 태그만 정리한다. 실제 데이터 회수(prune)는 주 1회 backup-prune 이 한다.
#
# 그 전에 스테일 락을 치운다. restic 저장소 락은 Drive 위의 파일이라 프로세스가
# 죽으면 남는다 — 위쪽 flock 은 로컬이고 커널이 회수하므로 층이 다르다.
# backup 은 shared lock 이라 통과하지만 forget 은 exclusive 라 막힌다. 그래서
# 락 하나가 백업은 멀쩡한 채 보존 정리만 골라 세운다.
# 실측 2026-08-20: 08-19 17:13 의 락이 18시간 방치돼 매시 forget 이 실패했고,
# 스냅샷이 정리되지 않은 채 쌓였다. unlock 은 기본적으로 30분 넘게 갱신되지 않은
# 락만 지운다(--remove-all 을 쓰지 않으므로 살아 있는 백업은 건드리지 않는다).

restic unlock \
  -o rclone.connections=2 \
  -o rclone.args="serve restic --stdio --tpslimit 10 --tpslimit-burst 5 --drive-pacer-min-sleep 200ms --retries 20 --low-level-retries 20" \
  --quiet

restic forget --keep-hourly 24 --keep-daily 7 --keep-weekly 8 \
  -o rclone.connections=2 \
  -o rclone.args="serve restic --stdio --tpslimit 10 --tpslimit-burst 5 --drive-pacer-min-sleep 200ms --retries 20 --low-level-retries 20" \
  --quiet

log "Done."
