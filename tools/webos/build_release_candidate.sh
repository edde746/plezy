#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

: "${RUNNER_TEMP:?This release build must run on an Actions private JIT runner}"
: "${GITHUB_RUN_ID:?The JIT run ID is required for task-scoped paths}"

if [[ ! "$GITHUB_RUN_ID" =~ ^[0-9]+$ ]]; then
  echo "GITHUB_RUN_ID must contain only decimal digits." >&2
  exit 1
fi
if [[ -L "$RUNNER_TEMP" || ! -d "$RUNNER_TEMP" ]]; then
  echo "RUNNER_TEMP must be an existing real directory." >&2
  exit 1
fi

TASK_ROOT="${PLEZYNG_WEBOS_TASK_ROOT:-$RUNNER_TEMP/plezyng-webos-$GITHUB_RUN_ID}"
if [[ "$TASK_ROOT" != "$RUNNER_TEMP"/plezyng-webos-* ]]; then
  echo "PLEZYNG_WEBOS_TASK_ROOT must be a task-scoped child of RUNNER_TEMP." >&2
  exit 1
fi
if [[ -e "$TASK_ROOT" || -L "$TASK_ROOT" ]]; then
  echo "Refusing to reuse or overwrite the WebOS task directory: $TASK_ROOT" >&2
  exit 1
fi

JSON_PYTHON="${WEBOS_JSON_PYTHON_BIN:-$(command -v python3 || true)}"
if [[ -z "$JSON_PYTHON" || ! -x "$JSON_PYTHON" ]]; then
  echo "The private JIT image must provide Python 3 to read the compatibility lock." >&2
  exit 1
fi

OS_RELEASE_PATH=/etc/os-release
if [[ -L "$OS_RELEASE_PATH" ]]; then
  OS_RELEASE_PATH="$("$JSON_PYTHON" - "$OS_RELEASE_PATH" <<'PY'
import os
import sys

print(os.path.realpath(sys.argv[1]))
PY
)"
  if [[ "$OS_RELEASE_PATH" != /usr/lib/os-release ]]; then
    echo "The /etc/os-release symlink must resolve to /usr/lib/os-release." >&2
    exit 1
  fi
fi
if [[ ! -f "$OS_RELEASE_PATH" || ! -r "$OS_RELEASE_PATH" ]]; then
  echo "The private JIT image must provide a readable /etc/os-release file." >&2
  exit 1
fi
HOST_OS_FACTS="$("$JSON_PYTHON" - "$OS_RELEASE_PATH" <<'PY'
import shlex
import sys

values = {}
with open(sys.argv[1], encoding="utf-8") as os_release:
    for line in os_release:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, raw_value = line.split("=", 1)
        parsed = shlex.split(raw_value, posix=True)
        if len(parsed) == 1:
            values[key] = parsed[0]
print(values.get("ID", ""), values.get("VERSION_ID", ""), sep="\t")
PY
)"
IFS=$'\t' read -r HOST_OS_ID HOST_OS_VERSION <<< "$HOST_OS_FACTS"
if [[ "$HOST_OS_ID" != "ubuntu" || ! "$HOST_OS_VERSION" =~ ^(22\.04|24\.04|26\.04)$ ]]; then
  echo "LG supports the Flutter-webOS build host on Ubuntu 22.04, 24.04, or 26.04; refusing unsupported host $HOST_OS_ID $HOST_OS_VERSION." >&2
  exit 1
fi

REQUIRED_COMMANDS=(curl git git-lfs sha256sum df awk tee install unzip cmake pkg-config file clang clang++ tar)
MISSING_COMMANDS=()
for required_command in "${REQUIRED_COMMANDS[@]}"; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    MISSING_COMMANDS+=("$required_command")
  fi
