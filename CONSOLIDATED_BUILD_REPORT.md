# Plezy GKUI consolidated build report

Build date: 2026-09-28. Branch: `gkui/api19-implementation`. Historical source base: Plezy 1.8.1 (`10d4b3088f009c8c61e1fe1024e3ae99cf147113`). M0 physical evidence supplied by the user confirms install, launch, Flutter rendering, touch navigation, API 19 and ARMv7 on ECARX XE1115H.

## Deliverable

- APK: `build/gkui/Plezy-GKUI-1.0.0-api19-armeabi-v7a.apk`
- SHA-256: `cad5705348224539872537805add0e8fe910ac0a3e5db262cc4c6f4a1d36c724`
- Size: 14,402,072 bytes
- Package/version: `com.jialim.plezygkui`, 1.0.0 (2)
- Min/target/compile SDK: 19 / 34 / 34
- ABI: armeabi-v7a only
- Signature: v1 true, v2 true; same M0 test signer, certificate SHA-256 `b55f4d2caa2ac2953a75a58ab9ab6ae731434734bf1a775a6e7c73558c58fab4`
- DEX: `classes.dex` and `classes2.dex`; AndroidX multidex bootstrap installed before Flutter starts

## Included end-to-end path

- Plex PIN/QR sign-in with persistent private app storage and sign-out token deletion.
- HTTPS-only Plex resource discovery, multiple-server selection and preferred secure route probing.
- Home hubs, Plex libraries, movie/show/season/episode traversal, poster/details views and pull-to-refresh.
- Token-bearing image requests through headers rather than image URLs.
- Direct playback through native ExoPlayer 2.19.1; automatic fallback to H.264/AAC-oriented 720p 3 Mbps HLS, then 480p 1.5 Mbps HLS.
- Resume from Plex `viewOffset`, 10-second timeline updates during playback and final paused/stopped progress.
- Native audio focus, immersive landscape controls and ExoPlayer track/subtitle selector.
- Bounded redacted on-device logs and copyable device/build diagnostics.
- Explicit invalid-clock screen. The supplied device evidence reported 1 January 2000; the app will not weaken TLS and asks for Wi-Fi/4G clock synchronization before sign-in.

## API 19 and memory handling

- The ECARX unit reports a 64 MiB normal app heap. Flutter's decoded image cache is capped at 16 MiB/48 entries, poster decode width is bounded, and ExoPlayer is configured with a 12 MiB target buffer and short time windows.
- Dart and native player HTTPS both combine system roots with bundled DigiCert Global Root G2, GTS Root R4 and ISRG Root X1. Normal certificate-chain and hostname validation remain enabled; no trust-all or plaintext fallback exists.
- ExoPlayer's optional adapter is resolved with OkHttp 3.12.13 only. Its upstream API-21 manifest declaration is narrowly overridden because the default OkHttp 4 runtime was excluded; the resolved release dependency tree was inspected.

## Verification completed off-car

- `flutter analyze lib/main_gkui.dart lib/gkui`: clean.
- Seven Flutter tests pass, including sign-in at 800x480 and 1280x720, QR layout at 800x480, authenticated Home/Library/Status navigation at 800x480, secret redaction and bounded-log eviction.
- Android `lintRelease`: passes. Remaining warnings are expected for the deliberate ARMv7/landscape/API19 target and retained raster resources.
- Resolved runtime contains ExoPlayer 2.19.1 and OkHttp 3.12.13, not OkHttp 4.
- APK inspection confirms API 19, normal launcher, ARMv7-only native libraries, bundled CA roots and v1/v2 signing.

## Single physical acceptance visit

This build deliberately combines the remaining gates. During one visit: connect Wi-Fi/4G and confirm the date is current; install over M0; scan the QR; open Home and one library; play one ordinary H.264 title and one title that needs fallback; open audio/subtitle controls; exit and confirm resume; then perform one sleep/wake cycle. If a step fails, copy the Status log or photograph it so the failure can be corrected without repeating every earlier gate.

Physical-only unknowns remain the XE1115H hardware decoder behavior, its TLS/provider implementation, actual Plex Media Server entitlement/transcoder output, and sleep/wake lifecycle. These cannot be truthfully certified by a desktop build or widget test.
