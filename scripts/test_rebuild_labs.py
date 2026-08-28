#!/usr/bin/env python3
"""Tests for deterministic Plezy Labs reconstruction."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("rebuild-labs.py")
SPEC = importlib.util.spec_from_file_location("rebuild_labs", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
REBUILD_LABS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(REBUILD_LABS)


def run(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=repo,
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def git(repo: Path, *args: str) -> str:
    return run(repo, "git", *args).stdout.strip()


def write(repo: Path, path: str, value: str) -> None:
    target = repo / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(value, encoding="utf-8")


def commit(repo: Path, message: str, files: dict[str, str]) -> str:
    for path, value in files.items():
        write(repo, path, value)
    git(repo, "add", ".")
    git(repo, "commit", "-m", message)
    return git(repo, "rev-parse", "HEAD")


class RebuildLabsTest(unittest.TestCase):
    def test_recognizes_generated_translation_with_composite_locale(self) -> None:
        self.assertIsNotNone(
            REBUILD_LABS.GENERATED_TRANSLATION.fullmatch("lib/i18n/strings_zh_Hant.g.dart")
        )

    def test_rebrands_current_upstream_windows_installer(self) -> None:
        upstream = (
            'function New-InnoSetupScript {\n'
            '  #define Publisher "edde746"\n'
            '}\n'
        )

        branded = REBUILD_LABS.brand_labs_windows_installer(upstream)

        self.assertIn('#define Publisher "RyanTheTechMan (Plezy Labs)"', branded)
        self.assertNotIn('#define Publisher "edde746"', branded)

    def test_refuses_unknown_windows_installer_publisher_shape(self) -> None:
        with self.assertRaisesRegex(ValueError, "publisher declaration"):
            REBUILD_LABS.brand_labs_windows_installer('#define Publisher "someone-else"\n')

    def test_merges_independent_translation_keys(self) -> None:
        base = {"videoControls": {"screenshotSaved": "Screenshot saved", "zoomPercent": "Zoom"}}
        ours = {
            "videoControls": {
                "screenshotSaved": "Screenshot saved",
                "zoomPercent": "Zoom",
                "clip": {"title": "Clip"},
            }
        }
        theirs = {
            "videoControls": {
                "screenshotSaved": "Screenshot saved",
                "zoomPercent": "Zoom",
                "frameCount": {"one": "frame", "other": "frames"},
            }
        }

        merged = REBUILD_LABS.merge_json_value(base, ours, theirs)

        self.assertEqual(merged["videoControls"]["clip"], {"title": "Clip"})
        self.assertEqual(merged["videoControls"]["frameCount"], {"one": "frame", "other": "frames"})

    def test_rejects_translation_key_collisions(self) -> None:
        base = {"common": {"close": "Close"}}
        ours = {"common": {"close": "Dismiss"}}
        theirs = {"common": {"close": "Exit"}}

        with self.assertRaisesRegex(ValueError, "common.close"):
            REBUILD_LABS.merge_json_value(base, ours, theirs)

    def make_repo(self, *, official_has_feature: bool = False, conflict: bool = False) -> tuple[Path, tempfile.TemporaryDirectory[str]]:
        temporary = tempfile.TemporaryDirectory()
        repo = Path(temporary.name)
        git(repo, "init", "-b", "main")
        git(repo, "config", "user.name", "Test User")
        git(repo, "config", "user.email", "test@example.com")
        commit(
            repo,
            "official 1.0.0",
            {"pubspec.yaml": "version: 1.0.0+1\n", "shared.txt": "official\n"},
        )
        git(repo, "tag", "1.0.0")

        git(repo, "switch", "-c", "feature/example")
        feature_value = "feature\n"
        feature_commit = commit(repo, "feat: example", {"feature.txt": feature_value})

        git(repo, "switch", "main")
        if official_has_feature:
            git(repo, "cherry-pick", feature_commit)
        official_files = {"pubspec.yaml": "version: 1.0.1+2\n", "official.txt": "minor\n"}
        if conflict:
            official_files["shared.txt"] = "official changed\n"
        commit(repo, "official 1.0.1", official_files)
        git(repo, "tag", "1.0.1")

        git(repo, "switch", "-c", "labs", "1.0.0")
        core_value = "labs\n" if conflict else "official\nlabs\n"
        commit(repo, "feat(labs): base release channel", {"shared.txt": core_value, "labs.txt": "updater\n"})
        manifest = {
            "schema_version": 1,
            "features": [
                {
                    "id": "example",
                    "enabled": True,
                    "source_ref": "feature/example",
                    "commits": [feature_commit],
                    "description": "Example feature",
                }
            ],
        }
        commit(repo, "chore(labs): register enabled feature overlays", {"tool/labs_features.json": json.dumps(manifest, indent=2) + "\n"})
        if not official_has_feature:
            git(repo, "cherry-pick", feature_commit)
        return repo, temporary

    def make_adaptive_repo(self) -> tuple[Path, tempfile.TemporaryDirectory[str]]:
        temporary = tempfile.TemporaryDirectory()
        repo = Path(temporary.name)
        git(repo, "init", "-b", "main")
        git(repo, "config", "user.name", "Test User")
        git(repo, "config", "user.email", "test@example.com")
        commit(
            repo,
            "official 1.0.0",
            {"pubspec.yaml": "version: 1.0.0+1\n", "shared.txt": "official\n"},
        )
        git(repo, "tag", "1.0.0")

        git(repo, "switch", "-c", "release/1.0.1")
        commit(repo, "official 1.0.1", {"pubspec.yaml": "version: 1.0.1+2\n"})
        git(repo, "tag", "1.0.1")

        git(repo, "switch", "main")
        activation_commit = commit(repo, "upstream foundation", {"foundation.txt": "ready\n"})
        commit(repo, "official 1.1.0", {"pubspec.yaml": "version: 1.1.0+3\n"})
        git(repo, "tag", "1.1.0")
        native_commit = commit(repo, "feat: native example", {"feature.txt": "native\n"})
        commit(repo, "official 1.2.0", {"pubspec.yaml": "version: 1.2.0+4\n"})
        git(repo, "tag", "1.2.0")

        git(repo, "switch", "-c", "backport/example", "1.0.0")
        backport_commit = commit(repo, "backport: compatible example", {"feature.txt": "backport\n"})

        git(repo, "switch", "-c", "labs", "1.0.0")
        commit(repo, "feat(labs): base release channel", {"labs.txt": "updater\n"})
        manifest = {
            "schema_version": 2,
            "features": [
                {
                    "id": "adaptive-example",
                    "enabled": True,
                    "source_ref": "feature/example",
                    "commits": [native_commit],
                    "backport": {
                        "source_ref": "backport/example",
                        "commits": [backport_commit],
                        "use_native_after": activation_commit,
                    },
                    "description": "Adaptive example feature",
                }
            ],
        }
        commit(
            repo,
            "chore(labs): register enabled feature overlays",
            {"tool/labs_features.json": json.dumps(manifest, indent=2) + "\n"},
        )
        git(repo, "cherry-pick", backport_commit)
        return repo, temporary

    def rebuild(self, repo: Path, official_tag: str = "1.0.1") -> subprocess.CompletedProcess[str]:
        return run(
            repo,
            "python3",
            str(SCRIPT),
            "--repo",
            str(repo),
            "--official-tag",
            official_tag,
            "--report",
            str(repo / ".git" / "report.json"),
            "--skip-translation-generation",
            check=False,
        )

    def test_rebuilds_linear_stack_on_new_official_tag(self) -> None:
        repo, temporary = self.make_repo()
        self.addCleanup(temporary.cleanup)
        result = self.rebuild(repo)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(git(repo, "merge-base", "1.0.1", "HEAD"), git(repo, "rev-parse", "1.0.1"))
        subjects = git(repo, "log", "--reverse", "--format=%s", "1.0.1..HEAD").splitlines()
        self.assertEqual(
            subjects,
            [
                "feat(labs): base release channel on Plezy 1.0.1",
                "chore(labs): register enabled feature overlays",
                "feat: example",
            ],
        )
        self.assertEqual((repo / "official.txt").read_text(), "minor\n")
        self.assertEqual((repo / "labs.txt").read_text(), "updater\n")
        self.assertEqual((repo / "feature.txt").read_text(), "feature\n")

    def test_skips_feature_patch_already_in_official_release(self) -> None:
        repo, temporary = self.make_repo(official_has_feature=True)
        self.addCleanup(temporary.cleanup)
        result = self.rebuild(repo)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads((repo / ".git" / "report.json").read_text())
        self.assertEqual(report["applied_features"], [])
        self.assertEqual(report["skipped_official_features"][0]["id"], "example")

    def test_reports_core_conflict_without_release_candidate(self) -> None:
        repo, temporary = self.make_repo(conflict=True)
        self.addCleanup(temporary.cleanup)
        result = self.rebuild(repo)
        self.assertNotEqual(result.returncode, 0)
        report = json.loads((repo / ".git" / "report.json").read_text())
        self.assertEqual(report["status"], "failure")
        self.assertEqual(report["stage"], "labs-base")
        self.assertIn("shared.txt", report["files"])

    def test_uses_backport_before_official_reaches_native_base(self) -> None:
        repo, temporary = self.make_adaptive_repo()
        self.addCleanup(temporary.cleanup)
        result = self.rebuild(repo, "1.0.1")
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads((repo / ".git" / "report.json").read_text())
        self.assertEqual(report["applied_features"][0]["variant"], "backport")
        self.assertEqual((repo / "feature.txt").read_text(), "backport\n")

    def test_switches_to_native_after_official_reaches_native_base(self) -> None:
        repo, temporary = self.make_adaptive_repo()
        self.addCleanup(temporary.cleanup)
        result = self.rebuild(repo, "1.1.0")
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads((repo / ".git" / "report.json").read_text())
        self.assertEqual(report["applied_features"][0]["variant"], "native")
        self.assertEqual((repo / "feature.txt").read_text(), "native\n")

    def test_skips_adaptive_feature_when_native_patch_is_official(self) -> None:
        repo, temporary = self.make_adaptive_repo()
        self.addCleanup(temporary.cleanup)
        result = self.rebuild(repo, "1.2.0")
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads((repo / ".git" / "report.json").read_text())
        self.assertEqual(report["applied_features"], [])
        self.assertEqual(report["skipped_official_features"][0]["variant"], "native")
        self.assertEqual((repo / "feature.txt").read_text(), "native\n")


if __name__ == "__main__":
    unittest.main()
