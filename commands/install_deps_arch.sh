#!/bin/bash

# 로그 파일 설정
LOG_FILE="aur_install_$(date +%Y%m%d_%H%M%S).log"

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

# yay가 설치되어 있는지 확인
check_yay() {
  if ! command -v yay &>/dev/null; then
    log "yay가 설치되어 있지 않습니다. yay를 먼저 설치해주세요."
    log "설치 방법:"
    log "1. git clone https://aur.archlinux.org/yay.git"
    log "2. cd yay"
    log "3. makepkg -si"
    exit 1
  fi
}

# 입력 파일 확인
check_input_file() {
  if [ ! -f "packages_aur.txt" ]; then
    handle_error "packages_aur.txt 파일을 찾을 수 없습니다."
  fi
}

# 시스템 업데이트
update_system() {
  log "시스템 업데이트를 시작합니다..."
  yay -Syu --noconfirm || handle_error "시스템 업데이트 실패"
}

# 패키지 설치 함수
install_packages() {
  local failed_packages=()

  # 패키지 개수 확인
  local total_packages=$(grep -v '^#' packages_aur.txt | grep -v '^$' | wc -l)
  log "총 $total_packages 개의 패키지를 설치합니다."

  # 각 패키지 설치
  while IFS= read -r package || [[ -n "$package" ]]; do
    # 주석과 빈 줄 건너뛰기
    [[ -z "$package" || "$package" =~ ^#.*$ ]] && continue

    log "설치 중: $package"
    if ! yay -S --needed --noconfirm "$package"; then
      log "경고: $package 설치 실패"
      failed_packages+=("$package")
    fi
  done <packages_aur.txt

  # 설치 결과 보고
  if [ ${#failed_packages[@]} -eq 0 ]; then
    log "모든 패키지가 성공적으로 설치되었습니다."
  else
    log "다음 패키지들의 설치가 실패했습니다:"
    printf '%s\n' "${failed_packages[@]}" | tee -a "$LOG_FILE"
  fi
}

# 캐시 정리
clean_cache() {
  log "패키지 캐시를 정리합니다..."
  yay -Sc --noconfirm || log "캐시 정리 중 오류 발생"
}

# 메인 실행 부분
main() {
  log "AUR 패키지 설치 스크립트를 시작합니다..."

  check_yay
  check_input_file
  update_system
  install_packages
  clean_cache

  log "설치 작업이 완료되었습니다. 로그 파일: $LOG_FILE"
}

# 스크립트 실행
main
