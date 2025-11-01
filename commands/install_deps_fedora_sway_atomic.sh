#!/bin/bash

# Fedora Sway Atomic 패키지 설치 스크립트
# rpm-ostree를 사용하여 packages_fedora_sway_atomic.txt의 패키지들을 설치합니다

# 로그 파일 설정
LOG_FILE="fedora_sway_atomic_install_$(date +%Y%m%d_%H%M%S).log"

# 로깅 함수
log() {
  local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "$message" | tee -a "$LOG_FILE"
}

# 오류 처리 함수
handle_error() {
  log "오류 발생: $1"
  exit 1
}

# rpm-ostree 시스템 확인
check_rpm_ostree() {
  if ! command -v rpm-ostree &>/dev/null; then
    handle_error "rpm-ostree를 찾을 수 없습니다. 이 스크립트는 Fedora Atomic 시스템에서만 작동합니다."
  fi
  log "rpm-ostree 시스템 확인됨"
}

# 스크립트가 root 권한으로 실행되는지 확인
check_root() {
  if [ "$EUID" -eq 0 ]; then
    log "경고: 이 스크립트를 root로 실행하지 마세요. sudo는 필요시 자동으로 요청됩니다."
    exit 1
  fi
}

# 입력 파일 확인
check_input_file() {
  if [ ! -f "packages_fedora_sway_atomic.txt" ]; then
    handle_error "packages_fedora_sway_atomic.txt 파일을 찾을 수 없습니다."
  fi
}

# 시스템 업데이트
update_system() {
  log "시스템 업데이트를 시작합니다..."
  rpm-ostree upgrade || log "시스템 업데이트 실패 (계속 진행)"
}

# RPM Fusion 리포지토리 활성화 (선택사항)
enable_rpmfusion() {
  log "RPM Fusion 리포지토리 활성화 여부를 확인합니다..."
  if ! ostree remote list | grep -q rpmfusion; then
    read -p "RPM Fusion 리포지토리를 활성화하시겠습니까? (멀티미디어 코덱 및 추가 패키지 제공) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log "RPM Fusion Free 및 Nonfree 리포지토리를 활성화합니다..."
      sudo rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || log "RPM Fusion 설치 실패 (계속 진행)"
      log "RPM Fusion 설치를 위해 재부팅이 필요합니다."
      read -p "지금 재부팅하시겠습니까? [y/N]: " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl reboot
        exit 0
      fi
    fi
  else
    log "RPM Fusion 리포지토리가 이미 활성화되어 있습니다."
  fi
}

