# 포맷 전 체크리스트

> 날짜: 2026-08-17 (월) 점검 기준
> 대상: GEM12 (Fedora Workstation → Fedora Server + Incus 전환)
> 관련 문서: `gem12-private-cloud-plan-2026-08-17.md`, `gem12-ai-pipeline-2026-08-17.md`, `gem12-first-wifi-tutorial-2026-08-17.md`

포맷은 되돌릴 수 없다. 이 목록을 순서대로 지우면서 진행한다. **A와 B를 끝내기 전에는 포맷하지 않는다.**

---

## A. 데이터 — 잃으면 못 되찾는 것

### A-1. 원격이 없는 저장소 — 처리 완료

| 저장소 | 크기 | 처분 | 상태 |
|---|---:|---|---|
| `personal_labs/comfyui-playground` | 75G | private 저장소 생성 후 push | **완료** |
| `transcodes/tc-ui-components` | 296M | 담당자가 관리 중 | 제외 |
| `transcodes/tc-design-tokens` | 143M | 담당자가 관리 중 | 제외 |
| `personal_labs/cghds_crawl` | 5.3M | 폐기 | 제외 |

`comfyui-playground` 는 `.gitignore` 가 모델과 miniconda, ComfyUI 클론을 제외하고 있어 **실제로 올라간 것은 44개 파일뿐**이다. 75GB는 전부 재생성 가능한 런타임 데이터였다.

올라간 것 중 서버 구축에 쓸 자산은 다음과 같다.

- `Containerfile`, `run-self-build.sh` — ComfyUI 컨테이너 빌드. ai 컨테이너가 Podman이므로 그대로 쓴다
- `patches/` — WAN22 I2V 감지 수정 등 실제로 겪은 문제의 해결책
- `docs/research/2026-05-10_wan22-i2v-rocm-black-output.md` — ROCm 검은 출력 문제 기록
- `download_*.sh`, `tools/download_models.sh` — 모델 재다운로드 스크립트

마지막 항목이 §A-5의 "모델 목록과 다운로드 스크립트를 남긴다"를 이미 충족한다.

### A-2. 미푸시 커밋 — 처리 완료

| 저장소 | 미푸시 | 내용 | 상태 |
|---|---:|---|---|
| `personal_labs/reelmi` | 4 | ComfyUI Podman+ROCm 런타임, SOTA 모델 리서치 | **완료** |
| `personal_labs/ssiat` | 1 | package.json 정리 | **완료** |
| `obsidian/cyprien_vault` | 1 | vault backup | 이미 최신 |
| `bfai/bgs_modeling` | 1 | 회사 작업, 맥북에서 관리 중 | 제외 |

`reelmi` 의 ComfyUI ROCm 기록은 ai 컨테이너 구축에 직접 쓰인다.

### A-3. 미커밋 변경 — 처리 완료

25곳을 훑어 실제 작업물만 가려냈다. 나머지는 도구 부산물(`.serena/`, `.claude/`, `CLAUDE.md`, `package-lock.json`)이거나 담당자가 관리하는 transcodes 저장소다.

| 저장소 | 커밋한 것 |
|---|---|
| `personal_labs/reelmi` | 로컬 LLM 런타임 비교 리서치 — **ai 컨테이너 설계 근거** |
| `personal_labs/moon_bird` | 마이크로 SaaS·RAG·솔로프리너 트렌드 리서치 3건 |
| `personal_labs/seolhap` | Google ADK 심층 분석, Pydantic AI 비교 |
| `moon_bird/automation` | Linear 작업 조회 Python 재작성 |
| `personal_labs/funes_days_alter` | OG 이미지 시안과 브리프 |
| `personal_labs/seolhap_archived` | 자동화 여정 PRD, 킥오프 문서 |

`reelmi` 의 런타임 비교 문서가 특히 중요하다. 7900 XTX에서 Vulkan이 ROCm보다 빠른 사례가 기록돼 있고, 이것이 §4에서 llama.cpp를 Vulkan 백엔드로 쓰는 근거다.

`external_packages/llama.cpp` 의 미추적 스크립트 2개는 dotfiles `commands/llamacpp/` 원본과 동일한 사본이라 조치하지 않았다.

### A-4. Git 밖의 데이터

| 대상 | 확인할 것 |
|---|---|
| `~/Dropbox` (4.7G) | Dropbox 동기화가 최신인지 |
| `~/Downloads` (9.8G) | 보관할 것이 섞여 있는지 |
| `~/Pictures` (717M) | Immich 초기 데이터로 쓸 것이므로 외장에 복사 |
| `~/.gemini`, `~/.codex`, `~/.claude-mem` | 대화 이력 중 남길 것이 있는지 |
| 브라우저 프로필 | 북마크와 확장 설정 |

### A-5. 모델 재다운로드 경로 — 처리 완료

가중치는 백업하지 않는다. 대신 **어디서 받았는지**를 스크립트로 남긴다.

| 대상 | 재다운로드 경로 |
|---|---|
| Muse Glimmer 30B + drafter (17GB) | `commands/llamacpp/download-muse-glimmer.sh` |
| ComfyUI 모델 (65GB) | `comfyui-playground` 의 `download_*.sh` |
| Qwen3-Coder-Next (46GB) | 받지 않는다 |

Qwen3-Coder-Next는 CPU 오프로드 탓에 17 tok/s로 떨어져 실용 범위 밖이었다. **이 장비에서 작동이 확인된 로컬 모델은 Glimmer뿐이다.**

