#!/usr/bin/env python3
"""Guard the generated MSIX manifest behind Microsoft Store submissions.

windows/build-msix.ps1 generates AppxManifest.xml per architecture at package
time, so there is no manifest in the tree to review. These checks read the
script as text and validate the template it returns - they never invoke
PowerShell, because root CI runs on Linux where pwsh cannot be assumed, and
-EmitManifestOnly is the Windows-side developer loop instead.

The invariants pinned here are the ones makeappx, the shell and Store
certification enforce: the schema's fixed child order, identity strings that
satisfy their pattern constraints and match the reserved product, a four-part
version whose revision field is the 0 the Store reserves, one template shared by
both architectures, assets that actually exist in the tree, and the resource
index without which the unplated taskbar icons never resolve.
"""

import hashlib
from pathlib import Path
import re
import sys
from xml.etree import ElementTree

from pubspec_version import parse_pubspec_version
from workflow_yaml import job_block


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SCRIPT = ROOT / "windows/build-msix.ps1"
if len(sys.argv) > 2:
    raise SystemExit(f"Usage: {Path(sys.argv[0]).name} [build-msix-path]")
SCRIPT = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else DEFAULT_SCRIPT
ASSETS = ROOT / "windows/msix/assets"
CMAKE = ROOT / "windows/CMakeLists.txt"
PUBSPEC = ROOT / "pubspec.yaml"
WORKFLOW = ROOT / ".github/workflows/build.yml"
MSIX_STEP = "Build Store package (MSIX)"
BUNDLE = "plezy-windows.msixbundle"
# The identity reserved in Partner Center. All three are pinned here because a
# character of drift in any of them fails Store validation, and the first two
# derive the package family name edde746.Plezy_13q3sv6jzathm that installed
# copies are keyed by.
IDENTITY_NAME = "edde746.Plezy"
PUBLISHER = "CN=AA9C53CB-AD3C-48DA-B3E3-D1E8986D4E25"
PUBLISHER_DISPLAY_NAME = "edde746"
PACKAGE_FAMILY_SUFFIX = "13q3sv6jzathm"
FOUNDATION = "http://schemas.microsoft.com/appx/manifest/foundation/windows10"
ASSET_REFERENCE = re.compile(r"assets\\([A-Za-z0-9._-]+\.png)")
# Package's child order is fixed by the foundation schema. A manifest may use a
# subset of these, but never a different order.
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
REQUIRED_ELEMENTS = (
    "Identity",
    "Properties",
    "Resources",
    "Dependencies",
    "Capabilities",
    "Applications",
)
REQUIRED_CAPABILITIES = ("runFullTrust", "internetClient", "privateNetworkClientServer")
# Certification requires these three. The optional tile and splash assets are
# only checked once referenced, since dropping them is a legitimate choice.
REQUIRED_ASSETS = ("StoreLogo.png", "Square150x150Logo.png", "Square44x44Logo.png")

# Normalized so that every pattern below can anchor on \n and $ regardless of
# whether this checkout stores the PowerShell scripts with CRLF endings.
text = SCRIPT.read_text(encoding="utf-8").replace("\r\n", "\n")
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def local_name(tag: str) -> str:
    return tag.rpartition("}")[2]


def declarations() -> str:
    """New-AppxManifest above its here-string: params and identity strings."""
    match = re.search(r'(?ms)^function New-AppxManifest \{\n(.*?)^    return @"$', text)
    require(match is not None, "New-AppxManifest must return a here-string template")
    return match.group(1) if match else ""


def template() -> str:
    """The AppxManifest.xml emitted by New-AppxManifest."""
    match = re.search(r'(?ms)^    return @"\n(.*?)\n"@\n', text)
    require(match is not None, "New-AppxManifest must return a single here-string template")
    return match.group(1) if match else ""


def substitute(manifest: str, values: dict[str, str]) -> str:
    """Fill the template's PowerShell interpolations with their real values.

    Longest name first: $PublisherDisplayName also starts with $Publisher, and
    PowerShell resolves the longer name.
    """
    for name in sorted(values, key=len, reverse=True):
        manifest = manifest.replace(f"${name}", values[name])
    unresolved = sorted(set(re.findall(r"\$\w+", manifest)))
    require(
        not unresolved,
        "the template interpolates values this checker cannot resolve: "
        f"{', '.join(unresolved)}",
    )
    return manifest


def package_family_suffix(publisher: str) -> str:
    """The 13-character hash Windows derives from a publisher distinguished name.

    SHA-256 over the UTF-16LE publisher, first 8 bytes, padded to 65 bits and
    base32-encoded with the alphabet Windows uses for this (i, l, o and u are
    omitted).
    """
    digest = hashlib.sha256(publisher.encode("utf-16-le")).digest()[:8]
    bits = f"{int.from_bytes(digest, 'big'):064b}0"
    alphabet = "0123456789abcdefghjkmnpqrstvwxyz"
    return "".join(alphabet[int(bits[index : index + 5], 2)] for index in range(0, 65, 5))


