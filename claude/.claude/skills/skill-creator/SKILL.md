---
name: skill-creator
description: |
  Create new Agent Skills (SKILL.md + directory structure) from a user's
  feature description. Use when the user wants to build a custom skill,
  slash command, or reusable agent capability. Handles requirement gathering,
  skill architecture, SKILL.md generation, scripts, and references.
  Invoke with /skill-creator <description>.
user_invocable: true
argument: "<feature-description>"
---

# Agent Skill Creator

Create production-quality Agent Skills from a user's feature description. Follows the open Agent Skills specification (https://agentskills.io).

## Core Principles

1. **Skills encode expertise** — capture domain-specific procedures, not generic knowledge the agent already has.
2. **Progressive disclosure** — SKILL.md stays concise (<500 lines). Heavy content goes to `references/`.
3. **Procedures over declarations** — "Run X, then check Y" beats "X should be done properly."
4. **Opinionated defaults** — provide sensible defaults instead of presenting option menus.
5. **All prompts and instructions in English** — for maximum agent compliance.

## Workflow

### Step 0 — Parse Request

Read the user's feature description from the argument. Identify:
- **What** the skill should do (core capability)
- **When** it should trigger (activation context)
- **How complex** it is (instructions-only vs scripts vs references)

If the description is too vague to proceed, ask ONE focused clarifying question. Do not ask a laundry list.

### Step 1 — Architecture Decision

Based on the request, determine the skill's shape:

| Complexity | Structure | When to use |
|-----------|-----------|-------------|
| **Simple** | SKILL.md only | Pure instructions, no code needed |
| **Moderate** | SKILL.md + `references/` | Instructions with domain knowledge that would bloat SKILL.md |
| **Complex** | SKILL.md + `scripts/` + `references/` | Needs executable code (API calls, data processing, etc.) |

Read `references/spec-summary.md` for the full specification rules.
Read `references/skill-template.md` for structural templates.

Decide:
- Is this **user-invocable** (slash command)? → needs `user_invocable: true` + `argument` field
- Does it need **scripts**? → plan script names and purposes
- Does it need **reference files**? → plan file names and content scope
- What **tools** does it primarily use? → consider `allowed-tools` if applicable

Present a brief architecture summary to the user:
```
Skill: {name}
Type: {simple/moderate/complex}
Directory:
  {name}/
  ├── SKILL.md
  ├── scripts/{files if any}
  └── references/{files if any}
Slash command: /{name} {args if any}
```

Get confirmation before proceeding. If the user suggests changes, adapt.

### Step 2 — Draft the Skill Name and Description

Generate a `name` that:
- Is lowercase, hyphenated, 1-64 chars
- Is descriptive but concise (e.g., `csv-analyzer`, `pr-reviewer`, `api-scaffolder`)
- Will become the directory name

Generate a `description` that:
- Uses imperative phrasing: "Use this skill when..."
- Focuses on user intent, not implementation details
- Lists non-obvious trigger scenarios
- Stays under 1024 characters
- Is specific enough to trigger correctly, broad enough to not miss relevant tasks

**Bad:** "Helps with data."
**Good:** "Analyze CSV and Excel files to produce summary statistics, charts, and cleaned datasets. Use when the user mentions data analysis, spreadsheets, CSV files, or asks to visualize tabular data — even if they don't explicitly say 'CSV' or 'data analysis.'"

### Step 3 — Write the SKILL.md Body

Structure the body following these patterns from the spec's best practices:

**Always include:**
1. A one-line overview after the heading
2. A "When to Use" or context section (if not fully covered by `description`)
3. A step-by-step workflow with numbered steps
4. A quality checklist at the end

**Use these proven patterns where applicable:**

- **Gotchas section** — known pitfalls and how to avoid them
- **Templates** — for structured output formats
- **Checklists** — for multi-step verification
- **Validation loops** — plan → validate → execute cycles
- **File references** — point to `references/*.md` for heavy content

**Writing rules:**
- Write ALL instructions and prompts in English
- Use procedures ("Run X, then check Y"), not declarations ("X should be clean")
- Provide defaults, not menus — make opinionated choices
- Match specificity to fragility — be precise where errors are costly, loose where they aren't
- Add what the agent lacks, omit what it knows — don't teach basic programming
- Keep SKILL.md under 500 lines — move reference material to `references/`

### Step 4 — Create Scripts (if needed)

For skills that need executable code:

1. Write self-contained scripts with inline dependency declarations
2. Include `--help` output with usage examples
3. Use structured output (JSON) over whitespace-aligned text
4. Avoid interactive prompts — use CLI arguments
5. Write helpful error messages that suggest corrections
6. Reference scripts from SKILL.md with exact invocation commands

Script language preference:
- **Python** — default for data processing, API calls, complex logic. Use `uv run` for deps.
- **Bash** — for simple file operations, git workflows, CLI wrappers
- **Node/Deno** — for web-related tooling, npm ecosystem integration

### Step 5 — Create Reference Files (if needed)

For skills with reference content:

1. One file per focused topic (e.g., `references/api-patterns.md`, `references/error-codes.md`)
2. Keep each file focused — agents load on demand, smaller = better
3. Reference from SKILL.md with clear "when to read" guidance:
   ```
   Read `references/api-patterns.md` before generating API endpoints.
   ```

### Step 6 — Write Files

Determine the installation path. Default: `{cwd}/.claude/skills/{skill-name}/`

If the user specifies a different location, use that.

Write all files:
1. `SKILL.md` (always)
2. `scripts/*` (if applicable)
3. `references/*` (if applicable)

### Step 7 — Verify

After writing, verify:
- [ ] `name` field matches directory name
- [ ] `name` follows validation rules (lowercase, hyphens, no leading/trailing hyphen)
- [ ] `description` is under 1024 characters
- [ ] `description` uses imperative phrasing and covers trigger scenarios
- [ ] SKILL.md is under 500 lines
- [ ] All file references point to files that exist
- [ ] Scripts are executable and have clear usage docs
- [ ] No generic filler ("follow best practices", "handle errors appropriately")
- [ ] Instructions are in English

Report the created files and their sizes to the user.

## Edge Cases

- **User wants to modify an existing skill**: Read the existing SKILL.md first, understand its structure, then apply targeted edits.
- **User's request maps to multiple skills**: Suggest splitting. One skill = one coherent workflow.
- **User's request is too broad**: Narrow scope by asking "What's the single most important thing this skill should do?"
- **User provides reference material** (docs, APIs, runbooks): Incorporate into `references/` files, synthesize procedures into SKILL.md.
