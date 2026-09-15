#!/usr/bin/env bash
# Move Plezy's native mpv dependency to an exact commit of the unified
# mpv-build repository (github.com/edde746/mpv-build).
#
# Why this exists: the unified repo publishes content-addressed binaries on
# every push to main -- each asset is named after a hash of the inputs that
# produced it, so the artifacts for any commit stay downloadable forever and
# are never overwritten. A commit, not a semver tag, is therefore the unit
# Plezy pins: picking up an mpv or FFmpeg patch no longer requires cutting a
# release upstream, and the pin names the exact bytes we ship on every
# platform, not just Apple.
#
# Ten tracked files carry that pin and must move together:
#   <p>/Runner.xcodeproj/project.pbxproj                                  the requirement
#   <p>/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/...      the SwiftPM lock
#   <p>/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved           Xcode's duplicate lock
# for p in ios, macos, tvos, plus the root mpv-build.lock.json. The duplicate
# SwiftPM locks are not redundant to us: scripts/checks/check_apple_spm_locks.py
# fails the build when a pair drifts, and tvos/scripts/test_wire_mpv.rb asserts
# all ten sites name one commit.
#
# mpv-build.lock.json is how the non-Apple platforms consume the same pin.
# JSON cannot carry comments, so its schema lives here:
#
#   {
#     "formatVersion": 1,
#     "repo": "edde746/mpv-build",         the GitHub repo the commit lives in
#     "commit": "<full-40-char-sha>",       must equal the nine Apple pin sites
#     "artifacts": {                        one entry per published non-apple group
#       "<group>": {                        android | linux | windows
#         "key": "<12-hex>",               the group's content-address key
#         "assetBase": "https://...",       release download base for the assets
#         "assets": {                       one entry per platform variant
#           "<variant>": {                  e.g. an Android ABI
#             "asset": "<file name>",       downloaded as <assetBase>/<asset>
#             "checksum": "<sha256>"        of the complete asset file
#           }
#         }
#       }
#     }
#   }
#
# The artifacts map is extracted from artifacts.json at the pinned commit;
# groups that commit has not published yet are omitted, and each omission is
# noted on stdout. Serialization is deterministic: two-space indent, sorted
# keys, trailing newline. Consumers must fail when their group is missing
# rather than fall back to an unpinned source.
#
# Usage:
#   scripts/set_native_revision.sh <full-40-char-commit-sha> [--repo <path-or-url>]
#
# The commit's artifacts.json and versions.json are read from, in order: the
# --repo override (a local checkout or an https URL), a local checkout at
# ../mpv-build that contains the commit, else
# https://raw.githubusercontent.com/edde746/mpv-build. A commit without those
# manifests is refused: it predates the unified repo and cannot be pinned by
# this script.
#
# The pin names a repository as well as a commit. The target repo is derived
# from the source actually used: a GitHub --repo URL names it directly, a
# local checkout is asked for its origin remote, and anything else falls back
# to edde746/mpv-build. When the target differs from the repo the pin sites
# currently carry (e.g. the first flip away from edde746/MPVKit), the same
# all-or-nothing pass also rewrites each pbxproj repositoryURL and the
# package-name comments Xcode derives from it, and each Package.resolved
# location plus the identity SwiftPM derives from the URL's last path
# component.
#
# Rerunning with the same sha is a no-op and says so. Edits to the Apple pin
# sites are targeted text replacements on purpose: `plutil -convert`
# round-trips would reformat an entire pbxproj, and re-serializing
# Package.resolved would churn every unrelated pin. Each file must match
# exactly once; anything else aborts before a byte is written -- the lock file
# included. The locks name the new revision, but no local SwiftPM mirror
# fetches it on its own: a macOS Flutter build resolves with
# `-skipPackageUpdates` and aborts with "could not find the commit <sha>"
# until the mirror catches up. Run scripts/refresh_apple_spm.sh afterwards (or
# open the project in Xcode once).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

usage() {
  echo "usage: scripts/set_native_revision.sh <full-40-char-commit-sha> [--repo <path-or-url>]" >&2
  exit 2
}

