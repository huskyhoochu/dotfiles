# Report Template

Use this structure for the full research report. Fill all sections in **Korean**. Write in dense, evidence-anchored prose — tables are reserved for the video/community sections only.

## Citation system

Number every source: `[1]`, `[2]`, … Every non-obvious claim in the report carries its citation numbers inline (`…약 30% 축소됐다 [4][17].`). The 출처 section maps each number to a clickable markdown link. A claim you cannot anchor to a numbered source either gets cut or is explicitly marked — see honesty markers below.

## Honesty markers (inline, mandatory)

When evidence for a specific claim is thin, say so in place, not just in a confidence column:
- A claim mentioned by sources but not substantiated in the extracted content: append `— 근거 부족` and treat it as unverified.
- A claim resting on your background knowledge rather than collected sources: mark `(출처 목록 외 일반 지식에 의존)`.

These markers are what let a reader trust the unmarked claims.

```markdown
# {topic} — 리서치 리포트

> 날짜: {date} | 키워드: {keyword}

## 한 줄 결론
<!-- 입장을 명시한 고밀도 단락 1개 (3-6문장). 핵심 정량 근거와 각주 포함.
     "무엇이 사실이고, 어디까지가 한계인가"를 한 호흡에. 폴백 모드 사용 시
     "> ⚠️ 이 리포트는 폴백 모드로 생성되었습니다 (제한된 소스)." 한 줄 추가. -->

## 개요
<!-- 주제의 배경 서사 2-4단락: 이 질문이 왜 제기되는가, 핵심 메커니즘/역사/맥락,
     현재 논의 지형. 뒤의 분석을 이해하는 데 필요한 최소 배경을 깐다. 각주 필수. -->

## 핵심 발견
<!-- 불릿 5-8개. 각 불릿은 "주장 문장: 뒷받침 정량 근거·구체 사실 [n]" 형태의
     완결된 1-3문장. 표 금지. 숫자가 있으면 반드시 숫자를 쓴다. -->

## 상세 분석

### {증거에서 도출한 소제목 1}
### {증거에서 도출한 소제목 2}
### {증거에서 도출한 소제목 3...}
<!-- 소제목 3-5개는 synthesizer가 Step 1.7에서 설계한 동적 목차를 그대로 쓴다.
     고정 목차(합의점/논쟁점/정량 데이터) 금지 — 주제가 목차를 결정한다.
     각 소제목당 2-4단락의 밀도 있는 산문. 소스 간 교차 검증과 합의/이견은
     해당 쟁점을 다루는 소제목 안에서 소화한다. -->

## 쟁점과 관점 비교
<!-- 출처 간 상충하는 관점을 2개 이상 세우고, 각각의 근거를 제시한 뒤
     **어느 쪽이 왜 더 강한지 반드시 판정**한다. "의견이 갈린다"에서 멈추면 실패.
     상충이 정말 없으면 "출처 간 직접 충돌은 없으나 …" 형태로 접근법의 긴장을 다룬다. -->

## 종합 판단
<!-- 필수 섹션. 생략 불가. 위 상세 분석/쟁점 비교는 이 판단의 근거다. -->
**입장:** {모든 증거를 종합해 분석가가 실제로 취하는 한 문장 입장}
**확신도:** 높음 / 보통 / 낮음 — {이유: 증거 깊이, 소스 합의, 소스 품질}
**근거:** {선택한 입장이 대안보다 잘 뒷받침되는 이유 — 받치는 소스 인용}
**반대 입장이 더 약한 이유:** {경쟁 견해가 왜 "다른" 게 아니라 "약한"지}

## 한계와 반대 근거
<!-- 이 결론이 틀릴 수 있는 조건을 "첫째, 둘째, 셋째…"로 열거한다. 각 항목은
     구체적 반대 근거(disconfirming search 결과 포함)나 전제 조건에 기반해야 한다.
     주제 자체의 지식 공백(어떤 소스도 답하지 못한 영역)도 여기에 포함한다.
     추출 실패 URL은 파이프라인 기술 한계이므로 각주로만 간략히 — 항목으로 세우지 않는다. -->

<!-- 영상 섹션: 영상을 분석한 경우에만 포함. 영상 미발견 시 섹션 전체 생략. -->
## 영상
| 소스 | 제목 | 핵심 내용 | URL |
|------|------|----------|-----|

<!-- 커뮤니티 토론 섹션: 커뮤니티 토론을 분석한 경우에만 포함. 미발견 시 생략. -->
## 커뮤니티 토론
| 플랫폼 | 주요 주장 | 여론 비율 | URL |
|--------|----------|----------|-----|

## 출처
<!-- 번호 목록. 본문 각주 [n]과 1:1 대응. 반드시 클릭 가능한 마크다운 링크. -->
1. [제목](url) — 소스 유형 (기사/공식문서/영상/커뮤니티)
2. …
```

## Field Guidelines

- **한 줄 결론 vs 종합 판단**: 한 줄 결론은 리포트 맨 앞의 요약된 입장(바쁜 독자용), 종합 판단은 그 입장의 완전한 방어(stance 객체 렌더링). 서로 모순되면 안 된다. "이 결론이 뒤집힐 조건"은 한계와 반대 근거 섹션이 담당한다.
- **동적 목차**: 소제목은 수집된 증거가 실제로 다루는 쟁점 축에서 나와야 한다. 패턴 예시(강제 아님): 메커니즘/원리, 최신 검증·데이터, 실무 함의·구현 가이드, 성공과 한계, 이해관계자별 관점. 주제가 실용적이면 "단계별 가이드"류, 논쟁적이면 쟁점 축별 소제목이 자연스럽다.
- **확신도 (Confidence)**: High = 3+ sources agree, Medium = 1-2 sources, Low = single unverified claim. **출처 수만이 아니라 품질로 보정**: 동일 출처·저품질군(예: 위키·익명 커뮤니티 위주)이면 한 단계 하향, 단일 1차/공식 소스는 Low 위로 상향, 소스 충돌·희소 시 하향 (`source-classification.md`의 품질 위계 참조). 저품질 소스 의존이 심한 주제(루머·유출 등)는 그 사실 자체를 개요와 한계 섹션에 명시한다.
- **정량 데이터**: 별도 섹션이 아니라 핵심 발견과 상세 분석의 문장 안에 녹인다. 숫자가 존재하는데 쓰지 않는 것은 실패다.
- **영상/커뮤니티 테이블**: 해당 소스를 분석한 경우에만 포함. Gemini 영상 분석(`{video_analysis}`)이 있으면 핵심 내용 열에 본문 근거(발언·시연)를 담는다.
