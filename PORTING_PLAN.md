# Plezy GKUI porting plan

Audit date: 2026-09-28. Status: **CONDITIONAL GO**. This commit contains planning only; no application port, dependency replacement in the application, workflow, or APK has been produced.

Start implementation from **Plezy `1.8.1`, commit `10d4b3088f009c8c61e1fe1024e3ae99cf147113`**. Retain its Flutter UI, Plex models, browsing, authentication and reporting. Use **Flutter 3.19.6 / Dart 3.3.4**. Plan an Android-only adapter using **legacy ExoPlayer `com.google.android.exoplayer:2.19.1`**. Keep a media-kit experiment optional: the inspected prebuilt mpv stack is not an API-19 solution.

Read [DEPENDENCY_MATRIX.md](DEPENDENCY_MATRIX.md) for package pins and limits, [BACKPORT_CANDIDATES.md](BACKPORT_CANDIDATES.md) for implementation commits, [RISKS_AND_GATES.md](RISKS_AND_GATES.md) for acceptance experiments, and [IMPLEMENTATION_HANDOFF.md](IMPLEMENTATION_HANDOFF.md) for the next agent's first actions.

## Scope and evidence boundary

Target: original Proton X70 GKUI 4.0.3 / IC4, Android 4.4/API 19, 32-bit ARM, ordinary USB-installed standalone APK, v1/JAR signing, no ADB and no root. Use a normal `MAIN`/`LAUNCHER` activity. Android Auto, mirroring, Android Automotive, `CAR_LAUNCHER`, and parked-app APIs are outside this design.

Accept the user's physical observations: modern Plex 9.23.0.1746 and current Plezy ARMv7 APKs fail package parsing; Plex 6.17.1.5294 installs and launches but fails contacting plex.tv. This establishes that the installer works. It does **not** identify the exact parse failure or prove the old Plex error was TLS. Obtain those answers through the new app's own diagnostics.

Repository state audited:

- Origin: `https://github.com/jialim/plezy-gkui.git`.
- Upstream: `https://github.com/edde746/plezy.git`, fetched with tags.
- Planning branch: `planning/api19-gkui`, created from the cloned fork's main, leaving main unchanged.
- Upstream snapshot: `a2f85f9b17cdfec8fd5570ecc300b460782c8549` (2026-09-27).
- Latest available release inspected: `2.21.0`; newer untagged fixes are explicitly marked in the backport document. Do not treat an untagged commit as a released fix.
- Local probes: Flutter reports 3.19.6 and Dart 3.3.4; 145 base Dart files parse using `dart format --output=none`; an isolated historical dependency set resolves; an unchanged source copy was analyzed; ARM ELF files and public Plex TLS handshakes were inspected. No Android assembly, GKUI execution, authenticated Plex session, or PMS stream was tested.

## Why 1.8.1

All eight required base tags were inspected through their pubspec, Android configuration, release notes and relevant commit diffs. Even `1.0.0` declares Dart `^3.8.1`; choosing an earlier Plezy release does not itself remove the language/toolchain downgrade.

| Tag / commit | Material differences | Decision |
| --- | --- | --- |
| `1.0.0` / `d31d6c71bc992d55fedd7ebf2bc9d5f13b0935a0` | Early Plex/UI foundation and media-kit; modern Dart constraint already present | Too many missing Plex and UX fixes; no inherent API-19 benefit |
| `1.5.1` / `e047c820aeb99dfb9d3f586cbb2154645e096155` | Malformed UTF-8 handling already present; synthesizes HTTP alternatives to HTTPS PMS connections | Useful history, but HTTP behavior needs tightening |
| `1.6.1` / `d3a35d56d90e7c5d1f0708ebe73420426bc009c0` | QR sign-in, partial library loading, external subtitles, seek throttling; PGS/TrueHD through media-kit dependency changes | Good functionality, superseded by later connection/profile fixes |
| `1.7.0` / `12c0d650031e39823566a0545337585a673644ee` | Connection race, endpoint failover, connectivity monitoring; playlists/library improvements; revised native mpv | Useful network structure retained in 1.8.1 |
| `1.7.1` / `adbf12643036178ece96ba40511a956bb460b1d1` | Subtitle crop / macOS playback corrections | No special legacy Android advantage |
| `1.8.0` / `8d0d220d786df77f61d36907c0284158b5014738` | Unified servers, actual HTTPS URI candidates, Android resume dependency fix | Almost suitable, but misses 1.8.1 profile fix |
| **`1.8.1` / `10d4b3088f009c8c61e1fe1024e3ae99cf147113`** | Profile switching and mobile controls fixes; last release before custom platform player rewrite | **Selected source base** |
| `1.9.0` / `dc01c5af2f7991f25d56147acef0d69a3b2ca871` | Removes media-kit; introduces `lib/mpv/` and platform implementations; Android `dev.jdtech.mpv:libmpv:0.5.1`, explicit minSdk 26 | Use selected Dart fixes only; not the Android base |

