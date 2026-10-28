# Optional speech acceleration builds

The subtitle AI sheet selects only devices reported by the packaged native runtime. A GPU shown by the video decoder does not imply that the Whisper runtime contains a GPU backend.

## Desktop Whisper GPU builds

The app dependency pins whisper.cpp through `flutter_whisper_ggml`. CPU is the package's default so ordinary application builds do not require GPU SDKs. Opt into a backend only on a build runner with the matching native SDK, headers, shader compiler, and driver runtime:

### Windows

```powershell
$env:FLUTTER_WHISPER_GPU_BACKEND = 'VULKAN'
flutter build windows --release
```

Use `CUDA` instead of `VULKAN` when building with the CUDA Toolkit and NVIDIA driver stack. Consumer builds without the variable remain CPU builds.

### Linux

```bash
FLUTTER_WHISPER_GPU_BACKEND=VULKAN flutter build linux --release
```

The Vulkan build requires Vulkan development headers and the SPIR-V/`glslc` toolchain. The packaged runtime exposes the device only when the backend was compiled successfully and the host driver is available. Failed discovery or inference restarts the job on CPU.

## Other targets

- Android Whisper is CPU/NEON in this package; Android Vulkan and WebGPU are not enabled.
- iOS/macOS Whisper uses CPU/Accelerate; Metal is not enabled.
- Browser Whisper uses WebAssembly CPU. The app's file-path and generated-track attachment flow currently gates browser generation off.
- Sherpa ONNX Core ML, QNN, and RKNN provider strings are attempted only on compatible application targets. The app does not bundle a custom Core ML/QNN/RKNN build of sherpa-onnx in this PR; a provider request that the package cannot initialize falls back to its CPU Moonshine model.

This document describes build options, not measured compatibility. Keep the normal CPU build as the required baseline. A platform-specific release must verify device enumeration, inference results, fallback behavior, model memory, and coexistence with playback on the private JIT/device runner for that target.
