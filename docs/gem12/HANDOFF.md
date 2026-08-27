# HANDOFF — GEM12 Discord 개발 제어 + moon_bird 원장 (2026-08-25 밤 기준)

> 로컬 전용(gitignore). 다음 세션이 이 문서만 읽고 이어서 일할 수 있게 현재 상태·남은 일·규칙을 적는다.
> 이력은 vault `journal/2026-08-25.md` 와 각 저장소 커밋에 있다.

## 한줄 요약

Discord 챗봇(n8n dev-control + 웹검색)과 슬래시 커맨드 8개는 서버에서 검증됐고, 그 위에 얹을
장기기억·온톨로지 프로젝트 **moon_bird** 가 설계·확정되어 P1 사건 원장(`gem12-ledger.service`)이
오늘 밤 가동을 시작했다. 다음은 원장에 이벤트를 흘려 넣는 일(T-16, T-20~24)이다.

## 현재 서버 상태

| 항목 | 값 |
|---|---|
| n8n | 2.36.6, apps :5678. 워크플로 `dev-control-workflow`·`web-search-workflow` 활성. 모델 `google/gemini-3.7-flash` |
| discord-adapter | apps docker, b95labs_bot#4692, 커맨드 8개. n8n 전달 실패 시 5초 간격 3회 재시도 후 실패 안내 |
| gem12-driver | ci :3000, `DRIVER_REPOS=b95labs/drop_manager,b95labs/customer_debugger` |
| **gem12-ledger** | ci :3001, enabled·active. DB `/mnt/data/sqlite/moon-bird.ledger.db`(호스트 `/mnt/data/ci/sqlite/`). bearer `LEDGER_TOKEN` |
| Litestream(호스트) | 대상 10개. 원장 포함, `flue-agents.db`·`gem12-driver.db` 는 **일부러 제외**(flue 런타임 잠금 경합) |
| 길드/채널 | b95labs(1540982276895277079). #chat 1540982278073745490 대화, #drop_manager 1540982524140855306 알림 |
| 저장소 동기화 | dotfiles `dc66a4c`, gem12-agents `8d115ca`, vault `da57bc1+` — 서버 사본·origin 모두 일치 |

## 구성 요소와 위치

```text
Discord ↔ discord-adapter (apps docker) ↔ POST /webhook/dev-control (X-Adapter-Secret)
n8n dev-control (apps :5678)
  ├─ chat: Build Prompt → gemini-3.7-flash ─(web_search toolWorkflow)→ web-search → Tavily
  ├─ command: Forgejo API (core :3000)  /issue /issues /implement /labels /help …
  └─ agent_finished: ci agent-run.sh 종료 훅 → #drop_manager 알림
gem12-agents (ci /opt/agents/gem12-agents)
  ├─ dist/server.mjs  gem12-driver.service  :3000  webhook → flue 개발 루프
  ├─ dist/gc.mjs      gem12-driver-gc.timer 04:30 스트림 정리 + VACUUM(flue DB 만)
  └─ dist/ledger.mjs  gem12-ledger.service  :3001  POST/GET /events (append 전용)
```

| 무엇 | 경로 |
|---|---|
| 어댑터 | `commands/incus/services/discord-adapter/src/bot.ts`, `deploy.sh` |
| n8n 워크플로(SSOT) | `commands/incus/services/n8n/workflows/dev-control.json`, `web-search.json`, `deploy.sh` |
| Litestream 정본 | `commands/incus/services/litestream/litestream.yml`, `deploy.sh`(호스트 `/etc/litestream.yml` 설치) |
| 원장 코드 | gem12-agents `src/persistence.ledger.ts`(store) · `src/ledger.http.ts`(Hono) · `src/entry.ledger.ts` · `deploy/gem12-ledger.service` · `test/ledger.test.ts` |
| moon_bird 계획 | vault `projects/moon_bird/dev-계획.md`(티켓 T-01~T-32, 스키마 계약, 슬러그 대응표), `README.md` |
| 설계 문서 | `docs/gem12/discord-dev-control.md`(파이프라인), `docs/gem12/operations.md` §6 시크릿 대응표 |
| 시크릿 | 1Password SSOT. 서버 `/root/.secrets/`(600), ci `/etc/agent-loop.env`(LEDGER_TOKEN·LEDGER_DB_PATH 포함). 1Password `GEM12/gem12 ledger token` |

## 원장 API (T-20 이후 n8n 이 호출)

```text
POST http://10.10.10.12:3001/events   Authorization: Bearer <LEDGER_TOKEN>
  body: 객체 또는 배열  {ts, project?, kind, actor, payload(JSON 문자열), source_ref}
  201 {ids:[…]} · 400 {error,index?} · 401 · 500(토큰 미설정)
GET  http://10.10.10.12:3001/events?project=&kind=&from=&to=&limit=   → 200 {events:[…]} 최신순, limit 기본 100 상한 1000
```

`project` 생략 시 `_unrouted`. `kind`·`source_ref` 형식은 dev-계획 「스키마 계약」이 정본이다.
UPDATE·DELETE 는 SQLite 트리거가 거부한다(`events is append-only`).

