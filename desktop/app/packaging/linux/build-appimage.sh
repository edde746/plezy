#!/usr/bin/env bash
# Packages the Linux app image as plezy-linux-<arch>.AppImage and its plezy-linux-<arch>.AppImage.zsync.
#
#   build-appimage.sh --app <image dir> --arch x64|arm64 --output <dir>
#
# stage-image.py assembles the tree (the image, plezy.sh, lib/mpv-deps; see build-packages.py for the host it needs);
# the AppDir is that tree with AppRun, a link to plezy.sh, the desktop entry and the 256 px icon at its root.
# appimagetool and the AppImage runtime are fixed releases, downloaded and checked by sha256 before either runs (left
# alone, appimagetool would embed whichever runtime is newest on the day). The AppImage carries the update information
# gh-releases-zsync|edde746|plezy|latest|plezy-linux-<arch>.AppImage.zsync, which Gear Lever and AppImageUpdate read:
# they fetch that .zsync from the latest GitHub release and the AppImage named the same without .zsync. appimagetool
# writes the .zsync with zsyncmake, and only warns without it, so a missing zsyncmake fails here, and so does an
# AppImage that doesn't report its update information. Needs python3, curl, sha256sum, file and zsyncmake (zsync); runs
# appimagetool without FUSE (APPIMAGE_EXTRACT_AND_RUN).
set -euo pipefail

usage() { echo "usage: $0 --app <image dir> --arch x64|arm64 --output <dir>" >&2; exit 2; }
app="" arch="" output=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --app) app=${2:-}; shift 2 ;;
        --arch) arch=${2:-}; shift 2 ;;
        --output) output=${2:-}; shift 2 ;;
        *) usage ;;
    esac
done
[[ -n $app && -n $arch && -n $output ]] || usage

appimagetool_version=1.9.1
runtime_version=20251108
case $arch in
    x64)
        appimage_arch=x86_64
        appimagetool_sha256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
        runtime_sha256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d
        ;;
    arm64)
        appimage_arch=aarch64
        appimagetool_sha256=f0837e7448a0c1e4e650a93bb3e85802546e60654ef287576f46c71c126a9158
        runtime_sha256=00cbdfcf917cc6c0ff6d3347d59e0ca1f7f45a6df1a428a0d6d8a78664d87444
        ;;
    *) usage ;;
esac
command -v zsyncmake > /dev/null || { echo "zsyncmake (zsync) is not installed: the AppImage would get no .zsync" >&2; exit 1; }

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../../../.." && pwd)"
mkdir -p "$output"
output="$(cd "$output" && pwd)"
name="plezy-linux-$arch.AppImage"
update="gh-releases-zsync|edde746|plezy|latest|$name.zsync"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir "$work/tools"
curl -fsSL --retry 3 -o "$work/tools/appimagetool" \
    "https://github.com/AppImage/appimagetool/releases/download/$appimagetool_version/appimagetool-$appimage_arch.AppImage"
curl -fsSL --retry 3 -o "$work/tools/runtime" \
    "https://github.com/AppImage/type2-runtime/releases/download/$runtime_version/runtime-$appimage_arch"
echo "$appimagetool_sha256  $work/tools/appimagetool" | sha256sum --check --strict
echo "$runtime_sha256  $work/tools/runtime" | sha256sum --check --strict
chmod +x "$work/tools/appimagetool"

python3 "$here/stage-image.py" --app "$app" --arch "$arch" --output "$work"
appdir="$work/plezy"
ln -s plezy.sh "$appdir/AppRun"
cp "$here/com.edde746.plezy.desktop" "$appdir/"
cp "$root/desktop/app/icons/hicolor/256x256/apps/com.edde746.plezy.png" "$appdir/plezy.png"
ln -s plezy.png "$appdir/.DirIcon"

rm -f "$output/$name" "$output/$name.zsync"
# zsyncmake writes the .zsync into the working directory, which appimagetool changes to $OWD first: an OWD inherited
# from an AppImage further up the process tree is replaced too.
(cd "$output" && OWD="$output" ARCH="$appimage_arch" APPIMAGE_EXTRACT_AND_RUN=1 "$work/tools/appimagetool" \
    --no-appstream --runtime-file "$work/tools/runtime" --updateinformation "$update" "$appdir" "$output/$name")

[[ -s $output/$name.zsync ]] || { echo "appimagetool wrote no $output/$name.zsync" >&2; exit 1; }
embedded=$("$output/$name" --appimage-updateinformation)
[[ $embedded == "$update" ]] || { echo "$name reports the update information '$embedded', not '$update'" >&2; exit 1; }
echo "Created: $output/$name and $name.zsync ($embedded)"
