#!/usr/bin/env bash
# containers.conf 정의대로 Incus 컨테이너를 만든다
#
# 컨테이너를 만들고 네트워크와 GPU만 붙인다. 서비스 설치는 하지 않는다.
# 여러 번 실행해도 안전하다. 이미 있는 컨테이너는 건너뛴다.
#
# GPU는 VM 패스스루가 아니라 Incus gpu 장치(/dev/dri 노드 전달)로 넘긴다.
# RDNA3는 vendor-reset을 지원하지 않아 VM에 넘기면 재시작 후 GPU가 복구되지
# 않는다. 시스템 컨테이너는 호스트 커널의 amdgpu 드라이버를 공유하므로 이
# 문제가 없다.

source "$(dirname "$0")/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE="images:fedora/44"       # 호스트와 같은 배포판으로 통일한다
DISK_SIZE="16GiB"              # 시스템만. 데이터는 /mnt/data 디스크 장치로 붙인다
DATA_ROOT="/mnt/data"

# GPU 이름 → PCI 주소 (lspci 실측값, docs §1 참조)
PCI_DGPU="0000:03:00.0"        # RX 7900 XTX
PCI_IGPU="0000:c8:00.0"        # Radeon 780M

require_root
require_incus

mkdir -p "$DATA_ROOT"

# ── 컨테이너 생성 ───────────────────────────────────────────────────
# 정의 파일은 fd 3 으로 읽는다. 루프 안의 incus 명령이 stdin 을 읽는
# 경우가 있어(YAML 설정 수신), stdin 으로 돌리면 다음 줄을 삼켜버린다.

while read -r -u3 NAME CORES MEM IP RUNTIME GPU COLOR; do
  echo
  log "── ${NAME} ──"

  if container_exists "$NAME"; then
    skip "이미 있다"
    continue
  fi

  mkdir -p "${DATA_ROOT}/${NAME}"

  log "생성 중: ${CORES} vCPU / ${MEM}MB / ${IP}"

  # init → 장치 구성 → start 순서. IP 를 시작 전에 정해야 첫 부팅부터
  # 고정 주소로 DHCP 임대를 받는다.
  incus init "$IMAGE" "$NAME" \
    -c limits.cpu="$CORES" \
    -c limits.memory="${MEM}MiB" \
    -c boot.autostart=true \
    -c security.nesting=true \
    -d root,size="$DISK_SIZE"

  incus config set "$NAME" user.comment "${RUNTIME} / $(date +%Y-%m-%d) / commands/incus 가 생성"

  # 고정 IP — incusbr0 의 dnsmasq 가 이 주소로 임대한다.
  incus config device override "$NAME" eth0 ipv4.address="$IP"

  # 서비스 데이터는 마운트 지점으로 추상화한다. 컨테이너는 /mnt/data 아래만
  # 알고 그 밑이 어떤 파일시스템인지 모른다. shift=true 가 uid 매핑을 맞춘다.
  incus config device add "$NAME" data disk \
    source="${DATA_ROOT}/${NAME}" path=/mnt/data shift=true

  # ── GPU 장치 ──────────────────────────────────────────────────────
  # unprivileged 컨테이너의 cgroup 허용과 /dev/dri 노드 전달을 Incus 가
  # 알아서 처리한다.

  if [ "$GPU" != "none" ]; then
    case "$GPU" in
      dgpu) PCI="$PCI_DGPU" ;;
      igpu) PCI="$PCI_IGPU" ;;
      *) die "${NAME}: 알 수 없는 GPU '${GPU}'" ;;
    esac
    log "GPU 장치 연결 (${GPU} → ${PCI})"
    incus config device add "$NAME" gpu gpu gputype=physical pci="$PCI"
  fi

  log "시작"
  incus start "$NAME"
  sleep 5

  # ── 컨테이너 초기 설정 ────────────────────────────────────────────

  log "기본 패키지 설치"
  incus exec "$NAME" -- bash -c "dnf install -y -q curl ca-certificates openssh-server >/dev/null"
  incus exec "$NAME" -- systemctl enable --now sshd
  incus exec "$NAME" -- timedatectl set-timezone Asia/Seoul 2>/dev/null || true

  # SSH 공개키를 호스트에서 물려준다.
  if [ -s /root/.ssh/authorized_keys ]; then
    incus exec "$NAME" -- mkdir -p /root/.ssh
    incus file push /root/.ssh/authorized_keys "${NAME}/root/.ssh/authorized_keys" --mode 600
    log "SSH 공개키 전달"
  fi

  # ── 셸 환경 ───────────────────────────────────────────────────────
  # apps 는 안에서 코딩하므로 개발 도구를 함께 넣는다.

  if [ "$NAME" = "apps" ]; then
    bash "${SCRIPT_DIR}/shell/install-shell.sh" --name "$NAME" --color "$COLOR" --dev
  else
    bash "${SCRIPT_DIR}/shell/install-shell.sh" --name "$NAME" --color "$COLOR"
  fi

  log "${NAME} 완료"
done 3< <(read_containers "${SCRIPT_DIR}/containers.conf")

# ── 결과 ────────────────────────────────────────────────────────────

echo
log "컨테이너 목록"
incus list

echo
log "완료. 다음은 04-runtime.sh 다."
