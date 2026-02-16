#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
IMAGE="registry.gitlab.steamos.cloud/steamrt/sniper/sdk:latest"

docker run --rm \
  --platform linux/amd64 \
  -v "$PROJECT_ROOT":/app \
  -w /app \
  "$IMAGE" \
  bash -c '
set -euo pipefail

echo "==> Installing build dependencies..."
apt-get update -qq
apt-get install -y -qq \
  clang cmake meson ninja-build pkg-config nasm git curl unzip xz-utils \
  libgtk-3-dev liblzma-dev \
  libasound2-dev libass-dev libfreetype-dev libfontconfig-dev libfribidi-dev libharfbuzz-dev \
  libepoxy-dev libegl-dev libgl-dev libgnutls28-dev \
  libpipewire-0.3-dev libva-dev libvdpau-dev \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev libxpresent-dev \
  libxkbcommon-dev libpulse-dev libdbus-1-dev libdrm-dev libgbm-dev \
  libwayland-dev wayland-protocols liblcms2-dev python3-pip \

pip3 install meson --upgrade

echo ""
echo "==> Building libmpv..."
bash linux/packaging/build-libmpv.sh

export PKG_CONFIG_PATH="$(pwd)/libmpv-prefix/lib/pkgconfig:$(pwd)/libmpv-prefix/lib/x86_64-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}"

echo ""
echo "==> Installing Flutter..."
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /opt/flutter
export PATH="/opt/flutter/bin:$PATH"
flutter --disable-analytics
flutter config --no-cli-animations
flutter precache --linux

echo ""
echo "==> Building Plezy..."
flutter pub get
flutter build linux --release --dart-define=ENABLE_UPDATE_CHECK=true

echo ""
echo "==> Assembling Steam bundle..."
BUNDLE=build/linux/x64/release/bundle

# Copy libmpv + shaderc into bundle
BUNDLE_LIB="$BUNDLE/lib"
LIBMPV_DIR=$(dirname "$(find libmpv-prefix -name libmpv.so | head -1)")
cp -a "$LIBMPV_DIR"/libmpv.so* "$BUNDLE_LIB/"
cp -a libmpv-prefix/lib/libshaderc_shared.so* "$BUNDLE_LIB/"

# For Steam, do NOT run bundle-libs.sh — the runtime provides system libs.
# Only verify the binary can resolve deps against the runtime.
echo ""
echo "==> Checking dependencies..."
MISSING=$(LD_LIBRARY_PATH="$BUNDLE_LIB" ldd "$BUNDLE/plezy" 2>&1 | grep "not found" || true)
if [[ -n "$MISSING" ]]; then
  echo "WARNING: Unresolved dependencies (will need Steam runtime):"
  echo "$MISSING"
fi

echo ""
echo "==> Creating tarball..."
cd "$BUNDLE"
tar -czf /app/plezy-steam-linux-x64.tar.gz *

echo ""
echo "==> Done! Output: plezy-steam-linux-x64.tar.gz"
'
