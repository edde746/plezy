# PlezyNG feature build-out handoff

Status: 2026-10-25. PlezyNG is a fork of `edde746/plezy` intended to carry requested features that upstream declined or has not shipped, while keeping parity across Plex, Jellyfin, and Emby where the APIs allow it. The fork should retire as the corresponding capabilities converge upstream.

## Implemented in this work branch

- Converted video download quality for Plex, Jellyfin, and Emby. Plex uses its download queue; Jellyfin and Emby use progressive H.264/AAC transcodes and restart after interrupted transfers because those streams are not resumable.
- Per-sync-rule quality, per-download quality prompt, and automatic Continue Watching rules with cleanup when items leave the shelf.
- Local random movie pre-rolls, following server-provided Plex pre-rolls.
- Per-show audio and subtitle memory stored locally by app profile, in addition to existing Plex/Jellyfin server memory.
- In-player subtitle size/position controls and loading a local subtitle file in mpv.
- Theme-song playback on the active TV home spotlight, using the existing cross-server theme-song controller.
- Resolve watch links for Jellyfin and Emby by IMDb/TMDB/TVDB ID, falling back to a server-specific link when metadata is incomplete.
- People search and offline playlist downloads were already present in the merged code. Existing watched-download cleanup and per-item sync offsets were also present.
- The earlier 23 upstream PR integrations remain on `main`, including local Plex connections, download storage reporting, deep links, external-player return sync, repeat playlists, swipe/frame controls, subtitle preview and delay hotkeys, bulk selection, prerolls, live-TV timeshift, theme songs, and download sync actions.

## Remaining features from the requested list

| Area | Remaining work |
| --- | --- |
| Downloads | Orphan cleanup; verify converted downloads against real Plex/Jellyfin/Emby servers |
| Profiles | PIN-gate delete/settings/Explore actions; hide Explore per profile |
| Audio/subtitles | Choose tracks before playback; always-on subtitles and preferred-language auto-fetch; validate per-show memory on every backend |
| Playback | Jellyfin/Emby cinema-intro APIs; background video/audio-only mode; mpv equalizer; separate local/remote quality; opt-in TheIntroDB fallback |
| Browsing | Random movie and library shuffle; show finish time on detail pages |
| Home | Configurable rows and merged libraries (#2203); separate Next Up; hide empty libraries, hero/backdrop art; row sizing; clock |
| Servers | Preferred server |
| Live TV | Jellyfin/Emby DVR timeshift timeline |
| Integrations | Google Cast; new-episode notifications; content screensaver; Home Assistant and Android automation intents |
| Settings | Save logs to a file; cloud settings backup |

## Validation and cautions

- No tests were run in this handoff. Static formatting, analyzer, localization, and repository guard checks are used without invoking the pre-commit wrapper, which runs Python regression tests.
- Converted downloads and playback features still need live-server validation. Jellyfin/Emby converted streams have unknown content length and cannot resume; a failed transfer restarts from the beginning.
- The live TV time-shift, local transcoding, and device-specific UI paths require real-device or server validation before release.
