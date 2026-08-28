#!/usr/bin/env bash
set -euo pipefail

tag=${1:?usage: publish-labs-feed.sh <published-labs-tag>}
repository=${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}

export GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME:-github-actions[bot]}
export GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}
export GIT_COMMITTER_NAME=${GIT_COMMITTER_NAME:-$GIT_AUTHOR_NAME}
export GIT_COMMITTER_EMAIL=${GIT_COMMITTER_EMAIL:-$GIT_AUTHOR_EMAIL}

if [[ ! "$tag" =~ ^labs-v[0-9]+\.[0-9]+\.[0-9]+-r[0-9]+$ ]]; then
  echo "Not a Plezy Labs release tag: $tag" >&2
  exit 1
fi

release=$(gh api "repos/$repository/releases/tags/$tag")
test "$(jq -r '.draft' <<<"$release")" = false
test "$(jq -r '.prerelease' <<<"$release")" = false

destination=$(mktemp -d)
trap 'rm -rf "$destination"' EXIT
gh release download "$tag" --repo "$repository" --pattern appcast.xml --dir "$destination"
appcast="$destination/appcast.xml"
test -s "$appcast"
grep -q "github.com/$repository/releases/download/$tag/" "$appcast"

blob=$(git hash-object -w "$appcast")
tree=$(printf "100644 blob %s\tappcast.xml\n" "$blob" | git mktree)
commit=$(printf 'Publish Plezy Labs feed for %s\n' "$tag" | git commit-tree "$tree")
git push origin "$commit:refs/heads/labs-feed" --force
