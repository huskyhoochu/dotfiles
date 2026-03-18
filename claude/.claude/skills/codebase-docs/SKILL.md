---
name: codebase-docs
description: |
  Explore a workspace codebase and generate or improve CLAUDE.md and
  .claude/rules/ documentation. Analyzes directory structure, tech stack,
  conventions, and workflows to produce context-engineered documentation
  optimized for Claude's processing. Use this skill when the user wants to
  set up a project for Claude, initialize Claude context, create or update
  CLAUDE.md, document a codebase for Claude, migrate from .cursorrules,
  or mentions "codebase docs", "claude docs", "셋업", "문서화" in context
  of Claude configuration — even if they don't say "codebase-docs" explicitly.
  Invoke with /codebase-docs [path].
user_invocable: true
argument: "[workspace-path]"
---

# Codebase Documentation Generator

Explore a workspace and produce high-quality CLAUDE.md and `.claude/rules/` files that maximize Claude's effectiveness in that codebase. If documentation already exists, analyze and improve it.

## Core Principles

This skill applies context engineering best practices:

- **CLAUDE.md as index**: Teach Claude *how to find* information, not exhaustive docs. Keep under 200 lines.
- **English instructions**: Rules and directives in English for higher compliance. Comments and descriptions may use the user's language.
- **Progressive disclosure**: Core identity and must/never rules at top. Detailed guides linked via file references.
- **Identity over negation**: "You are a X that does Y" > "Don't do Z"
- **Surgical precision**: Every line must earn its place. No filler, no obvious statements.

## Workflow

### Step 0 — Determine Workspace & Language

If argument provided, use that path. Otherwise, use the current working directory.

Confirm the target workspace path with the user before proceeding. If the workspace is the same repo where this skill lives (dotfiles), warn and confirm — the user likely wants to target a different project.

Detect the user's language from conversation context. The generated CLAUDE.md body (rules, directives, commands) should be in English for higher LLM compliance. Project description and inline comments may use the user's language if the team is non-English.

### Step 1 — Codebase Exploration

Run these **in parallel** using the Explore agent or direct tools:

**1a. Structure scan:**
- `ls` top-level directory
- `Glob` for key config files: `**/package.json`, `**/Cargo.toml`, `**/go.mod`, `**/pyproject.toml`, `**/build.gradle*`, `**/pom.xml`, `**/Makefile`, `**/Dockerfile*`, `**/docker-compose*`, `**/.github/workflows/*`
- `Glob` for framework/tooling configs: `**/tsconfig*.json`, `**/vite.config.*`, `**/next.config.*`, `**/nuxt.config.*`, `**/tailwind.config.*`, `**/turbo.json`, `**/nx.json`, `**/pnpm-workspace.yaml`
- `Glob` for version/env files: `**/.nvmrc`, `**/.node-version`, `**/.python-version`, `**/.env.example`, `**/renovate.json`, `**/.github/dependabot.yml`
- `Glob` for existing docs: `**/CLAUDE.md`, `**/.claude/rules/*`, `**/.cursorrules`, `**/.github/CONTRIBUTING.md`

