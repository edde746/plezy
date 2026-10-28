# Optional speech acceleration and local translation

Normal release builds keep Whisper on CPU. GPU compilation is an explicit, opt-in full build because each backend needs its matching native SDK and the deployed machine still needs a compatible driver.

## Build from GitHub Actions

Dispatch the private PlezyNG Release workflow with:

- action=build
- mode=release
- subtitle_gpu_backend=cpu, vulkan, or cuda

The default is cpu. Choosing vulkan installs the pinned LunarG Vulkan SDK 1.4.363.0 for Windows x64 and Linux x64, verifies the published archive SHA-256 (Windows: 94a82d378f7a5e3e54c9db7d2fb7016af136e14ac0a18dbf0f2f67a36352d141; Linux: 197962f5cbf80baf2775a03336a01cee7c8745686c65aaa70d3f751ade4d7e43), and sets FLUTTER_WHISPER_GPU_BACKEND=VULKAN. Choosing cuda installs NVIDIA CUDA Toolkit 13.4.3 components on Windows x64, validates the NVIDIA Authenticode signer, and sets FLUTTER_WHISPER_GPU_BACKEND=CUDA. Linux CUDA and non-x64 builds stay on CPU. Release publishing rejects GPU selections and remains CPU-only.

The SDK installation happens only on the private JIT runner. It does not run from ordinary app builds or configure a consumer machine. The workflow does not install an NVIDIA display driver; GPU use still depends on a compatible driver on the system where the app runs.

## Prerequisites and pinned SDKs

| Target | Build selection | SDK prepared by workflow | Host requirement |
| --- | --- | --- | --- |
| Windows x64 | vulkan | LunarG Vulkan SDK 1.4.363.0, SHA-256 94a82d378f7a5e3e54c9db7d2fb7016af136e14ac0a18dbf0f2f67a36352d141 | Visual Studio 2022 C++ build tools and a Vulkan-capable driver |
| Linux x64 | vulkan | LunarG Vulkan SDK 1.4.363.0, SHA-256 197962f5cbf80baf2775a03336a01cee7c8745686c65aaa70d3f751ade4d7e43 | CMake, Ninja, pkg-config, and a Vulkan-capable driver |
| Windows x64 | cuda | NVIDIA CUDA Toolkit 13.4.3; installer signer checked as NVIDIA Corporation | Visual Studio 2022 C++ build tools and a compatible NVIDIA driver |
| Other targets | cpu | None | No GPU SDK |

Use the official [NVIDIA Windows installation guide](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/) and [LunarG SDK downloads](https://vulkan.lunarg.com/sdk/home). CUDA 13.1 and later Windows toolkits do not install the NVIDIA display driver; install the compatible driver separately.

## Build locally

The application dependency pins whisper.cpp through flutter_whisper_ggml. Install the matching toolchain, then set the backend before building.

### Windows x64

~~~powershell
# Install CUDA Toolkit 13.4.3 and a compatible NVIDIA driver first.
$env:FLUTTER_WHISPER_GPU_BACKEND = 'CUDA'
flutter build windows --release

# Or install LunarG Vulkan SDK 1.4.363.0 and build with Vulkan.
$env:FLUTTER_WHISPER_GPU_BACKEND = 'VULKAN'
flutter build windows --release
~~~

### Linux x64

~~~bash
# Install LunarG Vulkan SDK 1.4.363.0 and a compatible Vulkan driver first.
FLUTTER_WHISPER_GPU_BACKEND=VULKAN flutter build linux --release
~~~

CPU builds need no GPU SDK. Backend selection changes which native code is compiled; it cannot enable a GPU in a binary already built for CPU. Whisper device discovery and execution are still runtime-dependent. Failed GPU loading or inference restarts the WAV transcription on CPU.

## Local desktop subtitle-text translation

Desktop cue translation uses the optional Argos Translate Python runtime. Install argostranslate for the Python interpreter used by PlezyNG, then install the source-to-target package. Example for English to Spanish:

~~~bash
python -m pip install argostranslate
argospm update
argospm install translate-en_es
~~~

Use PLEZY_ARGOS_PYTHON to point PlezyNG at a specific Python executable when python/python3 is not on PATH. Translation runs locally, preserves subtitle timing and markup, and writes a separate SRT. Argos accepts ARGOS_DEVICE_TYPE=cuda; this is an optional request through CTranslate2, not evidence that every cue ran on CUDA. A failed CUDA request retries on CPU. An NVIDIA driver and a CUDA-enabled CTranslate2/Argos installation are required.

## Other targets

- Android Whisper uses CPU/NEON. Android Vulkan and WebGPU are not enabled by the packaged Flutter runtime.
- iOS/macOS Whisper uses CPU/Accelerate. Metal is not enabled.
- Browser Whisper uses WebAssembly CPU; PlezyNG's generated-subtitle attachment flow is not enabled in the browser.
- Sherpa ONNX requests Core ML, QNN, and RKNN for its English Moonshine path on supported application targets. Provider initialization or inference failure retries on CPU; the app cannot verify per-node placement.
- Live in-player capture currently taps decoded PCM only on Android ExoPlayer VOD. MPV fallback, desktop and Apple players do not expose PCM to this workflow. Those backends use matching WAV input for full-file transcription and sync.

This document describes build and runtime requests, not measured compatibility. No native GPU build, device enumeration, live capture, or physical-device benchmark was run for this PR.
