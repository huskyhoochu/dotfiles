# Skill Trigger Evals

모델 호출이 켜진 스킬(quick-search, korean-polish, pg-aiguide, google-dev-docs, tsdoc)의
발동 정확도를 수동 점검하는 체크리스트. 설명문(description)을 수정한 뒤 새 세션에서
아래 프롬프트를 하나씩 입력하고, 기대대로 스킬이 발동/미발동하는지 표시한다.

판정 기준: 프롬프트 입력 후 Claude가 해당 Skill 도구를 호출하면 발동(O), 직접 답하면 미발동(X).

---

## quick-search

**발동해야 함:**
- [ ] "요즘 환율 검색해줘"
- [ ] "Bun 최신 버전이 뭔지 찾아봐"
- [ ] "look up the current LTS version of Node.js"
- [ ] "https://example.com/post 이 페이지 내용 가져와"
- [ ] "오늘 AI 관련 뉴스 뭐 있어?"

**발동하면 안 됨:**
- [ ] "Claude Code 스킬 트렌드를 종합 리서치해줘" → web-research 영역 (슬래시 전용이므로 안내만)
- [ ] "이 함수 이름 뭐로 지을까?" → 검색 불필요
- [ ] "grep으로 이 저장소에서 TODO 찾아줘" → 로컬 검색

## korean-polish

**발동해야 함:**
- [ ] "draft.md 윤문해줘"
- [ ] "이 글 번역투 고쳐줘: (텍스트)"
- [ ] "README.ko.md 좀 자연스럽게 다듬어줘"
- [ ] "polish korean in docs/guide.md"

**발동하면 안 됨:**
- [ ] "이 영어 문서를 한국어로 번역해줘" → 번역이지 윤문 아님
- [ ] "맞춤법만 빠르게 확인해줘" → 문장·담화 차원 윤문 아님
- [ ] "이 코드 주석을 한국어로 바꿔줘" → 코드 편집

## pg-aiguide

**발동해야 함:**
- [ ] "주문 테이블 스키마 설계해줘 (PostgreSQL)"
- [ ] "이 쿼리에 인덱스를 어떻게 잡아야 해?"
- [ ] "센서 데이터용 hypertable 어떻게 만들어?"
- [ ] "pgvector로 시맨틱 검색 구현하려는데 HNSW 설정 알려줘"

**발동하면 안 됨:**
- [ ] "MySQL에서 이 쿼리 왜 느려?" → PostgreSQL 아님
- [ ] "SQLite로 로컬 캐시 만들어줘" → PostgreSQL 아님
- [ ] "이 Prisma 스키마 TypeScript 타입 고쳐줘" → DB 설계 아님

## google-dev-docs

**발동해야 함:**
- [ ] "Firebase Auth에서 커스텀 클레임 어떻게 설정해?"
- [ ] "GCS signed URL 만드는 법 공식 문서에서 찾아줘"
- [ ] "Gemini API의 파일 업로드 제한이 얼마야?"
- [ ] "Android WorkManager 주기 작업 최소 간격은?"

**발동하면 안 됨:**
- [ ] "AWS S3 presigned URL 만들어줘" → Google 아님
- [ ] "구글 스프레드시트에 이 데이터 정리해줘" → 문서 검색 아님 (Drive/Sheets 조작)
- [ ] "Anthropic API 스트리밍 어떻게 해?" → claude-api 영역

## tsdoc

**발동해야 함:**
- [ ] "이 파일 exported 함수들에 TSDoc 달아줘"
- [ ] "document this (커서가 .ts 파일)"
- [ ] "src/utils.ts add comments"
- [ ] "지금 수정한 파일들 JSDoc 정리해줘"

**발동하면 안 됨:**
- [ ] "이 Python 함수에 docstring 달아줘" → .ts/.tsx 아님
- [ ] "README에 사용법 문서화해줘" → 코드 주석 아님
- [ ] "이 함수 리팩터링해줘" → 문서화 요청 아님

---

## 기록

| 날짜 | 변경한 설명문 | 결과 요약 |
|------|--------------|----------|
| 2026-07-13 | 초기 작성 (Phase C 위생 직후) | 미실행 |
