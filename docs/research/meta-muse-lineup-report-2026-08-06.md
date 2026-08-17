# Meta Muse 신규 모델 라인업(2026.7~8) — 리서치 리포트

> 날짜: 2026-08-06 | 키워드: Meta Muse 모델 라인업

## 한 줄 결론

Meta의 Muse 라인업(Muse Image·Muse Video·Muse Spark 1.1·Muse Spark 1.2·Muse Code)에서 개발자가 실제로 API로 쓸 수 있는 것은 Muse Spark 1.1/1.2 두 모델뿐이며, 이 둘은 "프런티어급 코딩 1위"가 아니라 **도구 사용·에이전트 워크플로 특화 + 공격적 가격($1.25/$4.25 per 1M 토큰)의 준프런티어 모델**로 평가하는 것이 가장 방어 가능한 입장이다 [1][4][6][14]. Meta의 자체 벤치마크 주장(Muse Spark 1.2의 Terminal-Bench 2.1 82.9%)은 검증 이력상 3~4점 할인해서 봐야 한다 — 직전 모델 1.1의 자체 주장 80.0%는 독립 검증에서 76.2%로 3.8점 낮게 나왔다 [8]. 접근 경로는 명확히 갈린다. OpenRouter에는 Muse Spark 1.1과 1.2가 모두 올라와 있고 [6][15], ZenMux에는 8월 6일 기준 **Muse Spark 1.1만** 있으며 1.2는 아직 없다 [7]. Muse Image는 7월 7일 출시 후 약 12일 만에 반발로 철회되었고, Muse Video는 프리뷰 상태, Muse Code는 API 모델이 아닌 터미널 코딩 에이전트(베타)다 [3][5][12].

## 개요

Meta Superintelligence Labs(MSL, 알렉산더 왕 주도)는 2026년 7~8월 두 달 사이에 Muse 브랜드로 5개 발표를 쏟아냈다. 7월 7일 미디어 생성 모델 Muse Image(정식)와 Muse Video(프리뷰)를 공개했고 [3], 7월 9일에는 에이전트·코딩·멀티모달을 겨냥한 Muse Spark 1.1을 Meta Model API 공개 프리뷰와 함께 내놓았다 [1]. 8월 5일에는 코딩 특화 업데이트인 Muse Spark 1.2와, 이를 구동 모델로 쓰는 터미널 코딩 에이전트 Muse Code(베타)를 발표하며 Anthropic의 Claude Code, OpenAI의 Codex와 정면 경쟁을 선언했다 [4][5].

이 라인업은 단순한 신모델 출시가 아니라 전략 전환이다. Meta는 Llama 오픈 웨이트 노선에서 벗어나 독점(proprietary) 모델 API 판매로 축을 옮겼으며, 이는 Llama 4의 벤치마크 조작 논란과 AI 조직 개편 이후의 재출발이라는 맥락 위에 있다 [13][18]. 왕은 오픈소스 변형 모델을 개발 중이라고 밝혔지만 시점과 세부는 미정이다 [13][19].

두 달간의 전개는 성공과 실패가 뒤섞였다. Muse Spark 1.1은 OpenRouter에서 44.3B 토큰을 처리하며 빠르게 채택된 반면 [6], Muse Image는 공개 Instagram 계정을 기본 옵트인으로 AI 이미지 생성에 활용하도록 한 설계가 딥페이크·초상권 반발을 불러 7월 19일 보도 시점에 기능이 전면 철회되었다 [12].

## 핵심 발견

