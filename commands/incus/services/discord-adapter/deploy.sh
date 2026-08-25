#!/usr/bin/env bash
# apps 컨테이너에 Discord 어댑터를 빌드해 띄운다 (docker)
#
# 호스트에서 root 로 실행한다.
#   sudo ./deploy.sh
#
# 시크릿은 컨테이너 안 /mnt/data/discord-adapter/.env 로 관리한다 — 이 저장소에
# 넣지 않는다. 항목은 .env.example 참고:
#   DISCORD_BOT_TOKEN, DISCORD_GUILD_ID, N8N_WEBHOOK_URL,
#   WEBHOOK_SHARED_SECRET, ALLOWED_USER_IDS
#
# n8n 은 기본 bridge 에 5678 포트를 게시하므로, 어댑터는 host gateway 로 호출한다.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="apps"
NAME="discord-adapter"
ENV_DIR="/mnt/data/discord-adapter"
ENV_FILE="${ENV_DIR}/.env"

require_root

# ── 사전 확인 ───────────────────────────────────────────────────────
incus exec "$CONTAINER" -- test -f "$ENV_FILE" || {
  die "컨테이너에 ${ENV_FILE} 가 없다. 먼저 채워 넣어라:
    incus exec ${CONTAINER} -- mkdir -p ${ENV_DIR}
    incus file push <env> ${CONTAINER}${ENV_FILE}"
}

log "Building image on ${CONTAINER}"
tar -C "$SCRIPT_DIR" --exclude node_modules --exclude dist -cf - . |
  incus exec "$CONTAINER" -- sh -c "mkdir -p /tmp/${NAME} && tar -xf - -C /tmp/${NAME}"
incus exec "$CONTAINER" -- sh -c "cd /tmp/${NAME} && docker build -q -t localhost/${NAME}:latest ." ||
  die "이미지 빌드 실패"

log "(Re)starting ${NAME}"
incus exec "$CONTAINER" -- docker rm -f "$NAME" >/dev/null 2>&1 || true
incus exec "$CONTAINER" -- docker run -d \
  --name "$NAME" \
  --restart unless-stopped \
  --add-host n8n:host-gateway \
  --env-file "$ENV_FILE" \
  "localhost/${NAME}:latest" ||
  die "컨테이너 기동 실패"

sleep 3
incus exec "$CONTAINER" -- docker logs "$NAME" --tail 5
incus exec "$CONTAINER" -- docker ps --filter "name=${NAME}" --format '{{.Names}} {{.Status}}'