def named_step(block: str, name: str) -> str:
    match = re.search(rf"(?ms)^      - name: {re.escape(name)}\n.*?(?=^      - |\Z)", block)
    require(match is not None, f"missing '{name}' step in package-windows")
    return match.group(0) if match else ""


require(
    "function New-AppxManifest" in text,
    "the manifest must be built by New-AppxManifest so every architecture shares one template",
)
prelude = declarations()
manifest_template = template()

# build-installer.ps1 once carried one whole .iss per architecture shape and the
# copies drifted apart. Anything that appears twice here has drifted too.
for once in (
    r'^    return @"$',
    r"^<Package ",
    r"^  <Identity ",
    r"^  <Capabilities>$",
    r"^  <Applications>$",
):
    require(
        len(re.findall(once, text, re.MULTILINE)) == 1,
        f"{once} must match exactly one line; a second copy of the template will drift",
    )

# The two values the caller supplies, plus every identity string the function
# declares. Together they must cover the whole template, so an interpolation
# added there has to be declared here before it can pass.
for parameter in ("MsixVersion", "Architecture"):
    require(
        f"[Parameter(Mandatory)][string]${parameter}" in prelude,
        f"New-AppxManifest must take ${parameter} as a mandatory parameter",
    )
pubspec_version, _ = parse_pubspec_version(PUBSPEC.read_text(encoding="utf-8"))
values = {"MsixVersion": f"{pubspec_version}.0", "Architecture": "x64"}
values.update(re.findall(r'(?m)^    \$(\w+) = "([^"]*)"$', prelude))

substituted = substitute(manifest_template, values)
package = None
try:
    package = ElementTree.fromstring(substituted)
except ElementTree.ParseError as error:
    require(False, f"the substituted manifest must be well-formed XML: {error}")

if package is not None:
    require(
        package.tag == f"{{{FOUNDATION}}}Package",
        "the root element must be Package in the appx foundation namespace",
    )

    present = [local_name(child.tag) for child in package]
    missing = [element for element in REQUIRED_ELEMENTS if element not in present]
    require(not missing, f"the manifest must declare {', '.join(missing)}")
    require(
        [element for element in present if element in SCHEMA_ORDER]
        == [element for element in SCHEMA_ORDER if element in present],
        "Package children must keep schema order "
        f"({', '.join(SCHEMA_ORDER)}); makeappx rejects a reordered manifest",
    )
    require(len(present) == len(set(present)), "no Package child may be declared twice")

    identity = package.find(f"{{{FOUNDATION}}}Identity")
    if identity is None:
        require(False, "the manifest must declare an Identity element")
    else:
        # Both patterns are schema constraints: makeappx refuses the package
        # before reading a single payload file when either is violated.
        require(
            re.fullmatch(r"[-.A-Za-z0-9]{3,50}", identity.get("Name") or "") is not None,
            "Identity/@Name must match the schema's [-.A-Za-z0-9]+ pattern; an underscore "
            "is rejected by makeappx before it reads any payload",
        )
        require(
            (identity.get("Publisher") or "").startswith("CN="),
            "Identity/@Publisher must be the full distinguished name, starting with CN=",
        )
        require(
            identity.get("Name") == IDENTITY_NAME
            and identity.get("Publisher") == PUBLISHER
            and package.findtext(
                f"{{{FOUNDATION}}}Properties/{{{FOUNDATION}}}PublisherDisplayName"
            )
            == PUBLISHER_DISPLAY_NAME,
            "the manifest must carry the identity reserved in Partner Center "
            f"({IDENTITY_NAME}, {PUBLISHER}, {PUBLISHER_DISPLAY_NAME}); any drift fails "
            "Store validation",
        )
        require(
            identity.get("Version") == values["MsixVersion"],
            "Identity/@Version must be the pubspec version plus the Store-reserved "
            f"revision field: expected {values['MsixVersion']}",
        )

    capabilities = [
        child.get("Name") for child in package.findall(f"{{{FOUNDATION}}}Capabilities/*")
    ]
    for capability in REQUIRED_CAPABILITIES:
        require(
            capability in capabilities,
            f"the manifest must declare the {capability} capability",
        )
    require(
        "Windows.Desktop"
        in [
            child.get("Name")
            for child in package.findall(
                f"{{{FOUNDATION}}}Dependencies/{{{FOUNDATION}}}TargetDeviceFamily"
            )
        ],
        "Dependencies must target Windows.Desktop; packaging fails without a device family",
    )

    application = package.find(f"{{{FOUNDATION}}}Applications/{{{FOUNDATION}}}Application")
    binary_name = re.search(
        r'(?m)^set\(BINARY_NAME "([^"]+)"\)$', CMAKE.read_text(encoding="utf-8")
    )
    require(binary_name is not None, "windows/CMakeLists.txt must set BINARY_NAME")
    if application is None:
        require(False, "the manifest must declare an Application element")
    elif binary_name is not None:
        require(
            application.get("Executable") == f"{binary_name.group(1)}.exe",
            "Application/@Executable must be the executable windows/CMakeLists.txt builds, "
            f"{binary_name.group(1)}.exe",
        )
        require(
            application.get("EntryPoint") == "Windows.FullTrustApplication",
            "a packaged Win32 app must enter through Windows.FullTrustApplication",
        )

    # Assets are named in attributes (the tile logos) and in element text (the
    # Properties/Logo), so both are scanned.
    referenced = {
        match.group(1)
        for element in package.iter()
        for value in (*element.attrib.values(), element.text or "")
        if (match := ASSET_REFERENCE.fullmatch(value.strip()))
    }
    for asset in REQUIRED_ASSETS:
        require(asset in referenced, f"the manifest must reference {asset}")
    for asset in sorted(referenced):
        require(
            (ASSETS / asset).is_file(),
            f"windows/msix/assets/{asset} is referenced by the manifest but is not in the "
            "tree; packaging fails on a missing asset",
        )

