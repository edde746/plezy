#!/usr/bin/env bash
# Regenerates the committed launcher, status-bar and desktop icons from tools/brand/plezy.svg (the mark) and
# tools/brand/plezy-adaptive-foreground.svg (the mark on the Android adaptive icon's canvas):
#   android/app/src/main/res/{mipmap-*,mipmap-anydpi-v26,drawable,drawable-night,drawable-*dpi}/
#                                                          (launcher icons, the adaptive icon's background, the media
#                                                          notification's status-bar icon)
#   desktop/app/icons/                                     (Windows .ico, Linux hicolor PNGs)
#   desktop/app/packaging/windows/assets/                  (the MSIX package's logos, tiles and splash screen)
# Plezy's other artwork is committed as is, not generated: apple/AppIcon.icon (the Icon Composer icon for iOS, iPadOS
# and macOS; open it in Icon Composer to edit), apple/Brand.xcassets (the tvOS layered icon and Top Shelf images) and
# android/app/src/main/res/drawable-*/banner.png (the Android TV banner).
# Needs python3, rsvg-convert (librsvg) and magick (ImageMagick 7). Outputs are byte-for-byte reproducible with the
# same tools. tools/brand/verify.sh checks the results, generated and committed, with actool and aapt2.
set -euo pipefail

cd "$(dirname "$0")/../.."

for tool in python3 rsvg-convert magick; do
  command -v "$tool" >/dev/null || { echo "generate.sh: $tool not found" >&2; exit 1; }
done

exec python3 tools/brand/brand.py
