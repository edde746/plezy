#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests>=2.31",
#   "google-api-python-client>=2.100",
#   "google-auth>=2.23",
#   "PyJWT>=2.8",
#   "cryptography>=42",
# ]
# ///
"""Plezy production deployment pipeline.

One command releases to every channel:

    uv run scripts/release/deploy.py release --version 2.27.0 --notes cl.txt

Phases (in order):
    preflight   validate tools, credentials, git state
    changelog   generate per-channel release notes via the claude CLI
    bump        set version.xcconfig (MARKETING_VERSION, CURRENT_PROJECT_VERSION) and the Flatpak metainfo's
                first <release>, commit those two files, push main
    farm_start  trigger .github/workflows/build.yml for a tagged draft release
    play        build the Play bundle (Gradle, -Pplezy.flavor=store), upload its native symbols, publish it to
                Google Play production
    amazon      build the Amazon APK (Gradle, -Pplezy.flavor=amazon), replace the APK in an Amazon Appstore edit
                through the App Submission API, commit the edit
    ios         archive Plezy-iOS (XcodeGen + xcodebuild), export the App Store IPA, upload its dSYMs, upload the
                IPA to App Store Connect
    tvos        the same for Plezy-tvOS (with its Top Shelf extension)
    asc         App Store Connect metadata: wait for builds, set What's New,
                attach builds to iOS + tvOS versions (submit with --submit)
    farm_wait   wait for the build workflow, download the Microsoft Store artifact
    release     verify the build workflow's draft release and attach release notes
    msstore     submit the Store msixbundle via the Microsoft Store Submission API
    publish     flip the GitHub release out of draft; the release event updates
                Homebrew, WinGet, and the appcast branch

State is checkpointed to build/deploy/state.json; a failed run resumes where
it stopped (`release` again, optionally with --only/--skip). `--dry-run`
prints every external action without performing any.

Credentials come from .env at the repository root:
    SUPPLY_JSON_KEY_DATA / SUPPLY_JSON_KEY   Play service-account JSON (data or path)
    SUPPLY_PACKAGE_NAME                      Android package name (com.edde746.plezy)
    AMAZON_APPSTORE_CLIENT_ID / _CLIENT_SECRET / _PACKAGE_NAME
    AMAZON_APPSTORE_APP_ID                   Amazon App ID (amzn1.devportal.
                                             mobileapp...., from the console URL)
    DELIVER_APP_IDENTIFIER                   Apple bundle id (com.edde746.plezy)
    ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_PATH
                                             App Store Connect team API key (.p8)
    APPLE_TEAM_ID                            Apple distribution team id (G88U5B5783,
                                             the team project.yml and ExportOptions.plist name)
    MSSTORE_TENANT_ID / MSSTORE_CLIENT_ID / MSSTORE_CLIENT_SECRET
                                             Azure AD app linked to Partner Center
    MSSTORE_APP_ID                           Store application id (from the
                                             Partner Center product URL)
    MSSTORE_PRICE_ID                         Store price tier to keep on every
                                             submission (see the Store caveat)
    PLEZY_SENTRY_DSN                         crash reports' DSN, built into the store builds
    SENTRY_AUTH_TOKEN (or BUGS_ADMIN_TOKEN)  the crash-report server's token for tools/upload_symbols.sh;
                                             SENTRY_URL, SENTRY_ORG, SENTRY_PROJECT default to
                                             https://bugs.plezy.app, plezy, plezy
The Play bundle and the Amazon APK are signed with the upload keystore android/app/key.properties names.
The App Store export signs with the Xcode account signed in on this Mac (team G88U5B5783).
GitHub auth comes from the `gh` CLI login.

In-app purchases (the `supporter` product on the App Store and Google Play) live on the store records; no phase
creates, changes or submits them.

Amazon caveat: the "touch capabilities" / "offline capabilities" questions are
not exposed by the public App Submission API (verified against its OpenAPI
spec), so the amazon phase pauses for those two checkboxes before it commits
the edit. Everything else, including the submit, is automated.

Microsoft Store caveat: the packaged submission API cannot echo back the
priceId "Base" it reports for a base price set in Partner Center's current
pricing UI, and a submission sent without a priceId publishes as free. The
msstore phase therefore refuses to submit unless MSSTORE_PRICE_ID names a
price tier the API accepts, and it verifies the tier the API stored before
committing.

Tier ids run Tier1012 - Tier1424 for this account (advanced pricing model),
one id per row of the Partner Center conversion table in ascending order:
Tier1012 is 0.99 USD and Tier1424 is 1999.99 USD, so 5.99 USD is Tier1062.
Read the table at Pricing and availability -> view conversion table when the
price changes.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import plistlib
import re
import shlex
import shutil
import socket
import subprocess
import sys
import time
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent.parent

DEPLOY_DIR = ROOT / "build" / "deploy"
STATE_PATH = DEPLOY_DIR / "state.json"
NOTES_DIR = DEPLOY_DIR / "notes"
ARTIFACTS_DIR = DEPLOY_DIR / "artifacts"
APPLE_DIR = DEPLOY_DIR / "apple"
MAPPINGS_DIR = DEPLOY_DIR / "r8-mappings"

VERSION_FILE = "version.xcconfig"
METAINFO_FILE = "desktop/app/packaging/linux/com.edde746.plezy.metainfo.xml"
EXPORT_OPTIONS = SCRIPT_DIR / "ExportOptions.plist"

REPO = "edde746/plezy"
APPLE_TEAM_ID = "G88U5B5783"
BUNDLE_ID = "com.edde746.plezy"
TOP_SHELF_BUNDLE_ID = "com.edde746.plezy.TopShelfExtension"
AMAZON_VERSION_CODE_OFFSET = 3000

PHASES = [
    "preflight",
    "changelog",
    "bump",
    "farm_start",
    "play",
    "amazon",
    "ios",
    "tvos",
    "asc",
    "farm_wait",
    "release",
    "msstore",
    "publish",
]

# channel -> (claude platform description, hard character limit)
CHANNEL_SPECS = {
    # One What's New text serves both the iOS and the tvOS App Store versions.
    "appstore": ("iOS and tvOS (Apple TV)", 4000),
    "play": ("Android", 500),
    "amazon": ("Android (Amazon Appstore: Fire TV and Fire tablets)", 4000),
}

AMAZON_API_BASE = "https://developer.amazon.com/api/appstore/v1/applications"
AMAZON_AUTH_URL = "https://api.amazon.com/auth/o2/token"
ASC_API_BASE = "https://api.appstoreconnect.apple.com/v1"
MSSTORE_API_BASE = "https://manage.devcenter.microsoft.com/v1.0/my/applications"


@dataclass(frozen=True)
class GradleBuild:
    flavor: str
    task: str
    output: str
    # The zip member holding the Sentry Gradle plugin's properties, which name the R8 mapping's UUID.
    debug_meta: str


GRADLE_BUILDS = {
    "play": GradleBuild(
        flavor="store",
        task=":app-android:bundleRelease",
        output="android/app/build/outputs/bundle/release/app-android-release.aab",
        debug_meta="base/assets/sentry-debug-meta.properties",
    ),
    "amazon": GradleBuild(
        flavor="amazon",
        task=":app-android:assembleRelease",
        output="android/app/build/outputs/apk/release/app-android-release.apk",
        debug_meta="assets/sentry-debug-meta.properties",
    ),
}
R8_MAPPING = "android/app/build/outputs/mapping/release/mapping.txt"


@dataclass(frozen=True)
class ApplePlatform:
    scheme: str
    destination: str
    asc_platform: str
    altool_type: str


APPLE_PLATFORMS = {
    "ios": ApplePlatform("Plezy-iOS", "generic/platform=iOS", "IOS", "ios"),
    "tvos": ApplePlatform("Plezy-tvOS", "generic/platform=tvOS", "TV_OS", "appletvos"),
}

# The draft release build.yml makes: every public asset (the msixbundle is a workflow artifact only), the Sparkle
# appcast and the checksums file.
RELEASE_ASSET_NAMES = frozenset(
    {
        "SHA256SUMS",
        "appcast.xml",
        "plezy-android-arm64-v8a.tar.gz",
        "plezy-android-armeabi-v7a.tar.gz",
        "plezy-android-x86_64.tar.gz",
        "plezy-ios.ipa",
        "plezy-macos.dmg",
        "plezy-windows-installer.exe",
        "plezy-windows-x64-portable.7z",
        "plezy-windows-arm64-portable.7z",
        *(
            f"plezy-linux-{arch}.{kind}"
            for arch in ("x64", "arm64")
            for kind in ("tar.gz", "deb", "rpm", "pkg.tar.zst", "flatpak", "AppImage", "AppImage.zsync")
        ),
    }
)


class DeployError(Exception):
    """Fatal, user-actionable pipeline failure."""


class PhaseDeferred(Exception):
    """A phase intentionally left pending for a later resume."""


# ---------------------------------------------------------------------------
# Pure helpers (unit-tested in test_deploy.py)
# ---------------------------------------------------------------------------


def parse_env_text(text: str, base: dict[str, str] | None = None) -> dict[str, str]:
    """Parse .env content: KEY=VALUE lines, comments, quotes, ${VAR} expansion.

    Expansion resolves against earlier keys in the same file first, then
    ``base``. Unknown references expand to the empty string, matching shell
    behavior when sourcing the file.
    """
    base = base or {}
    values: dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export "):].lstrip()
        if "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip()
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
            continue
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            quote = value[0]
            value = value[1:-1]
        else:
            quote = None
        if quote != "'":
            value = re.sub(
                r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}",
                lambda m: values.get(m.group(1), base.get(m.group(1), "")),
                value,
            )
        values[key] = value
    return values


def semver(version: str) -> tuple[int, int, int]:
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise DeployError(f"version must be major.minor.patch (e.g. 2.27.0); got {version!r}")
    major, minor, patch = (int(part) for part in version.split("."))
    return major, minor, patch


def parse_version_text(text: str) -> tuple[str, int]:
    """version.xcconfig's MARKETING_VERSION and CURRENT_PROJECT_VERSION."""
    values = dict(re.findall(r"^([A-Z_]+) = (\S+)$", text, re.M))
    marketing, build = values.get("MARKETING_VERSION"), values.get("CURRENT_PROJECT_VERSION")
    if not marketing or not re.fullmatch(r"\d+\.\d+\.\d+", marketing):
        raise DeployError(f"{VERSION_FILE}: MARKETING_VERSION is {marketing!r}, not major.minor.patch")
    if not build or not re.fullmatch(r"[1-9]\d*", build):
        raise DeployError(f"{VERSION_FILE}: CURRENT_PROJECT_VERSION is {build!r}, not a positive integer")
    return marketing, int(build)


