#!/usr/bin/env python3
"""Tests for resolving upstream Plezy's Flutter SDK pin."""

from __future__ import annotations

import unittest

from resolve_labs_flutter_version import resolve_flutter_version


class ResolveLabsFlutterVersionTest(unittest.TestCase):
    def test_resolves_legacy_literal_pins(self) -> None:
        workflow = """
jobs:
  linux:
    with:
      flutter-version: "3.41.2"
  windows:
    with:
      flutter-version: 3.41.2
"""
        self.assertEqual(resolve_flutter_version(workflow), "3.41.2")

    def test_resolves_top_level_environment_pin(self) -> None:
        workflow = """
env:
  FLUTTER_VERSION: "3.44.0"
  OTHER_VALUE: unchanged

jobs:
  linux:
    with:
      flutter-version: ${{ env.FLUTTER_VERSION }}
  windows:
    env:
      FLUTTER_VERSION: should-not-override-the-workflow-pin
    with:
      flutter-version: ${{ env.FLUTTER_VERSION }}
"""
        self.assertEqual(resolve_flutter_version(workflow), "3.44.0")

    def test_accepts_consistent_literal_and_environment_pins(self) -> None:
        workflow = """
env:
  FLUTTER_VERSION: 3.44.0
jobs:
  first:
    with:
      flutter-version: ${{ env.FLUTTER_VERSION }}
  second:
    with:
      flutter-version: "3.44.0"
"""
        self.assertEqual(resolve_flutter_version(workflow), "3.44.0")

    def test_rejects_conflicting_resolved_versions(self) -> None:
        workflow = """
env:
  FLUTTER_VERSION: 3.44.0
jobs:
  first:
    with:
      flutter-version: ${{ env.FLUTTER_VERSION }}
  second:
    with:
      flutter-version: 3.45.0
"""
        with self.assertRaisesRegex(ValueError, "Expected one upstream Flutter version"):
            resolve_flutter_version(workflow)

    def test_rejects_an_unresolved_environment_reference(self) -> None:
        workflow = """
jobs:
  linux:
    with:
      flutter-version: ${{ env.FLUTTER_VERSION }}
"""
        with self.assertRaisesRegex(ValueError, "top-level env pin is missing"):
            resolve_flutter_version(workflow)

    def test_rejects_an_unknown_expression(self) -> None:
        workflow = """
jobs:
  linux:
    with:
      flutter-version: ${{ vars.FLUTTER_VERSION }}
"""
        with self.assertRaisesRegex(ValueError, "Unsupported upstream flutter-version value"):
            resolve_flutter_version(workflow)


if __name__ == "__main__":
    unittest.main()
