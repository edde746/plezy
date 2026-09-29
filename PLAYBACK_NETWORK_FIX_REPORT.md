# Plezy GKUI 1.0.1 playback network fix

> Superseded for Plex certificate compatibility by version 1.0.2; see
> `PLEX_CERTIFICATE_CHAIN_FIX_REPORT.md`.

Date: 2026-09-28. Supersedes the playback claims in the 1.0.0 consolidated report.

## Evidence and diagnosis

The user's Status photograph shows successful Plex Home loading followed by
`ERROR_CODE_IO_NETWORK_CONNECTION_FAILED: Source error` for direct play, 3000 kbps
HLS, and 1500 kbps HLS. This establishes a native player connection failure, not a
confirmed decoder or resolution failure. A file stored locally on the Plex server
still travels over the network to the head unit. The photograph's clock is now
correct; the earlier January 2000 clock is not evidence for this failure.

A concrete TLS configuration defect was found: the custom trust-store client
supplied an SSLContext("TLS") socket factory, bypassing OkHttp 3.12.13's API 16-21
TLSv1.2 context workaround. ConnectionSpec only intersects enabled protocols; it
does not enable supported-but-disabled TLS 1.2. This is a strong candidate for the
observed connection error, but the old flattened log cannot establish the exact
underlying exception. The XE1115H failure has not been reproduced off-car.

Source references:

- https://github.com/square/okhttp/blob/parent-3.12.13/okhttp/src/main/java/okhttp3/internal/platform/AndroidPlatform.java
- https://github.com/square/okhttp/blob/parent-3.12.13/okhttp/src/main/java/okhttp3/ConnectionSpec.java

## Changes

- Native HTTPS explicitly selects TLSv1.2 and enables TLS 1.2/1.3 on provider
  sockets before OkHttp applies its connection spec. Certificate-chain and
  hostname verification remain enabled; no plaintext or trust-all fallback.
- Bounded connection diagnostics capture DNS progress, TLS negotiation, HTTP
  response codes, and nested exception class names, without URLs, tokens,
  headers, IPs, server names, or exception messages.
- Visible buffering indicator and a 45-second first-frame timeout replace
  indefinite silent startup. A persistent failure dialog points to Status.
- Network/HTTP/initialization/timeout failures no longer automatically retry
  lower resolutions. Decoder/source failures retain the existing fallback.
- Failed starts no longer send a final zero-position progress update.
- HLS fallback explicitly requests MPEG-TS/H.264/AAC, at most two audio channels,
  with direct stream copying disabled, using the profile DSL retained in upstream
  commit c10cf55f. Bitrate/resolution requests remain 3000 kbps/1280x720 and
  1500 kbps/720x480. Actual server output and AAC profile remain unverified.

## Deliverable

- `build/gkui/Plezy-GKUI-1.0.1-api19-armeabi-v7a.apk`
- Package `com.jialim.plezygkui`, version 1.0.1 (3), min SDK 19, target SDK 34.
- ARMv7 only; 14,435,405 bytes; two DEX files; bundled CA roots present.
- SHA-256: `5128392c785418ae77c599a7ad2b83fc2f5027d0d256d370057f7b04e3dd03e7`
- Verified v1 and v2 signatures. Same signer as M0/1.0.0, certificate SHA-256:
  `b55f4d2caa2ac2953a75a58ab9ab6ae731434734bf1a775a6e7c73558c58fab4`.
- Install as an update over the existing application; do not uninstall first.

## Verification and limits

- Flutter static analysis: no issues.
- Ten Flutter tests pass, including three new playback-request tests for direct
  play and both safe presets. These inspect requests; they do not run a server.
- Three native JUnit tests pass: all six socket-creation overloads enable modern
  TLS despite simulated legacy defaults while preserving provider sockets;
  nested network exception classification/redaction; bounded diagnostic storage.
- Android release lint: zero errors, ten warnings.
- Signed release build and APK identity/signature/ABI inspection pass.
- No connected head unit, API19 emulator, or authenticated Plex playback test
  was available. JVM tests do not reproduce the actual Android TLS provider.
  Hardware decode, actual server transcode output, resume, and sleep/wake are
  not certified by this update. Do not label this fully working on the car yet.

For the next parked-car check, update and retry the same episode once. If it
fails, preserve the new dialog and Status diagnostics, which should identify the
connection stage instead of repeating three indistinguishable resolution tests.
