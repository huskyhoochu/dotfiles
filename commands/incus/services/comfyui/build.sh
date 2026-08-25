#!/usr/bin/env bash
# ai 컨테이너에 ComfyUI 를 설치한다 — 배포(deploy.sh)와 분리된 준비 단계 (계획 §1-2)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다 — 버전은 항상 아래 REF 로 고정된다.
#   sudo ./build.sh
#
# 클라우드 전용 구성이다 (사용자 결정 2026-08-18): OpenRouter API 로 이미지 생성을
# 라우팅하고 로컬 모델은 받지 않는다. 그래서 torch 는 CPU 휠로 충분하고
# (ROCm 스택 수 GB 대비 가볍다), VRAM 을 쓰지 않아 glimmer/qwen 과 경합이 없다.
#
# venv 를 3.13 으로 만드는 이유: ai 의 기본 python 3.14(cp314)는 torch 생태계 휠이
# 아직 preview 수준이라 의존성(av 등)이 빠진다. cp313 휠은 전부 있다.
# 폴백(python3.13 리포 부재 시): dnf install python3-torch 후
# python3 -m venv --system-site-packages 로 만들고 requirements 중 실패 패키지만 확인.

source "$(dirname "$0")/../../lib.sh"

CONTAINER="ai"
COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI"
COMFYUI_REF="v0.33.2"                                    # 2026-08-18 최신 릴리스
NODE_REPO="https://github.com/gabe-init/ComfyUI-Openrouter_node"
NODE_REF="45c67f94e335b978577773f05752e17ffe63a09e"       # 2026-05-18 (커밋 고정)
NODE_DIR="/opt/comfyui/custom_nodes/ComfyUI-Openrouter_node"
PIP="/opt/comfyui/venv/bin/pip"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# 컨테이너 root 디스크는 16GiB — venv+torch 가 2GB 안팎이라 여유를 먼저 본다.
FREE_KB=$(incus exec "$CONTAINER" -- df --output=avail / | tail -1 | tr -dc '0-9')
[ "$FREE_KB" -ge $((4 * 1024 * 1024)) ] \
  || die "ai root disk has <4GiB free. Clean up first (podman system prune, dnf clean all)."

# ── 도구·인터프리터 ─────────────────────────────────────────────────

log "Installing python3.13 + git"
incus exec "$CONTAINER" -- dnf install -y -q python3.13 git

# ── ComfyUI 본체 ────────────────────────────────────────────────────

if incus exec "$CONTAINER" -- test -d /opt/comfyui/.git; then
  skip "ComfyUI already cloned"
else
  log "Cloning ComfyUI"
  incus exec "$CONTAINER" -- git clone -q "$COMFYUI_REPO" /opt/comfyui
fi
incus exec "$CONTAINER" -- git -C /opt/comfyui fetch -q --tags
incus exec "$CONTAINER" -- git -C /opt/comfyui checkout -q "$COMFYUI_REF"
log "ComfyUI at ${COMFYUI_REF}"

# ── venv + 의존성 ───────────────────────────────────────────────────

if incus exec "$CONTAINER" -- test -x /opt/comfyui/venv/bin/python; then
  skip "venv already present"
else
  log "Creating python3.13 venv"
  incus exec "$CONTAINER" -- python3.13 -m venv /opt/comfyui/venv
fi

log "Installing CPU torch + requirements (first run downloads ~2GB)"
incus exec "$CONTAINER" -- "$PIP" install -q --upgrade pip
incus exec "$CONTAINER" -- "$PIP" install -q \
  torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
incus exec "$CONTAINER" -- "$PIP" install -q -r /opt/comfyui/requirements.txt

# ── OpenRouter custom node ──────────────────────────────────────────

if incus exec "$CONTAINER" -- test -d "${NODE_DIR}/.git"; then
  skip "OpenRouter node already cloned"
else
  log "Cloning ComfyUI-Openrouter_node"
  incus exec "$CONTAINER" -- git clone -q "$NODE_REPO" "$NODE_DIR"
fi
incus exec "$CONTAINER" -- git -C "$NODE_DIR" fetch -q
incus exec "$CONTAINER" -- git -C "$NODE_DIR" checkout -q "$NODE_REF"
incus exec "$CONTAINER" -- bash -c \
  "[ -f ${NODE_DIR}/requirements.txt ] && ${PIP} install -q -r ${NODE_DIR}/requirements.txt || true"
log "OpenRouter node at ${NODE_REF:0:12}"

# ── 자작 OpenRouter 미디어 노드 (Seedream·Seedance) ─────────────────
# 챗 완성 노드가 못 부르는 전용 엔드포인트(/api/v1/images·/videos)용.
# 소스가 이 저장소에 있으므로 push 가 곧 버전 고정이다.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
incus exec "$CONTAINER" -- mkdir -p /opt/comfyui/custom_nodes/openrouter_media
incus file push "${SCRIPT_DIR}/openrouter-media/__init__.py" \
  "${CONTAINER}/opt/comfyui/custom_nodes/openrouter_media/__init__.py"
log "openrouter_media nodes deployed (Seedream image + Seedance video)"

echo
log "Done. Next: deploy.sh (환경 파일 /etc/comfyui.env 준비 후)"
