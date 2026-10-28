#!/usr/bin/env python3
"""Export the pinned ANVIL checkpoints to Android LiteRT model packs.

The exported input/output tensors are NHWC to match vf_anvil's frame packer.
This tool runs outside normal app builds. Optional W8A8 output is calibrated
from the same raw six-channel samples accepted by build_android_anvil_contexts.py.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import os
import shutil
import subprocess
import sys
import tempfile
import types
import urllib.request
from pathlib import Path
from typing import Any, Iterable


SOURCE_REVISION = "f701fd9b01b9fbb20822637b5d82cac626079e5f"
WEIGHTS_REVISION = "fa97e30f6aabe897bd4f6f82d971ad607f5d61fa"
WEIGHTS_REPOSITORY = "https://huggingface.co/NihilDigit/anvil/resolve/" + WEIGHTS_REVISION
MODELS = {
    "anvil-s": {
        "upstream_id": "D-unet-v3bs-nomv",
        "checkpoint": "checkpoints/D-unet-v3bs-nomv/best.pt",
        "bytes": 10_412_983,
        "sha256": "574297dcad27e601c813c3cab514a8d2b237eef30f40d9e4a6f600720808fefa",
    },
    "anvil-m": {
        "upstream_id": "D-unet-v3bm-nomv",
        "checkpoint": "checkpoints/D-unet-v3bm-nomv/best.pt",
        "bytes": 32_193_921,
        "sha256": "469851d37818e06e851409a46976fe4b26465179b94299a939dc7892bf67346a",
    },
}
SHAPES = {"720p": (720, 1280), "1080p": (1080, 1920)}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_pinned(url: str, destination: Path, expected_bytes: int, expected_sha256: str) -> Path:
    if destination.is_file() and destination.stat().st_size == expected_bytes:
        if sha256_file(destination) == expected_sha256:
            return destination
    destination.parent.mkdir(parents=True, exist_ok=True)
    partial = destination.with_suffix(destination.suffix + ".partial")
    digest = hashlib.sha256()
    count = 0
    request = urllib.request.Request(url, headers={"User-Agent": "PlezyNG-LiteRT-Exporter/1"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response, partial.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                count += len(chunk)
                if count > expected_bytes:
                    raise ValueError(f"Pinned artifact exceeds expected size: {url}")
                digest.update(chunk)
                output.write(chunk)
        if count != expected_bytes or digest.hexdigest() != expected_sha256:
            raise ValueError(f"Pinned artifact size or SHA-256 mismatch: {url}")
        partial.replace(destination)
    except Exception:
        partial.unlink(missing_ok=True)
        raise
    return destination


def verify_source(source: Path) -> None:
    revision = subprocess.check_output(
        ["git", "-C", str(source), "rev-parse", "HEAD"], text=True
    ).strip()
    if revision != SOURCE_REVISION:
        raise ValueError(f"ANVIL source must be at {SOURCE_REVISION}; found {revision}")


def load_checkpoint(model: Any, checkpoint_path: Path, torch: Any) -> None:
    checkpoint = torch.load(checkpoint_path, map_location="cpu", weights_only=True)
    state = checkpoint.get("model_state_dict", checkpoint)
    model.load_state_dict(state, strict=True)


def configure_samsung_aot(sdk_root: Path) -> Any:
    """Point LiteRT's Samsung AOT backend at the locally obtained LiteCore SDK."""
    sdk_root = sdk_root.resolve()
    host_libraries = sdk_root / "lib" / "x86_64-linux"
    required = (host_libraries / "libgraph_wrapper.so", host_libraries / "libgraphgen_api.so")
    missing = [path for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError(
            "Samsung AOT requires host LiteCore libraries under lib/x86_64-linux: "
            + ", ".join(str(path) for path in missing)
        )

    # The official Samsung provider package downloads LiteCore into Python
    # package data at install time. This exporter already receives the
    # authorized SDK as an explicit input, so point LiteRT at it directly.
    sdk_module = sys.modules.get("ai_edge_litert_sdk_samsung")
    if sdk_module is None:
        sdk_module = types.ModuleType("ai_edge_litert_sdk_samsung")
        sys.modules["ai_edge_litert_sdk_samsung"] = sdk_module
    sdk_module.path_to_sdk_libs = lambda: host_libraries
    os.environ["EXYNOS_AI_LITECORE_ROOT"] = str(sdk_root)

    from ai_edge_litert.aot.vendors.samsung import target as samsung_target

    return samsung_target


def export_samsung_aot(
    model: Any,
    sample: Any,
    litert_torch: Any,
    samsung_target: Any,
    model_name: str,
    resolution: str,
    soc_model: str,
    work_dir: Path,
    output_dir: Path,
) -> dict[str, Any]:
    target = samsung_target.Target(samsung_target.SocModel(soc_model))
    result = litert_torch.experimental_add_compilation_backend(target).convert(
        model,
        (sample,),
    )
    print(f"Samsung {soc_model} compile report for {model_name}/{resolution}:")
    print(result.compilation_report())

    export_name = f"{model_name}-{resolution}"
    filename = f"{model_name}-{resolution}-samsung-{soc_model}.tflite"
    destination = output_dir / filename
    with tempfile.TemporaryDirectory(
        prefix=f"plezy-samsung-aot-{model_name}-{resolution}-",
        dir=work_dir,
    ) as temporary_directory:
        export_dir = Path(temporary_directory)
        result.export(str(export_dir), model_name=export_name)
        compiled_path = export_dir / f"{export_name}_Samsung_{soc_model}.tflite"
        if not compiled_path.is_file() or compiled_path.stat().st_size == 0:
            outputs = sorted(path.name for path in export_dir.glob("*.tflite"))
            raise RuntimeError(
                f"LiteRT did not export a Samsung {soc_model} model for {model_name}/{resolution}; "
                f"found: {outputs}"
            )
        shutil.copyfile(compiled_path, destination)
    height, width = SHAPES[resolution]
    return {
        "file": filename,
        "bytes": destination.stat().st_size,
        "sha256": sha256_file(destination),
        "input_layout": "NHWC",
        "input_shape": [1, height, width, 6],
        "output_layout": "NHWC",
        "output_shape": [1, height, width, 3],
        "output_semantics": "residual_to_add_to_pair_blend",
        "execution": "aot",
        "soc_model": soc_model,
        "backend": "samsung",
    }


def configure_google_tensor_aot() -> tuple[Any, Any]:
    """Load LiteRT's Google Tensor AOT compiler after enabling its backend."""
    # LiteRT hides the experimental Google Tensor backend unless this is set
    # before importing the AOT package. The compiler payload itself is
    # installed from Google's Tensor SDK Beta package by the operator.
    os.environ["GOOGLE_TENSOR_BACKEND_ENABLED"] = "1"
    try:
        from ai_edge_litert.aot import aot_compile as aot_module
        from ai_edge_litert.aot.vendors.google_tensor import target as google_tensor_target
    except (ImportError, OSError) as error:
        raise RuntimeError(
            "Install scripts/motion/requirements-android-litert-google-tensor-aot.txt "
            "with the Google Tensor SDK Beta compiler archive configured to enable Tensor AOT export."
        ) from error

    compile_model = getattr(aot_module, "aot_compile", aot_module)
    return compile_model, google_tensor_target


def export_google_tensor_aot(
    input_model: Path,
    aot_compile: Any,
    google_tensor_target: Any,
    model_name: str,
    resolution: str,
    soc_model: str,
    work_dir: Path,
    output_dir: Path,
) -> dict[str, Any]:
    """Compile a fixed-shape float LiteRT graph for a Google Tensor TPU."""
    soc_enum = getattr(google_tensor_target.SocModel, soc_model.upper())
    target = google_tensor_target.Target(soc_enum)
    compiler_flags: dict[str, Any] = {"google_tensor_truncation_type": "half"}
    if soc_model == "Tensor_G6":
        # Google's Tensor SDK FAQ recommends this for non-G5 devices.
        compiler_flags["google_tensor_sharding_intensity"] = "maximum"

    export_name = f"{model_name}-{resolution}"
    filename = f"{export_name}-google-tensor-{soc_model.lower().replace('_', '-')}.tflite"
    destination = output_dir / filename
    with tempfile.TemporaryDirectory(
        prefix=f"plezy-google-tensor-aot-{model_name}-{resolution}-{soc_model.lower()}-",
        dir=work_dir,
    ) as temporary_directory:
        export_dir = Path(temporary_directory)
        compilation = aot_compile(
            str(input_model),
            output_dir=str(export_dir),
            target=[target],
            keep_going=False,
            **compiler_flags,
        )
        if hasattr(compilation, "compilation_report"):
            print(f"Google Tensor {soc_model} compile report for {model_name}/{resolution}:")
            print(compilation.compilation_report())
        suffix = f"_Google_Tensor_{soc_model.removeprefix('Tensor_')}.tflite"
        compiled_models = sorted(export_dir.rglob(f"*{suffix}"))
        if len(compiled_models) != 1 or compiled_models[0].stat().st_size == 0:
            outputs = sorted(path.name for path in export_dir.rglob("*.tflite"))
            raise RuntimeError(
                f"LiteRT did not export exactly one Google Tensor {soc_model} model "
                f"for {model_name}/{resolution}; found: {outputs}"
            )
        shutil.copyfile(compiled_models[0], destination)

    height, width = SHAPES[resolution]
    return {
        "file": filename,
        "bytes": destination.stat().st_size,
        "sha256": sha256_file(destination),
        "input_layout": "NHWC",
        "input_shape": [1, height, width, 6],
        "output_layout": "NHWC",
        "output_shape": [1, height, width, 3],
        "output_semantics": "residual_to_add_to_pair_blend",
        "precision": "float16-truncated",
        "execution": "aot",
        "soc_model": soc_model,
        "backend": "google-tensor",
    }


def read_calibration_samples(
    root: Path, resolution: str, np: Any, signature_input_name: str
) -> list[dict[str, Any]]:
    height, width = SHAPES[resolution]
    list_path = root / resolution / "input_list.txt"
    if not list_path.is_file():
        raise FileNotFoundError(f"Missing calibration sample list: {list_path}")
    paths: list[Path] = []
    for line in list_path.read_text(encoding="utf-8").splitlines():
        value = line.strip()
        if not value or value.startswith("#"):
            continue
        path = Path(value)
        if not path.is_absolute():
            path = list_path.parent / path
        paths.append(path.resolve())
    if not paths:
        raise ValueError(f"Calibration list is empty: {list_path}")
    # LiteRT Quantizer counts samples before it runs calibration, so keep this
    # iterable replayable instead of passing a one-shot generator.
    samples: list[dict[str, Any]] = []
    for path in paths:
        expected_bytes = 6 * height * width * 4
        if not path.is_file() or path.stat().st_size != expected_bytes:
            raise ValueError(f"Expected a {expected_bytes}-byte six-channel calibration tensor: {path}")
        nchw = np.fromfile(path, dtype=np.float32).reshape(1, 6, height, width)
        samples.append({signature_input_name: np.transpose(nchw, (0, 2, 3, 1)).copy()})
    return samples


def signature_input_name(model_path: Path) -> str:
    """Return the single input name exposed by LiteRT's exported signature."""
    from ai_edge_litert.interpreter import Interpreter

    interpreter = Interpreter(model_path=str(model_path), num_threads=1)
    signatures = interpreter.get_signature_list()
    signature = signatures.get("serving_default")
    input_names = signature.get("inputs", []) if signature is not None else []
    if len(signatures) != 1 or len(input_names) != 1:
        raise ValueError(
            f"Expected one input in the serving_default LiteRT signature; found {signatures}"
        )
    return input_names[0]


def verify_model_interface(model_path: Path, resolution: str) -> None:
    """Fail export if the serialized tensors do not match the Android ABI."""
    from ai_edge_litert.interpreter import Interpreter

    height, width = SHAPES[resolution]
    interpreter = Interpreter(model_path=str(model_path), num_threads=1)
    inputs = interpreter.get_input_details()
    outputs = interpreter.get_output_details()
    expected_input = [1, height, width, 6]
    expected_output = [1, height, width, 3]
    if len(inputs) != 1 or inputs[0]["shape"].tolist() != expected_input:
        actual = [detail["shape"].tolist() for detail in inputs]
        raise ValueError(
            f"LiteRT input ABI mismatch for {model_path}: expected {expected_input}; got {actual}"
        )
    if len(outputs) != 1 or outputs[0]["shape"].tolist() != expected_output:
        actual = [detail["shape"].tolist() for detail in outputs]
        raise ValueError(
            f"LiteRT output ABI mismatch for {model_path}: expected {expected_output}; got {actual}"
        )


def read_calibration_provenance(root: Path | None) -> dict[str, Any] | None:
    if root is None:
        return None
    metadata_path = root / "metadata.json"
    if not metadata_path.is_file():
        return None
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    if metadata.get("format") != 1:
        raise ValueError(f"Unsupported calibration metadata format: {metadata_path}")
    tensor = metadata.get("tensor", {})
    if tensor.get("dtype") != "float32" or tensor.get("layout") != "NCHW":
        raise ValueError(f"Calibration metadata does not describe float32 NCHW inputs: {metadata_path}")
    return {
        "metadata_sha256": sha256_file(metadata_path),
        "metadata": metadata,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--anvil-source", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--resolutions", nargs="+", choices=SHAPES, default=["720p", "1080p"])
    parser.add_argument("--models", nargs="+", choices=MODELS, default=list(MODELS))
    parser.add_argument(
        "--calibration-root",
        type=Path,
        help="Enable static W8A8 export using raw NCHW ANVIL samples listed per resolution.",
    )
    parser.add_argument(
        "--samsung-aot",
        action="store_true",
        help="Also compile a Samsung Exynos AOT variant (currently E9965).",
    )
    parser.add_argument(
        "--samsung-litecore-root",
        type=Path,
        help="Authorized LiteCore SDK root containing lib/x86_64-linux and lib/arm64-v8a.",
    )
    parser.add_argument("--samsung-soc", choices=["E9965"], default="E9965")
    parser.add_argument(
        "--google-tensor-aot",
        action="store_true",
        help="Also compile target-specific Google Tensor AOT variants (requires the Google Tensor SDK Beta compiler).",
    )
    parser.add_argument(
        "--google-tensor-socs",
        nargs="+",
        choices=["Tensor_G5", "Tensor_G6"],
        default=["Tensor_G5", "Tensor_G6"],
        help="Google Tensor targets to compile when --google-tensor-aot is enabled.",
    )
    args = parser.parse_args()

    if args.google_tensor_aot:
        # Set this before loading litert-torch or any LiteRT AOT modules so the
        # Google Tensor provider is registered consistently in this process.
        os.environ["GOOGLE_TENSOR_BACKEND_ENABLED"] = "1"

    if args.samsung_aot and args.samsung_litecore_root is None:
        parser.error("--samsung-aot requires --samsung-litecore-root")
    if args.samsung_litecore_root is not None:
        android_libraries = args.samsung_litecore_root / "lib" / "arm64-v8a"
        required_android_libraries = (
            android_libraries / "libgraph_wrapper.so",
            android_libraries / "libgraphgen_api.so",
        )
        missing = [path for path in required_android_libraries if not path.is_file()]
        if missing:
            parser.error(
                "Samsung LiteCore SDK is missing Android runtime libraries: "
                + ", ".join(str(path) for path in missing)
            )
    if args.google_tensor_socs != ["Tensor_G5", "Tensor_G6"] and not args.google_tensor_aot:
        parser.error("--google-tensor-socs requires --google-tensor-aot")

    verify_source(args.anvil_source)
    try:
        import numpy as np
        import torch
        import litert_torch
    except ImportError as error:
        raise SystemExit(
            "Exporter dependencies are missing. Use Linux with Python 3.11, "
            "torch, numpy, and scripts/motion/requirements-android-litert-models.txt."
        ) from error
    if torch.version.cuda is not None or getattr(torch.version, "hip", None) is not None:
        raise SystemExit(
            "Android LiteRT model export must use the pinned CPU-only PyTorch wheel; "
            "workstation GPUs are not used for model conversion."
        )
    if hasattr(torch, "set_default_device"):
        torch.set_default_device("cpu")

    if args.calibration_root:
        try:
            from ai_edge_quantizer import quantizer, recipe
        except ImportError as error:
            raise SystemExit(
                "Install scripts/motion/requirements-android-litert-models.txt to create calibrated W8A8 packs."
            ) from error

    calibration_provenance = read_calibration_provenance(args.calibration_root)

    samsung_target = None
    if args.samsung_aot:
        try:
            samsung_target = configure_samsung_aot(args.samsung_litecore_root)
        except ImportError as error:
            raise SystemExit(
                "Install scripts/motion/requirements-android-litert-samsung-aot.txt "
                "to enable Samsung LiteRT AOT export."
            ) from error

    google_tensor_aot_compile = None
    google_tensor_target = None
    if args.google_tensor_aot:
        try:
            google_tensor_aot_compile, google_tensor_target = configure_google_tensor_aot()
        except RuntimeError as error:
            raise SystemExit(str(error)) from error

    sys.path.insert(0, str(args.anvil_source / "anvil_exp01"))
    from models.conv_vfi import build_model

    args.work_dir.mkdir(parents=True, exist_ok=True)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, Any] = {
        "format": 1,
        "license": "MIT",
        "source": {
            "repository": "https://github.com/NihilDigit/anvil",
            "revision": SOURCE_REVISION,
        },
        "weights": {
            "repository": "https://huggingface.co/NihilDigit/anvil",
            "revision": WEIGHTS_REVISION,
        },
        "converter": {
            "name": "litert-torch",
            "version": getattr(litert_torch, "__version__", "unknown"),
            "torch_version": torch.__version__,
            "quantizer_version": (
                importlib.metadata.version("ai-edge-quantizer") if args.calibration_root else None
            ),
        },
        "calibration": calibration_provenance,
        "models": {},
    }

    for model_name in args.models:
        spec = MODELS[model_name]
        checkpoint = download_pinned(
            f"{WEIGHTS_REPOSITORY}/{spec['checkpoint']}",
            args.work_dir / Path(spec["checkpoint"]).name,
            spec["bytes"],
            spec["sha256"],
        )
        output_variants: dict[str, Any] = {}
        for resolution in args.resolutions:
            height, width = SHAPES[resolution]
            model = build_model(spec["upstream_id"])
            load_checkpoint(model, checkpoint, torch)
            model.eval()
            if hasattr(model, "fuse_for_deploy"):
                model.fuse_for_deploy()

            # The mpv filter already packs two source frames as NHWC float32.
            # The ANVIL checkpoint returns an NCHW residual. The Android frame
            # packer and LiteRT C ABI both use NHWC, so convert the model output
            # as well as its input before export.
            model_nhwc = litert_torch.to_channel_last_io(
                model, args=[0], outputs=[0]
            ).eval()
            sample = torch.zeros((1, height, width, 6), dtype=torch.float32)
            with torch.no_grad():
                edge_model = litert_torch.convert(model_nhwc, (sample,))

            name = f"{model_name}-{resolution}.tflite"
            float_path = args.output_dir / name
            edge_model.export(str(float_path))
            verify_model_interface(float_path, resolution)
            float_record = {
                "file": name,
                "bytes": float_path.stat().st_size,
                "sha256": sha256_file(float_path),
                "input_layout": "NHWC",
                "input_shape": [1, height, width, 6],
                "output_layout": "NHWC",
                "output_shape": [1, height, width, 3],
                "output_semantics": "residual_to_add_to_pair_blend",
                "precision": "float32",
            }
            output_variants[resolution] = {"gpu": float_record}

            if samsung_target is not None:
                output_variants[resolution]["samsung"] = export_samsung_aot(
                    model_nhwc,
                    sample,
                    litert_torch,
                    samsung_target,
                    model_name,
                    resolution,
                    args.samsung_soc,
                    args.work_dir,
                    args.output_dir,
                )

            if google_tensor_aot_compile is not None and google_tensor_target is not None:
                for soc_model in args.google_tensor_socs:
                    provider_key = f"google-tensor-{soc_model.lower().replace('_', '-')}"
                    output_variants[resolution][provider_key] = export_google_tensor_aot(
                        float_path,
                        google_tensor_aot_compile,
                        google_tensor_target,
                        model_name,
                        resolution,
                        soc_model,
                        args.work_dir,
                        args.output_dir,
                    )

            if args.calibration_root:
                calibration_input_name = signature_input_name(float_path)
                int8_path = args.output_dir / f"{model_name}-{resolution}-w8a8.tflite"
                calibrator = quantizer.Quantizer(str(float_path))
                calibrator.load_quantization_recipe(recipe.static_wi8_ai8())
                calibration = calibrator.calibrate(
                    {
                        "serving_default": read_calibration_samples(
                            args.calibration_root, resolution, np, calibration_input_name
                        )
                    }
                )
                calibrator.quantize(calibration_result=calibration).export_model(
                    str(int8_path), overwrite=True
                )
                verify_model_interface(int8_path, resolution)
                output_variants[resolution]["npu"] = {
                    "file": int8_path.name,
                    "bytes": int8_path.stat().st_size,
                    "sha256": sha256_file(int8_path),
                    "input_layout": "NHWC",
                    "input_shape": [1, height, width, 6],
                    "output_layout": "NHWC",
                    "output_shape": [1, height, width, 3],
                    "output_semantics": "residual_to_add_to_pair_blend",
                    "precision": "int8-w8a8",
                    "execution": "jit",
                    "quantization_recipe": "static_wi8_ai8",
                    "calibration_metadata_sha256": (
                        calibration_provenance["metadata_sha256"]
                        if calibration_provenance is not None
                        else None
                    ),
                }

        manifest["models"][model_name] = {
            "checkpoint": {
                "path": spec["checkpoint"],
                "bytes": spec["bytes"],
                "sha256": spec["sha256"],
            },
            "variants": output_variants,
        }

    manifest_path = args.output_dir / "manifest.json"
    temporary = manifest_path.with_suffix(".json.partial")
    temporary.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(manifest_path)
    print(f"Wrote {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
