#!/usr/bin/env bash
# Wi-Fi 연결과 NAT 브리지 구성
#
# 반드시 콘솔(모니터+키보드)에서 실행한다. SSH로 실행하면 네트워크가 바뀌는
# 순간 연결이 끊기고 되돌릴 수 없다.
#
# 무선에서는 일반 브리지를 쓸 수 없다. 802.11 규격상 무선 클라이언트는 자기
# MAC 주소로만 프레임을 보낼 수 있어서, 컨테이너의 다른 MAC이 붙은 프레임을
# 공유기가 버리기 때문이다. 그래서 컨테이너를 사설망에 두고 호스트가
# 마스커레이딩한다.

source "$(dirname "$0")/lib.sh"

WIFI_IF="wlp6s0"
BRIDGE_NET="10.10.10.0/24"
BRIDGE_IP="10.10.10.1/24"
WPA_CONF="/etc/wpa_supplicant/wpa_supplicant-${WIFI_IF}.conf"

require_root

# ── 실행 환경 확인 ──────────────────────────────────────────────────

if [ -n "${SSH_CONNECTION:-}" ]; then
  warn "SSH 세션에서 실행하고 있다. 네트워크 설정이 바뀌면 연결이 끊긴다."
  confirm "그래도 계속하겠는가?" || die "콘솔에서 다시 실행하라."
fi

ip link show "$WIFI_IF" >/dev/null 2>&1 || die "$WIFI_IF 를 찾을 수 없다. 인터페이스 이름을 확인하라: ip -br link"

# ── 1. Wi-Fi 펌웨어와 도구 ──────────────────────────────────────────

log "Wi-Fi 패키지 확인"

if ! dpkg -s wpasupplicant >/dev/null 2>&1 || ! dpkg -s firmware-iwlwifi >/dev/null 2>&1; then
  # 인터넷이 없는 상태이므로 설치는 실패할 수 있다.
  # Proxmox ISO에 wpasupplicant는 들어 있고, firmware-iwlwifi는 non-free 저장소가 필요하다.
  log "wpasupplicant / firmware-iwlwifi 설치 시도"
  apt-get install -y wpasupplicant firmware-iwlwifi 2>/dev/null || {
    warn "설치에 실패했다. 인터넷이 없으면 정상이다."
    warn "다른 기기에서 .deb 를 받아 USB로 옮기거나, 유선을 임시로 연결하라."
    dpkg -s wpasupplicant >/dev/null 2>&1 || die "wpasupplicant 없이는 진행할 수 없다."
  }
fi

# ── 2. Wi-Fi 자격증명 ───────────────────────────────────────────────

if [ -f "$WPA_CONF" ]; then
  skip "$WPA_CONF 가 이미 있다"
else
  log "Wi-Fi 자격증명을 입력하라 (저장소에 남기지 않는다)"
  read -rp "  SSID: " WIFI_SSID
  read -rsp "  비밀번호: " WIFI_PASS
  echo

  [ -n "$WIFI_SSID" ] || die "SSID가 비어 있다"

  mkdir -p /etc/wpa_supplicant
  # wpa_passphrase 는 평문 비밀번호를 주석으로 남기므로 지운다.
  wpa_passphrase "$WIFI_SSID" "$WIFI_PASS" | grep -v '^\s*#psk=' >"$WPA_CONF"
  chmod 600 "$WPA_CONF"
  unset WIFI_PASS
  log "$WPA_CONF 생성 (권한 600)"
fi

systemctl enable "wpa_supplicant@${WIFI_IF}" >/dev/null 2>&1 || true

# ── 3. 네트워크 인터페이스 ──────────────────────────────────────────

log "/etc/network/interfaces 구성"
backup_once /etc/network/interfaces

cat >/etc/network/interfaces <<EOF
# Proxmox 부트스트랩이 생성 — commands/proxmox/01-network.sh
# 원본은 /etc/network/interfaces.orig 에 있다.

auto lo
iface lo inet loopback

# Wi-Fi (상위 연결)
auto ${WIFI_IF}
iface ${WIFI_IF} inet dhcp
    wpa-conf ${WPA_CONF}

# 컨테이너용 NAT 브리지 — 물리 포트 없음
auto vmbr0
iface vmbr0 inet static
    address ${BRIDGE_IP}
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    post-up   echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up   iptables -t nat -A POSTROUTING -s ${BRIDGE_NET} -o ${WIFI_IF} -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s ${BRIDGE_NET} -o ${WIFI_IF} -j MASQUERADE

# 유선을 연결하면 아래 주석을 풀고 위 ${WIFI_IF} 블록을 지운다.
# MASQUERADE 의 -o 인터페이스도 함께 바꾼다.
#auto eno1
#iface eno1 inet dhcp
EOF

# ── 4. 적용 ─────────────────────────────────────────────────────────

log "설정을 적용한다"
systemctl restart "wpa_supplicant@${WIFI_IF}" || warn "wpa_supplicant 재시작 실패"
ifreload -a 2>/dev/null || systemctl restart networking

sleep 5

# ── 5. 검증 ─────────────────────────────────────────────────────────

echo
log "결과"
ip -br addr show "$WIFI_IF" || true
ip -br addr show vmbr0 || true
echo

if ping -c 2 -W 3 1.1.1.1 >/dev/null 2>&1; then
  log "인터넷 연결 확인"
else
  warn "인터넷에 닿지 않는다. 'journalctl -u wpa_supplicant@${WIFI_IF}' 로 원인을 보라."
  exit 1
fi

log "완료. 이제 저장소를 clone 하고 02-host.sh 를 실행하라."
