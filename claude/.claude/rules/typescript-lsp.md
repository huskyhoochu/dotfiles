# TypeScript LSP — Mandatory Usage Rules

You have a TypeScript LSP server. LSP queries resolve in ~50ms with exact symbol accuracy. Grep takes 30-60s and returns noisy text matches including comments, strings, and unrelated names. LSP uses 75% fewer tokens per query because it returns only exact matches — not entire file scans. Use LSP by default; fall back to Grep only when LSP cannot help.

## MUST — Required before specific actions

- **Before modifying or deleting** a function, type, variable, or export:
  → `findReferences` on the symbol first.
  _Why: Grep matches names across comments/strings/CSS — LSP matches the actual symbol across re-exports and aliases. Skipping this causes broken references that require multiple fix cycles._

- **When you need to know a type** (variable type, return type, parameter type):
  → `hover` on the symbol.
  _Why: TypeScript infers complex types (unions, generics, mapped types) that don't appear in source text. Grep cannot show inferred types — only `hover` resolves the actual type the compiler sees._

- **When a type error occurs** or the user reports one:
  → `hover` on both sides of the mismatch before attempting a fix.
  _Why: Type errors often involve inferred types that differ from what the source text suggests. Fixing without seeing actual types leads to trial-and-error cycles that waste tokens._

- **When first reading an unfamiliar file** (a file you haven't seen in this session):
  → `documentSymbol` first, then Read selectively.
  _Why: Reading a full file consumes 500-2000 tokens. `documentSymbol` gives you the structural overview in ~50 tokens, so you only Read what matters._

## NEVER

- Never grep for a type definition when `hover` resolves it in one call — grepping pulls in multiple candidate files and wastes 4x the tokens.
- Never rename or delete a symbol without `findReferences` — grep misses re-exports, aliases, and barrel files, causing silent breakage.
- Never guess a return type from reading a function body — the compiler's inferred type may differ from what the code appears to return.

## Additional operations — use when relevant

| Situation | Operation |
|-----------|-----------|
| Trace what a function calls internally | `outgoingCalls` |
| Find all callers of a function | `incomingCalls` |
| Navigate to a symbol's source definition | `goToDefinition` |

## When to use Grep instead

- `goToDefinition` fails on external package symbols (e.g., `@nestjs/*` decorators) → Grep `.d.ts` files.
- `incomingCalls` misses dynamic invocations (lazy imports, reflection-based DI) → Grep as supplement.
- Searching for a literal string pattern (log messages, config keys, CSS classes) → Grep is the right tool.
- `workspaceSymbol` returns too many results → Grep with targeted patterns.
