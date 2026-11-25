#!/usr/bin/env bash
# Moves Plezy's mpv dependency to commits of github.com/edde746/mpv-build.
#
# mpv-build publishes content-addressed binaries on every push to main, so a commit names the exact bytes for
# every platform. Each platform records its own commit, and these sites carry the pins:
#   mpv-build.lock.json                 every platform's commit; Android's AAR and the Linux and Windows tarballs
#                                       (Linux and Windows read by build-logic's plezy.mpv-artifacts plugin;
#                                       Android's by settings.gradle.kts)
#   gradle/verification-metadata.xml    the Android AAR's sha256 again, which Gradle's dependency verification checks
#   apple/project.yml                   the MPVKit Swift package revision (the line tagged "# mpv-build pin"), which
#                                       must equal the lock's apple commit (the plezy.mpv-artifacts plugin fails
#                                       the build when they differ)
#
# mpv-build.lock.json schema (JSON has no comments):
#   {
#     "formatVersion": 2,
#     "repo": "edde746/mpv-build",
#     "artifacts": {
#       "apple": {                    MPVKit, which Swift Package Manager resolves from mpv-build itself
#         "commit": "<40-char sha>",  the revision apple/project.yml pins
#         "key": "<12-hex>"           its libmpv's content-address key
#       },
#       "android": {                  the mpv-android library (artifacts.json's mpv-android entry)
#         "commit": "<40-char sha>",  the mpv-build commit this platform is pinned to
#         "assetBase": "https://...", the group's release download base
#         "aar": {
#           "key": "<12-hex>",        its content-address key: the version Gradle resolves
#           "asset": "<file name>",   downloaded as <assetBase>/<asset>
#           "checksum": "<sha256>",
#           "assetBase": "https://..."  only when artifacts.json records one: the release of the publish run that
#                                       built it, which <assetBase>/<asset> uses instead of the group's
#         },
#         "symbols": {                the AAR's libraries unstripped, one zip per ABI (tools/upload_symbols.sh)
#           "<abi>": {"asset": ..., "checksum": ..., "assetBase": ...}  as the aar's
#         }
#       },
#       "<group>": {                  linux | windows
#         "commit": "<40-char sha>",  as android's
#         "key": "<12-hex>",          the group's content-address key
#         "assetBase": "https://...", the group's release download base
#         "assets": {
#           "<variant>": {            CPU arch
#             "asset": "<file name>", downloaded as <assetBase>/<asset>
#             "checksum": "<sha256>",
#             "assetBase": "https://..."  as the aar's: the asset's own release, when it has one
#           }
#         },
#         "symbols": {                the libraries of each variant's asset unstripped (Windows: their PDBs), one
#           "<variant>": {...}        zip per variant, as the assets' entries (tools/upload_symbols.sh)
#         }
#       }
#     }
#   }
# mpv-build uploads each publish run's binaries to a release of its own (binaries-<commit>) and leaves a library
# whose sources did not change where an older run put it, so one commit's assets can sit in several releases. An
# asset recorded before that (in the group's binaries-<group> release) has no assetBase of its own.
# Serialization is deterministic (two-space indent, sorted keys, trailing newline). A group the commit has not
# published is omitted and reported; consumers then fail instead of falling back to an unpinned source. So are a
# group's symbols, when the commit publishes none for it: tools/upload_symbols.sh then fails for that group.
#
# Usage: tools/set_native_revision.sh [--only <android|linux|windows|apple>] <40-char sha | latest>
#   latest = the current head of mpv-build's main branch. Without --only every platform moves to the commit; with it
#   only that platform's entry (and for android gradle/verification-metadata.xml, for apple apple/project.yml) does.
set -euo pipefail
cd "$(dirname "$0")/.."
repo="edde746/mpv-build"
usage="usage: $0 [--only <android|linux|windows|apple>] <40-char sha | latest>"
only=""
if [[ "${1:-}" == --only ]]; then
  only="${2:?$usage}"
  shift 2
  [[ "$only" =~ ^(android|linux|windows|apple)$ ]] || { echo "unknown platform: $only" >&2; exit 1; }
