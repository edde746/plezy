# Changelog

## [Unreleased]

- Add opt-in subtitle-on-mute for library playback, retrying after the native track catalog arrives and restoring a temporary Off override on unmute unless the viewer changes tracks or the item changes.
- Extend opt-in subtitle-on-mute to standalone source video playback with guarded restoration of the prior track on unmute.
- Add a configurable shortcut to reset subtitle timing to zero through the selected persistence scope and show the applied value.

- Carry selected SDH/closed-caption subtitle intent across library episode changes and saved show preferences, infer the role from older title-only preferences, and preserve the existing server fallback when the matching caption class is unavailable.

- Read BOM-marked UTF-16LE/BE subtitle text for cue inspection and corrected export while preserving source encoding and line endings.

- Add current subtitle cue copy, previous/next cue navigation, and replay with an adjustable preroll for persistent standalone MPV text subtitles.

- Fix clean tvOS CocoaPods setup, Android 17 preview SDK provisioning, and short-path Apple native-asset builds on private JIT runners.
- Fix the macOS native reliability target to import the `PlezyNG` app module.
- Require Android host native-test tools to be provisioned on the private runner before CI starts.

- Add an MPV subtitle-drift preview that applies calibration temporarily and restores prior timing on cancel; saving commits the read-back values.
- Add one-step undo for the most recent applied MPV subtitle drift calibration or reset, including its prior scoped rate and delay.
- Retain downloaded OpenSubtitles text subtitles for standalone MPV VOD, bound to profile, source item, edition and file fingerprint; verify content hashes when restoring and enforce per-file asset limits. Preserve session-only cleanup for transient and live playback.
- Roll back native sync timing when saving an offset fails, keeping player state, confirmation state and persisted settings consistent.
- Export affine-corrected SRT/WebVTT and simple ASS/SSA copies for standalone MPV VOD subtitles; preserve source metadata and cue payload, confirm before removing cues wholly before playback starts, and refuse ASS/SSA karaoke/animation or Effect timing the exporter cannot safely preserve.
- Align a selected SRT/WebVTT cue to the current standalone MPV playback position and persist the one-anchor correction for the active subtitle and audio stream.
- Preview actual cue times and text before applying direct OpenSubtitles SRT, WebVTT, ASS, and SSA downloads on standalone file playback.
- Add subtitle sync controls to standalone MPV VOD OpenSubtitles assets. Persist delay and drift rate by the current audio descriptor, reapply only matching audio calibration after a track switch, and restore corrections only when edition, source file, and subtitle digest still match.
- Search OpenSubtitles by moviehash when a local or cached file is available and its byte size matches the source record; rank reported hash matches ahead of title-only results.
- Add bounded two-anchor subtitle drift calibration for MPV text tracks. Capture matching playback positions, fit one timestamp multiplier plus delay, persist both in the existing scope, and exclude unsupported players and known bitmap subtitle codecs.
- Add exact millisecond audio/subtitle sync entry and backend-aware local subtitle import: MPV keeps its existing formats, Android ExoPlayer accepts SRT/ASS/SSA/VTT on VOD, and Tizen/webOS add SRT/VTT overlays.
- Add a separately persisted sync offset for MPV's secondary subtitle track, using the existing scoped timing controls.
- Import backend-supported subtitle files from bounded ZIP archives; validate safe entry paths, reject symbolic links, and materialize only the selected subtitle or paired IDX/SUB files into a temporary app cache.
- Add previous/next subtitle cue alignment on MPV, persisting the player-reported offset through the existing scoped controls.
- Expand in-player subtitle readability controls with text color, weight, outline, and background adjustments on MPV and ExoPlayer; hide the style action on unsupported backends. Add a one-tap reset to stored style defaults.
- Add normalized provider, evidence, and licensed-offer contracts with bounded, no-cache availability lookup; keep offers non-actionable until approval and exclude generic OPDS purchase links from local-file access.
- Make a single tap or click toggle playback by default across platforms, with a preference to show the playback controls instead.
- Add signed visualizer catalog support with release-pinned Ed25519 keys, quorum verification, explicit refresh, revocation and rollback protection, and durable install receipts. Remote updates remain disabled until release keys are configured.

