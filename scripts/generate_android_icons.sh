#!/usr/bin/env bash

# Generate Android notification and monochrome icons from assets/plezy.svg.

set -e

SVG_SOURCE="assets/plezy.svg"
ANDROID_RES="android/app/src/main/res"
TEMP_DIR="/tmp/android_icons_$$"

if [ ! -f "$SVG_SOURCE" ]; then
    echo "Error: $SVG_SOURCE not found"
    exit 1
fi

if ! command -v rsvg-convert &> /dev/null; then
    echo "Error: rsvg-convert not found. Install with: brew install librsvg"
    exit 1
fi

if command -v magick &> /dev/null; then
    IMAGEMAGICK=magick
elif command -v convert &> /dev/null; then
    IMAGEMAGICK=convert
else
    echo "Error: ImageMagick not found. Install with: brew install imagemagick"
    exit 1
fi

if ! command -v bc &> /dev/null; then
    echo "Error: bc not found. Install with: brew install bc"
    exit 1
fi

mkdir -p "$TEMP_DIR"

echo "🎨 Generating Android icons from $SVG_SOURCE..."

generate_white_icon() {
    local size=$1
    local output=$2

    # Read dimensions so non-square artwork can be padded.
    local svg_viewbox=$(grep -o 'viewBox="[^"]*"' "$SVG_SOURCE" | sed 's/viewBox="//;s/"//')
    local svg_width=$(echo "$svg_viewbox" | awk '{print $3}')
    local svg_height=$(echo "$svg_viewbox" | awk '{print $4}')

    # Preserve the source aspect ratio.
    if (( $(echo "$svg_width != $svg_height" | bc -l) )); then
        # Center non-square artwork on a transparent square canvas.
        rsvg-convert --keep-aspect-ratio --background-color=transparent "$SVG_SOURCE" -o "$TEMP_DIR/temp_unpadded.png"

        "$IMAGEMAGICK" "$TEMP_DIR/temp_unpadded.png" \
            -resize "${size}x${size}" \
            -gravity center \
            -background transparent \
            -extent "${size}x${size}" \
            "$TEMP_DIR/temp.png"
    else
        rsvg-convert -w "$size" -h "$size" --background-color=transparent "$SVG_SOURCE" -o "$TEMP_DIR/temp.png"
    fi

    # Convert the source alpha channel to a white silhouette.
    "$IMAGEMAGICK" "$TEMP_DIR/temp.png" \
        -alpha extract \
        "$TEMP_DIR/alpha_mask.png"

    "$IMAGEMAGICK" -size "${size}x${size}" xc:white \
        "$TEMP_DIR/alpha_mask.png" \
        -alpha off \
        -compose copy-opacity \
        -composite \
        -define png:color-type=6 \
        "$output"

    echo "  ✓ Generated $(basename $output) (${size}x${size}px)"
}

echo ""
echo "📱 Generating notification icons (ic_stat_notification.png)..."

declare -A NOTIF_SIZES=(
    ["mdpi"]=24
    ["hdpi"]=36
    ["xhdpi"]=48
    ["xxhdpi"]=72
    ["xxxhdpi"]=96
)

for density in "${!NOTIF_SIZES[@]}"; do
    size=${NOTIF_SIZES[$density]}
    output_dir="$ANDROID_RES/drawable-$density"
    mkdir -p "$output_dir"
    generate_white_icon "$size" "$output_dir/ic_stat_notification.png"
done

echo ""
echo "🚀 Generating monochrome launcher icons (ic_launcher_monochrome.png)..."

declare -A MONO_SIZES=(
    ["mdpi"]=108
    ["hdpi"]=162
    ["xhdpi"]=216
    ["xxhdpi"]=324
    ["xxxhdpi"]=432
)

for density in "${!MONO_SIZES[@]}"; do
    size=${MONO_SIZES[$density]}
    output_dir="$ANDROID_RES/mipmap-$density"
    mkdir -p "$output_dir"
    generate_white_icon "$size" "$output_dir/ic_launcher_monochrome.png"
done

rm -rf "$TEMP_DIR"

echo ""
echo "✅ All icons generated successfully!"
echo ""
echo "Icon locations:"
echo "  • Notification icons: $ANDROID_RES/drawable-*/ic_stat_notification.png"
echo "  • Monochrome icons: $ANDROID_RES/mipmap-*/ic_launcher_monochrome.png"
echo ""
echo "To apply changes, rebuild the app: flutter clean && flutter build apk"
