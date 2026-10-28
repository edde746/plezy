#!/usr/bin/env python3
"""Prepare Android ANVIL HTP contexts for supported Qualcomm mobile targets.

Requires a licensed Qualcomm QAIRT SDK, ANVIL ONNX exports, and representative
calibration inputs. It produces the context tree consumed by
android/app/build.gradle.kts via PLEZY_ANVIL_CONTEXT_ROOT:

  sm7475/anvil-s-720p/context.serialized.bin
  sm7475/anvil-m-720p/context.serialized.bin
  sm8550/anvil-s-1080p/context.serialized.bin
  ...a SoC-specific pair for each entry in TARGETS...

Conversion and context generation follow Qualcomm's QNN/HTP toolchain and the
MIT-licensed ANVIL reproduction scripts. This script does not download QAIRT,
weights, or calibration media and never runs during ordinary app builds.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


TARGETS = {
    "sm7325": {"soc": "SM7325", "soc_id": 35, "dsp_arch": "v68", "resolution": "720p"},
    "sm8350": {"soc": "SM8350", "soc_id": 30, "dsp_arch": "v68", "resolution": "720p"},
    "sm8350p": {"soc": "SM8350P", "soc_id": 30, "dsp_arch": "v68", "resolution": "720p"},
    "sm7450": {"soc": "SM7450", "soc_id": 41, "dsp_arch": "v69", "resolution": "720p"},
    "sm7475": {"soc": "SM7475", "soc_id": 41, "dsp_arch": "v69", "resolution": "720p"},
    "sm8450": {"soc": "SM8450", "soc_id": 36, "dsp_arch": "v69", "resolution": "720p"},
    "sm8475": {"soc": "SM8475", "soc_id": 42, "dsp_arch": "v69", "resolution": "720p"},
    "sm8550": {"soc": "SM8550", "soc_id": 43, "dsp_arch": "v73", "resolution": "1080p"},
    "sm8650": {"soc": "SM8650", "soc_id": 57, "dsp_arch": "v75", "resolution": "1080p"},
    "sm8750": {"soc": "SM8750", "soc_id": 69, "dsp_arch": "v79", "resolution": "1080p"},
    "sm8850": {"soc": "SM8850", "soc_id": 87, "dsp_arch": "v81", "resolution": "1080p"},
}
MODELS = {
    "anvil-s": "D_unet_v3bs_nomv",
    "anvil-m": "D_unet_v3bm_nomv",
}
SHAPES = {"720p": (720, 1280), "1080p": (1080, 1920)}
ANVIL_SOURCE_REVISION = "f701fd9b01b9fbb20822637b5d82cac626079e5f"
ANVIL_MODEL_REVISION = "fa97e30f6aabe897bd4f6f82d971ad607f5d61fa"
PINNED_1080P_ONNX = {
    "D_unet_v3bs_nomv_1080p.onnx": {
        "bytes": 3_441_349,
        "sha256": "65e871aed25b331e3a3747cf9019942121a94af71997476f5804a24b768cd0d8",
    },
    "D_unet_v3bm_nomv_1080p.onnx": {
        "bytes": 10_677_524,
        "sha256": "261f95a17c865b45e4d7e2be3439d91b47315bef96e32d46f3cfc785941774fd",
    },
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run(command: list[str], *, env: dict[str, str], cwd: Path) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, check=True, cwd=cwd, env=env)


def calibration_list(calibration_root: Path, resolution: str, work_dir: Path) -> Path:
    source_dir = calibration_root / resolution
    resize_from_1080p = resolution == "720p" and not (source_dir / "input_list.txt").is_file()
    if resize_from_1080p:
        source_dir = calibration_root / "1080p"
    listing = source_dir / "input_list.txt"
    if not listing.is_file():
        raise FileNotFoundError(f"Missing representative calibration list: {listing}")
    inputs: list[Path] = []
    resized_dir = work_dir / "resized_720p"
    if resize_from_1080p:
        resized_dir.mkdir(parents=True, exist_ok=True)
        try:
            import cv2
            import numpy as np
        except ImportError as error:
            raise RuntimeError("NumPy and OpenCV are required to resize 1080p calibration samples to 720p") from error

    for raw_line in listing.read_text(encoding="utf-8").splitlines():
        entry = raw_line.strip()
        if not entry or entry.startswith("#"):
            continue
        raw = Path(entry)
        if not raw.is_absolute():
            raw = source_dir / raw
        raw = raw.resolve()
        if not raw.is_file():
            raise FileNotFoundError(f"Calibration sample listed but missing: {raw}")
        expected = 6 * SHAPES[resolution][0] * SHAPES[resolution][1] * 4
        if resize_from_1080p:
            frame = np.fromfile(raw, dtype=np.float32)
            expected_1080 = 6 * 1080 * 1920
            if frame.size * 4 != expected_1080:
                raise ValueError(f"Expected a six-channel 1080p ANVIL sample ({expected_1080} bytes): {raw}")
            frame = frame.reshape(6, 1080, 1920)
            resized = np.stack(
                [cv2.resize(channel, (1280, 720), interpolation=cv2.INTER_AREA) for channel in frame]
            ).astype(np.float32, copy=False)
            converted = resized_dir / raw.name
            resized.tofile(converted)
            raw = converted
        elif raw.stat().st_size != expected:
            raise ValueError(
                f"Expected a six-channel {resolution} ANVIL sample ({expected} bytes): {raw}"
            )
        inputs.append(raw)
    if not inputs:
        raise ValueError(f"Calibration list contains no samples: {listing}")
    result = work_dir / "calibration_input_list.txt"
    result.write_text("\n".join(map(str, inputs)) + "\n", encoding="utf-8")
    return result


def compile_context(
    *,
    qairt: Path,
    onnx: Path,
    calibration: Path,
    output: Path,
    model_id: str,
    target_id: str,
) -> dict[str, Any]:
    target = TARGETS[target_id]
    resolution = target["resolution"]
    height, width = SHAPES[resolution]
    graph_name = f"{model_id.replace('-', '_')}_{resolution}_{target_id}"
    work = output / "working" / target_id / model_id
    work.mkdir(parents=True, exist_ok=True)

    bin_dir = qairt / "bin" / "x86_64-linux-clang"
    lib_dir = qairt / "lib" / "x86_64-linux-clang"
    converter = bin_dir / "qnn-onnx-converter"
    library_generator = bin_dir / "qnn-model-lib-generator"
    context_generator = bin_dir / "qnn-context-binary-generator"
    backend = lib_dir / "libQnnHtp.so"
    required = (converter, library_generator, context_generator, backend)
    missing = [path for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError("QAIRT SDK is missing: " + ", ".join(map(str, missing)))

    backend_config = work / "htp_backend_config.json"
    backend_config.write_text(
        json.dumps(
            {
                "graphs": [{"graph_names": [graph_name], "vtcm_mb": 0, "O": 3}],
                "devices": [
                    {
                        "dsp_arch": target["dsp_arch"],
                        "soc_id": target["soc_id"],
                        "pd_session": "unsigned",
                        "device_id": 0,
                    }
                ],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    converter_config = work / "htp_converter_config.json"
    converter_config.write_text(
        json.dumps(
            {
                "backend_extensions": {
                    "shared_library_path": "libQnnHtpNetRunExtensions.so",
                    "config_file_path": str(backend_config),
                }
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    env = os.environ.copy()
    qairt_python = str(qairt / "lib" / "python")
    qairt_libs = str(lib_dir)
    env["PYTHONPATH"] = os.pathsep.join(filter(None, (qairt_python, env.get("PYTHONPATH", ""))))
    env["LD_LIBRARY_PATH"] = os.pathsep.join(filter(None, (qairt_libs, env.get("LD_LIBRARY_PATH", ""))))
    env["PATH"] = os.pathsep.join((str(bin_dir), env.get("PATH", "")))
    env["TMPDIR"] = str(work)

    model_output = work / graph_name
    run(
        [
            str(converter),
            "--input_network",
            str(onnx.resolve()),
            "--output_path",
            str(model_output),
            "--input_list",
            str(calibration),
            "--input_dim",
            "input",
            f"1,6,{height},{width}",
            "--input_layout",
            "input",
            "NCHW",
            "--act_bitwidth",
            "8",
            "--weights_bitwidth",
            "8",
            "--bias_bitwidth",
            "32",
            "--act_quantizer_calibration",
            "percentile",
            "--percentile_calibration_value",
            "99.99",
            "--act_quantizer_schema",
            "asymmetric",
            "--param_quantizer_schema",
            "symmetric",
            "--use_per_channel_quantization",
        ],
        env=env,
        cwd=work,
    )
    model_cpp = model_output.with_suffix(".cpp")
    model_bin = model_output.with_suffix(".bin")
    if not model_cpp.is_file() and model_output.is_file():
        model_output.rename(model_cpp)
    if not model_cpp.is_file() or not model_bin.is_file():
        raise RuntimeError(f"QNN converter did not produce both model files for {graph_name}")

    run(
        [
            str(library_generator),
            "-c",
            str(model_cpp),
            "-b",
            str(model_bin),
            "-o",
            str(work),
            "-t",
            "x86_64-linux-clang",
        ],
        env=env,
        cwd=work,
    )
    model_library = work / "x86_64-linux-clang" / f"lib{graph_name}.so"
    if not model_library.is_file():
        raise RuntimeError(f"QNN model library was not produced: {model_library}")

    target_dir = output / target_id / f"{model_id}-{resolution}"
    target_dir.mkdir(parents=True, exist_ok=True)
    run(
        [
            str(context_generator),
            "--model",
            str(model_library),
            "--backend",
            str(backend),
            "--binary_file",
            "context.serialized",
            "--output_dir",
            str(target_dir),
            "--config_file",
            str(converter_config),
        ],
        env=env,
        cwd=work,
    )
    context = target_dir / "context.serialized.bin"
    if not context.is_file() or context.stat().st_size == 0:
        raise RuntimeError(f"QNN context was not produced: {context}")

    return {
        "target": target_id,
        "soc_model": target["soc"],
        "dsp_arch": target["dsp_arch"],
        "soc_id": target["soc_id"],
        "model": model_id,
        "resolution": resolution,
        "input_shape": [1, 6, height, width],
        "onnx_sha256": sha256_file(onnx),
        "context_path": str(context.relative_to(output)),
        "context_bytes": context.stat().st_size,
        "context_sha256": sha256_file(context),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qairt-root", type=Path, default=os.environ.get("QAIRT_SDK_ROOT"), required=False)
    parser.add_argument("--onnx-dir", type=Path, required=True)
    parser.add_argument("--calibration-root", type=Path, required=True, help="Contains 720p/ and 1080p/ calibration lists and raw samples.")
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    if args.qairt_root is None:
        parser.error("--qairt-root or QAIRT_SDK_ROOT is required")
    qairt = args.qairt_root.resolve()
    onnx_dir = args.onnx_dir.resolve()
    calibration_root = args.calibration_root.resolve()
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)

    prepared: list[dict[str, Any]] = []
    calibration_by_resolution: dict[str, Path] = {}
    for target_id, target in TARGETS.items():
        resolution = target["resolution"]
        calibration = calibration_by_resolution.get(resolution)
        if calibration is None:
            calibration_work = output / "working" / "calibration" / resolution
            calibration_work.mkdir(parents=True, exist_ok=True)
            calibration = calibration_list(calibration_root, resolution, calibration_work)
            calibration_by_resolution[resolution] = calibration
        for model_id, onnx_stem in MODELS.items():
            onnx = onnx_dir / f"{onnx_stem}_{resolution}.onnx"
            if not onnx.is_file():
                raise FileNotFoundError(
                    f"Missing {onnx}. Export ANVIL-S/M at both required resolutions from the pinned model source first."
                )
            pin = PINNED_1080P_ONNX.get(onnx.name)
            if pin is not None and (
                onnx.stat().st_size != pin["bytes"] or sha256_file(onnx) != pin["sha256"]
            ):
                raise ValueError(f"Pinned ANVIL ONNX artifact does not match its size and SHA-256: {onnx}")
            print(f"\nPreparing {target_id} {model_id} {resolution}", flush=True)
            prepared.append(
                compile_context(
                    qairt=qairt,
                    onnx=onnx,
                    calibration=calibration,
                    output=output,
                    model_id=model_id,
                    target_id=target_id,
                )
            )

    manifest = {
        "schema_version": 1,
        "runtime": "Qualcomm QNN HTP",
        "quantization": "W8A8",
        "anvil_source_revision": ANVIL_SOURCE_REVISION,
        "anvil_model_revision": ANVIL_MODEL_REVISION,
        "contexts": prepared,
    }
    manifest_path = output / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"\nPrepared {len(prepared)} ANVIL contexts. Manifest: {manifest_path}", flush=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
