import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location("prepare_android_sdk", Path(__file__).with_name("prepare_android_sdk.py"))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class AndroidSdkTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="plezy-android-sdk-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "android/steam").mkdir(parents=True)
        (self.root / "android/.gradle").mkdir()
        (self.root / "android/build.gradle.kts").write_text(
            'compileSdk = 37\nbuildToolsVersion = "37.0.0"\nndkVersion = "29.0.14206865"\n'
            'cmake { version = "4.1.2" }\n'
        )
        (self.root / "android/steam/build.gradle").write_text(
            "compileSdk 36\nexternalNativeBuild { cmake { version '3.22.1' } }\n"
        )
        self.env = {"HTTPS_PROXY": "http://10.0.2.100:3128"}

    def test_each_modules_tools_are_collected_including_older_cmake(self):
        packages = MODULE.required_packages(self.root)
        self.assertEqual(packages, ["build-tools;37.0.0", "cmake;3.22.1", "cmake;4.1.2",
                                    "ndk;29.0.14206865", "platform-tools",
                                    "platforms;android-36", "platforms;android-37"])
        (self.root / "android/steam/build.gradle").write_text("cmake { version '4.2.0' }\n")
        updated = MODULE.required_packages(self.root)
        self.assertIn("cmake;4.2.0", updated)
        self.assertNotIn("cmake;3.22.1", updated)

    def test_real_source_includes_steam_and_libass_toolchains(self):
        packages = MODULE.required_packages(MODULE.ROOT)
        for expected in ("cmake;3.22.1", "cmake;4.1.2", "platforms;android-36", "platforms;android-37"):
            self.assertIn(expected, packages)

    def test_sdk_java_and_gradle_both_receive_proxy_before_downloads(self):
        output = self.root / "github-env"
        MODULE.configure_proxy(self.env | {"GITHUB_ENV": str(output), "JAVA_TOOL_OPTIONS": "-Xmx2g"})
        entries = dict(line.split("=", 1) for line in output.read_text().splitlines())
        self.assertEqual(set(entries), {"JAVA_TOOL_OPTIONS", "GRADLE_OPTS"})
        for value in entries.values():
            self.assertIn("-Dhttps.proxyHost=10.0.2.100", value)
            self.assertIn("-Dhttp.proxyPort=3128", value)
        self.assertTrue(entries["JAVA_TOOL_OPTIONS"].startswith("-Xmx2g "))

    def test_invalid_proxy_or_multiline_environment_is_rejected(self):
        for proxy in ("", "https://host:3128", "http://user:secret@host:3128",
                      "http://host:3128?query=secret", "http://host:3128\nINJECTED=true"):
            with self.subTest(proxy=proxy), self.assertRaises(ValueError):
                MODULE.proxy_parts({"HTTPS_PROXY": proxy})
        with self.assertRaises(ValueError):
            MODULE.configure_proxy(self.env | {"GITHUB_ENV": str(self.root / "env"),
                                               "GRADLE_OPTS": "-Xmx2g\nINJECTED=true"})
        self.assertFalse((self.root / "env").exists())

    def test_partial_sdk_install_does_not_pass(self):
        sdk = self.root / "sdk"
        for name in ("cmake", "ninja"):
            path = sdk / "cmake/4.1.2/bin" / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("#!/bin/sh\nexit 0\n")
            path.chmod(0o755)
        MODULE.verify_packages(sdk, ["cmake;4.1.2"])
        with self.assertRaisesRegex(ValueError, "cmake;3.22.1"):
            MODULE.verify_packages(sdk, ["cmake;4.1.2", "cmake;3.22.1"])

    def test_installer_passes_exact_packages_and_proxy_to_sdkmanager(self):
        sdk = self.root / "sdk"
        manager = sdk / "cmdline-tools/latest/bin/sdkmanager"
        manager.parent.mkdir(parents=True)
        manager.touch()
        with patch.object(MODULE.subprocess, "run") as run, patch.object(MODULE, "verify_packages") as verify:
            MODULE.install(self.root, self.env | {"ANDROID_HOME": str(sdk)})
        self.assertEqual(run.call_count, 2)
        arguments = run.call_args_list[1].args[0]
        self.assertIn("--proxy_host=10.0.2.100", arguments)
        self.assertIn("--proxy_port=3128", arguments)
        self.assertEqual(arguments[arguments.index("--install") + 1:], MODULE.required_packages(self.root))
        verify.assert_called_once_with(sdk, MODULE.required_packages(self.root))

    def test_ci_release_and_games_use_shared_setup_in_order(self):
        for filename in ("ci.yml", "build.yml", "games-native.yml"):
            source = (MODULE.ROOT / ".github/workflows" / filename).read_text()
            with self.subTest(workflow=filename):
                proxy = source.index("python3 scripts/prepare_android_sdk.py proxy")
                setup = source.index("uses: android-actions/setup-android@", proxy)
                install = source.index("python3 scripts/prepare_android_sdk.py install", setup)
                self.assertLess(proxy, setup)
                self.assertLess(setup, install)


if __name__ == "__main__":
    unittest.main()
