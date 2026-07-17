#!/usr/bin/env python3
"""Guard the release contract for the relay container image workflow."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/publish-relay-image.yml"
CHECK_WORKFLOW = ROOT / ".github/workflows/check-relay-image.yml"
text = WORKFLOW.read_text(encoding="utf-8")
check_text = CHECK_WORKFLOW.read_text(encoding="utf-8")
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


require("  push:\n    tags:" in text, "relay image workflow must trigger on pushed tags")
require("workflow_dispatch:" not in text, "relay image workflow must not allow manual publication")
require("pull_request:" not in text, "relay image workflow must not run on pull requests")
require("branches:" not in text, "relay image workflow must not trigger on branch pushes")
require("fetch-depth: 0" in text, "relay image workflow must fetch release history")
require("persist-credentials: false" in text, "relay image checkouts must discard credentials")
require(
    '^[0-9]+\\.[0-9]+\\.[0-9]+$' in text,
    "relay image workflow must validate semantic release tags",
)
require(
    'git for-each-ref' in text
    and '--merged "$GITHUB_SHA^"' in text
    and '--sort=-version:refname' in text,
    "relay image workflow must resolve the previous semantic release tag",
)
require(
    'git diff --quiet "$previous_tag" "$GITHUB_SHA" -- server/' in text,
    "relay image workflow must publish only after server changes",
)
require(
    'owner="${GITHUB_REPOSITORY_OWNER,,}"' in text,
    "relay image workflow must lowercase the repository owner",
)
require(
    'image="ghcr.io/$owner/plezy/relay-server"' in text,
    "relay image workflow must publish under the repository owner namespace",
)
for permission in ("contents: read", "packages: write", "id-token: write", "attestations: write"):
    require(permission in text, f"relay image workflow must grant {permission}")
require("context: ./server" in text, "relay image workflow must build from the server context")
require("file: ./server/Dockerfile" in text, "relay image workflow must use the server Dockerfile")
require("platforms: linux/amd64" in text, "relay image workflow must build amd64 natively")
require("platforms: linux/arm64" in text, "relay image workflow must build arm64 natively")
require("runs-on: ubuntu-24.04-arm" in text, "relay image workflow must use a native arm64 runner")
for cache_scope in ("relay-amd64", "relay-arm64"):
    require(f"scope={cache_scope}" in text, f"relay image workflow must cache {cache_scope} independently")
require("docker buildx imagetools create" in text, "relay image workflow must assemble a multi-architecture manifest")
for tag in (
    "type=raw,value=${{ needs.detect-server-changes.outputs.version }}",
    "type=raw,value=sha-${{ github.sha }}",
    "type=raw,value=latest",
):
    require(tag in text, f"relay image workflow must publish tag: {tag}")
require("subject-digest: ${{ steps.manifest.outputs.digest }}" in text, "relay image workflow must attest the manifest digest")
require("push-to-registry: true" in text, "relay image provenance must be published to GHCR")

require(
    "  pull_request:\n    branches: [main]\n    paths:" in check_text,
    "relay image check must run for filtered pull requests to main",
)
require(
    "  push:\n    branches: [main]\n    paths:" in check_text,
    "relay image check must run for filtered pushes to main",
)
for path in (
    ".github/workflows/check-relay-image.yml",
    "server/Dockerfile",
    "server/go.mod",
    "server/go.sum",
    "server/*.go",
):
    require(path in check_text, f"relay image check must include {path}")
require("server/**" not in check_text, "relay image pull-request check must not rebuild for all server changes")
require("push: false" in check_text, "relay image pull-request check must not publish")
require("context: ./server" in check_text, "relay image pull-request check must use the server context")
require("file: ./server/Dockerfile" in check_text, "relay image pull-request check must use the server Dockerfile")
require("cache-from: type=gha,scope=relay-amd64" in check_text, "relay image pull-request check must reuse the amd64 cache")

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print("relay image workflow checks passed")
