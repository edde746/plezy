# Motion processing and neural interpolation

**Status (2026-10-27):** The opt-in motion setting and Windows MPV interpolation are implemented. Neural interpolation, model packs, a shared native motion engine, and automatic cross-platform provider selection are not implemented. The research below records verified provider candidates and the experiments required before expanding playback behavior.

## Product contract

The device-local setting is **Motion smoothing**:

| Choice | Behavior |
| --- | --- |
| **Off** | Keep the selected player's existing cadence and output. This is the default. |
| **MPV** | Use MPV's display-synchronized temporal interpolation only on a qualified MPV output. This blends/resamples neighboring frames; it does not perform neural optical-flow frame generation. |
| **Neural** | Reserved for synthesizing frames with a qualified OS, vendor, or model provider. It remains unavailable until a real playback path and device pass qualification. |

Neural's **Performance**, **Balanced**, and **Quality** presets remain part of the product shape. A preset must identify a tested model/configuration and processing scale; it must not promise an NPU or GPU merely from the platform name. Do not offer Quality if calibration has not demonstrated headroom.

Motion smoothing is separate from **Match Content Frame Rate** and **Match Refresh Rate**. Those settings select display cadence; motion processing generates or resamples video frames.

## What is implemented

`MotionProcessingService` configures Windows MPV before each on-demand `loadfile`, including reused-player episode transitions. It sets `video-sync=display-resample`, `tscale=mitchell`, the associated blur/clamp values, and `interpolation=yes`. The service remembers and restores the user's original timing properties when smoothing is turned off. Configuration must happen before decoder initialization because MPV sizes decoder/renderer frame references based on whether interpolation is enabled.

This is MPV renderer interpolation, not motion-compensated frame generation. The setting is currently exposed only for Windows MPV, whose player configures `vo=gpu-next`. It is not exposed on Linux's embedded `vo=libmpv`, which has no display-refresh interval for this scheduler; on Apple `vo_avfoundation`; or on Android's direct-to-surface MediaCodec and ExoPlayer routes. Android can select a GPU output for some playback cases, but that does not by itself establish a presentable interpolation path.

The performance overlay already reports the active output and available MPV timing/interpolation properties, together with existing decode, frame-rate, and dropped-frame information. These are observations of the active path, not proof that a neural provider ran. Relevant code includes:

- `lib/services/motion_processing_service.dart`
- `lib/screens/video_player/parts/playback_open.dart`
- `lib/widgets/video_controls/widgets/performance_overlay/`
- `windows/runner/mpv/mpv_player.cpp`
- `linux/runner/mpv/mpv_plugin.cc`
- `android/app/src/main/kotlin/com/edde746/plezy/mpv/GpuVoPolicy.kt`
- `ios/Runner/MpvPlayer/MpvPlayerCore.swift`

Plezy already uses hardware for ordinary playback: Android MediaCodec, Apple VideoToolbox, desktop hardware decoding where supported, GPU rendering/shaders on eligible outputs, and native video paths on TV clients. Decoder acceleration, GPU presentation, spatial shader enhancement, and neural inference are distinct capabilities. We currently have no NPU-specific motion feature.

## Research assessment

The supplied research points in a useful direction, but several runtime and performance claims remain hypotheses. Support must be determined from the actual decoder, output, display clock, provider, stream, and device—not the OS label.

### Verified candidates

