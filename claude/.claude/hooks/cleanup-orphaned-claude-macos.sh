#!/bin/bash
# cleanup-orphaned-claude-macos.sh
# macOS용: 고아 상태의 claude 서브에이전트 프로세스를 정리하는 스크립트
#
# 정리 대상: TTY 없이(??) 떠 있는 stream-json 모드 서브에이전트
# 보존 대상: 터미널에 연결된 활성 claude 세션 및 그 직계 자식 프로세스

set -euo pipefail

# 현재 프로세스 트리 보존을 위해 자신의 PID와 부모 트리 수집
SELF_PID=$$
PARENT_CHAIN=""
pid=$SELF_PID
while [ "$pid" -gt 1 ] 2>/dev/null; do
    PARENT_CHAIN="$PARENT_CHAIN $pid"
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ') || break
done

# macOS: TTY가 "??"인 고아 서브에이전트 찾기
ORPHANED_PIDS=$(ps aux | awk '
    $7 == "??" && /claude/ && /--output-format.*stream-json/ {
        print $2
    }
')

if [ -z "$ORPHANED_PIDS" ]; then
    exit 0
fi

# 부모 체인에 속한 PID는 제외
KILL_PIDS=""
for pid in $ORPHANED_PIDS; do
    if ! echo "$PARENT_CHAIN" | grep -qw "$pid"; then
        KILL_PIDS="$KILL_PIDS $pid"
    fi
done

if [ -z "$KILL_PIDS" ]; then
    exit 0
fi

COUNT=$(echo "$KILL_PIDS" | wc -w | tr -d ' ')

# SIGTERM으로 graceful 종료 시도
echo "$KILL_PIDS" | xargs kill -15 2>/dev/null || true

# 1초 대기 후 남은 프로세스 강제 종료
sleep 1
for pid in $KILL_PIDS; do
    if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
    fi
done

echo "Cleaned up $COUNT orphaned claude subagent(s)" >&2
exit 0
