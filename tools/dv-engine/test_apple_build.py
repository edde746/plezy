import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from build_adapters import build_apple_devices


class AppleDeviceBuildTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.host = self.work / "host"
        self.host.mkdir()
        self.pins = [{"identity": "fixture", "location": "https://example.org/fixture",
                      "state": {"revision": "locked"}}]
        (self.host / "Package.resolved").write_text(json.dumps({"pins": self.pins}))

    @patch("build_adapters.shutil.which", return_value="xcodegen")
    @patch("build_adapters.run")
    def test_both_device_sdks_are_unsigned_and_resolution_locked(self, run, which):
        results = {}
        build_apple_devices(self.host, self.work, ["ios", "tvos"], self.pins, results, {"fixture"})
        self.assertEqual(set(results), {"ios", "tvos"})
        commands = [call.args[0] for call in run.call_args_list if call.args[0][0] == "xcodebuild"]
        self.assertEqual(len(commands), 2)
        self.assertIn("generic/platform=iOS", commands[0])
        self.assertIn("generic/platform=tvOS", commands[1])
        for command in commands:
            self.assertIn("CODE_SIGNING_ALLOWED=NO", command)
            self.assertIn("-onlyUsePackageVersionsFromResolvedFile", command)
            self.assertNotIn("-allowProvisioningUpdates", command)

    @patch("build_adapters.shutil.which", return_value=None)
    def test_missing_generator_is_failure(self, which):
        with self.assertRaisesRegex(ValueError, "XcodeGen"):
            build_apple_devices(self.host, self.work, ["ios"], self.pins, {}, {"fixture"})

    @patch("build_adapters.shutil.which", return_value="xcodegen")
    def test_failed_second_sdk_preserves_first_result(self, which):
        def run(command, **kwargs):
            if "generic/platform=tvOS" in command:
                raise subprocess.CalledProcessError(65, command)
        results = {}
        with patch("build_adapters.run", side_effect=run), self.assertRaises(subprocess.CalledProcessError):
            build_apple_devices(self.host, self.work, ["ios", "tvos"], self.pins, results, {"fixture"})
        self.assertEqual(set(results), {"ios"})

    @patch("build_adapters.shutil.which", return_value="xcodegen")
    def test_resolver_drift_does_not_record_success(self, which):
        def run(command, **kwargs):
            if command[0] == "xcodebuild":
                resolved = self.host / "PlezyNGDVExperiment.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
                resolved.write_text('{"pins": []}')
        results = {}
        with patch("build_adapters.run", side_effect=run), self.assertRaisesRegex(ValueError, "drifted"):
            build_apple_devices(self.host, self.work, ["ios"], self.pins, results, {"fixture"})
        self.assertEqual(results, {})


if __name__ == "__main__":
    unittest.main()
