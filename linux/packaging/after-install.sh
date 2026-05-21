#!/bin/bash
# Ensure binaries are executable
chmod +x /usr/bin/vibe_stream
chmod +x /opt/vibe_stream/vibe_stream
chmod +x /opt/vibe_stream/lib/crashpad_handler

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
fi

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database /usr/share/applications || true
fi
