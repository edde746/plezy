#!/usr/bin/env python3
"""Provision every Android module's pinned SDK tools on private JIT runners."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]


def proxy_parts(env: dict[str, str]) -> tuple[str, int]:
    raw = env.get("HTTPS_PROXY") or env.get("https_proxy") or ""
    if not raw or any(character.isspace() for character in raw):
        raise ValueError("The private JIT HTTPS proxy is required and must not contain whitespace")
    parsed = urlsplit(raw if "://" in raw else f"http://{raw}")
    if (parsed.scheme != "http" or not parsed.hostname or not parsed.port
            or parsed.username or parsed.password or parsed.path not in ("", "/")
            or parsed.query or parsed.fragment
            or not re.fullmatch(r"[A-Za-z0-9.:-]+", parsed.hostname)):
        raise ValueError("Expected an unauthenticated HTTP proxy with an explicit host and port")
    return parsed.hostname, parsed.port


def configure_proxy(env: dict[str, str]) -> None:
    host, port = proxy_parts(env)
    options = (f"-Dhttp.proxyHost={host} -Dhttp.proxyPort={port} "
               f"-Dhttps.proxyHost={host} -Dhttps.proxyPort={port} "
               "-Dhttp.nonProxyHosts=localhost|127.*|[::1]")
    lines = []
    for name in ("JAVA_TOOL_OPTIONS", "GRADLE_OPTS"):
        previous = env.get(name, "").strip()
        if "\n" in previous or "\r" in previous:
            raise ValueError(f"{name} must fit on one environment-file line")
        lines.append(f"{name}={previous + ' ' if previous else ''}{options}\n")
    with Path(env["GITHUB_ENV"]).open("a", encoding="utf-8") as output:
        output.writelines(lines)


def platform_package(api: int) -> str:
    # Google publishes API 37 and later with a minor version
    # (platforms;android-37.0); there is no plain platforms;android-37.
    return f"platforms;android-{api}.0" if api >= 37 else f"platforms;android-{api}"


def required_packages(root: Path) -> list[str]:
    packages = {"platform-tools"}
    sources = list((root / "android").glob("*.gradle*"))
    sources += list((root / "android").glob("*/*.gradle*"))
    for path in sources:
        if not path.is_file() or not (path.name.endswith(".gradle") or path.name.endswith(".gradle.kts")):
            continue
        source = path.read_text(encoding="utf-8")
        for value in re.findall(r"\bcompileSdk\s*(?:=\s*)?(\d+)\b", source):
            packages.add(platform_package(int(value)))
        for field, package in (("buildToolsVersion", "build-tools"), ("ndkVersion", "ndk")):
            pattern = rf"\b{field}\s*(?:=\s*)?['\"]([0-9.]+)['\"]"
            for value in re.findall(pattern, source):
                packages.add(f"{package};{value}")
        # These project files declare externalNativeBuild CMake versions as
        # literals. Do not confuse Android/Kotlin plugin versions with CMake.
        for block in re.findall(r"\bcmake\s*\{([^{}]*)\}", source):
            for value in re.findall(r"\bversion\s*(?:=\s*)?['\"]([0-9.]+)['\"]", block):
                packages.add(f"cmake;{value}")
    for prefix in ("platforms;", "build-tools;", "ndk;", "cmake;"):
        if not any(package.startswith(prefix) for package in packages):
            raise ValueError(f"No literal Android {prefix} pin found; review the Gradle declarations")
    return sorted(packages)


def verify_packages(sdk: Path, packages: list[str]) -> None:
    for package in packages:
        parts = package.split(";")
        directory = sdk.joinpath(*parts)
        kind = parts[0]
        if kind == "platform-tools":
            required = (directory / "adb",)
        elif kind == "platforms":
            required = (directory / "android.jar",)
        elif kind == "build-tools":
            required = (directory / "aapt2", directory / "apksigner")
        elif kind == "cmake":
            required = (directory / "bin/cmake", directory / "bin/ninja")
        else:
            required = (directory / "ndk-build", directory / "source.properties",
                        directory / "toolchains/llvm/prebuilt/linux-x86_64/bin/clang")
        for path in required:
            if not path.is_file() or (path.suffix not in (".jar", ".properties") and not os.access(path, os.X_OK)):
                raise ValueError(f"Incomplete Android toolchain package {package}: missing {path.name}")
        if kind == "ndk":
            properties = (directory / "source.properties").read_text()
            if not re.search(rf"^Pkg\.Revision\s*=\s*{re.escape(parts[1])}\s*$", properties, re.MULTILINE):
                raise ValueError(f"NDK metadata does not match its declared version: {package}")


def install(root: Path, env: dict[str, str]) -> None:
    host, port = proxy_parts(env)
    sdk_value = env.get("ANDROID_SDK_ROOT") or env.get("ANDROID_HOME")
    if not sdk_value:
        raise ValueError("setup-android must provide ANDROID_SDK_ROOT or ANDROID_HOME")
    sdk = Path(sdk_value)
    managers = sorted(sdk.glob("cmdline-tools/*/bin/sdkmanager"))
    if not managers:
        raise ValueError("setup-android did not install sdkmanager")
    manager = sdk / "cmdline-tools/latest/bin/sdkmanager"
    if manager not in managers:
        manager = managers[-1]
    args = [str(manager), f"--sdk_root={sdk}", "--proxy=http",
            f"--proxy_host={host}", f"--proxy_port={port}", "--channel=3"]
    packages = required_packages(root)
    print("Provisioning pinned Android packages: " + ", ".join(packages), flush=True)
    subprocess.run(args + ["--licenses"], input="y\n" * 100, text=True,
                   stdout=subprocess.DEVNULL, check=True)
    subprocess.run(args + ["--install", *packages], check=True)
    verify_packages(sdk, packages)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("proxy", "install", "list"))
    args = parser.parse_args()
    if args.action == "proxy":
        configure_proxy(dict(os.environ))
    elif args.action == "install":
        install(ROOT, dict(os.environ))
    else:
        print("\n".join(required_packages(ROOT)))


if __name__ == "__main__":
    main()
