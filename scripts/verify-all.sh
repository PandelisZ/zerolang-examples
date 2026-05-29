#!/usr/bin/env bash
#
# Verify every example project: `zero check` (must pass) and `zero test`.
# Optionally also smoke-runs each tool with `--run`.
#
#   scripts/verify-all.sh          # check + test every project
#   scripts/verify-all.sh --run    # also run a sample invocation per tool
#
# Exit status is non-zero if any project fails `zero check`.
set -uo pipefail

export PATH="$HOME/.zero/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECTS="$ROOT/projects"

if ! command -v zero >/dev/null 2>&1; then
    echo "error: 'zero' not on PATH. Run scripts/setup.sh first." >&2
    exit 127
fi

run_demos=0
[ "${1:-}" = "--run" ] && run_demos=1

fail=0
printf '%-10s %-8s %-18s\n' "PROJECT" "CHECK" "TEST"
printf '%-10s %-8s %-18s\n' "-------" "-----" "----"

for dir in "$PROJECTS"/*/; do
    name="$(basename "$dir")"

    if zero check "$dir" >/dev/null 2>&1; then
        check="ok"
    else
        check="FAIL"
        fail=1
    fi

    test_out="$(zero test "$dir" 2>&1)"
    if printf '%s' "$test_out" | grep -q "test(s) ok"; then
        test_res="$(printf '%s' "$test_out" | grep -o '[0-9]* test(s) ok')"
    else
        test_res="FAIL"
    fi

    printf '%-10s %-8s %-18s\n' "$name" "$check" "$test_res"
done

if [ "$run_demos" -eq 1 ]; then
    echo
    echo "=== sample runs ==="
    run_one() { printf '$ %s\n' "$*"; ( cd "$PROJECTS/$1" && zero run . -- "${@:2}" 2>&1 ); echo; }
    run_one zgrep -in err "no errors here" "Error: disk full" "all ok"
    run_one zwc "hello world" "the quick brown fox"
    run_one zcalc "(3 + 4) * 2 - 1"
    run_one zsort -n 10 2 33 4
    run_one zcut -d : -f 2 root:x:0:0 daemon:y:1:1
    run_one ztr rot13 "Hello, World"
    run_one zbase ff 16 2
    run_one zfactor 360
    run_one zuniq -c a a b c c c
    run_one zstats 4 8 15 16 23 42
fi

if [ "$fail" -ne 0 ]; then
    echo
    echo "one or more projects failed 'zero check'" >&2
fi
exit "$fail"
