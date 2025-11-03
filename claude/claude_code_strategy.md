# Claude Code 사용법 전략 심층 분석

> **원본 참고 자료:** [How I Use Every Claude Code Feature](https://blog.sshh.io/p/how-i-use-every-claude-code-feature) by Shrivu Shankar

## 개요

이 문서는 Claude Code의 효과적인 활용 전략에 대한 종합적인 분석을 담고 있습니다. 개인 프로젝트와 기업용 모노레포 환경에서 광범위하게 활용되며, 핵심 구성요소와 고급 기능의 실제 사용 방식을 정리합니다.

**핵심 철학:** 효과적인 에이전트 운용의 핵심은 **출력 스타일이나 UI가 아닌 최종 PR의 품질**에 있으며, "설정 후 방치(shoot and forget)" 방식의 위임이 목표입니다.

---

## 1. 핵심 철학: "Shoot and Forget" 원칙

### 기본 접근법
- Claude Code를 단순 CLI가 아닌 **엔터프라이즈급 AI 개발 인프라**로 활용
- **"위임 → 컨텍스트 설정 → 작업 수행"** 순서로 진행
- 도구 판단 기준은 **최종 PR의 품질** (과정보다는 결과물)
- 사용자가 과도하게 루프에 관여하지 않는 것이 목표

### 왜 다른 도구보다 Claude Code인가?
CLI 에이전트 시장은 Claude Code, Gemini CLI, Cursor, Codex CLI로 혼잡하지만 **실질적 경쟁은 Anthropic과 OpenAI** 둘이 경쟁합니다. 하지만 개발자들과 대화 해보면 도구 선택은 **표면적 요소에 의존**합니다:
- "운 좋은" 기능 구현
- 선호하는 시스템 프롬프트의 "Vibe"

현재 시점에서 이러한 도구들은 모두 상당히 우수한 상태입니다.

---

## 2. CLAUDE.md: 에이전트의 헌법

가장 중요한 파일로, 에이전트의 행동 규칙과 도구 사용법을 정의하는 "헌법" 역할을 수행합니다.

### 컨텍스트별 작성 전략

**취미 프로젝트:**
- Claude가 원하는 대로 자유롭게 작성
- 단순하고 가벼운 가이드라인

**엔터프라이즈 모노레포:**
- **13KB 규모로 엄격 관리** (최대 25KB까지 확장 가능)
- 엔지니어 30% 이상이 사용하는 도구만 문서화
- 각 내부 도구 문서화에 최대 토큰 수 할당 ("광고 공간" 판매 방식)
- 도구를 간결하게 설명하지 못하면 `CLAUDE.md` 준비 미완료

### 작성 팁과 안티패턴

#### ✅ 좋은 예시
```markdown
# Monorepo

## Python
- Always use virtual environments
- Test with `pytest --cov=src`
- Install dependencies via `pip install -e .`

## <내부 CLI 도구>
... 80% 사용 사례에 집중한 10개 불릿 ...
- <사용 예시>
- Always ...
- Never <x>, prefer <Y>

복잡한 사용법이나 오류 시 path/to/<tool>_docs.md 참조
```

#### 핵심 작성 원칙
1. **가드레일로 시작, 매뉴얼 아님**: Claude가 잘못하는 부분 기반으로 소규모 문서화
2. **@파일 문서화 금지**: 광범위한 문서를 @언급하면 매 실행 시 전체 파일이 임베딩되어 비대화
   - ✅ **올바른 방법**: "복잡한 사용법이나 `FooBarError` 발생 시 고급 문제 해결을 위해 `path/to/docs.md` 참조"
3. **"절대 안 됨"만 말하지 말 것**: 부정형 제약 회피, 항상 대안 제시
4. **CLAUDE.md를 강제 함수로 활용**: 복잡한 CLI는 bash 래퍼 작성 후 래퍼만 문서화

#### AGENTS.md와의 동기화
- 엔지니어가 사용하는 다른 AI IDE와 호환성 유지
- Anthropic 권장 방식: `CLAUDE.md` 파일에 `@AGENTS.md` 한 줄만 넣고, 실제 내용은 AGENTS.md에 두기

---

## 3. 컨텍스트 윈도우 관리 전략

### 윈도우 사용 현황 이해
- `/context` 명령으로 200k 토큰 윈도우 사용 현황 확인
- Sonnet-1M에서도 전체 컨텍스트 윈도우가 효과적으로 사용되는지 불확실
- 모노레포 새 세션 기본 **~20k 토큰(10%)** 소비
- 나머지 **180k는 변경 작업용** (빠르게 소진)

### 3가지 워크플로우 비교

| 워크플로우 | 특징 | 사용 시나리오 |
|-----------|-------|---------------|
| **`/compact` (회피)** | ❌ 자동 압축은 불투명, 오류 발생, 최적화 부족 | 거의 사용하지 않음 |
| **`/clear` + `/catchup`** | ✅ 단순 재시작 방식 | 기본 재부팅 방식 |
| **"Document & Clear"** | ✅ 대용량 작업용 | 복잡한 작업 완료 후 외부 메모리 생성 |

#### 실행 예시
```bash
# 단순 재시작
/clear
/catchup

# 복잡한 작업 재시작
# 1. Claude가 계획과 진행상황을 `.md`에 덤프
# 2. /clear로 상태 초기화
# 3. 새 세션에서 `.md` 읽고 계속
```

---

## 4. 슬래시 명령어: 최소주의 접근

### 효과적인 설정
**최소 설정 원칙**: 슬래시 커맨드는 **자주 사용하는 프롬프트의 단순 바로가기**, 그 이상도 이하도 아님

```bash
# 기본 설정
/catchup    # git 브랜치의 모든 변경 파일 읽기 프롬프트
/pr         # 코드 정리, 스테이징, PR 준비 헬퍼
```

### 안티패턴: 복잡한 커스텀 명령 리스트
❌ **실패하는 접근법:**
```bash
# 나쁜 예시: 복잡한 커스텀 명령 리스트
/setup-project
/run-tests
/generate-docs
/optimize-performance
/deploy-production
# ... 20개 이상의 명령어
```

✅ **올바른 접근법:**
- Claude 같은 에이전트의 핵심: **거의 모든 자연어 입력으로 유용하고 병합 가능한 결과 생성**
- 엔지니어에게 작업 수행을 위한 "매직 커맨드" 필수 리스트 학습 강요 = 실패
- **더 직관적인 CLAUDE.md와 더 나은 도구를 갖춘 에이전트 구축**이 목표

---

## 5. Subagent vs Task(...): Master-Clone 아키텍처

### 커스텀 Subagent의 이론적 장점
**컨텍스트 관리 기능:**
- 복잡한 작업: `X` 토큰 입력 컨텍스트 + `Y` 토큰 작업 컨텍스트 + `Z` 토큰 답변
- `N`개 작업 = 메인 윈도우에서 `(X + Y + Z) * N` 토큰
- Subagent 솔루션: `(X + Y) * N` 작업을 특화 에이전트에 위임, 최종 `Z` 토큰 답변만 반환

### 실전에서 커스텀 Subagent가 만드는 두 가지 문제

1. **컨텍스트 게이트키핑**
   ```markdown
   # Problem:
   # PythonTests Subagent 생성 시
   # 메인 에이전트에서 모든 테스트 컨텍스트 숨김
   # → 전체적 추론 불가능
   # → 자체 코드 검증 방법 알기 위해 Subagent 호출 강제
   ```

2. **인간 워크플로우 강제**
   ```markdown
   # Problem:
   # Claude를 경직된 인간 정의 워크플로우로 강제
   # 위임 방법 지시 = 에이전트가 해결해야 할 문제 자체
   ```

### Task(...) 기능 선호: Master-Clone 아키텍처

**원리:**
1. **Claude 빌트인 `Task(...)` 기능**으로 범용 에이전트 복제본 생성
2. `CLAUDE.md`에 모든 핵심 컨텍스트 배치
3. 메인 에이전트가 자체 복사본에 작업 위임 시점과 방법을 결정
4. Subagent의 컨텍스트 절약 이점은 유지하면서 단점은 제거
5. **에이전트가 자체 오케스트레이션을 동적으로 관리**

```markdown
# "Building Multi-Agent Systems (Part 2)"에서 "Master-Clone" 아키텍처라 명명
# 커스텀 Subagent가 유도하는 "Lead-Specialist" 모델보다 강력히 선호
```

---

## 6. Resume, Continue, History

### 기본 수준 활용
```bash
# 빈번히 사용하는 명령어
claude --resume    # 버그가 있는 터미널 재시작
claude --continue  # 오래된 세션 빠른 재부팅
```

**실전 활용:**
- 며칠 전 세션 `claude --resume`하여 **특정 오류 극복 방법 요약**
- → `CLAUDE.md` 및 내부 도구 개선

### 심화 활용: 메타 분석
```bash
# 세션 히스토리 위치
~/.claude/projects/

# 스크립트 활용
# 로그에 대한 메타 분석 실행:
# - 공통 예외 패턴 검색
# - 권한 요청 분석
# - 오류 패턴 발견 → 에이전트 대상 컨텍스트 개선
```

---

## 7. Hooks: 결정론적 "must-do" 규칙

**엔터프라이즈에서 핵심적**: 취미 프로젝트에서는 미사용

`CLAUDE.md`의 "should-do" 제안을 보완하는 **결정론적 "must-do" 규칙**

### 두 가지 유형

#### 1. 커밋 단계 차단 Hook (Block-at-Submit): 주요 전략
```rust
// 예시: PreToolUse Hook으로 모든 `Bash(git commit)` 명령 래핑
// `/tmp/agent-pre-commit-pass` 파일 확인
// 테스트 스크립트가 모든 테스트 통과 시에만 생성
// 파일 없으면 커밋 차단
// → 빌드 성공까지 Claude를 "테스트-수정" 루프로 강제
```

#### 2. 힌트 Hook: 단순한 비차단 Hook
- 에이전트가 차선책 수행 시 "fire-and-forget" 피드백 제공
- 단순한 비차단 피드백

### 의도적 미사용: 쓰기 단계 차단 Hook
```bash
# Edit 또는 Write 시 차단 ❌
# - 계획 중간에 에이전트 차단 시 혼란 또는 "좌절" 유발
# - 작업 완료 후 커밋 단계에서 최종 완료 결과 확인이 훨씬 효과적 ✅
```

---

## 8. 플래닝 모드

**AI IDE로 "대규모" 기능 변경 시 필수**

### 취미 프로젝트: 빌트인 플래닝 모드 독점 사용
```markdown
# 실행 순서:
# 1. Claude 시작 전 정렬 방법 정의
# 2. 빌드 방법 정의
# 3. 작업 중단 및 결과 표시 필요한 "검사 체크포인트" 정의
# 4. 정기적 사용으로 직관 구축:
#    - Claude가 구현을 망치지 않고 좋은 계획 얻는 데 필요한 최소 컨텍스트에 대한 강한 직관
```

### 엔터프라이즈 모노레포: 커스텀 플래닝 도구
```markdown
# Claude Code SDK 기반 커스텀 플래닝 도구 롤아웃:
# - 네이티브 플랜 모드와 유사하지만 기존 기술 설계 포맷에 출력 정렬하도록 집중 프롬프트
# - 내부 모범 사례 강제:
#   * 코드 구조부터 데이터 프라이버시
#   * 보안까지 기본 제공
# - 엔지니어가 시니어 아키텍트처럼 새 기능 "vibe plan" 가능
```

---

## 9. Skills vs MCP: 스크립팅 기반 모델

### 에이전트 자율성 멘탈 모델 3단계 진화

#### 1. Single Prompt
```markdown
# 에이전트에 모든 컨텍스트를 하나의 거대한 프롬프트로 제공
# ❌ 취약, 확장 불가
```

#### 2. Tool Calling
```markdown
# "클래식" 에이전트 모델
# 도구 수작업 제작 및 에이전트를 위한 현실 추상화
# ✅ 개선됐지만 새로운 추상화와 컨텍스트 병목 생성
```

#### 3. Scripting
```markdown
# ✅ 에이전트에 원시 환경 접근 제공 (바이너리, 스크립트, 문서)
# → 에이전트가 즉석에서 코드 작성하여 상호작용
# Agent Skills는 명백한 다음 기능: "Scripting" 레이어의 공식 제품화
```

### Skills의 이점

**이미 구현하고 있다면:**
- CLI를 MCP보다 선호했다면 **이미 암묵적으로 Skills의 이점 획득**
- `SKILL.md` 파일은 이러한 CLI와 스크립트를 문서화하고 에이전트에 노출하는 **더 조직화되고 공유 가능하며 발견 가능한 방법**

**올바른 추상화:**
- **MCP가 나타내는 경직된 API 같은 모델보다 더 견고하고 유연한 "스크립팅" 기반 에이전트 모델을 공식화**

### MCP의 새로운 역할: 데이터 게이트웨이

#### 이전 문제점
```markdown
# 많은 이들이 REST API 미러링하는 수십 개 도구로 끔찍하고 컨텍스트 무거운 MCP 구축
read_thing_a()
read_thing_b()
update_thing_c()
# ❌ 컨텍스트 과다, 비효율적
```

#### "Scripting" 모델 (Skills로 공식화)
**더 나은 방식이지만 환경 접근을 위한 안전한 방법 필요** → MCP의 새롭고 더 집중된 역할

**간단하고 안전한 게이트웨이:**
```python
# 몇 가지 강력한 고수준 도구만 제공
download_raw_data(filters…)
take_sensitive_gated_action(args…)
execute_code_in_environment_with_state(code…)
```

**MCP의 새로운 역할:**
- **에이전트를 위한 현실 추상화가 아닌** 인증, 네트워킹, 보안 경계 관리 후 방해하지 않기
- 에이전트용 진입점 제공 → 에이전트는 스크립팅과 `markdown` 컨텍스트로 실제 작업 수행

**현재 사용 중인 유일한 MCP:**
- [Playwright](https://github.com/microsoft/playwright-mcp) (복잡하고 상태 저장 환경이라 타당)
- 모든 무상태 도구 (Jira, AWS, GitHub)는 단순 CLI로 마이그레이션

---

## 10. Claude Code SDK: 범용 에이전트 프레임워크

Claude Code는 대화형 CLI일 뿐 아니라 **코딩 및 비코딩 작업 모두를 위한 완전히 새로운 에이전트 구축용 강력한 SDK**

LangChain/CrewAI 같은 도구보다 **기본 에이전트 프레임워크**로 사용 시작

### 세 가지 주요 사용 방식

#### 1. 대규모 병렬 스크립팅
**사용 시나리오**: 대규모 리팩토링, 버그 수정, 마이그레이션

```bash
# 대화형 채팅 미사용
# 단순 bash 스크립트로 병렬 호출
claude -p "in /pathA change all refs from foo to bar"

# 메인 에이전트가 수십 개 Subagent 작업 관리하는 것보다
# ✅ 훨씬 확장 가능하고 제어 가능
```

#### 2. 내부 채팅 도구 구축
**사용자**: 비기술 사용자

**활용 예시:**
- 오류 시 Claude Code SDK로 폴백하여 사용자 문제 해결하는 **인스톨러**
- 디자인 팀이 사내 UI 프레임워크로 목업 프론트엔드를 vibe-code할 수 있는 사내 **"v0-at-home" 도구**
  - 아이디어 고충실도 보장
  - 프론트엔드 프로덕션 코드에서 더 직접 사용 가능

#### 3. 신속한 에이전트 프로토타이핑
**가장 일반적 사용 사례**, 코딩 전용 아님

```markdown
# 에이전트 작업 아이디어가 있을 때:
# 예: 커스텀 CLI 또는 MCP 사용 "위협 조사 에이전트"

# 전체 배포 스캐폴딩 커밋 전
# Claude Code SDK로 프로토타입 빠르게 구축 및 테스트
```

---

## 11. Claude Code GitHub Action (GHA)

**가장 좋아하고 과소평가된 기능 중 하나**: 단순 개념 (GHA에서 Claude Code 실행)이지만 이 단순함이 강력함의 원천

### 다른 제품 대비 장점

**비교 대상:**
- Cursor의 백그라운드 에이전트
- Codex 관리형 웹 UI

**Claude Code GHA의 장점:**
- 전체 컨테이너와 환경 제어 → 데이터 접근성 향상
- 다른 제품보다 **훨씬 강력한 샌드박싱 및 감사 제어**
- Hook, MCP 같은 모든 고급 기능 지원

### 활용 사례

#### 1. 커스텀 "어디서나 PR" 도구 구축
```bash
# 트리거 소스:
Slack → GHA → 버그 수정 → 완전히 테스트된 PR 반환
Jira → GHA → 기능 추가 → 완전히 테스트된 PR 반환
CloudWatch 알림 → GHA → 자동 수정 → PR 생성
```

#### 2. 데이터 기반 플라이휠
```bash
# GHA 로그 = 전체 에이전트 로그
# 회사 수준에서 정기적으로 로그 검토:
# - 공통 실수 발견
# - bash 오류 패턴 분석
# - 정렬되지 않은 엔지니어링 관행 발견

# 플라이휠: 버그 → CLAUDE.md/CLI 개선 → 더 나은 에이전트
$ query-claude-gha-logs --since 5d | claude -p "see what the other claudes were getting stuck on and fix it, then put up a PR"
```

---

## 12. settings.json: 필수 구성

**취미 및 업무 작업 모두에 필수적인 특정 구성**

### 핵심 설정 값

#### HTTPS_PROXY/HTTP_PROXY
```json
{
  "HTTPS_PROXY": "http://localhost:8080",
  "HTTP_PROXY": "http://localhost:8080"
}
```
**활용도:**
- 디버깅용: 원시 트래픽 검사로 Claude가 전송하는 정확한 프롬프트 확인
- 백그라운드 에이전트용: 세밀한 네트워크 샌드박싱 강력한 도구

#### MCP_TOOL_TIMEOUT/BASH_MAX_TIMEOUT_MS
```json
{
  "MCP_TOOL_TIMEOUT": 600000,
  "BASH_MAX_TIMEOUT_MS": 600000
}
```
**이유:**
- 길고 복잡한 명령 실행 선호
- 기본 타임아웃이 종종 너무 보수적
- bash 백그라운드 작업 이후 여전히 필요한지 불확실하지만 만약을 위해 유지

#### ANTHROPIC_API_KEY
```json
{
  "ANTHROPIC_API_KEY": "enterprise-api-key"
}
```
**엔터프라이즈 운영:**
- [apiKeyHelper](https://www.reddit.com/r/ClaudeAI/comments/1jwvssa/comment/mtt0urz/) 통해 사용
- "좌석당" 라이선스에서 **"사용량 기반"** 가격으로 전환 (작업 방식에 훨씬 나은 모델)
- 개발자 사용량의 막대한 차이 고려 (엔지니어 간 **1:100배** 차이 확인)
- 엔지니어가 단일 엔터프라이즈 계정으로 비Claude-Code LLM 스크립트 실험 가능

#### permissions
```json
{
  "permissions": [
    "Bash(git add)",
    "Bash(git commit)",
    "Bash(git push)",
    "Read(*)",
    "Edit(*)",
    "Write(*)"
  ]
}
```
**목적**: Claude가 자동 실행 허용한 명령 리스트 주기적 자체 감사

---

## 핵심 인사이트 요약

### 🎯 가장 중요한 원칙
1. **Claude Code는 단순한 CLI 도구가 아닌 새로운 에이전트 구축 플랫폼**
2. **가장 중요한 것은 CLAUDE.md를 통한 컨텍스트 관리**
3. **"Shoot and Forget" 원칙: 위임과 결과물에 집중**

### 🛠️ 기술적 전략
1. **커스텀 Subagent보다는 Task(...)와 Master-Clone 아키텍처 선호**
2. **Skills와 MCP의 차이를 이해하고 적절히 활용**
3. **Hooks와 GHA를 통한 엔터프라이즈급 자동화 구축**

### 🚀 조직적 관점
1. **프롬프트 설계보다는 도구와 워크플로우 최적화에 집중**
2. **AI가 읽을 수 있는 문서 작성 (간결하고 구체적으로)**
3. **지속적인 개선 사이클: GHA 로그 분석 → CLAUDE.md 개선 → 더 나은 에이전트**

---

## 마무리 및 권장사항

### 즉시 실행할 수 있는 행동 계획

#### 1. CLAUDE.md 구축 시작
```bash
# 현재 프로젝트에서 시작
touch CLAUDE.md
# 기본 구조 작성 후 Claude가 잘못하는 부분을 기반으로 지속적으로 개선
```

#### 2. 컨텍스트 윈도우 이해
```bash
# 작업 세션 중간에 한 번 실행
/context
#如何使用 200k 토큰을 효과적으로 사용하는지 관찰
```

#### 3. 기본 슬래시 명령어 설정
```bash
# /catchup과 /pr 정도만 설정
# 복잡한 리스트보다는 CLAUDE.md와 도구 개선에 집중
```

#### 4. 플래닝 모드 경험
```bash
# 복잡한 변경 작업 시 플래닝 모드 사용
# "검사 체크포인트" 정의 연습
```

### 학습 방법

**이 전략들을 제대로 활용하면:**
Claude Code를 단순한 코드 생성 도구에서 **엔터프라이즈급 AI 개발 인프라**로 확장할 수 있습니다.

**학습의 유일한 방법은 직접 뛰어드는 것입니다:**
- 이러한 고급 기능에 대한 좋은 가이드는 드물기 때문에 경험을 통해 익히는 것이 중요합니다
- 개인 프로젝트부터 시작하여 점진적으로 엔터프라이즈 기능으로 확장하세요

---

## 참고 자료

- [How I Use Every Claude Code Feature](https://blog.sshh.io/p/how-i-use-every-claude-code-feature) - 원본 아티클
- [Claude Code Best Practices](https://docs.claude.com/en/docs/claude-code/claude-code-on-the-web#best-practices)
- [Building Multi-Agent Systems (Part 2)](https://blog.sshh.io/p/building-multi-agent-systems-part)
- [AI Can't Read Your Docs](https://blog.sshh.io/p/ai-cant-read-your-docs)
- [Everything Wrong with MCP](https://blog.sshh.io/p/everything-wrong-with-mcp)

---

*이 문서는 Claude Code 사용법 전략에 대한 종합적인 분석을 제공하며, 실제 경험을 바탕으로 작성되었습니다. 지속적 업데이트를 통해 최신 정보와 경험을 반영할 예정입니다.*
