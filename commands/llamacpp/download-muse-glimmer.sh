#!/usr/bin/env bash
# Muse Glimmer 30B 가중치 내려받기
#
# 이 장비에서 실제 작동이 확인된 유일한 로컬 모델이다. 다른 후보들은
# 시험만 했거나 속도가 쓸 만하지 않았다(Qwen3-Coder-Next 80B 는 CPU
# 오프로드 때문에 17 tok/s 로 떨어졌다).
#
# 모델 가중치는 백업하지 않는다 — 재다운로드할 수 있기 때문이다. 대신 이
# 스크립트가 실질적인 백업 역할을 한다. 어느 저장소의 어느 파일을 쓰는지가
# 여기에 기록돼 있다.
#
# 본 모델 15.6GB + drafter 1.5GB = 약 17GB.
# run-muse-glimmer-server.sh 가 이 파일들을 찾는다.

set -euo pipefail

REPO="meta-models/Muse-Glimmer-30B-GGUF"
MODELS="${MODELS:-$HOME/Documents/models}"

# 본 모델과 DFlash drafter. drafter 는 블록 확산 방식 초안 모델로,
# 출력 품질은 그대로 두고 생성 속도만 올린다.
FILES=(
  "Muse-Glimmer-30B-KQuant-17GB-Q4_K_M.gguf"
  "dflash-Muse-Glimmer-30B-Q4_K_M.gguf"
)

mkdir -p "$MODELS"

if command -v hf >/dev/null 2>&1; then
  DL=(hf download)
elif command -v huggingface-cli >/dev/null 2>&1; then
  DL=(huggingface-cli download)
else
  echo "huggingface CLI가 없다. 설치한다: pip install -U 'huggingface_hub[cli]'" >&2
  exit 1
fi

for f in "${FILES[@]}"; do
  if [ -f "$MODELS/$f" ]; then
    echo "[건너뜀] $f 가 이미 있다"
    continue
  fi
  echo "[내려받기] $f"
  "${DL[@]}" "$REPO" "$f" --local-dir "$MODELS"
done

echo
echo "완료. 파일 목록:"
ls -lh "$MODELS"/*.gguf 2>/dev/null | awk '{print " ", $5, $9}'
