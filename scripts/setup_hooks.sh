#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

chmod +x .githooks/pre-commit scripts/ci_checks.sh
git config core.hooksPath .githooks

cat <<EOF
Git hooks installed.
  pre-commit  runs the CI analyze pipeline (format + analyze + unused code + unused files)

Bypass once:  git commit --no-verify
Bypass env:   SKIP_HOOKS=1 git commit ...
Run manually: ./scripts/ci_checks.sh
Uninstall:    git config --unset core.hooksPath
EOF
