#!/usr/bin/env bash
# Qwen 3.8-27B 가중치(Q4_K_M + MTP 드래프터)를 ai 컨테이너로 내려받는다
#
# 호스트에서 root 로 실행한다. 중단된 파일은 이어받는다.
#   sudo ./download.sh              # 기본 5 MB/s
#   sudo RATE=2M ./download.sh      # 더 느리게
#
# 속도 제한이 기본값인 이유: 이 서버는 집 Wi-Fi 를 쓴다. 제한 없이 받으면
# 회선을 포화시켜 다른 기기의 인터넷이 끊긴다 (2026-08-18 실측).
#
# 본 모델 17.7GiB + MTP 드래프터 1.6GiB = 약 19.3GiB. 5 MB/s 로 약 70분이다.
# 어느 저장소의 어느 파일을 쓰는지가 이 스크립트의 기록 역할이다.
#
# ggml-org 저장소를 고른 이유: llama.cpp 팀의 변환본이라 아키텍처 메타데이터
# (general.architecture=qwen35)가 서버 빌드와 확실히 맞는다. 커뮤니티 변환본은
# 같은 이름으로도 메타데이터가 다를 수 있다.

source "$(dirname "$0")/../../lib.sh"

CONTAINER="ai"
DEST="/mnt/data/models"
RATE="${RATE:-5M}"
BASE="https://huggingface.co/ggml-org/Qwen3.8-27B-GGUF/resolve/main"

# 파일 이름과 기대 크기(바이트, HF API 실측 2026-08-22). 크기로 완결성을 판정한다.
FILES=(
  "Qwen3.8-27B-Q4_K_M.gguf 18973870432"
  "mtp-Qwen3.8-27B-Q4_0.gguf 1680271648"
)

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

incus exec "$CONTAINER" -- mkdir -p "$DEST"

log "Rate limit: ${RATE}/s"

for entry in "${FILES[@]}"; do
  read -r NAME SIZE <<<"$entry"
  TARGET="${DEST}/${NAME}"

  CURRENT=$(incus exec "$CONTAINER" -- stat -c %s "$TARGET" 2>/dev/null || echo 0)

  if [ "$CURRENT" = "$SIZE" ]; then
    skip "${NAME} already complete"
    continue
  fi

  if [ "$CURRENT" != "0" ]; then
    log "${NAME}: resuming from ${CURRENT} bytes"
  else
    log "${NAME}: downloading"
  fi

  # -C - 가 로컬 크기를 읽어 Range 헤더를 만든다. 중단돼도 이어받는다.
  incus exec "$CONTAINER" -- curl -fL --limit-rate "$RATE" -C - \
    -o "$TARGET" "${BASE}/${NAME}"

  FINAL=$(incus exec "$CONTAINER" -- stat -c %s "$TARGET")
  [ "$FINAL" = "$SIZE" ] || die "${NAME}: size mismatch (${FINAL} != ${SIZE})"

  log "${NAME}: OK"
done

echo
log "Done. Next: deploy.sh"
