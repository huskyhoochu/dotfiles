# Discord 개발 파이프라인 제어 + YouTube Discover — 설계

> 날짜: 2026-08-25
> 전제 인프라: [operations.md](operations.md)
> 출발점: `~/Documents/cghds_n8n` 의 디스코드 봇 구성에서 컨셉을 가져온다.
> 상태: 설계. 구현은 아직 시작하지 않았다.

## 한줄 요약

디스코드를 GEM12 개발 파이프라인의 리모컨으로 삼는다 — `/task` 로 Forgejo 에이전트
루프를 투입하고 완료·실패를 받아보고, 별도 파이프라인으로 AI·1인사업 관련 유튜브
영상을 매일 발굴해 요약한 뒤 NocoDB 에 적재한다. 두 파이프라인 모두 n8n 이 중심에
있고, 디스코드 어댑터는 지능 없는 전달자로 남긴다(cghds 의 얇은 어댑터 원칙).

---

## 1. 전체 그림

```text
┌─ 제어 평면 ────────────────────────────────────────────────┐
│  Discord (사람)                                             │
│    ↕ slash command / 이벤트 알림                             │
│  discord-bot-adapter (apps)                                 │
│    ↕ webhook + shared secret                                │
│  n8n (apps :5678) — 라우팅·포맷·스케줄링                     │
│    ├→ Forgejo API (core :3000) — 이슈 생성·조회             │
│    ├→ agent-run.sh (ci) — 에이전트 루프 투입·상태 조회      │
│    └→ Discord REST — 완료·실패 알림 posting                 │
└─────────────────────────────────────────────────────────────┘

┌─ YouTube Discover 파이프라인 ──────────────────────────────┐
│  n8n cron (매일)                                            │
│    1. Discover — 키워드 검색으로 신규 영상 수집              │
│    2. Dedupe — NocoDB 기존 레코드와 대조                    │
│    3. Interpret — 자막 수집 → LLM 요약                      │
│    4. Persist — NocoDB youtube-discover 베이스에 적재       │
│    5. 주간 digest → Discord posting (선택)                  │
└─────────────────────────────────────────────────────────────┘
```

## 2. Part A — Discord ↔ Forgejo 개발 파이프라인 제어

### A1. 어댑터

cghds 의 `discord/adapter`(discord.js 14, TypeScript)를 축소해 옮긴다.

가져올 것:
- Gateway 연결과 슬래시 커맨드 등록
- `ALLOWED_USER_IDS` 허용 목록 게이트(목록 밖은 ephemeral 거부)
- deferReply → n8n 이 interaction token 으로 답장을 수정하는 패턴(토큰 유효 15분)
- typing 루프(8초 갱신, 최대치 도달 시 포기)
- `X-Adapter-Secret` 공유 시크릿 헤더
- Podman/Docker 재시작 위임(Restart=on-failure, 어댑터에 재시도 로직을 넣지 않음)

잘라낼 것: 이미지 첨부 전달, DM 처리.

**멘션→스레드 세션화는 잘라내지 않고 가져온다.** 과제는 챗봇과의 대화로 구체화되고
그 산물이 이슈 발급이기 때문이다. 봇을 멘션하면 원본 메시지에서 스레드를 열고,
이후 대화는 스레드 안에서 멘션 없이 이어진다(cghds 의 typing 루프·스레드 이름
생성 로직 포함).

배포: apps(docker). cghds 의 Dockerfile(node:22-alpine 멀티스테이지)을 그대로
재사용한다. 환경변수는 `DISCORD_BOT_TOKEN`, `DISCORD_GUILD_ID`, `N8N_WEBHOOK_URL`,
`WEBHOOK_SHARED_SECRET`, `ALLOWED_USER_IDS`.

### A2. 커맨드

작업 투입은 커맨드가 아니라 **대화 → 이슈 → 라벨**의 3단 흐름이다.

1. **대화**: 채널에서 봇을 멘션하면 스레드가 생기고, 할 일을 대화로 다듬는다.
   n8n AI Agent 가 맥북의 Wayfinder 같은 역할을 서버에서 수행한다 — 모호한 요청은
   되묻고, 충분히 구체해지면 이슈 초안을 제안한다.
2. **이슈 발급**: 대화 중 `이슈로 만들어` 류 의사표현 또는 `/issue` 커맨드로
   n8n 이 Forgejo 에 이슈를 생성한다(`owner/repo`, 제목, 본문). 아직 라벨은 없다 —
   생성만으로 루프가 돌지 않는다.
