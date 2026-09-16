#!/usr/bin/env python3
"""Relocate GTK module caches from the release builder into the Flatpak prefix."""

from pathlib import Path
import re
import sys

bundle = Path(sys.argv[1])
for cache, modules in (
    (bundle / "lib/gdk-pixbuf-2.0/2.10.0/loaders.cache", "loaders"),
    (bundle / "lib/gtk-3.0/3.0.0/immodules.cache", "immodules"),
):
    if not cache.exists():
        continue

    def relocate(match):
        module = cache.parent / modules / Path(match.group(1)).name
        if not module.is_file():
            raise FileNotFoundError(f"Cached GTK module is missing: {module}")
        return f'"{module}"'

    cache.write_text(re.sub(r'^"([^"]+\.so)"', relocate, cache.read_text(), flags=re.MULTILINE))
