#!/usr/bin/env bash

# greetd + tuigreet 설치 및 설정 스크립트
# Fedora Sway Atomic 환경용

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "greetd + tuigreet 설정 스크립트"
echo "=================================================="
echo ""

# Root 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo "Error: 이 스크립트는 sudo 권한이 필요합니다."
    echo "Usage: sudo ./setup_greetd.sh"
    exit 1
fi

# greetd 패키지 설치 확인
echo "[1/4] greetd 패키지 설치 확인..."
if ! rpm -q greetd &>/dev/null || ! rpm -q greetd-tuigreet &>/dev/null; then
    echo "Warning: greetd 또는 greetd-tuigreet이 설치되지 않았습니다."
    echo ""
    echo "다음 명령어로 설치하세요:"
    echo "  rpm-ostree install greetd greetd-tuigreet"
    echo "  systemctl reboot"
    echo ""
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ greetd 패키지가 설치되어 있습니다."
fi

# 설정 파일 복사
echo ""
echo "[2/4] greetd 설정 파일 복사..."
if [ -d "$DOTFILES_DIR/greetd/etc/greetd" ]; then
    mkdir -p /etc/greetd
    cp -v "$DOTFILES_DIR/greetd/etc/greetd/config.toml" /etc/greetd/
    cp -v "$DOTFILES_DIR/greetd/etc/greetd/sway-config" /etc/greetd/
    echo "✓ 설정 파일이 복사되었습니다."
else
    echo "Error: greetd 설정 파일을 찾을 수 없습니다: $DOTFILES_DIR/greetd/etc/greetd"
    exit 1
fi

# SDDM 비활성화 및 greetd 활성화
echo ""
echo "[3/4] 디스플레이 매니저 전환..."
if systemctl is-enabled sddm &>/dev/null; then
    systemctl disable sddm
    echo "✓ SDDM이 비활성화되었습니다."
fi

if systemctl is-enabled gdm &>/dev/null; then
    systemctl disable gdm
    echo "✓ GDM이 비활성화되었습니다."
fi

systemctl enable greetd
echo "✓ greetd가 활성화되었습니다."

# 설정 확인
echo ""
echo "[4/4] 설정 확인..."
echo ""
cat /etc/greetd/config.toml
echo ""

echo "=================================================="
echo "greetd + tuigreet 설정 완료!"
echo "=================================================="
echo ""
echo "변경 사항을 적용하려면 재부팅하세요:"
echo "  systemctl reboot"
echo ""
echo "문제가 발생하면 다음 명령어로 SDDM으로 롤백할 수 있습니다:"
echo "  sudo systemctl disable greetd"
echo "  sudo systemctl enable sddm"
echo "  systemctl reboot"
echo ""
