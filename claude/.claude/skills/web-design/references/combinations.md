# Style Combination Guide

스타일 조합 규칙과 검증된 레시피. 최대 3개 스타일을 조합하여 고유한 디자인 생성.

## Combination Framework

최적의 조합은 **3개 축에서 각 1개**를 선택:

| Axis | Role | Categories |
|------|------|-----------|
| **Aesthetic** | 시각적 톤과 분위기 결정 | Morphism, Web Movements, Era-Based, Digital-Native |
| **Texture** | 표면 질감과 깊이 결정 | Texture/Material |
| **Layout** | 공간 구성과 리듬 결정 | Layout/Structural |

예시: `Neobrutalism(Aesthetic) + Grain Texture(Texture) + Asymmetric Layout(Layout)`

단일 스타일도 유효 — 강한 하나가 약한 셋보다 낫다.

## Tested Recipes (실전 검증)

### 🟢 Warm Brutalism
```
Styles: Neobrutalism + Asymmetric Layout + (Earthbound Warmth palette)
Result: 따뜻한 대지색 위에 거친 테두리와 offset 그림자. 비대칭 그리드로 동적 긴장감.
Key CSS: border: 3px solid; box-shadow: 6px 6px 0; rotate(-1.5deg); margin-left: 8%
Tested: Gemini Pro 3 → "HOLLOW GROVE" indie game landing (2026-02)
Rating: ★★★★★
```

### 🟢 Frosted Future
```
Styles: Glassmorphism + Bento Grid + Gradient Blur
Result: 반투명 카드가 블러 배경 위에 벤토 그리드로 배열. 몽환적 미래감.
Key CSS: backdrop-blur-xl; bg-white/10; border border-white/20; grid with varied spans
Palette: Galactic Glow or Aurora Pastel Harmony
Rating: ★★★★☆
```

### 🟢 Neo Magazine
```
Styles: Editorial + Neobrutalism + Swiss Grid
Result: 매거진 타이포그래피에 brutalist 테두리와 정밀 그리드 결합. 지적이면서 대담.
Key CSS: multi-column; large serif headings; thick borders; strict 12-col grid
Palette: Premium Corporate or Royal Noir Gold
Rating: ★★★★☆
```

### 🟢 Retro Arcade
```
Styles: Y2K + Pixel Art + Full-Bleed Sections
Result: 크롬 그라디언트, 픽셀 폰트, 섹션마다 전체 화면 전환. 게임 느낌.
Key CSS: chrome gradients; Press Start 2P font; min-h-screen sections; scanline overlay
Palette: Neon Festival Chaos or Cyber Pink Pulse
Rating: ★★★★☆
```

### 🟢 Zen Minimal
```
Styles: Japandi + Neo-Minimalism + Organic Imperfection
Result: 선과 여백의 조화, 자연 소재감, 미세한 불완전함이 인간미를 더함.
Key CSS: generous padding; neutral tones; wavy svg borders; serif accent
Palette: Chocolate & Jade or Earthbound Warmth
Rating: ★★★★☆
```

### 🟢 Dark Terminal
```
Styles: Cyberpunk + Dashboard + Grain Texture
Result: 어두운 터미널 미학에 데이터 위젯, 네온 악센트, 필름 그레인.
Key CSS: dark bg; neon borders; monospace; grid of stat cards; noise overlay
Palette: Luminous Tech Neon or Midnight Luxe
Rating: ★★★★☆
```

### 🟡 Academic Gothic
```
Styles: Dark Magic Academia + Victorian + Editorial Scroll
Result: 어두운 학술적 분위기, 고딕 장식, 긴 스크롤 스토리텔링.
Key CSS: dark warm bg; ornate borders; serif fonts; long-scroll sections
Palette: Royal Noir Gold (modified with warm browns)
Rating: ★★★☆☆ (장식이 과하면 로딩 지연)
```

### 🟡 Liquid Luxury
```
Styles: Aurora UI + Liquid Design + Glassmorphism
Result: 유체적 형태 + 프로스트 글라스 + 오로라 그라디언트. 화려하지만 과잉 주의.
Key CSS: blob shapes; iridescent gradients; backdrop-blur; animated color shifts
Palette: Aurora Pastel Harmony or Galactic Glow
Rating: ★★★☆☆ (세 스타일 모두 "화려한" 축이라 절제 필요)
```

## Combination Anti-Patterns (피해야 할 조합)

| Bad Combo | Why |
|-----------|-----|
| Minimalism + Maximalism | 상충하는 철학 — 중간지대가 어중간해짐 |
| Glassmorphism + Neobrutalism | 블러+투명 vs 두꺼운 실선 — 시각적 혼란 |
| Art Deco + Pixel Art | 럭셔리 정밀함 vs 저해상도 — 의도가 불분명 |
| Neumorphism + Dark Mode UI | Neumorphism의 미묘한 그림자가 어두운 배경에서 작동 안함 |
| 3개 모두 같은 축 | Neobrutalism + Maximalism + Anti-Design → 과잉, 구조 없음 |

## Combination Tips

1. **하나를 지배적으로**: 3개 스타일 중 하나가 70%의 시각적 무게를 가져야 함
2. **레이아웃 스타일은 항상 유용**: Bento Grid, Asymmetric, Swiss Grid는 어떤 미학과도 조합 가능
3. **텍스처는 양념**: Grain, Gradient Blur 등은 약하게 적용 — 주인공이 되면 안됨
4. **팔레트가 조합을 통합**: 서로 다른 스타일도 같은 팔레트를 공유하면 coherent해짐
5. **의심되면 2개로 줄여라**: 2개 스타일이 3개보다 거의 항상 나음
