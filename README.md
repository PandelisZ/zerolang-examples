# zerolang-examples

A corpus of ten small-to-medium CLI tools written in
[zerolang](https://github.com/vercel-labs/zerolang), each modeled on a familiar
open-source utility. The goal is a **diverse, realistic, editable base** of
zerolang programs to run editing experiments on top of — teaching/evaluating
models that modify `.0` projects and then verify their work with the `zero`
toolchain.

Every project is built to clear three bars on the current `zero 0.2.0` backend:

- `zero check`  — typechecks cleanly
- `zero test`   — its unit tests pass
- `zero run`    — it actually executes and produces correct output

See [`LANGUAGE_NOTES.md`](./LANGUAGE_NOTES.md) for the empirically-derived
0.2.0 capability matrix and the sharp edges that shaped the code style.

## Quick start

```sh
scripts/setup.sh                 # install the `zero` toolchain
export PATH="$HOME/.zero/bin:$PATH"
scripts/verify-all.sh --run      # check + test all 10 projects, then demo each
```

## The tools

Each lives in `projects/<name>` with a unit-tested core in `src/lib.0` and an
argv/IO shell in `src/main.0`. Because this backend has no stdin/file runtime
yet, input is passed as arguments (each argument is one "line").

| Project   | Models      | What it does                                   | Example |
|-----------|-------------|------------------------------------------------|---------|
| `zgrep`   | grep/ripgrep| substring line search, `-i -v -c -n`           | `zero run projects/zgrep -- -in err "no errors" "Error: x"` |
| `zwc`     | wc          | line/word/byte counts, `-l -w -c`              | `zero run projects/zwc -- "hello world" "a b c"` |
| `zcalc`   | bc/expr     | shunting-yard arithmetic: `+ - * / %`, parens  | `zero run projects/zcalc -- "(3 + 4) * 2"` |
| `zsort`   | sort/uniq   | insertion sort of lines, `-r -n -u`            | `zero run projects/zsort -- -n 10 2 33 4` |
| `zcut`    | cut         | extract a delimited field, `-d -f`             | `zero run projects/zcut -- -d : -f 2 root:x:0` |
| `ztr`     | tr          | translate/delete: `rot13`/`upper`/`lower`/`-d` | `zero run projects/ztr -- rot13 "Hello"` |
| `zbase`   | printf/bc   | integer base conversion, bases 2..16           | `zero run projects/zbase -- ff 16 2` |
| `zfactor` | factor      | prime factorization via trial division         | `zero run projects/zfactor -- 360` |
| `zuniq`   | uniq        | collapse adjacent duplicates, `-c -d`          | `zero run projects/zuniq -- -c a a b c c` |
| `zstats`  | datamash/st | count/sum/min/max/mean/median over numbers     | `zero run projects/zstats -- 4 8 15 16 23 42` |

## Layout

```
zerolang-examples/
├── README.md
├── LANGUAGE_NOTES.md        # zerolang 0.2.0 capability matrix (read this)
├── scripts/
│   ├── setup.sh             # install the zero toolchain
│   ├── verify-all.sh        # check + test (+ optional --run) every project
│   └── new-project.sh       # scaffold a new example in the corpus style
└── projects/
    └── <name>/
        ├── zero.json
        ├── src/lib.0        # pure, unit-tested core
        └── src/main.0       # argv parsing + IO
```

## Conventions (for editing experiments)

- **Pure core, thin shell.** Algorithms live in `lib.0`; `main.0` only parses
  args and writes output. IO never leaves `main` (the backend can't pass
  `World` to a helper).
- **Tested helpers are recursive + cast-free** so the `zero test` interpreter
  can run them. `while`/span code is covered by `zero check` + `zero run`.
- **Decimal output is hand-rolled** (`fmt_u32`) because 0.2.0 has no integer
  formatter — a recurring, easy-to-mutate target across projects.

## Working on a project

```sh
zero check projects/zcalc          # typecheck
zero test  projects/zcalc          # run unit tests
zero run   projects/zcalc -- 6 '*' 7
zero fmt   projects/zcalc          # canonical formatting
```

## Adding another example

```sh
scripts/new-project.sh zhead       # scaffolds projects/zhead in corpus style
# edit src/{lib,main}.0, then:
zero check projects/zhead && zero test projects/zhead
```

Natural next examples / experiment ideas: `zhead`/`ztail`, `zrev`, a JSON
pretty-printer, or file-reading variants of the existing tools (these compile
under `zero check` but won't `run` until the backend gains `std.fs`).
