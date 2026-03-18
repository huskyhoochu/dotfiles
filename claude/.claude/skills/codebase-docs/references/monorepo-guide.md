# Monorepo Documentation Guide

When the codebase is a monorepo, documentation needs a layered approach — a top-level index plus per-package context.

## Detection

A project is a monorepo if any of these exist:
- `pnpm-workspace.yaml`
- `workspaces` field in root `package.json`
- `turbo.json` or `nx.json`
- `lerna.json`
- Multiple `package.json` / `Cargo.toml` / `go.mod` files at different depths

## Documentation Structure

```
repo/
├── CLAUDE.md                    # Top-level index (100-150 lines)
├── .claude/rules/
│   ├── shared-conventions.md    # Cross-package rules
│   └── package-*.md             # Per-package rules (scoped by paths)
├── packages/
│   ├── api/
│   │   └── CLAUDE.md            # Package-specific docs (optional)
│   └── web/
│       └── CLAUDE.md            # Package-specific docs (optional)
```

## Top-Level CLAUDE.md

The root CLAUDE.md for a monorepo should focus on:

1. **Workspace overview** — list packages with one-line descriptions
2. **Shared commands** — root-level build/test/lint that run across packages
3. **Inter-package dependencies** — which packages depend on which (brief diagram or list)
4. **Shared conventions** — naming, versioning, commit format that apply everywhere
5. **Per-package pointers** — "For API details, see `packages/api/CLAUDE.md`"

Avoid listing every package's internal commands at the top level. That's what per-package docs are for.

## Per-Package CLAUDE.md

Only create per-package CLAUDE.md files when a package has:
- Its own build/test commands different from root
- Unique conventions not shared with other packages
- Enough complexity to warrant separate docs (>20 files)

Per-package docs should NOT repeat root-level conventions. Reference them: "Follows root conventions. Additional rules below."

## .claude/rules/ for Monorepos

Use `paths` scoping to target specific packages:

```yaml
---
paths:
  - "packages/api/**/*"
---
# API Package Rules
- All endpoints return `{ data, error, meta }` envelope
- Use Zod schemas for request validation
```

This is more maintainable than per-package CLAUDE.md files for simple rule sets, because rules files load automatically by path match.

## Decision: rules/ Files vs Per-Package CLAUDE.md

| Situation | Use |
|-----------|-----|
| 2-5 rules specific to a package | `.claude/rules/package-name.md` |
| Extensive package-specific docs (commands, architecture, patterns) | Per-package `CLAUDE.md` |
| Conventions shared across 2-3 packages but not all | `.claude/rules/` with multi-path scope |
