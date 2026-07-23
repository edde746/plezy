#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ "${1:-}" == "--check" ]]; then
  shift
  exec python3 scripts/check_codegen.py "$@"
fi

dart run scripts/generate_ducet_ranks.dart
dart run scripts/generate_hid_key_labels.dart
dart run scripts/generate_iso_639_data.dart
python3 scripts/generate_relay_protocol.py
dart run slang
dart run build_runner build --delete-conflicting-outputs "$@"
