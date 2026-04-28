---
name: web-design
description: |
  Claude-optimized web design skill. Generates distinctive, production-grade
  single-page HTML through interactive design consultation. Tuned for Claude's
  strengths: deep instruction following, hierarchical reference processing,
  and consistent multi-section code generation.
---

# Web Design Skill — Claude Optimized

Generate distinctive, production-grade single-page HTML through interactive design consultation. Every generation must look unique — never converge on common AI defaults.

## Why Claude-Specific

This skill is tuned for Claude's processing characteristics:
- **Hierarchical reference loading**: Claude excels at cross-referencing multiple structured documents. Load references lazily — read only when the step requires them.
- **Positive instructions**: Tell Claude what TO DO, not what to avoid. Claude follows affirmative directives more reliably.
- **Semantic token system**: Define colors as named tokens in Tailwind config — Claude maintains consistency across a long file when tokens have meaningful names.
- **Quality gates**: Claude responds well to explicit "verify before proceeding" checkpoints embedded in the workflow.

## Constraints

- **Output**: Single `.html` file. No build tools.
- **CDNs only**: Tailwind CSS CDN + Google Fonts CDN.
- **No external images**: Inline SVG, CSS gradients, emoji, Unicode.
- **Self-contained**: Must render from local filesystem.
- **Language**: Match user's language.

## Interactive Design Workflow

Walk through each step sequentially. Ask one question at a time. Confirm before proceeding. If the user provides all specs upfront, skip to Step 6.

### Step 1 — Page Type

Ask what kind of page to build.

| Type | Typical Sections |
|------|-----------------|
| Landing page | Hero, features, testimonials, CTA, footer |
| Portfolio | Hero, project grid, about, contact |
| Blog/article | Header, content, sidebar, footer |
| Dashboard | Nav, stat cards, charts, data tables |
| Product page | Hero, gallery, specs, pricing, reviews |
| Event page | Hero, schedule, speakers, registration |

Adapt sections to the user's concept.

### Step 2 — Design Style Selection

Read `references/styles.md`. Present the 6 categories with brief visual descriptions:

1. **Morphism** — surface/depth (Glassmorphism, Neumorphism...)
2. **Web Movements** — philosophies (Neobrutalism, Minimalism...)
3. **Era-Based** — historical (Art Deco, Y2K, Japandi...)
4. **Digital-Native** — internet-born (Vaporwave, Cyberpunk...)
5. **Texture/Material** — tactile (Liquid, Grain, Chrome...)
6. **Layout/Structural** — composition (Bento Grid, Asymmetric...)

User picks 1–3 styles (one per axis: aesthetic + layout + texture).

After selection, read `references/combinations.md` to validate. Flag anti-patterns. Suggest refinements if needed.

### Step 3 — Color Palette

Read `references/palettes.md`. Suggest 3 palettes matching the chosen styles.

Present each palette with visual blocks and context:
```
Palette: Earthbound Warmth
█ #C18A63  █ #F4EBD2  █ #7E9C76  █ #4A3F36  █ #5E7B4C
Best for: eco brands, wellness — pairs with Neobrutalism, Japandi
```

Ensure 4.5:1 contrast ratio between text and background. Define hierarchy: background, surface, primary, secondary, accent.

### Step 4 — Font Pairing

Read `references/fonts.md`. Suggest 3 font pairs matching styles.

```
Pair: Space Grotesk + Space Mono
Heading: Space Grotesk (600, 700) — geometric, technical
Body/Accent: Space Mono (400) — monospace contrast
Best for: Neobrutalism, Dashboard
```

All fonts from Google Fonts CDN. Korean projects: always include Noto Sans KR.

### Step 5 — Content Brief

Ask about:
- Hero headline and subtext
- Key sections (confirm from Step 1 or customize)
- Tone: playful / professional / dramatic / minimal
- Special elements: animations, scroll effects, SVG illustrations

### Step 6 — Confirm & Generate

