#!/usr/bin/env bash
# Fedora Server 호스트 기본 설정
#
# 시간대, 기본 패키지, SSH 키 인증, Incus 설치와 초기화, 셸 환경.
# 01-network.sh 로 인터넷이 연결된 뒤 실행한다.
#
# 인자 없이 실행하면 된다. 기본값:
#   SSH 공개키  — GitHub(https://github.com/huskyhoochu.keys) 첫 번째 키
#   ADMIN_USER  — b95labs (일상 접속용 사용자. SSH 키 인증과 incus 권한을 받는다)
# 환경변수로 덮어쓸 수 있다:
#   SSH_PUBKEY="ssh-ed25519 AAAA..." ADMIN_USER=other ./02-host.sh

source "$(dirname "$0")/lib.sh"

BRIDGE_NAME="incusbr0"
BRIDGE_IP="10.10.10.1/24"
POOL_NAME="default"
POOL_PATH="/var/lib/incus-pool"
GITHUB_USER="huskyhoochu"
ADMIN_USER="${ADMIN_USER:-b95labs}"

require_root

# ── 1. 시간대와 기본 패키지 ─────────────────────────────────────────

if [ "$(timedatectl show -p Timezone --value)" != "Asia/Seoul" ]; then
  timedatectl set-timezone Asia/Seoul
  log "Timezone set to Asia/Seoul"
else
  skip "Timezone already Asia/Seoul"
fi

log "Installing base packages"
dnf install -y -q \
  curl git vim htop tmux \
  rclone restic \
  smartmontools \
  btrfs-progs \
  incus

# ── 2. SSH 키 인증 ──────────────────────────────────────────────────

log "SSH setup"

if [ -z "${SSH_PUBKEY:-}" ]; then
  if [ -s /root/.ssh/authorized_keys ]; then
    skip "authorized_keys already present"
  else
    # 맥북 공개키는 GitHub 이 URL 로 제공한다. 1Password 의 SSH 키가
    # GitHub 계정에 등록돼 있으므로 손으로 칠 필요가 없다.
    log "Fetching public key from GitHub: ${GITHUB_USER}.keys"
    SSH_PUBKEY="$(curl -fsSL "https://github.com/${GITHUB_USER}.keys" 2>/dev/null | head -1)" || true
    if [ -n "$SSH_PUBKEY" ]; then
      log "Public key: ${SSH_PUBKEY:0:40}..."
    else
      warn "Could not fetch key from GitHub. Without a key, disabling password login would lock you out."
      echo "On the MacBook: ssh-add -L   (1Password agent prints the public keys)"
      read -rp "Paste public key (empty line to skip): " SSH_PUBKEY
    fi
  fi
fi

if [ -n "${SSH_PUBKEY:-}" ]; then
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  ensure_line /root/.ssh/authorized_keys "$SSH_PUBKEY"
  chmod 600 /root/.ssh/authorized_keys
  log "Public key registered"
fi

# 키가 있을 때만 비밀번호 로그인을 끈다. 순서를 지키지 않으면 잠긴다.
if [ -s /root/.ssh/authorized_keys ]; then
  # Anaconda 에서 "비밀번호로 root SSH 허용"을 켰다면 그 설정을 걷어낸다.
  # 키 인증이 준비된 지금부터는 필요 없다.
  if [ -f /etc/ssh/sshd_config.d/01-permitrootlogin.conf ]; then
    rm -f /etc/ssh/sshd_config.d/01-permitrootlogin.conf
    systemctl reload sshd
    log "Removed Anaconda root-password-SSH override"
  fi

  SSHD_CONF=/etc/ssh/sshd_config.d/10-hardening.conf
  if [ -f "$SSHD_CONF" ]; then
    skip "SSH hardening already present"
  else
    cat >"$SSHD_CONF" <<'EOF'
# Incus 부트스트랩이 생성 — commands/incus/02-host.sh
PasswordAuthentication no
PermitRootLogin prohibit-password
EOF
    systemctl reload sshd
    log "Password login disabled (key auth only)"
  fi
else
  warn "No public key; leaving password login enabled."
fi

# ── 3. Cockpit ──────────────────────────────────────────────────────
# Fedora Server 에 기본 포함된 웹 관리 UI. 웹 터미널이 있어 SSH가 막혀도
# 브라우저에서 호스트 셸에 들어갈 수 있다. https://<서버>:9090

systemctl enable --now cockpit.socket >/dev/null 2>&1 || warn "Failed to enable cockpit.socket"

# ── 4. Incus 초기화 ─────────────────────────────────────────────────

log "Initializing Incus"

# unprivileged 컨테이너의 uid/gid 매핑 범위. Fedora 패키지는 이것을
# 자동으로 만들지 않는다.
ensure_line /etc/subuid "root:1000000:1000000000"
ensure_line /etc/subgid "root:1000000:1000000000"

systemctl enable --now incus.service

