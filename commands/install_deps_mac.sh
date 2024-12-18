#!/bin/bash

# 스크립트 실행 시작을 알림
echo "Homebrew 패키지 설치를 시작합니다..."

# packages.txt 파일 존재 여부 확인
if [ ! -f "packages_homebrew.txt" ]; then
  echo "Error: packages.txt 파일을 찾을 수 없습니다."
  exit 1
fi

# Homebrew가 설치되어 있는지 확인
if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew가 설치되어 있지 않습니다."
  echo "다음 명령어로 Homebrew를 먼저 설치해주세요:"
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

# Homebrew 업데이트
echo "Homebrew 업데이트 중..."
brew update

# 설치 실패한 패키지를 기록할 배열 선언
declare -a failed_formulas
declare -a failed_casks

# Formula 설치
echo -e "\nFormula 패키지 설치 중..."
while IFS= read -r line || [[ -n "$line" ]]; do
  # 빈 줄이나 주석은 건너뜀
  [[ -z "$line" || "$line" =~ ^#.*$ ]] && continue

  # formula: 로 시작하는 줄 이후의 패키지들을 설치
  if [[ "$line" == "formula:" ]]; then
    while IFS= read -r package || [[ -n "$package" ]]; do
      # 다음 섹션이 시작되면 종료
      [[ "$package" == "cask:" ]] && break
      # 빈 줄이나 주석은 건너뜀
      [[ -z "$package" || "$package" =~ ^#.*$ ]] && continue

      echo "Formula 설치 중: $package"
      if ! brew install "$package"; then
        failed_formulas+=("$package")
      fi
    done
  fi
done <"packages_homebrew.txt"

# Cask 설치
echo -e "\nCask 패키지 설치 중..."
is_cask_section=false
while IFS= read -r line || [[ -n "$line" ]]; do
  # 빈 줄이나 주석은 건너뜀
  [[ -z "$line" || "$line" =~ ^#.*$ ]] && continue

  # cask: 섹션 찾기
  if [[ "$line" == "cask:" ]]; then
    is_cask_section=true
    continue
  fi

  # cask 섹션에서 패키지 설치
  if [[ "$is_cask_section" == true ]]; then
    echo "Cask 설치 중: $line"
    if ! brew install --cask "$line"; then
      failed_casks+=("$line")
    fi
  fi
done <"packages_homebrew.txt"

# 설치 결과 보고
echo -e "\n설치 완료 보고서:"
echo "----------------"

if [ ${#failed_formulas[@]} -eq 0 ] && [ ${#failed_casks[@]} -eq 0 ]; then
  echo "모든 패키지가 성공적으로 설치되었습니다!"
else
  if [ ${#failed_formulas[@]} -gt 0 ]; then
    echo "설치 실패한 Formula 패키지:"
    printf '%s\n' "${failed_formulas[@]}"
  fi
  if [ ${#failed_casks[@]} -gt 0 ]; then
    echo "설치 실패한 Cask 패키지:"
    printf '%s\n' "${failed_casks[@]}"
  fi
fi

# 청소 작업 수행
echo -e "\n청소 작업 수행 중..."
brew cleanup

echo "설치 작업이 완료되었습니다."
