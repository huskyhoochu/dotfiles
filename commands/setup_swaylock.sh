#!/usr/bin/env bash

# swaylock-effects 설치 및 설정 스크립트
# Fedora Sway Atomic 환경용
# COPR 활성화 및 rpm-ostree 설치 자동화

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "swaylock-effects 설치 스크립트"
echo "=================================================="
echo ""

# Root 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo "Error: 이 스크립트는 sudo 권한이 필요합니다."
    echo "Usage: sudo ./setup_swaylock.sh"
    exit 1
fi

# 이미 설치되어 있는지 확인
if rpm -q swaylock-effects &>/dev/null; then
    echo "✓ swaylock-effects가 이미 설치되어 있습니다."
    echo ""
    read -p "재설치하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "설치를 건너뜁니다."
        exit 0
    fi
fi

# COPR 활성화
echo "[1/3] COPR 리포지토리 활성화..."
if ! dnf copr list --enabled | grep -q "eddsalkield/swaylock-effects"; then
    dnf copr enable eddsalkield/swaylock-effects -y
    echo "✓ COPR 리포지토리가 활성화되었습니다."
else
    echo "✓ COPR 리포지토리가 이미 활성화되어 있습니다."
fi

# swaylock-effects 설치
echo ""
echo "[2/3] swaylock-effects 패키지 설치..."
echo "Warning: rpm-ostree로 설치 후 재부팅이 필요합니다."
echo ""

# 기존 swaylock 제거 여부 확인
if rpm -q swaylock &>/dev/null && ! rpm -q swaylock-effects &>/dev/null; then
    echo "기본 swaylock이 설치되어 있습니다."
    read -p "swaylock을 제거하고 swaylock-effects를 설치하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rpm-ostree override remove swaylock --install swaylock-effects
    else
        echo "설치를 취소합니다."
        exit 0
    fi
else
    rpm-ostree install swaylock-effects
fi

echo "✓ swaylock-effects 설치가 예약되었습니다."

# Stow 안내
echo ""
echo "[3/3] 설정 파일 배포 안내"
echo ""
echo "재부팅 후 다음 명령어로 설정 파일을 배포하세요:"
echo "  cd $DOTFILES_DIR"
echo "  stow swaylock"
echo ""

echo "=================================================="
echo "swaylock-effects 설치 완료!"
echo "=================================================="
echo ""
echo "변경 사항을 적용하려면 재부팅하세요:"
echo "  systemctl reboot"
echo ""
echo "재부팅 후:"
echo "  1. stow swaylock 실행으로 설정 배포"
echo "  2. swaylock -f 명령으로 테스트"
echo ""
echo "Sway config에 단축키를 추가하려면:"
echo "  sway/.config/sway/config에 다음 추가:"
echo "  bindsym \$mod+l exec swaylock -f"
echo ""
