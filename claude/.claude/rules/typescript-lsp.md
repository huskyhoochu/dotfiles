---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript LSP Usage

You have access to a TypeScript LSP server. Use it instead of guessing types or grepping for symbols.

## When to use each operation

| Task | Operation | Why not Grep/Read |
|------|-----------|-------------------|
| Check a variable/function type | `hover` | Grep can't show inferred types |
| Find all usages before refactoring | `findReferences` | Grep matches names, LSP matches the exact symbol |
| Trace what a function calls | `outgoingCalls` | Grep can't distinguish call sites from declarations |
| Understand file structure | `documentSymbol` | Faster than reading the whole file |
| Find callers of a function | `incomingCalls` | Grep can't handle re-exports or aliases |

## Preferred workflows

- **Before renaming/deleting**: `findReferences` to check impact scope.
- **Reading unfamiliar code**: `documentSymbol` first for overview, then `hover` on key symbols.
- **Debugging type errors**: `hover` on both sides of the mismatch to see actual inferred types.
- **Understanding dependencies**: `outgoingCalls` to see what a function depends on.

## Limitations to know

- `goToDefinition` may fail on external package symbols (e.g., `View` from react-native). Fall back to Grep for `.d.ts` lookups.
- `incomingCalls` won't catch dynamic invocations (JSX rendering via Expo Router, lazy imports).
- `workspaceSymbol` returns all symbols unfiltered — prefer `Grep` for targeted name searches.
