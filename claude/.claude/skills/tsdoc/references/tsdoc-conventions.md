# TSDoc Conventions

This project uses **TSDoc** for TypeScript code documentation.
TSDoc is the TypeScript documentation standard maintained by Microsoft ([tsdoc.org](https://tsdoc.org)).

## Guiding Principles

1. **TypeScript is the type system** — TSDoc provides *semantic meaning*, not type information.
2. **All or nothing for `@param`** — If any parameter needs explanation, document ALL parameters. If none do, omit `@param` entirely.
3. **Describe intent, not mechanics** — Focus on *why* and *what*, not *how* (the code shows how).

## General Format

```ts
/** Single-line for simple symbols. */
export const MAX_RETRY = 3;
```

```ts
/**
 * Multi-line for functions and complex symbols.
 *
 * @param email - User's email address
 * @param password - Plain-text password to verify
 * @returns JWT access token string
 * @throws {AuthError} INVALID_CREDENTIALS if credentials don't match
 */
export async function login(email: string, password: string): Promise<string> {
```

## Tag Reference

| Tag | When to use | Format |
|-----|-------------|--------|
| `@param` | See "All or Nothing" rule below | `@param name - Description` |
| `@returns` | Non-obvious return values | `@returns Description` |
| `@throws` | Intentional errors callers should handle | `@throws {ErrorClass} CODE description` |
| `@example` | Non-trivial usage only | Code block with realistic usage |
| `@see` | Cross-reference related symbols | `@see symbolName` or `@see filename` |
| `@remarks` | Extended discussion (separate from summary) | Free-form text |

### `@param` — All or Nothing Rule

The `@param` tag follows the **all-or-nothing** principle (consistent with `eslint-plugin-jsdoc/require-param`):

**Include `@param` for ALL parameters** when:
- Any parameter name doesn't clearly convey what to pass
- The function has 3+ parameters
- Parameters have constraints not expressed by the type (e.g. "must be positive", "min 8 chars")
- The function is a public API or factory

**Omit `@param` entirely** when:
- All parameter names + types are self-explanatory (e.g. `ok(data: T)`, `err(error, message)`)
- The summary sentence already explains the parameters sufficiently

```ts
// GOOD: All params documented (one needed explanation, so all are listed)
/**
 * Sign a JWT token with HS256 algorithm and 7-day expiration.
 *
 * @param payload - Claims to encode (sub, role)
 * @returns Signed JWT string
 */
export async function signJwt(payload: JwtPayload): Promise<string> {

// GOOD: No @param (names + types are self-explanatory)
/** Wrap a successful result in the standard API response envelope. */
export function ok<T>(data: T): ApiResponse<T> {

// BAD: Partial @param (some documented, some not)
/**
 * @param email - The user's email
 */
export async function login(email: string, password: string): Promise<string> {
```

### `@returns` — Only When Non-Obvious

- Omit for void functions, simple getters, and trivially obvious returns.
- Include when the return value involves transformations, conditional logic, or side effects.
- For generator functions, use `@yields` instead.

```ts
// GOOD: @returns adds information beyond the type
/** @returns Cached result if available; otherwise performs a network call. */

// BAD: @returns just restates the type
/** @returns The string value. */
```

### `@throws` — Intentional Contract Errors Only

- Document errors that callers are **expected to handle**.
- Do NOT exhaustively list all possible runtime failures (OOM, network errors, etc.).
- Use `@throws` multiple times for different error conditions.

```ts
/**
 * @throws {NotFoundError} RESOURCE_NOT_FOUND if entity doesn't exist
 * @throws {ValidationError} INVALID_INPUT if input fails validation
 */
```

## Rules

1. **No type annotations in TSDoc** — TypeScript provides all type information. Never write `@param {string}`. (Enforced by `eslint-plugin-jsdoc/no-types` in TS mode.)
2. **No `@type` tags** — Redundant with TypeScript declarations.
3. **No `@typedef`** — Use TypeScript interfaces/types instead.
4. **No `@callback`** — Use TypeScript function types instead.
5. **Hyphen separator required** — Use `@param name - Description` (TSDoc standard). Not `@param name Description`.
6. **Tag order** — `@param` → `@returns` → `@throws` → `@example` → `@see`.
7. **English only** — All TSDoc content in English.

## Per-Category Examples

### Route Handler

```ts
/**
 * Register a new user account.
 *
 * Validates the input, creates the user record,
 * and returns an authentication token.
 *
 * @throws {NotFoundError} RESOURCE_NOT_FOUND if referenced entity doesn't exist
 * @throws {ConflictError} EMAIL_ALREADY_EXISTS if email is taken
 */
router.post('/register', async (req, res) => {
```

### Middleware Factory

```ts
/**
 * Create a role-based authorization middleware.
 *
 * Checks the authenticated user's role against the required role
 * and returns 403 Forbidden if unauthorized.
 *
 * @param role - Required role to access the route
 * @returns Middleware function
 */
export function requireRole(role: UserRole) {
```

### Database Model / Schema

```ts
/** Users of the platform. Created during registration. */
export const users = defineTable('users', {
```

### Constant Object

```ts
/** HTTP status code constants for the response API. */
export const HttpStatus = {
```

### Error Code Enum-like Object

```ts
/**
 * Domain-namespaced error codes for API error responses.
 *
 * Namespaces: `AUTH_` (authentication), `USER_` (user management),
 * `SERVER_` (server-level errors).
 */
export const ErrorCode = {
```

### Interface

```ts
/**
 * Standard API response envelope.
 *
 * On success: `data` contains the result, `error` and `message` are null.
 * On failure: `data` is null, `error` contains an error code, `message` has detail.
 */
export interface ApiResponse<T> {
```

### Utility Function (no @param needed)

```ts
/** Generate a unique identifier for use as a public entity ID. */
export function generatePublicId(): string {
```

### Function with @param (all params documented)

```ts
/**
 * Create and configure the application with all routes and middleware.
 *
 * @param db - Database instance injected into request context
 */
export function createApp(db: Database) {
```

### Class with @throws

```ts
/**
 * Domain-specific error with a machine-readable error code.
 *
 * Thrown to signal expected failures that the global error handler
 * logs and returns as structured API errors.
 */
export class DomainError extends Error {
```

## What NOT to Document

- Re-exports and barrel files (`export * from`)
- Type aliases that are self-explanatory (`export type ID = string`)
- Individual properties of well-documented interfaces
- Schema declarations that are self-documenting (e.g. Zod, Yup)
- Test helper functions
