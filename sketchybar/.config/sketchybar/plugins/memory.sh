#!/bin/bash

# 페이지 크기 확인 (바이트 단위)
PAGE_SIZE=$(pagesize)
echo "PAGE_SIZE: $PAGE_SIZE"

# vm_stat 명령을 사용하여 메모리 사용량 계산 (페이지 단위)
ACTIVE=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
INACTIVE=$(vm_stat | awk '/Pages inactive/ {print $3}' | tr -d '.')
WIRED=$(vm_stat | awk '/Pages wired down/ {print $4}' | tr -d '.')
COMPRESSED=$(vm_stat | awk '/Pages occupied by compressor/ {print $5}' | tr -d '.')
SPECULATIVE=$(vm_stat | awk '/Pages speculative/ {print $3}' | tr -d '.')
PURGEABLE=$(vm_stat | awk '/Pages purgeable/ {print $3}' | tr -d '.')
EXTERNAL=$(vm_stat | awk '/File-backed pages/ {print $3}' | tr -d '.')

echo "ACTIVE: $ACTIVE"
echo "INACTIVE: $INACTIVE"
echo "WIRED: $WIRED"
echo "COMPRESSED: $COMPRESSED"
echo "SPECULATIVE: $SPECULATIVE"
echo "PURGEABLE: $PURGEABLE"
echo "EXTERNAL: $EXTERNAL"

# macmon 코드와 유사하게 사용된 메모리 계산 (페이지 단위)
# (ACTIVE + INACTIVE + WIRED + SPECULATIVE + COMPRESSED - PURGEABLE - EXTERNAL)
USED_PAGES=$((ACTIVE + INACTIVE + WIRED + SPECULATIVE + COMPRESSED - PURGEABLE - EXTERNAL))
echo "USED_PAGES: $USED_PAGES"

# awk로 사용된 메모리 계산 (GB 단위)
USED_GB=$(awk -v pages="$USED_PAGES" -v pageSize="$PAGE_SIZE" 'BEGIN {printf "%.2f", pages * pageSize / 1024 / 1024 / 1024}')
echo "USED_GB: $USED_GB"

# 전체 메모리 계산 (GB 단위)
TOTAL_GB=$(sysctl -n hw.memsize | awk '{printf "%.2f", $1 / 1024 / 1024 / 1024}')
echo "TOTAL_GB: $TOTAL_GB"

# awk로 사용률 계산
PERCENTAGE=$(awk -v used="$USED_GB" -v total="$TOTAL_GB" 'BEGIN {printf "%.2f", used / total * 100}')
echo "PERCENTAGE: $PERCENTAGE"

sketchybar --set "$NAME" label="$PERCENTAGE%"