- **개발자용 API 모델은 Spark 계열 둘뿐이다**: Muse Image·Video·Code는 소비자 제품 또는 에이전트 하네스이며, OpenRouter와 ZenMux 어디에도 API 모델로 등재되어 있지 않다 [6][7].
- **가격은 동일하고 공격적이다**: Spark 1.1과 1.2 모두 입력 $1.25/출력 $4.25 per 1M 토큰, 캐시 입력 $0.15, 신규 계정 $20 무료 크레딧. 유사 추론 모델 중간값(입력 $1.75/출력 $10) 대비 뚜렷하게 싸다 [4][14][16].
- **1.2에는 데이터 제공 조건의 초저가 티어가 있다**: Contributor 티어는 $0.10/$0.20 per 1M로 표준 티어의 1/10 이하이지만 프롬프트·출력이 Meta 학습에 사용되고, 속도 제한도 3,000 rpm 대비 60 rpm으로 좁다 [4][8].
- **자체 벤치마크는 검증치보다 부풀려진 전력이 있다**: Spark 1.1의 Terminal-Bench 2.1 자체 주장 80.0% 대비 독립 검증치는 76.2%±1.2%로 3.8점 낮았고, 1.2의 82.9%는 8월 6일 현재 미검증이다 [8].
- **Meta 자체 차트에서도 코딩 1위가 아니다**: Terminal-Bench 2.1에서 Muse Spark 1.2+Muse Code 82.9% vs Claude Opus 5+Claude Code 86.7%, DeepSWE 1.1에서 59.3% vs 65.0%, 자체 내부 코딩 벤치마크에서도 70.6% vs 79.4%로 전 종목 열세다 [17][8].
- **강점은 에이전트·도구 사용이다**: Spark 1.1은 MCP Atlas 88.1, JobBench 54.7(Opus 4.8 48.4, GPT-5.5 38.3 대비 우위), 도구 활용 HLE 62.1로 프런티어를 앞서는 지점이 있다 [1][2][11].
- **OpenRouter는 2개 모델 모두 지원, ZenMux는 1.1만**: OpenRouter의 Meta 페이지는 Spark 1.1(44.3B 토큰 처리)과 1.2(8/5 등재, 2.33B 토큰)를 1.05M 컨텍스트로 제공하며 [6], ZenMux는 meta/muse-spark-1.1(144.92M 토큰, 캐시 적중률 97.45%, 최대 출력 128K)만 보인다 [7].
- **접근 지역 제한이 풀렸다**: Spark 1.1은 출시 당시 미국 개발자 한정이었으나, 1.2 출시와 함께 두 Spark 모델 모두 글로벌 접근으로 확대되었다 [8][15][16].

## 상세 분석

### 라인업의 실체 — 5개 발표, 개발자용 모델은 2개

Muse 브랜드는 다섯 이름을 달고 있지만 성격이 제각각이다. Muse Image는 Meta AI 앱·meta.ai·Instagram Stories(미국)·WhatsApp(일부 국가)에 통합된 소비자용 이미지 생성 모델로, 일상 사용은 무료이고 API 제공은 없다 [3]. Muse Video는 같은 사전학습 기반의 영상 모델로 "coming soon" 프리뷰 상태다 [3]. Muse Code는 모델이 아니라 Muse Spark 1.2로 구동되는 터미널 코딩 에이전트(베타)로, 큰 작업을 격리된 워크트리의 병렬 서브에이전트로 분산하는 구조를 내세운다 — 저커버그는 "게임 기능 6개를 동시에 충돌 없이 구축했다"고 주장했다 [5].

개발자가 토큰 단위로 호출할 수 있는 것은 Muse Spark 1.1(7/9)과 1.2(8/5)다. 둘 다 1.05M 토큰 컨텍스트에 텍스트·이미지·비디오·오디오·PDF 입력, 텍스트 출력, 구조화 출력·병렬 함수 호출·추론 강도 조절을 지원한다 [6]. 1.2는 "코딩 태스크에 학습 컴퓨트를 대폭 증액한" 코딩 특화 포인트 릴리스로, Meta 자체 하네스 기준 1.1 대비 Terminal-Bench +6.7점, DeepSWE +6.3점 개선을 보고했다 [4][9]. 1.1 출시 한 달 만의 이례적으로 빠른 후속은, 1.1이 Kimi K3에 묻힌 데 대한 "재출시" 성격이라는 해석도 있다 — 근거는 정황뿐이다 [8].

### 성능 — 에이전트에서 이기고 코딩에서 진다

