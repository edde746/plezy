#!/usr/bin/env bash
# Usage: upload-symbols.sh <platform>
# Env: BUGS_ADMIN_TOKEN (required), BUGS_URL (default https://bugs.plezy.app)
# Platforms: macos | ios | android-apk | android-aab | linux-x64 | linux-arm64
set -euo pipefail

PLATFORM="${1:?platform arg required}"
TOKEN="${BUGS_ADMIN_TOKEN:?BUGS_ADMIN_TOKEN env var required}"
URL="${BUGS_URL:-https://bugs.plezy.app}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

RELEASE="plezy@$(git rev-parse --short HEAD)"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

if [ -d "debug-info/${PLATFORM}" ]; then
  cp -a "debug-info/${PLATFORM}"/. "$STAGE"/
fi

case "$PLATFORM" in
  macos)
    find build/macos/Build/Products/Release -name '*.dSYM' -exec cp -a {} "$STAGE"/ \; 2>/dev/null || true
    ;;
  ios)
    find build/ios -name '*.dSYM' -exec cp -a {} "$STAGE"/ \; 2>/dev/null || true
    ;;
  linux-x64|linux-arm64)
    find build/linux -path '*/release/bundle/plezy' -exec cp {} "$STAGE"/ \; 2>/dev/null || true
    ;;
  android-apk|android-aab)
    find build/app/intermediates/merged_native_libs -name '*.so' -exec cp {} "$STAGE"/ \; 2>/dev/null || true
    ;;
  *)
    echo "unknown platform: $PLATFORM" >&2
    exit 2
    ;;
esac

if [ -z "$(ls -A "$STAGE" 2>/dev/null)" ]; then
  echo "no symbols found for platform ${PLATFORM}" >&2
  exit 3
fi

(cd "$STAGE" && zip -qr symbols.zip .)

curl --fail --silent --show-error -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "file=@${STAGE}/symbols.zip" \
  -F "release=${RELEASE}" \
  "${URL}/api/0/projects/plezy/plezy/files/dsyms/"
