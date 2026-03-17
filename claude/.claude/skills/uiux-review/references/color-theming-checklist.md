# Color & Theming — Review Checklist

Based on: Material Design 3 token system, WCAG 2.1 AA, Medium Design Bootcamp dark mode guides.

## 1. Hardcoded Color Values

**Rule:** Colors must be referenced via design tokens or CSS variables, not hardcoded literals.

**Flag any of:**
- Hex literals in CSS/SCSS (e.g., `color: #1a73e8`, `background: #ffffff`)
- RGB/RGBA literals (e.g., `background-color: rgb(255, 255, 255)`)
- Tailwind arbitrary color values (e.g., `bg-[#1a73e8]`, `text-[#666666]`)
- Hardcoded color in inline styles (e.g., `style={{ color: '#333' }}`)

**Allowed — these are NOT violations:**
- CSS variable declarations (`:root { --color-primary: #1a73e8; }`)
- Design token definition files (`tokens.json`, `theme.ts`, `variables.css`)
- Storybook/test fixture files that intentionally use raw values

**Severity:** medium (codebase with existing token system → high)

## 2. Semantic Color System

**Rule:** Colors should be named by role, not by appearance.

The 3-tier token hierarchy:
```
Primitive Token    →  Semantic Token           →  Component Token
blue-500          →  color-primary             →  button-bg-primary
gray-900          →  color-surface             →  card-bg
red-500           →  color-error               →  input-border-error
```

**Flag:**
- Primitive tokens used directly in components (e.g., `color: var(--blue-500)` in a button component — should be `var(--color-primary)`)
- Missing error/success/warning semantic tokens when the app has form validation
- Missing surface/on-surface token pair (especially in dark mode context)

**Severity:** medium

## 3. Dark Mode Implementation

**Rule:** Dark mode must work by swapping semantic tokens. Components should not have dark-mode-specific color hardcodes.

**Flag:**
```css
/* BAD: hardcoded per-mode */
.card { background: white; }
.dark .card { background: #1e1e1e; }

/* GOOD: token-based */
.card { background: var(--color-surface); }
/* --color-surface changes value in dark mode via media query or class */
```

Also flag:
- Pure black `#000000` or `rgb(0,0,0)` used as dark mode background (should be `#121212` or similar)
- Pure white `#ffffff` text on very dark background without opacity adjustment (eye strain — prefer ~87% opacity white)
- Elevation not expressed as tonal shifts in dark mode (dark mode should use surface brightness, not shadows)

**Severity:** medium (pure black background → low; missing dark mode entirely in a supposedly dark-mode-ready app → high)

## 4. Contrast Ratios

**Rule:** WCAG AA requires 4.5:1 for normal text, 3:1 for large text (18px+ bold or 24px+ regular).

**Flag (high confidence):**
- Light gray text on white background (e.g., `#999999` on `#ffffff` = ~2.85:1 — fails)
- Placeholder text below 3:1 contrast
- Disabled text where the visual signal is lost entirely (< 1.5:1 is too invisible even for disabled)
- White text on medium-saturation colored buttons (e.g., white on `#4CAF50` medium green = borderline)

**Quick contrast failure patterns:**
| Foreground | Background | Ratio | Result |
|------------|------------|-------|--------|
| #999999 | #ffffff | 2.85:1 | FAIL |
| #767676 | #ffffff | 4.48:1 | PASS (barely) |
| #6b7280 | #f9fafb | 4.6:1 | PASS |
| #9ca3af | #ffffff | 2.85:1 | FAIL |
| white | #4ade80 | 1.7:1 | FAIL |

**Severity:** high (verified WCAG failure)

## 5. Color Blindness Safety

**Rule:** Do not rely on color alone to convey meaning.

**Flag:**
- Error state shown only with red color, no icon or text label
- Success vs error differentiated only by green vs red (no icon, no shape difference)
- Progress or status indicators using only color with no numerical or textual label

**Severity:** high (accessibility violation)

## Severity Guide

| Issue | Severity |
|-------|----------|
| Confirmed WCAG AA contrast failure | high |
| Color-only state differentiation | high |
| Hardcoded color in codebase with token system | high |
| Hardcoded color in codebase without token system | medium |
| Dark mode using pure black background | low |
| Missing semantic token layer | medium |
