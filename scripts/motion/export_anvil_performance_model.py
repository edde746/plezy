#!/usr/bin/env python3
"""Export the pinned 540p ANVIL-S graph used by the desktop Performance preset.

The model weights remain the upstream ANVIL-S checkpoint. This script only
changes its fixed ONNX tensor shape, then validates the result against the
checked-in model pack's size and SHA-256.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import urllib.request
from pathlib import Path

SOURCE_REVISION = "f701fd9b01b9fbb20822637b5d82cac626079e5f"
WEIGHTS_REVISION = "fa97e30f6aabe897bd4f6f82d971ad607f5d61fa"
CHECKPOINT_BYTES = 10_412_983
CHECKPOINT_SHA256 = "574297dcad27e601c813c3cab514a8d2b237eef30f40d9e4a6f600720808fefa"
MODEL_BYTES = 3_431_923
MODEL_SHA256 = "6b599d7b13c848ce7608d5e6fa1de8ec0adea8477d29a57be69d71daf808ce84"
CHECKPOINT_URL = (
    "https://huggingface.co/NihilDigit/anvil/resolve/"
    f"{WEIGHTS_REVISION}/checkpoints/D-unet-v3bs-nomv/best.pt"
)


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def download_checkpoint(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    partial = path.with_suffix(path.suffix + ".partial")
    request = urllib.request.Request(
        CHECKPOINT_URL,
        headers={"User-Agent": "PlezyNG-motion-model-export/1"},
    )
    count = 0
    hasher = hashlib.sha256()
    try:
        with urllib.request.urlopen(request, timeout=90) as response, partial.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                count += len(chunk)
                hasher.update(chunk)
                output.write(chunk)
        if count != CHECKPOINT_BYTES or hasher.hexdigest() != CHECKPOINT_SHA256:
            raise RuntimeError(
                f"Pinned checkpoint mismatch: {count} bytes, SHA-256 {hasher.hexdigest()}"
            )
        partial.replace(path)
    except Exception:
        partial.unlink(missing_ok=True)
        raise


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-root",
        type=Path,
        required=True,
        help="Checkout of NihilDigit/anvil at the pinned source revision.",
    )
    parser.add_argument(
        "--checkpoint",
        type=Path,
        required=True,
        help="Path for the pinned upstream ANVIL-S checkpoint (downloaded if missing).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("assets/motion_models/anvil-s-540p.onnx"),
        help="Destination for the 540p static ONNX graph.",
    )
    args = parser.parse_args()

    source_root = args.source_root.resolve()
    source_revision = subprocess.check_output(
        ["git", "-C", str(source_root), "rev-parse", "HEAD"], text=True
    ).strip()
    if source_revision != SOURCE_REVISION:
        raise SystemExit(
            f"Expected ANVIL source {SOURCE_REVISION}, found {source_revision}"
        )

    checkpoint = args.checkpoint.resolve()
    if (
        not checkpoint.is_file()
        or checkpoint.stat().st_size != CHECKPOINT_BYTES
        or digest(checkpoint) != CHECKPOINT_SHA256
    ):
        download_checkpoint(checkpoint)

    import onnx
    import torch

    if onnx.__version__ != "1.17.0":
        raise SystemExit(f"Expected ONNX 1.17.0 for the pinned export, found {onnx.__version__}")
    if torch.__version__.split("+", maxsplit=1)[0] != "2.9.1":
        raise SystemExit(
            f"Expected PyTorch 2.9.1 for the pinned export, found {torch.__version__}"
        )

    sys.path.insert(0, str(source_root / "anvil_exp01"))
    from models.conv_vfi import build_model  # noqa: E402

    model = build_model("D-unet-v3bs-nomv")
    state = torch.load(checkpoint, map_location="cpu", weights_only=True)
    model.load_state_dict(state.get("model_state_dict", state), strict=True)
    model.eval()
    if hasattr(model, "fuse_for_deploy"):
        model.fuse_for_deploy()

    sample = torch.zeros((1, 6, 540, 960), dtype=torch.float32)
    with torch.no_grad():
        output = model(sample)
    if not isinstance(output, torch.Tensor) or tuple(output.shape) != (1, 3, 540, 960):
        raise SystemExit(f"Unexpected ANVIL output tensor: {getattr(output, 'shape', None)}")

    destination = args.output.resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    torch.onnx.export(
        model,
        sample,
        destination,
        export_params=True,
        opset_version=17,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes=None,
        dynamo=False,
    )
    graph = onnx.load(str(destination), load_external_data=True)
    for value_info, shape in (
        (graph.graph.input[0], [1, 6, 540, 960]),
        (graph.graph.output[0], [1, 3, 540, 960]),
    ):
        dimensions = value_info.type.tensor_type.shape.dim
        if len(dimensions) != len(shape):
            raise SystemExit(f"Unexpected tensor rank for {value_info.name}")
        for dimension, size in zip(dimensions, shape, strict=True):
            dimension.Clear()
            dimension.dim_value = size
    onnx.save(graph, str(destination))
    graph = onnx.load(str(destination), load_external_data=True)
    onnx.checker.check_model(graph)

    output_size = destination.stat().st_size
    output_sha256 = digest(destination)
    if output_size != MODEL_BYTES or output_sha256 != MODEL_SHA256:
        raise SystemExit(
            f"Export differs from the pinned pack: {output_size} bytes, SHA-256 {output_sha256}"
        )

    print(
        json.dumps(
            {
                "source_revision": SOURCE_REVISION,
                "weights_revision": WEIGHTS_REVISION,
                "checkpoint_bytes": checkpoint.stat().st_size,
                "checkpoint_sha256": digest(checkpoint),
                "model": str(destination),
                "model_bytes": output_size,
                "model_sha256": output_sha256,
                "input_shape": [1, 6, 540, 960],
                "output_shape": [1, 3, 540, 960],
                "opset": graph.opset_import[0].version,
                "torch": torch.__version__,
                "onnx": onnx.__version__,
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