- Verify the pinned Windows installer compiler by running its version probe, supporting Inno Setup's zeroed executable version metadata without weakening signature or payload checks.

- Verify publication tools supplied by the private runner bootstrap without requiring administrator access in restricted metadata jobs.

- Publish checksum-verified Snap packages with the same pinned container toolchain used for packaging, preserving private proxy routing and keeping store credentials out of command arguments.

- Prepare release-channel jobs for fresh private runners: explicit GitHub repository context before checkout, native Ruby extension prerequisites, and proxy routing for both BuildKit and container build downloads.

- Provision checksum- and publisher-verified NuGet and Inno Setup before Windows builds, and route ARM64 jobs through the existing PC runner pool.

- Initialize webOS engine dependencies from Flutter's pinned checkout template, and build Snap packages in a digest-pinned Ubuntu 24.04 container on each native private runner architecture.

- Preserve localized error messages from Companion Remote pairing fallbacks.

- Hide URL credentials, query strings, and fragments in HTTP consent prompts.

- Provision Android toolchains from every module's Gradle pins and configure both Java and Gradle downloads for the private runner proxy before SDK setup.
- Improve TV detail announcements with spaced episode labels and keep the download-location settings row compact.

- Retain checksum-verified webOS candidates and their exact source/run receipts in private storage after ephemeral runners exit, so device qualification can use the built package.

- Keep encrypted cloud sync confined to generated state files in dedicated provider locations; reject unsafe WebDAV roots and encoded traversal before any request.
- Add profile-scoped stereo, quad and 5.1 Steam audio requests with bounded Opus multistream decoding, explicit speaker mapping and a stereo compatibility retry for unsupported layouts or outputs.

- Preserve TV navigation-remote assistance for player one without consuming a Steam gamepad seat; release both input paths when a composite device disconnects.

- Add opt-in Companion Remote controls for active PlezyNG game streams: inspect titles, choose audio, mute, fullscreen and confirm disconnect, using temporary session handles that expire on reconnection or replacement.
- Prevent a timed-out Steam host inventory check from launching later, using monotonic deadlines and explicit operation retirement.

- Add live Steam connection details from native receiver counters and host adaptation messages, including actual codec, frame rate, received video payload, queue depth and input reliability; opening details releases game input and keeps measurements local.

- Add one-to-four independent Android Steam controller seats, with a profile setting, stable HID identities, shared native/Flutter device mapping and per-device disconnect cleanup; preserve the single-controller default.

- Add on-demand Steam achievements, news and optional friends-playing context to game details, with identity-bound server requests, spoiler protection and confirmed Steam destinations.
- Add separately permissioned Companion Remote requests to launch installed Steam games, request installation, and open Steam/downloads on the authenticated computer; reject replayed or arbitrary commands and preserve Steam's authority over launch/install results.
- Unify Steam games across computers and library drives with one poster grid, shared favorites, computer filters, timestamped installation snapshots and optional encrypted Companion Remote inventory sharing.
- Refresh linked Steam catalogs with encrypted, revocable, identity-scoped credentials while retaining compatibility with older relays and saved game libraries.
- Add profile-scoped Android Steam quality and codec preferences, first-frame connection state, accessible reconnect controls and teardown acknowledgement before retrying a stream. Other embedded receiver platforms remain in development.

- Apply the coral ribbon identity across native launchers, store artwork and in-app branding, with light/dark marks, matching wordmarks and simplified small-size icons.

