---
name: uiux-review
description: |
  Perform a comprehensive UI/UX review of frontend code in the current codebase or a specified directory/file. Use this skill when the user asks to review UI, UX, design quality, visual hierarchy, color usage, accessibility, micro-interactions, affordance, component states, responsive design, or web performance in frontend code. Also use this skill when the user mentions "audit design", "check components", "review animations", "check accessibility", "review responsive", or asks about visual consistency — even if they don't explicitly say "UI/UX review". Triggers on: "review UI", "check UX", "audit design", "review accessibility", "check component states", "review animations", "responsive check", "/uiux-review".
user_invocable: true
argument: "[path] — directory or file to review. Defaults to current working directory."
---

# UI/UX Review

Frontend UI/UX review using parallel specialist agents. Each agent self-scores findings so only high-confidence issues reach the final report.

Pipeline: context discovery → 6 parallel specialist reviews (with self-scoring) → deduplicate → structured report.

## Arguments

Parse the user's argument:
- If a path is provided, review that directory or file.
- If no path is provided, review the current working directory.
- Normalize to an absolute path before proceeding.

## Workflow

### Step 1 — Context Discovery

Launch a single agent (`model: "haiku"`) to scan the target path and return **all of the following in one pass**:

1. **Frontend detection**: Are there frontend files? (`.tsx`, `.jsx`, `.vue`, `.svelte`, `.html`, `.css`, `.scss`)
   → If none found, stop and report: "No frontend code found at [path]."
2. **Framework**: React, Vue, Svelte, plain HTML/CSS, etc.
3. **Design system signals**: Token files, theme files, CSS variable declarations, Tailwind config — file paths only.
4. **CLAUDE.md files**: In the target path and its parents — file paths only.
5. **File inventory**: Up to 30 UI-relevant files, prioritizing components over utility/logic files.
6. **Scope summary**: Read the top 10 most UI-relevant files and return:
   - 3-sentence summary of what the UI does
   - UI patterns observed (forms, modals, cards, navigation, data tables, etc.)
   - Styling approach identified

### Step 2 — Parallel Specialist Review (6 agents)

Launch all 6 agents simultaneously (`model: "sonnet"`). Each agent receives:
- The full context from Step 1
- Its specific reference file to load
- The self-scoring rubric below

Each agent **scores every issue it finds** and **discards anything below 75** before returning results. This eliminates false positives at the source — agents have the best context to judge their own domain.

**Self-scoring rubric (provide verbatim to each agent):**

```
Score each issue you find:

0: False positive. Doesn't hold up to scrutiny. Framework default. Auto-generated code.
25: Possibly real. Can't verify. Stylistic preference, not a standard violation.
50: Likely real but minor. Nitpick or rare edge case. Low user impact.
75: High confidence. Verified real. Clear violation of a named standard. Users will notice.
100: Certain. Confirmed. Happens in a primary user flow. No ambiguity.

Also read references/scoring-rubric.md for domain-specific scoring thresholds and
false positive examples. Only return issues scoring 75+.
```

**Return format for all agents:** `[file:line] (score: N) issue description — severity: high/medium/low`

---

**Agent 1 — Visual Hierarchy & Layout**
Read `references/visual-hierarchy-checklist.md`.
- Spacing and grid consistency (4px/8px grid adherence)
- Visual hierarchy clarity (size, weight, color for importance signaling)
- Typography scale consistency and line-height
- Alignment and proximity grouping (Gestalt principles)
- White space usage

**Agent 2 — Color & Theming**
Read `references/color-theming-checklist.md`.
- Hardcoded color values instead of design tokens/CSS variables
- Missing semantic color roles (primary, error, success, warning, surface)
- Dark mode implementation issues
- Color-only state differentiation (no icon/text backup)
- **Ownership boundary**: Do NOT check contrast ratios — Agent 5 (Accessibility) owns contrast.

**Agent 3 — Interaction Design**
Read `references/interaction-design-checklist.md`, **Parts A and B only**.
- Interactive elements without clear signifiers (missing cursor, hover state, visual cue)
- Primary action prominence and discoverability
- Missing component states: hover, active, disabled, loading, error, success
- Disabled state indistinguishable from enabled
- No loading/skeleton states for async content
- **Ownership boundary**: Do NOT check focus styles or `outline` removal — Agent 5 owns focus.

**Agent 4 — Motion & Animation**
Read `references/interaction-design-checklist.md`, **Part C only**.
- Abrupt state transitions without easing
- Transition duration outside natural range (200–400ms for micro-interactions)
- Missing `prefers-reduced-motion` media query for animations
- Over-animation (excessive motion that distracts)
- Missing feedback transitions (toggle/delete/navigation with no animation)

