#!/usr/bin/env bash
# 컨테이너별 런타임 설치
#
# containers.conf 의 런타임 열을 보고 Docker 또는 Podman 을 넣는다.
# 하나로 통일하지 않는 이유는 docs/gem12/operations.md §5 에 있다.
# 요약하면 CI와 앱은 기존 compose 자산과 Actions Runner 때문에 Docker 이고,
# core/ai/media 는 systemd 직접 관리와 rootless GPU 접근 때문에 Podman 이다.

source "$(dirname "$0")/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

require_root
require_incus

# ── Docker ──────────────────────────────────────────────────────────

install_docker() {
  local name="$1"

  if incus exec "$name" -- command -v docker >/dev/null 2>&1; then
    skip "${name}: Docker already installed"
    # 설치는 됐는데 데몬이 죽어 있던 경우(재실행 시나리오)를 살린다.
    incus exec "$name" -- systemctl enable --now docker >/dev/null 2>&1 \
      || warn "${name}: docker.service failed to start - check journalctl -u docker"
    return
  fi

  log "${name}: Installing Docker"

  incus exec "$name" -- bash -c '
    set -e
    dnf install -y -q dnf-plugins-core >/dev/null
    dnf config-manager addrepo \
      --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo \
      --overwrite >/dev/null
    dnf install -y -q \
      docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin >/dev/null
    systemctl enable --now docker
  '

  log "${name}: Docker $(incus exec "$name" -- docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
}

# ── Podman ──────────────────────────────────────────────────────────

install_podman() {
  local name="$1" gpu="$2"

  if incus exec "$name" -- command -v podman >/dev/null 2>&1; then
    skip "${name}: Podman already installed"
  else
    log "${name}: Installing Podman"
    # Podman 은 Fedora 의 1급 시민이다. 저장소 추가 없이 바로 깔린다.
    incus exec "$name" -- bash -c 'dnf install -y -q podman podman-compose >/dev/null'
  fi

  # Quadlet 디렉토리 — .container 파일을 두면 systemd 가 서비스로 다룬다.
  incus exec "$name" -- mkdir -p /etc/containers/systemd

  # 컨테이너를 systemd 가 관리하므로 부팅 시 자동 기동된다.
  incus exec "$name" -- systemctl enable podman-restart >/dev/null 2>&1 || true

  # ── GPU 컨테이너 추가 설정 ──────────────────────────────────────
  if [ "$gpu" != "none" ]; then
    log "${name}: Installing GPU userspace (${gpu})"

    # Vulkan 백엔드를 쓰므로 Mesa RADV 와 로더만 있으면 된다.
    # ROCm 전체 스택은 필요하지 않다 — llama.cpp 가 -dev Vulkan0 로 돈다.
    incus exec "$name" -- bash -c '
      set -e
      dnf install -y -q \
        mesa-vulkan-drivers vulkan-tools \
        mesa-va-drivers libva-utils >/dev/null
    '

    # 780M VAAPI 트랜스코딩(H.264/HEVC)은 코덱이 빠진 Fedora 기본 Mesa 로는
    # 안 된다. RPM Fusion 의 freeworld 드라이버로 바꾼다.
    if [ "$gpu" = "igpu" ]; then
      log "${name}: Installing RPM Fusion freeworld VAAPI driver"
      # RPM Fusion 이 Fedora 의 mesa 업데이트를 리빌드로 따라잡기 전에는
      # 버전 불일치로 실패한다. 트랜스코딩은 Jellyfin 구축 시점에나 필요하므로
      # 실패해도 진행하고, 나중에 이 명령을 다시 실행한다.
      incus exec "$name" -- bash -c '
        set -e
        dnf install -y -q \
          "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" >/dev/null
        dnf swap -y -q mesa-va-drivers mesa-va-drivers-freeworld >/dev/null
      ' || warn "${name}: freeworld swap failed - RPM Fusion rebuild lag. Retry before setting up Jellyfin: dnf swap mesa-va-drivers mesa-va-drivers-freeworld"
    fi

    log "${name}: Verifying GPU"
    if incus exec "$name" -- sh -c 'ls /dev/dri/renderD* >/dev/null 2>&1'; then
      incus exec "$name" -- vulkaninfo --summary 2>/dev/null \
        | grep -E 'deviceName|driverName' | head -4 \
        || warn "${name}: vulkaninfo failed - check GPU config in 03-containers.sh"
    else
      warn "${name}: no /dev/dri render node. Check container config."
    fi
  fi
}

# ── 실행 ────────────────────────────────────────────────────────────

# 정의 파일은 fd 3 으로 읽는다. incus exec 가 stdin 을 소비하면
# 다음 줄을 삼켜버리기 때문이다 (03-containers.sh 와 동일).
while read -r -u3 NAME CORES MEM IP RUNTIME GPU COLOR; do
  echo
  log "-- ${NAME} --"

  container_exists "$NAME" || { warn "${NAME} missing. Run 03-containers.sh first."; continue; }
  ensure_running "$NAME"

  case "$RUNTIME" in
    docker) install_docker "$NAME" ;;
    podman) install_podman "$NAME" "$GPU" ;;
    *) warn "${NAME}: unknown runtime '${RUNTIME}'" ;;
  esac
done 3< <(read_containers "${SCRIPT_DIR}/containers.conf")

echo
log "Done."
echo
echo "Next: deploy services inside each container."
echo "  incus exec core -- bash    # core  - Forgejo"
echo "  incus exec ai -- bash      # ai    - llama.cpp, ComfyUI"
echo
echo "Build order: docs/gem12/build-history.md"
