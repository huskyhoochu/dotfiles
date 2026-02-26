# Design Style Taxonomy

70개 이상의 웹/UI 디자인 스타일을 6개 카테고리로 분류. AI 프롬프트에서 정확한 스타일명을 사용하면 출력 품질이 극적으로 향상됨 (NN/g 연구 근거).

## A. Morphism (표면/깊이감)

| Style | Visual Signature | CSS Essence |
|-------|-----------------|-------------|
| **Skeuomorphism** | 실제 물리적 대상의 질감·그림자·반사를 디지털로 모사 | Realistic textures, detailed shadows |
| **Flat Design** | 2차원 평면, 선명한 색상, 그림자 없음 | No shadows, no gradients, bold fills |
| **Material Design** | 미묘한 그림자, 레이어 깊이, 카드 레이아웃 | `elevation: shadow-sm/md/lg`, cards |
| **Neumorphism** | 부드러운 내부/외부 그림자, 촉각적 돌출/함몰 | `box-shadow: 6px 6px 12px #d1d1d1, -6px -6px 12px #ffffff` |
| **Glassmorphism** | 프로스트 글라스 — 반투명, 배경 블러, 밝은 테두리 | `backdrop-blur-xl bg-white/10 border border-white/20` |
| **Claymorphism** | 점토/Play-Doh 느낌의 3D 둥근 형태, 파스텔 | `border-radius: 24px`, soft multi-shadow |
| **Aurora UI** | 북극광 — 무지개빛 그라디언트, 몽환적, 반짝이는 오버레이 | Iridescent gradients, shimmer animations |

## B. Web Movements (설계 철학)

| Style | Visual Signature | CSS Essence |
|-------|-----------------|-------------|
| **Minimalism** | 여백 중심, 제한된 색상, "less is more" | Generous whitespace, 2-3 colors max |
| **Neo-Minimalism** | 미니멀 + 따뜻한 그림자, 촉각적 간격, 섬세한 질감 | Soft shadows, subtle textures, warm tones |
| **Maximalism** | 밀도 높은 구성, 강렬한 색상, 레이어링 | Dense layouts, clashing colors, overlapping |
| **Brutalism (Web)** | 원시적 HTML, 시스템 폰트, 노출된 구조 | `font-family: monospace`, raw borders |
| **Neobrutalism** | 고대비 색상 블록, 굵은 테두리, offset 그림자 | `border: 3px solid black; box-shadow: 6px 6px 0 black` |
| **Anti-Design** | 의도적 규칙 파괴, 불규칙 그리드, 예상치 못한 색상 | Broken grids, intentional misalignment |
| **Swiss / International** | 수학적 그리드, 산세리프, 객관적 정밀함 | Strict grid system, Helvetica-style fonts |
| **Editorial** | 매거진 레이아웃 — 대형 타이포, 컬럼 그리드 | Multi-column, large headlines, text-image interplay |
| **Utilitarian** | 군용/산업 계기판, 모노스페이스, 무장식 | `font-mono`, minimal decoration, function-first |

## C. Era-Based (시대/미학)

| Style | Visual Signature | CSS Essence |
|-------|-----------------|-------------|
| **Art Deco** | 1920s 기하학적 대칭, 금속 골드/실버, 럭셔리 | Gold accents, geometric patterns, symmetry |
| **Art Nouveau** | 유기적 곡선, 식물 모티프, 장식적 타이포 | Organic curves, floral, ornamental |
| **Bauhaus** | 원·삼각·사각, 원색, 기능주의 | Primary colors, geometric primitives |
| **Mid-Century Modern** | 1950-60s 따뜻한 톤, 유기적 형태, 레트로 일러스트 | Warm oranges/teals, atomic-age patterns |
| **Y2K** | 사이버 메탈릭, 크롬, 무지개빛, 픽셀 폰트 | Chrome gradients, iridescent, pixel fonts |
| **Neo Frutiger Aero** | Y2K 리바이벌 — 광택 UI, 아쿠아 블루, 버블 | Glossy surfaces, aqua blue, bubbly shapes |
| **Retro-Futurism** | 빈티지+미래 결합, 원자력 시대 그래픽 | Vintage sci-fi, atom symbols, bold type mix |
| **Victorian / Gothic** | 정교한 장식, 세리프, 어두운 색조, 금박 | Ornate borders, serif fonts, dark palette |
| **Baroque** | 극도의 장식, 극적 명암, 호화로운 질감 | Dramatic light/dark, rich textures, gold |
| **Neoclassical** | 고전 그리스-로마 — 질서, 대칭, 절제된 우아함 | Columns, symmetry, restrained elegance |
| **Japandi** | 일본 미니멀리즘 + 스칸디나비아 기능성, 자연 소재 | Neutral tones, natural materials, zen spacing |
| **Mystical Western** | 카우보이 + 오컬트, 사막 톤 + 신비 기호 | Desert tones, mystical symbols, serif |

