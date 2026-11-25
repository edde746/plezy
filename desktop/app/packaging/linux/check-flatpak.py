#!/usr/bin/env python3
"""Check the installed Plezy Flatpak against its runtime, not the build SDK, and its sandbox's permissions.

Run after `flatpak install --user plezy-linux-<arch>.flatpak`, under a session bus (`dbus-run-session -- ...`).
Inside the sandbox, with nothing on LD_LIBRARY_PATH: every ELF object of the app image and /app/lib resolves all its
dependencies, the bundled runtime is JetBrains Runtime, libmpv is in the app's resources and every licence text the
Linux app ships is in the app image's resources, where About reads it, and in /app/share/licenses/com.edde746.plezy:
licenses/apps.json's linux groups of the repository's licenses/ in the resources' licenses/ and at that folder's top,
and the licenses/ folder of the libmpv artifact the app image was built with (desktop/mpv/build/mpv/<arch>/licenses)
in the resources' mpv/licenses/ and that folder's mpv-build/. Then what the
app relies on in the sandbox, whose home folder is in memory: with a Videos folder on the host (a temporary one, named
in a user-dirs.dirs of its own), the sandbox's Videos folder is the host's and a file written in its Plezy folder
(the default downloads folder, DesktopDownloads.linuxFolder) is on the host; and the session bus lets the app own its
MPRIS name (LinuxMediaControls.BUS_NAME) while it refuses one outside the app id's. This does not replace running the
app in a Wayland session.
"""

import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile

APP_ID = "com.edde746.plezy"
MPRIS_NAME = f"org.mpris.MediaPlayer2.{APP_ID}"
# The licence texts the Linux app ships: its groups of the repository's licenses/, merged in the app image's resources.
LICENSES_DIR = Path(__file__).resolve().parents[4] / "licenses"
LICENSE_TEXTS = [LICENSES_DIR / group for group in json.loads((LICENSES_DIR / "apps.json").read_text())["linux"]]
# libmpv's: the licenses/ folder of mpv-jvm's extracted artifact, one per architecture.
MPV_ARTIFACTS = Path(__file__).resolve().parents[3] / "mpv" / "build" / "mpv"

# The runtime has bash, od, grep, find and ldd, but not necessarily Python or readelf: enumerate inside the sandbox,
# so the host never resolves these dependencies.
CHECK = r'''
set -euo pipefail
for executable in /app/bin/plezy /app/plezy/bin/Plezy; do
    test -x "$executable" || { echo "Not executable: $executable" >&2; exit 1; }
done
grep -aq 'JetBrains s.r.o.' /app/plezy/lib/runtime/lib/modules ||
    { echo "The bundled runtime is not JetBrains Runtime" >&2; exit 1; }
test -n "$(find /app/plezy/lib/app/resources/mpv -name libmpv.so.2)" ||
    { echo "No libmpv.so.2 in the app resources" >&2; exit 1; }
count=0
while IFS= read -r -d '' object; do
    magic=$(od -An -tx1 -N4 "$object")
    if [[ "$magic" != *"7f 45 4c 46"* ]]; then continue; fi
    # The JDK's libraries link libjvm.so by soname alone: the launcher has loaded it from lib/server before them.
    server=
    if [[ $object == /app/plezy/lib/runtime/* ]]; then server=/app/plezy/lib/runtime/lib/server; fi
    dependencies=$(LD_LIBRARY_PATH=$server ldd "$object" 2>&1) || { echo "$object: $dependencies" >&2; exit 1; }
    if [[ "$dependencies" == *"not found"* ]]; then
        printf 'Unresolved dependency in %s:\n%s\n' "$object" "$dependencies" >&2
        exit 1
    fi
    count=$((count + 1))
done < <(find /app/plezy /app/lib -type f -print0)
test "$count" -gt 0
printf 'Resolved all dependencies for %s ELF objects in the installed runtime.\n' "$count"
'''

