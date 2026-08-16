import sys
import tempfile
import unittest
import xml.dom.minidom
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import deploy
from deploy import (
    DeployError,
    State,
    build_appcast,
    bump_pubspec_text,
    collect_release_files,
    parse_env_text,
    resolve_phases,
    sanitize_msstore_pricing,
    update_cask_text,
)


class ParseEnvTextTest(unittest.TestCase):
    def test_parses_values_and_skips_comments_and_blanks(self) -> None:
        text = """\
# App Store
DELIVER_USERNAME=user@example.com

export TOKEN=abc123
NOT A VALID LINE
"""
        values = parse_env_text(text)
        self.assertEqual(
            values,
            {"DELIVER_USERNAME": "user@example.com", "TOKEN": "abc123"},
        )

    def test_strips_matching_quotes(self) -> None:
        values = parse_env_text("A=\"quoted value\"\nB='single'\nC=un\"quoted\n")
        self.assertEqual(values["A"], "quoted value")
        self.assertEqual(values["B"], "single")
        self.assertEqual(values["C"], 'un"quoted')

    def test_expands_references_to_earlier_keys(self) -> None:
        # The real .env relies on this: SUPPLY_PACKAGE_NAME=${DELIVER_APP_IDENTIFIER}
        text = "DELIVER_APP_IDENTIFIER=com.edde746.plezy\nSUPPLY_PACKAGE_NAME=${DELIVER_APP_IDENTIFIER}\n"
        values = parse_env_text(text)
        self.assertEqual(values["SUPPLY_PACKAGE_NAME"], "com.edde746.plezy")

    def test_expands_from_base_environment(self) -> None:
        values = parse_env_text("A=${HOME_LIKE}/sub\n", {"HOME_LIKE": "/base"})
        self.assertEqual(values["A"], "/base/sub")

    def test_unknown_reference_expands_empty(self) -> None:
        self.assertEqual(parse_env_text("A=${MISSING}x\n")["A"], "x")

    def test_single_quotes_suppress_expansion(self) -> None:
        values = parse_env_text("A='${NOPE}'\n", {"NOPE": "value"})
        self.assertEqual(values["A"], "${NOPE}")


class BumpPubspecTextTest(unittest.TestCase):
    PUBSPEC = """\
name: plezy
description: A media client.
version: 2.12.1+230
environment:
  sdk: ">=3.12.0 <4.0.0"
dependencies:
  some_package:
    version: 9.9.9+999
"""

    def test_replaces_only_the_top_level_version(self) -> None:
        result = bump_pubspec_text(self.PUBSPEC, "2.13.0", 231)
        self.assertIn("version: 2.13.0+231\n", result)
        self.assertIn("    version: 9.9.9+999\n", result)
        self.assertNotIn("2.12.1+230", result)
        self.assertEqual(result.count("\n"), self.PUBSPEC.count("\n"))

    def test_rejects_pubspec_without_version(self) -> None:
        with self.assertRaises(ValueError):
            bump_pubspec_text("name: plezy\n", "2.13.0", 231)


class BuildAppcastTest(unittest.TestCase):
    def test_full_appcast_has_both_enclosures(self) -> None:
        xml_text = build_appcast("2.13.0", "231", "macsig", "1000", "winsig", "2000")
        doc = xml.dom.minidom.parseString(xml_text)
        enclosures = doc.getElementsByTagName("enclosure")
        self.assertEqual(len(enclosures), 2)
        macos, windows = enclosures
        self.assertEqual(
            macos.getAttribute("url"),
            "https://github.com/edde746/plezy/releases/download/2.13.0/plezy-macos.dmg",
        )
        self.assertEqual(macos.getAttribute("sparkle:edSignature"), "macsig")
        self.assertEqual(macos.getAttribute("length"), "1000")
        self.assertEqual(
            windows.getAttribute("url"),
            "https://github.com/edde746/plezy/releases/download/2.13.0/plezy-windows-installer.exe",
        )
        self.assertEqual(windows.getAttribute("sparkle:installerArguments"), "/SILENT /SP-")
        version_nodes = doc.getElementsByTagName("sparkle:version")
        self.assertEqual(version_nodes[0].firstChild.nodeValue, "231")

    def test_unsigned_appcast_has_no_enclosures(self) -> None:
        xml_text = build_appcast("2.13.0", "231")
        doc = xml.dom.minidom.parseString(xml_text)
        self.assertEqual(len(doc.getElementsByTagName("enclosure")), 0)
        notes = doc.getElementsByTagName("sparkle:releaseNotesLink")
        self.assertIn("2.13.0", notes[0].firstChild.nodeValue)


class UpdateCaskTextTest(unittest.TestCase):
    CASK = """\
cask "plezy" do
  version "2.12.1"
  sha256 "7a5e30d125d5a379108bf691ae8ce5e2af0a1acf98ee40897909a9576ebe3ef9"

  url "https://github.com/edde746/plezy/releases/download/#{version}/plezy-macos.dmg"
  name "Plezy"
end
"""

    def test_updates_version_and_sha(self) -> None:
        result = update_cask_text(self.CASK, "2.13.0", "f" * 64)
        self.assertIn('version "2.13.0"', result)
        self.assertIn(f'sha256 "{"f" * 64}"', result)
        self.assertNotIn("2.12.1", result)
        # Interpolated URL and other stanzas are untouched.
        self.assertIn('#{version}/plezy-macos.dmg', result)

    def test_missing_stanza_raises(self) -> None:
        with self.assertRaises(DeployError):
            update_cask_text('cask "plezy" do\nend\n', "2.13.0", "f" * 64)


