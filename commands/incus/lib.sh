#!/usr/bin/env bash
# Incus 부트스트랩 스크립트 공통 함수
# 각 스크립트에서 source 해서 쓴다. 단독 실행하지 않는다.

set -euo pipefail

# ── 로깅 ────────────────────────────────────────────────────────────

log()  { printf '\033[34m[%s]\033[0m %s\n' "$(date '+%H:%M:%S')" "$1"; }
warn() { printf '\033[33m[WARN]\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[31m[ERROR]\033[0m %s\n' "$1" >&2; exit 1; }
skip() { printf '\033[90m[SKIP]\033[0m %s\n' "$1"; }

# ── 실행 전 검사 ────────────────────────────────────────────────────

require_root() {
  [ "$(id -u)" -eq 0 ] || die "Must run as root. Use sudo or log in as root."
}

require_incus() {
  command -v incus >/dev/null 2>&1 || die "incus command not found. Run 02-host.sh first."
}

# 사용자에게 확인을 받는다. 되돌리기 어려운 작업 앞에 둔다.
confirm() {
  local prompt="$1"
  local answer
  printf '\033[33m%s\033[0m [y/N] ' "$prompt"
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

# ── 멱등성 도우미 ───────────────────────────────────────────────────

# 파일에 특정 줄이 없으면 추가한다.
ensure_line() {
  local file="$1" line="$2"
  [ -f "$file" ] || touch "$file"
  grep -qxF "$line" "$file" || printf '%s\n' "$line" >>"$file"
}

# 파일을 덮어쓰기 전에 원본을 한 번만 백업한다.
backup_once() {
  local file="$1"
  [ -f "$file" ] || return 0
  [ -f "${file}.orig" ] && return 0
  cp -a "$file" "${file}.orig"
  log "Original saved to ${file}.orig"
}

# 컨테이너가 이미 있는지 본다.
container_exists() {
  incus info "$1" >/dev/null 2>&1
}

# 컨테이너가 실행 중인지 보고, 아니면 시작한다.
ensure_running() {
  local name="$1"
  [ "$(incus list "$name" -c s -f csv)" = "RUNNING" ] || incus start "$name"
}

# ── 컨테이너 정의 읽기 ──────────────────────────────────────────────

# containers.conf 를 한 줄씩 넘긴다. 주석과 빈 줄은 건너뛴다.
# 사용: while read -r NAME CORES MEM IP RUNTIME GPU COLOR; do ... done < <(read_containers)
read_containers() {
  local conf="${1:-$(dirname "${BASH_SOURCE[0]}")/containers.conf}"
  [ -f "$conf" ] || die "$conf not found"
  grep -vE '^\s*(#|$)' "$conf"
}