# $1: the texts' folder in the app image's resources, $2: theirs in /app/share/licenses/<app id>; the rest: the texts,
# relative to those folders.
LICENSES = rf'''
set -euo pipefail
resources=/app/plezy/lib/app/resources/$1
shared=/app/share/licenses/{APP_ID}/$2
shift 2
missing=0
for text in "$@"; do
    for folder in "$resources" "$shared"; do
        test -s "$folder/$text" || {{ echo "No licence text $folder/$text" >&2; missing=1; }}
    done
done
test "$missing" -eq 0
printf "All %s licence texts are in %s and %s.\n" "$#" "$resources" "$shared"
'''

# $1: the host's Videos folder, $2: the probe file's name, $3: the MPRIS name.
SANDBOX = r'''
set -euo pipefail
videos=$(xdg-user-dir VIDEOS)
test "$videos" = "$1" || { echo "The sandbox's Videos folder is $videos, not the host's $1" >&2; exit 1; }
test -d "$videos/Plezy" || { echo "The sandbox has no $videos/Plezy" >&2; exit 1; }
echo plezy > "$videos/Plezy/$2"
bus() {
    gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.RequestName "$1" 4 2>&1
}
owned=$(bus "$3") || { echo "The session bus refused $3: $owned" >&2; exit 1; }
[[ "$owned" == "(uint32 1,)" ]] || { echo "Requesting $3 answered $owned" >&2; exit 1; }
if outside=$(bus org.mpris.MediaPlayer2.plezy); then
    echo "The session bus isn't the sandbox's filtered one: it gave org.mpris.MediaPlayer2.plezy ($outside)" >&2
    exit 1
fi
printf "The sandbox writes to the host's Videos/Plezy and may own %s.\n" "$3"
'''

parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument("--arch", choices=("x64", "arm64"), help="defaults to the host architecture")
args = parser.parse_args()
architecture = {"x64": "x86_64", "arm64": "aarch64"}.get(args.arch)
run = ["flatpak", "run", "--user", *([f"--arch={architecture}"] if architecture else []), "--command=bash", APP_ID, "-c"]

subprocess.run([*run, CHECK], check=True)
texts = sorted(str(text.relative_to(folder)) for folder in LICENSE_TEXTS for text in folder.rglob("*") if text.is_file())
if not texts:
    raise SystemExit(f"No licence texts in {', '.join(map(str, LICENSE_TEXTS))}")
subprocess.run([*run, LICENSES, "licenses", "licenses", ".", *texts], check=True)
mpv_licenses = MPV_ARTIFACTS / (architecture or platform.machine()) / "licenses"
mpv_texts = sorted(str(text.relative_to(mpv_licenses)) for text in mpv_licenses.rglob("*") if text.is_file())
if not mpv_texts:
    raise SystemExit(f"No licence texts in {mpv_licenses}, the app image's libmpv artifact")
subprocess.run([*run, LICENSES, "licenses", "mpv/licenses", "mpv-build", *mpv_texts], check=True)

# The sandbox has a /tmp of its own: the host's stand-in Videos folder goes in the home folder.
with tempfile.TemporaryDirectory(prefix=".check-flatpak-", dir=Path.home()) as temporary:
    host = Path(temporary)
    videos = host / "Videos"
    videos.mkdir()
    (host / "config").mkdir()
    (host / "config" / "user-dirs.dirs").write_text(f'XDG_VIDEOS_DIR="{videos}"\n')
    probe = ".check-flatpak"
    sandbox = subprocess.run([*run, SANDBOX, "sandbox", str(videos), probe, MPRIS_NAME],
                             env={**os.environ, "XDG_CONFIG_HOME": str(host / "config")})
    if sandbox.returncode != 0:
        raise SystemExit(f"The sandbox's check failed ({sandbox.returncode}): the manifest's finish-args")
    written = videos / "Plezy" / probe
    if not written.is_file() or written.read_text() != "plezy\n":
        raise SystemExit(f"The sandbox's write to its Videos/Plezy didn't reach the host's {written}")
    print(f"The host has the file the sandbox wrote into {videos / 'Plezy'}.")
