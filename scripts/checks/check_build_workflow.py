#!/usr/bin/env python3
"""Guard the architecture matrices and release contract in build.yml."""

from pathlib import Path
import re
import sys

from workflow_yaml import iter_uses_references, job_block


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_WORKFLOW = ROOT / ".github/workflows/build.yml"
FLUTTER_VERSION = "3.47.1"
FLUTTER_COMMIT = "6655482ec06e547f90abf8ae7590466f4415978d"
if len(sys.argv) > 2:
    raise SystemExit(f"Usage: {Path(sys.argv[0]).name} [workflow-path]")
WORKFLOW = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else DEFAULT_WORKFLOW
# Resolve the shared bootstrap beside the workflow so fixture checks use their
# local action rather than the checkout's real action.
SETUP_FLUTTER_GIT = WORKFLOW.parents[1] / "actions/setup-flutter-git/action.yml"
text = WORKFLOW.read_text(encoding="utf-8")
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def job(name: str) -> str:
    block = job_block(text, name)
    require(bool(block), f"missing {name} job")
    return block


def named_step(block: str, name: str) -> str:
    match = re.search(
        rf"(?ms)^      - name: {re.escape(name)}\n.*?(?=^      - |\Z)",
        block,
    )
    require(match is not None, f"missing '{name}' step")
    return match.group(0) if match else ""


def validate_windows_signing(block: str) -> None:
    install = named_step(block, "Install dependencies")
    signing = named_step(block, "Sign installer for WinSparkle (EdDSA)")
    require(
        block.find("      - name: Install dependencies")
        < block.find("      - name: Sign installer for WinSparkle (EdDSA)"),
        "locked root dependencies must be installed before Windows signing",
    )
    require(
        "flutter pub get --enforce-lockfile --no-example" in install,
        "Windows signing must use the enforced root dependency lock",
    )
    require(
        "dart run auto_updater:sign_update plezy-windows-installer.exe $keyPath"
        in signing,
        "Windows signing must execute the locked auto_updater package",
    )
    require(
        "$env:RUNNER_TEMP" in signing,
        "Windows signing key must live under RUNNER_TEMP",
    )
    require(
        "try {" in signing and "} finally {" in signing,
        "Windows signing key cleanup must run from a finally block",
    )
    require(
        "Remove-Item -Path $keyPath -Force -ErrorAction SilentlyContinue"
        in signing,
        "Windows signing must remove its temporary key",
    )
    lowered = signing.lower()
    for forbidden in (
        "raw.githubusercontent.com",
        "invoke-webrequest",
        "git clone",
        "_signer",
        "pubspec.yaml",
        "dart pub get",
    ):
        require(
            forbidden not in lowered,
            f"Windows signing step contains mutable or ad-hoc input: {forbidden}",
        )


def require_explicit_shells(name: str, block: str, shell: str) -> None:
    steps = re.findall(r"(?ms)^      - .*?(?=^      - |\Z)", block)
    run_steps = [step for step in steps if re.search(r"(?m)^        run:", step)]
    require(bool(run_steps), f"{name} must contain run steps")
    for step in run_steps:
        step_name = re.search(r"(?m)^      - name: (.+)$", step)
        label = step_name.group(1) if step_name else "unnamed step"
        require(
            f"        shell: {shell}\n" in step,
            f"{name} step '{label}' must explicitly use {shell}",
        )


for legacy_job in (
    "build-windows-x64",
    "build-windows-arm64",
    "build-linux-x64",
    "build-linux-arm64",
):
    require(f"  {legacy_job}:\n" not in text, f"legacy job {legacy_job} must stay removed")

windows = job("build-windows")
require("runs-on: ${{ matrix.runner }}" in windows, "Windows must use its matrix runner")
require("fail-fast: false" in windows, "Windows matrix must not cancel its other architecture")
require(
    re.search(
        r"(?ms)          - arch: x64\n"
        r"            runner: windows-latest\n"
        r"            flutter_setup: action\n"
        r"            native_cache_path: build/windows/x64/_deps\n",
        windows,
    )
    is not None,
    "Windows x64 matrix configuration changed",
)
require(
    re.search(
        r"(?ms)          - arch: arm64\n"
        r"            runner: windows-11-arm\n"
        r"            flutter_setup: git\n"
        r"            native_cache_path: build/windows/arm64/_deps\n",
        windows,
    )
    is not None,
    "Windows arm64 matrix configuration changed",
)
for expected in (
    "if: matrix.flutter_setup == 'action'",
    "if: matrix.flutter_setup == 'git'",
    "uses: ./.github/actions/setup-flutter-git",
    "flutter pub get --enforce-lockfile --no-example",
    "--dart-define=SENTRY_DIST=github-windows-${{ matrix.arch }}",
    "--split-debug-info=debug-info/windows-${{ matrix.arch }}",
    "name: windows-${{ matrix.arch }}-build",
    "path: build/windows/${{ matrix.arch }}/runner/Release/",
):
    require(expected in windows, f"Windows matrix missing: {expected}")
