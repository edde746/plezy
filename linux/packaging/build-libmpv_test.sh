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
mkdir -p "$repository"
git -C "$repository" init --quiet
git -C "$repository" config user.name "Plezy provenance test"
git -C "$repository" config user.email "provenance-test@invalid.example"
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
mkdir -p "$mirror_repository"
git -C "$mirror_repository" init --quiet
git -C "$mirror_repository" config user.name "Plezy provenance test"
git -C "$mirror_repository" config user.email "provenance-test@invalid.example"
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

echo "Linux native acquisition verification passed"
