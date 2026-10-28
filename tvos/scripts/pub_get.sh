#!/usr/bin/env bash
# Resolve the shared Flutter app for tvOS with the tvOS MethodChannel bridge.
# The upstream dart_smb2 native assets do not target tvOS; the bridge uses the
# dynamically linked AMSMB2 SPM framework instead.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [[ -e pubspec_overrides.yaml ]]; then
  echo "pubspec_overrides.yaml already exists; move it aside before preparing tvOS dependencies." >&2
  exit 1
fi

# pubspec_overrides.yaml replaces the dependency_overrides map as a whole.
# Merge the root overrides first so tvOS keeps the pinned connectivity_plus
# Git source required by the vendored background_downloader package.
ruby -ryaml -e '
root = YAML.load_file("pubspec.yaml")
overlay = YAML.load_file("pubspec_overrides_tvos.yaml")
root_overrides = root.fetch("dependency_overrides", {})
tvos_overrides = overlay.fetch("dependency_overrides", {})
overlay["dependency_overrides"] = root_overrides.merge(tvos_overrides)
File.write("pubspec_overrides.yaml", YAML.dump(overlay))
'
trap 'rm -f pubspec_overrides.yaml' EXIT
flutter pub get --no-example
