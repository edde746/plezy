#!/bin/sh
# After the deb, rpm or pacman package is removed: the icon cache and the desktop database (the menu entry and its
# plezy:// scheme handler) refreshed.
if command -v gtk-update-icon-cache > /dev/null 2>&1; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
fi
if command -v update-desktop-database > /dev/null 2>&1; then
    update-desktop-database /usr/share/applications || true
fi
