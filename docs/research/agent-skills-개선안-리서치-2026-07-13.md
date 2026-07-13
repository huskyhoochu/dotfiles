# Matt Pocock의 에이전트 스킬 방법론 분석 및 dotfiles 스킬 개선안 — 리서치 리포트

> 날짜: 2026-07-13 (월) | 키워드: mattpocock/skills + YouTube(YLq04CDeOTE) 기반 스킬 개선 방법론

## 한줄 요약

Pocock 방법론의 핵심은 "스킬은 확률적 시스템에서 **예측 가능성**(같은 출력이 아니라 같은 *과정*)을 짜내는 장치"라는 것이며, 이를 위해 ① 호출 방식(트리거) 선택, ② 최소 본문 구조, ③ 선행 단어(leading words)로 유도, ④ 삭제 테스트 기반 가지치기라는 4단계 체크리스트를 제시한다 — 우리 dotfiles 스킬은 구조(progressive disclosure)는 이미 우수하나, **호출 방식 최적화·가지치기 규율·트리거 평가**가 부재하다.

## 핵심 발견사항

| # | 발견사항 | 소스 유형 | 신뢰도 |
|---|---------|----------|--------|
| 1 | 스킬의 근본 덕목은 "예측 가능성" — 매번 같은 답이 아니라 매번 같은 방식으로 작동하게 만드는 것 | 영상 + 저장소(`writing-great-skills`) | 높음 |
| 2 | 호출 축이 최대 토큰 레버: 모델 호출 스킬은 설명문이 항상 컨텍스트에 상주(컨텍스트 부하), 사용자 호출은 부하 제로지만 사용자가 색인 역할(인지 부하). Pocock은 대부분을 사용자 호출로 만들어 문제를 통째로 제거 | 영상 + 저장소 | 높음 |
| 3 | 본문은 극단적으로 작게: 대표 스킬 `grill-me`는 프론트매터 포함 20단어. 오케스트레이터는 한 줄("Run a `/grilling` session, using the `/domain-modeling` skill")로 프리미티브를 조합 | 영상 + 저장소 | 높음 |
| 4 | "선행 단어"가 문단을 대체: *vertical slice*, *seam*, *tracer bullet*, *red* 같이 모델이 이미 학습한 강한 개념어를 심어 사전 지식 전체를 활성화하고, 그 단어가 불필요하게 만든 산문은 삭제 | 영상 + 저장소 | 높음 |
| 5 | 가지치기 규율: "이 문단을 지워도 결과가 같으면 처음부터 필요 없던 것"(삭제 테스트). 실패 유형에 이름 부여 — no-op, sediment(퇴적), sprawl(비대), duplication, negation(부정 표현은 코끼리를 호명하니 긍정형으로) | 영상 + 저장소 | 높음 |
| 6 | 미래 단계 숨기기: 에이전트는 "목표를 보여주면 서두르고, 가리면 파고든다" — 질문 스킬과 계획 작성 스킬을 분리해 다음 단계의 존재를 감춤 | 영상 | 높음 |
| 7 | 어휘 통제: 루트 `CONTEXT.md`/`GLOSSARY.md`에 용어 정의 + `_Avoid_:` 동의어 금지 목록. 설정은 스킬 밖으로(1회성 setup 인터뷰가 저장소별 config 생성) | 영상 + 저장소 | 높음 |
| 8 | 진화 방식: 저장소에 공식 eval 하니스는 **없음** — 매일 dogfooding + GitHub 사용자 리포트 + 모든 수정에 산문 근거를 남기는 changeset 규율(CHANGELOG가 설계 일지). 단, 별도 영상과 Anthropic 공식 문서는 소규모 eval(3-5개 트리거/비트리거 케이스)을 권장 | 저장소 + 보조 소스 | 높음 |

## 상세 분석

### 합의점

세 소스(영상 네이티브 분석, 저장소 클론 분석, 서드파티 보조 소스)가 일치하는 지점:

- **작고 조합 가능한 단일 목적 스킬**이 무겁고 절차를 소유하는 프레임워크(BMAD, Spec-Kit 류)보다 낫다. 스킬은 능력 확장이 아니라 **워크플로우 규율의 강제**다(interrogation-before-planning, red-green-refactor 등).
- 새 개념 발명이 아니라 **수십 년 된 소프트웨어 공학 고전의 재활용**(실용주의 프로그래머, DDD, A Philosophy of Software Design)이 핵심이다.
- Progressive disclosure는 **분기(branching)가 있을 때만** 정당화된다: 모든 분기가 필요로 하는 내용은 인라인, 분기별 내용은 sibling 파일로. 포인터의 *문구*가 참조 신뢰도를 좌우한다.

### 논쟁점 / 의견 분화

