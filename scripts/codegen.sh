#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ "${1:-}" == "--check" ]]; then
  shift
  exec python3 scripts/check_codegen.py "$@"
fi

python3 scripts/generate_relay_protocol.py
dart run slang
dart run build_runner build --delete-conflicting-outputs "$@"
