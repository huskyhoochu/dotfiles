#!/bin/bash
# cleanup-orphaned-claude.sh
# OS를 감지하여 플랫폼별 정리 스크립트를 실행하는 디스패처

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
    Darwin) exec "$SCRIPT_DIR/cleanup-orphaned-claude-macos.sh" ;;
    Linux)  exec "$SCRIPT_DIR/cleanup-orphaned-claude-linux.sh" ;;
    *)      echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
