#!/usr/bin/env bash
# Installs the XcodeGen release apple/project.yml is generated with into <dir> (once; checked against the release
# zip's sha256) and prints its binary's path. The CI and release workflows and the Apple test harness use it, so every
# machine generates the Xcode project with the same XcodeGen; project.yml's options.minimumXcodeGenVersion names the
# same version, so an older one elsewhere (brew's, on a Mac) refuses to generate.
#
# Usage: tools/install_xcodegen.sh <dir>
#   "$(tools/install_xcodegen.sh "$RUNNER_TEMP")" generate
# A new version: change both lines below and minimumXcodeGenVersion together.
set -euo pipefail
version=2.46.0
sha256=4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806

dir="${1:?usage: $0 <dir>}/xcodegen-$version"
# An install is reused only while every file the release unpacked is still there (listed in .files): macOS deletes
# files in /tmp that nobody read for days, and an XcodeGen without its setting presets still generates, a project whose
# iOS and tvOS targets build for macOS.
complete() {
  [[ -f "$dir/.files" ]] || return 1
  while IFS= read -r file; do
    [[ -f "$dir/$file" ]] || return 1
  done < "$dir/.files"
}
if ! complete; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --retry 3 --max-time 300 -o "$tmp/xcodegen.zip" \
    "https://github.com/yonaskolb/XcodeGen/releases/download/$version/xcodegen.zip"
  echo "$sha256  $tmp/xcodegen.zip" | shasum -a 256 -c - > /dev/null
  unzip -q "$tmp/xcodegen.zip" -d "$tmp"
  rm -rf "$dir"
  mkdir -p "$(dirname "$dir")"
  mv "$tmp/xcodegen" "$dir"
  (cd "$dir" && find . -type f ! -name .files | sort > .files)
fi
echo "$dir/bin/xcodegen"
