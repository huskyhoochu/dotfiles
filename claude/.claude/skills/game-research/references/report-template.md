# Report Template (Game Research)

Use this structure for the full research report. Fill all sections in **Korean**. Adapt sections based on `{query_type}` — omit sections that don't apply.

```markdown
# {topic} — 게임 리서치 리포트

> 날짜: {date} | 키워드: {keyword}

## 한줄 요약
{one_line_summary}
<!-- 폴백 모드 사용 시 아래 한 줄 추가: "> ⚠️ 이 리포트는 폴백 모드로 생성되었습니다 (제한된 소스)." -->

## 핵심 발견사항
| # | 발견사항 | 소스 유형 | 신뢰도 |
|---|---------|----------|--------|
| 1 | ... | 리뷰/기사/영상/커뮤니티 | 높음/보통/낮음 |

<!-- 평가 섹션: query_type이 title 또는 hardware일 때 포함. genre/industry/esports는 생략. -->
## 평가 종합

### 평론가 점수
| 매체 | 점수 | 한줄평 |
|------|------|--------|
| Metacritic | 85/100 | ... |
| OpenCritic | Strong | ... |

### 유저 반응
| 플랫폼 | 점수/평가 | 주요 의견 |
|--------|----------|----------|
| Steam | 매우 긍정적 (92%) | ... |
| 루리웹 | ... | ... |

## 상세 분석

### 합의점
{points_where_multiple_sources_agree}

### 논쟁점 / 의견 분화
{controversial_or_divided_opinions}

### 정량 데이터
{numbers_statistics_benchmarks_if_any}
<!-- 게임 특화: 판매량, 동시접속자, FPS 벤치마크, 가격, 플레이타임 등 -->

## 소스 상세

### 리뷰 및 기사
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
     예시 (O): "이 게임의 한국 서버 지연시간 데이터를 찾을 수 없었다"
     예시 (X): "IGN 리뷰 원문을 추출하지 못했다" — 이건 파이프라인 기술 한계이지 지식 공백이 아니다. -->

## 전체 출처
{all_sources_as_numbered_markdown_links}
```

## Field Guidelines

- **신뢰도 (Confidence)**: High = 3+ sources agree, Medium = 1-2 sources, Low = single unverified claim
- **소스 유형 (Source Type)**: 리뷰 (Review), 기사 (Article), 영상 (Video), 커뮤니티 (Community), 공식 (Official)
- **평가 종합**: Only include when reviewing a specific game or hardware. Omit for genre/industry/esports queries.
- **정량 데이터**: Game-specific numbers — sales figures, concurrent players, FPS benchmarks, pricing, completion times. Write "발견된 정량 데이터 없음" if none.
- **영상 테이블**: Only include if video results were found. Omit the section entirely if no videos.
- **커뮤니티 테이블**: Only include if community discussions were analyzed. Omit if none found.
- **전체 출처**: Number each source and provide clickable markdown links. Group by type.
- **미비점**: Only list genuine knowledge gaps. Do NOT list pipeline limitations as research gaps.

## Query-Type Adaptations

| Query type | Sections to emphasize | Sections to de-emphasize or omit |
|------------|----------------------|----------------------------------|
| `title` | 평가 종합, 상세 분석 | — |
| `genre` | 핵심 발견사항 (as recommendations list) | 평가 종합 (omit) |
| `esports` | 정량 데이터 (standings, results) | 평가 종합 (omit) |
| `industry` | 상세 분석, 정량 데이터 (market data) | 평가 종합 (omit) |
| `hardware` | 평가 종합, 정량 데이터 (benchmarks) | — |
