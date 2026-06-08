# Brief Template

Use this structure for quick overviews (`--brief` mode). Fill all sections in **Korean**.

```markdown
# {topic} — 브리프

> {date} | {n}개 소스 참조

## 요약
{synthesized_summary_from_initial_discovery}

## 핵심 포인트
- {point_1}
- {point_2}
- {point_3}
- ...

## 잠정 판단
{one_line_provisional_stance}
<!-- brief는 표면 탐색(추출·반증 없음)이므로 확정 입장이 아닌 '현재까지 증거 기준 잠정 입장'.
     비교/추천형 질문이면 어느 쪽으로 기우는지 + 확정에 필요한 추가 조사를 한 줄로.
     정보성 질문이면 핵심 takeaway 한 줄. 단순 요약 반복 금지. -->

## 주요 출처
- [{title_1}]({url_1})
- [{title_2}]({url_2})
- ...
```

## Field Guidelines

- **잠정 판단**: 한 줄. 비교/추천형이면 현재 증거가 어느 쪽으로 기우는지 + 확정에 필요한 추가 조사를 명시. 정보성 질문이면 핵심 takeaway 한 줄. brief는 표면 탐색이므로 '잠정'임을 분명히 한다(확정 입장 아님 — 깊은 입장이 필요하면 full 모드 안내).
- **요약**: 2-3 paragraphs synthesizing the Perplexity overview and Tavily search results
- **핵심 포인트**: 5-8 bullet points covering the most important findings
- **주요 출처**: Top 5-8 most relevant sources with clickable links
- Keep the entire brief under ~500 words
