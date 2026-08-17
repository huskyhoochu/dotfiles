#!/usr/bin/env bash
# containers.conf 정의대로 LXC를 만든다
#
# 컨테이너를 만들고 네트워크와 GPU만 붙인다. 서비스 설치는 하지 않는다.
# 여러 번 실행해도 안전하다. 이미 있는 컨테이너는 건너뛴다.
#
# GPU는 VM 패스스루가 아니라 /dev/dri 바인드마운트로 넘긴다. RDNA3는
# vendor-reset을 지원하지 않아 VM에 넘기면 재시작 후 GPU가 복구되지 않는다.
# LXC는 호스트 커널의 amdgpu 드라이버를 공유하므로 이 문제가 없다.

source "$(dirname "$0")/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_STORE="local"
ROOTFS_STORE="local-lvm"
DEBIAN_TEMPLATE="debian-13-standard"
GATEWAY="10.10.10.1"
DISK_SIZE="16"          # GB — 시스템만. 데이터는 /mnt/data 바인드마운트로 붙인다
DATA_ROOT="/mnt/data"

require_root
require_proxmox

# ── 1. 템플릿 확보 ──────────────────────────────────────────────────

log "Debian 13 템플릿 확인"

TEMPLATE_FILE=$(pveam list "$TEMPLATE_STORE" 2>/dev/null | awk -v t="$DEBIAN_TEMPLATE" '$1 ~ t {print $1; exit}')

if [ -z "$TEMPLATE_FILE" ]; then
  log "템플릿을 내려받는다"
  pveam update >/dev/null
  AVAILABLE=$(pveam available --section system | awk -v t="$DEBIAN_TEMPLATE" '$2 ~ t {print $2; exit}')
  [ -n "$AVAILABLE" ] || die "$DEBIAN_TEMPLATE 템플릿을 찾을 수 없다. pveam available --section system 으로 확인하라."
  pveam download "$TEMPLATE_STORE" "$AVAILABLE"
  TEMPLATE_FILE="${TEMPLATE_STORE}:vztmpl/${AVAILABLE}"
fi

log "템플릿: $TEMPLATE_FILE"

# ── 2. 데이터 디렉토리 ──────────────────────────────────────────────
# 서비스 데이터를 마운트 지점으로 추상화한다. 컨테이너는 /mnt/data 아래만
# 알고 그 밑이 어떤 파일시스템인지 모른다. 나중에 디스크를 추가하거나
# btrfs 에서 ZFS 로 옮길 때 마운트만 바꾸면 된다.

mkdir -p "$DATA_ROOT"

# ── 3. 컨테이너 생성 ────────────────────────────────────────────────

while read -r ID NAME CORES MEM IP RUNTIME GPU COLOR; do
  echo
  log "── ${NAME} (ID ${ID}) ──"

  if container_exists "$ID"; then
    skip "이미 있다"
    continue
  fi

  mkdir -p "${DATA_ROOT}/${NAME}"

  log "생성 중: ${CORES} vCPU / ${MEM}MB / ${IP}"

  pct create "$ID" "$TEMPLATE_FILE" \
    --hostname "$NAME" \
    --cores "$CORES" \
    --memory "$MEM" \
    --swap 512 \
    --rootfs "${ROOTFS_STORE}:${DISK_SIZE}" \
    --net0 "name=eth0,bridge=vmbr0,ip=${IP}/24,gw=${GATEWAY}" \
    --nameserver "1.1.1.1 8.8.8.8" \
    --onboot 1 \
    --unprivileged 1 \
    --features nesting=1 \
    --mp0 "${DATA_ROOT}/${NAME},mp=/mnt/data" \
    --description "${RUNTIME} / $(date +%Y-%m-%d) / commands/proxmox 가 생성"

  CONF="/etc/pve/lxc/${ID}.conf"

  # ── GPU 바인드마운트 ──────────────────────────────────────────────
  # unprivileged 컨테이너에서 /dev/dri 를 쓰려면 cgroup 허용과 장치
  # 마운트를 함께 넣어야 한다. 226 은 DRM 메이저 번호다.

  if [ "$GPU" != "none" ]; then
    log "GPU 장치 연결 (${GPU})"
    cat >>"$CONF" <<'EOF'

# GPU 접근 — /dev/dri 바인드마운트
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
EOF
    # render 그룹(GID 104)이 있어야 컨테이너 안에서 렌더 노드를 연다.
    ensure_line "$CONF" "lxc.idmap: u 0 100000 65536"
  fi

  # nesting 은 컨테이너 안에서 Docker/Podman 을 돌리는 데 필요하다.
  ensure_line "$CONF" "features: nesting=1,keyctl=1"

  log "시작"
  pct start "$ID"
  sleep 3

  # ── 컨테이너 초기 설정 ────────────────────────────────────────────

  log "기본 패키지 설치"
  pct exec "$ID" -- bash -c "apt-get update -qq && apt-get install -y -qq curl ca-certificates >/dev/null"

  pct exec "$ID" -- timedatectl set-timezone Asia/Seoul 2>/dev/null || true

  # SSH 공개키를 호스트에서 물려준다.
  if [ -s /root/.ssh/authorized_keys ]; then
    pct exec "$ID" -- mkdir -p /root/.ssh
    pct push "$ID" /root/.ssh/authorized_keys /root/.ssh/authorized_keys --perms 600
    log "SSH 공개키 전달"
  fi

  # ── 셸 환경 ───────────────────────────────────────────────────────
  # apps 는 안에서 코딩하므로 개발 도구를 함께 넣는다.

  if [ "$NAME" = "apps" ]; then
    bash "${SCRIPT_DIR}/shell/install-shell.sh" --ctid "$ID" --color "$COLOR" --dev
  else
    bash "${SCRIPT_DIR}/shell/install-shell.sh" --ctid "$ID" --color "$COLOR"
  fi

  log "${NAME} 완료"
done < <(read_containers "${SCRIPT_DIR}/containers.conf")

# ── 4. 결과 ─────────────────────────────────────────────────────────

echo
log "컨테이너 목록"
pct list

echo
log "완료. 다음은 04-runtime.sh 다."