증거는 일관된 패턴을 보인다. 에이전트·도구 사용 벤치마크에서 Spark 계열은 프런티어를 앞선다. MCP Atlas 88.1, JobBench 54.7, 도구 활용 HLE 62.1이 대표적이고 [1][2][11], 1.2는 전용 도구 사용 벤치마크에서 90.3%로 1위를 기록했다 [17]. Artificial Analysis 인텔리전스 인덱스에서도 1.2(xhigh)는 54점으로 중간값 32를 크게 웃돌며 출력 속도 165 tok/s로 상위권이다 — 다만 xhigh의 첫 토큰 지연이 약 26초로, 지연을 추론 깊이와 맞바꾼 설계다 [14].

반면 코딩에서는 Meta가 직접 공개한 차트에서조차 전 종목 2위 이하다. Terminal-Bench 2.1 82.9% vs Opus 5 86.7%, DeepSWE 1.1 59.3% vs 65.0%, GDPVal-AA V2 1,631 vs 1,852 [17]. 1.1 시절에는 격차가 더 커서 SWE-Bench Pro에서 Opus 4.8보다 7점 낮은 61.5, DeepSWE 1.1은 53.3으로 뚜렷한 3위였다 [2][8]. Replit·Cline·Box 등 초기 파트너의 호평은 있으나 [1], 이는 마케팅 인용이므로 독립 근거로 치지 않는다.

### 가격과 접근 경로 — OpenRouter 둘 다, ZenMux는 1.1만

표준 가격은 두 모델 동일하게 $1.25/$4.25(캐시 입력 $0.15, 웹 검색 $2.50/1천 회)이며, OpenRouter는 여기에 5.5% 수수료(최소 $0.80)를 더한다 [4][16]. 장문 컨텍스트 프리미엄이 없고 팀당 3,000 요청·4M 토큰/분의 넉넉한 한도가 붙는다 [4]. 1.2에만 있는 Contributor 티어($0.10/$0.20)는 저렴한 대신 데이터가 학습에 쓰이고 60 rpm으로 제한된다. kingy.ai의 정리가 정확하다. "싼 티어는 당신을 학습하는 티어고, 학습하지 않는 티어는 지난달과 같은 가격이다" [8].

접근 경로는 이번 리서치의 핵심 질문이므로 추출된 실제 페이지 기준으로 정밀하게 적는다. **OpenRouter**의 Meta 페이지는 정확히 2개 모델 — Muse Spark 1.2(8/5 등재, 2.33B 토큰 처리)와 Muse Spark 1.1(44.3B 토큰 처리) — 을 나열하며, Muse Image·Video·Code는 없다 [6]. OpenRouter 공식 발표는 1.2 등재와 함께 "두 Spark 모델의 글로벌 접근 확대"를 명시했다 [15]. **ZenMux**의 모델 목록(8/4~8/6 스냅숏)에는 `meta/muse-spark-1.1`이 $1.25/$4.25, 1.05M 컨텍스트, 최대 출력 128K, 단일 프로바이더, 144.92M 토큰 처리·캐시 적중률 97.45%로 등재되어 있으나, **muse-spark-1.2는 목록·검색 어디에도 나타나지 않는다** [7]. 1.2가 8월 5일 출시된 점을 감안하면 "아직 미등재"일 가능성이 크며, 영구적 미지원으로 단정할 근거는 없다.

### 신뢰성 — Llama 4의 그림자와 3.8점의 갭

