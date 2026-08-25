# HANDOFF — Discord 개발 제어 파이프라인 구축 (2026-08-25)

> 이 문서는 2026-08-25 하루 동안의 작업 결과와 현재 상태, 남은 일을 정리한다.
> 다음 세션이 이어서 작업할 때 이 문서 하나로 상황을 파악할 수 있어야 한다.

## 한줄 요약

Discord 챗봇(범용 대화 + Forgejo 개발 제어)이 GEM12에서 **완전 가동 중**이다.
YouTube Discover 파이프라인은 설계만 완료되고 미구현이다.

## 완성된 것

### 1. Discord 어댑터 — `commands/incus/services/discord-adapter/`

- cghds의 `discord/adapter`를 축소·개작. TypeScript + discord.js 14
- **멘션 불필요** — 허용 사용자의 모든 길드 메시지를 `chat` 이벤트로 n8n에 전달
- 슬래시 커맨드 8종: `/issue` `/implement` `/status` `/runs` `/cancel` `/issues` `/pr` `/help`
- typing 루프, 허용 목록 게이트, `X-Adapter-Secret` 검증 포함
- 배포: apps 컨테이너 docker. 시크릿은 `/mnt/data/discord-adapter/.env`
- `deploy.sh`: 이미지 빌드 + 컨테이너 재생성 원스텝

### 2. n8n dev-control 워크플로 — `commands/incus/services/n8n/workflows/dev-control.json`

n8n **2.36.6**에서 가동 중. 세 갈래 라우팅:

| 분기 | 흐름 |
|---|---|
| chat | Build Prompt → Tavily 선검색 → gemini-3.7-flash 답변 → Discord posting |
| command | /issue→Forgejo 이슈 생성 · /implement→라벨 부착 · /issues /pr→목록 조회 |
| agent_finished | exit 코드에 따라 ✅/❌ 알림 → #drop_manager posting |

**핵심 설계 결정 — httpRequestTool 버그 우회**: n8n 2.x의 httpRequestTool은
실행 로그에 데이터가 있음에도 모델에게 빈 값으로 전달되는 버그가 있다
(커뮤니티 다수 보고, v1.x에서는 정상). 이를 우회하기 위해 **도구를 에이전트에
붙이지 않고**, Tavily 검색을 워크플로 앞단의 일반 HTTP Request 노드로 실행해
결과를 프롬프트에 삽입하는 선(先)검색 방식으로 재구성했다.

**credential 5종** (DB 저장, `/root/.secrets/`에 원본):

| credential | 타입 | 용도 |
|---|---|---|
| Forgejo DevControl | httpHeaderAuth | 이슈 생성·라벨·조회 (rw) |
| Discord Bot | httpHeaderAuth | 메시지 posting |
| OpenRouter | openRouterApi | gemini-3.7-flash 호출 |
| Tavily Bearer | httpBearerAuth | 웹검색 |
| DevControl Shared Secret | httpHeaderAuth | webhook 인증 |

### 3. agent-run.sh 종료 훅

루프 종료 시 run-id·repo·모델·exit 코드를 n8n webhook으로 POST.
환경변수 `AGENT_EVENT_WEBHOOK_URL` 설정 시에만 작동.

### 4. 시크릿 — `/root/.secrets/` (600)

1Password가 SSOT. operations.md §6에 전체 대응표 있다.

## 아키텍처

```text
Discord (#chat 등)
  ↕ discord-adapter (apps docker)
    ↕ POST /webhook/dev-control + X-Adapter-Secret
n8n 2.36.6 (apps :5678)
  ├─ chat: Build Prompt → Tavily 선검색 → gemini-3.7-flash → Discord
  ├─ command: Forgejo API (core :3000)
  └─ agent_finished: ci agent-run.sh 종료 훅 → 알림
```

## 오늘 해결한 문제들

