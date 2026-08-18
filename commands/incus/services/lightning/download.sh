#!/usr/bin/env bash
# Nemotron 3.5 Lightning Q4_0 GGUF 를 ai 컨테이너에 내려받는다 (본체 17.6GiB + MTP 1.1GiB)
#
# 회선을 오래 점유하므로 시점과 속도 제한을 사람이 정한다.
#   sudo ./download.sh [속도제한, 기본 10M]
set -euo pipefail

RATE="${1:-10M}"
BASE=https://huggingface.co/ggml-org/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-GGUF/resolve/main

incus exec ai -- sh -c "
mkdir -p /mnt/data/models && cd /mnt/data/models
for f in NVIDIA-Nemotron-3.5-Lightning-30B-A3B-Q4_0.gguf mtp-NVIDIA-Nemotron-3.5-Lightning-30B-A3B-Q4_0.gguf; do
  [ -s \"\$f\" ] && { echo \"already: \$f\"; continue; }
  curl -fL -C - --limit-rate ${RATE} -o \"\$f.part\" ${BASE}/\$f && mv \"\$f.part\" \"\$f\"
done
ls -la /mnt/data/models/ | grep -i nemotron
"
