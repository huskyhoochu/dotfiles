---
paths:
  - "claude/**"
---

# Claude Code Settings and Skills

The `claude/` package stows Claude Code configuration to `~/.claude/`.

## Structure

- `claude/.claude/settings.json` — Claude Code settings (tracked)
- `claude/.claude/hooks/` — Claude Code hooks (tracked)
- `claude/.claude/CLAUDE.md` — global behavioral guidelines (tracked)
- `claude/.claude/skills/` — Agent Skills (tracked)

## What is excluded (see .gitignore)

- `claude/.claude.json`, `.claude.local.json` — local state, not portable
- `claude/.claude-code-router/` — runtime data
- `claude/**/CLAUDE.md` — auto-generated skill CLAUDE.md files (except `claude/.claude/CLAUDE.md`)

## Skills

Skills live in `claude/.claude/skills/<skill-name>/` with a `SKILL.md` entry point:

| Skill | Purpose |
|-------|---------|
| `web-research` | Multi-source web research (Perplexity, Tavily, Brave Search) |
| `web-design` | Interactive web design consultation |
| `codebase-docs` | Generate/improve CLAUDE.md and .claude/rules/ docs |

## Editing rules

- Keep `SKILL.md` files self-contained with references in `references/` subdirectory.
- The `.gitignore` pattern `claude/**/CLAUDE.md` excludes auto-generated files. Only `claude/.claude/CLAUDE.md` is tracked via negation.
- Do not add secrets or API keys to tracked files. Use `.zshenv` (gitignored) for environment variables.
