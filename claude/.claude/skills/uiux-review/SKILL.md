---
name: uiux-review
description: |
  Perform a comprehensive UI/UX review of frontend code in the current codebase or a specified directory/file. Use this skill when the user asks to review UI, UX, design quality, visual hierarchy, color usage, accessibility, micro-interactions, affordance, or component states in frontend code. Triggers on: "review UI", "check UX", "audit design", "review accessibility", "check component states", "review animations", "/uiux-review".
user_invocable: true
argument: "[path] — directory or file to review. Defaults to current working directory."
---

# UI/UX Review

Comprehensive frontend UI/UX review using parallel specialist agents. Modeled after the code-review plugin's multi-agent pipeline: gather context → parallel specialist review → confidence scoring → filter → structured report.

## Arguments

Parse the user's argument:
- If a path is provided, review that directory or file.
- If no path is provided, review the current working directory.
- Normalize to an absolute path before proceeding.

## Workflow

### Step 1 — Pre-flight Check (Haiku agent)

Launch a Haiku agent to scan the target path and determine:

1. Does the target contain frontend code? (Look for `.tsx`, `.jsx`, `.vue`, `.svelte`, `.html`, `.css`, `.scss` files.)
2. What framework is used? (React, Vue, Svelte, plain HTML/CSS, etc.)
3. Is there any existing design system documentation? (Look for `design-system/`, `tokens/`, `theme/`, CSS variables, Tailwind config, any style guide docs.)
4. List the top-level frontend files and directories relevant to UI/UX review. Return max 30 files, prioritizing component files over utility/logic files.

If no frontend code is found, stop and report: "No frontend code found at [path]."

### Step 2 — Context Gathering (Haiku agent)

Launch a Haiku agent to:
1. Find any CLAUDE.md files in the target path and its parents. Return file paths only (not contents).
2. Find any design tokens, theme files, or CSS variable declarations (e.g., `variables.css`, `tokens.json`, `theme.ts`). Return file paths only.
3. Return the tech stack summary from Step 1.

### Step 3 — Scope Summary (Haiku agent)

Launch a Haiku agent to read the top 10 most UI-relevant files identified in Step 1, then return:
- A 3-sentence summary of what the UI does (purpose, main components, overall structure).
- A list of UI patterns observed (forms, modals, cards, navigation, data tables, etc.).
- Any immediately obvious design system or styling approach.

### Step 4 — Parallel Specialist Review (6 Sonnet agents)

Launch all 6 agents simultaneously. Each agent loads its specific reference file and returns a list of issues with exact file paths and line numbers where possible.

**Agent 1 — Visual Hierarchy & Layout**
Read `references/visual-hierarchy-checklist.md` before reviewing.
Examine the target files for:
- Spacing and grid consistency (4px/8px grid adherence)
- Visual hierarchy clarity (size, weight, color contrast for importance signaling)
- Typography scale consistency and line-height adherence
- Alignment and proximity grouping (Gestalt principles)
- White space usage

Return issues as: `[file:line] issue description — severity: high/medium/low`

