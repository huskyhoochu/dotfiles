---
name: tsdoc
description: "Add TSDoc comments to exported symbols across the project. By default scans uncommitted/untracked files; use --all to scan the entire codebase. Use when the user wants to document code with TSDoc or invokes /tsdoc."
user_invocable: true
argument: "[--all] [file-or-directory-path]"
---

# TSDoc Documentation Skill

Add TSDoc comments to all exported symbols in TypeScript source files.
Follows the [TSDoc standard](https://tsdoc.org) — no type annotations in tags, hyphen separators required.

## Scope Selection

Determine which files to process based on the argument:

1. **Specific path given** — Process only that file or directory
2. **`--all` flag** — Scan entire codebase: `**/*.ts` and `**/*.tsx`
3. **Default (no args)** — Scan only changed files:
   ```bash
   # Uncommitted changes (staged + unstaged)
   git diff --name-only HEAD -- '*.ts' '*.tsx'
   # Untracked files
   git ls-files --others --exclude-standard -- '*.ts' '*.tsx'
   ```

### Exclusions

Always skip:
- Test files: `**/__tests__/**`, `**/*.test.ts`, `**/*.spec.ts`
- Generated files: `**/dist/**`, `**/build/**`, `**/node_modules/**`
- Config files: `*.config.ts`
- Declaration files: `**/*.d.ts`

## Process

For each file in scope:

1. **Read the file** and identify all exported symbols using LSP `documentSymbol`
2. **Skip symbols that already have TSDoc** (lines immediately above starting with `/**`)
3. **Write TSDoc** for each undocumented exported symbol following the conventions in [references/tsdoc-conventions.md](references/tsdoc-conventions.md)
4. **Run the project's lint/format command** after all files are processed to ensure formatting is preserved

## Symbol Coverage

Document these exported symbol types:

| Symbol Type | TSDoc Required |
|------------|---------------|
| `export function` | Yes — describe purpose, params, return, throws |
| `export const` (function expression) | Yes — same as function |
| `export const` (object/config) | Yes — describe purpose and shape |
| `export interface` / `export type` | Yes — describe purpose and usage context |
| `export class` | Yes — describe purpose; document public methods |
| `export enum` | Yes — describe purpose |
| Internal (non-exported) symbols | No — skip unless complex logic warrants it |

## Writing Style

- **Concise**: One sentence for simple utilities. Don't pad with obvious information.
- **No type duplication**: TypeScript already has the types. Never write `@param {string} name` (TSDoc forbids this).
- **All-or-nothing `@param`**: If any parameter needs explanation, document ALL parameters. If none do, omit `@param` entirely.
- **English**: All TSDoc content in English.
- **Hyphen separator**: Use `@param name - Description` with a hyphen (TSDoc standard).
- **Tag order**: `@param` → `@returns` → `@throws` → `@example` → `@see`.
- **@returns only when non-obvious**: Skip for simple getters. Include for transformations.
- **@throws for intentional errors only**: Document thrown errors that callers should handle.
- **@example sparingly**: Only for non-trivial APIs or functions with tricky usage.

## Output

After processing, report:
- Number of files scanned
- Number of symbols documented
- Any files skipped and why
