#!/usr/bin/env bash
# 에이전트 루프 투입구 — 맥은 이 스크립트를 SSH 한 줄로 부르고 즉시 손을 뗀다.
# 루프는 systemd 일회 유닛으로 ci 컨테이너 안에 남는다 (SSH 가 끊겨도 계속).
#
#   실행:   echo "<task message>" | sudo ./agent-run.sh run <run-id> <owner/repo> [model]
#           model: glimmer(기본) | qwen | 전체 지정자(예: or-extra/...)
#   조회:   sudo ./agent-run.sh status <run-id>
#   목록:   sudo ./agent-run.sh list
#
# 산출물 관측은 PR 코멘트(에이전트가 남김)와 /opt/agents/logs/<run-id>.log,
# 종료 코드는 같은 자리 .status 파일.
set -euo pipefail

CONTAINER="ci"
AGENTS_DIR="/opt/agents"
FORGEJO_HTTP="http://10.10.10.11:3000"

resolve_model() {
  case "$1" in
    */*)       echo "$1" ;;
    glimmer)   echo "glimmer/muse-glimmer" ;;
    qwen)      echo "qwen/qwen3.8" ;;
    *) echo "알 수 없는 모델: $1" >&2; exit 2 ;;
  esac
}

cmd=${1:-}; shift || true
case "$cmd" in
  run)
    RUN_ID=$1; SLUG=$2; MODEL=$(resolve_model "${3:-glimmer}")
    MSG=$(cat)   # 과제 본문은 stdin 으로 — SSH 인용 지옥을 피한다
    [ -n "$MSG" ] || { echo "stdin 으로 과제 메시지를 넘겨라" >&2; exit 2; }

    # 유닛 이름 충돌 방지
    ! incus exec "$CONTAINER" -- systemctl is-active --quiet "agent-${RUN_ID}" \
      || { echo "agent-${RUN_ID} 가 이미 실행 중" >&2; exit 1; }

    # 과제 메시지를 컨테이너에 파일로 전달
    TMP=$(mktemp); printf '%s' "$MSG" > "$TMP"
    incus exec "$CONTAINER" -- mkdir -p "${AGENTS_DIR}/work" "${AGENTS_DIR}/logs"
    incus file push -q "$TMP" "${CONTAINER}${AGENTS_DIR}/work/${RUN_ID}.msg"
    rm -f "$TMP"

    # 작업 저장소 클론 (토큰은 로그·원격 URL 에 남기지 않는다)
    incus exec "$CONTAINER" -- sh -c "
      set -e
      rm -rf ${AGENTS_DIR}/work/${RUN_ID}
      set -a; . /etc/agent-loop.env; set +a
      git clone -q \"${FORGEJO_HTTP%%//*}//oauth2:\${FORGEJO_TOKEN}@${FORGEJO_HTTP#http://}/${SLUG}.git\" ${AGENTS_DIR}/work/${RUN_ID}
      git -C ${AGENTS_DIR}/work/${RUN_ID} config credential.helper \
        '!f() { echo username=oauth2; . /etc/agent-loop.env; echo password=\$FORGEJO_TOKEN; }; f'
      git -C ${AGENTS_DIR}/work/${RUN_ID} remote set-url origin ${FORGEJO_HTTP}/${SLUG}.git
      # 라운드 디렉터리에 잠긴 의존성이 있으면 미리 설치 (없으면 무시)
      for d in ${AGENTS_DIR}/work/${RUN_ID} ${AGENTS_DIR}/work/${RUN_ID}/rounds/*/; do
        [ -f \"\$d/package-lock.json\" ] && (cd \"\$d\" && npm ci --silent) || true
      done
    "

    # 루프를 systemd 일회 유닛으로 — 이 시점 이후 호출자는 필요 없다
    incus exec "$CONTAINER" -- systemd-run --unit="agent-${RUN_ID}" --collect \
      sh -c "set -a; . /etc/agent-loop.env; set +a
        cd ${AGENTS_DIR}/gem12-agents
        IMPL_CWD=${AGENTS_DIR}/work/${RUN_ID} IMPL_MODEL=${MODEL} \
          npx flue run src/agents/implement.ts --id ${RUN_ID} \
          --message \"\$(cat ${AGENTS_DIR}/work/${RUN_ID}.msg)\" \
          > ${AGENTS_DIR}/logs/${RUN_ID}.log 2>&1
        echo \$? > ${AGENTS_DIR}/logs/${RUN_ID}.status"
    echo "투입됨: agent-${RUN_ID} (model ${MODEL}) — 조회: agent-run.sh status ${RUN_ID}"
    ;;

  status)
    RUN_ID=$1
    incus exec "$CONTAINER" -- sh -c "
      systemctl is-active agent-${RUN_ID} 2>/dev/null || true
      [ -f ${AGENTS_DIR}/logs/${RUN_ID}.status ] && echo \"exit: \$(cat ${AGENTS_DIR}/logs/${RUN_ID}.status)\"
      tail -12 ${AGENTS_DIR}/logs/${RUN_ID}.log 2>/dev/null"
    ;;

  list)
    incus exec "$CONTAINER" -- sh -c "
      systemctl list-units 'agent-*' --no-legend --no-pager 2>/dev/null
      ls ${AGENTS_DIR}/logs/ 2>/dev/null | grep '\.status$' | while read -r f; do
        echo \"done: \${f%.status} (exit \$(cat ${AGENTS_DIR}/logs/\$f))\"
      done"
    ;;

  *)
    grep '^#' "$0" | head -12; exit 2 ;;
esac
