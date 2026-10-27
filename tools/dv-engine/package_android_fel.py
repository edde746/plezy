#!/usr/bin/env python3
"""Build and validate a local ARM64 experimental Android FEL AAR.

The native mpv/FFmpeg tree must already be installed in an Android mpv-build
prefix. The script compiles Plezy's JNI glue against that exact tree, reuses the
matching mpv-android Java API from a baseline AAR, and embeds the matching
FFmpeg headers plus engine identity. It never modifies the checked-out source
or publishes the artifact.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile


HERE = Path(__file__).resolve().parent
ENGINE_ID = "plezyng-dv-fel-v1"
MPV_BUILD_COMMIT = "582f6d6e748a87a1536bf5cdad0af97b75725ffb"
FFMPEG_COMMIT = "46f23be8b1976ed4c8ec85584daabcf0e57a7b9e"
PLACEBO_COMMIT = "275f7dea27924cdd34ab2e6c20e448b6bc4fab65"
MPV_COMMIT = "16563d120f3260cdc0beb1b07f199818fc32dd8c"
ANDROID_ABIS = {
    "arm64-v8a": ("arm64", "aarch64-linux-android", "AArch64"),
    "armeabi-v7a": ("armv7l", "arm-linux-androideabi", "ARM"),
    "x86": ("x86", "i686-linux-android", "Intel 80386"),
    "x86_64": ("x86_64", "x86_64-linux-android", "Advanced Micro Devices X86-64"),
}
ENGINE_LIBRARIES = (
    "libmpv.so",
    "libavcodec.so",
    "libavdevice.so",
    "libavfilter.so",
    "libavformat.so",
    "libavutil.so",
    "libswresample.so",
    "libswscale.so",
)
HEADER_DIRS = (
    "libavcodec", "libavdevice", "libavfilter", "libavformat",
    "libavutil", "libswresample", "libswscale",
)
REQUIRED_HEADERS = (
    "libavcodec/avcodec.h",
    "libavcodec/mediacodec.h",
    "libavcodec/jni.h",
    "libavutil/avconfig.h",
    "libavutil/channel_layout.h",
    "libswresample/swresample.h",
)


def run(args: list[object], *, cwd: Path | None = None) -> None:
    command = list(map(str, args))
    print("+ " + " ".join(command), flush=True)
    subprocess.run(command, cwd=cwd, check=True)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_zip_entries(archive: zipfile.ZipFile):
    for entry in archive.infolist():
        name = PurePosixPath(entry.filename)
        if name.is_absolute() or ".." in name.parts:
            raise ValueError(f"Unsafe archive path: {entry.filename}")
        yield entry


def ndk_version(build_source: Path) -> str:
    path = build_source / "toolchain/android.txt"
    match = re.search(r"^ndk=(\d+(?:\.\d+){2,})$", path.read_text(), re.M)
    if not match:
        raise ValueError(f"No pinned NDK version in {path}")
    return match.group(1)


def copy_header_tree(include: Path, staging: Path) -> None:
    for directory in HEADER_DIRS:
        source = include / directory
        if not source.is_dir():
            raise ValueError(f"FFmpeg development tree is missing {directory}/")
        shutil.copytree(source, staging / directory, dirs_exist_ok=True)
    missing = [name for name in REQUIRED_HEADERS if not (staging / name).is_file()]
    if missing:
        raise ValueError(f"FFmpeg headers are incomplete: {', '.join(missing)}")


def native_machine(readelf: str, path: Path, expected: str) -> None:
    result = subprocess.run([readelf, "-h", str(path)], check=True, text=True,
                            stdout=subprocess.PIPE).stdout
    if expected not in result:
        raise ValueError(f"{path.name} has the wrong ELF machine; expected {expected}")


def build(args: argparse.Namespace) -> tuple[Path, str]:
    build_source = args.mpv_build_source.resolve(strict=True)
    native_prefix = args.native_prefix.resolve(strict=True)
    base_aar = args.base_aar.resolve(strict=True)
    sdk = args.android_sdk.resolve(strict=True)
    abi = args.abi
    _, triple, machine = ANDROID_ABIS[abi]

    head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=build_source,
                          check=True, text=True, stdout=subprocess.PIPE).stdout.strip()
    if head != MPV_BUILD_COMMIT:
        raise ValueError(f"mpv-build must be pinned to {MPV_BUILD_COMMIT}, got {head}")

    platform_source = build_source / "platforms/android/lib/src/main/cpp"
    patch = HERE / "patches/android-libplayer-fel.patch"
    native_lib_dir = native_prefix / "lib"
    native_include_dir = native_prefix / "include"
    missing_libs = [name for name in ENGINE_LIBRARIES if not (native_lib_dir / name).is_file()]
    if missing_libs:
        raise ValueError(f"Android FEL engine prefix is missing: {', '.join(missing_libs)}")

    ndk = sdk / "ndk" / ndk_version(build_source)
    toolchain = ndk / "build/cmake/android.toolchain.cmake"
    host_tag = "linux-x86_64" if sys.platform.startswith("linux") else "darwin-arm64"
    libcxx = ndk / "toolchains/llvm/prebuilt" / host_tag / "sysroot/usr/lib" / triple / "libc++_shared.so"
    if not toolchain.is_file() or not libcxx.is_file():
        raise ValueError(f"Pinned Android NDK {ndk} is incomplete for {abi}")
    for tool in ("cmake", "ninja"):
        if not shutil.which(tool):
            raise ValueError(f"Required build tool is not on PATH: {tool}")
    readelf = str(ndk / "toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf")
    if not Path(readelf).is_file():
        raise ValueError(f"Missing NDK llvm-readelf: {readelf}")

    with tempfile.TemporaryDirectory(prefix="plezyng-android-fel-") as temp_name:
        temp = Path(temp_name)
        patched_source = temp / "mpv-build"
        shutil.copytree(build_source, patched_source, ignore=shutil.ignore_patterns(".git", "build", "dist", "prefix"))
        run(["git", "apply", "--check", patch], cwd=patched_source)
        run(["git", "apply", patch], cwd=patched_source)

        staged_root = temp / "native"
        staged_abi = staged_root / abi
        shutil.copytree(native_lib_dir, staged_abi / "lib")
        shutil.copytree(native_include_dir, staged_abi / "include")
        shutil.copy2(libcxx, staged_abi / "lib/libc++_shared.so")

        cmake_source = patched_source / "platforms/android/lib/src/main/cpp"
        cmake_build = temp / "jni-build"
        run([
            "cmake", "-S", cmake_source, "-B", cmake_build,
            "-G", "Ninja",
            f"-DCMAKE_TOOLCHAIN_FILE={toolchain}",
            f"-DANDROID_ABI={abi}", "-DANDROID_PLATFORM=android-25",
            f"-DMPV_NATIVE_ROOT={staged_root}",
            "-DCMAKE_BUILD_TYPE=Release",
            "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384 -Wl,--build-id=sha1",
        ])
        run(["cmake", "--build", cmake_build, "--parallel", str(args.jobs)])
        player = cmake_build / "libplayer.so"
        if not player.is_file():
            raise ValueError("JNI build did not produce libplayer.so")
        shutil.copy2(player, staged_abi / "lib/libplayer.so")

        for name in ENGINE_LIBRARIES + ("libplayer.so", "libc++_shared.so"):
            native_machine(readelf, staged_abi / "lib" / name, machine)

        aar_classes: dict[str, bytes] = {}
        with zipfile.ZipFile(base_aar) as archive:
            for entry in safe_zip_entries(archive):
                name = entry.filename
                if name.startswith("jni/") or name.startswith("META-INF/plezyng-dv"):
                    continue
                if entry.is_dir():
                    continue
                aar_classes[name] = archive.read(entry)
        for required in ("AndroidManifest.xml", "classes.jar"):
            if required not in aar_classes:
                raise ValueError(f"Baseline AAR has no {required}")

        header_stage = temp / "ffmpeg-headers"
        copy_header_tree(native_include_dir, header_stage)
        metadata = {
            "schema_version": 1,
            "engine_id": ENGINE_ID,
            "ffmpeg_commit": FFMPEG_COMMIT,
            "libplacebo_commit": PLACEBO_COMMIT,
            "mpv_commit": MPV_COMMIT,
            "mpv_build_commit": MPV_BUILD_COMMIT,
            "ffmpeg_headers": "META-INF/plezyng-dv/ffmpeg-headers/",
            "abis": [abi],
            "native_library_sha256": {
                name: sha256(staged_abi / "lib" / name)
                for name in ENGINE_LIBRARIES + ("libplayer.so", "libc++_shared.so")
            },
            "qualification": {
                "fel_decode_and_render": "compiled; requires device playback verification",
                "physical_dolby_vision_output": "not_claimed",
            },
        }
        metadata_bytes = (json.dumps(metadata, indent=2, sort_keys=True) + "\n").encode()

        output = args.output.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        temp_output = output.with_suffix(output.suffix + ".tmp")
        with zipfile.ZipFile(temp_output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for name, content in sorted(aar_classes.items()):
                archive.writestr(name, content)
            for name in ENGINE_LIBRARIES + ("libplayer.so", "libc++_shared.so"):
                archive.write(staged_abi / "lib" / name, f"jni/{abi}/{name}")
            archive.writestr("META-INF/plezyng-dv-engine.json", metadata_bytes)
            for path in sorted(header_stage.rglob("*")):
                if path.is_file():
                    relative = path.relative_to(header_stage).as_posix()
                    archive.write(path, f"META-INF/plezyng-dv/ffmpeg-headers/{relative}")
        temp_output.replace(output)
        digest = sha256(output)
        output.with_suffix(output.suffix + ".sha256").write_text(f"{digest}  {output.name}\n")

        with zipfile.ZipFile(output) as archive:
            names = set(archive.namelist())
            required = {"AndroidManifest.xml", "classes.jar", "META-INF/plezyng-dv-engine.json"}
            required.update(f"jni/{abi}/{name}" for name in ENGINE_LIBRARIES + ("libplayer.so", "libc++_shared.so"))
            required.update(f"META-INF/plezyng-dv/ffmpeg-headers/{name}" for name in REQUIRED_HEADERS)
            if not required.issubset(names):
                raise ValueError(f"Packaged AAR is missing {sorted(required - names)}")
            packaged_metadata = json.loads(archive.read("META-INF/plezyng-dv-engine.json"))
            if packaged_metadata.get("engine_id") != ENGINE_ID or packaged_metadata.get("abis") != [abi]:
                raise ValueError("Packaged AAR engine identity validation failed")
        return output, digest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mpv-build-source", type=Path, required=True,
                        help="clean checkout of the pinned edde746/mpv-build source")
    parser.add_argument("--native-prefix", type=Path, required=True,
                        help="installed prefix/<abi> containing lib/ and include/")
    parser.add_argument("--base-aar", type=Path, required=True,
                        help="matching baseline mpv-android AAR for classes.jar/manifest")
    parser.add_argument("--android-sdk", type=Path,
                        default=Path(os.environ.get("ANDROID_HOME", os.environ.get("ANDROID_SDK_ROOT", "."))))
    parser.add_argument("--abi", choices=tuple(ANDROID_ABIS), default="arm64-v8a")
    parser.add_argument("--jobs", type=int, default=max(1, min(4, os.cpu_count() or 1)))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if not 1 <= args.jobs <= 64:
        parser.error("--jobs must be between 1 and 64")
    try:
        output, digest = build(args)
    except (OSError, ValueError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        parser.exit(1, f"Android FEL AAR build failed: {error}\n")
    print(f"Built {output}\nSHA-256: {digest}")


if __name__ == "__main__":
    main()