fi
rev="${1:?$usage}"
if [[ "$rev" == latest ]]; then
  rev=$(curl -fsSL "https://api.github.com/repos/$repo/commits/main" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sha"])')
fi
[[ "$rev" =~ ^[0-9a-f]{40}$ ]] || { echo "not a full commit sha: $rev" >&2; exit 1; }

manifest=$(curl -fsSL "https://raw.githubusercontent.com/$repo/$rev/artifacts.json")
REPO="$repo" REV="$rev" ONLY="$only" python3 - "$manifest" <<'EOF'
import json, os, sys
manifest = json.loads(sys.argv[1])
rev, only = os.environ["REV"], os.environ["ONLY"]
if only:
    with open("mpv-build.lock.json") as f:
        out = json.load(f)
    if out.get("formatVersion") != 2:
        sys.exit(f"mpv-build.lock.json has formatVersion {out.get('formatVersion')}; move every platform first (no --only)")
else:
    out = {"formatVersion": 2, "repo": os.environ["REPO"], "artifacts": {}}

def located(recorded, entry):
    """entry, plus the asset's own release download base when artifacts.json records one."""
    if recorded.get("assetBase"):
        entry["assetBase"] = recorded["assetBase"]
    return entry

def pinned(variants):
    """Each variant's asset, checksum and own download base."""
    return {v: located(a, {"asset": a["asset"], "checksum": a["checksum"]}) for v, a in variants.items()}

for group in [only] if only else ("android", "apple", "linux", "windows"):
    platform = manifest.get("platforms", {}).get(group)
    libs = (platform or {}).get("libraries", {})
    out["artifacts"].pop(group, None)
    if group == "android":
        lib = libs.get("mpv-android")
    elif group == "apple":
        lib = libs.get("libmpv")
    else:
        lib = libs.get(f"libmpv-{group}")
        lib = lib if lib and lib.get("prebuilt") else None
    if not lib:
        if only or group == "apple":
            sys.exit(f"{group} is not published at {rev}")
        print(f"note: {group} is not published at this commit; omitted")
        continue
    if group == "android":
        out["artifacts"][group] = {
            "commit": rev,
            "assetBase": platform["assetBase"],
            "aar": located(lib, {"key": lib["key"], "asset": lib["asset"], "checksum": lib["checksum"]}),
        }
    elif group == "apple":
        out["artifacts"][group] = {"commit": rev, "key": lib["key"]}
    else:
        out["artifacts"][group] = {
            "commit": rev,
            "key": lib["key"],
            "assetBase": platform["assetBase"],
            "assets": pinned(lib["prebuilt"]),
        }
    if group != "apple":
        if lib.get("symbols"):
            out["artifacts"][group]["symbols"] = pinned(lib["symbols"])
        else:
            print(f"note: {group} publishes no symbols at this commit; omitted")
with open("mpv-build.lock.json", "w") as f:
    json.dump(out, f, indent=2, sort_keys=True)
    f.write("\n")
pins = {g: (a["commit"][:12], (a.get("aar") or a)["key"]) for g, a in out["artifacts"].items()}
print("mpv-build.lock.json (commit, key) ->", pins)
if only and only != "android":
    sys.exit(0)

# Gradle verifies only what this names; every other dependency stays trusted, as without the file.
aar = out["artifacts"].get("android", {}).get("aar")
component = "" if not aar else f"""
      <component group="edde746" name="mpv-android" version="{aar['key']}">
         <artifact name="mpv-android-{aar['key']}.aar">
            <sha256 value="{aar['checksum']}" origin="mpv-build.lock.json"/>
         </artifact>
      </component>"""
with open("gradle/verification-metadata.xml", "w") as f:
    f.write(f"""<?xml version="1.0" encoding="UTF-8"?>
<!-- Written by tools/set_native_revision.sh with mpv-build.lock.json: the mpv-android AAR's sha256, checked by Gradle
     wherever it resolves the AAR. Every other group is trusted. -->
<verification-metadata xmlns="https://schema.gradle.org/dependency-verification" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="https://schema.gradle.org/dependency-verification https://schema.gradle.org/dependency-verification/dependency-verification-1.3.xsd">
   <configuration>
      <verify-metadata>true</verify-metadata>
      <verify-signatures>false</verify-signatures>
      <trusted-artifacts>
         <trust group="^(?!edde746$).*$" regex="true"/>
      </trusted-artifacts>
   </configuration>
   <components>{component}
   </components>
</verification-metadata>
""")
print("gradle/verification-metadata.xml ->", aar["key"] if aar else "no mpv-android")
EOF

[[ -z "$only" || "$only" == apple ]] || exit 0
yml=apple/project.yml
pin='^([[:space:]]*revision: )[0-9a-f]{40}([[:space:]]*# mpv-build pin)'
n=$(grep -cE "$pin" "$yml" || [[ $? == 1 ]])
[[ "$n" == 1 ]] || { echo "$yml: expected exactly one 'revision: <sha> # mpv-build pin' line, found $n" >&2; exit 1; }
sed -i.bak -E "s/$pin/\1$rev\2/" "$yml" && rm -f "$yml.bak"
grep -qE "^[[:space:]]*revision: ${rev}[[:space:]]*# mpv-build pin" "$yml" || { echo "$yml: the pin did not move to $rev" >&2; exit 1; }
echo "$yml -> $rev"
