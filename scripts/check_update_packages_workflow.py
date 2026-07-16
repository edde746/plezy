#!/usr/bin/env python3
"""Guard the release-tag flow in update-packages.yml against regressions."""

from pathlib import Path
import re
import sys


WORKFLOW = Path(__file__).resolve().parents[1] / ".github/workflows/update-packages.yml"
text = WORKFLOW.read_text(encoding="utf-8")
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def job(name: str) -> str:
    match = re.search(
        rf"(?ms)^  {re.escape(name)}:\n(.*?)(?=^  [a-zA-Z0-9_-]+:\n|\Z)", text
    )
    require(match is not None, f"missing {name} job")
    return match.group(0) if match else ""


require(
    re.search(
        r"(?ms)^  workflow_dispatch:\n    inputs:\n      release_tag:\n"
        r".*?        required: true\n",
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
winget = job("update-winget")
appcast = job("update-appcast-branch")
for name, block in (
    ("update-homebrew", homebrew),
    ("update-winget", winget),
    ("update-appcast-branch", appcast),
):
    require("needs: resolve-release" in block, f"{name} must depend on the resolver")

resolved_output = "${{ needs.resolve-release.outputs.tag }}"
require(f"RELEASE_TAG: {resolved_output}" in homebrew, "Homebrew must use the resolved tag")
require(f"release-tag: {resolved_output}" in winget, "WinGet must use the resolved tag")
require(f"RELEASE_TAG: {resolved_output}" in appcast, "appcast must use the resolved tag")
require(
    'git commit -m "chore: update cask to $RELEASE_TAG"' in homebrew,
    "Homebrew commit text must include the resolved tag",
)
require(
    'git commit-tree "$TREE" -m "Update appcast for $RELEASE_TAG"' in appcast,
    "appcast commit text must include the resolved tag",
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
