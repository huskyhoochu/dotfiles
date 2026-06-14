# codebase-docs 스킬 격언 검증 — 리서치 리포트

> 날짜: 2026-06-12 | 키워드: codebase-docs 스킬 격언 검증 (CLAUDE.md 컨텍스트 엔지니어링 베스트 프랙티스 2026)

## 한줄 요약

2026년 중반 기준, 스킬의 7개 격언 중 5개(인덱스형 간결성, 영어 작성, 정체성 프레이밍, 위치 배치, 점진적 공개)는 여전히 유효하거나 오히려 강화됐지만, **가장 큰 패러다임 전환은 "문서를 잘 쓰는 법"이 아니라 "LLM이 자동 생성한 장황한 컨텍스트 파일 자체가 성능을 깎는다"는 ETH Zurich의 실증 결과**이며 — codebase-docs처럼 LLM이 문서를 생성하는 스킬은 이 결과를 정면으로 반영해 "추론 불가능한 정보만 남기는" 방향으로 재설계해야 하고, .cursorrules 마이그레이션 격언은 AGENTS.md 표준화 흐름을 반영해 갱신이 필요하다.

## 핵심 발견사항

| # | 발견사항 | 소스 유형 | 신뢰도 |
|---|---|---|---|
| 1 | ETH Zurich 연구(ICLR 2026 워크숍): LLM 생성 컨텍스트 파일은 과제 성공률을 평균 -2~-3%p 낮추고, 모든 컨텍스트 파일이 추론 비용을 19~23% 증가시킴. 인간 작성 파일만 +4%p의 소폭 이득 | 동료심사 논문 + InfoQ/EngineersCodex/Upsun 보도 | 높음 |
| 2 | 에이전트는 컨텍스트 파일 지시를 충실히 따름(`uv` 언급 시 사용 빈도 1.6배) — 문제는 "무시"가 아니라 "불필요한 요구사항이 과제를 어렵게 만드는 것" | 동료심사 논문 | 높음 |
| 3 | Lost-in-the-middle은 2026년 1M 토큰 모델에서도 재현됨: U자형 회상 곡선, 가장자리 90%+ vs 중간 뚜렷한 하락, "500K 이상에서 안전한 모델 없음" | 학술(TACL/OpenReview) + 2026 실측 블로그 다수 | 높음 |
| 4 | Anthropic 공식 입장: Agent Skills의 핵심 설계 원리는 점진적 공개(메타데이터 → SKILL.md 본문 → 참조 파일 3단계), 상시 로드 컨텍스트는 최소화 | 공식 엔지니어링 블로그 + 공식 문서 | 높음 |
| 5 | NAACL 2025: 복잡한 지시는 영어 작성이 instruction-tuned 모델에서 더 효과적, 단 분류 등 단순 과제에서는 한국어·스페인어 등 대상 언어 지시가 영어를 이기는 사례도 다수 | 동료심사 논문 | 보통 |
| 6 | AGENTS.md가 크로스툴 표준으로 부상(공개 저장소 6만+ 개가 컨텍스트 파일 보유), Claude Code는 아직 네이티브 미지원이라 `@AGENTS.md` 참조/심링크가 합의된 우회책 | 커뮤니티(HN) + 다수 기사 | 높음 |
| 7 | 커뮤니티 실전 인사이트: "CLAUDE.md에 '안전한 코드를 써라' 한 줄은 거의 무효 — 같은 컴퓨트를 생성 후 체크리스트 리뷰(스킬/훅)로 구조화하는 게 실제 효과" (nibble 접근) | 커뮤니티(Reddit) | 보통 |

## 격언별 판정 (7개 항목)

### 1. CLAUDE.md는 인덱스로, 200줄 이하 유지 — **판정: 유효 (단, 근거 갱신 필요)**

- **근거**: ETH 연구·Upsun·EngineersCodex 모두 "짧고 비중복적"을 지지. 다만 어떤 소스도 200줄이라는 수치를 실증하지 않음 — 연구가 실제로 보여준 건 "줄 수"가 아니라 **중복성(repo에서 추론 가능한 내용의 재기술)이 해악**이라는 점. 아키텍처 개요·디렉토리 트리 같은 "인덱스성" 내용조차 탐색을 불필요하게 유발해 비용만 늘린다는 게 ETH의 발견.
- **스킬 수정 제안**: 200줄 상한은 유지하되 격언의 본문을 "줄 수 제한"에서 **"비추론성(non-inferable) 테스트"로 교체** — 각 줄에 대해 "에이전트가 package.json/코드에서 스스로 알아낼 수 있는가? 그렇다면 삭제"를 생성 단계의 필수 필터로 추가. 디렉토리 구조 나열 섹션은 기본 출력에서 제거하거나 대폭 축소.

