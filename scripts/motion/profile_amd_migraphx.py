#!/usr/bin/env python3
"""Profile the pinned ANVIL-S ONNX model on one visible RX 7900 XT.

Run inside an AMD ROCm container with ROCR_VISIBLE_DEVICES set to the host
index of the RX 7900 XT. This measures only the model inference stage; it does
not qualify Plezy's PME ABI, frame transfers, preprocessing, or presentation.
It supports both the older monolithic MIGraphX EP wheel and AMD's current
separate execution-provider plugin package.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import os
import re
import statistics
import subprocess
import tempfile
import time
import urllib.request
from pathlib import Path
from typing import Any


MODELS = {
    "anvil-s": {
        "filename": "D_unet_v3bs_nomv_1080p.onnx",
        "bytes": 3_441_349,
        "sha256": "65e871aed25b331e3a3747cf9019942121a94af71997476f5804a24b768cd0d8",
    },
    "anvil-m": {
        "filename": "D_unet_v3bm_nomv_1080p.onnx",
        "bytes": 10_677_524,
        "sha256": "261f95a17c865b45e4d7e2be3439d91b47315bef96e32d46f3cfc785941774fd",
    },
}
MODEL_REPOSITORY = "https://huggingface.co/NihilDigit/anvil/resolve/fa97e30f6aabe897bd4f6f82d971ad607f5d61fa/onnx/"
EXPECTED_GPU = "Radeon RX 7900 XT"


def visible_amd_gpus() -> list[str]:
    mask = os.environ.get("ROCR_VISIBLE_DEVICES", "").strip()
    if not mask:
        raise RuntimeError("Set ROCR_VISIBLE_DEVICES to isolate the target GPU before starting this process.")

    result = subprocess.run(["rocminfo"], check=True, capture_output=True, text=True)
    architectures = re.findall(r"^\s*Name:\s*(gfx[0-9a-z]+)\s*$", result.stdout, re.MULTILINE)
    if architectures != ["gfx1100"] or EXPECTED_GPU not in result.stdout:
        raise RuntimeError(
            "Refusing to profile: the isolated ROCm view must contain only the RX 7900 XT "
            f"(gfx1100); found GPU architectures {architectures!r}."
        )
    return [EXPECTED_GPU]


def download_model(model_id: str, destination: Path) -> None:
    model = MODELS[model_id]
    digest = hashlib.sha256()
    count = 0
    request = urllib.request.Request(
        MODEL_REPOSITORY + model["filename"],
        headers={"User-Agent": "PlezyNG-local-motion-profile/1"},
    )
    with urllib.request.urlopen(request, timeout=60) as response, destination.open("wb") as output:
        while chunk := response.read(1024 * 1024):
            count += len(chunk)
            if count > model["bytes"]:
                raise RuntimeError(f"Pinned model exceeds expected size ({model['bytes']} bytes).")
            digest.update(chunk)
            output.write(chunk)

    if count != model["bytes"] or digest.hexdigest() != model["sha256"]:
        raise RuntimeError(
            f"Pinned model verification failed: bytes={count}, sha256={digest.hexdigest()}"
        )


def concrete_input_shape(shape: list[Any]) -> tuple[list[int], str]:
    if len(shape) != 4:
        raise RuntimeError(f"Expected a rank-4 image tensor, received shape {shape!r}.")

    normalized = [value if isinstance(value, int) and value > 0 else None for value in shape]
    if normalized[1] == 6:
        expected = [1, 6, 1080, 1920]
        layout = "NCHW"
    elif normalized[3] == 6:
        expected = [1, 1080, 1920, 6]
        layout = "NHWC"
    else:
        raise RuntimeError(f"Could not identify six-channel NCHW/NHWC input from shape {shape!r}.")

    for index, value in enumerate(normalized):
        if value is not None and value != expected[index]:
            raise RuntimeError(f"Model input {shape!r} is not the pinned 1080p {layout} shape.")
    return expected, layout


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def profile(model_id: str, warmup: int, iterations: int, allow_cpu_fallback: bool) -> dict[str, Any]:
    import numpy as np

    # ROCm 10.x's MIGraphX Python package initializes shared runtime libraries
    # needed by its separately packaged ONNX Runtime EP plugin.
    try:
        import migraphx  # type: ignore[import-not-found]  # noqa: F401
    except ImportError:
        pass

    import onnxruntime as ort

    gpus = visible_amd_gpus()
    if gpus != [EXPECTED_GPU]:
        raise RuntimeError(
            f"Refusing to profile: expected only {EXPECTED_GPU!r} to be visible, found {gpus!r}."
        )
    try:
        import onnxruntime_ep_migraphx as migraphx_ep
    except ImportError:
        migraphx_ep = None
    if migraphx_ep is not None:
        names = migraphx_ep.get_ep_names()
        paths = migraphx_ep.get_library_paths()
        if not names or len(names) != len(paths):
            raise RuntimeError("AMD's MIGraphX plugin package returned no matching EP names and libraries.")
        for name, path in zip(names, paths, strict=True):
            ort.register_execution_provider_library(name, path)

    if "MIGraphXExecutionProvider" not in ort.get_available_providers():
        raise RuntimeError(f"MIGraphX is unavailable: {ort.get_available_providers()!r}.")

    with tempfile.TemporaryDirectory(prefix="plezy-anvil-migraphx-") as temporary_directory:
        model = MODELS[model_id]
        model_path = Path(temporary_directory) / model["filename"]
        print(f"Downloading and verifying the pinned {model_id.upper()} model…", flush=True)
        download_model(model_id, model_path)

        # With ROCR_VISIBLE_DEVICES exposing only one card, device 0 always
        # maps to the requested physical RX 7900 XT.
        provider: Any = ("MIGraphXExecutionProvider", {"device_id": "0"})
        node_providers: dict[str, int] = {}
        diagnostic_session_providers: list[str] = []
        options = ort.SessionOptions()
        if allow_cpu_fallback:
            options.enable_profiling = True
            options.profile_file_prefix = str(Path(temporary_directory) / "provider-assignment")
        else:
            options.add_session_config_entry("session.disable_cpu_ep_fallback", "1")
        options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        print(
            "Creating a MIGraphX session on visible device 0 with "
            f"CPU fallback {'allowed and node profiling enabled' if allow_cpu_fallback else 'disabled'}…",
            flush=True,
        )
        session = ort.InferenceSession(str(model_path), sess_options=options, providers=[provider])
        diagnostic_session_providers = session.get_providers() if allow_cpu_fallback else []
        if not allow_cpu_fallback and (
            not session.get_providers() or session.get_providers()[0] != "MIGraphXExecutionProvider"
        ):
            raise RuntimeError(f"MIGraphX did not own the session: {session.get_providers()!r}.")

        inputs = session.get_inputs()
        if len(inputs) != 1:
            raise RuntimeError(f"Expected one model input, received {len(inputs)}.")
        input_meta = inputs[0]
        if input_meta.type != "tensor(float)":
            raise RuntimeError(f"Expected float32 model input, received {input_meta.type!r}.")
        shape, layout = concrete_input_shape(input_meta.shape)
        rng = np.random.default_rng(0)
        sample = rng.random(shape, dtype=np.float32)

        print(f"Warm-up: {warmup} inference(s); timed runs: {iterations}…", flush=True)
        for _ in range(warmup):
            session.run(None, {input_meta.name: sample})

        timings_ms: list[float] = []
        for _ in range(iterations):
            started = time.perf_counter()
            session.run(None, {input_meta.name: sample})
            timings_ms.append((time.perf_counter() - started) * 1000.0)

        if allow_cpu_fallback:
            profile_path = Path(session.end_profiling())
            profile_events = json.loads(profile_path.read_text(encoding="utf-8"))
            node_providers = dict(
                sorted(
                    Counter(
                        event.get("args", {}).get("provider")
                        for event in profile_events
                        if event.get("cat") == "Node" and event.get("args", {}).get("provider")
                    ).items()
                )
            )

        return {
            "gpu": gpus[0],
            "rocr_visible_devices": os.environ["ROCR_VISIBLE_DEVICES"],
            "onnxruntime": ort.__version__,
            "available_providers": ort.get_available_providers(),
            "session_providers": session.get_providers(),
            "diagnostic_session_providers": diagnostic_session_providers,
            "provider_options": session.get_provider_options(),
            "cpu_ep_fallback_disabled": not allow_cpu_fallback,
            "profiling_enabled_during_timing": allow_cpu_fallback,
            "cpu_fallback_diagnostic_node_providers": node_providers,
            "model": model_id,
            "model_sha256": model["sha256"],
            "input": {"name": input_meta.name, "shape": shape, "layout": layout},
            "warmup_runs": warmup,
            "timed_runs": iterations,
            "inference_ms": {
                "min": min(timings_ms),
                "median": statistics.median(timings_ms),
                "p95": percentile(timings_ms, 0.95),
                "max": max(timings_ms),
            },
            "source_frame_budget_ms": {"24_fps": 1000.0 / 24, "30_fps": 1000.0 / 30},
        }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", choices=MODELS, default="anvil-s")
    parser.add_argument(
        "--allow-cpu-fallback",
        action="store_true",
        help="profile node placement with fallback enabled; never use this run to claim pure GPU execution",
    )
    parser.add_argument("--warmup", type=int, default=3)
    parser.add_argument("--iterations", type=int, default=12)
    args = parser.parse_args()
    if args.warmup < 0 or args.iterations < 3:
        parser.error("--warmup must be nonnegative and --iterations must be at least 3")
    print(
        json.dumps(
            profile(args.model, args.warmup, args.iterations, args.allow_cpu_fallback),
            indent=2,
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
