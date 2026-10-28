#!/usr/bin/env python3
"""Build pinned, app-owned Steam transport archives for the active Xcode SDK.

VideoToolbox/Core Audio are compiled by Xcode; this script builds portable C/C++
and the pinned native Metal Pyrowave library. Vulkan is disabled on Apple.
"""
from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
PLATFORMS = {
    "macosx": ("Darwin", "MACOSX_DEPLOYMENT_TARGET", "14.0"),
    "iphoneos": ("iOS", "IPHONEOS_DEPLOYMENT_TARGET", "15.5"),
    "iphonesimulator": ("iOS", "IPHONEOS_DEPLOYMENT_TARGET", "15.5"),
    "appletvos": ("tvOS", "TVOS_DEPLOYMENT_TARGET", "15.0"),
    "appletvsimulator": ("tvOS", "TVOS_DEPLOYMENT_TARGET", "15.0"),
}


def run(*args: str) -> None:
    subprocess.run(args, cwd=ROOT, check=True)


def build() -> None:
    platform = os.environ.get("PLATFORM_NAME", "")
    if platform not in PLATFORMS:
        raise SystemExit("Steam receiver requires an Apple Xcode SDK")
    system, deployment_key, default_deployment = PLATFORMS[platform]
    deployment = os.environ.get(deployment_key, default_deployment)
    if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", deployment):
        raise SystemExit("Invalid Apple deployment target")
    architectures = os.environ.get("ARCHS", "").split()
    if not architectures or not set(architectures) <= {"arm64", "x86_64"} or len(set(architectures)) != len(architectures):
        raise SystemExit("Unsupported or missing Apple architecture")
    if platform in {"iphoneos", "appletvos"} and architectures != ["arm64"]:
        raise SystemExit("Apple device builds require arm64")
    derived = os.environ.get("DERIVED_FILE_DIR")
    if not derived or not Path(derived).is_absolute():
        raise SystemExit("Xcode DERIVED_FILE_DIR is required")
    cmake = shutil.which("cmake")
    if not cmake:
        # Xcode GUI does not inherit the usual Homebrew shell path.
        cmake = next((p for p in ("/opt/homebrew/bin/cmake", "/usr/local/bin/cmake") if Path(p).is_file()), None)
    if not cmake:
        raise SystemExit("Install CMake 3.22+ on the Apple builder")
    run(sys.executable, str(ROOT / "scripts/games/prepare_steam.py"))
    sdk = subprocess.check_output(["xcrun", "--sdk", platform, "--show-sdk-path"], text=True).strip()
    destination = Path(derived) / "plezy-steam"
    destination.mkdir(parents=True, exist_ok=True)
    archives = []
    for arch in architectures:
        directory = destination / f"{platform}-{arch}"
        run(cmake, "-S", str(ROOT / "native/games/steam"), "-B", str(directory),
            "-DCMAKE_BUILD_TYPE=Release", "-DPLEZY_STEAM_PYROWAVE=OFF", "-DPLEZY_STEAM_METAL=ON", "-DPLEZY_STEAM_TESTS=OFF",
            "-DPLEZY_STEAM_GSTREAMER=OFF", f"-DCMAKE_SYSTEM_NAME={system}",
            f"-DCMAKE_SYSTEM_PROCESSOR={arch}", f"-DCMAKE_OSX_ARCHITECTURES={arch}",
            f"-DCMAKE_OSX_SYSROOT={sdk}", f"-DCMAKE_OSX_DEPLOYMENT_TARGET={deployment}")
        run(cmake, "--build", str(directory), "--target", "plezy_steam_runtime", "--parallel", "2")
        archive = directory / "libplezy_steam_apple.a"
        libraries = [directory / name for name in (
            "libplezy_steam_runtime.a", "libplezy_ihs.a", "libplezy_protobuf_c.a", "libplezy_pyrowave_metal.a",
            "opus/libopus.a", "mbedtls/library/libmbedcrypto.a")]
        if not all(p.is_file() for p in libraries):
            raise SystemExit("Pinned Steam build did not produce every required archive")
        run("xcrun", "libtool", "-static", "-o", str(archive), *(str(p) for p in libraries))
        archives.append(archive)
    temporary = destination / "libplezy_steam.pending.a"
    run("xcrun", "lipo", "-create", *(str(p) for p in archives), "-output", str(temporary))
    temporary.replace(destination / "libplezy_steam.a")


if __name__ == "__main__":
    build()