REVISION=""
REPO_ARG=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      [ "$#" -ge 2 ] || usage
      REPO_ARG="$2"
      shift 2
      ;;
    --*)
      usage
      ;;
    *)
      [ -z "$REVISION" ] || usage
      REVISION="$1"
      shift
      ;;
  esac
done
[ -n "$REVISION" ] || usage

if [[ ! "$REVISION" =~ ^[0-9a-f]{40}$ ]]; then
  echo "error: '$REVISION' is not a full 40-character lowercase commit sha" >&2
  echo "hint:  git -C ../mpv-build rev-parse HEAD" >&2
  exit 2
fi

# ---- locate the commit's manifests ----------------------------------------

MANIFEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/set-native-revision.XXXXXX")"
trap 'rm -rf "$MANIFEST_DIR"' EXIT

local_has_commit() {
  git -C "$1" rev-parse --git-dir >/dev/null 2>&1 \
    && git -C "$1" cat-file -e "$REVISION^{commit}" 2>/dev/null
}

# Extract one manifest file from the resolved source into MANIFEST_DIR.
# A missing file means the commit predates the unified repo; refuse it.
fetch_manifest() {
  local name="$1"
  case "$SOURCE_KIND" in
    local)
      if ! git -C "$SOURCE" cat-file blob "$REVISION:$name" >"$MANIFEST_DIR/$name" 2>/dev/null; then
        echo "error: $REVISION has no $name in $SOURCE; not a unified mpv-build commit" >&2
        exit 1
      fi
      ;;
    remote)
      if ! curl -fsSL "$SOURCE/$REVISION/$name" -o "$MANIFEST_DIR/$name"; then
        echo "error: could not fetch $SOURCE/$REVISION/$name; not a unified mpv-build commit?" >&2
        exit 1
      fi
      ;;
  esac
}

# GitHub repo URLs serve files through raw.githubusercontent.com; anything
# else is taken as a base already serving <base>/<commit>/<file>.
remote_base() {
  local url="${1%/}"
  url="${url%.git}"
  case "$url" in
    https://github.com/*)
      echo "https://raw.githubusercontent.com/${url#https://github.com/}"
      ;;
    *)
      echo "$url"
      ;;
  esac
}

# owner/name from a GitHub remote URL (https, ssh, or raw form); empty when
# the URL does not name a GitHub repo.
github_slug() {
  local url="${1%/}"
  url="${url%.git}"
  case "$url" in
    https://github.com/*/*) url="${url#https://github.com/}" ;;
    https://raw.githubusercontent.com/*/*) url="${url#https://raw.githubusercontent.com/}" ;;
    ssh://git@github.com/*/*) url="${url#ssh://git@github.com/}" ;;
    git@github.com:*/*) url="${url#git@github.com:}" ;;
    *) return 0 ;;
  esac
  local owner="${url%%/*}" rest="${url#*/}"
  echo "$owner/${rest%%/*}"
}

SOURCE_KIND=""
SOURCE=""
if [ -n "$REPO_ARG" ]; then
  case "$REPO_ARG" in
    http://*|https://*)
      SOURCE_KIND="remote"
      SOURCE="$(remote_base "$REPO_ARG")"
      ;;
    *)
      if [ ! -d "$REPO_ARG" ]; then
        echo "error: --repo '$REPO_ARG' is neither a directory nor an https URL" >&2
        exit 2
      fi
      if ! local_has_commit "$REPO_ARG"; then
        echo "error: $REPO_ARG does not contain commit $REVISION" >&2
        echo "hint:  git -C $REPO_ARG fetch" >&2
        exit 1
      fi
      SOURCE_KIND="local"
      SOURCE="$REPO_ARG"
      ;;
  esac
else
  if [ -d ../mpv-build ] && local_has_commit ../mpv-build; then
    SOURCE_KIND="local"
    SOURCE="../mpv-build"
  else
    SOURCE_KIND="remote"
    SOURCE="https://raw.githubusercontent.com/edde746/mpv-build"
  fi
fi

