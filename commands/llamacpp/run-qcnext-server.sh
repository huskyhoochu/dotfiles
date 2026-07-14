#!/usr/bin/env bash
# Qwen3-Coder-Next 80B-A3B — llama.cpp Vulkan 서버 (MoE 인지형 배치)
# 어텐션·KV + 전문가 14개 레이어: GPU(~20GB) / 나머지 전문가: CPU RAM(mmap)
# 실측(GEM12, 2026-07-14): --n-cpu-moe 99 기준 decode 16.6~17.7 tok/s, prefill 67~90 tok/s.
#   ollama 단순 레이어 분할은 1.9 tok/s로 사용 불가 — MoE 인지형 배치가 9배 차이의 핵심.
# 튜닝: N_CPU_MOE(기본 34, 총 48레이어)를 낮출수록 GPU 몫 증가. VRAM 여유 3GB 이상 유지할 것
#   (데스크톱 렌더링 몫 — 부족하면 화면 멈춤).
# 전제: llama.cpp Vulkan 빌드 (cmake -B build -DGGML_VULKAN=ON), GGUF는 ~/Documents/models에.
BIN="$HOME/Documents/external_packages/llama.cpp/build/bin/llama-server"
N_CPU_MOE="${N_CPU_MOE:-34}"

exec "$BIN" \
  -m ~/Documents/models/Qwen3-Coder-Next-Q4_K_M.gguf \
  --alias qwen3-coder-next \
  --host 127.0.0.1 --port 8080 \
  -ngl 99 --n-cpu-moe "$N_CPU_MOE" \
  -c 65536 --jinja \
  --no-warmup
