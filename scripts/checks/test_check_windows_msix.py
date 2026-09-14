#!/usr/bin/env python3
"""Behavior tests for the Windows MSIX manifest guard."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "scripts/checks/check_windows_msix.py"
SCRIPT = ROOT / "windows/build-msix.ps1"


class WindowsMsixGuardTest(unittest.TestCase):
    def _run(self, script: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory(prefix="plezy-windows-msix-test-") as directory:
            fixture = Path(directory) / "build-msix.ps1"
            fixture.write_text(script, encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(CHECKER), str(fixture)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def _script(self) -> str:
        return SCRIPT.read_text(encoding="utf-8")

    def _mutate(self, old: str, new: str) -> str:
        script = self._script().replace(old, new, 1)
        self.assertNotEqual(script, self._script(), f"fixture mutation no longer matches: {old!r}")
        return script

    def test_current_script_passes(self) -> None:
        result = self._run(self._script())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("msix manifest checks passed", result.stdout)

    def test_second_template_copy_is_rejected(self) -> None:
        # The regression build-installer.ps1 already had: one whole manifest per
        # architecture shape, drifting apart.
        marker = "  <Capabilities>\n"
        script = self._mutate(marker, marker + marker)

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("a second copy of the template will drift", result.stderr)

    def test_schema_element_order_is_rejected_when_tidied(self) -> None:
        # Resources before Dependencies looks wrong next to the old Visual
        # Studio UWP templates, but the foundation schema requires it.
        resources = (
            "  <Resources>\n"
            '    <Resource Language="en-us" />\n'
            "  </Resources>\n"
            "\n"
        )
        dependencies = (
            "  <Dependencies>\n"
            '    <TargetDeviceFamily Name="Windows.Desktop"\n'
            '                        MinVersion="10.0.17763.0"\n'
            '                        MaxVersionTested="10.0.26100.0" />\n'
            "  </Dependencies>\n"
            "\n"
        )
        script = self._mutate(resources + dependencies, dependencies + resources)

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must keep schema order", result.stderr)

    def test_hard_coded_architecture_is_rejected(self) -> None:
        script = self._mutate(
            'ProcessorArchitecture="$Architecture"', 'ProcessorArchitecture="x64"'
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be interpolated", result.stderr)

    def test_underscored_identity_name_is_rejected(self) -> None:
        # makeappx enforces the schema pattern on Identity/@Name before it reads
        # any payload, so an underscore makes the package unbuildable.
        script = self._mutate('$IdentityName = "edde746.Plezy"', '$IdentityName = "edde746_Plezy"')

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("[-.A-Za-z0-9]+ pattern", result.stderr)

    def test_identity_drift_from_partner_center_is_rejected(self) -> None:
        # The reserved identity is what Store validation matches the upload
        # against, and what installed copies are keyed by.
        script = self._mutate(
            '$PublisherDisplayName = "edde746"', '$PublisherDisplayName = "someone else"'
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("reserved in Partner Center", result.stderr)

    def test_three_part_version_is_rejected(self) -> None:
        script = self._mutate('    return "$Semver.0"', '    return "$Semver"')

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Store-reserved revision field", result.stderr)

    def test_unvalidated_version_input_is_rejected(self) -> None:
        script = self._mutate(r"if ($Semver -notmatch '^\d+\.\d+\.\d+$') {", "if ($false) {")

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be rejected instead of packaged", result.stderr)

    def test_dropping_a_capability_is_rejected(self) -> None:
        script = self._mutate('    <rescap:Capability Name="runFullTrust" />\n', "")

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("runFullTrust capability", result.stderr)

    def test_asset_reference_without_a_file_is_rejected(self) -> None:
        script = self._mutate("Square150x150Logo.png", "Square150x150Logo-renamed.png")

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("packaging fails on a missing asset", result.stderr)

    def test_unresolved_interpolation_is_rejected(self) -> None:
        # A new variable in the template has to be declared where the checker
        # can see it, or the manifest it validates is not the one that ships.
        script = self._mutate("<DisplayName>Plezy</DisplayName>", "<DisplayName>$AppName</DisplayName>")

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cannot resolve", result.stderr)

    def test_malformed_manifest_is_rejected(self) -> None:
        script = self._mutate("</Applications>", "</Application>")

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("well-formed XML", result.stderr)

    def test_unchecked_makeappx_invocation_is_rejected(self) -> None:
        script = self._mutate(
            'Write-Host "`nBuild complete!" -ForegroundColor Green',
            '& $MakeAppx bundle /d packages /p extra.msixbundle',
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("checks $LASTEXITCODE", result.stderr)

    def test_dropping_the_resource_index_is_rejected(self) -> None:
        # Without resources.pri the unplated logo variants are inert payload and
        # the shell plates the taskbar icon with the accent colour.
        script = self._mutate('"new", "/pr"', '"version", "/pr"')

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("inert payload", result.stderr)

    def test_keeping_auto_resource_packages_is_rejected(self) -> None:
        script = self._mutate(
            "$PriConfigXml.resources.RemoveChild($Packaging)", "$PriConfigXml.resources.AppendChild($Packaging)"
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("autoResourcePackage must be stripped", result.stderr)

    def test_signing_the_bundle_is_rejected(self) -> None:
        script = self._mutate(
            "# Clean up staging",
            '& signtool sign /fd SHA256 /f release.pfx $Bundle\n\n# Clean up staging',
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must stay unsigned", result.stderr)


if __name__ == "__main__":
    unittest.main()
