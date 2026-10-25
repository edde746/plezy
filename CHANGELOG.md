# Changelog

## [Unreleased]

### Added

- Add converted download quality for Jellyfin and Emby, and let sync rules keep their own quality preset.
- Add per-server Continue Watching downloads that remove shelf items when they leave the shelf.
- Add selectable random local prerolls before movies, with Plex server prerolls taking precedence.
- Remember audio and subtitle choices per show locally across Plex, Jellyfin, and Emby.
- Add in-player subtitle size/position controls and load a local subtitle file in mpv.
- Play theme songs for the active home spotlight.
- Resolve watch links across Jellyfin and Emby by catalog IDs, with server-specific fallback links.
- Add configurable Home rows, merged library and collection rows, and Plex Home layout synchronization.
- Add local profile PIN gates for Settings, Explore, and download deletion, plus per-profile Explore visibility.
- Add a random movie picker, detail-page finish-time estimate, optional empty-library hiding, and log-file export.
- Add an opt-in TheIntroDB intro fallback when the media server has no matching intro marker.
- Add Home backdrop visibility and Continue Watching row-size controls.
- Add an optional audio and subtitle picker before starting video playback.
- Added changelog enforcement, changelog-based release notes, and Discord announcements for published PlezyNG releases.
- Require an explicit versioned release dispatch, and move release downloads and package updates to PlezyNG.
- Remove the inherited WinGet publisher and add the PlezyNG Discord support link to the README.