**eval 주도 vs 현장 주도 반복.** 보조 소스(Anthropic 공식 문서, Pocock의 별도 eval 영상)는 "eval 먼저" 접근을 권하지만, 정작 그의 저장소에는 eval 하니스가 전혀 없고 dogfooding + 삭제 테스트 + 근거 있는 changelog로 진화한다. **판정: 현장 주도가 더 잘 뒷받침된다** — 단일 사용자 환경(개인 dotfiles 포함)에서는 실사용 실패가 가장 저렴하고 정확한 신호이며, 삭제 테스트 자체가 "실행해서 확인하라(settled by running, not debate)"는 경량 eval이다. 다만 **트리거링(스킬이 제때 발동하는가)만큼은** 사용 중에 관찰하기 어려우므로 소규모 트리거/비트리거 케이스가 보완재로 유효하다.

**스킬 개수 집계 불일치.** 영상은 29개, 저장소 분석은 v1.1 기준 승격된 스킬 ~22개로 집계 — `in-progress/`/`deprecated/` 포함 여부 차이로 보이며 방법론 결론에는 영향 없음.

### 정량 데이터

- `grill-me/SKILL.md`: 프론트매터 포함 전체 **20단어**
- 컨텍스트 위생 "smart zone": **~120k 토큰** 이내에서 grill→tickets를 한 창으로 유지
- Anthropic 공식 권고: SKILL.md **500줄 미만**, eval **3-5개** 쿼리 세트
- 우리 스킬 현황: web-research 272줄 / web-design 216줄 / uiux-review 214줄, Python 스크립트 9개 전부 stdlib 자족형, eval 인프라 **0개**

## 종합 판단

**입장:** 우리 dotfiles 스킬의 다음 개선 사이클은 "구조 보강"이 아니라 **호출 방식 감사 → 가지치기 → 선행 단어 치환** 순서로 진행해야 하며, Pocock식 대규모 재편(라우터 스킬, 흐름 파이프라인)은 도입하지 않는 것이 옳다.

**확신도:** 높음 — 1차 소스 2종(저장소 직접 클론 분석 + Gemini 네이티브 영상 분석)이 상호 일치하고, 독립적 서드파티 소스가 교차 확증하며, 우리 저장소 인벤토리도 직접 조사했다.

**근거:** 우리 스킬은 Pocock 체크리스트 4단계 중 2단계(구조: progressive disclosure, 참조 분리)는 이미 그의 수준으로 충족하고, 일부(web-research의 단계 분리·서브에이전트 은닉)는 그의 "미래 숨기기" 원칙을 이미 구현하고 있다. 반면 1단계(호출 방식)와 4단계(가지치기)는 완전히 미적용 상태다: 15개 이상 스킬의 풍부한 설명문이 전부 모델 컨텍스트에 상주하고(그가 지목한 정확한 컨텍스트 부하 문제), 삭제 테스트·실패 유형 점검 이력이 전무하다. 갭이 있는 곳에 투자하는 것이 한계 효용이 가장 크다.

**반대 입장이 더 약한 이유:** "라우터 스킬 + 흐름 파이프라인까지 이식하자"는 견해는 그의 스킬들이 grill→spec→tickets→implement라는 **단일 개발 흐름의 단계들**이기에 성립한다. 우리 스킬은 대부분 독립 도구(검색, 윤문, DB 설계, 문서화)라 흐름이 없고, 라우터는 "거짓말하는 라우터"(동기화 비용) 리스크만 추가한다. 반대로 "지금도 잘 되니 그대로 두자"는 견해는 스킬 목록이 계속 늘어나는 추세(현재 세션에도 50+개 설명문 로드)에서 컨텍스트 부하가 단조 증가한다는 사실을 외면한다.

**이 결론을 뒤집을 조건:** Claude Code가 스킬 설명문을 지연 로딩(계층 색인화)하는 방향으로 바뀌면 호출 방식 감사의 우선순위가 급락한다. 또한 우리 스킬들이 서로를 호출하는 파이프라인으로 진화하면(예: research→polish→publish 흐름) 라우터 스킬 도입이 정당화된다.

---

## 우리 dotfiles 스킬 개선안 (우선순위순)

### 1. 호출 방식 감사 — 최대 토큰 레버 ★
슬래시로만 부르는 스킬(`web-research`, `web-design`, `codebase-docs`, `uiux-review`, `tsdoc` 등)에 모델 호출 비활성화 옵션(Pocock 저장소의 `disable-model-invocation: true`에 해당하는 Claude Code 프론트매터)을 적용해 설명문의 상시 컨텍스트 상주를 제거. 모델이 자율 발동해야 하는 스킬(`quick-search`, `korean-polish`, `pg-aiguide`)만 모델 호출로 남긴다. 적용 전 현재 Claude Code 버전의 프론트매터 스펙 확인 필요.

### 2. 삭제 테스트 기반 가지치기
최장 3개 스킬(web-research 272줄, web-design 216줄, uiux-review 214줄)에 대해 문단 단위로 "지우면 행동이 달라지는가?"를 실행으로 검증. Pocock의 5대 실패 유형(no-op / sediment / sprawl / duplication / negation) 체크리스트를 커밋 메시지 규율과 함께 도입 — 그의 CHANGELOG처럼 **왜 지웠는지 산문 근거**를 남긴다.

