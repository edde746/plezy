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
- Hide libraries only when a backend explicitly reports zero items, choose a random movie from a library, estimate a detail page's finish time, and export diagnostic logs to a file.
- Hide Home hero/spotlight artwork or choose a compact, standard, or large Continue Watching row.
- Choose a preferred server per profile; it is queried first while all Plex, Jellyfin, and Emby servers remain available.
- Keep Continue Watching and Next Up in separate Home rows, each with its own visibility and organizer position.
- Five-band, device-local audio equalizer for mpv video playback; gains compose with loudness normalization and are stored in portable settings.
- Optional TheIntroDB community intro timings are queried only when no server or chapter-derived intro exists. The setting is off by default and requires a catalog ID and internet access.
- People search and offline playlist downloads were already present in the merged code. Existing watched-download cleanup and per-item sync offsets were also present.
- The earlier 23 upstream PR integrations remain on `main`, including local Plex connections, download storage reporting, deep links, external-player return sync, repeat playlists, swipe/frame controls, subtitle preview and delay hotkeys, bulk selection, prerolls, live-TV timeshift, theme songs, and download sync actions.

## Remaining features from the requested list

| Area | Remaining work |
| --- | --- |
| Downloads | Orphan cleanup; verify converted downloads against real Plex/Jellyfin/Emby servers |
| Profiles | None for the listed PIN and per-profile Explore visibility requests; Plex Home PIN remains server-owned |
| Audio/subtitles | Validate per-show memory, pre-play selection, and automatic subtitle fetching against real Plex/Jellyfin/Emby servers |
| Playback | Background video/audio-only mode |
| Browsing | Library-wide shuffle; show finish time in TV details and remaining detail surfaces |
| Home | Backdrop-art visibility and Continue Watching row sizing are implemented. Empty-library filtering applies when the server reports an explicit zero. The legacy hero banner already has a visibility setting; the top-bar clock is available on TV. |
| Live TV | Jellyfin/Emby DVR timeshift timeline |
| Integrations | Google Cast; new-episode notifications; content screensaver; Home Assistant and Android automation intents |
| Settings | Cloud settings backup |

## Validation and cautions

- No tests were run in this handoff. Static formatting, analyzer, localization, and repository guard checks are used without invoking the pre-commit wrapper, which runs Python regression tests.
- Converted downloads and playback features still need live-server validation. Jellyfin/Emby converted streams have unknown content length and cannot resume; a failed transfer restarts from the beginning.
- The live TV time-shift, local transcoding, and device-specific UI paths require real-device or server validation before release.
