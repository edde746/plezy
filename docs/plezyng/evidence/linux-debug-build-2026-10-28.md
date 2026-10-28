# Linux debug bundle evidence

**Date:** 2026-10-28
**Host:** `kspld0`
**Build:** Flutter Linux x64 debug, CPU-only

## Build

Command:

```sh
nice -n 10 env CUDA_VISIBLE_DEVICES= HIP_VISIBLE_DEVICES= ROCR_VISIBLE_DEVICES= flutter build linux --debug
```

Result: **built successfully**.

- Bundle: `build/linux/x64/debug/bundle`
- Bundle size: 407 MiB
- Executable: `build/linux/x64/debug/bundle/plezy`
- Executable SHA-256: `a72d82c844d82bdfd291cd7e25f47a30ecbd300c412eab8c363710821fa583f4`
- PME library SHA-256: `a06e102ca75801f3ed7692c82529f6d1bba750599b51eada84032b70091c39d4`

## Packaged motion runtime

The bundle contains the ONNX Runtime 1.27.1 library and its complete SONAME
chain:

```text
libonnxruntime.so -> libonnxruntime.so.1
libonnxruntime.so.1 -> libonnxruntime.so.1.27.1
```

`readlink -e` resolved the chain to `libonnxruntime.so.1.27.1`. The bundle
also contains `libonnxruntime_providers_shared.so` and the Flutter asset
`data/flutter_assets/assets/motion_models/anvil-s-540p.onnx` (3,431,923 bytes).
`ldd` on the PME shared library reported no unresolved shared-library
dependencies.

The model and native runtime were packaged; this check did not run inference
or verify visible presentation, A/V sync, model quality, or hardware-provider
selection. The build disabled CUDA and ROCm device visibility. Desktop neural
qualification remains limited to the RX 7900 XT, and this build did not use
either desktop GPU. The RX 9070 XT remains reserved for normal desktop use.
