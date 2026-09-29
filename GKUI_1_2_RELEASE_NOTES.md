# Plezy GKUI 1.2.2 — Stability and Scale

This is the consolidated API 19 / ARMv7 release for the ECARX XE1115H head unit. Phone remote and mirroring are intentionally excluded.

## 1.2.2 adaptive mobile-data startup

- A Direct Play no-frame timeout now automatically retries 720p compatible playback, then 480p safe mode if required.
- Playback keeps waiting while the buffer advances and falls back after 30 seconds with no loading progress.
- Direct Play has a 90-second safety ceiling; Plex transcodes have 120 seconds for cellular and slow-server startup.
- A player that reports Ready but renders no frame for 10 seconds falls back as a decoder/rendering failure.
- Sleep/wake pauses and restarts the startup watchdog instead of consuming its timeout in the background.
- A no-frame timeout is no longer mislabeled as a server connection failure.

## Included

- Plex Home profile switcher, including protected-user PIN entry.
- Secure endpoint identity and profile-token verification before a server route is saved.
- Cached Home, library, and poster data; five-minute Home refresh; no full-library reload after playback.
- Paged large-library loading, Collections and Unwatched views.
- Ranked search with All, Movies, Shows, and Episodes filters.
- Preferred H.264 1080p version selection plus an explicit version picker with codec, bitrate, and file size.
- Per-profile, per-title/show memory for media version, audio track, and subtitle track.
- Direct Play, 720p compatible transcode, and 480p safe transcode paths.
- Plex playback session identifiers, progress reporting, and transcode-session cleanup.
- Configurable seek buttons and coalesced hardware/D-pad seeking.
- Skip Intro/Credits modes: Off, on-screen button, or automatic.
- Next-episode autoplay with configurable 0/5/10/15/30-second countdown.
- Wi-Fi/network retry, app resume refresh, native audio focus, and in-place playback retry.
- Watched badges, Continue Watching refresh, and memory-pressure poster cleanup.
- Redacted diagnostics for endpoint, profile, selected version, content startup, first-frame time, decoder, and video format.

## Verified off-car

- Flutter static analysis: clean.
- Flutter tests: 17 passed, including 800×480 and 1280×720 coverage.
- Android unit tests: passed.
- Native Kotlin/ExoPlayer compilation: passed.
- APK manifest: version 1.2.2 (8), minimum API 19, target API 34.
- APK native ABI: armeabi-v7a only.
- APK signatures: v1 and v2 verified.
- APK SHA-256: `0defa6cb5fa7c803bb6459433fdeb0858ac670967c3dbf513bff0839a759482f`.

## One-pass M5 check

1. Install over 1.1.0 and confirm the existing account remains signed in.
2. Switch Plex Home profiles once, including a PIN-protected profile if available.
3. Open a multi-version title and confirm 1080p H.264 is selected; change audio/subtitles once.
4. Direct Play a local-copy H.264 1080p title, use D-pad seek repeatedly, sleep/wake the unit, and resume.
5. Play one 720p-compatible transcode and one 480p-safe transcode.
6. Verify Skip Intro/Credits and the Play Next countdown on an episode that has Plex markers.
7. Reopen the title and confirm its version/audio/subtitle choices were remembered.
8. Open Status and photograph both columns if anything fails.

Physical ECARX/M5 playback remains the final hardware gate because its Android 4.4 decoder and vehicle firmware cannot be reproduced by desktop tests.
