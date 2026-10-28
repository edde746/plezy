# Plezy Motion Engine runtime ABI

`pme_runtime.h` is the stable C boundary used by native playback adapters.
`pme_runtime.cpp` loads ONNX Runtime dynamically and keeps execution-provider
registration, session ownership, and tensor validation out of the mpv filter.
The runtime is compiled against ONNX Runtime C API version 27 or newer. Plugin
and catalog providers require a runtime that exposes API 27. A narrowly scoped
Linux compatibility path requests API 23 only when the provider manifest
explicitly selects built-in MIGraphX; this covers AMD's ROCm 7.2.1 ORT 1.23.2
package. The Windows package uses the stable Windows ML 2.4.89 SDK/runtime,
which ships ONNX Runtime 1.27.1.

The current ABI accepts a fixed-shape model with one float32 input tensor and
one float32 output tensor. The playback adapter owns frame conversion,
provider preference, timing, scheduling, and generated-frame presentation.
Model packs are supplied by `NeuralModelPackService`; the library does not
bundle model weights.

Provider candidates are ordered and are checked against the device that owns
the model output. On Windows, the provider manifest uses the `windows-ml`
marker for certified QNN, OpenVINO, Vitis AI, NvTensorRtRtx, and MIGraphX
providers. PME resolves each short registration name through the Windows ML
execution-provider catalog, prepares it on the asynchronous session worker,
registers its returned library path with ONNX Runtime, and verifies the output
provider/device. Windows ML's bundled DirectML provider is the legacy GPU
compatibility fallback. The self-contained runtime adds about 41 MB and is
staged beside the app executable;
vendor execution providers are acquired from the Windows catalog when the
user enables Neural playback on a compatible Windows 11 24H2-or-later device.
Provider preparation runs on PME's initialization worker and observes filter
shutdown: an in-flight Windows ML acquisition is canceled and drained before
its callback state is released.

On Linux, QNN and OpenVINO plugins use ORT's plugin EP API. The AMD ANVIL
manifest selects the built-in MIGraphX provider: the verified ROCm 7.2.1
`onnxruntime-migraphx` wheel is ORT 1.23.2, and the PME loader requests API 23
only for that explicit built-in provider. The pinned 1080p ANVIL-S and ANVIL-M
models have run on an RX 7900 XT with CPU fallback disabled. After three
warm-ups and 12 timed inferences, ANVIL-S measured 25.73 ms median / 29.49 ms
p95 and ANVIL-M measured 33.59 ms median / 38.09 ms p95. These are
inference-only measurements: ANVIL-M leaves about 3.57 ms within a 24 fps source
interval and exceeds the 30 fps interval before frame preparation, transfers,
reconstruction, or presentation are included. The C++ PME ABI was also run
against ANVIL-S in the ROCm 7.2.1 container with only the RX 7900 XT visible.
With CPU fallback disabled, 3 warm-ups and 12 timed calls measured 28.252 ms
median / 32.697 ms p95 through `pme_runtime_run`; this includes ONNX Runtime
tensor handling and output copy, but not decoded-frame preparation, conversion,
interpolation reconstruction, or presentation. A 540p static export of the same
ANVIL-S weights measured 6.851 ms median / 7.329 ms p95 in the same isolated
ABI probe. The complete filter then ran that 540p model against 1080p24 sources
on the RX 7900 XT: a repeated 4:30 null-VO playback generated 5,207 midpoint
frames from 6,409 source frames. The final sampled pipeline was 22.685 ms, with
19 deadline misses and four temporary governor backoffs across the run. This
qualifies local filter throughput, not visible presentation or A/V sync. `scripts/motion/pme_runtime_probe.cpp` can reproduce the ABI path and
reports the actual provider, session-open time, and latency. Build it with
`-DPME_BUILD_RUNTIME_PROBE=ON`; CPU fallback is disabled by the probe. AMD's newer
ROCm 10.1/ORT 1.29 plugin is available for `gfx1100`, but the pinned ANVIL-S
graph currently lands entirely on CPU through that plugin, so PME does not use
it for this model. CUDA uses
`SessionOptionsAppendExecutionProvider_CUDA` with adapter 0. Windows
DirectML uses ORT's `OrtDmlApi` DML2 high-performance GPU selection, and Vitis
AI can use the built-in `SessionOptionsAppendExecutionProvider_VitisAI` API
where the matching runtime is supplied. Accelerator sessions disable CPU EP
fallback. DirectML also disables memory-pattern allocation and forces
sequential execution, as required by that provider. CPU inference is a separate
last-resort session and must be enabled explicitly.

The explicit Linux `--cpu-only` probe opened the 540p ANVIL-S graph on
`kspls0` through `CPUExecutionProvider` at 317.831 ms median / 343.899 ms p95
after three warm-ups and twelve timed calls. That exceeds a 24/30 fps source
interval, so it validates the diagnostic CPU session only; see the
[CPU probe evidence](../../../docs/plezyng/evidence/linux-cpu-probe-2026-10-28.md).

The optional runtime probe can run the explicit CPU session without loading an
accelerator manifest. Pass `-` for the manifest and add `--cpu-only`; it reports
CPU execution separately from an accelerator session that used its opted-in
CPU fallback:

