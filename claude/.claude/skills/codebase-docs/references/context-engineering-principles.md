# Context Engineering Principles for CLAUDE.md

Distilled from prompt engineering research. Apply these when generating or reviewing documentation. Principles are roughly ordered by how strongly 2026 evidence supports them.

## 0. Include Only Non-Inferable Content (the strongest, most overlooked principle)

A context file should hold only what the agent *cannot* discover by reading the repo: special tooling (`uv`, custom build/release steps), repo-specific conventions, and explicit "done" criteria. Everything else is not harmless filler.

Controlled studies in 2026 (ETH Zurich, "Evaluating AGENTS.md") found that adding such files *lowered* agent task success by ~2-3 percentage points and raised inference cost ~20% across benchmarks — and that LLM-generated files were the worst offenders, while sparse human-written files gave only a small gain. The mechanism isn't that agents ignore the file; they follow it faithfully (mentioning `uv` made the agent use it 1.6× more). The harm comes from redundant content adding tokens and unnecessary requirements without adding information.

**The test for every line:** "Could the agent figure this out by reading the code? If yes, delete it." This subsumes the older "index not manual" rule — an index of inferable facts is still waste.

## 1. CLAUDE.md Is an Index, Not a Manual

CLAUDE.md answers "how to find information" — not "here is all information."

**Good:** `Database schema: see prisma/schema.prisma`
**Bad:** [50 lines explaining the database schema]

**Good:** `Test with: npm test -- --grep "pattern"`
**Bad:** [Paragraph explaining what testing is and why it matters]

## 2. English Instructions, User's Language for Context

Write rules and directives in English. The defensible reason is empirical, not the folk "~80% of training data is English" claim (no primary source establishes that as the cause): NAACL 2025 ("English vs. Target-language Instructions") found that **complex instruction-following favors English** on instruction-tuned models — and CLAUDE.md is exactly a complex-instruction artifact. The effect is not universal: for *simple* tasks (e.g. classification) target-language instructions sometimes beat English. So keep directives in English, but don't over-claim — the advantage is task-dependent.

Acceptable in the user's language:
- Project description (if the team is non-English)
- Comments explaining domain-specific terms
- Output language directives ("Answer in Korean")

## 3. Identity Over Negation

Frame rules as identity statements, not prohibitions. This is a reasoned heuristic — no 2026 study directly measures positive-vs-negative framing in agent context files — but it lowers interpretation load by stating an actionable default instead of a thing to avoid. Treat it as a style preference, not a proven law; a short negation ("use pnpm, not npm") is fine when it's the clearest way to say it.

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

LLMs weight the beginning and end of context most heavily. "Lost in the middle" remains real in 2026 — reproductions on current frontier models (incl. 1M-token models) still show the U-shaped recall curve, so this is not obsoleted by large context windows.

**Top of CLAUDE.md:** Project identity + critical constraints
**Middle:** Commands, architecture, conventions
**Bottom:** Anti-patterns and common mistakes (things to avoid)

Caveat: positioning is a mitigation for *length*, not a license for it. If the file is short enough (Principle 0/1), there is no "middle" to get lost in, and this principle barely matters. Don't pad a file to exploit positioning — shorten it first.

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

## 8. AGENTS.md Is the Cross-Tool Standard

By 2026, `AGENTS.md` has become the convention shared across coding agents (Cursor, Codex, Gemini CLI, and 60k+ public repos). Documenting only into CLAUDE.md is a one-way migration that strands every other tool.

Default to a **hybrid layout**:
- `AGENTS.md` — canonical, tool-agnostic content (commands, conventions, "done" criteria).
- `CLAUDE.md` — thin Claude-specific layer that references it: `See @AGENTS.md`. Add only Claude-only material (skills, `.claude/rules/` pointers). When there's nothing Claude-specific, a relative-path symlink `CLAUDE.md -> AGENTS.md` is equivalent.

Practical note: Claude Code does not yet load `AGENTS.md` natively, so the explicit `@AGENTS.md` reference (verified in community testing to inject identically into the system prompt) or the symlink is what makes the hybrid work today. Single-file CLAUDE.md is still fine for Claude-only projects — don't force the split when the user doesn't want cross-tool support.

## 9. Behavior-Correcting Rules Belong in Skills/Hooks, Not Always-On Files

A standing line like "always write secure code" in CLAUDE.md is near-useless — it's an always-loaded instruction the model already weakly holds. The same compute spent as a *post-generation* review (a skill or hook that runs a checklist over the diff) is what actually changes behavior. Reserve always-on rules for tool/path constraints and non-inferable facts; route quality/security enforcement to skills and hooks.