Summarize choices:
```
┌─────────────────────────────────────────┐
│ Page: [concept]                         │
│ Styles: [selections]                    │
│ Palette: [name]                         │
│ Fonts: [heading + body]                 │
│ Sections: [list]                        │
│ Tone: [description]                     │
└─────────────────────────────────────────┘
```

After confirmation, generate the complete HTML.

## HTML Generation Rules

### Claude-Specific Generation Strategy

Generate the full HTML in a single pass. Claude's strength is maintaining coherence across long outputs — leverage this by establishing the design system (Tailwind config, CSS variables, keyframe animations) in the `<head>` first, then building sections that reference those tokens consistently.

**Mental model for generation:**
1. First, write the complete `<head>`: Tailwind config with ALL semantic color tokens, font families, custom shadows, and all `<style>` rules (keyframes, grain overlays, hover effects, scroll animation classes)
2. Then write `<body>` sections top-to-bottom, each section using the tokens from step 1
3. Finally write `<script>` with IntersectionObserver and interaction handlers

This top-down approach plays to Claude's sequential coherence — tokens defined early get used consistently throughout.

### Document Structure
```html
<!DOCTYPE html>
<html lang="[user-language]">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[Page Title]</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=[fonts]&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: { /* ALL palette colors as semantic tokens */ },
                    fontFamily: { /* heading, body, mono */ },
                    boxShadow: { /* custom shadows matching style */ }
                }
            }
        }
    </script>
    <style>
        /* Keyframe animations, grain/noise overlay, hover effects, scroll animation classes */
    </style>
</head>
```

### Implementation Checklist

Every generated page MUST include all of the following:

**Structure:**
- [ ] Semantic HTML5: `<nav>`, `<main>`, `<section>`, `<footer>`
- [ ] Proper heading hierarchy (h1 → h2 → h3)
- [ ] Mobile-first responsive design with `sm:`, `md:`, `lg:` breakpoints

**Design System:**
- [ ] All palette colors defined as semantic Tailwind tokens
- [ ] Custom box-shadow tokens (not just default `shadow-lg`)
- [ ] Font families registered in Tailwind config

**Interactivity:**
- [ ] IntersectionObserver for scroll-triggered animations
- [ ] Navbar scroll effect (backdrop-blur / background change on scroll)
- [ ] Mobile hamburger menu with toggle functionality
- [ ] `html { scroll-behavior: smooth }`
- [ ] Hover effects on interactive elements (cards, buttons)

**Accessibility:**
- [ ] `aria-label` on buttons, nav links, decorative SVGs (`aria-hidden="true"`)
- [ ] Sufficient color contrast (4.5:1 minimum)
- [ ] Keyboard-navigable interactive elements

**Visual Richness:**
- [ ] At least one texture element (grain overlay, noise, gradient, pattern)
- [ ] At least one custom SVG illustration
- [ ] At least one keyframe animation (float, pulse, rotate, etc.)
- [ ] Section background variation (not all sections same color)

### Quality Gate

Before outputting the final HTML, mentally verify:
1. Does every section use the defined color tokens consistently?
2. Is the mobile menu functional (JS toggle included)?
3. Are scroll animations wired up (IntersectionObserver + CSS classes)?
4. Does the page have visual rhythm — alternating section backgrounds, varied card sizes?
5. Would a designer say "this has personality" rather than "this looks AI-generated"?

## Anti-Convergence Rules

### Use distinctive choices:
- Choose characterful, unexpected typefaces — not Inter, Roboto, or Arial
- Commit fully to the chosen aesthetic (if Neobrutalism → thick borders, offset shadows)
- Add texture: grain, noise, gradients, patterns
- Break symmetry intentionally: offset elements, vary card sizes
- Create atmosphere: every page should have a mood

### Vary across generations:
- Alternate between light/dark, warm/cool
- Rotate layout patterns (Bento → Asymmetric → Swiss Grid)
- Use different illustration styles each time

### Quality Indicators
A well-designed page should:
- Feel handcrafted, not assembled from components
- Have a coherent visual narrative from top to bottom
- Surprise the viewer at least once
- Work beautifully on both mobile and desktop
