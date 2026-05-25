# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See `ARCHITECTURE.md` for the human-readable deep dive.

## Stack

Flutter app for Plex/Jellyfin. Desktop + mobile + TV (incl. tvOS via a custom engine fork).

- Flutter SDK: **3.44.0** (pinned in CI and `tvos/engine.version`)
- Dart: `>=3.12.0 <4.0.0`
- State: `provider` (not Riverpod)
- DB: `drift` (SQLite)
- Codegen: `freezed`, `json_serializable`, `drift_dev`, `slang`
- Playback: `mpv` everywhere except Android (ExoPlayer)

## Commands

```bash
flutter pub get
scripts/codegen.sh                    # slang + build_runner (delete-conflicting-outputs)
flutter run
flutter test                          # all
flutter test test/path/foo_test.dart  # one file
flutter analyze
dart format .                         # page_width 120; ignores .g.dart / .freezed.dart
scripts/format_native.sh --check      # add --fix to apply
scripts/ci_checks.sh                  # full pre-commit pipeline (= CI analyze job)
scripts/setup_hooks.sh                # install pre-commit
```

## Hard rules

- **Run `scripts/codegen.sh` after touching anything generated and commit the result.** CI runs codegen and fails if `git diff lib/` is non-empty.
- **Analyzer warnings fail CI** (not just errors). So do `dart_code_linter` `check-unused-code` and `check-unused-files` hits on `lib/`.
- **Never use `enum.name` for persisted enum values.** Tables and JSON use an explicit `.id` string mapping (e.g. `OfflineActionType.id` in `lib/database/app_database.dart`); renaming an enum value would corrupt every row.
- **Plex-only operations live on `PlexClient` directly, not on `MediaServerClient`.** The interface is backend-neutral; do not pollute it with backend-specific calls. Read methods use `fetch*` prefix; write methods follow the error contract in `lib/media/media_server_client.dart`.
- **Plugin registration for tvOS is manual in both** `tvos/Runner/AppDelegate.swift` and `_registerTvosPlatformPlugins()` in `lib/main.dart`. Wire any new tvOS-used plugin in both places.
- **`Platform.isIOS` is true on tvOS too.** Branch on `TvDetectionService` / `PlatformDetector.isAppleTV()`, not `Platform`.
- **iOS must be built before tvOS** — `tvos/scripts/copy_assets.sh` reuses `flutter_assets` from the iOS build.
- **Tokens are sensitive.** Use `appLogger` (`lib/utils/app_logger.dart`); it redacts `Authorization`/`Password`. `avoid_print` is enforced.
- Pre-commit bypass: `SKIP_HOOKS=1 git commit ...` (auto-skipped during merge/revert).

## Code map

- `lib/media/media_server_client.dart` — backend-neutral interface (Plex/Jellyfin)
- `lib/services/plex_client.dart`, `lib/services/jellyfin_client.dart` (+ `*_client/parts/*` as Dart `part of` files)
- `lib/connection/connection.dart` — sealed `Connection` (Plex account / Jellyfin server)
- `lib/profiles/profile.dart` — sealed `Profile` (LocalProfile / PlexHomeProfile); 1..n connections via `profile_connections` join, **per-profile token per connection**
- `lib/database/app_database.dart`, `tables.dart` — drift
- `lib/services/settings_service.dart` — typed `Pref<T>` over SharedPreferences
- `lib/services/credential_vault.dart` — token storage
- `lib/mpv/` — libmpv wrapper (Android uses ExoPlayer paths)
- `lib/focus/` — D-pad / keyboard / gamepad focus; many `widgets/focusable_*` variants
- `lib/i18n/` — slang JSON; `en.i18n.json` is base; `fallback_strategy: base_locale`
- `lib/utils/platform_detector.dart` — `TvDetectionService`, `PlatformDetector`

## Generated/derived files

- `*.g.dart` (json_serializable, drift), `*.freezed.dart` (freezed) — produced by `scripts/codegen.sh`, **committed**
- `lib/i18n/strings*.g.dart` — produced by `dart run slang` (chained in `scripts/codegen.sh`); `slang_build_runner` is disabled in `build.yaml`

## Auxiliary trees (separate toolchains)

- `server/` — Go WebSocket relay for Watch Together; `go test ./...`, `docker-compose.yml`
- `website/` — SvelteKit (Bun): `bun install`, `bun run dev|check|build`
- `shared/` — Apple/native C++ shared by iOS/macOS/tvOS
- `tvos/` — see `ARCHITECTURE.md#tvos`

Do not run `flutter` commands inside these.

## Conventions

- Analyzer extras: `unawaited_futures`, `cancel_subscriptions`, `close_sinks`, `prefer_final_locals`, `avoid_print`
- `// ignore:` requires a reason (`prefer-commenting-analyzer-ignores`)
- `build.yaml`: `explicit_to_json: true`, `field_rename: none`, `include_if_null: true`
- Top-level providers + service singletons are wired in `_bootstrapApp()` in `lib/main.dart`
