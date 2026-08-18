#!/usr/bin/env bash
# 웹 콘솔 포트 노출 규약을 tailscale serve 로 고정한다 (계획 §7, §10 원칙 2)
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다 — 같은 설정의 재적용은 무해하다.
#   sudo ./deploy.sh
#
# 규약: https://gem12.tail4555a7.ts.net:<컨테이너 포트> → 컨테이너 (tailnet 전용).
# tailscaled 가 설정을 저장하므로 재부팅에도 유지된다 — 이 스크립트는
# 재설치·신규 서비스 추가 때 규약을 재현하는 정본이다.

source "$(dirname "$0")/../../lib.sh"

require_root
command -v tailscale >/dev/null || die "tailscale not installed. See §7 of the plan doc."

# 포트 → 대상 (컨테이너 IP 는 03-containers.sh 의 containers.conf 와 일치해야 한다)
declare -A SERVES=(
  [3000]="http://10.10.10.11:3000"   # Forgejo (core)
  [3001]="http://10.10.10.11:3001"   # Uptime Kuma (core)
  [5678]="http://10.10.10.13:5678"   # n8n (apps)
  [8080]="http://10.10.10.13:8080"   # NocoDB (apps)
  [2283]="http://10.10.10.15:2283"   # Immich (media)
  [8096]="http://10.10.10.15:8096"   # Jellyfin (media)
  [8188]="http://10.10.10.14:8188"   # ComfyUI (ai)
)

for port in "${!SERVES[@]}"; do
  tailscale serve --bg --https="$port" "${SERVES[$port]}" >/dev/null
  log "serve :${port} → ${SERVES[$port]}"
done

echo
tailscale serve status | sed 's/^/  /'

echo
log "Done."
