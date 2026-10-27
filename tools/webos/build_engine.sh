#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

: "${FLUTTER_WEBOS_SDK_ROOT:?Set this to the pinned, patched flutter-webos checkout}"
: "${WEBOS_NDK_ROOT:?Set this to the pinned LG webOS 26 NDK root}"
: "${WEBOS_ENGINE_BUILD_ROOT:?Set this to a new, task-scoped output directory}"
: "${WEBOS_ENGINE_BASE_ARCHIVE:?Set this to LG unmodified webos-arm-release.zip}"
: "${WEBOS_ENGINE_COMMON_ARCHIVE:?Set this to the matching LG webos-common.zip}"

for path in "$FLUTTER_WEBOS_SDK_ROOT" "$WEBOS_NDK_ROOT"; do
  if [[ -L "$path" ]]; then
    echo "Pinned toolchain roots must not be symbolic links: $path" >&2
    exit 1
  fi
done

SDK_ROOT="$(cd -- "$FLUTTER_WEBOS_SDK_ROOT" && pwd)"
NDK_ROOT="$(cd -- "$WEBOS_NDK_ROOT" && pwd)"
ENGINE_ROOT="$SDK_ROOT/flutter/engine/src"
TASK_ROOT="$(cd -- "$(dirname -- "$SDK_ROOT")" && pwd)"
CUSTOM_ENGINE_ROOT="$TASK_ROOT/custom-engine"
PINNED_DEPOT_TOOLS="$ENGINE_ROOT/flutter/third_party/depot_tools"
GN="$ENGINE_ROOT/flutter/third_party/gn/gn"
NINJA="${WEBOS_NINJA_BIN:-/usr/bin/ninja}"
PYTHON="${WEBOS_PYTHON_BIN:-/usr/bin/python3.14}"
JOBS="${WEBOS_ENGINE_JOBS:-8}"

