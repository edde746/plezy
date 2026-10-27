from __future__ import annotations

import io
import json
import os
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path


TOOLS_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS_ROOT))

import package_ipk  # noqa: E402
import verify_package  # noqa: E402


APP_ID = "org.snapetech.plezyng"


def make_elf32_arm() -> bytes:
    header = bytearray(64)
    header[:4] = b"\x7fELF"
    header[4] = 1  # ELFCLASS32
    header[5] = 1  # little-endian
    header[6] = 1  # current ELF version
    header[18:20] = (40).to_bytes(2, "little")  # EM_ARM
    return bytes(header)


def make_staging_tree(root: Path) -> tuple[Path, Path]:
    output = root / "ipk"
    app = output / "data/usr/palm/applications" / APP_ID
    (app / "appdata").mkdir(parents=True)
    (app / "appinfo.json").write_text(
        json.dumps({"id": APP_ID, "version": "2.24.1", "type": "native", "main": "plezyng"}),
        encoding="utf-8",
    )
    executable = app / "plezyng"
    executable.write_bytes(make_elf32_arm())
    executable.chmod(0o755)
    (app / "icon.png").write_bytes(b"icon")
    return output, app


class PackageIpkTests(unittest.TestCase):
    def test_control_parser_rejects_duplicate_fields(self) -> None:
        with self.assertRaisesRegex(ValueError, "repeats field 'Package'"):
            verify_package.parse_control_fields(b"Package: first\nPackage: second\n\n")

    def test_ipk_verifier_rejects_symlink_input(self) -> None:
        with tempfile.TemporaryDirectory(dir=os.environ["PLEZY_WEBOS_TEST_TMP"]) as temporary:
            root = Path(temporary)
            target = root / "valid.ipk"
            target.write_bytes(b"not an IPK")
            link = root / "linked.ipk"
            link.symlink_to(target)
            with self.assertRaisesRegex(ValueError, "regular, non-symlink file"):
                verify_package.read_ar_archive(link)

    def test_package_is_deterministic_and_has_restricted_paths(self) -> None:
        with tempfile.TemporaryDirectory(dir=os.environ["PLEZY_WEBOS_TEST_TMP"]) as temporary:
            output, app = make_staging_tree(Path(temporary))
            first = package_ipk.package(app, output)
            first_bytes = first.read_bytes()
            second = package_ipk.package(app, output)
            self.assertEqual(first_bytes, second.read_bytes())

            ar_members = verify_package.read_ar_archive(first)
            self.assertEqual(list(ar_members), ["debian-binary", "control.tar.gz", "data.tar.gz"])
            control = verify_package.read_tar_member(ar_members["control.tar.gz"], "control").decode("utf-8")
            control_fields = {
                key.strip(): value.strip()
                for line in control.splitlines()
                if ":" in line
                for key, value in [line.split(":", 1)]
            }
            self.assertEqual(control_fields["Maintainer"], "SnapeTech <noreply@github.com>")
            self.assertEqual(control_fields["Description"], "Plex media client for LG webOS TVs.")
            self.assertNotIn("nobody@example.com", control)
            self.assertNotIn("This is a webOS application.", control)
            data_files = verify_package.read_tar_members(
                ar_members["data.tar.gz"],
                {f"usr/palm/applications/{APP_ID}/plezyng"},
            )
            self.assertEqual(data_files[f"usr/palm/applications/{APP_ID}/plezyng"], make_elf32_arm())

            with tarfile.open(fileobj=io.BytesIO(ar_members["data.tar.gz"]), mode="r:gz") as archive:
                appdata = archive.getmember(f"usr/palm/applications/{APP_ID}/appdata")
                executable = archive.getmember(f"usr/palm/applications/{APP_ID}/plezyng")
                self.assertEqual(appdata.mode, 0o777)
                self.assertEqual(executable.mode, 0o755)

    def test_package_rejects_symlinks(self) -> None:
        with tempfile.TemporaryDirectory(dir=os.environ["PLEZY_WEBOS_TEST_TMP"]) as temporary:
            output, app = make_staging_tree(Path(temporary))
            external = Path(temporary) / "external-secret"
            external.write_text("must not be packaged", encoding="utf-8")
            (app / "link-out").symlink_to(external)
            with self.assertRaisesRegex(package_ipk.PackageError, "symbolic links are forbidden"):
                package_ipk.package(app, output)

    def test_verifier_rejects_tar_path_traversal(self) -> None:
        contents = io.BytesIO()
        with tarfile.open(fileobj=contents, mode="w", format=tarfile.USTAR_FORMAT) as archive:
            member = tarfile.TarInfo("../outside")
            member.size = 0
            archive.addfile(member, io.BytesIO())
        compressed = io.BytesIO()
        import gzip

        with gzip.GzipFile(fileobj=compressed, mode="wb", mtime=0) as output:
            output.write(contents.getvalue())
        with self.assertRaisesRegex(ValueError, "unsafe path"):
            verify_package.read_tar_members(compressed.getvalue(), {"../outside"})


if __name__ == "__main__":
    unittest.main()
