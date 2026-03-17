# Visual Hierarchy & Layout — Review Checklist

Based on: Figma Visual Hierarchy Guide, Material Design 3, Designary 4px/8px Grid research.

## 1. Spacing & Grid Consistency

**Rule:** All spacing values (margin, padding, gap, line-height) should be multiples of 4px.

Check for:
- Arbitrary spacing values (e.g., `padding: 7px`, `margin: 13px`, `gap: 5px`) that break grid rhythm
- Inline styles with non-grid-aligned values
- Mixed grid systems in the same component (some 4px, some 5px, some arbitrary)

**Common patterns (flag these):**
```css
/* BAD — non-multiples */
padding: 7px 11px;
margin-top: 13px;
gap: 5px;

/* GOOD — 4px multiples */
padding: 8px 12px;
margin-top: 16px;
gap: 8px;
```

**Tailwind mappings:** `p-1`=4px, `p-2`=8px, `p-3`=12px, `p-4`=16px, `p-6`=24px, `p-8`=32px — these are all fine.

## 2. Typography Scale

**Rule:** Font sizes should follow a consistent scale. Line-heights should be 4px multiples.

Acceptable scale examples:
- `12 / 14 / 16 / 20 / 24 / 32 / 48px`
- Tailwind's default type scale is acceptable.

Flag:
- Arbitrary font sizes (e.g., `font-size: 13px`, `font-size: 17px`) that don't fit any scale
- Line-heights not aligned to 4px grid (e.g., `line-height: 1.37`)
- Body text line-height outside 1.4–1.6 range
- Heading line-height outside 1.1–1.2 range

**Target line-heights:**
| Element | Font size | Line-height |
|---------|-----------|-------------|
| Body | 16px | 24px (1.5) |
| Small | 14px | 20px (1.43) |
| Heading L | 32px | 40px (1.25) |
| Heading XL | 48px | 56px (1.17) |

## 3. Visual Hierarchy — Size & Weight

**Rule:** Content importance should be legible from the visual weight alone. Primary content must visually dominate.

Flag:
- All text on a page/component uses the same weight (no differentiation)
- CTA buttons not visually dominant relative to surrounding content
- Multiple competing elements at the same visual weight (split focus)
- Decorative elements drawing more visual attention than functional content

## 4. Alignment & Proximity (Gestalt)

**Rule:** Related elements grouped, unrelated elements separated. Consistent alignment axis.

Flag:
- Form labels not aligned with their inputs
- Card content misaligned (titles at different x-positions across a grid of cards)
- Unrelated elements placed in proximity without visual separator
- Mixed alignment axes in the same component (some left-aligned, some center-aligned with no clear intent)

## 5. White Space

**Rule:** Sufficient breathing room between logical sections. Dense layouts should use internal grouping.

Flag:
- No spacing between major sections of a page (everything crammed together)
- Interactive elements touching each other without any gap (tap target collision risk)
- Content containers with zero or near-zero padding

## Severity Guide

| Issue | Severity |
|-------|----------|
| Non-grid spacing causing layout breaks | high |
| Typography scale violation across primary content | medium |
| Single element with bad spacing in isolation | low |
| Missing white space between major sections | medium |
| Alignment inconsistency across repeated components | medium |
