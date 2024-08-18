#!/bin/bash

# Arch Linux and Flatpak Cache Cleaner Script

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "이 스크립트는 root 권한으로 실행해야 합니다."
  exit 1
fi

# Function to get disk usage
get_disk_usage() {
  df -h / | awk 'NR==2 {print $3}'
}

# Function to log disk usage change
log_disk_usage_change() {
  local before=$1
  local after=$2
  local action=$3
  echo "$action 전 사용량: $before"
  echo "$action 후 사용량: $after"
  echo "변화량: $(echo $before $after | awk '{print $2-$1}')G"
  echo ""
}

echo "Arch Linux 및 Flatpak 캐시 정리를 시작합니다..."

# Initial disk usage
initial_usage=$(get_disk_usage)
echo "초기 디스크 사용량: $initial_usage"
echo ""

# 1. 메모리 캐시 삭제 (sync만 수행하고 drop_caches는 선택적으로)
echo "파일 시스템 버퍼를 동기화 중..."
sync
read -p "메모리 캐시를 비우시겠습니까? (주의: 시스템 성능에 일시적인 영향을 줄 수 있습니다) (y/n): " answer
if [[ $answer = y ]]; then
  before_mem_cache=$(get_disk_usage)
  echo "메모리 캐시를 비우는 중..."
  echo 3 >/proc/sys/vm/drop_caches
  after_mem_cache=$(get_disk_usage)
  log_disk_usage_change $before_mem_cache $after_mem_cache "메모리 캐시 정리"
fi

# 2. pacman 캐시 정리 (설치되지 않은 패키지)
echo "pacman 캐시를 정리 중 (설치되지 않은 패키지)..."
before_pacman=$(get_disk_usage)
pacman -Sc --noconfirm
after_pacman=$(get_disk_usage)
log_disk_usage_change $before_pacman $after_pacman "pacman 캐시 정리"

# 3. 임시 파일 삭제 (단, 현재 사용 중인 파일은 제외)
echo "사용하지 않는 임시 파일을 삭제 중..."
before_tmp=$(get_disk_usage)
find /tmp -type f -atime +10 -delete
after_tmp=$(get_disk_usage)
log_disk_usage_change $before_tmp $after_tmp "임시 파일 정리"

# 4. 저널 로그 정리 (1주일 이상 된 로그)
echo "오래된 저널 로그를 정리 중..."
before_journal=$(get_disk_usage)
journalctl --vacuum-time=1week
after_journal=$(get_disk_usage)
log_disk_usage_change $before_journal $after_journal "저널 로그 정리"

# 5. Flatpak 캐시 정리
if command -v flatpak &>/dev/null; then
  echo "Flatpak 캐시를 정리 중..."
  before_flatpak=$(get_disk_usage)
  flatpak uninstall --unused -y
  flatpak repair
  after_flatpak=$(get_disk_usage)
  log_disk_usage_change $before_flatpak $after_flatpak "Flatpak 캐시 정리"
else
  echo "Flatpak이 설치되어 있지 않습니다. Flatpak 캐시 정리를 건너뜁니다."
fi

# Final disk usage
final_usage=$(get_disk_usage)
echo "최종 디스크 사용량: $final_usage"
echo "총 확보된 용량: $(echo $initial_usage $final_usage | awk '{print $1-$2}')G"

echo "캐시 정리가 완료되었습니다."
