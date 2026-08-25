# GEM12 챗봇 장기기억 설계 (2026-08-26)

> 대상: dev-control 워크플로의 Chatbot Agent. 목표는 사용자 활동 전반을 기억하는 것.
> 제약: GEM12에는 Postgres가 없고, 저장 계층은 **SQLite(서비스별 파일) + 호스트 Litestream**이 원칙(operations.md §140).

## 0. 결론

- n8n이 기본 제공하는 chat memory 노드 중 **SQLite용은 없다**(Simple·Postgres·Redis·MongoDB·Motorhead·Xata·Zep).
- 따라서 메모리를 노드에 맡기지 않고, **Code 노드에서 `better-sqlite3`로 직접 읽고 쓰는 방식**으로 간다.
- 단기(버퍼)와 장기(사실 요약) 두 층으로 나누고, 파일 하나(`/mnt/data/n8n/chat-memory.db`)에 몰아넣는다.
- 이 파일을 호스트 Litestream 복제 목록에 추가하면 기존 백업 체계(restic → Drive)에 그대로 편승한다.

## 1. n8n이 제공하는 AI 관련 노드 정리 (2.x)

| 구분 | 노드 | GEM12 적합성 |
|---|---|---|
| root | AI Agent (`langchain.agent`) | ✅ 이미 사용 |
| model | lmChatOpenRouter 등 | ✅ 사용 중 |
| memory | Simple Memory(RAM) | 재시작 시 소실 → 부적합 |
| memory | Postgres / Redis / MongoDB / Zep Chat Memory | 해당 DB 없음 → 불가 |
| memory | Motorhead / Xata | 외부 서비스 추가 필요 → 과함 |
| tool | HTTP Request Tool | ❌ 빈 결과 버그(확인됨) |
| tool | **Custom Code Tool** (`toolCode`) | ✅ Pre Search 제거 후 Tavily 도구로 채택 |
| tool | Call n8n Workflow Tool | 야간 통합 배치에 유용 |

## 2. 스키마

```sql
-- 단기: 채널별 대화 원문
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,      -- '{channel_id}:{author_id}'
  role TEXT NOT NULL,            -- 'user' | 'assistant'
  content TEXT NOT NULL,
  created_at TEXT NOT NULL       -- ISO 8601 KST
);
CREATE INDEX idx_messages_session ON messages(session_id, id);

-- 장기: 통합된 사실 (야간 배치가 생성)
CREATE TABLE facts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scope TEXT NOT NULL DEFAULT 'global',  -- 'global' | 'channel:{id}' | 'user:{id}'
  fact TEXT NOT NULL,
  source_window TEXT,                    -- 근거 기간 (예: '2026-08-01~08-07')
  created_at TEXT NOT NULL,
  superseded_by INTEGER                  -- 사실 갱신 시 구행 무효화
);
```

## 3. 워크플로 구성 (dev-control 확장)

```text
Route Event(chat)
  → Load Memory   (Code: better-sqlite3 SELECT 최근 N건 + 유효한 facts)
  → Build Prompt  (대화이력 + 장기사실을 시스템 프롬프트에 주입)
  → Agent (+ Web Search Tool)
  → Save Memory   (Code: user/assistant 발화 INSERT)
  → Post Chat Reply
```

- **Load Memory**: `messages`에서 세션 최근 20건 + `facts`에서 `superseded_by IS NULL` 전 건을 읽어 프롬프트 컨텍스트로 조립. 기존 memoryBufferWindow 노드는 제거.
- **Save Memory**: 발화 한 쌍을 INSERT. 실패해도 답변 posting은 계속되도록 try/catch.
- **장기기억 도구(선택)**: `remember`라는 Custom Code Tool을 에이전트에 붙여, 모델이 대화 중 중요 사실(프로젝트 결정, 선호 등)을 즉시 `facts`에 기록하게 할 수 있다. 야간 배치만 믿지 않는 보험.

### 환경 요구

- n8n 컨테이너 env: `NODE_FUNCTION_ALLOW_EXTERNAL=better-sqlite3`
- `better-sqlite3`는 컨테이너 내 설치(n8n 커스텀 이미지에 추가 또는 volume 마운트된 node_modules). `deploy.sh` 수정 필요.
- WAL 모드 사용(`journal_mode=WAL`). nocodb의 `journal_mode=delete` 예외와 달리 Litestream이 정상 복제 가능.

## 4. 야간 통합 배치 (facts 생성)

매일 새벽 n8n Schedule Trigger 워크플로:

1. 어제 하루 `messages` 로드 (세션별)
2. OpenRouter(gemini-3.7-flash)로 "이 사용자에 대해 알게 된 사실" 추출
3. 기존 `facts`와 비교해 신규/갱신 판단 → INSERT, 갱신이면 구행 `superseded_by` 설정
4. 30일 지난 `messages`는 아카이브 삭제(선택)

cghds의 Postgres Chat Memory + 야간 통합 패턴을 SQLite 위로 옮긴 것이다.

## 5. 백업 연계 (Litestream)

- 파일 위치: `/mnt/data/n8n/chat-memory.db` (n8n 볼륨 안)
- core 호스트 `/etc/litestream.yml`의 dbs 목록에 추가:

```yaml
dbs:
  - path: /mnt/data/n8n/chat-memory.db
    replicas:
      - type: file
        path: /mnt/data/backup/litestream/chat-memory
```

- 이후 매시 restic → Drive 경로에 자동 편입. 별도 비용 0.

## 6. 구현 순서

1. [ ] n8n 이미지에 better-sqlite3 반영 + env 플래그(deploy.sh 수정)
2. [ ] 스키마 생성 코드 노드(최초 1회 실행)
3. [ ] Load Memory / Save Memory 노드 교체, memoryBufferWindow 제거 → re-export
4. [ ] 실제 대화로 이력 유지 확인(컨테이너 재시작 후에도)
5. [ ] Litestream dbs 항목 추가, 복제 확인
6. [ ] 야간 통합 배치 워크플로 작성
7. [ ] (선택) remember 도구 부착
