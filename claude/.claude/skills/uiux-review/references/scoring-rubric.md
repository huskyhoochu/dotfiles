# Confidence Scoring Rubric — UI/UX Review Issues

Used in Step 5 of the uiux-review skill. Each scoring agent receives one issue and returns a score from 0–100.

## The Rubric (provide verbatim to scoring agents)

```
Score the issue on this scale:

0: False positive. Does not stand up to scrutiny. Pre-existing issue in code the
   reviewer wasn't asked to audit. Framework default behavior. Issue is in
   auto-generated code.

25: Possibly real. Could not verify with confidence. Stylistic concern not
    explicitly required by any standard or guideline. May be a matter of
    preference rather than correctness.

50: Likely real but minor. Confirmed as an issue, but it's a nitpick, rarely
    encountered, or has low user impact. A polished codebase would address it,
    but it won't cause UX failures.

75: High confidence. Verified as real. Will be encountered in normal usage.
    Clear violation of a named standard (WCAG, Material Design guidelines,
    Apple HIG, Dan Saffer's framework, 4px grid system). The existing
    implementation is insufficient and users will notice.

100: Certain. Confirmed real. Happens frequently or in a primary user flow.
     The evidence directly confirms the issue. No ambiguity.
```

## Domain-Specific Scoring Guidance

### Accessibility Issues

| Issue type | Base score |
|------------|-----------|
| `outline: none` / `outline: 0` on focus with no replacement | 100 |
| WCAG AA contrast failure (verified ratio) | 100 |
| Missing keyboard access on interactive element | 100 |
| Animation without `prefers-reduced-motion` (confirmed) | 100 |
| Missing alt text on `<img>` with no `alt=""` or `aria-hidden` | 100 |
| Touch target confirmed < 44px on mobile component | 75 |
| Missing ARIA on confirmed custom interactive component | 75 |
| tabindex > 0 | 50 |
| Missing `aria-live` on dynamic content | 50–75 (higher if primary flow) |

### Color & Theming Issues

| Issue type | Base score |
|------------|-----------|
| Hardcoded hex in codebase with design token system | 75 |
| Hardcoded hex in codebase without any token system | 50 |
| Color-only state differentiation (no icon/text backup) | 100 |
| Pure `#000000` background in dark mode | 25 |
| Missing dark mode support in token-defined codebase | 75 |

### Interaction Issues

| Issue type | Base score |
|------------|-----------|
| No hover state on confirmed interactive element | 75 |
| `linear` easing on transition | 25 |
| `transition: all` | 25 |
| No loading state on confirmed async operation | 75 |
| No focus state (distinct from outline removal) | 75 |
| Transition duration > 400ms on micro-interaction | 50 |

### Visual Hierarchy Issues

| Issue type | Base score |
|------------|-----------|
| Non-4px-multiple spacing in a design-token codebase | 75 |
| Non-4px-multiple spacing in codebase with no token system | 50 |
| Typography scale violation on primary content areas | 50 |
| No visual hierarchy between primary/secondary actions | 75 |
| Line-height outside recommended range for body text | 50 |

## False Positive Examples — Do NOT flag these

- An element that removes `outline: none` on `:focus` but provides a custom `:focus-visible` style
- A `:root` CSS file that defines hardcoded color hex values (this IS the token definition file)
- A `.generated.tsx` or `.d.ts` file with inline styles (auto-generated, not human-authored)
- Pre-existing issues in files the user didn't touch (only flag if user was explicitly asked to review the whole codebase)
- `transition: none` on a component that explicitly has `@media (prefers-reduced-motion)` applied (this IS the reduced-motion implementation)
- A Tailwind class like `text-gray-500` — this uses the design system scale, NOT a hardcoded color
- Icon decorative SVGs with `aria-hidden="true"` — this is correct, not an issue
- A `<button disabled>` that appears visually similar to enabled — if the framework provides the disabled state styling automatically

## Scoring Agent Instructions

1. Read the issue description and the file:line reference.
2. If a file:line is given, read that specific code in context (±5 lines).
3. Apply the rubric and domain-specific guidance above.
4. Check: is this a false positive from the list above?
5. Return only: `SCORE: [0/25/50/75/100] — [1-sentence reason]`

Do not return partial scores (e.g., 60 or 80). Use the five discrete values only.
