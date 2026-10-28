#!/usr/bin/env python3
"""Compare synthesized frames from calibrated LiteRT W8A8 and float32 models on CPU.

This is an offline model-fidelity check. It does not claim that an Android NPU
supports the graph or that a provider selected it; device/provider qualification
must still be reported by Plezy's LiteRT CompiledModel runtime.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from collections import Counter
from pathlib import Path
from typing import Any


def load_interpreter(model_path: Path, interpreter_type: Any) -> Any:
    interpreter = interpreter_type(model_path=str(model_path), num_threads=1)
    interpreter.allocate_tensors()
    return interpreter


def verify_record(model_root: Path, record: dict[str, Any]) -> Path:
    path = model_root / record["file"]
    if not path.is_file() or path.stat().st_size != record["bytes"]:
        raise ValueError(f"Model size does not match manifest: {path}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != record["sha256"]:
        raise ValueError(f"Model SHA-256 does not match manifest: {path}")
    return path


def tensor_to_float(value: Any, detail: dict[str, Any]) -> Any:
    import numpy as np

    array = np.asarray(value)
    if array.dtype in (np.int8, np.uint8):
        quantization = detail.get("quantization_parameters", {})
        scales = np.asarray(quantization.get("scales", []), dtype=np.float32)
        zero_points = np.asarray(quantization.get("zero_points", []), dtype=np.float32)
        if scales.size != 1 or zero_points.size != 1 or scales[0] <= 0:
            raise ValueError(f"Expected per-tensor quantization for {detail.get('name')}")
        array = (array.astype(np.float32) - zero_points[0]) * scales[0]
    return array.astype(np.float32, copy=False)


def invoke(interpreter: Any, value: Any) -> tuple[Any, str]:
    import numpy as np

    input_detail = interpreter.get_input_details()[0]
    input_dtype = input_detail["dtype"]
    if input_dtype == np.float32:
        tensor = value.astype(np.float32, copy=False)
    elif input_dtype in (np.int8, np.uint8):
        quantization = input_detail.get("quantization_parameters", {})
        scales = np.asarray(quantization.get("scales", []), dtype=np.float32)
        zero_points = np.asarray(quantization.get("zero_points", []), dtype=np.float32)
        if scales.size != 1 or zero_points.size != 1 or scales[0] <= 0:
            raise ValueError(f"Expected per-tensor input quantization for {input_detail['name']}")
        low, high = np.iinfo(input_dtype).min, np.iinfo(input_dtype).max
        tensor = np.clip(np.rint(value / scales[0] + zero_points[0]), low, high).astype(input_dtype)
    else:
        raise ValueError(f"Unsupported input dtype {input_dtype} in {input_detail['name']}")

    interpreter.set_tensor(input_detail["index"], tensor)
    interpreter.invoke()
    output_detail = interpreter.get_output_details()[0]
    result = interpreter.get_tensor(output_detail["index"])
    return tensor_to_float(result, output_detail), str(input_dtype)


def calibration_inputs(root: Path, resolution: str, np: Any):
    height, width = {"720p": (720, 1280), "1080p": (1080, 1920)}[resolution]
    listing = root / resolution / "input_list.txt"
    for raw_line in listing.read_text(encoding="utf-8").splitlines():
        entry = raw_line.strip()
        if not entry or entry.startswith("#"):
            continue
        path = Path(entry)
        if not path.is_absolute():
            path = listing.parent / path
        expected = 6 * height * width * 4
        if not path.is_file() or path.stat().st_size != expected:
            raise ValueError(f"Invalid {resolution} calibration sample: {path}")
        nchw = np.fromfile(path, dtype=np.float32).reshape(1, 6, height, width)
        yield path.name, np.transpose(nchw, (0, 2, 3, 1)).copy()


def validate_pair(float_path: Path, quantized_path: Path, inputs: list[tuple[str, Any]], interpreter_type: Any) -> dict[str, Any]:
    import numpy as np

    float_interpreter = load_interpreter(float_path, interpreter_type)
    quant_interpreter = load_interpreter(quantized_path, interpreter_type)
    float_input = float_interpreter.get_input_details()[0]
    quant_input = quant_interpreter.get_input_details()[0]
    float_output = float_interpreter.get_output_details()[0]
    quant_output = quant_interpreter.get_output_details()[0]
    if list(float_input["shape"]) != list(quant_input["shape"]):
        raise ValueError("Float and W8A8 input shapes differ")
    if list(float_output["shape"]) != list(quant_output["shape"]):
        raise ValueError("Float and W8A8 output shapes differ")

    squared_error = 0.0
    absolute_error = 0.0
    value_count = 0
    max_absolute_error = 0.0
    per_sample: list[dict[str, Any]] = []
    for sample_name, value in inputs:
        reference, _ = invoke(float_interpreter, value)
        quantized, _ = invoke(quant_interpreter, value)
        if reference.shape != quantized.shape:
            raise ValueError(f"Float and W8A8 output shapes differ on {sample_name}")
        if value.ndim != 4 or value.shape[-1] != 6:
            raise ValueError(f"Expected an NHWC six-channel pair on {sample_name}")
        if reference.shape != (*value.shape[:3], 3):
            raise ValueError(
                f"Expected an NHWC three-channel residual output on {sample_name}; "
                f"got {reference.shape} for input {value.shape}"
            )

        # ANVIL predicts a residual. The playback filter adds it to the blend
        # of the two prealigned source frames before clamping to display range.
        blend = (value[..., :3] + value[..., 3:]) * 0.5
        reference_frame = np.clip(blend + reference, 0.0, 1.0)
        quantized_frame = np.clip(blend + quantized, 0.0, 1.0)
        delta = quantized_frame - reference_frame
        sample_squared = float(np.sum(np.square(delta), dtype=np.float64))
        sample_count = int(delta.size)
        sample_rmse = math.sqrt(sample_squared / sample_count)
        sample_mae = float(np.mean(np.abs(delta), dtype=np.float64))
        sample_max = float(np.max(np.abs(delta)))
        per_sample.append(
            {
                "sample": sample_name,
                "rmse": sample_rmse,
                "mae": sample_mae,
                "max_absolute_error": sample_max,
                "psnr_db": 120.0 if sample_rmse == 0 else 20.0 * math.log10(1.0 / sample_rmse),
            }
        )
        squared_error += sample_squared
        absolute_error += float(np.sum(np.abs(delta), dtype=np.float64))
        value_count += sample_count
        max_absolute_error = max(max_absolute_error, sample_max)

    rmse = math.sqrt(squared_error / value_count)
    details = quant_interpreter.get_tensor_details()
    dtype_counts = Counter(str(detail["dtype"]) for detail in details)
    list_ops = getattr(quant_interpreter, "_get_ops_details", None)
    if list_ops is None:
        list_ops = getattr(quant_interpreter, "get_ops_details", None)
    operator_counts = Counter(detail.get("op_name", "unknown") for detail in (list_ops() if list_ops else []))
    return {
        "float_model": float_path.name,
        "w8a8_model": quantized_path.name,
        "input_dtype": str(quant_input["dtype"]),
        "output_dtype": str(quant_output["dtype"]),
        "input_shape": [int(dimension) for dimension in quant_input["shape"]],
        "output_shape": [int(dimension) for dimension in quant_output["shape"]],
        "quantized_tensor_dtype_counts": dict(sorted(dtype_counts.items())),
        "operator_counts": dict(sorted(operator_counts.items())),
        "sample_count": len(per_sample),
        "rmse": rmse,
        "mae": absolute_error / value_count,
        "max_absolute_error": max_absolute_error,
        "psnr_db": 120.0 if rmse == 0 else 20.0 * math.log10(1.0 / rmse),
        "per_sample": per_sample,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-root", type=Path, default=Path("assets/motion_models/litert"))
    parser.add_argument(
        "--validation-root",
        type=Path,
        required=True,
        help="Nonoverlapping sample set with one input_list.txt per resolution.",
    )
    parser.add_argument("--models", nargs="+", choices=["anvil-s", "anvil-m"], default=["anvil-s", "anvil-m"])
    parser.add_argument("--resolutions", nargs="+", choices=["720p", "1080p"], default=["720p", "1080p"])
    parser.add_argument("--max-rmse", type=float, help="Optional acceptance limit in normalized RGB units")
    parser.add_argument("--output", type=Path, help="Write the JSON report to this path as well as stdout")
    args = parser.parse_args()

    try:
        from ai_edge_litert.interpreter import Interpreter
    except ImportError as error:
        raise SystemExit("LiteRT interpreter is missing; install the Android model exporter requirements") from error
    import numpy as np

    root = args.model_root.resolve(strict=True)
    validation_root = args.validation_root.resolve(strict=True)
    manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    validation_metadata_path = validation_root / "metadata.json"
    validation_metadata = None
    if validation_metadata_path.is_file():
        validation_metadata = {
            "metadata_sha256": hashlib.sha256(validation_metadata_path.read_bytes()).hexdigest(),
            "metadata": json.loads(validation_metadata_path.read_text(encoding="utf-8")),
        }
    results: list[dict[str, Any]] = []
    failed = False
    for model_name in args.models:
        for resolution in args.resolutions:
            records = manifest["models"][model_name]["variants"][resolution]
            float_path = verify_record(root, records["gpu"])
            quantized_record = records.get("npu")
            if quantized_record is None:
                raise ValueError(f"Manifest is missing {model_name}/{resolution}/npu")
            quantized_path = verify_record(root, quantized_record)
            inputs = list(calibration_inputs(validation_root, resolution, np))
            result = validate_pair(float_path, quantized_path, inputs, Interpreter)
            result.update({"model": model_name, "resolution": resolution})
            result["float_sha256"] = records["gpu"]["sha256"]
            result["w8a8_sha256"] = quantized_record["sha256"]
            if quantized_record.get("calibration_metadata_sha256"):
                result["calibration_metadata_sha256"] = quantized_record[
                    "calibration_metadata_sha256"
                ]
            if args.max_rmse is not None:
                result["max_rmse_limit"] = args.max_rmse
                result["passed_max_rmse"] = result["rmse"] <= args.max_rmse
                failed = failed or not result["passed_max_rmse"]
            results.append(result)

    report = {
        "format": 1,
        "comparison": (
            "CPU LiteRT interpreter synthesized-frame fidelity; compare the clamped "
            "two-frame blend plus each model's residual, float32 reference vs calibrated W8A8"
        ),
        "model_output_semantics": "residual_to_add_to_pair_blend",
        "quantization_calibration": manifest.get("calibration"),
        "validation_source": validation_metadata,
        "reference_is_ground_truth": False,
        "device_execution_claim": False,
        "results": results,
    }
    encoded = json.dumps(report, indent=2, sort_keys=True) + "\n"
    print(encoded, end="")
    if args.output:
        output = args.output.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(encoded, encoding="utf-8")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