- Add metadata-backed mood and familiarity filters, explicit local genre taste controls with hide/restore/reset, private co-present shortlist voting, optional bounded AI reranking, Open Library catalog-only candidates, and gated borrower-catalog candidates to Find your next.
- Add capped, disposable OPDS sample previews, exact-ID adaptation matching, side-by-side Saved-pick comparison, and opt-in encrypted Saved-pick sync with exact-identity re-resolution.
- Add a searchable, region-aware directory of official video, rental, book, audiobook, comics, music and game storefronts to Services and title details; add Google Books catalog search with country-specific sale metadata and official purchase handoff.
- Add a previewed Trakt movie-history CSV export for manual Letterboxd import, preserving rewatches and splitting oversized exports into safe files.
- Surface free/ad-supported video services first and add the Samsung TV Plus official handoff; keep title-level availability disabled until a supplier is approved.
- Fix NFS source setup so mount, identity, and RPC-with-TLS controls appear without showing username or password fields.
- Add OpenSubsonic music-server browsing and playback, plus RSS/Atom podcast subscriptions with encrypted feed URLs and OPML import/export in the existing Files and books experience.
- Normalize punctuation around inline markup in podcast episode descriptions.
- Keep file-source activation profile-scoped through download and shelf reconciliation, and stop cloud settings backup or restore when the initiating profile session changes.
- Require every release-critical CI job, including each native platform matrix row, to pass for the exact release commit; keep implementation and qualification claims in a source-linked capability ledger.
- Add household readiness checks and a QR support flow that drafts a privacy-safe GitHub issue, with optional redacted log upload.
- Add profile-local Find your next review history with localized timestamps and safe detail revalidation.
- Add exact genre filtering across server, catalog, and publication picks within the existing filter sheet.
- Filter Find your next by its displayed source within the existing filter sheet.
- Search Saved picks by title, source, type, or subtitle; Shuffle uses the matching shortlist.
- Add a Home shortcut that opens Saved picks without loading the discovery deck.
- Let people shuffle a saved pick back onto the deck for a deliberate action, without auto-starting playback.
- Clear all active Find your next filters directly from a no-match result.
- Link the QR GitHub issue draft directly from Household setup for faster problem reporting.
- Fix compile errors in discovery, source details and issue reporting by using existing translations and framework symbols; localize the Steam source badge.
- Offer the same QR report flow from the startup failure screen, alongside copy and log upload.
- Include the startup phase and exception type in its reviewed GitHub issue draft while excluding the raw message and stack trace from the QR payload.
- Search the full Find your next source and genre option lists from the existing filter sheet when the quick chips are insufficient.
- Retry an individual Find your next history pick into the deck without changing its Saved picks membership or launching playback.
- Keep Files search accessible during server outages and index identified video titles as well as original filenames, with a bounded migration of existing search data.
- Rank library copies by verified offline access, reachability, complete parts, device codec acceptance and local/remote/cellular quality limits before resolution, updating the existing copy list when connectivity changes.
- Preserve the last reliable Files playback position across native stream failures and expose Retry in the existing player without advancing editions or marking failed playback finished.
- Verify downloaded representations on disk before showing offline availability, require all audiobook/video parts, and reject server versions with a known missing part.
- Include indexed Files and books in main Search with shared relevance, media-kind filters, TV focus, partial-failure results and profile-switch invalidation.
- Accept branded `plezyng://` links across Android, Apple, Linux and Windows while preserving both existing aliases; correct PlezyNG Flatpak launch instructions.
- Bind release builds and configured publication workflows to the exact main commit, and resolve pinned Apple packages before native CI tests.
- Attach the validated ARM Tizen tester handoff to versioned releases and fail closed if its package, checksum, provenance or toolchain files are missing.
- Retain previous server results when a new search is cancelled, while preserving indexed Files and Seerr results.
- Route Windows x64 native CI through the private Packer JIT workflow allowlist.
- Lock iOS, macOS and tvOS CocoaPods dependencies for CI, and retain root dependency overrides when resolving tvOS packages.
- Fix clean tvOS CocoaPods setup, Android 17 preview SDK provisioning, and short-path Apple native-asset builds on private JIT runners.
- Fix the macOS native reliability target to import the `PlezyNG` app module.
- Require Android host native-test tools to be provisioned on the private runner before CI starts.
- Include the Steam audio labels in the explicit English fallback manifest used by strict localization checks.
- Set ThreadSanitizer ASLR entropy through the disposable runner's authorized sysctl.
- Prepare an ephemeral default keychain for the optional Xcode cloud-signing path for iOS App Store builds.

