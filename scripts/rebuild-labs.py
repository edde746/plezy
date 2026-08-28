#!/usr/bin/env python3
"""Reconstruct Plezy Labs from an official tag and its feature manifest."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any


NUMERIC_TAG = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
FULL_SHA = re.compile(r"^[0-9a-f]{40}$")
GENERATED_TRANSLATION = re.compile(r"^lib/i18n/strings(?:_[A-Za-z0-9_]+)?\.g\.dart$")
TRANSLATION_JSON = re.compile(r"^lib/i18n/[A-Za-z0-9_-]+\.i18n\.json$")
WINDOWS_INSTALLER = "windows/build-installer.ps1"
OFFICIAL_WINDOWS_PUBLISHER = '#define Publisher "edde746"'
LABS_WINDOWS_PUBLISHER = '#define Publisher "RyanTheTechMan (Plezy Labs)"'
SUPPORTED_MANIFEST_SCHEMAS = {1, 2}
UPSTREAM_PR = re.compile(r"^https://github\.com/edde746/plezy/pull/[1-9][0-9]*$")


class RebuildError(RuntimeError):
    def __init__(self, stage: str, message: str, *, feature: str = "", files: list[str] | None = None):
        super().__init__(message)
        self.stage = stage
        self.feature = feature
        self.files = files or []


def command(
    repo: Path,
    *args: str,
    check: bool = True,
    input_text: str | None = None,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        args,
        cwd=repo,
        check=False,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
    )
    if check and result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(f"{' '.join(args)} failed: {detail}")
    return result


def git(repo: Path, *args: str, check: bool = True) -> str:
    return command(repo, "git", *args, check=check).stdout.strip()


def rev_parse(repo: Path, ref: str) -> str:
    value = git(repo, "rev-parse", "--verify", f"{ref}^{{commit}}")
    if not FULL_SHA.fullmatch(value):
        raise RuntimeError(f"Cannot resolve commit {ref}")
    return value


def version_key(tag: str) -> tuple[int, int, int]:
    major, minor, patch = tag.split(".")
    return int(major), int(minor), int(patch)


def current_official_tag(repo: Path, source: str) -> str:
    tags = git(repo, "tag", "--merged", source, "--list").splitlines()
    stable = sorted((tag for tag in tags if NUMERIC_TAG.fullmatch(tag)), key=version_key)
    if not stable:
        raise RebuildError("discovery", f"No numeric official tag is reachable from {source}")
    return stable[-1]


def read_json_at(repo: Path, ref: str, path: str) -> dict[str, Any]:
    raw = git(repo, "show", f"{ref}:{path}")
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as error:
        raise RebuildError("manifest", f"Cannot parse {ref}:{path}: {error}") from error
    if not isinstance(data, dict) or data.get("schema_version") not in SUPPORTED_MANIFEST_SCHEMAS:
        supported = ", ".join(str(value) for value in sorted(SUPPORTED_MANIFEST_SCHEMAS))
        raise RebuildError("manifest", f"Feature manifest schema_version must be one of: {supported}")
    schema_version = data["schema_version"]
    features = data.get("features")
    if not isinstance(features, list):
        raise RebuildError("manifest", "Feature manifest features must be a list")
    seen: set[str] = set()
    for feature in features:
        if not isinstance(feature, dict):
            raise RebuildError("manifest", "Every feature entry must be an object")
        feature_id = feature.get("id")
        source_ref = feature.get("source_ref")
        commits = feature.get("commits")
        if not isinstance(feature_id, str) or not feature_id or feature_id in seen:
            raise RebuildError("manifest", f"Invalid or duplicate feature id: {feature_id}")
        seen.add(feature_id)
        if not isinstance(feature.get("enabled"), bool):
            raise RebuildError("manifest", f"Feature {feature_id} has no boolean enabled value")
        if not isinstance(source_ref, str) or not source_ref:
            raise RebuildError("manifest", f"Feature {feature_id} has no source_ref")
        if (
            not isinstance(commits, list)
            or not commits
            or not all(isinstance(item, str) and FULL_SHA.fullmatch(item) for item in commits)
        ):
            raise RebuildError("manifest", f"Feature {feature_id} has no ordered commit list")
        upstream_pr = feature.get("upstream_pr")
        if upstream_pr is not None and (
            not isinstance(upstream_pr, str) or not UPSTREAM_PR.fullmatch(upstream_pr)
        ):
            raise RebuildError("manifest", f"Feature {feature_id} has an invalid upstream_pr")
        backport = feature.get("backport")
        if backport is None:
            continue
        if schema_version < 2:
            raise RebuildError("manifest", f"Feature {feature_id} uses backport metadata with schema_version 1")
        if not isinstance(backport, dict):
            raise RebuildError("manifest", f"Feature {feature_id} backport must be an object")
        backport_ref = backport.get("source_ref")
        backport_commits = backport.get("commits")
        use_native_after = backport.get("use_native_after")
        if not isinstance(backport_ref, str) or not backport_ref:
            raise RebuildError("manifest", f"Feature {feature_id} backport has no source_ref")
        if (
            not isinstance(backport_commits, list)
            or not backport_commits
            or not all(isinstance(item, str) and FULL_SHA.fullmatch(item) for item in backport_commits)
        ):
            raise RebuildError("manifest", f"Feature {feature_id} backport has no ordered commit list")
        if not isinstance(use_native_after, str) or not FULL_SHA.fullmatch(use_native_after):
            raise RebuildError("manifest", f"Feature {feature_id} backport has no full use_native_after SHA")
    return data


def patch_id(repo: Path, commit: str) -> str:
    patch = command(repo, "git", "show", "--pretty=format:", commit).stdout
    result = command(repo, "git", "patch-id", "--stable", input_text=patch)
    line = result.stdout.strip().splitlines()
    if not line:
        raise RebuildError("feature", f"Commit {commit} has no patch")
    return line[0].split()[0]


def official_patch_ids(repo: Path, official: str) -> set[str]:
    log = subprocess.Popen(
        ["git", "log", "-p", "--pretty=format:", official],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert log.stdout is not None
    patches = subprocess.run(
        ["git", "patch-id", "--stable"],
        cwd=repo,
        check=False,
        text=True,
        stdin=log.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    log.stdout.close()
    log_stderr = log.stderr.read() if log.stderr is not None else ""
    log_status = log.wait()
    if log_status != 0:
        raise RuntimeError(f"git log failed: {log_stderr.strip()}")
    if patches.returncode != 0:
        raise RuntimeError(f"git patch-id failed: {patches.stderr.strip()}")
    return {line.split()[0] for line in patches.stdout.splitlines() if line.strip()}


def is_ancestor(repo: Path, ancestor: str, descendant: str) -> bool:
    return command(repo, "git", "merge-base", "--is-ancestor", ancestor, descendant, check=False).returncode == 0


def resolve_commits(repo: Path, commits: list[str], *, feature_id: str, variant: str) -> list[str]:
    resolved: list[str] = []
    for value in commits:
        try:
            resolved.append(rev_parse(repo, value))
        except RuntimeError as error:
            raise RebuildError(
                "feature",
                f"Feature {feature_id} {variant} commit cannot be resolved: {value}",
                feature=feature_id,
            ) from error
    return resolved


def official_patch_matches(repo: Path, commits: list[str], official_patches: set[str]) -> list[str]:
    return [source_commit for source_commit in commits if patch_id(repo, source_commit) in official_patches]


def unmerged_files(repo: Path) -> list[str]:
    return [line for line in git(repo, "diff", "--name-only", "--diff-filter=U").splitlines() if line]


_MISSING = object()


def merge_json_value(base: Any, ours: Any, theirs: Any, path: str = "") -> Any:
    if ours == theirs:
        return ours
    if ours == base:
        return theirs
    if theirs == base:
        return ours
    if all(isinstance(value, dict) for value in (base, ours, theirs)):
        merged: dict[str, Any] = {}
        keys = list(base)
        keys.extend(key for key in ours if key not in base)
        keys.extend(key for key in theirs if key not in base and key not in ours)
        for key in keys:
            base_value = base.get(key, _MISSING)
            ours_value = ours.get(key, _MISSING)
            theirs_value = theirs.get(key, _MISSING)
            key_path = f"{path}.{key}" if path else key
            value = merge_json_value(base_value, ours_value, theirs_value, key_path)
            if value is not _MISSING:
                merged[key] = value
        return merged
    raise ValueError(f"both sides changed translation key {path or '<root>'}")


def read_conflict_json(repo: Path, stage: int, path: str) -> Any:
    raw = git(repo, "show", f":{stage}:{path}")
    return json.loads(raw)


def resolve_translation_conflicts(repo: Path, files: list[str]) -> bool:
    if not files or not all(GENERATED_TRANSLATION.fullmatch(path) or TRANSLATION_JSON.fullmatch(path) for path in files):
        return False
    try:
        for path in files:
            if GENERATED_TRANSLATION.fullmatch(path):
                git(repo, "checkout", "--ours", "--", path)
            else:
                merged = merge_json_value(
                    read_conflict_json(repo, 1, path),
                    read_conflict_json(repo, 2, path),
                    read_conflict_json(repo, 3, path),
                )
                (repo / path).write_text(json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            git(repo, "add", "--", path)
    except (json.JSONDecodeError, KeyError, RuntimeError, ValueError):
        return False
    remaining = set(unmerged_files(repo))
    return not any(path in remaining for path in files)


def brand_labs_windows_installer(contents: str) -> str:
    """Apply the single Labs-owned installer change to current upstream code."""
    if LABS_WINDOWS_PUBLISHER in contents:
        return contents
    if OFFICIAL_WINDOWS_PUBLISHER not in contents:
        raise ValueError("official Windows installer publisher declaration was not found")
    return contents.replace(OFFICIAL_WINDOWS_PUBLISHER, LABS_WINDOWS_PUBLISHER)


def resolve_labs_base_conflicts(repo: Path, files: list[str]) -> bool:
    """Resolve generated files and narrow, semantic Labs branding conflicts."""
    generated = [
        path
        for path in files
        if GENERATED_TRANSLATION.fullmatch(path) or TRANSLATION_JSON.fullmatch(path)
    ]
    supported = set(generated)
    if WINDOWS_INSTALLER in files:
        supported.add(WINDOWS_INSTALLER)
    if not files or supported != set(files):
        return False

    if generated and not resolve_translation_conflicts(repo, generated):
        return False

    if WINDOWS_INSTALLER in files:
        try:
            git(repo, "checkout", "--ours", "--", WINDOWS_INSTALLER)
            installer = repo / WINDOWS_INSTALLER
            installer.write_text(
                brand_labs_windows_installer(installer.read_text(encoding="utf-8")),
                encoding="utf-8",
            )
            git(repo, "add", "--", WINDOWS_INSTALLER)
        except (OSError, RuntimeError, ValueError):
            return False

    return not unmerged_files(repo)


def try_generated_resolution(repo: Path, files: list[str], *, continue_cherry_pick: bool) -> bool:
    if not resolve_translation_conflicts(repo, files):
        return False
    if continue_cherry_pick:
        environment = os.environ.copy()
        environment["GIT_EDITOR"] = "true"
        result = command(repo, "git", "cherry-pick", "--continue", check=False, env=environment)
    else:
        result = command(repo, "git", "cherry-pick", "--quit", check=False)
    return result.returncode == 0


def commit(repo: Path, message: str, *, allow_empty: bool = False) -> str:
    args = ["commit", "--no-verify", "-m", message]
    if allow_empty:
        args.insert(1, "--allow-empty")
    git(repo, *args)
    return rev_parse(repo, "HEAD")


def append_github_output(path: Path | None, values: dict[str, str]) -> None:
    if path is None:
        return
    with path.open("a", encoding="utf-8") as handle:
        for key, value in values.items():
            handle.write(f"{key}={value}\n")


def write_report(path: Path, report: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


def report_path(repo: Path, value: str | None) -> Path:
    if value:
        return Path(value).expanduser().resolve()
    return Path(git(repo, "rev-parse", "--git-path", "labs-rebuild-report.json")).resolve()


def regenerate_translations(repo: Path) -> bool:
    command(repo, "flutter", "pub", "get", "--enforce-lockfile", "--no-example")
    command(repo, str(repo / "scripts" / "prepare-labs-translations.py"))
    command(repo, "dart", "run", "slang")
    translations = sorted((repo / "lib" / "i18n").glob("*.i18n.json"))
    translations.extend(sorted((repo / "lib" / "i18n").glob("strings*.g.dart")))
    if translations:
        git(repo, "add", "--", *(str(path.relative_to(repo)) for path in translations))
    changed = command(repo, "git", "diff", "--cached", "--quiet", check=False).returncode != 0
    if changed:
        commit(repo, "chore(labs): regenerate translations")
    return changed


def normalize_dart_formatting(repo: Path, official: str) -> bool:
    changed_files = [
        path
        for path in git(repo, "diff", "--name-only", official, "HEAD").splitlines()
        if path.endswith(".dart") and not path.endswith((".g.dart", ".freezed.dart"))
    ]
    if not changed_files:
        return False
    command(repo, "dart", "format", *changed_files)
    changed_files = [path for path in changed_files if command(repo, "git", "diff", "--quiet", "--", path, check=False).returncode != 0]
    if not changed_files:
        return False
    git(repo, "add", "--", *changed_files)
    commit(repo, "chore(labs): normalize feature overlay formatting")
    return True


def rebuild(args: argparse.Namespace) -> dict[str, Any]:
    repo = Path(args.repo).expanduser().resolve()
    resolved_report_path = report_path(repo, args.report)
    github_output = Path(args.github_output).expanduser().resolve() if args.github_output else None
    source = rev_parse(repo, args.source_ref)
    status = git(repo, "status", "--porcelain")
    if status:
        raise RebuildError("preflight", "Candidate worktree must be clean before reconstruction")

    old_tag = current_official_tag(repo, source)
    old_base = rev_parse(repo, old_tag)
    manifest = read_json_at(repo, source, args.manifest)
    manifest_history = git(
        repo,
        "log",
        "--reverse",
        "--format=%H",
        f"{old_base}..{source}",
        "--",
        args.manifest,
    ).splitlines()
    if not manifest_history:
        raise RebuildError("discovery", f"No manifest commit follows official tag {old_tag}")
    manifest_boundary = manifest_history[0]
    core_tip = rev_parse(repo, f"{manifest_boundary}^")
    core_commits = [
        line for line in git(repo, "rev-list", "--reverse", f"{old_base}..{core_tip}").splitlines() if line
    ]
    if not core_commits:
        raise RebuildError("discovery", "No mandatory Labs base commits precede the manifest")

    official_tag = args.official_tag
    if not NUMERIC_TAG.fullmatch(official_tag):
        raise RebuildError("official", f"Official tag must be numeric X.Y.Z: {official_tag}")
    official = rev_parse(repo, official_tag)
    pubspec = git(repo, "show", f"{official_tag}:pubspec.yaml")
    match = re.search(r"^version:\s*([^+\s]+)", pubspec, re.MULTILINE)
    if not match or match.group(1) != official_tag:
        raise RebuildError("official", f"Tag {official_tag} does not match pubspec.yaml")

    report: dict[str, Any] = {
        "status": "running",
        "old_official_tag": old_tag,
        "official_tag": official_tag,
        "official_commit": official,
        "source_commit": source,
        "core_source_commits": core_commits,
        "applied_features": [],
        "skipped_official_features": [],
        "disabled_features": [],
    }
    write_report(resolved_report_path, report)

    git(repo, "config", "user.name", args.git_name)
    git(repo, "config", "user.email", args.git_email)
    official_patches = official_patch_ids(repo, official)
    git(repo, "reset", "--hard", official)

    for core_source in core_commits:
        result = command(repo, "git", "cherry-pick", "--no-commit", core_source, check=False)
        if result.returncode != 0:
            conflicts = unmerged_files(repo)
            if not resolve_labs_base_conflicts(repo, conflicts):
                raise RebuildError(
                    "labs-base",
                    f"Mandatory Labs base commit {core_source} does not apply cleanly",
                    files=conflicts,
                )
            command(repo, "git", "cherry-pick", "--quit", check=False)
    if command(repo, "git", "diff", "--cached", "--quiet", check=False).returncode == 0:
        raise RebuildError("labs-base", "Mandatory Labs base produced no changes")
    core_commit = commit(repo, f"feat(labs): base release channel on Plezy {official_tag}")

    manifest_path = repo / args.manifest
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    git(repo, "add", "--", args.manifest)
    manifest_commit = commit(repo, "chore(labs): register enabled feature overlays", allow_empty=True)

    for feature in manifest["features"]:
        feature_id = feature["id"]
        if not feature["enabled"]:
            report["disabled_features"].append(feature_id)
            continue
        native_commits = resolve_commits(repo, feature["commits"], feature_id=feature_id, variant="native")
        backport = feature.get("backport")
        if backport is not None:
            backport_commits = resolve_commits(
                repo,
                backport["commits"],
                feature_id=feature_id,
                variant="backport",
            )
            try:
                use_native_after = rev_parse(repo, backport["use_native_after"])
            except RuntimeError as error:
                raise RebuildError(
                    "feature",
                    f"Feature {feature_id} use_native_after commit cannot be resolved: {backport['use_native_after']}",
                    feature=feature_id,
                ) from error

            matched_variant = ""
            matched_commits: list[str] = []
            for variant, variant_commits in (("native", native_commits), ("backport", backport_commits)):
                official_matches = official_patch_matches(repo, variant_commits, official_patches)
                if official_matches and len(official_matches) != len(variant_commits):
                    raise RebuildError(
                        "feature",
                        f"Feature {feature_id} is only partially official in its {variant} form",
                        feature=feature_id,
                    )
                if official_matches:
                    matched_variant = variant
                    matched_commits = official_matches
                    break
            if matched_variant:
                report["skipped_official_features"].append(
                    {"id": feature_id, "variant": matched_variant, "commits": matched_commits}
                )
                continue

            if is_ancestor(repo, use_native_after, official):
                selected_variant = "native"
                selected_commits = native_commits
            else:
                selected_variant = "backport"
                selected_commits = backport_commits

            for source_commit in selected_commits:
                result = command(repo, "git", "cherry-pick", source_commit, check=False)
                if result.returncode != 0:
                    conflicts = unmerged_files(repo)
                    if not try_generated_resolution(repo, conflicts, continue_cherry_pick=True):
                        raise RebuildError(
                            "feature",
                            f"Feature {feature_id} {selected_variant} commit {source_commit} does not apply cleanly",
                            feature=feature_id,
                            files=conflicts,
                        )
            report["applied_features"].append(
                {"id": feature_id, "variant": selected_variant, "commits": selected_commits}
            )
            continue

        applied_commits: list[str] = []
        skipped_commits: list[str] = []
        for source_commit in native_commits:
            source_patch = patch_id(repo, source_commit)
            if source_patch in official_patches:
                skipped_commits.append(source_commit)
                continue
            result = command(repo, "git", "cherry-pick", source_commit, check=False)
            if result.returncode != 0:
                conflicts = unmerged_files(repo)
                if not try_generated_resolution(repo, conflicts, continue_cherry_pick=True):
                    raise RebuildError(
                        "feature",
                        f"Feature {feature_id} commit {source_commit} does not apply cleanly",
                        feature=feature_id,
                        files=conflicts,
                    )
            applied_commits.append(source_commit)
        if applied_commits:
            report["applied_features"].append(
                {"id": feature_id, "variant": "native", "commits": applied_commits}
            )
        if skipped_commits:
            report["skipped_official_features"].append(
                {"id": feature_id, "variant": "native", "commits": skipped_commits}
            )

    generated_commit = False
    if not args.skip_translation_generation:
        generated_commit = regenerate_translations(repo)
    # Resolve package language versions before formatting. A fresh Actions
    # checkout has no .dart_tool/package_config.json until translation
    # generation runs `flutter pub get`; formatting before that can use the
    # SDK's default language version and then change again during CI checks.
    formatting_commit = normalize_dart_formatting(repo, official)

    head = rev_parse(repo, "HEAD")
    if git(repo, "merge-base", official, head) != official:
        raise RebuildError("validation", "Candidate is not based on the exact official tag")
    if git(repo, "rev-list", "--merges", f"{official}..{head}"):
        raise RebuildError("validation", "Candidate contains merge commits")
    if unmerged_files(repo):
        raise RebuildError("validation", "Candidate still contains unresolved files", files=unmerged_files(repo))
    if git(repo, "status", "--porcelain"):
        raise RebuildError("validation", "Candidate worktree is not clean after reconstruction")

    report.update(
        {
            "status": "success",
            "core_commit": core_commit,
            "manifest_commit": manifest_commit,
            "formatting_commit": formatting_commit,
            "generated_translation_commit": generated_commit,
            "source_sha": head,
        }
    )
    write_report(resolved_report_path, report)
    append_github_output(
        github_output,
        {
            "official_tag": official_tag,
            "version": official_tag,
            "source_sha": head,
            "applied_features": ",".join(item["id"] for item in report["applied_features"]),
            "skipped_features": ",".join(item["id"] for item in report["skipped_official_features"]),
            "backported_features": ",".join(
                item["id"] for item in report["applied_features"] if item.get("variant") == "backport"
            ),
        },
    )
    print(json.dumps(report, indent=2))
    return report


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--repo", default=".")
    result.add_argument("--source-ref", default="HEAD")
    result.add_argument("--official-tag", required=True)
    result.add_argument("--manifest", default="tool/labs_features.json")
    result.add_argument("--report")
    result.add_argument("--github-output")
    result.add_argument("--git-name", default="github-actions[bot]")
    result.add_argument("--git-email", default="github-actions[bot]@users.noreply.github.com")
    result.add_argument("--skip-translation-generation", action="store_true")
    return result


def main() -> int:
    args = parser().parse_args()
    repo = Path(args.repo).expanduser().resolve()
    resolved_report_path = report_path(repo, args.report)
    try:
        rebuild(args)
    except RebuildError as error:
        report = {
            "status": "failure",
            "stage": error.stage,
            "message": str(error),
            "feature": error.feature,
            "files": error.files,
            "official_tag": args.official_tag,
        }
        write_report(resolved_report_path, report)
        append_github_output(
            Path(args.github_output).expanduser().resolve() if args.github_output else None,
            {
                "failure_stage": error.stage,
                "failure_feature": error.feature,
                "failure_files": ",".join(error.files),
                "failure_message": str(error).replace("\n", " "),
            },
        )
        print(json.dumps(report, indent=2), file=sys.stderr)
        return 1
    except Exception as error:  # Defensive reporting for workflow diagnostics.
        report = {
            "status": "failure",
            "stage": "unexpected",
            "message": str(error),
            "feature": "",
            "files": [],
            "official_tag": args.official_tag,
        }
        write_report(resolved_report_path, report)
        print(json.dumps(report, indent=2), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
