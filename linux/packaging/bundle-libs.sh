#!/usr/bin/env bash
#
# bundle-libs.sh — Bundle shared libraries and GTK modules into a Flutter
# Linux bundle directory so the resulting tarball is portable.
#
# Usage: bundle-libs.sh <bundle-dir>
#
# The bundle directory should contain the main binary and a lib/ subdirectory.
# After running, lib/ will contain all required shared libraries (minus the
# exclusion list), GTK/GDK modules, and GSettings schemas.

set -euo pipefail

BUNDLE_DIR="$(realpath "$1")"
LIB_DIR="$BUNDLE_DIR/lib"
BINARY="$BUNDLE_DIR/plezy"

if [[ ! -f "$BINARY" ]]; then
    echo "Error: binary not found at $BINARY" >&2
    exit 1
fi

# ── Exclusion list ──────────────────────────────────────────────────────────
# Libraries that must come from the host system.
EXCLUDE_PATTERN='linux-vdso\.so|ld-linux.*\.so|libc\.so|libm\.so|libpthread\.so|libdl\.so|librt\.so|libmvec\.so|libresolv\.so|libnss_.*\.so|libGL\.so|libEGL\.so|libGLX\.so|libGLESv2\.so|libGLdispatch\.so|libOpenGL\.so|libvulkan\.so|libdrm\.so|libgbm\.so|libnvidia.*\.so|libcuda.*\.so|libasound\.so'

# ── Helper: collect ldd deps ───────────────────────────────────────────────
collect_deps() {
    # Collect resolved library paths from ldd output for the given files.
    # Filters out excluded libs and libs that don't exist on disk.
    ldd "$@" 2>/dev/null \
        | grep -oP '(?<==> )/\S+' \
        | sort -u \
        | grep -vE "$EXCLUDE_PATTERN" \
        || true
}

# ── Explicitly bundle dlopen'd libraries ───────────────────────────────────
# These are loaded at runtime via dlopen() and invisible to ldd.
bundle_dlopen_lib() {
    local name="$1"
    local path
    path="$(ldconfig -p | grep -oP "/\S+/${name}[^\s]*" | head -1 || true)"
    if [[ -n "$path" && -f "$path" ]]; then
        local base
        base="$(basename "$path")"
        if [[ ! -f "$LIB_DIR/$base" ]]; then
            echo "==> Bundling dlopen'd library: $path"
            cp -L "$path" "$LIB_DIR/$base"
        fi
    else
        echo "WARNING: Could not find $name" >&2
    fi
}

echo "==> Discovering shared library dependencies..."

# Seed: the main binary + all .so files already in lib/
mapfile -t seed_files < <(find "$LIB_DIR" -name '*.so*' -type f 2>/dev/null; echo "$BINARY")

