#!/usr/bin/env bash
set -euo pipefail

APP_ID=4435320
DEPOT_WIN=4435321
DEPOT_LINUX=4435322
REPO="edde746/plezy"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK="$SCRIPT_DIR/build"

# Get latest release tag
TAG=$(gh release view --repo "$REPO" --json tagName -q .tagName)
echo "Latest release: $TAG"

rm -rf "$WORK"
mkdir -p "$WORK"

# Download & extract
echo "Downloading Windows build..."
gh release download "$TAG" --repo "$REPO" -p "plezy-windows-x64-portable.7z" -D "$WORK"
if [[ "$OSTYPE" == "darwin"* ]]; then
    unar -o "$WORK" "$WORK/plezy-windows-x64-portable.7z"
else
    7z x "$WORK/plezy-windows-x64-portable.7z" -o"$WORK" -y
fi
mv "$WORK"/plezy-windows-x64-portable "$WORK/windows"

echo "Extracting Linux Steam build..."
STEAM_TARBALL="$SCRIPT_DIR/../plezy-steam-linux-x64.tar.gz"
if [[ ! -f "$STEAM_TARBALL" ]]; then
    echo "Error: $STEAM_TARBALL not found. Run build_steam.sh first." >&2
    exit 1
fi
mkdir -p "$WORK/linux"
tar xzf "$STEAM_TARBALL" -C "$WORK/linux"

# Generate VDF files
cat > "$WORK/app_build.vdf" <<EOF
"appbuild"
{
    "appid" "$APP_ID"
    "desc" "$TAG"
    "buildoutput" "$WORK/output"
    "contentroot" "$WORK"
    "setlive" "public"
    "depots"
    {
        "$DEPOT_WIN"
        {
            "FileMapping"
            {
                "LocalPath" "windows/*"
                "DepotPath" "."
                "recursive" "1"
            }
        }
        "$DEPOT_LINUX"
        {
            "FileMapping"
            {
                "LocalPath" "linux/*"
                "DepotPath" "."
                "recursive" "1"
            }
        }
    }
}
EOF

mkdir -p "$WORK/output"

echo "Uploading to Steam..."
steamcmd +login "$STEAM_USER" +run_app_build "$WORK/app_build.vdf" +quit

echo "Done! Uploaded $TAG to Steam."