class ResolvePhasesTest(unittest.TestCase):
    def test_default_selects_all_phases_in_order(self) -> None:
        self.assertEqual(resolve_phases(None, None), deploy.PHASES)

    def test_only_keeps_preflight_and_canonical_order(self) -> None:
        self.assertEqual(
            resolve_phases(["msstore", "play"], None),
            ["preflight", "play", "msstore"],
        )

    def test_skip_removes_phases(self) -> None:
        selected = resolve_phases(None, ["ios", "tvos", "asc"])
        self.assertNotIn("ios", selected)
        self.assertNotIn("tvos", selected)
        self.assertNotIn("asc", selected)
        self.assertIn("play", selected)

    def test_preflight_can_be_skipped_explicitly(self) -> None:
        self.assertEqual(resolve_phases(["release"], ["preflight"]), ["release"])

    def test_unknown_phase_raises(self) -> None:
        with self.assertRaises(DeployError):
            resolve_phases(["appstore"], None)
        with self.assertRaises(DeployError):
            resolve_phases(None, ["nope"])


class CollectReleaseFilesTest(unittest.TestCase):
    EXPECTED = [
        "android-apk/plezy-android-arm64-v8a.tar.gz",
        "android-apk/plezy-android-armeabi-v7a.tar.gz",
        "android-apk/plezy-android-x86_64.tar.gz",
        "ios-ipa/plezy-ios.ipa",
        "macos-dmg/plezy-macos.dmg",
        "windows-x64-portable/plezy-windows-x64-portable.7z",
        "windows-arm64-portable/plezy-windows-arm64-portable.7z",
        "windows-installer/plezy-windows-installer.exe",
        "linux-x64/plezy-linux-x64.deb",
        "linux-x64/plezy-linux-x64.tar.gz",
        "linux-arm64/plezy-linux-arm64.deb",
        "linux-arm64/plezy-linux-arm64.tar.gz",
    ]

    def make_tree(self, root: Path, skip: str = "") -> None:
        for rel in self.EXPECTED:
            if rel == skip:
                continue
            path = root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"artifact")

    def test_collects_all_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_tree(root)
            files = collect_release_files(root)
            relative = {str(p.relative_to(root)) for p in files}
            self.assertEqual(relative, set(self.EXPECTED))

    def test_missing_explicit_artifact_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_tree(root, skip="macos-dmg/plezy-macos.dmg")
            with self.assertRaisesRegex(DeployError, "plezy-macos.dmg"):
                collect_release_files(root)

    def test_empty_linux_directory_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_tree(root)
            for entry in (root / "linux-arm64").iterdir():
                entry.unlink()
            with self.assertRaisesRegex(DeployError, "linux-arm64"):
                collect_release_files(root)


class StateTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self._original = deploy.STATE_PATH
        deploy.STATE_PATH = Path(self._tmp.name) / "state.json"

    def tearDown(self) -> None:
        deploy.STATE_PATH = self._original
        self._tmp.cleanup()

    def test_round_trip(self) -> None:
        state = State(version="2.13.0", build_number=231)
        state.data["farm_run_id"] = 42
        state.mark_done("changelog")
        loaded = State.load()
        self.assertIsNotNone(loaded)
        self.assertEqual(loaded.version, "2.13.0")
        self.assertEqual(loaded.build_number, 231)
        self.assertEqual(loaded.done, ["changelog"])
        self.assertEqual(loaded.data, {"farm_run_id": 42})

    def test_mark_done_is_idempotent(self) -> None:
        state = State(version="2.13.0", build_number=231)
        state.mark_done("play")
        state.mark_done("play")
        self.assertEqual(State.load().done, ["play"])

    def test_load_returns_none_without_file(self) -> None:
        self.assertIsNone(State.load())


class SplitPhaseListsTest(unittest.TestCase):
    def test_splits_commas_and_repeats(self) -> None:
        self.assertEqual(
            deploy._split_phase_lists(["play,amazon", "ios"]),
            ["play", "amazon", "ios"],
        )

    def test_none_passthrough(self) -> None:
        self.assertIsNone(deploy._split_phase_lists(None))
        self.assertIsNone(deploy._split_phase_lists([]))


class SanitizeMsstorePricingTest(unittest.TestCase):
    def test_drops_price_id_and_advanced_flag_but_keeps_the_rest(self) -> None:
        submission = {
            "pricing": {
                "trialPeriod": "SevenDays",
                "marketSpecificPricings": {"LB": "NotAvailable"},
                "sales": [],
                "priceId": "Base",
                "isAdvancedPricingModel": True,
            }
        }
        sanitize_msstore_pricing(submission)
        self.assertEqual(
            submission["pricing"],
            {
                "trialPeriod": "SevenDays",
                "marketSpecificPricings": {"LB": "NotAvailable"},
                "sales": [],
            },
        )

    def test_tolerates_missing_pricing(self) -> None:
        submission: dict = {}
        sanitize_msstore_pricing(submission)
        self.assertEqual(submission, {})


if __name__ == "__main__":
    unittest.main()
