#!/usr/bin/env bash
# apps 컨테이너의 n8n을 재구성하고 dev-control 워크플로를 배포한다
#
# 호스트(gem12)에서 root로 실행한다.
#   sudo ./deploy.sh
#
# 하는 일:
#   1. /root/.secrets/ 의 시크릿으로 n8n 컨테이너를 재생성(env 주입)
#   2. dev-control 워크플로를 import + 활성화
#
# 전제:
#   - /root/.secrets/{devcontrol-webhook-secret,tavily-api-key} 존재
#   - n8n credential(Forgejo DevControl·Discord Bot·OpenRouter·Tavily Bearer
#     ·DevControl Shared Secret)은 DB에 이미 있음 — 볼륨(/mnt/data/apps/n8n)이
#     유지되는 한 재주입 불필요

source "$(dirname "$0")/../../lib.sh"

CONTAINER="apps"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WF_SRC="$SCRIPT_DIR/workflows/dev-control.json"
N8N_DATA="/mnt/data/apps/n8n"

for f in devcontrol-webhook-secret tavily-api-key discord-bot-token; do
  [ -f "/root/.secrets/$f" ] || die "시크릿 없음: /root/.secrets/$f"
done
[ -f "$WF_SRC" ] || die "워크플로 파일 없음: $WF_SRC"

require_root

log "Recreating n8n container (env: 시크릿 주입)"
TV=$(cat /root/.secrets/tavily-api-key)
SECRET=$(cat /root/.secrets/devcontrol-webhook-secret)

incus exec $CONTAINER -- sh -c "docker rm -f n8n >/dev/null 2>&1 || true
docker run -d --name n8n --restart unless-stopped -p 5678:5678 \
  -v /mnt/data/arxiv:/data/arxiv \
  -v /mnt/data/sqlite:/data/arxiv/sqlite \
  -v ${N8N_DATA}:/home/node/.n8n \
  -e GENERIC_TIMEZONE=Asia/Seoul -e TZ=Asia/Seoul \
  -e N8N_SECURE_COOKIE=false \
  -e N8N_BLOCK_ENV_ACCESS_IN_NODE=false \
  -e N8N_LOG_LEVEL=info \
  -e DEVCONTROL_WEBHOOK_SECRET=$SECRET \
  -e TAVILY_API_KEY=$TV \
  docker.n8n.io/n8nio/n8n:2.36.6" >/dev/null

log "Waiting for n8n..."
sleep 15

log "Importing dev-control workflow"
incus file push "$WF_SRC" $CONTAINER/tmp/dev-control.json >/dev/null
incus exec $CONTAINER -- docker cp /tmp/dev-control.json n8n:/tmp/dev-control.json

# 기존 워크플로 삭제 후 재임포트 (id 충돌 방지)
incus exec $CONTAINER -- python3 - << 'PYEOF'
import sqlite3, json, sys
src = json.load(open('/tmp/dev-control.json'))
wf_id = src.get('id', 'dev-control-workflow')
c = sqlite3.connect('/mnt/data/apps/n8n/database.sqlite')
c.execute('delete from workflow_entity where id=? or name=?', (wf_id, 'dev-control'))
c.commit()
print('cleared old workflow')
sys.exit(0)
PYEOF

incus exec $CONTAINER -- sh -c "docker cp /tmp/dev-control.json n8n:/tmp/wf-import.json && docker exec -u node n8n n8n import:workflow --input=/tmp/wf-import.json 2>&1 | grep -iE 'success|error' | tail -1"

log "Activating + restarting n8n"
incus exec $CONTAINER -- sh -c "docker exec -u node n8n n8n update:workflow --id=dev-control-workflow --active=true >/dev/null 2>&1 || true; docker restart n8n >/dev/null"

log "Done. 확인: incus exec apps -- curl -sm 5 http://localhost:5678"
