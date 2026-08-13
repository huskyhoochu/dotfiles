#!/usr/bin/env bash
# Muse Glimmer 30B — llama.cpp Vulkan 서버 (DFlash 추측 디코딩)
# 밀집 모델(52레이어, MoE 아님)이라 전 레이어를 GPU 에 올린다. KV 는 GQA(KV헤드 2개)
# + sliding window 2048(39/52 레이어)이라 매우 가볍다 — 128k 도 q8_0 기준 0.9GB.
# VRAM 예산(GEM12, 실측 2026-08-14): 총 24560MiB 중 데스크톱이 2.2GB 상주 → 가용 약 21.8GB.
#   이 구성(64k, q8_0, drafter 포함)의 실측 점유는 20853MiB, 여유 3707MiB.
# 튜닝: CTX 를 키우면 KV 만 늘어난다(128k 여도 +0.4G). 여유가 부족하면 DRAFT= 를 비워
#   drafter(1.63G)를 빼는 쪽이 컨텍스트를 줄이는 것보다 효과가 크다.
#   VRAM 여유 3GB 이상 유지할 것 (데스크톱 렌더링 몫 — 부족하면 화면 멈춤).
# 실측 성능: 생성 29~68 tok/s(툴 호출처럼 정형화된 출력일수록 DFlash 채택률이 올라 빠름),
#   프롬프트 처리 620~790 tok/s. 비교: Qwen3-Coder-Next 80B(CPU 오프로드)는 17 / 90 tok/s.
# 전제: llama.cpp Vulkan 빌드 (cmake -B build -DGGML_VULKAN=ON), GGUF 는 ~/Documents/models 에.
BIN="$HOME/Documents/external_packages/llama.cpp/build/bin/llama-server"
MODELS="$HOME/Documents/models"
CTX="${CTX:-65536}"
DRAFT="${DRAFT:-$MODELS/dflash-Muse-Glimmer-30B-Q4_K_M.gguf}"

# DFlash: 블록 확산 방식 초안 모델. 한 번의 forward 로 블록 전체를 제안하고 본 모델이
# 병렬 검증한다 — 출력 품질은 동일하고 속도만 오른다. n-max 는 학습된 블록 크기로 클램프됨.
SPEC_ARGS=()
if [ -n "$DRAFT" ] && [ -f "$DRAFT" ]; then
  SPEC_ARGS=(-md "$DRAFT" --spec-type draft-dflash --spec-draft-n-max 15)
fi

exec "$BIN" \
  -m "$MODELS/Muse-Glimmer-30B-KQuant-17GB-Q4_K_M.gguf" \
  --alias muse-glimmer \
  --host 127.0.0.1 --port 8081 \
  -dev Vulkan0 \
  -ngl 99 \
  -c "$CTX" \
  -fa on -ctk q8_0 -ctv q8_0 \
  "${SPEC_ARGS[@]}" \
  --jinja \
  --no-warmup
