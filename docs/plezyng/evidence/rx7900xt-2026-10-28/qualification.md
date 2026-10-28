# RX 7900 XT PME Performance qualification

**Date:** 2026-10-28
**Host:** `kspld0`, dual-GPU desktop
**Target GPU:** Radeon RX 7900 XT (`gfx1100`, PCI `0000:15:00.0`)

## Isolation and setup

The task container exposed `/dev/kfd` and only `/dev/dri/renderD129`, which maps to the RX 7900 XT. ROCm saw that card as container GPU 0; the desktop RX 9070 XT was not exposed. The run used process-local `ROCR_VISIBLE_DEVICES=0` and selected `Radeon RX 7900 XT` for PME Vulkan compute.

The tested source was mpv 0.41.0 at commit `41f6a645068483470267271e1d09966ca3b9f413`, with the Plezy PME filter and reduced-model-shape patch. The filter used the bundled ANVIL-S 540p graph (`[1,6,540,960]` input; `[1,3,540,960]` output), the AMD MIGraphX inference provider, and the RADV RX 7900 XT Vulkan device. A 1080p24 H.264 clip was software-decoded with exported motion vectors. Output used mpv's null VO, so this isolated the filter and model path from visible presentation.

## Result

During a 4:30 repeated run, the filter processed 6,409 source frames and generated 5,207 midpoint frames. The last sampled source-pair pipeline time was 22.685 ms; inference p95 was 10.551 ms. There were 19 deadline misses, handled by four temporary MPV-smoothing backoffs. Neural output was active again at the end. No scene-cut bypasses were observed. The last sampled GPU load was 31%; the late thermal sample was 63°C GPU hotspot, 84°C memory, and 72 W.

The bundled graph is reproducible from the pinned ANVIL source and checkpoint with `scripts/motion/export_anvil_performance_model.py`; the regenerated model matches the checked-in 3,431,923-byte file and SHA-256 `6b599d7b13c848ce7608d5e6fa1de8ec0adea8477d29a57be69d71daf808ce84`.

The 60-second H.264 source clip is retained on `kspld0` at `/var/tmp/plezy-pme-qualification-evidence-2026-10-28/motion-test-1080p24-60s.mp4` (38,847,474 bytes; SHA-256 `64ec1c5b3f8929ef1f940afdf5c56e5148b003790df5a06bf08dc25f037164fc`) for local reruns.

## What this does and does not qualify

This is evidence that the local Linux PME filter can run its reduced-resolution model and generate midpoint frames within a 24 fps source-pair budget on the RX 7900 XT, with its deadline governor falling back and recovering. The null VO does not qualify visible frame presentation, display pacing, A/V sync, subtitles/OSD, perceived image quality, or hardware decode. It also does not qualify Balanced/Quality models, 30 fps, other GPUs or platforms, or a two-hour thermal run. Keep those claims gated on their own device and presentation-path evidence.

## Retained raw logs

- [mpv PME playback log](raw/mpv-540p-loop.log)
- [Vulkan device inventory](raw/vulkan-summary.log)

The `raw/` folder also retains the other iteration and environment logs.

## Rebuilt PME ABI probe

The common PME library and standalone runtime probe were freshly configured
and compiled from this checkout in the cached ROCm 7.2.1 PyTorch container.
The container received `/dev/kfd` and only `/dev/dri/renderD129`; its ROCm
inventory contained `gfx1100` Radeon RX 7900 XT and did not contain the desktop
RX 9070 XT. The container was removed automatically after the run. CMake and
the build output were placed in the repository's ignored `build/pme-amd`
directory.

Build configuration:

```sh
cmake -S shared/cpp/plezy_motion_engine -B build/pme-amd \
  -DCMAKE_INSTALL_PREFIX="$PWD/build/pme-amd/stage" \
  -DPLEZY_ORT_LINUX_VARIANT=amd-migraphx \
  -DPME_BUILD_RUNTIME_PROBE=ON
cmake --build build/pme-amd --target plezy_motion_runtime_probe --parallel 4
cmake --install build/pme-amd --component Runtime
cmake --install build/pme-amd --component DevTools
```

The probe ran `assets/motion_models/anvil-s-540p.onnx` with
`MIGraphXExecutionProvider`, device 0 inside the single-GPU container, and CPU
fallback disabled. The model SHA-256 was
`6b599d7b13c848ce7608d5e6fa1de8ec0adea8477d29a57be69d71daf808ce84`.
After 3 warmups and 12 calls, it reported:

```json
{"provider":"MIGraphXExecutionProvider","vendor":"AMD","device":"GPU","cpu_fallback":false,"input_elements":3110400,"output_elements":1555200,"warmups":3,"iterations":12,"session_open_ms":30792.194,"inference_ms":{"median":7.231,"p95":7.683,"mean":7.290}}
```

The staged files include the ONNX Runtime 1.23.2 MIGraphX runtime, provider
library, shared provider interface library, PME ABI, and diagnostic executable.
The runtime probe demonstrates GPU model execution through the current PME
ABI on the RX 7900 XT. It excludes decoded-frame preparation, full filter
reconstruction, display presentation, audio sync, and visual quality.
