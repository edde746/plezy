#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
dart run slang
exec dart run build_runner build --delete-conflicting-outputs "$@"
