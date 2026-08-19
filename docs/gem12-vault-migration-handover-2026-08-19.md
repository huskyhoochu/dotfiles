# vault 이관 실행 기록 — 2026-08-19

§1-7 을 실행하며 겪은 것과 그때 내린 판단을 적는다. 절차는 끝났고, 여기 남는 값은
**재현이 필요할 때 쓸 명령어와 실측으로 확인한 함정**이다.

## 최종 상태

세 저장소가 Forgejo 원본 + GitHub private 미러 체제로 옮겨졌고 새 vault 가 만들어졌다.

| 저장소 | Forgejo | GitHub 미러 | 로컬 |
|---|---|---|---|
| `cyprien_vault` | `b95labs/cyprien_vault` | 반영됨 | origin=Forgejo, github=GitHub |
| `funes_days_alter` | `b95labs/funes_days_alter` | 반영됨 | origin=Forgejo, github=GitHub |
| `b95labs_vault` | `b95labs/b95labs_vault` (신규) | 반영됨 | origin=Forgejo, github=GitHub |

셋 다 local=forgejo=github 3중 일치를 확인했다.
`~/Documents/personal/b95labs_vault` 는 Obsidian 에 등록돼 있다.

**검증한 것**: 이관본 339개 파일 전수 대조(차이는 의도한 이미지 경로 수정 2건뿐),
`sync_remote` 경로 재현(미러 clone → 변환 → astro build 80페이지), 실발행 1회
(미러 가드 통과 → Vercel success), 백업 편입(`restic ls` 로 저장소 3개 확인).

restic 백업은 `/mnt/data/core` 를 포함하므로 세 저장소 모두 매시 백업에 들어간다.

**첫 대량 사이클은 한 번 실패했다.** 02:17 실행이 Google Drive 500 을 반복해서 받다
24분 만에 `Fatal: unable to save snapshot` 으로 죽었다. 원인은 rclone **공용
client_id** 의 분당 쿼터다 — 로그의 `project_number:202264815644` 가 그것이고,
전 세계 rclone 사용자가 나눠 쓴다. restic 기본 동시성 5로 두드리니 재시도 한도를
넘겼다.

세 번 실패하며 진단이 두 번 바뀌었다. 기록해 둔다.

1. **동시성 탓으로 봄** → `-o rclone.connections=2`. 실패.
2. **상한(1 MiB/s)이 전송을 늘려 세션이 오래 열리는 탓으로 봄** → 4 MiB/s 로 완화. 실패.
3. **오류 분포를 세어 보니 답이 나왔다** — 세 번째 실행 로그에 `rateLimitExceeded`
   22건, 500 은 11건. **500 은 쿼터의 파생이고 근본은 분당 요청 수**다. 상한을
   완화해도 총 요청 수는 그대로라 쿼터는 똑같이 소진된다.

그래서 **요청 빈도 자체를 낮췄다**: rclone 의 `--tpslimit 4`(초당 트랜잭션 4개)와
`--drive-pacer-min-sleep 200ms`, 재시도 20회.

**결과: 통과했다.** 968MiB 를 11분 20초에 rateLimit **0건**으로 올리고 스냅샷
`cdfad024` 를 저장했다. `restic ls` 로 `cyprien_vault.git`·`b95labs_vault.git`·
`funes_days_alter.git` 세 개가 백업에 들어간 것을 확인했다. 이 설정은
`backup.sh`·`backup-prune.service` 에 정식 반영해 배포했다.

교훈 하나: **오류 메시지가 아니라 오류 분포를 세어야 했다.** 눈에 띄는 500 을 쫓느라
두 번 헛짚었고, 유형별로 집계하자 바로 드러났다.

**근본 해결은 §1-1 에 이미 미결로 있는 개인 client_id 전환**이다 (Google Cloud
콘솔에서 OAuth 클라이언트를 만들어 `rclone config` 에 넣는 웹 작업). 이번 일로
우선순위가 올라갔다 — 공용 client_id 의 쿼터를 전 세계 rclone 사용자와 나누는 한
대량 유입 때마다 같은 위험이 있다.

백업이 실패했을 때의 확인·복구:

```bash
ssh root@gem12 'systemctl show backup.service -p Result --value'   # success 여야 한다
```

`exit-code` 로 나오면 락을 풀고 다시 돌린다. **실패 뒤에는 반드시 락을 풀어야 한다** —
스테일 락이 남으면 이후 모든 백업이 막힌다.

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

## 실행 순서와 그때의 판단 (전부 완료)

순서에 의존성이 있었다. 아래는 그 이유와 함께 남기는 기록이다.

### 1. GitHub PAT 의 저장소 범위 확장 ✅

`op://Personal/GITHUB_MIRROR_PAT` 은 fine-grained PAT 이라 **저장소를 하나씩 허용**해야
한다. 이관 직후에는 polydeukes 에만 허용돼 있어 나머지 셋은 404, 미러 push 가 403 으로
실패했다. `healthcheck.service` 가 이걸 `DOWN: mirror:...` 로 정확히 잡아냈다(오탐 아님).

