# Motion processing and neural interpolation

## Current app behavior

Motion processing is an opt-in, device-local playback setting:

| Mode | Behavior |
| --- | --- |
| Off | Default. Keep the selected player's existing cadence and output. |
| MPV | Use MPV display-synchronized temporal interpolation on the qualified Windows MPV output. This blends/resamples frames; it is not neural optical-flow generation. |
| Neural | Reserved for a model-backed path. It is unavailable until the runtime, model, active video output, and device pass qualification. |

The MPV configuration is applied immediately before every on-demand item opens, including episode transitions that reuse a player. This lets MPV configure interpolation buffers before decoding starts. The service preserves and restores the MPV timing properties it found before enabling interpolation. Live TV and non-MPV players do not use this path. The performance overlay reports the active video output, interpolation flag, video-sync mode, display rate, rendered rate, and dropped frames when MPV exposes them.

Preferences written by the earlier development UI (`natural`, `balanced`, and `smooth`) are read as the single MPV mode. The selected Neural preset is kept separately as a device-local preference, defaulting to Balanced; it is not presented as selectable until a Neural backend is qualified.

Plezy already uses hardware for ordinary playback: Android MediaCodec, Apple VideoToolbox, automatic hardware decoding on desktop, the television's native media pipeline, and MPV GPU presentation/scaling where those routes provide it. Those paths do not by themselves expose decoded frames for inference. In particular, direct MediaCodec-to-display and the webOS/Tizen native video planes do not provide a Flutter frame stream.

## Runtime decision

There is no single runtime package that currently covers every PlezyNG target, execution provider, and video path. Use **ONNX Runtime's ONNX model format and C API as the shared inference contract**, with a platform-specific execution provider and a native frame adapter for each qualified target.

The Dart package `onnxruntime_core` is the closest shared Flutter binding candidate: its published platform matrix lists Android, iOS, macOS, Linux, Windows, and Web. Its published release is currently `0.1.0+onnxruntime-1.29.0`, from an unverified uploader, so it needs a source, binary, ABI, and maintenance audit before becoming a production dependency. Its package matrix does not include tvOS, webOS, or Tizen. The more established `flutter_onnxruntime` wrapper requires iOS 16, above Plezy's current iOS deployment target, and also omits those three targets; do not add it unchanged.

ONNX Runtime's execution-provider architecture keeps one model/runtime API while selecting different acceleration libraries. That does not promise one accelerator everywhere:

| Target | Runtime/provider direction | Current blocker |
| --- | --- | --- |
| Windows | ONNX Runtime with Windows ML provider selection; WebGPU is another GPU route | No MPV frame-tap or inference path is integrated. |
| Linux | ONNX Runtime CPU/XNNPACK or a qualified GPU provider | The embedded `libmpv` video plane has no display-vsync input and no inference frame adapter. |
| macOS / iOS | ONNX Runtime CoreML provider, with CPU/GPU/ANE selected by Core ML | AVFoundation frames must be acquired and returned without changing native HDR/Dolby Vision presentation. |
| tvOS | A separately built and maintained ONNX Runtime/CoreML package would be required | Official ONNX Runtime iOS build documentation excludes tvOS. |
| Android MPV | ONNX Runtime CPU/XNNPACK; optional Qualcomm QNN on supported Snapdragon hardware | The preferred MediaCodec route renders directly to the display. A supported copy/process/present route is not integrated. QNN is not a general Android NPU provider. |
| Android ExoPlayer | Separate native adapter and runtime work | No interpolation path is qualified; leave ExoPlayer unchanged. |
| Web | ONNX Runtime Web with WebGPU/WebNN where the browser supports it | Needs browser-decoded frame access and a tested presentation path; a runtime alone cannot access the MPV/native video plane. |
| webOS / Tizen | Custom native runtime/provider investigation | No runtime is configured in this repository, and neither native video path has a qualified decoded-frame adapter. |

`onnxruntime_core` lists XNNPACK for CPU acceleration on its native binaries, CoreML on Apple mobile/desktop, and WebGPU or WebNN depending on the web build. ONNX Runtime's native WebGPU provider targets D3D12/Vulkan on Windows, Vulkan on Linux/Android, and Metal on macOS/iOS. Qualcomm QNN requires Qualcomm hardware and its SDK/provider. Treat all providers as optional capabilities discovered at runtime, never as a platform-name guarantee.

ExecuTorch is the alternate candidate, but its backend lowering produces backend-specific `.pte` artifacts and target-specific bundles. That makes it a weaker single-model interchange layer for this app's wide platform matrix; it remains an option if one native backend proves materially better on a pilot device.

## Neural integration gates

Do not connect inference to a Flutter screenshot or read back the composed video surface. A useful adapter must obtain the decoded frames in the video pipeline, synthesize between adjacent frames, and submit results before subtitle/OSD composition while audio remains the presentation clock.

The first prototype should use SDR, progressive, on-demand 24/30 fps video and a 2× target on one real device. Measure frame access, copy cost, model initialization, sustained inference latency, thermal behavior, presentation pacing, source-frame drops, seeks, scene cuts, audio sync, and subtitle composition. Bypass generated frames on any missed deadline or inference failure and continue ordinary playback. HDR, Dolby Vision, interlaced material, Live TV, and direct-to-display paths remain unavailable until separately qualified.

No interpolation model is selected. RIFE is a benchmark candidate, not a shippable model choice: the upstream repository points to externally hosted weights and does not provide a project-qualified ONNX package. Before shipping a model, record its source, exact version, hash, license for the weights and exported graph, supported operators, and per-device performance. Performance, Balanced, and Quality must map to qualified models/scales rather than a claimed NPU/GPU tier.

## References

- [ONNX Runtime execution providers](https://onnxruntime.ai/docs/execution-providers/)
- [ONNX Runtime native and WebGPU provider requirements](https://onnxruntime.ai/docs/execution-providers/WebGPU-ExecutionProvider.html)
- [ONNX Runtime for Windows and Windows ML](https://onnxruntime.ai/docs/get-started/with-windows.html)
- [ONNX Runtime iOS build targets](https://onnxruntime.ai/docs/build/ios.html)
- [`onnxruntime_core` platform and provider matrix](https://pub.dev/documentation/onnxruntime_core/latest/)
- [`flutter_onnxruntime` platform and iOS deployment requirements](https://pub.dev/documentation/flutter_onnxruntime/latest/)
- [Practical-RIFE upstream model references](https://github.com/hzwer/Practical-RIFE)