### 3. 선행 단어 치환
절차를 길게 서술한 문단을 모델이 이미 아는 강한 개념어로 교체하고 잉여 산문 삭제. 예: web-research의 반박 검색 문단 → "disconfirming evidence" 앵커는 이미 있음(양호); korean-polish의 진단 절차 → "diagnosis-first" 앵커 강화; uiux-review → *heuristic evaluation*, *WCAG* 같은 앵커 활용.

### 4. 설명문 위생 — "분기당 트리거 하나"
`web-design`은 트리거 문구가 전무한 최약체 — KO/EN 트리거 추가. 반대로 일부 설명문은 duplication 실패 유형(같은 분기를 여러 문구로 반복) 점검 대상.

### 5. 경량 트리거 eval
스킬별 3-5개의 트리거/비트리거 프롬프트 목록을 `evals/triggers.md` 한 파일로 관리(Anthropic 권고 + 그의 eval 영상). 하니스 구축까지는 불필요 — 수동 확인으로 충분.

### 6. 공유 HTTP 헬퍼 (자체 발견)
9개 stdlib 스크립트가 동일한 `urllib` 요청/에러 보일러플레이트를 각자 재구현 중 — `scripts/_http.py` 공유 모듈로 흡수. 단, Pocock의 "설정은 스킬 밖으로" 원칙과 별개인 우리 저장소 고유 이슈.

### 7. 이식성 갭 수정 (자체 발견)
`claude/**/CLAUDE.md` gitignore 규칙 때문에 스킬 내부 보조 CLAUDE.md가 커밋되지 않아 다른 머신에 전파되지 않음 — 의도된 것인지 확인 후, 의도라면 스킬이 해당 파일에 의존하지 않도록 정리.

## 소스 상세

### 기사 및 문서
| 소스 | 핵심 내용 | URL |
|------|----------|-----|
| mattpocock/skills 저장소 (1차, 클론 분석) | 메타 스킬 `writing-great-skills`, 호출 축, 라이프사이클 버킷, CHANGELOG 규율 | [github.com/mattpocock/skills](https://github.com/mattpocock/skills) |
| Anthropic 스킬 작성 모범 사례 (공식) | 500줄 규칙, eval-first, 설명문 최적화 | [platform.claude.com](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| tosea.ai 실무 가이드 | "워크플로우 강제 vs 능력 확장" 프레임 | [tosea.ai](https://tosea.ai/blog/matt-pocock-skills-claude-code-guide) |
| byteiota 분석 | 저장소 구조와 "vibe coding → real engineering" 철학 | [byteiota.com](https://byteiota.com/agent-skills-framework-revolution-vibe-coding-to-real-engineering/) |

### 영상
| 소스 | 제목 | 핵심 내용 | URL |
|------|------|----------|-----|
| YouTube (Gemini 네이티브 분석) | 스킬 구축 4단계 체크리스트 | Skill Hell 진단, 컨텍스트/인지 부하 저울, grill-me 20단어, vertical slice 유도, 삭제 테스트, 경주마 눈가리개 비유(미래 숨기기) | [youtube.com/watch?v=YLq04CDeOTE](https://www.youtube.com/watch?v=YLq04CDeOTE) |
| YouTube (메타데이터만) | How to Evaluate and Test Agent Skills | eval 워크플로우 — 고정 프롬프트 세트 대비 수동 발동·채점·반복 | [youtube.com/watch?v=XUzUf_HCgvk](https://www.youtube.com/watch?v=XUzUf_HCgvk) |

### 커뮤니티 토론
| 플랫폼 | 주요 주장 | 여론 비율 | URL |
|--------|----------|----------|-----|
| Reddit r/ClaudeAI | 스킬 대량 삭제 후 Pocock식 소수 정예 프리미티브로 전환, 만족 | 우호 다수 | [reddit.com](https://www.reddit.com/r/ClaudeAI/comments/1sw6rss/i_deleted_most_of_my_claude_skills_last_week/) |

## 미비점 및 추가 조사 필요 영역

- Claude Code 현행 버전에서 `disable-model-invocation` 프론트매터 키의 정확한 지원 여부·문법은 이번 소스들에서 확정하지 못했다 — 개선안 1번 착수 전 공식 문서 확인 필요.
- 스킬 개수(21/22/29)의 정확한 현재 값은 소스 간 시점 차이로 미확정이나 결론에 영향 없음.

## 전체 출처

1. [github.com/mattpocock/skills](https://github.com/mattpocock/skills) (1차 — 클론 분석)
2. [YouTube: 스킬 구축 체크리스트 영상](https://www.youtube.com/watch?v=YLq04CDeOTE) (1차 — Gemini 네이티브 분석)
3. [Anthropic: Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
4. [YouTube: How to Evaluate and Test Agent Skills](https://www.youtube.com/watch?v=XUzUf_HCgvk)
5. [tosea.ai 가이드](https://tosea.ai/blog/matt-pocock-skills-claude-code-guide)
6. [byteiota 분석](https://byteiota.com/agent-skills-framework-revolution-vibe-coding-to-real-engineering/)
7. [Reddit r/ClaudeAI 사례](https://www.reddit.com/r/ClaudeAI/comments/1sw6rss/i_deleted_most_of_my_claude_skills_last_week/)
