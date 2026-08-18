# vault 이관 인수인계 — 2026-08-19 새벽 작업

§1-7 실행 결과와, 사람이 해야 할 남은 작업을 적는다.

## 지금 어떤 상태인가

세 저장소가 Forgejo 원본 체제로 옮겨졌고 새 vault 가 만들어졌다.

| 저장소 | Forgejo | GitHub 미러 | 로컬 |
|---|---|---|---|
| `cyprien_vault` | `b95labs/cyprien_vault` (327M) | 등록됨, **반영 대기** | origin=Forgejo, github=GitHub |
| `funes_days_alter` | `b95labs/funes_days_alter` | 등록됨, **반영 대기** | origin=Forgejo, github=GitHub |
| `b95labs_vault` | `b95labs/b95labs_vault` (신규) | 등록됨, **반영 대기** | origin=Forgejo, github=GitHub |

`~/Documents/personal/b95labs_vault` 가 Obsidian 에 등록돼 있다. 열면 바로 쓸 수 있다.

restic 백업은 `/mnt/data/core` 를 포함하므로 세 저장소 모두 매시 백업에 편입된다.
업로드 상한 1 MiB/s 가 걸려 있어 대량 유입이 회선을 점유하지 않는다.

**첫 대량 사이클은 한 번 실패했다.** 02:17 실행이 Google Drive 500 을 반복해서 받다
24분 만에 `Fatal: unable to save snapshot` 으로 죽었다. 원인은 rclone **공용
client_id** 의 분당 쿼터다 — 로그의 `project_number:202264815644` 가 그것이고,
전 세계 rclone 사용자가 나눠 쓴다. restic 기본 동시성 5로 두드리니 재시도 한도를
넘겼다.

두 번 실패한 뒤 원인이 하나 더 드러났다. **내가 넣은 `--limit-upload 1024` 자체가
실패를 키우고 있었다** — 1 MiB/s 로 조이면 402MB 전송이 7분 이상 걸리고, 그동안
Drive 의 resumable upload 세션이 열려 있어 쿼터·500 을 만날 확률이 올라간다. 상한의
목적이 대량 유입 억제인데 정작 그때 죽으면 뜻이 없다.

그래서 상한을 **4 MiB/s(≈32 Mbps)로 완화**하고 연결을 4개로 두었다. 402MB 를 2분
안에 넘기면서도 가정용 업링크의 일부만 쓴다. 평상시 매시 백업은 수 MB 라 어차피
상한에 닿지 않는다. 03:45 에 이 설정으로 재실행했다.

**근본 해결은 §1-1 에 이미 미결로 있는 개인 client_id 전환**이다 (Google Cloud
콘솔에서 OAuth 클라이언트를 만들어 `rclone config` 에 넣는 웹 작업). 이번 일로
우선순위가 올라갔다 — 공용 client_id 의 쿼터를 전 세계 rclone 사용자와 나누는 한
대량 유입 때마다 같은 위험이 있다.

아침 확인:

```bash
ssh root@gem12 'systemctl show backup.service -p Result --value'   # success 여야 한다
```

`exit-code` 로 나오면 락을 풀고 다시 돌린다.

```bash
ssh root@gem12
export RESTIC_REPOSITORY=rclone:gdrive:gem12-backup \
  RESTIC_PASSWORD_FILE=/root/.restic-password HOME=/root
restic unlock
systemctl start backup.service
```

```bash
ssh root@gem12 'export RESTIC_REPOSITORY=rclone:gdrive:gem12-backup \
  RESTIC_PASSWORD_FILE=/root/.restic-password HOME=/root
restic ls latest | grep -c cyprien_vault'   # 0 이 아니면 편입된 것
```

0 이면 `systemctl start backup.service` 로 한 번 돌리면 된다.

## 반드시 이 순서로 (아침에 할 일)

### 1. GitHub PAT 의 저장소 범위 확장 — 이것부터

