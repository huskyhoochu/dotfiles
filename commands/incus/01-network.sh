#!/usr/bin/env bash
# Wi-Fi 연결 확인과 복구
#
# 설치 직후 네트워크가 전혀 없는 첫 연결은 이 스크립트로 못 한다 — 저장소를
# 받을 네트워크가 없기 때문이다. 첫 연결은 사람이 콘솔에서 직접 한다:
#   docs/gem12-first-wifi-tutorial-2026-08-17.md (맥북이나 휴대폰으로 연다)
#
# 이 스크립트는 clone 이후에 같은 절차를 멱등하게 재실행하는 용도다.
# 연결이 깨졌을 때의 복구, 재설치 후 재현에 쓴다.
#
# Fedora Server 는 NetworkManager-wifi 와 wpa_supplicant 를 기본 포함하고
# (F28부터) AX200 펌웨어도 linux-firmware 에 들어 있으므로, 추가 설치 없이
# nmcli 만으로 연결된다.
#
# 컨테이너용 NAT 브리지는 여기서 만들지 않는다. Incus가 incusbr0 을 직접
# 만들고 마스커레이딩까지 관리한다 (02-host.sh). 무선에서는 802.11 규격상
# 일반 브리지가 동작하지 않으므로 이 NAT 구조가 필수다.

source "$(dirname "$0")/lib.sh"

require_root

command -v nmcli >/dev/null 2>&1 || die "nmcli 가 없다. Fedora Server 가 맞는지 확인하라."

# 표준 Server 설치에는 들어 있다. 없다면 최소 구성으로 설치한 경우다.
if ! rpm -q NetworkManager-wifi wpa_supplicant >/dev/null 2>&1; then
  die "NetworkManager-wifi / wpa_supplicant 가 없다. 튜토리얼 문서의 'USB 테더링' 절차로 설치하라."
fi

# ── 1. 무선 인터페이스 탐지 ─────────────────────────────────────────
# GEM12 에서는 wlp6s0 이지만 하드코딩하지 않는다. 장비를 옮겨도 돌게 한다.

WIFI_IF="${WIFI_IF:-$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')}"
[ -n "$WIFI_IF" ] || die "wifi 장치가 없다. rfkill list 와 'dmesg | grep iwlwifi' 로 원인을 보라."

log "무선 인터페이스: $WIFI_IF"

nmcli radio wifi | grep -q enabled || { nmcli radio wifi on; log "무선을 켰다"; }
command -v rfkill >/dev/null 2>&1 && rfkill unblock wifi 2>/dev/null || true

# ── 2. 연결 ─────────────────────────────────────────────────────────

if ping -c 2 -W 3 1.1.1.1 >/dev/null 2>&1; then
  log "인터넷이 이미 연결돼 있다"
else
  if [ -n "${SSH_CONNECTION:-}" ]; then
    warn "SSH 세션에서 실행하고 있다. 네트워크 설정이 바뀌면 연결이 끊긴다."
    confirm "그래도 계속하겠는가?" || die "콘솔에서 다시 실행하라."
  fi

  log "주변 네트워크 검색"
  nmcli device wifi rescan 2>/dev/null || true
  sleep 3

  read -rp "  SSID: " WIFI_SSID
  [ -n "$WIFI_SSID" ] || die "SSID가 비어 있다"

  # --ask 는 비밀번호를 화면에 보이지 않게 따로 묻는다. 히스토리와 ps 출력에
  # 비밀번호가 남지 않는다.
  nmcli --ask device wifi connect "$WIFI_SSID" ifname "$WIFI_IF" \
    || die "연결에 실패했다. nmcli device wifi list 로 SSID를 확인하라."
fi

# ── 3. 부팅 시 자동 연결 ────────────────────────────────────────────
# 서버는 무인으로 재부팅되므로 자동 연결이 꺼져 있으면 안 된다.

ACTIVE_CONN=$(nmcli -t -f GENERAL.CONNECTION device show "$WIFI_IF" | cut -d: -f2)
if [ -n "$ACTIVE_CONN" ]; then
  nmcli connection modify "$ACTIVE_CONN" connection.autoconnect yes
  log "자동 연결 설정: $ACTIVE_CONN"
fi

# ── 4. 검증 ─────────────────────────────────────────────────────────

echo
log "결과"
ip -br addr show "$WIFI_IF" || true
echo

ping -c 2 -W 3 1.1.1.1 >/dev/null 2>&1 \
  || { warn "인터넷에 닿지 않는다. 'nmcli device' 와 'journalctl -u NetworkManager' 로 원인을 보라."; exit 1; }
getent hosts github.com >/dev/null 2>&1 \
  || { warn "DNS가 풀리지 않는다. 튜토리얼 문서의 문제 해결 표를 보라."; exit 1; }

log "인터넷과 DNS 연결 확인"
log "완료. 다음은 02-host.sh 다."
