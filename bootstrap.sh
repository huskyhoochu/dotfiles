#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

# 공통 패키지 (모든 플랫폼)
COMMON_PACKAGES=(zsh nvim tmux git ghostty fonts backgrounds claude pi)

# 플랫폼별 패키지
MACOS_PACKAGES=(aerospace)
LINUX_PACKAGES=(deskflow-linux)

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [ -f /etc/fedora-release ]; then
        echo "fedora"
      else
        echo "linux-unknown"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

install_packages() {
  local os="$1"
  echo "패키지 설치 중 (OS: $os)..."

  case "$os" in
    macos)
      bash "$DOTFILES_DIR/commands/install_deps_mac.sh"
      ;;
    fedora)
      bash "$DOTFILES_DIR/commands/install_deps_fedora.sh"
      ;;
    *)
      echo "경고: 지원되지 않는 OS입니다. 패키지 설치를 건너뜁니다."
      return 1
      ;;
  esac
}

deploy_dotfiles() {
  local os="$1"
  local packages=("${COMMON_PACKAGES[@]}")

  case "$os" in
    macos)
      packages+=("${MACOS_PACKAGES[@]}")
      ;;
    fedora)
      packages+=("${LINUX_PACKAGES[@]}")
      ;;
  esac

  echo "stow 배포 중: ${packages[*]}"

  local failed=()
  for pkg in "${packages[@]}"; do
    if [ -d "$DOTFILES_DIR/$pkg" ]; then
      if ! stow "$pkg"; then
        failed+=("$pkg")
      fi
    else
      echo "경고: $pkg 디렉토리가 없습니다. 건너뜁니다."
    fi
  done

  if [ ${#failed[@]} -gt 0 ]; then
    echo "실패한 패키지: ${failed[*]}"
    echo "stow -n <패키지>로 충돌을 확인하세요."
    return 1
  fi

  echo "배포 완료."
}

main() {
  local skip_install=false

  for arg in "$@"; do
    case "$arg" in
      --skip-install) skip_install=true ;;
      -h | --help)
        echo "사용법: $0 [--skip-install]"
        echo "  --skip-install  패키지 설치를 건너뛰고 stow 배포만 실행"
        exit 0
        ;;
      *)
        echo "알 수 없는 옵션: $arg"
        exit 1
        ;;
    esac
  done

  local os
  os="$(detect_os)"
  echo "감지된 OS: $os"

  if [ "$skip_install" = false ]; then
    install_packages "$os"
  else
    echo "패키지 설치 건너뜀 (--skip-install)"
  fi

  deploy_dotfiles "$os"
}

main "$@"