### Localization

- Keep the new Steam audio setting labels available through an explicit English fallback until reviewed translations are available.

### Release automation

- Validate all platform assets before publishing and dispatch configured release channels from one private-JIT orchestrator.
- Retry transient Flathub disconnects while preparing the Linux release runtime and SDK.

### Platform integration

- Keep argument-aware deep-link startup compatible with the webOS entrypoint and format Windows link forwarding for the native toolchain.

### VLC feature parity

- Expand the VLC feature comparison with safe local playlist references, more conversion formats, MPV audio effects, device-local playback bookmarks and temporary A/B loops in existing playback controls.
- Add bounded desktop folder queues and named device-local bookmarks for seekable Open media audio while preserving existing bookmark data.
- Add direct source-queue browsing, upcoming-file shuffle, repeat modes, and item selection in the existing adaptive player sheet; keep audiobook/server order and current-item progress intact.
- Save eligible same-folder desktop file queues as reopenable M3U playlists, and select alternate video tracks through existing MPV playback controls.
- Show direct-input MPV file details in the shared File Info sheet, and expose edition/disc-title switching only when multiple choices are available.
- Preview discovered desktop camera and display inputs in the existing MPV player from Media tools → Capture; keep preview session-only and video-only.
- Use optional MPV audio-analysis metadata in the existing visualizer when Plex loudness data is unavailable, and show conversion profiles only when the installed FFmpeg build supports them.
- Fix the MPV edition selector so it refreshes when a new file loads, without passing an asynchronous value through Flutter's state update callback.
- Keep temporary HLS sharing within its startup window for long-GOP sources by forcing keyframes at the segment cadence; verify that playlist and media segments remain token-scoped and the listener closes cleanly.
- Translate the added video-track, playlist, edition, and capture-preview cues across supported locales, and use the converter's concise help on the existing Open media tile.

## [3.0.0] - 2026-10-27

This release gathers PlezyNG’s feature work since the fork, platform expansion, and security updates. Experimental playback and platform paths remain identified as experimental below.

### Added

#### Release automation

- Add one-command native dependency refresh and all-platform private-JIT release orchestration.
- Reuse complete, checksum-verified native platform groups after another platform fails, while requiring the full artifact set before updating app dependencies.
- Bind release builds and configured publication workflows to the exact main commit, and resolve pinned Apple packages before native CI tests.
- Validate all platform assets before publishing and dispatch configured release channels through the private-JIT orchestrator.
- Include ARM webOS and Tizen tester builds in versioned releases, with pinned SDK and host-tool setup for Android, webOS and Tizen.
- Provision pinned Android SDK packages and install hash-verified Python/Ninja plus host prerequisites for Android, webOS and Tizen private JIT builds.

#### Localization

- Complete translated labels for deep links and playback screen-lock controls across supported locales.

#### Universal media tools

- Add one Open media workspace for direct streams, playlists, local files and desktop discs, plus desktop conversion, live-stream recording, Wi-Fi transfer, and MPV picture tools. Preserve live `#EXTINF` entries with playlist metadata, and keep favorites and nested launchers in the existing focus-aware Files and books rows.
- Add integrated VLC-inspired media capture, private-LAN HLS sharing, consent-based search extensions and the `plezyctl` helper, with accessible cues, deep links, platform registrations and setup documentation.

#### Playback and downloads

