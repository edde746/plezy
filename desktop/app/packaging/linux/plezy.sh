#!/usr/bin/env bash
# Starts Plezy with its arguments (a plezy:// link among them). The deb, rpm and pacman packages install this as
# /usr/bin/plezy and the app in /opt/plezy; the portable tarball has it at the app's root, and the AppImage's AppRun
# is a link to it. libmpv links four libraries under Ubuntu's sonames that the app carries in lib/mpv-deps (other
# distributions ship them under other sonames or not at all): the dynamic linker finds them there when the app loads
# libmpv.
set -euo pipefail
dir="$(dirname "$(readlink -f "$0")")"
[[ $dir != /usr/bin ]] || dir=/opt/plezy
export LD_LIBRARY_PATH="$dir/lib/mpv-deps${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$dir/bin/Plezy" "$@"