| Candidate | What upstream documents | Plezy implication |
| --- | --- | --- |
| **Apple VideoToolbox `VTFrameProcessor`** | Apple's API includes frame-rate conversion and low-latency frame interpolation. Apple describes it as introduced in macOS 15.4 and available in iOS 26. Configurations expose runtime support checks; support and acceptable dimensions still need to be queried on each device. | This is the strongest near-term neural-like/native interpolation candidate. It needs a native adapter between Plezy's decoded frames and `vo_avfoundation` / `AVSampleBufferDisplayLayer`, with timestamp, HDR, and playback-pacing qualification. Report the provider as VideoToolbox; do not claim “Neural Engine” unless the API provides evidence of that execution device. No tvOS availability is assumed. |
| **MPV renderer interpolation** | MPV's `interpolation` option uses temporal resampling with `tscale` and requires a `display-*` video-sync mode. Enabling it after decoder initialization can require additional hardware-decoder frames. | The existing Windows implementation sets it early enough and uses a supported configured output. It remains a useful low-risk baseline, but is not optical flow or neural interpolation. |
| **MPV AMD AMF FRC** | Current upstream MPV documentation describes `amf_frc`, an AMD frame-rate-conversion filter that doubles input rate, requires supported AMD hardware/drivers, and currently requires D3D11 input. | This could improve the Windows MPV path on qualified AMD systems. The exact locked Plezy MPV artifacts may not contain this filter; do not activate it until `vf=help`, the build configuration, and real AMD hardware confirm it. Keep the existing renderer path as fallback. |
| **MPV D3D11 video processing** | Current upstream documentation describes `d3d11vpp` scaling modes for Intel Video Super Resolution and NVIDIA RTX Video Super Resolution, depending on driver settings and hardware. These are spatial enhancement/scaling paths, not frame interpolation. | This is a possible later GPU enhancement route. It does not satisfy Motion smoothing and must not be shown as an interpolation provider. Confirm availability in Plezy's pinned binaries before considering integration. |
| **Android LiteRT** | Current LiteRT documentation recommends its `CompiledModel` API for CPU/GPU/NPU execution. Android NPU access is vendor-specific: Google documents a Qualcomm AI Engine Direct delegate and Intel OpenVINO NPU support; the cited NPU overview lists Pixel and Samsung delegates as forthcoming. Android NNAPI was deprecated in Android 15. | LiteRT is a relevant Android candidate, not a universal Android NPU runtime. Never use NNAPI as the long-term answer. Qualify each delegate, chip, model/operator set, device build, and frame path; expose only verified execution. |
| **Windows inference** | ONNX Runtime's Windows documentation recommends WinML's automatic provider selection on Windows 11 24H2 and later; DirectML is in sustained engineering. ONNX Runtime also documents QNN for Windows ARM64/Qualcomm and Vitis AI for AMD Ryzen AI on Windows. Provider availability and maturity differ. | Use a provider adapter that reports observed execution. QNN on a Snapdragon X device is a bounded prototype candidate. Do not hard-code one runtime as the cross-platform engine. |
| **Linux inference** | ONNX Runtime documents an OpenVINO execution provider, including Intel hardware support. | A runtime provider is not enough: Plezy's embedded libmpv path currently lacks display-refresh timing feedback. First prove the output clock/presentation contract before attempting cadence-exact synthesis. |
| **Android Media3 effects** | Media3 exposes `setVideoEffects` and a GL effect/frame processor for processing video frames. | This can be investigated for single-frame GPU enhancement on ExoPlayer. Its per-frame effects API does not itself establish a scheduler that emits intermediate frames at display timestamps, so it is not yet an interpolation route. |

The TV's own motion-compensation feature is outside the app's current control. Unless webOS/Tizen exposes a trustworthy playback capability API, Plezy must report it as unknown and must not claim that the TV performed smoothing.

### Claims that need measurement

- **A native MPV filter is plausible, but it is not a drop-in plugin.** The MPV manual documents the video-filter chain and scripting API; it does not document a stable dynamically loaded third-party video-filter ABI. Plan `vf_plezy_pme` as code built into Plezy's pinned MPV fork/artifacts unless a supported external mechanism is demonstrated. Every affected artifact, ABI, and platform build would need coordinated updates.
- **Zero-copy surface sharing is not established.** D3D11 textures, VideoToolbox pixel buffers, VAAPI/dmabuf, and Android hardware buffers have different ownership, synchronization, format, and runtime requirements. A shared handle/fence does not prove that an inference provider can consume the decoder surface directly. Measure transfers, conversions, synchronization, and peak memory on the real path.
- **NPU flow plus GPU warp is an experiment, not the selected design.** Operator support, especially flow sampling/warping, varies by provider. A provider may partition or fall back per operator. Profile the executed graph and verify the device used; do not trust the requested provider. GPU work and bandwidth also grow with the number of output frames, so “same NPU cost at any refresh rate” is only true for the flow stage and is not an end-to-end performance claim.
- **Cadence-exact output is not guaranteed by intermediate PTS alone.** It also requires a known display refresh, stable frame scheduling, correct seek/track/display-change behavior, preserved audio-clock sync, and output-layer pacing. Linux's present path is a known obstacle. MPV subtitle/OSD draw order and subtitle blending must be checked for each integration before assuming overlays remain clean.
- **No stage-time estimates are accepted yet.** The proposed sub-millisecond GPU stages, 3 ms interop threshold, and 4K/120 claims need measurements on target devices. Record p50/p95 by stage, provider/operator placement, copies, dropped source frames, deadline misses, A/V sync, and thermal state.
- **No model or “first” claim is approved.** RIFE is a benchmark candidate only. Weights, exported graphs, operators, and redistribution terms need separate review. A claim of being first to split NPU/GPU processing or qualify devices across vendors needs independent market evidence and reproducible product results.