이 판단으로 포맷 후 재다운로드 용량이 128GB에서 82GB로 줄었다.

---

## B. 자격증명 — 브라우저가 필요해 지금 해야 하는 것

포맷 후 서버에는 브라우저가 없다. 발급은 전부 지금 이 기기에서 끝낸다.

| 항목 | 명령 | 보관처 | 상태 |
|---|---|---|---|
| Claude Code 장기 토큰 | `claude setup-token` | 1Password | **발급 완료 (맥북)** |
| rclone Google Drive 토큰 | `rclone authorize "drive"` | 1Password | |
| 맥북 SSH 공개키 | 맥북에서 `cat ~/.ssh/id_ed25519.pub` | 메모 또는 1Password | |
| GitHub PAT (필요시) | github.com 설정 | 1Password | |

**발급은 맥북에서 하는 편이 낫다.** 토큰은 기기에 묶이지 않으므로 발급 위치와 사용 위치가 달라도 되고, 이 기기에서 발급하면 포맷과 함께 잃는다.

서버에서는 환경변수로 넘긴다. `bashrc.template` 이 마지막에 `~/.bashrc.local` 을 읽으므로 그 파일에 둔다. 저장소에서 관리하지 않는 파일이다.

```bash
# 서버의 ~/.bashrc.local
export CLAUDE_CODE_OAUTH_TOKEN="<맥북에서 발급한 토큰>"
```

나중에 서버에 `op` CLI를 인증해두면 평문 대신 1Password에서 읽어올 수 있다.

```bash
export CLAUDE_CODE_OAUTH_TOKEN="$(op read 'op://Private/Claude Code GEM12/credential')"
```

**서버 밖에 둬야 하는 것** — 서버가 죽었을 때 필요한 정보다.

- 1Password 자체 복구 키 → **종이로 오프라인 보관**
- Google 계정 복구 정보
- Wi-Fi SSID와 비밀번호 (Anaconda 설치 관리자의 네트워크 화면에서 입력한다)

---

## C. 하드웨어 확인

### C-1. 확장 슬롯 — 확인 완료, 조치 없음

AOOSTAR 공식 사양이 **M.2 2280 NVMe 2슬롯(PCIe 4.0 x4, 최대 8TB)**이고 "OCuLink 포트는 M.2 슬롯을 점유하지 않는다"고 명시한다. 지금 1슬롯만 쓰고 있으므로 `dmidecode` 가 보고한 빈 슬롯 `U93` 가 M.2다. 케이스를 열 필요가 없다.

**당분간 하드웨어를 추가하지 않기로 했으므로 이번 포맷에서는 조치하지 않는다.** 나중에 용량이 부족해지면 2TB를 꽂는다.

### C-2. 입력 장치

- **유선** 키보드와 마우스 (블루투스는 설치 단계에서 쓸 수 없다)
- 모니터와 케이블

블루투스 어댑터가 AX200에 통합돼 있고 UEFI와 설치 관리자는 USB HID만 인식한다. 포맷하면 `/var/lib/bluetooth` 의 페어링 키도 사라진다.

### C-3. USB 부팅 디스크

**다시 만들어야 한다.** 현재 USB(`/dev/sda`)에는 Proxmox VE 9.2-1이 들어 있다 — Incus 전환 이전에 만든 것이다. **Fedora Server 44 ISO**를 받아 SHA256 검증 후 다시 굽는다.

---

## D. 일정

포맷부터 서비스 재가동까지 **최소 며칠**이 걸린다. 그동안 이 장비의 GPU와 로컬 LLM을 쓸 수 없다. 급한 일정이 없는 시점을 고른다.

데스크톱 이관은 판단이 끝났다. 평소 작업은 맥북에서 하므로 이 장비에서 GNOME이 사라져도 문제되지 않는다.

---

## E. 최종 확인

포맷 직전에 이것만 다시 본다.

```bash
# 1. dotfiles 가 전부 올라갔는가 — 부트스트랩 스크립트가 여기 있다
git -C ~/dotfiles status -sb
git -C ~/dotfiles log --oneline origin/main..HEAD    # 비어 있어야 한다

# 2. 원격 없는 저장소가 남아 있는가
for d in ~/Documents/*/*/; do
  [ -d "$d/.git" ] || continue
  git -C "$d" remote -v 2>/dev/null | grep -q . || echo "원격없음: $d"
done

# 3. 미푸시 커밋이 남아 있는가
for d in ~/Documents/*/*/; do
  [ -d "$d/.git" ] || continue
  n=$(git -C "$d" rev-list --count @{u}..HEAD 2>/dev/null) || continue
  [ "$n" -gt 0 ] 2>/dev/null && echo "미푸시 $n: $d"
done
```

**판정 질문**: 지금 이 장비가 물에 빠져 못 쓰게 되어도 잃는 것이 없는가?

이 질문에 "그렇다"고 답할 수 있으면 포맷한다.

---

## 포맷 후 첫 단계

`gem12-private-cloud-plan-2026-08-17.md` §8 의 1단계부터 진행한다.

1. Fedora Server 설치 — Anaconda 네트워크 화면에서 Wi-Fi 연결, 수동 파티셔닝으로 btrfs 지정
2. 첫 부팅 후 네트워크 확인 — 안 붙어 있으면 `gem12-first-wifi-tutorial-2026-08-17.md` 를 따라 `nmcli` 로 연결
3. `git clone https://github.com/huskyhoochu/dotfiles.git ~/dotfiles`
4. `cd ~/dotfiles/commands/incus && SSH_PUBKEY="..." ./02-host.sh`