Meta의 벤치마크 수치는 두 겹의 할인 요인을 안고 있다. 첫째, 전력이다. Llama 4(2025.4)는 공개되지 않은 특수 서브모델로 벤치마크 결과를 조작했다는 비판을 받았고, 이것이 조직 개편과 Muse로의 재출발 배경이다 [13][18]. 둘째, 실측 갭이다. Terminal-Bench 2.1 공식 리더보드의 독립 검증에서 Spark 1.1(mini-SWE-agent, xhigh)은 76.2%±1.2%로, Meta 주장 80.0%보다 3.8점 낮았다 [8]. 1.2의 82.9%는 Meta 자체 Daytona 샌드박스 하네스에서 각 모델을 벤더 전용 에이전트(Muse Code, Claude Code, Codex 등)에 태워 측정한 수치로, 8월 6일 현재 공식 리더보드 검증 항목이 없다 [8][17]. 같은 하네스에서 Meta가 매긴 Opus 5의 86.7%조차 공식 보드의 약 89%보다 낮게 나오는 등 하네스 간 편차가 수 점에 달하므로, 82.9%는 "잠정치"로 취급하는 것이 맞다 [8]. HN에서도 "왜 GPT-5.6-sol과는 비교하지 않고 Terra하고만 비교했나"라는 비교 대상 선별 의혹이 제기되었다 [9].

## 쟁점과 관점 비교

**쟁점 1 — "Muse Spark는 Claude/GPT급 코딩 경쟁자다" vs "가격·에이전트 특화 니치 모델이다."** 전자는 Meta의 발표와 파트너 인용, 1.1→1.2의 빠른 개선 폭(+6.7점)에 기댄다 [1][4]. 후자는 Meta 자체 차트의 전 종목 열세(82.9 vs 86.7 등), 독립 검증 갭 3.8점, AA 인덱스 54점에 기댄다 [8][14][17]. **판정: 후자가 강하다.** 결정적 근거는 Meta 스스로 공개한 차트에서조차 코딩 4개 종목 전부 Anthropic에 뒤진다는 점이다 — 자사에 가장 유리한 조건에서도 2위라면, 검증 후 실제 격차는 더 벌어질 개연성이 높다. 다만 "니치"라는 표현은 과소평가다. 도구 사용 90.3% 1위, MCP Atlas 88.1 등 에이전트 오케스트레이션에서는 실제로 프런티어를 앞서므로, 정확한 위치는 "코딩 2군, 에이전트 1군, 가격 최상위권"이다 [14][17].

**쟁점 2 — Contributor 티어를 "관대한 보조금"으로 볼 것인가 "데이터 수확 장치"로 볼 것인가.** VentureBeat는 이를 "접근을 보조하고 대규모로 데이터를 수확해 격차를 좁히는 전형적 Meta 방식"으로 규정했고 [4], kingy.ai는 독점 코드 작업자에게 명시적으로 사용 회피를 권고했다 [8]. 옹호론은 개인·실험 용도에 압도적 가격을 든다. **판정: 비판론이 강하다.** 60 rpm 제한이 프로덕션 사용을 구조적으로 차단하므로 이 티어의 실질 기능은 저비용 제공이 아니라 학습 데이터 확보이고, 학습에 쓰지 않는 표준 티어 가격은 전혀 내려가지 않았다는 사실이 이를 뒷받침한다 [4][8].

**쟁점 3 — Muse 라인업 전체가 성공적 재출발인가.** Spark의 API 견인(OpenRouter 44.3B+2.33B 토큰, ZenMux 144.92M 토큰)은 실체가 있는 반면 [6][7], Muse Image의 12일 만의 철회는 제품 판단력에 대한 의문을 남겼고 [12], 커뮤니티 일부는 Meta의 AI 확장 자체를 방향 상실로 본다 [13]. **판정: "개발자 API 부문은 성과, 소비자 미디어 부문은 실패"로 분리 평가하는 것이 정확하다.** 하나의 성패로 묶는 양쪽 서사 모두 증거를 취사선택하고 있다.

## 종합 판단

**입장:** Muse 라인업의 개발자용 실체는 Muse Spark 1.1/1.2이며, 이들은 "코딩 프런티어 동급"이 아니라 **에이전트·도구 사용에 강하고 가격이 매우 공격적인 준프런티어 모델**이다. Meta의 자체 벤치마크는 3~4점 할인해 읽어야 한다. 경로 선택은 명확하다. Spark 1.2가 필요하면 OpenRouter 또는 Meta Model API, ZenMux 사용자는 현재 1.1만 쓸 수 있다.