- Add a PlezyNG mpv playback backend, direct Plex server sign-in without plex.tv, and external-player return with playback progress sync.
- Add a pre-play audio/subtitle picker; per-show audio and subtitle preferences; device-language subtitle selection and server subtitle downloads; local subtitle loading in mpv; subtitle size, position, live preview and RGB styling; subtitle-delay shortcuts; and player buffer controls.
- Add touch swipe-to-seek, frame-by-frame stepping while paused, reliable video-playlist repeat, and background video audio on handheld Android and iOS.
- Add video shuffle across Plex, Jellyfin and Emby, a preferred-server setting, remote-streaming quality limits, and separate Continue Watching and Next Up rows.
- Add Plex server-side converted downloads, Jellyfin/Emby converted-download quality, and per-rule quality presets.
- Add per-server Continue Watching downloads, Sync now, random episode selection with custom counts, download storage and per-item sizes, and explicit removal of failed or paused downloads.
- Add selectable local movie prerolls, Plex server prerolls, Jellyfin/Emby cinema intros and theme songs on media detail pages.
- Add program-aware Plex Live TV timeshift, Google Cast playback handoff, and Android playback automation links.
- Add configurable Plex commercial-marker skipping, six animated music visualizers and optional loudness-aware music fades.

#### Libraries and discovery

- Add Plex watchlist filtering and sorting, Seerr requests for titles missing from the server, custom MDBList shelves, director credits with person pages, library item counts, bulk watch-state updates and a version picker that remembers choices across episodes.
- Add plezy://watch links, random movie selection, estimated finish times and profile-scoped new-episode alerts.
- Add local profile PIN gates for Settings, Explore and download deletion, per-profile Explore visibility, and optional hiding of empty libraries.
- Add Find your next, a profile-local cross-media discovery deck for libraries, live TV, file sources and completed downloads, with filters, saved picks, Undo and normal playback routes.
- Add a content screensaver that rotates artwork from selected connected libraries.

#### Sources and cross-device sync

- Add read-only SMB 2/3, FTP/FTPES/FTPS, pinned-host-key SFTP and NFSv3 sources, including optional NFS RPC-with-TLS, custom trust certificates and client identities; add DLNA discovery with manual server entry.
- Add standalone-video matching through Trakt, OpenSubtitles search and downloads, and Kodi/Jellyfin NFO sidecar metadata and posters.
- Add encrypted WebDAV state sync for file-source playback progress and notes, plus HTTPS WebDAV settings backup and restore.
- Add explicit cross-provider item and edition pairing so shared progress, bookmarks and notes can be mapped between sources.

#### Books, comics and accessibility

- Add ebooks, comics and multipart audiobooks with reading preferences, zoom, bookmarks, notes, offline editions and chapter-aware controls; connect local files, OPDS, Audiobookshelf, Google Drive, OneDrive, Dropbox, WebDAV and S3-compatible storage.
- Add Komga comic sources, ComicInfo metadata, streamed comic pages, spreads, continuous scrolling, thumbnails, touch zoom and per-comic display settings.
- Add encrypted cross-device audiobook progress, bookmarks and notes, with public-library discovery and a default-off OverDrive/Libby handoff.
- Add app-wide accessibility preferences for text size, bold text, contrast, reduced motion and larger controls, along with expanded language, regional-format and metadata-language choices.

#### Games, workspace and Dolby Vision

- Add a Games category with LAN discovery, profile libraries, pairing and Android Moonlight streaming; add experimental Android Steam account catalog and streaming support and experimental Pyrowave support.
- Add a retained Multiview workspace for video, music, sources and publications, with floating/split layouts, shared audio and input ownership, two simultaneous video sessions, and an Android Steam game surface.
- Add profile-aware Dolby Vision routing and server-transcode compatibility checks. Provide isolated experimental P7 FEL paths for Android, Windows and Apple, plus a Linux gpu-next option and offline HDR/SDR tools; these experiments remain outside the production engine pin and require device qualification.

#### Platforms and release channels

