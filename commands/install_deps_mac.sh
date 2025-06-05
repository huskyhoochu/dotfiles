#!/bin/bash

if [ ! -f "packages_homebrew.txt" ]; then
  echo "Error: packages_homebrew.txt 파일을 찾을 수 없습니다."
  exit 1
fi

if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew가 설치되어 있지 않습니다."
  exit 1
fi

echo "Homebrew 패키지 설치 시작..."
brew update

declare -a failed_formulas
declare -a failed_casks

echo "Formula 설치 중..."
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^# || "$line" == "formula:" ]] && continue
  [[ "$line" == "cask:" ]] && break

  if ! brew install "$line"; then
    failed_formulas+=("$line")
  fi
done <packages_homebrew.txt

echo "Cask 설치 중..."
is_cask_section=false
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  if [[ "$line" == "cask:" ]]; then
    is_cask_section=true
    continue
  fi

  if [[ "$is_cask_section" == true ]]; then
    if ! brew install --cask "$line"; then
      failed_casks+=("$line")
    fi
  fi
done <packages_homebrew.txt

echo "설치 완료!"
if [ ${#failed_formulas[@]} -gt 0 ] || [ ${#failed_casks[@]} -gt 0 ]; then
  echo "실패한 패키지:"
  printf '%s\n' "${failed_formulas[@]}" "${failed_casks[@]}"
fi

brew cleanup
