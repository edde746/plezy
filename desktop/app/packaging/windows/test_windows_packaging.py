#!/usr/bin/env python3
"""The contracts of the Windows packages, read from the scripts that generate them.

build-installer.ps1 and build-msix.ps1 write the Inno Setup script and the AppxManifest.xml at package time, so neither
is in the tree to review. These tests fill each script's template the way PowerShell does and check the result: the
installed app's identity (the earlier releases' AppId, the Store's reserved identity), the silent in-app update, the
per-user install that still reaches a machine-wide one, the upgrade over the earlier releases, the plezy:// link
registration and the Store's packaging rules. They read the scripts as text and never run PowerShell, so they run on
any CI host:

    python3 -m unittest discover -s desktop/app/packaging/windows
"""

from __future__ import annotations

import hashlib
from pathlib import Path
import re
import unittest
from xml.etree import ElementTree

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
INSTALLER = HERE / "build-installer.ps1"
MSIX = HERE / "build-msix.ps1"
APP_IMAGE = HERE / "app-image.ps1"
ASSETS = HERE / "assets"
GRADLE = ROOT / "desktop/app/build.gradle.kts"

APP_GUID = "4213385e-f7be-4f2b-95f9-54082a28bb8f"
# What the earlier releases (up to 2.25.0) installed beside plezy.exe, besides data\: the upgrade removes
# every one, so nothing of theirs lingers in the install directory.
EARLIER_RELEASE_FILES = (
    "auto_updater_windows_plugin.dll",
    "concrt140.dll",
    "connectivity_plus_plugin.dll",
    "dartjni.dll",
    "flutter_windows.dll",
    "libmpv-2.dll",
    "msvcp140.dll",
    "msvcp140_1.dll",
    "msvcp140_2.dll",
    "msvcp140_atomic_wait.dll",
    "msvcp140_codecvt_ids.dll",
    "os_media_controls_plugin.dll",
    "screen_retriever_windows_plugin.dll",
    "sentry.dll",
    "sqlite3.dll",
    "universal_gamepad_plugin.dll",
    "url_launcher_windows_plugin.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll",
    "vulkan-1.dll",
    "VulkanRT-License.txt",
    "window_manager_plugin.dll",
    "WinSparkle.dll",
)

