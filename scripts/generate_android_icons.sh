#!/usr/bin/env bash

# Android Icon Generator Script
# Generates notification icons and monochrome launcher icons from SVG source
# Usage: ./generate_android_icons.sh

set -e

# Configuration
SVG_SOURCE="assets/plezy.svg"
ANDROID_RES="android/app/src/main/res"
TEMP_DIR="/tmp/android_icons_$$"

# Check if source SVG exists
if [ ! -f "$SVG_SOURCE" ]; then
    echo "Error: $SVG_SOURCE not found"
    exit 1
fi

# Check for required tools
if ! command -v rsvg-convert &> /dev/null; then
    echo "Error: rsvg-convert not found. Install with: brew install librsvg"
    exit 1
fi

if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick not found. Install with: brew install imagemagick"
    exit 1
fi

# Create temp directory
mkdir -p "$TEMP_DIR"

echo "🎨 Generating Android icons from $SVG_SOURCE..."

# Function to generate white silhouette icon
generate_white_icon() {
    local size=$1
    local output=$2

    # Get SVG dimensions to detect if it's non-square
    local svg_viewbox=$(grep -o 'viewBox="[^"]*"' "$SVG_SOURCE" | sed 's/viewBox="//;s/"//')
    local svg_width=$(echo "$svg_viewbox" | awk '{print $3}')
    local svg_height=$(echo "$svg_viewbox" | awk '{print $4}')

    # Convert SVG to PNG, preserving aspect ratio
    if (( $(echo "$svg_width != $svg_height" | bc -l) )); then
        # Non-square SVG: render at size and add padding to center it
        rsvg-convert --keep-aspect-ratio --background-color=transparent "$SVG_SOURCE" -o "$TEMP_DIR/temp_unpadded.png"

        # Center the image in a square canvas with transparent padding
        magick "$TEMP_DIR/temp_unpadded.png" \
            -resize "${size}x${size}" \
            -gravity center \
            -background transparent \
            -extent "${size}x${size}" \
            "$TEMP_DIR/temp.png"
    else
        # Square SVG: convert directly
        rsvg-convert -w "$size" -h "$size" --background-color=transparent "$SVG_SOURCE" -o "$TEMP_DIR/temp.png"
    fi

    # Convert to white silhouette: extract alpha, fill with white, apply alpha
    magick "$TEMP_DIR/temp.png" \
        -alpha extract \
        "$TEMP_DIR/alpha_mask.png"

    magick -size "${size}x${size}" xc:white \
        "$TEMP_DIR/alpha_mask.png" \
        -alpha off \
        -compose copy-opacity \
        -composite \
        -define png:color-type=6 \
        "$output"

    echo "  ✓ Generated $(basename $output) (${size}x${size}px)"
}

# Generate Notification Icons (24dp base)
echo ""
echo "📱 Generating notification icons (ic_stat_notification.png)..."

# Notification icon densities: 24dp base
# mdpi=1x, hdpi=1.5x, xhdpi=2x, xxhdpi=3x, xxxhdpi=4x
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

# Generate Monochrome Launcher Icons (108dp base)
echo ""
echo "🚀 Generating monochrome launcher icons (ic_launcher_monochrome.png)..."

# Monochrome launcher icon densities: 108dp base
# mdpi=1x, hdpi=1.5x, xhdpi=2x, xxhdpi=3x, xxxhdpi=4x
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

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "✅ All icons generated successfully!"
echo ""
echo "Icon locations:"
echo "  • Notification icons: $ANDROID_RES/drawable-*/ic_stat_notification.png"
echo "  • Monochrome icons: $ANDROID_RES/mipmap-*/ic_launcher_monochrome.png"
echo ""
echo "To apply changes, rebuild the app: flutter clean && flutter build apk"