### 2. 영어 작성 (~80% 영어 학습 데이터 근거) — **판정: 유효하나 근거 문구 갱신 필요**

- **근거**: NAACL 2025가 이 질문을 직접 실험 — "복잡한 가이드가 필요한 과제에서는 영어 지시가 더 효과적"이라고 결론. CLAUDE.md는 정확히 "복잡한 지시" 범주이므로 결론은 유지됨. 단, 단순 과제에서는 대상 언어 지시가 영어를 능가하는 사례(한국어 qwen2-i: tgt 82.5 vs en 79.0 등)가 있어 **"항상 영어가 우월"은 과장**이며, "80% 학습 데이터" 논리는 어떤 1차 소스도 직접 입증하지 않은 통속 근거.
- **스킬 수정 제안**: 격언 자체(지시 파일은 영어로)는 유지. 근거 문구를 "학습 데이터 비율" 대신 **"복잡한 지시 추종은 영어가 실증적으로 우세 (NAACL 2025)"로 교체**하고, "응답 언어는 별도 지정 가능(Output language 규칙)"을 명시.

### 3. 정체성 > 부정 프레이밍 — **판정: 유효 (직접 실증은 부재, 간접 지지)**

- **근거**: 2026년에 이 격언을 직접 검증한 실험은 발견되지 않음. 그러나 ETH 연구의 핵심 메커니즘 — 에이전트는 지시를 충실히 따르므로 **해석 부담이 적고 행동 가능한 기본값을 주는 지시가 유리** — 가 간접적으로 지지. "use pnpm, not npm" 식의 공식 문서·Upsun 권장 예시도 모두 긍정 기본값 + 짧은 부정 보조 형태. 반박 증거 없음.
- **스킬 수정 제안**: 유지. 단 신뢰도 표기를 "실증됨"이 아닌 "추론적 모범 사례"로 정직하게 조정.

### 4. Primacy-recency 배치 (lost-in-the-middle) — **판정: 유효, 오히려 강화됨**

- **근거**: 가장 강하게 재확인된 격언. 2026년 실측(dev.to 재현 실험: Claude Sonnet 4.5, 200청크에서 가장자리 90%+ vs 중간 뚜렷한 하락)과 2025-12 OpenReview 논문(현상이 검색 요구 구조에서 창발하는 본질적 속성)이 일치. 1M 토큰 마케팅과 무관하게 U자형 어텐션은 지속. "Never Lost in the Middle" 류 완화 기법 연구가 있다는 것 자체가 문제의 현존을 방증.
- **스킬 수정 제안**: 변경 불요. 다만 "CLAUDE.md가 충분히 짧으면(격언 1 준수 시) 이 격언의 실익은 줄어든다"는 우선순위 주석을 추가하면 일관성이 좋아짐 — 위치 최적화는 긴 컨텍스트의 보완책이지 장문 허용의 면죄부가 아님.

### 5. .claude/rules/ 경로 스코프 점진적 공개 — **판정: 유효, 강화됨**

- **근거**: Anthropic이 Agent Skills로 점진적 공개를 공식 아키텍처 원리로 격상("로드 가능한 컨텍스트는 사실상 무한"). Cursor의 `alwaysApply` + glob 패턴, Gemini CLI의 채택 등 업계 전반의 수렴. ETH의 "상시 로드 컨텍스트는 해롭다"는 발견과도 논리적으로 정합 — 해법이 바로 필요 시점 로딩.
- **스킬 수정 제안**: 유지·확장. 한 가지 추가 — Reddit/커뮤니티 합의에 따라 **"행동 교정성 규칙(보안, 코드 품질 체크리스트)은 rules보다 스킬/훅(생성 후 리뷰)으로 빼라"**는 분기 기준을 스킬에 넣을 것. 상시 규칙 파일은 도구·경로 제약 전용으로.

### 6. .cursorrules → CLAUDE.md/rules 마이그레이션 — **판정: 갱신 필요 (격언 중 유일하게 시대에 뒤처짐)**

