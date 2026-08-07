#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_INPUTS_MANIFEST="${NATIVE_INPUTS_MANIFEST:-$SCRIPT_DIR/native-inputs.json}"

manifest_value() {
  python3 - "$NATIVE_INPUTS_MANIFEST" "$1" "$2" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    manifest = json.load(source)
value = manifest["inputs"][sys.argv[2]][sys.argv[3]]
if not isinstance(value, str) or not value:
    raise SystemExit(f"invalid manifest value: {sys.argv[2]}.{sys.argv[3]}")
print(value)
PY
}

# For keys that are genuinely optional, where absence means "not offered"
# rather than a broken manifest. Pinned values never come through here: a
# missing checksum or commit has to stay fatal.
manifest_optional() {
  python3 - "$NATIVE_INPUTS_MANIFEST" "$1" "$2" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    manifest = json.load(source)
value = manifest["inputs"][sys.argv[2]].get(sys.argv[3], "")
if not isinstance(value, str):
    raise SystemExit(f"invalid manifest value: {sys.argv[2]}.{sys.argv[3]}")
print(value)
PY
}

FFMPEG_VERSION="$(manifest_value ffmpeg version)"
FFMPEG_URL="$(manifest_value ffmpeg url)"
FFMPEG_SHA256="$(manifest_value ffmpeg sha256)"
SHADERC_VERSION="$(manifest_value shaderc version)"
SHADERC_URL="$(manifest_value shaderc url)"
SHADERC_REF="$(manifest_value shaderc ref)"
SHADERC_COMMIT="$(manifest_value shaderc commit)"
LIBPLACEBO_VERSION="$(manifest_value libplacebo version)"
LIBPLACEBO_URL="$(manifest_value libplacebo url)"
LIBPLACEBO_MIRROR="$(manifest_optional libplacebo mirror)"
LIBPLACEBO_REF="$(manifest_value libplacebo ref)"
LIBPLACEBO_COMMIT="$(manifest_value libplacebo commit)"
MPV_VERSION="$(manifest_value mpv version)"
MPV_URL="$(manifest_value mpv url)"
MPV_SHA256="$(manifest_value mpv sha256)"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

