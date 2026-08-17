# 포맷 전 체크리스트

> 날짜: 2026-08-17 (월) 점검 기준
> 대상: GEM12 (Fedora Workstation → Proxmox VE 전환)
> 관련 문서: `gem12-private-cloud-plan-2026-08-17.md`, `gem12-ai-pipeline-2026-08-17.md`

포맷은 되돌릴 수 없다. 이 목록을 순서대로 지우면서 진행한다. **A와 B를 끝내기 전에는 포맷하지 않는다.**

---

## A. 데이터 — 잃으면 못 되찾는 것

### A-1. 원격이 없는 저장소 4개

Git 저장소이지만 원격이 없다. 포맷하면 커밋 이력째 사라진다.

| 저장소 | 크기 | 커밋 | 최종 작업일 | 처분 |
|---|---:|---:|---|---|
| `personal_labs/comfyui-playground` | 75G | 12 | 2026-05-28 | 코드만 push, `data/` 는 제외 |
| `transcodes/tc-ui-components` | 296M | 3 | 2025-12-10 | push 또는 폐기 판단 |
| `transcodes/tc-design-tokens` | 143M | 8 | 2025-12-10 | push 또는 폐기 판단 |
| `personal_labs/cghds_crawl` | 5.3M | ? | ? | push 또는 폐기 판단 |

`comfyui-playground` 의 75GB는 대부분 `data/models` 다. **모델은 재다운로드할 수 있으므로 push 대상이 아니다.** 워크플로와 커스텀 노드 설정만 올린다.

```bash
cd ~/Documents/personal_labs/comfyui-playground
cat .gitignore              # data/ 가 제외돼 있는지 확인
gh repo create comfyui-playground --private --source=. --push
```

나머지 셋은 지금도 쓸 것인지 판단한다. 안 쓴다면 그대로 두고 넘어가도 된다 — 다만 **판단을 미루면 그것이 곧 폐기다.**

### A-2. 미푸시 커밋 4곳

원격은 있는데 로컬 커밋이 올라가지 않았다.

| 저장소 | 미푸시 | 내용 |
|---|---:|---|
| `personal_labs/reelmi` | 4 | ComfyUI Podman+ROCm 런타임, SOTA 모델 리서치 |
| `personal_labs/ssiat` | 1 | package.json 정리 |
| `bfai/bgs_modeling` | 1 | Photo → AI Prompt → Text-to-3D 파이프라인 |
| `obsidian/cyprien_vault` | 1 | vault backup 2026-08-06 |

```bash
for d in ~/Documents/personal_labs/reelmi ~/Documents/personal_labs/ssiat \
         ~/Documents/bfai/bgs_modeling ~/Documents/obsidian/cyprien_vault; do
  echo "--- $d"; git -C "$d" push
done
```

`reelmi` 의 ComfyUI ROCm 기록은 **ai-lxc 구축에 직접 쓰인다.** 반드시 올린다.

### A-3. 미커밋 변경 25곳

`git status` 에 잡히는 변경이 있는 저장소가 25곳이다. 대부분 빌드 산출물이나 로컬 설정일 것이므로 일괄 커밋하지 않는다. 다음으로 실제 소스 변경만 가려낸다.

```bash
for d in ~/Documents/*/*/; do
  [ -d "$d/.git" ] || continue
  n=$(git -C "$d" status --porcelain 2>/dev/null | grep -vE '\.(log|lock)$|node_modules|dist/|build/' | wc -l)
  [ "$n" -gt 0 ] && { echo "=== $d"; git -C "$d" status --short | head -10; }
done
```

### A-4. Git 밖의 데이터

| 대상 | 확인할 것 |
|---|---|
| `~/Dropbox` (4.7G) | Dropbox 동기화가 최신인지 |
| `~/Downloads` (9.8G) | 보관할 것이 섞여 있는지 |
| `~/Pictures` (717M) | Immich 초기 데이터로 쓸 것이므로 외장에 복사 |
| `~/.gemini`, `~/.codex`, `~/.claude-mem` | 대화 이력 중 남길 것이 있는지 |
| 브라우저 프로필 | 북마크와 확장 설정 |