# 스토리지 풀 — 루트가 btrfs 이므로 서브볼륨을 풀로 쓴다. CoW 스냅샷이
# 순간이고 loop 이미지 파일을 거치지 않는다.
if incus storage show "$POOL_NAME" >/dev/null 2>&1; then
  skip "Storage pool ${POOL_NAME} already exists"
else
  if [ "$(stat -f -c %T /var/lib)" = "btrfs" ]; then
    [ -d "$POOL_PATH" ] || btrfs subvolume create "$POOL_PATH"
    incus storage create "$POOL_NAME" btrfs source="$POOL_PATH"
    log "Created btrfs storage pool: $POOL_PATH"
  else
    # btrfs 는 이 계획의 전제 조건이다 (스냅샷 백업, 체크섬, Incus CoW 풀).
    # Fedora Server 설치 기본값(LVM+xfs, 루트 16GB)으로 잘못 설치된 경우
    # 여기서 멈춰야 한다 — 계속 가면 16GB 루트에 컨테이너가 쌓인다.
    die "Root filesystem is not btrfs. Reinstall with Btrfs via Anaconda custom partitioning (see the partitioning section of docs/gem12-first-wifi-tutorial)."
  fi
fi

# NAT 브리지 — Incus 가 dnsmasq(DHCP/DNS)와 마스커레이딩을 직접 관리한다.
# Wi-Fi 상위 연결에서도 동작한다. 802.11 규격상 일반 브리지는 쓸 수 없다.
if incus network show "$BRIDGE_NAME" >/dev/null 2>&1; then
  skip "Bridge ${BRIDGE_NAME} already exists"
else
  incus network create "$BRIDGE_NAME" \
    ipv4.address="$BRIDGE_IP" \
    ipv4.nat=true \
    ipv6.address=none
  log "Created NAT bridge: $BRIDGE_NAME ($BRIDGE_IP)"
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
  || warn "Failed to load iptable_nat modules - Docker inside containers will not start"
MODULES_CONF=/etc/modules-load.d/docker-legacy-iptables.conf
if [ ! -f "$MODULES_CONF" ]; then
  printf 'iptable_nat\nip6table_nat\n' >"$MODULES_CONF"
  log "Registered legacy iptables modules for boot"
fi

# firewalld 가 브리지의 DHCP/DNS 를 막지 않게 trusted 존에 넣는다.
if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
  if firewall-cmd --zone=trusted --list-interfaces | grep -qw "$BRIDGE_NAME"; then
    skip "firewalld: ${BRIDGE_NAME} already in trusted zone"
  else
    firewall-cmd --permanent --zone=trusted --change-interface="$BRIDGE_NAME" >/dev/null
    firewall-cmd --reload >/dev/null
    log "firewalld: added ${BRIDGE_NAME} to trusted zone"
  fi
fi

# ── 4.5 관리자 사용자 ───────────────────────────────────────────────
# 부트스트랩은 root 로 하고, 이후 일상 접속은 이 사용자로 한다.

if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  warn "User ${ADMIN_USER} not found; skipping admin user setup."
else
  if [ -s /root/.ssh/authorized_keys ]; then
    ADMIN_HOME=$(getent passwd "$ADMIN_USER" | cut -d: -f6)
    ADMIN_GROUP=$(id -gn "$ADMIN_USER")
    install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_GROUP" "${ADMIN_HOME}/.ssh"
    install -m 600 -o "$ADMIN_USER" -g "$ADMIN_GROUP" \
      /root/.ssh/authorized_keys "${ADMIN_HOME}/.ssh/authorized_keys"
    log "${ADMIN_USER}: SSH key registered"
  fi

  # incus-admin 그룹이면 sudo 없이 incus 를 다룬다. 이 권한은 사실상
  # 호스트 root 와 같으므로 관리자 사용자에게만 준다.
  usermod -aG incus-admin "$ADMIN_USER"
  log "${ADMIN_USER}: added to incus-admin group (takes effect after re-login)"

  # sudo 가능 여부는 여기서 만들지 않고 확인만 한다. Anaconda 에서
  # 관리자로 지정했다면 wheel 에 이미 들어 있다.
  id -nG "$ADMIN_USER" | grep -qw wheel \
    || warn "${ADMIN_USER} is not in wheel. For sudo: usermod -aG wheel ${ADMIN_USER}"
fi

# ── 5. 셸 환경 ──────────────────────────────────────────────────────
# 서버에는 zsh을 깔지 않는다. 프롬프트에 호스트명을 색으로 박아
# SSH 창을 여러 개 띄웠을 때 어디에 있는지 헷갈리지 않게 한다.

log "Deploying shell environment"
bash "$(dirname "$0")/shell/install-shell.sh" --host --color 1

# ── 6. GPU 확인 ─────────────────────────────────────────────────────

log "Checking GPU devices"
if [ -d /dev/dri ]; then
  ls -l /dev/dri/ | grep -E 'card|render' || true
else
  warn "/dev/dri missing. Check amdgpu driver: lsmod | grep amdgpu"
fi

echo
log "Done. Next: 03-containers.sh"
