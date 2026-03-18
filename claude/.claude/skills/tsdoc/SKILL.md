---
name: tsdoc
description: "Add TSDoc comments to exported symbols across the project. By default scans uncommitted/untracked files; use --all to scan the entire codebase. Use when the user wants to document TypeScript code, add comments or documentation to functions/types/exports, write JSDoc/TSDoc, or mentions code documentation for .ts/.tsx files — even if they just say 'add comments', 'document this', or 'JSDoc'. Also triggers on /tsdoc."
user_invocable: true
argument: "[--all] [--update] [file-or-directory-path]"
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

1. **Survey the file** — run LSP `documentSymbol` to get the structural overview before reading the full file
2. **Identify exported symbols** — read only the relevant sections, not the entire file if it's large
3. **Resolve actual types** — run LSP `hover` on each exported symbol to see the compiler's inferred type. Do not guess types from reading the function body — the inferred type may differ from what the code appears to return
4. **Skip already-documented symbols** — lines immediately above starting with `/**`. If `--update` flag is set, also check existing TSDoc against conventions (hyphen separators, no type annotations, all-or-nothing `@param`) and fix violations
5. **Write TSDoc** for each undocumented symbol following [references/tsdoc-conventions.md](references/tsdoc-conventions.md), using the resolved type information from step 3
6. **Run the project's lint/format command** after all files are processed to ensure formatting is preserved

### Batch Processing

When processing many files (`--all` or a large directory):

- **Chunk by directory** — process one directory at a time to stay within context limits
- **Use subagents for parallelism** — spawn one subagent per directory chunk when the file count exceeds ~10 files. Each subagent receives the conventions reference and processes its chunk independently
- **Report progress** — after each chunk, update the user on files scanned and symbols documented

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

## Edge Cases

- **`.js` files** — out of scope. This skill targets TypeScript (`.ts`, `.tsx`) only. If the user asks for JSDoc on `.js` files, note the distinction and handle inline without this skill.
- **`export default`** — document the default export like any named export. Place TSDoc above the `export default` statement.
- **Re-exports and barrel files** (`export * from`, `export { X } from`) — skip. Document at the source, not the re-export.
- **Monorepo with multiple `tsconfig.json`** — LSP resolves based on the nearest tsconfig. When processing across project boundaries, note which tsconfig context is active.

## Output

After processing, report:
- Number of files scanned
- Number of symbols documented (new + updated if `--update`)
- Any files skipped and why
