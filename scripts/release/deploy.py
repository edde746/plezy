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

    uv run scripts/release/deploy.py release --version 2.13.0 --notes cl.txt

Phases (in order):
    preflight   validate tools, credentials, git state
    changelog   generate per-channel release notes via the claude CLI
    bump        bump pubspec version, commit, push (replaces release.yml);
                the git tag is created by the release phase, so store-only
                pushes can reuse an already-released version string
    farm_start  trigger .github/workflows/build.yml (Windows/Linux/macOS farm)
    play        build AAB, upload symbols, publish to Google Play production
    amazon      build APK, upload via the App Submission API, commit the edit
    ios         flutter build ipa, upload archive to App Store Connect
    tvos        xcodebuild archive tvos/, upload to App Store Connect
    asc         App Store Connect metadata: wait for builds, set What's New,
                attach builds to iOS + tvOS versions (submit with --submit)
    farm_wait   wait for the build workflow, download its artifacts
    release     generate appcast.xml, create the draft GitHub release
    msstore     submit the Store msixbundle via the Microsoft Store
                Submission API (replaces the manual Partner Center upload)
    publish     flip the GitHub release out of draft, update Casks/plezy.rb

State is checkpointed to build/deploy/state.json; a failed run resumes where
it stopped (`release` again, optionally with --only/--skip). `--dry-run`
prints every external action without performing any.

Credentials come from .env at the repository root (same file fastlane used):
    SUPPLY_JSON_KEY_DATA / SUPPLY_JSON_KEY   Play service-account JSON (data or path)
    SUPPLY_PACKAGE_NAME                      Android package name
    AMAZON_APPSTORE_CLIENT_ID / _CLIENT_SECRET / _PACKAGE_NAME
    DELIVER_APP_IDENTIFIER                   Apple bundle id
    ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_PATH
                                             App Store Connect team API key
                                             (.p8; replaces Apple-ID auth)
    APPLE_TEAM_ID                            optional, forwarded to xcodebuild
    MSSTORE_TENANT_ID / MSSTORE_CLIENT_ID / MSSTORE_CLIENT_SECRET
                                             Azure AD app linked to Partner Center
    MSSTORE_APP_ID                           Store application id (from the
                                             Partner Center product URL)
GitHub auth comes from the `gh` CLI login.

Amazon caveat: the "touch capabilities" / "offline capabilities" questions are
not exposed by the public App Submission API (verified against its OpenAPI
spec), so the amazon phase pauses for those two checkboxes before it commits
the edit. Everything else, including the submit, is automated.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
import re
import shlex
import shutil
import subprocess
import sys
import time
import zipfile
from dataclasses import dataclass, field
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SCRIPTS_DIR = SCRIPT_DIR.parent
ROOT = SCRIPTS_DIR.parent
sys.path.insert(0, str(SCRIPTS_DIR))

from pubspec_version import parse_pubspec_version  # noqa: E402

DEPLOY_DIR = ROOT / "build" / "deploy"
STATE_PATH = DEPLOY_DIR / "state.json"
NOTES_DIR = DEPLOY_DIR / "notes"
ARTIFACTS_DIR = DEPLOY_DIR / "artifacts"

REPO = "edde746/plezy"
GH_PAGES_NOTES_BASE = "https://gh-html.edde746.dev/edde746/plezy"

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
    "appstore": ("iOS", 4000),
    "play": ("Android", 500),
    "amazon": ("Android (Amazon Appstore: Fire TV and Fire tablets)", 4000),
}

AMAZON_API_BASE = "https://developer.amazon.com/api/appstore/v1/applications"
AMAZON_AUTH_URL = "https://api.amazon.com/auth/o2/token"
ASC_API_BASE = "https://api.appstoreconnect.apple.com/v1"
MSSTORE_API_BASE = "https://manage.devcenter.microsoft.com/v1.0/my/applications"


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


