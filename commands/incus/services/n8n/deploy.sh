#!/usr/bin/env bash
# apps 컨테이너의 n8n을 재구성하고 dev-control 워크플로를 배포한다
#
# 호스트(gem12)에서 root로 실행한다.
#   sudo ./deploy.sh
#
# 하는 일:
#   1. /root/.secrets/ 의 시크릿으로 n8n 컨테이너를 재생성(env 주입)
#   2. workflows/*.json 을 전부 import + 활성화
#
# 전제:
#   - /root/.secrets/{devcontrol-webhook-secret,tavily-api-key,discord-bot-token,ledger-token} 존재
#   - n8n credential(Forgejo DevControl·Discord Bot·OpenRouter·Tavily Bearer
#     ·DevControl Shared Secret)은 DB에 이미 있음 — 볼륨(/mnt/data/n8n)이
#     유지되는 한 재주입 불필요. cred-ledger 만 이 스크립트가 멱등하게 넣는다

source "$(dirname "$0")/../../lib.sh"

CONTAINER="apps"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WF_DIR="$SCRIPT_DIR/workflows"
N8N_DATA="/mnt/data/n8n"

for f in devcontrol-webhook-secret tavily-api-key discord-bot-token ledger-token; do
  [ -f "/root/.secrets/$f" ] || die "시크릿 없음: /root/.secrets/$f"
done
ls "$WF_DIR"/*.json >/dev/null 2>&1 || die "워크플로 파일 없음: $WF_DIR/*.json"

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
  -e N8N_HOST=gem12.tail4555a7.ts.net -e N8N_PROTOCOL=https \
  -e N8N_WEBHOOK_URL=https://gem12.tail4555a7.ts.net/ \
  -e NODE_FUNCTION_ALLOW_BUILTIN=crypto \
  -e N8N_SECURE_COOKIE=false \
  -e N8N_BLOCK_ENV_ACCESS_IN_NODE=false \
  -e N8N_LOG_LEVEL=info \
  -e DEVCONTROL_WEBHOOK_SECRET=$SECRET \
  -e TAVILY_API_KEY=$TV \
  docker.n8n.io/n8nio/n8n:2.36.6" >/dev/null

log "Waiting for n8n..."
sleep 15

# cred-ledger 는 이 저장소가 워크플로와 함께 소유한다 — 볼륨을 잃으면 워크플로가
# 조용히 401 을 받으므로, 다른 credential 과 달리 배포가 매번 보장한다.
log "Ensuring credential: cred-ledger"
# 토큰을 셸 인용에 태우지 않는다 — 파일로 만들어 밀어 넣는다(워크플로와 같은 방식).
CRED_TMP=$(mktemp)
python3 -c "import json,sys; json.dump([{'id':'cred-ledger','name':'Ledger Bearer','type':'httpBearerAuth','data':{'token':open('/root/.secrets/ledger-token').read().strip()}}], open(sys.argv[1],'w'))" "$CRED_TMP"
incus file push "$CRED_TMP" $CONTAINER/tmp/cred-ledger.json >/dev/null
rm -f "$CRED_TMP"
incus exec $CONTAINER -- sh -c "docker cp /tmp/cred-ledger.json n8n:/tmp/cred-ledger.json && docker exec -u node n8n n8n import:credentials --input=/tmp/cred-ledger.json 2>&1 | grep -iE 'success|error' | tail -1; rm -f /tmp/cred-ledger.json"

log "Importing workflows: $(ls "$WF_DIR" | tr '\n' ' ')"
for wf in "$WF_DIR"/*.json; do
  incus file push "$wf" $CONTAINER/tmp/wf-import.json >/dev/null
  # 기존 워크플로 삭제 후 재임포트 (id 충돌 방지). import:workflow 는 top-level id 가 없으면 NOT NULL 제약으로 실패한다
  incus exec $CONTAINER -- python3 - << 'PYEOF'
import sqlite3, json
p = '/tmp/wf-import.json'
src = json.load(open(p))
if not src.get('id'):
    src['id'] = src['name'] + '-workflow'
    json.dump(src, open(p, 'w'), ensure_ascii=False)
c = sqlite3.connect('/mnt/data/n8n/database.sqlite')
c.execute('delete from workflow_entity where id=? or name=?', (src['id'], src['name']))
c.commit()
print('cleared', src['id'])
PYEOF
  incus exec $CONTAINER -- sh -c "docker cp /tmp/wf-import.json n8n:/tmp/wf-import.json && docker exec -u node n8n n8n import:workflow --input=/tmp/wf-import.json 2>&1 | grep -iE 'success|error' | tail -1"
done

log "Activating + restarting n8n"
# 2.x 는 서브워크플로도 활성(published) 상태여야 toolWorkflow 가 호출할 수 있다
for wf in "$WF_DIR"/*.json; do
  wf_id=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('id') or json.load(open(sys.argv[1]))['name']+'-workflow')" "$wf")
  incus exec $CONTAINER -- sh -c "docker exec -u node n8n n8n update:workflow --id=$wf_id --active=true >/dev/null 2>&1 || true"
done
incus exec $CONTAINER -- docker restart n8n >/dev/null

log "Done. 확인: incus exec apps -- curl -sm 5 http://localhost:5678"
