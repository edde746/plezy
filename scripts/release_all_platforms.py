#!/usr/bin/env python3
"""Orchestrate a native dependency refresh and the complete PlezyNG release.

This is a local control-plane command. All build, test, package, and release
jobs still run on their existing private JIT runners. It uses the operator's
authenticated `gh` CLI session and never copies credentials into the repos.
With --publish, it promotes the verified draft and runs every configured
package/store publication workflow from main, sequentially and idempotently.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLEZY_REPO = "snapetech-org/PlezyNG"
MPV_REPO = "snapetech-org/mpv-build"
MPV_WORKFLOW = "publish.yml"
CI_WORKFLOW = "ci.yml"
RELEASE_WORKFLOW = "build.yml"
NATIVE_GROUPS = ("apple", "android", "linux", "windows")
FFMPEG_SIGNING_FINGERPRINT = "FCF986EA15E6E293A5644F10B4322F04D67658D8"


class ReleaseError(RuntimeError):
    pass


def command(args: list[str], *, cwd: Path | None = None, capture: bool = False,
            check: bool = True, quiet: bool = False) -> subprocess.CompletedProcess[str]:
    if not quiet:
        print("+", " ".join(str(part) for part in args), flush=True)
    result = subprocess.run(
        [str(part) for part in args],
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
        check=False,
    )
    if check and result.returncode:
        detail = (result.stderr or result.stdout or "").strip() if capture else ""
        raise ReleaseError(f"command failed ({result.returncode}): {args[0]} {args[1:]}\n{detail}")
    return result


def gh_json(*args: str) -> object:
    result = command(["gh", *args], capture=True)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ReleaseError(f"GitHub CLI returned invalid JSON for: {' '.join(args)}") from error


def workflow_runs(repo: str, workflow: str, *, ref: str | None = None) -> list[dict]:
    args = [
        "run", "list", "--repo", repo, "--workflow", workflow, "--limit", "40",
        "--json", "databaseId,status,conclusion,headSha,headBranch,event,createdAt,displayTitle,url",
    ]
    if ref:
        args.extend(["--branch", ref])
    result = command(["gh", *args], capture=True)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ReleaseError(f"Could not read workflow runs for {repo}/{workflow}") from error


def matching_run(
    repo: str,
    workflow: str,
    sha: str,
    *,
    ref: str | None = None,
    expected_title: str | None = None,
) -> dict | None:
    runs = workflow_runs(repo, workflow, ref=ref)
    matches = [
        run for run in runs
        if run.get("headSha") == sha
        and run.get("event") == "workflow_dispatch"
        and (expected_title is None or run.get("displayTitle") == expected_title)
    ]
    matches.sort(key=lambda run: run.get("createdAt", ""), reverse=True)
    return matches[0] if matches else None


def wait_for_run(repo: str, run: dict, purpose: str) -> dict:
    run_id = str(run["databaseId"])
    print(f"\n{purpose}: {run.get('url', f'https://github.com/{repo}/actions/runs/{run_id}')}", flush=True)
    command(["gh", "run", "watch", run_id, "--repo", repo, "--interval", "30", "--exit-status"])
    updated = gh_json("run", "view", run_id, "--repo", repo,
                      "--json", "databaseId,status,conclusion,headSha,headBranch,event,url,jobs")
    if updated.get("status") != "completed" or updated.get("conclusion") != "success":
        raise ReleaseError(f"{purpose} did not succeed: {updated.get('conclusion') or updated.get('status')}")
    return updated


def dispatch(repo: str, workflow: str, ref: str, fields: dict[str, str], purpose: str,
             *, expected_title: str | None = None, expected_sha: str | None = None) -> dict:
    before = dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=10)
    args = ["gh", "workflow", "run", workflow, "--repo", repo, "--ref", ref]
    for key, value in fields.items():
        args.extend(["--field", f"{key}={value}"])
    command(args)
    deadline = time.monotonic() + 180
    while time.monotonic() < deadline:
        for run in workflow_runs(repo, workflow, ref=ref):
            if run.get("event") != "workflow_dispatch":
                continue
            if run.get("createdAt", "") < before.isoformat().replace("+00:00", "Z"):
                continue
            if expected_title and run.get("displayTitle") != expected_title:
                continue
            if expected_sha and run.get("headSha") != expected_sha:
                raise ReleaseError(
                    f"{purpose} was dispatched on {ref}, but GitHub resolved it to "
                    f"{run.get('headSha') or 'an unknown commit'} instead of expected "
                    f"{expected_sha}. The branch moved during dispatch; no other run was reused."
                )
            return wait_for_run(repo, run, purpose)
        time.sleep(5)
    raise ReleaseError(f"Workflow dispatch succeeded, but its run was not visible: {repo}/{workflow} on {ref}")


def active_run(repo: str, workflow: str, *, ref: str) -> dict | None:
    active_states = {"queued", "in_progress", "waiting", "requested", "pending"}
    for run in workflow_runs(repo, workflow, ref=ref):
        if run.get("status") in active_states:
            return run
    return None


def download(url: str, destination: Path) -> None:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in {"ffmpeg.org", "www.ffmpeg.org"}:
        raise ReleaseError(f"Refusing non-official FFmpeg source URL: {url}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": "PlezyNG-release-orchestrator/1"})
    with urllib.request.urlopen(request, timeout=90) as response, destination.open("wb") as output:
        shutil.copyfileobj(response, output)


def verified_ffmpeg_source(version_pin: str, scratch: Path) -> tuple[str, str]:
    match = re.fullmatch(r"n(\d+\.\d+\.\d+)", version_pin)
    if not match:
        raise ReleaseError(f"Expected a stable FFmpeg release tag such as n9.0.2, got {version_pin!r}")
    version = match.group(1)
    archive_name = f"ffmpeg-{version}.tar.xz"
    archive = scratch / archive_name
    signature = scratch / f"{archive_name}.asc"
    key = scratch / "ffmpeg-devel.asc"
    download(f"https://ffmpeg.org/releases/{archive_name}", archive)
    download(f"https://ffmpeg.org/releases/{archive_name}.asc", signature)
    download("https://ffmpeg.org/ffmpeg-devel.asc", key)
    if shutil.which("gpg") is None:
        raise ReleaseError("gpg is required to verify the official FFmpeg release signature.")

    keyring = scratch / "gnupg"
    keyring.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(keyring, 0o700)
    command(["gpg", "--homedir", keyring, "--batch", "--import", key])
    verified = command(
        ["gpg", "--homedir", keyring, "--batch", "--status-fd", "1", "--verify", signature, archive],
        capture=True,
    )
    fingerprints = [
        line.split()[2]
        for line in verified.stdout.splitlines()
        if line.startswith("[GNUPG:] VALIDSIG ") and len(line.split()) > 2
    ]
    if FFMPEG_SIGNING_FINGERPRINT not in fingerprints:
        raise ReleaseError(
            "FFmpeg archive signature was not made by the pinned official signing key "
            f"{FFMPEG_SIGNING_FINGERPRINT}; found {fingerprints!r}"
        )
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    print(f"Verified {archive_name} with FFmpeg release key {FFMPEG_SIGNING_FINGERPRINT}; SHA-256 {digest}")
    return version, digest


def update_android_ffmpeg_pin(repo: Path, version: str, digest: str) -> bool:
    path = repo / "android/app/build.gradle.kts"
    source = path.read_text(encoding="utf-8")
    updated = source

    def replace_pin(pattern: str, value: str) -> None:
        nonlocal updated
        updated, count = re.subn(
            pattern,
            lambda match: f'{match.group(1)}{value}{match.group(2)}',
            updated,
        )
        if count != 1:
            raise ReleaseError(f"Expected one Android FFmpeg pin in {path}, found {count}: {pattern}")

    replace_pin(r'(val mpvFfmpegVersion = ")[^"]+("\s*)', version)
    replace_pin(r'(val mpvFfmpegSourceSha256 = ")[0-9a-f]{64}("\s*)', digest)
    if updated == source:
        return False
    path.write_text(updated, encoding="utf-8")
    return True


def prepare_native_checkout(scratch: Path) -> tuple[Path, str]:
    checkout = scratch / "mpv-build"
    command(["git", "clone", "--filter=blob:none", f"https://github.com/{MPV_REPO}.git", checkout])
    command(["git", "fetch", "origin", "main"], cwd=checkout)
    command(["git", "checkout", "--detach", "origin/main"], cwd=checkout)

    running = active_run(MPV_REPO, MPV_WORKFLOW, ref="main")
    if running:
        print(f"Reusing active native build {running['databaseId']} instead of starting a duplicate.")
        wait_for_run(MPV_REPO, running, "Native mpv/FFmpeg build")
    command(["git", "fetch", "origin", "main"], cwd=checkout)
    command(["git", "checkout", "--detach", "origin/main"], cwd=checkout)

    native_head = command(["git", "rev-parse", "origin/main"], cwd=checkout, capture=True).stdout.strip()
    native_title = "action:build:pool:private"
    existing = matching_run(
        MPV_REPO,
        MPV_WORKFLOW,
        native_head,
        ref="main",
        expected_title=native_title,
    )
    if existing and existing.get("status") == "completed" and existing.get("conclusion") == "success":
        print(f"Reusing successful native build {existing['databaseId']} for current source {native_head[:12]}.")
    else:
        if existing:
            print(
                f"Current-source native build {existing['databaseId']} concluded "
                f"{existing.get('conclusion') or existing.get('status')}; starting a fresh explicit build."
            )
        dispatch(
            MPV_REPO,
            MPV_WORKFLOW,
            "main",
            {"action_tag": "build", "runner_pool_tag": "private"},
            "Native mpv/FFmpeg build",
            expected_title=native_title,
            expected_sha=native_head,
        )

    command(["git", "fetch", "origin", "main"], cwd=checkout)
    command(["git", "checkout", "--detach", "origin/main"], cwd=checkout)
    # A valid older manifest alone does not prove that current main ran.
    sync_native_asset_bases(checkout)

    native_sha = command(["git", "rev-parse", "HEAD"], cwd=checkout, capture=True).stdout.strip()
    if not verify_native_groups(checkout):
        raise ReleaseError(
            "The native workflow completed, but its manifest/assets do not verify for every platform group. "
            "No PlezyNG pin was changed."
        )
    verify_native_release_assets(checkout)
    return checkout, native_sha


def verify_native_groups(checkout: Path) -> bool:
    for group in NATIVE_GROUPS:
        result = command(
            ["python3", "scripts/keys.py", "verify", "--platform-group", group],
            cwd=checkout,
            check=False,
        )
        if result.returncode:
            print(f"Native manifest verification failed for {group}.", file=sys.stderr)
            return False
    return True


def git_commit_as_current_user(checkout: Path, message: str) -> None:
    identity = gh_json("api", "user")
    login = identity.get("login")
    user_id = identity.get("id")
    if not login or not user_id:
        raise ReleaseError("Could not resolve the authenticated GitHub account for commit attribution.")
    email = f"{user_id}+{login}@users.noreply.github.com"
    command(
        ["git", "-c", f"user.name={login}", "-c", f"user.email={email}", "commit", "-m", message],
        cwd=checkout,
    )


def sync_native_asset_bases(checkout: Path) -> None:
    """Commit manifest URL corrections after the native publish run has drained."""
    command(["python3", "scripts/keys.py", "sync-asset-bases"], cwd=checkout)
    status = command(["git", "status", "--porcelain"], cwd=checkout, capture=True).stdout.strip()
    if not status:
        return
    changed_paths = {
        line[3:]
        for line in status.splitlines()
        if len(line) > 3
    }
    allowed = {"artifacts.json", "Package.swift"}
    if not changed_paths.issubset(allowed):
        raise ReleaseError(f"Asset-base sync changed unexpected files: {sorted(changed_paths - allowed)}")
    command(["git", "add", "artifacts.json", "Package.swift"], cwd=checkout)
    git_commit_as_current_user(checkout, "fix: point native artifacts at the organization fork")
    command(["git", "fetch", "origin", "main"], cwd=checkout)
    behind = command(
        ["git", "rev-list", "--count", "HEAD..origin/main"], cwd=checkout, capture=True
    ).stdout.strip()
    if behind != "0":
        command(["git", "rebase", "origin/main"], cwd=checkout)
    command(["git", "push", "origin", "HEAD:refs/heads/main"], cwd=checkout)
    command(["git", "fetch", "origin", "main"], cwd=checkout)
    command(["git", "checkout", "--detach", "origin/main"], cwd=checkout)


def manifest_assets(section: dict) -> dict[str, str | None]:
    assets: dict[str, str | None] = {}

    def add(value: object) -> None:
        if isinstance(value, str):
            assets.setdefault(value, None)
        elif isinstance(value, dict) and isinstance(value.get("asset"), str):
            checksum = value.get("checksum")
            if checksum is not None or value["asset"] not in assets:
                assets[value["asset"]] = checksum

    for entry in section.get("libraries", {}).values():
        add(entry.get("asset"))
        for value in (entry.get("prebuilt") or {}).values():
            add(value)
        for collection in ("frameworks", "symbols"):
            for value in (entry.get(collection) or {}).values():
                add(value)
    return assets


def verify_native_release_assets(checkout: Path) -> None:
    manifest = json.loads((checkout / "artifacts.json").read_text(encoding="utf-8"))
    for group in NATIVE_GROUPS:
        section = manifest["platforms"][group]
        expected_base = f"https://github.com/{MPV_REPO}/releases/download/binaries-{group}"
        if section.get("assetBase") != expected_base:
            raise ReleaseError(
                f"platforms.{group}.assetBase points to {section.get('assetBase')!r}; "
                f"expected the fork release {expected_base!r}."
            )
        release = gh_json("release", "view", f"binaries-{group}", "--repo", MPV_REPO, "--json", "assets")
        available = {asset["name"]: asset.get("digest") for asset in release.get("assets", [])}
        missing = sorted(set(manifest_assets(section)) - set(available))
        if missing:
            raise ReleaseError(f"{group} release is missing manifest assets: {', '.join(missing[:8])}")
        for name, checksum in manifest_assets(section).items():
            if checksum is None:
                continue
            remote_digest = available.get(name)
            if not remote_digest or not remote_digest.startswith("sha256:"):
                raise ReleaseError(f"GitHub did not provide a SHA-256 digest for {group}/{name}.")
            if remote_digest.removeprefix("sha256:") != checksum:
                raise ReleaseError(
                    f"Published {group}/{name} digest {remote_digest} does not match manifest {checksum}."
                )
        print(f"Verified {len(available)} assets in the {group} private-builder release.")


def create_plezy_worktree(scratch: Path) -> Path:
    worktree = scratch / "plezyng-main"
    command(["git", "fetch", "origin", "main"], cwd=ROOT)
    command(["git", "worktree", "add", "--detach", worktree, "origin/main"], cwd=ROOT)
    return worktree


def commit_and_push_native_pin(worktree: Path, native_repo: Path, native_sha: str,
                               ffmpeg_version: str, ffmpeg_sha256: str) -> str:
    command(["scripts/set_native_revision.sh", native_sha, "--repo", native_repo], cwd=worktree)
    update_android_ffmpeg_pin(worktree, ffmpeg_version, ffmpeg_sha256)
    command(["python3", "scripts/checks/check_apple_spm_locks.py"], cwd=worktree)
    command(["git", "diff", "--check"], cwd=worktree)

    changed = command(["git", "status", "--porcelain"], cwd=worktree, capture=True).stdout.strip()
    if changed:
        command(["git", "add", "-u"], cwd=worktree)
        command(
            ["git", "commit", "-m", f"build: pin verified native artifacts {native_sha[:12]}"],
            cwd=worktree,
        )

    command(["git", "fetch", "origin", "main"], cwd=worktree)
    behind = command(
        ["git", "rev-list", "--count", "HEAD..origin/main"], cwd=worktree, capture=True
    ).stdout.strip()
    if behind != "0":
        command(["git", "rebase", "origin/main"], cwd=worktree)
    command(["git", "push", "origin", "HEAD:refs/heads/main"], cwd=worktree)
    return command(["git", "rev-parse", "HEAD"], cwd=worktree, capture=True).stdout.strip()


def ensure_ci(commit_sha: str) -> dict:
    existing = matching_run(PLEZY_REPO, CI_WORKFLOW, commit_sha, ref="main")
    if existing:
        if existing.get("status") == "completed" and existing.get("conclusion") != "success":
            raise ReleaseError(f"CI for release commit {commit_sha[:12]} failed; refusing to tag it.")
        if existing.get("status") == "completed":
            print(f"Reusing successful CI run {existing['databaseId']} for {commit_sha[:12]}.")
            return existing
        return wait_for_run(PLEZY_REPO, existing, "PlezyNG CI")
    return dispatch(
        PLEZY_REPO,
        CI_WORKFLOW,
        "main",
        {"action": "ci", "runner_pool": "private", "build_linux_packages": "false"},
        "PlezyNG CI",
        expected_title="action:ci:pool:private",
        expected_sha=commit_sha,
    )


def ensure_tag(worktree: Path, version: str, commit_sha: str) -> str:
    tag = f"v{version}"
    command(["git", "fetch", "--tags", "origin"], cwd=worktree)
    existing = command(
        ["git", "rev-parse", f"refs/tags/{tag}^{{commit}}"],
        cwd=worktree,
        capture=True,
        check=False,
        quiet=True,
    )
    if existing.returncode == 0:
        if existing.stdout.strip() != commit_sha:
            raise ReleaseError(
                f"Tag {tag} already points to {existing.stdout.strip()[:12]}, "
                f"not release commit {commit_sha[:12]}; refusing to move it."
            )
        return tag
    command(["git", "tag", "-a", tag, commit_sha, "-m", f"PlezyNG {version}"], cwd=worktree)
    command(["git", "push", "origin", f"refs/tags/{tag}"], cwd=worktree)
    return tag


def ensure_release(tag: str, commit_sha: str, *, include_webos_release: bool) -> dict:
    run_title = f"action:release:pool:private:tag:{tag}"
    existing = matching_run(
        PLEZY_REPO,
        RELEASE_WORKFLOW,
        commit_sha,
        ref="main",
        expected_title=run_title,
    )
    if existing:
        if existing.get("status") == "completed" and existing.get("conclusion") != "success":
            raise ReleaseError(
                f"Release build run {existing['databaseId']} concluded {existing.get('conclusion')}; "
                "it was not re-run to avoid duplicating publication side effects."
            )
        if existing.get("status") == "completed":
            print(f"Reusing successful release build run {existing['databaseId']} for {tag}.")
            return existing
        return wait_for_run(PLEZY_REPO, existing, f"PlezyNG {tag} all-platform release build")
    ensure_remote_main_sha(commit_sha, f"dispatching the {tag} release build")
    return dispatch(
        PLEZY_REPO,
        RELEASE_WORKFLOW,
        "main",
        {
            "action": "release",
            "runner_pool": "private",
            "mode": "release",
            "build_version": tag.removeprefix("v"),
            "include_webos_build": "true",
            "include_webos_release": "true" if include_webos_release else "false",
            "include_tizen_build": "true",
        },
        f"PlezyNG {tag} all-platform release build",
        expected_title=run_title,
        expected_sha=commit_sha,
    )


def ensure_remote_main_sha(expected_sha: str, purpose: str) -> None:
    branch = gh_json("api", f"repos/{PLEZY_REPO}/branches/main")
    actual_sha = branch.get("commit", {}).get("sha") if isinstance(branch, dict) else None
    if actual_sha != expected_sha:
        raise ReleaseError(
            f"Cannot continue with {purpose}: PlezyNG main is {actual_sha or 'unavailable'}, "
            f"but release tag source is {expected_sha}. Reconcile main before publishing."
        )


def release_metadata(tag: str) -> dict:
    pages = gh_json(
        "api",
        "--paginate",
        "--slurp",
        f"repos/{PLEZY_REPO}/releases?per_page=100",
    )
    if isinstance(pages, list):
        for page in pages:
            if not isinstance(page, list):
                continue
            for release in page:
                if isinstance(release, dict) and release.get("tag_name") == tag:
                    return release
    raise ReleaseError(f"No GitHub release (draft or published) exists for tag {tag}.")


def publish_github_release(tag: str) -> dict:
    release = release_metadata(tag)
    if release.get("tag_name") != tag:
        raise ReleaseError(f"GitHub returned a different release tag while resolving {tag}.")
    if release.get("draft"):
        command([
            "gh", "api", "--method", "PATCH",
            f"repos/{PLEZY_REPO}/releases/{release['id']}",
            "-F", "draft=false",
        ])
    published = release_metadata(tag)
    if published.get("draft") or not published.get("published_at"):
        raise ReleaseError(f"GitHub release {tag} was not promoted to a published release.")
    return published


def validate_release_outputs(tag: str, version: str, *, include_webos_release: bool) -> None:
    release = release_metadata(tag)
    assets = {
        asset.get("name")
        for asset in release.get("assets", [])
        if isinstance(asset, dict) and isinstance(asset.get("name"), str)
    }
    required = {
        "SHA256SUMS.txt", "appcast.xml",
        "plezy-android-arm64-v8a.tar.gz", "plezy-android-armeabi-v7a.tar.gz", "plezy-android-x86_64.tar.gz",
        "plezy-ios-unsigned.ipa", "plezy-tvos-unsigned.ipa", "plezyng-macos.dmg",
        "plezy-windows-x64-portable.7z", "plezy-windows-arm64-portable.7z", "plezy-windows-installer.exe",
        f"plezyng-winget-manifests-{version}.zip", f"plezyng.{version}.nupkg",
        "plezy-linux-x64.tar.gz", "plezy-linux-x64.deb", "plezy-linux-x64.rpm",
        "plezy-linux-x64.pkg.tar.zst", "plezy-linux-x64.flatpak", "plezyng-linux-x64.snap",
        "plezy-linux-arm64.tar.gz", "plezy-linux-arm64.deb", "plezy-linux-arm64.rpm",
        "plezy-linux-arm64.pkg.tar.zst", "plezy-linux-arm64.flatpak", "plezyng-linux-arm64.snap",
        "plezyng-linux-x86_64.AppImage",
        "PlezyNG-tizen-arm-tester-handoff.zip",
    }
    if include_webos_release:
        required.update({
            "webos-engine-provenance.json", "webos-compatibility.json",
            "webos-SHA256SUMS.txt", "PlezyNG-lg-webos-submission.zip",
        })
        if not any(name.endswith(".ipk") for name in assets if isinstance(name, str)):
            required.add("<eligible webOS .ipk>")

    secrets = configured_repo_names("secret")
    android_signing = {
        "ANDROID_KEYSTORE_BASE64", "ANDROID_STORE_PASSWORD", "ANDROID_KEY_PASSWORD", "ANDROID_KEY_ALIAS",
    }
    if android_signing.issubset(secrets):
        required.update({"plezyng-android-play.aab", "plezyng-amazon-firetv.apk"})
    if {"APPLE_API_KEY_ID", "APPLE_API_ISSUER_ID", "APPLE_API_PRIVATE_KEY", "APPLE_TEAM_ID"}.issubset(secrets):
        required.add("plezyng-ios-appstore.ipa")
    if {"APPLE_API_KEY_ID", "APPLE_API_ISSUER_ID", "APPLE_API_PRIVATE_KEY", "APPLE_TEAM_ID"}.issubset(secrets):
        required.add("plezyng-tvos-appstore.ipa")

    missing = sorted(required - assets)
    if missing:
        raise ReleaseError(
            f"The draft release {tag} is missing expected platform/channel assets: {', '.join(missing)}. "
            "It remains a draft; no public release or store/package publication was started."
        )
    print(f"Verified {len(required)} required release assets for {tag} before publication.")


def configured_repo_names(kind: str) -> set[str]:
    rows = gh_json(kind, "list", "--repo", PLEZY_REPO, "--json", "name")
    if not isinstance(rows, list):
        raise ReleaseError(f"Could not read configured repository {kind}s.")
    return {row["name"] for row in rows if isinstance(row, dict) and isinstance(row.get("name"), str)}


def ensure_channel_run(
    workflow: str,
    title: str,
    fields: dict[str, str],
    purpose: str,
    *,
    release_sha: str,
) -> dict:
    for run in workflow_runs(PLEZY_REPO, workflow, ref="main"):
        if run.get("event") != "workflow_dispatch" or run.get("displayTitle") != title:
            continue
        if run.get("headSha") != release_sha:
            raise ReleaseError(
                f"Previous {purpose} run {run['databaseId']} used source "
                f"{run.get('headSha') or 'unknown'}, not the exact release commit {release_sha}."
            )
        if run.get("status") == "completed":
            if run.get("conclusion") != "success":
                raise ReleaseError(
                    f"Previous {purpose} run {run['databaseId']} concluded "
                    f"{run.get('conclusion')}; inspect its external side effects before retrying."
                )
            print(f"Reusing successful {purpose} run {run['databaseId']}.")
            return run
        return wait_for_run(PLEZY_REPO, run, purpose)
    ensure_remote_main_sha(release_sha, f"dispatching {purpose}")
    return dispatch(
        PLEZY_REPO,
        workflow,
        "main",
        fields,
        purpose,
        expected_title=title,
        expected_sha=release_sha,
    )


def publish_configured_channels(
    tag: str,
    version: str,
    *,
    release_sha: str,
    include_webos_release: bool,
) -> tuple[list[dict], list[dict], list[str]]:
    release = release_metadata(tag)
    assets = {asset.get("name") for asset in release.get("assets", []) if isinstance(asset, dict)}
    secrets = configured_repo_names("secret")
    variables = configured_repo_names("variable")

    specs = [
        {
            "name": "Google Play internal draft",
            "workflow": "publish-app-stores.yml",
            "title": f"action:publish-app-stores:pool:private:tag:{tag}:channel:google-play",
            "fields": {"action": "publish-app-stores", "runner_pool": "private", "release_tag": tag,
                       "channel": "google-play", "play_track": "internal", "play_release_status": "draft"},
            "secrets": {"GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"}, "variables": set(),
            "assets": {"plezyng-android-play.aab", "SHA256SUMS.txt"},
        },
        {
            "name": "Amazon Appstore upload",
            "workflow": "publish-app-stores.yml",
            "title": f"action:publish-app-stores:pool:private:tag:{tag}:channel:amazon-appstore",
            "fields": {"action": "publish-app-stores", "runner_pool": "private", "release_tag": tag,
                       "channel": "amazon-appstore", "play_track": "internal", "play_release_status": "draft"},
            "secrets": {"AMAZON_APPSTORE_CLIENT_ID", "AMAZON_APPSTORE_CLIENT_SECRET"}, "variables": set(),
            "assets": {"plezyng-amazon-firetv.apk", "SHA256SUMS.txt"},
        },
        {
            "name": "Apple App Store Connect iOS upload",
            "workflow": "publish-app-stores.yml",
            "title": f"action:publish-app-stores:pool:private:tag:{tag}:channel:app-store-ios",
            "fields": {"action": "publish-app-stores", "runner_pool": "private", "release_tag": tag,
                       "channel": "app-store-ios", "play_track": "internal", "play_release_status": "draft"},
            "secrets": {"APPLE_API_KEY_ID", "APPLE_API_ISSUER_ID", "APPLE_API_PRIVATE_KEY"}, "variables": set(),
            "assets": {"plezyng-ios-appstore.ipa", "SHA256SUMS.txt"},
        },
        {
            "name": "Apple App Store Connect tvOS upload",
            "workflow": "publish-app-stores.yml",
            "title": f"action:publish-app-stores:pool:private:tag:{tag}:channel:app-store-tvos",
            "fields": {"action": "publish-app-stores", "runner_pool": "private", "release_tag": tag,
                       "channel": "app-store-tvos", "play_track": "internal", "play_release_status": "draft"},
            "secrets": {"APPLE_API_KEY_ID", "APPLE_API_ISSUER_ID", "APPLE_API_PRIVATE_KEY"}, "variables": set(),
            "assets": {"plezyng-tvos-appstore.ipa", "SHA256SUMS.txt"},
        },
        {
            "name": "AUR",
            "workflow": "publish-aur.yml",
            "title": f"action:publish-aur:pool:private:tag:{tag}",
            "fields": {"action": "publish-aur", "runner_pool": "private", "release_tag": tag},
            "secrets": {"AUR_SSH_KEY"}, "variables": {"AUR_PACKAGE_NAME"},
            "assets": {"plezy-linux-x64.tar.gz", "plezy-linux-arm64.tar.gz", "SHA256SUMS.txt"},
        },
        {
            "name": "Fedora COPR",
            "workflow": "publish-copr.yml",
            "title": f"action:publish-copr:pool:private:tag:{tag}",
            "fields": {"action": "publish-copr", "runner_pool": "private", "release_tag": tag},
            "secrets": {"COPR_LOGIN", "COPR_USERNAME", "COPR_TOKEN"}, "variables": {"COPR_PROJECT"},
            "assets": {"plezy-linux-x64.tar.gz", "plezy-linux-arm64.tar.gz", "SHA256SUMS.txt"},
        },
        {
            "name": "Launchpad PPA",
            "workflow": "publish-ppa.yml",
            "title": f"action:publish-ppa:pool:private:tag:{tag}",
            "fields": {"action": "publish-ppa", "runner_pool": "private", "release_tag": tag},
            "secrets": {"GPG_PRIVATE_KEY"}, "variables": {"LAUNCHPAD_PPA"},
            "assets": {"plezy-linux-x64.tar.gz", "plezy-linux-arm64.tar.gz", "SHA256SUMS.txt"},
        },
        {
            "name": "Snap Store stable",
            "workflow": "publish-snap.yml",
            "title": f"action:publish-snap:pool:private:tag:{tag}:channel:stable",
            "fields": {"action": "publish-snap", "runner_pool": "private", "release_tag": tag,
                       "channel": "stable"},
            "secrets": {"SNAPCRAFT_STORE_CREDENTIALS"}, "variables": set(),
            "assets": {"plezyng-linux-x64.snap", "plezyng-linux-arm64.snap", "SHA256SUMS.txt"},
        },
        {
            "name": "Chocolatey",
            "workflow": "publish-chocolatey.yml",
            "title": f"action:publish-chocolatey:pool:private:tag:{tag}:publish:true",
            "fields": {"action": "publish-chocolatey", "runner_pool": "private", "release_tag": tag,
                       "publish": "true"},
            "secrets": {"CHOCO_API_KEY"}, "variables": set(),
            "assets": {"plezy-windows-installer.exe", "SHA256SUMS.txt"},
            "asset_predicate": lambda name: name.startswith("plezyng.") and name.endswith(".nupkg"),
        },
        {
            "name": "WinGet community submission",
            "workflow": "publish-winget.yml",
            "title": f"action:publish-winget:pool:private:tag:{tag}:submit:true",
            "fields": {"action": "publish-winget", "runner_pool": "private", "release_tag": tag,
                       "submit": "true"},
            "secrets": {"WINGET_CREATE_GITHUB_TOKEN"}, "variables": set(),
            "assets": {f"plezyng-winget-manifests-{version}.zip", "plezy-windows-installer.exe", "SHA256SUMS.txt"},
        },
        {
            "name": "GitHub Container Registry and Docker Hub",
            "workflow": "release-containers.yml",
            "title": f"action:publish-containers:pool:private:tag:{tag}",
            "fields": {"action": "publish-containers", "runner_pool": "private", "release_tag": tag},
            "secrets": set(), "variables": set(),
            "assets": {"SHA256SUMS.txt"},
        },
        {
            "name": "Discord release announcement",
            "workflow": "discord-release.yml",
            "title": f"action:announce-release:pool:private:tag:{tag}",
            "fields": {"action": "announce-release", "runner_pool": "private", "release_tag": tag},
            "secrets": {"DISCORD_RELEASE_WEBHOOK"}, "variables": set(),
            "assets": set(),
        },
        {
            "name": "Homebrew cask and Sparkle appcast",
            "workflow": "update-packages.yml",
            "title": f"action:update-packages:pool:private:tag:{tag}",
            "fields": {"action": "update-packages", "runner_pool": "private", "release_tag": tag},
            "secrets": set(), "variables": set(),
            "assets": {"plezyng-macos.dmg", "appcast.xml"},
        },
    ]

    completed: list[dict] = []
    skipped: list[dict] = []
    failures: list[str] = []
    macos_signing = {
        "MACOS_CERTIFICATE_BASE64", "MACOS_CERTIFICATE_PASSWORD", "KEYCHAIN_PASSWORD",
        "APPLE_ID", "APPLE_APP_SPECIFIC_PASSWORD", "APPLE_TEAM_ID",
    }
    if not macos_signing.issubset(secrets):
        skipped.append({
            "channel": "Homebrew Cask",
            "reason": "Developer ID signing and notarization secrets are not configured; appcast update remains enabled.",
        })
    if not {"WINDOWS_SIGNING_CERTIFICATE_BASE64", "WINDOWS_SIGNING_CERTIFICATE_PASSWORD"}.issubset(secrets):
        skipped.append({
            "channel": "Windows Authenticode signature",
            "reason": "certificate secrets are not configured; Windows release files will be unsigned.",
        })
    skipped.append({
        "channel": "Microsoft Store",
        "reason": "MSSTORE_PACKAGE_NAME, MSSTORE_PUBLISHER, and MSSTORE_PUBLISHER_DISPLAY_NAME are not configured.",
    })
    skipped.append({
        "channel": "Samsung Tizen Seller Office",
        "reason": "no Samsung TV signing profile is configured; the release builds a tester TPK only.",
    })
    if not include_webos_release:
        skipped.append({
            "channel": "LG webOS public release",
            "reason": "the webOS IPK is built as a candidate; exact-artifact eligibility is not enabled.",
        })
    for spec in specs:
        missing_secrets = sorted(spec["secrets"] - secrets)
        missing_variables = sorted(spec["variables"] - variables)
        if missing_secrets or missing_variables:
            skipped.append({
                "channel": spec["name"],
                "reason": f"missing secrets={missing_secrets}, variables={missing_variables}",
            })
            print(f"Skipping {spec['name']}: missing configured credentials or variables.")
            continue
        predicate = spec.get("asset_predicate")
        required_assets = set(spec["assets"])
        if predicate:
            matching = {name for name in assets if isinstance(name, str) and predicate(name)}
            if not matching:
                required_assets.add("<Chocolatey .nupkg>")
        missing_assets = sorted(required_assets - assets)
        if missing_assets:
            failures.append(f"{spec['name']} lacks release assets: {missing_assets}")
            continue
        try:
            result = ensure_channel_run(
                spec["workflow"],
                spec["title"],
                spec["fields"],
                spec["name"],
                release_sha=release_sha,
            )
            completed.append({"channel": spec["name"], "run_id": result["databaseId"], "url": result.get("url")})
        except ReleaseError as error:
            failures.append(f"{spec['name']}: {error}")
    return completed, skipped, failures


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="Release version matching pubspec.yaml, such as 3.0.0")
    parser.add_argument(
        "--include-webos-release",
        action="store_true",
        help="Attach the webOS IPK to the public draft release when the existing eligibility gate passes.",
    )
    parser.add_argument(
        "--publish",
        action="store_true",
        help=(
            "After every release build succeeds, publish the GitHub release and run each configured "
            "package/store channel sequentially. Store lanes upload binaries but do not submit them for review."
        ),
    )
    parser.add_argument(
        "--scratch",
        type=Path,
        help="Keep temporary checkouts and signature-verification inputs under this directory.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        raise ReleaseError("--version must be MAJOR.MINOR.PATCH, without a leading v.")
    package_version = command(
        ["python3", "scripts/pubspec_version.py", "pubspec.yaml"], cwd=ROOT, capture=True
    ).stdout.strip().split("+", 1)[0]
    if package_version != args.version:
        raise ReleaseError(f"Requested {args.version}, but pubspec.yaml declares {package_version}.")
    command(["gh", "auth", "status", "--hostname", "github.com"], capture=True, quiet=True)

    scratch = args.scratch.resolve() if args.scratch else Path(tempfile.mkdtemp(prefix="plezyng-release-"))
    if scratch.exists() and any(scratch.iterdir()):
        raise ReleaseError(f"Scratch directory must be empty so task-owned cleanup is exact: {scratch}")
    scratch.mkdir(parents=True, exist_ok=True)
    summary_path = scratch / "release-summary.json"
    progress_path = scratch / "release-progress.json"
    worktree: Path | None = None
    stage = "startup"
    progress = {"version": args.version, "status": "running", "stage": stage}

    def save_progress() -> None:
        progress_path.write_text(json.dumps(progress, indent=2) + "\n", encoding="utf-8")

    try:
        print(f"Release scratch: {scratch}", flush=True)
        stage = "native build and manifest verification"
        progress["stage"] = stage
        save_progress()
        native_repo, native_sha = prepare_native_checkout(scratch)
        progress["native_manifest_commit"] = native_sha
        versions = json.loads((native_repo / "versions.json").read_text(encoding="utf-8"))
        ffmpeg_pin = versions["components"]["ffmpeg"]["version"]
        stage = "FFmpeg signature and checksum verification"
        progress["stage"] = stage
        save_progress()
        ffmpeg_version, ffmpeg_sha256 = verified_ffmpeg_source(ffmpeg_pin, scratch / "ffmpeg")
        progress["ffmpeg_version"] = ffmpeg_version
        progress["ffmpeg_source_sha256"] = ffmpeg_sha256

        stage = "PlezyNG pin update and push"
        progress["stage"] = stage
        save_progress()
        worktree = create_plezy_worktree(scratch)
        pin_sha = commit_and_push_native_pin(
            worktree, native_repo, native_sha, ffmpeg_version, ffmpeg_sha256
        )
        progress["plezyng_commit"] = pin_sha
        stage = "PlezyNG CI"
        progress["stage"] = stage
        save_progress()
        ci = ensure_ci(pin_sha)
        progress["ci_run"] = ci["databaseId"]
        stage = "release tag"
        progress["stage"] = stage
        save_progress()
        tag = ensure_tag(worktree, args.version, pin_sha)
        progress["tag"] = tag
        stage = "all-platform release build"
        progress["stage"] = stage
        save_progress()
        release = ensure_release(tag, pin_sha, include_webos_release=args.include_webos_release)
        progress["release_run"] = release["databaseId"]
        progress["release_url"] = f"https://github.com/{PLEZY_REPO}/releases/tag/{tag}"

        stage = "release asset validation"
        progress["stage"] = stage
        save_progress()
        validate_release_outputs(
            tag,
            args.version,
            include_webos_release=args.include_webos_release,
        )

        published_channels: list[dict] = []
        skipped_channels: list[dict] = []
        channel_failures: list[str] = []
        release_published = False
        if args.publish:
            ensure_remote_main_sha(pin_sha, f"publishing PlezyNG {tag}")
            stage = "publish GitHub release"
            progress["stage"] = stage
            save_progress()
            publish_github_release(tag)
            release_published = True
            progress["release_published"] = True
            stage = "publish configured release channels"
            progress["stage"] = stage
            save_progress()
            published_channels, skipped_channels, channel_failures = publish_configured_channels(
                tag,
                args.version,
                release_sha=pin_sha,
                include_webos_release=args.include_webos_release,
            )
            progress["published_channels"] = published_channels
            progress["skipped_channels"] = skipped_channels
            progress["channel_failures"] = channel_failures
            save_progress()
            if channel_failures:
                raise ReleaseError("Release channel publication failures:\n- " + "\n- ".join(channel_failures))
        else:
            metadata = release_metadata(tag)
            release_published = not metadata.get("draft") and bool(metadata.get("published_at"))

        summary = {
            "version": args.version,
            "tag": tag,
            "native_manifest_commit": native_sha,
            "ffmpeg_version": ffmpeg_version,
            "ffmpeg_source_sha256": ffmpeg_sha256,
            "plezyng_commit": pin_sha,
            "ci_run": ci["databaseId"],
            "release_run": release["databaseId"],
            "release_url": f"https://github.com/{PLEZY_REPO}/releases/tag/{tag}",
            "release_published": release_published,
            "published_channels": published_channels,
            "skipped_channels": skipped_channels,
            "webos_built": True,
            "webos_attached_to_public_release": args.include_webos_release,
            "tizen_built": True,
            "tizen_seller_office_submission": "not configured; tester artifact only",
            "microsoft_store": "not configured; package identity variables are absent",
            "runner_pool": "private JIT",
        }
        progress.update(summary)
        progress["status"] = "success"
        progress["stage"] = "complete"
        save_progress()
        summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        print("\nRelease orchestration completed:")
        print(json.dumps(summary, indent=2))
        print(f"Evidence: {summary_path}")
        return 0
    except Exception as error:
        progress["status"] = "failed"
        progress["stage"] = stage
        progress["error"] = str(error)
        save_progress()
        failure_path = scratch / "release-failure.json"
        failure_path.write_text(
            json.dumps({"failed_at": stage, "error": str(error)}, indent=2) + "\n",
            encoding="utf-8",
        )
        raise
    finally:
        if worktree is not None:
            command(["git", "worktree", "remove", "--force", worktree], cwd=ROOT, check=False, quiet=True)
        # Remove only the checkouts and downloads this run created; keep receipts.
        for name in ("mpv-build", "plezyng-main", "ffmpeg"):
            child = scratch / name
            if child.is_symlink() or child.is_file():
                child.unlink(missing_ok=True)
            elif child.is_dir():
                shutil.rmtree(child, ignore_errors=True)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ReleaseError as error:
        print(f"release orchestration stopped: {error}", file=sys.stderr)
        raise SystemExit(1)
