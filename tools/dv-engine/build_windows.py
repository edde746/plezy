#!/usr/bin/env python3
"""Build the pinned dual-layer engine natively in an MSYS2 MinGW shell.

Produces a separate mpv-dev-shaped ZIP for an explicitly selected app build.
Does not overwrite a release engine or change system DLL search paths.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tarfile
import zipfile

from engine_bundle import bundle_manifest, digest, pe_machine, MACHINES, validate_bundle


HERE = Path(__file__).resolve().parent


def compiler_architecture(triple: str) -> str:
    if re.fullmatch(r"x86_64-w64-(mingw32|windows-gnu)", triple):
        return "x86_64"
    if re.fullmatch(r"aarch64-w64-(mingw32|windows-gnu)", triple):
        return "aarch64"
    raise ValueError(f"Unsupported native MinGW compiler: {triple}")


def imported_dlls(objdump_output: str) -> list[str]:
    names = re.findall(r"^\s*DLL Name:\s*(\S+)\s*$", objdump_output, re.MULTILINE)
    if any(not re.fullmatch(r"[A-Za-z0-9_.+\-]+\.dll", name, re.IGNORECASE) for name in names):
        raise ValueError("Invalid imported DLL name")
    return names


def collect_runtime_dlls(bundle: Path, search: list[Path], system: Path,
                         architecture: str, inspect) -> None:
    # Follow imports, never glob the whole toolchain into the application.
    pending = list(bundle.glob("*.dll")) + list(bundle.glob("*.exe"))
    seen = set()
    indexes = []
    for directory in search:
        index = {}
        for candidate in directory.glob("*.dll"):
            key = candidate.name.casefold()
            if key in index:
                raise ValueError("Ambiguous runtime DLL names")
            index[key] = candidate
        indexes.append(index)
    while pending:
        image = pending.pop()
        key = image.name.casefold()
        if key in seen:
            continue
        seen.add(key)
        if pe_machine(image) != MACHINES[architecture]:
            raise ValueError(f"Runtime architecture mismatch: {image.name}")
        for name in imported_dlls(inspect(image)):
            key = name.casefold()
            if key in seen:
                continue
            existing = next((p for p in bundle.glob("*.dll") if p.name.casefold() == key), None)
            if existing is not None:
                pending.append(existing)
                continue
            source = next((index[key] for index in indexes if key in index), None)
            if source is not None:
                target = bundle / source.name
                shutil.copy2(source, target)
                pending.append(target)
            elif not (key.startswith(("api-ms-win-", "ext-ms-win-")) or (system / name).is_file()):
                raise ValueError(f"Unresolved engine dependency: {name}")


def build(work: Path, jobs: int) -> Path:
    if sys.platform != "win32" or not os.environ.get("MSYSTEM_PREFIX"):
        raise ValueError("Run with native MinGW Python inside an MSYS2 UCRT64/CLANGARM64 shell")
    if work.exists() and any(work.iterdir()):
        raise ValueError("Use an empty work directory")
    for tool in ("git", "bash", "make", "meson", "ninja", "pkg-config", "cc", "objdump", "cygpath"):
        if not shutil.which(tool):
            raise ValueError(f"Missing build tool: {tool}")
    work.mkdir(parents=True, exist_ok=True)
    prefix, sources, bundle = (work / name for name in ("prefix", "sources", "bundle"))
    for directory in (prefix, sources, bundle):
        directory.mkdir()
    env = os.environ.copy()
    env["PATH"] = str(prefix / "bin") + os.pathsep + env["PATH"]
    env["PKG_CONFIG_PATH"] = str(prefix / "lib/pkgconfig") + os.pathsep + env.get("PKG_CONFIG_PATH", "")
    env["GIT_TERMINAL_PROMPT"] = "0"
    env["SOURCE_DATE_EPOCH"] = "1577836800"
    provenance = {"commands": [], "qualification": "unverified", "production_patch_parity": False}

    def run(args, *, cwd=None, capture=False):
        args = list(map(str, args))
        provenance["commands"].append(args)
        print("+ " + shlex.join(args), flush=True)
        return subprocess.run(args, cwd=cwd, env=env, check=True, text=True,
                              stdout=subprocess.PIPE if capture else None, timeout=7200).stdout

    architecture = compiler_architecture(run(["cc", "-dumpmachine"], capture=True).strip())
    toolchain = Path(run(["cygpath", "-w", os.environ["MSYSTEM_PREFIX"]], capture=True).strip())
    # Record the concrete dependency versions, rather than claiming the package
    # manager's current channel is a pinned SDK.
    provenance["packages"] = run(["bash", "-lc", "pacman -Q"], capture=True)
    lock = json.loads((HERE / "engine.lock.json").read_text())
    for name, spec in lock["sources"].items():
        if not re.fullmatch(r"[a-z]+", name) or not re.fullmatch(r"[0-9a-f]{40}", spec["commit"]):
            raise ValueError("Invalid pinned source identity")
        if not re.fullmatch(r"https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git", spec["url"]):
            raise ValueError("Invalid pinned source URL")
        source = sources / name
        run(["git", "init", source])
        run(["git", "remote", "add", "origin", spec["url"]], cwd=source)
        run(["git", "fetch", "--depth=1", "origin", spec["commit"]], cwd=source)
        run(["git", "checkout", "--detach", spec["commit"]], cwd=source)
        if run(["git", "rev-parse", "HEAD"], cwd=source, capture=True).strip() != spec["commit"]:
            raise ValueError("Pinned source mismatch")
        run(["git", "-c", "protocol.file.allow=never", "submodule", "update", "--init", "--recursive", "--depth=1"], cwd=source)
        status = run(["git", "submodule", "status", "--recursive"], cwd=source, capture=True)
        if any(line[:1] != " " for line in status.splitlines()):
            raise ValueError("Unresolved source submodule")
    run([sys.executable, HERE / "patches/apply_mpv_fel_failclosed.py", sources / "mpv"])
    patch = HERE / "patches/libplacebo-reject-failed-fel.patch"
    run(["git", "apply", "--check", patch], cwd=sources / "libplacebo")
    run(["git", "apply", patch], cwd=sources / "libplacebo")

    ffbuild = work / "ffmpeg-build"
    ffbuild.mkdir()
    shell_prefix = run(["cygpath", "-u", prefix], capture=True).strip()
    configure = run(["cygpath", "-u", sources / "ffmpeg/configure"], capture=True).strip()
    run(["bash", configure, f"--prefix={shell_prefix}", "--enable-shared", "--disable-static",
         "--enable-gpl", "--enable-version3", "--disable-autodetect", "--enable-schannel",
         "--enable-d3d11va", "--enable-dxva2", "--enable-bsf=dovi_split", "--disable-doc",
         "--disable-debug"], cwd=ffbuild)
    run(["make", f"-j{jobs}"], cwd=ffbuild)
    run(["make", "install"], cwd=ffbuild)
    for name, options in (
        ("libplacebo", ["-Dopengl=disabled", "-Dvulkan=disabled", "-Dd3d11=enabled",
                        "-Dshaderc=enabled", "-Dglslang=disabled", "-Ddovi=enabled",
                        "-Dlibdovi=disabled", "-Ddemos=false", "-Dtests=true"]),
        ("mpv", ["-Dcplayer=true", "-Dlibmpv=true", "-Dtests=true", "-Dbuild-date=false",
                 "-Dgl=disabled", "-Dvulkan=disabled", "-Dd3d11=enabled", "-Dd3d-hwaccel=enabled",
                 "-Dmanpage-build=disabled", "-Dhtml-build=disabled", "-Dpdf-build=disabled"]),
    ):
        directory = work / (name + "-build")
        run(["meson", "setup", directory, sources / name, f"--prefix={prefix}", "--libdir=lib",
             "--buildtype=debugoptimized", "--wrap-mode=nofallback", "-Ddefault_library=shared", *options])
        run(["meson", "compile", "-C", directory, "-j", jobs])
        run(["meson", "test", "-C", directory, "--no-rebuild", "--print-errorlogs"])
        run(["meson", "install", "-C", directory])
    flags = shlex.split(run(["pkg-config", "--cflags", "--libs", "mpv", "libplacebo", "libavcodec", "libavformat"], capture=True))
    probe = work / "engine-features.exe"
    run(["cc", "-std=c11", "-DPLEZYNG_DV_REQUIRE_D3D11=1", HERE / "engine_features.c", "-o", probe, *flags])
    report = run([probe], capture=True)
    (bundle / "feature-report.json").write_text(report)
    vo = run([prefix / "bin/mpv.exe", "--no-config", "--vo=help"], capture=True)
    if "gpu-next" not in vo:
        raise ValueError("Built engine has no gpu-next renderer")
    for name in ("libmpv-2.dll", "mpv.exe", "ffmpeg.exe", "ffprobe.exe"):
        shutil.copy2(prefix / "bin" / name, bundle / name)
    shutil.copy2(prefix / "lib/libmpv.dll.a", bundle / "libmpv.dll.a")
    shutil.copytree(prefix / "include/mpv", bundle / "include/mpv")
    collect_runtime_dlls(bundle, [prefix / "bin", toolchain / "bin"],
                         Path(os.environ["SystemRoot"]) / "System32", architecture,
                         lambda image: run(["objdump", "-p", image], capture=True))
    licenses = toolchain / "share/licenses"
    if not licenses.is_dir():
        raise ValueError("Toolchain license directory is missing")
    shutil.copytree(licenses, bundle / "toolchain-licenses")
    provenance["redistribution"] = "development-only; audit toolchain runtime source obligations before release"
    source_bundle = bundle / "sources"
    source_bundle.mkdir()
    for name in ("run_windows.py", "output_target.py", "engine_bundle.py", "engine.lock.json"):
        shutil.copy2(HERE / name, bundle / name)
    for name in lock["sources"]:
        with tarfile.open(source_bundle / f"{name}.tar.xz", "w:xz") as archive:
            archive.add(sources / name, arcname=name,
                        filter=lambda entry: None if ".git" in Path(entry.name).parts else entry)
    # Keep corresponding integration sources alongside the native sources.
    for name in ("build_windows.py", "engine_bundle.py", "engine_features.c", "engine.lock.json",
                 "fel_pair_state.h", "fel_pair_state_test.c", "run_windows.py", "output_target.py"):
        shutil.copy2(HERE / name, source_bundle / name)
    shutil.copytree(HERE / "patches", source_bundle / "patches")
    provenance["architecture"] = architecture
    (bundle / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
    manifest = bundle_manifest(bundle, architecture, lock["sources"])
    (bundle / "engine-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    validate_bundle(bundle, architecture)
    artifact = work / f"plezyng-dv-windows-{architecture}.zip"
    with zipfile.ZipFile(artifact, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(bundle.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(bundle))
    artifact.with_suffix(".zip.sha256").write_text(f"{digest(artifact)}  {artifact.name}\n")
    return artifact


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work-dir", required=True, type=Path)
    parser.add_argument("--jobs", type=int, default=2)
    args = parser.parse_args()
    if not 1 <= args.jobs <= 64:
        parser.error("jobs must be between 1 and 64")
    try:
        print(build(args.work_dir.resolve(), args.jobs))
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f"Engine build failed: {error}\n")


if __name__ == "__main__":
    main()