# The GitHub repo the pins will name, derived from the actual source used.
CANONICAL_REPO="edde746/mpv-build"
TARGET_REPO=""
case "$SOURCE_KIND" in
  local)
    TARGET_REPO="$(github_slug "$(git -C "$SOURCE" remote get-url origin 2>/dev/null || true)")"
    ;;
  remote)
    TARGET_REPO="$(github_slug "$SOURCE")"
    ;;
esac
[ -n "$TARGET_REPO" ] || TARGET_REPO="$CANONICAL_REPO"

echo "reading manifests for ${REVISION:0:12} from $SOURCE"
fetch_manifest artifacts.json
fetch_manifest versions.json

# ---- collect the Apple pin sites ------------------------------------------

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
  echo "error: missing native pin site(s); refusing to run:" >&2
  printf '  %s\n' "${MISSING[@]}" >&2
  exit 1
fi

MPV_BUILD_REVISION="$REVISION" MPV_BUILD_MANIFEST_DIR="$MANIFEST_DIR" MPV_BUILD_REPO="$TARGET_REPO" \
  python3 - "${#PROJECTS[@]}" "${PROJECTS[@]}" "${LOCKS[@]}" <<'PY'
"""Rewrite the native requirement, SwiftPM pins, and mpv-build.lock.json.

Every file is parsed and rewritten in memory first; nothing is written unless
all nine Apple edits are unambiguous and the lock can be derived completely,
so a malformed file can never leave the pin half-moved. When the target repo
differs from the one the pin sites carry, the pbxproj repositoryURL and its
package-name comments, the Package.resolved location, and the identity SwiftPM
derives from the URL move in the same pass.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

revision = os.environ["MPV_BUILD_REVISION"]
manifest_dir = Path(os.environ["MPV_BUILD_MANIFEST_DIR"])
project_count = int(sys.argv[1])
projects = sys.argv[2 : 2 + project_count]
locks = sys.argv[2 + project_count :]

LOCK_PATH = "mpv-build.lock.json"
LOCK_REPO = os.environ["MPV_BUILD_REPO"]
TARGET_URL = f"https://github.com/{LOCK_REPO}"
# Xcode names the package after the URL's last path component; SwiftPM
# lowercases that same component into the pin identity.
TARGET_NAME = LOCK_REPO.rsplit("/", 1)[-1]
TARGET_IDENTITY = TARGET_NAME.lower()
LEGACY_IDENTITY = "mpvkit"  # the pre-flip edde746/MPVKit pin
ACCEPTED_IDENTITIES = {LEGACY_IDENTITY, TARGET_IDENTITY}
EXPECTED_GROUPS = ("android", "linux", "windows")
KEY_RE = re.compile(r"\A[0-9a-f]{12}\Z")
CHECKSUM_RE = re.compile(r"\A[0-9a-f]{64}\Z")


def url_identity(url: str) -> str:
    """The identity SwiftPM derives from a repository URL."""
    tail = url.rstrip("/")
    if tail.endswith(".git"):
        tail = tail[:-4]
    return tail.rsplit("/", 1)[-1].lower()


# The `*/ = {` suffix is what makes this anchor unique: the same comment appears
# in packageReferences lists and product dependencies, but only the object
# definition opens a brace. The package name is not anchored -- it tracks the
# repo and moves with it -- so matches are filtered by the URL's identity.
PACKAGE_REFERENCE = re.compile(
    r'/\* XCRemoteSwiftPackageReference "(?P<name>[^"]+)" \*/ = \{\n'
    r"(?:[^\n]*\n)*?"
    r'[\t ]*repositoryURL = "(?P<url>[^"]+)";\n'
    r"(?:[^\n]*\n)*?"
    r"(?P<indent>[\t ]*)requirement = \{\n"
    r"(?P<body>(?:[^\n]*\n)*?)"
    r"(?P=indent)\};\n"
)
PIN = re.compile(
    r'"identity"[ \t]*:[ \t]*"(?P<identity>[^"]+)",\n'
    r"(?:[^\n]*\n)*?"
    r'[ \t]*"location"[ \t]*:[ \t]*"(?P<url>[^"]+)",\n'
    r"(?:[^\n]*\n)*?"
    r'(?P<indent>[ \t]*)"state"[ \t]*:[ \t]*\{\n'
    r"(?P<body>(?:[^\n]*\n)*?)"
    r"(?P=indent)\}"
)

errors: list[str] = []
notes: list[str] = []
writes: list[tuple[str, str]] = []
unchanged: list[str] = []


def sole_pin(pattern: re.Pattern[str], text: str, path: str) -> re.Match[str] | None:
    """The one match that is the native pin, judged by its URL's identity."""
    matches = [
        match
        for match in pattern.finditer(text)
        if url_identity(match.group("url")) in ACCEPTED_IDENTITIES
    ]
    if len(matches) != 1:
        errors.append(f"{path}: expected exactly 1 native pin, found {len(matches)}")
        return None
    return matches[0]


