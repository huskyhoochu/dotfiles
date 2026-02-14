#!/bin/bash
# claude-mem worker가 생성한 초과 프로세스 정리
# 대상 1: chroma-mcp (벡터 DB) - PPID 기반 그룹당 최신 1개 보존
# 대상 2: claude sonnet 서브에이전트 - worker 자식 중 최신 1개만 보존
set -euo pipefail

KILL_LIST=""

# --- 1) chroma-mcp 정리 ---
UV_PIDS=$(pgrep -f "uv tool uvx.*chroma-mcp" 2>/dev/null || true)
if [ -n "$UV_PIDS" ]; then
    PROC_INFO=""
    for pid in $UV_PIDS; do
        ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ') || continue
        PROC_INFO=$(printf '%s\n%s %s' "$PROC_INFO" "$pid" "$ppid")
    done
    PROC_INFO=$(echo "$PROC_INFO" | sed '/^$/d')

    if [ -n "$PROC_INFO" ]; then
        # 고아 프로세스(PPID=1) 전부 수집
        KILL_LIST=$(echo "$PROC_INFO" | awk '$2 == 1 { print $1 }')

        # PPID별 그룹에서 최신 1개만 보존
        LIVE=$(echo "$PROC_INFO" | awk '$2 != 1 { print $1, $2 }')
        if [ -n "$LIVE" ]; then
            KEEP=$(echo "$LIVE" | sort -k2,2 -k1,1rn | awk '!seen[$2]++ { print $1 }')
            EXCESS=$(echo "$LIVE" | while read pid ppid; do
                echo "$KEEP" | grep -qw "$pid" || echo "$pid"
            done)
            [ -n "$EXCESS" ] && KILL_LIST=$(printf '%s\n%s' "$KILL_LIST" "$EXCESS")
        fi
    fi
fi

# --- 2) claude-mem 서브에이전트 정리 ---
WORKER_PID=$(pgrep -f "worker-service\.cjs --daemon" 2>/dev/null || true)
if [ -n "$WORKER_PID" ]; then
    # worker의 직접 자식 중 claude 서브에이전트만 찾기
    SUB_PIDS=$(pgrep -P "$WORKER_PID" -f "claude.*--output-format stream-json" 2>/dev/null || true)
    if [ -n "$SUB_PIDS" ]; then
        # PID가 가장 큰 것(최신)만 보존
        KEEP_SUB=$(echo "$SUB_PIDS" | sort -rn | head -1)
        for pid in $SUB_PIDS; do
            [ "$pid" != "$KEEP_SUB" ] && KILL_LIST=$(printf '%s\n%s' "$KILL_LIST" "$pid")
        done
    fi
fi

KILL_LIST=$(echo "$KILL_LIST" | sed '/^$/d')
[ -z "$KILL_LIST" ] && exit 0

KILLED=0
for pid in $KILL_LIST; do
    for child in $(pgrep -P "$pid" 2>/dev/null || true); do
        kill -15 "$child" 2>/dev/null || true
    done
    kill -15 "$pid" 2>/dev/null || true
    KILLED=$((KILLED + 1))
done

sleep 0.5
for pid in $KILL_LIST; do
    kill -9 "$pid" 2>/dev/null || true
    for child in $(pgrep -P "$pid" 2>/dev/null || true); do
        kill -9 "$child" 2>/dev/null || true
    done
done

echo "Cleaned up $KILLED excess claude-mem process(es)" >&2
exit 0
