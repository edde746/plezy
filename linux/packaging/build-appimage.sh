#!/usr/bin/env bash
#
# build-appimage.sh — Wrap a resolved Linux bundle into an AppImage.
#
# Usage: build-appimage.sh <bundle-dir> <x64|arm64> <output-dir>
#
# The bundle must already have been through bundle-libs.sh and have plezy.sh
# copied in, the same tree the tarball and packages are cut from. Writes
# plezy-linux-<arch>.AppImage to <output-dir>.
#
# Needs appimagetool (or APPIMAGETOOL=<path>), desktop-file-validate and
# ImageMagick. Optional environment:
#   RUNTIME_FILE   AppImage runtime to embed; appimagetool downloads the
#                  latest one when unset.
#   UPDATE_REPO    <owner>/<repo> whose latest GitHub release carries this
#                  AppImage. Embeds gh-releases-zsync update information (what
#                  Gear Lever and AppImageUpdate read) and writes the matching
#                  .zsync next to the AppImage; needs zsyncmake.
#   VERSION        Recorded as X-AppImage-Version in the embedded desktop file.

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <bundle-dir> <x64|arm64> <output-dir>" >&2
    exit 1
fi

BUNDLE_DIR="$(realpath "$1")"
ARCH_SUFFIX="$2"
OUTPUT_DIR="$(realpath "$3")"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../..")"
APPIMAGETOOL="${APPIMAGETOOL:-appimagetool}"

case "$ARCH_SUFFIX" in
    x64) APPIMAGE_ARCH=x86_64 ;;
    arm64) APPIMAGE_ARCH=aarch64 ;;
    *)
        echo "Error: unknown arch '$ARCH_SUFFIX' (expected x64 or arm64)" >&2
        exit 1
        ;;
esac

for file in plezy plezy.sh; do
    if [[ ! -f "$BUNDLE_DIR/$file" ]]; then
        echo "Error: $file not found in $BUNDLE_DIR" >&2
        exit 1
    fi
done

if command -v magick &>/dev/null; then
    IMAGEMAGICK=magick
elif command -v convert &>/dev/null; then
    IMAGEMAGICK=convert
else
    echo "Error: ImageMagick (magick or convert) is needed to size the icon" >&2
    exit 1
fi

OUTPUT_NAME="plezy-linux-$ARCH_SUFFIX.AppImage"
OUTPUT="$OUTPUT_DIR/$OUTPUT_NAME"

TOOL_ARGS=(--no-appstream)
if [[ -n "${RUNTIME_FILE:-}" ]]; then
    TOOL_ARGS+=(--runtime-file "$(realpath "$RUNTIME_FILE")")
fi
if [[ -n "${UPDATE_REPO:-}" ]]; then
    if [[ ! "$UPDATE_REPO" =~ ^[^/|]+/[^/|]+$ ]]; then
        echo "Error: UPDATE_REPO must be <owner>/<repo>, got '$UPDATE_REPO'" >&2
        exit 1
    fi
    # appimagetool only warns and carries on without the .zsync when zsyncmake
    # is missing, which would ship an AppImage whose updates never resolve.
    if ! command -v zsyncmake &>/dev/null; then
        echo "Error: UPDATE_REPO is set but zsyncmake is not installed" >&2
        exit 1
    fi
    # Gear Lever finds the release asset by this .zsync name and downloads the
    # asset named the same without .zsync, so the two must stay in step.
    TOOL_ARGS+=(--updateinformation "gh-releases-zsync|${UPDATE_REPO%/*}|${UPDATE_REPO#*/}|latest|$OUTPUT_NAME.zsync")
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
APPDIR="$WORK_DIR/Plezy.AppDir"

echo "==> Assembling AppDir"
cp -a "$BUNDLE_DIR" "$APPDIR"

# plezy.sh resolves its own path with readlink -f, so as AppRun it finds the
# binary and lib/ at the root of the mounted image.
chmod 0755 "$APPDIR/plezy.sh"
ln -s plezy.sh "$APPDIR/AppRun"

# appimagetool reads the one .desktop file at the AppDir root and expects the
# icon its Icon= names beside it; .DirIcon is what file managers show.
cp "$SCRIPT_DIR/com.edde746.plezy.desktop" "$APPDIR/"
ICON_DIR="$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$ICON_DIR"
"$IMAGEMAGICK" "$PROJECT_ROOT/assets/plezy.png" -resize 256x256 "$ICON_DIR/plezy.png"
ln -s usr/share/icons/hicolor/256x256/apps/plezy.png "$APPDIR/plezy.png"
ln -s plezy.png "$APPDIR/.DirIcon"

echo "==> Building $OUTPUT_NAME"
rm -f "$OUTPUT" "$OUTPUT.zsync"
# zsyncmake writes the .zsync into the working directory, which appimagetool
# first changes to $OWD. An OWD inherited from any AppImage further up the
# process tree outlives the cd, so it is pinned here too.
(cd "$OUTPUT_DIR" && OWD="$OUTPUT_DIR" ARCH="$APPIMAGE_ARCH" "$APPIMAGETOOL" "${TOOL_ARGS[@]}" "$APPDIR" "$OUTPUT")

if [[ -n "${UPDATE_REPO:-}" && ! -f "$OUTPUT.zsync" ]]; then
    echo "Error: appimagetool did not write $OUTPUT.zsync" >&2
    exit 1
fi

echo "==> Done"
ls -l "$OUTPUT"*
