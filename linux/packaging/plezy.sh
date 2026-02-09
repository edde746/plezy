#!/usr/bin/env bash
# Wrapper script for Plezy. Works for both:
#   - Portable tarball (run from extracted directory)
#   - System packages (/usr/bin/plezy -> /opt/plezy/)

# Resolve the real path of this script, following symlinks
SCRIPT_PATH="$(readlink -f "$0")"
INSTALL_DIR="$(dirname "$SCRIPT_PATH")"

# If we're in /usr/bin, the actual install is in /opt/plezy
if [[ "$INSTALL_DIR" == "/usr/bin" ]]; then
    INSTALL_DIR="/opt/plezy"
fi

# Prepend bundled libraries to LD_LIBRARY_PATH
if [[ -d "$INSTALL_DIR/lib" ]]; then
    export LD_LIBRARY_PATH="$INSTALL_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

# gdk-pixbuf loaders
if [[ -f "$INSTALL_DIR/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" ]]; then
    export GDK_PIXBUF_MODULE_FILE="$INSTALL_DIR/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
fi

# GIO modules
if [[ -d "$INSTALL_DIR/lib/gio/modules" ]]; then
    export GIO_MODULE_DIR="$INSTALL_DIR/lib/gio/modules"
fi

# GTK IM modules
if [[ -f "$INSTALL_DIR/lib/gtk-3.0/3.0.0/immodules.cache" ]]; then
    export GTK_IM_MODULE_FILE="$INSTALL_DIR/lib/gtk-3.0/3.0.0/immodules.cache"
fi

# GTK module path (print backends, etc.)
if [[ -d "$INSTALL_DIR/lib/gtk-3.0" ]]; then
    export GTK_PATH="$INSTALL_DIR/lib/gtk-3.0"
fi

# GSettings schemas
if [[ -d "$INSTALL_DIR/share/glib-2.0/schemas" ]]; then
    export GSETTINGS_SCHEMA_DIR="$INSTALL_DIR/share/glib-2.0/schemas"
fi

exec "$INSTALL_DIR/plezy" "$@"
