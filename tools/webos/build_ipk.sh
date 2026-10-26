#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
IPK_DIR="$ROOT/build/webos/arm/release/ipk"

: "${FLUTTER_WEBOS_SDK_ROOT:?Set this to the pinned, patched flutter-webos checkout}"
: "${WEBOS_ENGINE_LOCAL_PATH:?Set this to the pinned webos-arm-release.zip}"
: "${WEBOS_NDK_ROOT:?Set this to the pinned LG webOS 26 NDK root}"
: "${WEBOS_PYTHON_BIN:=python3}"
export WEBOS_PYTHON_BIN

SDK_ROOT="$(cd -- "$FLUTTER_WEBOS_SDK_ROOT" && pwd)"
NDK_ROOT="$(cd -- "$WEBOS_NDK_ROOT" && pwd)"
ENGINE_ARCHIVE="$(cd -- "$(dirname -- "$WEBOS_ENGINE_LOCAL_PATH")" && pwd)/$(basename -- "$WEBOS_ENGINE_LOCAL_PATH")"
COMMON_ARCHIVE="$(dirname -- "$ENGINE_ARCHIVE")/webos-common.zip"

for path in "$FLUTTER_WEBOS_SDK_ROOT" "$WEBOS_NDK_ROOT"; do
  if [[ -L "$path" ]]; then
    echo "Pinned toolchain roots must not be symbolic links: $path" >&2
    exit 1
  fi
done

# Never let a stale, linked, or redirected output be mistaken for the result
# of this invocation. Keep old candidates intact and require a fresh output.
for output_path in \
  "$ROOT/build" \
  "$ROOT/build/webos" \
  "$ROOT/build/webos/arm" \
  "$ROOT/build/webos/arm/release" \
  "$IPK_DIR"; do
  if [[ -L "$output_path" ]]; then
    echo "Refusing to build through a symbolic-link output path: $output_path" >&2
    exit 1
  fi
done
shopt -s nullglob
EXISTING_IPKS=("$IPK_DIR"/org.snapetech.plezyng_*_arm.ipk)
if (( ${#EXISTING_IPKS[@]} != 0 )); then
  echo "Refusing to reuse existing webOS IPKs; use a clean build output tree: ${EXISTING_IPKS[*]}" >&2
  exit 1
fi

"$WEBOS_PYTHON_BIN" "$ROOT/tools/webos/verify_sdk_checkout.py" "$SDK_ROOT"
"$WEBOS_PYTHON_BIN" "$ROOT/tools/webos/ndk_environment.py" --root "$NDK_ROOT" --verify
source <("$WEBOS_PYTHON_BIN" "$ROOT/tools/webos/ndk_environment.py" --root "$NDK_ROOT" --emit-shell)
if [[ "${SDKTARGETSYSROOT:-}" != "$NDK_ROOT/sysroots/ca9v1-webosmllib32-linux-gnueabi" ]]; then
  echo "The verified webOS NDK environment did not load the expected target sysroot." >&2
  exit 1
fi

PACKAGER="$ROOT/tools/webos/bin/ares-package"
if [[ ! -x "$PACKAGER" ]]; then
  echo "The checked-in webOS IPK packager is not executable: $PACKAGER" >&2
  exit 1
fi
if ! "$WEBOS_PYTHON_BIN" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)'; then
  echo "The webOS IPK packager requires Python 3.10 or newer." >&2
  exit 1
fi
PACKAGER_VERSION="$("$PACKAGER" --version)"
if [[ "$PACKAGER_VERSION" != "plezyng-ipk-packager 1" ]]; then
  echo "The webOS IPK packager version is not pinned to version 1." >&2
  exit 1
fi
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"

export PATH="$ROOT/tools/webos/bin:$SDK_ROOT/bin:$SDK_ROOT/flutter/bin:$PATH"
export FLUTTER_GIT_URL="https://github.com/lg-flutter-webos/flutter-webos.git"
export WEBOS_ENGINE_LOCAL_PATH="$ENGINE_ARCHIVE"

"$WEBOS_PYTHON_BIN" "$ROOT/tools/webos/verify_package.py" \
  --engine-archive "$ENGINE_ARCHIVE" \
  --common-archive "$COMMON_ARCHIVE"

LOCK_BEFORE="$(sha256sum "$ROOT/pubspec.lock" | cut -d' ' -f1)"
flutter pub get --enforce-lockfile --no-example
LOCK_AFTER="$(sha256sum "$ROOT/pubspec.lock" | cut -d' ' -f1)"
if [[ "$LOCK_BEFORE" != "$LOCK_AFTER" ]]; then
  echo "flutter pub get changed pubspec.lock despite --enforce-lockfile." >&2
  exit 1
fi

GIT_COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
flutter-webos build webos \
  --release \
  --target-arch arm \
  --target-backend-type wayland \
  --dart-define=PLEZY_WEBOS=true \
  --dart-define=ENABLE_UPDATE_CHECK=true \
  --dart-define="GIT_COMMIT=$GIT_COMMIT"

if ! git -C "$ROOT" diff --quiet -- webos/flutter/main.dart pubspec.lock; then
  echo "The webOS build changed tracked generated or dependency files." >&2
  exit 1
fi

IPKS=("$IPK_DIR"/org.snapetech.plezyng_*_arm.ipk)
if (( ${#IPKS[@]} != 1 )); then
  echo "Expected one versioned PlezyNG ARM IPK; found ${#IPKS[@]}." >&2
  exit 1
fi
if [[ -L "${IPKS[0]}" || ! -f "${IPKS[0]}" ]]; then
  echo "The webOS build output must be a regular, non-symlink IPK: ${IPKS[0]}" >&2
  exit 1
fi

"$WEBOS_PYTHON_BIN" "$ROOT/tools/webos/verify_package.py" --ipk "${IPKS[0]}"
printf 'Validated release candidate: %s\n' "${IPKS[0]}"
