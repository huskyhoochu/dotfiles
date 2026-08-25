# HANDOFF — Discord 개발 제어 파이프라인 구축 (2026-08-25)

> 이 문서는 2026-08-25 하루 동안의 작업 결과와 현재 상태, 남은 일을 정리한다.
> 다음 세션이 이어서 작업할 때 이 문서 하나로 상황을 파악할 수 있어야 한다.

## ⚠️ 세션 2 (2026-08-25 밤) — 부분 실패 상태로 종료

### 해결됨 (서버 배포 + 실측 검증까지 완료)

1. **슬래시 커맨드 답장 안 붙는 문제** — 원인 3건 수정:
   - Reply via Interaction이 `$json._app/_tok`를 Forgejo 응답에서 참조하던 버그 → `$('Parse Command')` 직접 참조 + 신설 **Build Command Reply** 노드로 통합 조립
   - Post Chat Reply의 중복 jsonBody/오참조 제거
   - **Route Command Switch v1 → v3.2 마이그레이션**: n8n 임포트가 v1 파라미터의 `fallbackOutput`/`outputKey`를 조용히 삭제함(DB 직접 조회로 확인). `/help`가 무응답으로 끝나던 원인. v3.2로 전환 후 **exec 14 (`/help`) 성공 확인**
2. 배포 절차 확립: export물 JSON에 top-level `id`(=dev-control-workflow) 필수 — 없으면 import NOT NULL 제약 위반. `webhook_entity` 테이블에 옛 워크플로의 고아 등록이 남으면 "Conflicting Webhook Path" 발생 → 해당 행 삭제 후 재시작으로 해결.

### ❌ 미해결: web_search 도구(toolCode)가 에이전트 안에서 계속 실패

- 현상: 채팅에서 시의성 질문 시 모델이 web_search를 호출하지만 실패하고 재시도를 반복 → **Max iterations (10) 도달** (exec 15). 선검색(Pre Search)은 제거했고 도구 방식으로 전환한 상태.
- 시도한 것 (전부 dotfiles JSON 수정 + 서버 재배포 반영됨):
  - `this.helpers.httpRequest` → 동일 실패
  - 글로벌 `fetch()` + `process.env.TAVILY_API_KEY` → 동일 실패 (단, 컨테이너 안 plain node로 fetch+키 조합 직접 테스트하면 200 정상 — 인스턴스 외부에서는 잘 된다)
  - `$env.TAVILY_API_KEY` 단독 사용
  - try/catch로 에러를 JSON 텍스트로 모델에 반환(무한재시도 방지) — 그래도 max iterations
  - 최종 버전: `[web_search] key source...` console.log 진단 코드 삽입까지 했으나, **마지막 테스트에서 해당 로그 라인이 docker logs에 하나도 안 찍힘** → 도구 코드 자체가 실행조차 안 되고 있을 가능성(또는 task runner stdout 미전달). 여기서 조사 중단.
- 유력 가설 (다음 세션 첫 확인 사항):
  1. n8n 2.x JS Task Runner 샌드박스에서 toolCode의 env 접근 차단 — `N8N_RUNNERS_*` 관련 env 또는 task runner 비활성화(`N8N_RUNNERS_ENABLED=false`)로 검증해볼 것
  2. toolCode가 아닌 **HTTP Request Tool의 재시도**(원래 버그 노드) 또는 **Call n8n Workflow Tool로 Tavily 호출을 서브워크플로화**하는 우회 — 서브워크플로 내 일반 HTTP Request 노드는 httpRequestTool 버그와 무관하게 정상 작동하므로 가장 유망
  3. 최후 폴백: Pre Search 복원 + IF 노드(키워드 정규식, AI 불필요)로 조건 검색 — 이건 반드시 된다
- 참고: exec 13에서 "floci 26회 등록"은 검색 결과가 아니라 모델 자체 지식 기반 답변이었을 가능성 높음(성공 판정 오류였음).

### ❌ 추가 발견 (미처리)

- **커맨드 에러 시 무응답**: exec 16 — `/issues drop_manager`(owner 누락) → Forgejo 404 → 실행이 error로 끝나면서 interaction PATCH가 안 날아감. **Forgejo HTTP 노드들에 onError: continueRegularOutput 설정(또는 error branch)해서 에러 메시지를 답장으로 돌려줘야 함**
- `deploy.sh` 두 군데 수정 필요: ① `N8N_DATA=/mnt/data/n8n`(현재 apps/n8n은 잘못된 경로), ② 워크플로 JSON에 id 필드 보증 로직

### 현재 서버 상태 (세션 2 종료 시점)

- dev-control 워크플로 활성화됨, webhook 정상 응답(403 게이트 확인). 채팅 일반 대화·`/help`는 정상.
- **웹검색 있는 답변은 깨진 상태**(max iterations → Discord에 "생각 중" 후 타임아웃 or 실패 통보)
- dotfiles의 `dev-control.json` = 서버에 배포된 것과 동일(최신 versionId). SSOT 교체 완료. 커밋 필요.
- 장기기억 설계 문서 신설: `docs/gem12/chat-memory-design.md` (미구현)

## 한줄 요약

Discord 챗봇(범용 대화 + Forgejo 개발 제어)이 GEM12에서 가동 중이다.
단, **웹검색 도구는 미해결 버그로 깨진 상태**(세션 2 참조) — 일반 대화와 /help·/issues 등 커맨드 조회는 정상.
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

### 5. 선검색 제거 → Custom Code Tool 전환 + 슬래시 커맨드 수리 (2026-08-26)

- **Pre Search 노드 삭제**. Tavily 검색을 `toolCode`(Custom Code Tool) `web_search`로
  감싸 에이전트 도구로 부착 — 모델이 필요할 때만 호출(추가 AI 판단 호출 불필요).
  httpRequestTool 버그는 toolCode에는 재현되지 않는 별도 노드 타입.
- **슬래시 커맨드 무응답 원인 3건 수정**:
  1. Reply via Interaction이 `$json._app/_tok` 참조 → Forgejo 응답에서 유실 →
     `$('Parse Command')` 직접 참조로 변경, 답장 문구는 신설 **Build Command Reply** 노드에서 통합 조립
  2. Route Command에 fallbackOutput 추가 — help·사용법 답변(`_action` 없음)이 버려지던 것 수정
  3. Post Chat Reply의 중복 jsonBody/`$json.output` 오참조 및 잔여 키 제거
- **장기기억 설계 완료**: [chat-memory-design.md](chat-memory-design.md) —
  better-sqlite3 기반 Load/Save Memory + facts 테이블 + 야간 통합 배치 설계. 미구현.
- ⚠️ dotfiles의 JSON은 편집본 — 서버 n8n에 재임포트 후 실동작 검증 필요.
  toolCode가 2.x에서 문제를 일으키면 대안: IF 노드 + 시의성 키워드 정규식으로 Pre Search 복원.

## 남은 작업

### 즉시 (다음 세션 첫 작업)

0. **수정된 워크플로 재임포트 + 스모크** — chat 분기(검색 필요/불필요 질문 각각),
   `/issue`·`/issues`·`/help` E2E 확인. 성공 후 서버에서 re-export해서 dotfiles 커밋

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

### 장기기억 구현 (설계 완료)

- 설계: [chat-memory-design.md](chat-memory-design.md). 구현 순서 §6 참조.
- 선행 조건: n8n 이미지에 better-sqlite3 + `NODE_FUNCTION_ALLOW_EXTERNAL` env

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
