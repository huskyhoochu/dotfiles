#!/usr/bin/env bash
# Muse Glimmer 30B — llama.cpp Vulkan 서버 (DFlash 추측 디코딩)
# 밀집 모델(52레이어, MoE 아님)이라 전 레이어를 GPU 에 올린다. KV 는 GQA(KV헤드 2개)
# + sliding window 2048(39/52 레이어)이라 매우 가볍다 — 128k 도 q8_0 기준 0.9GB.
# VRAM 예산(GEM12, 실측 2026-08-14): 총 24560MiB. Vivaldi·유튜브·Slack 을 함께 띄운
#   상태에서 이 구성(128k, q8_0, drafter 포함)의 점유가 21734MiB, 여유 2826MiB 였다.
#   (64k 였을 때는 20853MiB / 3707MiB. 늘어난 몫의 절반은 KV, 절반은 슬롯 4개분 버퍼다.)
# 튜닝: CTX 를 키워도 KV 만 늘고 그 폭이 작다 — 64k 0.48G, 128k 0.91G, 256k 1.79G.
#   컨텍스트를 줄이는 것보다 DRAFT= 로 drafter(1.63G)를 빼는 쪽이 회수량이 훨씬 크다.
#   192k 이상은 여유가 2.3G 아래로 떨어지고 학습된 max_position_embeddings(131072)도 넘는다.
#   VRAM 여유 3GB 이상 유지할 것 (데스크톱 렌더링 몫 — 부족하면 화면 멈춤).
# 실측 성능: 생성 29~68 tok/s(툴 호출처럼 정형화된 출력일수록 DFlash 채택률이 올라 빠름),
#   프롬프트 처리 620~790 tok/s. 비교: Qwen3-Coder-Next 80B(CPU 오프로드)는 17 / 90 tok/s.
# 전제: llama.cpp Vulkan 빌드 (cmake -B build -DGGML_VULKAN=ON), GGUF 는 ~/Documents/models 에.
BIN="$HOME/Documents/external_packages/llama.cpp/build/bin/llama-server"
MODELS="$HOME/Documents/models"
CTX="${CTX:-131072}"
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
