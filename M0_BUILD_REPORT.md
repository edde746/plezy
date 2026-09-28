# M0 API19 shell build report

Build date: 2026-09-28. Branch: `gkui/api19-implementation`. Historical application base: Plezy `1.8.1` / `10d4b3088f009c8c61e1fe1024e3ae99cf147113`.

## Outcome

M0 is ready for the first physical GKUI gate. It is deliberately a Flutter-only Plezy-styled landscape shell with Home/Library placeholders and an on-device Status screen. It has no Plex account, network permission, player, media-kit, desktop plugin, OS media control or background service.

The APK is a generated build artifact and is not committed:

- Path: `build/gkui/Plezy-GKUI-M0-api19-armeabi-v7a.apk`
- Size: `10,926,430` bytes
- SHA-256: `97498fd54441d4c644a2e8488d076deafe2f44e12e106157f52e72c811ca2555`
- Package: `com.jialim.plezygkui`, version `0.1.0` (`1`)
- Min/target/compile SDK: `19` / `34` / `34`
- Native contents: `lib/armeabi-v7a/libapp.so`, `lib/armeabi-v7a/libflutter.so`; no other ABI
- Launcher: `com.edde746.plezy.MainActivity`, normal `MAIN` / `LAUNCHER`
- Signing: v1/JAR **true**, v2 **true**, RSA 2048 test key
- Signer certificate SHA-256: `b55f4d2caa2ac2953a75a58ab9ab6ae731434734bf1a775a6e7c73558c58fab4`
- Launcher icon: density-specific raster PNGs only; adaptive icon removed from M0
- Touchscreen and landscape feature declarations are explicitly `required=false`
- Native extraction is enabled for the legacy package/runtime path

The dedicated private test key is stored only in ignored local audit data at `.audit/signing/gkui-test.jks`. Preserve and back it up securely before depending on update-in-place. Losing it means later APKs cannot update an installed M0 without uninstalling it. Do not commit the key. Signed release builds use the `GKUI_KEYSTORE_PATH`, `GKUI_KEYSTORE_PASSWORD`, `GKUI_KEY_ALIAS` and `GKUI_KEY_PASSWORD` environment variables; without them the Gradle release variant is not assigned a fallback signer.

## Verified toolchain

- Flutter `3.19.6`, framework `54e66469a933b60ddf175f858f82eaeb97e48c8d`
- Engine `c4cd48e186460b32d44585ce3c103271ab676355`
- Dart `3.3.4`
- Temurin JDK `17.0.10+7`
- Gradle `8.4`, distribution SHA-256 pinned in wrapper properties
- Android Gradle Plugin `8.3.2`; Kotlin `1.9.22`
- Android platform/target `34`; build-tools `34.0.0`
- Minimal Pub graph: Flutter SDK + Flutter test SDK only; lockfile committed

## Checks completed

- Scoped `flutter analyze` on `lib/main_gkui.dart`, `lib/gkui`, and `test/gkui`: no issues.
- Four tests pass: secret redaction, bounded log eviction, and shell navigation/rendering at `800x480` and `1280x720`.
- `lintRelease` passes with the explicit M0 Flutter target. Remaining warnings are intentional for this target: ARMv7-only, landscape-only, backup disabled and unused old resource variants.
- `aapt dump badging`: min19, target34, ARMv7, normal launcher, raster icon.
- `apkanalyzer`: min19, target34, application ID above, one DEX with 31,789 references (no multidex).
- `apksigner verify --verbose --min-sdk-version 19`: verifies v1 and v2 with one signer.
- ZIP inspection: only the ARMv7 Flutter engine and application native libraries.

The first Gradle probe identified and fixed two genuine compatibility issues: Flutter3.19 requires version metadata from `local.properties`, not the newer Flutter Gradle extension, and `android:colorAccent` belongs to API21 rather than the unqualified API19 theme. The build uses the older Flutter-compatible paths now.

## Physical pass criteria

Copy the named APK to USB and use the normal GKUI installer. M0 passes only after all of the following are observed on the original unit:

1. Installer accepts the APK without a parse error.
2. `Plezy GKUI` launches from the normal app icon and renders the Home poster shelves.
3. Touch navigation reaches Library and Status; text is readable and not clipped.
4. Status shows Android/API, ARM ABI, memory and clock; Copy works if the system clipboard is available.
5. Relaunch and one sleep/wake cycle return to a usable UI without a persistent black screen.
6. A second build signed by the same test key updates the installation without uninstalling.

Record a photo of Home and Status plus the exact failure stage if any. Do not start M1 account/network work until install, launch and render are known. The current Status screen is the no-ADB evidence channel for later gates.