# 패키지 목록 추출 및 일괄 설치
install_packages() {
  local packages_to_install=()
  local skipped_packages=()
  local total_packages=0

  # 패키지 목록 추출
  log "패키지 목록을 추출합니다..."
  while IFS= read -r package || [[ -n "$package" ]]; do
    # 주석과 빈 줄 건너뛰기
    [[ -z "$package" || "$package" =~ ^#.*$ ]] && continue

    # 앞뒤 공백 제거
    package=$(echo "$package" | xargs)

    # 패키지가 이미 설치되어 있는지 확인
    if rpm -qa | grep -q "^$package-"; then
      log "이미 설치됨: $package"
      skipped_packages+=("$package")
    else
      packages_to_install+=("$package")
    fi

    ((total_packages++))
  done <packages_fedora_sway_atomic.txt

  log "총 $total_packages 개의 패키지 중 ${#packages_to_install[@]} 개를 설치합니다."

  # rpm-ostree로 일괄 설치
  if [ ${#packages_to_install[@]} -gt 0 ]; then
    log "rpm-ostree를 사용하여 패키지를 설치합니다..."
    log "설치할 패키지: ${packages_to_install[*]}"

    if sudo rpm-ostree install "${packages_to_install[@]}"; then
      log "패키지 설치가 완료되었습니다."
      log ""
      log "⚠️  중요: 설치된 패키지를 사용하려면 재부팅이 필요합니다."
      log "    재부팅 명령: systemctl reboot"
    else
      log "경고: 일부 패키지 설치가 실패했습니다."
      log "개별 패키지를 수동으로 설치해야 할 수 있습니다."
    fi
  else
    log "설치할 새 패키지가 없습니다."
  fi

  # 설치 결과 보고
  echo ""
  log "==================== 설치 완료 보고 ===================="

  if [ ${#skipped_packages[@]} -gt 0 ]; then
    log "이미 설치되어 있던 패키지 (${#skipped_packages[@]}개):"
    printf '  - %s\n' "${skipped_packages[@]}" | tee -a "$LOG_FILE"
    echo ""
  fi

  log "========================================================"
}

# Flatpak 앱 설치 안내
print_flatpak_instructions() {
  log ""
  log "==================== Flatpak 앱 설치 권장 ===================="
  log "Fedora Atomic에서는 GUI 애플리케이션을 Flatpak으로 설치하는 것을 권장합니다:"
  log ""
  log "1. Obsidian (메모 앱):"
  log "   flatpak install flathub md.obsidian.Obsidian"
  log ""
  log "2. Spotify:"
  log "   flatpak install flathub com.spotify.Client"
  log ""
  log "3. 1Password:"
  log "   Flatpak 또는 RPM: https://1password.com/downloads/linux/"
  log ""
  log "4. VS Code:"
  log "   flatpak install flathub com.visualstudio.code"
  log ""
  log "5. Discord:"
  log "   flatpak install flathub com.discordapp.Discord"
  log ""
  log "Flatpak 검색: flatpak search <앱이름>"
  log "============================================================="
}

# COPR 및 수동 설치 안내
print_manual_instructions() {
  log ""
  log "==================== COPR/수동 설치 필요 ===================="
  log "다음 패키지들은 COPR 또는 수동 설치가 필요합니다:"
  log ""
  log "1. lazygit (Git TUI):"
  log "   sudo dnf copr enable atim/lazygit"
  log "   rpm-ostree install lazygit"
  log "   또는: https://github.com/jesseduffield/lazygit/releases"
  log ""
  log "2. oh-my-posh (프롬프트 테마):"
  log "   sudo dnf copr enable chronoscrat/oh-my-posh"
  log "   rpm-ostree install oh-my-posh"
  log ""
  log "3. swaylock-effects (화면 잠금 이펙트):"
  log "   sudo dnf copr enable eddsalkield/swaylock-effects"
  log "   rpm-ostree install swaylock-effects"
  log "   (또는 기본 swaylock 사용)"
  log ""
  log "4. ghostty (터미널):"
  log "   - GitHub에서 소스 빌드 또는 COPR 검색"
  log "   - 대안: 기본 포함된 foot 사용"
  log ""
  log "5. Nerd Fonts (아이콘 폰트):"
  log "   - https://www.nerdfonts.com/font-downloads"
  log "   - 다운로드 후 ~/.local/share/fonts/ 에 복사"
  log "   - fc-cache -fv 실행"
  log ""
  log "6. spicetify-cli (Spotify 테마):"
  log "   - npm install -g spicetify-cli"
  log "   - 또는: curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh"
  log ""
  log "============================================================="
}

# Toolbox 사용 안내
print_toolbox_instructions() {
  log ""
  log "==================== Toolbox 사용 안내 ===================="
  log "개발 도구는 Toolbox 컨테이너에서 사용하는 것을 권장합니다:"
  log ""
  log "Toolbox 생성:"
  log "  toolbox create"
  log ""
  log "Toolbox 진입:"
  log "  toolbox enter"
  log ""
  log "Toolbox 내부에서 일반 dnf 명령 사용 가능:"
  log "  sudo dnf install nodejs python3-pip golang"
  log ""
  log "============================================================="
}

# 메인 실행 부분
main() {
  log "Fedora Sway Atomic 패키지 설치 스크립트를 시작합니다..."
  log "Fedora 버전: $(rpm -E %fedora)"
  log "OSTree 커밋: $(rpm-ostree status --json | grep -oP '\"checksum\":\s*\"\K[^\"]+' | head -1)"
  log ""

  check_root
  check_rpm_ostree
  check_input_file
  update_system
  enable_rpmfusion
  install_packages
  print_flatpak_instructions
  print_manual_instructions
  print_toolbox_instructions

  log ""
  log "설치 작업이 완료되었습니다."
  log "로그 파일: $LOG_FILE"
  log ""
  log "다음 단계:"
  log "1. 재부팅하여 설치된 패키지 적용: systemctl reboot"
  log "2. 위의 Flatpak 앱 설치 안내 참고"
  log "3. GNU Stow로 dotfiles 배포: cd ~/dotfiles && stow sway zsh tmux nvim"
  log "4. Sway는 이미 설치되어 있으므로 로그아웃 후 Sway 세션 선택"
}

# 스크립트 실행
main
