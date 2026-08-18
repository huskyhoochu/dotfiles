#!/usr/bin/env bash
# 3단계 오프라인 사본 — 외장 SSD 에 서버 핵심 데이터 tar (계획 §8 3단계)
#
# 호스트에서 root 로 실행한다. 분기 1회, SSD 를 서버에 연결한 김에 돌린다.
#   sudo ./offline-copy.sh          # SSD 가 /mnt/ssd 에 rw 마운트된 상태에서
#
# 암호화하지 않는다 (사용자 결정 2026-08-18) — 이 SSD 는 집 안 보관 매체이고,
# 계정 잠김·클라우드 접근 불가 시 즉시 읽을 수 있는 것이 우선이다.
#
# 대상은 restic 과 같다: "서버가 유일한 사본"인 것만. 사진·영화 원본은 이 SSD
# 자체에 있으므로(이중화의 반대편) 제외 규칙도 restic 과 동일하다.
# 원본 훼손을 피하려고 새 스냅샷을 만들지 않고 매시 스냅샷의 최신본에서 뜬다.

set -euo pipefail

log()  { printf '\033[34m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$1"; }
die()  { printf '\033[31m[ERROR]\033[0m %s\n' "$1" >&2; exit 1; }

DEST=/mnt/ssd/gem12-offline
KEEP=2

[ "$(id -u)" -eq 0 ] || die "Must run as root."
mountpoint -q /mnt/ssd || die "/mnt/ssd not mounted. mount -o rw /dev/sdX1 /mnt/ssd"
touch /mnt/ssd/.rw-test 2>/dev/null && rm -f /mnt/ssd/.rw-test \
  || die "/mnt/ssd is read-only. mount -o remount,rw /mnt/ssd"

SNAP=$(ls -d /.snapshots/auto-* 2>/dev/null | sort | tail -1)
[ -n "$SNAP" ] || die "no hourly snapshot found — is backup.timer running?"
log "Source snapshot: ${SNAP}"

mkdir -p "$DEST"
ARCHIVE="${DEST}/gem12-data-$(date +%Y%m%d-%H%M).tar.gz"

tar -C "${SNAP}/mnt" \
  --exclude='data/ai' \
  --exclude='data/ci' \
  --exclude='data/media/jellyfin/media' \
  --exclude='data/media/immich/library' \
  -czf "$ARCHIVE" data
log "Archive written: ${ARCHIVE} ($(du -h "$ARCHIVE" | cut -f1))"

# 무결성 — 목록을 끝까지 읽을 수 있으면 아카이브가 온전하다.
tar -tzf "$ARCHIVE" >/dev/null || die "archive verification failed"
log "Archive verified ($(tar -tzf "$ARCHIVE" | wc -l) entries)"

# 보존 — 최신 KEEP 개만 남긴다 (분기 1회 갱신이므로 2개면 반년 이력).
ls -1t "$DEST"/gem12-data-*.tar.gz | tail -n +$((KEEP + 1)) | while read -r old; do
  rm -f "$old"
  log "Pruned: $(basename "$old")"
done

# SSD 건강 확인 (§8 — 갱신할 때 함께 본다). USB 브리지는 -d sat 가 필요하다(실측).
DEV=$(findmnt -n -o SOURCE /mnt/ssd | sed 's/[0-9]*$//')
smartctl -H -d sat "$DEV" | grep -E "overall-health" || true

log "Done."