**Agent 2 — Color & Theming**
Read `references/color-theming-checklist.md` before reviewing.
Examine the target files for:
- Hardcoded color values instead of design tokens/CSS variables
- Missing semantic color roles (primary, error, success, warning, surface)
- Dark mode implementation issues (hardcoded light-only values, missing dark variants)
- Insufficient contrast ratios (WCAG AA: 4.5:1 for text)
- Pure black (#000000) used as background

Return issues as: `[file:line] issue description — severity: high/medium/low`

**Agent 3 — Affordance & Signifiers**
Read `references/interaction-design-checklist.md` before reviewing.
Examine the target files for:
- Interactive elements without clear signifiers (missing cursor, hover state, or visual cue)
- Hidden or buried primary actions (key actions not prominent)
- Ambiguous button/link labels
- Missing or insufficient hover states on clickable elements
- Anti-patterns: flat buttons that look like text, text that looks like buttons

Return issues as: `[file:line] issue description — severity: high/medium/low`

**Agent 4 — Feedback & Component States**
Read `references/interaction-design-checklist.md` before reviewing.
Examine the target files for:
- Missing component states: hover, focus, active, disabled, loading, error, success
- Focus styles removed without replacement (`outline: none` without custom focus indicator)
- No loading/skeleton states for async content
- Error states not designed (form validation, fetch errors)
- Disabled state indistinguishable from enabled state

Return issues as: `[file:line] issue description — severity: high/medium/low`

**Agent 5 — Micro-interactions & Motion**
Read `references/interaction-design-checklist.md` before reviewing.
Examine the target files for:
- Abrupt state transitions without easing (linear or instant transitions)
- Missing `prefers-reduced-motion` media query for animations
- Transition duration outside the natural range (aim for 200–400ms)
- Missing touch feedback (no visual/haptic response to taps on mobile)
- Over-animation (excessive motion that could distract or harm)

Return issues as: `[file:line] issue description — severity: high/medium/low`

**Agent 6 — Accessibility**
Read `references/accessibility-checklist.md` before reviewing.
Examine the target files for:
- Focus styles removed (`outline: none` with no replacement)
- State conveyed by color alone (no icon/text alternative)
- Missing `aria-*` attributes for dynamic content (`aria-live`, `aria-expanded`, etc.)
- Touch targets smaller than 44×44px
- Interactive elements unreachable via keyboard (missing `tabindex`, `role`, or keyboard handler)
- Images without alt text, icons without labels

Return issues as: `[file:line] issue description — severity: high/medium/low`

### Step 5 — Confidence Scoring (parallel Haiku agents)

For each issue found across all 6 agents, launch a parallel Haiku agent. Provide the agent with:
- The issue description and file:line reference
- The CLAUDE.md file paths from Step 2
- The tech stack context from Step 1

The agent must score the issue on 0–100 confidence. Give the agent this rubric verbatim:

```
Score the issue on this scale:
0: False positive. Does not stand up to scrutiny, or is a pre-existing/framework issue.
25: Possibly real. Could not verify. Stylistic issue not explicitly required.
50: Likely real but minor. Nitpick or rare edge case. Low importance relative to scope.
75: High confidence. Verified as a real issue. Will be encountered in practice. Important.
100: Certain. Confirmed real. Will happen frequently. Clear violation of standard or checklist item.

For issues in the Accessibility category, treat WCAG AA violations as 100 if confirmed.
For issues in Color, treat hardcoded colors in a codebase with existing tokens as 75+.
```

### Step 6 — Filter

Discard any issue with a score below 75.

If no issues remain, skip to Step 8 and report: "No significant UI/UX issues found."

### Step 7 — Pre-report Eligibility Check (Haiku agent)

Launch a Haiku agent to confirm the target path still exists and was not deleted. This mirrors the final eligibility check in the code-review plugin.

### Step 8 — Output the Report

Format the final report using the template below. Group issues by specialist domain. Sort each group by severity (high → medium → low).

---

```
### UI/UX Review

Target: {path}
Framework: {framework}
Files reviewed: {count}

Found {N} issues:

#### Visual Hierarchy & Layout

1. [high] Brief description
   `{file}:{line}` — {specific observation}

#### Color & Theming

2. [high] Brief description
   `{file}:{line}` — {specific observation}

#### Affordance & Signifiers

(none found)

#### Feedback & Component States

3. [medium] Brief description
   `{file}:{line}` — {specific observation}

#### Micro-interactions & Motion

4. [medium] Brief description
   `{file}:{line}` — {specific observation}

#### Accessibility

5. [high] Brief description
   `{file}:{line}` — {specific observation}

---
Reference standards:
- Visual Hierarchy: WCAG, Figma design system guidelines
- Color: WCAG AA 4.5:1 contrast, Material Design 3 token system
- Micro-interactions: Dan Saffer's framework (200–400ms natural range)
- Accessibility: WCAG 2.1 AA, Apple HIG (44×44px touch targets), MDN prefers-reduced-motion
```

---

If no issues were found:

```
### UI/UX Review

Target: {path}
Framework: {framework}
Files reviewed: {count}

No significant UI/UX issues found.

Domains checked: Visual Hierarchy, Color & Theming, Affordance & Signifiers,
Feedback & States, Micro-interactions & Motion, Accessibility
```

---

## Gotchas

- **Framework CSS-in-JS**: In Tailwind/styled-components codebases, hardcoded colors may appear as arbitrary values like `bg-[#ff0000]` — flag these the same as hardcoded hex in CSS.
- **Design system codebases**: If the target IS a design system (tokens, theme files), skip the "missing tokens" check — these files define tokens, not consume them.
- **Generated code**: If files are clearly auto-generated (e.g., `.generated.ts`, icon sprite files), skip them.
- **False positive threshold**: A component that intentionally uses `outline: none` with a custom `:focus-visible` style is NOT a violation — confirm before flagging.
- **Severity mapping**: high = accessibility violation or broken UX flow; medium = degraded experience but functional; low = polish/refinement.

## Reference Files

| File | Load when | Content |
|------|-----------|---------|
| `references/visual-hierarchy-checklist.md` | Agents 1 | Grid, spacing, typography review criteria |
| `references/color-theming-checklist.md` | Agent 2 | Color tokens, dark mode, contrast criteria |
| `references/interaction-design-checklist.md` | Agents 3, 4, 5 | Affordance, states, micro-interactions criteria |
| `references/accessibility-checklist.md` | Agent 6 | WCAG, ARIA, keyboard, motion criteria |
| `references/scoring-rubric.md` | Step 5 scoring agents | Full confidence scoring rubric with examples |
