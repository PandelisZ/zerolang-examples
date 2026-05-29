# zerolang 0.2.0 — capability notes (darwin-arm64 host)

These notes were derived empirically against `zero 0.2.0` while building this
corpus. zerolang is experimental and changes fast; re-verify with `zero check`
before trusting any of this. The authoritative docs are `zero skills get
language` / `zero skills get stdlib` / `zero skills get testing`.

The corpus is written to a deliberately conservative subset so that **every
project passes `zero check`, `zero test`, AND `zero run`** on this host. There
are three very different "engines" with three different feature sets.

## 1. `zero check` — full typechecker

Validates the whole language. This is the primary signal for the corpus: if a
program is well-formed zerolang, `zero check` passes. All ten projects pass.

## 2. `zero test` — the test interpreter

Runs `test { ... }` blocks in a small interpreter. It is **much** more limited
than the typechecker. Empirically it supports:

- `fn` calls, **recursion**, `if` / `else`, `return`
- integer/bool arithmetic and comparisons, typed literals (`42_u32`)

It does **not** support (the test is reported as "unknown function" or
"direct runner does not support this ..."):

- `while` loops
- any `std.*` helper (including `std.mem.len`, `std.mem.span`)
- span / array **indexing**
- `match`, `as` casts, custom `type` / `choice` / `enum` values

**Consequence:** unit-tested helpers must be recursive, integer-only, and
cast-free. In this corpus those live in `src/lib.0` (e.g. `is_prime`,
`apply_op`, `cmp_u32`, `rot13_byte`). String/byte processing is verified by
`zero run` instead.

## 3. `zero run` / `zero build` — the direct AArch64 backend

Compiles to a native executable. Supports a "Mach-O direct-backend subset".
What works (everything the tools actually use):

- top-level **functions only**
- primitives, `Bool`, `String`, fixed arrays `[N]u8` / `[N]u32` / `[N]usize`
  / `[N]i32`, `Span<u8>` / `MutSpan<u8>`, slicing `buf[a..b]`, indexing
- `let` / `var`, `while`, `if` / `else`, arithmetic, `as` casts
- `world.out.write(...)`, `world.err.write(...)` — `String` or `Span<u8>`
- `std.args.len()`, `std.args.get(i) -> Maybe<String>` (`.has` / `.value`)
- `std.mem.span` / `std.mem.len` / `std.mem.eql`
- `std.str.contains` (and similar pure byte helpers)
- calling helper functions, including helpers that themselves call
  `std.args.get` / `std.mem.*`

What does **not** build/run on this backend (each is a hard `BLD004`):

| Construct | Status |
|---|---|
| top-level `const` / `type` / `enum` / `choice` | unsupported ("declarations other than functions") |
| custom `type` as a function parameter/return | unsupported |
| `World` as a parameter to a helper function | unsupported — **all IO must be inline in `main`** |
| `break` | unsupported (it *checks* fine, then fails to run) |
| fixed arrays of `i64` (`[N]i64`) | unsupported — use `i32` / `u32` |
| `std.parse.*`, `std.math.*`, `std.rand.*`, `std.codec.*` | unsupported (Maybe-payload / runtime not emitted) |
| `std.fs`, `std.proc`, `std.net` | unsupported (no file/stdin/process runtime) |

### Sharp edges that cost real debugging time

- **No `World` in helpers.** Factor pure logic out; do every `world.out.write`
  in `main`. (`zfactor` was rewritten for this.)
- **No `break`.** Use a `var scanning: Bool` guard on the `while` instead.
- **Don't reuse a variable name with two different types in one function.**
  `let a: Maybe<String>` and later `var a: usize` in the same `fn` makes the
  backend reject an unrelated `.has` access. Use distinct names
  (`fa`/`pos`, `lhs`/`rhs`). This bit both `zsort` and `zcalc`.
- **Keep stack arrays modest.** A `[4096]u8` local segfaulted at runtime;
  `[256]` is fine. Declare one buffer and reuse it.
- **`set`, `err` are reserved words** (the latter from `rescue x err y`).
  Don't use them as identifiers (`delset`, `failed`).
- **No stdin / no file I/O at runtime.** Tools take their input as
  command-line arguments; file-reading variants compile under `zero check`
  but cannot run on this backend yet.

## Standard library helpers that exist (from the 0.2.0 binary)

`std.args`, `std.env`, `std.mem`, `std.str`, `std.parse`, `std.math`,
`std.codec`, `std.crypto`, `std.json`, `std.time`, `std.rand`, `std.io`,
`std.fs`, `std.path`, `std.net`, `std.http`, `std.proc`.

Only `std.args`, `std.mem`, and `std.str` (pure parts) are used here because
they are the subset the direct backend can currently emit. The rest typecheck
but won't `run` on this host — a natural axis for editing experiments.
