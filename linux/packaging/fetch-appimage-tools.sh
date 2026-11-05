#!/usr/bin/env bash
#
# fetch-appimage-tools.sh — Download the pinned appimagetool and AppImage
# runtime for one architecture, verifying both before either can run.
#
# Usage: fetch-appimage-tools.sh <x64|arm64> <dest-dir>
#
# Writes <dest-dir>/appimagetool and <dest-dir>/runtime, which build-appimage.sh
# takes as APPIMAGETOOL and RUNTIME_FILE. Both are fixed releases: left alone,
# appimagetool embeds whichever runtime is newest on the day of the build.

set -euo pipefail

APPIMAGETOOL_VERSION=1.9.1
RUNTIME_VERSION=20251108

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <x64|arm64> <dest-dir>" >&2
    exit 1
fi

case "$1" in
    x64)
        ARCH=x86_64
        APPIMAGETOOL_SHA256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
        RUNTIME_SHA256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d
        ;;
    arm64)
        ARCH=aarch64
        APPIMAGETOOL_SHA256=f0837e7448a0c1e4e650a93bb3e85802546e60654ef287576f46c71c126a9158
        RUNTIME_SHA256=00cbdfcf917cc6c0ff6d3347d59e0ca1f7f45a6df1a428a0d6d8a78664d87444
        ;;
    *)
        echo "Error: unknown arch '$1' (expected x64 or arm64)" >&2
        exit 1
        ;;
esac

DEST_DIR="$2"
mkdir -p "$DEST_DIR"

curl -fsSL --retry 3 -o "$DEST_DIR/appimagetool" \
    "https://github.com/AppImage/appimagetool/releases/download/$APPIMAGETOOL_VERSION/appimagetool-$ARCH.AppImage"
curl -fsSL --retry 3 -o "$DEST_DIR/runtime" \
    "https://github.com/AppImage/type2-runtime/releases/download/$RUNTIME_VERSION/runtime-$ARCH"

echo "$APPIMAGETOOL_SHA256  $DEST_DIR/appimagetool" | sha256sum --check --strict
echo "$RUNTIME_SHA256  $DEST_DIR/runtime" | sha256sum --check --strict
chmod +x "$DEST_DIR/appimagetool"
