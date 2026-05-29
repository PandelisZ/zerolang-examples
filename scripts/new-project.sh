#!/usr/bin/env bash
#
# Scaffold a new example CLI project that follows the corpus conventions
# (pure, unit-tested core in lib.0 + arg/IO shell in main.0).
#
#   scripts/new-project.sh zhead
#
# Then edit projects/<name>/src/{lib,main}.0 and run:
#   zero check projects/<name> && zero test projects/<name>
set -euo pipefail

export PATH="$HOME/.zero/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

name="${1:-}"
if [ -z "$name" ]; then
    echo "usage: scripts/new-project.sh <name>" >&2
    exit 2
fi

dest="$ROOT/projects/$name"
if [ -e "$dest" ]; then
    echo "error: $dest already exists" >&2
    exit 1
fi

cd "$ROOT/projects"
zero new cli "$name" >/dev/null

cat > "$name/src/lib.0" <<'EOF'
// Core logic. Keep unit-tested helpers recursive and cast-free so the 0.2.0
// `zero test` interpreter can run them; put `while`/std.mem code here too (it
// is validated by `zero check` / `zero run`).

pub fn fmt_u32(buf: MutSpan<u8>, value: u32) -> Span<u8> {
    if value == 0 {
        buf[0] = 48
        return buf[0..1]
    }
    var n: u32 = value
    var tmp: [10]u8 = [0; 10]
    var count: usize = 0
    while n > 0 {
        tmp[count] = 48 + ((n % 10) as u8)
        n = n / 10
        count = count + 1
    }
    var i: usize = 0
    while i < count {
        buf[i] = tmp[count - 1 - i]
        i = i + 1
    }
    return buf[0..count]
}

test "fmt placeholder" {
    expect 1 + 1 == 2
}
EOF

cat > "$name/src/main.0" <<EOF
// $name - TODO describe the tool.
use lib

pub fn main(world: World) -> Void raises {
    let argc: usize = std.args.len()
    if argc < 2 {
        check world.err.write("usage: $name <args>...\n")
        return
    }
    var i: usize = 1
    while i < argc {
        let a: Maybe<String> = std.args.get(i)
        if a.has {
            check world.out.write(a.value)
            check world.out.write("\n")
        }
        i = i + 1
    }
}
EOF

echo "created projects/$name"
echo "next: edit src/{lib,main}.0, then 'zero check projects/$name && zero test projects/$name'"
