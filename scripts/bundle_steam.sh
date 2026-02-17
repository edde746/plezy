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
# Iteratively resolve the main binary + all bundled .so files until no new deps appear.
echo ""
echo "==> Bundling runtime dependencies..."
RT_LIBS="/steam-rt-libs.txt"
while true; do
  new_count=0
  while read dep; do
    dep_name=$(basename "$dep")
    if ! grep -qF "$dep_name" "$RT_LIBS"; then
      if [ ! -f "$BUNDLE_LIB/$dep_name" ]; then
        echo "  Bundling $dep_name"
        cp -a "$dep" "$BUNDLE_LIB/"
        dep_dir=$(dirname "$dep")
        dep_base=$(echo "$dep_name" | sed 's/\.so.*//')
        cp -a "$dep_dir"/${dep_base}.so* "$BUNDLE_LIB/" 2>/dev/null || true
        new_count=$((new_count + 1))
      fi
    fi
  done < <({ ldd "$BUNDLE/plezy" 2>/dev/null; find "$BUNDLE_LIB" -name '*.so*' -type f -exec ldd {} \; 2>/dev/null; } | grep "=> /" | awk '{print $3}' | sort -u)
  if [ "$new_count" -eq 0 ]; then
    break
  fi
  echo "  Bundled $new_count new libraries, re-scanning..."
done

# Verify all deps resolve
echo ""
echo "==> Checking dependencies..."
MISSING=$({ LD_LIBRARY_PATH="$BUNDLE_LIB" ldd "$BUNDLE/plezy" 2>&1; find "$BUNDLE_LIB" -name '*.so*' -type f -exec env LD_LIBRARY_PATH="$BUNDLE_LIB" ldd {} \; 2>&1; } | grep "not found" | sort -u || true)
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