### A-5. 모델 목록 저장

가중치 128GB는 백업하지 않는다. 대신 **무엇을 받았는지** 기록을 남긴다.

```bash
find ~/Documents/models \
     ~/Documents/personal_labs/comfyui-playground/data/models \
     \( -name "*.gguf" -o -name "*.safetensors" \) -printf '%s\t%p\n' \
  | sort -rn > ~/dotfiles/docs/models-manifest.txt
git -C ~/dotfiles add docs/models-manifest.txt && git -C ~/dotfiles commit -m "docs: 모델 목록 스냅샷"
```

---

## B. 자격증명 — 브라우저가 필요해 지금 해야 하는 것

포맷 후 서버에는 브라우저가 없다. 발급은 전부 지금 이 기기에서 끝낸다.

| 항목 | 명령 | 보관처 |
|---|---|---|
| Claude Code 장기 토큰 | `claude setup-token` | 1Password |
| rclone Google Drive 토큰 | `rclone authorize "drive"` | 1Password |
| 맥북 SSH 공개키 | 맥북에서 `cat ~/.ssh/id_ed25519.pub` | 메모 또는 1Password |
| GitHub PAT (필요시) | github.com 설정 | 1Password |

**서버 밖에 둬야 하는 것** — 서버가 죽었을 때 필요한 정보다.

- 1Password 자체 복구 키 → **종이로 오프라인 보관**
- Google 계정 복구 정보
- Wi-Fi SSID와 비밀번호 (설치 직후 콘솔에서 손으로 입력한다)

---

## C. 하드웨어 확인

### C-1. `U93` 슬롯 물리 확인

`dmidecode` 는 빈 슬롯 `U93` 를 보고하지만, M.2인지 OCuLink인지 Wi-Fi인지 구분하지 못한다. **케이스를 열어 눈으로 본다.**

M.2로 확인되면 2TB 추가를 검토한다. 모델 230GB를 별도 디스크로 옮기면 1TB의 용량 압박이 사라진다.

### C-2. 입력 장치

- **유선** 키보드와 마우스 (블루투스는 설치 단계에서 쓸 수 없다)
- 모니터와 케이블

블루투스 어댑터가 AX200에 통합돼 있고 UEFI와 설치 관리자는 USB HID만 인식한다. 포맷하면 `/var/lib/bluetooth` 의 페어링 키도 사라진다.

### C-3. USB 부팅 디스크

준비 완료. Proxmox VE 9.2-1, SHA256 검증 통과, `/dev/sda` 에 기록됨.

---

## D. 되돌릴 수 없는 결정 — 미리 시험할 것

### D-1. 맥북 단독 작업 시험

Proxmox로 전환하면 이 장비에서 GNOME 데스크톱은 사라진다. **며칠 맥북만으로 평소 작업을 해보고 문제가 없는지 확인한다.**

특히 확인할 것은 다음과 같다.

- 로컬 LLM 없이 작업이 되는가 (서버 구축 전까지 Glimmer를 못 쓴다)
- ComfyUI 작업을 얼마나 자주 하는가
- 맥북 성능으로 충분한 작업인가

### D-2. 다운타임 감당 여부

포맷부터 서비스 재가동까지 **최소 며칠**이 걸린다. 그 사이 이 장비의 GPU와 로컬 LLM을 쓸 수 없다. 급한 일정이 없는 시점을 고른다.

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

1. Proxmox VE 설치 (네트워크 없이 완료)
2. 콘솔에서 Wi-Fi 연결 — `commands/proxmox/01-network.sh` 를 손으로 옮겨 실행
3. `git clone https://github.com/huskyhoochu/dotfiles.git ~/dotfiles`
4. `SSH_PUBKEY="..." ./02-host.sh`
