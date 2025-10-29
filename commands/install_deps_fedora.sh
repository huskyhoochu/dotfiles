#!/bin/bash

# Fedora 패키지 설치 스크립트
# dnf를 사용하여 packages_fedora.txt의 패키지들을 설치합니다

# 로그 파일 설정
LOG_FILE="fedora_install_$(date +%Y%m%d_%H%M%S).log"

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

# 스크립트가 root 권한으로 실행되는지 확인
check_root() {
  if [ "$EUID" -eq 0 ]; then
    log "경고: 이 스크립트를 root로 실행하지 마세요. sudo는 필요시 자동으로 요청됩니다."
    exit 1
  fi
}

# 입력 파일 확인
check_input_file() {
  if [ ! -f "packages_fedora.txt" ]; then
    handle_error "packages_fedora.txt 파일을 찾을 수 없습니다."
  fi
}

# 시스템 업데이트
update_system() {
  log "시스템 업데이트를 시작합니다..."
  sudo dnf update -y || handle_error "시스템 업데이트 실패"
}

# RPM Fusion 리포지토리 활성화 (선택사항)
enable_rpmfusion() {
  log "RPM Fusion 리포지토리 활성화 여부를 확인합니다..."
  if ! dnf repolist | grep -q rpmfusion; then
    read -p "RPM Fusion 리포지토리를 활성화하시겠습니까? (멀티미디어 코덱 및 추가 패키지 제공) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log "RPM Fusion Free 및 Nonfree 리포지토리를 활성화합니다..."
      sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || log "RPM Fusion 설치 실패 (계속 진행)"
    fi
  else
    log "RPM Fusion 리포지토리가 이미 활성화되어 있습니다."
  fi
}

# 패키지 설치 함수
install_packages() {
  local failed_packages=()
  local skipped_packages=()

  # 패키지 개수 확인
  local total_packages=$(grep -v '^#' packages_fedora.txt | grep -v '^$' | wc -l)
  log "총 $total_packages 개의 패키지를 설치합니다."

  # 각 패키지 설치
  while IFS= read -r package || [[ -n "$package" ]]; do
    # 주석과 빈 줄 건너뛰기
    [[ -z "$package" || "$package" =~ ^#.*$ ]] && continue

    # 앞뒤 공백 제거
    package=$(echo "$package" | xargs)

    log "설치 중: $package"

    # 패키지가 이미 설치되어 있는지 확인
    if dnf list installed "$package" &>/dev/null; then
      log "이미 설치됨: $package"
      skipped_packages+=("$package")
      continue
    fi

    # 패키지 설치 시도
    if sudo dnf install -y "$package"; then
      log "설치 완료: $package"
    else
      log "경고: $package 설치 실패"
      failed_packages+=("$package")
    fi
  done <packages_fedora.txt

  # 설치 결과 보고
  echo ""
  log "==================== 설치 완료 보고 ===================="

  if [ ${#skipped_packages[@]} -gt 0 ]; then
    log "이미 설치되어 있던 패키지 (${#skipped_packages[@]}개):"
    printf '  - %s\n' "${skipped_packages[@]}" | tee -a "$LOG_FILE"
    echo ""
  fi

  if [ ${#failed_packages[@]} -eq 0 ]; then
    log "모든 패키지가 성공적으로 설치되었습니다."
  else
    log "다음 패키지들의 설치가 실패했습니다 (${#failed_packages[@]}개):"
    printf '  - %s\n' "${failed_packages[@]}" | tee -a "$LOG_FILE"
    echo ""
    log "실패한 패키지들은 수동으로 설치하거나 대안을 찾아야 할 수 있습니다."
  fi
  log "======================================================="
}

# 추가 수동 설치 안내
print_manual_instructions() {
  log ""
  log "==================== 수동 설치 필요 ===================="
  log "다음 패키지들은 Fedora 기본 리포지토리에 없어 수동 설치가 필요합니다:"
  log ""
  log "1. swaylock-effects (화면 잠금 이펙트):"
  log "   sudo dnf copr enable eddsalkield/swaylock-effects"
  log "   sudo dnf install swaylock-effects"
  log "   (또는 기본 swaylock 사용 시 sway config에서 'swaylock-effects' → 'swaylock' 변경)"
  log ""
  log "2. oh-my-posh (프롬프트 테마):"
  log "   sudo dnf copr enable chronoscrat/oh-my-posh"
  log "   sudo dnf install oh-my-posh"
  log ""
  log "3. ghostty (터미널):"
  log "   - GitHub에서 소스 빌드 또는 COPR 검색"
  log "   - 대안: alacritty, kitty (dnf로 설치 가능)"
  log ""
  log "4. lazygit (Git TUI):"
  log "   sudo dnf copr enable atim/lazygit"
  log "   sudo dnf install lazygit"
  log "   또는: https://github.com/jesseduffield/lazygit/releases"
  log ""
  log "5. Nerd Fonts (아이콘 폰트):"
  log "   - https://www.nerdfonts.com/font-downloads"
  log "   - 다운로드 후 ~/.local/share/fonts/ 에 복사"
  log "   - fc-cache -fv 실행"
  log ""
  log "6. 1Password (비밀번호 관리자):"
  log "   - https://1password.com/downloads/linux/"
  log "   - RPM 패키지 다운로드 및 설치"
  log "   - (Fedora 43: XWayland를 통해 실행됨)"
  log ""
  log "7. Dropbox:"
  log "   - https://www.dropbox.com/install-linux"
  log "   - Fedora RPM 다운로드"
  log "   - (Fedora 43: XWayland를 통해 실행됨)"
  log ""
  log "8. Obsidian (메모 앱):"
  log "   - Flatpak: flatpak install flathub md.obsidian.Obsidian"
  log "   - 또는 AppImage 다운로드"
  log ""
  log "9. Spotify:"
  log "   - Flatpak: flatpak install flathub com.spotify.Client"
  log "   - 또는 RPM Fusion: sudo dnf install lpf-spotify-client"
  log ""
  log "10. spicetify-cli (Spotify 테마):"
  log "   - npm install -g spicetify-cli"
  log "   - 또는: curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh"
  log ""
  log "======================================================="
}

# 캐시 정리
clean_cache() {
  log "패키지 캐시를 정리합니다..."
  sudo dnf clean all || log "캐시 정리 중 오류 발생"
}

# 메인 실행 부분
main() {
  log "Fedora 패키지 설치 스크립트를 시작합니다..."
  log "Fedora 버전: $(rpm -E %fedora)"
  log ""

  check_root
  check_input_file
  update_system
  enable_rpmfusion
  install_packages
  print_manual_instructions
  clean_cache

  log ""
  log "설치 작업이 완료되었습니다."
  log "로그 파일: $LOG_FILE"
  log ""
  log "다음 단계:"
  log "1. 위의 수동 설치 안내를 참고하여 추가 패키지 설치"
  log "2. GNU Stow로 dotfiles 배포: cd ~/dotfiles && stow sway zsh tmux nvim"
  log "3. 로그아웃 후 Sway 세션 선택"
}

# 스크립트 실행
main