| # | 문제 | 해결 |
|---|---|---|
| 1 | httpRequestTool → 모델에게 빈 결과 전달 (n8n 2.x 버그) | 도구 제거 → Tavily 선검색 방식으로 우회 |
| 2 | credential 미적용 (`authentication` 파라미터 누락) | 모든 HTTP 노드에 명시 |
| 3 | Route Event 라우팅 불일치 | 규칙 5개 ↔ 연결 배열 정렬 |
| 4 | cross-node 참조 깨짐 (`$('Normalize').item`) | Prepare Reply Code 노드로 분리 |
| 5 | 어댑터 env 시크릿 불일치 | `/root/.secrets/devcontrol-webhook-secret` 정본 통일 |
| 6 | n8n 1.x 다운그레이드 시도 후 롤백 | langchain 패키지가 agent v3.1 미지원 확인 → 2.x 복귀 |

## 현재 서버 상태

| 항목 | 값 |
|---|---|
| n8n | 2.36.6, apps :5678, dev-control 활성화 |
| discord-adapter | apps docker, b95labs_bot#4692, 커맨드 8개 등록 |
| 길드 | b95labs (1540982276895277079) |
| 채널 | #chat(대화), #drop_manager(알림), #research(예정) |
| Forgejo 토큰 | 스모크 테스트 통과 (이슈 생성·라벨 부착·삭제) |
| implement 라벨 | repo별 생성 필요 (gem12-agents에는 id=40 존재) |
| dotfiles | 최신 커밋 push 완료, 서버 사본 동기화 |

## 남은 작업

### 즉시 (다음 세션 첫 작업)

1. **`/implement` E2E 테스트** — 실제 이슈에 implement 라벨 붙여서 에이전트 루프
   트리거까지 확인. Forgejo webhook → agent-run.sh 경로 연결 필요
2. **agent-run.sh 종료 훅 활성화** — `/etc/agent-loop.env`에 이미 설정됨,
   실제 루프 종료 시 알림 오는지 확인

### YouTube Discover 파이프라인 (미구현)

설계 완료: [discord-dev-control.md](discord-dev-control.md) Part B

- Apify 유튜브 검색 actor → 신규 영상 dedupe → NocoDB videos 적재
- gemini-3.7-flash로 영상 해석 → insights 적재
- NocoDB API token 발급 필요 (사용자 UI 작업)
- Apify API key: `/root/.secrets/apify-api-key` 저장됨

### 장기기억 설계 (사용자 요청, 미착수)

- 메인 챗봇이 사용자 활동 전체 기억 보유
- cghds의 Postgres Chat Memory + 야간 통합 패턴 참고
- GEM12에는 Postgres가 없으므로 SQLite 기반 설계 필요
- `user-memory-architecture.md`(cghds 리서치) 참고 권장

## 사용자가 해야 할 일

- [x] ~~Discord Developer Portal 설정~~ 완료
- [x] ~~봇 서버 초대 + 권한~~ 완료
- [ ] NocoDB API token 발급 (UI → Account → API Tokens)
- [ ] 1Password에 forgejo-devcontrol-token 등록 (서버 파일에서 값 복사)

## 주요 파일 위치

```
dotfiles/
├── commands/incus/services/
│   ├── discord-adapter/
│   │   ├── src/bot.ts          # 어댑터 본체
│   │   ├── deploy.sh           # apps docker 배포
│   │   └── .env.example        # 환경변수 목록
│   ├── n8n/
│   │   ├── workflows/dev-control.json  # 워크플로 정의 (export물)
│   │   └── deploy.sh           # 컨테이너 재생성+임포트+활성화
│   └── agent-loop/
│       └── agent-run.sh        # 종료 훅 추가됨
├── docs/gem12/
│   ├── discord-dev-control.md  # 설계 문서
│   └── operations.md           # 운영 참조 (§6 시크릿 대응표)
```

## 주의사항

- **워크플로 JSON은 export 물이다**: SSOT는 n8n 인스턴스. 수정 후 re-export해서
  dotfiles에 커밋하는 것을 잊지 말 것
- **커맨드는 두 곳에 등록**: 어댑터 `SLASH_COMMANDS` + n8n 라우팅. 한쪽만 바꾸면
  커맨드가 보이는데 아무것도 안 한다
- **n8n 컨테이너 재생성 시**: env 플래그(`N8N_BLOCK_ENV_ACCESS_IN_NODE=false`,
  `DEVCONTROL_WEBHOOK_SECRET`, `TAVILY_API_KEY`) 누락 주의 — `deploy.sh` 사용
- **credential은 DB 볼륨 유지 시 재주입 불필요** — 볼륨 새로 만들 때만 재임포트