`op://Personal/GITHUB_MIRROR_PAT` 은 fine-grained PAT 이고 현재 **polydeukes 에만**
접근이 허용돼 있다. 나머지 세 저장소는 404 라 미러 push 가 403 으로 실패한다.

GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
→ 해당 토큰 → **Repository access** 에 아래 세 개를 추가한다.

- `huskyhoochu/cyprien_vault`
- `huskyhoochu/funes_days_alter`
- `huskyhoochu/b95labs_vault`

권한은 polydeukes 와 같게 **Contents: Read and write**.

### 2. 미러 동기화 트리거

가장 쉬운 길은 웹 UI 다. `https://gem12.tail4555a7.ts.net:3000` → 각 저장소 →
설정 → 미러 → **지금 동기화**.

CLI 로 하려면 토큰을 그때그때 발급해 쓰고 지운다 (작업용 토큰을 남겨두지 않는다).

```bash
ssh root@gem12
TOK=$(incus exec core -- podman exec -u git forgejo \
  forgejo admin user generate-access-token --username b95labs \
  --token-name "sync-$(date +%s)" --scopes write:repository --raw)

for r in cyprien_vault funes_days_alter b95labs_vault; do
  incus exec core -- curl -s -o /dev/null -w "$r: %{http_code}\n" \
    -X POST "http://127.0.0.1:3000/api/v1/repos/b95labs/$r/push_mirrors-sync" \
    -H "Authorization: token $TOK"
done

# 다 쓴 토큰 회수 — CLI 에 삭제 명령이 없고 DELETE API 는 basic auth 를 요구한다
incus exec core -- podman exec forgejo sqlite3 /data/gitea/gitea.db \
  "delete from access_token where name like 'sync-%';"
```

각 200 이면 성공이다.

확인:

```bash
gh api repos/huskyhoochu/b95labs_vault/commits/main --jq .sha   # 85f6c552… 여야 한다
```

### 3. alter 의 GitHub push — 2번 이후에만

**순서가 중요하다.** GitHub 의 `funes_days_alter` 는 아직 옛 스크립트(cyprien_vault 를
clone)를 갖고 있어 현재 배포가 안전하다. 새 스크립트는 `b95labs_vault` 를 clone 하므로,
vault 미러가 비어 있는 상태에서 alter 만 먼저 올리면 **다음 Vercel 빌드가 실패한다.**

```bash
cd ~/Documents/personal/funes_days_alter
git push github main
```

### 4. 실발행 1회 (검증의 마지막 구간)

기존 포스트에 무해한 수정(오타 등)을 넣고 발행한다. Q5 에서 (b)로 정한 방식이다.

```bash
cd ~/Documents/personal/b95labs_vault
# projects/funes_days_blog/<슬러그>/<파일>.md 를 한 줄 고친다

cd ~/Documents/personal/funes_days_alter
pnpm publish:post <슬러그>
```

5단계가 순서대로 지나가면 된다. 3/5 "GitHub 미러 반영 대기"가 새로 들어간 가드다 —
미러가 반영될 때까지 최대 10분 기다렸다가 배포를 트리거한다. 완료되면
`https://funes-days.com` 에서 수정이 보인다.

### 5. cyprien_vault 에서 이동 항목 삭제 — 4번 통과 후

발행이 검증되기 전에는 지우지 않는다.