done
if (( ${#MISSING_COMMANDS[@]} != 0 )); then
  printf 'The private JIT image is missing required LG Flutter-webOS build tools: %s\n' \
    "${MISSING_COMMANDS[*]}" >&2
  exit 1
fi
if ! pkg-config --exists gtk+-3.0; then
  echo "The private JIT image must provide the GTK 3 development files required by the supported Linux host." >&2
  exit 1
fi

read_lock() {
  "$JSON_PYTHON" - "$ROOT/tools/webos/compatibility.json" "$@" <<'PY'
import json
import sys

path, *keys = sys.argv[1:]
with open(path, encoding="utf-8") as lock_file:
    value = json.load(lock_file)
for key in keys:
    value = value[key]
if not isinstance(value, (str, int, float)):
    raise SystemExit(f"Lock value is not scalar: {'.'.join(keys)}")
print(value)
PY
}

case "${PLEZY_WEBOS_RELEASE_BUILD:-false}" in
  true)
    if [[ -n "${PLEZY_WEBOS_GIT_COMMIT:-}" ]]; then
      echo "The public WebOS release must use the commit recorded in the eligibility lock." >&2
      exit 1
    fi
    PLEZY_WEBOS_GIT_COMMIT="$(read_lock releaseEligibility validatedSourceCommit)"
    if [[ ! "$PLEZY_WEBOS_GIT_COMMIT" =~ ^[0-9a-f]{40,64}$ ]]; then
      echo "The approved WebOS source commit is missing or malformed." >&2
      exit 1
    fi
    export PLEZY_WEBOS_GIT_COMMIT
    ;;
  false)
    ;;
  *)
    echo "PLEZY_WEBOS_RELEASE_BUILD must be exactly true or false." >&2
    exit 1
    ;;
esac

PYTHON_BIN="${WEBOS_PYTHON_BIN:-$(command -v python3.14 || true)}"
NINJA_BIN="${WEBOS_NINJA_BIN:-$(command -v ninja || true)}"
if [[ -z "$PYTHON_BIN" || ! -x "$PYTHON_BIN" ]]; then
  echo "The approved private JIT image must provide the hash-locked Python 3.14.8 interpreter." >&2
  exit 1
fi
if [[ -z "$NINJA_BIN" || ! -x "$NINJA_BIN" ]]; then
  echo "The approved private JIT image must provide the hash-locked Ninja 1.13.2 binary." >&2
  exit 1
fi

LOCKED_PYTHON_VERSION="$(read_lock engineBuild pythonVersion)"
LOCKED_PYTHON_SHA256="$(read_lock engineBuild pythonSha256ByUbuntu "$HOST_OS_VERSION")"
LOCKED_NINJA_VERSION="$(read_lock engineBuild ninjaVersion)"
LOCKED_NINJA_SHA256="$(read_lock engineBuild ninjaSha256)"
ACTUAL_PYTHON_VERSION="$("$PYTHON_BIN" --version 2>&1)"
ACTUAL_PYTHON_SHA256="$(sha256sum -- "$PYTHON_BIN" | awk '{ print $1 }')"
ACTUAL_NINJA_VERSION="$("$NINJA_BIN" --version)"
ACTUAL_NINJA_SHA256="$(sha256sum -- "$NINJA_BIN" | awk '{ print $1 }')"
if [[ "$ACTUAL_PYTHON_VERSION" != "Python $LOCKED_PYTHON_VERSION" || "$ACTUAL_PYTHON_SHA256" != "$LOCKED_PYTHON_SHA256" ]]; then
  echo "The private JIT Python does not match the locked version and hash." >&2
  exit 1
fi
if [[ "$ACTUAL_NINJA_VERSION" != "$LOCKED_NINJA_VERSION" || "$ACTUAL_NINJA_SHA256" != "$LOCKED_NINJA_SHA256" ]]; then
  echo "The private JIT Ninja does not match the locked version and hash." >&2
  exit 1
fi

AVAILABLE_KB="$(df -Pk "$RUNNER_TEMP" | awk 'NR == 2 { print $4 }')"
MINIMUM_FREE_KIB=$((60 * 1024 * 1024))
if [[ ! "$AVAILABLE_KB" =~ ^[0-9]+$ ]] || (( AVAILABLE_KB < MINIMUM_FREE_KIB )); then
  echo "The webOS source build needs at least 60 GiB free under RUNNER_TEMP; refusing to start." >&2
  df -h "$RUNNER_TEMP" >&2
  exit 1
fi

