#!/usr/bin/env python3
"""Compatibility entry point: regenerate selected branding for all icon slots.

The 23 permanent alternate ids remain in AndroidManifest.xml, tvOS Info.plist
and the Dart catalog. Every slot now uses the approved nested-play logo; only
the theme backplate differs. See docs/maintainers/branding.md.
"""

from generate_brand_assets import ICONS, main

if __name__ == "__main__":
    raise SystemExit(main())
