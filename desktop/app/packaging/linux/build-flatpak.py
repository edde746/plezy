#!/usr/bin/env python3
"""Package the Linux app image (`:app-desktop:createReleaseDistributable`) as a Flatpak bundle.

The Flatpak (com.edde746.plezy.json next to this script) holds the app image as built, with its JetBrains Runtime
and libmpv, and in /app/lib the Ubuntu 24.04 libraries mpv-build's libmpv links under sonames the freedesktop runtime
lacks (linux_image.UBUNTU_LIBS): liblua5.2.so.0, libmujs.so.3 and libdisplay-info.so.1, and libbz2.so.1.0 (Debian's
soname; the runtime has libbz2.so.1). Each Ubuntu package's copyright file, which carries its licence (MIT, ISC, the
bzip2 licence) and copyright notices, is in the repository's licenses/linux/<library>/copyright, which the app image
carries with the other licence texts of the Linux app (licenses/apps.json) in lib/app/resources/licenses, where About
reads them; this script refuses a package whose copyright file differs from it, and the Flatpak copies that folder to
/app/share/licenses/com.edde746.plezy, and libmpv's licence texts (the libmpv artifact's licenses/, which the app
image carries in lib/app/resources/mpv/licenses) to its mpv-build/. The sandbox gets a Wayland socket, and an X11 one
only outside a Wayland session (fallback-x11): the app is a native Wayland client, the one its video plane needs. It
also gets the network, PulseAudio, the GPU (dri), the Secret Service, where LibsecretStore keeps the account's
secrets, the screen saver service (LinuxDisplayAwake), Discord's sockets (discord-ipc-0 to 9 in the runtime folder,
and the folders Flatpak Discord and Discord Canary put theirs in, which DiscordIpc looks in), and Plezy in the user's
Videos folder (xdg-videos/Plezy, created on the host), the default downloads folder: the sandbox's home is in memory.
Its file dialogs are the desktop portal's. The app's MPRIS name, org.mpris.MediaPlayer2.com.edde746.plezy, is one
Flatpak lets every app own under its app id.

It also holds Noto Sans in /app/share/fonts, where the runtime's fontconfig looks (freedesktop-sdk's 50-flatpak.conf),
with its licence (SIL OFL 1.1) among the licence texts (licenses/linux/noto-sans). Compose's sans serif on Linux is
Noto Sans, else DejaVu Sans, and the runtime has only DejaVu: without it the app's font, and whether a navigation label
fits its 72 dp, depended on the host's fonts. The release's hinted TTFs (those Arch's noto-fonts installs) at the
weights the Compose UI draws: Regular, Medium, SemiBold (the theme's headlines and titles) and Bold. Static files, not
the variable font: Skia's fontconfig font manager opens the face fontconfig matched without its variations, so a
variable font's weights would rest on fontconfig always matching one of its named instances.

Needs flatpak, and flatpak-builder (with unzip) or the org.flatpak.Builder flatpak, with org.freedesktop.Platform and
org.freedesktop.Sdk 26.08 for the target architecture installed for the user. Downloads only the Noto Sans release the
manifest pins by sha256.

  build-flatpak.py --app desktop/app/build/compose/binaries/main-release/app/Plezy --libs <dir> --arch x64 [--output <dir>]

--libs is searched for those libraries by name and for their packages' copyright files (usr/share/doc/<package>/
copyright; the release workflow passes the tree dpkg-deb unpacked the Ubuntu packages into). Writes
<output>/plezy-linux-<arch>.flatpak; check-flatpak.py checks it once installed.
"""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

from linux_image import APP_ID, ARCHITECTURES, UBUNTU_LIBS, check_image, elf_machine, notice_problem

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parents[3]


def builder() -> list[str]:
    """flatpak-builder from the host, else the org.flatpak.Builder flatpak."""
    if shutil.which("flatpak-builder"):
        return ["flatpak-builder"]
    if subprocess.run(["flatpak", "info", "--user", "org.flatpak.Builder"], capture_output=True).returncode == 0:
        return ["flatpak", "run", "org.flatpak.Builder"]
    raise SystemExit("Neither flatpak-builder nor the org.flatpak.Builder flatpak (--user) is installed")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--app", required=True, type=Path, help="the app image (createReleaseDistributable's Plezy/)")
    parser.add_argument("--libs", required=True, type=Path, help="a tree holding the Ubuntu libraries")
    parser.add_argument("--arch", required=True, choices=ARCHITECTURES)
    parser.add_argument("--output", type=Path, default=Path.cwd())
    args = parser.parse_args()
    architecture, machine = ARCHITECTURES[args.arch]

    app = args.app.resolve()
    for problem in check_image(app, args.arch):
        parser.error(problem)
    libraries = {}
    for soname, (package, folder) in UBUNTU_LIBS.items():
        found = sorted(args.libs.rglob(soname))
        if not found or elf_machine(found[0].resolve()) != machine:
            parser.error(f"{args.libs}: no {architecture} {soname}")
        notice = sorted(args.libs.rglob(f"doc/{package}/copyright"))
        if not notice:
            parser.error(f"{args.libs}: no usr/share/doc/{package}/copyright")
        problem = notice_problem(app, package, folder, notice[0])
        if problem:
            parser.error(problem)
        libraries[soname] = found[0].resolve()

    args.output.mkdir(parents=True, exist_ok=True)
    output = args.output.resolve() / f"plezy-linux-{args.arch}.flatpak"
    # The staging directory sits beside the output, not in /tmp: the org.flatpak.Builder flatpak has its own /tmp.
    with tempfile.TemporaryDirectory(prefix=".plezy-flatpak-", dir=args.output) as temporary:
        stage = Path(temporary)
        shutil.copytree(app, stage / "Plezy", symlinks=True)
        (stage / "ubuntu-libs").mkdir()
        for soname, library in libraries.items():
            shutil.copyfile(library, stage / "ubuntu-libs" / soname)
        shutil.copytree(ROOT / "desktop" / "app" / "icons" / "hicolor", stage / "hicolor")
        for name in (f"{APP_ID}.desktop", f"{APP_ID}.json", f"{APP_ID}.metainfo.xml"):
            shutil.copy2(SCRIPT_DIR / name, stage)

        subprocess.run([
            *builder(), "--user", "--disable-rofiles-fuse", "--force-clean", f"--arch={architecture}",
            f"--state-dir={stage / 'state'}", f"--repo={stage / 'repo'}", str(stage / "build"), f"{APP_ID}.json",
        ], check=True, cwd=stage)
        # Published only once flatpak has written the whole bundle.
        bundle = stage / output.name
        subprocess.run([
            "flatpak", "build-bundle", f"--arch={architecture}",
            "--runtime-repo=https://flathub.org/repo/flathub.flatpakrepo",
            str(stage / "repo"), str(bundle), APP_ID, "master",
        ], check=True)
        shutil.move(bundle, output)
    print(f"Created: {output}")


if __name__ == "__main__":
    main()