**Agent 5 — Accessibility**
Read `references/accessibility-checklist.md`.
- **Owns all focus-related issues**: `outline: none` removal, missing focus indicators, `:focus` vs `:focus-visible`
- **Owns all contrast issues**: WCAG AA 4.5:1 for text, 3:1 for large text and UI components
- Missing `aria-*` attributes for dynamic content
- Touch targets smaller than 44×44px
- Interactive elements unreachable via keyboard
- Images without alt text, icons without labels
- Form accessibility (missing labels, required fields)

**Agent 6 — Responsive Design & Performance**
Read `references/responsive-performance-checklist.md`.
- Missing or broken responsive breakpoints for key layouts
- Fixed pixel widths that break on smaller screens
- Images without explicit dimensions (causes layout shift / CLS)
- Content overflow and text truncation issues
- Missing viewport meta tag, zoom restriction
- Hover-only interactions with no touch alternative

### Step 3 — Deduplicate & Report

Collect results from all 6 agents.

**Deduplication**: If the same `file:line` appears from multiple agents, keep the higher-scoring version only.

Format the final report. Group by specialist domain. Sort each group by score (highest first).

---

```
### UI/UX Review

Target: {path}
Framework: {framework}
Files reviewed: {count}

Found {N} issues (confidence ≥ 75):

#### Visual Hierarchy & Layout

1. [high] Brief description
   `{file}:{line}` — {specific observation} (confidence: {score})

#### Color & Theming

2. [high] Brief description
   `{file}:{line}` — {specific observation} (confidence: {score})

#### Interaction Design

(none found)

#### Motion & Animation

3. [medium] Brief description
   `{file}:{line}` — {specific observation} (confidence: {score})

#### Accessibility

4. [high] Brief description
   `{file}:{line}` — {specific observation} (confidence: {score})

#### Responsive Design & Performance

5. [medium] Brief description
   `{file}:{line}` — {specific observation} (confidence: {score})

---
Reference standards:
- Visual Hierarchy: Figma guidelines, 4px/8px grid system
- Color: Material Design 3 token system
- Interaction: Don Norman's signifier theory, Material Design 3 State Layers
- Motion: Dan Saffer's framework (200–400ms), Disney's 12 principles
- Accessibility: WCAG 2.1 AA, Apple HIG (44×44px touch targets)
- Responsive: Mobile-first principles, Core Web Vitals (CLS)
```

---

If no issues were found:

```
### UI/UX Review

Target: {path}
Framework: {framework}
Files reviewed: {count}

No significant UI/UX issues found (confidence threshold: 75).

Domains checked: Visual Hierarchy, Color & Theming, Interaction Design,
Motion & Animation, Accessibility, Responsive Design & Performance
```

---

## Gotchas

- **Framework CSS-in-JS**: In Tailwind/styled-components codebases, hardcoded colors may appear as arbitrary values like `bg-[#ff0000]` — flag these the same as hardcoded hex in CSS.
- **Design system codebases**: If the target IS a design system (tokens, theme files), skip the "missing tokens" check — these files define tokens, not consume them.
- **Generated code**: If files are clearly auto-generated (e.g., `.generated.ts`, icon sprite files), skip them.
- **False positive threshold**: A component that intentionally uses `outline: none` with a custom `:focus-visible` style is NOT a violation — confirm before flagging.
- **Severity mapping**: high = accessibility violation or broken UX flow; medium = degraded experience but functional; low = polish/refinement.
- **Ownership boundaries**: Each agent owns specific checks to prevent duplication. Contrast ratios → Accessibility. Focus styles → Accessibility. Color tokens → Color & Theming. `prefers-reduced-motion` → Motion.

## Reference Files

| File | Load when | Content |
|------|-----------|---------|
| `references/visual-hierarchy-checklist.md` | Agent 1 | Grid, spacing, typography criteria |
| `references/color-theming-checklist.md` | Agent 2 | Color tokens, dark mode (not contrast) |
| `references/interaction-design-checklist.md` | Agents 3, 4 | Affordance + states (A, B), motion (C) |
| `references/accessibility-checklist.md` | Agent 5 | WCAG, ARIA, keyboard, focus, contrast |
| `references/responsive-performance-checklist.md` | Agent 6 | Responsive, layout shift, viewport |
| `references/scoring-rubric.md` | All agents | Domain-specific scoring thresholds, false positive examples |
