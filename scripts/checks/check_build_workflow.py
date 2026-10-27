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
# Resolve the shared bootstrap and the Windows CMake file beside the workflow
# so fixture checks use their local copies rather than the checkout's real ones.
SETUP_FLUTTER_GIT = WORKFLOW.parents[1] / "actions/setup-flutter-git/action.yml"
WINDOWS_CMAKE = WORKFLOW.parents[2] / "windows/CMakeLists.txt"
WEBOS_CANDIDATE_BUILDER = ROOT / "tools/webos/build_release_candidate.sh"
WEBOS_IPK_BUILDER = ROOT / "tools/webos/build_ipk.sh"
WEBOS_RELEASE_GATE = ROOT / "tools/webos/check_release_eligibility.py"
text = WORKFLOW.read_text(encoding="utf-8")
CI_WORKFLOW = ROOT / ".github/workflows/ci.yml"
ci_text = CI_WORKFLOW.read_text(encoding="utf-8") if CI_WORKFLOW.is_file() else ""
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
require(
    '"group":"packer-windows"' in windows
    and '"Windows","X64"' in windows
    and '"PlezyNG"' in windows,
    "Windows x64 must use the private Packer JIT route",
)
require(
    '"group":"packer-windows"' in windows
    and '"Windows","ARM64"' in windows
    and '"ng-shared-main-plezyng"' in windows
    and "matrix.arch == 'x64'" in windows,
    "Windows ARM64 must use its private JIT route",
)
require("fail-fast: false" in windows, "Windows matrix must not cancel its other architecture")
require(
    re.search(
        r"(?ms)          - arch: x64\n"
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
    "--split-debug-info=debug-info/windows-${{ matrix.arch }}",
    "name: windows-${{ matrix.arch }}-build",
    "path: build/windows/${{ matrix.arch }}/runner/Release/",
):
    require(expected in windows, f"Windows matrix missing: {expected}")
# libmpv comes from our mpv-build release zips via FetchContent for both
# arches (no 7-Zip, no unpinned sourceforge download); the asset name and
# checksum must be read from mpv-build.lock.json, never pinned by hand, and
# the checksum must stay enforced.
windows_cmake = WINDOWS_CMAKE.read_text(encoding="utf-8") if WINDOWS_CMAKE.is_file() else ""
require(bool(windows_cmake), "missing windows/CMakeLists.txt")
windows_mpv_block = windows_cmake.split("FetchContent_MakeAvailable(mpv_dev)", 1)[0]
require(
    "URL_HASH SHA256=${MPV_SHA256}" in windows_mpv_block,
    "Windows libmpv fetch must keep URL_HASH enforcement",
)
require(
    "string(JSON MPV_SHA256 GET " in windows_mpv_block
    and re.search(r"[0-9a-f]{64}", windows_mpv_block) is None,
    "Windows libmpv checksum must come from mpv-build.lock.json, not a literal",
)
require(
    "sourceforge" not in windows_cmake,
    "Windows libmpv fetch must not regress to the unpinned sourceforge download",
)
windows_native_cache = named_step(windows, "Cache Windows native dependencies")
require(
    "hashFiles('windows/CMakeLists.txt', 'mpv-build.lock.json')" in windows_native_cache,
    "Windows native cache identity must include the mpv-build lock",
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
require(
    '"group":"ng-shared-main-jit"' in linux
    and "ng-shared-main-plezyng" in linux
    and '"linux","x64"' in linux
    and '"linux","arm64"' in linux
    and "matrix.arch == 'x64'" in linux
    and '"gha-{0}-{1}-build-linux"' in linux,
    "Linux architectures must use the private JIT route",
)
require("fail-fast: false" in linux, "Linux matrix must not cancel its other architecture")
require(
    re.search(
        r"(?ms)          - arch: x64\n"
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
require(
    "python3 scripts/fetch_linux_libmpv.py" in named_step(linux, "Fetch libmpv"),
    "Linux libmpv fetch must go through scripts/fetch_linux_libmpv.py",
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

release_tag_input = re.search(
    r"(?ms)^      release_tag:\n(?P<body>.*?)(?=^      [A-Za-z0-9_-]+:\n|^env:\n)",
    text,
)
require(
    release_tag_input is not None
    and re.search(r"(?m)^        required: false$", release_tag_input.group("body")) is not None
    and re.search(r"(?m)^        type: string$", release_tag_input.group("body")) is not None,
    "workflow must expose a release_tag input, validated in full-platform mode",
)
require(
    re.search(
        r"(?ms)^      mode:\n.*?        required: true\n"
        r"        type: choice\n.*?          - release\n"
        r"          - webos-validation\n",
        text,
    )
    is not None,
    "manual workflow must expose required release and webOS validation modes",
)
require(
    re.search(
        r"(?ms)^      include_webos_release:\n.*?        type: boolean\n"
        r"        default: false\n",
        text,
    )
    is not None,
    "public WebOS release inclusion must be an explicit opt-in",
)
require(
    "Validate release tag before building" in job("validate-trusted-ref")
    and "steps.request.outputs.mode == 'release'" in job("validate-trusted-ref")
    and "RELEASE_TAG: ${{ steps.request.outputs.release_tag }}" in job("validate-trusted-ref")
    and '"$VERSION" != "$PACKAGE_VERSION"' in job("validate-trusted-ref")
    and '"$RELEASE_TAG" != "v$PACKAGE_VERSION"' in job("validate-trusted-ref"),
    "release mode must validate the requested version and pushed v-tag before building",
)
build_webos = job("build-webos")
require(
    "needs.validate-trusted-ref.outputs.mode == 'webos-validation'" in build_webos
    and "needs.validate-trusted-ref.outputs.mode == 'release' && needs.validate-trusted-ref.outputs.include_webos_release == 'true'" in build_webos
    and "bash tools/webos/build_release_candidate.sh" in build_webos,
    "webOS builds must be validation-only or explicitly included in a full release",
)
require(
    "python3 -m unittest discover -s tools/webos/tests -v"
    in named_step(build_webos, "Test WebOS packaging and release gates"),
    "private webOS builds must run the headless packaging and release-gate tests",
)
require(
    "python3 tools/webos/check_release_eligibility.py" in named_step(
        job("validate-trusted-ref"), "Require approval for the exact webOS release artifact"
    )
    and "--preflight" in named_step(
        job("validate-trusted-ref"), "Require approval for the exact webOS release artifact"
    ),
    "webOS public-release approval must fail before platform builds start",
)
candidate_builder = (
    WEBOS_CANDIDATE_BUILDER.read_text(encoding="utf-8")
    if WEBOS_CANDIDATE_BUILDER.is_file()
    else ""
)
ipk_builder = (
    WEBOS_IPK_BUILDER.read_text(encoding="utf-8")
    if WEBOS_IPK_BUILDER.is_file()
    else ""
)
release_gate = (
    WEBOS_RELEASE_GATE.read_text(encoding="utf-8")
    if WEBOS_RELEASE_GATE.is_file()
    else ""
)
require(
    'read_lock releaseEligibility validatedSourceCommit' in candidate_builder
    and "export PLEZY_WEBOS_GIT_COMMIT" in candidate_builder
    and '"${PLEZY_WEBOS_GIT_COMMIT:-$(git -C "$ROOT" rev-parse HEAD)}"' in ipk_builder,
    "approved WebOS releases must embed the exact C6-qualified app-source commit",
)
require(
    '"validatedArtifactSha256"' in release_gate
    and 'actual_hash != expected_hash' in release_gate
    and "REQUIRED_GATES" in release_gate,
    "the WebOS public-release guard must check all gates and the exact IPK hash",
)
require(
    "--artifact" in named_step(build_webos, "Verify the exact approved WebOS IPK")
    and "--version \"$RELEASE_TAG\"" in named_step(
        build_webos, "Verify the exact approved WebOS IPK"
    ),
    "the public release must verify the exact qualified IPK hash, source, and version",
)
require(
    "if: ${{ needs.validate-trusted-ref.outputs.mode == 'release' && needs.validate-trusted-ref.outputs.include_webos_release == 'true' }}"
    in named_step(build_webos, "Upload approved WebOS IPK for public release assembly"),
    "the WebOS IPK must not be uploaded as a public workflow artifact before release approval",
)
validation_evidence = named_step(
    build_webos, "Upload WebOS validation evidence without vendor runtime binaries"
)
require(
    "webos-validation-evidence" in validation_evidence
    and "*.ipk" not in validation_evidence,
    "webOS validation artifacts must contain metadata, not vendor runtime binaries",
)
require(
    re.search(
        r"(?ms)^      action:\n.*?^        required: true\n        type: choice\n"
        r".*?^        options:\n          - build\n          - release$",
        text,
    ) is not None,
    "platform workflow must require an explicit build or release action",
)
require(
    re.search(
        r"(?ms)^      runner_pool:\n.*?^        required: true\n        type: choice\n"
        r".*?^        options:\n          - private$",
        text,
    ) is not None,
    "platform workflow must require its supported private runner pool",
)
require("inputs.build_" not in text, "release workflow must build every platform together")
require(
    re.search(r"(?ms)^  push:\n    tags:\n      - ['\"]v\*['\"]", text) is not None
    and re.search(r"(?m)^  pull_request:", text) is None,
    "release builds must run only for v* tags, not commits or pull requests",
)
require(
    "if: ${{ github.event_name == 'workflow_dispatch' && inputs.build_linux_packages }}"
    in job_block(ci_text, "linux-packages"),
    "the optional Linux package smoke build must not run on pushes",
)


run_name = re.search(r"(?m)^run-name: (.*)$", text)
run_name_expression = run_name.group(1) if run_name else ""
require(
    "github.event_name == 'push'" in run_name_expression
    and all(field in run_name_expression for field in ("inputs.action", "inputs.runner_pool", "inputs.release_tag"))
    and all(marker in run_name_expression for marker in ("action:", "pool:", "tag:")),
    "run names must expose the action, pool, and tag claim for manual and pushed releases",
)

for action_pool_job in (
    "validate-trusted-ref",
    "build-android",
    "build-webos",
    "build-ios",
    "build-tvos",
    "build-macos",
    "build-windows",
    "package-windows",
    "build-linux",
):
    block = job(action_pool_job)
    if action_pool_job == "validate-trusted-ref":
        gated = "github.event_name == 'push'" in block and "inputs.runner_pool == 'private'" in block
    else:
        gated = (
            "needs.validate-trusted-ref.outputs.action == 'build'" in block
            and "needs.validate-trusted-ref.outputs.runner_pool == 'private'" in block
        )
    require(gated, f"{action_pool_job} must be gated by the requested action and private pool")

release = job("create-release")
require(
    "needs: [validate-trusted-ref, build-android, build-webos, build-ios, build-tvos, build-macos, build-windows, package-windows, build-linux]"
    in release,
    "release dependencies must include the trust gate, all platform builds, and Windows packaging",
)
for artifact in (
    "android-apk",
    "ios-ipa",
    "tvos-ipa",
    "macos-dmg",
    "windows-x64-portable",
    "windows-arm64-portable",
    "windows-installer",
    "windows-chocolatey",
    "linux-x64",
    "linux-arm64",
):
    require(f"name: {artifact}" in release, f"release download lost {artifact}")

webos_download = named_step(release, "Download WebOS artifact")
require(
    "if: ${{ needs.validate-trusted-ref.outputs.include_webos_release == 'true' }}" in webos_download
    and "name: webos-ipk" in webos_download,
    "the WebOS release artifact must be downloaded only after explicit opt-in",
)
collect_release_files = named_step(release, "Collect release files")
require(
    'if [[ "$INCLUDE_WEBOS_RELEASE" == "true" ]]' in collect_release_files
    and "artifacts/webos/*.ipk" in collect_release_files,
    "the WebOS IPK must enter the public release asset list only after approval",
)

release_if = re.search(r"(?m)^    if: (.+)$", release)
require(release_if is not None, "release job must have an explicit condition")
release_condition = release_if.group(1) if release_if else ""
require(
    "needs.validate-trusted-ref.outputs.mode == 'release'" in release_condition
    and "needs.validate-trusted-ref.outputs.action == 'release'" in release_condition
    and "needs.validate-trusted-ref.outputs.runner_pool == 'private'" in release_condition
    and all(f"needs.{name}.result == 'success'" in release_condition for name in (
        "build-android", "build-ios", "build-tvos", "build-macos", "build-windows", "package-windows", "build-linux"))
    and "needs.validate-trusted-ref.result == 'success'" in release_condition
    and "needs.build-webos.result == 'success'" in release_condition
    and "needs.build-webos.result == 'skipped'" in release_condition
    and "contains(needs.*.result, 'failure')" in release_condition
    and "contains(needs.*.result, 'cancelled')" in release_condition,
    "draft release creation must require a successful complete build",
)


require("draft: true" in release, "build output must remain a draft release")
require("body_path: release-notes.md" in release, "draft notes must come from the changelog renderer")
require(
    "tag_name: ${{ needs.validate-trusted-ref.outputs.release_tag }}" in release,
    "release builds must bind the validated release tag",
)
require(
    "target_commitish: ${{ github.sha }}" in release,
    "release tags must target the exact build commit",
)
require(
    "python3 scripts/generate_release_notes.py \"$RELEASE_TAG\" > release-notes.md"
    in release,
    "draft release notes must be rendered from CHANGELOG.md",
)

trusted_ref = job("validate-trusted-ref")
require(
    "permissions:\n      contents: read" in trusted_ref,
    "release request validation must have read-only repository access",
)
require(
    '"$GITHUB_REF" != "refs/heads/main"' in trusted_ref,
    "trusted-ref validation must reject non-main refs",
)
require(
    "Validate release tag before building" in trusted_ref
    and '"$VERSION" != "$PACKAGE_VERSION"' in trusted_ref
    and '"$EVENT_NAME" == "push" && "$RELEASE_TAG" != "v$PACKAGE_VERSION"' in trusted_ref
    and '"$RUNNER_POOL" != "private"' in trusted_ref
    and '"$ACTION" != "build"' in trusted_ref,
    "release tags must be checked against pubspec; action and runner pool must be validated before platform builds start",
)
for protected_job in (
    "build-android",
    "build-ios",
    "build-tvos",
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
