#!/usr/bin/env python3
"""Guard the architecture matrices and release contract in build.yml."""

from pathlib import Path
import re
import sys


WORKFLOW = Path(__file__).resolve().parents[1] / ".github/workflows/build.yml"
text = WORKFLOW.read_text(encoding="utf-8")
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def job(name: str) -> str:
    match = re.search(
        rf"(?ms)^  {re.escape(name)}:\n(.*?)(?=^  [a-zA-Z0-9_-]+:\n|\Z)", text
    )
    require(match is not None, f"missing {name} job")
    return match.group(0) if match else ""


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
        r"            native_cache_path: \|\n"
        r"              build/windows/arm64/_deps\n"
        r"              build/windows/arm64/mpv-dev-arm64\n",
        windows,
    )
    is not None,
    "Windows arm64 matrix configuration changed",
)
for expected in (
    "if: matrix.flutter_setup == 'action'",
    "if: matrix.flutter_setup == 'git'",
    "git -C $root fetch --depth 1 origin 559ffa3f75e7402d65a8def9c28389a9b2e6fe42",
    "flutter pub get --enforce-lockfile --no-example",
    "--dart-define=SENTRY_DIST=github-windows-${{ matrix.arch }}",
    "--split-debug-info=debug-info/windows-${{ matrix.arch }}",
    "name: windows-${{ matrix.arch }}-build",
    "path: build/windows/${{ matrix.arch }}/runner/Release/",
):
    require(expected in windows, f"Windows matrix missing: {expected}")
require(
    "if: matrix.arch == 'arm64' && steps.windows-native-cache.outputs.cache-hit != 'true'"
    in windows,
    "7-Zip installation must remain ARM-only and cache-aware",
)
require(
    re.search(
        r"(?ms)^    permissions:\n      contents: read\n    strategy:", windows
    )
    is not None,
    "Windows build permissions must remain contents: read",
)
require_explicit_shells("build-windows", windows, "pwsh")

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
    'flutter-version: "3.44.0"',
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

package_windows = job("package-windows")
require("needs: build-windows" in package_windows, "Windows packaging must fan in the matrix")
for artifact in (
    "windows-x64-build",
    "windows-arm64-build",
    "windows-x64-portable",
    "windows-arm64-portable",
    "windows-installer",
):
    require(f"name: {artifact}" in package_windows, f"Windows packaging lost {artifact}")

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

require("draft: true" in release, "build output must remain a draft release")
require("tag_name:" not in release, "build output must not bind a release tag")
require(
    "generate_release_notes:" not in release,
    "untagged draft releases must not request generated release notes",
)
require(
    "Refuse to overwrite a published release" not in release,
    "untagged draft creation must not inspect or block on published releases",
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

action_refs = re.findall(r"(?m)^\s*(?:-\s+)?uses:\s+([^\s@]+)@([^\s#]+)", text)
require(bool(action_refs), "build workflow must use pinned actions")
for action, ref in action_refs:
    require(
        re.fullmatch(r"[0-9a-f]{40}", ref) is not None,
        f"action {action} must be pinned to a full commit SHA",
    )

checkout_count = sum(action == "actions/checkout" for action, _ in action_refs)
require(
    text.count("persist-credentials: false") == checkout_count,
    "every build checkout must discard GitHub credentials",
)
require(
    "raw.githubusercontent.com/edde746/auto_updater/9e150f71e17495b7361aedbe6df22e89ad52c254/"
    in text,
    "Windows signing helper must remain pinned to the locked auto_updater commit",
)
require(
    'dependencies=@{cryptography="2.9.0"}' in text,
    "Windows signing dependency must remain exact",
)

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print("build workflow architecture matrix checks passed")
