#!/usr/bin/env bash
# Fedora Server 호스트 기본 설정
#
# 시간대, 기본 패키지, SSH 키 인증, Incus 설치와 초기화, 셸 환경.
# 01-network.sh 로 인터넷이 연결된 뒤 실행한다.
#
# SSH 공개키는 저장소에 넣지 않는다. 아래 둘 중 하나로 넘긴다.
#   SSH_PUBKEY="ssh-ed25519 AAAA..." ./02-host.sh
#   ./02-host.sh   (입력 요청을 받는다)
#
# ADMIN_USER=<이름> 을 함께 넘기면 그 사용자에게도 SSH 키 인증을 열고
# incus 관리 권한을 준다. 부트스트랩 이후 일상 접속은 이 사용자로 한다.
#   ADMIN_USER=b95 SSH_PUBKEY="..." ./02-host.sh

source "$(dirname "$0")/lib.sh"

BRIDGE_NAME="incusbr0"
BRIDGE_IP="10.10.10.1/24"
POOL_NAME="default"
POOL_PATH="/var/lib/incus-pool"

require_root

# ── 1. 시간대와 기본 패키지 ─────────────────────────────────────────

if [ "$(timedatectl show -p Timezone --value)" != "Asia/Seoul" ]; then
  timedatectl set-timezone Asia/Seoul
  log "시간대를 Asia/Seoul 로 설정"
else
  skip "시간대가 이미 Asia/Seoul 이다"
fi

log "기본 패키지 설치"
dnf install -y -q \
  curl git vim htop tmux \
  rclone restic \
  smartmontools \
  btrfs-progs \
  incus

# ── 2. SSH 키 인증 ──────────────────────────────────────────────────

log "SSH 설정"

if [ -z "${SSH_PUBKEY:-}" ]; then
  if [ -s /root/.ssh/authorized_keys ]; then
    skip "authorized_keys 가 이미 있다"
  else
    warn "SSH 공개키가 없다. 비밀번호 로그인을 끄면 접속할 수 없게 된다."
    echo "맥북에서 확인: ssh-add -L   (1Password 에이전트가 공개키를 출력한다)"
    read -rp "공개키를 붙여넣어라 (건너뛰려면 빈 줄): " SSH_PUBKEY
  fi
fi

if [ -n "${SSH_PUBKEY:-}" ]; then
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  ensure_line /root/.ssh/authorized_keys "$SSH_PUBKEY"
  chmod 600 /root/.ssh/authorized_keys
  log "공개키 등록"
fi

# 키가 있을 때만 비밀번호 로그인을 끈다. 순서를 지키지 않으면 잠긴다.
if [ -s /root/.ssh/authorized_keys ]; then
  # Anaconda 에서 "비밀번호로 root SSH 허용"을 켰다면 그 설정을 걷어낸다.
  # 키 인증이 준비된 지금부터는 필요 없다.
  if [ -f /etc/ssh/sshd_config.d/01-permitrootlogin.conf ]; then
    rm -f /etc/ssh/sshd_config.d/01-permitrootlogin.conf
    systemctl reload sshd
    log "Anaconda의 root 비밀번호 SSH 허용 설정 제거"
  fi

  SSHD_CONF=/etc/ssh/sshd_config.d/10-hardening.conf
  if [ -f "$SSHD_CONF" ]; then
    skip "SSH 강화 설정이 이미 있다"
  else
    cat >"$SSHD_CONF" <<'EOF'
# Incus 부트스트랩이 생성 — commands/incus/02-host.sh
PasswordAuthentication no
PermitRootLogin prohibit-password
EOF
    systemctl reload sshd
    log "비밀번호 로그인 차단 (키 인증만 허용)"
  fi
else
  warn "공개키가 없어 비밀번호 로그인을 그대로 둔다."
fi

# ── 3. Cockpit ──────────────────────────────────────────────────────
# Fedora Server 에 기본 포함된 웹 관리 UI. 웹 터미널이 있어 SSH가 막혀도
# 브라우저에서 호스트 셸에 들어갈 수 있다. https://<서버>:9090

systemctl enable --now cockpit.socket >/dev/null 2>&1 || warn "cockpit.socket 활성화 실패"

# ── 4. Incus 초기화 ─────────────────────────────────────────────────

log "Incus 초기화"

# unprivileged 컨테이너의 uid/gid 매핑 범위. Fedora 패키지는 이것을
# 자동으로 만들지 않는다.
ensure_line /etc/subuid "root:1000000:1000000000"
ensure_line /etc/subgid "root:1000000:1000000000"

systemctl enable --now incus.service

# 스토리지 풀 — 루트가 btrfs 이므로 서브볼륨을 풀로 쓴다. CoW 스냅샷이
# 순간이고 loop 이미지 파일을 거치지 않는다.
if incus storage show "$POOL_NAME" >/dev/null 2>&1; then
  skip "스토리지 풀 ${POOL_NAME} 이 이미 있다"
else
  if [ "$(stat -f -c %T /var/lib)" = "btrfs" ]; then
    [ -d "$POOL_PATH" ] || btrfs subvolume create "$POOL_PATH"
    incus storage create "$POOL_NAME" btrfs source="$POOL_PATH"
    log "btrfs 스토리지 풀 생성: $POOL_PATH"
  else
    warn "/var/lib 가 btrfs 가 아니다. dir 드라이버로 만든다 (스냅샷이 느려진다)."
    incus storage create "$POOL_NAME" dir
  fi
