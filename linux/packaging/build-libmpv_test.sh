#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=build-libmpv.sh
source "$SCRIPT_DIR/build-libmpv.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_absent() {
  [ ! -e "$1" ] || fail "unexpected path remains: $1"
}

init_repository() {
  mkdir -p "$1"
  git -C "$1" init --quiet
  git -C "$1" config user.name "Plezy provenance test"
  git -C "$1" config user.email "provenance-test@invalid.example"
}

temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

fixture="$temporary/source.bin"
destination="$temporary/download/output.bin"
printf 'reviewed native input\n' >"$fixture"
expected="$(sha256_file "$fixture")"
download_verified "file://$fixture" "$expected" "$destination"
cmp -s "$fixture" "$destination" || fail "verified download changed bytes"

printf 'reviewed native inpuu\n' >"$fixture"
rm -f "$destination"
if download_verified "file://$fixture" "$expected" "$destination"; then
  fail "changed archive was accepted"
fi
assert_absent "$destination"
if compgen -G "$destination.tmp.*" >/dev/null; then
  fail "failed download left a temporary file"
fi

repository="$temporary/repository"
checkout="$temporary/checkout"
init_repository "$repository"
printf 'first\n' >"$repository/input.txt"
git -C "$repository" add input.txt
git -C "$repository" commit --quiet -m first
git -C "$repository" tag release
approved_commit="$(git -C "$repository" rev-parse HEAD)"
checkout_verified_ref "file://$repository" release "$approved_commit" "$checkout"
[ "$(git -C "$checkout" rev-parse HEAD)" = "$approved_commit" ] ||
  fail "verified checkout selected the wrong commit"

# A dead primary must fall through to the mirror, because the whole point is
# that one unreachable host cannot stop the build. This runs while the tag still
# points at the approved commit; the moved-tag case is below.
unreachable="file://$temporary/definitely-not-a-repository"
checkout_verified_ref "$unreachable" release "$approved_commit" "$checkout" "file://$repository"
[ "$(git -C "$checkout" rev-parse HEAD)" = "$approved_commit" ] ||
  fail "mirror fallback selected the wrong commit"

# And the mirror answers to the same pin. A mirror serving a different tree is
# the one thing a fallback must never quietly accept.
mirror_repository="$temporary/mirror"
init_repository "$mirror_repository"
printf 'substituted\n' >"$mirror_repository/input.txt"
git -C "$mirror_repository" add input.txt
git -C "$mirror_repository" commit --quiet -m substituted
git -C "$mirror_repository" tag release
if checkout_verified_ref "$unreachable" release "$approved_commit" "$checkout" "file://$mirror_repository"; then
  fail "mirror serving another commit was accepted"
fi
assert_absent "$checkout"

printf 'second\n' >"$repository/input.txt"
git -C "$repository" commit --quiet -am second
git -C "$repository" tag --force release >/dev/null
if checkout_verified_ref "file://$repository" release "$approved_commit" "$checkout"; then
  fail "moved tag was accepted"
fi
assert_absent "$checkout"

# ─── The build plan ─────────────────────────────────────────────────────────
# Everything above checks how sources arrive. What they are then configured
# with decides whether the feature works at all, and it fails quietly: a libmpv
# built without -Dwayland=enabled still compiles, still links and still plays,
# it just has no Wayland backend, so the render context cannot accept
# MPV_RENDER_PARAM_WL_DISPLAY, vaapi finds no device and hardware decoding
# drops to a copy-back path. Nothing crashes, so nothing else notices. Run
# main() for real against stub build tools and assert the argument vectors they
# were handed.

stub_bin="$temporary/stub-bin"
stub_extra="$temporary/stub-extra"
records="$temporary/records"
mkdir -p "$stub_bin" "$stub_extra" "$records" "$temporary/tmp"

# Deliberately unlike the pinned versions: every path below is derived from the
# manifest, so a stub that matched by accident would prove nothing.
ffmpeg_version="9.9.9"
dav1d_version="2.2.2"
shaderc_version="6.6.6"
libplacebo_version="7.7.7"
mpv_version="8.8.8"