def bump_pubspec_text(text: str, new_version: str, new_build: int) -> str:
    """Replace the single top-level version line, validating both sides."""
    parse_pubspec_version(text)  # raises on malformed/missing version
    replacement = f"version: {new_version}+{new_build}"
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    replaced = False
    for line in lines:
        if not replaced and re.match(r"^version:[ \t]", line):
            newline = "\n" if line.endswith("\n") else ""
            out.append(replacement + newline)
            replaced = True
        else:
            out.append(line)
    if not replaced:
        raise DeployError("pubspec.yaml has no top-level version line")
    result = "".join(out)
    parse_pubspec_version(result)
    return result


def build_appcast(
    version: str,
    build_number: str,
    macos_signature: str = "",
    macos_size: str = "0",
    windows_signature: str = "",
    windows_size: str = "0",
) -> str:
    """Sparkle/WinSparkle appcast, byte-compatible with the old workflow step."""
    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">',
        "  <channel>",
        "    <title>Plezy Updates</title>",
        "    <item>",
        f"      <title>Version {version}</title>",
        f"      <sparkle:version>{build_number}</sparkle:version>",
        f"      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>",
        f"      <sparkle:releaseNotesLink>{GH_PAGES_NOTES_BASE}/{version}</sparkle:releaseNotesLink>",
    ]
    if macos_signature:
        lines += [
            f'      <enclosure url="https://github.com/{REPO}/releases/download/{version}/plezy-macos.dmg"',
            f'                 length="{macos_size}" type="application/octet-stream"',
            f'                 sparkle:edSignature="{macos_signature}"',
            '                 sparkle:os="macos" />',
        ]
    if windows_signature:
        lines += [
            f'      <enclosure url="https://github.com/{REPO}/releases/download/{version}/plezy-windows-installer.exe"',
            f'                 length="{windows_size}" type="application/octet-stream"',
            f'                 sparkle:edSignature="{windows_signature}"',
            '                 sparkle:installerArguments="/SILENT /SP-"',
            '                 sparkle:os="windows" />',
        ]
    lines += [
        "    </item>",
        "  </channel>",
        "</rss>",
        "",
    ]
    return "\n".join(lines)


def update_cask_text(text: str, version: str, sha256: str) -> str:
    """Update version and sha256 stanzas in Casks/plezy.rb."""
    new_text, n_version = re.subn(
        r'(?m)^(\s*version\s+")[^"]*(")', rf"\g<1>{version}\g<2>", text, count=1
    )
    if n_version != 1:
        raise DeployError("cask: version stanza not found")
    new_text, n_sha = re.subn(
        r'(?m)^(\s*sha256\s+")[^"]*(")', rf"\g<1>{sha256}\g<2>", new_text, count=1
    )
    if n_sha != 1:
        raise DeployError("cask: sha256 stanza not found")
    return new_text


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


def collect_release_files(artifacts_dir: Path) -> list[Path]:
    """Release asset list, mirroring the old create-release workflow job."""
    explicit = [
        "android-apk/plezy-android-arm64-v8a.tar.gz",
        "android-apk/plezy-android-armeabi-v7a.tar.gz",
        "android-apk/plezy-android-x86_64.tar.gz",
        "ios-ipa/plezy-ios.ipa",
        "macos-dmg/plezy-macos.dmg",
        "windows-x64-portable/plezy-windows-x64-portable.7z",
        "windows-arm64-portable/plezy-windows-arm64-portable.7z",
        "windows-installer/plezy-windows-installer.exe",
    ]
    files = [artifacts_dir / rel for rel in explicit]
    for arch_dir in ("linux-x64", "linux-arm64"):
        linux_dir = artifacts_dir / arch_dir
        if not linux_dir.is_dir():
            raise DeployError(f"missing artifact directory: {linux_dir}")
        entries = sorted(p for p in linux_dir.iterdir() if p.is_file())
        if not entries:
            raise DeployError(f"artifact directory is empty: {linux_dir}")
        files.extend(entries)
    missing = [str(p) for p in files if not p.is_file()]
    if missing:
        raise DeployError("missing release artifacts:\n  " + "\n  ".join(missing))
    return files


