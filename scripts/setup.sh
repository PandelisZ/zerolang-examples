#!/usr/bin/env bash
#
# Install the zerolang toolchain (`zero`) used by every example project.
# Idempotent: re-running just reports the installed version.
set -euo pipefail

if command -v zero >/dev/null 2>&1; then
    echo "zero already installed: $(zero --version)"
    exit 0
fi

if [ ! -x "$HOME/.zero/bin/zero" ]; then
    echo "installing zerolang..."
    curl -fsSL https://zerolang.ai/install.sh | bash
fi

export PATH="$HOME/.zero/bin:$PATH"
echo
echo "installed: $(zero --version)"
echo 'add this to your shell profile:'
echo '  export PATH="$HOME/.zero/bin:$PATH"'
