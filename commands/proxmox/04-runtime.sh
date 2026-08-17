#!/usr/bin/env bash
# 컨테이너별 런타임 설치
#
# containers.conf 의 런타임 열을 보고 Docker 또는 Podman 을 넣는다.
# 하나로 통일하지 않는 이유는 docs/gem12-private-cloud-plan-2026-08-17.md §4 에 있다.
# 요약하면 CI와 앱은 기존 compose 자산과 Actions Runner 때문에 Docker 이고,
# core/ai/media 는 systemd 직접 관리와 rootless GPU 접근 때문에 Podman 이다.

source "$(dirname "$0")/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

require_root
require_proxmox

# ── Docker ──────────────────────────────────────────────────────────

install_docker() {
  local id="$1" name="$2"

  if pct exec "$id" -- command -v docker >/dev/null 2>&1; then
    skip "${name}: Docker 가 이미 있다"
    return
  fi

  log "${name}: Docker 설치"

  pct exec "$id" -- bash -c '
    set -e
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg >/dev/null

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg \
      -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    cat >/etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    apt-get update -qq
    apt-get install -y -qq \
      docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin >/dev/null

    systemctl enable --now docker
  '

  log "${name}: Docker $(pct exec "$id" -- docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
}

# ── Podman ──────────────────────────────────────────────────────────

install_podman() {
  local id="$1" name="$2" gpu="$3"

  if pct exec "$id" -- command -v podman >/dev/null 2>&1; then
    skip "${name}: Podman 이 이미 있다"
  else
    log "${name}: Podman 설치"
    pct exec "$id" -- bash -c '
      set -e
      apt-get update -qq
      apt-get install -y -qq podman podman-compose uidmap slirp4netns >/dev/null
    '
  fi

  # Quadlet 디렉토리 — .container 파일을 두면 systemd 가 서비스로 다룬다.
  pct exec "$id" -- mkdir -p /etc/containers/systemd

  # 컨테이너를 systemd 가 관리하므로 부팅 시 자동 기동된다.
  pct exec "$id" -- systemctl enable podman-restart >/dev/null 2>&1 || true

  # ── GPU 컨테이너 추가 설정 ──────────────────────────────────────
  if [ "$gpu" != "none" ]; then
    log "${name}: GPU 사용자 공간 설치 (${gpu})"

    # Vulkan 백엔드를 쓰므로 Mesa RADV 와 로더만 있으면 된다.
    # ROCm 전체 스택은 필요하지 않다 — llama.cpp 가 -dev Vulkan0 로 돈다.
    pct exec "$id" -- bash -c '
      set -e
      apt-get install -y -qq \
        mesa-vulkan-drivers vulkan-tools libvulkan1 \
        mesa-va-drivers vainfo >/dev/null
    '

    log "${name}: GPU 인식 확인"
    if pct exec "$id" -- test -e /dev/dri/renderD128; then
      pct exec "$id" -- vulkaninfo --summary 2>/dev/null \
        | grep -E 'deviceName|driverName' | head -4 \
        || warn "${name}: vulkaninfo 실패 — 03-containers.sh 의 GPU 설정을 확인하라"
    else
      warn "${name}: /dev/dri/renderD128 이 없다. 컨테이너 설정을 확인하라."
    fi
  fi
}

# ── 실행 ────────────────────────────────────────────────────────────

while read -r ID NAME CORES MEM IP RUNTIME GPU COLOR; do
  echo
  log "── ${NAME} (ID ${ID}) ──"

  container_exists "$ID" || { warn "${NAME} 이 없다. 03-containers.sh 를 먼저 실행하라."; continue; }
  pct status "$ID" | grep -q running || pct start "$ID"

  case "$RUNTIME" in
    docker) install_docker "$ID" "$NAME" ;;
    podman) install_podman "$ID" "$NAME" "$GPU" ;;
    *) warn "${NAME}: 알 수 없는 런타임 '${RUNTIME}'" ;;
  esac
done < <(read_containers "${SCRIPT_DIR}/containers.conf")

echo
log "완료."
echo
echo "다음 단계는 각 컨테이너에 서비스를 올리는 것이다."
echo "  pct enter 111    # core  — Forgejo, Headscale"
echo "  pct enter 114    # ai    — llama.cpp, ComfyUI"
echo
echo "구축 순서는 docs/gem12-private-cloud-plan-2026-08-17.md §8 을 따른다."
