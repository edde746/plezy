# Android LiteRT model pack and W8A8 fidelity — 2026-10-28

The Android LiteRT pack now contains float32 GPU models and calibrated W8A8
generic JIT NPU candidates for ANVIL-S and ANVIL-M at 720p and 1080p. All eight
models expose the NHWC input/output shapes required by
`plezy_litert_motion.cpp`. ANVIL returns a three-channel residual; playback adds
that residual to the average of the two input frames before clamping to display
range.

The exporter converted the pinned ANVIL source and weights on the CPU. It used
16 evenly spaced, even-index frame pairs for calibration and 16 disjoint,
odd-index pairs for validation. Both sets come from the same SDR *Tears of
Steel* clip (Blender Foundation, 2012, CC BY 3.0); validation therefore checks
held-out pairs, not generalization to independent content. The raw decoded pairs
do not reproduce ANVIL playback's motion-vector prealignment.

The validator compares each synthesized W8A8 frame with its float32 model
counterpart. It does not compare against a ground-truth midpoint or claim device
execution. The worst held-out pair was `pair-023.f32`:

| Model | Resolution | Float bytes | W8A8 bytes | RMSE | MAE | PSNR | Worst-pair PSNR |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ANVIL-S | 720p | 3,463,252 | 958,080 | 0.006485 | 0.002085 | 43.76 dB | 34.55 dB |
| ANVIL-S | 1080p | 3,464,436 | 959,312 | 0.007888 | 0.002526 | 42.06 dB | 33.10 dB |
| ANVIL-M | 720p | 10,707,640 | 2,828,160 | 0.007508 | 0.002132 | 42.49 dB | 32.39 dB |
| ANVIL-M | 1080p | 10,708,864 | 2,829,440 | 0.009178 | 0.002304 | 40.74 dB | 30.95 dB |

These results support packaging the opt-in W8A8 candidates alongside the GPU
fallback. They do not qualify Qualcomm, MediaTek, OpenVINO, Samsung, or Google
Tensor execution on a device. The Android runtime continues to reject NPU
sessions with CPU partitions and falls back to the float GPU model when a
provider cannot take the full graph.

The complete per-pair metrics, source metadata, split definitions, and model
hashes are in the [validation JSON](android-litert-w8a8-validation-2026-10-28.json).
