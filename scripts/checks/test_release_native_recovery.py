#!/usr/bin/env python3
"""Keep recovery from accepting stale source keys or unverifiable artifacts."""

import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile


ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("release_all_platforms", ROOT / "scripts/release_all_platforms.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


def archive_bytes(manifest, extra=None):
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w") as archive:
        archive.writestr("artifacts.json", json.dumps(manifest))
        if extra:
            archive.writestr(extra, "unexpected")
    return output.getvalue()


def trusted_run():
    return {"id": 42, "status": "completed", "event": "workflow_dispatch",
            "head_branch": "main", "path": ".github/workflows/publish.yml",
            "display_title": "action:build:pool:private",
            "head_repository": {"full_name": release.MPV_REPO}, "head_sha": "a" * 40}


class NativeRecoveryTest(unittest.TestCase):
    def test_recovery_is_only_from_completed_explicit_private_main_run(self):
        self.assertTrue(release.native_recovery_run_is_trusted(trusted_run()))
        for field, value in (("status", "in_progress"), ("event", "push"),
                             ("head_branch", "feature"), ("path", ".github/workflows/test.yml"),
                             ("display_title", "action:build:pool:public"),
                             ("head_repository", {"full_name": "outside/fork"}),
                             ("head_sha", "short")):
            with self.subTest(field=field):
                self.assertFalse(release.native_recovery_run_is_trusted({**trusted_run(), field: value}))

    def test_manifest_archive_digest_and_paths_are_checked(self):
        manifest = {"platforms": {"apple": {"libraries": {}}}}
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / "manifest.zip"
            for extra in (None, "../artifacts.json", "unrelated.sh"):
                archive.write_bytes(archive_bytes(manifest, extra))
                digest = "sha256:" + hashlib.sha256(archive.read_bytes()).hexdigest()
                if extra is None:
                    self.assertEqual(release.read_native_manifest_archive(archive, digest), manifest)
                    with self.assertRaisesRegex(release.ReleaseError, "digest"):
                        release.read_native_manifest_archive(archive, "sha256:" + "0" * 64)
                else:
                    with self.assertRaisesRegex(release.ReleaseError, "archive entries"):
                        release.read_native_manifest_archive(archive, digest)

    def test_package_asset_keeps_its_checksum(self):
        self.assertEqual(release.manifest_assets({"libraries": {
            "mpv-android": {"asset": "mpv.aar", "checksum": "b" * 64}}}),
            {"mpv.aar": "b" * 64})

    def test_published_aar_with_wrong_digest_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            checkout = Path(directory)
            (checkout / "artifacts.json").write_text(json.dumps({"platforms": {"android": {
                "assetBase": f"https://github.com/{release.MPV_REPO}/releases/download/binaries-android",
                "libraries": {"mpv-android": {"asset": "mpv.aar", "checksum": "b" * 64}},
            }}}))
            with patch.object(release, "gh_json", return_value={"assets": [
                {"name": "mpv.aar", "digest": "sha256:" + "c" * 64}]}):
                with self.assertRaisesRegex(release.ReleaseError, "does not match"):
                    release.verify_native_release_assets(checkout, groups=("android",))

    def _exercise_recovery(self, candidate_key="valid", asset_error=False, published=True):
        original = {"platforms": {"apple": {"libraries": {"libmpv": {"key": "old"}}}}}
        candidate = {"platforms": {"apple": {"libraries": {"libmpv": {"key": candidate_key}}}}}
        archive = archive_bytes(candidate)
        digest = "sha256:" + hashlib.sha256(archive).hexdigest()
        commands = []
        with tempfile.TemporaryDirectory() as directory:
            checkout = Path(directory)
            manifest = checkout / "artifacts.json"
            package = checkout / "Package.swift"
            manifest.write_text(json.dumps(original))
            package.write_text("original package")

            def command(args, **kwargs):
                commands.append(args)
                status = 0
                if args[:3] == ["python3", "scripts/keys.py", "verify"]:
                    key = json.loads(manifest.read_text())["platforms"]["apple"]["libraries"]["libmpv"]["key"]
                    status = 0 if key == "valid" else 1
                elif args[:3] == ["python3", "scripts/keys.py", "render"]:
                    package.write_text("generated by current source")
                return subprocess.CompletedProcess(args, status, "", "")

            def gh_json(*args):
                endpoint = args[1]
                if endpoint.endswith("/42"):
                    return trusted_run()
                if "/jobs?" in endpoint:
                    return {"jobs": [{"name": "Publish apple", "status": "completed",
                                      "conclusion": "success" if published else "failure"}]}
                if "/artifacts?" in endpoint:
                    return {"artifacts": [{"id": 123, "name": "manifest-apple", "expired": False,
                                           "size_in_bytes": len(archive), "digest": digest}]}
                raise AssertionError(args)

            def download(args, **kwargs):
                self.assertEqual(args[-1], f"repos/{release.MPV_REPO}/actions/artifacts/123/zip")
                kwargs["stdout"].write(archive)
                return subprocess.CompletedProcess(args, 0, b"", b"")

            with (patch.object(release, "NATIVE_GROUPS", ("apple",)),
                  patch.object(release, "active_run", return_value=None),
                  patch.object(release, "workflow_runs", return_value=[{
                      "databaseId": 42, "status": "completed", "event": "workflow_dispatch",
                      "displayTitle": "action:build:pool:private"}]),
                  patch.object(release, "command", side_effect=command),
                  patch.object(release, "gh_json", side_effect=gh_json),
                  patch.object(release.subprocess, "run", side_effect=download),
                  patch.object(release, "git_commit_as_current_user") as commit,
                  patch.object(release, "verify_native_release_assets",
                               side_effect=release.ReleaseError("bad asset") if asset_error else None)):
                if asset_error:
                    with self.assertRaisesRegex(release.ReleaseError, "bad asset"):
                        release.recover_native_groups(checkout, checkout / "recovery")
                    recovered = []
                else:
                    recovered = release.recover_native_groups(checkout, checkout / "recovery")
                if recovered:
                    self.assertEqual(recovered, ["apple"])
                    self.assertEqual(json.loads(manifest.read_text()), candidate)
                    self.assertEqual(package.read_text(), "generated by current source")
                    commit.assert_called_once()
                    self.assertIn(["git", "push", "origin", "HEAD:refs/heads/main"], commands)
                else:
                    self.assertEqual(json.loads(manifest.read_text()), original)
                    self.assertEqual(package.read_text(), "original package")
                    commit.assert_not_called()
                    self.assertFalse(any(args[:2] == ["git", "push"] for args in commands))

    def test_verified_complete_group_is_committed_for_reuse(self):
        self._exercise_recovery()

    def test_stale_source_group_is_rebuilt_without_manifest_mutation(self):
        self._exercise_recovery(candidate_key="old-source")

    def test_failed_publisher_cannot_supply_a_manifest(self):
        self._exercise_recovery(published=False)

    def test_bad_release_asset_rolls_back_manifest_and_package(self):
        self._exercise_recovery(asset_error=True)


if __name__ == "__main__":
    unittest.main()
