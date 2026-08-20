#!/usr/bin/env bash
# ai 컨테이너에 llama.cpp 를 Vulkan 백엔드로 빌드한다
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./build.sh
#
# Vulkan 을 쓰는 이유는 docs/gem12/operations.md §5 에 있다.
# 요약하면 RDNA3 는 RADV 드라이버로 충분하고, ROCm 전체 스택이 필요 없다.

source "$(dirname "$0")/../../lib.sh"

CONTAINER="ai"
SRC="/opt/llama.cpp"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# ── 빌드 도구 ───────────────────────────────────────────────────────
# glslc 는 llama.cpp 가 GPU 커널을 GLSL 로 두고 빌드 때 SPIR-V 로 컴파일하기
# 때문에 필요하다. spirv-headers-devel 이 빠지면 cmake 구성 단계에서 멈춘다.

log "Installing build tools"
incus exec "$CONTAINER" -- bash -c 'dnf install -y -q \
  git cmake gcc-c++ ninja-build libcurl-devel \
  vulkan-headers vulkan-loader-devel glslc glslang \
  spirv-headers-devel spirv-tools-devel >/dev/null'

# ── 소스 ────────────────────────────────────────────────────────────

if incus exec "$CONTAINER" -- test -d "$SRC"; then
  skip "llama.cpp already cloned"
else
  log "Cloning llama.cpp"
  incus exec "$CONTAINER" -- git clone -q --depth 1 \
    https://github.com/ggml-org/llama.cpp "$SRC"
fi

# ── 빌드 ────────────────────────────────────────────────────────────

log "Configuring (Vulkan)"
incus exec "$CONTAINER" -- cmake -B "${SRC}/build" -S "$SRC" \
  -DGGML_VULKAN=ON -DLLAMA_CURL=ON -DCMAKE_BUILD_TYPE=Release -G Ninja >/dev/null

log "Building (this takes several minutes)"
incus exec "$CONTAINER" -- cmake --build "${SRC}/build" --config Release -j "$(nproc)" >/dev/null

# ── 검증 ────────────────────────────────────────────────────────────

incus exec "$CONTAINER" -- test -x "${SRC}/build/bin/llama-server" \
  || die "llama-server was not produced"

log "GPU detected by llama.cpp:"
incus exec "$CONTAINER" -- "${SRC}/build/bin/llama-server" --list-devices 2>&1 \
  | grep -i vulkan | sed 's/^/  /'

echo
log "Done. Next: download.sh (weights), then deploy.sh"
