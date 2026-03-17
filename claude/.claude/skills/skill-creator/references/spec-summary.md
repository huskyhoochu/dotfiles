# Agent Skills Specification Summary

Reference: https://agentskills.io/specification

## Directory Structure

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation for progressive disclosure
└── assets/           # Optional: templates, static resources
```

## SKILL.md Format

YAML frontmatter followed by Markdown body.

### Required Frontmatter Fields

| Field | Constraints |
|-------|-------------|
| `name` | 1-64 chars. Lowercase letters, numbers, hyphens only. No leading/trailing/consecutive hyphens. Must match parent directory name. |
| `description` | 1-1024 chars. What the skill does + when to use it. |

### Optional Frontmatter Fields

| Field | Purpose |
|-------|---------|
| `license` | License name or reference to bundled file |
| `compatibility` | Environment requirements (max 500 chars) |
| `metadata` | Arbitrary key-value map (author, version, etc.) |
| `allowed-tools` | Space-delimited pre-approved tools (experimental) |
| `user_invocable` | If true, user can trigger via slash command |
| `argument` | Argument format hint when user_invocable is true |

### Name Validation Rules

- Only `a-z`, `0-9`, `-`
- Cannot start or end with `-`
- No consecutive `--`
- Must match parent directory name

### Description Best Practices

- Use imperative phrasing: "Use this skill when…"
- Focus on user intent, not implementation
- Be pushy — list contexts explicitly
- Include non-obvious trigger scenarios
- Max 1024 characters

## Body Content

No format restrictions. Recommended sections:
- Step-by-step instructions
- Examples of inputs and outputs
- Common edge cases
- Gotchas sections
- Checklists for multi-step workflows

## Progressive Disclosure

1. **Metadata** (~100 tokens): name + description loaded at startup
2. **Instructions** (< 5000 tokens recommended): full SKILL.md loaded on activation
3. **Resources** (as needed): scripts/, references/, assets/ loaded on demand

Keep SKILL.md under 500 lines. Move detailed reference material to separate files.

## File References

Use relative paths from skill root:
```markdown
See [the reference guide](references/REFERENCE.md) for details.
Run: `scripts/extract.py`
```

Keep references one level deep. Avoid nested chains.

## Scripts Best Practices

- Avoid interactive prompts — use CLI arguments
- Include `--help` documentation
- Write helpful error messages
- Use structured output (JSON preferred over whitespace-aligned)
- Make scripts self-contained with inline dependency declarations
- Reference scripts from SKILL.md with clear usage instructions

## Key Authoring Principles (from best-practices page)

1. **Start from real expertise** — don't generate generic procedures
2. **Add what the agent lacks, omit what it knows** — don't teach Python basics
3. **Design coherent units** — one skill = one workflow
4. **Aim for moderate detail** — not too vague, not over-specified
5. **Match specificity to fragility** — be precise where errors are costly
6. **Provide defaults, not menus** — opinionated choices reduce cognitive load
7. **Favor procedures over declarations** — "do X then Y" beats "X should be done"
8. **Use validation loops** — plan-validate-execute pattern