fi

# NAT 브리지 — Incus 가 dnsmasq(DHCP/DNS)와 마스커레이딩을 직접 관리한다.
# Wi-Fi 상위 연결에서도 동작한다. 802.11 규격상 일반 브리지는 쓸 수 없다.
if incus network show "$BRIDGE_NAME" >/dev/null 2>&1; then
  skip "브리지 ${BRIDGE_NAME} 이 이미 있다"
else
  incus network create "$BRIDGE_NAME" \
    ipv4.address="$BRIDGE_IP" \
    ipv4.nat=true \
    ipv6.address=none
  log "NAT 브리지 생성: $BRIDGE_NAME ($BRIDGE_IP)"
fi

# 기본 프로파일에 루트 디스크와 NIC 을 연결한다.
incus profile device show default | grep -q '^root:' \
  || incus profile device add default root disk path=/ pool="$POOL_NAME"
incus profile device show default | grep -q '^eth0:' \
  || incus profile device add default eth0 nic network="$BRIDGE_NAME" name=eth0

# Docker CE(ci/apps 컨테이너)는 iptables-legacy 를 쓰는데, legacy nat
# 테이블은 이 커널 모듈이 있어야 생긴다. 컨테이너는 모듈을 로드할 수
# 없으므로 호스트가 올려준다 — 로드되면 모든 netns 에 테이블이 생긴다.
modprobe -a iptable_nat ip6table_nat 2>/dev/null \
  || warn "iptable_nat 모듈 로드 실패 — 컨테이너 안 Docker 가 뜨지 않는다"
MODULES_CONF=/etc/modules-load.d/docker-legacy-iptables.conf
if [ ! -f "$MODULES_CONF" ]; then
  printf 'iptable_nat\nip6table_nat\n' >"$MODULES_CONF"
  log "legacy iptables 모듈 부팅 시 로드 등록"
fi

# firewalld 가 브리지의 DHCP/DNS 를 막지 않게 trusted 존에 넣는다.
if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
  if firewall-cmd --zone=trusted --list-interfaces | grep -qw "$BRIDGE_NAME"; then
    skip "firewalld: ${BRIDGE_NAME} 이 이미 trusted 존에 있다"
  else
    firewall-cmd --permanent --zone=trusted --change-interface="$BRIDGE_NAME" >/dev/null
    firewall-cmd --reload >/dev/null
    log "firewalld: ${BRIDGE_NAME} 을 trusted 존에 추가"
  fi
fi

# ── 4.5 관리자 사용자 ───────────────────────────────────────────────
# 부트스트랩은 root 로 하고, 이후 일상 접속은 이 사용자로 한다.

if [ -n "${ADMIN_USER:-}" ]; then
  id "$ADMIN_USER" >/dev/null 2>&1 || die "사용자 ${ADMIN_USER} 가 없다"

  if [ -s /root/.ssh/authorized_keys ]; then
    ADMIN_HOME=$(getent passwd "$ADMIN_USER" | cut -d: -f6)
    ADMIN_GROUP=$(id -gn "$ADMIN_USER")
    install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_GROUP" "${ADMIN_HOME}/.ssh"
    install -m 600 -o "$ADMIN_USER" -g "$ADMIN_GROUP" \
      /root/.ssh/authorized_keys "${ADMIN_HOME}/.ssh/authorized_keys"
    log "${ADMIN_USER}: SSH 키 인증 등록"
  fi

  # incus-admin 그룹이면 sudo 없이 incus 를 다룬다. 이 권한은 사실상
  # 호스트 root 와 같으므로 관리자 사용자에게만 준다.
  usermod -aG incus-admin "$ADMIN_USER"
  log "${ADMIN_USER}: incus-admin 그룹 추가 (재로그인 후 적용)"

  # sudo 가능 여부는 여기서 만들지 않고 확인만 한다. Anaconda 에서
  # 관리자로 지정했다면 wheel 에 이미 들어 있다.
  id -nG "$ADMIN_USER" | grep -qw wheel \
    || warn "${ADMIN_USER} 가 wheel 그룹에 없다. sudo 가 필요하면: usermod -aG wheel ${ADMIN_USER}"
fi

# ── 5. 셸 환경 ──────────────────────────────────────────────────────
# 서버에는 zsh을 깔지 않는다. 프롬프트에 호스트명을 색으로 박아
# SSH 창을 여러 개 띄웠을 때 어디에 있는지 헷갈리지 않게 한다.

log "셸 환경 배포"
bash "$(dirname "$0")/shell/install-shell.sh" --host --color 1

# ── 6. GPU 확인 ─────────────────────────────────────────────────────

log "GPU 장치 확인"
if [ -d /dev/dri ]; then
  ls -l /dev/dri/ | grep -E 'card|render' || true
else
  warn "/dev/dri 가 없다. amdgpu 드라이버를 확인하라: lsmod | grep amdgpu"
fi

echo
log "완료. 다음은 03-containers.sh 다."
