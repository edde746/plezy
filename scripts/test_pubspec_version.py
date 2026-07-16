import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from pubspec_version import parse_pubspec_version


SCRIPT = SCRIPT_DIR / "pubspec_version.py"


class ParsePubspecVersionTest(unittest.TestCase):
    def test_ignores_duplicate_nested_version_keys(self) -> None:
        contents = """\
name: example
dependencies:
  first:
    version: 9.9.9+999
version: 2.8.0+119
metadata:
  version: malformed
"""

        self.assertEqual(parse_pubspec_version(contents), ("2.8.0+119", "119"))

    def test_rejects_malformed_versions(self) -> None:
        for value in ("2.8", "2.8.0", "02.8.0+1", "2.8.0+build.1"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                parse_pubspec_version(f"version: {value}\n")

    def test_rejects_missing_top_level_version(self) -> None:
        contents = """\
name: example
dependency:
  version: 2.8.0+119
"""

        with self.assertRaisesRegex(ValueError, "found 0"):
            parse_pubspec_version(contents)

    def test_accepts_numeric_build_metadata(self) -> None:
        self.assertEqual(
            parse_pubspec_version("version: 10.20.30+0007 # release build\n"),
            ("10.20.30+0007", "0007"),
        )

    def test_cli_prints_build_number(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            pubspec = Path(directory) / "pubspec.yaml"
            pubspec.write_text("version: 1.2.3+456\n", encoding="utf-8")

            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--build-number", str(pubspec)],
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "456\n")
        self.assertEqual(result.stderr, "")


if __name__ == "__main__":
    unittest.main()
