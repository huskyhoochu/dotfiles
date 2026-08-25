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

잘라낼 것: 멘션→스레드 세션화, 이미지 첨부 전달, DM 처리. 1차는 슬래시 커맨드
전용으로 단순화한다 — 개발 제어는 전용 채널 하나면 충분하다.

배포: apps(docker). cghds 의 Dockerfile(node:22-alpine 멀티스테이지)을 그대로
재사용한다. 환경변수는 `DISCORD_BOT_TOKEN`, `DISCORD_GUILD_ID`, `N8N_WEBHOOK_URL`,
`WEBHOOK_SHARED_SECRET`, `ALLOWED_USER_IDS`.

### A2. 커맨드

| 커맨드 | 동작 | 백엔드 |
|---|---|---|
| `/task <owner/repo> <과제>` | Forgejo 이슈 생성(`implement` 라벨) → 에이전트 루프 자동 트리거 | Forgejo API + 기존 웹훅 경로 |
| `/status <run-id>` | 루프 상태·로그 tail | `agent-run.sh status` |
| `/runs [repo]` | 최근 실행 목록(진행중·완료·exit 코드) | ci logs 조회 |
| `/issues <repo>` | 열린 이슈 목록 | Forgejo API |
| `/pr <repo>` | 열린 PR 목록 | Forgejo API |
| `/help` | 사용법 | 정적 응답 |

**두 곳 등록 시임**: 커맨드는 어댑터의 `SLASH_COMMANDS` 와 n8n 메인 워크플로의
라우팅 양쪽에 있어야 한다. 한쪽만 바꾸면 커맨드가 보이는데 아무것도 하지 않는다.
cghds 가 남긴 교훈 그대로다.

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

1. Schedule Trigger → 키워드 세트로 검색(`AI 에이전트`, `1인 사업 자동화`,
   `publishedAfter=어제`)
2. NocoDB videos 와 대조해 신규만 통과
3. status=discovered 로 선적재 후 interpret 호출

**interpret-youtube**

1. 영상별 자막 수집(자동자막 포함). 자막이 없으면 제목+설명만으로 요약하고
   품질 낮음 표시
2. LLM 요약 — JSON 스키마(summary / key_points / categories / relevance_score /
   why_relevant) 강제
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
| 1 | Discord Application + Bot 생성, 토큰을 1Password 에 등록 | 봇이 서버 참여 |
| 2 | 어댑터 빌드·apps 배포, `/help` 만 구현 | Discord 에서 응답 |
| 3 | n8n dev-control webhook + `/runs` `/issues` (읽기 전용) | 조회 커맨드 동작 |
| 4 | agent-run.sh 종료 훅 + Forgejo webhook 연결 | `/task` → 완료 알림 수신 |
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

## 6. 미결 판단

| 항목 | 선택지 | 결정 시점 |
|---|---|---|
| YouTube 수집 방식 | Data API 검색 vs 관심 채널 RSS 폴링 | 착수 시 |
| interpret 요약 모델 | OpenRouter 저가 vs 로컬 glimmer/qwen | 착수 시 |
| 어댑터 배포 형태 | apps docker compose 편입 vs 별도 quadlet | 단계 2 |
| `/task` 범위 | 이슈 생성까지 vs 즉시 루프 투입까지 | 단계 4 |
