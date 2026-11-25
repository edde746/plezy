#!/usr/bin/env bash
# Uploads debug files to the crash-report server, edde746/bugs, which takes sentry-cli's chunked uploads, with the
# sentry-cli release below (checked against its sha256). It waits until the server has processed each file (600 s at
# most, the wait bugs advertises by default) and fails when sentry-cli took fewer files than it was given (a server
# whose upload accept list lacks a format drops those files without an error). The release workflow runs it: the
# Android, Linux and Windows jobs for the native libraries they ship, the Apple jobs for their dSYMs.
#
# dsym uploads the dSYMs found in the paths. android, linux and windows upload, for each native library the release
# ships, its debug file:
# - the libraries mpv-build built (Android: mpv-android's libmpv, FFmpeg and JNI glue; desktop: libmpv, below the app
#   image's resources/mpv/: libmpv-2.dll at its root, lib/<multiarch>/libmpv.so.2 on Linux) ship stripped; their
#   unstripped copies (Windows: their PDBs, with the DLL itself, whose unwind tables the PDB lacks) come from the
#   symbols zips pinned in mpv-build.lock.json (schema:
#   tools/set_native_revision.sh), downloaded and checked against their sha256, and are matched to the shipped
#   library by debug ID (an ELF's build ID, a PE's CodeView ID). A library of mpv-build's without a debug file of the
#   same ID, or a variant without pinned symbols, fails the upload: the pin and the build disagree.
# - an Android library mpv-build didn't build (Sentry's, AndroidX's) has no debug file elsewhere: it uploads as packed,
#   its symbol table and unwind tables.
# The desktop image's other native code is the Java runtime's and Compose's, whose builders publish no debug files.
#
# Usage: tools/upload_symbols.sh dsym <path>...
#        tools/upload_symbols.sh android <apk or aab>...
#        tools/upload_symbols.sh <linux|windows> <app image directory>
#   tools/upload_symbols.sh android plezy-android.aab plezy-amazon.apk android/app/build/outputs/apk/release/*.apk
#   DRY_RUN=1 tools/upload_symbols.sh windows desktop/app/build/compose/binaries/main-release/app/Plezy
# Env: SENTRY_AUTH_TOKEN (the server's admin token), SENTRY_URL, SENTRY_ORG, SENTRY_PROJECT (the project's slug)
#      DRY_RUN=1  android, linux and windows: list each shipped library's debug ID and the files that would upload
#                 for it, then stop (no token needed)
# A new version: change the version and every checksum together.
set -euo pipefail
version=3.8.2
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) asset=sentry-cli-Linux-x86_64 sha256=c958865f9d4000183509ea21b1f04925d5390de6d8d87386b9e69f2b305070c3 ;;
  Linux-aarch64) asset=sentry-cli-Linux-aarch64 sha256=b6e49fca868a36d20da2ada1832a0ce2f9ac7012c128207518b09d6b6c991f4d ;;
  Darwin-*) asset=sentry-cli-Darwin-universal sha256=2d1b118fa46960ba5e8e0cca9a6e197366905776a0ddc5a89c7d05a3908b77db ;;
  MINGW*-x86_64 | MSYS*-x86_64) asset=sentry-cli-Windows-x86_64.exe sha256=50009f23c49d6e9ff7624204c7035855303b49c5e326708ee783c1fdf783ac83 ;;
  MINGW*-aarch64 | MSYS*-aarch64) asset=sentry-cli-Windows-aarch64.exe sha256=3c197c61120e2d53a6ecfd9e7812d123bfdc598df1d569700bf5c3b936dfe891 ;;
  *) echo "upload_symbols.sh: no sentry-cli for $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac

