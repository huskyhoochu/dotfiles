# Responsive Design & Performance — Review Checklist

Based on: Mobile-first design principles, Core Web Vitals (CLS), MDN Responsive Design Guide.

## 1. Viewport & Meta

**Rule:** Pages must include a proper viewport meta tag.

**Flag:**
- Missing `<meta name="viewport" content="width=device-width, initial-scale=1">` in HTML entry points
- `user-scalable=no` or `maximum-scale=1` (blocks pinch-to-zoom — accessibility issue)

**Severity:** high (missing viewport), medium (zoom restriction)

## 2. Responsive Breakpoints

**Rule:** Key layouts must adapt to common breakpoints. Components should not break at standard widths.

**Flag:**
- Container or layout component with only fixed pixel widths (e.g., `width: 1200px` with no `max-width` or responsive alternative)
- No media queries or responsive utility classes (e.g., Tailwind `md:`, `lg:`) in a multi-component page
- Sidebar/main layout that has no collapse or stack behavior below tablet width

**Common patterns:**
```css
/* BAD — breaks on small screens */
.container { width: 1200px; }
.sidebar { width: 300px; float: left; }

/* GOOD */
.container { max-width: 1200px; width: 100%; }
.layout { display: grid; grid-template-columns: 1fr; }
@media (min-width: 768px) {
  .layout { grid-template-columns: 300px 1fr; }
}
```

Tailwind: flag components using only `w-[Npx]` without responsive variants.

**Severity:** high (main layout breaks), medium (secondary component)

## 3. Content Overflow

**Rule:** Dynamic text content must handle overflow gracefully.

**Flag:**
- Long text with no `overflow`, `text-overflow`, or `word-break` handling
- Horizontal scrollbar appearing on the page body at any standard viewport width
- Tables without responsive wrapper (`overflow-x: auto`) or alternative mobile layout
- Fixed-width elements inside flex/grid containers that can't shrink

**Severity:** medium

## 4. Layout Shift (CLS)

**Rule:** Elements should not shift position after initial render. This is a Core Web Vital.

**Flag:**
- `<img>` or `<video>` without explicit `width` and `height` attributes (or CSS `aspect-ratio`)
- Dynamically injected content (ads, banners, lazy-loaded items) that pushes existing content down without reserved space
- Font loading that causes visible text reflow (no `font-display: swap` or `font-display: optional`)
- Skeleton/placeholder absent for above-the-fold async content

**Severity:** high (above-the-fold shift), medium (below-the-fold)

## 5. Image Optimization

**Flag:**
- Large images served without `srcset` or `<picture>` for responsive sizing
- Missing `loading="lazy"` on below-the-fold images
- SVG icons embedded as `<img>` when they could be inline SVG (prevents styling, adds requests)

**Severity:** low (optimization suggestion, not a UX failure)

## 6. Mobile Interaction Patterns

**Flag:**
- Hover-dependent interactions with no touch alternative (tooltip content only on hover)
- Horizontal scroll requiring precise mouse drag with no scroll snap or indicators
- Form inputs without appropriate `inputmode` for mobile keyboards (e.g., `inputmode="numeric"` for phone numbers)

**Severity:** medium

## Severity Guide

| Issue | Severity |
|-------|----------|
| Missing viewport meta tag | high |
| Main layout breaks at standard widths | high |
| Above-the-fold layout shift | high |
| Zoom restriction (user-scalable=no) | medium |
| Content overflow/horizontal scroll | medium |
| Hover-only interaction pattern | medium |
| Missing responsive breakpoints on secondary components | medium |
| Missing lazy loading on images | low |
| Missing srcset for responsive images | low |
