#!/usr/bin/env bash
set -e

APP_NAME="plezy"
VERSION="1.0.0"
ARCH="amd64"
DEB_DIR="${APP_NAME}_${VERSION}_${ARCH}"

rm -rf "$DEB_DIR" "$DEB_DIR.deb"

mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/lib/$APP_NAME"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/256x256/apps"

# Control file
cat <<EOF > "$DEB_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: Plezy Developer <developer@plezy.app>
Description: Plezy Media Player Client
 A modern media browser client for Jellyfin, Emby, and Plex.
EOF

# Copy flutter bundle
cp -r build/linux/x64/release/bundle/* "$DEB_DIR/usr/lib/$APP_NAME/"

# Create symlink executable
ln -s "/usr/lib/$APP_NAME/plezy" "$DEB_DIR/usr/bin/$APP_NAME"

# Copy desktop launcher
if [ -f "linux/packaging/app.desktop" ]; then
    cp "linux/packaging/app.desktop" "$DEB_DIR/usr/share/applications/plezy.desktop"
else
    cat <<EOF > "$DEB_DIR/usr/share/applications/plezy.desktop"
[Desktop Entry]
Name=Plezy
Comment=Plezy Media Player
Exec=/usr/bin/plezy
Icon=plezy
Terminal=false
Type=Application
Categories=Video;AudioVideo;Player;
EOF
fi

# Copy icon
if [ -f "assets/icons/app_icon.png" ]; then
    cp "assets/icons/app_icon.png" "$DEB_DIR/usr/share/icons/hicolor/256x256/apps/plezy.png"
fi

# Build deb package
dpkg-deb --build "$DEB_DIR" "${APP_NAME}_${VERSION}_${ARCH}.deb"
echo "🎉 DEB paketi başarıyla oluşturuldu: ${APP_NAME}_${VERSION}_${ARCH}.deb"