- Add experimental LG webOS TV playback with OLED sign-in, OS-backed credentials and app-private artwork caching, plus ARM package build tooling; keep its IPK out of public artifacts until redistribution and exact-device qualification are approved.
- Add experimental Samsung Tizen TV playback, signed TPK packaging and a disabled Apps2Samsung catalog recipe.
- Add PlezyNG-branded cross-platform release packaging, versioned private-JIT builds, checksums and credential-gated submissions for mobile, desktop and TV stores, plus Linux packages, Windows package-manager submissions and multi-architecture relay images.
- Attach a downloadable ARM Samsung Tizen tester handoff with its checksum, source and toolchain evidence; label it as development-signed and requiring TV re-signing.
- Add a seven-day full-app trial followed by a one-time lifetime unlock, a public privacy notice and PlezyNG branding across app icons, launchers, TV and store artwork.

### Security

- Upgrade Cronet to 500.1.0 for CVE-2026-11215.
- Upgrade Mbed TLS to 3.6.7 for the affected 3.6.x security advisories.
- Encrypt cross-device audiobook progress, bookmarks and notes with AES-256-GCM; cloud providers store only encrypted state generations.
- Upgrade the branding asset generator to Pillow 13.0.0 to include upstream security fixes.
- Clarify that the branding verifier parses only the checked-in Android launcher manifest.
- Clarify that the publication reader's local WebSocket bridge is restricted to loopback and a per-session capability.
- Restrict OAuth authorization redirects to configured provider hosts, preserve relay error status for log downloads, and remove the bundled Trakt client secret.
- Update the relay to Go 1.27.3 for GO-2026-6809 and refresh its immutable container pin.

- Require a random, revocable pairing code for companion remotes and bound unauthenticated WebSocket traffic before fragmented messages can accumulate. Update both devices and pair once.
- Verify playback TLS certificates, provide trust roots for OpenSSL players, prefer HTTPS server discovery, and require explicit consent for HTTP sign-in. Keep authenticated failover on HTTPS except for the exact Direct Plex or Jellyfin endpoint the user approved.
- Move credential keys to OS secure storage and migrate tracker tokens and Seerr cookies without signing users out. Preserve old credentials when the keychain is temporarily unavailable.
- Use 130-bit log retrieval codes; existing shared links keep their original expiry.
- Require a fork-owned updater public key and verify it matches the signing seed. Builds without a configured key retain GitHub release notifications and manual downloads.

### Changed

- Complete locale catalogs, record explicit fallbacks for new Steam account copy, fix release validation, and configure Gradle to use the private JIT runner's HTTPS proxy.
- Keep argument-aware deep-link startup compatible with the webOS entrypoint and format Windows deep-link forwarding for the native toolchain.
- Keep settings import and reset feedback visible when root rebuilds for locale or TV-mode changes.
- Route Windows release packaging through PlezyNG's private Windows runner.
- Use shared focus controls for Home row dialogs, subtitle styling and video equalizer sliders, with TV text input for Home row names.
- Use Plezy's shared Material Symbols icons for file-source, source-detail, player and standalone subtitle-search actions.
- Keep library/publication-reader search, page entry and bookmark notes on shared focus-aware fields and scoped dialog actions.
- Keep comic page images resident during pinch gestures; apply zoom once when the gesture ends.
- Route public-library forms and email dialogs through shared focus-aware fields and dialog actions for keyboard and TV navigation.
- Show source, audiobook sync and lending search errors with the same live, theme-colored feedback.
- Report failed sync rules and unavailable-server retries, and give orphan review one safe initial focus target.
- Align audiobook sync conflicts, playback input dialogs and source menus with shared Mono rows, focus and compact overflow patterns.
- Validate Seerr sign-in fields before asking users to allow an unencrypted HTTP connection.
- Keep Games entry points limited to supported Android handheld and TV builds; style Steam stream controls and dialogs with Mono surfaces, focus states and localized touch accessibility text.
- Refresh the sign-in background with current plezyng.app artwork, including WebP and high-resolution assets for 4K screens, responsive login choices and QR sizing.
- Keep SMB setup copy localized and show the Videos shelf by default only for local and SMB sources.
- Polish catalog, source, TV and cross-media discovery surfaces with Plezy's Mono focus and icon styles, RTL-aware navigation, accessible controls, responsive layouts, and localized error handling.
- Complete localization coverage across settings, playback, downloads and accessibility labels; improve right-to-left focus navigation, numeric input, localized units and native permission prompts, and correct regional wording in source setup and Find your next controls.
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

