# Plezy Architecture

This document is the long-form companion to `README.md` (user-facing) and `CONTRIBUTING.md` (workflow). It explains how the codebase is shaped and why — aimed at new contributors and anyone wading into an unfamiliar part of the app.

For the lean, agent-facing rule sheet, see `CLAUDE.md`.

## Project shape

Plezy is a Flutter client for Plex and Jellyfin. One codebase ships to:

- **Desktop** — Windows, macOS, Linux (native windows, mpv playback)
- **Mobile** — iOS, Android (ExoPlayer on Android, mpv on iOS)
- **TV** — Android TV / Fire TV (leanback), Apple TV (tvOS, via a custom engine fork — see [tvOS](#tvos))

The Flutter SDK is pinned to **3.44.0** in CI (`.github/workflows/ci.yml`) and `tvos/engine.version` must track the same version. Dart constraint is `>=3.12.0 <4.0.0`.

State management uses `provider` (not Riverpod). Persistence is split between `drift` (SQLite) for structured data and `SharedPreferences` (wrapped by a typed `SettingsService`) for user preferences.

## Backend abstraction

Plezy talks to two media backends with substantially different APIs, but the rest of the app sees only one shape. The key file is `lib/media/media_server_client.dart`:

```
       UI / providers / mixins
                 │
                 ▼
       MediaServerClient    ← backend-neutral interface
                ╱ ╲
               ╱   ╲
        PlexClient   JellyfinClient
            │              │
   plex/parts/*    jellyfin/parts/*    ← topic split as Dart `part of` files
            │              │
            ▼              ▼
        Plex HTTP     Jellyfin HTTP
```

### Conventions on the interface

- **Read methods are prefixed `fetch*`** (e.g. `fetchLibraries`, `fetchHubItems`). This makes "is this a read or a write?" obvious at call sites.
- **Plex-only operations stay on `PlexClient`** under their original `get*` / verb names — DVR tuning, metadata edit, plex-match. Do not lift them onto `MediaServerClient`, even if you "could" stub them on the Jellyfin side. The interface is supposed to be backend-neutral.
- **Write methods follow a strict error contract** (documented in the file header):
  - HTTP 4xx/5xx → throw `MediaServerHttpException`
  - Network/IO failure → throw the underlying exception
  - "Not applicable to this backend" (e.g. wrong-backend item handed to a write) → return `false`, do not throw
  - Success → return the created entity / `true`

### Backend discriminator

Two types serve slightly different roles:

- `MediaBackend` (`lib/media/media_backend.dart`) — used on **neutral domain types** (a `MediaItem` carries its backend so consumers can branch).
- `ConnectionKind` (`lib/connection/connection.dart`) — lighter-weight, used in **DB columns and auth-shape decisions**.

Both serialize via an explicit `.id` string mapping. **Never use `.name`** — see [Persisted enum stability](#persisted-enum-stability) below.

### Per-backend partitioning

Each client is split across multiple files via Dart's `part of` mechanism, grouped by topic:

- `lib/services/jellyfin_client/parts/` — `browse`, `collections`, `file_info`, `images_downloads`, `live_tv`, `playback`, `playlists`, `watch_state`
- `lib/services/plex_client/parts/` — `live_tv` (most of `PlexClient` is still monolithic at the time of writing)

When adding a new operation, place it with its topic neighbours rather than growing the root file.

## Identity model: Connection → Profile → ProfileConnection

This is the part of the app that tends to confuse newcomers, because the three concepts look similar on the surface but mean different things:

```
            Profile (LocalProfile or PlexHomeProfile)
                │
                │  owns 1..n via the profile_connections join
                ▼
        ProfileConnection ── carries the per-profile user-level TOKEN ──┐
                │                                                       │
                ▼                                                       │
            Connection (PlexAccountConnection or JellyfinConnection) ◄──┘
                │
                ▼
        Servers / users discovered via that auth unit
```

### Connection

A `Connection` (`lib/connection/connection.dart`, sealed) is **one auth unit the user added**:

- `PlexAccountConnection` — a single Plex account, plus the servers discovered through it, plus an optional active Plex Home user.
- `JellyfinConnection` — a single Jellyfin server with a single user.

Most users only ever have one Connection.

### Profile

A `Profile` (`lib/profiles/profile.dart`, sealed) is the **user-facing identity** in the app:

- `LocalProfile` — a Plezy-only profile the user created. Optional 4-digit PIN, hashed client-side (`computePinHash`); the raw PIN is never persisted.
- `PlexHomeProfile` — auto-surfaced from a connected Plex account's Home users. PIN protection here is **server-side via Plex** (`/home/users/{uuid}/switch`); the local `pinHash` field is unused.

### ProfileConnection

The join row between a Profile and a Connection. It carries the **per-profile user-level token** for talking to that connection. The crucial gotcha: a connection has *N* tokens in flight, one per profile that activates it. Code that wants to make a request must resolve the token via the **active profile's** join row, not via the connection alone.

Orchestration of "which profile is active right now" lives in `lib/profiles/active_profile_binder.dart` and `active_profile_provider.dart`.

## Persistence

### Drift (SQLite)

`lib/database/app_database.dart` and `tables.dart` define the schema. Tables:

| Table | Purpose |
|---|---|
| `DownloadedMedia`, `DownloadOwners`, `DownloadQueue` | Offline downloads |
| `ApiCache` | Persistent HTTP response cache |
| `OfflineWatchProgress` | Watch-state actions queued while offline |
| `SyncRules` | Auto-download rules |
| `Connections`, `Profiles`, `ProfileConnections` | Identity model (see above) |

### Persisted enum stability

Enums that get written to SQLite columns or JSON **must** define an explicit `String get id` mapping plus a `fromId` reverse, and use those for serialization. Example from `OfflineActionType`:

```dart
String get id => switch (this) {
  OfflineActionType.progress => 'progress',
  OfflineActionType.watched => 'watched',
  OfflineActionType.unwatched => 'unwatched',
};
```

The reason is in the source comment: if you used `.name`, a future rename like `progress → inProgress` would silently corrupt every existing row in the database. The `.id` map decouples the on-disk identifier from the Dart symbol.

This pattern is used throughout — `MediaBackend`, `ConnectionKind`, `OfflineActionType`, etc. Mirror it for any new persisted enum.

### SharedPreferences (typed)

`lib/services/settings_service.dart` exposes `Pref<T>` accessors (`BoolPref`, `IntPref`, `JsonPref`, `EnumPref`, etc.). Read with `settings.read(SettingsService.someKey)` and write with `settings.write(...)`. The base implementation in `base_shared_preferences_service.dart` handles the platform plumbing.

### API caches

In addition to the persistent `ApiCache` table, there are per-backend in-memory caches: `lib/services/plex_api_cache.dart` and `jellyfin_api_cache.dart`. These exist because the access patterns (and TTLs) for the two backends differ enough that one shared cache would be either overly broad or full of conditionals.

### Credentials and logging

Tokens live in `lib/services/credential_vault.dart`. The shared logger (`lib/utils/app_logger.dart`) redacts `Authorization` and `Password` patterns automatically — this is the safety net, not the primary defense. `avoid_print` is enforced, so all logging goes through `appLogger` by construction.

## Code generation

The project leans heavily on codegen:

| Tool | Outputs | Used for |
|---|---|---|
| `freezed` | `*.freezed.dart` | Sealed unions, data classes with `copyWith` |
| `json_serializable` | `*.g.dart` | DTOs (Plex/Jellyfin API shapes) |
| `drift_dev` | `app_database.g.dart` | Generated DAO + table classes |
| `slang` (+ `slang_build_runner`) | `lib/i18n/strings*.g.dart` | Type-safe i18n |

`scripts/codegen.sh` chains `dart run slang` then `dart run build_runner build --delete-conflicting-outputs`. Note that `slang_build_runner` is **disabled** in `build.yaml` — `slang` is run as a separate step to keep build times predictable.

`build.yaml` defaults worth knowing: `explicit_to_json: true`, `field_rename: none`, `include_if_null: true`. Don't override these per-file unless you have a real reason.

### CI enforcement

The CI analyze job runs `scripts/codegen.sh` and then fails if `git diff lib/` is non-empty. In other words: **generated files are committed**, and getting them out of sync is a build break, not a warning. `scripts/ci_checks.sh` does the same locally and is what the pre-commit hook calls.

## Internationalization

Source of truth: `lib/i18n/*.i18n.json`. `en.i18n.json` is the base locale.

`slang.yaml` sets `fallback_strategy: base_locale`, which means a missing key in a non-base locale silently falls back to English. The pragmatic effect:

- You can land a new English string without touching the other 14 locale files. Translations land later via the normal translation flow.
- Without this setting, every locale would need every key declared up-front and codegen would fail with "class is missing implementations for…".

After editing JSON, run `dart run slang` (or `scripts/codegen.sh`, which chains it). Use translations in code as `t.section.key`.

## Playback

`lib/mpv/` wraps libmpv (`player_native.dart` + per-platform parts under `mpv/player/platform/`). Android falls back to ExoPlayer paths inside the same player abstraction.

User-visible playback features that have non-trivial code paths:

- **Subtitles** — full ASS/SSA via libass, with style overrides controlled by `SubAssOverride` (no / yes / scale / force / strip).
- **Shaders** — GLSL presets under `assets/shaders/{nvscaler,artcnn,anime4k}/`, loaded by `lib/services/shader_service.dart`. Not available on iOS/tvOS.
- **HDR / Dolby Vision** — `DvConversionModePreference` selects auto / disabled / DV 8.1 / HEVC-strip. Not available on Linux.
- **Picture-in-Picture** — Android (`PipService`), iOS/macOS via OS hooks.
- **Refresh-rate matching** — `DisplayModeService`, Windows/Android/tvOS only.

The `MediaServerClient` provides playback-init data (URLs, transcode params, subtitle/audio streams) via `playback_initialization_types.dart`; the player consumes those and reports back through `PlaybackProgressTracker` and `PlaybackReportSession`.

## Focus / TV input

`lib/focus/` is a sizeable subsystem because Plezy targets D-pad, keyboard, gamepad, and Siri Remote inputs — all funnelled into Flutter's focus tree.

Key files:

- `dpad_navigator.dart` — directional focus traversal
- `input_mode_tracker.dart` — knows whether the user is currently in pointer or focus-driven mode (affects hover / highlight)
- `focusable_*.dart` — wrappers for `Button`, `Slider`, `TextField`, etc., that integrate with the navigator
- `focus_memory_tracker.dart` — restores focus position when returning to a screen
- `key_event_utils.dart`, `key_repeat_helper.dart`, `key_event_simulator.dart`

Many widgets in `lib/widgets/` have `focusable_*` variants (`focusable_list_tile`, `focusable_media_card`, `focusable_popup_menu_button`, etc.). On code paths reachable from TV, prefer the focusable variant over the raw Material widget; otherwise the focus tree will skip the widget and D-pad navigation will feel broken.

Tab-aware focus memory (e.g. library tabs remembering which item was focused when you come back) is covered by mixins in `lib/mixins/`: `library_tab_focus_mixin`, `library_tab_state`, `tab_navigation_mixin`, `tab_visibility_aware`.

## tvOS

Upstream Flutter does not target tvOS. Plezy ships to Apple TV by using a **custom prebuilt engine** from [edde746/flutter-tvos](https://github.com/edde746/flutter-tvos), pinned to the same version as the main Flutter SDK (`tvos/engine.version`, currently `3.44.0`).

This is *not* a widely-used community Flutter distribution — it's effectively a project-specific fork (`edde746` is the upstream Plezy author). Practically that means: if it stops being maintained or falls behind a Flutter SDK version, the tvOS target is on its own.

### What the port required

The Dart side did not need a rewrite — the app was already TV-aware for Android TV (focus subsystem, layouts, D-pad). The tvOS-specific Dart additions are small:

- `lib/services/apple_tv_remote_touch_service.dart` — bridges Siri Remote touch-surface gestures (`flutter/gamepadtouchevent` channel) into focus-tree key events
- A compile-time `TVOS_BUILD` flag (read in `TvDetectionService`)
- An `_AppleTvScale` overscan-correction wrapper in `main.dart`
- A handful of `Platform.isIOS` branches that also check the tvOS flag (because `Platform.isIOS` is true on tvOS — see [Gotcha](#gotcha-platformisios-on-tvos))

The build system, on the other hand, is **entirely hand-rolled** under `tvos/` — Flutter's tool emits nothing for tvOS:

- **~1,000 lines of build scripts** under `tvos/scripts/`. The big ones: `xcode_appletv.sh` (454 lines, orchestrates the whole build), `fetch_engine.sh` (downloads the prebuilt engine), `wire_plugins.rb` and `wire_mpv.rb` (patch the Xcode project), `copy_assets.sh` and `copy_framework.sh` (reuse iOS build output), `switch_target.sh` and `set_tvos_target_*.sh` (retarget pods/runner between iOS and appletvos).
- **Hand-written `tvos/Podfile`**. Only a small whitelist of plugins is podded normally (`universal_gamepad`, `os_media_controls`, `wakelock_plus` — i.e. the ones whose upstream podspecs already declare tvOS). The rest are **vendored as source copies** under `tvos/Runner/Plugins/`: currently `connectivity_plus`, `device_info_plus`, `package_info_plus`, `path_provider`, `shared_preferences_foundation`. Updating one of these means re-vendoring.
- **Manual plugin registration in two places**:
  - `tvos/Runner/AppDelegate.swift` — Swift `register(with:)` calls for each plugin
  - `_registerTvosPlatformPlugins()` in `lib/main.dart` — Dart-side `registerWith()` calls for plugins that have a Dart-side platform store (currently `SharedPreferencesFoundation`)
  When adding a tvOS-used plugin, wire it in **both** places.
- **iOS-first asset reuse** — `tvos/scripts/copy_assets.sh` copies the `flutter_assets` folder produced by the iOS build into the tvOS bundle. Consequence: **iOS must be built first** or the tvOS build has nothing to ship.

The engine itself is fetched by `tvos/scripts/fetch_engine.sh` and cached at `~/.cache/flutter-tvos-engine` by default. Override with `FLUTTER_TVOS_ENGINE_CACHE` (cache location) and `FLUTTER_TVOS_RELEASES_URL` (release source) if you maintain a private mirror.

### Gotcha: `Platform.isIOS` on tvOS

`dart:io`'s `Platform.isIOS` returns `true` on tvOS. Always branch on `TvDetectionService.isAppleTVSync()` or `PlatformDetector.isAppleTV()` for tvOS-specific behaviour. The `TVOS_BUILD` compile-time flag is the source of truth at app start; runtime device-info detection covers cases where the flag isn't set.

## Auxiliary projects

Three trees in the repo are *not* part of the Flutter build:

- `server/` — Go WebSocket relay for Watch Together. Built and tested with the usual Go toolchain (`go build`, `go test ./...`). Deployed via `docker-compose.yml` + `Dockerfile`.
- `website/` — SvelteKit static site for plezy.app, built with Bun (`bun install`, `bun run dev`, `bun run check`, `bun run build`). Output goes to `build/` (git-ignored).
- `shared/` — Native C++ shared between iOS/macOS/tvOS targets (currently `MpvPlayer`).

Don't run `flutter` commands inside any of these.

## Conventions and tooling

### Static analysis

`analysis_options.yaml` extends `package:flutter_lints/flutter.yaml` and adds:

- **Required**: `unawaited_futures`, `cancel_subscriptions`, `close_sinks`, `use_super_parameters`, `prefer_final_locals`, `prefer_final_in_for_each`, `avoid_print`
- **`dart_code_linter`** with the recommended preset plus Flutter-specific extras (`avoid-border-all`, `avoid-shrink-wrap-in-lists`, `prefer-const-border-radius`, `use-setstate-synchronously`, etc.)
- `// ignore:` and `// ignore_for_file:` must include a reason (`prefer-commenting-analyzer-ignores`)

### Formatting

- Dart: `dart format .`, **`page_width: 120`** (set in `analysis_options.yaml`). CI's format check excludes `.g.dart` and `.freezed.dart`.
- Kotlin / Swift / C++ / Obj-C / native headers: `scripts/format_native.sh --check` (CI) or `--fix` (local). Uses ktlint (auto-downloaded), clang-format, and swift-format.

### Pre-commit

`scripts/setup_hooks.sh` points `core.hooksPath` at `.githooks/`. The hook runs `scripts/ci_checks.sh`, which is byte-for-byte the same pipeline as the CI analyze job (format, codegen freshness, native format, analyze, unused code, unused files).

Bypass with `SKIP_HOOKS=1 git commit ...` only when you have a real reason — merges and reverts are auto-skipped by the hook.

## Bootstrap and lifecycle

`lib/main.dart` is intentionally a single long file (~1,400 lines). It walks through:

1. Pre-binding setup (zero-offset pointer guard for iPadOS 26.1 modal bug, manual tvOS plugin registration)
2. Sentry init (gated by `--dart-define=ENABLE_SENTRY=true`)
3. `_bootstrapApp()`:
   - Settings + locale + date formatting
   - One-shot legacy cleanups (e.g. old `plexImageCache` directory)
   - Image cache sizing (different budgets desktop vs. mobile)
   - Platform-specific window/services init (window_manager, PiP, native fullscreen hooks)
   - Logger configuration
   - Download storage initialization
   - Gamepad service start
   - Provider tree assembly
   - App run

All top-level providers and service singletons are wired in `_bootstrapApp()`. When adding a new global service, that's where it goes.
