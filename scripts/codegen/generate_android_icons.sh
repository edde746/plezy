#!/usr/bin/env bash

# Generate Android notification and monochrome icons from the approved PlezyNG app icon.

set -euo pipefail

APP_ICON_SOURCE="assets/plezyng-app-icon.png"
ANDROID_RES="android/app/src/main/res"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/plezyng-android-icons.XXXXXX")
trap 'rm -rf -- "$TEMP_DIR"' EXIT

if [[ ! -f "$APP_ICON_SOURCE" ]]; then
    echo "Error: $APP_ICON_SOURCE not found" >&2
    exit 1
fi

if command -v magick >/dev/null 2>&1; then
    IMAGEMAGICK=magick
elif command -v convert >/dev/null 2>&1; then
    IMAGEMAGICK=convert
else
    echo "Error: ImageMagick not found. Install with: brew install imagemagick" >&2
    exit 1
fi

echo "Generating Android icons from $APP_ICON_SOURCE..."

generate_white_icon() {
    local size=$1
    local output=$2
    mkdir -p "$(dirname "$output")"

    "$IMAGEMAGICK" "$APP_ICON_SOURCE" \
        -channel A -fx 'u<=0.025?0:u' +channel \
        -resize "${size}x${size}" \
        -fill white -colorize 100% \
        -define png:color-type=6 \
        "$output"

    echo "  Generated $(basename "$output") (${size}x${size}px)"
}

declare -A NOTIF_SIZES=(
    [mdpi]=24
    [hdpi]=36
    [xhdpi]=48
    [xxhdpi]=72
    [xxxhdpi]=96
)

for density in "${!NOTIF_SIZES[@]}"; do
    generate_white_icon "${NOTIF_SIZES[$density]}" "$ANDROID_RES/drawable-$density/ic_stat_notification.png"
done

declare -A MONO_SIZES=(
    [mdpi]=108
    [hdpi]=162
    [xhdpi]=216
    [xxhdpi]=324
    [xxxhdpi]=432
)

for density in "${!MONO_SIZES[@]}"; do
    generate_white_icon "${MONO_SIZES[$density]}" "$ANDROID_RES/mipmap-$density/ic_launcher_monochrome.png"
done

echo "Generated Android notification and monochrome icons."
