#!/usr/bin/env bash
# Usage: upload-symbols.sh <platform> [source-root]
# Env: SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN (required unless BUGS_UPLOAD_DRY_RUN is set)
#      SENTRY_URL or BUGS_URL (default https://bugs.plezy.app)
# Platforms: macos | ios | android-apk | android-aab | linux-x64 | linux-arm64
set -euo pipefail

: "${1:?platform arg required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"
exec dart run scripts/upload_symbols.dart "$@"