**확신도:** 높음(라인업 구성·가격·OpenRouter 지원 — 공식 1차 소스 3개와 플랫폼 페이지가 일치) / 보통(ZenMux 1.2 미지원 — 8/6 시점 스냅숏 근거의 부재 증명이며, 등재는 수일 내 바뀔 수 있음) / 보통(벤치마크 할인 폭 — 검증 사례가 1.1 한 건).

**근거:** Meta 공식 블로그·개발자 페이지 [1][2][3], OpenRouter·ZenMux 실페이지 추출 [6][7], 독립 검증 리더보드 [8], Artificial Analysis [14], 그리고 Meta 자체 공개 차트의 열세 [17]가 상호 모순 없이 같은 그림을 그린다.

**반대 입장이 더 약한 이유:** "프런티어 동급" 주장의 근거는 전부 Meta 자체 측정 또는 파트너 인용인데, Meta는 자사 하네스 수치가 독립 검증보다 높게 나온 직전 사례와 Llama 4 조작 전력이 있다 [8][13]. 반대편 극단인 "과대포장 실패작" 주장도 약하다 — OpenRouter 46.6B 토큰 처리량과 AA 인덱스 54점은 실사용 수요와 실제 역량을 입증한다 [6][14].

## 한계와 반대 근거

첫째, ZenMux 판단은 8월 4~6일 스냅숏과 검색 결과의 **부재**에 근거한다. 1.2 출시가 8월 5일이므로, 이 리포트 직후 ZenMux에 1.2가 등재되면 접근 경로 결론의 절반이 뒤집힌다. 둘째, Muse Spark 1.2의 82.9%가 향후 공식 Terminal-Bench 검증에서 그대로 확인되면 "3~4점 할인" 판단은 과도한 보수주의가 된다 — 현재 검증 갭의 표본은 1.1 한 건뿐이다. 셋째, Muse Code는 베타 상태라 실전 리포지토리 성능에 대한 독립 사용기가 아직 축적되지 않았고, 병렬 서브에이전트 시연은 Meta 데모에 의존한다 [4][5]. 넷째, Muse Image "철회"는 7월 19일 보도 기준이며 이후 재출시 여부는 이번 소스 범위에서 확인되지 않았다 — 근거 부족. 다섯째, Muse Video의 성능(Arena 3위 주장 등)은 발견 단계 요약에만 있고 심층 추출로 교차검증되지 않았다.

## 영상

| 소스 | 제목 | 핵심 내용 | URL |
|---|---|---|---|
| YouTube | Meta's Biggest AI Launch Yet — Muse Spark 1.1 Explained | 메인 에이전트가 계획·위임하고 서브에이전트가 병렬 실행하는 에이전트 아키텍처 해설. 스마트폰 영상만으로 Facebook Marketplace 판매 목록(자전거 프레임 $1,300, 포크 $550)을 자동 작성·게시하는 시연, 박스 라벨의 부품번호까지 판독 | [11] |
| YouTube (ABC News) | Meta rolls back 'Muse Image' A.I. tool after backlash | 공개 Instagram 계정을 기본 옵트인으로 타인 외모 기반 이미지 생성에 허용한 설계가 딥페이크 우려와 탤런트 에이전시 압력을 불러, 옵트인 수정이 아닌 기능 전면 철회를 선택. "이 기능은 목표를 벗어났다"는 공식 성명 인용 | [12] |
| YouTube | Meta Releases AI Coding Model — Zuckerberg is Lost | 왕의 "매우 공격적이고 매력적인 가격" 발언과 $20 크레딧·$1.25/$4.25 구조 전달. 발화자는 AI 가격 경쟁을 "바닥을 향한 경쟁"으로 규정하고 Meta의 확장을 방향 상실로 비판. Spark 오픈소스 변형 개발 중이라는 왕의 발언도 전달 | [13] |

## 커뮤니티 토론

