#!/bin/bash
# =============================================================================
# Plezy webOS Build Script
#
# Builds the Flutter web app and packages it as a webOS IPK for LG TVs.
#
# Prerequisites:
#   - Flutter SDK installed and in PATH
#   - webOS CLI tools (ares-*) installed: npm install -g @anthropic/webos-cli
#   - For deployment: webOS TV in Developer Mode with ares-setup-device configured
#
# Usage:
#   ./scripts/build_webos.sh           # Build only
#   ./scripts/build_webos.sh --deploy  # Build and deploy to connected TV
#   ./scripts/build_webos.sh --debug   # Build in debug mode
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/web"
WEBOS_DIR="$PROJECT_DIR/webos"
OUTPUT_DIR="$PROJECT_DIR/build/webos"
DEPLOY=false
DEBUG=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --deploy) DEPLOY=true ;;
    --debug) DEBUG=true ;;
    --help)
      echo "Usage: $0 [--deploy] [--debug]"
      echo "  --deploy  Install IPK on connected webOS TV"
      echo "  --debug   Build in debug mode (profile)"
      exit 0
      ;;
  esac
done

echo "================================================"
echo "  Plezy webOS Build"
echo "================================================"
echo ""

# Step 1: Build Flutter web
echo "[1/4] Building Flutter web app..."
cd "$PROJECT_DIR"

if [ "$DEBUG" = true ]; then
  flutter build web --profile --web-renderer canvaskit \
    --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/
else
  flutter build web --release --web-renderer canvaskit \
    --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/
fi

echo "  Flutter web build complete."
echo ""

# Step 2: Prepare webOS package directory
echo "[2/4] Preparing webOS package..."
mkdir -p "$OUTPUT_DIR"

# Copy Flutter web build output
cp -r "$BUILD_DIR/"* "$OUTPUT_DIR/"

# Copy webOS app metadata
cp "$WEBOS_DIR/appinfo.json" "$OUTPUT_DIR/"

# Copy icons (generate from assets if not present)
if [ -f "$WEBOS_DIR/icon.png" ]; then
  cp "$WEBOS_DIR/icon.png" "$OUTPUT_DIR/"
else
  echo "  Warning: No icon.png in webos/ directory. Using placeholder."
  cp "$PROJECT_DIR/assets/plezy.png" "$OUTPUT_DIR/icon.png"
fi

if [ -f "$WEBOS_DIR/largeIcon.png" ]; then
  cp "$WEBOS_DIR/largeIcon.png" "$OUTPUT_DIR/"
else
  echo "  Warning: No largeIcon.png in webos/ directory. Using placeholder."
  cp "$PROJECT_DIR/assets/plezy.png" "$OUTPUT_DIR/largeIcon.png"
fi

echo "  Package directory prepared."
echo ""

# Step 3: Package as IPK
echo "[3/4] Packaging IPK..."
if command -v ares-package &> /dev/null; then
  cd "$PROJECT_DIR/build"
  ares-package webos -o "$PROJECT_DIR/build/"
  IPK_FILE=$(ls -t "$PROJECT_DIR/build/"*.ipk 2>/dev/null | head -1)
  if [ -n "$IPK_FILE" ]; then
    echo "  IPK created: $IPK_FILE"
  else
    echo "  Warning: IPK file not found after packaging."
  fi
else
  echo "  Warning: ares-package not found. Install webOS CLI tools:"
  echo "    npm install -g @anthropic/webos-cli"
  echo "  Skipping IPK packaging. Web build is available at: $OUTPUT_DIR/"
fi
echo ""

# Step 4: Deploy (optional)
if [ "$DEPLOY" = true ]; then
  echo "[4/4] Deploying to webOS TV..."
  if [ -n "$IPK_FILE" ] && command -v ares-install &> /dev/null; then
    ares-install "$IPK_FILE"
    echo "  Deployed successfully!"

    # Optionally launch the app
    echo "  Launching app..."
    ares-launch com.plezy.app
  else
    echo "  Warning: Cannot deploy. Ensure ares-install is available and TV is connected."
  fi
else
  echo "[4/4] Skipping deployment (use --deploy to install on TV)."
fi

echo ""
echo "================================================"
echo "  Build complete!"
if [ -n "$IPK_FILE" ]; then
  echo "  IPK: $IPK_FILE"
fi
echo "  Web: $OUTPUT_DIR/"
echo "================================================"