3. **루프 투입**: `/implement <owner/repo> <issue#>` 커맨드가 기존 이슈에
   `implement` 라벨을 붙인다 — 기존 웹훅 경로가 그대로 에이전트 루프를 트리거한다.
   사람이 판단해 투입 시점을 결정한다.

| 커맨드 | 동작 | 백엔드 |
|---|---|---|
| `/issue <owner/repo> <제목>` | 대화 스레드 내용으로 이슈 생성(라벨 없음) | Forgejo API |
| `/implement <owner/repo> <issue#>` | 기존 이슈에 implement 라벨 부착 → 루프 트리거 | Forgejo API + 웹훅 |
| `/status <run-id>` | 루프 상태·로그 tail | `agent-run.sh status` |
| `/runs [repo]` | 최근 실행 목록(진행중·완료·exit 코드) | ci logs 조회 |
| `/cancel <run-id>` | 진행중 루프 중지(systemctl stop) | systemd |
| `/issues <repo>` | 열린 이슈 목록 | Forgejo API |
| `/pr <repo>` | 열린 PR 목록 | Forgejo API |
| `/help` | 사용법 | 정적 응답 |

**두 곳 등록 시임**: 커맨드는 어댑터의 `SLASH_COMMANDS` 와 n8n 메인 워크플로의
라우팅 양쪽에 있어야 한다. 한쪽만 바꾸면 커맨드가 보이는데 아무것도 하지 않는다.
cghds 가 남긴 교훈 그대로다.

대화형 응답에는 화자 식별이 필요하다 — payload 의 author_id 를 이름 매핑 테이블로
바꿔 프롬프트에 `[화자: ...]` 접두를 붙인다(cghds 의 discord-members.md 패턴).
GEM12 는 사용자가 1명이라 매핑은 간단하지만, 구조는 동일하게 둔다.

### A3. 역방향 — 완료·실패 통보

- **Forgejo webhook** → n8n 신설 엔드포인트(`/forgejo-events`). PR 리뷰 결과,
  PR 상태 변경, push 를 수신해 Discord 전용 채널로 포맷 posting.
- **agent-run.sh 종료 훅**: systemd-run 유닛 명령 끝에 curl 을 추가해 종료 코드와
  run-id, 소요시간을 n8n webhook 으로 POST 한다. 폴링보다 확실하고 의존성이 없다.
- 알림 내용: run-id, repo, 모델(glimmer/qwen), exit 코드, PR 링크, 리뷰 판정.

### A4. 보안

- Discord → n8n: shared secret 헤더
- Forgejo → n8n: webhook secret
- n8n → Forgejo: read/write 스코프 토큰(healthcheck 용 read-only 와 분리 발급)
- 허용 사용자가 1명이어도 `ALLOWED_USER_IDS` 는 유지한다 — 실수로 서버를 공개
  초대받아도 안전하다.

## 3. Part B — YouTube Discover → NocoDB

### B1. NocoDB 스키마

베이스 `youtube-discover`, 테이블 둘:

- **videos**: video_id(PK), title, channel, url, published_at, discovered_at,
  status(discovered / interpreted / failed), duration
- **insights**: video_id(FK), summary, key_points, categories(AI / 1인사업 /
  개발 …), relevance_score(1–5), why_relevant, model_used, created_at

API 토큰을 발급해 apps env 에 넣는다.

### B2. 워크플로 둘

**discover-youtube (매일 09:00)**

1. Schedule Trigger → Apify 유튜브 검색 actor 실행 — 키워드 세트
   (`AI 에이전트`, `1인 사업 자동화` …), 업로드일 필터(최근 7일)
2. NocoDB videos 와 대조해 신규만 통과(video_id dedupe)
3. status=discovered 로 선적재 후 interpret 호출

Apify 토큰과 actor 선택 노하우는 cghds 의
`apify-scrapers-influencer-discovery.md` 리서치와 운영 이력을 참고한다 —
Instagram 수집으로 이미 검증된 계정을 그대로 쓴다.

**interpret-youtube**

1. OpenRouter 의 **gemini-3.7-flash** 에 영상 URL 을 직접 넘긴다 — Gemini 만이
   유튜브 영상의 화면+음성을 네이티브로 해석할 수 있으므로 자막 수집 단계가
   아예 없다. 이것이 google 모델을 고른 이유다.
2. JSON 스키마 강제 — summary / key_points / categories / relevance_score /
   why_relevant. 프롬프트에 한국어 출력과 윤문 규칙을 명시한다.
