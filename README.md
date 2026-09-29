# Plezy GKUI

<p>
  <img src="assets/plezy.png" alt="Plezy GKUI logo" height="38" />
</p>

Plezy GKUI is an unofficial, purpose-built Plex client for older GKUI in-car
head units. This fork targets Android 4.4.2 / API 19, ARMv7 hardware, limited
memory, and landscape vehicle displays such as the ECARX XE1115H.

It is based on the open-source [Plezy](https://github.com/edde746/plezy)
project, but its interface, playback stack, networking, dependencies, and
release process have been adapted specifically for legacy GKUI hardware. It is
not the App Store, Google Play, desktop, or current upstream Plezy build.

> This project is not affiliated with or endorsed by Plex, Plezy, ECARX, or a
> vehicle manufacturer. A Plex account and Plex Media Server are required.

## Download

The current tested build is **Plezy GKUI 1.2.2**:

- [Download the API 19 ARMv7 APK](https://github.com/jialim/plezy-gkui/releases/download/gkui-v1.2.2/Plezy-GKUI-1.2.2-api19-armeabi-v7a.apk)
- [Release notes and checksum](https://github.com/jialim/plezy-gkui/releases/tag/gkui-v1.2.2)
- [All releases](https://github.com/jialim/plezy-gkui/releases)

SHA-256: `0defa6cb5fa7c803bb6459433fdeb0858ac670967c3dbf513bff0839a759482f`

The APK uses package ID `com.jialim.plezygkui`, requires Android API 19 or
newer, and contains only the `armeabi-v7a` native ABI. Releases are signed with
the same GKUI development certificate so newer builds can install over earlier
GKUI builds.

## What is included

### Plex access

- Plex PIN sign-in and persistent sessions
- Secure HTTPS server discovery and endpoint identity verification
- Plex Home profile switching, including PIN-protected profiles
- Local and remote Plex Media Server connections

### Car-friendly library

- Cached Home, library metadata, and posters for faster startup
- Continue Watching, libraries, Collections, and Unwatched views
- Paged loading for large libraries
- Ranked search with Movies, Shows, and Episodes filters
- Watched badges and playback progress
- Large landscape controls designed for 800×480 and 1280×720 displays

### Playback

- Native ExoPlayer 2.19.1 playback compatible with Android API 19
- Automatic preference for an H.264 1080p copy when multiple versions exist
- Explicit media-version, audio-track, and subtitle-track selectors
- Remembered choices per Plex profile and title or show
- Direct Play plus 720p compatible and 480p safe Plex transcode modes
- Configurable seek intervals and hardware/D-pad controls
- Skip Intro/Credits button or automatic mode when Plex supplies markers
- Next-episode autoplay with a configurable countdown
- Playback progress, resume, session tracking, and transcode cleanup

### Mobile-data and recovery behavior

- Direct Play automatically falls back to 720p and then 480p when the head
  unit cannot produce a video frame
- Playback keeps waiting while its buffer advances
- A fallback occurs after 30 seconds with no buffer progress
- Safety ceilings are 90 seconds for Direct Play and 120 seconds for Plex
  transcodes
- Wi-Fi/mobile reconnection retries, sleep/wake recovery, and audio focus
- The startup watchdog pauses while the activity is suspended

### Diagnostics

The Status screen provides copyable, redacted diagnostics including:

- Device, Android version, ABI, and memory
- Sanitized Plex endpoint and active Home profile
- Selected media version and playback mode
- Content startup and first-frame timings
- Video format, decoder name, player state, and bounded logs

Authentication tokens and URL credentials are redacted.

## Deliberate limitations

This is a low-memory compatibility client, not a complete port of modern
Plezy. The following are intentionally outside its current scope:

- Phone remote control or screen mirroring
- Software HEVC, AV1, VP9, Dolby, or HDR processing
- Full ASS/SSA subtitle rendering
- Downloads, music, Live TV, Watch Together, Jellyfin, or Emby
- Desktop, iOS, Google Play, or App Store packages

Actual Direct Play support still depends on the head unit's hardware decoder.
Unsupported sources should use the automatic Plex transcode fallback.

## Installing on a GKUI head unit

1. Download the APK from the latest GitHub Release.
2. Transfer it to the head unit using the installation method available for
   your vehicle.
3. Allow installation from that source when prompted.
4. Install over an earlier Plezy GKUI build, or perform a fresh installation.
5. Open Plezy GKUI, complete Plex PIN sign-in, and select the server/profile.

Use the Status screen and photograph both diagnostic columns if playback still
fails on physical hardware.

## Building from source

The compatibility build is pinned to:

- Flutter 3.19.6 / Dart 3.3.4
- JDK 17
- Android SDK / build tools 34
- Minimum Android SDK 19
- ARMv7 output

```powershell
git clone https://github.com/jialim/plezy-gkui.git
cd plezy-gkui
flutter pub get
flutter build apk --release --target lib/main_gkui.dart --target-platform android-arm
```

Release signing is configured through the `GKUI_KEYSTORE_PATH`,
`GKUI_KEYSTORE_PASSWORD`, `GKUI_KEY_ALIAS`, and `GKUI_KEY_PASSWORD`
environment variables. Keystores and passwords must never be committed.

## Validation

```powershell
dart format lib/main_gkui.dart lib/gkui test/gkui
flutter analyze lib/main_gkui.dart lib/gkui test/gkui
flutter test test/gkui
cd android
./gradlew :app:testDebugUnitTest :app:compileDebugKotlin -x compileFlutterBuildDebug
```

The 1.2.2 release passed Flutter analysis, 17 Flutter tests, Android unit tests,
native Kotlin compilation, APK signature verification, and manifest/ABI
inspection. Physical in-car playback remains the final hardware gate.

## Project documentation

- [GKUI 1.2 release notes](GKUI_1_2_RELEASE_NOTES.md)
- [Porting plan](PORTING_PLAN.md)
- [Risks and validation gates](RISKS_AND_GATES.md)
- [Compatibility dependency matrix](DEPENDENCY_MATRIX.md)
- [Playback networking report](PLAYBACK_NETWORK_FIX_REPORT.md)
- [Legacy certificate-chain report](PLEX_CERTIFICATE_CHAIN_FIX_REPORT.md)
- [Privacy policy](PRIVACY.md)

## Upstream and license

Plezy GKUI is a compatibility fork of
[edde746/plezy](https://github.com/edde746/plezy), with the GKUI work based on
the historical Plezy 1.8.1 source line. Thanks to the upstream Plezy
contributors, Flutter, ExoPlayer, Plex, and the open-source projects included
in this repository.

This repository remains licensed under the [GNU GPL v3](LICENSE).
