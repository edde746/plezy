#!/usr/bin/env python3
"""Build a pinned ARM64 FEL engine AAR and optionally an installable APK.

The output is a local experimental app build. It does not replace or publish
the project's normal mpv engine. Source revisions are taken from engine.lock.json.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile


HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
MPV_BUILD_URL = "https://github.com/edde746/mpv-build.git"
MPV_BUILD_COMMIT = "582f6d6e748a87a1536bf5cdad0af97b75725ffb"


def run(command, *, cwd: Path, env: dict[str, str], timeout: int = 21600,
        capture: bool = False) -> str:
    command = list(map(str, command))
    print("+ " + shlex.join(command), flush=True)
    result = subprocess.run(command, cwd=cwd, env=env, check=True, text=True,
                            stdout=subprocess.PIPE if capture else None,
                            stderr=subprocess.STDOUT if capture else None,
                            timeout=timeout)
    if capture and result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n", flush=True)
    return result.stdout or ""


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def checkout(destination: Path, url: str, commit: str, *, submodules: bool = False,
             env: dict[str, str]) -> None:
    destination.mkdir(parents=True)
    run(["git", "init", destination], cwd=destination.parent, env=env)
    run(["git", "remote", "add", "origin", url], cwd=destination, env=env)
    run(["git", "-c", "protocol.file.allow=never", "fetch", "--depth=1", "origin", commit],
        cwd=destination, env=env)
    run(["git", "checkout", "--detach", "FETCH_HEAD"], cwd=destination, env=env)
    actual = run(["git", "rev-parse", "HEAD"], cwd=destination, env=env, capture=True).strip()
    if actual != commit:
        raise ValueError(f"Expected {url} at {commit}, got {actual}")
    if submodules:
        run(["git", "-c", "protocol.file.allow=never", "submodule", "update", "--init",
             "--recursive", "--depth=1"], cwd=destination, env=env)
        status = run(["git", "submodule", "status", "--recursive"], cwd=destination, env=env,
                     capture=True)
        if any(line[:1] != " " for line in status.splitlines()):
            raise ValueError(f"Unresolved submodule in {destination.name}")


def replace_once(path: Path, before: str, after: str) -> None:
    text = path.read_text()
    count = text.count(before)
    if count != 1:
        raise ValueError(f"Expected one pinned build-script anchor in {path.name}, found {count}")
    path.write_text(text.replace(before, after, 1))


def configure_mp_build(source: Path) -> None:
    android = source / "platforms/android"
    depinfo = android / "include/depinfo.sh"
    replace_once(
        depinfo,
        'components="openssl dav1d libdovi ffmpeg freetype fribidi harfbuzz libunibreak libass lua libplacebo mpv"',
        'components="openssl dav1d freetype fribidi harfbuzz libunibreak libass lua"',
    )
    replace_once(depinfo, 'dep_ffmpeg="openssl dav1d libdovi"', 'dep_ffmpeg="openssl dav1d"')
    replace_once(depinfo, 'args_libplacebo="-Dvulkan=disabled -Ddemos=false"',
                 'args_libplacebo="-Dvulkan=disabled -Ddemos=false -Dopengl=enabled '
                 '-Dgl-proc-addr=enabled -Ddovi=enabled -Dlibdovi=disabled -Dtests=false"')
    replace_once(
        depinfo,
        'args_mpv="--default-library shared -Diconv=disabled -Dlua=enabled -Dlibmpv=true '
        '-Dcplayer=false -Dmanpage-build=disabled -Dbuild-date=false"',
        'args_mpv="--default-library shared -Diconv=disabled -Dlua=enabled -Dlibmpv=true '
        '-Dcplayer=false -Dmanpage-build=disabled -Dbuild-date=false -Dgl=enabled -Degl=enabled '
        '-Degl-android=enabled -Dplain-gl=enabled -Dvulkan=disabled -Daudiotrack=enabled '
        '-Daaudio=disabled -Dopensles=enabled -Dalsa=disabled -Dcoreaudio=disabled '
        '-Dpipewire=disabled -Dpulse=disabled -Dwasapi=disabled"',
    )

    ffmpeg = android / "scripts/ffmpeg.sh"
    replace_once(ffmpeg, '\t--extra-libs=-ldovi \\\n', '')
    replace_once(ffmpeg,
                 '\t--enable-{jni,mediacodec,openssl,libdav1d,libdovi} --disable-vulkan \\\n',
                 '\t--enable-{jni,mediacodec,openssl,libdav1d} --disable-vulkan \\\n')
    replace_once(ffmpeg, '\t--enable-filter=bwdif,decimate,fieldmatch,loudnorm,aresample \\\n',
                 '\t--enable-filter=bwdif,decimate,fieldmatch,loudnorm,aresample \\\n'
                 '\t--enable-bsf=dovi_split \\\n')

    download = android / "download.sh"
    replace_once(download,
                 'tar -xzf "$archive" --strip-components=1 -C "deps/$component"',
                 'tar -xzf "$archive" --no-same-owner --strip-components=1 -C "deps/$component"')

    # Android's NDK ships EGL but not an egl.pc file. mpv's Meson build asks
    # pkg-config for EGL, so add a tiny target-side package file and include
    # the normal /usr layouts in searches (some upstream install drivers use
    # /usr even though the artifact packaging is intentionally prefix-flat).
    path_script = android / "include/path.sh"
    replace_once(
        path_script,
        'export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/lib/pkgconfig"',
        'export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/lib/pkgconfig:'
        '$PKG_CONFIG_SYSROOT_DIR/usr/lib/pkgconfig:$PKG_CONFIG_SYSROOT_DIR/usr/local/lib/pkgconfig'
        '${PLEZYNG_ANDROID_SYSTEM_PKGCONFIG_DIR:+:$PLEZYNG_ANDROID_SYSTEM_PKGCONFIG_DIR}"',
    )

    meson_script = android / "scripts/meson.sh"
    replace_once(
        meson_script,
        '\t${SED:-sed} "/^Libs:/ s|\\$| $pc_libs|" "$prefix_dir/lib/pkgconfig/$component.pc" -i',
        '\tpc_file="$prefix_dir/lib/pkgconfig/$component.pc"\n'
        '\tif [ ! -f "$pc_file" ]; then\n'
        '\t\tfor candidate in "$prefix_dir/usr/lib/pkgconfig/$component.pc" '
        '"$prefix_dir/usr/local/lib/pkgconfig/$component.pc"; do\n'
        '\t\t\tif [ -f "$candidate" ]; then pc_file=$candidate; break; fi\n'
        '\t\tdone\n'
        '\tfi\n'
        '\tif [ ! -f "$pc_file" ]; then\n'
        '\t\techo >&2 "Missing pkg-config metadata for $component under $prefix_dir"\n'
        '\t\texit 1\n'
        '\tfi\n'
        '\t${SED:-sed} "/^Libs:/ s|\\$| $pc_libs|" "$pc_file" -i',
    )


def normalize_prefix(prefix: Path) -> None:
    """Flatten any /usr or /usr/local installs into the ABI artifact prefix."""
    for nested in (prefix / "usr/local", prefix / "usr"):
        if nested.is_symlink() or not nested.exists():
            continue
        for source in nested.iterdir():
            destination = prefix / source.name
            if source.is_dir() and not source.is_symlink():
                shutil.copytree(source, destination, dirs_exist_ok=True)
            elif destination.exists():
                if source.is_file() and destination.is_file() and source.read_bytes() == destination.read_bytes():
                    continue
                raise ValueError(f"Conflicting Android prefix install: {source} and {destination}")
            else:
                shutil.copy2(source, destination, follow_symlinks=False)
        shutil.rmtree(nested)
    usr = prefix / "usr"
    local = prefix / "local"
    for link in (usr, local):
        if link.exists() and not link.is_symlink():
            raise ValueError(f"Expected a flat Android prefix, found real directory {link}")
        if not link.is_symlink():
            link.symlink_to(".")


def verify_flutter_assets(apk: Path, flutter_assets: Path) -> int:
    """Prove the APK has every merged Flutter asset with the same bytes."""
    if not flutter_assets.is_dir():
        raise ValueError(f"Gradle's merged Flutter asset directory is missing: {flutter_assets}")
    expected = {path.relative_to(flutter_assets).as_posix(): path
                for path in flutter_assets.rglob("*") if path.is_file()}
    prefix = "assets/flutter_assets/"
    with zipfile.ZipFile(apk) as archive:
        packaged = {name[len(prefix):] for name in archive.namelist()
                    if name.startswith(prefix) and not name.endswith("/")}
        missing = set(expected) - packaged
        extra = packaged - set(expected)
        if missing or extra:
            raise ValueError(
                "APK Flutter asset set differs from the merged assets: "
                f"missing={sorted(missing)[:10]}, extra={sorted(extra)[:10]}"
            )
        changed = [name for name, path in expected.items()
                   if digest(path) != hashlib.sha256(archive.read(prefix + name)).hexdigest()]
        if changed:
            raise ValueError(f"APK Flutter assets differ from merged inputs: {changed[:10]}")
    return len(expected)


def verify_fel_native_libraries(apk: Path, aar: Path, sdk: Path, abi: str) -> int:
    """Prove the APK contains the selected FEL AAR's stripped native libraries."""
    strip_tool = (sdk / "ndk/29.0.14206865/toolchains/llvm/prebuilt"
                  / f"linux-{platform.machine()}" / "bin/llvm-strip")
    if not strip_tool.is_file():
        raise ValueError(f"Android NDK llvm-strip is missing: {strip_tool}")

    with zipfile.ZipFile(aar) as engine, zipfile.ZipFile(apk) as package:
        package_names = set(package.namelist())
        packaged_abis = {
            name.split("/", 2)[1]
            for name in package_names
            if name.startswith("lib/") and name.endswith(".so")
        }
        if packaged_abis != {abi}:
            raise ValueError(
                f"FEL APK must contain only {abi}; found {sorted(packaged_abis)}"
            )

        native_entries = sorted(
            name for name in engine.namelist()
            if name.startswith(f"jni/{abi}/") and name.endswith(".so")
        )
        if not native_entries:
            raise ValueError(f"FEL AAR contains no native libraries for {abi}")
        missing = [
            f"lib/{abi}/{Path(name).name}"
            for name in native_entries
            if f"lib/{abi}/{Path(name).name}" not in package_names
        ]
        if missing:
            raise ValueError(f"FEL APK is missing AAR native libraries: {missing}")

        with tempfile.TemporaryDirectory(prefix="plezyng-fel-apk-check-") as temp_dir:
            for entry in native_entries:
                apk_entry = f"lib/{abi}/{Path(entry).name}"
                candidate = Path(temp_dir) / Path(entry).name
                candidate.write_bytes(engine.read(entry))
                result = subprocess.run(
                    [str(strip_tool), "--strip-unneeded", str(candidate)],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                )
                if result.returncode != 0:
                    raise ValueError(
                        f"Failed to prepare {entry} for APK comparison: {result.stdout}"
                    )
                if digest(candidate) != hashlib.sha256(package.read(apk_entry)).hexdigest():
                    raise ValueError(
                        f"APK native library differs from the selected FEL AAR: {apk_entry}"
                    )
                candidate.unlink()
    return len(native_entries)


