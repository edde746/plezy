#!/usr/bin/env python3
"""Guard the release-channel invariants that keep Labs reproducible."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parent.parent


def require(path: str, snippets: list[str]) -> str:
    text = (ROOT / path).read_text(encoding="utf-8")
    missing = [snippet for snippet in snippets if snippet not in text]
    if missing:
        formatted = "\n".join(f"  - {snippet}" for snippet in missing)
        raise SystemExit(f"{path} is missing required Labs behavior:\n{formatted}")
    return text


workflow_names = sorted(path.name for path in (ROOT / ".github" / "workflows").glob("labs-*.yml"))
expected = ["labs-build.yml", "labs-watch.yml"]
if workflow_names != expected:
    raise SystemExit(f"Expected exactly the two Labs workflows {expected}, found {workflow_names}")

main = require(
    ".github/workflows/labs-build.yml",
    [
        "name: Plezy Labs",
        "scripts/rebuild-labs.py",
        "tool/labs_features.json",
        "--force-with-lease=",
        'elif [[ "$state" == disabled_* ]]',
        "scripts/check-labs-preferences.sh",
        "scripts/check-labs-candidate.sh",
        "scripts/generate-labs-release-notes.py",
        "scripts/check-labs-workflows.py",
        "scripts/manage-labs-issue.sh",
        "scripts/publish-labs-feed.sh",
        "flutter_version: ${{ steps.metadata.outputs.flutter_version }}",
        "git show \"$TAG:.github/workflows/build.yml\"",
        "scripts/resolve_labs_flutter_version.py",
        "scripts/test_resolve_labs_flutter_version.py",
        "flutter-version: ${{ needs.prepare.outputs.flutter_version }}",
        '$version = "${{ needs.prepare.outputs.flutter_version }}"',
        "--dart-define=PLEZY_LABS=true",
        "LABS_PACKAGE_ITERATION=labs.${{ needs.prepare.outputs.revision }}",
        "draft: ${{ !inputs.publish }}",
        "prerelease: false",
        "body_path: release-notes.md",
        "types: [published]",
    ],
)
if re.search(r"\bgit merge(?:\s|$)", main):
    raise SystemExit("Labs orchestration must reconstruct with patches, never merge old Labs history")

require(
    ".github/workflows/labs-watch.yml",
    [
        "timezone: America/New_York",
        ".draft == false and .prerelease == false",
        "gh workflow run labs-build.yml",
        "-f publish=true",
    ],
)
require(
    "scripts/check-labs-candidate.sh",
    [
        "scripts/ci_checks.sh",
        "Candidate hit the known analyzer crash",
        "worktree add --detach",
        "dart run scripts/checks/check_analyzer.dart",
        "normalized_diagnostics",
        "Official $OFFICIAL_TAG reproduces the same analyzer-plugin crash and diagnostics",
        "has_known_upstream_maestro_contract_failure",
        "has_only_unchanged_upstream_unused_code",
        "ACCEPTED_FAILURES",
    ],
)
require(
    "scripts/generate-labs-release-notes.py",
    [
        "Plezy Labs features included",
        "Official Plezy {official_tag} release notes",
        "applied_features",
        "official_notes",
        "upstream_pr",
    ],
)
require(
    "scripts/publish-labs-feed.sh",
    [
        "GIT_AUTHOR_NAME",
        "GIT_AUTHOR_EMAIL",
        "GIT_COMMITTER_NAME",
        "GIT_COMMITTER_EMAIL",
        "github-actions[bot]",
        "git commit-tree",
    ],
)
require(
    "scripts/resolve_labs_flutter_version.py",
    [
        "FLUTTER_VERSION",
        "${{ env.FLUTTER_VERSION }}",
        "Expected one upstream Flutter version",
        "Official Flutter pin is not numeric X.Y.Z",
    ],
)
require(
    "scripts/rebuild-labs.py",
    [
        "Mandatory Labs base",
        "skipped_official_features",
        "use_native_after",
        "selected_variant",
        "backported_features",
        'glob("*.i18n.json")',
        'glob("strings*.g.dart")',
        'git(repo, "reset", "--hard", official)',
        'git(repo, "rev-list", "--merges"',
    ],
)

print("Plezy Labs workflow guards passed.")