| 플랫폼 | 주요 주장 | 여론 비율 | URL |
|---|---|---|---|
| Hacker News | Muse Code·Spark 1.2 발표 스레드(8점, 댓글 2개로 냉담). "왜 GPT-5.6-sol과 비교하지 않고 Terra만 비교했나"라는 벤치마크 비교 대상 선별 의혹 | 표본이 작아 비율 판단 불가, 톤은 회의적 | [9] |
| Reddit r/artificial | Muse Image 출력 블라인드 비교 스레드. 모델 간 스타일 수렴("전부 같은 기본 모자") 지적 | 부분 추출로 비율 판단 불가 | [10] |
| Reddit r/LocalLLaMA | Spark 오픈소스 변형 개발 소식(195점, 댓글 47개). 최상위 댓글은 "3개월 전에도 같은 힌트만 줬다 — 그냥 1.1 웨이트를 공개하라"는 냉소 | 기대보다 불신 우세 | [19] |

## 출처

1. [Introducing Muse Spark 1.1 — ai.meta.com](https://ai.meta.com/blog/introducing-muse-spark-meta-model-api/) — 공식 1차
2. [Muse Spark 1.2 — developer.meta.com](https://developer.meta.com/ai/models/muse-spark/) — 공식 1차
3. [Introducing Muse Image and Muse Video — ai.meta.com](https://ai.meta.com/blog/introducing-muse-image-muse-video-msl/) — 공식 1차
4. [Meta enters the AI coding wars — VentureBeat](https://venturebeat.com/orchestration/meta-enters-the-ai-coding-wars-with-muse-spark-1-2-and-muse-code-with-persistent-async-background-agents) — 언론
5. [Meta launches Muse Code — TechCrunch](https://techcrunch.com/2026/08/05/meta-launches-muse-code-an-ai-agent-for-large-code-bases/) — 언론
6. [Meta models on OpenRouter](https://openrouter.ai/meta) — 플랫폼 1차
7. [Models | ZenMux](https://zenmux.ai/models) — 플랫폼 1차
8. [Muse Code Benchmarks: Meta's 82.9% vs Verified Scores — kingy.ai](https://kingy.ai/blog/muse-code-muse-spark-1-2-benchmarks-verified/) — 독립 분석
9. [HN: Muse Code and Muse Spark 1.2](https://news.ycombinator.com/item?id=49187575) — 커뮤니티
10. [Reddit r/artificial: Muse Image 비교](https://www.reddit.com/r/artificial/comments/1ur6h98/guess_which_row_is_metas_new_muse_image_model/) — 커뮤니티
11. [Muse Spark 1.1 Explained — YouTube](https://www.youtube.com/watch?v=yQpFUVqYKFA) — 영상(Gemini 분석)
12. [Meta rolls back Muse Image — ABC News/YouTube](https://www.youtube.com/watch?v=T4LCejQzIIg) — 영상(Gemini 분석)
13. [Meta Releases AI Coding Model — YouTube](https://www.youtube.com/watch?v=EyU3qOolddc) — 영상(Gemini 분석)
14. [Muse Spark 1.2 (xhigh) — Artificial Analysis](https://artificialanalysis.ai/models/muse-spark-1-2) — 독립 벤치마크
15. [OpenRouter 공식 X: Muse Spark 1.2 등재·글로벌 확대](https://x.com/OpenRouter/status/2085093509519090030) — 플랫폼 공식
16. [Muse Spark 1.1 on OpenRouter — KuCoin News](https://www.kucoin.com/news/flash/meta-s-muse-spark-1-1-available-on-openrouter-limited-to-u-s-developers) — 언론
17. [Muse Spark 1.2 & Muse Code Methodology — research.meta.ai](https://research.meta.ai/static/muse-spark-1-2-methodology) — 공식 1차(측정 방법론)
18. [With Muse Spark, Meta pivots away from open-weights Llama — The Batch](https://www.deeplearning.ai/the-batch/with-muse-spark-meta-pivots-away-from-its-open-weights-llama-strategy) — 언론/분석
19. [Reddit r/LocalLLaMA: 오픈소스 변형 개발 중](https://www.reddit.com/r/LocalLLaMA/comments/1usbfz3/meta_are_apparently_working_on_an_open_source/) — 커뮤니티
