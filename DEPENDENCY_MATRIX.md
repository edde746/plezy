# Dependency and compatibility matrix

Audit: 2026-09-28. Source base: Plezy `1.8.1` (`10d4b3088f009c8c61e1fe1024e3ae99cf147113`). Target: Flutter **3.19.6**, Dart **3.3.4**, Android **19**, **armeabi-v7a**. This is a planning document, not an application dependency change.

## How to interpret the evidence

Three different ceilings matter: the package's declared SDK constraint, the **complete Pub solver graph**, and Android runtime/native compatibility. A low `minSdk` in a wrapper does not certify its downloaded `.so`. A successful `pub get` does not test Gradle, DEX, native loading, or GKUI.

Versions below come from the [base manifest](https://github.com/edde746/plezy/blob/1.8.1/pubspec.yaml), [base lockfile](https://github.com/edde746/plezy/blob/1.8.1/pubspec.lock), pub.dev version metadata and downloaded package archives, including their `pubspec.yaml`, `android/build.gradle`, manifests and changelogs. Each package's versioned pub.dev link exposes its metadata/changelog; archives are identified by `https://pub.dev/api/packages/PACKAGE/versions/VERSION`. Record archive checksums in the implementation lockfile.

`D` = Dart minimum; `F` = Flutter minimum; `N/A` = no separate Android minimum in pure Dart/Flutter code, **not** independence from the Flutter engine. “Candidate” is the exact recommended integration pin, not always the numerically newest release. All Android execution remains Gate C. Rows marked UNKNOWN name the smallest remaining test rather than assuming compatibility.

## Main dependency decisions

| Dependency | Plezy 1.8.1 constraint -> locked version | Candidate requirement / native Android code | API19 + F3.19 candidate | Downgrade / source work | Remove or local fork? | Risk / notes |
| --- | --- | --- | --- | --- | --- | --- |
| `media_kit` | `^1.1.10+1` -> fork `1.2.1` | Public 1.1.11 D>=2.17; FFI/native mpv required | `1.1.11` **Dart probe only** | Yes; fork fields differ | Remove for preferred Exo adapter; native local fork only time-boxed experiment | **High:** 1.2.x brings `web ^1.1.0` requiring newer Dart; no certified API19 mpv |
| `media_kit_video` | `^1.2.4` -> fork `1.3.1` | 1.2.5 D>=2.17/F>=3.7; native texture plugin | `1.2.5` **Dart probe only** | Yes; configuration/track APIs differ | Remove with media-kit | High: Pub success is not native compatibility |
| `media_kit_libs_video` | `^1.0.4` -> fork `1.0.7` | D>=2.17/F>=3.7; umbrella pulls platform native payloads | **None verified** | Cannot fix by manifest downgrade | Remove; do not retain universal platform bundles | High: pin Android payload separately if experimenting |
| `media_kit_libs_android_video` | override -> fork `1.3.9` | Wrapper min16; JNI/FFmpeg/mpv payload; fork compile36/AGP8.13 | **None verified** | Rebuild/recover and audit native artifacts, not just Pub pin | Remove preferred | High: known public payload min21; exact fork payload unavailable |
| Plezy media-kit fork | Git `dce2963936424ffc80309ef4bca7e95041dfbfef` | Overrides media/video/Android/iOS/macOS/universal libs | No complete compatible fork revision demonstrated | Public replacement loses `mpvConfiguration`, `libassAndroidFontName`, track `isDefault` | Replace boundary, not wholesale app rewrite | High; see native evidence below |
| [`dio`](https://pub.dev/packages/dio/versions/5.9.0) | `^5.4.0` -> `5.9.0` | D>=2.18; pure Dart, uses Dart native TLS | **5.9.0** | No downgrade; central TLS/timeouts/cancellation factory | Keep; no fork | Medium: auth, probes, images and player have separate transport paths |
| [`json_annotation`](https://pub.dev/packages/json_annotation/versions/4.9.0) | `^4.8.1` -> `4.9.0` | D^3.0; pure Dart | **4.9.0** | No; retain generated files initially | Keep | Low; pair with generator 6.8.0 |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences/versions/2.2.3) | `^2.2.2` -> `2.5.3`; Android `2.4.15` | 2.2.3 D>=3.1/F>=3.13; native Android delegated | **2.2.3 + android 2.2.2** (min19) | Yes; base uses legacy `SharedPreferences` API, no broad rewrite | Keep; no fork | Medium: app-private preferences are not encrypted token storage; disable backup |
| [`cached_network_image`](https://pub.dev/packages/cached_network_image/versions/3.4.0) | `^3.4.1` -> `3.4.1` | 3.4.0 D>=3/F>=3.10; no own Android code, cache dependencies native | **3.4.0** with cache pins below | Yes; resize/cache-key/custom HTTP work | Keep initially; replace with small bounded image cache only if graph blocks | Medium/high: 3.4.1's web transitive fails Dart3.3 even on Android |
| [`url_launcher`](https://pub.dev/packages/url_launcher/versions/6.3.1) | `^6.3.0` -> `6.3.2`; Android `6.3.24` | 6.3.1 D>=3.3/F>=3.19; native Android | **6.3.1 + android 6.3.2** (min19) | Yes; ordinary launchUrl API retained | **Can remove** for QR-only sign-in | Low; never require a working GKUI browser |
| [`uuid`](https://pub.dev/packages/uuid/versions/4.5.2) | `^4.4.0` -> `4.5.2` | D>=3; pure Dart | **4.5.2** | No | Keep | Low; stable install ID, distinct play/transcode IDs |
| [`package_info_plus`](https://pub.dev/packages/package_info_plus/versions/8.0.2) | `^9.0.0` -> `9.0.0` | 8.0.2 D>=3.3/F>=3.19; Android min19, compile34, AGP8.3.1, Java17 | **8.0.2** | Yes; `PackageInfo.fromPlatform` retained | Can replace with small build-info channel; no fork initially | Medium: 8.0.3+ transitive `win32 >=5.5.1` requires Dart3.4 |
| [`provider`](https://pub.dev/packages/provider/versions/6.1.5%2B1) | `^6.1.2` -> `6.1.5+1` | D>=2.12/F>=1.16; Flutter only | **6.1.5+1** | No | Keep | Low |
| [`flex_color_picker`](https://pub.dev/packages/flex_color_picker/versions/3.4.1) | `^3.6.0` -> `3.7.2` | 3.4.1 D>=3/F>=3.16; Flutter only | **3.4.1**, or omit | Yes; test subtitle settings API/appearance | **Can remove** elaborate picker; fixed readable presets | Low; 3.5 raises Flutter floor to 3.22 |
| [`qr_flutter`](https://pub.dev/packages/qr_flutter/versions/4.1.0) | `^4.1.0` -> `4.1.0` | D>=2.19.6/F>=3.7; Flutter only | **4.1.0** | No | Keep | Low; do not log QR URL/PIN |
| [`slang`](https://pub.dev/packages/slang/versions/3.32.0) | `^3.31.2` -> `3.32.0` | D>=2.17; pure Dart/codegen | **3.32.0** | No runtime downgrade | Keep; no fork | Low initially; retain generated code |
| [`slang_flutter`](https://pub.dev/packages/slang_flutter/versions/3.32.0) | `^3.31.0` -> `3.32.0` | D>=2.17/F>=3.0; Flutter only | **3.32.0** | No | Keep matched to slang | Low |
| [`duration`](https://pub.dev/packages/duration/versions/4.0.3) | `^4.0.3` -> `4.0.3` | D>=2.17; pure Dart | **4.0.3** | No | Keep or trivial formatter later | Low |
| [`connectivity_plus`](https://pub.dev/packages/connectivity_plus/versions/6.1.5) | `^6.0.5` -> `6.1.5` | D>=3.2/F>=3.7; Android min19/compile34/AGP8.3.1/Java17 | **6.1.5** | **No downgrade**; keep list-valued connectivity API | Keep; channel fallback if native assembly fails | Medium: network interface availability is not server health |
| `os_media_controls` | Git `75dc5642cd148c54c03fe96976702b8d31c48599`, package `0.1.0` | D^3.9.2/F>=3.3; native Android **min21**, compile33, androidx.media1.6.0 | **Remove** | Replace media-control facade; use API19 focus in player | Remove rather than fork | High if retained; no required functionality justifies historical fork research beyond this exclusion |
| [`logger`](https://pub.dev/packages/logger/versions/2.6.2) | `^2.0.2` -> `2.6.2` | D>=2.17; pure Dart | **2.6.2** | No; add bounded/redacted sinks | Keep | Medium security: sanitize before every sink, never raw Dio exceptions |

## Version ceilings: declared versus effective

“Newest” is relative to the audited package history, not a promise about future releases. Pure Dart packages have no additional Android API ceiling beyond their Flutter/Dart dependencies. Do not upgrade merely because a newer version fits.

| Package family | Newest declared legacy-SDK candidate / actual boundary | Android-only boundary and selected outcome |
| --- | --- | --- |
| media-kit | Latest 1.2.6 still declares D>=3.1, but 1.2.0+ requires web1.1; **1.1.11** is the effective old-Dart candidate. Video latest 2.0.1 declares F>=3.7 but 1.3+ pulls newer media/web; **1.2.5** resolves | No verified API19 native combination. Universal1.0.7/Android1.3.8 Pub declarations do not certify binaries |
| dio | Latest **5.11.1** declares D>=2.18; base **5.9.0** resolves in complete probe | Pure Dart; latest full app graph untested. Keep base pin to minimize unrelated change |
| json_annotation | **4.9.0** is the D3.3 candidate; latest4.12.0 requires D3.9 | Pure Dart; keep4.9.0 |
| shared_preferences | Declared parent ceiling2.3.1 (D3.3/F3.19), but2.3.x requires Android^2.3.0, beyond this Flutter; **2.2.3 + android2.2.2** resolves | Android2.2.3 still says min19 but raises F3.22/D3.4. Later2.4.10 removes pre21 branches. Highest Android-only runnable combination is **UNKNOWN** without its transitive/build graph; it cannot improve the joint F3.19 ceiling |
| cached_network_image | **3.4.0** effective. 3.4.1 declares old Dart but its `cached_network_image_web 1.3.1 -> web ^1.0.0` requires D>=3.4. Latest4.0.2 requires D3.12/F3.44 | Native floor comes from cache/path/sqflite; keep verified old graph |
| url_launcher | **6.3.1**, Android **6.3.2**. Parent6.3.2 requires D3.6/F3.27; Android6.3.3 requires D3.4/F3.22 | Android6.3.3 still min19;6.3.16 removes pre21 code. Highest Android-only combination **UNKNOWN**; not usable with selected Flutter anyway |
| uuid | Latest **4.6.0** D>=3; base4.5.2 resolves | Pure Dart; keep4.5.2 |
| package_info_plus | Declared9.0.1 D3.3/F3.19 is misleading for full graph; **8.0.2** is effective. 8.0.3 fails solver through win32 | Even latest10.2.1 `android/build.gradle.kts` declares **min19**, but requires D3.10/F3.38.1/new build generation. Do not call9.0.0 an Android-minimum blocker; its Dart/build graph is the blocker |
| provider / QR / duration | Latest **6.1.5+1 / 4.1.0 / 4.0.3** all resolve | Pure Dart/Flutter; keep |
| flex_color_picker | **3.4.1** before F3.22 floor in3.5; latest4.0.0 requires F3.47/D3.13 | Flutter-only; downgrade or omit |
| slang / slang_flutter | Latest **4.19.2 / 4.19.0** declare D>=3.3, Flutter runtime F>=3.19. Full 4.x generator migration/build is **UNKNOWN** | No native floor; do not create unrelated generator migration. Matched **3.32.0** is solver-verified |
| connectivity_plus | Latest7.3.1 still declares D3.2/F3.7, but **7.1.0 raises minSdk to21** | **7.0.0** is last declared min19 release, but requires AGP>=8.12.1/Gradle>=8.13/Kotlin2.2.0. **6.1.5** is newest in the selected coherent Android generation; no downgrade from base needed |
| os_media_controls | Exact base Git revision requires D3.9.2 and Android21; historical last API19 release **UNKNOWN** | Remove nonessential integration; implement focus, not a full media-session package |
| logger | Latest **2.8.0** D>=2.17; base2.6.2 resolves | Pure Dart; keep2.6.2 |

Declared latest versions of Dio/UUID/logger/slang were inspected, not jointly build-tested. The selected older graph below was actually resolved. The UNKNOWN Android-only maxima for federated plugins are not blockers: their known joint SDK ceilings are earlier and verified, and the implementation should not force newer package code past its Flutter constraint.

## Transitive and build-time pins

| Dependency | Recommended pin / source requirement | Why explicit / source impact |
| --- | --- | --- |
| `shared_preferences_android` | **2.2.2**, min19, compile34, D3.2/F3.16 | 2.2.3 raises SDK floor, not minSdk. No DataStore migration |
| `url_launcher_android` | **6.3.2**, min19, compile34, AGP7.3.0; browser1.5.0/core1.10.1 | Newer Android implementations resolve differently; optional if launcher removed |
| `flutter_cache_manager` | **3.4.1**, D>=3 | Newer3.4.2+ raises Dart floor; custom validated HttpFileService needed |
| `path_provider` / `path_provider_android` | **2.1.4 / 2.2.4**, Android min19/compile34, D3.2/F3.16 | Parent2.1.5 raises F3.22; Android2.2.5 raises F3.22 but still min19;2.2.17 removes pre21 code |
| `sqflite` / `sqflite_common` | **2.3.3+1 / 2.5.4**, Android min16/compile34/AGP7.4.2 | Cache metadata database;2.3.3+2 requires Dart3.5 |
| `cached_network_image_web` / `web` | Resolved **1.3.0 / 0.5.1** | Web dependencies still participate in Pub solving for Android |
| `http` / `ffi` / `win32` | Resolved **1.2.2 / 2.1.3 / 5.5.0** | Do not “fix” package_info by letting win32 drift to5.5.1+ |
| `collection` / `meta` / `path` / `async` | Resolved **1.18.0 / 1.11.0 / 1.9.0 / 2.11.0** | Flutter SDK pins are part of the graph |
| `wakelock_plus` | **1.2.8** in media-kit probe only | Remove with media-kit; native player can set FLAG_KEEP_SCREEN_ON while playing |
| `screen_brightness` / Android implementation / `volume_controller` | Probe **0.2.2+1 / 0.1.0+2 / 2.0.8** | Transitive media-kit UI integrations; runtime/native suitability **UNKNOWN**, not in preferred Exo graph |
| `build_runner` | **2.4.9**, D>=3; base2.5.4 | 2.4.10 raises D3.4; do not regenerate everything at M0 |
| `json_serializable` | **6.8.0**, D>=3; base6.9.5 | 6.9 series requires newer Dart; keep model serialization tests |
| `slang_build_runner` | **3.32.0** | Match retained translation runtime |
| `flutter_lints` | Omit at M0 or choose historical4.x after solver check; base5.0.0 | Development-only, not an Android runtime blocker |
| `dart_code_linter` | Remove from GKUI dev graph; base3.1.1 | Nonessential analysis tooling; no runtime value |
| `flutter_launcher_icons` | Defer generator; retain raster resources; base0.14.4 | Not required to prove an APK can render |
| `macos_window_utils` / `window_manager` / `hotkey_manager` | Remove GKUI dependencies (base1.9.0 / 0.4.3 / 0.2.3) | Isolate Dart imports, mixins and singleton references; platform checks alone don't resolve imports |

## Reproducible Pub/source probes performed

Flutter checkout `54e66469a933b60ddf175f858f82eaeb97e48c8d` reports Flutter3.19.6, engine `c4cd48e186460b32d44585ce3c103271ab676355`, Dart3.3.4. An isolated scratch project, **not the application's pubspec**, resolved 146 packages with the following manifest. This includes public media-kit solely to expose fork API differences; **it is not the M0 or final Exo manifest** and contains no certified native mpv payload.

```yaml
name: plezy_legacy_dependency_probe
publish_to: none
environment:
  sdk: '>=3.3.4 <3.4.0'
dependencies:
  flutter:
    sdk: flutter
  dio: 5.9.0
  json_annotation: 4.9.0
  shared_preferences: 2.2.3
  shared_preferences_android: 2.2.2
  cached_network_image: 3.4.0
  flutter_cache_manager: 3.4.1
  path_provider: 2.1.4
  path_provider_android: 2.2.4
  sqflite: 2.3.3+1
  url_launcher: 6.3.1
  url_launcher_android: 6.3.2
  uuid: 4.5.2
  package_info_plus: 8.0.2
  provider: 6.1.5+1
  flex_color_picker: 3.4.1
  qr_flutter: 4.1.0
  slang: 3.32.0
  slang_flutter: 3.32.0
  duration: 4.0.3
  connectivity_plus: 6.1.5
  logger: 2.6.2
  media_kit: 1.1.11
  media_kit_video: 1.2.5
  wakelock_plus: 1.2.8
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: 2.4.9
  json_serializable: 6.8.0
  slang_build_runner: 3.32.0
```

Reproduce with the exact SDK's `flutter pub get`, inspect `flutter pub deps --style=compact`, commit the implementation's lockfile and run `flutter pub get --enforce-lockfile` in CI. The complete Android graph must be separately inspected with Gradle `dependencies`/`dependencyInsight`. Do not add `dependency_overrides` that silence incompatible declared SDKs.

Observed failures before the successful probe:

- cached_network_image3.4.1 -> cached_network_image_web1.3.1 -> web^1.0.0 -> Dart>=3.4.
- package_info_plus8.0.3 -> win32>=5.5.1 -> Dart>=3.4.

All 145 unchanged base Dart files parsed using Dart3.3.4 `dart format --output=none`. Analysis of the copied source returned errors (expected), including **64** `withValues` calls across Color/MaterialColor, 19 `surfaceContainerHighest` references, theme-state changes, `RadioGroup`, `PopupMenuButton.menuPadding`, `PopScope.onPopInvokedWithResult`, removed desktop/media symbols and fork-only player members. The probe's different package name also makes `package:plezy/...` self-imports unresolved: do not misclassify that scratch artifact as an upstream defect. See source adaptations in the roadmap and handoff. No app code was changed to make this analysis pass.

## Native media-kit evidence and alternative dependencies

The fork's [Android wrapper](https://github.com/edde746/media-kit/blob/dce2963936424ffc80309ef4bca7e95041dfbfef/libs/android/media_kit_libs_android_video/android/build.gradle) downloads release7 of `edde746/libmpv-android-build`; exact payload/source retrieval failed (repository unavailable), so its minimum is UNKNOWN. Public Android libs1.0.0/1.1.1 use old `media-kit/android-dependencies` payloads that were also unavailable. There is no basis for calling those usable API19 binaries.

Public Android libs1.3.8 uses `media-kit/libmpv-android-video-build` v1.1.7. The [build script](https://github.com/media-kit/libmpv-android-video-build/blob/v1.1.7/buildscripts/build.sh) and earliest v1.0.0 set Android API21. An actual v1.1.7 ARMv7 archive contains ELF32 ARM libmpv and helper, both with Android note21 (hashes in the roadmap). The mpv imports locale functions absent from [KitKat's libc locale header](https://github.com/aosp-mirror/platform_bionic/blob/android-4.4_r1/libc/include/locale.h) but present in [Lollipop's](https://github.com/aosp-mirror/platform_bionic/blob/android-5.0.0_r1/libc/include/locale.h). Lowering wrapper minSdk cannot supply missing Bionic symbols. Rebuilding requires auditing mpv, FFmpeg, rendering/helper, C++ runtime and TLS together.

Preferred new native dependencies, to introduce only for Gate D/M5:

- `com.google.android.exoplayer:exoplayer-core:2.19.1` and `exoplayer-hls:2.19.1`: [source minSdk16](https://github.com/google/ExoPlayer/blob/r2.19.1/constants.gradle), platform MediaCodec, no separate FFmpeg `.so` needed. Legacy artifact namespace, **not Media3**. Pin all resolved AndroidX dependencies and inspect merged minSdk/API calls.
- Optional `extension-okhttp:2.19.1`: its source declares **OkHttp4.11.0**, which is not API19. Explicitly exclude that dependency and resolve **OkHttp3.12.13**, then compile and exercise all data-source methods; binary/API compatibility of this substitution is **UNKNOWN** until the small transport probe. If it fails, write a small API19 data source using that client rather than upgrading to Media3.
- Optional `org.conscrypt:conscrypt-android:2.5.2`: [build source](https://github.com/google/conscrypt/blob/2.5.2/android/build.gradle) min9/ARMv7. Prove load/handshake and supply maintained trust roots. It does not replace Dart's TLS implementation.
- Android framework `MediaPlayer`: no package dependency; fallback if Exo surface/decoder path fails. Its native HTTP/TLS behavior is a separate gate.

These runtimes are legacy, with ongoing security-maintenance cost. Keep the fork personal/minimal, expose no inbound service, retain HTTPS verification, avoid software codecs and unnecessary parsers, and review critical patches independently of feature upgrades. A frozen old SDK is a compatibility decision, not a security guarantee.
