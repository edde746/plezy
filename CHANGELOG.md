# Changelog

## [Unreleased]

### Added

- Add configurable skipping for Plex-detected commercial markers, six original animated visualizer styles, and opt-in loudness-aware music fades.
- Added changelog enforcement, changelog-based release notes, and Discord announcements for published PlezyNG releases.
- Require an explicit versioned release dispatch, and move release downloads and package updates to PlezyNG.
- Add credential-gated signed Android Play/Amazon and Apple App Store assets, manual mobile-store submissions, an identity-gated Windows Store MSIX bundle, release checksums, Windows package-manager submissions, and multi-architecture relay container publishing.
- Prepare credential-gated Snap Store, AppImage, AUR, Fedora COPR, and Launchpad PPA release channels.
- Use PlezyNG-specific Android, Apple, tvOS, and Flatpak application identities for store and package submissions.
- Remove the inherited WinGet publisher and add the PlezyNG Discord support link to the README.

### Changed

- Update remaining app and OAuth messages to PlezyNG and make donation copy provider-neutral.
- Keep Android signing material until all signed store builds finish, and clean it up afterward.
- Fix music fade gain handling across track transitions and avoid visualizer profile requests before the active track is ready.

### Removed

- Remove unused upstream website, legacy app-store and Sentry upload automation, and funding links.