def read_artifact_text(artifacts_dir: Path, relative: str) -> str:
    path = artifacts_dir / relative
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8").strip()


def sanitize_msstore_pricing(submission: dict) -> None:
    """Make a cloned Store submission's pricing acceptable to PUT.

    The ingestion API echoes priceId "Base" for apps on the advanced pricing
    model but rejects it on PUT ("'Base' is not a valid PriceId"), while
    omitting the pricing node entirely is also an error. Dropping priceId and
    the read-only isAdvancedPricingModel flag keeps Partner Center pricing
    unchanged; the API re-resolves the real tier itself (verified 2.14.0).
    """
    pricing = submission.get("pricing")
    if isinstance(pricing, dict):
        pricing.pop("priceId", None)
        pricing.pop("isAdvancedPricingModel", None)


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
    cwd: Path = ROOT,
    env: dict[str, str] | None = None,
    check: bool = True,
    capture: bool = False,
    input_text: str | None = None,
    echo: bool = True,
) -> subprocess.CompletedProcess:
    if echo:
        print(f"    $ {shlex.join(cmd)}", flush=True)
    merged_env = {**os.environ, **(env or {})}
    result = subprocess.run(
        cmd,
        cwd=cwd,
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


def dry_guard(ctx: Context, description: str) -> bool:
    """True when the action must be skipped because of --dry-run."""
    if ctx.dry_run:
        log(f"[dry-run] would {description}")
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


def load_env_file() -> dict[str, str]:
    env_path = ROOT / ".env"
    if not env_path.is_file():
        raise DeployError(f".env not found at {env_path}")
    values = parse_env_text(env_path.read_text(encoding="utf-8"), dict(os.environ))
    # Pre-set environment wins, matching one-off `VAR=x uv run ...` overrides.
    for key, value in values.items():
        os.environ.setdefault(key, value)
    return dict(os.environ)


def git_output(args: list[str]) -> str:
    return run(["git", *args], capture=True, echo=False).stdout.strip()


def short_sha() -> str:
    return git_output(["rev-parse", "--short", "HEAD"])


# ---------------------------------------------------------------------------
# Phase: preflight
# ---------------------------------------------------------------------------


def phase_preflight(ctx: Context) -> None:
    # Requirements are checked only for phases that will actually run this
    # invocation; a resume after e.g. `changelog` must not re-demand --notes.
    pending = set(ctx.phases) - set(ctx.state.done)

    require_tool("git")
    branch = git_output(["branch", "--show-current"])
    if branch != "main":
        raise DeployError(f"releases run from main; current branch is {branch!r}")

    dirty = [
        line
        for line in git_output(["status", "--porcelain"]).splitlines()
        if line and not line.startswith("??")
    ]
    if dirty and "bump" in pending and not ctx.dry_run:
        raise DeployError(
            "tracked files have uncommitted changes; commit or stash before releasing:\n  "
            + "\n  ".join(dirty)
        )

    if not re.fullmatch(r"\d+\.\d+\.\d+", ctx.version):
        raise DeployError(f"version must be semver (e.g. 2.13.0); got {ctx.version!r}")

    tag_exists = bool(git_output(["tag", "-l", ctx.tag]))
    if tag_exists and {"bump", "release"} <= pending:
        raise DeployError(
            f"tag {ctx.tag} already exists; pick a new version, or drop the "
            "release phase for a store-only push that reuses it"
        )

    if pending & {"play", "amazon", "ios"}:
        require_tool("flutter")
    if pending & {"ios", "tvos"}:
        require_tool("xcodebuild", "Xcode command line tools")
    if pending & {"farm_start", "farm_wait", "release", "publish"}:
        require_tool("gh", "GitHub CLI")
        run(["gh", "auth", "status"], capture=True, echo=False)
    if "changelog" in pending and not ctx.dry_run:
        require_tool("claude", "used to generate per-channel changelogs")

    notes = getattr(ctx.args, "notes", None)
    if "changelog" in pending:
        if not notes:
            raise DeployError("changelog phase requires --notes <file>")
        if not Path(notes).is_file():
            raise DeployError(f"notes file not found: {notes}")

    env = ctx.env
    if "play" in pending:
        if not (env.get("SUPPLY_JSON_KEY_DATA") or env.get("SUPPLY_JSON_KEY")):
            raise DeployError("play: set SUPPLY_JSON_KEY_DATA or SUPPLY_JSON_KEY in .env")
        require_env(env, ["SUPPLY_PACKAGE_NAME"], "play")
    if "amazon" in pending:
        require_env(
            env,
            [
                "AMAZON_APPSTORE_CLIENT_ID",
                "AMAZON_APPSTORE_CLIENT_SECRET",
                "AMAZON_APPSTORE_PACKAGE_NAME",
            ],
            "amazon",
        )
    if pending & {"ios", "tvos", "asc"}:
        require_env(env, ["ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH"], "app store connect")
        require_env(env, ["DELIVER_APP_IDENTIFIER"], "app store connect")
        key_path = Path(env["ASC_KEY_PATH"]).expanduser()
        if not key_path.is_file():
            raise DeployError(f"ASC_KEY_PATH does not exist: {key_path}")
    if "msstore" in pending:
        require_env(
            env,
            ["MSSTORE_TENANT_ID", "MSSTORE_CLIENT_ID", "MSSTORE_CLIENT_SECRET", "MSSTORE_APP_ID"],
            "msstore",
        )

    log("preflight OK")


# ---------------------------------------------------------------------------
# Phase: changelog
# ---------------------------------------------------------------------------

CHANGELOG_PROMPT = (
    "Below is a changelog for a cross-platform Flutter app (iOS, Android, macOS, "
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
    for attempt in (1, 2, 3):
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
    notes_text = notes_file.read_text(encoding="utf-8")

    if dry_guard(ctx, f"generate channel notes from {notes_file} via claude"):
        return

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

    # Compatibility copies for the fastlane fallback until it is deleted.
    ios_meta = ROOT / "ios/fastlane/metadata/en-US/release_notes.txt"
    android_meta = (
        ROOT
        / "android/fastlane/metadata/android/en-GB/changelogs"
        / f"{ctx.build_number}.txt"
    )
    ios_meta.parent.mkdir(parents=True, exist_ok=True)
    android_meta.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(notes_path("appstore"), ios_meta)
    shutil.copyfile(notes_path("play"), android_meta)


# ---------------------------------------------------------------------------
# Phase: bump
# ---------------------------------------------------------------------------


def phase_bump(ctx: Context) -> None:
    """Bump pubspec and push main.

    Tagging deliberately happens at the release phase (via gh --target):
    a store-only push that reuses an already-tagged version must not
    collide with the existing tag.
    """
    pubspec = ROOT / "pubspec.yaml"
    text = pubspec.read_text(encoding="utf-8")
    current_full, _ = parse_pubspec_version(text)
    current_name = current_full.split("+", 1)[0]
    target_full = f"{ctx.version}+{ctx.build_number}"
    if current_full == target_full:
        log(f"bump: pubspec already at {target_full}")
    else:
        if dry_guard(ctx, f"bump pubspec {current_full} -> {target_full}, commit, push"):
            return
        pubspec.write_text(bump_pubspec_text(text, ctx.version, ctx.build_number), encoding="utf-8")
        if current_name == ctx.version:
            message = f"chore: bump build number to {ctx.build_number}"
        else:
            message = f"chore: bump version to {ctx.version}"
        # Pathspec commit: never sweeps unrelated staged work into the bump.
        run(["git", "commit", "-m", message, "--", "pubspec.yaml"])
    if dry_guard(ctx, "push main"):
        return
    run(["git", "push", "origin", "main"])
    ctx.state.data["release_sha"] = git_output(["rev-parse", "HEAD"])
    ctx.state.save()


# ---------------------------------------------------------------------------
# Phases: farm_start / farm_wait (GitHub Actions build farm)
# ---------------------------------------------------------------------------


def phase_farm_start(ctx: Context) -> None:
    if dry_guard(ctx, "trigger build.yml via gh workflow run and record the run id"):
        return
    head = ctx.state.data.get("release_sha") or git_output(["rev-parse", "HEAD"])
    run(["gh", "workflow", "run", "build.yml", "--ref", "main"])
    log("farm: waiting for the workflow run to appear")
    deadline = time.monotonic() + 180
    while time.monotonic() < deadline:
        time.sleep(10)
        result = run(
            [
                "gh", "run", "list",
                "--workflow", "build.yml",
                "--branch", "main",
                "--limit", "10",
                "--json", "databaseId,headSha,status,createdAt",
            ],
            capture=True,
            echo=False,
        )
        runs = json.loads(result.stdout or "[]")
        for entry in runs:
            if entry["headSha"] == head and entry["status"] != "completed":
                ctx.state.data["farm_run_id"] = entry["databaseId"]
                ctx.state.save()
                log(f"farm: run {entry['databaseId']} started")
                return
    raise DeployError("farm: build.yml run did not appear within 3 minutes")


def phase_farm_wait(ctx: Context) -> None:
    if dry_guard(ctx, "wait for the build.yml run and download all artifacts"):
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
    ARTIFACTS_DIR.mkdir(parents=True)
    run(["gh", "run", "download", str(run_id), "--dir", str(ARTIFACTS_DIR)])
    log(f"farm: artifacts downloaded to {ARTIFACTS_DIR}")


# ---------------------------------------------------------------------------
# Phase: play
# ---------------------------------------------------------------------------


def phase_play(ctx: Context) -> None:
    package = ctx.env["SUPPLY_PACKAGE_NAME"]
    aab = ROOT / "build/app/outputs/bundle/release/app-release.aab"
    if dry_guard(ctx, f"build AAB, upload symbols, publish {package} to Play production"):
        return

    commit = short_sha()
    run([
        "flutter", "build", "appbundle",
        "--dart-define=ENABLE_SENTRY=true",
        f"--dart-define=GIT_COMMIT={commit}",
        "--dart-define=SENTRY_ENVIRONMENT=play-store",
        "--dart-define=SENTRY_DIST=play-store",
        "--obfuscate",
        "--split-debug-info=debug-info/android-aab",
        "--extra-gen-snapshot-options=--save-obfuscation-map=debug-info/android-aab/obfuscation.map.json",
    ])
    run(
        [str(SCRIPTS_DIR / "upload-symbols.sh"), "android-aab"],
        env={"SENTRY_DIST": "play-store"},
    )
    if not aab.is_file():
        raise DeployError(f"play: AAB not found at {aab}")

    from google.oauth2 import service_account  # noqa: PLC0415
    from googleapiclient.discovery import build as gapi_build  # noqa: PLC0415
    from googleapiclient.http import MediaFileUpload  # noqa: PLC0415

    if ctx.env.get("SUPPLY_JSON_KEY_DATA"):
        info = json.loads(ctx.env["SUPPLY_JSON_KEY_DATA"])
    else:
        info = json.loads(Path(ctx.env["SUPPLY_JSON_KEY"]).read_text(encoding="utf-8"))
    credentials = service_account.Credentials.from_service_account_info(
        info, scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    publisher = gapi_build("androidpublisher", "v3", credentials=credentials, cache_discovery=False)
    edits = publisher.edits()

    edit_id = edits.insert(packageName=package, body={}).execute()["id"]
    log(f"play: created edit {edit_id}")
    uploaded = (
        edits.bundles()
        .upload(
            packageName=package,
            editId=edit_id,
            media_body=MediaFileUpload(str(aab), mimetype="application/octet-stream", resumable=True),
        )
        .execute()
    )
    version_code = uploaded["versionCode"]
    if version_code != ctx.build_number:
        raise DeployError(
            f"play: uploaded versionCode {version_code} != expected {ctx.build_number}"
        )
    release_notes = notes_path("play").read_text(encoding="utf-8").strip()
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
    ).execute()
    from googleapiclient.errors import HttpError  # noqa: PLC0415

    def requires_manual_review_send(error: Exception) -> bool:
        return "changesNotSentForReview" in str(error)

    try:
        edits.validate(packageName=package, editId=edit_id).execute()
    except HttpError as error:
        if not requires_manual_review_send(error):
            raise
        log("play: validate blocked; this app state requires a manual review send")
    try:
        edits.commit(packageName=package, editId=edit_id).execute()
        log(f"play: committed edit for versionCode {version_code} (sent for review)")
    except HttpError as error:
        if not requires_manual_review_send(error):
            raise
        edits.commit(
            packageName=package, editId=edit_id, changesNotSentForReview=True
        ).execute()
        log(
            f"play: committed edit for versionCode {version_code} WITHOUT sending "
            "for review (Play refused automatic submission for this app's current "
            "state); open the Play Console and press 'Send for review'"
        )


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
    package = ctx.env["AMAZON_APPSTORE_PACKAGE_NAME"]
    apk = ROOT / "build/app/outputs/flutter-apk/app-release.apk"
    if dry_guard(ctx, f"build Amazon APK, replace binary in an edit for {package}, commit"):
        return
    pending_edit_id = ctx.state.data.get("amazon_pending_edit_id")
    if pending_edit_id:
        log(f"amazon: resuming pending edit {pending_edit_id} without replacing its APK")
        client = AmazonClient(package, _amazon_token(ctx.env))
        _commit_amazon_edit(ctx, client, str(pending_edit_id))
        return


    commit = short_sha()
    run(
        [
            "flutter", "build", "apk", "--release",
            "--dart-define=ENABLE_SENTRY=true",
            f"--dart-define=GIT_COMMIT={commit}",
            "--dart-define=SENTRY_ENVIRONMENT=amazon",
            "--dart-define=SENTRY_DIST=amazon",
            "--obfuscate",
            "--split-debug-info=debug-info/android-apk",
            "--extra-gen-snapshot-options=--save-obfuscation-map=debug-info/android-apk/obfuscation.map.json",
        ],
        env={"AMAZON": "1"},
    )
    run(
        [str(SCRIPTS_DIR / "upload-symbols.sh"), "android-apk"],
        env={"SENTRY_DIST": "amazon"},
    )
    if not apk.is_file():
        raise DeployError(f"amazon: APK not found at {apk}")

    client = AmazonClient(package, _amazon_token(ctx.env))

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
    log("amazon: uploading APK (replace, preserves device targeting)")
    replaced = client.request(
        "PUT",
        f"/edits/{edit_id}/apks/{apk_id}/replace",
        headers={"Content-Type": "application/octet-stream", "If-Match": etag},
        data=apk.read_bytes(),
    ).json()
    log(f"amazon: uploaded versionCode {replaced.get('versionCode')}")

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
# Phases: ios / tvos (build + upload to App Store Connect)
# ---------------------------------------------------------------------------


def _asc_auth_args(env: dict[str, str]) -> list[str]:
    return [
        "-allowProvisioningUpdates",
        "-authenticationKeyPath", str(Path(env["ASC_KEY_PATH"]).expanduser().resolve()),
        "-authenticationKeyID", env["ASC_KEY_ID"],
        "-authenticationKeyIssuerID", env["ASC_ISSUER_ID"],
    ]


def _upload_archive(ctx: Context, archive: Path, label: str) -> None:
    """Upload an .xcarchive to App Store Connect via xcodebuild -exportArchive."""
    if not archive.is_dir():
        raise DeployError(f"{label}: archive not found at {archive}")
    options: dict[str, object] = {
        "method": "app-store-connect",
        "destination": "upload",
        "signingStyle": "automatic",
        "manageAppVersionAndBuildNumber": False,
    }
    if ctx.env.get("APPLE_TEAM_ID"):
        options["teamID"] = ctx.env["APPLE_TEAM_ID"]
    plist_path = DEPLOY_DIR / f"export-options-{label}.plist"
    plist_path.parent.mkdir(parents=True, exist_ok=True)
    plist_path.write_bytes(plistlib.dumps(options))
    run([
        "xcodebuild", "-exportArchive",
        "-archivePath", str(archive),
        "-exportOptionsPlist", str(plist_path),
        "-exportPath", str(DEPLOY_DIR / f"export-{label}"),
        *_asc_auth_args(ctx.env),
    ])
    log(f"{label}: uploaded to App Store Connect")


def phase_ios(ctx: Context) -> None:
    if dry_guard(ctx, "flutter build ipa, upload symbols, upload archive to ASC"):
        return
    commit = short_sha()
    run([
        "flutter", "build", "ipa",
        "--dart-define=ENABLE_SENTRY=true",
        f"--dart-define=GIT_COMMIT={commit}",
        "--dart-define=SENTRY_ENVIRONMENT=app-store",
        "--dart-define=SENTRY_DIST=app-store",
        "--split-debug-info=debug-info/ios",
    ])
    run(
        [str(SCRIPTS_DIR / "upload-symbols.sh"), "ios"],
        env={"SENTRY_DIST": "app-store"},
    )
    _upload_archive(ctx, ROOT / "build/ios/archive/Runner.xcarchive", "ios")


def phase_tvos(ctx: Context) -> None:
    if dry_guard(ctx, "xcodebuild archive tvos/Runner.xcworkspace, upload archive to ASC"):
        return
    archive = ROOT / "build/tvos/Runner.xcarchive"
    run([
        "xcodebuild",
        "-workspace", str(ROOT / "tvos/Runner.xcworkspace"),
        "-scheme", "Runner",
        "-configuration", "Release",
        "-destination", "generic/platform=tvOS",
        "-archivePath", str(archive),
        "archive",
        *_asc_auth_args(ctx.env),
    ])
    _upload_archive(ctx, archive, "tvos")


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
    if dry_guard(ctx, f"wait for builds and update ASC metadata for {', '.join(platforms)}"):
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
    if dry_guard(ctx, "generate appcast.xml and create the draft GitHub release"):
        return
    if not ARTIFACTS_DIR.is_dir():
        raise DeployError("release: no downloaded artifacts; run farm_wait first")

    appcast = build_appcast(
        ctx.version,
        str(ctx.build_number),
        macos_signature=read_artifact_text(ARTIFACTS_DIR, "macos-dmg/macos-ed-signature.txt"),
        macos_size=read_artifact_text(ARTIFACTS_DIR, "macos-dmg/macos-dmg-size.txt") or "0",
        windows_signature=read_artifact_text(ARTIFACTS_DIR, "windows-installer/win-ed-signature.txt"),
        windows_size=read_artifact_text(ARTIFACTS_DIR, "windows-installer/win-installer-size.txt") or "0",
    )
    appcast_path = DEPLOY_DIR / "appcast.xml"
    appcast_path.write_text(appcast, encoding="utf-8")

    files = [*collect_release_files(ARTIFACTS_DIR), appcast_path]
    file_args = [str(p) for p in files]

    exists = (
        run(["gh", "release", "view", ctx.tag], capture=True, check=False, echo=False).returncode
        == 0
    )
    if exists:
        log(f"release: {ctx.tag} already exists; re-uploading assets with --clobber")
        run(["gh", "release", "upload", ctx.tag, "--clobber", *file_args])
    else:
        body = notes_path("github")
        create = ["gh", "release", "create", ctx.tag, "--draft", "--title", ctx.version]
        target = ctx.state.data.get("release_sha")
        if target:
            create += ["--target", target]
        if body.is_file():
            create += ["--notes-file", str(body)]
        else:
            create += ["--generate-notes"]
        run([*create, *file_args])
        log(f"release: draft created for {ctx.tag} with {len(files)} assets")


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
    if dry_guard(ctx, "create a Store submission, upload the msixbundle, commit it"):
        return
    bundle = ARTIFACTS_DIR / "windows-msix/plezy-windows.msixbundle"
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
    sanitize_msstore_pricing(submission)

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

    api("PUT", f"/submissions/{submission_id}", json=submission)
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
    if dry_guard(ctx, "publish the GitHub release and update Casks/plezy.rb"):
        return
    if not ctx.confirm(f"Publish GitHub release {ctx.tag} (removes draft) and update the cask?"):
        log("publish: skipped; rerun with --only publish when ready")
        raise PhaseDeferred

    run(["gh", "release", "edit", ctx.tag, "--draft=false"])
    log(f"publish: release {ctx.tag} is live")

    dmg = ARTIFACTS_DIR / "macos-dmg/plezy-macos.dmg"
    if not dmg.is_file():
        raise DeployError(f"publish: DMG not found at {dmg}; cask not updated")
    digest = hashlib.sha256(dmg.read_bytes()).hexdigest()
    cask = ROOT / "Casks/plezy.rb"
    cask.write_text(
        update_cask_text(cask.read_text(encoding="utf-8"), ctx.version, digest),
        encoding="utf-8",
    )
    run(["git", "add", str(cask)])
    if run(["git", "diff", "--cached", "--quiet"], check=False, echo=False).returncode != 0:
        run(["git", "commit", "-m", f"chore: update cask to {ctx.version}"])
        run(["git", "push", "origin", "main"])
        log("publish: cask updated and pushed")
    else:
        log("publish: cask already up to date")


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
    print(f"\nRelease {ctx.version}+{ctx.build_number} summary")
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
        log(f"resuming release {state.version}+{state.build_number} "
            f"(done: {', '.join(state.done) or 'nothing'})")
        return state
    if not args.version:
        raise DeployError("--version is required for a new release")
    _, current_build = parse_pubspec_version((ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
    build_number = args.build_number or int(current_build) + 1
    state = State(version=args.version, build_number=build_number)
    if not getattr(args, "dry_run", False):
        state.save()
    return state


def cmd_release(args: argparse.Namespace) -> int:
    env = load_env_file()
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
    _, current_build = parse_pubspec_version((ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
    state = State.load() or State(version="unreleased", build_number=int(current_build) + 1)
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
    print(f"release {state.version}+{state.build_number}")
    for phase in PHASES:
        marker = "x" if phase in state.done else " "
        print(f"  [{marker}] {phase}")
    if state.data:
        print(json.dumps(state.data, indent=2))
    return 0


def cmd_clean(_args: argparse.Namespace) -> int:
    subprocess.run(["./gradlew", "clean"], cwd=ROOT / "android", check=False)
    subprocess.run(
        ["xcodebuild", "clean", "-workspace", "Runner.xcworkspace", "-scheme", "Runner"],
        cwd=ROOT / "ios",
        check=False,
    )
    subprocess.run(["flutter", "clean"], cwd=ROOT, check=False)
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
    release.add_argument("--version", help="semver for a new release (e.g. 2.13.0)")
    release.add_argument("--notes", help="path to the raw release notes file")
    release.add_argument("--build-number", type=int,
                         help="use this build number instead of pubspec+1 "
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

    clean = sub.add_parser("clean", help="clean build artifacts (gradle, xcode, flutter)")
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
