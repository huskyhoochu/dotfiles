# SKILL.md Template

Use this as a starting scaffold. Adapt structure to the skill's complexity.

## Minimal Skill (instructions only)

```markdown
---
name: {skill-name}
description: |
  {What this skill does. When to use it. Be specific about trigger scenarios.}
---

# {Skill Title}

{Brief overview of what this skill accomplishes.}

## When to Use

{Explicit conditions for activation.}

## Workflow

### Step 1 — {First Step}
{Instructions}

### Step 2 — {Second Step}
{Instructions}

## Quality Checklist

- [ ] {Verification item 1}
- [ ] {Verification item 2}
```

## User-Invocable Skill (slash command)

```markdown
---
name: {skill-name}
description: |
  {Description with trigger keywords.}
user_invocable: true
argument: "{argument-format-hint}"
---

# {Skill Title}

{Overview}

## Arguments

Parse the user's argument: {describe expected format}

## Workflow

{Steps}
```

## Skill with Scripts

```markdown
---
name: {skill-name}
description: |
  {Description}
compatibility: Requires {dependencies}
---

# {Skill Title}

{Overview}

## Available Scripts

- **`scripts/{name}.py`** — {purpose}
- **`scripts/{name}.sh`** — {purpose}

## Workflow

1. Run the {first} script:
   ```bash
   python3 scripts/{name}.py --arg value
   ```

2. Process results...
```

## Skill with References (Progressive Disclosure)

```markdown
---
name: {skill-name}
description: |
  {Description}
---

# {Skill Title}

{Overview — keep SKILL.md concise}

## Workflow

### Step 1 — {Step}
Read `references/{topic}.md` for {specific guidance}.

### Step 2 — {Step}
{Instructions referencing loaded knowledge}

## Reference Files

| File | When to load | Content |
|------|-------------|---------|
| `references/{a}.md` | Step 1 | {topic} |
| `references/{b}.md` | Step 3 | {topic} |
```
