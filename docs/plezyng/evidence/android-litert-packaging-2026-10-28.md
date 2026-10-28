# Android LiteRT model-packaging build evidence

**Date:** 2026-10-28
**Host:** `kspld0`
**Build:** Android debug APK with embedded Moonlight and Steam modules

## Updated eight-model APK verification

The debug APK was rebuilt after the W8A8 candidates were added to the LiteRT
manifest. Both Gradle output paths contain the same 526,471,987-byte APK with
SHA-256 `e12dbc651f37234180d457bb2800afe3934d3d590f757dc5ffc699d2152f2c84`:

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/apk/debug/app-debug.apk`

The embedded `assets/litert/models/manifest.json` is byte-identical to
`assets/motion_models/litert/manifest.json`. All eight packaged model files
match their manifest sizes and SHA-256 values: four float32 GPU packs total
28,344,192 bytes, and four generic W8A8 JIT NPU candidates total 7,574,992
bytes, for 35,919,184 model bytes. Exact per-model hashes remain in the
checked-in manifest. No target-specific Google Tensor, Samsung LiteCore, or
Qualcomm HTP AOT artifacts are included.

This verifies Gradle packaging and asset integrity. The APK was not installed;
provider execution, Android inference latency, visible quality, presentation
pacing, and audio/video synchronization remain unqualified.

## Original four-model pack

The four float32 GPU packs were generated locally with
`scripts/motion/export_android_litert_models.py`, using the ANVIL source
revision `f701fd9b01b9fbb20822637b5d82cac626079e5f`, checkpoint revision
`fa97e30f6aabe897bd4f6f82d971ad607f5d61fa`, LiteRT-Torch 0.10.0, and the
official CPU-only PyTorch wheel 2.14.1. The exporter checked the pinned
checkpoint sizes and SHA-256 values. The committed manifest records the
converter, PyTorch, source, and weight revisions.

| Model | Size | SHA-256 |
| --- | ---: | --- |
| ANVIL-S 720p | 3,463,620 bytes | `277dee4a7de7dc23c305d712a9b6ba2b6b78d19f13a340a5736fd19e5aa03f05` |
| ANVIL-S 1080p | 3,464,752 bytes | `f68a76b0bdd8811751db89d9b1011aba44a0de94c303515bbadfb95ba9a60a4e` |
| ANVIL-M 720p | 10,708,008 bytes | `8535a880ad5d110fe9c2fe1c880976d2ea91d45dd2cad5041ff6fe2c0b9fa4ef` |
| ANVIL-M 1080p | 10,709,180 bytes | `8cc64b43cee3573458ea39b55bc2265a27cee1df2c1e2a401633c5eedd429fc4` |

The recorded APK build used the then-current four-model float32 manifest.
Gradle verifies each manifest size and hash before staging; the native Android
loader repeats the integrity check when it copies a selected model into
app-private storage. The current source manifest has since grown to eight
models: these four float32 GPU variants plus four W8A8 generic NPU candidates.
The APK hash and size below do not verify packaging of those later W8A8 files.
Their single-clip comparison is recorded separately in
[`android-litert-w8a8-validation-2026-10-28.md`](android-litert-w8a8-validation-2026-10-28.md).
No vendor-specific AOT models are included in the current default manifest.

## Original four-model APK build

Command:

```sh
nice -n 10 ./gradlew :app:assembleDebug --no-daemon --max-workers=4
```

Result: **BUILD SUCCESSFUL**, with Moonlight and Steam included. The APK
contains the four LiteRT float32 models from the manifest at that build's
source revision and one merged Bouncy Castle license notice. The package was
inspected and each included model's size and SHA-256 matched its manifest
entry.

- Artifact: `build/app/outputs/apk/debug/app-debug.apk`
- Size: 531,426,214 bytes
- SHA-256: `89ddd44db5cd921ecc0a01d404a896095db1c5f209f63bbba67941fe1307d98a`

The APK was not installed. This historical build verifies source compilation
and packaging of the four then-current float32 models, not the current
eight-model manifest, provider execution, inference latency, visual quality,
display pacing, or audio/video synchronization on an Android device.

## GPU selection

The model export used CPU-only PyTorch; Gradle compilation and APK packaging
used no desktop GPU. Desktop PME qualification remains isolated to the RX 7900
XT as recorded in
[`rx7900xt-2026-10-28/qualification.md`](rx7900xt-2026-10-28/qualification.md).
The RX 9070 XT is the desktop's normal-use GPU and is excluded from those
qualification results.