## D. Digital-Native (디지털 네이티브 미학)

| Style | Visual Signature | CSS Essence |
|-------|-----------------|-------------|
| **Vaporwave** | 파스텔 네온, Windows 95 UI, 일본어 텍스트, 90s 향수 | Pastel pink/cyan, retro UI elements |
| **Synthwave** | 1980s — 네온 그리드, 심홍+시안, 선셋 그라디언트 | Neon pink/cyan, grid lines, chrome text |
| **Cyberpunk** | 네온 + 어둠, 홀로그램, 하이테크/로우라이프 | Dark bg, neon accents, glitch effects |
| **Pixel Art** | 8/16비트 레트로 게임, 제한된 팔레트 | Pixelated fonts, limited colors |
| **Glitch Art** | 디지털 오류 — 색상 시프트, 노이즈, 데이터모싱 | `clip-path`, RGB shift, noise overlay |
| **Cybercore** | 해커 미학, 매트릭스 코드, SF 터미널 | Green-on-black, terminal fonts, scanlines |
| **Steampunk** | 빅토리아+산업혁명 SF — 톱니바퀴, 황동 | Brass/copper tones, gear motifs |
| **Dark Mode UI** | 어두운 배경, 밝은 악센트, OLED 최적화 | Dark surfaces, light text, accent pops |
| **Futuristic Minimalism** | 하이테크 고요함, SF 인터페이스 | Clean whites, thin lines, sci-fi calm |
| **Dark Magic Academia** | 고딕 학술 + 신비주의, 판타지 | Dark tones, serif, mystical imagery |
| **Light Academia** | 부드럽고 시적, 크리미 중성색, 문학적 낭만 | Cream/beige, serif, warm lighting |

## E. Texture/Material (텍스처/재질)

| Style | Visual Signature | CSS Essence |
|-------|-----------------|-------------|
| **Liquid Design** | 유체역학 — 물결, 방울, 유기적 곡선 블롭 | `border-radius: 50%`, fluid shapes |
| **Metallic / Chrome** | 금속 반사, 크롬 그라디언트 | Linear gradients mimicking metal |
| **Grain / Grainy Gradient** | 필름 그레인 + 소프트 그라디언트 | SVG noise filter overlay |
| **Gradient Blur / Acid Blur** | 몽환적 흐릿한 색상 전환 | Large blurred gradient blobs |
| **3D / Soft-Depth** | 미묘한 그림자로 반입체감 | Multi-layer shadows, subtle highlights |
| **Organic Imperfection** | 손으로 그린 느낌, 불완전한 선 | Wavy borders, hand-drawn SVG |
| **Paper / Papercraft** | 종이 접기, 물리적 층위감, 공예 질감 | Paper textures, folded edges |
| **Naïve Design** | 어린아이처럼 순수한 드로잉, 따뜻함 | Crude shapes, bright fills, playful |
| **Collage** | 겹치는 이미지·텍스처·텍스트 조각 | Overlapping positioned elements |
| **Graffiti** | 스프레이 페인트, 자유형 타이포, 스트리트 | Bold irregular type, spray textures |
| **Surrealism** | 꿈 같은 병치, 초현실적 공간 | Unexpected juxtapositions, dreamlike |

## F. Layout/Structural (레이아웃)

| Style | Visual Signature | CSS Essence |
|-------|-----------------|-------------|
| **Bento Grid** | Apple식 — 다양한 크기 직사각형 타일, 균일 간격 | CSS Grid with varying `span` sizes |
| **Swiss Grid** | 수학적 정밀 열 기반 그리드, 비례 관계 | 12-column strict grid |
| **Asymmetric Layout** | 의도적 비대칭, 오프셋, 동적 긴장감 | Uneven column splits (7/5, 8/4), `rotate()`, margin offsets |
| **Modular Typography** | 타이포를 빌딩 블록으로, 실험적 활자 | Font as layout element |
| **Blueprint / Technical** | 설계도면 — 파란 배경, 흰색 라인 | Blue bg, white lines, grid coords |
| **Dashboard** | 데이터 위젯, 차트, KPI 카드 | Dense card grids, data-focused |
| **Editorial Scroll** | 긴 스크롤 스토리텔링, 매거진 리듬 | Alternating layouts, scroll-triggered |
| **Full-Bleed Sections** | 섹션마다 전체 화면, 극적 전환 | `min-h-screen` per section |