# Iteratively resolve until no new deps appear
declare -A seen
while true; do
    mapfile -t deps < <(collect_deps "${seed_files[@]}")
    new_files=()
    for dep in "${deps[@]}"; do
        base="$(basename "$dep")"
        if [[ -z "${seen[$base]:-}" && ! -f "$LIB_DIR/$base" ]]; then
            seen[$base]=1
            cp -L "$dep" "$LIB_DIR/$base" 2>/dev/null || true
            new_files+=("$LIB_DIR/$base")
        fi
    done
    if [[ ${#new_files[@]} -eq 0 ]]; then
        break
    fi
    echo "    Bundled ${#new_files[@]} new libraries"
    seed_files=("${new_files[@]}")
done

# ── GTK modules (loaded via dlopen, invisible to ldd) ──────────────────────

bundle_module_dir() {
    local src_dir="$1" dest_dir="$2"
    if [[ -d "$src_dir" ]]; then
        echo "==> Bundling modules from $src_dir"
        mkdir -p "$dest_dir"
        find "$src_dir" -name '*.so' -exec cp -L {} "$dest_dir/" \;
        # Resolve transitive deps of module .so files
        mapfile -t mod_deps < <(collect_deps "$dest_dir"/*.so 2>/dev/null)
        for dep in "${mod_deps[@]}"; do
            base="$(basename "$dep")"
            if [[ ! -f "$LIB_DIR/$base" ]]; then
                cp -L "$dep" "$LIB_DIR/$base" 2>/dev/null || true
            fi
        done
    fi
}

# gdk-pixbuf loaders
PIXBUF_MODULE_DIR="$(pkg-config --variable=gdk_pixbuf_moduledir gdk-pixbuf-2.0 2>/dev/null || true)"
PIXBUF_DEST="$LIB_DIR/gdk-pixbuf-2.0/2.10.0/loaders"
if [[ -n "$PIXBUF_MODULE_DIR" && -d "$PIXBUF_MODULE_DIR" ]]; then
    bundle_module_dir "$PIXBUF_MODULE_DIR" "$PIXBUF_DEST"
    # Regenerate loaders.cache with relative paths
    GDK_PIXBUF_MODULEDIR="$PIXBUF_DEST" \
        gdk-pixbuf-query-loaders "$PIXBUF_DEST"/*.so > "$LIB_DIR/gdk-pixbuf-2.0/2.10.0/loaders.cache" 2>/dev/null || true
fi

# GIO modules
GIO_MODULE_DIR="$(pkg-config --variable=giomoduledir gio-2.0 2>/dev/null || true)"
GIO_DEST="$LIB_DIR/gio/modules"
if [[ -n "$GIO_MODULE_DIR" && -d "$GIO_MODULE_DIR" ]]; then
    bundle_module_dir "$GIO_MODULE_DIR" "$GIO_DEST"
fi

# GTK IM modules + print backends
GTK_LIBDIR="$(pkg-config --variable=libdir gtk+-3.0 2>/dev/null || true)"
if [[ -n "$GTK_LIBDIR" ]]; then
    IM_MODULE_DIR="$GTK_LIBDIR/gtk-3.0/3.0.0/immodules"
    IM_DEST="$LIB_DIR/gtk-3.0/3.0.0/immodules"
    bundle_module_dir "$IM_MODULE_DIR" "$IM_DEST"

    # Regenerate IM modules cache
    if [[ -d "$IM_DEST" ]] && command -v gtk-query-immodules-3.0 &>/dev/null; then
        gtk-query-immodules-3.0 "$IM_DEST"/*.so > "$IM_DEST/../immodules.cache" 2>/dev/null || true
    fi

    PRINT_MODULE_DIR="$GTK_LIBDIR/gtk-3.0/3.0.0/printbackends"
    PRINT_DEST="$LIB_DIR/gtk-3.0/3.0.0/printbackends"
    bundle_module_dir "$PRINT_MODULE_DIR" "$PRINT_DEST"
fi

# ── GSettings schemas ─────────────────────────────────────────────────────
SCHEMAS_SRC="/usr/share/glib-2.0/schemas"
SCHEMAS_DEST="$BUNDLE_DIR/share/glib-2.0/schemas"
if [[ -d "$SCHEMAS_SRC" ]]; then
    echo "==> Bundling GSettings schemas"
    mkdir -p "$SCHEMAS_DEST"
    cp "$SCHEMAS_SRC"/*.xml "$SCHEMAS_DEST/" 2>/dev/null || true
    cp "$SCHEMAS_SRC"/*.override "$SCHEMAS_DEST/" 2>/dev/null || true
    glib-compile-schemas "$SCHEMAS_DEST" 2>/dev/null || true
fi

# ── Strip debug symbols ───────────────────────────────────────────────────
echo "==> Stripping debug symbols..."
find "$LIB_DIR" -name '*.so*' -type f -exec strip --strip-unneeded {} \; 2>/dev/null || true

echo "==> Done. Bundled libraries in $LIB_DIR"
du -sh "$LIB_DIR"
