#!/usr/bin/env python3
"""Behavior tests for scripts/set_native_revision.sh.

The script moves ten pin sites at once and promises all-or-nothing: either
every Apple requirement, every SwiftPM lock, and mpv-build.lock.json move to
the new commit together, or nothing is written. These tests drive the real
script end to end against a synthetic Plezy tree and a real (temporary) git
checkout of the unified mpv-build repo, because the failure that matters --
a half-moved pin -- can only happen across process and file boundaries.

The pin-site fixtures reproduce the exact anchors the rewrites key on: the
pbxproj carries the `/* XCRemoteSwiftPackageReference "MPVKit" */ = {` object
plus the same comment inside a packageReferences list and a product
dependency (which must NOT match), and the SwiftPM locks are version-3 files
with an unrelated pin that must survive untouched. The fixtures are staged at
the pre-flip edde746/MPVKit state, so every successful run also exercises the
repo flip to edde746/mpv-build: repositoryURL, SwiftPM identity, and the
pbxproj comment strings move with the revision in one all-or-nothing pass.
"""

import json
import http.server
import os
import shutil
import subprocess
import tempfile
import threading
import unittest
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SCRIPT = SCRIPT_DIR / "set_native_revision.sh"

OLD_SHA = "b" * 40
OLD_URL = "https://github.com/edde746/MPVKit"
NEW_REPO = "edde746/mpv-build"
NEW_URL = f"https://github.com/{NEW_REPO}"
NEW_KEY_ANDROID = "aa11bb22cc33"
NEW_KEY_LINUX = "dd44ee55ff66"

PBXPROJ_TEMPLATE = """\
// !$*UTF8*$!
{{
\tobjects = {{
\t\t97C146E61CF9000F007C117D /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tpackageReferences = (
\t\t\t\tCEE842A5A25923620300AB90 /* XCRemoteSwiftPackageReference "MPVKit" */,
\t\t\t);
\t\t}};
\t\tCEE842A5A25923620300AB90 /* XCRemoteSwiftPackageReference "MPVKit" */ = {{
\t\t\tisa = XCRemoteSwiftPackageReference;
\t\t\trepositoryURL = "https://github.com/edde746/MPVKit";
\t\t\trequirement = {{
\t\t\t\tkind = revision;
\t\t\t\trevision = {revision};
\t\t\t}};
\t\t}};
\t\tEA0F4263E7B912702C490108 /* MPVKit */ = {{
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = CEE842A5A25923620300AB90 /* XCRemoteSwiftPackageReference "MPVKit" */;
\t\t\tproductName = MPVKit;
\t\t}};
\t}};
\trootObject = 97C146E61CF9000F007C117D /* Project object */;
}}
"""

RESOLVED_TEMPLATE = {
    "originHash": "c535d3cdb62bd4e11e67f3c9e68290fa7ee9306634c5f56d2b0396eb75ed41ee",
    "pins": [
        {
            "identity": "mpvkit",
            "kind": "remoteSourceControl",
            "location": "https://github.com/edde746/MPVKit",
            "state": {"revision": OLD_SHA},
        },
        {
            "identity": "unrelated",
            "kind": "remoteSourceControl",
            "location": "https://example.invalid/unrelated",
            "state": {"revision": "c" * 40},
        },
    ],
    "version": 3,
}

VERSIONS_FIXTURE = {"formatVersion": 1, "components": {"mpv": {"version": "0.40.0"}}}


def android_section() -> dict:
    return {
        "assetBase": "https://github.com/edde746/MPVKit/releases/download/binaries-android",
        "libraries": {
            "libmpv-android": {
                "key": NEW_KEY_ANDROID,
                "prebuilt": {
                    abi: {
                        "asset": f"libmpv-android-{NEW_KEY_ANDROID}-{abi}.tar.gz",
                        "checksum": format(index, "x") * 64,
                    }
                    for index, abi in enumerate(
                        ("arm64-v8a", "armeabi-v7a", "x86", "x86_64"), start=1
                    )
                },
            }
        },
    }