def bump_version_text(text: str, version: str, build: int) -> str:
    """version.xcconfig with MARKETING_VERSION = version and CURRENT_PROJECT_VERSION = build.

    The version may stay (a build-number-only release) but never goes back; the build always grows.
    """
    current, current_build = parse_version_text(text)
    if semver(version) < semver(current):
        raise DeployError(f"version {version} is below {VERSION_FILE}'s {current}")
    if build <= current_build:
        raise DeployError(f"build {build} is not above {VERSION_FILE}'s {current_build}")
    text = re.sub(r"^MARKETING_VERSION = \S+$", f"MARKETING_VERSION = {version}", text, count=1, flags=re.M)
    text = re.sub(r"^CURRENT_PROJECT_VERSION = \S+$", f"CURRENT_PROJECT_VERSION = {build}", text, count=1, flags=re.M)
    if parse_version_text(text) != (version, build):
        raise DeployError(f"{VERSION_FILE}: the bump did not take")
    return text


def release_description(notes: str) -> str:
    """AppStream markup for release notes: `- `, `* ` or `• ` lines as a list, other lines (headings without their
    `#`s) as paragraphs."""
    parts: list[str] = []
    items: list[str] = []
    for raw in notes.splitlines():
        line = raw.strip()
        bullet = re.match(r"[-*•]\s+(.*)", line)
        if bullet:
            items.append(f"<li>{escape(bullet.group(1))}</li>")
            continue
        if items:
            parts.append(f"<ul>{''.join(items)}</ul>")
            items = []
        text = line.lstrip("#").strip()
        if text:
            parts.append(f"<p>{escape(text)}</p>")
    if items:
        parts.append(f"<ul>{''.join(items)}</ul>")
    if not parts:
        raise DeployError("release notes are empty")
    return "\n".join(f"        {part}" for part in parts)


def metainfo_with_release(text: str, version: str, date: str, notes: str) -> str:
    """The Flatpak metainfo with <release version date> and its notes first in <releases> (build-flatpak.py requires
    the first release to be version.xcconfig's MARKETING_VERSION). Unchanged when that release is already first."""
    root = ET.fromstring(text)
    releases = root.find("releases")
    first = releases.find("release") if releases is not None else None
    if first is not None and first.get("version") == version:
        return text
    block = (
        f'    <release version="{version}" date="{date}">\n'
        "      <description>\n"
        f"{release_description(notes)}\n"
        "      </description>\n"
        "    </release>\n"
    )
    if releases is None:
        match = re.search(r"^</component>", text, re.M)
        if not match:
            raise DeployError(f"{METAINFO_FILE}: no </component> line")
        result = text[: match.start()] + "  <releases>\n" + block + "  </releases>\n" + text[match.start():]
    else:
        match = re.search(r"^\s*<releases>\n", text, re.M)
        if not match:
            raise DeployError(f"{METAINFO_FILE}: no <releases> line")
        result = text[: match.end()] + block + text[match.end():]
    ET.fromstring(result)
    return result


def resolve_phases(only: list[str] | None, skip: list[str] | None) -> list[str]:
    """Select phases in canonical order; preflight rides along unless skipped."""
    only = only or []
    skip = skip or []
    for name in [*only, *skip]:
        if name not in PHASES:
            raise DeployError(f"unknown phase {name!r}; valid: {', '.join(PHASES)}")
    selected = []
    for phase in PHASES:
        if only and phase not in only and phase != "preflight":
            continue
        if phase in skip:
            continue
        selected.append(phase)
    return selected


def gradle_command(channel: str) -> list[str]:
    """The Gradle build of a store channel's Android package (signed with android/app/key.properties' keystore)."""
    build = GRADLE_BUILDS[channel]
    return ["./gradlew", "--console=plain", f"-Pplezy.flavor={build.flavor}", build.task]


def expected_version_code(channel: str, build: int) -> int:
    """android/app/build.gradle.kts' versionCode of a channel: Play N, Amazon N + 3000."""
    return build + AMAZON_VERSION_CODE_OFFSET if channel == "amazon" else build


def apple_archive_command(platform: str, archive: Path, extra: list[str]) -> list[str]:
    """xcodebuild archive of a platform's app scheme (Release) from the XcodeGen project, into ``archive``."""
    target = APPLE_PLATFORMS[platform]
    return [
        "xcodebuild", "archive",
        "-project", str(ROOT / "apple" / "Plezy.xcodeproj"),
        "-scheme", target.scheme,
        "-configuration", "Release",
        "-destination", target.destination,
        "-archivePath", str(archive),
        "-derivedDataPath", str(APPLE_DIR / f"dd-{platform}"),
        *extra,
    ]


def archive_problems(archive: Path, platform: str, version: str, build: int) -> list[str]:
    """What is wrong with an xcarchive for the App Store: the app's identity and version, and on tvOS its Top Shelf
    extension."""
    app = archive / "Products" / "Applications" / "Plezy.app"
    info_path = app / "Info.plist"
    if not info_path.is_file():
        return [f"{archive} holds no Products/Applications/Plezy.app"]
    info = plistlib.loads(info_path.read_bytes())
    problems = []
    found = (info.get("CFBundleIdentifier"), info.get("CFBundleShortVersionString"), info.get("CFBundleVersion"))
    wanted = (BUNDLE_ID, version, str(build))
    if found != wanted:
        problems.append(f"Plezy.app is {found}, not {wanted}")
    if platform == "tvos":
        extension = app / "PlugIns" / "PlezyTopShelf.appex" / "Info.plist"
        if not extension.is_file():
            problems.append("Plezy.app embeds no PlugIns/PlezyTopShelf.appex")
        else:
            ext = plistlib.loads(extension.read_bytes())
            ext_found = (ext.get("CFBundleIdentifier"), ext.get("CFBundleShortVersionString"), ext.get("CFBundleVersion"))
            ext_wanted = (TOP_SHELF_BUNDLE_ID, version, str(build))
            if ext_found != ext_wanted:
                problems.append(f"PlezyTopShelf.appex is {ext_found}, not {ext_wanted}")
    return problems


def release_asset_problems(expected: frozenset[str], actual: set[str]) -> list[str]:
    problems = []
    missing = sorted(expected - actual)
    unexpected = sorted(actual - expected)
    if missing:
        problems.append("missing: " + ", ".join(missing))
    if unexpected:
        problems.append("unexpected: " + ", ".join(unexpected))
    return problems


def mapping_uuid(package: Path, member: str) -> str:
    """The R8 mapping UUID the Sentry Gradle plugin wrote into an AAB or APK (io.sentry.ProguardUuids)."""
    with zipfile.ZipFile(package) as archive:
        text = archive.read(member).decode("utf-8")
    match = re.search(r"^io\.sentry\.ProguardUuids=(\S+)$", text, re.M)
    if not match:
        raise DeployError(f"{package.name}: {member} names no R8 mapping UUID")
    return match.group(1)


# Price tiers the ingestion API echoes on GET but refuses on PUT.
MSSTORE_UNUSABLE_PRICE_IDS = frozenset({"Base"})


def resolve_msstore_pricing(submission: dict, price_id: str | None) -> str:
    """Pin a cloned Store submission's base price, or refuse to submit.

    The ingestion API echoes priceId "Base" for a base price set through
    Partner Center's current pricing UI, then rejects it on PUT ("'Base' is not
    a valid PriceId for base price"). Dropping priceId is worse: the PUT
    defaults the submission to Free, which is how 2.19.1 published at $0.
    Microsoft's own msstore CLI just refuses to update such products. So send a
    real tier when one is configured, otherwise stop before anything uploads.

    isAdvancedPricingModel is read-only; it describes which tier table the
    account has, not the price, and is dropped rather than echoed back.
    """
    pricing = submission.get("pricing")
    if not isinstance(pricing, dict):
        pricing = {}
        submission["pricing"] = pricing
    pricing.pop("isAdvancedPricingModel", None)

    resolved = price_id or pricing.get("priceId")
    if not resolved or resolved in MSSTORE_UNUSABLE_PRICE_IDS:
        raise DeployError(
            f"msstore: the cloned submission reports priceId {pricing.get('priceId')!r}, "
            "which the ingestion API rejects on PUT, and submitting without one "
            "publishes the app as free (that is how 2.19.1 shipped at $0). Set "
            "MSSTORE_PRICE_ID in .env to the price tier this app must keep, or "
            "upload the package in Partner Center by hand"
        )
    pricing["priceId"] = resolved
    return resolved


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------