# libmpv comes from our mpv-build release zips via FetchContent for both
# arches (no 7-Zip, no unpinned sourceforge download); the checksums must
# stay enforced.
require(
    "URL_HASH SHA256=${MPV_SHA256}" in (ROOT / "windows/CMakeLists.txt").read_text(encoding="utf-8"),
    "Windows libmpv fetch must keep URL_HASH enforcement",
)
require(
    "sourceforge" not in (ROOT / "windows/CMakeLists.txt").read_text(encoding="utf-8"),
    "Windows libmpv fetch must not regress to the unpinned sourceforge download",
)
require(
    re.search(
        r"(?ms)^    permissions:\n      contents: read\n    strategy:", windows
    )
    is not None,
    "Windows build permissions must remain contents: read",
)
require_explicit_shells("build-windows", windows, "pwsh")

setup_flutter_git = (
    SETUP_FLUTTER_GIT.read_text(encoding="utf-8") if SETUP_FLUTTER_GIT.is_file() else ""
)
require(bool(setup_flutter_git), "missing .github/actions/setup-flutter-git/action.yml")
for expected in (
    f'$version = "{FLUTTER_VERSION}"',
    f'$expectedCommit = "{FLUTTER_COMMIT}"',
    # Fetch and verify the release tag so moved tags cannot change the SDK.
    'git -C $root fetch --depth 1 origin "refs/tags/${version}:refs/tags/${version}"',
    'git -C $root checkout --detach "refs/tags/$version"',
    "$actualCommit = git -C $root rev-parse HEAD",
    "$actualCommit -ne $expectedCommit",
    r'$versionOutput = & "$root\bin\flutter.bat" --version --machine',
    "$reportedVersion -ne $version",
):
    require(
        expected in setup_flutter_git,
        f"shared Flutter bootstrap must keep its verified pin: {expected}",
    )

linux = job("build-linux")
require("runs-on: ${{ matrix.runner }}" in linux, "Linux must use its matrix runner")
require("fail-fast: false" in linux, "Linux matrix must not cancel its other architecture")
require(
    re.search(
        r"(?ms)          - arch: x64\n"
        r"            runner: ubuntu-latest\n"
        r"            flutter_channel: stable\n"
        r"            pkg_config_arch: x86_64-linux-gnu\n",
        linux,
    )
    is not None,
    "Linux x64 matrix configuration changed",
)
require(
    re.search(
        r"(?ms)          - arch: arm64\n"
        r"            runner: ubuntu-24.04-arm\n"
        r"            flutter_channel: master\n"
        r"            pkg_config_arch: aarch64-linux-gnu\n",
        linux,
    )
    is not None,
    "Linux arm64 matrix configuration changed",
)
for expected in (
    "channel: ${{ matrix.flutter_channel }}",
    "flutter-version: ${{ env.FLUTTER_VERSION }}",
    "flutter pub get --enforce-lockfile --no-example",
    "lib/${{ matrix.pkg_config_arch }}/pkgconfig",
    "--dart-define=SENTRY_DIST=github-linux-${{ matrix.arch }}",
    "--split-debug-info=debug-info/linux-${{ matrix.arch }}",
    "BUILD_DIR=\"$BUNDLE_DIR\"",
    "ARCH_SUFFIX=${{ matrix.arch }}",
    "name: linux-${{ matrix.arch }}",
):
    require(expected in linux, f"Linux matrix missing: {expected}")
require(
    re.search(
        r"(?ms)^    permissions:\n"
        r"      id-token: write\n"
        r"      attestations: write\n"
        r"      contents: read\n"
        r"    strategy:",
        linux,
    )
    is not None,
    "Linux build attestation permissions changed",
)
require_explicit_shells("build-linux", linux, "bash")
libmpv_cache = named_step(linux, "Cache libmpv prefix")
require(
    "hashFiles('mpv-build.lock.json')" in libmpv_cache,
    "libmpv cache identity must include the mpv-build lock",
)


