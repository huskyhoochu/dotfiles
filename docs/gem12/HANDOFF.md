# HANDOFF — Discord 개발 제어 파이프라인 구축 (2026-08-25)

> 이 문서는 2026-08-25 하루 동안의 작업 결과와 현재 상태, 남은 일을 정리한다.
> 다음 세션이 이어서 작업할 때 이 문서 하나로 상황을 파악할 수 있어야 한다.

## ✅ 세션 3 (2026-08-25 저녁) — 웹검색 도구 복구 완료

### 해결됨 (서버 배포 + exec 27 실측 검증)

웹검색 실패는 서로 다른 원인 4겹이 겹쳐 있었다. 하나를 고치면 다음 층이 드러나는 구조라 세션 2 는 첫 층조차 못 벗겼다.

| # | 층 | 증거 | 수정 |
|---|---|---|---|
| 1 | toolCode 안의 `$fromAI('query')` 가 실행 컨텍스트 없이 예외 | `execution_data` 에 `No execution data available at ToolCode.node.ts:102` | 세션 2 코드는 첫 줄에서 죽어 이후 수정이 전부 무의미했음 |
| 2 | Task Runner vm 컨텍스트에 `fetch`·`process` 없음 | `js-task-runner.js getNativeVariables()` 직접 확인 | toolCode 폐기 → **toolWorkflow + 서브워크플로 `web-search`** (HTTP Request + Tavily Bearer credential) |
| 3 | 2.x 는 서브워크플로도 활성(published) 이어야 호출 가능 | `Workflow is not active and cannot be executed` | deploy.sh 가 `workflows/*.json` 전부 import + 활성화 |
| 4 | 도구 출력은 있는데 모델에 `Tool: ""` | n8n#26202 — Agent V3 재개 항목이 도구보다 먼저 큐에서 소비되는 FIFO 버그, **legacy 실행 순서에서만** 발생. `settings: {}` 였음 | `settings.executionOrder = "v1"` |

4번이 HANDOFF 가 "httpRequestTool 버그" 로 기록한 것의 진짜 정체다 — 도구 종류와 무관하게 `executionOrder` 미지정 워크플로에서 모든 도구가 빈 값으로 보인다.

### 함께 처리

- Forgejo HTTP 노드 5개 `onError: continueRegularOutput`, Build Command Reply·Format List 가 `error` 아이템을 "Forgejo 요청 실패: …" 답장으로 변환 (exec 19 검증)
- `deploy.sh`: `N8N_DATA=/mnt/data/n8n`(실경로), id 필드 보증, 컨테이너에 있던 env(`N8N_HOST`/`N8N_PROTOCOL`/`N8N_WEBHOOK_URL`/`NODE_FUNCTION_ALLOW_BUILTIN`) 반영
- `TAVILY_API_KEY` env 주입은 더 이상 사용처가 없다(credential 로 대체). 제거는 보류.

### 진단에서 얻은 규칙

- n8n 도구 실패는 `execution_data` 테이블이 1차 증거다. 도구 호출 스택·모델이 받은 `Tool:` 문자열이 그대로 남는다.
- 같은 수정을 반복해도 결과가 완전히 같으면 수정 지점이 실행 경로 위에 있는지부터 의심한다.
- exec 17 의 Discord 404 는 별개 원인: 기본 채널(ID = 길드 ID) 에서 온 메시지에 봇 게시 권한이 없다.

### 슬래시 커맨드 전수 점검 (같은 날 밤)

exec 40–54 로 8종 전부 실측. 고친 것:

- `/implement`: Find Label 의 라벨당 아이템 응답을 Attach 가 `$json.data` 로 읽어 `labels:[null]` 전송 → **Pick implement Label**(Code) + **Has implement Label**(IF) 노드 신설. 라벨 없으면 안내 답장
- `/issues` `/pr`: 결과 0건이면 HTTP 노드가 아이템을 안 내보내 Format List 미실행 → 무응답. `alwaysOutputData` 로 해결. Format List 는 아이템당 이슈 하나인 응답 형태를 처리
- Reply via Interaction 이 `$('Build Command Reply')` 를 참조해 목록 경로에서 미실행 노드 오류 → `$json._reply/_app/_tok` 사용
- `/issue`: 제목 옵션 필수화(추론 기능은 없음), 본문 "스레드 참조" 문구 제거
- `/status` `/runs` `/cancel`: 미구현. 호스트 `agent-run.sh` 를 n8n 에서 못 부르므로 ci 쪽 HTTP 셈이 있어야 한다. 커맨드 설명에 "(준비 중)" 표기
- `/implement` 답장의 "에이전트 루프에 투입" 문구 제거 — Forgejo webhook → agent-run.sh 연결이 아직 없다
- 어댑터: n8n 전달 실패 시 5초 간격 3회 재시도, 최종 실패는 채널/interaction 에 알림 (deploy.sh 재시작 창 ≈30초 대응)

### 남은 것

- `/implement` 후 실제 루프 투입: Forgejo webhook → agent-run.sh 연결
- `/status` `/runs` `/cancel` 구현 (ci 컨테이너 HTTP 셈 필요)

## 한줄 요약

Discord 챗봇(범용 대화 + Forgejo 개발 제어)이 GEM12에서 가동 중이다.
웹검색 도구는 세션 3 에서 복구됐다(toolWorkflow + executionOrder v1). 일반 대화·/help·/issues 등 커맨드 조회 정상.
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
| chat | Build Prompt → gemini-3.7-flash 에이전트(도구: web_search 서브워크플로) → Discord posting |
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
  ├─ chat: Build Prompt → gemini-3.7-flash 에이전트 ─(web_search)→ 서브워크플로 web-search → Tavily
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
│   │   ├── workflows/dev-control.json  # 메인 워크플로
│   │   ├── workflows/web-search.json   # web_search 서브워크플로 (Tavily)
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
