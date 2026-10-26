# Changelog

## [Unreleased]

- Add a pinned experimental LG webOS ARMv7 engine/IPK build and verification path, with a webOS 26 Re:New+ compatibility matrix.
- Fit Find your next to the screen with persistent action buttons, mirrored swipe/TV direction cues, contextual help, and artwork that follows the current pick. Restore downloaded and alternate covers, distinguish artwork loading from missing images, and allow failed source covers to be retried.

- Add experimental comic page streaming, Komga source integration and ComicInfo metadata support.
- Fix file-source metadata and listing edge cases, and validate the experimental webOS ARM build on an LG C6.

### Added

- Add device-local Dolby Vision experiment and compatibility switches, enhancement-layer diagnostics, pinned Apple/FelBaker experiments, and an offline HDR/SDR companion encoder; preserve Luna’s real P7 FEL graph evidence and remaining device qualification work.
- Route trusted-main release validation, Android artifacts, and draft-release assembly through the private JIT runner pool.
- Add SMB2/3 read-only NAS sources on Android, iOS, macOS, Windows, Linux, and Apple TV, with a Videos library shelf and resumable video watch progress.
- Add passive FTP/FTPES/FTPS, pinned-host-key SFTP, and read-only NFSv3 sources with byte-range playback; NFS can require TLS 1.3 RPC-with-TLS, custom trust certificates, or a PKCS#12 client identity. Add best-effort SSDP discovery for DLNA ContentDirectory servers with manual URL fallback.
- Automatically match standalone video filenames against Trakt with confidence and ambiguity checks; add online posters, cast, ratings, IDs, and validated trailer links. Manual matching remains available.
- Search and download OpenSubtitles for standalone videos, including SMB files, using source-scoped encrypted API credentials, with accessible search and download progress states.
- Read offline Kodi/Jellyfin NFO sidecars and sibling posters to enrich local and SMB video titles, summaries, ratings, genres, years, and external IDs.
- Sync SMB and other file-source progress and notes across devices through one configured WebDAV state folder.
- Add an isolated experimental Dolby Vision engine build with a Linux gpu-next embedding option and profile inspection lab; full FEL and device output qualification remain pending.
- Add Find your next, a profile-local swipe discovery deck across media libraries, Explore catalogs, live TV, file sources and completed downloads, with format/time filters, Saved picks, Undo and normal Plezy launch routes.
- Add Arabic, Persian, Hebrew, Bengali, Hindi, Indonesian, Malay, Thai, Vietnamese, Czech and Ukrainian interfaces, with regional Spanish, French and Portuguese catalogs.
- Add searchable language controls, independent regional formatting and metadata-language preferences, and Android system app-language synchronization.
- Replace PlezyNG branding across the app, launchers, TV, desktop packages and store artwork with the selected nested-play logo and lower-right NG badge; preserve existing alternate icon selections.
- Add experimental webOS TV support with OLED sign-in, OS-backed credentials, app-private artwork caching, and authenticated native media playback.
- Add a review-first cleanup for orphaned tagged downloads in PlezyNG's default app-managed folders.
- Add an automatically started seven-day full-app trial followed by a USD $2.99 one-time lifetime unlock for Apple, Google Play, and Amazon builds.
- Use the new nested-triangle PlezyNG artwork as the default app icon across platforms and in store listings.
- Add a public privacy notice and link to it from the app's About screen.
- Add ebooks, comics and multipart audiobooks with reading preferences, zoom, bookmarks and notes, offline editions, chapter-aware controls and encrypted cross-device state sync; connect local files, OPDS, Audiobookshelf, Google Drive, OneDrive, Dropbox, WebDAV and S3-compatible storage.
- Add public-library discovery and service handoffs, with OverDrive/Libby circulation prepared behind a default-off Coming soon release flag.
- Add app-wide accessibility preferences for text size, bold text, contrast, reduced motion and larger shared controls; improve keyboard slider navigation and reader affordances.
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

### Security

