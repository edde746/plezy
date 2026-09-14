#!/usr/bin/env bash
# Re-resolve Plezy's Apple SwiftPM dependencies so a moved pin is actually fetched.
#
# Why this exists: the locks name a revision, but nothing in a normal Flutter
# build ever fetches it. `flutter run/build -d macos` runs its Xcode steps with
# `-skipPackageUpdates`, which forbids contacting the remote, and the one
# fetch-capable step Flutter does perform (`prefetchSwiftPackages`) is started
# for at most one Darwin platform per invocation -- iOS wins, because a single
# `_swiftPackageFetchProcess` field in flutter_tools guards it. So on a checkout
# whose build/macos/SourcePackages predates the pin, every macOS build dies in
# the SwiftPM integration migration with:
#
#   could not find the commit <sha> in https://github.com/edde746/MPVKit
#
# even though the commit is perfectly reachable upstream. The mirror is stale,
# the fetch is forbidden, and nothing self-heals. One `-resolvePackageDependencies`
# without those flags updates the mirror, materializes the checkout, and leaves
# the tracked locks untouched.
#
# Run this after scripts/set_native_revision.sh, or after pulling someone else's
# pin bump, whenever a macOS build reports a commit it cannot find.
#
# Usage:
#   scripts/refresh_apple_spm.sh [--reset] [ios|macos ...]
#
# Defaults to every supported platform. tvOS is deliberately absent: it is not
# built through Flutter, and Xcode resolves it with fetching enabled anyway.
#
# --reset deletes the platform's SourcePackages directory first. Needed only when
# that directory is internally inconsistent -- a workspace-state.json naming a
# checkout that no longer exists makes SwiftPM refuse to resolve at all. Binary
# artifacts re-hydrate from ~/Library/Caches/org.swift.swiftpm, so a reset costs
# seconds, not a re-download.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

SUPPORTED=(ios macos)
RESET=0
PLATFORMS=()

for arg in "$@"; do
  case "$arg" in
    --reset)
      RESET=1
      ;;
    -h | --help)
      # Print the header block itself, so help can never drift from the comments.
      awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "error: unknown option '$arg'" >&2
      exit 2
      ;;
    *)
      valid=0
      for platform in "${SUPPORTED[@]}"; do
        [ "$arg" = "$platform" ] && valid=1
      done
      if [ "$valid" -eq 0 ]; then
        echo "error: unsupported platform '$arg' (expected: ${SUPPORTED[*]})" >&2
        exit 2
      fi
      PLATFORMS+=("$arg")
      ;;
  esac
done

if [ "${#PLATFORMS[@]}" -eq 0 ]; then
  PLATFORMS=("${SUPPORTED[@]}")
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found; this script only runs on a macOS host with Xcode" >&2
  exit 1
fi

FAILED=0

for platform in "${PLATFORMS[@]}"; do
  project="$platform/Runner.xcodeproj"
  if [ ! -d "$project" ]; then
    echo "skip       $platform (no $project)"
    continue
  fi
  # The graph includes Flutter's generated local packages; without them xcodebuild
  # fails on a missing manifest rather than on anything to do with the pin.
  if [ ! -d "$platform/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage" ]; then
    echo "error: $platform/Flutter/ephemeral/Packages is missing; run 'flutter pub get' first" >&2
    FAILED=1
    continue
  fi

  cloned_dir="$ROOT/build/$platform/SourcePackages"
  if [ "$RESET" -eq 1 ] && [ -d "$cloned_dir" ]; then
    rm -rf "$cloned_dir"
    echo "reset      $cloned_dir"
  fi

  log="$(mktemp)"
  if (cd "$platform" && xcodebuild -project Runner.xcodeproj -resolvePackageDependencies \
    -clonedSourcePackagesDirPath "$cloned_dir" >"$log" 2>&1); then
    echo "resolved   $platform"
    # Only the lines that say what moved; the rest is a list of local plugin packages.
    grep -E '^(Fetching|Updating|Cloning|Creating working copy|Checking out) ' "$log" | sed 's/^/             /' || true
  else
    echo "FAILED     $platform" >&2
    cat "$log" >&2
    if [ "$RESET" -eq 0 ]; then
      echo "hint: rerun as 'scripts/refresh_apple_spm.sh --reset $platform' if $cloned_dir is inconsistent" >&2
    fi
    FAILED=1
  fi
  rm -f "$log"
done

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