## Candidate architecture

Treat the UI choice as a **request**, then resolve it against measured capabilities and stream eligibility. A future `VideoProcessingController` can build on the current setting and overlay:

1. **Playback capability report:** actual player backend, `current-vo`, `hwdec-current`, active render API, display refresh source, decoder pixel format, frame rate/variability, render/drop counts, HDR/Dolby Vision/interlace/live flags, and any provider evidence available from native telemetry.
2. **Effective-pipeline resolver:** a pure decision from request × actual path × stream × device qualification. Return the effective path and a visible reason when the request is unavailable or downgraded. Never show Neural merely because the preference is Neural.
3. **Native provider adapters:** OS-native processor first when it is supported and preserves the output contract; vendor acceleration next; model-backed NPU/GPU inference after qualification; current MPV temporal interpolation as the simpler fallback; then passthrough. The order is a candidate policy, not shipped behavior.
4. **Frame processing boundary:** keep frame work in native video paths, not Flutter screenshots or a composed-surface readback. A `vf_plezy_pme` filter plus a small `libpme` C ABI is a plausible MPV-side seam, but first verify build ownership, frame formats, subtitle/OSD order, and cross-platform artifact costs. Apple VideoToolbox should use its native frame processor rather than forcing it through an ONNX model path.
5. **Provider and timing telemetry:** report the path that actually ran (for example, `Apple VideoToolbox` or `ONNX Runtime · QNN`) only when execution telemetry confirms it. Track p50/p95 stage times, synthesized/source frame ratio, misses, and fallback reason. If a provider cannot prove NPU execution, report the runtime/adapter without naming the NPU.
6. **Fail-safe scheduling:** open sessions and warm models asynchronously; never block initial playback on model load. Flush queued frame pairs on seek, track change, resolution/display change, and discontinuity. On deadline or confidence failure, bypass generated frames and continue ordinary playback. A proposed degradation ladder is Quality → Balanced → Performance → fewer generated timestamps → MPV smoothing → Off, with hysteresis to avoid rapid mode switching.
7. **Qualification data:** keep capability results keyed by device/SoC, OS and driver, provider, model-pack version, and decode/output path. Re-run calibration after relevant changes. Offer only profiles that meet measured deadlines with headroom.

Start with SDR, progressive, constant-frame-rate, on-demand 24/30 fps and a 2× target. Keep Live TV, interlaced video, HDR, Dolby Vision, and direct-to-display paths out of Neural until separately qualified. Use a copy of the real playback path for tests; do not infer support from synthetic tensor benchmarks alone.

The proposed single-frame Restore/Upscale modes are deferred. Plezy already has GPU shader enhancements on selected renderer paths, and ExoPlayer has a GL effect pipeline, but neither creates one cross-platform enhancement stack. Decide whether Restore addresses a measured user problem, then qualify one single-frame model and path before adding a product setting. Do not multiply interpolation artifacts by chaining unqualified filters.

## Delivery plan and gates

