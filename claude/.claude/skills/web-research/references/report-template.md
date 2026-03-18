# Report Template

Use this structure for the full research report. Fill all sections in **Korean**.

```markdown
# {topic} — 리서치 리포트

> 날짜: {date} | 키워드: {keyword}

## 한줄 요약
{one_line_summary}
<!-- 폴백 모드 사용 시 아래 한 줄 추가: "> ⚠️ 이 리포트는 폴백 모드로 생성되었습니다 (제한된 소스)." -->

## 핵심 발견사항
| # | 발견사항 | 소스 유형 | 신뢰도 |
|---|---------|----------|--------|
| 1 | ... | 기사/영상/커뮤니티 | 높음/보통/낮음 |

## 상세 분석

### 합의점
{points_where_multiple_sources_agree}

### 논쟁점 / 의견 분화
{controversial_or_divided_opinions}

### 정량 데이터
{numbers_statistics_benchmarks_if_any}

## 소스 상세

### 기사 및 문서
| 소스 | 핵심 내용 | URL |
|------|----------|-----|

<!-- 영상 섹션: 영상을 분석한 경우에만 포함. 영상 미발견 시 섹션 전체 생략. -->
### 영상
| 소스 | 제목 | 핵심 내용 | URL |
|------|------|----------|-----|

<!-- 커뮤니티 토론 섹션: 커뮤니티 토론을 분석한 경우에만 포함. 미발견 시 섹션 전체 생략. -->
### 커뮤니티 토론
| 플랫폼 | 주요 주장 | 여론 비율 | URL |
|--------|----------|----------|-----|

## 미비점 및 추가 조사 필요 영역
{knowledge_gaps_only}
<!-- 이 섹션에는 실제 주제에 대한 지식 공백만 기재한다.
     예시 (O): "AI 영화의 박스오피스 실적 데이터를 찾을 수 없었다"
     예시 (X): "네이버 블로그 원문을 추출하지 못했다" — 이건 파이프라인 기술 한계이지 지식 공백이 아니다.
     추출 실패한 URL이 있으면 이 섹션 하단에 각주로 간략히 언급할 수 있으나, 주요 항목으로 나열하지 않는다. -->

## 전체 출처
{all_sources_as_numbered_markdown_links}
```

## Field Guidelines

- **신뢰도 (Confidence)**: High = 3+ sources agree, Medium = 1-2 sources, Low = single unverified claim
- **소스 유형 (Source Type)**: 기사 (Article), 영상 (Video), 커뮤니티 (Community), 공식문서 (Official Docs)
- **정량 데이터**: Only include if actual numbers/statistics were found. Write "발견된 정량 데이터 없음" if none.
- **영상 테이블**: Only include if video results were found. Omit the section entirely if no videos were found.
- **커뮤니티 테이블**: Only include if community discussions were analyzed. Omit if none found.
- **전체 출처**: Number each source and provide clickable markdown links. Group by type.
- **미비점**: Only list genuine knowledge gaps — topic areas where no source provided information. Do NOT list pipeline limitations (URLs not extracted, bot-blocked sites) as research gaps. Skipped URLs are covered by the Perplexity overview. If extraction failures exist, mention them as a brief footnote, not a numbered gap item.
