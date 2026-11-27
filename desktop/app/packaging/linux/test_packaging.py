"""The Linux packaging scripts' contracts: python3 -m unittest discover desktop/app/packaging/linux"""

import configparser
import importlib.util
import json
import os
from pathlib import Path
import stat
import struct
import subprocess
import sys
import tempfile
import textwrap
import unittest
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from linux_image import APP_ID, MPV_DEPS, UBUNTU_LIBS, debug_sections  # noqa: E402


def load(script: str):
    spec = importlib.util.spec_from_file_location(script.replace("-", "_").removesuffix(".py"), HERE / script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


packages = load("build-packages.py")
host_deps = load("check-host-deps.py")

# Which Ubuntu 24.04 package provides each host library, and what it Provides: what dpkg answers on the build host,
# for the guard's stand-in dpkg-query.
UBUNTU_OWNERS = {
    "libEGL.so.1": ("libegl1", ""),
    "libGL.so.1": ("libgl1", ""),
    "libX11.so.6": ("libx11-6", ""),
    "libXext.so.6": ("libxext6", ""),
    "libXi.so.6": ("libxi6", ""),
    "libXrandr.so.2": ("libxrandr2", ""),
    "libXrender.so.1": ("libxrender1", ""),
    "libXtst.so.6": ("libxtst6", ""),
    "libasound.so.2": ("libasound2t64", "libasound2 (= 1.2.11-1build2)"),
    "libdrm.so.2": ("libdrm2", ""),
    "libfontconfig.so.1": ("libfontconfig1", ""),
    "libfreetype.so.6": ("libfreetype6", ""),
    "libfribidi.so.0": ("libfribidi0", ""),
    "libgbm.so.1": ("libgbm1", ""),
    "libglib-2.0.so.0": ("libglib2.0-0t64", "libglib2.0-0 (= 2.80.0-6ubuntu3)"),
    "libgnutls.so.30": ("libgnutls30t64", "libgnutls30 (= 3.8.3-1.1ubuntu3)"),
    "libharfbuzz.so.0": ("libharfbuzz0b", ""),
    "liblcms2.so.2": ("liblcms2-2", ""),
    "libpipewire-0.3.so.0": ("libpipewire-0.3-0t64", "libpipewire-0.3-0 (= 1.0.5-1ubuntu1)"),
    "libpulse.so.0": ("libpulse0", ""),
    "libsecret-1.so.0": ("libsecret-1-0", ""),
    "libstdc++.so.6": ("libstdc++6", ""),
    "libva-drm.so.2": ("libva-drm2", ""),
    "libva-wayland.so.2": ("libva-wayland2", ""),
    "libva-x11.so.2": ("libva-x11-2", ""),
    "libva.so.2": ("libva2", ""),
    "libwayland-client.so.0": ("libwayland-client0", ""),
    "libwayland-cursor.so.0": ("libwayland-cursor0", ""),
    "libwayland-egl.so.1": ("libwayland-egl1", ""),
    "libxkbcommon.so.0": ("libxkbcommon0", ""),
    "libz.so.1": ("zlib1g", ""),
}


class DependsTest(unittest.TestCase):
    def test_every_rpm_and_pacman_dependency_is_the_package_of_a_library_the_app_needs(self):
        for distro in ("rpm", "pacman"):
            needed = {packages_of[distro] for packages_of in host_deps.OTHER_DISTROS.values()}
            self.assertEqual(set(packages.DEPENDS[distro]), needed, distro)

    def test_the_libraries_loaded_at_run_time_have_rpm_and_pacman_packages(self):
        self.assertLessEqual(set(host_deps.DLOPENED), set(host_deps.OTHER_DISTROS))

    def test_no_package_depends_on_a_host_libmpv_or_the_bundled_ubuntu_libraries(self):
        for distro, names in packages.DEPENDS.items():
            for name in names:
                self.assertNotIn("mpv", name, distro)
                self.assertFalse(name.startswith(("liblua", "libmujs", "mujs", "lua", "libdisplay-info", "bzip2", "libbz2")), name)

    def test_each_list_names_a_package_once(self):
        for distro, names in packages.DEPENDS.items():
            self.assertEqual(len(names), len(set(names)), distro)


class FpmTest(unittest.TestCase):
    tree = Path("/stage/plezy")

    def command(self, distro, arch="x64", version="2.26.0"):
        return packages.fpm_command(distro, self.tree, arch, version, Path("/out"))

    @staticmethod
    def option(command, flag):
        return [command[i + 1] for i, value in enumerate(command) if value == flag]

    def test_packages_replace_the_earlier_releases_plezy_package(self):
        for distro in packages.FORMATS:
            command = self.command(distro)
            self.assertEqual(self.option(command, "-n"), ["plezy"])
            self.assertEqual(self.option(command, "-t"), [distro])
            self.assertEqual(self.option(command, "-v"), ["2.26.0"])
            self.assertEqual(self.option(command, "--iteration"), ["1"])
            self.assertEqual(self.option(command, "--license"), ["GPL-3.0"])
            self.assertEqual(self.option(command, "--vendor"), ["edde746"])
            self.assertEqual(self.option(command, "--maintainer"), ["edde746 <noreply@github.com>"])
            self.assertEqual(self.option(command, "--url"), ["https://github.com/edde746/plezy"])
            self.assertEqual(self.option(command, "--description"), ["A modern Plex and Jellyfin client for desktop and mobile"])
            self.assertEqual(self.option(command, "--depends"), packages.DEPENDS[distro])

    def test_a_beta_carries_its_label_in_each_formats_pre_release_syntax(self):
        for distro, version in {"deb": "3.0.0~beta3", "rpm": "3.0.0~beta3", "pacman": "3.0.0beta3"}.items():
            command = self.command(distro, version="3.0.0-beta.3")
            self.assertEqual(self.option(command, "-v"), [version])
            self.assertEqual(self.option(command, "--iteration"), ["1"])

    def test_rejects_a_version_that_is_not_semantic(self):
        for version in ("3.0", "v3.0.0", "3.0.0-beta", "3.0.0-beta3", "3.0.0-beta.3.1", "3.0.0~beta3", "3.0.0-Beta.3"):
            with self.assertRaises(ValueError, msg=version):
                self.command("deb", version=version)

    def test_architectures_compression_and_file_names(self):
        expected = {
            "deb": ({"x64": "amd64", "arm64": "arm64"}, ["--deb-compression", "xz"], "deb"),
            "rpm": ({"x64": "x86_64", "arm64": "aarch64"}, ["--rpm-compression", "xzmt"], "rpm"),
            "pacman": ({"x64": "x86_64", "arm64": "aarch64"}, ["--pacman-compression", "zstd"], "pkg.tar.zst"),
        }
        for distro, (arches, compression, extension) in expected.items():
            for arch, package_arch in arches.items():
                command = self.command(distro, arch)
                self.assertEqual(self.option(command, "--architecture"), [package_arch])
                self.assertEqual(self.option(command, compression[0]), [compression[1]])
                self.assertEqual(self.option(command, "--package"), [f"/out/plezy-linux-{arch}.{extension}"])

    def test_install_scripts(self):
        command = self.command("deb")
        self.assertEqual(self.option(command, "--after-install"), [str(HERE / "after-install.sh")])
        self.assertEqual(self.option(command, "--after-upgrade"), [str(HERE / "after-install.sh")])
        self.assertEqual(self.option(command, "--after-remove"), [str(HERE / "after-remove.sh")])
        for script in ("after-install.sh", "after-remove.sh"):
            text = (HERE / script).read_text()
            self.assertIn("update-desktop-database /usr/share/applications", text)
            self.assertIn("gtk-update-icon-cache -f -t /usr/share/icons/hicolor", text)

    def test_file_layout(self):
        mappings = dict(mapping.split("=", 1) for mapping in packages.file_mappings(self.tree))
        self.assertEqual(mappings[f"{self.tree}/"], "/opt/plezy/")
        self.assertEqual(mappings[f"{self.tree}/plezy.sh"], "/usr/bin/plezy")
        self.assertEqual(mappings[f"{HERE}/{APP_ID}.desktop"], f"/usr/share/applications/{APP_ID}.desktop")
        self.assertEqual(mappings[f"{HERE}/{APP_ID}.metainfo.xml"], f"/usr/share/metainfo/{APP_ID}.metainfo.xml")
        icons = {source: target for source, target in mappings.items() if target.startswith("/usr/share/icons/")}
        self.assertEqual(sorted(icons.values()), sorted(
            f"/usr/share/icons/hicolor/{size}x{size}/apps/plezy.png" for size in (16, 24, 32, 48, 64, 128, 256, 512)))
        for source in icons:
            self.assertTrue(Path(source).is_file(), source)
            width, height = struct.unpack(">II", Path(source).read_bytes()[16:24])
            self.assertEqual(f"{width}x{height}", Path(source).parts[-3])


# How each format's package manager orders versions, for the ordering tests: dpkg's verrevcmp (lib/dpkg/version.c,
# deb-version(7)), rpm's rpmvercmp (rpmio/rpmvercmp.c, `~` from 4.10; its `^` is left out, no version here has one) and
# pacman's, libalpm's older copy of rpm's without `~` (lib/libalpm/version.c, vercmp(8)). Each compares the version,
# then the release (split at the last `-`); the versions here have no epoch. Each returns <0, 0 or >0.
def run_end(text: str, start: int, kind) -> int:
    while start < len(text) and kind(text[start]):
        start += 1
    return start


def compare_segments(one: str, two: str, numeric: bool) -> int:
    if numeric:
        one, two = one.lstrip("0"), two.lstrip("0")
        if len(one) != len(two):
            return 1 if len(one) > len(two) else -1
    return (one > two) - (one < two)


def dpkg_compare(a: str, b: str) -> int:
    def order(c: str) -> int:
        if c.isdigit():
            return 0
        if c.isalpha():
            return ord(c)
        if c == "~":
            return -1
        return ord(c) + 256 if c else 0

    i = j = 0
    while i < len(a) or j < len(b):
        first_diff = 0
        while a[i:i + 1] and not a[i].isdigit() or b[j:j + 1] and not b[j].isdigit():
            difference = order(a[i:i + 1]) - order(b[j:j + 1])
            if difference:
                return difference
            i, j = i + 1, j + 1
        while a[i:i + 1] == "0":
            i += 1
        while b[j:j + 1] == "0":
            j += 1
        while a[i:i + 1].isdigit() and b[j:j + 1].isdigit():
            first_diff = first_diff or ord(a[i]) - ord(b[j])
            i, j = i + 1, j + 1
        if a[i:i + 1].isdigit():
            return 1
        if b[j:j + 1].isdigit():
            return -1
        if first_diff:
            return first_diff
    return 0


def rpm_compare(a: str, b: str) -> int:
    i = j = 0
    while i < len(a) or j < len(b):
        while i < len(a) and not a[i].isalnum() and a[i] != "~":
            i += 1
        while j < len(b) and not b[j].isalnum() and b[j] != "~":
            j += 1
        x, y = a[i:i + 1], b[j:j + 1]
        if x == "~" or y == "~":
            if x != y:
                return -1 if x == "~" else 1
            i, j = i + 1, j + 1
            continue
        if not x or not y:
            break
        numeric = x.isdigit()
        kind = str.isdigit if numeric else str.isalpha
        m, n = run_end(a, i, kind), run_end(b, j, kind)
        if n == j:
            return 1 if numeric else -1
        result = compare_segments(a[i:m], b[j:n], numeric)
        if result:
            return result
        i, j = m, n
    return (i < len(a)) - (j < len(b))


def alpm_compare(a: str, b: str) -> int:
    i = j = previous_i = previous_j = 0
    while i < len(a) and j < len(b):
        while i < len(a) and not a[i].isalnum():
            i += 1
        while j < len(b) and not b[j].isalnum():
            j += 1
        if i == len(a) or j == len(b):
            break
        # Separators of different lengths: the longer one is newer.
        if i - previous_i != j - previous_j:
            return -1 if i - previous_i < j - previous_j else 1
        numeric = a[i].isdigit()
        kind = str.isdigit if numeric else str.isalpha
        m, n = run_end(a, i, kind), run_end(b, j, kind)
        if n == j:
            return 1 if numeric else -1
        result = compare_segments(a[i:m], b[j:n], numeric)
        if result:
            return result
        i, j = previous_i, previous_j = m, n
    if i == len(a) and j == len(b):
        return 0
    # What is left of one but not the other: a letter segment is older than the end, anything else newer.
    x, y = a[i:i + 1], b[j:j + 1]
    return -1 if (not x and not y.isalpha()) or x.isalpha() else 1


COMPARE = {"deb": dpkg_compare, "rpm": rpm_compare, "pacman": alpm_compare}


def package_compare(distro: str, a: str, b: str) -> int:
    (version_a, _, release_a), (version_b, _, release_b) = a.rpartition("-"), b.rpartition("-")
    return COMPARE[distro](version_a, version_b) or COMPARE[distro](release_a, release_b)


class VersionOrderTest(unittest.TestCase):
    def assert_ascending(self, distro, versions):
        for older, newer in zip(versions, versions[1:]):
            self.assertLess(package_compare(distro, older, newer), 0, f"{distro}: {older} before {newer}")
            self.assertGreater(package_compare(distro, newer, older), 0, f"{distro}: {newer} after {older}")
            self.assertEqual(package_compare(distro, older, older), 0, f"{distro}: {older}")

    def test_the_comparisons_sort_their_manuals_examples(self):
        # deb-version(7): ~~ < ~~a < ~ < the empty part < a. rpm: 1.0~rc1 < 1.0, a letter segment older than a number.
        # vercmp(8): 1.0a < 1.0b < 1.0beta < 1.0p < 1.0pre < 1.0rc < 1.0 < 1.0.a < 1.0.1, and 1 < 1.0 < … < 3.0.0.
        examples = {
            "deb": ["1.0~~", "1.0~~a", "1.0~", "1.0", "1.0a"],
            "rpm": ["1.0~rc1", "1.0", "1.0a", "1.0.1", "1.10"],
            "pacman": ["1.0a", "1.0b", "1.0beta", "1.0p", "1.0pre", "1.0rc", "1.0", "1.0.a", "1.0.1"],
        }
        for distro, versions in examples.items():
            self.assert_ascending(distro, [f"{version}-1" for version in versions])
        self.assert_ascending("pacman", [f"{version}-1" for version in ("1", "1.0", "1.1", "1.1.1", "1.2", "2.0", "3.0.0")])

    def test_each_release_upgrades_its_pre_releases_and_each_beta_the_one_before(self):
        versions = ["2.26.0", "3.0.0-alpha.1", "3.0.0-beta.2", "3.0.0-beta.3", "3.0.0-beta.10", "3.0.0-rc.1", "3.0.0",
                    "3.0.1-beta.1", "3.0.1"]
        for distro in packages.FORMATS:
            self.assert_ascending(distro, [f"{packages.package_version(distro, version)}-1" for version in versions])


class DesktopEntryTest(unittest.TestCase):
    def test_entry_opens_plezy_links(self):
        entry = configparser.ConfigParser(interpolation=None)
        entry.optionxform = str
        entry.read(HERE / f"{APP_ID}.desktop")
        section = entry["Desktop Entry"]
        self.assertEqual(section["Exec"], "plezy %u")
        self.assertIn("x-scheme-handler/plezy", section["MimeType"].split(";"))
        self.assertEqual(section["Icon"], "plezy")
        self.assertEqual(section["Name"], "Plezy")
        # The windows' class and Wayland app id (awt.app.id), so the desktop shows them as this entry's app.
        self.assertEqual(section["StartupWMClass"], APP_ID)

    def test_metainfo(self):
        component = ET.parse(HERE / f"{APP_ID}.metainfo.xml").getroot()
        self.assertEqual(component.findtext("id"), APP_ID)
        self.assertEqual(component.findtext("summary"), "Watch and listen to your Plex, Jellyfin, and Emby libraries")
        self.assertEqual(component.find("developer").get("id"), "com.edde746")
        self.assertEqual(component.findtext("metadata_license"), "CC0-1.0")
        self.assertEqual(component.findtext("project_license"), "GPL-3.0-only")
        self.assertEqual({url.get("type"): url.text for url in component.iter("url")}, {
            "homepage": "https://plezy.app",
            "bugtracker": "https://github.com/edde746/plezy/issues",
            "vcs-browser": "https://github.com/edde746/plezy",
        })
        self.assertEqual(component.find("content_rating").get("type"), "oars-1.1")
        self.assertIsNone(component.find("releases"))
        self.assertEqual(component.find("launchable").text, f"{APP_ID}.desktop")


class FlatpakManifestTest(unittest.TestCase):
    def test_sandbox_reaches_what_the_app_uses(self):
        manifest = json.loads((HERE / f"{APP_ID}.json").read_text())
        self.assertEqual(manifest["app-id"], APP_ID)
        self.assertEqual(manifest["command"], "plezy")
        finish = set(manifest["finish-args"])
        for index in range(10):
            self.assertIn(f"--filesystem=xdg-run/discord-ipc-{index}", finish)
        self.assertIn("--filesystem=xdg-run/app/com.discordapp.Discord:create", finish)
        self.assertIn("--talk-name=org.freedesktop.secrets", finish)
        self.assertIn("--socket=wayland", finish)


class WrapperTest(unittest.TestCase):
    def test_starts_the_launcher_beside_it_with_libmpvs_libraries_on_the_linker_path(self):
        with tempfile.TemporaryDirectory() as temporary:
            tree = Path(temporary) / "plezy"
            (tree / "bin").mkdir(parents=True)
            launcher = tree / "bin" / "Plezy"
            launcher.write_text('#!/bin/sh\nprintf "%s\\n" "$LD_LIBRARY_PATH" "$@"\n')
            launcher.chmod(0o755)
            (tree / "plezy.sh").write_bytes((HERE / "plezy.sh").read_bytes())
            (tree / "plezy.sh").chmod(0o755)
            # The AppImage's AppRun and a user's own link both reach it through a symlink.
            (Path(temporary) / "AppRun").symlink_to(tree / "plezy.sh")
            result = subprocess.run([str(Path(temporary) / "AppRun"), "plezy://open", "a b"], capture_output=True,
                                    text=True, check=True, env={**os.environ, "LD_LIBRARY_PATH": "/x"})
            self.assertEqual(result.stdout.splitlines(), [f"{tree.resolve()}/{MPV_DEPS}:/x", "plezy://open", "a b"])

    def test_from_usr_bin_it_starts_the_app_in_opt_plezy(self):
        text = (HERE / "plezy.sh").read_text()
        self.assertIn('[[ $dir != /usr/bin ]] || dir=/opt/plezy', text)
        self.assertIn('exec "$dir/bin/Plezy" "$@"', text)


def elf(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"\x7fELF\x02\x01\x01" + bytes(11) + struct.pack("<H", 62) + bytes(44))


def elf_with_sections(path: Path, names: list[str]):
    """A 64-bit x86-64 ELF with a null section, the named sections and its section-name table."""
    table = b"\0" + b"".join(name.encode() + b"\0" for name in [*names, ".shstrtab"])
    offsets = [1 + sum(len(name) + 1 for name in names[:i]) for i in range(len(names) + 1)]
    sections = bytes(64) + b"".join(struct.pack("<IIQQQQIIQQ", offset, 1, 0, 0, 0, 0, 0, 0, 0, 0)
                                    for offset in offsets[:-1])
    sections += struct.pack("<IIQQQQIIQQ", offsets[-1], 3, 0, 0, 64, len(table), 0, 0, 0, 0)
    header = bytearray(b"\x7fELF\x02\x01\x01" + bytes(11) + struct.pack("<H", 62) + bytes(44))
    struct.pack_into("<Q", header, 0x28, 64 + len(table))
    struct.pack_into("<HHH", header, 0x3A, 64, len(names) + 2, len(names) + 1)
    path.write_bytes(bytes(header) + table + sections)


class DebugSectionsTest(unittest.TestCase):
    def test_finds_dwarf_sections_and_passes_a_stripped_library(self):
        with tempfile.TemporaryDirectory() as temporary:
            library = Path(temporary) / "libmpv.so.2"
            elf_with_sections(library, [".text", ".debug_info", ".symtab", ".zdebug_line"])
            self.assertEqual(debug_sections(library), [".debug_info", ".zdebug_line"])
            elf_with_sections(library, [".text", ".gnu_debuglink", ".symtab"])
            self.assertEqual(debug_sections(library), [])
            library.write_text("not an ELF")
            self.assertEqual(debug_sections(library), [])


class HostDepsGuardTest(unittest.TestCase):
    """check-host-deps.py against a synthetic tree, with stand-ins for ldd, ldconfig and dpkg-query."""

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        base = Path(self.temporary.name)
        self.tree = base / "plezy"
        elf(self.tree / "bin" / "Plezy")
        for soname in UBUNTU_LIBS:
            elf(self.tree / MPV_DEPS / soname)
        self.tools = base / "tools"
        self.tools.mkdir()
        self.data = base / "data"
        self.data.mkdir()
        tools = {
            "readelf": f'cat "{self.data}/readelf"',
            "ldd": f'cat "{self.data}/ldd"',
            "ldconfig": f'cat "{self.data}/ldconfig"',
            # -S <path> → "<package>: <path>"; -W -f ${{Provides}} <package> → its Provides.
            "dpkg-query": textwrap.dedent(f'''\
                if [ "$1" = -S ]; then grep -F " $2" "{self.data}/owners" || exit 1
                else grep "^$4 " "{self.data}/provides" | cut -d' ' -f2-; fi'''),
        }
        for name, body in tools.items():
            (self.tools / name).write_text(f"#!/bin/sh\n{body}\n")
            (self.tools / name).chmod(stat.S_IRWXU)
        self.ldd = {soname: f"/usr/lib/x86_64-linux-gnu/{soname}" for soname in UBUNTU_OWNERS if soname not in host_deps.DLOPENED}
        self.owners = dict(UBUNTU_OWNERS)

    def tearDown(self):
        self.temporary.cleanup()

    def check(self) -> subprocess.CompletedProcess:
        needed = [*self.ldd, *UBUNTU_LIBS, "libc.so.6"]
        (self.data / "readelf").write_text("".join(
            f" 0x0000000000000001 (NEEDED)             Shared library: [{soname}]\n" for soname in needed))
        # ldd lists what the object links directly and, like libpcre2 here, what those link in turn: only the former
        # are the app's to declare.
        lines = [f"\t{soname} => {path} (0x0)" for soname, path in self.ldd.items()]
        lines += [f"\t{soname} => {self.tree / MPV_DEPS / soname} (0x0)" for soname in UBUNTU_LIBS]
        lines += ["\tlibc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x0)",
                  "\tlibpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x0)"]
        (self.data / "ldd").write_text("\n".join(lines) + "\n")
        (self.data / "ldconfig").write_text("".join(
            f"\t{soname} (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/{soname}\n" for soname in host_deps.DLOPENED))
        (self.data / "owners").write_text("".join(
            f"{package}:amd64: /usr/lib/x86_64-linux-gnu/{soname}\n" for soname, (package, _) in self.owners.items()))
        (self.data / "provides").write_text("".join(
            f"{package} {provides}\n" for package, provides in self.owners.values()))
        return subprocess.run([sys.executable, str(HERE / "check-host-deps.py"), str(self.tree), "--arch", "x64"],
                              capture_output=True, text=True, env={**os.environ, "PLEZY_HOST_TOOLS": str(self.tools)})

    def test_passes_when_every_host_library_is_declared(self):
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("libasound.so.2", result.stdout)

    def test_fails_on_a_library_no_package_declares(self):
        self.ldd["libfoo.so.1"] = "/usr/lib/x86_64-linux-gnu/libfoo.so.1"
        self.owners["libfoo.so.1"] = ("libfoo1", "")
        result = self.check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("libfoo.so.1 is from the deb package libfoo1", result.stderr)
        self.assertIn("libfoo.so.1: no rpm or pacman package recorded", result.stderr)

    def test_fails_on_a_library_that_resolves_nowhere(self):
        self.ldd["libbar.so.2"] = "not found"
        result = self.check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("needs libbar.so.2, which resolves to nothing", result.stderr)

    def test_fails_on_a_declared_package_the_app_does_not_need(self):
        del self.ldd["libXtst.so.6"]
        result = self.check()
        self.assertEqual(result.returncode, 1)
        for package in ("libxtst6", "libXtst", "libxtst"):
            self.assertIn(f"declares {package}, which provides none", result.stderr)


if __name__ == "__main__":
    unittest.main()