# Independent of the manifest: Partner Center reports the package family name,
# so recomputing it from the pinned publisher proves that string is byte-exact.
# A mistyped publisher otherwise only surfaces as a rejected upload.
require(
    package_family_suffix(PUBLISHER) == PACKAGE_FAMILY_SUFFIX,
    f"the pinned publisher must hash to the package family name reported by Partner "
    f"Center, {IDENTITY_NAME}_{PACKAGE_FAMILY_SUFFIX}",
)

require(
    'Version="$MsixVersion"' in manifest_template,
    "Identity/@Version must come from the single version variable, not a literal",
)
require(
    'ProcessorArchitecture="$Architecture"' in manifest_template,
    "Identity/@ProcessorArchitecture must be interpolated, not pinned to one architecture",
)
require(
    len(re.findall(r"(?m)^\$MsixVersion = ", text)) == 1,
    "the MSIX version must be derived once, so the bundle and both packages agree",
)
require(
    re.search(r'(?m)^    return "\$\w+\.0"$', text) is not None,
    "the MSIX version must append the Store-reserved revision field as 0",
)
require(
    r"($Version -split '\+')[0]" in text,
    "pubspec's +build metadata must be stripped; the Store reserves the fourth field",
)
require(
    r"'^\d+\.\d+\.\d+$'" in text,
    "a version that is not major.minor.patch must be rejected instead of packaged",
)

# Native exit codes are invisible to $ErrorActionPreference, so the one
# invocation that checks $LASTEXITCODE has to be the only one.
require(
    len(re.findall(r"(?m)^    & \$Tool @Arguments$", text)) == 1
    and "& $MakeAppx" not in text
    and "& $MakePri" not in text
    and "$LASTEXITCODE -ne 0" in text,
    "every SDK tool call must go through the single invocation that checks $LASTEXITCODE",
)

# The taskbar, task view and Alt-Tab draw the small logo on a plate filled with
# BackgroundColor, and the manifest's transparent background leaves the shell
# painting the user's accent colour behind the icon. Only an altform-unplated
# variant suppresses that plate, and qualified variants resolve solely through
# resources.pri - as plain payload files they are inert.
for form in ("altform-unplated", "altform-lightunplated"):
    require(
        any(ASSETS.glob(f"Square44x44Logo.targetsize-*_{form}.png")),
        f"the small logo needs targetsize {form} variants, or the shell draws the taskbar "
        "icon on an accent-coloured plate",
    )
require(
    '"new", "/pr"' in text and "resources.pri" in text,
    "the staged payload must be indexed into resources.pri, or every qualified logo "
    "variant is inert payload",
)
require(
    "RemoveChild($Packaging)" in text,
    "autoResourcePackage must be stripped from the PRI config; it moves the qualified "
    "logos into resource-package indexes that a per-architecture .msix never carries",
)
require(
    "signtool" not in text.lower(),
    "the bundle must stay unsigned; the Store re-signs it, and any other certificate "
    "fails publisher-identity validation",
)

# The version the manifest carries is passed in by the workflow, so the link
# back to pubspec.yaml lives there rather than in the script.
workflow = WORKFLOW.read_text(encoding="utf-8")
package_windows = job_block(workflow, "package-windows")
require(bool(package_windows), "missing package-windows job")
msix_step = named_step(package_windows, MSIX_STEP)
for argument in (
    ".\\windows\\build-msix.ps1",
    '-X64BuildDir "build-x64"',
    '-Arm64BuildDir "build-arm64"',
    '-Version "${{ steps.version.outputs.version }}"',
):
    require(
        argument in msix_step,
        f"the MSIX step must reuse the existing packaging inputs: {argument}",
    )
require(
    "pubspec.yaml" in package_windows,
    "the version handed to both packaging scripts must be read from pubspec.yaml",
)
require(
    package_windows.count(BUNDLE) == 2,
    f"{BUNDLE} must be attested and uploaded, exactly once each",
)
require(
    BUNDLE not in job_block(workflow, "create-release"),
    f"{BUNDLE} must not be attached to the GitHub release; a Store-identity package "
    "cannot be installed without the Store certificate",
)

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print("windows msix manifest checks passed")