# Each stub records the vector it was called with, one argument per line, plus
# the directory it ran in - which is what tells mpv's meson call apart from
# libplacebo's. An argument containing a newline would corrupt the record, and
# none of these ever does: they are literal flags and mktemp -d paths.
make_stub() {
  local directory="$1" name="$2" extra="${3:-}"
  cat >"$directory/$name" <<STUB
#!/usr/bin/env bash
set -euo pipefail
record="\$(mktemp "$records/record.XXXXXX")"
{ printf '%s\n' "$name" "\$(pwd)"; [ \$# -eq 0 ] || printf '%s\n' "\$@"; } >"\$record"
$extra
STUB
  chmod +x "$directory/$name"
}

payload="$temporary/payload.bin"
printf 'stub archive payload\n' >"$payload"
payload_sha256="$(sha256_file "$payload")"

curl_extra='
output=""
previous=""
for argument in "$@"; do
  if [ "$previous" = "--output" ]; then output="$argument"; fi
  previous="$argument"
done
[ -n "$output" ] || { echo "stub curl: no --output argument" >&2; exit 1; }
cp -- "'"$payload"'" "$output"
'

# The unmapped case is fatal on purpose: a new archive in the build plan has to
# come here and be described rather than silently extract to nothing.
tar_extra='
archive="$(basename -- "${!#}")"
case "$archive" in
  ffmpeg.tar.xz) directory="ffmpeg-'"$ffmpeg_version"'" ;;
  mpv.tar.gz) directory="mpv-'"$mpv_version"'" ;;
  *) echo "stub tar: unexpected archive $archive" >&2; exit 1 ;;
esac
mkdir -p "$directory"
cp -- "'"$stub_extra"'/configure" "$directory/configure"
chmod +x "$directory/configure"
'

# ffmpeg runs ./configure out of its own tarball, so that one is planted by the
# tar stub rather than found on PATH.
make_stub "$stub_extra" configure
make_stub "$stub_bin" curl "$curl_extra"
make_stub "$stub_bin" tar "$tar_extra"
for tool in make cmake meson ninja; do
  make_stub "$stub_bin" "$tool"
done

# git stays real, pointed at local repositories: the checkout is pinned by
# commit, and a stub that answered rev-parse would be asserting its own input.
shaderc_repository="$temporary/shaderc-source"
init_repository "$shaderc_repository"
mkdir -p "$shaderc_repository/utils"
printf '#!/bin/sh\nexit 0\n' >"$shaderc_repository/utils/git-sync-deps"
chmod +x "$shaderc_repository/utils/git-sync-deps"
git -C "$shaderc_repository" add utils/git-sync-deps
# Windows checkouts do not track the mode bit, and the build plan executes it.
git -C "$shaderc_repository" update-index --chmod=+x utils/git-sync-deps
git -C "$shaderc_repository" commit --quiet -m shaderc
git -C "$shaderc_repository" tag release
shaderc_commit="$(git -C "$shaderc_repository" rev-parse HEAD)"

dav1d_repository="$temporary/dav1d-source"
init_repository "$dav1d_repository"
printf 'stub dav1d\n' >"$dav1d_repository/meson.build"
git -C "$dav1d_repository" add meson.build
git -C "$dav1d_repository" commit --quiet -m dav1d
git -C "$dav1d_repository" tag release
dav1d_commit="$(git -C "$dav1d_repository" rev-parse HEAD)"

libplacebo_repository="$temporary/libplacebo-source"
init_repository "$libplacebo_repository"
printf 'stub libplacebo\n' >"$libplacebo_repository/meson.build"
git -C "$libplacebo_repository" add meson.build
git -C "$libplacebo_repository" commit --quiet -m libplacebo
git -C "$libplacebo_repository" tag release
libplacebo_commit="$(git -C "$libplacebo_repository" rev-parse HEAD)"

manifest="$temporary/native-inputs.json"
cat >"$manifest" <<JSON
{
  "inputs": {
    "ffmpeg": {
      "version": "$ffmpeg_version",
      "url": "https://stub.invalid/ffmpeg.tar.xz",
      "sha256": "$payload_sha256"
    },
    "dav1d": {
      "version": "$dav1d_version",
      "url": "file://$dav1d_repository",
      "ref": "release",
      "commit": "$dav1d_commit"
    },
    "shaderc": {
      "version": "$shaderc_version",
      "url": "file://$shaderc_repository",
      "ref": "release",
      "commit": "$shaderc_commit"
    },
    "libplacebo": {
      "version": "$libplacebo_version",
      "url": "file://$libplacebo_repository",
      "ref": "release",
      "commit": "$libplacebo_commit"
    },
    "mpv": {
      "version": "$mpv_version",
      "url": "https://stub.invalid/mpv.tar.gz",
      "sha256": "$payload_sha256"
    }
  }
}
JSON