- **근거**: AGENTS.md가 크로스툴 표준으로 명확히 부상(6만+ 저장소, OpenAI 주도, Cursor가 자동 로드). Claude Code는 아직 AGENTS.md 네이티브 미지원이지만, HN 스레드에서 검증된 합의 패턴은 ① `CLAUDE.md`에 `@AGENTS.md` 한 줄 참조(시스템 프롬프트에 동일하게 주입됨을 실험으로 확인) 또는 ② 저장소 내 상대 경로 심링크(`CLAUDE.md -> AGENTS.md`). .cursorrules 내용을 CLAUDE.md로만 흡수하면 다른 도구와의 호환을 버리는 일방향 마이그레이션이 됨. 단, HN 반론(도구별로 다른 지시가 필요한 경우 단일 파일이 오히려 불편)도 실재하므로 "CLAUDE.md 완전 폐기"는 과잉.
- **스킬 수정 제안**: 마이그레이션 대상을 **"공통 내용 → AGENTS.md(정본), CLAUDE.md는 `@AGENTS.md` 참조 + Claude 전용 내용만 담는 얇은 레이어"**로 변경. 스킬이 두 파일 구조를 기본 출력으로 제안하도록.

### 7. 구체성 > 추상성, 설정 파일 기반 명령어 검증 — **판정: 유효, 강화됨**

- **근거**: ETH 연구의 명시적 권고가 정확히 이것 — "인간 작성 파일은 최소 요구사항만: `uv` 같은 특수 툴링, 커스텀 빌드 명령. 코드베이스 개요는 노이즈". Claude Code 공식 best-practices의 예시도 전부 구체 명령("typecheck when done", "single tests not whole suite"). package.json/pyproject.toml에서 명령을 검증해 추출하는 관행은 Upsun도 동일하게 권장.
- **스킬 수정 제안**: 유지. 이 격언을 스킬의 **제1원칙으로 승격**할 것 — 2026년 증거상 "구체적 툴링/명령 + 비추론 제약"이 컨텍스트 파일에 남아야 할 거의 유일한 범주이기 때문.

## 상세 분석

### 합의점

- **"적을수록 좋다"**: 공식 문서(Anthropic), 동료심사 연구(ETH), 실무 블로그(Upsun, EngineersCodex), 커뮤니티(Reddit) 4개 소스 유형이 모두 수렴. 2026년 컨텍스트 파일 베스트 프랙티스의 단일 최대 합의.
- 점진적 공개가 상시 로드의 대안이라는 점, lost-in-the-middle의 지속, "에이전트는 지시를 따른다(문제는 지시의 질)"는 행동 관찰도 소스 간 이견 없음.

### 논쟁점 / 의견 분화

- **컨텍스트 파일 무용론 vs 최소주의**: ETH 결과를 근거로 "아예 빼라"는 강경 해석과 "인간이 최소로 쓰면 +4%"라는 온건 해석이 공존. **판정: 온건 해석이 우세** — 논문 자체가 인간 작성 파일의 양의 효과를 측정했고(+4%p, AGENTbench), InfoQ가 인용한 개발자 증언("작성 행위 자체가 암묵지를 문서화시켜 인간 팀원에게도 이득")이라는 부수 가치도 있음. 단 codebase-docs는 *LLM이 생성하는* 스킬이므로, ETH가 가장 해롭다고 본 범주(-2~-3%p)에 해당 — 인간 검토·삭제 단계를 강제하는 워크플로가 필수.
- **CLAUDE.md vs AGENTS.md**: "Anthropic이 선발 주자였으니 정당" vs "표준 미채택은 비판받아야"(HN). **판정: 실용적 하이브리드(AGENTS.md 정본 + CLAUDE.md 참조 레이어)가 가장 잘 뒷받침됨** — 양쪽 진영 모두 이 우회책 자체에는 동의하며 실험으로 동작이 검증됨.
- **영어 만능론**: NAACL 데이터는 과제 유형·모델별로 갈림. 복잡 지시(=CLAUDE.md 용도)에선 영어 우세가 더 잘 뒷받침되나, 보편 법칙은 아님.

### 정량 데이터

| 지표 | 값 | 출처 |
|---|---|---|
| LLM 생성 컨텍스트 파일의 성공률 변화 (AGENTbench) | **-2%p** | ETH Zurich |
| 동일, SWE-bench Lite | -0.5%p | ETH Zurich |
| 인간 작성 컨텍스트 파일 (AGENTbench) | **+4%p** | ETH Zurich |
| 컨텍스트 파일로 인한 추론 비용 증가 | **+19~23%** (유형 무관) | ETH Zurich |
| 파일에 `uv` 언급 시 사용 빈도 | 1.6배/인스턴스 | ETH Zurich |
| 컨텍스트 파일 보유 공개 저장소 | 60,000+ | EngineersCodex |
| Lost-in-the-middle 중간 위치 정확도 하락 (2023 원논문) | 20%p+ | Liu et al. (TACL) |
| 2026 재현 (Claude Sonnet 4.5, 200청크) | 가장자리 ~90%+ vs 중간 뚜렷한 하락 | dev.to 재현 실험 |
| NAACL 2025 한국어 예시 (qwen2-i) | 영어 79.0 vs 한국어 82.5 (단순 과제) | NAACL 2025 |

