# PlezyNG handoff — remaining work

Status as of 2026-10-25. Repo: `snapetech-org/PlezyNG` (fork of `edde746/plezy`), single branch `main`.
Toolchain: Flutter 3.47.1 (CI pin) at `~/.local/share/flutter`. Codegen: `dart run build_runner build --delete-conflicting-outputs` (drift/freezed/json) and `dart run slang` (i18n). Only `en.i18n.json` needs new keys; other locales fall back to English.

Rule for every item: support Plex, Jellyfin and Emby wherever the server can; say so in the commit when one backend genuinely cannot.

## Done this session

- Download quality (server-converted downloads, Plex download queue `/downloadQueue`), schema v26 `DownloadedMedia.downloadQuality`.
- Branches consolidated into `main`: 4 dependabot bumps, `ab/hdr-keep-alive-probe`, `appcast` (unrelated history), `feat/mpv-android-aar` (already contained), `refactor/focus-consolidation` (BackPressGate + NavigatorBackHandler; ported onto main's screens, see that merge commit message).
- Upstream PRs squashed in: #2738, #1516, #2725, #2811, #1757, #2248, #2797, #2824, #2740, #2681, #2376, #2762, #2601, #2347, #2483, #1584, #2300, #2596, #2563 (+#2561 contained), #2597, #2091, #1197, #1199 (schema v27 `SyncRules.randomEpisodes`).
- Local refs `refs/pr/<n>` hold every fetched upstream PR head: `git fetch upstream pull/N/head:refs/pr/N`.

## Housekeeping first (blocks clean commits)

The repo now has `.githooks/pre-commit` (added in `0826eb922`, not by this session). It currently fails on:
1. **dart format** — files from merged PRs: `lib/media/media_version_preference.dart`, `lib/providers/download_provider.dart`, `lib/services/repeating_playlist_launcher.dart`, `lib/widgets/video_controls/parts/navigation.dart`, `lib/widgets/video_controls/video_controls.dart`, `lib/main.dart`, and three tests. Run `dart format` on exactly those (never on `*.g.dart`; generated files are not formatted upstream).
2. **Translation hygiene** — run the repo's translation cleanup script (see `scripts/checks`) to add the ~37 new keys as empty strings to each locale.
3. **Hardcoded strings** — `lib/screens/settings/add_direct_plex_screen.dart:258` (URL hint, from #2248) and `lib/screens/settings/tracker_settings_screen.dart:161` (from #2740). Move both into `en.i18n.json`.
4. **Unused code** — `observeSimulatedKeyEvent` in `lib/focus/dpad_navigator.dart` is dead after the focus merge (the branch's simulator dispatches through the real key pipeline); delete it. `shouldCreateLocalJellyfinProfile` / `shouldPromptForJellyfinProfileSelection` in `add_jellyfin_screen.dart` — check whether used by tests only, then delete or annotate.
5. **Analyzer on `packages/wakelock_plus`** — vendored package lacks `pigeon`/`mocktail`; exclude `packages/**/test` and `packages/**/pigeons` in `analysis_options.yaml` or run `flutter pub get` inside the package.
6. **Workflow guards** — the failures are from another session's uncommitted edits to `.github/workflows/*` (release_tag input etc.); finish or revert those.
7. **CHANGELOG.md** `## [Unreleased]` — add entries for everything in "Done" above.
8. **Tests** — full suite: 8489 run, 2 failures that pass in isolation (order-dependent, in `test/connection/*` after #2248's credential vault); fix shared state (likely `FlutterSecureStorage` mock or `SharedPreferences` reset not happening between tests). `test/utils/memory_pressure_breadcrumbs_test.dart` also fails on pristine upstream.
9. **Live verification** — the Plex download-queue conversion is untested against a real PMS. Test on `kspls0` with a short episode at 480p: confirm the container (mkv), that embedded text subs survive, the `Retry-After` handling, and whether the server needs Plex Pass for `/downloadQueue`.

## Upstream PRs not yet merged

| PR | What | How |
|---|---|---|
| #2117 | Auto-download Continue Watching | `git merge --squash refs/pr/2117`; conflicts are i18n, `settings_screen.dart`, `settings_service.dart` (add both prefs). Extend so the executor passes the download quality setting. Works for all backends (uses `fetchContinueWatching`). |
| #2271 | Random local preroll clip before movies | Conflicts in `video_player_navigation.dart` with #2483's Plex preroll block. Order: Plex server preroll (if enabled + Plex) → else local random clip (any backend). Settings live in `playback_settings_screen.dart`; `storage_service.dart` conflict is the folder pref. |
| #2203 | Configurable home rows, merged libraries (#1652) | ~6k lines, conflicts in `discover_screen.dart`, `library_recommended_tab.dart`, `appearance_settings_screen.dart`, `platform_detector.dart`, `tv_browse_rail.dart`. Rebase manually; main's TV browse rail changed a lot since. |
| #2170 | Theme music on home spotlights | Superseded by #2596's player. Port only the spotlight hook: in `lib/widgets/tv_spotlight_scaffold.dart`, on focused-item change call #2596's theme-song service (`lib/services/...theme...`, see #2596 commit `322804089`) with a debounce; stop on navigation. All backends already supported by #2596. |

## Backend parity gaps in merged features

- **Prerolls (#2483) Jellyfin/Emby**: Jellyfin and Emby expose cinema intros at `GET /Users/{userId}/Items/{itemId}/Intros` (Jellyfin also `/Items/{id}/Intros`). Add `fetchIntros(MediaItem)` to `MediaServerClient` (Plex returns empty; Plex uses the play-queue path). In `navigateToVideoPlayer`, when `plexCinemaPreRoll` (rename to `cinemaPreRoll`) is on and backend is MediaBrowser, build a `LocalPlayQueue([..intros, movie])` and launch via `launchRepeatingVideoPlaylist`-style local queue.
- **Watch links (#2681)**: currently Plex only (`t.watchLink.plexOnly`). Resolve `plezy://watch?...` for Jellyfin/Emby by matching provider ids (`/Items?AnyProviderIdEquals=tmdb.123`) — `fetchExternalIds` already exists on the client interface.
- **Live TV timeshift timeline (#2300)**: Plex only. Jellyfin/Emby live streams expose a growing DVR window via the transcode HLS playlist; map `LiveTvTimeline` from the playlist's program-date-time and the guide (`/LiveTv/Programs`).
- **Plex watchlist filters (#2725)**: no Jellyfin/Emby watchlist; N/A (favorites already filterable).

## Own builds (not started)

### Downloads
1. **Jellyfin/Emby converted downloads.** Make `JellyfinClient` implement `ConvertedDownloadClient` (`lib/media/download_resolution.dart`). No server queue exists, so return `ConvertedDownloadReady` immediately with a progressive transcode URL: `/Videos/{id}/stream.mkv?static=false&MediaSourceId=..&VideoCodec=h264&AudioCodec=aac&MaxHeight=<preset h>&VideoBitrate=<kbps*1000>&AudioBitrate=192000&SubtitleMethod=Embed&PlaySessionId=<uuid>&api_key=<token>&DeviceId=<id>`. Caveats: unknown length (no Content-Length) and no resume — set the task to non-resumable and restart on failure; Jellyfin throttles transcodes (server setting "Throttle transcodes") so a download proceeds at ~realtime unless disabled; stop the job afterwards with `DELETE /Videos/ActiveEncodings?DeviceId=..&PlaySessionId=..`. Emby Premiere also has a real sync queue (`/Sync/Jobs`) — optional later. Update the setting subtitle text in `en.i18n.json` (`downloadQualityDescription`) once both work.
2. **Sync rule quality (#2206).** Add `downloadQuality` text column to `SyncRules` (v28 migration in `app_database.dart`, same `_ignoreAlreadyExists` pattern), a quality picker in the sync-rule dialog (`lib/utils/download_utils.dart`, now supports multiple toggles/options), and pass `downloadQuality:` to `DownloadManagerService.queueDownload` from `lib/services/sync_rule_executor.dart`.
3. **Per-download quality prompt.** Add `TranscodeQualityPreset? ` "Ask each time" option to `SettingsService.downloadQualityPreset` (nullable pref or sentinel); in `lib/utils/download_version_utils.dart` `resolveDownloadVersion`, show `showOptionPickerDialog` with `TranscodeQualityPreset.displayOrder` and carry the pick on `DownloadVersionConfig` → `DownloadProvider.queueDownload` → manager.
4. **Delete after watched with delay (#2181) and orphan cleanup (#1413).** Settings next to `autoRemoveWatchedDownloads` (`settings_screen.dart` ~line 465, there is a TODO for #1413). Delay: store watched-at per download (new nullable column `watchedAt`), delete in the existing auto-delete pass in `main.dart` (`_autoDeleteAndSync`) once `now - watchedAt > delay`. Orphans: rows whose item 404s on its server (`fetchItem` returns null) for N consecutive passes.
5. **Offline playlist downloads (#1721).** Add "Download playlist" to the playlist detail actions; enumerate with `fetchPlaylistPage` and call `queueDownload` per item; persist as a download collection (`DownloadCollections` table exists, v25) so the playlist shows offline.

### Kids / profiles
6. **Profile PIN lock for destructive actions + hide Explore per profile (#1924, #2514).** Profiles already have PINs (`lib/screens/profile/pin_entry_dialog.dart`). Add per-profile flags (`restrictDeletes`, `hideExplore`) on the profile model; gate `DownloadProvider.delete*`, settings entry and library delete actions behind `showPinEntryDialog` when set; filter the Explore tab in `navigation_tabs.dart`.

### Playback
7. **Per-show audio/subtitle memory (#2382, #2116).** New `JsonPref<Map<String, TrackPreference>>` keyed by `serverId:grandparentId` (mirror `mediaVersionPreferences` in `settings_service.dart`). Save on manual track change in the player (`track_controls.dart`), apply in playback init before server defaults (`playback_initialization_service.dart`). Works for all backends since track selection is client-side.
8. **Pick audio/subtitles before play (#84).** On the detail screen add an "Audio & Subtitles" action that opens the existing track sheets against `getFileInfo`/playback data, store the choice as `preferredAudioTrack`/`preferredSubtitleTrack` and pass to `navigateToVideoPlayer` (params already exist).
9. **Always-on subtitles + auto-fetch preferred language (#2346, #1758).** Setting `alwaysSubtitleLanguage`. On playback start, if no subtitle in that language exists, call `client.searchSubtitles` (#2091: Plex + Emby; enable for Jellyfin — its `RemoteSearch/Subtitles` API matches Emby's, check the dialect gate in `jellyfin_client/parts/subtitle_search.dart`), download the top result, then poll `fetchSourceSubtitleTracks` and select it.
10. **Per-item sync offsets (#1956).** Store audio/subtitle delay per `globalKey` in a JsonPref when changed with the hotkeys (#2824) or sliders; restore on open.
11. **In-player subtitle size/position (#2174).** Add sliders to the subtitle track sheet bound to mpv `sub-scale` / `sub-pos` (prefs `subtitleScale`, `subtitlePosition` exist) with live apply.
12. **Load local subtitle file (#1431).** `file_picker` is already a dependency. Add "Load from file…" in the subtitle sheet; mpv `sub-add <path> select`. Desktop/Android/iOS; not tvOS.
13. **Background play / audio-only (#367).** Setting; in `lib/screens/video_player/parts/lifecycle.dart` skip the pause-on-background when enabled and set mpv `vid=no` while backgrounded (restore on resume). Android needs the existing media session/foreground service to stay up.
14. **mpv equalizer (#2292).** mpv-only (ExoPlayer frozen upstream). 10-band preset UI; apply via `af=lavfi=[superequalizer=1b=..:...]` with `setProperty('af', ...)`. Hide when the ExoPlayer backend is active.
15. **Separate local/remote quality (#2064).** Plex `PlexConnection.local` tells local vs remote; Jellyfin: compare the active endpoint host against private ranges. Add `remoteQualityPreset` pref and apply in `TranscodeQualityPreset.resolveStartupDefault`.
16. **TheIntroDB fallback (#389, PR #1886 for reference).** Opt-in setting; only when the server returns no intro/credits markers. Query by TMDB id + season/episode, validate the window against the episode duration (±5s) before using it.

### Browse / UI
17. **Search by actor/director (#1517).** Plex `/hubs/search` already returns a people hub; Jellyfin/Emby `/Persons?searchTerm=`. Add a people row to `search_screen` results that opens the existing person page.
18. **Random movie / shuffle library (#1561, #2741).** Library toolbar "Shuffle" → fetch a random page (`sort=random` Plex, `SortBy=Random` Jellyfin/Emby) and play via the local queue launcher; "Pick for me" opens the detail page of one random item.
19. **"Ends at" on detail (#2671).** `FinishTimeBuilder` exists for the player; on the detail hero show `now + (duration - viewOffset)` for movies/episodes.
20. **Display toggles** (each a `BoolPref` + Appearance tile): clock in the top bar (#1764, see closed PR for UI), hide hero (#2784), hide backdrop art (#2701), Continue Watching row size (#2723, see closed PR), hide empty libraries (#2498 — needs a refresh path, see maintainer's objection on the PR), split Next Up from Continue Watching (#2690), preferred/default server (#591), save logs to file (#2496, closed PR has an implementation).
21. **Content screensaver (#401).** In-app idle overlay (no Android DreamService): after N idle minutes on non-player routes, show a fullscreen slideshow of library backdrops (`fetchLibraryContent` random), dismiss on any input.
22. **New-episode notifications (#1146).** While running and on resume: poll recently added for shows the profile watches (Continue Watching / Next Up series), diff against the last seen ids (pref), raise `flutter_local_notifications` (add dependency) per new episode. True background polling would need WorkManager/BGTaskScheduler.
23. **Settings backup (#1795).** Export already exists. Add auto-export to a chosen folder on change (debounced) plus import-on-first-run; Jellyfin/Emby can additionally store the JSON in `DisplayPreferences` (`/DisplayPreferences/plezyng?client=PlezyNG`, `CustomPrefs`) for cross-device sync.
24. **Home Assistant / automation (#823, #1996).** Android: exported broadcast receiver with actions `com.snapetech.plezyng.PLAY_PAUSE/NEXT/PREV/STOP` forwarded to the player over the existing method channel. Document the companion-remote protocol for HA. Optional: register as a Plex/Jellyfin remote-controllable session (Jellyfin `SupportsMediaControl` in capabilities, #1401).
25. **Google Cast (#126).** Largest item. Use a pure-Dart Cast v2 client (mDNS discovery + protobuf channel) or `flutter_chrome_cast`; LOAD the backend stream URL (direct-play or the HLS transcode URL from `getPlaybackInitialization`) on the Default Media Receiver (`CC1AD845`), forward seek/pause, report progress back to the server from the phone. Works for all backends because it sends a URL.

## Notes for whoever picks this up

- Helper scripts used this session live in the session scratchpad and are not in the repo; the pattern was: `git merge --squash refs/pr/N`, keep `--ours` for `*.g.dart`, rerun slang/build_runner, `flutter analyze lib test`, run the PR's tests plus the touched area's tests, commit with "Squash of upstream PR #N by <author>".
- Another agent session was editing release workflows, `CHANGELOG.md`, update feed and cask files in this same checkout at the same time; coordinate before touching those.
- The plex.tv account token was printed into the session log earlier; rotate it by signing out/in.