# JOBS keeps nproc out of it; TMPDIR keeps main()'s own mktemp -d inside the
# directory this test already cleans up.
build_log="$temporary/build.log"
if ! (
  export NATIVE_INPUTS_MANIFEST="$manifest"
  export PATH="$stub_bin:$PATH"
  export TMPDIR="$temporary/tmp"
  export PREFIX="$temporary/prefix"
  export JOBS=1
  bash "$SCRIPT_DIR/build-libmpv.sh"
) >"$build_log" 2>&1; then
  cat "$build_log" >&2
  fail "the stubbed build plan did not run to completion"
fi

recorded_call() {
  local program="$1" directory="$2" candidate
  for candidate in "$records"/record.*; do
    [ -f "$candidate" ] || continue
    if [ "$(sed -n 1p "$candidate")" = "$program" ] &&
      [ "$(basename -- "$(sed -n 2p "$candidate")")" = "$directory" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

# -Fxq, so this matches a whole recorded argument. A substring search would
# accept -Dwayland=enabled inside a comment, which is exactly the hole here.
assert_argument() {
  local record="$1" argument="$2" description="$3"
  tail -n +3 "$record" | grep -Fxq -- "$argument" ||
    fail "$description does not pass $argument"
}

mpv_meson="$(recorded_call meson "mpv-$mpv_version")" ||
  fail "the build plan never ran meson in the mpv source tree"
[ "$(sed -n 3p "$mpv_meson")" = "setup" ] ||
  fail "mpv's first meson call is no longer 'setup'"

assert_argument "$mpv_meson" "-Dwayland=enabled" "mpv's meson setup"
assert_argument "$mpv_meson" "-Dx11=disabled" "mpv's meson setup"
assert_argument "$mpv_meson" "-Dvaapi=enabled" "mpv's meson setup"
assert_argument "$mpv_meson" "-Dgl=enabled" "mpv's meson setup"
assert_argument "$mpv_meson" "-Degl=enabled" "mpv's meson setup"

# The DRM-derived providers are the ones that keep hardware decoding alive when
# the Wayland VA display cannot be had: vaapi-copy opens the render node on its
# own, and the GL dmabuf interop gives direct vaapi a display-independent
# path. mpv auto-disables the whole `drm` feature when libdisplay-info is
# missing, so these are pinned enabled and asserted here.
assert_argument "$mpv_meson" "-Ddrm=enabled" "mpv's meson setup"
assert_argument "$mpv_meson" "-Dvaapi-drm=enabled" "mpv's meson setup"
assert_argument "$mpv_meson" "-Dvaapi-wayland=enabled" "mpv's meson setup"

# vaapi has to reach ffmpeg too, or mpv's hwdec has no decoder behind it. And
# the bundled ffmpeg needs a software AV1 decoder: its native av1 codec is
# hardware-accelerated only, so without dav1d an AV1 source on a machine whose
# GPU cannot decode it fails every packet and plays black video with audio.
ffmpeg_configure="$(recorded_call configure "ffmpeg-$ffmpeg_version")" ||
  fail "the build plan never configured ffmpeg"
assert_argument "$ffmpeg_configure" "--enable-vaapi" "ffmpeg's configure"
assert_argument "$ffmpeg_configure" "--enable-libdav1d" "ffmpeg's configure"

# dav1d must be built static so ffmpeg absorbs it into the bundled libmpv:
# a shared dav1d would have to travel in the bundle and be kept version-true
# with the host, which is exactly the coupling the rest of the plan avoids.
dav1d_meson="$(recorded_call meson "dav1d-v$dav1d_version")" ||
  fail "the build plan never ran meson in the dav1d source tree"
assert_argument "$dav1d_meson" "--default-library=static" "dav1d's meson setup"

# libplacebo runs meson as well, and its call carries no Wayland flag: finding
# it separately is what proves the directory above really discriminated.
recorded_call meson "libplacebo-v$libplacebo_version" >/dev/null ||
  fail "the build plan never ran meson in the libplacebo source tree"

echo "Linux native acquisition and build plan verification passed"
