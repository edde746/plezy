# Changelog

## [Unreleased]

- Preserve the private JIT proxy for the optional Linux package CI smoke build.
- Install the Android SDK on private JIT build and Android test jobs before Flutter and Gradle use it.
- Fix private multi-platform builds by preserving the JIT proxy for fpm, accepting Ubuntu's canonical os-release symlink in the webOS preflight, and completing the shared audio plugin protocol.
- Make scans, platform builds, package uploads, and release announcements manual-only; require each dispatch to name an action and private pool, with no release-event publisher fan-out.
- Require manual build dispatches to select an action and private pool; release dispatches use an exact version tag, and ordinary tag pushes no longer start builds.
- Prepare the versioned 2.25.0 main-tag release with private JIT builds across the supported platforms, including ARM webOS and Tizen candidates.
- Fix private release builds by provisioning a webOS test temp directory and pinned CocoaPods for the Apple targets.

## [2.25.0] - 2026-10-27

This release records PlezyNG's additive feature work since the fork, along with the related security, accessibility, playback, source, reader, platform, and release-system changes. Experimental paths retain their qualification status below.

- Require platform build dispatches to carry explicit action and private-pool tags, and gate every build job to that selection.
- Let build-only platform runs validate the trusted branch without waiting for a separate CI dispatch; retain that CI prerequisite for release actions.
- Restore shared focus navigation across source browsing and dialogs, announce source and sync errors accessibly, and explain shared-ID requirements before recovery imports.
- Use shared focus controls for source search and page loading; make the exclusive sync confirmation scrollable with remote focus support.
- Make NFS read measurement results accurately labelled, locale-formatted, and usable with remote focus and smaller screens.
- Improve locale-aware metrics, remote focus and responsive dialogs across source browsing, NFS measurements, offline storage and sync recovery.
- Improve locale-aware metrics, remote focus and responsive dialogs across source browsing, item pairing, NFS measurements, offline storage and sync recovery.
- Improve source browsing and pairing with locale-aware metrics, clearer removal guidance, TV focus and responsive dialogs for offline storage and sync recovery.
- Improve source browsing and pairing with locale-aware metrics, clearer download-removal and recovery-import guidance, TV focus and responsive dialogs.
- Require an explicit confirmation before exclusive encrypted sync pauses Audiobookshelf progress and bookmark sync.
- Require an explicit confirmation before exclusive encrypted sync pauses Audiobookshelf progress and bookmark sync, with remote-focusable actions and scrollable privacy copy.
- Confirm encrypted sync setup with a privacy summary and keep provider progress/bookmark writes on separate retry paths.
- Isolate provider sync failures by source with bounded exponential retry backoff, retaining failed events while unrelated pending work proceeds.
- Provision pinned Chromium and make the existing publication reader browser suite required in the private JIT CI job.
- Reuse NFSv3 RPC/TLS sessions across calls and limit publication downloads to two active transfers, preserving durable records for partial recovery.
- Harden file-source profile isolation, option-preserving edits, scan reconciliation, discovery Undo retention, and bounded SQLite shelf/search/progress queries.
- Page cached source and shelf browsing in SQLite, use trigram FTS when supported, fetch progress only for visible entries, and reuse bounded local directory snapshots across pages.
- Require an explicit confirmation before exclusive encrypted sync pauses Audiobookshelf progress and bookmark sync, with remote-focusable dialog actions.
- Harden file-source profile isolation, option-preserving edits, scan reconciliation, discovery Undo retention, and bounded folder/progress queries.
- Bind cloud settings backups and restore writes to the initiating profile, enforce a 4 MiB download bound, and roll back an import if ownership changes.
- Require successful CI for the exact release commit while keeping release validation on private JIT runners.
- Corroborate StoreKit purchase events against verified transaction history and resume eligible direct-source downloads.

- Increase Multiview title-bar, session-tray, and resize controls to consistent 48dp focus targets.
- Release embedded game input when focus moves into workspace controls, and restore it when focus returns to the game surface.
- Keep the Multiview dock and session tray inside safe areas and fit the tray to short, narrow windows.
- Give Multiview, Games, and media workspace actions the shared TV focus indicator and D-pad activation behavior.
- Use shared TV focus and dialog controls for Games setup, search, and pairing; clear the search when the active profile changes.
- Give Android Steam touch controls at least 48dp hit areas, resolve overlaps by nearest control, and expose their localized description only while visible.
- Keep the Multiview dock and session tray clear of display cutouts; give the Steam touch controller usable 48dp targets, nearest-control overlap handling, and a localized description while active.
- Add an app-owned Multiview workspace for retained video, music, source playback and publication surfaces, with floating/split layouts, shared audio and input ownership, and independent native channels for two simultaneous video sessions.
- Add a retained Android Steam game surface to Multiview with workspace audio ownership and gamepad, touch, and mouse input restricted to the selected pane; other game engines remain on their existing launch paths.


