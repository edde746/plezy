#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

check=false
if [[ "${1:-}" == "--check" ]]; then
  check=true
  shift
fi

python3 scripts/generate_relay_protocol.py
dart run slang
dart run build_runner build --delete-conflicting-outputs "$@"

if $check; then
  generated_changes="$({
    git diff --name-only -- lib server/relay_protocol_gen.go
    git ls-files --others --exclude-standard -- \
      ':(glob)lib/**/*.g.dart' \
      ':(glob)lib/**/*.freezed.dart' \
      server/relay_protocol_gen.go
  } | grep -E '(\.(g|freezed)\.dart|relay_protocol_gen\.go)$' || true)"

  if [[ -n "$generated_changes" ]]; then
    echo "Generated files are out of date:" >&2
    printf '  %s\n' "$generated_changes" >&2
    echo "Run 'scripts/codegen.sh' and commit the result." >&2
    exit 1
  fi
fi