Evidence: [1.8.1 manifest](https://github.com/edde746/plezy/blob/1.8.1/pubspec.yaml), [1.8.1 lockfile](https://github.com/edde746/plezy/blob/1.8.1/pubspec.lock), [1.9 transition](https://github.com/edde746/plezy/compare/1.8.1...1.9.0), [Android transition commit e0fd77d7](https://github.com/edde746/plezy/commit/e0fd77d7de9cfd40eaa10c4e9849a0b3c9859feb), [release 1.9.0](https://github.com/edde746/plezy/releases/tag/1.9.0). The transition changes 181 files, so wholesale merging would import substantial unrelated work. The decision for 1.8.1 remains useful even if its player must be replaced: the retained application surface is smaller and its Plex UX already covers the target.

## Toolchain

Flutter's [KitKat deprecation notice](https://docs.flutter.dev/release/breaking-changes/android-kitkat-deprecation) places the removal at stable 3.22. The last stable 3.19 patch is **3.19.6**; this audit checked out and ran that SDK. Pre-release snapshots between stable releases are not production candidates.

| Component | Implementation pin | Evidence / reason |
| --- | --- | --- |
| Flutter | `3.19.6`, framework `54e66469a933b60ddf175f858f82eaeb97e48c8d` | Last stable family with API 19; version command verified |
| Engine | `c4cd48e186460b32d44585ce3c103271ab676355` | Flutter's `bin/internal/engine.version` |
| Dart | `3.3.4`, SDK source `d70d99a911b3316ca0d442caaf24fe57afe59893` | Engine DEPS and SDK `tools/VERSION`; runtime verified |
| JDK | Temurin `17.0.10+7` baseline | Locally available and verified; AGP 8.3 requires JDK 17. Pin distribution and patch in CI; review JDK patch updates separately |
| Gradle | `8.4` | Required/default for AGP 8.3 |
| Android Gradle Plugin | `8.3.2` | April 2024 patch, supports compile SDK 34 |
| Kotlin plugin | `1.9.22` | Conservative same-era compiler; do not carry base Kotlin 2.1.0. Full Android assembly remains Gate C |
| compile SDK / build tools | `34` / `34.0.0` | AGP 8.3 documented pair; compile API does not set device minimum |
| min / target SDK | **19** / `34` | Explicit min 19. Target 34 does not require device API 34; audit code and resources separately |
| NDK | `23.1.7779620` if requested by Flutter or a retained native plugin | Flutter 3.19.6 template default. No custom NDK compilation is required for Java ExoPlayer; do not substitute r26+ for an API-19 native rebuild |
| Java/Kotlin application bytecode | Java 8 / JVM 1.8 where practical | D8 desugars language bytecode; Java library APIs still require availability checks. Some retained plugins compile Java 17 under AGP 8.3 |

The Flutter 3.19.6 template itself pins Gradle 7.6.3, AGP 7.3.0, Kotlin 1.7.10, min 19 and compile 34. Those are **reference defaults, not the selected complete app tuple**: `connectivity_plus 6.1.5` and `package_info_plus 8.0.2` use AGP 8.3.1/Java 17. Select one coherent AGP 8.3.2/Gradle 8.4/JDK 17 build, with compatible plugin versions. Do not accidentally inherit the base's AGP 8.7.3 / Gradle 8.12 / Kotlin 2.1.0 or the media-kit fork's AGP 8.13.0 / SDK 36.

Sources: [Flutter constants](https://github.com/flutter/flutter/blob/3.19.6/packages/flutter_tools/lib/src/android/gradle_utils.dart), [engine DEPS](https://github.com/flutter/engine/blob/c4cd48e186460b32d44585ce3c103271ab676355/DEPS), [AGP 8.3 compatibility](https://developer.android.com/build/releases/agp-8-3-0-release-notes). This tuple is source-backed and package-solver-backed, **not yet Android-build-certified**. The first implementation gate must assemble it before adding product features.

## Dart and Flutter source compatibility

Base manifest: Dart `^3.8.1`. Base lockfile: Dart `>=3.9.2`, Flutter `>=3.35.0`. The pinned `os_media_controls` Git dependency itself declares Dart `^3.9.2`.

The non-writing Dart 3.3.4 formatter parsed all 145 `lib/**/*.dart` files, including generated translations. No post-3.3 syntax blocker was demonstrated in the base. This is a parser result, not proof of framework or plugin compatibility. Records, patterns and switch expressions do not require Dart 3.8.

Concrete analyzer/source findings and intended adaptations:

| Source use | Base locations (examples) | Adaptation |
| --- | --- | --- |
| `Color.withValues(alpha:)` | `screens/auth_screen.dart:419`, `screens/discover_screen.dart:732`, many controls/cards | `withOpacity` for these alpha-only calls; visual check rounding |
| `Color.r/g/b` normalized channels | `screens/subtitle_styling_screen.dart:151` | Use integer `.red/.green/.blue`; avoid retaining multiplication by 255 |
| `WidgetStateProperty(All)`, `WidgetState.selected` | `theme/mono_theme.dart:23,130` | `MaterialStateProperty(All)` / `MaterialState.selected` |
| `CardThemeData` | `theme/mono_theme.dart:91` | Flutter 3.19 `CardTheme` |
| `ColorScheme.surfaceContainerHighest` | detail/discover/season/library screens | Map deliberately to `surfaceVariant` / a Plezy theme token |
| New `ColorScheme` constructor fields | `theme/mono_theme.dart:35,53` | Supply required `background/onBackground`; replace unsupported `surfaceDim/surfaceBright` with explicit theme tokens |
| `RadioGroup` and implicit radio group wiring | `widgets/sort_bottom_sheet.dart:75,119` | Use 3.19 `RadioListTile(groupValue:, onChanged:)` with the same sort state |
| `PopupMenuButton.menuPadding` | `widgets/media_context_menu.dart:318` | Remove or reproduce padding in supported item/layout APIs; visual test |
| `PopScope.onPopInvokedWithResult` | `screens/video_player_screen.dart:924` | 3.19 `onPopInvoked`; preserve single exit and final progress semantics |
| Fork-only player configuration / track fields | `screens/video_player_screen.dart`, `services/track_selection_service.dart` | Do not assume public media-kit has Plezy fork APIs; map only required behavior to the new adapter |
| Imports of removed desktop/OS controls | main, settings, keyboard/titlebar/media-control services | Build-time facade/stub and no plugin dependency in GKUI manifest; runtime `Platform.is...` alone is insufficient |

`spacing:` occurrences in `Wrap` already work in 3.19; do not mechanically replace them as if all were modern `Row`/`Column.spacing`. Generated code should initially be retained; compatible generators are pinned in the matrix. Later backports can contain newer syntax, e.g. `{'X-Plex-Session-Identifier': ?sessionIdentifier}` in `19abd783`; express that using `if (sessionIdentifier != null)` under Dart 3.3.

Estimated effort: base syntax is low risk; framework substitutions are bounded UI maintenance; backend decoupling and asynchronous Plex behavior are the substantial source work. There is no evidence requiring a new native application.

## Playback decision

### What the media-kit investigation established

The base uses Git override `edde746/media-kit@dce2963936424ffc80309ef4bca7e95041dfbfef`: package versions media_kit 1.2.1, video 1.3.1, universal libs 1.0.7, Android libs 1.3.9. Its Android wrapper declares minSdk **16**, but downloads `edde746/libmpv-android-build/releases/download/7/full-armeabi-v7a.jar`. That source repository was not available during this audit; the exact fork binary's API target is **UNKNOWN**.

Public historical Android libs 1.0.0 and 1.1.1 also declare min 16. The latter refers to `media-kit/android-dependencies` v0.0.10; that repository is no longer available from the audited URL. A manifest alone cannot certify either payload. Public Android libs 1.3.8 points to native build v1.1.7. Both the earliest tag `v1.0.0` and v1.1.7's build family use `apilvl=21` for ARMv7. The actual v1.1.7 ARMv7 jar was downloaded and inspected:

| File | ELF | Android note | SHA-256 |
| --- | --- | --- | --- |
| `libmpv.so` | ELF32, machine 40 (ARM) | API 21, NDK r25c | `8aa2b23d16d941a8d685b8eb995b1cb31677ed3e28c55c776954eb1618ab1a2e` |
| `libmediakitandroidhelper.so` | ELF32, ARM | API 21, NDK r26b | `506d0bc7775fe9888be6b6e889d8556ca0574dba65813866e2158cbf52a8c8b1` |

The mpv binary imports `newlocale`, `uselocale`, `freelocale`, `strtof`, and other Bionic APIs; API-21 build notes and native imports must not be overridden by a minSdk manifest edit. Its ARMv7 ABI exists, but ABI existence does not establish API-19 compatibility. See [wrapper/fork source](https://github.com/edde746/media-kit/blob/dce2963936424ffc80309ef4bca7e95041dfbfef/libs/android/media_kit_libs_android_video/android/build.gradle), [native build script](https://github.com/media-kit/libmpv-android-video-build/blob/v1.1.7/buildscripts/build.sh), [earliest build tag](https://github.com/media-kit/libmpv-android-video-build/blob/v1.0.0/buildscripts/build.sh), [audited binary](https://github.com/media-kit/libmpv-android-video-build/releases/download/v1.1.7/default-armeabi-v7a.jar).

**A:** No retrievable, verified API-19 + ARMv7 media-kit/native combination was established. This is not a claim that every historical binary is impossible. **B:** The known available combination has native API-21 targets; the Plezy overrides also have Dart `web` transitive and modern build-tool requirements. **C:** A small legacy Java player adapter is the preferred engineering route. Rebuilding old mpv/FFmpeg/helper/renderer for API 19 would add NDK, POSIX/Bionic shims, codec and TLS work before the first video test. Time-box that alternative to artifact inspection plus one minimal load/render experiment if a genuine old binary is found.

### Player comparison

| Requirement | Legacy ExoPlayer 2.19.1 (preferred) | Android `MediaPlayer` (fallback) |
| --- | --- | --- |
| API/ABI | Source `constants.gradle` min 16; Java core/HLS/extractors use platform MediaCodec; ARMv7 does not require an FFmpeg extension | Platform API available before 19; uses vendor media stack |
| H.264/AAC | Hardware codec via MediaCodec; enumerate and test actual decoder/profile/level | Platform/vendor decoder; test same sample |
| MP3 | Supported through available platform decoder | Platform support; container combinations need tests |
| HLS / MP4 | Dedicated HLS and progressive extractors, configurable network data source | Platform HLS/MP4; older HLS implementation and vendor quirks |
| MKV | Matroska extractor; codec support is a separate condition | Android/OEM-dependent combinations; do not advertise general MKV support initially |
| Seeking | Millisecond API, VOD manifest/progressive support; validate Plex timestamps | API19 `seekTo(int)` asynchronous and commonly keyframe-limited |
| Subtitles | SRT/WebVTT/TTML and other Exo text renderers; begin SRT/WebVTT; burn PGS/complex ASS on PMS | Limited timed-text/subtitle support; do not count on full ASS/PGS; server burn safest |
| Audio tracks | Track selector; stable mapping from Plex stream IDs to player tracks | API16+ track APIs; vendor/container behavior varies |
| Memory | Configure buffer bytes and duration; no software video decoder extensions | Smaller client code footprint, opaque platform buffering |
| Integration | New MethodChannel/EventChannel + Flutter texture adapter; moderate work, explicit control | Similar bridge, fewer capabilities; more stream compatibility uncertainty |
| TLS | Exo `DataSource.Factory` can use API19-compatible OkHttp/Conscrypt and maintained roots | Network TLS lives in framework; Java provider replacement may not affect native fetches |

Sources: [ExoPlayer 2.19.1 constants](https://github.com/google/ExoPlayer/blob/r2.19.1/constants.gradle), [release](https://github.com/google/ExoPlayer/releases/tag/r2.19.1), [Android supported formats](https://developer.android.com/media/platform/supported-formats). Device decoder performance, surface behavior, and exact memory use remain hardware gates. Plezy 1.15's ExoPlayer implementation uses **Media3 1.5.1**, FFmpeg and libass extensions; it is design reference only, not a drop-in API-19 backend.

### Adapter contract and retained code

1. Introduce a narrow GKUI player interface with `open(url, headers, startPosition)`, play/pause/seek/stop/dispose, volume, track selection and streams for position/duration/buffering/error/end/tracks. Express positions in source milliseconds.
2. Native Android owns ExoPlayer, MediaCodec, Surface/Flutter texture, audio focus, bounded buffers and network source. Use core + HLS modules only initially. No Media3, FFmpeg audio, libass, mpv, PiP, refresh switching or background service.
3. Preserve Plezy controls and translate their inputs. Decouple `video_player_screen.dart`, playback initialization/progress, track selection, episode navigation, `player_utils.dart`, and controls, which currently import media-kit directly. 1.8.1 does **not** already have a clean backend-neutral abstraction.
4. Remove/stub dynamic mpv `setProperty` calls for filters, subtitle margins, audio delays and shaders. Unsupported settings must disappear from GKUI UI.
5. Use Flutter's external texture path first: API19 platform-view hosting is not a safe assumption. Release texture, Surface, player and subscriptions deterministically; pause on audio-focus loss/vehicle sleep. Use legacy AudioManager focus APIs available on API19.

## Networking, authentication and TLS

Keep Dio and the base Plex API/model code, adding a centralized validated client factory and explicit timeouts. Network reachability notifications are hints, not proof that PMS is available. Maintain separate account/profile tokens and per-resource PMS tokens.

Base authentication flow is already suitable for a phone-assisted sign-in:

1. Persist a random client identifier. POST `https://plex.tv/api/v2/pins?strong=true` with JSON accept, product and client identifier.
2. Display QR for `https://app.plex.tv/auth#?clientID=...&code=...&context[device][product]=...`. The phone runs the browser. Do not require a functional GKUI WebView or keyboard.
3. Poll `GET /api/v2/pins/{id}`, bounded by expiry/cancellation; acquire `authToken`. Base polls every second with two-minute overall budget but masks all errors as “not claimed”; expose network, expiry and authorization failure separately.
4. Validate `/api/v2/user`. Fetch `https://clients.plex.tv/api/v2/resources?includeHttps=1&includeRelay=1&includeIPv6=1`. Base uses `provides == 'server'`; make parsing tolerate comma-separated capabilities and partial invalid resources. Never log raw resource payloads containing access tokens.
5. Retain each resource's `accessToken`, `clientIdentifier`, and `local/relay/IPv6` connection flags. Do not replace a shared-server token with the account token.
6. Fetch `clients.plex.tv/api/v2/home/users`; require profile selection when appropriate; switch with `POST /home/users/{uuid}/switch` and optional PIN; refresh resources under the resulting profile token before binding clients. Cancel stale requests and discard old profile caches using a generation counter.
7. Prefer reachable validated HTTPS direct endpoints; use HTTPS relay when available and suitable. Verify server identity before failover. PMS's remote-access configuration must actually be reachable; the client cannot make a NAT-blocked server public. No VPN or manual LAN address is part of normal setup. Relay bandwidth/availability and account entitlement are server/service constraints to diagnose, not values to hardcode.

Base sources: [auth](https://github.com/edde746/plezy/blob/1.8.1/lib/services/plex_auth_service.dart), [storage](https://github.com/edde746/plezy/blob/1.8.1/lib/services/storage_service.dart), [profile provider](https://github.com/edde746/plezy/blob/1.8.1/lib/providers/user_profile_provider.dart), [multi-server manager](https://github.com/edde746/plezy/blob/1.8.1/lib/services/multi_server_manager.dart).

`Allow insecure connections` in release 1.5.1 means **HTTP PMS fallback generation**, implemented by `e4e79115`, not an “accept invalid certificate” switch. 1.8.1 still creates/probes HTTP candidates even when HTTPS exists. For GKUI remote use, remove plaintext authenticated candidates at candidate construction, cached endpoint loading, redirects and retry boundaries. HTTPS auth alone is insufficient if server tokens leak in HTTP probes. Port the restriction principles from untagged `7f45d8f9`; impose the stronger GKUI rule of authenticated HTTPS-only remote operation. Do not silently downgrade after a certificate error.

### TLS layers must be tested separately

- Dio on Android uses Dart `HttpClient`, hence Dart's native BoringSSL, not Android's Java `SSLSocket`. Dart 3.3.4 creates a TLS context with minimum TLS 1.2 and hostname/IP validation. Its Android implementation loads `/system/etc/security/cacerts` and does not bundle fallback roots.
- The audit host successfully validated **TLS 1.2** to both `plex.tv` and `clients.plex.tv`. plex.tv presented a DigiCert chain (leaf `*.plex.tv`, intermediate DigiCert Global G2 TLS RSA SHA256 2020 CA1, root DigiCert Global Root G2); clients.plex.tv presented a Google Trust Services WE1-issued chain. This proves host connectivity at the audit date, **not GKUI validation**; chains can rotate and GKUI's CA inventory is unknown. Do not bundle only the root observed at one host.
- Supply a reviewed, versioned current CA PEM asset if device roots fail: `SecurityContext(withTrustedRoots: true)` plus `setTrustedCertificatesBytes`, installed through `IOHttpClientAdapter(createHttpClient: ...)`. A stricter dedicated context using only the maintained bundle is also viable. Record bundle source, date, checksum and license; update through signed app releases. Validate hostname, dates and chain normally. Include device clock in diagnostics.
- Apply the same client factory to auth, PMS, endpoint probes, artwork, subtitle fetches and logs/export networking. Do not assume changing Dio affects cached-network-image or native playback.
- Native ExoPlayer has an `extension-okhttp:2.19.1` transport, but its default **OkHttp 4.11.0 is not API19-compatible**. Candidate: exclude it and resolve **OkHttp 3.12.13**, adding **Conscrypt Android 2.5.2** if needed. The substitution's binary/API behavior is **UNKNOWN** until a small data-source build/handshake/HLS probe; if it fails, implement a small API19 data source using that client. Conscrypt 2.5.2 source declares min 9 and ARMv7 JNI; it updates TLS, not the CA trust set. Build a real X509TrustManager from maintained roots and retain hostname verification. These are old compatibility fallbacks, not claimed current-security releases.
- Installing a Java security provider does not change Dart BoringSSL or mpv/FFmpeg TLS. If native Java transport must serve Dart, implement a bounded Dio adapter over MethodChannel for small API responses, cancellation and timeouts; stream media natively, never whole video buffers over a channel. Prefer Dart networking unless its actual device probe fails.

Sources: [Dart Android roots](https://github.com/dart-lang/sdk/blob/3.3.4/runtime/bin/security_context_android.cc), [TLS context](https://github.com/dart-lang/sdk/blob/3.3.4/runtime/bin/security_context.cc), [hostname checks](https://github.com/dart-lang/sdk/blob/3.3.4/runtime/bin/secure_socket_filter.cc), [Conscrypt build](https://github.com/google/conscrypt/blob/2.5.2/android/build.gradle), [Square's Android 4.x guidance](https://developer.squareup.com/blog/okhttp-3-13-requires-android-5/). Trust-all callbacks, invalid-certificate acceptance, hostname bypass and plaintext authentication are prohibited.

## Plex transcoding: minimal manual port

Release 1.35.0 introduces VOD transcoding in `c10cf55f2d47d84ae6bbb8944d55a296f32dbf14`. Its tagged VOD code uses `/video/:/transcode/universal/decision` then **`/video/:/transcode/universal/start.m3u8`**, HLS/MPEG-TS. The extensionless `/start` elsewhere in that tag belongs to Live TV. Separate these paths when reading the source.

Port only the quality model, Plex request/response parsing, playback result fields, settings and the necessary control plumbing. Adapt `PlexHttpClient` calls back to the centralized Dio service. Do not import downloads, database, multi-backend DTOs, Live TV or modern native players.

| GKUI preset | Video ceiling | Resolution ceiling | Initial behavior |
| --- | --- | --- | --- |
| Original | No user quality reduction | Still subject to actual decoder capability | Direct play only if conservative capability check passes; otherwise transcode or explain failure |
| 480p 1.5 Mbps | 1500 kbps | 720x480 | Recovery preset for weak decoder/network |
| 720p 2 Mbps | 2000 kbps | 1280x720 | Lower data use |
| **720p 3 Mbps** | **3000 kbps** | **1280x720** | Proposed default; hardware/network test required |
| 720p 4 Mbps | 4000 kbps | 1280x720 | Optional after baseline test |

Start with SDR 8-bit H.264, AAC-LC stereo output, <=30 fps, conservative H.264 profile/level supported by the reported hardware decoder. Allow MP3 direct play only in tested containers. Initial direct-play container: MP4; add H.264/AAC MKV only after Exo extractor/decoder tests. AC3 is disabled until demonstrated. Do not advertise HEVC, AV1, HDR, Dolby Vision, TrueHD or DTS-HD.

Required request contract:

- Stable install client ID, new logical playback `X-Plex-Session-Identifier`, separate transcode `session`, source ratingKey/mediaIndex/partIndex and selected stream IDs. Keep IDs consistent across decision/start/timeline for one session; end abandoned sessions. On a renegotiation that cannot reuse a session safely, stop it and create a new one explicitly.
- Construct `X-Plex-Client-Profile-Extra` with an HLS MPEG-TS **H.264/AAC-only** transcode target. 1.35's `h264%2Chevc` must be narrowed. Add explicit bitrate, dimensions, channels and codec/profile limits; inspect the actual returned stream to confirm PMS honors them. Merely defining `videoResolution` in an enum does not apply a limit: the original request builder primarily uses bitrate.
- Port strict profile-expression percent encoding with tests for `%2C`, `%`, parentheses and `+`; prevent accidental double-encoding through Dio query encoding. Use `Generic` as the recognized transcode platform/profile with explicit capabilities, then verify current PMS response.
- Match decision and start parameters: `hasMDE`, `path`, indexes, protocol, directPlay/directStream, bitrate/profile limits, audioStreamID, subtitles, session IDs and authentication. Set remote location deliberately (`wan` candidate) and verify current PMS semantics instead of inheriting `location=lan` unquestioningly.
- Classify direct play, direct stream, video/audio transcode and refusal from decision codes and returned media/part/stream decisions. Unknown/malformed responses must not authorize an unsupported source. 1.35 falls back to direct play on failure and accepts some unknown codes; GKUI must only do so if its own capability check passes.
- Header forwarding applies to media, HLS master/child playlists, segments, redirects, range requests and subtitles. Base media URLs already carry tokens in query strings; 1.13's missing-header fix does not mean 1.8 never authenticated. Prefer headers and redact any token-bearing URLs.
- Initially no subtitles; then real external SRT/WebVTT sidecars, fetched with the shared TLS policy. For embedded PGS/ASS or unsupported formats, use server burn. Follow 2.13 `f4ce6061`: select the requested subtitle on the part first, then request burn with direct play disabled. Do not download/demux the full original file merely for an embedded subtitle.
- Use source milliseconds for resume/reporting, `/:/timeline` every ~10s and on state changes, with the same playback session identifier (`19abd783`). Preserve full title duration. Avoid adding a transcode offset twice on ExoPlayer (`985c279b`). For HLS use one seek owner; start the full-title session and seek to the resume point after readiness. Do not also prewarm at offset T (`3a704a2b`). Validate long seeks and subtitle alignment on PMS/GKUI.
- Stop/cleanup via PMS's transcode-session stop endpoint when leaving/replacing playback; verify its accepted route/parameters against the tested PMS (`/video/:/transcode/universal/stop?session=...` candidate). Failures must not block exit. A start URL is consumed by the player, not downloaded as a whole by Dart.

Later upstream moved between streaming strategies; 2.10 HLS, 2.13 offset prewarming, and 2.14 removal of prewarming are documented in the backport list. Do not stack mutually superseding fixes. fMP4/HEVC-specific changes are unnecessary for the initial H.264/MPEG-TS target. PMS tone mapping, remote entitlements, transcoder availability and throughput are **UNKNOWN** until tested with the user's server; show a precise refusal instead of spinning or forcing local software decode.

## Memory, UI and feature isolation

The base reserves up to **500 MiB / 500 decoded images** in `main.dart:41`. This is an obvious risk for a 32-bit head unit. Start at **32 MiB / 100 decoded images**, modest 100–200 MiB private disk cache, 2–4 concurrent artwork transfers with header/body timeouts, and 8–16 MiB player target buffer. These are initial experiment settings, not measured GKUI limits. Record actual memory class and tune against M9. A single 1920x1080 RGBA image costs about 8 MiB before other copies.

Backport Plex `/photo/:/transcode` image sizing, stable token-free cache keys, and decode dimensions; cap hero images to screen size and posters to tile pixel dimensions. Fix body-stall slot release and lazy log rendering. Do not copy the 1.21.3 patch's increase to a 300 MiB cache or later desktop budgets. Use paginated/lazy grids, reduce concurrent library fetches, dispose listeners and stop auto-scroll timers off-screen. Keep Plezy monochrome identity, poster grid, readable titles and show/season/episode screens. Landscape touch controls should use roughly 56–64 logical-pixel targets as an initial design choice; verify physical size on GKUI. Disable blur, rotating hero effects and nonessential animation.

| Remove/isolate for GKUI | Dependency effect |
| --- | --- |
| media-kit native backend, mpv filters, PiP, HDR and refresh matching | Remove media_kit/video/libs and their brightness/volume/wakelock chains after adapter cutover; use native screen-on flag/focus handling |
| Desktop windows/hotkeys/titlebar | Remove `window_manager`, `hotkey_manager`, `macos_window_utils`; isolate imports in small platform facades |
| OS media integration | Remove Git `os_media_controls` (min21/Dart3.9.2); implement only necessary API19 audio focus in backend |
| Elaborate subtitle color editor | Optionally remove `flex_color_picker`; retain fixed readable subtitle presets |
| Browser launch | `url_launcher` optional if QR is the only login flow; do not require in-device browser |
| Downloads, Live TV/DVR, Watch Together, remote, Discord, trackers, admin, metadata editing, Watch Next, casting | Mostly absent in 1.8.1; **do not import** later packages/services. No pretend dependency savings for features not in the base |

Use a GKUI entry point, capability/facade boundaries and a minimal actual pubspec dependency graph. A Dart feature flag alone does not prevent Flutter from registering native plugins listed in pubspec. Preserve upstream code where practical, but keep unreachable imports out of the compiled GKUI path and scope analyzer checks honestly while milestones are incomplete.

## No-ADB diagnostics

Add a local diagnostics route in M0 and expand it at each gate. Show app/build ID, Android release/API, ABI, memory class/available memory, device clock, renderer, selected player/decoder, server name/ID, sanitized active endpoint and direct/relay status, TLS result/CA bundle version, source and output codecs, source and output resolution/bitrate, play method, preset, stream/session state, latest categorized error and failed operation duration.

Use a bounded in-memory ring plus size-rotated app-private logs. Offer copy and an on-screen lazy viewer first. Add API19 Storage Access Framework `ACTION_CREATE_DOCUMENT` export if GKUI provides a picker; otherwise clipboard/on-screen remains the guaranteed path. Do not require root/ADB or assume USB filesystem paths are writable.

Redact before every logging sink: `X-Plex-Token` in headers/query/nested encoded artwork URLs, `authToken`, per-server accessToken, Authorization/Cookie, Plex Home PIN and login QR/pin secrets. Avoid raw Dio exception objects and resource/decision response bodies. Include no tokens in cache keys, metadata, crash reports or exported settings. Tokens in app-private preferences are not encrypted secret storage; disable Android backup, clear credentials on sign-out, and never use external storage for them. API19 keystore behavior can be assessed later without blocking the first secure connection.

## Milestones and build reproducibility

| Milestone | Small implementation deliverable | Required observation before proceeding |
| --- | --- | --- |
| M0 | Minimal Flutter shell using adapted Plezy colors/poster placeholders and diagnostics; no player/auth dependencies | Single ARMv7, min19, v1-signed APK installs by USB, launches and renders; relaunch works |
| M1 | Shared validated TLS factory and clock/CA/network diagnostics | plex.tv and clients.plex.tv TLS succeed; invalid hostname/untrusted cert fail |
| M2 | QR/PIN flow, bounded polling, private token persistence, resources | Phone claims QR; valid token/resources returned; expiry/cancel/revoked-token paths terminate |
| M3 | HTTPS remote PMS selection, identity check, bounded failover/recovery | Hotspot to remote PMS without VPN/manual LAN address; shared resource tokens work; hotspot loss/recovery works |
| M4 | Home, Continue Watching, Recently Added, Movies, TV, season/episode/detail screens | Partial loading and profile/server scoping correct; artwork and memory bounded |
| M5 | Minimal Exo adapter, H.264/AAC MP4, focus and resource release | Hardware decoded local test asset then HTTPS PMS sample; repeat open/close without leak |
| M6 | Timeline/state reporting and resume | Stop/relaunch resumes accurately; watched/progress sync correct; failed reporting backs off |
| M7 | H.264/AAC HLS decision/start fallback and presets | Unsupported source transcodes remotely; 720p3 Mbps output verified; long seek/resume/stop correct |
| M8 | Audio IDs, SRT/WebVTT sidecars, embedded subtitle burn | Correct selected language survives switches; no full-source subtitle fetch |
| M9 | Artwork/buffer/animation/log tuning | 30–60 min browsing/playback plus repeated sleep/resume and low-memory testing stay within measured limits |

After M0 succeeds, run a small player load/decode spike alongside M1–M3 work if implementation resources permit; do not postpone discovery of an unusable vendor decoder until all browsing is polished. Retain the milestone order for feature integration.

GitHub Actions is feasible as a build service, subject to M0 proving the toolchain. Plan `workflow_dispatch` on the fork only, Linux `ubuntu-22.04`, read-only default token permissions, checkout/Java/upload actions pinned by full reviewed SHA, Flutter checkout by the framework SHA above, exact SDK platform/build-tools and NDK packages, and committed `pubspec.lock` plus Gradle dependency verification/locking. Use a stable dedicated **test** RSA signing key in fork Actions secrets so successive USB APKs update the same installation; a newly generated debug key per run would break updates. Do not publish signing secrets or use a production key on untrusted PR code.

Build: `flutter build apk --release --target-platform android-arm --target lib/main_gkui.dart`. Set `ndk.abiFilters 'armeabi-v7a'`, no ABI/density/language splits, explicit v1 signing enabled, ordinary compressed/extracted native libraries. Upload `app-release.apk` plus SHA-256, manifest/APK inspection, signing verification and source/toolchain IDs as an Actions artifact. Never use `--split-per-abi`, AAB, XAPK or APKS for this device. No workflow is implemented in this audit.

Before device handoff inspect with `aapt dump badging`, `apkanalyzer manifest print`, ZIP listing and `apksigner verify --verbose --min-sdk-version 19`. Require SDK19, one ARMv7 ABI, launchable activity and “Verified using v1 scheme: true.” Align before signing, never modify the ZIP afterward. Disable shrinking initially. D8 must emit API19-compatible DEX; if >65,536 references, use AndroidX multidex 2.0.1 and install it in Application on pre21, or reduce modules first. Java desugaring cannot manufacture platform APIs. Keep legacy raster launcher icons alongside any v26 adaptive resources, pre21 theme resources, and API-qualified vector/native icon alternatives. Flutter-drawn icons are unrelated to Android vector inflation. New manifest attributes are not automatically fatal; inspect the merged manifest and make only evidence-based changes. Package parse errors need the M0 artifact audit, not guesses about one field.

## Highest risks and decision

1. **GKUI engine/renderer/vendor decoder behavior:** no APK from this toolchain has run on the unit; validate the small shell and hardware decoder before broad UI work.
2. **Secure network consistency across Dart, images and native playback:** Android roots, clock, endpoint redirects, token scope and all HLS subrequests must work without insecure fallbacks.
3. **Plex transcode/timebase/profile correctness on constrained hardware:** the upstream base is direct-play-oriented, and later fixes assume richer codecs and players. Port the protocol deliberately and measure output/resume.

**CONDITIONAL GO**: there is a credible path preserving Plezy. Flutter API19 support, parseable Dart source, a resolved historical package set, and an API16-capable legacy player provide positive evidence. Unknown physical gates remain; no demonstrated hard blocker justifies abandoning Plezy for a new native client.