- Require explicit action and private-pool selections for build, scan, package and release dispatches; release builds use an exact version tag and validate the release commit on private JIT runners.
- Prepare Android SDK, pinned CocoaPods and webOS build prerequisites on private runners; preserve the JIT proxy for package tooling and accept Ubuntu’s canonical os-release link in webOS preflight.
### Fixed

- Restore TV remote focus to the Retry action while Plex sign-in is waiting.
- Stop Games host setup when saving fails, and show a retry state when the game library cannot load.
- Respect reduced motion in Supporter sheet scrolling, expose mobile profile PIN entry to screen readers, and retain D-pad focus on the locked-settings action; let PIN controls wrap at large text sizes.
- Restore visible keyboard and remote focus in workspace controls and Games forms; show full pane titles in pointer tooltips and isolate game and host metadata in right-to-left labels.
- Re-check a protected local profile PIN before every explicit download deletion, keep cancelled-download dismissal safe, and use explicit button actions for keyboard and remote Find Next controls.
- Keep compact Find Next artwork retries in the focus order and isolate recommendation summaries for mixed-direction text.
- Use shared focus-aware fields and viewport-sized dialogs for cloud backup, custom players, MDBList shelf editing, searchable settings, and Home Layout.
- Keep Games search scoped to the active profile, size pairing dialogs and QR codes for the available viewport, and report when the Sunshine PIN page cannot be opened.
- Restore navigator-managed Back handling in the companion remote dialog, use valid directional insets in RTL trees, and resolve the Flutter/intl `TextDirection` import collision.
- Make Multiview music visualizer presets change the scene, isolate track labels in mixed-direction text, and give music/source playback controls the shared keyboard and remote focus treatment.
- Keep playback controls and elapsed/total times in their familiar left-to-right order in RTL layouts, and isolate source titles and chapter names from surrounding text.
- Complete discovery, source-setup and subtitle-search translations; fix reviewed library and audiobook wording, add Arabic and Asian subtitle-language choices, and preserve regional numerals, mixed-direction titles and large-text layouts.
- Use the localized sort and filter labels in the audiobook library menu.
- Use CocoaPods for iOS and macOS builds until the pinned WebView plugin compiles with Xcode 26’s Swift Package Manager integration.
- Let Xcode choose signing identities for iOS and tvOS archives instead of forcing one across all targets.
- Keep raw companion remote transport exceptions out of discovery and session messages.
- Preserve existing TV and keyboard toolbar focus order when adding Find your next discovery actions.
- Localize standalone source setup and subtitle search, use shared icons and TV-aware text fields, and report when Trakt finds no metadata matches.
- Show NFS mount, identity, and RPC-with-TLS controls in its source setup, persist OPDS stream-only file flags, and handle standalone metadata arrays and missing DLNA totals.
- Fix FTP/SFTP stream typing and the SMB license text constructor for current Dart/Flutter APIs.
- Observe failures from shared online metadata lookups during cleanup.
- Keep entitlement-controlled themes and icons locked when store access is disabled in the build.
- Remove stale SVG imports after switching the setup and app-icon previews back to raster artwork.
- Localize the About screen privacy-policy link.
- Cover AVFoundation speed flush ordering deterministically when simulator audio is unavailable.
- Keep unsigned macOS release builds available when only the shared mobile Apple team ID is configured.

### Removed

- Remove unused upstream website, legacy app-store and Sentry upload automation, and funding links.