def splice(text: str, match: re.Match[str], replacements: list[tuple[str, str]]) -> str:
    """text with each named group's matched span replaced by new content."""
    parts = []
    cursor = 0
    for group, new in sorted(replacements, key=lambda item: match.start(item[0])):
        start, end = match.span(group)
        parts.append(text[cursor:start])
        parts.append(new)
        cursor = end
    parts.append(text[cursor:])
    return "".join(parts)


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
            if isinstance(item, dict) and item.get("identity") in ACCEPTED_IDENTITIES
        ),
        None,
    )
    if pin is None:
        errors.append(f"{path}: no native pin")
        return False
    if pin.get("kind") != "remoteSourceControl":
        errors.append(f"{path}: native pin is {pin.get('kind')!r}, expected remoteSourceControl")
        return False
    return True


def load_manifest(name: str, label: str) -> dict | None:
    try:
        payload = json.loads((manifest_dir / name).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"{label} at {revision[:12]}: not valid JSON ({error})")
        return None
    if not isinstance(payload, dict):
        errors.append(f"{label} at {revision[:12]}: expected a JSON object")
        return None
    return payload


def build_lock() -> str | None:
    """The lock file's content for this commit, or None with errors recorded.

    Schema documented in this script's header comment. The versions.json read
    is a guard, not a data source: a commit without formatVersion 1 predates
    the unified repo, and pinning it would name artifacts that do not exist.
    """
    versions = load_manifest("versions.json", "versions.json")
    manifest = load_manifest("artifacts.json", "artifacts.json")
    if versions is None or manifest is None:
        return None
    if versions.get("formatVersion") != 1:
        errors.append(
            f"versions.json at {revision[:12]}: formatVersion is "
            f"{versions.get('formatVersion')!r}, expected 1"
        )
        return None
    if manifest.get("schema") != 2:
        errors.append(
            f"artifacts.json at {revision[:12]}: schema is "
            f"{manifest.get('schema')!r}, expected 2"
        )
        return None
    platforms = manifest.get("platforms")
    if not isinstance(platforms, dict):
        errors.append(f"artifacts.json at {revision[:12]}: no platforms object")
        return None

    artifacts: dict[str, dict] = {}
    for group in sorted(platforms):
        if group == "apple":
            continue  # Apple consumes the SwiftPM pin sites, not the lock.
        section = platforms[group]
        label = f"artifacts.json platforms.{group}"
        if not isinstance(section, dict):
            errors.append(f"{label}: expected an object")
            continue
        asset_base = section.get("assetBase")
        if not isinstance(asset_base, str) or not asset_base:
            errors.append(f"{label}.assetBase: missing")
            continue
        libraries = section.get("libraries")
        if not isinstance(libraries, dict):
            errors.append(f"{label}.libraries: expected an object")
            continue
        if not libraries:
            notes.append(
                f"note: {group} has published no libraries at this commit; "
                f"omitted from {LOCK_PATH}"
            )
            continue
        if len(libraries) != 1:
            errors.append(
                f"{label}: {LOCK_PATH} formatVersion 1 records exactly one "
                f"library per group, found {sorted(libraries)}; bump the lock format"
            )
            continue
        ((library, entry),) = libraries.items()
        label = f"{label}.libraries.{library}"
        if not isinstance(entry, dict):
            errors.append(f"{label}: expected an object")
            continue
        key = entry.get("key")
        if not isinstance(key, str) or not KEY_RE.fullmatch(key):
            errors.append(f"{label}.key: {key!r} is not a 12-hex content key")
            continue
        prebuilt = entry.get("prebuilt")
        if not isinstance(prebuilt, dict) or not prebuilt:
            errors.append(f"{label}.prebuilt: no per-variant assets recorded")
            continue
        assets: dict[str, dict[str, str]] = {}
        for variant in sorted(prebuilt):
            value = prebuilt[variant]
            if not isinstance(value, dict):
                errors.append(
                    f"{label}.prebuilt.{variant}: {value!r} carries no checksum; "
                    f"refusing an unverifiable pin"
                )
                continue
            asset = value.get("asset")
            checksum = value.get("checksum")
            if not isinstance(asset, str) or not asset:
                errors.append(f"{label}.prebuilt.{variant}.asset: missing")
                continue
            if not isinstance(checksum, str) or not CHECKSUM_RE.fullmatch(checksum):
                errors.append(
                    f"{label}.prebuilt.{variant}.checksum: {checksum!r} is not a "
                    f"full lowercase SHA-256"
                )
                continue
            assets[variant] = {"asset": asset, "checksum": checksum}
        if len(assets) != len(prebuilt):
            continue
        artifacts[group] = {"assetBase": asset_base, "assets": assets, "key": key}

    for group in EXPECTED_GROUPS:
        if group not in artifacts and group not in platforms:
            notes.append(
                f"note: no {group} artifacts published at this commit; "
                f"omitted from {LOCK_PATH}"
            )

    lock = {
        "artifacts": artifacts,
        "commit": revision,
        "formatVersion": 1,
        "repo": LOCK_REPO,
    }
    return json.dumps(lock, indent=2, sort_keys=True) + "\n"


