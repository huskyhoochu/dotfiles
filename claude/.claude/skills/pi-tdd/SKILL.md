---
name: pi-tdd
description: "Run a TDD role (test writer, auditor, implementer, review fix) as a pi run on DeepSeek V4.1 Flash 1017 through OpenRouter instead of a Claude subagent. Use when a project's TDD or ticket loop delegates code or test writing in pi mode (the owner names sonnet or pi mode per ticket or phase) — the main Claude session keeps the contract, the gates and the merge; pi writes the code. Project skills (cghds-erp `ticket`, cghds_ontology `ontology-tdd`) own the phase order and the role files; this skill owns how a phase is launched."
---

# TDD roles on pi + DeepSeek

Only the main session runs on Opus. TDD roles run in one of two modes the owner
names per ticket or per phase (2026-10-23): **pi mode**, this skill, on
`openrouter/deepseek/deepseek-v4.1-flash-1017`; or **sonnet mode**, the project's
role agent through the `Agent` tool with `model: "sonnet"`. When the owner has
named no mode for the ticket, ask once before the first TDD phase.

## Machine setup (already shared — do not duplicate)

- `~/.local/bin/pi`, config in `~/.pi/agent/` (symlinks into `~/dotfiles/pi/`),
  default provider openrouter, packages incl. pi-lens and pi-subagents.
- `OPENROUTER_API_KEY` in `~/.zshenv` is the owner's personal key (…6e3).
  Check `GET https://openrouter.ai/api/v1/credits` before the first run; stop
  before the balance would cross the floor kept in memory. Several sessions
  share the key, so the balance drops faster than one session's runs.
- Check the model resolves: `pi --list-models deepseek-v4.1-flash`.

## Launching one phase

From the project's worktree (never the shared main checkout), in the
background:

```sh
pi -p --no-session --mode json --model openrouter/deepseek/deepseek-v4.1-flash-1017 \
  --thinking medium --tools read,bash,edit,write \
  --append-system-prompt "$(awk 'n>=2; /^---$/{n++}' .claude/agents/<role>.md)" \
  "$(cat <task file>)" < /dev/null > <scratchpad>/<id>-<phase>.jsonl
```

- The system prompt is the project's role file body without frontmatter.
- A read-only role (auditor) gets `--tools read,bash`.
- `< /dev/null` is required, and never `--session-dir`: either leaves a run idle
  with no model call. See events in the log within seconds before calling it
  running.
- The task file carries: the phase, the worktree path, the contract and
  acceptance list, the test scope (only touched files, never the whole suite),
  "commit only, stage by path, never `git add -A`, no hook bypass, no push",
  and "a rule the contract does not state is not made — stop and report it".
- A run whose tests need a database gets every test-DB env var the suite reads
  exported by the launcher (all roles, e.g. an app-role URL too): a missing one
  makes those tests skip silently, not fail (cghds-erp #49).
- The worktree needs the project's installs first (`pnpm install
  --frozen-lockfile`, `uv sync --locked`, …) or the commit hooks fail.

## Reading the result

- The report is the last assistant `message_end` text in the JSONL.
- Cost = sum of `usage.cost.total` over assistant `message_end` events
  (about $0.002–0.006 a phase).
- Delete `.pi-lens-probe-home/` that pi-lens leaves in the worktree.
- Read every commit the run made before landing it; every auditor DELETE row
  or defect claim is checked against the file by the main session before it
  acts — the auditor has misread code (a row of thunks in `it.each` taken for
  a bug, cghds-erp #49).