case "$WEBOS_ENGINE_BUILD_ROOT" in
  /*) ;;
  *) echo "WEBOS_ENGINE_BUILD_ROOT must be an absolute path." >&2; exit 1 ;;
esac
if [[ -e "$WEBOS_ENGINE_BUILD_ROOT" || -L "$WEBOS_ENGINE_BUILD_ROOT" ]]; then
  echo "Refusing to reuse or overwrite an engine build directory: $WEBOS_ENGINE_BUILD_ROOT" >&2
  exit 1
fi
if [[ ! -d "$CUSTOM_ENGINE_ROOT" || -L "$CUSTOM_ENGINE_ROOT" ]]; then
  echo "The task root must contain a real custom-engine directory: $CUSTOM_ENGINE_ROOT" >&2
  exit 1
fi
BUILD_ROOT="$(realpath -m -- "$WEBOS_ENGINE_BUILD_ROOT")"
if [[ "$(dirname -- "$BUILD_ROOT")" != "$CUSTOM_ENGINE_ROOT" ]]; then
  echo "WEBOS_ENGINE_BUILD_ROOT must be a new direct child of $CUSTOM_ENGINE_ROOT to preserve the reviewed Ninja source-relative layout." >&2
  exit 1
fi
if [[ -e "$BUILD_ROOT" || -L "$BUILD_ROOT" ]]; then
  echo "Refusing to reuse or overwrite an engine build directory: $BUILD_ROOT" >&2
  exit 1
fi
BUILD_ID="$(basename -- "$BUILD_ROOT")"
if [[ ! "$BUILD_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,80}$ ]]; then
  echo "WEBOS_ENGINE_BUILD_ROOT must end with a short safe task identifier." >&2
  exit 1
fi
TOOLCHAIN_ROOT="$CUSTOM_ENGINE_ROOT/flutter-engine-toolchain-$BUILD_ID"
HOST_OUT="$ENGINE_ROOT/out/host_release_linux_arm_target_aot-$BUILD_ID"
if [[ -L "$ENGINE_ROOT/out" ]]; then
  echo "Refusing to place host build output through a symbolic link: $ENGINE_ROOT/out" >&2
  exit 1
fi
for generated_path in "$TOOLCHAIN_ROOT" "$HOST_OUT"; do
  if [[ -e "$generated_path" || -L "$generated_path" ]]; then
    echo "Refusing to reuse or overwrite a generated engine path: $generated_path" >&2
    exit 1
  fi
done
for value in "$JOBS" "${SOURCE_DATE_EPOCH:-0}"; do
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "Build jobs and SOURCE_DATE_EPOCH must be non-negative integers." >&2
    exit 1
  fi
done
if (( JOBS < 1 || JOBS > 128 )); then
  echo "WEBOS_ENGINE_JOBS must be between 1 and 128." >&2
  exit 1
fi

for path in "$WEBOS_ENGINE_BASE_ARCHIVE" "$WEBOS_ENGINE_COMMON_ARCHIVE"; do
  if [[ ! -f "$path" || -L "$path" ]]; then
    echo "Required LG runtime input must be a regular file: $path" >&2
    exit 1
  fi
done
BASE_ARCHIVE="$(realpath -- "$WEBOS_ENGINE_BASE_ARCHIVE")"
COMMON_ARCHIVE="$(realpath -- "$WEBOS_ENGINE_COMMON_ARCHIVE")"

export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"
export LC_ALL=C
export LANG=C
export TZ=UTC

"$PYTHON" "$ROOT/tools/webos/verify_sdk_checkout.py" "$SDK_ROOT"
"$PYTHON" "$ROOT/tools/webos/verify_engine_toolchain.py" \
  --sdk-root "$SDK_ROOT" \
  --ndk-root "$NDK_ROOT" \
  --ninja "$NINJA" \
  --python "$PYTHON"

mkdir -m 700 -- "$BUILD_ROOT"
LOG_ROOT="$BUILD_ROOT/logs"
OUTPUT_ROOT="$BUILD_ROOT/artifacts"
mkdir -m 700 -- "$LOG_ROOT" "$OUTPUT_ROOT"
mkdir -m 700 -- "$BUILD_ROOT/out"
mkdir -m 700 -- "$TOOLCHAIN_ROOT" "$TOOLCHAIN_ROOT/bin"
ARM_OUT="$BUILD_ROOT/out/linux_release_arm"
ENGINE_ARCHIVE="$OUTPUT_ROOT/webos-arm-release.zip"
COMMON_ARCHIVE_OUTPUT="$OUTPUT_ROOT/webos-common.zip"
PROVENANCE="$OUTPUT_ROOT/webos-engine-provenance.json"
NORMALIZED_ROOT="$OUTPUT_ROOT/normalized"
NORMALIZATION_RECORD="$NORMALIZED_ROOT/webos-engine-normalization.json"
mkdir -m 700 -- "$NORMALIZED_ROOT"

# Emit only the byte-locked LG environment script with its old installation
# prefix relocated to the verified NDK root. Keep a copy beside the logs.
"$PYTHON" "$ROOT/tools/webos/ndk_environment.py" --root "$NDK_ROOT" --emit-shell > "$LOG_ROOT/ndk-environment.sh"
source "$LOG_ROOT/ndk-environment.sh"
export WEBOS_ENGINE_ROOT="$ENGINE_ROOT"
export WEBOS_NDK_SYSROOT="$SDKTARGETSYSROOT"
export WEBOS_NDK_HOST_SYSROOT="$OECORE_NATIVE_SYSROOT"
export WEBOS_ENGINE_TOOLCHAIN="$TOOLCHAIN_ROOT"
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
export PATH="$TOOLCHAIN_ROOT/bin:$PINNED_DEPOT_TOOLS:$(dirname -- "$PYTHON"):$PATH"

install -m 755 -- "$ROOT/tools/webos/engine-toolchain/clang" "$TOOLCHAIN_ROOT/bin/clang"
install -m 755 -- "$ROOT/tools/webos/engine-toolchain/clang++" "$TOOLCHAIN_ROOT/bin/clang++"
ln -s -- "$PYTHON" "$TOOLCHAIN_ROOT/bin/python3"
for tool in ar readelf nm strip; do
  triple_tool="arm-webosmllib32-linux-gnueabi-$tool"
  ndk_tool="$NDK_ROOT/sysroots/x86_64-starfishsdk-linux/usr/bin/arm-webosmllib32-linux-gnueabi/$triple_tool"
  ln -s -- "$ndk_tool" "$TOOLCHAIN_ROOT/bin/$triple_tool"
done
if [[ ! -d "$ENGINE_ROOT/out" ]]; then
  mkdir -m 700 -- "$ENGINE_ROOT/out"
fi

run_logged() {
  local log_path="$1"
  shift
  if ! "$@" 2>&1 | tee "$log_path"; then
    echo "Build command failed; full output is preserved at $log_path" >&2
    return 1
  fi
}

host_args="$(<"$ROOT/tools/webos/engine-args-host.gn")"
arm_args="$(<"$ROOT/tools/webos/engine-args-arm.gn")"

run_logged "$LOG_ROOT/gn-arm.log" "$GN" gen "$ARM_OUT" "--root=$ENGINE_ROOT" "--args=$arm_args"
run_logged "$LOG_ROOT/ninja-arm.log" "$NINJA" -C "$ARM_OUT" -j "$JOBS" libflutter_engine.so

run_logged "$LOG_ROOT/gn-host.log" "$GN" gen "$HOST_OUT" "--root=$ENGINE_ROOT" "--args=$host_args"
run_logged "$LOG_ROOT/ninja-host.log" "$NINJA" -C "$HOST_OUT" -j "$JOBS" gen_snapshot

"$PYTHON" "$ROOT/tools/webos/normalize_engine_artifacts.py" \
  --engine "$ARM_OUT/libflutter_engine.so" \
  --gen-snapshot "$HOST_OUT/gen_snapshot" \
  --ndk-root "$NDK_ROOT" \
  --output-dir "$NORMALIZED_ROOT" | tee "$LOG_ROOT/normalize.log"

"$PYTHON" "$ROOT/tools/webos/assemble_engine_archive.py" \
  --base-archive "$BASE_ARCHIVE" \
  --engine-library "$NORMALIZED_ROOT/libflutter_engine.so" \
  --gen-snapshot "$NORMALIZED_ROOT/gen_snapshot" \
  --engine-version "$SDK_ROOT/flutter/bin/internal/engine.version" \
  --common-archive "$COMMON_ARCHIVE" \
  --output "$ENGINE_ARCHIVE" | tee "$LOG_ROOT/assemble.log"

"$PYTHON" "$ROOT/tools/webos/write_engine_provenance.py" \
  --archive "$ENGINE_ARCHIVE" \
  --engine "$NORMALIZED_ROOT/libflutter_engine.so" \
  --snapshot "$NORMALIZED_ROOT/gen_snapshot" \
  --normalization-record "$NORMALIZATION_RECORD" \
  --output "$PROVENANCE" \
  --source-date-epoch "$SOURCE_DATE_EPOCH" | tee "$LOG_ROOT/provenance.log"

if [[ -e "$COMMON_ARCHIVE_OUTPUT" || -L "$COMMON_ARCHIVE_OUTPUT" ]]; then
  echo "Refusing to overwrite the webOS common-runtime output: $COMMON_ARCHIVE_OUTPUT" >&2
  exit 1
fi
install -m 644 -- "$COMMON_ARCHIVE" "$COMMON_ARCHIVE_OUTPUT"
if ! cmp -s -- "$COMMON_ARCHIVE" "$COMMON_ARCHIVE_OUTPUT"; then
  echo "Copied webOS common-runtime archive does not match its verified input." >&2
  exit 1
fi

printf 'Source-built webOS engine: %s\n' "$ENGINE_ARCHIVE"
printf 'Pinned webOS common runtime: %s\n' "$COMMON_ARCHIVE_OUTPUT"
sha256sum "$ENGINE_ARCHIVE" "$COMMON_ARCHIVE_OUTPUT" "$PROVENANCE"
