#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests of deploy.py's helpers and phases, without network or builds: uv run --script scripts/release/test_deploy.py
(or python3 -m unittest scripts/release/test_deploy.py)."""

import json
import os
import plistlib
import sys
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path
from types import SimpleNamespace
from unittest import mock
from xml.etree import ElementTree as ET

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import deploy
from deploy import (
    DeployError,
    State,
    bump_version_text,
    metainfo_with_release,
    parse_env_text,
    parse_version_text,
    resolve_msstore_pricing,
    resolve_phases,
)

XCCONFIG = """\
// The app's version on every platform.
// MARKETING_VERSION is major.minor.patch.
MARKETING_VERSION = 2.26.0
CURRENT_PROJECT_VERSION = 160
"""


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


class LoadEnvFileTest(unittest.TestCase):
    def test_file_values_override_stale_ambient_release_configuration(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".env").write_text(
                "DELIVER_APP_IDENTIFIER=com.edde746.plezy\n"
                "SUPPLY_PACKAGE_NAME=${DELIVER_APP_IDENTIFIER}\n"
                "APPLE_TEAM_ID=G88U5B5783\n",
                encoding="utf-8",
            )
            ambient = {
                "DELIVER_APP_IDENTIFIER": "com.example.stale",
                "SUPPLY_PACKAGE_NAME": "com.example.stale",
                "APPLE_TEAM_ID": "STALETEAM1",
            }
            with (
                mock.patch.object(deploy, "ROOT", root),
                mock.patch.dict(os.environ, ambient, clear=True),
            ):
                loaded = deploy.load_env_file()

        self.assertEqual(loaded["DELIVER_APP_IDENTIFIER"], "com.edde746.plezy")
        self.assertEqual(loaded["SUPPLY_PACKAGE_NAME"], "com.edde746.plezy")
        self.assertEqual(loaded["APPLE_TEAM_ID"], "G88U5B5783")

    def test_missing_file_fails_a_real_run_and_not_a_dry_run(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, mock.patch.object(deploy, "ROOT", Path(tmp)):
            with self.assertRaises(DeployError):
                deploy.load_env_file()
            with mock.patch.dict(os.environ, {"X": "1"}, clear=True):
                self.assertEqual(deploy.load_env_file(required=False), {"X": "1"})


class GoogleRequestTest(unittest.TestCase):
    def test_requests_use_client_retry_policy(self) -> None:
        request = mock.Mock()
        request.execute.return_value = {"ok": True}

        self.assertEqual(deploy._execute_google_request(request), {"ok": True})

        request.execute.assert_called_once_with(num_retries=5)

    def test_resumable_upload_retries_every_chunk(self) -> None:
        status = mock.Mock()
        status.progress.return_value = 0.5
        request = mock.Mock()
        request.next_chunk.side_effect = [(status, None), (None, {"versionCode": 131})]

        response = deploy._execute_resumable_google_upload(request, "play")

        self.assertEqual(response, {"versionCode": 131})
        self.assertEqual(request.next_chunk.call_count, 2)
        request.next_chunk.assert_called_with(num_retries=5)

    def test_resumable_upload_resumes_after_a_dropped_connection(self) -> None:
        request = mock.Mock()
        request.next_chunk.side_effect = [ConnectionError("reset"), (None, {"versionCode": 161})]
        with mock.patch.object(deploy.time, "sleep"):
            response = deploy._execute_resumable_google_upload(request, "play")
        self.assertEqual(response, {"versionCode": 161})


class VersionTest(unittest.TestCase):
    def test_parses_the_two_values_beside_comments(self) -> None:
        self.assertEqual(parse_version_text(XCCONFIG), ("2.26.0", 160))

    def test_rejects_malformed_values(self) -> None:
        with self.assertRaises(DeployError):
            parse_version_text("MARKETING_VERSION = 2.26\nCURRENT_PROJECT_VERSION = 160\n")
        with self.assertRaises(DeployError):
            parse_version_text("MARKETING_VERSION = 2.26.0\n")

    def test_bump_writes_both_values_and_keeps_everything_else(self) -> None:
        result = bump_version_text(XCCONFIG, "2.27.0", 161)
        self.assertEqual(parse_version_text(result), ("2.27.0", 161))
        self.assertEqual(
            result,
            XCCONFIG.replace("= 2.26.0", "= 2.27.0").replace("= 160", "= 161"),
        )

    def test_bump_may_keep_the_version_for_a_new_build(self) -> None:
        self.assertEqual(parse_version_text(bump_version_text(XCCONFIG, "2.26.0", 161)), ("2.26.0", 161))

    def test_bump_never_goes_back(self) -> None:
        with self.assertRaises(DeployError):
            bump_version_text(XCCONFIG, "2.25.9", 161)
        with self.assertRaises(DeployError):
            bump_version_text(XCCONFIG, "2.27.0", 160)


class MetainfoTest(unittest.TestCase):
    METAINFO = """\
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>com.edde746.plezy</id>
</component>
"""
    NOTES = "## Features\n- Live TV & recordings\n- Music\n\n## Fixes\n* Subtitles <ASS>\n"

    def test_adds_releases_with_the_notes(self) -> None:
        result = metainfo_with_release(self.METAINFO, "2.27.0", "2026-11-06", self.NOTES)
        release = ET.fromstring(result).find("releases/release")
        self.assertEqual((release.get("version"), release.get("date")), ("2.27.0", "2026-11-06"))
        description = release.find("description")
        self.assertEqual([child.tag for child in description], ["p", "ul", "p", "ul"])
        self.assertEqual(description[1][0].text, "Live TV & recordings")
        self.assertEqual(description[3][0].text, "Subtitles <ASS>")

    def test_puts_the_new_release_first_and_is_idempotent(self) -> None:
        first = metainfo_with_release(self.METAINFO, "2.27.0", "2026-11-06", self.NOTES)
        second = metainfo_with_release(first, "2.28.0", "2026-12-01", "- More")
        versions = [r.get("version") for r in ET.fromstring(second).iter("release")]
        self.assertEqual(versions, ["2.28.0", "2.27.0"])
        self.assertEqual(metainfo_with_release(second, "2.28.0", "2026-12-02", "- Other"), second)

    def test_the_repository_metainfo_takes_a_release(self) -> None:
        text = (deploy.ROOT / deploy.METAINFO_FILE).read_text(encoding="utf-8")
        result = metainfo_with_release(text, "9.9.9", "2026-11-06", "- Note")
        self.assertEqual(ET.fromstring(result).find("releases/release").get("version"), "9.9.9")


class BumpPhaseTest(unittest.TestCase):
    """bump and its preflight in a temporary git checkout of main with a local origin."""

    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name) / "repo"
        origin = Path(tmp.name) / "origin.git"
        subprocess.run(["git", "init", "-q", "--bare", origin], check=True)
        self.root.mkdir()
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "release@example.com")
        self.git("config", "user.name", "Release")
        (self.root / "version.xcconfig").write_text(XCCONFIG, encoding="utf-8")
        metainfo = self.root / deploy.METAINFO_FILE
        metainfo.parent.mkdir(parents=True)
        metainfo.write_text(MetainfoTest.METAINFO, encoding="utf-8")
        (self.root / "README").write_text("Plezy\n", encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "-q", "-m", "start")
        self.git("remote", "add", "origin", str(origin))
        self.git("push", "-q", "origin", "main")
        notes = Path(tmp.name) / "notes"
        notes.mkdir()
        (notes / "github.md").write_text("- Note\n", encoding="utf-8")
        self.state = State(version="2.27.0", build_number=161)
        for patch in (
            mock.patch.object(deploy, "ROOT", self.root),
            mock.patch.object(deploy, "NOTES_DIR", notes),
            mock.patch.object(self.state, "save"),
        ):
            patch.start()
            self.addCleanup(patch.stop)

    def git(self, *args: str) -> str:
        return subprocess.run(["git", *args], cwd=self.root, check=True, capture_output=True, text=True).stdout

    def context(self, phases: list[str]) -> deploy.Context:
        return deploy.Context(SimpleNamespace(dry_run=False, yes=True), {}, self.state, phases)

    def assert_one_bump_commit_pushed(self) -> None:
        self.assertEqual(self.git("log", "--format=%s", "HEAD~1..main").splitlines(), ["chore: bump version to 2.27.0"])
        self.assertEqual(self.git("log", "--format=%s", "HEAD~1").splitlines(), ["start"])
        self.assertEqual(
            sorted(self.git("show", "--name-only", "--format=", "main").split()),
            sorted(["version.xcconfig", deploy.METAINFO_FILE]),
        )
        self.assertEqual(parse_version_text(self.git("show", "main:version.xcconfig")), ("2.27.0", 161))
        self.assertIn('<release version="2.27.0"', self.git("show", f"main:{deploy.METAINFO_FILE}"))
        self.assertEqual(self.git("rev-parse", "origin/main"), self.git("rev-parse", "main"))
        self.assertEqual(self.state.data["release_sha"], self.git("rev-parse", "main").strip())

    def test_writes_both_files_and_commits_only_them(self) -> None:
        (self.root / "README").write_text("Plezy, staged\n", encoding="utf-8")
        self.git("add", "README")
        deploy.phase_bump(self.context(["bump"]))
        self.assert_one_bump_commit_pushed()
        self.assertEqual(self.git("status", "--porcelain"), "M  README\n")

    def test_a_rerun_after_a_bump_interrupted_before_its_commit_commits_both_files(self) -> None:
        real_run = deploy.run

        def run_until_commit(cmd, **kwargs):
            if cmd[:2] == ["git", "commit"]:
                raise KeyboardInterrupt
            return real_run(cmd, **kwargs)

        with mock.patch.object(deploy, "run", run_until_commit), self.assertRaises(KeyboardInterrupt):
            deploy.phase_bump(self.context(["bump"]))
        self.assertEqual(len(self.git("status", "--porcelain").splitlines()), 2)

        ctx = self.context(["preflight", "bump"])
        self.assertEqual(deploy.preflight_problems(ctx), [])
        deploy.phase_bump(ctx)
        self.assert_one_bump_commit_pushed()
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_preflight_refuses_unrelated_or_unexpected_changes(self) -> None:
        ctx = self.context(["preflight", "bump"])
        (self.root / "README").write_text("Plezy, edited\n", encoding="utf-8")
        self.assertIn(" M README", "\n".join(deploy.preflight_problems(ctx)))
        self.git("checkout", "README")
        (self.root / "version.xcconfig").write_text(bump_version_text(XCCONFIG, "2.27.0", 162), encoding="utf-8")
        self.assertIn(" M version.xcconfig", "\n".join(deploy.preflight_problems(ctx)))


class AndroidBuildTest(unittest.TestCase):
    def test_play_builds_the_store_bundle(self) -> None:
        self.assertEqual(
            deploy.gradle_command("play"),
            ["./gradlew", "--console=plain", "-Pplezy.flavor=store", ":app-android:bundleRelease"],
        )
        self.assertEqual(deploy.expected_version_code("play", 161), 161)

    def test_amazon_builds_the_amazon_apk_with_the_offset_version_code(self) -> None:
        self.assertEqual(
            deploy.gradle_command("amazon"),
            ["./gradlew", "--console=plain", "-Pplezy.flavor=amazon", ":app-android:assembleRelease"],
        )
        self.assertEqual(deploy.expected_version_code("amazon", 161), 3161)

    def test_mapping_uuid_reads_the_sentry_properties(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            aab = Path(tmp) / "app.aab"
            with zipfile.ZipFile(aab, "w") as archive:
                archive.writestr("base/assets/sentry-debug-meta.properties",
                                 "#Generated\nio.sentry.ProguardUuids=1234-abcd\n")
            self.assertEqual(deploy.mapping_uuid(aab, "base/assets/sentry-debug-meta.properties"), "1234-abcd")
            with zipfile.ZipFile(aab, "w") as archive:
                archive.writestr("base/assets/sentry-debug-meta.properties", "other=1\n")
            with self.assertRaises(DeployError):
                deploy.mapping_uuid(aab, "base/assets/sentry-debug-meta.properties")

    def test_build_runs_gradle_keeps_the_mapping_and_uploads_native_symbols(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mappings = root / "mappings"
            ctx = deploy.Context(SimpleNamespace(dry_run=False), {"SENTRY_AUTH_TOKEN": "t"},
                                 State("2.27.0", 161), ["play"])

            def gradle(cmd, **_kwargs):
                if cmd[0] == "./gradlew":
                    output = root / deploy.GRADLE_BUILDS["play"].output
                    output.parent.mkdir(parents=True)
                    with zipfile.ZipFile(output, "w") as archive:
                        archive.writestr("base/assets/sentry-debug-meta.properties",
                                         "io.sentry.ProguardUuids=uuid-1\n")
                    mapping = root / deploy.R8_MAPPING
                    mapping.parent.mkdir(parents=True)
                    mapping.write_text("mapping", encoding="utf-8")

            with (
                mock.patch.object(deploy, "ROOT", root),
                mock.patch.object(deploy, "MAPPINGS_DIR", mappings),
                mock.patch.object(deploy, "run", side_effect=gradle) as run_command,
            ):
                package = deploy.build_android(ctx, "play")
            self.assertEqual(package, root / deploy.GRADLE_BUILDS["play"].output)
            self.assertEqual((mappings / "uuid-1.txt").read_text(), "mapping")

        symbols = run_command.call_args_list[1]
        self.assertEqual(symbols.args[0][1:], ["android", root / deploy.GRADLE_BUILDS["play"].output])
        self.assertEqual(symbols.kwargs["env"]["SENTRY_AUTH_TOKEN"], "t")
        self.assertEqual(symbols.kwargs["env"]["SENTRY_URL"], "https://bugs.plezy.app")


class AppleUploadTest(unittest.TestCase):
    @staticmethod
    def _context() -> deploy.Context:
        return deploy.Context(
            args=SimpleNamespace(dry_run=False, yes=True),
            env={
                "APPLE_TEAM_ID": "G88U5B5783",
                "ASC_KEY_ID": "KEY1234567",
                "ASC_ISSUER_ID": "issuer",
                "ASC_KEY_PATH": "/keys/AuthKey_KEY1234567.p8",
            },
            state=State(version="2.26.0", build_number=160),
            phases=["ios", "tvos"],
        )

    def test_archive_command_per_platform(self) -> None:
        archive = Path("/tmp/Plezy-tvOS.xcarchive")
        command = deploy.apple_archive_command("tvos", archive, ["-allowProvisioningUpdates"])
        self.assertEqual(command[:2], ["xcodebuild", "archive"])
        self.assertEqual(command[command.index("-project") + 1], str(deploy.ROOT / "apple/Plezy.xcodeproj"))
        self.assertEqual(command[command.index("-scheme") + 1], "Plezy-tvOS")
        self.assertEqual(command[command.index("-configuration") + 1], "Release")
        self.assertEqual(command[command.index("-destination") + 1], "generic/platform=tvOS")
        self.assertEqual(command[command.index("-archivePath") + 1], str(archive))
        self.assertEqual(command[-1], "-allowProvisioningUpdates")
        ios = deploy.apple_archive_command("ios", archive, [])
        self.assertEqual(ios[ios.index("-scheme") + 1], "Plezy-iOS")
        self.assertEqual(ios[ios.index("-destination") + 1], "generic/platform=iOS")

    def test_archive_signs_automatically_with_the_asc_key(self) -> None:
        args = deploy._asc_auth_args(self._context().env)
        self.assertEqual(args[0], "-allowProvisioningUpdates")
        self.assertEqual(args[args.index("-authenticationKeyID") + 1], "KEY1234567")
        self.assertEqual(args[args.index("-authenticationKeyIssuerID") + 1], "issuer")

    def test_export_options(self) -> None:
        options = plistlib.loads(deploy.EXPORT_OPTIONS.read_bytes())
        self.assertEqual(options["method"], "app-store-connect")
        self.assertEqual(options["destination"], "export")
        self.assertEqual(options["teamID"], "G88U5B5783")
        self.assertIs(options["uploadSymbols"], True)
        self.assertIs(options["manageAppVersionAndBuildNumber"], False)

    def test_export_uses_local_xcode_account_and_returns_ipa(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            apple_dir = Path(tmp) / "apple"
            archive = Path(tmp) / "Plezy-tvOS.xcarchive"
            archive.mkdir()
            ipa = apple_dir / "export-tvos/Plezy.ipa"
            with (
                mock.patch.object(deploy, "APPLE_DIR", apple_dir),
                mock.patch.object(deploy, "run") as run_command,
                mock.patch.object(deploy, "_find_single_ipa", return_value=ipa),
            ):
                result = deploy._export_archive(self._context(), archive, "tvos")

        self.assertEqual(result, ipa)
        command = run_command.call_args.args[0]
        self.assertEqual(command[command.index("-exportOptionsPlist") + 1], str(deploy.EXPORT_OPTIONS))
        self.assertIn("-allowProvisioningUpdates", command)
        self.assertNotIn("-authenticationKeyPath", command)

    def test_upload_uses_altool_with_api_key(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            ipa = Path(tmp) / "Plezy.ipa"
            ipa.write_bytes(b"ipa")
            with mock.patch.object(deploy, "run") as run_command:
                deploy._upload_ipa(self._context(), ipa, "tvos")

        run_command.assert_called_once_with(
            [
                "xcrun", "altool", "--upload-app",
                "--type", "appletvos",
                "-f", str(ipa),
                "--apiKey", "KEY1234567",
                "--apiIssuer", "issuer",
                "--p8-file-path", "/keys/AuthKey_KEY1234567.p8",
            ]
        )

    def test_ios_resume_skips_an_already_uploaded_build(self) -> None:
        ctx = self._context()
        with (
            mock.patch.object(deploy, "_asc_has_uploaded_build", return_value=True) as has_build,
            mock.patch.object(deploy, "run") as run_command,
        ):
            deploy.phase_ios(ctx)

        has_build.assert_called_once_with(ctx, "IOS")
        run_command.assert_not_called()

    def test_tvos_resume_skips_an_already_uploaded_build(self) -> None:
        ctx = self._context()
        with (
            mock.patch.object(deploy, "_asc_has_uploaded_build", return_value=True) as has_build,
            mock.patch.object(deploy, "run") as run_command,
        ):
            deploy.phase_tvos(ctx)

        has_build.assert_called_once_with(ctx, "TV_OS")
        run_command.assert_not_called()

    def test_phase_archives_exports_uploads_symbols_then_the_ipa(self) -> None:
        ctx = self._context()
        archive = Path("/tmp/a.xcarchive")
        ipa = Path("/tmp/Plezy.ipa")
        order = mock.Mock()
        with (
            mock.patch.object(deploy, "_asc_has_uploaded_build", return_value=False),
            mock.patch.object(deploy, "generate_xcode_project", order.generate),
            mock.patch.object(deploy, "_archive", order.archive),
            mock.patch.object(deploy, "_export_archive", order.export),
            mock.patch.object(deploy, "upload_symbols", order.symbols),
            mock.patch.object(deploy, "_upload_ipa", order.upload),
        ):
            order.archive.return_value = archive
            order.export.return_value = ipa
            deploy.phase_ios(ctx)

        self.assertEqual(
            [name for name, *_ in order.mock_calls],
            ["generate", "archive", "export", "symbols", "upload"],
        )
        order.symbols.assert_called_once_with(ctx, "dsym", archive / "dSYMs")
        order.upload.assert_called_once_with(ctx, ipa, "ios")


class ArchiveProblemsTest(unittest.TestCase):
    @staticmethod
    def _archive(root: Path, version: str = "2.26.0", top_shelf: bool = True) -> Path:
        archive = root / "Plezy-tvOS.xcarchive"
        app = archive / "Products/Applications/Plezy.app"
        app.mkdir(parents=True)
        info = {"CFBundleIdentifier": "com.edde746.plezy", "CFBundleShortVersionString": version,
                "CFBundleVersion": "160"}
        (app / "Info.plist").write_bytes(plistlib.dumps(info))
        if top_shelf:
            ext = app / "PlugIns/PlezyTopShelf.appex"
            ext.mkdir(parents=True)
            (ext / "Info.plist").write_bytes(plistlib.dumps(
                {**info, "CFBundleIdentifier": "com.edde746.plezy.TopShelfExtension"}))
        return archive

    def test_accepts_the_release_archive(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            archive = self._archive(Path(tmp))
            self.assertEqual(deploy.archive_problems(archive, "tvos", "2.26.0", 160), [])

    def test_names_a_wrong_version_and_a_missing_top_shelf(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            archive = self._archive(Path(tmp), version="2.25.0", top_shelf=False)
            problems = deploy.archive_problems(archive, "tvos", "2.26.0", 160)
            self.assertEqual(len(problems), 2)
            self.assertIn("PlezyTopShelf.appex", problems[1])
            self.assertEqual(len(deploy.archive_problems(archive, "ios", "2.26.0", 160)), 1)


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


class BuildFarmTest(unittest.TestCase):
    @staticmethod
    def _context(state: State) -> deploy.Context:
        return deploy.Context(
            args=SimpleNamespace(dry_run=False, yes=True),
            env={},
            state=state,
            phases=["farm_start", "farm_wait"],
        )

    def test_start_passes_release_tag_and_records_only_the_new_run(self) -> None:
        state = State(version="2.15.0", build_number=131)
        state.data["release_sha"] = "abc123"
        responses = [
            SimpleNamespace(returncode=0, stdout=json.dumps([{"databaseId": 10}])),
            SimpleNamespace(returncode=0, stdout=""),
            SimpleNamespace(
                returncode=0,
                stdout=json.dumps(
                    [
                        {
                            "databaseId": 12,
                            "displayTitle": "Build abc123",
                            "headSha": "abc123",
                            "status": "completed",
                            "createdAt": "2026-08-18T00:00:01Z",
                        },
                        {
                            "databaseId": 11,
                            "displayTitle": "Release 2.15.0",
                            "headSha": "abc123",
                            "status": "completed",
                            "createdAt": "2026-08-18T00:00:00Z",
                        },
                        {
                            "databaseId": 10,
                            "headSha": "abc123",
                            "status": "completed",
                            "createdAt": "2026-08-17T00:00:00Z",
                        },
                    ]
                ),
            ),
        ]
        with (
            mock.patch.object(deploy, "run", side_effect=responses) as run_command,
            mock.patch.object(deploy.time, "sleep"),
            mock.patch.object(state, "save"),
        ):
            deploy.phase_farm_start(self._context(state))

        dispatch = run_command.call_args_list[1].args[0]
        self.assertIn("release_tag=2.15.0", dispatch)
        self.assertEqual(state.data["farm_run_id"], 11)

    def test_start_resumes_discovery_without_dispatching_twice(self) -> None:
        state = State(version="2.15.0", build_number=131)
        state.data.update(
            {
                "release_sha": "abc123",
                "farm_dispatch": {
                    "headSha": "abc123",
                    "previousRunIds": [10],
                },
            }
        )
        response = SimpleNamespace(
            returncode=0,
            stdout=json.dumps(
                [
                    {
                        "databaseId": 11,
                        "displayTitle": "Release 2.15.0",
                        "headSha": "abc123",
                        "status": "queued",
                        "createdAt": "2026-08-18T00:00:00Z",
                    }
                ]
            ),
        )
        with (
            mock.patch.object(deploy, "run", return_value=response) as run_command,
            mock.patch.object(deploy.time, "sleep"),
            mock.patch.object(state, "save"),
        ):
            deploy.phase_farm_start(self._context(state))

        run_command.assert_called_once()
        self.assertEqual(run_command.call_args.args[0][:4], ["gh", "run", "list", "--workflow"])
        self.assertEqual(state.data["farm_run_id"], 11)
        self.assertNotIn("farm_dispatch", state.data)

    def test_wait_downloads_only_the_store_artifact(self) -> None:
        state = State(version="2.15.0", build_number=131)
        state.data["farm_run_id"] = 11
        with tempfile.TemporaryDirectory() as tmp:
            artifacts = Path(tmp) / "artifacts"
            responses = [
                SimpleNamespace(
                    returncode=0,
                    stdout=json.dumps({"status": "completed", "conclusion": "success"}),
                ),
                SimpleNamespace(returncode=0, stdout=""),
            ]
            with (
                mock.patch.object(deploy, "ARTIFACTS_DIR", artifacts),
                mock.patch.object(deploy, "run", side_effect=responses) as run_command,
            ):
                deploy.phase_farm_wait(self._context(state))

        download = run_command.call_args_list[1].args[0]
        self.assertEqual(download[:4], ["gh", "run", "download", "11"])
        self.assertIn("windows-msix", download)
        self.assertNotIn("--pattern", download)


class GitHubReleaseTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self._notes_dir = Path(self._tmp.name) / "notes"
        self._notes_dir.mkdir()
        (self._notes_dir / "github.md").write_text("Release notes\n", encoding="utf-8")
        self._notes_patch = mock.patch.object(deploy, "NOTES_DIR", self._notes_dir)
        self._notes_patch.start()

    def tearDown(self) -> None:
        self._notes_patch.stop()
        self._tmp.cleanup()

    @staticmethod
    def _context() -> deploy.Context:
        state = State(version="2.15.0", build_number=131)
        state.data["release_sha"] = "abc123"
        return deploy.Context(
            args=SimpleNamespace(dry_run=False, yes=True),
            env={},
            state=state,
            phases=["release"],
        )

    @staticmethod
    def _release_info(assets: set[str]) -> SimpleNamespace:
        return SimpleNamespace(
            returncode=0,
            stdout=json.dumps(
                {
                    "isDraft": True,
                    "targetCommitish": "abc123",
                    "assets": [{"name": name} for name in sorted(assets)],
                }
            ),
        )

    def test_asset_names_are_the_public_contract(self) -> None:
        names = deploy.RELEASE_ASSET_NAMES
        self.assertEqual(len(names), 24)
        self.assertIn("SHA256SUMS", names)
        self.assertIn("appcast.xml", names)
        self.assertIn("plezy-linux-arm64.AppImage.zsync", names)
        self.assertNotIn("plezy-windows.msixbundle", names)

    def test_verifies_workflow_assets_then_attaches_notes(self) -> None:
        responses = [
            self._release_info(set(deploy.RELEASE_ASSET_NAMES)),
            SimpleNamespace(returncode=0, stdout=""),
        ]
        with mock.patch.object(deploy, "run", side_effect=responses) as run_command:
            deploy.phase_release(self._context())

        edit = run_command.call_args_list[1].args[0]
        self.assertEqual(edit[:4], ["gh", "release", "edit", "2.15.0"])
        self.assertIn(str(self._notes_dir / "github.md"), edit)

    def test_rejects_incomplete_draft_before_editing(self) -> None:
        assets = set(deploy.RELEASE_ASSET_NAMES)
        assets.remove("plezy-macos.dmg")
        assets.add("plezy-windows.msixbundle")
        with mock.patch.object(
            deploy,
            "run",
            return_value=self._release_info(assets),
        ) as run_command:
            with self.assertRaisesRegex(DeployError, "missing: plezy-macos.dmg; unexpected: plezy-windows.msixbundle"):
                deploy.phase_release(self._context())

        run_command.assert_called_once()


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


class InitializeStateTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self._original_root = deploy.ROOT
        self._original_deploy_dir = deploy.DEPLOY_DIR
        self._original_state_path = deploy.STATE_PATH
        deploy.ROOT = Path(self._tmp.name)
        deploy.DEPLOY_DIR = deploy.ROOT / "build" / "deploy"
        deploy.STATE_PATH = deploy.DEPLOY_DIR / "state.json"
        (deploy.ROOT / "version.xcconfig").write_text(
            "MARKETING_VERSION = 2.14.0\nCURRENT_PROJECT_VERSION = 130\n", encoding="utf-8"
        )

    def tearDown(self) -> None:
        deploy.ROOT = self._original_root
        deploy.DEPLOY_DIR = self._original_deploy_dir
        deploy.STATE_PATH = self._original_state_path
        self._tmp.cleanup()

    @staticmethod
    def _args(*, dry_run: bool, fresh: bool = True, version: str = "2.15.0") -> SimpleNamespace:
        return SimpleNamespace(
            version=version,
            build_number=None,
            fresh=fresh,
            dry_run=dry_run,
        )

    def _write_previous_release(self) -> Path:
        State(version="2.14.0", build_number=130, done=["publish"]).save()
        note = deploy.DEPLOY_DIR / "notes" / "play.txt"
        note.parent.mkdir(parents=True)
        note.write_text("old store notes\n", encoding="utf-8")
        return note

    def test_fresh_release_removes_state_and_generated_outputs(self) -> None:
        old_note = self._write_previous_release()

        state = deploy.initialize_state(self._args(dry_run=False))

        self.assertEqual((state.version, state.build_number), ("2.15.0", 131))
        self.assertFalse(old_note.exists())
        self.assertEqual(State.load(), state)

    def test_dry_run_fresh_release_preserves_existing_outputs(self) -> None:
        old_note = self._write_previous_release()

        state = deploy.initialize_state(self._args(dry_run=True))

        self.assertEqual((state.version, state.build_number), ("2.15.0", 131))
        self.assertEqual(old_note.read_text(encoding="utf-8"), "old store notes\n")
        self.assertEqual(State.load().version, "2.14.0")

    def test_resume_keeps_the_recorded_release_and_refuses_another_version(self) -> None:
        State(version="2.15.0", build_number=131, done=["changelog"]).save()
        state = deploy.initialize_state(self._args(dry_run=False, fresh=False))
        self.assertEqual(state.done, ["changelog"])
        with self.assertRaises(DeployError):
            deploy.initialize_state(self._args(dry_run=False, fresh=False, version="2.16.0"))


class DeferredPhaseTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self._original_state_path = deploy.STATE_PATH
        deploy.STATE_PATH = Path(self._tmp.name) / "state.json"

    def tearDown(self) -> None:
        deploy.STATE_PATH = self._original_state_path
        self._tmp.cleanup()

    @staticmethod
    def _context(state: State, **args) -> deploy.Context:
        defaults = {
            "dry_run": False,
            "yes": False,
            "amazon_skip_commit": False,
        }
        defaults.update(args)
        return deploy.Context(
            args=SimpleNamespace(**defaults),
            env={
                "AMAZON_APPSTORE_PACKAGE_NAME": "com.example.app",
                "AMAZON_APPSTORE_APP_ID": "amzn1.devportal.mobileapp.fixture",
            },
            state=state,
            phases=["amazon", "publish"],
        )

    def test_deferred_phase_remains_pending_in_release_state(self) -> None:
        state = State(version="2.15.0", build_number=131)
        args = SimpleNamespace(
            only=["publish"],
            skip=None,
            notes="cl.txt",
            dry_run=False,
        )

        def defer(_ctx) -> None:
            raise deploy.PhaseDeferred

        with (
            mock.patch.object(deploy, "load_env_file", return_value={}),
            mock.patch.object(deploy, "initialize_state", return_value=state),
            mock.patch.object(deploy, "resolve_phases", return_value=["publish"]),
            mock.patch.dict(deploy.PHASE_FUNCTIONS, {"publish": defer}, clear=True),
            mock.patch.object(deploy, "print_summary"),
        ):
            self.assertEqual(deploy.cmd_release(args), 0)

        self.assertNotIn("publish", State.load().done)

    def test_publish_decline_defers_phase(self) -> None:
        ctx = self._context(State(version="2.15.0", build_number=131))

        with mock.patch.object(deploy.Context, "confirm", return_value=False):
            with self.assertRaises(deploy.PhaseDeferred):
                deploy.phase_publish(ctx)

    def test_publish_does_not_commit_or_push_package_metadata(self) -> None:
        ctx = self._context(State(version="2.15.0", build_number=131))

        with (
            mock.patch.object(deploy.Context, "confirm", return_value=True),
            mock.patch.object(deploy, "run") as run_command,
        ):
            deploy.phase_publish(ctx)

        run_command.assert_called_once_with(
            ["gh", "release", "edit", "2.15.0", "--draft=false"]
        )

    def test_amazon_resume_commits_existing_edit_without_replacing_apk(self) -> None:
        state = State(version="2.15.0", build_number=131)
        state.data["amazon_pending_edit_id"] = "edit-42"
        ctx = self._context(state)
        client = mock.Mock()
        client.etag.return_value = "etag-42"

        with (
            mock.patch.object(deploy, "_amazon_token", return_value="token"),
            mock.patch.object(deploy, "AmazonClient", return_value=client),
            mock.patch.object(deploy.Context, "confirm", return_value=True),
            mock.patch.object(deploy, "run") as run_command,
        ):
            deploy.phase_amazon(ctx)

        run_command.assert_not_called()
        client.request.assert_called_once_with(
            "POST",
            "/edits/edit-42/commit",
            headers={"If-Match": "etag-42"},
        )
        self.assertNotIn("amazon_pending_edit_id", state.data)

    def test_amazon_resume_decline_keeps_edit_pending(self) -> None:
        state = State(version="2.15.0", build_number=131)
        state.data["amazon_pending_edit_id"] = "edit-42"
        ctx = self._context(state)
        client = mock.Mock()

        with (
            mock.patch.object(deploy, "_amazon_token", return_value="token"),
            mock.patch.object(deploy, "AmazonClient", return_value=client),
            mock.patch.object(deploy.Context, "confirm", return_value=False),
            mock.patch.object(deploy, "run") as run_command,
        ):
            with self.assertRaises(deploy.PhaseDeferred):
                deploy.phase_amazon(ctx)

        run_command.assert_not_called()
        client.request.assert_not_called()
        self.assertEqual(state.data["amazon_pending_edit_id"], "edit-42")


class SplitPhaseListsTest(unittest.TestCase):
    def test_splits_commas_and_repeats(self) -> None:
        self.assertEqual(
            deploy._split_phase_lists(["play,amazon", "ios"]),
            ["play", "amazon", "ios"],
        )

    def test_none_passthrough(self) -> None:
        self.assertIsNone(deploy._split_phase_lists(None))
        self.assertIsNone(deploy._split_phase_lists([]))


class ResolveMsstorePricingTest(unittest.TestCase):
    def test_keeps_a_usable_tier_and_drops_the_read_only_advanced_flag(self) -> None:
        submission = {
            "pricing": {
                "trialPeriod": "SevenDays",
                "marketSpecificPricings": {"LB": "NotAvailable"},
                "sales": [],
                "priceId": "Tier1013",
                "isAdvancedPricingModel": True,
            }
        }
        self.assertEqual(resolve_msstore_pricing(submission, None), "Tier1013")
        self.assertEqual(
            submission["pricing"],
            {
                "trialPeriod": "SevenDays",
                "marketSpecificPricings": {"LB": "NotAvailable"},
                "sales": [],
                "priceId": "Tier1013",
            },
        )

    def test_refuses_the_base_tier_the_api_cannot_accept(self) -> None:
        submission = {"pricing": {"priceId": "Base", "isAdvancedPricingModel": True}}
        with self.assertRaises(DeployError) as caught:
            resolve_msstore_pricing(submission, None)
        self.assertIn("MSSTORE_PRICE_ID", str(caught.exception))

    def test_configured_tier_replaces_the_base_tier(self) -> None:
        submission = {"pricing": {"priceId": "Base", "isAdvancedPricingModel": True}}
        self.assertEqual(resolve_msstore_pricing(submission, "Tier1013"), "Tier1013")
        self.assertEqual(submission["pricing"], {"priceId": "Tier1013"})

    def test_missing_pricing_never_submits_a_priceless_submission(self) -> None:
        submission: dict = {}
        with self.assertRaises(DeployError):
            resolve_msstore_pricing(submission, None)


if __name__ == "__main__":
    unittest.main()