download_verified() {
  local url="$1"
  local expected_sha256="$2"
  local destination="$3"
  local temporary
  local actual_sha256

  if [[ ! "$expected_sha256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Invalid SHA-256 pin for $url" >&2
    return 1
  fi

  mkdir -p "$(dirname "$destination")"
  temporary="$(mktemp "${destination}.tmp.XXXXXX")"
  # Retries cover the transfer only. A checksum mismatch below is never retried:
  # that is a tampered or moved artefact, not a flaky connection, and trying
  # again would only turn a loud failure into an intermittent one.
  if ! curl \
    --fail \
    --location \
    --silent \
    --show-error \
    --retry 3 \
    --retry-connrefused \
    --retry-delay 5 \
    --connect-timeout 30 \
    --proto '=https,file' \
    --tlsv1.2 \
    --output "$temporary" \
    "$url"; then
    rm -f "$temporary"
    return 1
  fi

  actual_sha256="$(sha256_file "$temporary")"
  if [ "$actual_sha256" != "$expected_sha256" ]; then
    echo "SHA-256 mismatch for $url" >&2
    echo "Expected: $expected_sha256" >&2
    echo "Actual:   $actual_sha256" >&2
    rm -f "$temporary" "$destination"
    return 1
  fi

  mv "$temporary" "$destination"
}

checkout_verified_ref() {
  local url="$1"
  local ref="$2"
  local expected_commit="$3"
  local destination="$4"
  local mirror="${5:-}"
  local actual_commit
  local source
  local attempt

  if [[ ! "$expected_commit" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid Git commit pin for $url at $ref" >&2
    return 1
  fi

  # Retries and the mirror cover the transfer, never the verification. The commit
  # pin below is checked identically whichever source answered, so a mirror can
  # only supply the same tree or fail - it cannot substitute another one.
  #
  # This exists because code.videolan.org, the only source fetched over git,
  # refused connections for well over two minutes at a time across several CI
  # runs and took every build with it.
  rm -rf "$destination"
  for source in "$url" ${mirror:+"$mirror"}; do
    for attempt in 1 2 3; do
      if git clone --quiet --depth 1 --branch "$ref" --no-checkout \
        "$source" "$destination"; then
        break 2
      fi
      rm -rf "$destination"
      # No point pausing before giving up on this source.
      if [ "$attempt" -lt 3 ]; then sleep $((attempt * 5)); fi
    done
    echo "Could not clone $source at $ref after 3 attempts" >&2
  done
  if [ ! -d "$destination" ]; then
    echo "No source produced $ref for $url" >&2
    return 1
  fi

  actual_commit="$(git -C "$destination" rev-parse 'HEAD^{commit}')"
  if [ "$actual_commit" != "$expected_commit" ]; then
    echo "Git ref mismatch for $ref" >&2
    echo "Expected: $expected_commit" >&2
    echo "Actual:   $actual_commit" >&2
    rm -rf "$destination"
    return 1
  fi

  git -C "$destination" checkout --quiet --detach "$expected_commit"
}

cleanup_srcdir=""

cleanup() {
  if [ -n "$cleanup_srcdir" ]; then
    rm -rf -- "$cleanup_srcdir"
  fi
}

main() {
  local prefix="${PREFIX:-$(pwd)/libmpv-prefix}"
  local jobs="${JOBS:-$(nproc)}"
  local srcdir

  mkdir -p "$prefix"
  prefix="$(realpath "$prefix")"
  export PKG_CONFIG_PATH="$prefix/lib/pkgconfig:$prefix/lib/$(uname -m)-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}"

  srcdir="$(mktemp -d)"
  cleanup_srcdir="$srcdir"
  trap cleanup EXIT
  cd "$srcdir"

  echo "==> Sources in $srcdir"
  echo "==> Install prefix: $prefix"
  echo ""

  # ─── Step 1: ffmpeg (static libraries) ─────────────────────────────────────
  echo "==> Building ffmpeg $FFMPEG_VERSION (static, decoder-only)..."
  download_verified "$FFMPEG_URL" "$FFMPEG_SHA256" "$srcdir/ffmpeg.tar.xz"
  tar -xJf "$srcdir/ffmpeg.tar.xz"
  cd "ffmpeg-${FFMPEG_VERSION}"

  ./configure \
    --prefix="$prefix" \
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
    --enable-gnutls \
    --enable-vaapi \
    --disable-vdpau \
    --disable-debug \
    --disable-stripping

  make -j"$jobs"
  make install
  cd "$srcdir"
  echo ""
  echo "==> ffmpeg done."
  echo ""

  # ─── Step 2: shaderc (static library) ───────────────────────────────────────
  echo "==> Building shaderc $SHADERC_VERSION (static)..."
  checkout_verified_ref \
    "$SHADERC_URL" "$SHADERC_REF" "$SHADERC_COMMIT" \
    "$srcdir/shaderc-v${SHADERC_VERSION}"
  cd "shaderc-v${SHADERC_VERSION}"
  ./utils/git-sync-deps

  cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DSHADERC_SKIP_TESTS=ON \
    -DSHADERC_SKIP_EXAMPLES=ON \
    -DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON

  cmake --build build -j"$jobs"
  cmake --install build
  cd "$srcdir"
  echo ""
  echo "==> shaderc done."
  echo ""

  # ─── Step 3: libplacebo (static library) ───────────────────────────────────
  echo "==> Building libplacebo $LIBPLACEBO_VERSION (static)..."
  checkout_verified_ref \
    "$LIBPLACEBO_URL" "$LIBPLACEBO_REF" "$LIBPLACEBO_COMMIT" \
    "$srcdir/libplacebo-v${LIBPLACEBO_VERSION}" "$LIBPLACEBO_MIRROR"
  cd "libplacebo-v${LIBPLACEBO_VERSION}"
  git submodule update --init --recursive

  meson setup build \
    --prefix="$prefix" \
    --default-library=static \
    -Dvulkan=disabled \
    -Dd3d11=disabled \
    -Ddemos=false \
    -Dtests=false

  ninja -C build -j"$jobs"
  ninja -C build install
  cd "$srcdir"
  echo ""
  echo "==> libplacebo done."
  echo ""

  # ─── Step 4: mpv (shared libmpv) ───────────────────────────────────────────
  echo "==> Building mpv $MPV_VERSION (shared libmpv only)..."
  download_verified "$MPV_URL" "$MPV_SHA256" "$srcdir/mpv.tar.gz"
  tar -xzf "$srcdir/mpv.tar.gz"
  cd "mpv-${MPV_VERSION}"

  # The runner's only video path is a Wayland subsurface, and it hands mpv
  # MPV_RENDER_PARAM_WL_DISPLAY so VAAPI can find the device instead of falling
  # back to software decoding. A libmpv built without Wayland cannot use that.
  # VDPAU goes with X11 - it has no Wayland backend at all.
  meson setup build \
    --prefix="$prefix" \
    -Dlibmpv=true \
    -Dcplayer=false \
    -Dbuild-date=false \
    -Dlua=enabled \
    -Djavascript=enabled \
    -Dcplugins=disabled \
    -Dmanpage-build=disabled \
    -Djack=disabled \
    -Dvulkan=disabled \
    -Dd3d11=disabled \
    -Dgl=enabled \
    -Dvaapi=enabled \
    -Dalsa=enabled \
    -Dpulse=enabled \
    -Dpipewire=enabled \
    -Dvdpau=disabled \
    -Dwayland=enabled \
    -Dx11=disabled

  ninja -C build -j"$jobs"
  ninja -C build install
  echo ""
  echo "==> mpv done."
  echo ""
  echo "==> libmpv build complete. Output in $prefix"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