- Route identified Dolby Vision sources through a profile-aware policy before opening them: keep profiles reported by the native path (or an explicit Profile 7 experiment), otherwise request an SDR encode and refuse the rendition unless every HLS video variant declares SDR.
- Gate server conversions by source profile and backend: retain Jellyfin's P5/P8 route and HDR10-compatible P7, allow only known HDR10-compatible P7/P8.1 on Plex/Emby, and refuse unsupported or unknown combinations instead of direct-playing them.
- Send unsupported downloaded Dolby Vision files through the server route when online, bypass downloaded copies on an explicit retry, and fail clearly when offline playback has no reported local profile path.
- Prepare native FEL ports with a Windows D3D11 engine builder and verified app bundle selection, unsigned Apple device-SDK build targets, and a production patch audit. Full Android/webOS FEL and cross-platform device qualification remain pending.

- Honor Android Dolby Vision output and player tone-mapping preferences through the in-app compatibility player; preserve Profile 5 reshaping on software fallback. Add display-constrained experimental routing and real-time HDR/SDR output targets to the isolated DV launcher.

- Add a pinned experimental LG webOS ARMv7 engine/IPK build, manual JIT-only validation, an LG-supported Ubuntu/toolchain preflight, and an evidence-based Re:New matrix. Keep the IPK out of public workflow artifacts and ordinary releases until runtime redistribution and exact-device qualification pass; release opt-in checks the approved source, version, and package hash.
- Record the exact 2026 C6H model/firmware evidence and list additional 2026 LG firmware cohorts as unqualified test candidates.
- Reconcile C6 install/launch logs with the distinct IPK hashes; keep visible-frame qualification tied to the exact candidate.
- Route Windows x64 release builds and package-manager submissions through private JIT runners.
- Keep Games gated on supported platforms and use shared focus, text-input, and dialog controls for its embedded game flows.
- Keep mobile navigation destinations at usable widths with a focusable More sheet for overflow tabs.
- Align settings and navigation with localized values, RTL direction cues, and stable keyboard/TV focus order; bound long metadata and announce sync feedback.
- Polish focus and dialog flows across playback, Settings, sources (including notes), lending, and discovery; keep compact artwork retry focusable, align subtitle previews with device preferences, keep search keyboard-safe, isolate external metadata for RTL, and filter Videos by watch progress.
- Let the preroll item picker use the dialog's available results viewport, up to 560dp.
- Route Games search, page actions, and dialogs through the shared TV focus controls; keep mobile navigation destinations usable with optional tabs in a focusable More sheet.
- Add a pinned experimental LG webOS ARMv7 engine/IPK build and verification path, with a webOS 26 Re:New+ compatibility matrix.
- Show public-library loading progress and a keyboard/remote-friendly retry action when its saved libraries cannot load.
- Add TV-aware text input and shared focus controls to Games search, setup, pairing, shortcuts, and actions.
- Route compact artwork retry through shared remote focus and isolate provider text in discovery cards.
- Keep Find your next decisions on labelled actions; D-pad arrows move focus and Select activates the focused card or action.
- Keep mobile navigation destinations readable with a localized overflow sheet on narrow phones.
- Fit the preroll item picker to its available viewport on short screens.
- Refresh the embedded login background from the current PlezyNG website artwork, including a 4K asset for large displays.
- Keep Dolby Vision source-layer flags under the localized source label and identify the experimental P7 FEL route as unqualified in the performance overlay.
- Fit Find your next to the screen with persistent action buttons, mirrored swipe/TV direction cues, contextual help, and artwork that follows the current pick. Restore downloaded and alternate covers, distinguish artwork loading from missing images, and allow failed source covers to be retried.

- Route comic reader pull request checks through private JIT and skip external forks.
- Respect the app text scale in the browser reader and correct comic terminology in affected translations.
- Keep the selected publication thumbnail visible and let reader dialogs scroll without losing their actions.
- Expand comic reading with responsive spreads, RTL wide-page splitting, continuous scroll, thumbnails, touch zoom and per-comic display settings; harden page streaming and add reproducible browser test dependencies.
- Keep comic page images resident during pinch gestures; apply zoom once when the gesture ends.
- Announce comic page load failures, preserve reader focus on retry, and focus the first thumbnail when the page picker opens.
- Repair source-reader merge compatibility and complete missing source setup translations.
- With explicit opt-in, force Android mpv P7 playback through the experimental software FEL graph even when native DV is advertised; switch only after mpv accepts the filter, and keep the existing fallback on unsupported engines.

- Add Windows' opt-in P7 FEL hook on the existing `gpu-next` path, with per-file software decode, fail-closed filter negotiation and decoder-setting restoration.

- Expose the existing Apple P7 conversion controls in Playback settings for the AVFoundation route.

- Add a checksum-verified local Android AAR override for building Plezy against an experimental FEL engine without changing the production engine pin.

