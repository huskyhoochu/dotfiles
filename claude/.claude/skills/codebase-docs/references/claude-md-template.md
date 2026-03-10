# CLAUDE.md Template

Use this as a structural guide. Adapt sections to the project. Delete sections that don't apply. Every line must be concrete and actionable — no generic advice.

## Template

```markdown
# CLAUDE.md

## Project Overview

[1-2 sentences: what this project is, its primary purpose]

**Stack:** [language] + [framework] + [key dependencies]
**Type:** [library | web app | API | CLI | monorepo | config]

## Commands

[Copy-pasteable commands. Test these are real before including.]

### Build
\`\`\`bash
[build command]
\`\`\`

### Test
\`\`\`bash
[test all]
[test single file pattern]
[test with coverage]
\`\`\`

### Lint & Format
\`\`\`bash
[lint command]
[format command]
\`\`\`

### Dev Server
\`\`\`bash
[dev server command, if applicable]
\`\`\`

## Architecture

[Directory map — only top 2 levels, only meaningful directories]

\`\`\`
src/
├── components/    # [brief purpose]
├── services/      # [brief purpose]
├── utils/         # [brief purpose]
└── types/         # [brief purpose]
\`\`\`

[Key architectural patterns — 3-5 bullets max]

## Code Conventions

[Only conventions that aren't obvious from linter configs]

- [Naming pattern]
- [Import ordering rule]
- [Error handling pattern]
- [State management approach]

## Testing

[Testing conventions specific to this project]

- Test location: [co-located | separate __tests__/ | tests/]
- Naming: [*.test.ts | *_test.go | test_*.py]
- [Mocking approach]
- [Required coverage threshold, if any]

## File References

[Point to deeper docs that exist in the repo]

- API endpoints: see `docs/api.md`
- Database schema: see `docs/schema.md`
- Deployment: see `.github/workflows/`
```

## Anti-Patterns to Avoid

These should NEVER appear in a generated CLAUDE.md:

- "Write clean, maintainable code" — too vague
- "Follow best practices" — which ones?
- "Use meaningful variable names" — obvious
- Restating what the linter already enforces
- Long paragraphs explaining what the project does (that's README's job)
- Instructions for how to use Git (Claude already knows)
- Listing every single file in the project
- Duplicating README content

## Sizing Guide

| Project Size | CLAUDE.md Target | Rules Files |
|-------------|-----------------|-------------|
| Small (<50 files) | 50-80 lines | 0-1 |
| Medium (50-500 files) | 80-150 lines | 1-3 |
| Large (500+ files) | 150-200 lines | 3-6 |
| Monorepo | 100-150 lines + per-package | 5+ |

## Rules File Template

```markdown
---
paths:
  - "pattern/**/*.ext"
---

# [Context Name] Rules

[Rules specific to files matching this glob pattern]

- [Convention 1]
- [Convention 2]
```

Rules files are for context-specific instructions that would clutter the main CLAUDE.md. Good candidates:
- Test files have different conventions than source files
- API routes follow specific patterns
- UI components have prop/state conventions
- Database migrations have naming/ordering rules
