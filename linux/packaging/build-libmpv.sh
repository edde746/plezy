#!/usr/bin/env bash
set -euo pipefail

PREFIX="$(pwd)/libmpv-prefix"
JOBS="$(nproc)"

FFMPEG_VERSION="7.1"
SHADERC_VERSION="2024.4"
LIBPLACEBO_VERSION="7.351.0"
MPV_VERSION="0.40.0"

PREFIX="$(realpath "$PREFIX")"
mkdir -p "$PREFIX"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib/$(uname -m)-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}"

SRCDIR="$(mktemp -d)"
trap 'rm -rf "$SRCDIR"' EXIT
cd "$SRCDIR"

echo "==> Sources in $SRCDIR"
echo "==> Install prefix: $PREFIX"
echo ""

# ─── Step 1: ffmpeg (static libraries) ───────────────────────────────────────

echo "==> Building ffmpeg $FFMPEG_VERSION (static, decoder-only)..."
curl -sL "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" | tar xJ
cd "ffmpeg-${FFMPEG_VERSION}"

./configure \
  --prefix="$PREFIX" \
  --enable-gpl \
  --enable-version3 \
  --enable-static \
  --disable-shared \
  --enable-pic \
  --disable-programs \
  --disable-doc \
  --disable-encoders \
  --disable-muxers \
  --enable-muxer=spdif \
  --disable-devices \
  --disable-bsfs \
  --enable-bsf=aac_adtstoasc,av1_metadata,extract_extradata,h264_metadata,h264_mp4toannexb,hevc_metadata,hevc_mp4toannexb,vp9_metadata \
  --disable-filters \
  --enable-filter=aformat,aresample,format,null,scale \
  --enable-vaapi \
  --enable-vdpau \
  --disable-debug \
  --disable-stripping

make -j"$JOBS"
make install
cd "$SRCDIR"

echo ""
echo "==> ffmpeg done."
echo ""

# ─── Step 2: shaderc (static library) ─────────────────────────────────────────

echo "==> Building shaderc $SHADERC_VERSION (static)..."
git clone --depth 1 --branch "v${SHADERC_VERSION}" \
  https://github.com/google/shaderc.git "shaderc-v${SHADERC_VERSION}"
cd "shaderc-v${SHADERC_VERSION}"
./utils/git-sync-deps

cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DSHADERC_SKIP_TESTS=ON \
  -DSHADERC_SKIP_EXAMPLES=ON \
  -DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON

cmake --build build -j"$JOBS"
cmake --install build

cd "$SRCDIR"

echo ""
echo "==> shaderc done."
echo ""

# ─── Step 3: libplacebo (static library) ─────────────────────────────────────

echo "==> Building libplacebo $LIBPLACEBO_VERSION (static)..."
git clone --depth 1 --recursive --branch "v${LIBPLACEBO_VERSION}" \
  https://code.videolan.org/videolan/libplacebo.git "libplacebo-v${LIBPLACEBO_VERSION}"
cd "libplacebo-v${LIBPLACEBO_VERSION}"

meson setup build \
  --prefix="$PREFIX" \
  --default-library=static \
  -Dvulkan=disabled \
  -Dd3d11=disabled \
  -Ddemos=false \
  -Dtests=false

ninja -C build -j"$JOBS"
ninja -C build install
cd "$SRCDIR"

echo ""
echo "==> libplacebo done."
echo ""

# ─── Step 4: mpv (shared libmpv) ─────────────────────────────────────────────

echo "==> Building mpv $MPV_VERSION (shared libmpv only)..."
curl -sL "https://github.com/mpv-player/mpv/archive/refs/tags/v${MPV_VERSION}.tar.gz" | tar xz
cd "mpv-${MPV_VERSION}"

meson setup build \
  --prefix="$PREFIX" \
  -Dlibmpv=true \
  -Dcplayer=false \
  -Dbuild-date=false \
  -Dlua=disabled \
  -Djavascript=disabled \
  -Dcplugins=disabled \
  -Dmanpage-build=disabled \
  -Djack=disabled \
  -Dvulkan=disabled \
  -Dd3d11=disabled \
  -Dgl=enabled \
  -Dvaapi=enabled \
  -Dvdpau=enabled \
  -Dalsa=enabled \
  -Dpulse=enabled \
  -Dpipewire=enabled \
  -Dwayland=enabled \
  -Dx11=enabled

ninja -C build -j"$JOBS"
ninja -C build install
cd "$SRCDIR"

echo ""
echo "==> mpv done."
echo ""
echo "==> libmpv build complete. Output in $PREFIX"
