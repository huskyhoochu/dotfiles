# Accessibility — Review Checklist

Based on: WCAG 2.1 AA, Apple Human Interface Guidelines, Material Design Accessibility, MDN Web Docs.

## 1. Keyboard Accessibility

**Rule:** All interactive functionality must be accessible via keyboard. Tab order must be logical.

### Checklist

**Flag (high severity):**
- `<div>` or `<span>` with click handlers that have no `tabindex`, `role`, or keyboard event handler
- Click-only interactions with no keyboard equivalent:
  ```jsx
  // BAD
  <div onClick={handleDelete}>Delete</div>

  // GOOD — use semantic element or add keyboard support
  <button onClick={handleDelete}>Delete</button>
  // or
  <div
    role="button"
    tabIndex={0}
    onClick={handleDelete}
    onKeyDown={(e) => e.key === 'Enter' && handleDelete()}
  >Delete</div>
  ```
- Dropdowns/modals that trap focus without providing a way to close via Escape key
- Custom components that implement mouse events but no keyboard events

**Flag (medium severity):**
- `tabindex` values > 0 (disrupts natural tab order — use 0 or -1 only)
- Logical tab order broken (visual order doesn't match DOM order without CSS reordering)

## 2. Focus Indicators

**Rule:** Focus must always be visible. Removing the browser default without adding a custom indicator is a WCAG 2.4.7 violation.

**Flag immediately:**
```css
/* VIOLATIONS */
* { outline: none; }
:focus { outline: none; }
button:focus { outline: 0; }
input:focus { outline: none; box-shadow: none; }

/* ALLOWED — custom focus indicator */
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

**Note:** `:focus` vs `:focus-visible` — using `:focus-visible` to hide focus on mouse click while showing on keyboard is acceptable and preferred. Using `:focus { outline: none }` without `:focus-visible` as fallback is NOT acceptable.

## 3. ARIA Attributes

### Dynamic Content

**Flag:**
- Modal that appears dynamically but has no `role="dialog"` and `aria-modal="true"`
- Loading state that has no `aria-live` region to announce completion to screen readers
- Error messages that appear dynamically but are not associated with the field they describe:
  ```html
  <!-- BAD: error appears but screen reader doesn't connect it to input -->
  <input id="email" />
  <p class="error">Invalid email</p>

  <!-- GOOD -->
  <input id="email" aria-describedby="email-error" aria-invalid="true" />
  <p id="email-error" role="alert">Invalid email</p>
  ```

### Interactive Component States

**Flag missing ARIA on custom components:**
| Component | Required ARIA |
|-----------|---------------|
| Toggle/Switch | `role="switch"` + `aria-checked` |
| Accordion | `aria-expanded` on trigger |
| Tab list | `role="tablist"`, `role="tab"`, `aria-selected` |
| Dropdown menu | `aria-haspopup`, `aria-expanded` |
| Progress bar | `role="progressbar"` + `aria-valuenow` + `aria-valuemin` + `aria-valuemax` |
| Loading spinner | `role="status"` or `aria-live="polite"` |
| Alert/notification | `role="alert"` (urgent) or `aria-live="polite"` (non-urgent) |

**Severity:** high if missing on interactive components; medium if missing on decorative/static

## 4. Images & Icons

**Rule:** All meaningful images need alt text. Decorative images must be hidden from screen readers.

**Flag:**
```html
<!-- BAD: missing alt -->
<img src="user-avatar.png" />

<!-- BAD: icon button with no label -->
<button><svg>...</svg></button>

<!-- GOOD: meaningful image -->
<img src="user-avatar.png" alt="Profile photo of John Doe" />

<!-- GOOD: decorative image -->
<img src="background-pattern.png" alt="" aria-hidden="true" />

<!-- GOOD: icon button -->
<button aria-label="Delete item">
  <svg aria-hidden="true">...</svg>
</button>
```

Also flag: Icon-only navigation items without `title`, `aria-label`, or visible label.

## 5. Touch Target Sizes

**Rule:**
- iOS (Apple HIG): minimum 44×44px tap target
- Android (Material Design): minimum 48×48dp tap target
- WCAG 2.5.5 (AAA): 44×44px; WCAG 2.5.8 (AA, WCAG 2.2): 24×24px minimum

**Flag:**
- Icon buttons < 44px × 44px without padding to reach target size
- Close buttons (×) in modals/toasts that are tiny
- Checkbox/radio inputs without `<label>` that extends the tap target
- Navigation items with very small padding on mobile breakpoints

**Severity:** high (mobile-first apps); medium (desktop-only apps)

## 6. Color & Contrast (Cross-reference with Color checklist)

Key rules specific to accessibility:
- Text on backgrounds: 4.5:1 minimum (WCAG AA)
- Large text (18px+ regular, 14px+ bold): 3:1 minimum
- UI component boundaries (input borders, button outlines vs background): 3:1 minimum
- Focus indicators: 3:1 contrast against adjacent colors

**Flag:**
- Placeholder text in inputs: commonly fails (light gray on white)
- Text over image backgrounds: needs overlay to ensure contrast in all conditions
- Disabled text: should still meet minimum readability (aim for 2:1–3:1 even for disabled)

## 7. Motion & Seizure Safety

**Rule:** Respect `prefers-reduced-motion`. No content flashes more than 3 times per second (WCAG 2.3.1).

**Flag (high severity):**
- Animations without `prefers-reduced-motion` media query (see interaction-design-checklist.md)
- Auto-playing video or GIFs that flash rapidly
- No way to pause, stop, or hide moving content that lasts more than 5 seconds (WCAG 2.2.2)

## 8. Form Accessibility

**Rule:** Every form input must have an associated label.

**Flag:**
```html
<!-- BAD: no label association -->
<input type="email" placeholder="Email" />

<!-- GOOD -->
<label for="email">Email address</label>
<input id="email" type="email" placeholder="user@example.com" />

<!-- ALSO GOOD: aria-label for compact forms -->
<input type="search" aria-label="Search products" placeholder="Search..." />
```

Also flag:
- Required fields not marked with `aria-required="true"` or `required`
- Autocomplete not set on common fields (`name`, `email`, `tel`, `address-line1`)

## Severity Guide

| Issue | Severity |
|-------|----------|
| `outline: none` without replacement | high |
| Missing keyboard access to interactive element | high |
| Missing alt text on meaningful image | high |
| WCAG AA contrast failure | high |
| Animation without prefers-reduced-motion | high |
| Touch target < 44px on mobile | high |
| Missing ARIA on custom interactive component | high |
| Icon button without accessible label | high |
| Missing form label | high |
| tabindex > 0 | medium |
| Missing aria-live on dynamic content | medium |
| Placeholder-only label (no visible label) | medium |