mkdir -m 700 -- "$TASK_ROOT"
LOG_ROOT="$TASK_ROOT/logs"
DOWNLOAD_ROOT="$TASK_ROOT/downloads"
SDK_ROOT="$TASK_ROOT/flutter-webos"
NDK_ROOT="$TASK_ROOT/webos-ndk"
CUSTOM_ENGINE_ROOT="$TASK_ROOT/custom-engine"
OUTPUT_ROOT="$TASK_ROOT/output"
BOOTSTRAP_DEPOT_TOOLS="$TASK_ROOT/bootstrap-depot-tools"
HOST_TOOLS="$TASK_ROOT/host-tools/bin"
mkdir -m 700 -- "$LOG_ROOT" "$DOWNLOAD_ROOT" "$CUSTOM_ENGINE_ROOT" "$OUTPUT_ROOT" "$TASK_ROOT/host-tools"
mkdir -m 700 -- "$HOST_TOOLS"
exec > >(tee -a "$LOG_ROOT/build-release-candidate.log") 2>&1

printf 'PlezyNG WebOS release build task: %s\n' "$TASK_ROOT"
printf 'Flutter-webOS SDK: %s\n' "$SDK_ROOT"
printf 'LG NDK: %s\n' "$NDK_ROOT"
printf 'Custom engine output: %s\n' "$CUSTOM_ENGINE_ROOT"
printf 'Release artifact output: %s\n' "$OUTPUT_ROOT"
df -h "$RUNNER_TEMP"

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "The locked engine toolchain currently targets an x86_64 Ubuntu build host." >&2
  exit 1
fi

SDK_REVISION="$(read_lock sdk revision)"
FLUTTER_REVISION="$(read_lock sdk frameworkRevision)"
DEPOT_TOOLS_REVISION="$(read_lock engineBuild depotToolsRevision)"
NDK_INSTALLER_URL="$(read_lock lgArtifacts ndkInstaller url)"
NDK_INSTALLER_SHA256="$(read_lock lgArtifacts ndkInstaller sha256)"
BASE_ENGINE_URL="$(read_lock lgArtifacts baseEngineArchiveUrl)"
BASE_ENGINE_SHA256="$(read_lock lgArtifacts baseEngineArchiveSha256)"
COMMON_ARCHIVE_URL="$(read_lock lgArtifacts commonArchiveUrl)"
COMMON_ARCHIVE_SHA256="$(read_lock lgArtifacts commonArchiveSha256)"

download_locked() {
  local name="$1"
  local url="$2"
  local expected_sha256="$3"
  local destination="$DOWNLOAD_ROOT/$name"

  if [[ -e "$destination" || -L "$destination" ]]; then
    echo "Refusing to overwrite a downloaded toolchain input: $destination" >&2
    return 1
  fi
  curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --retry 3 --retry-all-errors --output "$destination" "$url"
  printf '%s  %s\n' "$expected_sha256" "$destination" | sha256sum --check --status
  printf 'Verified download: %s\n' "$name" >&2
  printf '%s\n' "$destination"
}

NDK_INSTALLER="$(download_locked webos-ndk-installer.sh "$NDK_INSTALLER_URL" "$NDK_INSTALLER_SHA256")"
BASE_ENGINE_ARCHIVE="$(download_locked webos-arm-release.zip "$BASE_ENGINE_URL" "$BASE_ENGINE_SHA256")"
COMMON_ARCHIVE="$(download_locked webos-common.zip "$COMMON_ARCHIVE_URL" "$COMMON_ARCHIVE_SHA256")"

git -c protocol.file.allow=never clone --filter=blob:none --no-checkout \
  https://github.com/lg-flutter-webos/flutter-webos.git "$SDK_ROOT"
git -C "$SDK_ROOT" checkout --detach "$SDK_REVISION"
if [[ "$(git -C "$SDK_ROOT" rev-parse HEAD)" != "$SDK_REVISION" ]]; then
  echo "Flutter-webOS checkout did not resolve to the locked revision." >&2
  exit 1
fi

git -C "$SDK_ROOT" apply --check "$ROOT/tools/webos/flutter-webos-3.47.1.patch"
git -C "$SDK_ROOT" apply "$ROOT/tools/webos/flutter-webos-3.47.1.patch"

BIN_DIR="$SDK_ROOT/bin"
export BIN_DIR
source "$SDK_ROOT/bin/internal/shared.sh"
update_flutter
if [[ "$(git -C "$SDK_ROOT/flutter" rev-parse HEAD)" != "$FLUTTER_REVISION" ]]; then
  echo "Flutter framework checkout did not resolve to the locked revision." >&2
  exit 1
