#!/usr/bin/env bash
# Resolve the shared Flutter app for tvOS with the tvOS MethodChannel bridge.
# The upstream dart_smb2 native assets do not target tvOS; the bridge uses the
# dynamically linked AMSMB2 SPM framework instead.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [[ -e pubspec_overrides.yaml ]]; then
  echo "pubspec_overrides.yaml already exists; move it aside before preparing tvOS dependencies." >&2
  exit 1
fi

cp pubspec_overrides_tvos.yaml pubspec_overrides.yaml
trap 'rm -f pubspec_overrides.yaml' EXIT
flutter pub get --no-example