| Phase | Work | Exit gate |
| --- | --- | --- |
| **0. Bounded spikes** | (a) Exercise `VTFrameProcessor` from the Apple decode/display path on supported macOS and iOS hardware; query runtime and dimension support. (b) On Snapdragon X/Windows ARM64, measure D3D11-to-QNN/WinML tensor interop and profile the flow graph's actual provider/operator placement. (c) Measure Android direct MediaCodec, copy-capable, and GPU paths on one Pixel and one Snapdragon device; try only delegates documented for those devices. (d) Inventory Plezy's exact pinned MPV builds for `amf_frc`, `d3d11vpp`, and renderer interpolation, then check the corresponding hardware/driver paths. | Stage-level p50/p95, copy/format costs, device/provider evidence, and sustained thermals are recorded. A real 1080p SDR 24 fps path meets the frame deadline with headroom, preserves baseline A/V sync and overlays, and produces no source-frame drop regression. Stop or change direction if no path passes. |
| **1. Capability reporting** | Add a typed report of the active playback path and stream eligibility; connect it to the performance overlay and a pure effective-mode resolver. | Diagnostics state the real path and why a request is available, downgraded, or unavailable. |
| **2. MPV path qualification** | Keep Windows renderer interpolation as baseline; test vendor MPV filters only when the pinned binary and hardware report them. Qualify Linux/Android only when display timing, decode surfaces, and output behavior are proven. | No source-frame drops or A/V-sync regression; seeks, subtitle/OSD, HDR behavior, and mode changes pass on each listed path. |
| **3. Apple native provider** | Integrate the supported VideoToolbox frame processor with Plezy's Apple video presentation path. Gate at runtime and preserve native output. | Target-device measurements cover output timestamps, startup/warm-up, format/HDR behavior, audio sync, and sustained playback. Do not infer support for tvOS. |
| **4. PME model prototype** | If Phase 0 supports it, build the native filter/adapter and one model/provider on one device, likely a Windows ARM64 QNN pilot. Compare split flow/warp against an all-GPU baseline and a full-provider baseline. | Sustained SDR 1080p24 playback for two hours with no deadline storms or source-frame drops; measured visual quality and provider placement are reproducible. |
| **5. Presets and pack lifecycle** | Add per-device Performance/Balanced/Quality mappings, asynchronous model warm-up, signed/hash-verified opt-in packs, calibration invalidation, thermal/power policy, and fallback telemetry. | Presets map to qualified artifacts; model provenance/license and golden-clip quality gates are documented. |
| **6. Enhancement and expansion** | Evaluate one Restore or Upscale model, Media3 GL effects, more Android SoCs, Linux OpenVINO, higher resolutions, and HDR10 independently. | Each route passes its own image, color, performance, and thermal qualification. Keep Dolby Vision excluded until the frame processor is proven to preserve the actual Dolby Vision path and metadata. |

Phase 0 is a planned investigation, not a claim that hardware is currently available or that the split design has passed. Model builds, qualification, and any related CI must use the organization's required private ephemeral JIT runners; missing runner capacity is a blocker, never a hosted-runner fallback.

## References

- [Apple WWDC25: machine-learning-based VideoToolbox effects](https://developer.apple.com/videos/play/wwdc2025/300/) — macOS/iOS availability and frame-processor integration.
- [Apple `VTFrameRateConversionConfiguration`](https://developer.apple.com/documentation/videotoolbox/vtframerateconversionconfiguration) — frame-rate conversion configuration and runtime support property.
- [Apple low-latency frame interpolation configuration](https://developer.apple.com/documentation/videotoolbox/vtlowlatencyframeinterpolationconfiguration) — real-time interpolation API.
- [MPV video filters](https://mpv.io/manual/master/#video-filters) — filter-chain behavior, `d3d11vpp`, and `amf_frc`.
- [MPV interpolation](https://mpv.io/manual/master/#video-sync) — display synchronization and temporal resampling behavior.
- [LiteRT for Android](https://ai.google.dev/edge/litert/android) and [LiteRT NPU delegates](https://ai.google.dev/edge/litert/android/npu/overview) — current Android API and documented vendor delegate status.
- [Android NNAPI deprecation and migration](https://developer.android.com/ndk/guides/neuralnetworks/migration-guide).
- [Media3 `ExoPlayer.setVideoEffects`](https://developer.android.com/reference/androidx/media3/exoplayer/ExoPlayer#setVideoEffects(java.util.List)) and [`GlEffect`](https://developer.android.com/reference/androidx/media3/effect/GlEffect).
- [ONNX Runtime execution providers](https://onnxruntime.ai/docs/execution-providers/), [Windows integration](https://onnxruntime.ai/docs/get-started/with-windows.html), [QNN](https://onnxruntime.ai/docs/execution-providers/QNN-ExecutionProvider.html), and [Vitis AI](https://onnxruntime.ai/docs/execution-providers/Vitis-AI-ExecutionProvider.html).
- [Plezy's pinned MPV artifacts](../../mpv-build.lock.json) — check the exact version/build before using features documented on upstream MPV master.