usage="usage: $0 dsym <path>... | android <apk or aab>... | <linux|windows> <app image directory>"
group=${1:?$usage}
shift
(($#)) || { echo "$usage" >&2; exit 2; }
case $group in
  dsym) [[ -z ${DRY_RUN:-} ]] || { echo "upload_symbols.sh: DRY_RUN is for android, linux and windows" >&2; exit 2; } ;;
  android) ;;
  linux | windows) (($# == 1)) || { echo "$usage" >&2; exit 2; } ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
for path in "$@"; do
  [[ -e $path ]] || { echo "upload_symbols.sh: $path doesn't exist" >&2; exit 1; }
done
# The first Python 3.11 or later (hashlib.file_digest); Windows may have a python3 that only opens its store.
python=
for candidate in python3 python; do
  if "$candidate" -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2> /dev/null; then python=$candidate; break; fi
done
[[ -n $python ]] || { echo "upload_symbols.sh: no Python 3.11 or later" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# Git Bash's /tmp is no path to the Windows Python.
if command -v cygpath > /dev/null; then tmp=$(cygpath -m "$tmp"); fi
cli="$tmp/$asset"
curl -fsSL --retry 3 --max-time 300 -o "$cli" "https://github.com/getsentry/sentry-cli/releases/download/$version/$asset"
[[ $("$python" -c 'import hashlib,sys; print(hashlib.file_digest(open(sys.argv[1],"rb"),"sha256").hexdigest())' "$cli") == "$sha256" ]] ||
  { echo "upload_symbols.sh: $asset doesn't have the sha256 $sha256" >&2; exit 1; }
chmod +x "$cli"

if [[ $group == dsym ]]; then
  files=("$@")
  args=(--type dsym)
else
  "$python" - "$cli" "$tmp" "$(dirname "$0")/../mpv-build.lock.json" "$group" "$@" > "$tmp/plan.txt" <<'EOF'
import hashlib, json, os, re, subprocess, sys, urllib.request, zipfile

cli, tmp, lock_path, group, inputs = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5:]

def fail(message):
    sys.exit(f"upload_symbols.sh: {message}")

def identify(path):
    """sentry-cli's reading of an object file: (type, debug ID, arch, features)."""
    out = subprocess.run([cli, "debug-files", "check", "--json", path], capture_output=True, text=True)
    try:
        info = json.loads(out.stdout)
    except ValueError:
        fail(f"sentry-cli can't read {path}: {out.stderr.strip()}")
    if len(info.get("variants", [])) != 1:
        fail(f"{path} isn't one object file")
    v = info["variants"][0]
    return info["type"], v["debug_id"].lower(), v["arch"], info["features"]

# The shipped libraries: (variant, name, path).
shipped = []
if group == "android":
    for package in inputs:
        with zipfile.ZipFile(package) as z:
            for entry in z.namelist():
                m = re.fullmatch(r"(?:base/)?lib/([^/]+)/([^/]+\.so)", entry)
                if m:
                    path = os.path.join(tmp, "shipped", str(len(shipped)), m[2])
                    os.makedirs(os.path.dirname(path))
                    with open(path, "wb") as f:
                        f.write(z.read(entry))
                    shipped.append((m[1], f"{os.path.basename(package)}:{entry}", path))
else:
    for root, _, names in os.walk(inputs[0]):
        parts = os.path.relpath(root, inputs[0]).split(os.sep)
        if any(a == "resources" and b == "mpv" for a, b in zip(parts, parts[1:])):
            for name in names:
                if re.search(r"\.(so(\.\d+)*|dll)$", name):
                    shipped.append((None, os.path.relpath(os.path.join(root, name), inputs[0]), os.path.join(root, name)))
    if not shipped:
        fail(f"{inputs[0]} has no resources/mpv/ library: not an app image")

identities = {}
for i, (variant, name, path) in enumerate(shipped):
    kind, debug_id, arch, _ = identify(path)
    if variant is None:
        variant = {"x86_64": "x86_64", "arm64": "aarch64"}.get(arch) or fail(f"{name}: no {group} variant for {arch}")
    shipped[i] = (variant, name, path)
    identities[path] = (kind, debug_id, arch)

with open(lock_path) as f:
    section = json.load(f)["artifacts"].get(group) or fail(f"mpv-build.lock.json has no {group} group")
debug_files = {}  # variant -> {debug ID: path}
for variant in sorted({v for v, _, _ in shipped}):
    entry = section.get("symbols", {}).get(variant) or fail(f"mpv-build.lock.json pins no {group} symbols for {variant}")
    url = f"{entry.get('assetBase') or section['assetBase']}/{entry['asset']}"
    archive = os.path.join(tmp, entry["asset"])
    urllib.request.urlretrieve(url, archive)
    with open(archive, "rb") as f:
        digest = hashlib.file_digest(f, "sha256").hexdigest()
    if digest != entry["checksum"]:
        fail(f"{url} has the sha256 {digest}, not the pinned {entry['checksum']}")
    directory = os.path.join(tmp, "symbols", variant)
    with zipfile.ZipFile(archive) as z:
        names = [n for n in z.namelist() if not n.endswith("/")]
        if any("/" in n or "\\" in n or n.startswith(".") for n in names):
            fail(f"{url} holds files outside its root")
        z.extractall(directory, names)
    debug_files[variant] = {}
    for name in names:
        _, debug_id, _, _ = identify(os.path.join(directory, name))
        debug_files[variant][debug_id] = os.path.join(directory, name)

# Each shipped library's debug ID (once, under its first name) and the files that upload for it, a line each; the files
# alone in files.txt.
uploads = []
listed = set()
for variant, name, path in shipped:
    kind, debug_id, arch = identities[path]
    if debug_id in listed:
        continue
    listed.add(debug_id)
    debug = debug_files[variant].get(debug_id)
    library = os.path.basename(path)
    built = {os.path.basename(p) for p in debug_files[variant].values()}
    if debug:
        files = [debug] + ([path] if kind == "pe" else [])
    elif group == "android" and library not in built:
        files = [path]
    else:
        fail(f"{name} ({debug_id}) has no debug file in mpv-build's {variant} symbols: {', '.join(sorted(built))}")
    print(f"{debug_id} {arch} {name} <- {', '.join(os.path.relpath(f, tmp) if f.startswith(tmp) else name for f in files)}")
    uploads += [f for f in files if f not in uploads]
# "\n" alone: bash's read keeps a "\r", which Windows' text mode would add, in the path.
with open(os.path.join(tmp, "files.txt"), "w", newline="\n") as f:
    f.write("\n".join(uploads) + "\n")
EOF
  cat "$tmp/plan.txt"
  [[ -z ${DRY_RUN:-} ]] || exit 0
  files=()
  while IFS= read -r file; do files+=("$file"); done < "$tmp/files.txt"
  args=(--no-zips)
fi

"$cli" debug-files upload "${args[@]}" --wait-for 600 "${files[@]}" 2>&1 | tee "$tmp/upload.log"
found=$(sed 's/\x1b\[[0-9;]*m//g' "$tmp/upload.log" | sed -nE 's/.*Found ([0-9]+) debug information files?.*/\1/p' | head -n 1)
if [[ $group == dsym ]]; then
  ((${found:-0} > 0)) || { echo "upload_symbols.sh: sentry-cli found no dSYM in $*" >&2; exit 1; }
else
  ((${found:-0} >= ${#files[@]})) ||
    { echo "upload_symbols.sh: sentry-cli took ${found:-none} of the ${#files[@]} debug files" >&2; exit 1; }
fi
