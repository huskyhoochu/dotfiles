#!/usr/bin/env bash
# Proxmox 호스트 기본 설정
#
# 무료 저장소 전환, 시간대, SSH 키 인증, 셸 환경.
# 01-network.sh 로 인터넷이 연결된 뒤 실행한다.
#
# SSH 공개키는 저장소에 넣지 않는다. 아래 둘 중 하나로 넘긴다.
#   SSH_PUBKEY="ssh-ed25519 AAAA..." ./02-host.sh
#   ./02-host.sh   (입력 요청을 받는다)

source "$(dirname "$0")/lib.sh"

require_root
require_proxmox

# ── 1. 저장소 — 구독 없이 쓰는 무료 저장소로 바꾼다 ─────────────────

log "APT 저장소 설정"

ENTERPRISE_LIST=/etc/apt/sources.list.d/pve-enterprise.sources
CEPH_LIST=/etc/apt/sources.list.d/ceph.sources
NO_SUB_LIST=/etc/apt/sources.list.d/pve-no-subscription.sources

# 구독이 없으면 enterprise 저장소는 401을 낸다. 꺼둔다.
for f in "$ENTERPRISE_LIST" "$CEPH_LIST"; do
  if [ -f "$f" ] && ! grep -q '^Enabled: false' "$f"; then
    ensure_line "$f" "Enabled: false"
    log "$(basename "$f") 비활성화"
  fi
done

if [ -f "$NO_SUB_LIST" ]; then
  skip "no-subscription 저장소가 이미 있다"
else
  cat >"$NO_SUB_LIST" <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
  log "no-subscription 저장소 추가"
fi

log "패키지 목록 갱신"
apt-get update -qq

# ── 2. 시간대와 기본 패키지 ─────────────────────────────────────────

if [ "$(timedatectl show -p Timezone --value)" != "Asia/Seoul" ]; then
  timedatectl set-timezone Asia/Seoul
  log "시간대를 Asia/Seoul 로 설정"
else
  skip "시간대가 이미 Asia/Seoul 이다"
fi

log "기본 패키지 설치"
apt-get install -y -qq \
  curl git vim htop tmux \
  rclone restic \
  smartmontools \
  iptables-persistent \
  >/dev/null

# ── 3. SSH 키 인증 ──────────────────────────────────────────────────

log "SSH 설정"

if [ -z "${SSH_PUBKEY:-}" ]; then
  if [ -s /root/.ssh/authorized_keys ]; then
    skip "authorized_keys 가 이미 있다"
  else
    warn "SSH 공개키가 없다. 비밀번호 로그인을 끄면 접속할 수 없게 된다."
    echo "맥북에서 확인: cat ~/.ssh/id_ed25519.pub"
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
  SSHD_CONF=/etc/ssh/sshd_config.d/10-hardening.conf
  if [ -f "$SSHD_CONF" ]; then
    skip "SSH 강화 설정이 이미 있다"
  else
    cat >"$SSHD_CONF" <<'EOF'
# Proxmox 부트스트랩이 생성 — commands/proxmox/02-host.sh
PasswordAuthentication no
PermitRootLogin prohibit-password
EOF
    systemctl reload ssh 2>/dev/null || systemctl reload sshd
    log "비밀번호 로그인 차단 (키 인증만 허용)"
  fi
else
  warn "공개키가 없어 비밀번호 로그인을 그대로 둔다."
fi

# ── 4. 셸 환경 ──────────────────────────────────────────────────────
# 서버에는 zsh을 깔지 않는다. 프롬프트에 호스트명을 색으로 박아
# SSH 창을 여러 개 띄웠을 때 어디에 있는지 헷갈리지 않게 한다.

log "셸 환경 배포"
bash "$(dirname "$0")/shell/install-shell.sh" --host --color 1

# ── 5. GPU 확인 ─────────────────────────────────────────────────────

log "GPU 장치 확인"
if [ -d /dev/dri ]; then
  ls -l /dev/dri/ | grep -E 'card|render' || true
else
  warn "/dev/dri 가 없다. amdgpu 드라이버를 확인하라: lsmod | grep amdgpu"
fi

echo
log "완료. 다음은 03-containers.sh 다."
