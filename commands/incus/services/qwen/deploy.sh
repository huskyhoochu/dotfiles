#!/usr/bin/env bash
# ai 컨테이너에 Qwen 3.8-27B llama.cpp 서버를 systemd 서비스로 배포한다
#
# 호스트에서 root 로 실행한다. 여러 번 실행해도 안전하다.
#   sudo ./deploy.sh
#
# Glimmer·Lightning 과 상호 배타(Conflicts=)라, 이 서비스를 켜면 둘 다 내려간다.
# 전환:  systemctl start qwen  /  systemctl start glimmer  /  systemctl start lightning
#
# 모델 가중치는 이 스크립트가 받지 않는다 — download.sh 를 따로 실행한다.
#
# 배포 끝에 짧은 프롬프트로 출력 일관성을 검사한다. qwen35 계열이 7900 XTX
# Vulkan 에서 정상 속도로 깨진 텍스트를 낸 이력(#20651)이 있어 /v1/models 응답만으로는
# 기동 성공을 판정할 수 없다.

source "$(dirname "$0")/../../lib.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER="ai"
MODEL="/mnt/data/models/Qwen3.8-27B-Q4_K_M.gguf"
BIN="/opt/llama.cpp/build/bin/llama-server"
API="http://10.10.10.14:8083"

require_root
require_incus

container_exists "$CONTAINER" || die "${CONTAINER} container missing. Run 03-containers.sh first."
ensure_running "$CONTAINER"

# ── 전제 확인 ───────────────────────────────────────────────────────

incus exec "$CONTAINER" -- test -x "$BIN" \
  || die "llama-server not built. See ../glimmer/build.sh"
incus exec "$CONTAINER" -- test -s "$MODEL" \
  || die "Model missing: ${MODEL}. Run download.sh first."

log "Prerequisites OK"

# ── 유닛 배포 ───────────────────────────────────────────────────────

log "Deploying systemd unit"
incus file push "${SCRIPT_DIR}/qwen.service" \
  "${CONTAINER}/etc/systemd/system/qwen.service"
incus exec "$CONTAINER" -- systemctl daemon-reload

# Conflicts= 라 start 가 glimmer/lightning 을 내린다 — 의도된 동작
log "Starting qwen.service (glimmer/lightning 이 켜져 있으면 내려간다)"
incus exec "$CONTAINER" -- systemctl restart qwen

# 부팅 기본은 여전히 glimmer 다. qwen 은 수동 전환 전용이므로 enable 하지 않는다.

# ── 기동 대기 ───────────────────────────────────────────────────────

log "Waiting for the model to load (up to 5 minutes)"
for _ in $(seq 1 60); do
  if incus exec "$CONTAINER" -- curl -fso /dev/null "${API}/v1/models"; then
    READY=1
    break
  fi
  sleep 5
done
[ -n "${READY:-}" ] \
  && log "Qwen is up" \
  || die "Qwen did not come up. Check: incus exec ${CONTAINER} -- journalctl -u qwen"

# ── 출력 일관성 검사 ────────────────────────────────────────────────
# 사고 모드를 끄고 짧은 사실 질문을 던진다. 답에 "Paris" 가 없으면 GDN 층이
# 깨진 것으로 본다 — 판단은 사람이 하므로 실패해도 유닛은 내리지 않는다.

log "Sanity check (short prompt, thinking off)"
REPLY=$(incus exec "$CONTAINER" -- curl -fs -m 120 "${API}/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3.8","messages":[{"role":"user","content":"What is the capital of France? Answer in one word."}],"max_tokens":32,"chat_template_kwargs":{"enable_thinking":false}}' \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["choices"][0]["message"]["content"].strip())' 2>/dev/null || echo "<no reply>")

echo "  reply: ${REPLY}"
case "$REPLY" in
  *Paris*) log "Sanity check OK" ;;
  *) warn "Unexpected reply — GDN 층이 Vulkan 에서 깨졌을 수 있다. journalctl 과 llama.cpp #20651 을 본다." ;;
esac

# ── 결과 ────────────────────────────────────────────────────────────

echo
incus exec "$CONTAINER" -- sh -c \
  "awk '{printf \"  VRAM: %.0f MiB used\n\", \$1/1024/1024}' /sys/class/drm/card1/device/mem_info_vram_used"

echo
log "Done."
echo "  API: ${API}/v1"
echo "  Glimmer 복귀: incus exec ${CONTAINER} -- systemctl start glimmer"
