#!/usr/bin/env python3
"""Compose Plezy Labs notes from applied overlays and an official release body."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any


SUPPORTED_MANIFEST_SCHEMAS = {1, 2}
UPSTREAM_PR = re.compile(r"^https://github\.com/edde746/plezy/pull/([1-9][0-9]*)$")


def load_manifest(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.get("schema_version") not in SUPPORTED_MANIFEST_SCHEMAS:
        raise ValueError("Feature manifest schema_version must be 1 or 2")
    features = data.get("features")
    if not isinstance(features, list):
        raise ValueError("Feature manifest features must be a list")
    return data


def parse_applied_features(value: str) -> list[str]:
    features = [item.strip() for item in value.split(",") if item.strip()]
    if len(features) != len(set(features)):
        raise ValueError("Applied feature ids must not contain duplicates")
    return features


def nest_markdown_headings(value: str) -> str:
    return re.sub(r"^(#{1,5})(\s+)", r"#\1\2", value, flags=re.MULTILINE)


def generate_release_notes(
    manifest: dict[str, Any],
    applied_features: list[str],
    official_tag: str,
    official_notes: str,
) -> str:
    features = manifest["features"]
    by_id: dict[str, dict[str, Any]] = {}
    for feature in features:
        if not isinstance(feature, dict):
            raise ValueError("Every feature entry must be an object")
        feature_id = feature.get("id")
        if not isinstance(feature_id, str) or not feature_id or feature_id in by_id:
            raise ValueError(f"Invalid or duplicate feature id: {feature_id}")
        by_id[feature_id] = feature

    unknown = [feature_id for feature_id in applied_features if feature_id not in by_id]
    if unknown:
        raise ValueError(f"Applied features are missing from the manifest: {', '.join(unknown)}")

    applied = set(applied_features)
    descriptions: list[str] = []
    for feature in features:
        feature_id = feature["id"]
        if feature_id not in applied:
            continue
        if feature.get("enabled") is not True:
            raise ValueError(f"Applied feature is not enabled: {feature_id}")
        description = feature.get("description")
        if not isinstance(description, str) or not description.strip():
            raise ValueError(f"Applied feature has no description: {feature_id}")
        line = description.strip()
        upstream_pr = feature.get("upstream_pr")
        if upstream_pr is not None:
            if not isinstance(upstream_pr, str) or not (match := UPSTREAM_PR.fullmatch(upstream_pr)):
                raise ValueError(f"Applied feature has an invalid upstream PR: {feature_id}")
            line += f" ([upstream PR #{match.group(1)}]({upstream_pr}))"
        descriptions.append(line)

    lines = ["## Plezy Labs features included", ""]
    if descriptions:
        lines.extend(f"- {description}" for description in descriptions)
    else:
        lines.append("_No Labs-only feature overlays were applied in this release._")

    upstream_body = official_notes.strip()
    if not upstream_body:
        upstream_body = "_The official Plezy release did not include release notes._"
    upstream_body = nest_markdown_headings(upstream_body)

    lines.extend(
        [
            "",
            "---",
            "",
            f"## Official Plezy {official_tag} release notes",
            "",
            upstream_body,
            "",
            f"[View the official Plezy {official_tag} release](https://github.com/edde746/plezy/releases/tag/{official_tag})",
            "",
        ]
    )
    return "\n".join(lines)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--manifest", type=Path, required=True)
    result.add_argument("--applied-features", default="")
    result.add_argument("--official-tag", required=True)
    result.add_argument("--official-notes", type=Path, required=True)
    result.add_argument("--output", type=Path, required=True)
    return result


def main() -> int:
    args = parser().parse_args()
    notes = generate_release_notes(
        load_manifest(args.manifest),
        parse_applied_features(args.applied_features),
        args.official_tag,
        args.official_notes.read_text(encoding="utf-8"),
    )
    args.output.write_text(notes, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