def linux_section() -> dict:
    return {
        "assetBase": "https://github.com/edde746/MPVKit/releases/download/binaries-linux",
        "libraries": {
            "libmpv-linux": {
                "key": NEW_KEY_LINUX,
                "prebuilt": {
                    "x86_64": {
                        "asset": f"libmpv-linux-{NEW_KEY_LINUX}-x86_64.tar.gz",
                        "checksum": "5" * 64,
                    }
                },
            }
        },
    }


def apple_section() -> dict:
    return {
        "assetBase": "https://github.com/edde746/MPVKit/releases/download/binaries-apple",
        "libraries": {
            "libmpv": {
                "frameworks": {
                    "Libmpv": {
                        "asset": "Libmpv-e73a34ad67f2.xcframework.zip",
                        "checksum": "6" * 64,
                    }
                },
                "key": "e73a34ad67f2",
                "prebuilt": {"ios": "libmpv-all-e73a34ad67f2-ios.zip"},
            }
        },
    }


def artifacts_fixture() -> dict:
    # windows deliberately absent: its omission note is part of the contract.
    return {
        "platforms": {
            "apple": apple_section(),
            "android": android_section(),
            "linux": linux_section(),
        },
        "schema": 2,
    }


class SetNativeRevisionTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = Path(tempfile.mkdtemp(prefix="set-native-revision-test."))
        self.addCleanup(shutil.rmtree, self.temporary, ignore_errors=True)
        self.root = self.temporary / "plezy"
        self._stage_plezy_tree()

    # ---- fixtures ---------------------------------------------------------

    def _stage_plezy_tree(self) -> None:
        scripts = self.root / "scripts"
        scripts.mkdir(parents=True)
        shutil.copy2(SCRIPT, scripts / SCRIPT.name)
        for platform in ("ios", "macos", "tvos"):
            base = self.root / platform
            (base / "Runner.xcodeproj").mkdir(parents=True)
            self._pbxproj(platform).write_text(
                PBXPROJ_TEMPLATE.format(revision=OLD_SHA), encoding="utf-8"
            )
            for lock in self._resolved(platform):
                lock.parent.mkdir(parents=True)
                lock.write_text(
                    json.dumps(RESOLVED_TEMPLATE, indent=2) + "\n", encoding="utf-8"
                )

    def _pbxproj(self, platform: str) -> Path:
        return self.root / platform / "Runner.xcodeproj" / "project.pbxproj"

    def _resolved(self, platform: str) -> list[Path]:
        return [
            self.root
            / platform
            / "Runner.xcodeproj"
            / "project.xcworkspace"
            / "xcshareddata"
            / "swiftpm"
            / "Package.resolved",
            self.root
            / platform
            / "Runner.xcworkspace"
            / "xcshareddata"
            / "swiftpm"
            / "Package.resolved",
        ]

    def _pin_sites(self) -> list[Path]:
        sites = []
        for platform in ("ios", "macos", "tvos"):
            sites.append(self._pbxproj(platform))
            sites.extend(self._resolved(platform))
        return sites

    def _make_mpv_build(
        self, name: str = "mpv-build", *, artifacts: dict | None = None, manifests: bool = True
    ) -> tuple[Path, str]:
        """A real git checkout carrying the manifests, and its HEAD commit."""
        repo = self.temporary / name
        repo.mkdir()
        if manifests:
            (repo / "artifacts.json").write_text(
                json.dumps(artifacts or artifacts_fixture(), indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            (repo / "versions.json").write_text(
                json.dumps(VERSIONS_FIXTURE, indent=2, sort_keys=True) + "\n",
                encoding="utf-8",
            )
        else:
            (repo / "README.md").write_text("pre-migration MPVKit\n", encoding="utf-8")
        git = self._git(repo)
        subprocess.run(git[:3] + ["init", "-q"], check=True)
        subprocess.run(git + ["add", "-A"], check=True)
        subprocess.run(git + ["commit", "-q", "-m", "fixture"], check=True)
        head = subprocess.run(
            git[:3] + ["rev-parse", "HEAD"], check=True, capture_output=True, text=True
        ).stdout.strip()
        return repo, head

    def _git(self, repo: Path) -> list[str]:
        return [
            "git",
            "-C",
            str(repo),
            "-c",
            "user.name=fixture",
            "-c",
            "user.email=fixture@example.invalid",
            "-c",
            "commit.gpgsign=false",
        ]

    def _advance(self, repo: Path) -> str:
        """A second commit in the fixture repo, so the pin can move again."""
        (repo / "CHANGELOG").write_text("moved\n", encoding="utf-8")
        git = self._git(repo)
        subprocess.run(git + ["add", "-A"], check=True)
        subprocess.run(git + ["commit", "-q", "-m", "fixture 2"], check=True)
        return subprocess.run(
            git[:3] + ["rev-parse", "HEAD"], check=True, capture_output=True, text=True
        ).stdout.strip()

    def _run(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["bash", str(self.root / "scripts" / SCRIPT.name), *args],
            check=False,
            capture_output=True,
            text=True,
        )

    def _snapshot(self) -> dict[Path, str]:
        """Byte content of every pin site that exists right now."""
        return {
            site: site.read_text(encoding="utf-8")
            for site in self._pin_sites()
            if site.exists()
        }

    def _expected_lock(self, commit: str, repo: str = NEW_REPO) -> str:
        artifacts = {}
        for group, section in (("android", android_section()), ("linux", linux_section())):
            ((_, entry),) = section["libraries"].items()
            artifacts[group] = {
                "assetBase": section["assetBase"],
                "assets": entry["prebuilt"],
                "key": entry["key"],
            }
        lock = {
            "artifacts": artifacts,
            "commit": commit,
            "formatVersion": 1,
            "repo": repo,
        }
        return json.dumps(lock, indent=2, sort_keys=True) + "\n"

    # ---- the pin moves as one unit ----------------------------------------

    def _assert_pinned(self, commit: str, url: str = NEW_URL) -> None:
        """All nine Apple sites name url@commit with coherent names/identities."""
        name = url.rsplit("/", 1)[-1]
        for platform in ("ios", "macos", "tvos"):
            pbxproj = self._pbxproj(platform).read_text(encoding="utf-8")
            self.assertIn(f"revision = {commit};", pbxproj)
            self.assertIn(f'repositoryURL = "{url}";', pbxproj)
            # Xcode derives these comments from the URL's last path component;
            # all three mentions (packageReferences list, object definition,
            # product dependency) must carry the same name.
            self.assertEqual(
                pbxproj.count(f'/* XCRemoteSwiftPackageReference "{name}" */'), 3
            )
            # The product name comes from Package.swift, not the URL.
            self.assertIn("productName = MPVKit;", pbxproj)
            for lock in self._resolved(platform):
                resolved = json.loads(lock.read_text(encoding="utf-8"))
                by_identity = {pin["identity"]: pin for pin in resolved["pins"]}
                pin = by_identity[name.lower()]
                self.assertEqual(pin["location"], url)
                self.assertEqual(pin["state"]["revision"], commit)
                # Targeted edit: the unrelated pin and originHash never churn.
                self.assertEqual(by_identity["unrelated"]["state"]["revision"], "c" * 40)
                self.assertEqual(
                    by_identity["unrelated"]["location"], "https://example.invalid/unrelated"
                )
                self.assertEqual(resolved["originHash"], RESOLVED_TEMPLATE["originHash"])

    def test_the_flip_rewrites_every_pin_site_and_derives_the_lock(self) -> None:
        # The tree starts at the pre-flip edde746/MPVKit pin; a run against the
        # unified repo must move URL, identity, comments, and revision at all
        # nine Apple sites and derive the lock's repo from the source used.
        repo, commit = self._make_mpv_build()

        result = self._run(commit, "--repo", str(repo))

        self.assertEqual(result.returncode, 0, result.stderr)
        self._assert_pinned(commit)
        for platform in ("ios", "macos", "tvos"):
            pbxproj = self._pbxproj(platform).read_text(encoding="utf-8")
            self.assertNotIn(OLD_SHA, pbxproj)
            self.assertNotIn(OLD_URL, pbxproj)
            self.assertNotIn('XCRemoteSwiftPackageReference "MPVKit"', pbxproj)
        self.assertEqual(
            (self.root / "mpv-build.lock.json").read_text(encoding="utf-8"),
            self._expected_lock(commit),
        )
        self.assertIn(
            "note: no windows artifacts published at this commit; "
            "omitted from mpv-build.lock.json",
            result.stdout,
        )

    def test_default_source_is_the_sibling_checkout(self) -> None:
        # No --repo: the ../mpv-build convention must find the checkout
        # sitting next to the Plezy tree.
        _, commit = self._make_mpv_build()

        result = self._run(commit)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("../mpv-build", result.stdout)
        self.assertIn(f"revision = {commit};", self._pbxproj("ios").read_text(encoding="utf-8"))

    def test_remote_source_serves_the_manifests_by_commit(self) -> None:
        docroot = self.temporary / "raw"
        commit = "d" * 40
        (docroot / commit).mkdir(parents=True)
        (docroot / commit / "artifacts.json").write_text(
            json.dumps(artifacts_fixture()), encoding="utf-8"
        )
        (docroot / commit / "versions.json").write_text(
            json.dumps(VERSIONS_FIXTURE), encoding="utf-8"
        )
        handler = lambda *args, **kwargs: http.server.SimpleHTTPRequestHandler(  # noqa: E731
            *args, directory=str(docroot), **kwargs
        )
        server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)

        result = self._run(commit, "--repo", f"http://127.0.0.1:{server.server_address[1]}")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.root / "mpv-build.lock.json").read_text(encoding="utf-8"),
            self._expected_lock(commit),
        )

    def test_rerun_with_the_same_commit_is_a_reported_noop(self) -> None:
        repo, commit = self._make_mpv_build()
        first = self._run(commit, "--repo", str(repo))
        self.assertEqual(first.returncode, 0, first.stderr)
        before = self._snapshot()
        lock_before = (self.root / "mpv-build.lock.json").read_text(encoding="utf-8")

        second = self._run(commit, "--repo", str(repo))

        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("nothing to do", second.stdout)
        self.assertEqual(self._snapshot(), before)
        self.assertEqual(
            (self.root / "mpv-build.lock.json").read_text(encoding="utf-8"), lock_before
        )

    def test_a_move_within_the_target_repo_only_touches_revisions(self) -> None:
        # Once flipped, a later pin move must not churn URLs, identities, or
        # comment names -- only the revisions and the lock's commit change.
        repo, first_commit = self._make_mpv_build()
        first = self._run(first_commit, "--repo", str(repo))
        self.assertEqual(first.returncode, 0, first.stderr)
        second_commit = self._advance(repo)

        result = self._run(second_commit, "--repo", str(repo))

        self.assertEqual(result.returncode, 0, result.stderr)
        self._assert_pinned(second_commit)
        self.assertEqual(
            (self.root / "mpv-build.lock.json").read_text(encoding="utf-8"),
            self._expected_lock(second_commit),
        )

    def test_lock_repo_derives_from_the_local_checkouts_origin_remote(self) -> None:
        # The pin names whichever GitHub repo actually served the commit, so a
        # checkout cloned from a fork flips every site to that fork.
        repo, commit = self._make_mpv_build()
        subprocess.run(
            self._git(repo)[:3]
            + ["remote", "add", "origin", "git@github.com:someone/mpv-build.git"],
            check=True,
        )

        result = self._run(commit, "--repo", str(repo))

        self.assertEqual(result.returncode, 0, result.stderr)
        self._assert_pinned(commit, url="https://github.com/someone/mpv-build")
        self.assertEqual(
            (self.root / "mpv-build.lock.json").read_text(encoding="utf-8"),
            self._expected_lock(commit, repo="someone/mpv-build"),
        )

    # ---- refusals leave every byte alone ----------------------------------

    def test_refuses_a_malformed_sha(self) -> None:
        before = self._snapshot()

        result = self._run("deadbeef")

        self.assertEqual(result.returncode, 2)
        self.assertIn("not a full 40-character lowercase commit sha", result.stderr)
        self.assertEqual(self._snapshot(), before)

    def test_refuses_when_a_pin_site_is_missing(self) -> None:
        repo, commit = self._make_mpv_build()
        removed = self._resolved("macos")[1]
        removed.unlink()
        before = self._snapshot()

        result = self._run(commit, "--repo", str(repo))

        self.assertEqual(result.returncode, 1)
        self.assertIn("missing native pin site(s)", result.stderr)
        self.assertIn(str(removed.relative_to(self.root)), result.stderr)
        self.assertEqual(self._snapshot(), before)
        self.assertFalse((self.root / "mpv-build.lock.json").exists())

    def test_an_ambiguous_edit_aborts_before_any_write(self) -> None:
        repo, commit = self._make_mpv_build()
        pbxproj = self._pbxproj("tvos")
        content = pbxproj.read_text(encoding="utf-8")
        anchor = '/* XCRemoteSwiftPackageReference "MPVKit" */ = {'
        duplicated = content.replace(
            "\trootObject",
            "\t\tDUPLICATE " + anchor + "\n"
            '\t\t\trepositoryURL = "https://github.com/edde746/MPVKit";\n'
            "\t\t\trequirement = {\n"
            "\t\t\t\tkind = revision;\n"
            f"\t\t\t\trevision = {OLD_SHA};\n"
            "\t\t\t};\n"
            "\t\t};\n"
            "\trootObject",
        )
        pbxproj.write_text(duplicated, encoding="utf-8")
        before = self._snapshot()

        result = self._run(commit, "--repo", str(repo))

        self.assertEqual(result.returncode, 1)
        self.assertIn("expected exactly 1 native pin, found 2", result.stderr)
        # All-or-nothing: the eight unambiguous sites must not have moved, and
        # no lock may appear alongside a refused pin.
        self.assertEqual(self._snapshot(), before)
        self.assertFalse((self.root / "mpv-build.lock.json").exists())

    def test_refuses_a_commit_that_predates_the_unified_repo(self) -> None:
        repo, commit = self._make_mpv_build(name="MPVKit", manifests=False)
        before = self._snapshot()

        result = self._run(commit, "--repo", str(repo))

        self.assertEqual(result.returncode, 1)
        self.assertIn("not a unified mpv-build commit", result.stderr)
        self.assertEqual(self._snapshot(), before)

    def test_refuses_a_checksumless_prebuilt_asset(self) -> None:
        artifacts = artifacts_fixture()
        android = artifacts["platforms"]["android"]["libraries"]["libmpv-android"]
        android["prebuilt"]["arm64-v8a"] = f"libmpv-android-{NEW_KEY_ANDROID}-arm64-v8a.tar.gz"
        repo, commit = self._make_mpv_build(artifacts=artifacts)
        before = self._snapshot()

        result = self._run(commit, "--repo", str(repo))

        self.assertEqual(result.returncode, 1)
        self.assertIn("carries no checksum", result.stderr)
        self.assertEqual(self._snapshot(), before)
        self.assertFalse((self.root / "mpv-build.lock.json").exists())

    def test_a_group_with_no_published_libraries_is_omitted_with_a_note(self) -> None:
        artifacts = artifacts_fixture()
        artifacts["platforms"]["linux"]["libraries"] = {}
        repo, commit = self._make_mpv_build(artifacts=artifacts)

        result = self._run(commit, "--repo", str(repo))

        self.assertEqual(result.returncode, 0, result.stderr)
        lock = json.loads((self.root / "mpv-build.lock.json").read_text(encoding="utf-8"))
        self.assertEqual(sorted(lock["artifacts"]), ["android"])
        self.assertIn("linux has published no libraries", result.stdout)


if __name__ == "__main__":
    unittest.main()
