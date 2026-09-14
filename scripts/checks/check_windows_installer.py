#!/usr/bin/env python3
"""Guard the elevation contract in the generated Windows Inno Setup script.

The installer is generated at build time by windows/build-installer.ps1, so
there is no .iss in the tree to review. These checks pin the parts a silent
in-app update depends on: a per-user default install that can still reach a
machine-wide copy by relaunching itself elevated (issue #1705).
"""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCRIPT = ROOT / "windows/build-installer.ps1"
if len(sys.argv) > 2:
    raise SystemExit(f"Usage: {Path(sys.argv[0]).name} [build-installer-path]")
SCRIPT = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else DEFAULT_SCRIPT
APP_GUID = "4213385e-f7be-4f2b-95f9-54082a28bb8f"
text = SCRIPT.read_text(encoding="utf-8")
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def template() -> str:
    """The Inno Setup script emitted by New-InnoSetupScript."""
    match = re.search(r'(?ms)^    return @"\r?\n(.*?)\r?\n"@\r?\n', text)
    require(match is not None, "New-InnoSetupScript must return a single here-string template")
    return match.group(1) if match else ""


require(
    "function New-InnoSetupScript" in text,
    "the .iss must be built by New-InnoSetupScript so every architecture shares one template",
)
iss = template()

# A single template prevents architecture copies from drifting.
for once in (
    r"^\[Setup\]$",
    r"^\[Code\]$",
    r"^PrivilegesRequired=",
    r"^function InitializeSetup",
):
    require(
        len(re.findall(once, text, re.MULTILINE)) == 1,
        f"{once} must match exactly one line; a second copy of the template will drift",
    )
require(
    text.count(APP_GUID) == 1,
    "the AppId GUID must have a single source; AppId and the uninstall subkey both derive from it",
)

require("AppId={{$AppGuid}" in iss, "AppId must be built from the shared $AppGuid")
require(
    r"Uninstall\{$AppGuid}_is1" in iss,
    "the uninstall subkey must be the shared AppId with Inno's _is1 suffix",
)
require(
    "OutputBaseFilename=plezy-windows-installer" in iss,
    "the release asset name is referenced by the appcast, winget and the website",
)
require(
    "ArchitecturesAllowed=$ArchAllowed" in iss
    and "ArchitecturesInstallIn64BitMode=$ArchAllowed" in iss,
    "architectures must come from the template parameter, not be hard-coded",
)
require(
    "Check: IsX64" in text and "Check: IsArm64" in text,
    "the dual-architecture [Files] entries must keep their architecture checks",
)

# Fresh installs stay per-user; only /ALLUSERS may trigger elevation.
require(
    re.search(r"(?m)^PrivilegesRequired=lowest\s*$", iss) is not None,
    "a fresh install must stay per-user; PrivilegesRequired=lowest",
)
overrides = re.search(r"(?m)^PrivilegesRequiredOverridesAllowed=(.+)$", iss)
require(
    overrides is not None and "commandline" in overrides.group(1),
    "PrivilegesRequiredOverridesAllowed must allow commandline or /ALLUSERS is inert",
)
require(
    overrides is None or "dialog" not in overrides.group(1),
    "allowing dialog makes a silent install with no previous copy prompt; winget installs that way",
)

# Verify the elevation path.
require(
    "IsAdminInstallMode" in iss,
    "the elevation path must be skipped once Setup already runs in administrative install mode",
)
require(
    "{param:ELEVATED|0}" in iss,
    "the relaunched instance needs a guard parameter so it cannot elevate again",
)
require(
    "SaveStringToFile(Probe" in iss,
    "elevation must be driven by probing the install directory for write access",
)
require(
    "ShellExec('runas'" in iss and "{srcexe}" in iss,
    "a non-writable install directory must relaunch this installer elevated",
)
for parameter in ("/ALLUSERS", "/ELEVATED=1", "/DIR="):
    require(
        parameter in iss,
        f"the elevated relaunch must pass {parameter}",
    )
require(
    "'/CURRENTUSER'" in iss,
    "the forwarded command line must drop /CURRENTUSER, which would undo /ALLUSERS",
)
require(
    "CustomMessage('ElevationRequired')" in iss
    and re.search(r"(?m)^ElevationRequired=\S", iss) is not None,
    "a refused elevation must explain itself instead of failing silently",
)

# Preserve behavior required by release tooling.
require(
    "{param:WINGET|0}" in iss and "{app}\\.winget" in iss,
    "the winget marker file gates UpdateService.useNativeUpdater",
)
require(
    "{param:NORUN|0}" in iss and "Check: not IsNoRun" in iss,
    "the winget manifest passes /NORUN=1 and expects the launch entry to honor it",
)

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print("windows installer elevation checks passed")