@dataclass
class State:
    version: str = ""
    build_number: int = 0
    done: list[str] = field(default_factory=list)
    data: dict = field(default_factory=dict)

    @classmethod
    def load(cls) -> "State | None":
        if not STATE_PATH.is_file():
            return None
        raw = json.loads(STATE_PATH.read_text(encoding="utf-8"))
        return cls(
            version=raw.get("version", ""),
            build_number=raw.get("build_number", 0),
            done=raw.get("done", []),
            data=raw.get("data", {}),
        )

    def save(self) -> None:
        STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        STATE_PATH.write_text(
            json.dumps(
                {
                    "version": self.version,
                    "build_number": self.build_number,
                    "done": self.done,
                    "data": self.data,
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    def mark_done(self, phase: str) -> None:
        if phase not in self.done:
            self.done.append(phase)
        self.save()


@dataclass
class Context:
    args: argparse.Namespace
    env: dict[str, str]
    state: State
    phases: list[str]

    @property
    def dry_run(self) -> bool:
        return bool(self.args.dry_run)

    @property
    def version(self) -> str:
        return self.state.version

    @property
    def tag(self) -> str:
        return self.state.version

    @property
    def build_number(self) -> int:
        return self.state.build_number

    def confirm(self, prompt: str) -> bool:
        if self.args.yes:
            log(f"--yes: auto-confirming: {prompt}")
            return True
        if not sys.stdin.isatty():
            raise DeployError(
                f"interactive confirmation required ({prompt!r}) but stdin is not a "
                "TTY; rerun interactively or pass --yes"
            )
        answer = input(f"{prompt} [y/N] ").strip().lower()
        return answer in ("y", "yes")


# ---------------------------------------------------------------------------
# Process / logging helpers
# ---------------------------------------------------------------------------


def log(message: str) -> None:
    print(f"\033[1m==>\033[0m {message}", flush=True)


def run(
    cmd: list[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    check: bool = True,
    capture: bool = False,
    input_text: str | None = None,
    echo: bool = True,
) -> subprocess.CompletedProcess:
    cmd = [str(part) for part in cmd]
    if echo:
        print(f"    $ {shlex.join(cmd)}", flush=True)
    merged_env = {**os.environ, **(env or {})}
    result = subprocess.run(
        cmd,
        cwd=cwd or ROOT,
        env=merged_env,
        input=input_text,
        capture_output=capture,
        text=True,
    )
    if check and result.returncode != 0:
        detail = ""
        if capture:
            detail = "\n" + (result.stderr or result.stdout or "").strip()
        raise DeployError(f"command failed ({result.returncode}): {shlex.join(cmd)}{detail}")
    return result


def dry_guard(ctx: Context, *actions: str) -> bool:
    """True when the actions must be skipped because of --dry-run (each is printed as the plan)."""
    if ctx.dry_run:
        for action in actions:
            log(f"[dry-run] would {action}")
        return True
    return False


def require_env(env: dict[str, str], keys: list[str], purpose: str) -> None:
    missing = [k for k in keys if not env.get(k)]
    if missing:
        raise DeployError(f"{purpose}: missing environment values: {', '.join(missing)}")


def require_tool(name: str, hint: str = "") -> None:
    if shutil.which(name) is None:
        suffix = f" ({hint})" if hint else ""
        raise DeployError(f"required tool not found on PATH: {name}{suffix}")


def load_env_file(*, required: bool = True) -> dict[str, str]:
    env_path = ROOT / ".env"
    if not env_path.is_file():
        if required:
            raise DeployError(f".env not found at {env_path}")
        log(f".env not found at {env_path}; the dry run reads the process environment only")
        return dict(os.environ)
    values = parse_env_text(env_path.read_text(encoding="utf-8"), dict(os.environ))
    # The checked release configuration is authoritative. Ambient variables can
    # otherwise invisibly retain stale bundle IDs or signing teams between runs.
    os.environ.update(values)
    return dict(os.environ)


def git_output(args: list[str]) -> str:
    return run(["git", *args], capture=True, echo=False).stdout.strip()


def current_version() -> tuple[str, int]:
    return parse_version_text((ROOT / VERSION_FILE).read_text(encoding="utf-8"))


def symbols_env(env: dict[str, str]) -> dict[str, str]:
    """tools/upload_symbols.sh's environment: the crash-report server, its organization and project, its token."""
    return {
        "SENTRY_URL": env.get("SENTRY_URL") or "https://bugs.plezy.app",
        "SENTRY_ORG": env.get("SENTRY_ORG") or "plezy",
        "SENTRY_PROJECT": env.get("SENTRY_PROJECT") or "plezy",
        "SENTRY_AUTH_TOKEN": env.get("SENTRY_AUTH_TOKEN") or env.get("BUGS_ADMIN_TOKEN", ""),
    }


def upload_symbols(ctx: Context, kind: str, path: Path) -> None:
    run([ROOT / "tools" / "upload_symbols.sh", kind, path], env=symbols_env(ctx.env))


# ---------------------------------------------------------------------------
# Phase: preflight
# ---------------------------------------------------------------------------


def preflight_problems(ctx: Context) -> list[str]:
    # Requirements are checked only for phases that will actually run this
    # invocation; a resume after e.g. `changelog` must not re-demand --notes.
    pending = set(ctx.phases) - set(ctx.state.done)
    problems: list[str] = []

    def check(condition: bool, problem: str) -> None:
        if not condition:
            problems.append(problem)

    def need_env(keys: list[str], purpose: str) -> None:
        missing = [k for k in keys if not ctx.env.get(k)]
        check(not missing, f"{purpose}: missing environment values: {', '.join(missing)}")

    def need_tool(name: str, hint: str) -> None:
        check(shutil.which(name) is not None, f"required tool not found on PATH: {name} ({hint})")

    require_tool("git")
    branch = git_output(["branch", "--show-current"])
    check(branch == "main", f"releases run from main; current branch is {branch!r}")

    dirty = [
        line
        # Unstripped: each line's first two columns are its status, the path follows from the fourth.
        for line in run(["git", "status", "--porcelain"], capture=True, echo=False).stdout.splitlines()
        if line and not line.startswith("??")
    ]
    if "bump" in pending:
        # An interrupted bump leaves its two files written and uncommitted; the rerun's bump commits them.
        bumped: dict[str, str] = {}
        if any(line[3:] in (VERSION_FILE, METAINFO_FILE) for line in dirty):
            try:
                bumped = bump_texts(ctx)
            except DeployError:
                pass
        dirty = [
            line for line in dirty
            if line[3:] not in bumped or bumped[line[3:]] != (ROOT / line[3:]).read_text(encoding="utf-8")
        ]
        check(
            not dirty,
            "tracked files have uncommitted changes; commit or stash before releasing:\n  " + "\n  ".join(dirty),
        )

    try:
        semver(ctx.version)
    except DeployError as error:
        problems.append(str(error))

    tag_exists = bool(git_output(["tag", "-l", ctx.tag]))
    check(
        not (tag_exists and {"bump", "release"} <= pending),
        f"tag {ctx.tag} already exists; pick a new version, or drop the "
        "release phase for a store-only push that reuses it",
    )
    if "bump" not in pending and pending & {"play", "amazon", "ios", "tvos"}:
        check(
            current_version() == (ctx.version, ctx.build_number),
            f"{VERSION_FILE} is {current_version()}, not ({ctx.version!r}, {ctx.build_number}); "
            "the store builds read it, so run bump or check out the release commit",
        )

    env = ctx.env
    if pending & {"play", "amazon"}:
        check((ROOT / "android/app/key.properties").is_file(),
              "android/app/key.properties (the upload keystore) is missing; the store builds would be debug-signed")
    if pending & {"play", "amazon", "ios", "tvos"}:
        need_env(["PLEZY_SENTRY_DSN"], "store builds (crash reports)")
        check(bool(symbols_env(env)["SENTRY_AUTH_TOKEN"]),
              "symbols: set SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN in .env (tools/upload_symbols.sh)")
    if pending & {"ios", "tvos"}:
        need_tool("xcodebuild", "Xcode command line tools")
        need_tool("xcrun", "Xcode command line tools")
    if pending & {"farm_start", "farm_wait", "release", "publish"}:
        need_tool("gh", "GitHub CLI")
        if shutil.which("gh"):
            status = run(["gh", "auth", "status"], capture=True, echo=False, check=False)
            check(status.returncode == 0, "gh is not logged in (gh auth login)")
    if "changelog" in pending and not ctx.dry_run:
        need_tool("claude", "used to generate per-channel changelogs")

    notes = getattr(ctx.args, "notes", None)
    if "changelog" in pending:
        check(bool(notes), "changelog phase requires --notes <file>")
        check(not notes or Path(notes).is_file(), f"notes file not found: {notes}")

    if "play" in pending:
        check(bool(env.get("SUPPLY_JSON_KEY_DATA") or env.get("SUPPLY_JSON_KEY")),
              "play: set SUPPLY_JSON_KEY_DATA or SUPPLY_JSON_KEY in .env")
        need_env(["SUPPLY_PACKAGE_NAME"], "play")
        check(env.get("SUPPLY_PACKAGE_NAME") in (None, "", BUNDLE_ID),
              f"play: SUPPLY_PACKAGE_NAME must be {BUNDLE_ID}; got {env.get('SUPPLY_PACKAGE_NAME')!r}")
    if "amazon" in pending:
        need_env(
            [
                "AMAZON_APPSTORE_CLIENT_ID",
                "AMAZON_APPSTORE_CLIENT_SECRET",
                "AMAZON_APPSTORE_PACKAGE_NAME",
                "AMAZON_APPSTORE_APP_ID",
            ],
            "amazon",
        )
        check(env.get("AMAZON_APPSTORE_PACKAGE_NAME") in (None, "", "com.edde746.plezy3"),
              "amazon: AMAZON_APPSTORE_PACKAGE_NAME must be com.edde746.plezy3; "
              f"got {env.get('AMAZON_APPSTORE_PACKAGE_NAME')!r}")
        app_id = env.get("AMAZON_APPSTORE_APP_ID") or ""
        check(not app_id or app_id.startswith("amzn1.devportal.mobileapp."),
              "amazon: AMAZON_APPSTORE_APP_ID must be the amzn1.devportal.mobileapp. "
              "app id from the developer-console URL; the API no longer accepts "
              f"package names; got {app_id!r}")
    if pending & {"ios", "tvos", "asc"}:
        need_env(["ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH", "APPLE_TEAM_ID", "DELIVER_APP_IDENTIFIER"],
                 "app store connect")
        check(env.get("DELIVER_APP_IDENTIFIER") in (None, "", BUNDLE_ID),
              f"app store connect: DELIVER_APP_IDENTIFIER must be {BUNDLE_ID}; "
              f"got {env.get('DELIVER_APP_IDENTIFIER')!r}")
        check(env.get("APPLE_TEAM_ID") in (None, "", APPLE_TEAM_ID),
              f"app store connect: APPLE_TEAM_ID must be {APPLE_TEAM_ID} (apple/project.yml, ExportOptions.plist); "
              f"got {env.get('APPLE_TEAM_ID')!r}")
        if env.get("ASC_KEY_PATH"):
            key_path = Path(env["ASC_KEY_PATH"]).expanduser()
            check(key_path.is_file(), f"ASC_KEY_PATH does not exist: {key_path}")
    if "msstore" in pending:
        need_env(["MSSTORE_TENANT_ID", "MSSTORE_CLIENT_ID", "MSSTORE_CLIENT_SECRET", "MSSTORE_APP_ID"], "msstore")
    return problems


def phase_preflight(ctx: Context) -> None:
    problems = preflight_problems(ctx)
    if problems and not ctx.dry_run:
        raise DeployError("preflight:\n  " + "\n  ".join(problems))
    for problem in problems:
        log(f"[dry-run] preflight problem (a real run stops here): {problem}")
    log("preflight OK" if not problems else "preflight: problems above")


# ---------------------------------------------------------------------------
# Phase: changelog
# ---------------------------------------------------------------------------

CHANGELOG_PROMPT = (
    "Below is a changelog for a cross-platform app (iOS, tvOS, Android, macOS, "
    "Linux, Windows). Return ONLY the entries relevant to the given platform. "
    "Keep the same format (section headers + bullet points). If a section has no "
    "relevant entries, omit it entirely. If an entry is not platform-specific, "
    "include it. You MUST stay under the character limit. Aggressively drop less "
    "important entries and consolidate similar ones to fit. Count your output "
    "characters before responding. Output nothing else."
)


def generate_channel_notes(notes_text: str, platform: str, limit: int) -> str:
    # Retries ask for progressively less than the real limit: models routinely
    # land a few characters over an exact target, so build in headroom.
    target = limit
    previous_length = 0
    for _attempt in (1, 2, 3):
        prompt = f"{CHANGELOG_PROMPT} Platform: {platform}. Max {target} characters."
        if previous_length:
            prompt += (
                f" Your previous attempt was {previous_length} characters, which is "
                "OVER the limit. Cut aggressively; dropping entries is better than "
                "exceeding the limit."
            )
        result = run(
            ["claude", "--print", prompt],
            input_text=notes_text,
            capture=True,
            echo=False,
        )
        text = result.stdout.strip()
        if len(text) <= limit:
            return text
        previous_length = len(text)
        target = max(int(limit * 0.85), limit - 200)
        log(f"changelog for {platform!r} is {len(text)}/{limit} chars; retrying with target {target}")
    raise DeployError(
        f"changelog for {platform!r} still exceeds {limit} chars after retries; "
        f"write {NOTES_DIR} contents manually and rerun (existing files are reused)"
    )


def notes_path(channel: str) -> Path:
    suffix = "md" if channel == "github" else "txt"
    return NOTES_DIR / f"{channel}.{suffix}"


def phase_changelog(ctx: Context) -> None:
    notes_file = Path(ctx.args.notes)
    if dry_guard(
        ctx,
        f"copy {notes_file} to {notes_path('github')} (the GitHub release and the Flatpak metainfo)",
        *(
            f"generate {notes_path(channel)} for {platform} (max {limit} chars) with claude --print"
            for channel, (platform, limit) in CHANNEL_SPECS.items()
        ),
    ):
        return
    notes_text = notes_file.read_text(encoding="utf-8")
    NOTES_DIR.mkdir(parents=True, exist_ok=True)
    notes_path("github").write_text(notes_text, encoding="utf-8")
    for channel, (platform, limit) in CHANNEL_SPECS.items():
        target = notes_path(channel)
        if target.is_file() and target.read_text(encoding="utf-8").strip():
            log(f"changelog: reusing existing {target}")
            continue
        text = generate_channel_notes(notes_text, platform, limit)
        target.write_text(text + "\n", encoding="utf-8")
        log(f"changelog: {channel} ({len(text)}/{limit} chars)")


# ---------------------------------------------------------------------------
# Phase: bump
# ---------------------------------------------------------------------------


def head_text(path: str) -> str:
    return run(["git", "show", f"HEAD:{path}"], capture=True, echo=False).stdout


def bump_texts(ctx: Context) -> dict[str, str]:
    """The version file and the metainfo as bump writes them from HEAD's, by path."""
    github_notes = notes_path("github")
    if not github_notes.is_file():
        raise DeployError(f"bump: {github_notes} is missing (the metainfo's release notes); run changelog first")
    today = datetime.date.today().isoformat()
    return {
        VERSION_FILE: bump_version_text(head_text(VERSION_FILE), ctx.version, ctx.build_number),
        METAINFO_FILE: metainfo_with_release(
            head_text(METAINFO_FILE), ctx.version, today, github_notes.read_text(encoding="utf-8")
        ),
    }


def phase_bump(ctx: Context) -> None:
    """Set version.xcconfig and the metainfo's first release, commit those two files, push main.

    The files are written from HEAD's, so a rerun after a bump interrupted before its commit commits what it wrote.
    The build workflow creates the tag and draft release only after every
    release artifact succeeds. Store-only pushes can reuse an existing tag by
    omitting the farm and GitHub release phases.
    """
    current = parse_version_text(head_text(VERSION_FILE))
    target = (ctx.version, ctx.build_number)
    if current[0] == ctx.version:
        message = f"chore: bump build number to {ctx.build_number}"
    else:
        message = f"chore: bump version to {ctx.version}"
    if current == target:
        log(f"bump: {VERSION_FILE} already at {ctx.version} ({ctx.build_number})")
    elif not dry_guard(
        ctx,
        f"set {VERSION_FILE} {current[0]} ({current[1]}) -> MARKETING_VERSION {ctx.version}, "
        f"CURRENT_PROJECT_VERSION {ctx.build_number}",
        f"add <release version=\"{ctx.version}\" date=\"{datetime.date.today().isoformat()}\"> with "
        f"{notes_path('github')} first in {METAINFO_FILE}",
        f"git commit -m {message!r} -- {VERSION_FILE} {METAINFO_FILE}",
    ):
        for path, text in bump_texts(ctx).items():
            (ROOT / path).write_text(text, encoding="utf-8")
        # Pathspec commit: never sweeps unrelated staged work into the bump.
        run(["git", "commit", "-m", message, "--", VERSION_FILE, METAINFO_FILE])
    if dry_guard(ctx, "git push origin main"):
        return
    run(["git", "push", "origin", "main"])
    ctx.state.data["release_sha"] = git_output(["rev-parse", "HEAD"])
    ctx.state.save()


# ---------------------------------------------------------------------------
# Phases: farm_start / farm_wait (GitHub Actions build farm)
# ---------------------------------------------------------------------------


def phase_farm_start(ctx: Context) -> None:
    if dry_guard(
        ctx,
        f"gh workflow run build.yml --ref main --field release_tag={ctx.tag}",
        f"find the run titled 'Release {ctx.tag}' on the release commit and record its id",
    ):
        return
    head = ctx.state.data.get("release_sha") or git_output(["rev-parse", "HEAD"])
    dispatch = ctx.state.data.get("farm_dispatch")
    if isinstance(dispatch, dict) and dispatch.get("headSha") == head:
        previous_ids = set(dispatch.get("previousRunIds", []))
        log("farm: resuming run discovery after an interrupted dispatch")
    else:
        previous = run(
            [
                "gh", "run", "list",
                "--workflow", "build.yml",
                "--branch", "main",
                "--limit", "20",
                "--json", "databaseId",
            ],
            capture=True,
            echo=False,
        )
        previous_ids = {entry["databaseId"] for entry in json.loads(previous.stdout or "[]")}
        ctx.state.data["farm_dispatch"] = {
            "headSha": head,
            "previousRunIds": sorted(previous_ids),
        }
        ctx.state.save()
        run(["gh", "workflow", "run", "build.yml", "--ref", "main", "--field", f"release_tag={ctx.tag}"])
    log("farm: waiting for the workflow run to appear")
    deadline = time.monotonic() + 180
    while time.monotonic() < deadline:
        time.sleep(10)
        result = run(
            [
                "gh", "run", "list",
                "--workflow", "build.yml",
                "--branch", "main",
                "--limit", "20",
                "--json", "databaseId,displayTitle,headSha,status,createdAt",
            ],
            capture=True,
            echo=False,
        )
        runs = json.loads(result.stdout or "[]")
        for entry in runs:
            if (
                entry["databaseId"] not in previous_ids
                and entry["headSha"] == head
                and entry.get("displayTitle") == f"Release {ctx.tag}"
            ):
                ctx.state.data["farm_run_id"] = entry["databaseId"]
                ctx.state.data.pop("farm_dispatch", None)
                ctx.state.save()
                log(f"farm: run {entry['databaseId']} started")
                return
    ctx.state.data.pop("farm_dispatch", None)
    ctx.state.save()
    raise DeployError(
        "farm: build.yml run did not appear within 3 minutes; "
        "dispatch marker cleared, so rerunning farm_start is safe"
    )


def phase_farm_wait(ctx: Context) -> None:
    if dry_guard(
        ctx,
        "wait for the build.yml run to succeed (gh run view, every 30 s)",
        f"gh run download <run> --name windows-msix into {ARTIFACTS_DIR / 'windows-msix'} "
        "(plezy-windows.msixbundle)",
    ):
        return
    run_id = ctx.state.data.get("farm_run_id")
    if not run_id:
        raise DeployError("farm_wait: no farm_run_id in state; run farm_start first")
    log(f"farm: waiting for run {run_id} (this takes a while)")
    while True:
        result = run(
            ["gh", "run", "view", str(run_id), "--json", "status,conclusion"],
            capture=True,
            echo=False,
        )
        info = json.loads(result.stdout)
        if info["status"] == "completed":
            if info["conclusion"] != "success":
                raise DeployError(
                    f"farm: run {run_id} concluded {info['conclusion']!r}; "
                    f"see https://github.com/{REPO}/actions/runs/{run_id}"
                )
            break
        time.sleep(30)
    if ARTIFACTS_DIR.exists():
        shutil.rmtree(ARTIFACTS_DIR)
    msix_dir = ARTIFACTS_DIR / "windows-msix"
    msix_dir.mkdir(parents=True)
    run(["gh", "run", "download", str(run_id), "--name", "windows-msix", "--dir", str(msix_dir)])
    log(
        "farm: release assets were attached in GitHub Actions; "
        f"Microsoft Store package downloaded to {msix_dir}"
    )


# ---------------------------------------------------------------------------
# Android builds (play, amazon)
# ---------------------------------------------------------------------------


def build_android(ctx: Context, channel: str) -> Path:
    """Build a store channel's package with Gradle, keep its R8 mapping by UUID, upload its native symbols."""
    build = GRADLE_BUILDS[channel]
    package = ROOT / build.output
    if package.exists():
        package.unlink()
    run(gradle_command(channel))
    if not package.is_file():
        raise DeployError(f"{channel}: {package} not found after {build.task}")
    # The crash-report server takes no R8 mapping; a report names the UUID of the mapping that retraces it.
    uuid = mapping_uuid(package, build.debug_meta)
    MAPPINGS_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT / R8_MAPPING, MAPPINGS_DIR / f"{uuid}.txt")
    log(f"{channel}: R8 mapping kept as {MAPPINGS_DIR / f'{uuid}.txt'}")
    upload_symbols(ctx, "android", package)
    return package


def android_build_plan(channel: str) -> list[str]:
    build = GRADLE_BUILDS[channel]
    return [
        f"{shlex.join(gradle_command(channel))} (signed with android/app/key.properties) -> {build.output}",
        f"keep {R8_MAPPING} as {MAPPINGS_DIR}/<{build.debug_meta} UUID>.txt",
        f"tools/upload_symbols.sh android {build.output}",
    ]


# ---------------------------------------------------------------------------
# Phase: play
# ---------------------------------------------------------------------------


def _execute_google_request(request):
    return request.execute(num_retries=5)


def _execute_resumable_google_upload(request, label: str):
    # next_chunk retries HTTP status failures but raises on a dropped connection.
    # Calling it again after a raise asks the server how much it holds and
    # resumes there, or returns the finished resource when the last chunk
    # landed before the response was lost (Play closed the socket that way
    # after accepting the 2.21.0 bundle).
    response = None
    transport_failures = 0
    while response is None:
        try:
            status, response = request.next_chunk(num_retries=5)
        except (ConnectionError, TimeoutError) as error:
            transport_failures += 1
            if transport_failures > 5:
                raise
            log(f"{label}: upload connection lost ({error!r}); resuming")
            time.sleep(2**transport_failures)
            continue
        if status:
            log(f"{label}: upload {status.progress():.0%}")
    return response


def _play_publisher(ctx: Context):
    from google.oauth2 import service_account  # noqa: PLC0415
    from googleapiclient.discovery import build as gapi_build  # noqa: PLC0415

    if ctx.env.get("SUPPLY_JSON_KEY_DATA"):
        info = json.loads(ctx.env["SUPPLY_JSON_KEY_DATA"])
    else:
        info = json.loads(Path(ctx.env["SUPPLY_JSON_KEY"]).expanduser().read_text(encoding="utf-8"))
    credentials = service_account.Credentials.from_service_account_info(
        info, scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    # build_http() takes its read timeout from the socket default, else 60 s, and
    # Play processes a ~300 MB bundle for longer than that after the last chunk:
    # the upload is accepted but the response read times out and the edit is lost.
    previous_timeout = socket.getdefaulttimeout()
    socket.setdefaulttimeout(1800)
    try:
        return gapi_build("androidpublisher", "v3", credentials=credentials, cache_discovery=False)
    finally:
        socket.setdefaulttimeout(previous_timeout)


def _play_pending_edit(ctx: Context, edits, package: str) -> str | None:
    """The recorded edit id when it is still open and already holds this build."""
    from googleapiclient.errors import HttpError  # noqa: PLC0415

    edit_id = ctx.state.data.get("play_pending_edit_id")
    if not edit_id:
        return None
    try:
        _execute_google_request(edits.get(packageName=package, editId=edit_id))
        bundles = _execute_google_request(
            edits.bundles().list(packageName=package, editId=edit_id)
        ).get("bundles", [])
    except HttpError as error:
        log(f"play: recorded edit {edit_id} is gone ({error.status_code}); starting over")
        bundles = None
    if bundles is not None and any(b.get("versionCode") == ctx.build_number for b in bundles):
        return str(edit_id)
    if bundles is not None:
        log(f"play: recorded edit {edit_id} holds no versionCode {ctx.build_number}; starting over")
    ctx.state.data.pop("play_pending_edit_id", None)
    ctx.state.save()
    return None


def phase_play(ctx: Context) -> None:
    package = ctx.env.get("SUPPLY_PACKAGE_NAME", BUNDLE_ID)
    if dry_guard(
        ctx,
        *android_build_plan("play"),
        f"Play Developer API for {package}: insert an edit, upload the bundle (resumable, 30-min read timeout), "
        f"check versionCode {expected_version_code('play', ctx.build_number)}",
        f"set track production: release {ctx.version}, status completed, en-GB notes {notes_path('play')}",
        "validate and commit the edit (sent for review)",
    ):
        return

    from googleapiclient.http import MediaFileUpload  # noqa: PLC0415

    edits = _play_publisher(ctx).edits()
    edit_id = _play_pending_edit(ctx, edits, package)
    if edit_id:
        log(f"play: resuming edit {edit_id}, which already holds versionCode {ctx.build_number}")
        version_code = ctx.build_number
    else:
        aab = build_android(ctx, "play")
        edit_id = _execute_google_request(edits.insert(packageName=package, body={}))["id"]
        log(f"play: created edit {edit_id}")
        # Recorded before the upload so a run that dies after Play accepted the
        # bundle resumes this edit instead of rebuilding and re-uploading.
        ctx.state.data["play_pending_edit_id"] = edit_id
        ctx.state.save()
        upload = edits.bundles().upload(
            packageName=package,
            editId=edit_id,
            media_body=MediaFileUpload(
                str(aab),
                mimetype="application/octet-stream",
                chunksize=10 * 1024 * 1024,
                resumable=True,
            ),
        )
        uploaded = _execute_resumable_google_upload(upload, "play")
        version_code = uploaded["versionCode"]
        if version_code != expected_version_code("play", ctx.build_number):
            raise DeployError(f"play: uploaded versionCode {version_code} != expected {ctx.build_number}")
    release_notes = notes_path("play").read_text(encoding="utf-8").strip()
    _execute_google_request(
        edits.tracks().update(
            packageName=package,
            editId=edit_id,
            track="production",
            body={
                "releases": [
                    {
                        "name": ctx.version,
                        "versionCodes": [str(version_code)],
                        "status": "completed",
                        "releaseNotes": [{"language": "en-GB", "text": release_notes}],
                    }
                ]
            },
        )
    )
    from googleapiclient.errors import HttpError  # noqa: PLC0415

    def requires_manual_review_send(error: Exception) -> bool:
        return "changesNotSentForReview" in str(error)

    try:
        _execute_google_request(edits.validate(packageName=package, editId=edit_id))
    except HttpError as error:
        if not requires_manual_review_send(error):
            raise
        log("play: validate blocked; this app state requires a manual review send")
    try:
        _execute_google_request(edits.commit(packageName=package, editId=edit_id))
        log(f"play: committed edit for versionCode {version_code} (sent for review)")
    except HttpError as error:
        if not requires_manual_review_send(error):
            raise
        _execute_google_request(
            edits.commit(
                packageName=package,
                editId=edit_id,
                changesNotSentForReview=True,
            )
        )
        log(
            f"play: committed edit for versionCode {version_code} WITHOUT sending "
            "for review (Play refused automatic submission for this app's current "
            "state); open the Play Console and press 'Send for review'"
        )
    ctx.state.data.pop("play_pending_edit_id", None)
    ctx.state.save()


# ---------------------------------------------------------------------------
# Phase: amazon
# ---------------------------------------------------------------------------


def _amazon_token(env: dict[str, str]):
    import requests  # noqa: PLC0415

    response = requests.post(
        AMAZON_AUTH_URL,
        data={
            "grant_type": "client_credentials",
            "client_id": env["AMAZON_APPSTORE_CLIENT_ID"],
            "client_secret": env["AMAZON_APPSTORE_CLIENT_SECRET"],
            "scope": "appstore::apps:readwrite",
        },
        timeout=60,
    )
    if response.status_code != 200:
        raise DeployError(f"amazon: token request failed ({response.status_code})")
    return response.json()["access_token"]


class AmazonClient:
    def __init__(self, app_id: str, token: str):
        import requests  # noqa: PLC0415

        self.base = f"{AMAZON_API_BASE}/{app_id}"
        self.session = requests.Session()
        self.session.headers["Authorization"] = f"Bearer {token}"

    def request(self, method: str, path: str, **kwargs):
        response = self.session.request(method, f"{self.base}{path}", timeout=600, **kwargs)
        if response.status_code >= 400:
            raise DeployError(
                f"amazon: {method} {path} failed ({response.status_code}): {response.text[:500]}"
            )
        return response

    def etag(self, path: str) -> str:
        etag = self.request("GET", path).headers.get("ETag", "")
        if not etag:
            raise DeployError(f"amazon: no ETag returned for {path}")
        return etag


def _commit_amazon_edit(ctx: Context, client: AmazonClient, edit_id: str) -> None:
    print(
        "\n  Amazon requires two console-only answers that reset on every binary\n"
        "  upload (not exposed by the App Submission API):\n"
        "    1. open https://developer.amazon.com/apps-and-games/console\n"
        f"    2. open the pending edit for {ctx.env['AMAZON_APPSTORE_PACKAGE_NAME']}\n"
        '    3. re-check "touch capabilities" and "offline capabilities"\n'
    )
    if not ctx.confirm("Toggles checked? Commit (submit) the Amazon edit now?"):
        log("amazon: edit left open; rerun with --only amazon later or submit manually")
        raise PhaseDeferred
    etag = client.etag(f"/edits/{edit_id}")
    client.request("POST", f"/edits/{edit_id}/commit", headers={"If-Match": etag})
    ctx.state.data.pop("amazon_pending_edit_id", None)
    ctx.state.save()
    log(f"amazon: edit {edit_id} committed (submitted)")


def phase_amazon(ctx: Context) -> None:
    package = ctx.env.get("AMAZON_APPSTORE_PACKAGE_NAME", "")
    # The submission API addresses apps by Amazon app id; package names 400.
    app_id = ctx.env.get("AMAZON_APPSTORE_APP_ID", "")
    if dry_guard(
        ctx,
        *android_build_plan("amazon"),
        f"App Submission API for app {app_id or '<AMAZON_APPSTORE_APP_ID>'}: open (or reuse) an edit, replace its "
        f"APK (keeps device targeting), check versionCode {expected_version_code('amazon', ctx.build_number)}",
        f"set every listing's recentChanges to {notes_path('amazon')}",
        "pause for the console's touch/offline capability checkboxes, then commit (submit) the edit"
        + (" -- skipped: --amazon-skip-commit" if getattr(ctx.args, "amazon_skip_commit", False) else ""),
    ):
        return
    pending_edit_id = ctx.state.data.get("amazon_pending_edit_id")
    if pending_edit_id:
        log(f"amazon: resuming pending edit {pending_edit_id} without replacing its APK")
        client = AmazonClient(app_id, _amazon_token(ctx.env))
        _commit_amazon_edit(ctx, client, str(pending_edit_id))
        return

    apk = build_android(ctx, "amazon")
    client = AmazonClient(app_id, _amazon_token(ctx.env))

    edits_response = client.request("GET", "/edits")
    edits = edits_response.json() if edits_response.text.strip() else {}
    edit_id = edits.get("id")
    if edit_id:
        log(f"amazon: reusing active edit {edit_id}")
    else:
        edit_id = client.request("POST", "/edits").json()["id"]
        log(f"amazon: created edit {edit_id}")

    apks = client.request("GET", f"/edits/{edit_id}/apks").json()
    if not apks:
        raise DeployError("amazon: edit contains no APK slots; upload once via the console first")
    apk_id = apks[0]["id"]
    if len(apks) > 1:
        log(f"amazon: warning: {len(apks)} APK slots present, replacing only {apk_id}")

    etag = client.etag(f"/edits/{edit_id}/apks/{apk_id}")
    log(f"amazon: uploading APK of {package} (replace, preserves device targeting)")
    replaced = client.request(
        "PUT",
        f"/edits/{edit_id}/apks/{apk_id}/replace",
        headers={"Content-Type": "application/octet-stream", "If-Match": etag},
        data=apk.read_bytes(),
    ).json()
    version_code = replaced.get("versionCode")
    if version_code != expected_version_code("amazon", ctx.build_number):
        raise DeployError(
            f"amazon: uploaded versionCode {version_code} != expected "
            f"{expected_version_code('amazon', ctx.build_number)}; edit {edit_id} left uncommitted"
        )
    log(f"amazon: uploaded versionCode {version_code}")

    release_notes = notes_path("amazon").read_text(encoding="utf-8").strip() or "-"
    listings = client.request("GET", f"/edits/{edit_id}/listings").json().get("listings", {})
    for lang in listings:
        listing_response = client.request("GET", f"/edits/{edit_id}/listings/{lang}")
        listing = listing_response.json()
        listing["recentChanges"] = release_notes
        client.request(
            "PUT",
            f"/edits/{edit_id}/listings/{lang}",
            headers={"If-Match": listing_response.headers["ETag"]},
            json=listing,
        )
        log(f"amazon: release notes updated for {lang}")

    if ctx.args.amazon_skip_commit:
        log("amazon: --amazon-skip-commit set; edit left open for manual submission")
        return

    ctx.state.data["amazon_pending_edit_id"] = edit_id
    ctx.state.save()
    _commit_amazon_edit(ctx, client, edit_id)


# ---------------------------------------------------------------------------
# Phases: ios / tvos (archive, export, upload to App Store Connect)
# ---------------------------------------------------------------------------


def _asc_auth_args(env: dict[str, str]) -> list[str]:
    return [
        "-allowProvisioningUpdates",
        "-authenticationKeyPath", str(Path(env["ASC_KEY_PATH"]).expanduser().resolve()),
        "-authenticationKeyID", env["ASC_KEY_ID"],
        "-authenticationKeyIssuerID", env["ASC_ISSUER_ID"],
    ]


def _find_single_ipa(directory: Path, label: str) -> Path:
    ipas = sorted(directory.rglob("*.ipa")) if directory.is_dir() else []
    if len(ipas) != 1:
        raise DeployError(f"{label}: expected one exported IPA in {directory}, found {len(ipas)}")
    return ipas[0]


def generate_xcode_project() -> None:
    """apple/Plezy.xcodeproj from apple/project.yml, with the XcodeGen release tools/install_xcodegen.sh pins."""
    xcodegen = run([ROOT / "tools" / "install_xcodegen.sh", ROOT / "build" / "tools"], capture=True).stdout.strip()
    run([xcodegen, "generate", "--quiet"], cwd=ROOT / "apple")


def _archive(ctx: Context, platform: str) -> Path:
    archive = APPLE_DIR / f"{APPLE_PLATFORMS[platform].scheme}.xcarchive"
    if archive.exists():
        shutil.rmtree(archive)
    # The Kotlin phase inside the archive builds PlezyKit with PLEZY_SENTRY_DSN from this environment (.env).
    run(apple_archive_command(platform, archive, _asc_auth_args(ctx.env)))
    problems = archive_problems(archive, platform, ctx.version, ctx.build_number)
    if problems:
        raise DeployError(f"{platform}: " + "; ".join(problems))
    return archive


def _export_archive(ctx: Context, archive: Path, label: str) -> Path:
    """Export a signed IPA with the local Xcode account.

    App Store Connect API keys authenticate uploads but cannot create cloud
    distribution certificates. Xcode's signed-in account owns that export step.
    """
    if not archive.is_dir():
        raise DeployError(f"{label}: archive not found at {archive}")
    export_path = APPLE_DIR / f"export-{label}"
    if export_path.exists():
        shutil.rmtree(export_path)
    run([
        "xcodebuild", "-exportArchive",
        "-archivePath", str(archive),
        "-exportOptionsPlist", str(EXPORT_OPTIONS),
        "-exportPath", str(export_path),
        "-allowProvisioningUpdates",
    ])
    return _find_single_ipa(export_path, label)


def _upload_ipa(ctx: Context, ipa: Path, platform: str) -> None:
    """Upload with altool and the App Store Connect API key, a step of its own after the export: the IPA is on disk
    for a retry without re-exporting, and the key (not the Xcode account) authorizes the upload, as it does the
    ASC API calls."""
    if not ipa.is_file():
        raise DeployError(f"{platform}: IPA not found at {ipa}")
    run(
        [
            "xcrun", "altool", "--upload-app",
            "--type", APPLE_PLATFORMS[platform].altool_type,
            "-f", str(ipa),
            "--apiKey", ctx.env["ASC_KEY_ID"],
            "--apiIssuer", ctx.env["ASC_ISSUER_ID"],
            "--p8-file-path", str(Path(ctx.env["ASC_KEY_PATH"]).expanduser().resolve()),
        ]
    )
    log(f"{platform}: uploaded {ipa.name} to App Store Connect")


def phase_apple(ctx: Context, platform: str) -> None:
    target = APPLE_PLATFORMS[platform]
    archive = APPLE_DIR / f"{target.scheme}.xcarchive"
    if dry_guard(
        ctx,
        f"skip {platform} when App Store Connect already has {target.asc_platform} build {ctx.build_number}",
        "generate apple/Plezy.xcodeproj with tools/install_xcodegen.sh's XcodeGen",
        shlex.join(apple_archive_command(platform, archive, [
            "-allowProvisioningUpdates", "-authenticationKeyPath", "<ASC_KEY_PATH>",
            "-authenticationKeyID", "<ASC_KEY_ID>", "-authenticationKeyIssuerID", "<ASC_ISSUER_ID>",
        ])),
        f"check the archive is {BUNDLE_ID} {ctx.version} ({ctx.build_number})"
        + (f" embedding PlugIns/PlezyTopShelf.appex ({TOP_SHELF_BUNDLE_ID})" if platform == "tvos" else ""),
        f"xcodebuild -exportArchive -exportOptionsPlist {EXPORT_OPTIONS.relative_to(ROOT)} "
        f"-exportPath {APPLE_DIR / f'export-{platform}'} -allowProvisioningUpdates (Xcode account, team {APPLE_TEAM_ID})",
        f"tools/upload_symbols.sh dsym {archive / 'dSYMs'}",
        f"xcrun altool --upload-app --type {target.altool_type} -f <ipa> --apiKey --apiIssuer --p8-file-path",
    ):
        return
    if _asc_has_uploaded_build(ctx, target.asc_platform):
        log(f"{platform}: App Store Connect already has build {ctx.build_number}; skipping upload")
        return
    generate_xcode_project()
    archive = _archive(ctx, platform)
    ipa = _export_archive(ctx, archive, platform)
    upload_symbols(ctx, "dsym", archive / "dSYMs")
    _upload_ipa(ctx, ipa, platform)


def phase_ios(ctx: Context) -> None:
    phase_apple(ctx, "ios")


def phase_tvos(ctx: Context) -> None:
    phase_apple(ctx, "tvos")


# ---------------------------------------------------------------------------
# Phase: asc (App Store Connect metadata)
# ---------------------------------------------------------------------------


class AscClient:
    def __init__(self, env: dict[str, str]):
        self.env = env
        self._token = ""
        self._token_expiry = 0.0

    def token(self) -> str:
        import jwt  # noqa: PLC0415

        now = time.time()
        if not self._token or now > self._token_expiry - 60:
            key = Path(self.env["ASC_KEY_PATH"]).expanduser().read_text(encoding="utf-8")
            self._token_expiry = now + 1200
            self._token = jwt.encode(
                {
                    "iss": self.env["ASC_ISSUER_ID"],
                    "iat": int(now) - 30,
                    "exp": int(self._token_expiry),
                    "aud": "appstoreconnect-v1",
                },
                key,
                algorithm="ES256",
                headers={"kid": self.env["ASC_KEY_ID"]},
            )
        return self._token

    def request(self, method: str, path: str, **kwargs):
        import requests  # noqa: PLC0415

        response = requests.request(
            method,
            f"{ASC_API_BASE}{path}",
            headers={"Authorization": f"Bearer {self.token()}"},
            timeout=120,
            **kwargs,
        )
        if response.status_code >= 400:
            raise DeployError(
                f"asc: {method} {path} failed ({response.status_code}): {response.text[:800]}"
            )
        return response

    def app_id(self) -> str:
        bundle_id = self.env["DELIVER_APP_IDENTIFIER"]
        data = self.request("GET", f"/apps?filter[bundleId]={bundle_id}").json()["data"]
        if not data:
            raise DeployError(f"asc: no app found for bundle id {bundle_id}")
        return data[0]["id"]


def _asc_has_uploaded_build(ctx: Context, platform: str) -> bool:
    client = AscClient(ctx.env)
    app_id = client.app_id()
    builds = client.request(
        "GET",
        f"/builds?filter[app]={app_id}&filter[version]={ctx.build_number}"
        f"&filter[preReleaseVersion.platform]={platform}&sort=-uploadedDate&limit=1",
    ).json()["data"]
    return bool(builds)


def _asc_wait_for_build(client: AscClient, app_id: str, build_number: int, platform: str) -> str:
    log(f"asc: waiting for {platform} build {build_number} to finish processing")
    deadline = time.monotonic() + 45 * 60
    while time.monotonic() < deadline:
        data = client.request(
            "GET",
            f"/builds?filter[app]={app_id}&filter[version]={build_number}"
            f"&filter[preReleaseVersion.platform]={platform}&sort=-uploadedDate&limit=1",
        ).json()["data"]
        if data:
            state = data[0]["attributes"]["processingState"]
            if state == "VALID":
                return data[0]["id"]
            if state in ("FAILED", "INVALID"):
                raise DeployError(f"asc: {platform} build {build_number} processing state {state}")
        time.sleep(30)
    raise DeployError(f"asc: timed out waiting for {platform} build {build_number}")


def _asc_ensure_version(client: AscClient, app_id: str, version: str, platform: str) -> str:
    data = client.request(
        "GET",
        f"/apps/{app_id}/appStoreVersions?filter[versionString]={version}"
        f"&filter[platform]={platform}&limit=1",
    ).json()["data"]
    if data:
        return data[0]["id"]
    created = client.request(
        "POST",
        "/appStoreVersions",
        json={
            "data": {
                "type": "appStoreVersions",
                "attributes": {"platform": platform, "versionString": version},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        },
    ).json()["data"]
    log(f"asc: created {platform} version {version}")
    return created["id"]


def _asc_set_whats_new(client: AscClient, version_id: str, whats_new: str) -> None:
    localizations = client.request(
        "GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=50"
    ).json()["data"]
    targets = [l for l in localizations if l["attributes"]["locale"] == "en-US"] or localizations
    if not targets:
        raise DeployError("asc: version has no localizations; create one in ASC first")
    for localization in targets:
        client.request(
            "PATCH",
            f"/appStoreVersionLocalizations/{localization['id']}",
            json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": localization["id"],
                    "attributes": {"whatsNew": whats_new},
                }
            },
        )


def _asc_submit_for_review(client: AscClient, app_id: str, version_id: str, platform: str) -> None:
    # The submission holds the app version alone; in-app purchases (supporter) are left as they are.
    submission = client.request(
        "POST",
        "/reviewSubmissions",
        json={
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": platform},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        },
    ).json()["data"]
    client.request(
        "POST",
        "/reviewSubmissionItems",
        json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {
                        "data": {"type": "reviewSubmissions", "id": submission["id"]}
                    },
                    "appStoreVersion": {
                        "data": {"type": "appStoreVersions", "id": version_id}
                    },
                },
            }
        },
    )
    client.request(
        "PATCH",
        f"/reviewSubmissions/{submission['id']}",
        json={
            "data": {
                "type": "reviewSubmissions",
                "id": submission["id"],
                "attributes": {"submitted": True},
            }
        },
    )
    log(f"asc: {platform} version submitted for review")


def phase_asc(ctx: Context) -> None:
    apple_uploads = set(ctx.phases) | set(ctx.state.done)
    platforms = []
    if "ios" in apple_uploads:
        platforms.append("IOS")
    if "tvos" in apple_uploads:
        platforms.append("TV_OS")
    if not platforms:
        log("asc: no Apple upload phases selected; nothing to do")
        return
    if dry_guard(
        ctx,
        *(
            f"App Store Connect API ({platform}): wait for build {ctx.build_number} to be VALID, ensure version "
            f"{ctx.version}, set en-US whatsNew from {notes_path('appstore')}, attach the build"
            + (", submit for review" if ctx.args.submit else " (not submitted: no --submit)")
            for platform in platforms
        ),
    ):
        return

    whats_new = notes_path("appstore").read_text(encoding="utf-8").strip()
    client = AscClient(ctx.env)
    app_id = client.app_id()
    for platform in platforms:
        build_id = _asc_wait_for_build(client, app_id, ctx.build_number, platform)
        version_id = _asc_ensure_version(client, app_id, ctx.version, platform)
        _asc_set_whats_new(client, version_id, whats_new)
        client.request(
            "PATCH",
            f"/appStoreVersions/{version_id}/relationships/build",
            json={"data": {"type": "builds", "id": build_id}},
        )
        log(f"asc: {platform} version {ctx.version} ready with build attached")
        if ctx.args.submit:
            _asc_submit_for_review(client, app_id, version_id, platform)
        else:
            log(f"asc: {platform} not submitted (pass --submit to submit for review)")


# ---------------------------------------------------------------------------
# Phase: release (GitHub)
# ---------------------------------------------------------------------------


def phase_release(ctx: Context) -> None:
    if dry_guard(
        ctx,
        f"gh release view {ctx.tag}: a draft on the release commit with exactly these "
        f"{len(RELEASE_ASSET_NAMES)} assets: {', '.join(sorted(RELEASE_ASSET_NAMES))}",
        f"gh release edit {ctx.tag} --title {ctx.version} --notes-file {notes_path('github')}",
    ):
        return
    result = run(
        ["gh", "release", "view", ctx.tag, "--json", "isDraft,targetCommitish,assets"],
        capture=True,
        check=False,
        echo=False,
    )
    if result.returncode != 0:
        raise DeployError(
            f"release: build workflow did not create draft {ctx.tag}; "
            f"inspect run {ctx.state.data.get('farm_run_id', 'unknown')}"
        )
    info = json.loads(result.stdout)
    if not info.get("isDraft"):
        raise DeployError(f"release: {ctx.tag} exists but is not a draft")

    expected_sha = ctx.state.data.get("release_sha")
    if expected_sha and info.get("targetCommitish") != expected_sha:
        raise DeployError(
            f"release: {ctx.tag} targets {info.get('targetCommitish')}, expected {expected_sha}"
        )

    actual_assets = {asset["name"] for asset in info.get("assets", [])}
    problems = release_asset_problems(RELEASE_ASSET_NAMES, actual_assets)
    if problems:
        raise DeployError("release: draft asset set is invalid (" + "; ".join(problems) + ")")

    body = notes_path("github")
    if not body.is_file():
        raise DeployError(f"release: notes not found at {body}")
    run(["gh", "release", "edit", ctx.tag, "--title", ctx.version, "--notes-file", str(body)])
    log(f"release: verified draft {ctx.tag} with {len(actual_assets)} assets")


# ---------------------------------------------------------------------------
# Phase: msstore
# ---------------------------------------------------------------------------

MSSTORE_TERMINAL_OK = {"PreProcessing", "Certification", "Publishing", "Published", "Release"}


def _msstore_token(env: dict[str, str]) -> str:
    import requests  # noqa: PLC0415

    response = requests.post(
        f"https://login.microsoftonline.com/{env['MSSTORE_TENANT_ID']}/oauth2/token",
        data={
            "grant_type": "client_credentials",
            "client_id": env["MSSTORE_CLIENT_ID"],
            "client_secret": env["MSSTORE_CLIENT_SECRET"],
            "resource": "https://manage.devcenter.microsoft.com",
        },
        timeout=60,
    )
    if response.status_code != 200:
        raise DeployError(f"msstore: token request failed ({response.status_code})")
    return response.json()["access_token"]


def phase_msstore(ctx: Context) -> None:
    bundle = ARTIFACTS_DIR / "windows-msix/plezy-windows.msixbundle"
    if dry_guard(
        ctx,
        f"Microsoft Store submission API for app {ctx.env.get('MSSTORE_APP_ID') or '<MSSTORE_APP_ID>'}: refuse a "
        "pending submission (delete it with --msstore-replace-pending), clone the published one",
        f"mark its packages PendingDelete, add {bundle.name}, pin base price "
        f"{ctx.env.get('MSSTORE_PRICE_ID') or '<MSSTORE_PRICE_ID, else the cloned tier unless Base>'}",
        f"upload {bundle} zipped to the submission's blob, PUT the submission, check the stored priceId",
        "commit the submission and poll its status (at most 30 min)",
    ):
        return
    if not bundle.is_file():
        raise DeployError(f"msstore: msixbundle not found at {bundle}; run farm_wait first")

    import requests  # noqa: PLC0415

    app_id = ctx.env["MSSTORE_APP_ID"]
    session = requests.Session()
    session.headers["Authorization"] = f"Bearer {_msstore_token(ctx.env)}"
    base = f"{MSSTORE_API_BASE}/{app_id}"

    def api(method: str, path: str = "", **kwargs):
        response = session.request(method, f"{base}{path}", timeout=300, **kwargs)
        if response.status_code >= 400:
            raise DeployError(
                f"msstore: {method} {path or '/'} failed ({response.status_code}): "
                f"{response.text[:800]}"
            )
        return response

    app = api("GET").json()
    pending = app.get("pendingApplicationSubmission")
    if pending:
        if not ctx.args.msstore_replace_pending:
            raise DeployError(
                f"msstore: a pending submission exists ({pending['id']}); inspect it in "
                "Partner Center, or rerun with --msstore-replace-pending to delete it"
            )
        api("DELETE", f"/submissions/{pending['id']}")
        log(f"msstore: deleted pending submission {pending['id']}")

    submission = api("POST", "/submissions").json()
    submission_id = submission["id"]
    log(f"msstore: created submission {submission_id} (cloned from last published)")

    if not isinstance(submission.get("applicationPackages"), list):
        submission["applicationPackages"] = []
    for package in submission["applicationPackages"]:
        package["fileStatus"] = "PendingDelete"
    submission["applicationPackages"].append(
        {
            "fileName": bundle.name,
            "fileStatus": "PendingUpload",
            "minimumDirectXVersion": "None",
            "minimumSystemRam": "None",
        }
    )
    try:
        price_id = resolve_msstore_pricing(submission, ctx.env.get("MSSTORE_PRICE_ID"))
    except DeployError:
        api("DELETE", f"/submissions/{submission_id}")
        log(
            f"msstore: deleted submission {submission_id}; nothing was uploaded. "
            f"Upload {bundle} in Partner Center and rerun with --skip msstore"
        )
        raise
    log(f"msstore: base price pinned to {price_id}")

    upload_zip = DEPLOY_DIR / "msstore-upload.zip"
    with zipfile.ZipFile(upload_zip, "w", zipfile.ZIP_STORED) as archive:
        archive.write(bundle, bundle.name)
    log(f"msstore: uploading {upload_zip.stat().st_size / 1e6:.0f} MB package zip")
    with upload_zip.open("rb") as handle:
        blob = requests.put(
            submission["fileUploadUrl"].replace("+", "%2B"),
            data=handle,
            headers={"x-ms-blob-type": "BlockBlob"},
            timeout=3600,
        )
    if blob.status_code >= 400:
        raise DeployError(f"msstore: blob upload failed ({blob.status_code})")

    updated = api("PUT", f"/submissions/{submission_id}", json=submission).json()
    stored_price_id = (updated.get("pricing") or {}).get("priceId")
    if stored_price_id != price_id:
        api("DELETE", f"/submissions/{submission_id}")
        raise DeployError(
            f"msstore: the API stored priceId {stored_price_id!r} instead of "
            f"{price_id!r}; deleted submission {submission_id} instead of "
            "committing a price change"
        )
    api("POST", f"/submissions/{submission_id}/commit")
    log("msstore: committed; polling status")

    deadline = time.monotonic() + 30 * 60
    while time.monotonic() < deadline:
        status = api("GET", f"/submissions/{submission_id}/status").json()
        current = status.get("status", "")
        if current == "CommitFailed":
            raise DeployError(
                "msstore: commit failed: "
                + json.dumps(status.get("statusDetails", {}), indent=2)[:1500]
            )
        if current in MSSTORE_TERMINAL_OK:
            log(f"msstore: submission {submission_id} accepted (status: {current})")
            ctx.state.data["msstore_submission_id"] = submission_id
            ctx.state.save()
            return
        time.sleep(30)
    raise DeployError("msstore: timed out waiting for the submission to leave commit")


# ---------------------------------------------------------------------------
# Phase: publish
# ---------------------------------------------------------------------------


def phase_publish(ctx: Context) -> None:
    if dry_guard(
        ctx,
        f"ask, then gh release edit {ctx.tag} --draft=false (the release event runs update-packages.yml: "
        "Homebrew, WinGet, the appcast branch)",
    ):
        return
    if not ctx.confirm(
        f"Publish GitHub release {ctx.tag}? "
        "The release event will update Homebrew, WinGet, and the appcast branch."
    ):
        log("publish: skipped; rerun with --only publish when ready")
        raise PhaseDeferred

    run(["gh", "release", "edit", ctx.tag, "--draft=false"])
    log(f"publish: release {ctx.tag} is live; package updates run in update-packages.yml")


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

PHASE_LINKS = {
    "play": "https://play.google.com/console",
    "amazon": "https://developer.amazon.com/apps-and-games/console",
    "ios": "https://appstoreconnect.apple.com/apps",
    "tvos": "https://appstoreconnect.apple.com/apps",
    "asc": "https://appstoreconnect.apple.com/apps",
    "msstore": "https://partner.microsoft.com/dashboard",
    "release": f"https://github.com/{REPO}/releases",
    "publish": f"https://github.com/{REPO}/releases",
}


def print_summary(ctx: Context) -> None:
    print(f"\nRelease {ctx.version} ({ctx.build_number}) summary")
    for phase in PHASES:
        if phase == "preflight":
            continue
        if phase not in ctx.phases:
            status = "skipped"
        elif phase in ctx.state.done:
            status = "done"
        else:
            status = "PENDING"
        link = PHASE_LINKS.get(phase, "")
        print(f"  {phase:<12} {status:<8} {link}")
    print()


# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

PHASE_FUNCTIONS = {
    "preflight": phase_preflight,
    "changelog": phase_changelog,
    "bump": phase_bump,
    "farm_start": phase_farm_start,
    "play": phase_play,
    "amazon": phase_amazon,
    "ios": phase_ios,
    "tvos": phase_tvos,
    "asc": phase_asc,
    "farm_wait": phase_farm_wait,
    "release": phase_release,
    "msstore": phase_msstore,
    "publish": phase_publish,
}


def initialize_state(args: argparse.Namespace) -> State:
    if args.fresh:
        state = None
        if DEPLOY_DIR.exists() and not getattr(args, "dry_run", False):
            shutil.rmtree(DEPLOY_DIR)
    else:
        state = State.load()
    if state:
        if args.version and args.version != state.version:
            raise DeployError(
                f"state at {STATE_PATH} is for {state.version}; finish it, or pass "
                "--fresh to discard it"
            )
        if args.build_number and args.build_number != state.build_number:
            raise DeployError(
                f"state at {STATE_PATH} is for build {state.build_number}; pass "
                "--fresh to discard it"
            )
        log(f"resuming release {state.version} ({state.build_number}) "
            f"(done: {', '.join(state.done) or 'nothing'})")
        return state
    if not args.version:
        raise DeployError("--version is required for a new release")
    _, current_build = current_version()
    build_number = args.build_number or current_build + 1
    state = State(version=args.version, build_number=build_number)
    if not getattr(args, "dry_run", False):
        state.save()
    return state


def cmd_release(args: argparse.Namespace) -> int:
    env = load_env_file(required=not args.dry_run)
    state = initialize_state(args)
    # The release plan (phase selection + notes source) persists in state so a
    # bare `release` resume repeats the original invocation instead of widening.
    if args.only is None and state.data.get("only") is not None:
        args.only = state.data["only"]
    if args.skip is None and state.data.get("skip") is not None:
        args.skip = state.data["skip"]
    if args.notes is None and state.data.get("notes"):
        args.notes = state.data["notes"]
    state.data["only"] = args.only
    state.data["skip"] = args.skip
    state.data["notes"] = args.notes
    if not args.dry_run:
        state.save()
    phases = resolve_phases(args.only, args.skip)
    ctx = Context(args=args, env=env, state=state, phases=phases)

    if args.dry_run:
        log(f"dry run: release {state.version} ({state.build_number}), phases: {', '.join(phases)}")
    for phase in phases:
        if phase in state.done:
            log(f"{phase}: already done, skipping")
            continue
        log(f"phase: {phase}")
        try:
            PHASE_FUNCTIONS[phase](ctx)
        except PhaseDeferred:
            continue
        except KeyboardInterrupt:
            print()
            log(f"interrupted during {phase!r}; state saved, rerun `release` to resume")
            return 130
        except DeployError as error:
            print(f"\nERROR in phase {phase!r}: {error}", file=sys.stderr)
            if not ctx.dry_run:
                print(
                    f"State saved to {STATE_PATH}; fix the problem and rerun "
                    "`uv run scripts/release/deploy.py release` to resume.",
                    file=sys.stderr,
                )
            return 1
        if not ctx.dry_run and phase != "preflight":
            state.mark_done(phase)

    print_summary(ctx)
    return 0


def cmd_changelog(args: argparse.Namespace) -> int:
    load_env_file()
    _, current_build = current_version()
    state = State.load() or State(version="unreleased", build_number=current_build + 1)
    args.dry_run = False
    args.yes = True
    ctx = Context(args=args, env=dict(os.environ), state=state, phases=["changelog"])
    phase_changelog(ctx)
    for channel in [*CHANNEL_SPECS, "github"]:
        print(f"  {notes_path(channel)}")
    return 0


def cmd_status(_args: argparse.Namespace) -> int:
    state = State.load()
    if not state:
        print("no release in progress")
        return 0
    print(f"release {state.version} ({state.build_number})")
    for phase in PHASES:
        marker = "x" if phase in state.done else " "
        print(f"  [{marker}] {phase}")
    if state.data:
        print(json.dumps(state.data, indent=2))
    return 0


def cmd_clean(_args: argparse.Namespace) -> int:
    run(["./gradlew", "--console=plain", "clean"])
    if DEPLOY_DIR.exists():
        shutil.rmtree(DEPLOY_DIR)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="deploy.py",
        description="Plezy production deployment pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="phases: " + " ".join(PHASES),
    )
    sub = parser.add_subparsers(dest="command", required=True)

    release = sub.add_parser("release", help="run the release pipeline")
    release.add_argument("--version", help="semver for a new release (e.g. 2.27.0)")
    release.add_argument("--notes", help="path to the raw release notes file")
    release.add_argument("--build-number", type=int,
                         help=f"use this build number instead of {VERSION_FILE}'s CURRENT_PROJECT_VERSION + 1 "
                              "(for a tree whose version was already bumped)")
    release.add_argument("--only", action="append", metavar="PHASE",
                         help="run only these phases (repeatable, comma-separated)")
    release.add_argument("--skip", action="append", metavar="PHASE",
                         help="skip these phases (repeatable, comma-separated)")
    release.add_argument("--dry-run", action="store_true",
                         help="print external actions without performing them")
    release.add_argument("--submit", action="store_true",
                         help="also submit App Store versions for review")
    release.add_argument("--yes", action="store_true",
                         help="assume yes for confirmation prompts")
    release.add_argument("--fresh", action="store_true",
                         help="discard any in-progress release state")
    release.add_argument("--amazon-skip-commit", action="store_true",
                         help="leave the Amazon edit open instead of committing")
    release.add_argument("--msstore-replace-pending", action="store_true",
                         help="delete a pending Partner Center submission if present")
    release.set_defaults(func=cmd_release)

    changelog = sub.add_parser("changelog", help="generate per-channel notes only")
    changelog.add_argument("--notes", required=True, help="path to the raw release notes file")
    changelog.set_defaults(func=cmd_changelog)

    status = sub.add_parser("status", help="show in-progress release state")
    status.set_defaults(func=cmd_status)

    clean = sub.add_parser("clean", help="clean build outputs (gradle) and build/deploy")
    clean.set_defaults(func=cmd_clean)

    return parser


def _split_phase_lists(values: list[str] | None) -> list[str] | None:
    if not values:
        return None
    result: list[str] = []
    for value in values:
        result.extend(part.strip() for part in value.split(",") if part.strip())
    return result


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if hasattr(args, "only"):
        args.only = _split_phase_lists(args.only)
        args.skip = _split_phase_lists(args.skip)
    try:
        return args.func(args)
    except DeployError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
