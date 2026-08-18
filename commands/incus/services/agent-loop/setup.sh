#!/usr/bin/env bash
# ci 컨테이너에 에이전트 루프 실행 환경을 세운다. 호스트에서 root 로, 멱등.
#   sudo ./setup.sh
#
# 경계 원칙: 맥은 신호(투입·관찰)만 보내고, 에이전트 루프·도구 실행·추론 호출은
# 전부 서버 안에서 돈다. 근거: 맥→서버 장시간 스트리밍이 하루 4회 끊긴 실측
# (2026-08-18), 같은 날 서버 안 CI 리뷰는 무사고.
#
# 시크릿은 이 스크립트가 만들지 않는다 — ci 의 /etc/agent-loop.env 를 사람이
# 채운다 (env.example 참조).

source "$(dirname "$0")/../../lib.sh"

CONTAINER="ci"
AGENTS_DIR="/opt/agents"
HARNESS_REPO="http://10.10.10.11:3000/b95labs/gem12-agents.git"
TEA_VERSION="0.15.1"

require_root
require_incus
container_exists "$CONTAINER" || die "${CONTAINER} container missing."
ensure_running "$CONTAINER"

# ── 시크릿 전제 ─────────────────────────────────────────────────────

incus exec "$CONTAINER" -- test -s /etc/agent-loop.env \
  || die "ci:/etc/agent-loop.env 가 없다. env.example 을 참고해 채워 넣어라 (root 600)."
incus exec "$CONTAINER" -- chmod 600 /etc/agent-loop.env

# ── 도구 설치 ───────────────────────────────────────────────────────

log "Installing node/npm"
# Fedora 44 의 무접미사 nodejs 는 22 — 버전 접미사 패키지로 24 를 지정한다
incus exec "$CONTAINER" -- dnf install -y -q nodejs24-npm >/dev/null
NODE_V=$(incus exec "$CONTAINER" -- node --version)
case "$NODE_V" in
  v2[4-9]*|v[3-9]*) log "node ${NODE_V}" ;;
  *) die "node >= 24 필요, 현재 ${NODE_V}" ;;
esac

if ! incus exec "$CONTAINER" -- test -x /usr/local/bin/tea; then
  log "Installing tea ${TEA_VERSION}"
  incus exec "$CONTAINER" -- sh -c \
    "curl -fsSL -o /usr/local/bin/tea https://dl.gitea.com/tea/${TEA_VERSION}/tea-${TEA_VERSION}-linux-amd64 && chmod +x /usr/local/bin/tea"
fi

# ── 하네스 클론 + 의존성 ────────────────────────────────────────────

log "Cloning gem12-agents harness"
incus exec "$CONTAINER" -- sh -c "
  set -e
  mkdir -p ${AGENTS_DIR}/work ${AGENTS_DIR}/logs
  set -a; . /etc/agent-loop.env; set +a
  AUTH_REPO=\$(echo '${HARNESS_REPO}' | sed \"s#http://#http://oauth2:\${FORGEJO_TOKEN}@#\")
  if [ -d ${AGENTS_DIR}/gem12-agents/.git ]; then
    git -C ${AGENTS_DIR}/gem12-agents pull -q
  else
    git clone -q \"\$AUTH_REPO\" ${AGENTS_DIR}/gem12-agents
    # 토큰이 원격 URL 에 남지 않게 정리 — push 시점에 다시 주입한다
    git -C ${AGENTS_DIR}/gem12-agents remote set-url origin '${HARNESS_REPO}'
  fi
  cd ${AGENTS_DIR}/gem12-agents && npm ci --silent
"

# ── git 신원과 tea 로그인 ──────────────────────────────────────────

incus exec "$CONTAINER" -- sh -c "
  git config --global user.name  'b95labs-agent'
  git config --global user.email 'dfg1499@gmail.com'
  git config --global init.defaultBranch main
"
incus exec "$CONTAINER" -- sh -c "
  set -a; . /etc/agent-loop.env; set +a
  tea login list 2>/dev/null | grep -q gem12 || \
    tea login add --name gem12 --url http://10.10.10.11:3000 --token \"\$FORGEJO_TOKEN\" >/dev/null
"

# ── 검증 ────────────────────────────────────────────────────────────

echo
incus exec "$CONTAINER" -- sh -c "node --version; tea --version | head -1"
incus exec "$CONTAINER" -- sh -c "cd ${AGENTS_DIR}/gem12-agents && npx flue --version 2>/dev/null | head -1 || echo 'flue: npx 경유 실행 준비됨'"
log "Done. 투입: agent-run.sh 를 보라."
