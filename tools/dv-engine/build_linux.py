#!/usr/bin/env python3
"""Build a separate, pinned-source FEL engine; never install into the host/app."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import subprocess
import tarfile


HERE = Path(__file__).resolve().parent


def run(args, *, cwd=None, env=None, capture=False):
    print("+ " + shlex.join(map(str, args)), flush=True)
    return subprocess.run(
        list(map(str, args)), cwd=cwd, env=env, check=True,
        text=True, stdout=subprocess.PIPE if capture else None, timeout=3600,
    ).stdout


def build(work: Path, jobs: int):
    lock = json.loads((HERE / "engine.lock.json").read_text())
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "aarch64"):
        raise SystemExit("This recipe currently supports native Linux x86_64/aarch64 only.")
    if work.exists() and any(work.iterdir()):
        raise SystemExit("Use an empty work directory; stale dependencies must not enter this build.")
    work.mkdir(parents=True, exist_ok=True)
    prefix = work / "engine"
    prefix.mkdir()
    source_root = work / "sources"
    source_root.mkdir()
    provenance = {"lock": lock, "platform": platform.platform(), "commands": [], "sources": {}}
    env = os.environ.copy()
    env.update({
        "HOME": str(work / "home"),
        "XDG_CACHE_HOME": str(work / "home/cache"),
        "PKG_CONFIG_PATH": str(prefix / "lib/pkgconfig"),
        "LD_LIBRARY_PATH": str(prefix / "lib"),
        "LC_ALL": "C.UTF-8",
        "GIT_TERMINAL_PROMPT": "0",
    })
    (work / "home/cache").mkdir(parents=True)

    def execute(args, *, cwd=None, capture=False):
        provenance["commands"].append(list(map(str, args)))
        return run(args, cwd=cwd, env=env, capture=capture)

    for name, spec in lock["sources"].items():
        if not re.fullmatch(r"[a-z]+", name) or not re.fullmatch(r"[0-9a-f]{40}", spec["commit"]):
            raise SystemExit("Invalid source identity in engine lock")
        if not re.fullmatch(r"https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git", spec["url"]):
            raise SystemExit("Only explicit HTTPS GitHub sources are accepted")
        source = source_root / name
        execute(["git", "init", source])
        execute(["git", "remote", "add", "origin", spec["url"]], cwd=source)
        execute(["git", "fetch", "--depth=1", "origin", spec["commit"]], cwd=source)
        execute(["git", "checkout", "--detach", spec["commit"]], cwd=source)
        actual = execute(["git", "rev-parse", "HEAD"], cwd=source, capture=True).strip()
        if actual != spec["commit"]:
            raise SystemExit(f"Source mismatch for {name}")
        execute(["git", "-c", "protocol.file.allow=never", "submodule", "update", "--init", "--recursive", "--depth=1"], cwd=source)
        submodules = execute(["git", "submodule", "status", "--recursive"], cwd=source, capture=True)
        if any(line[:1] != " " for line in submodules.splitlines()):
            raise SystemExit(f"Unpinned or unresolved submodule for {name}")
        provenance["sources"][name] = {"commit": actual, "submodules": submodules}

    mpv_patcher = HERE / "patches/apply_mpv_fel_failclosed.py"
    execute(["python3", mpv_patcher, source_root / "mpv"])

    patch = HERE / "patches/libplacebo-reject-failed-fel.patch"
    execute(["git", "apply", "--check", patch], cwd=source_root / "libplacebo")
    execute(["git", "apply", patch], cwd=source_root / "libplacebo")
    provenance["patches"] = {
        patch.name: hashlib.sha256(patch.read_bytes()).hexdigest(),
        mpv_patcher.name: hashlib.sha256(mpv_patcher.read_bytes()).hexdigest(),
    }

    ffmpeg = source_root / "ffmpeg"
    ffmpeg_build = work / "ffmpeg-build"
    ffmpeg_build.mkdir()
    execute([
        ffmpeg / "configure", f"--prefix={prefix}", f"--libdir={prefix / 'lib'}",
        "--enable-shared", "--disable-static", "--enable-pic", "--enable-gpl",
        "--enable-version3", "--disable-autodetect", "--enable-gnutls", "--enable-zlib",
        "--enable-libdav1d", "--enable-vaapi", "--enable-libdrm",
        "--enable-decoder=png",
        "--enable-bsf=dovi_split", "--disable-doc", "--disable-debug",
    ], cwd=ffmpeg_build)
    execute(["make", f"-j{jobs}"], cwd=ffmpeg_build)
    execute(["make", "install"], cwd=ffmpeg_build)

    placebo_build = work / "libplacebo-build"
    execute([
        "meson", "setup", placebo_build, source_root / "libplacebo",
        f"--prefix={prefix}", "--libdir=lib", "--buildtype=debugoptimized",
        "--wrap-mode=nofallback", "-Ddefault_library=shared", "-Dopengl=enabled",
        "-Dvulkan=disabled", "-Dd3d11=disabled", "-Dglslang=disabled",
        "-Dshaderc=disabled", "-Ddovi=enabled", "-Dlibdovi=disabled",
        "-Ddemos=false", "-Dtests=true",
    ])
    execute(["meson", "compile", "-C", placebo_build, "-j", jobs])
    execute(["meson", "install", "-C", placebo_build])

    mpv_build = work / "mpv-build"
    execute([
        "meson", "setup", mpv_build, source_root / "mpv",
        f"--prefix={prefix}", "--libdir=lib", "--buildtype=debugoptimized",
        "--wrap-mode=nofallback", "-Dcplayer=true", "-Dlibmpv=true",
        "-Dtests=true", "-Dbuild-date=false", "-Dgl=enabled", "-Degl=enabled",
        "-Dplain-gl=enabled", "-Dvulkan=disabled", "-Dshaderc=disabled",
        "-Dmanpage-build=disabled", "-Dhtml-build=disabled", "-Dpdf-build=disabled",
    ])
    execute(["meson", "compile", "-C", mpv_build, "-j", jobs])
    execute(["meson", "install", "-C", mpv_build])

    # Mandatory runtime/ABI checks. A successful build is not FEL pixel evidence.
    probe = work / "engine_features"
    flags = shlex.split(execute(["pkg-config", "--cflags", "--libs", "mpv", "libplacebo", "libavcodec", "libavformat"], capture=True))
    execute(["cc", "-std=c11", "-Wall", "-Wextra", "-Werror", HERE / "engine_features.c", "-o", probe, *flags])
    feature_report = execute([probe], capture=True)
    (prefix / "feature-report.json").write_text(feature_report)
    vo = execute([prefix / "bin/mpv", "--no-config", "--vo=help"], capture=True)
    if "gpu-next" not in vo:
        raise SystemExit("Built engine does not expose gpu-next")
    (prefix / "video-outputs.txt").write_text(vo)
    provenance["mpv_version"] = execute([prefix / "bin/mpv", "--no-config", "--version"], capture=True)
    provenance["ffmpeg_version"] = execute([prefix / "bin/ffmpeg", "-version"], capture=True)
    provenance["system_packages"] = execute(["dpkg-query", "-W", "-f=${Package}\t${Version}\n"], capture=True)

    smoke = work / "render_smoke"
    flags = shlex.split(execute(["pkg-config", "--cflags", "--libs", "mpv", "libplacebo", "egl", "glesv2"], capture=True))
    execute(["cc", "-std=c11", "-Wall", "-Wextra", "-Werror", HERE / "render_smoke.c", HERE / "fel_smoke.c", "-o", smoke, *flags, "-lm"])
    execute(["cc", "-std=c11", "-Wall", "-Wextra", "-Werror", HERE / "real_clip_smoke.c",
             "-o", prefix / "bin/plezyng-dv-real-clip", *flags, "-lm"])
    env.update({"LIBGL_ALWAYS_SOFTWARE": "1", "EGL_PLATFORM": "surfaceless"})
    # The test asks for an ES context to match the application's surface family.
    # llvmpipe is a renderer integration check, not a real GPU/TV qualification.
    execute([smoke, work / "smoke.ppm"])
    provenance["surfaceless_gles_render_smoke"] = "passed-software-mesa"
    provenance["synthetic_fel_vectors"] = "passed-zero-positive-negative-threshold-clamping"
    test_results = {}
    for name, build_dir in (("mpv", mpv_build), ("libplacebo", placebo_build)):
        try:
            execute(["meson", "test", "-C", build_dir, "--print-errorlogs", "--no-rebuild", "--timeout-multiplier=3"])
            test_results[name] = "passed"
        except subprocess.CalledProcessError as exc:
            test_results[name] = f"failed-exit-{exc.returncode}"
    if any(result != "passed" for result in test_results.values()):
        provenance["unit_tests"] = test_results
        (prefix / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
        raise SystemExit(f"Upstream test failure: {test_results}")
    provenance["unit_tests"] = test_results

    # Ship source identities and corresponding source, including locked submodules.
    notices = prefix / "sources"
    notices.mkdir()
    for name in lock["sources"]:
        with tarfile.open(notices / f"{name}.tar.xz", "w:xz") as archive:
            archive.add(source_root / name, arcname=name,
                        filter=lambda item: None if ".git" in Path(item.name).parts else item)
    for name in ("engine.lock.json", "README.md", "run.py"):
        shutil.copy2(HERE / name, prefix / name)
    shutil.copytree(HERE / "patches", prefix / "patches")
    integration_source = notices / "integration"
    integration_source.mkdir()
    for name in ("Dockerfile", "build_linux.py", "engine_features.c", "fel_smoke.c", "render_smoke.c", "real_clip_smoke.c"):
        shutil.copy2(HERE / name, integration_source / name)
    shutil.copy2(mpv_patcher, integration_source / mpv_patcher.name)
    (prefix / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
    artifact = work / f"plezyng-dv-experimental-{platform.machine()}.tar.xz"
    with tarfile.open(artifact, "w:xz") as archive:
        archive.add(prefix, arcname="plezyng-dv-experimental")
    with artifact.open("rb") as content:
        digest = hashlib.file_digest(content, "sha256").hexdigest()
    artifact.with_suffix(artifact.suffix + ".sha256").write_text(f"{digest}  {artifact.name}\n")
    print(f"Built {artifact}; real FEL clips, app integration and DV signaling remain unqualified.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--jobs", type=int, default=2)
    args = parser.parse_args()
    if not 1 <= args.jobs <= 64:
        parser.error("--jobs must be between 1 and 64")
    build(args.work_dir.resolve(), args.jobs)


if __name__ == "__main__":
    main()
