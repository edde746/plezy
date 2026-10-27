#!/usr/bin/env python3
"""Orchestrate a native dependency refresh and the complete PlezyNG release build.

This is a local control-plane command. All build, test, package, and release
jobs still run on their existing private JIT runners. It uses the operator's
authenticated `gh` CLI session and never copies credentials into the repos.
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
        "--json", "databaseId,status,conclusion,headSha,headBranch,event,createdAt,url",
    ]
    if ref:
        args.extend(["--branch", ref])
    result = command(["gh", *args], capture=True)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ReleaseError(f"Could not read workflow runs for {repo}/{workflow}") from error


def matching_run(repo: str, workflow: str, sha: str, *, ref: str | None = None) -> dict | None:
    runs = workflow_runs(repo, workflow, ref=ref)
    matches = [run for run in runs if run.get("headSha") == sha and run.get("event") == "workflow_dispatch"]
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


def dispatch(repo: str, workflow: str, ref: str, fields: dict[str, str], purpose: str) -> dict:
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

    sync_native_asset_bases(checkout)
    if not verify_native_groups(checkout):
        native_head = command(["git", "rev-parse", "origin/main"], cwd=checkout, capture=True).stdout.strip()
        existing = matching_run(MPV_REPO, MPV_WORKFLOW, native_head, ref="main")
        if existing and existing.get("status") == "completed":
            raise ReleaseError(
                f"Native manifest verification failed for {native_head[:12]}, whose latest build "
                f"concluded {existing.get('conclusion')}; refusing to publish unverified artifacts."
            )
        dispatch(
            MPV_REPO,
            MPV_WORKFLOW,
            "main",
            {"action_tag": "build", "runner_pool_tag": "private"},
            "Native mpv/FFmpeg build",
        )
        command(["git", "fetch", "origin", "main"], cwd=checkout)
        command(["git", "checkout", "--detach", "origin/main"], cwd=checkout)
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
    existing = matching_run(PLEZY_REPO, RELEASE_WORKFLOW, commit_sha, ref=tag)
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
    return dispatch(
        PLEZY_REPO,
        RELEASE_WORKFLOW,
        tag,
        {
            "action": "release",
            "runner_pool": "private",
            "mode": "release",
            "include_webos_build": "true",
            "include_webos_release": "true" if include_webos_release else "false",
            "include_tizen_build": "true",
        },
        f"PlezyNG {tag} all-platform release build",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="Release version matching pubspec.yaml, such as 2.25.0")
    parser.add_argument(
        "--include-webos-release",
        action="store_true",
        help="Attach the webOS IPK to the public draft release when the existing eligibility gate passes.",
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
    worktree: Path | None = None
    stage = "startup"
    try:
        print(f"Release scratch: {scratch}", flush=True)
        stage = "native build and manifest verification"
        native_repo, native_sha = prepare_native_checkout(scratch)
        versions = json.loads((native_repo / "versions.json").read_text(encoding="utf-8"))
        ffmpeg_pin = versions["components"]["ffmpeg"]["version"]
        stage = "FFmpeg signature and checksum verification"
        ffmpeg_version, ffmpeg_sha256 = verified_ffmpeg_source(ffmpeg_pin, scratch / "ffmpeg")

        stage = "PlezyNG pin update and push"
        worktree = create_plezy_worktree(scratch)
        pin_sha = commit_and_push_native_pin(
            worktree, native_repo, native_sha, ffmpeg_version, ffmpeg_sha256
        )
        stage = "PlezyNG CI"
        ci = ensure_ci(pin_sha)
        stage = "release tag"
        tag = ensure_tag(worktree, args.version, pin_sha)
        stage = "all-platform release build"
        release = ensure_release(tag, pin_sha, include_webos_release=args.include_webos_release)

        summary = {
            "version": args.version,
            "tag": tag,
            "native_manifest_commit": native_sha,
            "ffmpeg_version": ffmpeg_version,
            "ffmpeg_source_sha256": ffmpeg_sha256,
            "plezyng_commit": pin_sha,
            "ci_run": ci["databaseId"],
            "release_run": release["databaseId"],
            "release_draft": f"https://github.com/{PLEZY_REPO}/releases/tag/{tag}",
            "webos_built": True,
            "webos_attached_to_public_release": args.include_webos_release,
            "tizen_built": True,
            "runner_pool": "private JIT",
        }
        summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        print("\nRelease orchestration completed:")
        print(json.dumps(summary, indent=2))
        print(f"Evidence: {summary_path}")
        return 0
    except Exception as error:
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
