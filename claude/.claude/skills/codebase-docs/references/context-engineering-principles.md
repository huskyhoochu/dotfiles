# Context Engineering Principles for CLAUDE.md

Distilled from prompt engineering research. Apply these when generating or reviewing documentation.

## 1. CLAUDE.md Is an Index, Not a Manual

CLAUDE.md answers "how to find information" — not "here is all information."

**Good:** `Database schema: see prisma/schema.prisma`
**Bad:** [50 lines explaining the database schema]

**Good:** `Test with: npm test -- --grep "pattern"`
**Bad:** [Paragraph explaining what testing is and why it matters]

## 2. English Instructions, User's Language for Context

Write rules and directives in English — LLMs comply more reliably with English instructions due to training data distribution (~80% English).

Acceptable in the user's language:
- Project description (if the team is non-English)
- Comments explaining domain-specific terms
- Output language directives ("Answer in Korean")

## 3. Identity Over Negation

Frame rules as identity statements, not prohibitions.

| Instead of | Write |
|-----------|-------|
| "Don't use any" → | "You are a TypeScript-strict codebase. All files use .ts/.tsx." |
| "Never commit without tests" → | "Every PR includes tests for new functionality." |
| "Don't use var" → | "This project uses const/let exclusively." |

## 4. Concrete Over Abstract

Every instruction must be actionable. If you can't verify compliance mechanically, it's too vague.

| Vague | Concrete |
|-------|----------|
| "Write good tests" | "Tests use describe/it blocks. Each test has exactly one assertion." |
| "Handle errors properly" | "API errors return `{ error: string, code: number }`. Use AppError class." |
| "Follow the existing patterns" | "Services are in `src/services/`, export a single class, use constructor injection." |

## 5. Primacy-Recency Positioning

LLMs weight the beginning and end of context most heavily.

**Top of CLAUDE.md:** Project identity + critical constraints
**Middle:** Commands, architecture, conventions
**Bottom:** Anti-patterns and common mistakes (things to avoid)

## 6. Progressive Disclosure in Practice

```
CLAUDE.md (always loaded, <200 lines)
  └── references via file paths
       └── detailed docs (loaded on demand)

.claude/rules/*.md (loaded by paths match)
  └── context-specific instructions
```

This means CLAUDE.md should NOT contain:
- Full API endpoint documentation
- Complete style guide
- Exhaustive dependency explanations
- Step-by-step deployment procedures

These belong in referenced files or rules.

## 7. Command Verification

Never guess commands. Extract them from:
- `package.json` scripts
- `Makefile` targets
- `pyproject.toml` [tool.*] sections
- `Cargo.toml` metadata
- CI/CD workflow files (the CI knows the real commands)
- README "Getting Started" sections

If a command can't be verified, mark it with a comment or omit it.
