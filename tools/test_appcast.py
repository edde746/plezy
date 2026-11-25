#!/usr/bin/env python3
"""Tests of tools/appcast.py: the feed the earlier releases published, byte for byte, and its refusals."""

from __future__ import annotations

import base64
import contextlib
import io
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ElementTree
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import appcast  # noqa: E402

MAC_SIGNATURE = base64.b64encode(bytes(range(64))).decode("ascii")
WIN_SIGNATURE = base64.b64encode(bytes(range(64, 128))).decode("ascii")
SPARKLE = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"

HEAD = """<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Plezy Updates</title>
    <item>
      <title>Version 2.26.0</title>
      <sparkle:version>160</sparkle:version>
      <sparkle:shortVersionString>2.26.0</sparkle:shortVersionString>
      <sparkle:releaseNotesLink>https://gh-html.edde746.dev/edde746/plezy/2.26.0</sparkle:releaseNotesLink>
"""
MAC_ENCLOSURE = f"""      <sparkle:hardwareRequirements>arm64</sparkle:hardwareRequirements>
      <enclosure url="https://github.com/edde746/plezy/releases/download/2.26.0/plezy-macos.dmg"
       length="123" type="application/octet-stream"
       sparkle:edSignature="{MAC_SIGNATURE}"
       sparkle:os="macos" />
"""
WIN_ENCLOSURE = f"""      <enclosure url="https://github.com/edde746/plezy/releases/download/2.26.0/plezy-windows-installer.exe"
       length="456" type="application/octet-stream"
       sparkle:edSignature="{WIN_SIGNATURE}"
       sparkle:installerArguments="/SILENT /SP-"
       sparkle:os="windows" />
"""
TAIL = """    </item>
  </channel>
</rss>
"""


class AppcastTest(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.mac = self.root / "macos-dmg"
        self.win = self.root / "windows-installer"
        self.mac.mkdir()
        self.win.mkdir()

    def sign_mac(self, size: str = "123") -> None:
        # As the macOS job writes them (echo: a trailing newline).
        (self.mac / "macos-ed-signature.txt").write_text(MAC_SIGNATURE + "\n")
        (self.mac / "macos-dmg-size.txt").write_text(size + "\n")

    def sign_win(self) -> None:
        # As the Windows job writes them (no trailing newline).
        (self.win / "win-ed-signature.txt").write_text(WIN_SIGNATURE)
        (self.win / "win-installer-size.txt").write_text("456")

    def generate(self) -> str:
        output = self.root / "appcast.xml"
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            status = appcast.main([
                "--version", "2.26.0", "--build-number", "160",
                "--macos-dir", str(self.mac), "--windows-dir", str(self.win), "--output", str(output),
            ])
        self.assertEqual(status, 0, stderr.getvalue())
        return output.read_bytes().decode("utf-8")

    def refusal(self, version: str = "2.26.0", build_number: str = "160") -> str:
        with self.assertRaises(appcast.AppcastError) as raised:
            appcast.appcast(version, build_number, self.mac, self.win)
        return str(raised.exception)

    def test_both_platforms_match_the_earlier_releases_feed(self) -> None:
        self.sign_mac()
        self.sign_win()
        text = self.generate()
        self.assertEqual(text, HEAD + MAC_ENCLOSURE + WIN_ENCLOSURE + TAIL)

        item = ElementTree.fromstring(text).find("channel/item")
        self.assertEqual(item.findtext(f"{SPARKLE}version"), "160")
        enclosures = {e.get(f"{SPARKLE}os"): e for e in item.findall("enclosure")}
        self.assertEqual(set(enclosures), {"macos", "windows"})
        self.assertEqual(enclosures["windows"].get(f"{SPARKLE}installerArguments"), "/SILENT /SP-")
        self.assertEqual(enclosures["macos"].get(f"{SPARKLE}edSignature"), MAC_SIGNATURE)
        self.assertIsNone(enclosures["macos"].get(f"{SPARKLE}installerArguments"))
        self.assertEqual(item.findtext(f"{SPARKLE}hardwareRequirements"), "arm64")

    def test_each_enclosure_needs_its_signature(self) -> None:
        self.assertEqual(self.generate(), HEAD + TAIL)
        self.sign_win()
        self.assertEqual(self.generate(), HEAD + WIN_ENCLOSURE + TAIL)
        (self.win / "win-ed-signature.txt").unlink()
        self.sign_mac()
        self.assertEqual(self.generate(), HEAD + MAC_ENCLOSURE + TAIL)

    def test_length_is_checked_against_the_asset_beside_it(self) -> None:
        self.sign_mac()
        (self.mac / "plezy-macos.dmg").write_bytes(b"x" * 123)
        self.assertIn('length="123"', self.generate())
        (self.mac / "plezy-macos.dmg").write_bytes(b"x" * 124)
        self.assertIn("has 124", self.refusal())

    def test_refuses_incomplete_or_malformed_inputs(self) -> None:
        self.sign_mac()
        (self.mac / "macos-dmg-size.txt").unlink()
        self.assertIn("no macos-dmg-size.txt", self.refusal())
        self.sign_mac(size="0")
        self.assertIn("not a size", self.refusal())
        (self.mac / "macos-ed-signature.txt").write_text(base64.b64encode(b"short").decode())
        self.assertIn("64-byte", self.refusal())
        (self.mac / "macos-ed-signature.txt").write_text("not base64!")
        self.assertIn("not base64", self.refusal())
        self.assertIn("major.minor.patch", self.refusal(version="v2.26.0"))
        self.assertIn("positive integer", self.refusal(build_number="0"))


if __name__ == "__main__":
    unittest.main()
