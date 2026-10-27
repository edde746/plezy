# Dolby Vision FEL phone test

These are experimental client builds for collecting device evidence. A build
or route label does not prove that the enhancement layer changed the displayed
pixels. Use a Profile 7 file known to contain both BL and FEL, and keep the
original file available as a control.

## Android

The current APK is ARM64 (`arm64-v8a`), Android API 25 minimum, debug-signed,
and installs under `org.snapetech.plezyng.dvfel`. It can coexist with the normal
PlezyNG app. It is not a Play Store build.

To rebuild the pinned AAR and APK from source, use the matching baseline
`mpv-android` AAR identified by the repository lock, an Android SDK/NDK,
Flutter, Meson and Ninja. Start with an empty native work directory:

```sh
python3 tools/dv-engine/build_android_fel.py \
  --work-dir build/dv-android-native \
  --android-sdk "$ANDROID_HOME" \
  --base-aar /absolute/path/to/locked-mpv-android-base.aar \
  --output build/dv-android/mpv-fel-arm64.aar \
  --flutter-sdk "$FLUTTER_ROOT" \
  --jobs 4 --assemble-apk
```

The builder writes the AAR checksum, APK checksum and a build report. It
packages only ARM64 native code, limits Gradle parallelism for smaller build
hosts, and checks the APK's engine libraries and Flutter assets against their
build inputs.

With Android platform-tools installed and USB debugging enabled:

```sh
adb devices -l
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p org.snapetech.plezyng.dvfel 1
```

If Android blocks the install, allow installs from the file source used to open
the APK. If using ADB, the confirmation prompt appears on the phone. The
device must support ARM64. A production PlezyNG install and its data are left
untouched.

In the experimental app, sign in to the usual media server and select **mpv**
under **Settings → Playback → Player Backend**. Start with a direct-play P7
FEL sample; avoid a server transcode during the first run. In another terminal,
capture player logs before playback:

```sh
adb logcat -c
adb logcat -v time -s MpvPlayerCore AndroidRuntime
```

The first expected marker is `paired FEL engine available`. For the P7 sample,
the route should select `gpu-next` and software decoding so both layers and the
RPU reach the FEL compositor. A missing engine identity intentionally fails
closed. Record the phone model, Android version, display mode, sample profile,
container, server delivery mode, playback route and any dropped frames.

Exercise start, pause/resume, seeks in both directions, subtitle/audio track
changes, rotation, background/foreground and a second playback after stopping.
If possible, compare the same sample on an HDR display and an SDR-only display.
The Android path renders through libplacebo; it does not send a Dolby Vision
signal or require a per-title LUT. HDR10/SDR output, color accuracy, thermal
stability and real FEL pixel contribution still need physical-device evidence.

## iPhone / iPad

The checked-in Apple project is a separate AetherEngine research host, not the
PlezyNG production iOS player. It has a P7/FEL toggle, playback controls and a
visible route/decoder status. The deployment target is iOS 18. Build and signing
require a Mac with Xcode 27 and XcodeGen, plus an Apple development team for
installation:

```sh
python3 tools/dv-engine/build_adapters.py \
  --component apple --apple-platform ios \
  --work-dir build/dv-apple-ios --build
open build/dv-apple-ios/host/PlezyNGDVExperiment.xcodeproj
```

The script fetches the locked engine revision, checks Swift package pins and
builds an unsigned generic iOS device target. In Xcode, select the connected
iPhone/iPad, set the tester's development team for the app target, then build
and run. In the host, use **Choose file** for a video in Files or enter an
HTTPS media URL, play once with
**Reconstruct FEL** off, then repeat with it on. Record the route, decoder,
engine errors and any visual difference. Use a direct media URL accessible to
the phone; this host does not log in to the PlezyNG server.

An iOS build, signing identity, provisioned device and physical Apple device
were not available in the Linux build workspace. The iOS host source is
prepared, but no iOS app/IPA is attached to this handoff. Even a successful
Aether host run would qualify that experiment only; production iOS player
integration and output/lifecycle testing are still separate work.

## Evidence to return

For each phone, include model and OS version, the test sample's verified Dolby
Vision profile and layer configuration, direct-play/transcode status, route and
decoder logs, seek/lifecycle results, whether the display is HDR-capable, and
whether playback stutters or overheats. Redact account tokens and private
server URLs before sharing logs.
