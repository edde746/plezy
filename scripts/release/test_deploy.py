import json
import os
import plistlib
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import deploy
from deploy import (
    DeployError,
    State,
    bump_pubspec_text,
    parse_env_text,
    resolve_phases,
    sanitize_msstore_pricing,
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


class AppleUploadTest(unittest.TestCase):
    @staticmethod
    def _context() -> deploy.Context:
        return deploy.Context(
            args=SimpleNamespace(dry_run=False, yes=True),
            env={
                "APPLE_TEAM_ID": "G88U5B5783",
                "ASC_KEY_ID": "KEY1234567",
                "ASC_ISSUER_ID": "issuer",
            },
            state=State(version="2.15.0", build_number=131),
            phases=["ios", "tvos"],
        )

    def test_export_uses_local_xcode_account_and_returns_ipa(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            deploy_dir = Path(tmp) / "deploy"
            archive = Path(tmp) / "Runner.xcarchive"
            archive.mkdir()
            ipa = deploy_dir / "export-tvos/Plezy.ipa"
            with (
                mock.patch.object(deploy, "DEPLOY_DIR", deploy_dir),
                mock.patch.object(deploy, "run") as run_command,
                mock.patch.object(deploy, "_find_single_ipa", return_value=ipa),
            ):
                result = deploy._export_archive(self._context(), archive, "tvos")

            options = plistlib.loads((deploy_dir / "export-options-tvos.plist").read_bytes())

        self.assertEqual(result, ipa)
        self.assertEqual(options["destination"], "export")
        self.assertEqual(options["teamID"], "G88U5B5783")
        command = run_command.call_args.args[0]
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
                "xcrun",
                "altool",
                "--upload-app",
                "--type",
                "tvos",
                "-f",
                str(ipa),
                "--apiKey",
                "KEY1234567",
                "--apiIssuer",
                "issuer",
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
        with mock.patch.object(
            deploy,
            "run",
            return_value=self._release_info(assets),
        ) as run_command:
            with self.assertRaisesRegex(DeployError, "plezy-macos.dmg"):
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
        (deploy.ROOT / "pubspec.yaml").write_text("version: 2.14.0+130\n", encoding="utf-8")

    def tearDown(self) -> None:
        deploy.ROOT = self._original_root
        deploy.DEPLOY_DIR = self._original_deploy_dir
        deploy.STATE_PATH = self._original_state_path
        self._tmp.cleanup()

    @staticmethod
    def _args(*, dry_run: bool) -> SimpleNamespace:
        return SimpleNamespace(
            version="2.15.0",
            build_number=None,
            fresh=True,
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
            env={"AMAZON_APPSTORE_PACKAGE_NAME": "com.example.app"},
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