package_windows = job("package-windows")
validate_windows_signing(package_windows)
require("needs: build-windows" in package_windows, "Windows packaging must fan in the matrix")
for artifact in (
    "windows-x64-build",
    "windows-arm64-build",
    "windows-x64-portable",
    "windows-arm64-portable",
    "windows-installer",
):
    require(f"name: {artifact}" in package_windows, f"Windows packaging lost {artifact}")

require(
    re.search(
        r"(?ms)^  workflow_dispatch:\n    inputs:\n      release_tag:\n"
        r".*?        default: ''\n        type: string\n",
        text,
    )
    is not None,
    "build workflow must expose an optional release_tag input",
)


require(
    "run-name: ${{ inputs.release_tag != '' && format('Release {0}', inputs.release_tag)"
    in text,
    "release workflow runs must expose their tag in the run name",
)

release = job("create-release")
require(
    "needs: [validate-trusted-ref, build-android, build-ios, build-macos, build-windows, package-windows, build-linux]"
    in release,
    "release dependencies must include the trust gate, both architecture matrices, and Windows packaging",
)
for artifact in (
    "android-apk",
    "ios-ipa",
    "macos-dmg",
    "windows-x64-portable",
    "windows-arm64-portable",
    "windows-installer",
    "linux-x64",
    "linux-arm64",
):
    require(f"name: {artifact}" in release, f"release download lost {artifact}")

release_if = re.search(r"(?m)^    if: (.+)$", release)
require(release_if is not None, "release job must have an explicit condition")
release_condition = release_if.group(1) if release_if else ""
for build_input in (
    "build_android",
    "build_ios",
    "build_macos",
    "build_windows",
    "build_linux",
):
    require(
        f"&& inputs.{build_input}" in release_condition,
        f"release publication must require {build_input}",
    )
require(
    "&& inputs.release_tag != ''" in release_condition,
    "draft release creation must require an explicit release tag",
)


require("draft: true" in release, "build output must remain a draft release")
require(
    "tag_name: ${{ inputs.release_tag }}" in release,
    "release builds must bind the requested tag",
)
require(
    "target_commitish: ${{ github.sha }}" in release,
    "release tags must target the exact build commit",
)
require(
    "if: ${{ inputs.release_tag != '' }}" in release
    and '"$RELEASE_TAG" != "$VERSION"' in release,
    "release tags must be validated against the pubspec version",
)
require(
    "generate_release_notes:" not in release,
    "draft releases must not generate notes before deploy.py attaches channel notes",
)

trusted_ref = job("validate-trusted-ref")
require("permissions: {}" in trusted_ref, "trusted-ref validation must have no token permissions")
require(
    '"$GITHUB_REF" != "refs/heads/main"' in trusted_ref,
    "trusted-ref validation must reject non-main refs",
)
for protected_job in (
    "build-android",
    "build-ios",
    "build-macos",
    "build-windows",
    "build-linux",
):
    require(
        "needs: validate-trusted-ref" in job(protected_job),
        f"{protected_job} must depend on trusted-ref validation",
    )

require(
    text.count(FLUTTER_VERSION) == 1 and f'FLUTTER_VERSION: "{FLUTTER_VERSION}"' in text,
    "the Flutter SDK version must be written once, as the workflow FLUTTER_VERSION env",
)
require(
    "TRUSTED_BUILD_CACHE_VERSION: trusted-build-v1" in text,
    "build caches must use a dedicated trusted namespace",
)
require("restore-keys:" not in text, "privileged build caches must not use prefix fallback")
cache_keys = re.findall(r"(?m)^          key: (.+)$", text)
require(bool(cache_keys), "build workflow must define cache keys")
for cache_key in cache_keys:
    require(
        "TRUSTED_BUILD_CACHE_VERSION" in cache_key,
        f"cache key is outside the trusted build namespace: {cache_key}",
    )
require(
    text.count("cache-key:") == text.count("cache: true"),
    "every Flutter SDK cache must define its trusted cache key",
)

# Action-pin checks run elsewhere; this guard adds the checkout credential
# invariant for the workflow-dispatch-only build.
remote_actions = [
    reference.rpartition("@")[0]
    for _, reference in iter_uses_references(text)
    if not reference.startswith("./")
]
require(bool(remote_actions), "build workflow must use pinned actions")
require(
    text.count("persist-credentials: false") == remote_actions.count("actions/checkout"),
    "every build checkout must discard GitHub credentials",
)

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print("build workflow architecture matrix checks passed")
