# Native FEL ports

This work reuses the pinned FFmpeg splitter, mpv layer pairing and libplacebo
residual reconstruction from the Linux experiment. It does not yet provide
qualified FEL playback on every platform. Output conversion to HDR10/SDR and
native Dolby Vision display signaling are separate capabilities.

## Status

| Platform | Available preparation | Remaining port work |
| --- | --- | --- |
| Linux x86-64/ARM64 | Existing isolated GL engine and embedded renderer; new runtime engine identity probe | Production patch parity, full app and device qualification |
| Windows x86-64/ARM64 | Native MinGW D3D11 build recipe, DLL dependency closure, architecture/hash validation, standalone HDR/SDR launcher, explicit app CMake engine selection | Run native builds; reconcile production patches; test app lifecycle, output and FEL pixels on both architectures |
| macOS | Existing pinned VideoToolbox/Metal research host | Production player adapter and device qualification |
| iOS/iPadOS and tvOS | Same host, now with automated unsigned device-SDK build selection and locked resolution | Build with Xcode, sign/install on devices, then production adapter and lifecycle/PiP/output tests |
| Android/Android TV/Fire TV | Production patch-series audit against the shared FEL sources | Rebase Android patches, rebuild the AAR and its JNI/FFmpeg consumers together, implement and test GPU routing |
| webOS | Existing compatibility playback | Obtain an app-accessible decoded BL/EL path and adequate GPU API; the current native path exposes no portable FEL compositor |

The source audit is a prerequisite, not an Android port. The Apple host is a
separate application, not a replacement production player. No platform receives
a full-FEL capability claim from a successful build or a DV badge.

## Windows build and run

Use Python 3.11+ from a native MSYS2 UCRT64 (x86-64) or CLANGARM64 shell.
The environment must supply Git, Bash, Make, Meson, Ninja, pkg-config, a native
MinGW C/C++ compiler, objdump, cygpath, shaderc, SPIRV-Cross and the mpv/libplacebo
development dependencies. Missing dependencies fail the build. The toolchain
packages are recorded, not claimed to be a reproducible SDK pin.

```sh
python tools/dv-engine/build_windows.py --work-dir C:/dv-work/windows --jobs 4
```

Use a new empty directory. The script verifies source commits and submodules,
applies the pairing/composer failure checks, builds D3D11, runs upstream tests,
and probes the *loaded* libmpv's `plezyng-dv-engine` identity. A failed step stops
packaging. The report still says pixels and physical output are untested.

The ZIP contains the engine, standalone executables, import library/headers,
recursive runtime DLL dependencies, source archives, integration sources,
toolchain notices, provenance and a file-hash manifest. PE architecture checks
cover both DLLs and executables. Keep the ZIP's separately emitted SHA256.
Development packaging is not a release license audit: review the recorded
toolchain runtimes and corresponding-source obligations before distribution.

After extracting to a separate directory on a matching Windows architecture:

```sh
python C:/dv-engine/run_windows.py --target sdr -- C:/media/fel.mkv
python C:/dv-engine/run_windows.py --target hdr10 -- C:/media/fel.mkv
```

`auto` lets the graphics context choose output. Explicit `hdr10` requires a
working HDR output. The qualification launcher uses software decoding and
D3D11, preserves source RPU/EL, and rejects options that override its controlled
rendering path. It validates the bundle before launching. Neither HDR nor SDR
requires a precomputed per-movie LUT; the source's own reconstruction metadata
is still needed.

### App integration

The Windows app already embeds `vo=gpu-next`. Its CMake build now accepts:

```text
-DPLEZYNG_DV_ENGINE_ARCHIVE=C:/dv-work/windows/plezyng-dv-windows-x86_64.zip
-DPLEZYNG_DV_ENGINE_SHA256=<the-64-digit-ZIP-hash>
```

Pass these to the app's Windows CMake configure in a **fresh, separate build
directory** with the normal Flutter-generated files/toolchain. CMake checks the
archive hash, manifest, source pins and binary architecture; a partial override
is an error. The normal build still uses `mpv-build.lock.json`. All validated
runtime DLLs are installed with the app and copied for native contract tests.
Sources, notices and reports accompany an experimental app install.

Do not copy the DLL into an existing production installation. Production patch
parity is currently false. Start app qualification with hardware decoding off,
then test each hardware/copy path independently. Record the actual renderer,
both layers, composer execution, seek/flush behavior, subtitles and A/V sync.

## Apple device builds

On a Mac with the required Xcode/Swift SDK and XcodeGen:

```sh
python3 tools/dv-engine/build_adapters.py --component apple \
  --apple-platform all --work-dir build/dv-apple-all --build --test
```

Selections are `macos`, `ios`, `tvos`, or `all`; the default remains `macos`.
iOS/tvOS use generic **device** destinations, separate derived-data directories,
disabled signing and pinned package resolution. No account, provisioning
profile, installation or distribution is performed. A completed SDK build is
recorded separately from playback. If a later SDK fails, earlier completed
results remain in `adapter-report.json`.

Production Apple integration cannot simply change `vo=avfoundation` to
`gpu-next`: the current client passes an `AVSampleBufferDisplayLayer`, whereas
the existing upstream MoltenVK example uses a Metal surface. Surface ownership,
resizing, EDR/HDMI negotiation and PiP need an explicit adapter. The existing
VideoToolbox/Metal research host remains the executable experiment meanwhile.

## Preserve production patches across native ports

```sh
python3 tools/dv-engine/audit_native_ports.py \
  --platform all --work-dir build/dv-native-audit
```

This fetches the production build repository at the application's exact lock
commit and the experimental engine's exact source commits. Independent worktrees
receive the FEL integration followed by each component's ordered common and
platform patches. Android, Apple, Linux and Windows are audited independently.
The first conflicting patch stops that component, preserves its tree for
rebasing, and records the unapplied remainder. Conflicts produce a nonzero exit;
there is no automatic patch skipping or fabricated parity result. Worktrees
are for the patch audit, not complete build staging (submodules are fetched in
the pristine source checkouts). Nothing changes the release pins.

Android specifically shares FFmpeg between libmpv and Media3. The production
bridge currently builds against FFmpeg 8.0.1 headers, while the FEL engine uses
a different FFmpeg commit. A port must align headers, shared-library ABI,
all packaged ABIs, JNI glue and production MediaCodec/surface patches together.
An arbitrary replacement AAR is not enabled by this change.

webOS is not represented as a fictional mpv-build platform. Native HEVC/DV
playback support alone does not expose decoded EL frames or GPU composition to
the client. A model-specific accessible path must be demonstrated before a
portable adapter can be implemented or advertised.

## Checks and limits

Local validation for this change: 52 Python contract tests; all pinned mpv
patch replacement anchors matched; the existing C pairing test passed all 11
cases. Those checks do not compile the Windows engine or the Apple host.
No Windows SDK/MSYS2, Xcode, Android native build or physical output trial was
available in this execution environment. The source-stack network audit has
not been run here. Native compilation, production patch rebasing and device
evidence remain required before enabling these paths for ordinary users.
