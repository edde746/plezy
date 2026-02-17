#!/usr/bin/env bash
set -euo pipefail

echo "==> Assembling Steam bundle..."
BUNDLE=build/linux/x64/release/bundle
BUNDLE_LIB="$BUNDLE/lib"

# Copy libmpv + shaderc into bundle
LIBMPV_DIR=$(dirname "$(find /build/libmpv-prefix -name libmpv.so | head -1)")
cp -a "$LIBMPV_DIR"/libmpv.so* "$BUNDLE_LIB/"
cp -a /build/libmpv-prefix/lib/libshaderc_shared.so* "$BUNDLE_LIB/"

# Bundle runtime deps that the Steam Runtime doesn't ship.
# /steam-rt-libs.txt was snapshot before we built anything (see Dockerfile).
echo ""
echo "==> Bundling runtime dependencies not in Steam Runtime..."
RT_LIBS="/steam-rt-libs.txt"

# Collect all binaries to scan: main binary, libmpv, and all plugin .so files.
SCAN_BINS=("$BUNDLE/plezy" "$LIBMPV_DIR/libmpv.so")
for so in "$BUNDLE_LIB"/*.so; do
  [ -f "$so" ] && SCAN_BINS+=("$so")
done

for bin in "${SCAN_BINS[@]}"; do
  ldd "$bin" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read dep; do
    dep_name=$(basename "$dep")
    if ! grep -qF "$dep_name" "$RT_LIBS"; then
      if [ ! -f "$BUNDLE_LIB/$dep_name" ]; then
        echo "  Bundling $dep_name (needed by $(basename "$bin"))"
        cp -a "$dep" "$BUNDLE_LIB/"
        dep_dir=$(dirname "$dep")
        dep_base=$(echo "$dep_name" | sed 's/\.so.*//')
        cp -a "$dep_dir"/${dep_base}.so* "$BUNDLE_LIB/" 2>/dev/null || true
      fi
    fi
  done
done

# Verify all deps resolve
echo ""
echo "==> Checking dependencies..."
MISSING=""
for bin in "$BUNDLE/plezy" "$BUNDLE_LIB"/*.so*; do
  [ -f "$bin" ] || continue
  MISSING+=$(LD_LIBRARY_PATH="$BUNDLE_LIB" ldd "$bin" 2>&1 | grep "not found" || true)
done
if [[ -n "$MISSING" ]]; then
  echo "WARNING: Unresolved dependencies (will need Steam runtime):"
  echo "$MISSING"
else
  echo "All dependencies resolved."
fi

# Create launcher script that sets LD_LIBRARY_PATH for bundled libs
echo ""
echo "==> Creating launcher script..."
mv "$BUNDLE/plezy" "$BUNDLE/plezy.bin"
cat > "$BUNDLE/plezy" <<'LAUNCHER'
#!/usr/bin/env bash
SCRIPT_PATH="$(readlink -f "$0")"
INSTALL_DIR="$(dirname "$SCRIPT_PATH")"

export LD_LIBRARY_PATH="$INSTALL_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

exec "$INSTALL_DIR/plezy.bin" "$@"
LAUNCHER
chmod +x "$BUNDLE/plezy"

echo ""
echo "==> Creating tarball..."
cd "$BUNDLE"
tar -czf /app/plezy-steam-linux-x64.tar.gz *

echo ""
echo "==> Done! Output: plezy-steam-linux-x64.tar.gz"
