#!/usr/bin/env python3
"""Guard the release-tag flow in update-packages.yml against regressions."""

from pathlib import Path
import re
import sys

from workflow_yaml import job_block


WORKFLOW = Path(__file__).resolve().parents[2] / ".github/workflows/update-packages.yml"
text = WORKFLOW.read_text(encoding="utf-8")
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def job(name: str) -> str:
    block = job_block(text, name)
    require(bool(block), f"missing {name} job")
    return block


require(
    re.search(
        r"(?ms)^  workflow_dispatch:\n    inputs:\n.*?^      release_tag:\n"
        r".*?^        required: true$",
        text,
    )
    is not None,
    "workflow_dispatch must require release_tag",
)
require("github.ref_name" not in text, "release tags must never fall back to a branch")
require(
    text.count("github.event.release.tag_name") == 1,
    "only the resolver may read the release event tag",
)

resolver = job("resolve-release")
require("gh release view \"$REQUESTED_TAG\"" in resolver, "resolver must validate the tag")
require("--json tagName,isDraft,publishedAt" in resolver, "resolver must require a published release")
require(
    "tag: ${{ steps.release.outputs.tag }}" in resolver,
    "resolver must expose one validated tag output",
)

homebrew = job("update-homebrew")
appcast = job("update-appcast-branch")
require(
    "update-winget:" not in text,
    "the inherited upstream WinGet publisher must stay removed",
)
for stale_upstream in ("WINGET_TOKEN", "edde746.Plezy", "winget-releaser"):
    require(
        stale_upstream not in text,
        f"obsolete upstream package reference remains: {stale_upstream}",
    )
for name, block in (
    ("update-homebrew", homebrew),
    ("update-appcast-branch", appcast),
):
    require("needs: resolve-release" in block, f"{name} must depend on the resolver")

for name, block in (
    ("resolve-release", resolver),
    ("update-homebrew", homebrew),
    ("update-appcast-branch", appcast),
):
    require(
        re.search(r"(?m)^    permissions:", block) is not None,
        f"{name} must declare its GITHUB_TOKEN permissions",
    )
resolved_output = "${{ needs.resolve-release.outputs.tag }}"
require(f"RELEASE_TAG: {resolved_output}" in homebrew, "Homebrew must use the resolved tag")
require(f"RELEASE_TAG: {resolved_output}" in appcast, "appcast must use the resolved tag")
require(
    "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/download/$RELEASE_TAG" in homebrew,
    "Homebrew must download from this repository",
)
require(
    "github.com/edde746/plezy" not in text,
    "package workflow must not target upstream releases",
)
require(
    'git commit -m "chore: update cask to $RELEASE_TAG"' in homebrew,
    "Homebrew commit text must include the resolved tag",
)
require(
    'git commit -m "Update appcast for $RELEASE_TAG"' in appcast,
    "appcast commit text must include the resolved tag",
)
require(
    "git push origin HEAD:refs/heads/appcast" in appcast,
    "appcast publishing must push the branch head",
)
require(
    "--force" not in appcast and "git commit-tree" not in appcast,
    "appcast publishing must be a normal fast-forward push",
)
require(
    'gh release download "$RELEASE_TAG"' in appcast,
    "appcast download must specify the resolved tag",
)

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print("update-packages workflow release-tag checks passed")
