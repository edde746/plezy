#!/usr/bin/env python3
"""Extract only the runtime files needed from the pinned AMD ORT wheel."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import shutil
import zipfile


WHEEL_FILES = {
    "onnxruntime/capi/libonnxruntime.so.1.23.2": "libonnxruntime.so.1.23.2",
    "onnxruntime/capi/libonnxruntime_providers_migraphx.so": "libonnxruntime_providers_migraphx.so",
    "onnxruntime/capi/libonnxruntime_providers_shared.so": "libonnxruntime_providers_shared.so",
    "onnxruntime/LICENSE": "ONNXRuntime-License.txt",
    "onnxruntime/ThirdPartyNotices.txt": "ONNXRuntime-ThirdPartyNotices.txt",
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wheel", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("sha256")
    args = parser.parse_args()

    digest = hashlib.sha256()
    with args.wheel.open("rb") as wheel_file:
        for chunk in iter(lambda: wheel_file.read(1024 * 1024), b""):
            digest.update(chunk)
    if digest.hexdigest() != args.sha256:
        raise SystemExit(f"AMD ONNX Runtime wheel SHA-256 mismatch: {digest.hexdigest()}")

    args.destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.wheel) as wheel:
        available = set(wheel.namelist())
        missing = sorted(set(WHEEL_FILES) - available)
        if missing:
            raise SystemExit(f"AMD ONNX Runtime wheel is missing required files: {missing!r}")

        for archive_path, output_name in WHEEL_FILES.items():
            destination = args.destination / output_name
            with wheel.open(archive_path) as source, destination.open("wb") as output:
                shutil.copyfileobj(source, output)


if __name__ == "__main__":
    main()