fi

git -C "$SDK_ROOT/flutter" apply --check "$ROOT/tools/webos/flutter-framework-3.47.1.patch"
git -C "$SDK_ROOT/flutter" apply "$ROOT/tools/webos/flutter-framework-3.47.1.patch"

git -c protocol.file.allow=never clone --filter=blob:none --no-checkout \
  https://chromium.googlesource.com/chromium/tools/depot_tools.git "$BOOTSTRAP_DEPOT_TOOLS"
git -C "$BOOTSTRAP_DEPOT_TOOLS" checkout --detach "$DEPOT_TOOLS_REVISION"
export DEPOT_TOOLS_UPDATE=0
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
export CIPD_CACHE_DIR="$TASK_ROOT/cipd-cache"
mkdir -m 700 -- "$CIPD_CACHE_DIR"
export PATH="$HOST_TOOLS:$BOOTSTRAP_DEPOT_TOOLS:$PATH"
ln -s -- "$PYTHON_BIN" "$HOST_TOOLS/python3"

(
  cd -- "$SDK_ROOT/flutter"
  gclient sync --no-history --shallow -j 8
)

"$PYTHON_BIN" "$ROOT/tools/webos/verify_sdk_checkout.py" "$SDK_ROOT"

"$NDK_INSTALLER" -y -d "$NDK_ROOT"
"$PYTHON_BIN" "$ROOT/tools/webos/ndk_environment.py" --root "$NDK_ROOT" --verify

export FLUTTER_WEBOS_SDK_ROOT="$SDK_ROOT"
export WEBOS_NDK_ROOT="$NDK_ROOT"
export WEBOS_NINJA_BIN="$NINJA_BIN"
export WEBOS_PYTHON_BIN="$PYTHON_BIN"
export WEBOS_ENGINE_BASE_ARCHIVE="$BASE_ENGINE_ARCHIVE"
export WEBOS_ENGINE_COMMON_ARCHIVE="$COMMON_ARCHIVE"
export WEBOS_ENGINE_BUILD_ROOT="$CUSTOM_ENGINE_ROOT/webos-engine-$GITHUB_RUN_ID"
export SOURCE_DATE_EPOCH=0
tools/webos/build_engine.sh

export WEBOS_ENGINE_LOCAL_PATH="$WEBOS_ENGINE_BUILD_ROOT/artifacts/webos-arm-release.zip"
tools/webos/build_ipk.sh 2>&1 | tee "$LOG_ROOT/build-ipk.log"

shopt -s nullglob
IPKS=("$ROOT/build/webos/arm/release/ipk"/org.snapetech.plezyng_*_arm.ipk)
if (( ${#IPKS[@]} != 1 )); then
  echo "Expected exactly one verified PlezyNG ARM IPK; found ${#IPKS[@]}." >&2
  exit 1
fi
ENGINE_PROVENANCE="$WEBOS_ENGINE_BUILD_ROOT/artifacts/webos-engine-provenance.json"
if [[ ! -f "$ENGINE_PROVENANCE" || -L "$ENGINE_PROVENANCE" ]]; then
  echo "The verified engine provenance file is missing." >&2
  exit 1
fi

install -m 644 -- "${IPKS[0]}" "$OUTPUT_ROOT/"
install -m 644 -- "$ENGINE_PROVENANCE" "$OUTPUT_ROOT/webos-engine-provenance.json"
install -m 644 -- "$ROOT/tools/webos/compatibility.json" "$OUTPUT_ROOT/webos-compatibility.json"
(
  cd -- "$OUTPUT_ROOT"
  sha256sum -- *.ipk webos-engine-provenance.json webos-compatibility.json > SHA256SUMS.txt
)

printf 'Validated webOS release artifact: %s\n' "$OUTPUT_ROOT/$(basename -- "${IPKS[0]}")"
printf 'Engine provenance: %s\n' "$OUTPUT_ROOT/webos-engine-provenance.json"
printf 'Build checksum manifest: %s\n' "$OUTPUT_ROOT/SHA256SUMS.txt"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'output_dir=%s\n' "$OUTPUT_ROOT" >> "$GITHUB_OUTPUT"
fi
