"""What the Linux packaging scripts know about the desktop app image (`:app-desktop:createReleaseDistributable`'s
Plezy/).

The image is self-contained but for libraries of the host: its launcher bin/Plezy, the app's jars and resources in
lib/app (libmpv.so.2 in lib/app/resources/mpv) and JetBrains Runtime in lib/runtime. mpv-build's libmpv is built on
Ubuntu 24.04 and links four libraries under Ubuntu's sonames, which other distributions ship under other ones or not
at all (UBUNTU_LIBS): every package carries those, with their Ubuntu packages' copyright files, which the image
already has among its licence texts (licenses/linux/<folder>/copyright in the repository).
"""

from pathlib import Path
import struct

APP_ID = "com.edde746.plezy"
# Release architecture → (Flatpak and AppImage architecture, ELF e_machine).
ARCHITECTURES = {"x64": ("x86_64", 62), "arm64": ("aarch64", 183)}
# soname → the Ubuntu package that ships it, and the licence folder of the app's notice of it, which holds that
# package's copyright file.
UBUNTU_LIBS = {
    "liblua5.2.so.0": ("liblua5.2-0", "lua"),
    "libmujs.so.3": ("libmujs3", "mujs"),
    "libdisplay-info.so.1": ("libdisplay-info1", "libdisplay-info"),
    "libbz2.so.1.0": ("libbz2-1.0", "bzip2"),
}
# Where the deb, rpm and pacman packages, the tarball and the AppImage put UBUNTU_LIBS, relative to the image's root;
# plezy.sh puts it on the dynamic linker's path.
MPV_DEPS = Path("lib") / "mpv-deps"


def elf_machine(path: Path) -> int | None:
    """The e_machine of a little-endian 64-bit ELF file, else None."""
    with path.open("rb") as file:
        header = file.read(20)
    if len(header) != 20 or header[:6] != b"\x7fELF\x02\x01":
        return None
    return struct.unpack_from("<H", header, 18)[0]


def debug_sections(path: Path) -> list[str]:
    """The DWARF sections (.debug_*, .zdebug_*) of a little-endian 64-bit ELF file; empty for any other file."""
    if elf_machine(path) is None:
        return []
    data = path.read_bytes()
    shoff, = struct.unpack_from("<Q", data, 0x28)
    shentsize, shnum, shstrndx = struct.unpack_from("<HHH", data, 0x3A)
    sections = [struct.unpack_from("<IIQQQQ", data, shoff + i * shentsize) for i in range(shnum)]
    names = sections[shstrndx][4] if sections else 0
    found = []
    for name_offset, *_ in sections:
        name = data[names + name_offset:data.index(b"\0", names + name_offset)].decode()
        if name.startswith((".debug_", ".zdebug_")):
            found.append(name)
    return found


def check_image(app: Path, arch: str) -> list[str]:
    """What is wrong with `app` as the app image for `arch`: nothing when the list is empty."""
    architecture, machine = ARCHITECTURES[arch]
    problems = []
    launcher = app / "bin" / "Plezy"
    if not launcher.is_file() or elf_machine(launcher) != machine:
        problems.append(f"{launcher} is not a 64-bit {architecture} executable")
    # The app needs JetBrains Runtime on Linux: its Wayland toolkit, and on another runtime AWT misses resizes by the
    # window manager. jlink's release file names no vendor; the java.base image carries it (java.vendor).
    modules = app / "lib" / "runtime" / "lib" / "modules"
    if not modules.is_file() or b"JetBrains s.r.o." not in modules.read_bytes():
        problems.append(f"{modules}: the app image's runtime is not JetBrains Runtime")
    if not any((app / "lib" / "app" / "resources" / "mpv").rglob("libmpv.so.2")):
        problems.append(f"{app}: no libmpv.so.2 in the app resources")
    # The release ships no debug information: debug files go to the crash-report server instead.
    for path in sorted(app.rglob("*")):
        if path.is_file() and not path.is_symlink() and (sections := debug_sections(path)):
            problems.append(f"{path} carries debug information ({', '.join(sections)}): strip it")
    return problems


def notice_problem(app: Path, package: str, folder: str, copyright_file: Path) -> str | None:
    """Why the image's licence text of `package` is not that package's copyright file, or None when it is."""
    shipped = app / "lib" / "app" / "resources" / "licenses" / folder / "copyright"
    if not shipped.is_file() or shipped.read_bytes() != copyright_file.read_bytes():
        return f"{shipped}: not {package}'s copyright file {copyright_file} (refresh licenses/linux/{folder} with the package)"
    return None
