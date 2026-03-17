# Interaction Design — Review Checklist

Covers: Affordance & Signifiers, Feedback & Component States, Micro-interactions & Motion.
Based on: Don Norman's signifier theory (2008), Dan Saffer's Microinteractions framework (O'Reilly 2013), Material Design 3 State Layer system, Disney's 12 animation principles.

---

## Part A — Affordance & Signifiers

**Core principle (Don Norman, 2008):** "Affordances determine what actions are possible. Signifiers communicate where the action should take place." Designers must focus on signifiers, not affordances.

### A1. Interactive Element Signifiers

**Rule:** Every clickable/interactive element must have a visual signifier that communicates interactivity.

**Flag:**
- `<div>` or `<span>` with click handlers but no `cursor: pointer`, no hover state, no button-like visual treatment
- Flat text that functions as a button (no border, no background, no underline — looks like static text)
- Icon-only buttons with no label, tooltip, or `aria-label`
- Links styled identically to surrounding non-link text (missing underline AND color differentiation)

**Good signifiers:**
- Button: background color + border-radius + hover state
- Link: underline or distinct color + hover change
- Input field: border + background difference from page + cursor change on focus
- Draggable element: grab cursor + subtle background change

### A2. Primary Action Prominence

**Rule:** The most important action on any screen should be visually dominant.

**Flag:**
- No visual hierarchy between primary CTA and secondary actions (all buttons same weight)
- Primary action uses an outlined/ghost button style when a filled/solid style should be used
- Multiple "primary" buttons on the same view (primary vs. secondary vs. tertiary hierarchy missing)

### A3. Discoverability

**Rule:** Key actions should not require discovery. Users should not need to hover to find critical functionality.

**Flag:**
- Important features accessible only via hover (no persistent hint)
- Long-press or right-click as the only way to access common actions with no tooltip or persistent UI
- Progressive disclosure used inappropriately (hiding primary actions behind menus)

---

## Part B — Feedback & Component States

**Required states for interactive components:** Default → Hover → Focus → Active/Pressed → Disabled → Loading → Error → Success

### B1. Hover State

**Rule:** All interactive elements must have a visually distinct hover state.

**Flag:**
```css
/* BAD — no hover differentiation */
.button { background: #0070f3; }
/* no .button:hover rule anywhere */

/* GOOD */
.button:hover { background: #0051cc; box-shadow: 0 2px 8px rgba(0,0,0,0.2); }
```
Tailwind equivalent: missing `hover:bg-*` or `hover:opacity-*` on clickable elements.

### B2. Focus State

**Rule:** Focus indicators are MANDATORY. Removing them is an accessibility violation.

**Flag immediately (high severity):**
```css
/* VIOLATION — removes all focus indication */
* { outline: none; }
button:focus { outline: none; }
input:focus { outline: none; }
```

**This is allowed (custom focus indicator provided):**
```css
button:focus-visible { outline: 2px solid #0070f3; outline-offset: 2px; }
```

### B3. Disabled State

**Rule:** Disabled elements must be visually distinguishable from enabled elements.

**Flag:**
- No opacity or color change on disabled elements
- `opacity: 0.3` is too extreme (use 0.4–0.5)
- Disabled state relies only on cursor change without visual change

### B4. Loading State

**Rule:** Any operation that takes >100ms needs a loading indicator.

**Flag:**
- Button triggers async operation but has no loading state (no spinner, no disabled state during fetch)
- List/table loads data but shows empty state rather than skeleton or spinner
- Form submission with no feedback during processing

### B5. Error & Success States

**Rule:** Form inputs must communicate validation state visually.

**Flag:**
- No visual change on invalid input (only the browser default red outline)
- Error message not associated with the field it describes (it appears elsewhere on the page)
- Success state not confirmed after successful form submission
- Error communicated only by color (no icon or text — color-blind users can't distinguish)

---

## Part C — Micro-interactions & Motion

**Core framework (Dan Saffer):** Trigger → Rules → Feedback → Loops & Modes

Natural interaction timing (Disney principles):
- Instant transitions: < 100ms (feel broken/laggy if longer)
- Micro-interaction: 200–300ms (sweet spot)
- Page/layout transition: 300–500ms
- Long animation: > 500ms (must have purpose — never decorative at this length)

### C1. Transition Easing

**Rule:** Use easing curves. `linear` feels mechanical. `ease-in-out` or `cubic-bezier` for UI transitions.

**Flag:**
```css
/* BAD */
transition: all 0.3s linear;
transition: opacity 0.2s linear;

/* GOOD */
transition: transform 200ms ease-out;
transition: opacity 150ms ease-in-out;
```

### C2. Transition Duration

**Flag:**
- Durations > 400ms for micro-interactions (hover, toggle, button feedback) — feels sluggish
- Durations < 100ms for visual state changes that users need to notice — feels broken/instant-glitch
- `transition: all` (catches unintended properties, causes performance issues — flag as low)

### C3. `prefers-reduced-motion` — REQUIRED

**Rule:** Any CSS animation or JS-driven animation MUST respect `prefers-reduced-motion`.

**Flag (high severity if animations exist but this is absent):**
```css
/* Required when using animations */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

Also accept component-level handling:
```css
@media (prefers-reduced-motion: reduce) {
  .animated-element { animation: none; transition: none; }
}
```

Or JS-level: `window.matchMedia('(prefers-reduced-motion: reduce)').matches`

### C4. Missing Feedback

**Rule (Dan Saffer Trigger→Feedback):** Every trigger must produce visible feedback.

**Flag:**
- Form submission: button clicked, nothing changes for > 200ms (no spinner, no state change)
- Toggle switch: state changes but no animation (instant jump with no transition)
- Delete action: item disappears instantly with no confirmation or undo affordance
- Navigation: page change with no transition (jarring cut)

### C5. Over-animation

**Flag:**
- Background decorative animations running continuously (spinning logos, floating particles)
- Multiple elements animating simultaneously and competing for attention
- Bounce/elastic easing on functional UI elements (acceptable for celebration/gamification moments only)

---

## Severity Guide

| Issue | Severity |
|-------|----------|
| `outline: none` without replacement | high |
| Missing `prefers-reduced-motion` with existing animations | high |
| No hover state on interactive elements | high |
| Primary action not visually dominant | high |
| No loading state for async operations | medium |
| `linear` easing on transitions | low |
| `transition: all` usage | low |
| Missing success state after form submit | medium |
| Disabled state indistinguishable | medium |
