#!/usr/bin/env bash
# Download the prebuilt flutter-tvos engine tarball from GitHub Releases,
# extract it into a shared cache, and write tvos/Flutter/Generated.xcconfig
# so Xcode picks it up via FLUTTER_LOCAL_ENGINE.
#
# Reads the engine version from tvos/engine.version. Re-runs are cheap —
# skips download if the cache already has the matching version.
#
# Usage:
#   tvos/scripts/fetch_engine.sh
#
# Env overrides:
#   FLUTTER_TVOS_ENGINE_CACHE — root dir for cached engines (default: ~/.cache/flutter-tvos-engine)
#   FLUTTER_TVOS_RELEASES_URL — base URL for release tarballs (default: github.com/edde746/flutter-tvos)

set -euo pipefail

TVOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${TVOS_DIR}/.." && pwd)"

VERSION_FILE="${TVOS_DIR}/engine.version"
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "error: $VERSION_FILE missing" >&2
  exit 1
fi
VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
if [[ -z "$VERSION" ]]; then
  echo "error: tvos/engine.version is empty" >&2
  exit 1
fi

CACHE_ROOT="${FLUTTER_TVOS_ENGINE_CACHE:-$HOME/.cache/flutter-tvos-engine}"
RELEASES_URL="${FLUTTER_TVOS_RELEASES_URL:-https://github.com/edde746/flutter-tvos}"

ENGINE_DIR="${CACHE_ROOT}/v${VERSION}"
TARBALL_URL="${RELEASES_URL}/releases/download/v${VERSION}/flutter-tvos-${VERSION}.tar.gz"
STAMP="${ENGINE_DIR}/.installed-${VERSION}"

if [[ ! -f "$STAMP" ]]; then
  echo "[fetch_engine] downloading ${TARBALL_URL}"
  mkdir -p "$ENGINE_DIR"
  TMP_TAR="$(mktemp -t flutter-tvos-engine.XXXXXX.tar.gz)"
  trap 'rm -f "$TMP_TAR"' EXIT
  curl -fL --progress-bar -o "$TMP_TAR" "$TARBALL_URL"
  echo "[fetch_engine] extracting to $ENGINE_DIR"
  tar -xzf "$TMP_TAR" -C "$ENGINE_DIR"
  touch "$STAMP"
  rm -f "$TMP_TAR"
  trap - EXIT
else
  echo "[fetch_engine] using cached engine at $ENGINE_DIR"
fi

# Locate a host Flutter SDK for flutter CLI invocation during the build.
if [[ -n "${FLUTTER_ROOT:-}" ]]; then
  FLUTTER_ROOT_RESOLVED="$FLUTTER_ROOT"
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_ROOT_RESOLVED="$(dirname "$(dirname "$(command -v flutter)")")"
else
  echo "error: couldn't find Flutter SDK — set FLUTTER_ROOT or put flutter on PATH" >&2
  exit 1
fi

# Read version name/number from pubspec so Generated.xcconfig matches the app.
PUBSPEC="${REPO_ROOT}/pubspec.yaml"
PUB_NAME=""
PUB_NUMBER=""
if [[ -f "$PUBSPEC" ]]; then
  VER_LINE="$(awk '/^version:/ {print $2; exit}' "$PUBSPEC" | tr -d '"')"
  if [[ -n "$VER_LINE" ]]; then
    PUB_NAME="${VER_LINE%+*}"
    if [[ "$VER_LINE" == *+* ]]; then
      PUB_NUMBER="${VER_LINE#*+}"
    fi
  fi
fi
PUB_NAME="${PUB_NAME:-1.0.0}"
PUB_NUMBER="${PUB_NUMBER:-1}"

# tvOS deployment target is hard-coded at the Podfile / project level to 14.0.
# Write Generated.xcconfig so Xcode (and the Run Script phase) see the engine.
GEN_XC="${TVOS_DIR}/Flutter/Generated.xcconfig"
mkdir -p "$(dirname "$GEN_XC")"
cat > "$GEN_XC" <<EOF
FLUTTER_ROOT=${FLUTTER_ROOT_RESOLVED}
FLUTTER_APPLICATION_PATH=${REPO_ROOT}
FLUTTER_TARGET=lib/main.dart
FLUTTER_BUILD_NAME=${PUB_NAME}
FLUTTER_BUILD_NUMBER=${PUB_NUMBER}
TVOS_DEPLOYMENT_TARGET=14.0
FLUTTER_LOCAL_ENGINE=${ENGINE_DIR}
PODS_ROOT=${TVOS_DIR}/Pods
EOF

echo
echo "Engine ready. Wrote $GEN_XC with:"
echo "  FLUTTER_LOCAL_ENGINE=$ENGINE_DIR"
echo "  FLUTTER_BUILD_NAME=$PUB_NAME"
echo "  FLUTTER_BUILD_NUMBER=$PUB_NUMBER"
echo
echo "Next: open tvos/Runner.xcworkspace in Xcode and build."
