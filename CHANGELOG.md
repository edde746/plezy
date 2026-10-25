# Changelog

## [Unreleased]

### Added

- Add configurable skipping for Plex-detected commercial markers, plus a native loudness visualizer and opt-in loudness-aware music fades.
- Added changelog enforcement, changelog-based release notes, and Discord announcements for published PlezyNG releases.
- Require an explicit versioned release dispatch, and move release downloads and package updates to PlezyNG.
- Add credential-gated signed Android Play/Amazon and Apple App Store assets, manual mobile-store submissions, an identity-gated Windows Store MSIX bundle, release checksums, Windows package-manager submissions, and multi-architecture relay container publishing.
- Use PlezyNG-specific Android, Apple, tvOS, and Flatpak application identities for store and package submissions.
- Remove the inherited WinGet publisher and add the PlezyNG Discord support link to the README.

### Changed

- Update remaining app and OAuth messages to PlezyNG and make donation copy provider-neutral.
- Keep Android signing material until all signed store builds finish, and clean it up afterward.

### Removed

- Remove unused upstream website, legacy app-store and Sentry upload automation, and funding links.