for path in projects:
    with open(path, encoding="utf-8") as handle:
        original = handle.read()

    match = sole_pin(PACKAGE_REFERENCE, original, path)
    if match is None:
        continue
    indent = match.group("indent")
    updated = splice(
        original,
        match,
        [
            ("url", TARGET_URL),
            ("body", f"{indent}\tkind = revision;\n{indent}\trevision = {revision};\n"),
        ],
    )
    # Xcode derives the `XCRemoteSwiftPackageReference "<name>"` comments from
    # the URL; every mention of the old name refers to this one reference, so
    # renaming them all keeps the file exactly as Xcode would regenerate it.
    old_name = match.group("name")
    if old_name != TARGET_NAME:
        updated = updated.replace(
            f'/* XCRemoteSwiftPackageReference "{old_name}" */',
            f'/* XCRemoteSwiftPackageReference "{TARGET_NAME}" */',
        )
    if updated == original:
        unchanged.append(path)
    else:
        writes.append((path, updated))

for path in locks:
    with open(path, encoding="utf-8") as handle:
        original = handle.read()
    if not check_lock_schema(path, original):
        continue

    match = sole_pin(PIN, original, path)
    if match is None:
        continue
    indent = match.group("indent")
    updated = splice(
        original,
        match,
        [
            ("identity", TARGET_IDENTITY),
            ("url", TARGET_URL),
            ("body", f'{indent}  "revision" : "{revision}"\n'),
        ],
    )
    if updated == original:
        unchanged.append(path)
    else:
        writes.append((path, updated))

lock_content = build_lock()
if lock_content is not None:
    try:
        existing_lock = Path(LOCK_PATH).read_text(encoding="utf-8")
    except OSError:
        existing_lock = None
    if lock_content == existing_lock:
        unchanged.append(LOCK_PATH)
    else:
        writes.append((LOCK_PATH, lock_content))

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
for note in notes:
    print(note)

short = f"{LOCK_REPO}@{revision[:12]}"
if writes:
    print(f"\nNative pin moved to {short} ({len(writes)} file(s) rewritten, {len(unchanged)} already correct).")
else:
    print(f"\nNative pin was already at {short}; nothing to do.")
PY
