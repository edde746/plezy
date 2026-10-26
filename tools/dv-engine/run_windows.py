#!/usr/bin/env python3
"""Run the isolated Windows FEL renderer with an explicit HDR/SDR target."""

import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import sys

from engine_bundle import validate_bundle
from output_target import playback_arguments


def arguments(forwarded: list[str], target: str, peak_nits=None) -> list[str]:
    for argument in forwarded:
        if argument == "--":
            break
        key = argument.split("=", 1)[0]
        if key.startswith(("--hwdec", "--gpu-api", "--gpu-context", "--no-hwdec", "--no-gpu-")):
            raise ValueError("This qualification launcher requires software decode and D3D11")
    return ["--gpu-api=d3d11", "--hwdec=no", *playback_arguments(forwarded, target, peak_nits)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--target", choices=("auto", "hdr10", "sdr"), default="auto")
    parser.add_argument("--peak-nits", type=float)
    parser.add_argument("args", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    try:
        if sys.platform != "win32":
            raise ValueError("This launcher needs native Windows Python")
        root = args.engine.resolve(strict=True)
        machine = platform.machine().lower()
        architecture = {"amd64": "x86_64", "x86_64": "x86_64", "arm64": "aarch64",
                        "aarch64": "aarch64"}.get(machine)
        if architecture is None:
            raise ValueError("Unsupported Windows host architecture")
        manifest = validate_bundle(root, architecture)
        if manifest["sources"] != json.loads((root / "engine.lock.json").read_text())["sources"]:
            raise ValueError("Engine source lock mismatch")
        executable = root / "mpv.exe"
        if not executable.is_file():
            raise ValueError("Missing standalone mpv.exe")
        forwarded = args.args[1:] if args.args[:1] == ["--"] else args.args
        command = [str(executable), *arguments(forwarded, args.target, args.peak_nits)]
        env = os.environ.copy()
        env["PATH"] = str(root) + os.pathsep + env.get("PATH", "")
        # Keep relative media paths relative to the caller. The executable's
        # directory supplies the validated DLL closure.
        result = subprocess.run(command, env=env, check=False)
        raise SystemExit(result.returncode)
    except (ValueError, OSError, KeyError, TypeError) as error:
        parser.exit(1, f"Experimental engine launch failed: {error}\n")


if __name__ == "__main__":
    main()
