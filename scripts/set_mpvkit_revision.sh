#!/usr/bin/env bash
# Move Plezy's MPVKit dependency to an exact upstream commit.
#
# Why this exists: the MPVKit fork publishes content-addressed binaries on every
# push to main -- each xcframework asset is named after a hash of the inputs that
# produced it, so the artifacts for any commit stay downloadable forever and are
# never overwritten. A commit, not a semver tag, is therefore the unit Plezy
# pins: picking up an mpv or FFmpeg patch no longer requires cutting a release
# upstream, and the pin names the exact bytes we ship.
#
# Nine tracked files carry that pin and must move together:
#   <p>/Runner.xcodeproj/project.pbxproj                                  the requirement
#   <p>/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/...      the SwiftPM lock
#   <p>/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved           Xcode's duplicate lock
# for p in ios, macos, tvos. The duplicate locks are not redundant to us:
# scripts/checks/check_apple_spm_locks.py fails the build when a pair drifts.
#
# Nothing else needs editing: tvos/scripts/wire_mpv.rb reads the sha back out of
# the tvOS lock, so re-wiring the tvOS project cannot revert a bump made here,
# and tvos/scripts/test_wire_mpv.rb asserts all nine sites name one commit.
#
# Usage:
#   scripts/set_mpvkit_revision.sh <full-40-char-commit-sha>
#
# Rerunning with the same sha is a no-op and says so. Edits are targeted text
# replacements on purpose: `plutil -convert` round-trips would reformat an entire
# pbxproj, and re-serializing Package.resolved would churn every unrelated pin.
# Each file must match exactly once; anything else aborts before a byte is
# written. The locks name the new revision, but no local SwiftPM mirror fetches
# it on its own: a macOS Flutter build resolves with `-skipPackageUpdates` and
# aborts with "could not find the commit <sha>" until the mirror catches up. Run
# scripts/refresh_apple_spm.sh afterwards (or open the project in Xcode once).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

if [ "$#" -ne 1 ]; then
  echo "usage: scripts/set_mpvkit_revision.sh <full-40-char-commit-sha>" >&2
  exit 2
fi

REVISION="$1"
if [[ ! "$REVISION" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: '$REVISION' is not a full 40-character lowercase commit sha" >&2
  echo "hint:  git -C ../MPVKit rev-parse main" >&2
  exit 2
fi

PROJECTS=()
LOCKS=()
MISSING=()
for platform in ios macos tvos; do
  PROJECTS+=("$platform/Runner.xcodeproj/project.pbxproj")
  LOCKS+=("$platform/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
  LOCKS+=("$platform/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved")
done

for target in "${PROJECTS[@]}" "${LOCKS[@]}"; do
  if [ ! -f "$target" ]; then
    MISSING+=("$target")
  fi
done
if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "error: missing MPVKit pin site(s); refusing to run:" >&2
  printf '  %s\n' "${MISSING[@]}" >&2
  exit 1
fi

MPVKIT_REVISION="$REVISION" python3 - "${#PROJECTS[@]}" "${PROJECTS[@]}" "${LOCKS[@]}" <<'PY'
"""Rewrite the MPVKit requirement and SwiftPM pins in place.

Every file is parsed and rewritten in memory first; nothing is written unless
all nine edits are unambiguous, so a malformed file can never leave the pin
half-moved.
"""

from __future__ import annotations

import json
import os
import re
import sys

revision = os.environ["MPVKIT_REVISION"]
project_count = int(sys.argv[1])
projects = sys.argv[2 : 2 + project_count]
locks = sys.argv[2 + project_count :]

# The `*/ = {` suffix is what makes this anchor unique: the same comment appears
# in packageReferences lists and product dependencies, but only the object
# definition opens a brace.
REQUIREMENT = re.compile(
    r'/\* XCRemoteSwiftPackageReference "MPVKit" \*/ = \{\n'
    r"(?:[^\n]*\n)*?"
    r"(?P<indent>[\t ]*)requirement = \{\n"
    r"(?P<body>(?:[^\n]*\n)*?)"
    r"(?P=indent)\};\n"
)
PIN_STATE = re.compile(
    r'"identity"[ \t]*:[ \t]*"mpvkit",\n'
    r"(?:[^\n]*\n)*?"
    r'(?P<indent>[ \t]*)"state"[ \t]*:[ \t]*\{\n'
    r"(?P<body>(?:[^\n]*\n)*?)"
    r"(?P=indent)\}"
)

errors: list[str] = []
writes: list[tuple[str, str]] = []
unchanged: list[str] = []


def replace_once(pattern: re.Pattern[str], text: str, path: str, render) -> str | None:
    matches = list(pattern.finditer(text))
    if len(matches) != 1:
        errors.append(f"{path}: expected exactly 1 MPVKit pin, found {len(matches)}")
        return None
    match = matches[0]
    return text[: match.start()] + render(match) + text[match.end() :]


def check_lock_schema(path: str, text: str) -> bool:
    try:
        payload = json.loads(text)
    except json.JSONDecodeError as error:
        errors.append(f"{path}: not valid JSON ({error})")
        return False
    version = payload.get("version") if isinstance(payload, dict) else None
    if version not in (2, 3):
        errors.append(f"{path}: unsupported SwiftPM lock schema version {version!r}")
        return False
    pins = payload.get("pins")
    if not isinstance(pins, list):
        errors.append(f"{path}: missing pins array")
        return False
    pin = next(
        (
            item
            for item in pins
            if isinstance(item, dict) and item.get("identity") == "mpvkit"
        ),
        None,
    )
    if pin is None:
        errors.append(f"{path}: no mpvkit pin")
        return False
    if pin.get("kind") != "remoteSourceControl":
        errors.append(f"{path}: mpvkit pin is {pin.get('kind')!r}, expected remoteSourceControl")
        return False
    return True


for path in projects:
    with open(path, encoding="utf-8") as handle:
        original = handle.read()

    def render(match: re.Match[str]) -> str:
        indent = match.group("indent")
        head = match.group(0)[: match.start("body") - match.start()]
        return (
            f"{head}"
            f"{indent}\tkind = revision;\n"
            f"{indent}\trevision = {revision};\n"
            f"{indent}}};\n"
        )

    updated = replace_once(REQUIREMENT, original, path, render)
    if updated is None:
        continue
    if updated == original:
        unchanged.append(path)
    else:
        writes.append((path, updated))

for path in locks:
    with open(path, encoding="utf-8") as handle:
        original = handle.read()
    if not check_lock_schema(path, original):
        continue

    def render(match: re.Match[str]) -> str:
        indent = match.group("indent")
        return (
            match.group(0)[: match.start("body") - match.start()]
            + f'{indent}  "revision" : "{revision}"\n'
            + f"{indent}}}"
        )

    updated = replace_once(PIN_STATE, original, path, render)
    if updated is None:
        continue
    if updated == original:
        unchanged.append(path)
    else:
        writes.append((path, updated))

if errors:
    for error in errors:
        print(f"error: {error}", file=sys.stderr)
    sys.exit(1)

for path, content in writes:
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(content)
    print(f"  updated    {path}")
for path in unchanged:
    print(f"  unchanged  {path}")

short = revision[:12]
if writes:
    print(f"\nMPVKit pinned to {short} ({len(writes)} file(s) rewritten, {len(unchanged)} already correct).")
else:
    print(f"\nMPVKit was already pinned to {short}; nothing to do.")
PY