3. insights 적재 + status=interpreted. 실패 시 status=failed + 오류 기록
   (재처리 가능)

### B3. 운영 보강

- watermark(publishedAfter 커서)는 n8n staticData 또는 NocoDB 메타 테이블에
- 주간 digest: relevance 상위 영상 목록을 매주 월요일 Discord #research 채널로 —
  두 파이프라인의 접점
- 워크플로 실패 시 Kuma push 에 실패 신호(기존 healthcheck 패턴 재사용)
- **워크플로 JSON 은 export 물이다**: SSOT 는 n8n 인스턴스. 수정 후 re-export 해
  dotfiles 에 커밋하는 규칙을 문서화한다

## 4. 실행 순서

| 단계 | 작업 | 검증 |
|---|---|---|
| 1 | Discord Application + Bot 생성(개발자 포털), 토큰을 1Password 에 등록, 서버 초대 | 봇이 채널에 참여 |
| 2 | 어댑터 빌드·apps 배포 — 멘션 대화·`/help` 부터 | 멘션하면 스레드 생성·응답 |
| 3 | n8n dev-control webhook + 조회 커맨드(``/runs`` `/issues` `/pr`) | 조회 커맨드 동작 |
| 4 | `/issue` 발급 + `/implement` 라벨 + `/cancel`, agent-run.sh 종료 훅, Forgejo webhook 연결 | 대화→이슈→투입→완료 알림 전체 경로 |
| 5 | NocoDB 베이스·테이블·API 토큰 | curl 로 레코드 삽입 |
| 6 | discover-youtube (interpret 은 더미) | 매일 신규 발견 적재 |
| 7 | interpret-youtube (LLM 요약) | insights 채워짐 |
| 8 | 주간 digest → Discord (선택) | 채널 posting |

## 5. 필요한 새 시크릿

| 항목 | 발급 방법 | 저장 위치 |
|---|---|---|
| Discord bot token | Developer Portal → Bot → Reset Token | 1Password + apps env |
| Forgejo API 토큰(rw) | core 에서 generate-access-token | 1Password + n8n credential |
| NocoDB API token | NocoDB UI → Account → Tokens | 1Password + apps env |
| YouTube Data API key | Google Cloud Console | 1Password + n8n credential |

## 6. 사람이 할 일 (구현 전 준비)

1. **Discord Developer Portal** (discord.com/developers/applications):
   - New Application → Bot 탭 → Reset Token → 토큰 복사해 1Password 등록
   - Bot 탭에서 **Message Content Intent 활성화**(privileged — 멘션 대화에 필요)
   - OAuth2 → URL Generator: scopes `bot` + `applications.commands`, 권한은
     Send Messages, Create Public Threads, Read Message History,
     Manage Messages(임베드 억제용) — 생성된 URL 로 자신의 서버에 초대
2. **자신의 Discord 사용자 ID 복사** — 설정 → 고급 → 개발자 모드 → 프로필
   우클릭 → 사용자 ID 복사. `ALLOWED_USER_IDS` 값이 된다
3. **채널 확보** — `#dev-pipeline`(알림용), 대화용 일반 채널 하나
4. **Apify 계정** — cghds 에서 쓰던 API token 을 1Password 에 넣고 GEM12 용으로
   공유 가능한지 확인(무료 플랜 한도면 유료 전환 판단)
5. OpenRouter 크레딧 잔액 확인 — gemini-3.7-flash 가 영상당 수만 토큰 입력을
   쓰므로 배치 규모를 정하고 예산 감각을 잡아둔다

| 항목 | 결정 | 비고 |
|---|---|---|
| YouTube 수집 방식 | **Apify** | cghds 에서 이미 운영 중인 계정·노하우 재사용 |
| interpret 요약 모델 | **gemini-3.7-flash (OpenRouter)** | 유튜브 네이티브 해석은 google 모델의 고유 영역 — URL 직접 입력, 자막 파이프라인 불필요 |
| 어댑터 배포 형태 | **apps docker 편입** | apps 는 docker 체제 — quadlet 혼용을 피한다 |
| 작업 투입 방식 | **대화 → `/issue` 발급 → `/implement` 라벨 투입** | 이슈 생성과 루프 투입을 분리해 사람이 투입 시점을 결정 |
| 루프 중단 수단 | **`/cancel <run-id>` 추가** | 실수 투입 대비, 단계 4 에 함께 구현 |
