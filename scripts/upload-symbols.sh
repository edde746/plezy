#!/usr/bin/env bash
# Usage: upload-symbols.sh <platform> [source-root]
# Env: SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN (required unless BUGS_UPLOAD_DRY_RUN is set)
#      SENTRY_URL or BUGS_URL (default https://bugs.plezy.app)
# Platforms: macos | ios | android-apk | android-aab | linux-x64 | linux-arm64
set -euo pipefail

PLATFORM="${1:?platform arg required}"
DRY_RUN="${BUGS_UPLOAD_DRY_RUN:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

SOURCE_ROOT="${2:-$ROOT}"
if [[ "$SOURCE_ROOT" != /* ]]; then
  SOURCE_ROOT="$ROOT/$SOURCE_ROOT"
fi

BUILD_ROOT="$SOURCE_ROOT/build"
SYMBOL_ROOT="$SOURCE_ROOT/debug-info/$PLATFORM"
DART_SYMBOL_MAP_PATH="${SENTRY_DART_SYMBOL_MAP_PATH:-}"

if [ -z "$DART_SYMBOL_MAP_PATH" ]; then
  for candidate in \
    "$SYMBOL_ROOT/obfuscation.map.json" \
    "$BUILD_ROOT/app/obfuscation/$PLATFORM.map.json" \
    "$BUILD_ROOT/app/obfuscation.map.json"; do
    if [ -f "$candidate" ]; then
      DART_SYMBOL_MAP_PATH="$candidate"
      break
    fi
  done
fi

SEARCH_ROOTS=()

add_existing_root() {
  if [ -d "$1" ]; then
    SEARCH_ROOTS+=("$1")
  fi
}

add_existing_root "$SYMBOL_ROOT"

case "$PLATFORM" in
  macos)
    add_existing_root "$BUILD_ROOT/macos"
    ;;
  ios)
    add_existing_root "$BUILD_ROOT/ios"
    add_existing_root "$SOURCE_ROOT/ios/build"
    ;;
  linux-x64|linux-arm64)
    add_existing_root "$BUILD_ROOT/linux"
    ;;
  android-apk|android-aab)
    add_existing_root "$BUILD_ROOT/app"
    ;;
  *)
    echo "unknown platform: $PLATFORM" >&2
    exit 2
    ;;
esac

found_symbol_file() {
  local first
  if [ "${#SEARCH_ROOTS[@]}" -eq 0 ]; then
    return 1
  fi

  first="$(find "${SEARCH_ROOTS[@]}" -type f -print -quit 2>/dev/null || true)"
  [ -n "$first" ]
}

if ! found_symbol_file; then
  echo "no symbols found for platform ${PLATFORM}" >&2
  exit 3
fi

export SENTRY_URL="${SENTRY_URL:-${BUGS_URL:-https://bugs.plezy.app}}"
export SENTRY_RELEASE="${SENTRY_RELEASE:-vibe@$(git rev-parse --short HEAD)}"
export SENTRY_LOG_LEVEL="${SENTRY_LOG_LEVEL:-info}"

if [ -z "${SENTRY_AUTH_TOKEN:-}" ] && [ -n "${BUGS_ADMIN_TOKEN:-}" ]; then
  export SENTRY_AUTH_TOKEN="$BUGS_ADMIN_TOKEN"
fi

if [ -z "$DRY_RUN" ] && [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
  echo "SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN env var required" >&2
  exit 1
fi

PLUGIN_ARGS=(
  "--sentry-define=release=${SENTRY_RELEASE}"
  "--sentry-define=url=${SENTRY_URL}"
  "--sentry-define=build_path=${BUILD_ROOT}"
)

if [ -n "${SENTRY_DIST:-}" ]; then
  PLUGIN_ARGS+=("--sentry-define=dist=${SENTRY_DIST}")
fi

if [ -d "$SYMBOL_ROOT" ]; then
  PLUGIN_ARGS+=("--sentry-define=symbols_path=${SYMBOL_ROOT}")
fi

if [ -n "$DART_SYMBOL_MAP_PATH" ]; then
  PLUGIN_ARGS+=("--sentry-define=dart_symbol_map_path=${DART_SYMBOL_MAP_PATH}")
fi

if [ -n "$DRY_RUN" ]; then
  echo "dry-run: would upload symbols for ${PLATFORM}"
  echo "dry-run: release=${SENTRY_RELEASE}"
  echo "dry-run: dist=${SENTRY_DIST:-}"
  echo "dry-run: source_root=${SOURCE_ROOT}"
  echo "dry-run: build_path=${BUILD_ROOT}"
  echo "dry-run: symbols_path=${SYMBOL_ROOT}"
  echo "dry-run: dart_symbol_map_path=${DART_SYMBOL_MAP_PATH}"
  find "${SEARCH_ROOTS[@]}" -type f -print 2>/dev/null || true
  exit 0
fi

echo "uploading symbols for ${PLATFORM} release ${SENTRY_RELEASE} dist ${SENTRY_DIST:-}"
dart run sentry_dart_plugin "${PLUGIN_ARGS[@]}"