- Record synthetic Android FEL Surface evidence and per-platform Dolby Vision playback/output qualification gates; the experimental engine remains separate from production builds.

- Route compact artwork retry through shared remote focus and isolate provider text in discovery cards.
- Keep Find your next decisions on labelled actions; D-pad arrows move focus and Select activates the focused card or action.
- Add experimental comic page streaming, Komga source integration and ComicInfo metadata support.
- Fix file-source metadata and listing edge cases, and validate the experimental webOS ARM build on an LG C6.

### Added

- Add an opt-in Games category with LAN discovery, artwork card grids, profile libraries, PIN/QR pairing, and an embedded Android Moonlight engine with touch controls. Add an experimental embedded Android Steam PIN/streaming adapter with encrypted device trust, direct game-ID launch, H.264/HEVC/Opus and a mobile controller. Steam account catalog import and native streaming ports remain in development; Pyrowave is opt-in experimental Android support and still needs real-host and device performance qualification; Games never hands a stream to another app.

- Add an experimental Samsung Tizen TV player, conservative server playback profiles, signed-TPK build and inspection tooling, and a disabled Apps2Samsung catalogue recipe. ARM release builds now compile with a native C++ runner, pinned SDK bootstrap and headless development signing; the tester handoff includes digest-checked re-signing without recompilation. Hardware qualification and the 2026/Tizen 10 toolchain remain pending.

- Route every GitHub Actions workflow through compatible private JIT capacity, with no GitHub-hosted fallback.
- Require an explicit build or release action and private runner pool for platform builds; add a build-only mode that leaves draft releases untouched.

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
- Trigger private JIT multi-platform release builds from validated `vMAJOR.MINOR.PATCH` tags on `main`, including experimental ARM webOS and Samsung Tizen build jobs by default.
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
- Use shared focus controls for Home row dialogs, subtitle styling and video equalizer sliders, with TV text input for Home row names.
- Use Plezy's shared Material Symbols icons for file-source, source-detail, player and standalone subtitle-search actions.
- Keep library/publication-reader search, page entry and bookmark notes on shared focus-aware fields and scoped dialog actions.
- Route public-library forms and email dialogs through shared focus-aware fields and dialog actions for keyboard and TV navigation.
- Show source, audiobook sync and lending search errors with the same live, theme-colored feedback.
- Report failed sync rules and unavailable-server retries, and give orphan review one safe initial focus target.
- Align audiobook sync conflicts, playback input dialogs and source menus with shared Mono rows, focus and compact overflow patterns.
- Validate Seerr sign-in fields before asking users to allow an unencrypted HTTP connection.
- Keep Games entry points limited to supported Android handheld and TV builds; style Steam stream controls and dialogs with Mono surfaces, focus states and localized touch accessibility text.
- Refresh sign-in with the crisp PlezyNG product artwork and responsive login choices and QR sizing for phone, desktop, TV and 4K screens.
- Refresh sign-in with current plezyng.app product artwork bundled for offline use, including a high-resolution variant and responsive login choices and QR sizing for phone, desktop, TV and 4K screens.
- Keep SMB setup copy localized and show the Videos shelf by default only for local and SMB sources.
- Polish catalog, source, TV and cross-media discovery surfaces to match Plezy's Mono focus, artwork, responsive layout and localized error patterns.
- Complete localization coverage across settings, playback, downloads and accessibility labels; improve right-to-left focus navigation, numeric input, localized units and native permission prompts.
- Mirror navigation affordances and tree controls for right-to-left reading order.
- Keep Steam touch-control hit areas at least 48dp, resolve overlapping targets by nearest control, and expose the localized controller label to Android accessibility.
- Route reader, source-setup, audiobook-sync and player text entry and dialog actions through Plezy's shared focus controls for keyboard and TV navigation.
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

- Restore TV remote focus to the Retry action while Plex sign-in is waiting.
- Stop Games host setup when saving fails, and show a retry state when the game library cannot load.
- Respect reduced motion in Supporter sheet scrolling, expose mobile profile PIN entry to screen readers, and retain D-pad focus on the locked-settings action; let PIN controls wrap at large text sizes.
- Restore visible keyboard and remote focus in workspace controls and Games forms; show full pane titles in pointer tooltips and isolate game and host metadata in right-to-left labels.
- Re-check a protected local profile PIN before every explicit download deletion, keep cancelled-download dismissal safe, and use explicit button actions for keyboard and remote Find Next controls.
- Keep compact Find Next artwork retries in the focus order and isolate recommendation summaries for mixed-direction text.
- Use shared focus-aware fields and viewport-sized dialogs for cloud backup, custom players, MDBList shelf editing, searchable settings, and Home Layout.
- Keep Games search scoped to the active profile, size pairing dialogs and QR codes for the available viewport, and report when the Sunshine PIN page cannot be opened.
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
