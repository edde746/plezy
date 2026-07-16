#!/usr/bin/env python3

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CHECKER = ROOT / "scripts" / "check_icon_consistency.dart"


class IconConsistencyCheckerTest(unittest.TestCase):
    def run_checker(self, sources: dict[str, str]) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as temporary_directory:
            fixture_root = Path(temporary_directory)
            for relative_path, source in sources.items():
                target = fixture_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(source, encoding="utf-8")

            return subprocess.run(
                ["dart", "run", str(CHECKER), "--root", str(fixture_root)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def test_accepts_canonical_wrapper_and_qualified_rounded_symbols(self) -> None:
        result = self.run_checker(
            {
                "lib/widgets/app_icon.dart": """
import 'package:flutter/material.dart';

Widget buildIcon(IconData icon) => Icon(icon);
""",
                "lib/example.dart": """
import 'package:material_symbols_icons/symbols.dart' as ms;

Object buildIcon() => AppIcon(ms.Symbols.add_rounded);
""",
                "lib/ignored.g.dart": """
Widget ignored(IconData icon) => Icon(icon);
""",
            }
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Icon consistency check passed", result.stdout)

    def test_rejects_qualified_legacy_symbols_and_constructor_tear_offs(self) -> None:
        result = self.run_checker(
            {
                "lib/bad.dart": """
import 'package:flutter/material.dart' as material;
import 'package:material_symbols_icons/symbols.dart' as ms;
import 'package:material_symbols_icons/material_symbols_icons.dart' as material_symbols;

final values = [
  material.Icons.add,
  ms.Symbols.add,
  material_symbols.Symbols.add,
  material.Icon.new,
  Icon.new,
];
""",
            }
        )

        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("material.Icons.add is forbidden", result.stderr)
        self.assertIn("ms.Symbols.add must use its _rounded counterpart", result.stderr)
        self.assertIn("material_symbols.Symbols.add must use its _rounded counterpart", result.stderr)
        self.assertEqual(result.stderr.count("constructor tear-offs are forbidden"), 2, result.stderr)


if __name__ == "__main__":
    unittest.main()