# Partner Center reserves these identity values and derives the package family name from them.
IDENTITY_NAME = "edde746.Plezy"
PUBLISHER = "CN=AA9C53CB-AD3C-48DA-B3E3-D1E8986D4E25"
PUBLISHER_DISPLAY_NAME = "edde746"
PACKAGE_FAMILY_SUFFIX = "13q3sv6jzathm"
FOUNDATION = "http://schemas.microsoft.com/appx/manifest/foundation/windows10"
UAP = "http://schemas.microsoft.com/appx/manifest/uap/windows10"
UAP3 = "http://schemas.microsoft.com/appx/manifest/uap/windows10/3"
SCHEMA_ORDER = (
    "Identity",
    "PhoneIdentity",
    "PublisherInfo",
    "Properties",
    "Resources",
    "Dependencies",
    "Capabilities",
    "Applications",
    "Extensions",
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8").replace("\r\n", "\n")


def here_string(text: str, function: str) -> tuple[str, str]:
    """The declarations of [function] above its returned here-string, and the here-string."""
    match = re.search(rf'(?ms)^function {function} \{{\n(.*?)^    return @"\n(.*?)\n"@\n', text)
    if match is None:
        raise AssertionError(f"{function} must return a single here-string template")
    return match.group(1), match.group(2)


def substitute(template: str, values: dict[str, str]) -> str:
    """The template with PowerShell's $name and $($name) interpolations filled; longest name first."""
    for name in sorted(values, key=len, reverse=True):
        template = template.replace(f"$(${name})", values[name]).replace(f"${name}", values[name])
    unresolved = sorted(set(re.findall(r"\$\(?\$?[\w']+", template)))
    if unresolved:
        raise AssertionError(f"unresolved interpolations: {', '.join(unresolved)}")
    return template


def exe_name() -> str:
    """The launcher createReleaseDistributable makes: <packageName>.exe."""
    match = re.search(r'(?m)^\s*packageName = "([^"]+)"$', read(GRADLE))
    if match is None:
        raise AssertionError("desktop/app/build.gradle.kts must set nativeDistributions.packageName")
    return f"{match.group(1)}.exe"


class InnoScript:
    """The setup.iss New-InnoSetupScript writes for both architectures: its #defines and sections."""

    def __init__(self, text: str) -> None:
        prelude, template = here_string(text, "New-InnoSetupScript")
        values = dict(re.findall(r"(?m)^    \$(\w+) = '([^']*)'$", prelude))
        dual = re.search(r'(?ms)^    if \(\$AppDirs\.Count -eq 2\) \{\n(.*?)^    \}', prelude)
        if dual is None:
            raise AssertionError("New-InnoSetupScript must build a dual-architecture branch")
        values.update(re.findall(r"(?m)^        \$(\w+) = '([^']*)'$", dual.group(1)))
        files = re.search(r'(?ms)^        \$FilesSection = @"\n(.*?)\n"@$', dual.group(1))
        if files is None:
            raise AssertionError("the dual-architecture branch must build $FilesSection")
        values["FilesSection"] = substitute(
            files.group(1), {"AppDirs['x64']": r"C:\img\x64", "AppDirs['arm64']": r"C:\img\arm64"}
        )
        values["Version"] = "2.26.0"
        self.text = substitute(template, values)
        self.defines = dict(re.findall(r'(?m)^#define (\w+) "([^"]*)"$', self.text))
        self.sections: dict[str, list[str]] = {}
        current = None
        for line in self.text.split("\n"):
            header = re.fullmatch(r"\[(\w+)\]", line)
            if header:
                current = header.group(1)
                if current in self.sections:
                    raise AssertionError(f"[{current}] appears twice")
                self.sections[current] = []
            elif current is not None and line and not line.startswith(";"):
                self.sections[current].append(line)

    def setup(self) -> dict[str, str]:
        return dict(line.split("=", 1) for line in self.sections["Setup"])

    def entries(self, section: str) -> list[dict[str, str]]:
        """Each line of an entry section as its parameters, `Name: "value"; Flags: a b`, quotes undone ("" is ")."""
        entries = []
        for line in self.sections[section]:
            params = re.findall(r'(\w+):\s*("(?:[^"]|"")*"|[^;]*)(?:;\s*|$)', line)
            entries.append({
                key: value[1:-1].replace('""', '"') if value.startswith('"') else value.strip()
                for key, value in params
            })
        return entries

    def expand(self, value: str) -> str:
        """[value] with the #defines expanded, as ISPP does."""
        return re.sub(r"\{#(\w+)\}", lambda m: self.defines[m.group(1)], value)


class InstallerTest(unittest.TestCase):
    text = read(INSTALLER)
    iss = InnoScript(text)
    code = "\n".join(iss.sections["Code"])

    def test_one_template_and_one_guid(self) -> None:
        # One template for every architecture shape, which can't drift apart; AppId and the uninstall key share one GUID.
        for once in (r"^\[Setup\]$", r"^\[Code\]$", r"^PrivilegesRequired=", r"^function InitializeSetup"):
            self.assertEqual(len(re.findall(once, self.text, re.MULTILINE)), 1, once)
        self.assertEqual(self.text.count(APP_GUID), 1)
        self.assertEqual(self.iss.setup()["AppId"], "{{" + APP_GUID + "}")
        self.assertIn(rf"Uninstall\{{{APP_GUID}}}_is1", self.code)

    def test_identity_and_install_location_are_the_earlier_releases(self) -> None:
        setup = self.iss.setup()
        self.assertEqual(self.iss.expand(setup["AppName"]), "Plezy")
        self.assertEqual(self.iss.expand(setup["AppPublisher"]), "edde746")
        self.assertEqual(self.iss.expand(setup["AppVersion"]), "2.26.0")
        self.assertEqual(self.iss.expand(setup["VersionInfoVersion"]), "2.26.0")
        self.assertEqual(self.iss.expand(setup["DefaultDirName"]), r"{autopf}\Plezy")
        self.assertEqual(self.iss.expand(setup["DefaultGroupName"]), "Plezy")
        # The release asset name the appcast, WinGet and the website use.
        self.assertEqual(setup["OutputBaseFilename"], "plezy-windows-installer")
        self.assertEqual(setup["Compression"], "lzma")
        self.assertEqual(setup["SolidCompression"], "yes")
        self.assertEqual(setup["WizardStyle"], "modern")
        self.assertEqual(self.iss.defines["ExeName"], exe_name())

    def test_architectures_select_their_image(self) -> None:
        setup = self.iss.setup()
        self.assertEqual(setup["ArchitecturesAllowed"], "x64compatible arm64")
        self.assertEqual(setup["ArchitecturesInstallIn64BitMode"], "x64compatible arm64")
        files = self.iss.entries("Files")
        self.assertEqual([(f["Source"], f["Check"]) for f in files], [(r"C:\img\x64\*", "IsX64"), (r"C:\img\arm64\*", "IsArm64")])
        for entry in files:
            self.assertEqual(entry["DestDir"], "{app}")
            self.assertTrue({"recursesubdirs", "createallsubdirs", "ignoreversion"} <= set(entry["Flags"].split()))
        self.assertRegex(self.code, r"function IsX64: Boolean;\nbegin\n  Result := not IsArm64;")
        # The single-architecture branches pick their own architecture.
        self.assertIn("$ArchAllowed = 'x64compatible'", self.text)
        self.assertIn("$ArchAllowed = 'arm64'", self.text)

    def test_installs_per_user_unless_told_otherwise(self) -> None:
        setup = self.iss.setup()
        self.assertEqual(setup["PrivilegesRequired"], "lowest")
        # commandline, or /ALLUSERS is inert; never dialog, which makes a silent install prompt (WinGet installs so).
        self.assertEqual(setup["PrivilegesRequiredOverridesAllowed"], "commandline")

    def test_unwritable_install_relaunches_elevated(self) -> None:
        self.assertIn("IsAdminInstallMode or (ExpandConstant('{param:ELEVATED|0}') = '1')", self.code)
        self.assertIn("WriteProbeName = 'plezy-write-probe.tmp'", self.code)
        self.assertIn("SaveStringToFile(Probe", self.code)
        self.assertIn("RegQueryStringValue(HKCU, UninstallSubkey, 'Inno Setup: App Path', Dir)", self.code)
        self.assertIn("RegQueryStringValue(HKLM, UninstallSubkey, 'Inno Setup: App Path', Dir)", self.code)
        self.assertIn("Params := ForwardedParams + '/ALLUSERS /ELEVATED=1 /DIR=' +", self.code)
        self.assertIn("ShellExec('runas', ExpandConstant('{srcexe}'), Params", self.code)
        # The forwarded command line drops /CURRENTUSER, which would undo /ALLUSERS.
        for dropped in ("'/ALLUSERS'", "'/CURRENTUSER'", "'/DIR='"):
            self.assertIn(dropped, self.code)
        # A refused elevation explains itself (#1705).
        self.assertIn("SuppressibleMsgBox(FmtMessage(CustomMessage('ElevationRequired'), [PreviousDir])", self.code)
        self.assertEqual(
            self.iss.sections["CustomMessages"],
            [
                "ElevationRequired=Plezy is installed in %1, which requires administrator privileges to update.%n%n"
                'Re-run this installer using "Run as administrator", or download the latest installer from '
                "https://github.com/edde746/plezy/releases/latest"
            ],
        )

    def test_admin_install_over_a_per_user_one_removes_its_registration(self) -> None:
        cleanup = self.code[self.code.index("if IsAdminInstallMode then") :]
        self.assertIn("RegDeleteKeyIncludingSubkeys(HKCU, UninstallSubkey);", cleanup)
        self.assertIn("RegDeleteKeyIncludingSubkeys(HKCU, ProtocolSubkey);", cleanup)
        self.assertIn("DelTree(ExpandConstant('{userprograms}') + '\\' + PreviousGroup", cleanup)

    def test_winget_marker_follows_the_parameter(self) -> None:
        # The app reads {app}\.winget to leave updates to WinGet.
        self.assertIn("MarkerPath := ExpandConstant('{app}\\.winget');", self.code)
        self.assertRegex(
            self.code,
            r"if ExpandConstant\('\{param:WINGET\|0\}'\) = '1' then\n\s+SaveStringToFile\(MarkerPath, '', False\)\n"
            r"\s+else\n\s+DeleteFile\(MarkerPath\);",
        )
        self.assertIn({"Type": "files", "Name": r"{app}\.winget"}, self.iss.entries("UninstallDelete"))

    def test_launches_after_install_unless_norun(self) -> None:
        (run,) = self.iss.entries("Run")
        self.assertEqual(self.iss.expand(run["Filename"]), r"{app}\Plezy.exe")
        self.assertEqual(run["Check"], "not IsNoRun")
        # No skipifsilent: the in-app updater's /SILENT /SP- install starts the app again.
        self.assertEqual(run["Flags"].split(), ["nowait", "postinstall"])
        self.assertIn("Result := ExpandConstant('{param:NORUN|0}') = '1';", self.code)

    def test_shortcuts(self) -> None:
        icons = [{k: self.iss.expand(v) for k, v in e.items()} for e in self.iss.entries("Icons")]
        self.assertIn({"Name": r"{group}\Plezy", "Filename": r"{app}\Plezy.exe"}, icons)
        self.assertIn({"Name": r"{group}\{cm:UninstallProgram,Plezy}", "Filename": "{uninstallexe}"}, icons)
        self.assertIn({"Name": r"{autodesktop}\Plezy", "Filename": r"{app}\Plezy.exe", "Tasks": "desktopicon"}, icons)
        (task,) = self.iss.entries("Tasks")
        self.assertEqual((task["Name"], task["Flags"]), ("desktopicon", "unchecked"))

    def test_upgrade_removes_what_the_earlier_releases_and_versions_installed(self) -> None:
        deleted = self.iss.entries("InstallDelete")
        # Only inside the install directory: the earlier releases' data (%APPDATA%) is never touched.
        for entry in deleted:
            self.assertTrue(entry["Name"].startswith("{app}\\"), entry)
        dirs = {e["Name"] for e in deleted if e["Type"] == "filesandordirs"}
        files = {e["Name"] for e in deleted if e["Type"] == "files"}
        self.assertEqual(dirs, {r"{app}\app", r"{app}\runtime", r"{app}\data"})
        self.assertEqual(files, {rf"{{app}}\{name}" for name in EARLIER_RELEASE_FILES})

    def test_registers_plezy_links(self) -> None:
        registry = {(e["Subkey"], e["ValueName"]): e for e in self.iss.entries("Registry")}
        for entry in registry.values():
            # HKA: the user's classes in a per-user install, the machine's in a machine-wide one.
            self.assertEqual(entry["Root"], "HKA")
        self.assertEqual(registry[(r"Software\Classes\plezy", "")]["ValueData"], "URL:Plezy")
        self.assertEqual(registry[(r"Software\Classes\plezy", "")]["Flags"], "uninsdeletekey")
        self.assertEqual(registry[(r"Software\Classes\plezy", "URL Protocol")]["ValueData"], "")
        # Inno's "" is one quote: "{app}\Plezy.exe" "%1", the link as the app's one (last) argument.
        command = registry[(r"Software\Classes\plezy\shell\open\command", "")]["ValueData"]
        self.assertEqual(self.iss.expand(command), r'"{app}\Plezy.exe" "%1"')
        self.assertIn("ProtocolSubkey = 'Software\\Classes\\plezy';", self.code)

    def test_packages_the_sideloaded_images(self) -> None:
        self.assertIn("-Flavor SIDELOADED", self.text)
        for name in ("plezy-windows-$Architecture-portable.7z", "plezy-windows-installer.exe"):
            self.assertIn(name, self.text)
        self.assertIn('@("a", "-mx=9", $Portable, "*")', self.text)


class MsixTest(unittest.TestCase):
    text = read(MSIX)
    prelude, template = here_string(text, "New-AppxManifest")
    values = dict(re.findall(r'(?m)^    \$(\w+) = "([^"]*)"$', prelude))
    values.update({"MsixVersion": "2.26.0.0", "Architecture": "x64"})
    package = ElementTree.fromstring(substitute(template, values))

    def find(self, path: str) -> ElementTree.Element:
        element = self.package.find(path, {"f": FOUNDATION, "uap": UAP, "uap3": UAP3})
        self.assertIsNotNone(element, path)
        return element

    def test_one_template(self) -> None:
        for once in (r'^    return @"$', r"^<Package ", r"^  <Identity ", r"^  <Capabilities>$", r"^  <Applications>$"):
            self.assertEqual(len(re.findall(once, self.text, re.MULTILINE)), 1, once)
        self.assertIn('Version="$MsixVersion"', self.template)
        self.assertIn('ProcessorArchitecture="$Architecture"', self.template)
        self.assertIn('foreach ($Architecture in @("x64", "arm64"))', self.text)

    def test_schema_order(self) -> None:
        present = [child.tag.rpartition("}")[2] for child in self.package]
        self.assertEqual(present, [e for e in SCHEMA_ORDER if e in present])
        self.assertEqual(len(present), len(set(present)))
        for required in ("Identity", "Properties", "Resources", "Dependencies", "Capabilities", "Applications"):
            self.assertIn(required, present)

    def test_identity_is_the_reserved_product(self) -> None:
        identity = self.find("f:Identity")
        self.assertEqual(identity.get("Name"), IDENTITY_NAME)
        self.assertRegex(identity.get("Name"), r"^[-.A-Za-z0-9]{3,50}$")
        self.assertEqual(identity.get("Publisher"), PUBLISHER)
        self.assertEqual(identity.get("Version"), "2.26.0.0")
        self.assertEqual(self.find("f:Properties/f:PublisherDisplayName").text, PUBLISHER_DISPLAY_NAME)
        self.assertEqual(self.find("f:Properties/f:DisplayName").text, "Plezy")
        self.assertEqual([r.get("Language") for r in self.package.iterfind(f"{{{FOUNDATION}}}Resources/*")], ["en-us"])
        # The publisher hashes to the package family name Partner Center reports: SHA-256 of the UTF-16LE publisher,
        # first 8 bytes, as 13 characters of Windows' base32 alphabet.
        digest = hashlib.sha256(PUBLISHER.encode("utf-16-le")).digest()[:8]
        bits = f"{int.from_bytes(digest, 'big'):064b}0"
        alphabet = "0123456789abcdefghjkmnpqrstvwxyz"
        self.assertEqual("".join(alphabet[int(bits[i : i + 5], 2)] for i in range(0, 65, 5)), PACKAGE_FAMILY_SUFFIX)

    def test_device_family_and_capabilities(self) -> None:
        family = self.find("f:Dependencies/f:TargetDeviceFamily")
        self.assertEqual(
            (family.get("Name"), family.get("MinVersion"), family.get("MaxVersionTested")),
            ("Windows.Desktop", "10.0.17763.0", "10.0.26100.0"),
        )
        capabilities = [c.get("Name") for c in self.package.iterfind(f"{{{FOUNDATION}}}Capabilities/*")]
        self.assertEqual(sorted(capabilities), ["internetClient", "privateNetworkClientServer", "runFullTrust"])

    def test_application(self) -> None:
        application = self.find("f:Applications/f:Application")
        self.assertEqual(application.get("Id"), "Plezy")
        self.assertEqual(application.get("Executable"), exe_name())
        self.assertEqual(application.get("EntryPoint"), "Windows.FullTrustApplication")
        visual = self.find("f:Applications/f:Application/uap:VisualElements")
        self.assertEqual(visual.get("DisplayName"), "Plezy")
        self.assertEqual(visual.get("Description"), "A modern client for Plex and Jellyfin")
        self.assertEqual(visual.get("BackgroundColor"), "transparent")
        protocol = self.find("f:Applications/f:Application/f:Extensions/uap3:Extension/uap3:Protocol")
        self.assertEqual((protocol.get("Name"), protocol.get("Parameters")), ("plezy", '"%1"'))

    def test_assets_exist_and_resolve(self) -> None:
        referenced = {
            m.group(1)
            for element in self.package.iter()
            for value in (*element.attrib.values(), element.text or "")
            if (m := re.fullmatch(r"assets\\([A-Za-z0-9._-]+\.png)", value.strip()))
        }
        for required in ("StoreLogo.png", "Square150x150Logo.png", "Square44x44Logo.png", "Wide310x150Logo.png",
                         "Square310x310Logo.png", "SplashScreen.png"):
            self.assertIn(required, referenced)
        for asset in referenced:
            self.assertTrue((ASSETS / asset).is_file(), asset)
        # Unplated variants, resolved through resources.pri, keep the shell from plating the taskbar icon.
        for form in ("altform-unplated", "altform-lightunplated"):
            self.assertTrue(any(ASSETS.glob(f"Square44x44Logo.targetsize-*_{form}.png")), form)
        self.assertIn('"new", "/pr"', self.text)
        self.assertIn("resources.pri", self.text)
        self.assertIn("RemoveChild($Packaging)", self.text)

    def test_unsigned_store_images_through_checked_calls(self) -> None:
        self.assertNotIn("signtool", self.text.lower())
        self.assertIn("-Flavor STORE", self.text)
        self.assertIn("plezy-windows.msixbundle", self.text)
        # Every native tool call goes through the one invocation that checks $LASTEXITCODE.
        helper = read(APP_IMAGE)
        self.assertEqual(len(re.findall(r"(?m)^    & \$Tool @Arguments$", helper)), 1)
        for script in (self.text, read(INSTALLER)):
            self.assertIsNone(re.search(r"(?m)^\s*& \$(?!Tool\b)", script))


if __name__ == "__main__":
    unittest.main()
