#!/usr/bin/env bash
# 서버 셸 환경 배포
#
# 사용:
#   ./install-shell.sh --host --color 1              # Proxmox 호스트에 설치
#   ./install-shell.sh --ctid 113 --color 2 --dev    # LXC 113 에 설치 (개발 도구 포함)
#
# --dev 는 apps-lxc 처럼 안에서 코딩할 컨테이너에만 쓴다. 나머지는 최소 구성으로
# 두어 컨테이너마다 패키지가 늘어나지 않게 한다.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/bashrc.template"

TARGET_HOST=false
CTID=""
COLOR=7
WITH_DEV=false

while [ $# -gt 0 ]; do
  case "$1" in
    --host)  TARGET_HOST=true; shift ;;
    --ctid)  CTID="$2"; shift 2 ;;
    --color) COLOR="$2"; shift 2 ;;
    --dev)   WITH_DEV=true; shift ;;
    *) echo "알 수 없는 옵션: $1" >&2; exit 1 ;;
  esac
done

[ -f "$TEMPLATE" ] || { echo "$TEMPLATE 를 찾을 수 없다" >&2; exit 1; }

# 색상을 치환한 내용을 만든다.
RENDERED="$(sed "s/@COLOR@/${COLOR}/g" "$TEMPLATE")"

# ── 개발 도구 (--dev 일 때만) ───────────────────────────────────────
# apps-lxc 에서 SSH로 들어와 코드를 만질 때 필요한 것들.

DEV_PACKAGES="git curl vim tmux ripgrep fd-find bat eza fzf jq"

DEV_SNIPPET='
# ── 개발 도구 ───────────────────────────────────────────────────────
# Debian은 fd 와 bat 을 다른 이름으로 설치한다.

command -v fdfind  >/dev/null 2>&1 && alias fd="fdfind"
command -v batcat  >/dev/null 2>&1 && alias bat="batcat"
command -v eza     >/dev/null 2>&1 && { alias ls="eza --icons"; alias ll="eza -alh --icons --git"; alias tree="eza --tree"; }
command -v rg      >/dev/null 2>&1 && alias rg="rg --smart-case"

if command -v fzf >/dev/null 2>&1; then
  [ -f /usr/share/bash-completion/completions/fzf ] && . /usr/share/bash-completion/completions/fzf
  [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
fi
'

# ── 배포 ────────────────────────────────────────────────────────────

install_to_host() {
  echo "[셸] Proxmox 호스트에 배포 (색상 ${COLOR})"

  [ -f /root/.bashrc ] && [ ! -f /root/.bashrc.orig ] && cp -a /root/.bashrc /root/.bashrc.orig

  printf '%s\n' "$RENDERED" >/root/.bashrc
  $WITH_DEV && printf '%s\n' "$DEV_SNIPPET" >>/root/.bashrc

  echo "[셸] /root/.bashrc 배포 완료"
}

install_to_ctid() {
  local id="$1"
  echo "[셸] LXC ${id} 에 배포 (색상 ${COLOR}, 개발도구 ${WITH_DEV})"

  pct status "$id" >/dev/null 2>&1 || { echo "LXC ${id} 가 없다" >&2; exit 1; }
  pct status "$id" | grep -q running || pct start "$id"

  if $WITH_DEV; then
    echo "[셸] 개발 도구 설치 중"
    pct exec "$id" -- bash -c "apt-get update -qq && apt-get install -y -qq ${DEV_PACKAGES}" >/dev/null
  fi

  # 템플릿을 컨테이너 안으로 옮긴다.
  local tmp="/tmp/bashrc.$$"
  printf '%s\n' "$RENDERED" >"$tmp"
  $WITH_DEV && printf '%s\n' "$DEV_SNIPPET" >>"$tmp"

  pct push "$id" "$tmp" /root/.bashrc
  rm -f "$tmp"

  echo "[셸] LXC ${id} 배포 완료"
}

if $TARGET_HOST; then
  install_to_host
elif [ -n "$CTID" ]; then
  install_to_ctid "$CTID"
else
  echo "--host 또는 --ctid 중 하나가 필요하다" >&2
  exit 1
fi
