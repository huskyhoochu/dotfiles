# Improvement Mode Checklist

When existing CLAUDE.md or `.claude/rules/` files are found, use this checklist to systematically identify what needs updating. Categorize findings as **Stale**, **Missing**, or **Violation**.

## Stale — Content that no longer matches reality

| Check | How to verify |
|-------|--------------|
| Referenced file paths exist | `Glob` each path mentioned in docs |
| Build/test/lint commands work | Compare against current `package.json` scripts, `Makefile` targets, or CI workflow files |
| Tech stack description is current | Compare listed dependencies against current config files (package.json, pyproject.toml, etc.) |
| Directory structure matches | `ls` the directories described in the architecture section |
| Rules file glob patterns match files | `Glob` each pattern in `.claude/rules/` frontmatter — empty results mean stale scope |

## Missing — Information the docs should have but don't

| Check | Signal |
|-------|--------|
| New packages/tools added since docs were written | Dependencies in config files not mentioned in docs |
| Undocumented conventions | Patterns visible in code (from Step 1b) that docs don't cover |
| Missing commands | CI workflow steps or package.json scripts not in Commands section |
| No architecture section | Project has >20 files but docs lack directory overview |
| No file references | Project has docs/ or detailed READMEs that aren't linked |
| Git workflow not captured | Conventional commits or branch patterns visible in history but not documented |

## Violation — Context engineering principles broken

| Check | Criteria |
|-------|---------|
| CLAUDE.md exceeds 200 lines | Count lines — if over, identify content to move to rules files or references |
| Generic advice present | Search for phrases like "best practices", "clean code", "maintainable", "meaningful names" |
| Duplicated content | Same information in both CLAUDE.md and a rules file |
| Instructions not in English | Rules and directives should be in English for LLM compliance |
| No progressive disclosure | Everything crammed into CLAUDE.md instead of using rules files for scoped context |
| Primacy-recency violation | Critical constraints buried in the middle instead of at top/bottom |
| Identity framing missing | Rules use negation ("don't", "never") instead of identity statements ("this project uses X") |

## Presenting Improvements

Group findings by category and severity:

```
## Improvement Plan

### Stale (3 items)
- `npm run build` → should be `pnpm build` (verified in package.json)
- `src/utils/` referenced but renamed to `src/lib/`
- React 17 mentioned but project is on React 19

### Missing (2 items)
- No mention of Vitest (detected in config, replaces Jest)
- Conventional commits pattern visible but undocumented

### Violations (1 item)
- CLAUDE.md is 247 lines — move testing conventions to `.claude/rules/testing.md`
```

Always show the specific evidence for each finding so the user can verify before approving changes.