def build(args: argparse.Namespace) -> dict:
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "aarch64"):
        raise ValueError("The Android native builder currently requires Linux x86_64 or ARM64")
    work = args.work_dir.resolve()
    if work.exists() and any(work.iterdir()):
        raise ValueError("Use a new empty --work-dir so stale native libraries cannot enter the AAR")
    work.mkdir(parents=True, exist_ok=True)
    if not shutil.which("git"):
        raise ValueError("git is required")
    sdk = args.android_sdk.resolve(strict=True)
    if not (sdk / "ndk").is_dir():
        raise ValueError(f"Android SDK has no NDK directory: {sdk}")

    env = os.environ.copy()
    meson_bin = str(args.meson_bin.resolve()) if args.meson_bin else ""
    if meson_bin:
        env["PATH"] = meson_bin + os.pathsep + env.get("PATH", "")
    env.update({
        "MPV_ANDROID_SDK": str(sdk),
        "ANDROID_HOME": str(sdk),
        "ANDROID_SDK_ROOT": str(sdk),
        "GIT_TERMINAL_PROMPT": "0",
        "LC_ALL": "C.UTF-8",
    })
    cmake_candidates = [path for path in (sdk / "cmake").glob("*/bin")
                        if (path / "cmake").is_file()]
    if cmake_candidates:
        def cmake_version(path: Path) -> tuple[int, ...]:
            try:
                return tuple(int(part) for part in path.parent.name.split("."))
            except ValueError:
                return (0,)
        cmake_bin = max(cmake_candidates, key=cmake_version)
        env["PATH"] = str(cmake_bin) + os.pathsep + env.get("PATH", "")
    if not shutil.which("meson", path=env["PATH"]) or not shutil.which("ninja", path=env["PATH"]):
        raise ValueError("Meson and Ninja must be installed or provided with --meson-bin")

    report: dict = {"schema_version": 1, "engine_id": "plezyng-dv-fel-v1",
                    "abi": "arm64-v8a", "qualification": "build-only; device playback pending"}
    try:
        source = work / "mpv-build"
        checkout(source, MPV_BUILD_URL, MPV_BUILD_COMMIT, env=env)
        configure_mp_build(source)

        lock = json.loads((HERE / "engine.lock.json").read_text())
        native_sources = source / "platforms/android/deps"
        for name in ("ffmpeg", "libplacebo", "mpv"):
            spec = lock["sources"][name]
            checkout(native_sources / name, spec["url"], spec["commit"],
                     submodules=(name == "libplacebo"), env=env)
            report[f"{name}_commit"] = spec["commit"]

        run([sys.executable, HERE / "patches/apply_mpv_fel_failclosed.py",
             native_sources / "mpv"], cwd=REPO_ROOT, env=env)
        for patch_name in ("libplacebo-reject-failed-fel.patch",
                           "libplacebo-android-gles-buffer-limits.patch"):
            patch = HERE / "patches" / patch_name
            run(["git", "apply", "--check", patch], cwd=native_sources / "libplacebo", env=env)
            run(["git", "apply", patch], cwd=native_sources / "libplacebo", env=env)
            report.setdefault("patches", {})[patch_name] = digest(patch)

        android = source / "platforms/android"
        system_pkgconfig = work / "android-system-pkgconfig"
        system_pkgconfig.mkdir(parents=True, exist_ok=True)
        (system_pkgconfig / "egl.pc").write_text(
            "prefix=/usr\nexec_prefix=${prefix}\nlibdir=${exec_prefix}/lib\n"
            "includedir=${prefix}/include\nName: EGL\n"
            "Description: Android NDK EGL system library\nVersion: 1.4.0\n"
            "Libs: -lEGL\nCflags:\n"
        )
        env["PLEZYNG_ANDROID_SYSTEM_PKGCONFIG_DIR"] = str(system_pkgconfig)
        run(["bash", "./download.sh"], cwd=android, env=env)
        env["cores"] = str(args.jobs)
        env["PATH"] = str(sdk / "ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64/bin") + os.pathsep + env["PATH"]
        run(["bash", "./build.sh", "--arch", "arm64", "libmpv-android"], cwd=android, env=env)
        prefix = android / "prefix/arm64-v8a"
        normalize_prefix(prefix)
        run(["bash", "./package.sh", "--arch", "arm64"], cwd=android, env=env)

        tarball = source / "dist/release/libmpv-android-arm64-v8a.tar.gz"
        if not tarball.is_file():
            raise ValueError("mpv-build did not emit the expected ARM64 engine tarball")
        report["native_tarball_sha256"] = digest(tarball)
        report["ffmpeg_commit"] = lock["sources"]["ffmpeg"]["commit"]

        aar = args.base_aar.resolve(strict=True)
        output = args.output.resolve()
        run([sys.executable, HERE / "package_android_fel.py",
             "--mpv-build-source", source,
             "--native-prefix", prefix,
             "--base-aar", aar,
             "--android-sdk", sdk,
             "--abi", "arm64-v8a",
             "--jobs", str(args.jobs),
             "--output", output], cwd=REPO_ROOT, env=env)
        report["aar"] = str(output)
        report["aar_sha256"] = digest(output)

        if args.assemble_apk:
            flutter = args.flutter_sdk.resolve(strict=True)
            if not (flutter / "bin/flutter").is_file():
                raise ValueError(f"Flutter SDK is missing bin/flutter: {flutter}")
            apk_env = env.copy()
            apk_env["PATH"] = os.pathsep.join((str(flutter / "bin"),
                                               str(sdk / "platform-tools"),
                                               apk_env["PATH"]))
            app = REPO_ROOT / "android"
            apk_build_started_ns = time.time_ns()
            run(["./gradlew", ":app:assembleDebug",
                 f"-PplezyngFelAar={output}",
                 f"-PplezyngFelAarSha256={digest(output)}",
                 "-PplezyngFelAbis=arm64-v8a",
                 # Restrict all Android plugins' native builds to the same
                 # ARM64 ABI as the FEL AAR, and serialize Gradle work so this
                 # phone-test package also builds in modest-memory workspaces.
                 "-Ptarget-platform=android-arm64",
                 "-Pandroid.injected.build.abi=arm64-v8a",
                 "--no-daemon", "--max-workers=1",
                 "-Dorg.gradle.jvmargs=-Xmx1g -XX:MaxMetaspaceSize=768m "
                 "-XX:ReservedCodeCacheSize=128m -XX:ActiveProcessorCount=2",
                 "-Pkotlin.compiler.execution.strategy=in-process",
                 "--console=plain"], cwd=app, env=apk_env)
            apk_candidates = [
                REPO_ROOT / "build/app/outputs/flutter-apk/app-debug.apk",
                REPO_ROOT / "build/app/outputs/apk/debug/app-debug.apk",
            ]
            fresh_apks = [
                candidate for candidate in apk_candidates
                if candidate.is_file() and candidate.stat().st_mtime_ns >= apk_build_started_ns
            ]
            if not fresh_apks:
                raise ValueError("Gradle completed without producing a fresh debug APK")
            apk = max(fresh_apks, key=lambda candidate: candidate.stat().st_mtime_ns)
            merged_assets = REPO_ROOT / "build/app/intermediates/assets/debug/mergeDebugAssets/flutter_assets"
            report["flutter_asset_count"] = verify_flutter_assets(apk, merged_assets)
            report["fel_native_library_count"] = verify_fel_native_libraries(
                apk, output, sdk, "arm64-v8a"
            )
            report["apk"] = str(apk)
            report["apk_sha256"] = digest(apk)
            apk.with_suffix(apk.suffix + ".sha256").write_text(
                f"{report['apk_sha256']}  {apk.name}\n"
            )
        return report
    finally:
        report_path = args.output.resolve().with_suffix(".build.json")
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--android-sdk", type=Path,
                        default=Path(os.environ.get("ANDROID_HOME", os.environ.get("ANDROID_SDK_ROOT", "."))))
    parser.add_argument("--base-aar", type=Path, required=True,
                        help="baseline mpv-android AAR supplying the matching Java API")
    parser.add_argument("--output", type=Path, required=True, help="experimental FEL AAR output path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--meson-bin", type=Path, help="directory containing the Meson and Ninja executables")
    parser.add_argument("--assemble-apk", action="store_true",
                        help="also compile a local arm64-v8a Plezy debug APK")
    parser.add_argument("--flutter-sdk", type=Path,
                        default=Path(os.environ.get("FLUTTER_ROOT", ".")))
    args = parser.parse_args()
    if not 1 <= args.jobs <= 64:
        parser.error("--jobs must be between 1 and 64")
    try:
        report = build(args)
    except (OSError, ValueError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
        parser.exit(1, f"Android FEL build failed: {error}\n")
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