## 종합 판단

**입장:** codebase-docs 스킬의 격언 체계는 대체로 건재하다(7개 중 5개 유효·강화). 그러나 진짜 위험은 격언이 아니라 **스킬의 존재 양식 자체** — "LLM이 코드베이스를 탐색해 풍부한 문서를 생성한다"는 모델이 2026년 최고 품질 증거(ETH)가 성능 저하 요인으로 지목한 바로 그 패턴이다. 따라서 스킬은 "풍부하게 생성"에서 **"최소로 생성 + 비추론성 필터 + 인간 검토 강제"**로 재설계하고, 격언 6을 AGENTS.md 하이브리드로 갱신해야 한다.

**확신도:** 높음 (격언 1, 4, 5, 7 및 ETH 함의), 보통 (격언 2, 3, 6 — 각각 과제 의존성, 직접 실증 부재, 표준화 진행 중).

**근거:** 동료심사 논문 2편(ETH, NAACL) + Anthropic 공식 문서 2건 + 독립 실측 재현 + 커뮤니티 실전 증언이 동일 방향(최소주의·점진적 공개·구체성)으로 수렴. 소스 유형 간 교차 검증이 성립한다.

**반대 입장이 더 약한 이유:** "풍부한 문서가 항상 도움"이라는 기존 통념은 2025년 벤더 권고와 일화에 기반한 반면, 반대 증거는 통제 실험(다중 에이전트·다중 벤치마크)이다. "컨텍스트 파일 전면 무용론"도 인간 작성 +4%p와 비추론 정보(특수 툴링)의 명확한 효과를 설명하지 못해 기각.

**이 결론을 뒤집을 조건:** ① ETH 결과가 후속 연구에서 재현 실패하거나 벤치마크 특이성(니치 repo 편향)으로 판명될 경우, ② 차세대 모델이 lost-in-the-middle을 구조적으로 해소(position-agnostic 학습의 본선 채택)할 경우, ③ Claude Code가 AGENTS.md를 네이티브 지원하며 CLAUDE.md를 공식 deprecate할 경우(격언 6 재갱신 필요).

## 소스 상세

### 기사 및 문서