```bash
cd ~/Documents/personal/cyprien_vault
git rm -r "Efforts/On/funes_days_blog" "Efforts/On/funes_days_roadmap" \
          "Efforts/On/reelmi" "Efforts/On/weave" "Efforts/On/youtube_summary"
git rm "Efforts/Later/셀프호스팅 자율 개발 파이프라인 구축.md" \
       "Efforts/Later/할일 관리는 결국 가장 단순하게.md" \
       "Efforts/Later/AI 에이전트 보안 SaaS 아키텍처 설계.md" \
       "Efforts/Later/AI 에이전트 보안 SaaS 시장성 분석.md" \
       "Efforts/Later/Amazon S3 Files 리서치 리포트.md" \
       "Efforts/Later/Meshy AI 반려동물 앱 도입 검토.md" \
       "Efforts/Later/Obsidian vault를 Claude Code의 RAG 백엔드로 설정하는 방법 — 리서치 리포트.md"
git rm -r "Efforts/Archived/moon_bird" "Efforts/Archived/ai-paper-newsletter" \
          "Efforts/Archived/youtube" "Efforts/Archived/Notes"
git commit -m "vault backup: 활성 작업을 b95labs_vault 로 이관"
git push
```

이력은 git 에 그대로 남는다. 지우는 것은 작업 트리의 사본뿐이다.

## 새 vault 를 다른 노트북에서 쓰려면

```bash
# ① Tailscale 연결 + 서브넷 라우트 10.10.10.0/24 승인 확인
tailscale status | grep gem12

# ② clone
cd ~/Documents/personal
git clone ssh://git@10.10.10.11:2222/b95labs/b95labs_vault.git

# ③ Obsidian 에서 "폴더를 vault 로 열기"
```

`.obsidian/` 이 저장소에 포함돼 있어 플러그인·테마·설정이 따라온다. 첫 실행 때
커뮤니티 플러그인 활성화 확인만 눌러주면 된다.

## 새 vault 의 규약

`b95labs_vault/CLAUDE.md` 가 사람과 AI 사이의 계약이다. 요지는 셋이다.

- **폴더는 `projects/` 와 `journal/` 둘로 시작한다.** 필요해질 때 늘린다
- **frontmatter 최소 스키마**: `type` / `status` / `date`
- **AI 산출물에는 출처 표식**: `author: claude`, `model:`, `reviewed: false`.
  사람이 읽고 손보면 `reviewed: true`

`journal/YYYY-MM-DD.md` 에 작업 기록을 쌓고, 블로그 글감이 될 만한 것에
`#blog-worthy` 를 붙인다.

## 이번에 손댄 것

**dotfiles**

- `commands/incus/services/backup/backup.sh` — restic 업로드 1 MiB/s 상한
- `commands/incus/services/backup/backup-prune.service` — prune 업로드·check 다운로드 상한

**funes_days_alter/scripts** (커밋 `67aa54e`, Forgejo 에만 반영됨)

- `publish_post.sh` — vault 경로 교체, **미러 반영 가드**(3/5 단계) 추가
- `sync_local.sh` — 경로 교체, BSD/GNU `sed -i` 분기 (맥에서 실패하던 것)
- `sync_remote.sh` — clone 대상을 `b95labs_vault` 로
- `og/generate.mjs` — `VAULT_POSTS` 경로 교체

**검증한 것**

- `sync_local.sh` 80편 동기화, 이미지 경로 `./` 변환 정상
- `astro build` 통과 — 80 페이지, 이미지 123개
- `publish_post.sh --dry-run` 5단계 통과

## 알아둘 것

- **`op whoami` 는 미인증으로 나오지만 `op item get` 은 동작한다.** 데스크톱 앱 연동
  세션이라 그렇다. 시크릿 읽기마다 승인 대화상자가 뜨므로 세션 시작 때 한 번에
  읽어두는 편이 낫다
- **Forgejo git SSH 는 `10.10.10.11:2222` 직결이다.** 호스트가 포워딩하지 않으므로
  Tailscale 서브넷 라우트가 있어야 닿는다. HTTPS(:3000)는 tailscale serve 로 열려 있다
- **대량 push 직후 첫 restic 사이클의 로그를 한 번 보라.** Drive 분당 요청 쿼터
  경고 이력이 있다. 상한을 걸어 완화했지만 확인해 두면 좋다

  ```bash
  ssh root@gem12 'journalctl -u backup.service -n 40 --no-pager'
  ```
