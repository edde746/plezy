# PlezyNG feature build-out handoff

Status: 2026-10-25. PlezyNG is a fork of `edde746/plezy` intended to carry requested features that upstream declined or has not shipped, while keeping parity across Plex, Jellyfin, and Emby where the APIs allow it. The fork should retire as the corresponding capabilities converge upstream.

## Implemented in this work branch

- Converted video download quality for Plex, Jellyfin, and Emby. Plex uses its download queue; Jellyfin and Emby use progressive H.264/AAC transcodes and restart after interrupted transfers because those streams are not resumable.
- Per-sync-rule quality, per-download quality prompt, and automatic Continue Watching rules with cleanup when items leave the shelf.
- Server-configured Plex pre-rolls and Jellyfin/Emby cinema intros, with local random movie pre-rolls as the fallback.
- Per-show audio and subtitle memory stored locally by app profile, in addition to existing Plex/Jellyfin server memory.
- Optional pre-play audio and subtitle selection using the same source track metadata as the player, across Plex, Jellyfin, and Emby.
- Preferred-language subtitle selection is a device-local playback policy. Its opt-in setting selects an existing track or asks Plex, Jellyfin, or Emby to fetch one, then attaches the returned subtitle as a sidecar. Automatic selections are never written to the account; explicit server-selected tracks, account Off, and user Off choices take precedence.
- In-player subtitle size/position controls and loading a local subtitle file in mpv.
- Theme-song playback on the active TV home spotlight, using the existing cross-server theme-song controller.
- Resolve watch links for Jellyfin and Emby by IMDb/TMDB/TVDB ID, falling back to a server-specific link when metadata is incomplete.
- Configurable Home rows, merged library and collection rows, organizer controls, and Plex account layout sync from upstream #2203. Custom rows can include selected Plex, Jellyfin, and Emby libraries; native Plex Home rows and account sync remain Plex-specific.
- A local profile PIN can gate Settings, download deletion, and entry to Explore. Explore visibility is configurable per profile; the app does not replace Plex Home's server-owned PIN.
- Hide libraries only when a backend explicitly reports zero items, choose a random movie or shuffle a movie/TV library, estimate a detail page's finish time, and export diagnostic logs to a file.
- Hide Home hero/spotlight artwork or choose a compact, standard, or large Continue Watching row.
- Choose a preferred server per profile; it is queried first while all Plex, Jellyfin, and Emby servers remain available.
- Keep Continue Watching and Next Up in separate Home rows, each with its own visibility and organizer position.
- Five-band, device-local audio equalizer for mpv video playback; gains compose with loudness normalization and are stored in portable settings.
- Optional audio-only video continuation when a handheld Android or iOS app backgrounds; Android uses the existing OS media playback foreground service.
- Google Cast discovery, playback handoff, subtitle sidecars, remote pause/resume/stop controls, and server progress reporting on Android and iOS. Plex, Jellyfin, and Emby streams use their existing external-playback resolvers and the default Cast media receiver.
- Android automation links can launch cross-server watch links, select an existing profile, and control the active video session with play, pause, toggle, or stop. Profile detail screens can copy the selection link, and profile activation follows the regular PIN/Plex Home verification flow. See [Android automation links](android-automation.md).
- Profile-scoped new-episode notifications scan connected Plex, Jellyfin, and Emby libraries while the app is foregrounded on Android/iOS. Initial scans establish a baseline; alerts are limited to shows whose earlier episodes are watched.
- An idle content screensaver rotates artwork from selected libraries across connected servers, with configurable delay and dismiss controls.
- Optional TheIntroDB community intro timings are queried only when no server or chapter-derived intro exists. The setting is off by default and requires a catalog ID and internet access.
- People search and offline playlist downloads were already present in the merged code. Existing watched-download cleanup and per-item sync offsets were also present.
- The Downloads screen can review and remove orphaned tagged media, episode thumbnails, and numeric-ID subtitle sidecars from PlezyNG's default app-managed folders. The scan preserves database-owned or active-task files, custom/SAF roots, iOS Documents, legacy paths, shared artwork, unknown files, and symlinks.
- The earlier 23 upstream PR integrations remain on `main`, including local Plex connections, download storage reporting, deep links, external-player return sync, repeat playlists, swipe/frame controls, subtitle preview and delay hotkeys, bulk selection, prerolls, live-TV timeshift, theme songs, and download sync actions.

## Remaining work and platform limits

| Area | Remaining work |
| --- | --- |
| Downloads | Verify converted downloads against real Plex/Jellyfin/Emby servers; orphan cleanup is implemented for the default app-managed folders only |
| Profiles | Implementation is complete: the app-local PIN gates Settings, download deletion, and Explore; Explore visibility is per profile. Plex Home PINs remain server-owned. |
| Audio/subtitles | Validate per-show memory, pre-play selection, and automatic subtitle fetching against real Plex/Jellyfin/Emby servers |
| Browsing | Finish-time estimate is shown on media details; check platform layouts during release validation |
| Home | Backdrop-art visibility and Continue Watching row sizing are implemented. Empty-library filtering applies when the server reports an explicit zero. The legacy hero banner already has a visibility setting; the top-bar clock is available on TV. |
| Live TV | Jellyfin/Emby do not expose a seekable capture-window snapshot in their public playback responses, so the app cannot safely map their live buffer to the absolute-time timeline used by Plex |
| Integrations | Notifications are foreground-polled only; they pause when the OS suspends Plezy. There is no background push source. Google Cast uses the default Cast media receiver and needs validation with physical receivers; the receiver must support the stream format and reach the server. |
| Automation | Android intent links provide direct media launch, profile selection, and active-video controls. Plezy does not yet advertise itself as a native Plex Companion player to Home Assistant's Plex integration. |
| Settings | HTTPS WebDAV backup of the portable settings export is implemented. Configure a file URL ending in `.json`, optionally with WebDAV credentials; local server connections, tokens, download locations, and history are excluded. |
| webOS TV | The rooted LG C6 is available as the physical test target and its SSH transport is confirmed. PlezyNG has no webOS application target or IPK yet: LG's published Flutter/Dart SDK is below this app's toolchain floor, the player has no webOS backend, and storage/plugin integrations need an explicit port; see [webOS port status](../maintainers/webos-tv.md). LGPrivacyShield documents the existing manual install path. |

## Validation and cautions

- The focused download, storage, manager, provider, Downloads focus, appearance, and orphan-cleanup test set passes all 284 tests. Analyzer and translation hygiene pass, and an Android arm64 debug APK builds against the merged SDK 37 configuration.
- The latest full `scripts/ci_checks.sh` run still reports repository-wide issues: formatting drift in two legacy screens, the example WebDAV URL flagged as a hard-coded UI string, an iOS SwiftPM lock mismatch for Google Cast, 22 existing icon consistency findings, and the unused `hubIdentifierMatches` helper. Translation and native-format checks pass; the screensaver description key is restored and analyzer passes independently.
- Converted downloads and playback features still need live-server validation. Jellyfin/Emby converted streams have unknown content length and cannot resume; a failed transfer restarts from the beginning.
- New-episode notifications need Android/iOS device validation, including OS permission denial/recovery and notification behavior while the app is open. They intentionally do not claim background delivery while the app is suspended.
- Google Cast needs validation against physical receivers on both platforms. The generic receiver does not use Plex's private receiver app and cannot add custom authorization headers; server adapters therefore provide self-contained HTTP(S) URLs, and playback is limited to formats supported by the receiver.
- The live TV time-shift, local transcoding, and device-specific UI paths require real-device or server validation before release.