| 소스 | 유형 | 핵심 기여 |
|---|---|---|
| [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) | 공식 문서 | 구체 명령 중심 CLAUDE.md 예시, 컨텍스트 관리(/clear, 서브에이전트) |
| [ETH Zurich — Evaluating AGENTS.md (OpenReview)](https://openreview.net/forum?id=0DyJeJ3iia) | 동료심사 | 컨텍스트 파일의 실증 평가: 성공률 감소·비용 +20%, 최소 요구사항만 권고 |
| [InfoQ — Research Reassesses AGENTS.md Value](https://www.infoq.com/news/2026/03/agents-context-file-value-review/) | 기술 보도 | ETH 결과 해설 + 개발자 반응(문서화의 인간 측 가치) |
| [EngineersCodex — Your AGENTS.md Might Be Making AI Worse](https://www.engineerscodex.com/agents-md-making-ai-worse) | 분석 블로그 | 정량 수치 상세(-2%/+4%/1.6x), 메커니즘 해설 |
| [Upsun — Your AGENTS.md is probably too long](https://devcenter.upsun.com/posts/agents-md-less-is-more/) | 실무 블로그 | "빈 파일에서 점진 구축" 실천 가이드, 최소 템플릿 |
| [Lost-in-the-Middle Is Still Real in 2026](https://dev.to/gabrielanhaia/lost-in-the-middle-is-still-real-in-2026-even-on-1m-token-models-2ehj) | 재현 실험 | 2026 프런티어 모델에서 U자형 곡선 재현 코드·결과 |
| [NAACL 2025 — English vs Target-language Instructions](https://aclanthology.org/2025.naacl-short.55.pdf) | 동료심사 | 복잡 지시는 영어 우세, 단순 과제는 혼재 (언어×모델별 수치) |
| [Anthropic — Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | 공식 블로그 | 점진적 공개 3단계 설계 원리, SKILL.md 분할 가이드 |

### 커뮤니티 토론

| 소스 | 핵심 논점 |
|---|---|
| [HN — How I use every Claude Code feature](https://news.ycombinator.com/item?id=45786738) | CLAUDE.md vs AGENTS.md 논쟁; `@AGENTS.md` 참조가 시스템 프롬프트 주입과 동등함을 실험 확인; 상대 경로 심링크가 유일한 이식 가능 대안 |
| [r/ClaudeAI — bite vs nibble](https://www.reddit.com/r/ClaudeAI/comments/1rinsc7/why_claudemd_and_agentsmd_often_dont_help_bite_vs/) | 상시 지시("안전한 코드 써라")는 무효, 생성 후 체크리스트 리뷰(스킬/훅)가 같은 컴퓨트로 실효; CLAUDE.md는 스타트업 시퀀스 전용 |

## 미비점 및 추가 조사 필요 영역

1. **정체성 vs 부정 프레이밍의 직접 실증 부재** — 2026년까지 코딩 에이전트 컨텍스트 파일에서 긍정/부정 표현을 통제 비교한 연구를 찾지 못함. 현재 판정은 간접 추론.
2. **ETH 연구의 일반화 한계** — AGENTbench(니치 repo)와 SWE-bench Lite 결과의 격차(-2% vs -0.5%)가 시사하듯, 대규모 사내 모노레포·도메인 특화 코드베이스에서의 효과는 미검증.
3. **`.claude/rules/` 경로 스코프 frontmatter의 실효 측정 부재** — 패턴 자체는 업계 수렴했으나, path-scoped rules가 상시 로드 대비 성공률을 얼마나 개선하는지의 정량 연구 없음.
4. **Claude Code의 AGENTS.md 네이티브 지원 로드맵** — 공식 발표 미확인. 격언 6의 권고는 지원 시점에 재검토 필요.

## 전체 출처

1. [Best practices for Claude Code — 공식 문서](https://code.claude.com/docs/en/best-practices)
2. [Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents? — OpenReview (ETH Zurich)](https://openreview.net/forum?id=0DyJeJ3iia)
3. [New Research Reassesses the Value of AGENTS.md Files — InfoQ](https://www.infoq.com/news/2026/03/agents-context-file-value-review/)
4. [Your Agents.md Might Be Making AI Worse — EngineersCodex](https://www.engineerscodex.com/agents-md-making-ai-worse)
5. [The research is in: your AGENTS.md is probably too long — Upsun](https://devcenter.upsun.com/posts/agents-md-less-is-more/)
6. [Lost-in-the-Middle Is Still Real in 2026 — DEV Community](https://dev.to/gabrielanhaia/lost-in-the-middle-is-still-real-in-2026-even-on-1m-token-models-2ehj)
7. [English vs. Target-language Instructions for Multilingual LLMs — NAACL 2025](https://aclanthology.org/2025.naacl-short.55.pdf)
8. [Equipping agents for the real world with Agent Skills — Anthropic](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
9. [Lost in the Middle: How Language Models Use Long Contexts — TACL (원논문)](https://aclanthology.org/2024.tacl-1.9/)
10. [Lost in the Middle: An Emergent Property from Information Retrieval Demands — OpenReview](https://openreview.net/forum?id=XSHP62BCXN)
11. [How Well AI Models Actually Use 1M Tokens in 2026 — CodingFleet](https://codingfleet.com/blog/context-window-lie-how-well-ai-models-use-1m-tokens-2026/)
12. [Agent Skills: Progressive Disclosure as a System Design Pattern — SwirlAI](https://www.newsletter.swirlai.com/p/agent-skills-progressive-disclosure)
13. [AI Basics: Progressive Disclosure & Cursor Rules — Remote Frog](https://remotefrog.com/2026/02/03/ai-basics-progressive-disclosure-cursor-rules/)
14. [Migrate Cursor and Claude rules to AGENTS.md — sentry-cli issue #2739](https://github.com/getsentry/sentry-cli/issues/2739)
15. [HN: How I use every Claude Code feature](https://news.ycombinator.com/item?id=45786738)
16. [r/ClaudeAI: Why claude.md and agents.md often don't help (bite vs nibble)](https://www.reddit.com/r/ClaudeAI/comments/1rinsc7/why_claudemd_and_agentsmd_often_dont_help_bite_vs/)
17. [AGENTS.md vs CLAUDE.md: The Definitive Guide — Blink](https://blink.new/blog/agents-md-vs-claude-md)
18. [Do AGENTS.md/CLAUDE.md files help coding? — ToDataBeyond](https://todatabeyond.substack.com/p/do-agentsmdclaudemd-files-help-coding)
19. [How to build AGENTS.md — Augment Code](https://www.augmentcode.com/guides/how-to-build-agents-md)
20. [Beyond English: Prompt Translation Strategies in Multilingual LLMs — arXiv](https://arxiv.org/html/2502.09331v1)