**1b. Convention detection:**
- `Grep` for test patterns: `describe(`, `it(`, `test(`, `#[test]`, `func Test`, `def test_`, `@Test`
- `Grep` for linting configs: `.eslintrc*`, `.prettierrc*`, `ruff.toml`, `.golangci*`, `clippy.toml`
- Check for CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`

**1c. Git history analysis:**
- `git log --oneline -20` — recent work direction and active areas
- `git log --format='%s' -50` — detect commit conventions (conventional commits, prefixes, etc.)
- `git log --diff-filter=M --name-only --pretty='' -50 | sort | uniq -c | sort -rn | head -10` — most actively modified files
- Branch naming patterns (`git branch -r | head -20`)

**1d. Read key files** (first 100 lines each, if they exist):
- README.md or README.*
- Main config file (package.json, pyproject.toml, etc.)
- Existing CLAUDE.md / .cursorrules (full read)

### Step 2 — Analysis & Classification

From Step 1 results, determine:

| Dimension | What to extract |
|-----------|----------------|
| **Tech stack** | Languages, frameworks, major dependencies |
| **Project type** | Library, CLI, web app, API, monorepo, etc. |
| **Build system** | Commands to build, test, lint, format |
| **Code organization** | src/ layout, module patterns, naming conventions |
| **Testing** | Framework, test location, run commands |
| **CI/CD** | Pipeline structure, deployment targets |
| **Existing conventions** | Code style, commit conventions, PR process |
| **Git workflow** | Commit message format, branch strategy, active areas |
| **Runtime versions** | Node/Python/Go versions pinned via version files |

**If `.cursorrules` found:** Parse and map existing rules into CLAUDE.md sections and `.claude/rules/` files. Present a migration plan showing where each rule maps to before proceeding. Delete `.cursorrules` only after user confirms the migration is complete.

Classify the codebase:

| Type | CLAUDE.md Focus |
|------|----------------|
| Monorepo | Top-level index + per-package rules (see `references/monorepo-guide.md`) |
| Library/SDK | API design conventions, test patterns, versioning |
| Web app | Component patterns, state management, routing |
| CLI tool | Command structure, argument parsing, output format |
| API service | Endpoint conventions, error handling, auth patterns |
| Config/dotfiles | Stow structure, platform specifics, deployment |

### Step 3 — Document Generation

Check if CLAUDE.md or `.claude/rules/` already exist.

**If no existing docs** → generate fresh using `references/claude-md-template.md`.

**If existing docs found** → enter Improvement Mode (see `references/improvement-checklist.md` for detailed criteria):
1. Read existing docs fully
2. **Staleness check** — verify all referenced file paths still exist, commands still work (check against current config files), and tech stack descriptions match current dependencies
3. **Gap analysis** — compare existing docs against Step 2 analysis. Look for missing sections, undocumented conventions, new packages/tools added since docs were written
4. **Context engineering audit** — check for violations: >200 lines, generic advice, duplicated content between CLAUDE.md and rules files, missing progressive disclosure, instructions not in English
5. **Rules scope validation** — verify `.claude/rules/` glob patterns match current directory structure
6. Present a categorized improvement plan (stale, missing, violations) with diffs to the user
7. Apply only after user confirmation

#### CLAUDE.md Structure (see `references/claude-md-template.md`)

The generated CLAUDE.md must follow this hierarchy:
```
1. Project identity (1-2 lines: what this is)
2. Essential commands (build, test, lint — copy-pasteable)
3. Architecture overview (directory map, key patterns)
4. Code conventions (naming, style, patterns to follow)
5. File references for deep dives ("see docs/api.md for endpoint specs")
```

#### .claude/rules/ Files

Generate context-specific rule files when the project warrants them:

| File pattern | When to create | Content focus |
|-------------|----------------|---------------|
| `*.md` (general) | Always, if project has specific patterns | Code style, naming, imports |
| `test-*.md` | Test files detected | Test conventions, mocking patterns |
| `api-*.md` | API routes detected | Endpoint patterns, error responses |
| `component-*.md` | UI components detected | Component structure, props, state |

Rules files use `paths` in frontmatter to scope activation:
```yaml
---
paths:
  - "src/components/**/*.tsx"
---
```

### Step 4 — Review & Output

Present the generated documentation to the user with:
1. Summary of what was detected
2. The complete CLAUDE.md content
3. Any `.claude/rules/` files with their glob scopes
4. Explanation of key decisions (why certain things were included/excluded)

Ask the user to confirm before writing files. Show the exact paths where files will be created.

### Step 5 — Write Files

After confirmation:
1. Write CLAUDE.md to the workspace root
2. Create `.claude/rules/` directory if needed
3. Write rule files
4. Report what was created

If files already existed, show the diff before overwriting.

## Quality Checklist

Before presenting output, verify:

- [ ] CLAUDE.md is under 200 lines
- [ ] All build/test/lint commands are real (verified from config files, not guessed)
- [ ] No obvious/generic advice ("write clean code", "follow best practices")
- [ ] Instructions are in English, concrete, and actionable
- [ ] File references point to files that actually exist
- [ ] Rules files have appropriate `paths` scopes
- [ ] No duplication between CLAUDE.md and rules files