**API 로는 바꿀 수 없다.** GitHub → Settings → Developer settings → Personal access
tokens → Fine-grained tokens → 해당 토큰 → **Repository access** 에서 저장소를 추가한다.
권한은 polydeukes 와 같게 **Contents: Read and write**.

앞으로 Forgejo 에 새 저장소를 만들고 미러를 걸 때마다 이 작업이 필요하다.

### 2. 미러 동기화 트리거 ✅

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

### 3. alter 의 GitHub push — 불필요했다

여기에 순서 의존성이 있었다. GitHub 의 `funes_days_alter` 는 새 스크립트를 받으면
`b95labs_vault` 를 clone 하는데, **vault 미러가 비어 있는 상태에서 alter 만 먼저
올리면 다음 Vercel 빌드가 실패한다.** 그래서 밤사이엔 Forgejo 에만 push 하고 GitHub
쪽은 보류했다.

결과적으로 2번에서 미러가 켜지자 push mirror 가 alter 의 새 커밋도 함께 밀어 올려
수동 push 가 필요 없어졌다. 순서도 자연히 지켜졌다 — vault 미러가 채워진 뒤 alter 가
반영됐다.

### 4. 실발행 1회 ✅

발행 소재를 찾다가 몇 가지를 확인했다. 최신 글에는 고칠 오타가 없었고(남의 글을 임의로
바꾸는 건 부적절), 이관 대상 80편은 구 vault 와 파일 단위로 완전 일치했다. og 카드가
없는 5편은 누락이 아니라 전부 `draft: true` 초안이라 생성기가 정상적으로 건너뛴 것이었다.

그래서 실질 변경 없이 배포만 재실행했는데, **리허설 목적으로는 오히려 이상적**이었다 —
새 파이프라인이 전 구간을 도는 동안 사이트 내용은 그대로 유지됐다.

```bash
cd ~/Documents/personal/funes_days_alter
pnpm publish:post          # 또는 pnpm publish:post <슬러그>
```

5단계가 순서대로 지나갔다: og 75편 확인 → vault 변경 없음 → **미러 반영 확인
(85f6c552)** → Forgejo push `67aa54e..7c02ff0` → Vercel pending ×4 → **success**.

3/5 가 이번 이관의 핵심 산출물이다. GitHub 이 비동기 미러가 됐으니, 이 가드가 없으면
반영 전에 빌드가 시작돼 **옛 원고로 "성공"하는 오배포**가 난다.

배포 검증: 메인 200, `career` 200, 경로를 고친 이미지 2개가 Astro 자산으로 정상
렌더링, sitemap 79 URL.

### 5. cyprien_vault 에서 이동 항목 삭제 ✅

지우기 전에 339개 파일을 전수 대조했다(`filecmp`). 차이는 의도한 이미지 경로 수정
2건뿐이었다.

```bash
cd ~/Documents/personal/cyprien_vault
git rm -r "Efforts/On/funes_days_blog" "Efforts/On/funes_days_roadmap" \
          "Efforts/On/reelmi" "Efforts/On/weave" "Efforts/On/youtube_summary"
git rm "Efforts/Later/셀프호스팅 자율 개발 파이프라인 구축.md" ...  # 사업·개발 7건
git rm -r "Efforts/Archived/moon_bird" "Efforts/Archived/ai-paper-newsletter" \
          "Efforts/Archived/youtube" "Efforts/Archived/Notes"
git commit -m "vault backup: 활성 작업을 b95labs_vault 로 이관"
git push
```

이력은 git 에 그대로 남는다. 지운 것은 작업 트리의 사본뿐이다.

남은 것: `Efforts/On/youth`(성당 회의록), `Archived/오늘부터 하모니`·`dorim`(연재·연극),
`Later/` 의 묵주기도·산만한 목표들·소설 2.

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

- `backup.sh` — 업로드 4 MiB/s 상한, `rclone.connections=2`, **`--tpslimit 4`**
- `backup-prune.service` — prune·check 에 같은 설정

**funes_days_alter/scripts** (커밋 `67aa54e`)

- `publish_post.sh` — vault 경로 교체, **미러 반영 가드**(3/5 단계) 추가
- `sync_local.sh` — 경로 교체, BSD/GNU `sed -i` 분기 (맥에서 실패하던 것)
- `sync_remote.sh` — clone 대상을 `b95labs_vault` 로
- `og/generate.mjs` — `VAULT_POSTS` 경로 교체

**새로 만든 것**

- `b95labs_vault` — `projects/` + `journal/` + `CLAUDE.md` 계약, 노트 127개

**검증한 것**

- 이관본 339개 파일 전수 대조 (차이는 의도한 경로 수정 2건)
- `sync_local` 80편 + `astro build` 80페이지·이미지 123개
- `sync_remote` 경로 재현 — 미러 clone → 변환 → 빌드 통과
- `publish_post` dry-run + **실발행 1회** (미러 가드 통과, Vercel success)
- 다른 노트북용 clone 재현 (플러그인·설정 계승 확인)
- restic 백업 편입 — 968MiB, rateLimit 0건, `restic ls` 로 저장소 3개 확인

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
