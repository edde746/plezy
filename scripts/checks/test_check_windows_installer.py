#!/usr/bin/env python3
"""Behavior tests for the Windows installer elevation guard."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "scripts/checks/check_windows_installer.py"
SCRIPT = ROOT / "windows/build-installer.ps1"


class WindowsInstallerGuardTest(unittest.TestCase):
    def _run(self, script: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory(prefix="plezy-windows-installer-test-") as directory:
            fixture = Path(directory) / "build-installer.ps1"
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
        self.assertIn("elevation checks passed", result.stdout)

    def test_missing_commandline_override_is_rejected(self) -> None:
        # Without the override /ALLUSERS is silently ignored and the relaunched
        # instance installs per-user again, which is issue #1705.
        script = self._mutate(
            "PrivilegesRequiredOverridesAllowed=commandline",
            "PrivilegesRequiredOverridesAllowed=",
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("/ALLUSERS is inert", result.stderr)

    def test_dialog_override_is_rejected(self) -> None:
        script = self._mutate(
            "PrivilegesRequiredOverridesAllowed=commandline",
            "PrivilegesRequiredOverridesAllowed=commandline dialog",
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("winget installs that way", result.stderr)

    def test_admin_default_is_rejected(self) -> None:
        script = self._mutate("PrivilegesRequired=lowest", "PrivilegesRequired=admin")

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must stay per-user", result.stderr)

    def test_dropping_the_elevated_relaunch_is_rejected(self) -> None:
        script = self._mutate(
            "  if ShellExec('runas', ExpandConstant('{srcexe}'), Params, '', SW_SHOW, ewNoWait, ErrorCode) then",
            "  if False then",
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("relaunch this installer elevated", result.stderr)

    def test_dropping_the_recursion_guard_is_rejected(self) -> None:
        script = self._mutate("/ELEVATED=1 /DIR=", "/DIR=")

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("/ELEVATED=1", result.stderr)

    def test_silent_elevation_failure_is_rejected(self) -> None:
        script = self._mutate(
            "  SuppressibleMsgBox(FmtMessage(CustomMessage('ElevationRequired'), [PreviousDir]),\n"
            "    mbCriticalError, MB_OK, IDOK);\n",
            "",
        )

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("explain itself", result.stderr)

    def test_second_template_copy_is_rejected(self) -> None:
        # The regression this guard exists for: the script used to hold one
        # whole .iss per architecture shape, and they drifted.
        script = self._script()
        marker = "[Setup]\n"
        self.assertIn(marker, script)
        script = script.replace(marker, marker + "[Setup]\n", 1)

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("a second copy of the template will drift", result.stderr)

    def test_losing_the_winget_marker_is_rejected(self) -> None:
        script = self._mutate("{param:WINGET|0}", "{param:NOTWINGET|0}")

        result = self._run(script)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("winget marker file", result.stderr)


if __name__ == "__main__":
    unittest.main()
