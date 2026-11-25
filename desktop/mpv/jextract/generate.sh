#!/usr/bin/env bash
# Regenerates the libmpv FFM bindings in desktop/mpv/src/main/java/com/edde746/plezy/mpv/ffi from the headers of the
# pinned mpv-build artifact (mpv-build.lock.json), with a pinned jextract build. Run it after
# tools/set_native_revision.sh moves the pin, and commit the result.
#
# Usage: desktop/mpv/jextract/generate.sh        (macOS arm64 or Linux x64 host)
# Env:   MPV_INCLUDE=<dir containing mpv/client.h> to skip the Gradle header fetch.
#
# The output is portable across every 64-bit desktop target (Windows x64 is LLP64, Linux and macOS are LP64) because:
#   - mpv.includes leaves out the one declaration that uses C `long` (mpv_client_api_version) and its macro;
#   - C_LONG, which jextract always emits and which size_t resolves to on LP64 hosts, is pinned to JAVA_LONG: size_t is
#     64-bit on all of those targets, while the canonical `long` layout is 32-bit on Windows;
#   - the library lookup is MpvNatives.lookup(), which loads libmpv by absolute path from the resolved natives
#     directory instead of the loader/default lookup.
# The script fails if a regenerated header starts using C `long` anywhere else.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
out="$repo/desktop/mpv/src/main/java/com/edde746/plezy/mpv/ffi"
package=com.edde746.plezy.mpv.ffi

# jextract 25-jextract+2-4 (2025/11/25), https://jdk.java.net/jextract/
jx_version=25-2-4
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) jx_os=macos-aarch64 jx_sha=3dd1dd1bde059d271739e2cc2290c64f93f85488c86c01e566c0e374eece798f ;;
  Linux-x86_64) jx_os=linux-x64 jx_sha=d0cc481abc1adb16fb9514e1c5e0bfc08d38c29228bece667fb5054ceaffaa42 ;;
  *) echo "no pinned jextract for $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac
cache="${XDG_CACHE_HOME:-$HOME/.cache}/plezy/jextract-$jx_version-$jx_os"
jextract="$cache/jextract-25/bin/jextract"
if [[ ! -x $jextract ]]; then
  mkdir -p "$cache"
  tarball="$cache/jextract.tar.gz"
  curl -fsSL -o "$tarball" "https://download.java.net/java/early_access/jextract/25/2/openjdk-25-jextract+2-4_${jx_os}_bin.tar.gz"
  actual=$( (command -v sha256sum >/dev/null && sha256sum "$tarball" || shasum -a 256 "$tarball") | cut -d' ' -f1)
  [[ $actual == "$jx_sha" ]] || { rm -f "$tarball"; echo "jextract checksum mismatch: $actual" >&2; exit 1; }
  # Unpacked beside its place and moved there whole: an unpack cut short leaves no jextract for the next run to reuse.
  rm -rf "$cache/jextract-25" "$cache/unpacking"
  mkdir "$cache/unpacking"
  tar -xzf "$tarball" -C "$cache/unpacking"
  mv "$cache/unpacking/jextract-25" "$cache/jextract-25"
  rmdir "$cache/unpacking"
  rm "$tarball"
  [[ $(uname -s) == Darwin ]] && xattr -r -d com.apple.quarantine "$cache" 2>/dev/null || true
fi

if [[ -z ${MPV_INCLUDE:-} ]]; then
  case "$(uname -m)" in arm64|aarch64) variant=aarch64 task=fetchMpvAarch64 ;; *) variant=x86_64 task=fetchMpvX8664 ;; esac
  (cd "$repo" && ./gradlew -q -Pplezy.android=false ":mpv-jvm:$task")
  MPV_INCLUDE="$repo/desktop/mpv/build/mpv/$variant/include"
fi
[[ -f $MPV_INCLUDE/mpv/client.h ]] || { echo "no mpv/client.h under $MPV_INCLUDE" >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
"$jextract" --version | head -1
"$jextract" -I "$MPV_INCLUDE" -t "$package" --header-class-name MpvFfi --output "$tmp" \
  @"$here/mpv.includes" "$here/mpv.h"
gen="$tmp/${package//.//}"

# C declarations are quoted in the generated javadoc snippets; `long long` is fine, plain `long` is not portable.
if grep -hE '^\s*\* .*\blong\b' "$gen"/*.java | grep -vE '\blong long\b' | grep -q .; then
  echo "generated bindings use C 'long'; exclude that declaration in mpv.includes:" >&2
  grep -nE '^\s*\* .*\blong\b' "$gen"/*.java | grep -vE '\blong long\b' >&2
  exit 1
fi

perl -0pi -e 's/static final SymbolLookup SYMBOL_LOOKUP = SymbolLookup\.loaderLookup\(\)\s*\.or\(Linker\.nativeLinker\(\)\.defaultLookup\(\)\);/static final SymbolLookup SYMBOL_LOOKUP = com.edde746.plezy.mpv.MpvNatives.lookup();/' "$gen/MpvFfi.java"
grep -q 'SYMBOL_LOOKUP = com.edde746.plezy.mpv.MpvNatives.lookup();' "$gen/MpvFfi.java" || { echo "SYMBOL_LOOKUP rewrite failed" >&2; exit 1; }

shared="$gen/MpvFfi\$shared.java"
perl -pi -e 's/^(\s*public static final ValueLayout\.OfLong C_LONG = ).*$/$1ValueLayout.JAVA_LONG; \/\/ size_t: 64-bit on every target (see desktop\/mpv\/jextract\/generate.sh)/' "$shared"
grep -q 'C_LONG = ValueLayout.JAVA_LONG;' "$shared" || { echo "C_LONG rewrite failed" >&2; exit 1; }

rm -rf "$out"
mkdir -p "$out"
cp "$gen"/*.java "$out/"
echo "wrote $(ls "$out" | wc -l | tr -d ' ') files to ${out#"$repo"/}"