- Encrypt cross-device audiobook progress, bookmarks and notes with AES-256-GCM; cloud providers store only encrypted state generations.
- Upgrade the branding asset generator to Pillow 13.0.0 to include upstream security fixes.
- Clarify that the branding verifier parses only the checked-in Android launcher manifest.
- Clarify that the publication reader's local WebSocket bridge is restricted to loopback and a per-session capability.
- Restrict OAuth authorization redirects to configured provider hosts, preserve relay error status for log downloads, and remove the bundled Trakt client secret.
- Update the relay to Go 1.27.3 for GO-2026-6809 and refresh its immutable container pin.

- Require a random, revocable pairing code for companion remotes and bound unauthenticated WebSocket traffic before fragmented messages can accumulate. Update both devices and pair once.
- Verify playback TLS certificates, provide trust roots for OpenSSL players, prefer HTTPS server discovery, and require explicit consent for HTTP sign-in. HTTPS connections no longer downgrade through HTTP fallbacks.
- Move credential keys to OS secure storage and migrate tracker tokens and Seerr cookies without signing users out. Preserve old credentials when the keychain is temporarily unavailable.
- Use 130-bit log retrieval codes; existing shared links keep their original expiry.
- Require a fork-owned updater public key and verify it matches the signing seed. Builds without a configured key retain GitHub release notifications and manual downloads.

### Changed

- Route Windows release packaging through PlezyNG's private Windows runner.
- Align audiobook sync conflicts, playback input dialogs and source menus with shared Mono rows, focus and compact overflow patterns.
- Refresh sign-in with the crisp PlezyNG product artwork and responsive login choices and QR sizing for phone, desktop, TV and 4K screens.
- Keep SMB setup copy localized and show the Videos shelf by default only for local and SMB sources.
- Polish catalog, source, TV and cross-media discovery surfaces to match Plezy's Mono focus, artwork, responsive layout and localized error patterns.
- Complete localization coverage across settings, playback, downloads and accessibility labels; improve right-to-left focus navigation, numeric input, localized units and native permission prompts.
- Mirror navigation affordances and tree controls for right-to-left reading order.
- Route the Google Drive source label through localization.
- Keep both iOS SwiftPM lockfiles pinned to the same Google Cast SDK revision.
- Explain the default behavior on the screensaver library selection page.
- Format the download and screensaver library views with Flutter's configured Dart formatter.
- Check iOS audio-output ordering while allowing the Spatial Audio driver on iOS 26.
- Build Android app and plugin modules with SDK 37 and generate BuildConfig for current Android dependencies.
- Brand default and alternate app icons, splash art, and TV launch graphics with the PlezyNG badge.
- Keep the webOS TV package icon generated from the approved NG-badged logo.
- Refresh package and store descriptions to explain PlezyNG's Plex client features.
- Refresh the release-channel guide with configured publishers and remaining credential requirements.
- Record the current Google Play foreground-service demo links and release-run results in the channel guide.
- Declare Bash explicitly when naming the Snap release artifact.
- Update remaining app and OAuth messages to PlezyNG and make donation copy provider-neutral.
- Keep Android signing material until all signed store builds finish, and clean it up afterward.
- Fix music fade gain handling across track transitions and avoid visualizer profile requests before the active track is ready.

### Fixed

- Complete discovery, source-setup and subtitle-search translations; fix reviewed library and audiobook wording, add Arabic and Asian subtitle-language choices, and preserve regional numerals, mixed-direction titles and large-text layouts.
- Use the localized sort and filter labels in the audiobook library menu.
- Use CocoaPods for iOS and macOS builds until the pinned WebView plugin compiles with Xcode 26’s Swift Package Manager integration.
- Let Xcode choose signing identities for iOS and tvOS archives instead of forcing one across all targets.
- Keep raw companion remote transport exceptions out of discovery and session messages.
- Preserve existing TV and keyboard toolbar focus order when adding Find your next discovery actions.
- Localize standalone source setup and subtitle search, use shared icons and TV-aware text fields, and report when Trakt finds no metadata matches.
- Keep entitlement-controlled themes and icons locked when store access is disabled in the build.
- Remove stale SVG imports after switching the setup and app-icon previews back to raster artwork.
- Localize the About screen privacy-policy link.
- Cover AVFoundation speed flush ordering deterministically when simulator audio is unavailable.
- Keep unsigned macOS release builds available when only the shared mobile Apple team ID is configured.

### Removed

- Remove unused upstream website, legacy app-store and Sentry upload automation, and funding links.
