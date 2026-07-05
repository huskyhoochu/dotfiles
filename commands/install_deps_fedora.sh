#!/bin/bash

# Fedora 44 패키지 설치 스크립트
# packages_fedora.txt의 섹션(dnf: / brew: / repo:)별로 패키지를 설치합니다

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

# packages_fedora.txt에서 특정 섹션의 항목만 추출
# 섹션 헤더는 "dnf:", "brew:", "repo:" 형식
parse_section() {
  local section="$1"
  awk -v target="$section" '
    /^[a-z]+:$/ { current = substr($0, 1, length($0) - 1); next }
    /^#/ || /^[[:space:]]*$/ { next }
    current == target { print }
  ' packages_fedora.txt
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

# dnf 패키지 하나 설치 (이미 설치됐으면 건너뜀). 실패 시 1 반환
dnf_install_one() {
  local package="$1"
  if dnf list installed "$package" &>/dev/null; then
    log "이미 설치됨: $package"
    return 0
  fi
  if sudo dnf install -y "$package"; then
    log "설치 완료: $package"
  else
    log "경고: $package 설치 실패"
    return 1
  fi
}

# dnf: 섹션 — Fedora 공식 리포지토리 패키지
install_dnf_packages() {
  local failed_packages=()
  local packages
  packages=$(parse_section dnf)

  local total
  total=$(echo "$packages" | grep -c .)
  log "==================== dnf (공식 리포) ===================="
  log "총 $total 개의 패키지를 설치합니다."

  while IFS= read -r package; do
    [ -z "$package" ] && continue
    package=$(echo "$package" | xargs)
    log "설치 중: $package"
    dnf_install_one "$package" || failed_packages+=("$package")
  done <<<"$packages"

  if [ ${#failed_packages[@]} -gt 0 ]; then
    log "dnf 설치 실패 (${#failed_packages[@]}개):"
    printf '  - %s\n' "${failed_packages[@]}" | tee -a "$LOG_FILE"
  else
    log "dnf 패키지가 모두 설치되었습니다."
  fi
}

# repo: 섹션 — 추가 리포지토리 등록 후 dnf 설치
# 줄 형식: "copr:<user>/<project> <package>" 또는 "<repo파일 URL> <package>"
install_repo_packages() {
  log "==================== repo (추가 리포지토리) ===================="

  while read -r spec package; do
    [ -z "$package" ] && continue

    if [[ "$spec" == copr:* ]]; then
      local copr_repo="${spec#copr:}"
      log "COPR 활성화: $copr_repo"
      if ! sudo dnf copr enable -y "$copr_repo"; then
        log "경고: COPR 활성화 실패: $copr_repo ($package 건너뜀)"
        continue
      fi
    else
      local repo_file="/etc/yum.repos.d/$(basename "$spec")"
      if [ -f "$repo_file" ]; then
        log "리포지토리 이미 등록됨: $(basename "$spec")"
      else
        log "리포지토리 등록: $spec"
        # dnf5 (Fedora 41+) 문법
        if ! sudo dnf config-manager addrepo --from-repofile="$spec"; then
          log "경고: 리포지토리 등록 실패: $spec ($package 건너뜀)"
          continue
        fi
      fi
    fi

    log "설치 중: $package"
    dnf_install_one "$package" || true
  done < <(parse_section repo)
}

# brew: 섹션 — Homebrew on Linux
install_brew_packages() {
  log "==================== brew (linuxbrew) ===================="

  if ! command -v brew &>/dev/null; then
    log "경고: brew가 설치되어 있지 않습니다. 다음 섹션 패키지를 건너뜁니다:"
    parse_section brew | sed 's/^/  - /' | tee -a "$LOG_FILE"
    log "설치: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    return 0
  fi

  while IFS= read -r package; do
    [ -z "$package" ] && continue
    if brew list "$package" &>/dev/null; then
      log "이미 설치됨 (brew): $package"
      continue
    fi
    log "설치 중 (brew): $package"
    brew install "$package" || log "경고: $package 설치 실패 (brew)"
  done < <(parse_section brew)
}

# 추가 수동 설치 안내
print_manual_instructions() {
  log ""
  log "==================== 수동 설치 필요 ===================="
  log "다음 패키지들은 리포지토리가 없어 수동 설치가 필요합니다:"
  log ""
  log "1. Nerd Fonts (아이콘 폰트):"
  log "   - https://www.nerdfonts.com/font-downloads"
  log "   - 다운로드 후 ~/.local/share/fonts/ 에 복사"
  log "   - fc-cache -fv 실행"
  log ""
  log "2. 1Password (비밀번호 관리자):"
  log "   - https://1password.com/downloads/linux/"
  log "   - RPM 패키지 다운로드 및 설치"
  log ""
  log "3. Dropbox:"
  log "   - https://www.dropbox.com/install-linux"
  log "   - Fedora RPM 다운로드"
  log ""
  log "4. Obsidian (메모 앱):"
  log "   - Flatpak: flatpak install flathub md.obsidian.Obsidian"
  log ""
  log "5. Spotify:"
  log "   - Flatpak: flatpak install flathub com.spotify.Client"
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
  install_dnf_packages
  install_repo_packages
  install_brew_packages
  print_manual_instructions
  clean_cache

  log ""
  log "설치 작업이 완료되었습니다."
  log "로그 파일: $LOG_FILE"
  log ""
  log "다음 단계:"
  log "1. 위의 수동 설치 안내를 참고하여 추가 패키지 설치"
  log "2. GNU Stow로 dotfiles 배포: cd ~/dotfiles && ./bootstrap.sh --skip-install"
}

# 스크립트 실행
main