## 남은 작업

### moon_bird (dev-계획 티켓 번호)

1. **내일 확인** — `ls -l /mnt/data/ci/sqlite/moon-bird.ledger.db-wal`. 수 MB 넘게 팽창하면
   Litestream 잠금 경합이므로 `litestream.yml` 에서 빼고 gc 타이머의 `sqlite3 .backup` 사본으로 대체
2. **T-16** Forgejo webhook 유입 — `forgejo.webhook.ts` 의 `parseTrigger` 는 손대지 말고(GPU 뮤텍스 보호용
   제외 규칙이 테스트 20건으로 고정) 별도 파서로 issue·pr 이벤트를 `forgejo.issue`·`forgejo.pr` 로 append
3. **T-20~24** n8n 쪽: `chat.turn` 기록(HTTP Request 노드, credential `cred-ledger` httpBearerAuth 신설),
   슬러그 라우팅 JSON(대응표는 dev-계획), 원장 조회·vault 읽기 toolWorkflow. **한 번의 import 로 묶어 배포**
4. **T-27** `docs/gem12/chat-memory-design.md` 를 P1 결과에 맞춰 다시 쓴다 — 지금 그 문서는
   better-sqlite3·Task Runner 전제가 틀렸고 moon_bird 계획이 대체한다
5. 미결(사용자): `customer_debugger`·`polydeukes` Discord 채널, cognee 인덱스 3개와 원칙 6(벡터·그래프 보류)의 관계

### 파이프라인 잔여

- **drop_manager 에서 `/implement` E2E** — 라벨 부착 → 드라이버 webhook → 루프 → `agent_finished` 알림.
  종료 훅은 설정만 되어 있고 완료된 루프가 없어 미검증
- `/status` `/runs` `/cancel` — 드라이버(:3000)에 조회 엔드포인트를 추가하고 n8n 이 호출. 지금은 "(준비 중)"
- YouTube Discover — 설계는 `discord-dev-control.md` Part B. NocoDB API token(사용자 UI), Apify 키는 `/root/.secrets/apify-api-key`

### 사용자가 해야 할 일

- [ ] NocoDB API token 발급 (UI → Account → API Tokens)
- [ ] 1Password 에 forgejo-devcontrol-token 등록 (서버 파일에서 값 복사)
- [ ] 내일 원장 `-wal` 크기 확인(위 1번) — 또는 다음 세션에 맡김

## 규칙 (오늘 실측으로 굳어진 것)

- **워크플로 SSOT 는 dotfiles `workflows/*.json`**. `deploy.sh` 가 같은 id 를 지우고 재임포트한다.
  UI 에서 고쳤으면 re-export 해 JSON 에 반영. `settings.executionOrder: "v1"` 필수(legacy 면 Agent 도구 결과가 `""`)
- **n8n Code/toolCode 는 Task Runner vm** — `fetch`·`process` 없음. 외부 HTTP 는 HTTP Request 노드, 도구는 toolWorkflow 서브워크플로(활성 상태여야 함)
- **`deploy.sh`(n8n) 는 약 30초 챗봇을 내린다** — 배포 전에 알린다
- **서버 반영은 `git pull` 로만**. 그리고 **배포 직전 저장소별 `git status -sb` 로 `ahead` 가 없는지 확인** —
  오늘 dotfiles 푸시를 빠뜨린 채 litestream `deploy.sh` 를 돌려 2분간 옛 yml 이 설치됐다. 여러 저장소 push 는 `git -C <path> push`
- **ci 의 flue DB·driver DB 는 Litestream 대상이 아니다** — 등록 제안 금지. 원장만 예외
- **gem12-agents 는 프로젝트 중립** — 원장 코드에 슬러그를 박지 않는다. 파일명 `moon-bird.ledger.db` 는 서버 env 로만 준다.
  `check-boundaries.mjs` 규칙 1 때문에 Hono 앱은 `entry.*` 가 아닌 `ledger.http.ts` 에 둔다
- **원장에 VACUUM 금지** — append 전용, `entry.gc.ts` 는 원장을 열지 않는다
- **vault 를 고쳤으면 커밋 전에 `journal/YYYY-MM-DD.md` 에 `## HH:MM` 절 append**(AI 작성 명시)
- 커맨드는 어댑터 `SLASH_COMMANDS` 와 n8n 라우팅 두 곳에 등록. n8n 컨테이너 재생성은 반드시 `deploy.sh`(env 누락 방지). credential 은 DB 볼륨 유지 시 재주입 불필요

## 진단 단서

- n8n 실행 결과는 `/mnt/data/n8n/database.sqlite` 의 `execution_entity`·`execution_data`
- 원장: `incus exec ci -- journalctl -u gem12-ledger`, 호스트에는 `sqlite3` 이 없어 raw 검사는 `incus exec ci -- node -e "require('node:sqlite')…"`
- Litestream: `litestream databases`, `journalctl -u litestream --since '1 min ago' | grep -c 'replica sync'`
