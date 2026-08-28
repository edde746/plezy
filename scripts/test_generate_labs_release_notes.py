#!/usr/bin/env python3
"""Tests for Plezy Labs release-note composition."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("generate-labs-release-notes.py")
SPEC = importlib.util.spec_from_file_location("generate_labs_release_notes", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GenerateLabsReleaseNotesTest(unittest.TestCase):
    def test_loads_schema_two_manifest_from_disk(self) -> None:
        manifest = {"schema_version": 2, "features": []}
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "labs_features.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")

            self.assertEqual(MODULE.load_manifest(path), manifest)

    def test_lists_only_applied_features_in_manifest_order_before_upstream_notes(self) -> None:
        manifest = {
            "schema_version": 2,
            "features": [
                {
                    "id": "one",
                    "enabled": True,
                    "description": "First Labs feature",
                    "upstream_pr": "https://github.com/edde746/plezy/pull/1515",
                },
                {"id": "skipped", "enabled": True, "description": "Already official"},
                {"id": "two", "enabled": True, "description": "Second Labs feature"},
            ],
        }

        notes = MODULE.generate_release_notes(manifest, ["two", "one"], "2.9.1", "## Fixed\n\n- Upstream fix")

        self.assertLess(notes.index("First Labs feature"), notes.index("Second Labs feature"))
        self.assertIn("[upstream PR #1515](https://github.com/edde746/plezy/pull/1515)", notes)
        self.assertNotIn("Already official", notes)
        self.assertLess(notes.index("Second Labs feature"), notes.index("Official Plezy 2.9.1 release notes"))
        self.assertIn("### Fixed\n\n- Upstream fix", notes)
        self.assertIn("https://github.com/edde746/plezy/releases/tag/2.9.1", notes)

    def test_writes_fallbacks_when_no_overlay_or_upstream_notes_exist(self) -> None:
        manifest = {"schema_version": 2, "features": []}

        notes = MODULE.generate_release_notes(manifest, [], "3.0.0", "")

        self.assertIn("No Labs-only feature overlays were applied", notes)
        self.assertIn("official Plezy release did not include release notes", notes)

    def test_rejects_applied_feature_missing_from_manifest(self) -> None:
        manifest = {"schema_version": 2, "features": []}

        with self.assertRaisesRegex(ValueError, "missing from the manifest"):
            MODULE.generate_release_notes(manifest, ["missing"], "3.0.0", "Notes")

    def test_rejects_invalid_upstream_pr_for_applied_feature(self) -> None:
        manifest = {
            "schema_version": 2,
            "features": [
                {
                    "id": "one",
                    "enabled": True,
                    "description": "First Labs feature",
                    "upstream_pr": "https://github.com/somewhere/else/pull/1",
                }
            ],
        }

        with self.assertRaisesRegex(ValueError, "invalid upstream PR"):
            MODULE.generate_release_notes(manifest, ["one"], "3.0.0", "Notes")


if __name__ == "__main__":
    unittest.main()