```sh
plezy_motion_runtime_probe \
  /path/to/libonnxruntime.so \
  - \
  /path/to/anvil-s-540p.onnx \
  CPUExecutionProvider 3 12 --cpu-only
```

Build and stage the local Linux AMD diagnostic with:

```sh
cmake -S shared/cpp/plezy_motion_engine -B build/pme-amd \
  -DCMAKE_INSTALL_PREFIX="$PWD/build/pme-amd/stage" \
  -DPLEZY_ORT_LINUX_VARIANT=amd-migraphx \
  -DPME_BUILD_RUNTIME_PROBE=ON
cmake --build build/pme-amd --target plezy_motion_runtime_probe
cmake --install build/pme-amd --component Runtime
cmake --install build/pme-amd --component DevTools
ROCR_VISIBLE_DEVICES=1 \
LD_LIBRARY_PATH="$PWD/build/pme-amd/stage/lib:/opt/rocm-7.2.1/lib:/opt/rocm-7.2.1/lib/migraphx/lib:/opt/rocm/lib" \
  "$PWD/build/pme-amd/stage/bin/plezy_motion_runtime_probe" \
  "$PWD/build/pme-amd/stage/lib/libonnxruntime.so" \
  "$PWD/build/pme-amd/stage/lib/providers.linux.tsv" \
  /path/to/anvil-s-1080p.onnx MIGraphXExecutionProvider 3 12
```

Set `ROCR_VISIBLE_DEVICES` to the selected host ROCm index only for this
process. On `kspld0`, host index `1` is the RX 7900 XT. The playback
qualification container exposes only that card, so it is index `0` inside the
container; it mounts only `/dev/dri/renderD129` for Vulkan. The diagnostic checks
the visible GPU before it reports the selected provider.

Linux runtime discovery checks `PLEZY_PME_RUNTIME_DIR` before the app bundle.
That directory must contain `libplezy_motion_engine.so`, `libonnxruntime.so`,
and `providers.linux.tsv`, plus any provider plug-ins named by the manifest.
For AMD's built-in MIGraphX provider, the Linux `amd-migraphx` CMake variant
stages the matching ORT runtime and provider libraries from the verified ROCm
7.2.1 wheel. The target system must provide ROCm 7.2.1 and MIGraphX runtime
dependencies; the app does not bundle that system stack. To reserve a
particular AMD GPU for a development process, set `ROCR_VISIBLE_DEVICES` only
on that process when launching PlezyNG. ROCm then numbers the visible device
set inside the process; MIGraphX's device `0` means the first visible GPU, not
necessarily host GPU 0.

Build the library with `ONNXRUNTIME_ROOT` pointing at an SDK whose C API is at
least version 27 and `PME_ORT_RUNTIME_LIBRARY` pointing at the runtime to stage.
When the Linux runner has no SDK override, CMake downloads the official ONNX
Runtime 1.27.1 package for Linux x64 or ARM64 and verifies its SHA-256. AMD
packagers can select the reproducible x86_64 AMD bundle with
`-DPLEZY_ORT_LINUX_VARIANT=amd-migraphx`. CMake keeps the v27 SDK headers,
downloads and verifies AMD's ROCm 7.2.1 ORT 1.23.2 wheel, extracts only the ORT
runtime, MIGraphX provider libraries, and notices, then installs a manifest
that selects only built-in MIGraphX. This mode needs Python 3 at configure
time for selective wheel extraction. The PME API-v23 compatibility path is
restricted to that provider. The default `cpu` variant continues to bundle the
official ORT 1.27.1 CPU runtime. CMake installs the runtime as
`libonnxruntime.so` beside `libplezy_motion_engine.so` on Linux, preserves the
versioned `libonnxruntime.so.*` targets behind its SONAME links, and stages
`libonnxruntime_providers_shared.so` so the runtime and provider-loader symbols
are present in the app bundle. It also stages the matching ORT license and
third-party notices. It can stage provider libraries through
`PME_PROVIDER_LIBRARIES` and their non-ORT dependencies through
`PME_PROVIDER_DEPENDENCY_LIBRARIES`. The platform TSV files list registration
names, required device kinds, and plugin paths or provider markers (`builtin`,
`builtin-migraphx`, `builtin-dml`, `builtin-vitisai`, and `windows-ml`) in
selection order. Relative plugin paths resolve from the manifest's directory.

The Windows app pins and extracts the Windows ML NuGet package during CMake
configuration, then stages its runtime, PME, provider manifest, package license,
and package third-party notices beside the Flutter executable. A pre-extracted
package can be supplied through `PLEZY_WINML_PACKAGE_ROOT` for build workers
that stage dependencies separately. Its catalog-backed vendor providers are downloaded and
updated by Windows ML, subject to device, OS, and driver support. The catalog is available on compatible Windows 11 24H2-or-later devices; an unavailable provider falls through to the next manifest entry. Catalog EPs have vendor-specific terms listed in Microsoft's Windows ML third-party notices. The Android LiteRT and QNN paths are independent of this desktop runtime. The mpv filter
adapter and Windows/Linux patch series load this ABI and publish the provider
that actually ran.
