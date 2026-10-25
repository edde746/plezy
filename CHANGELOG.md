# Changelog

## [Unreleased]

### Added

- Add a review-first cleanup for orphaned tagged downloads in PlezyNG's default app-managed folders.
- Add configurable skipping for Plex-detected commercial markers, six original animated visualizer styles, and opt-in loudness-aware music fades.
- Add converted download quality for Jellyfin and Emby, and let sync rules keep their own quality preset.
- Add per-server Continue Watching downloads that remove shelf items when they leave the shelf.
- Add selectable random local prerolls before movies, with Plex server prerolls taking precedence.
- Play configured Jellyfin and Emby cinema intros before movies when server extras are enabled.
- Add a separate remote-streaming quality cap across Plex, Jellyfin, and Emby.
- Split Home's Continue Watching and Next Up rows, with independent visibility and ordering.
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
- Add device-local preferred-language subtitle selection and opt-in downloads through the server's subtitle provider API.
- Add a five-band device-local audio equalizer to mpv video playback.
- Let each profile prioritize a preferred media server in cross-server result ordering.
- Shuffle every movie or episode in the selected library across Plex, Jellyfin, and Emby.
- Continue video audio in the background on handheld Android and iOS when enabled.
- Back up and restore portable settings through an HTTPS WebDAV file endpoint.
- Cast Plex, Jellyfin, and Emby video to Google Cast receivers on Android and iOS, with remote controls, subtitle sidecars, and server progress reporting.
- Add Android automation links to launch media, select profiles, and control active playback, with copy actions for profile links.
- Add profile-scoped new-episode alerts for caught-up shows while Plezy is open on Android/iOS.
- Add a configurable content screensaver that rotates artwork from selected connected libraries while idle.
- Added changelog enforcement, changelog-based release notes, and Discord announcements for published PlezyNG releases.
- Require an explicit versioned release dispatch, and move release downloads and package updates to PlezyNG.
- Add credential-gated signed Android Play/Amazon and Apple App Store assets, manual mobile-store submissions, an identity-gated Windows Store MSIX bundle, release checksums, Windows package-manager submissions, and multi-architecture relay container publishing.
- Prepare credential-gated Snap Store, AppImage, AUR, Fedora COPR, and Launchpad PPA release channels.
- Use PlezyNG-specific Android, Apple, tvOS, and Flatpak application identities for store and package submissions.
- Remove the inherited WinGet publisher and add the PlezyNG Discord support link to the README.

### Changed

- Explain the default behavior on the screensaver library selection page.
- Build Android app and plugin modules with SDK 37 and generate BuildConfig for current Android dependencies.
- Declare Bash explicitly when naming the Snap release artifact.
- Update remaining app and OAuth messages to PlezyNG and make donation copy provider-neutral.
- Keep Android signing material until all signed store builds finish, and clean it up afterward.
- Fix music fade gain handling across track transitions and avoid visualizer profile requests before the active track is ready.

### Removed

- Remove unused upstream website, legacy app-store and Sentry upload automation, and funding links.
