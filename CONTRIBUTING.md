# Contributing

## Getting Started

1. Fork and clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `scripts/codegen.sh` to generate translations and Dart model code
4. Start developing!

## Development

- Follow Dart/Flutter conventions
- Run `dart format .` to format Dart code (note: generated files like `*.g.dart` are excluded from CI checks)
- Run `scripts/format_native.sh --fix` to format Kotlin, Swift, C++, C, Objective-C, and native headers
- Run `flutter analyze` before submitting to check for issues
- Run `scripts/run_tests.sh` to run the test suite (same as `flutter test`, but scaled to your core count)
- Test your changes thoroughly

### AI-assisted contributions

AI-assisted pull requests must state in the PR description which model(s) were used (e.g. Claude Sonnet 4.5, GPT-5, Gemini 3 Pro).

### Code Quality Checks

The project includes automated CI checks that run on all pull requests:

1. **Code Formatting**: Ensures code follows Dart and native formatting standards
   - Run locally: `dart format .` to format Dart files
   - Run locally: `scripts/format_native.sh --fix` to format native files
   - Note: CI only checks non-generated files (excludes `.g.dart`, `.freezed.dart`)
   - Generated files are reformatted automatically by build tools

2. **Static Analysis**: Checks for code issues and potential bugs
   - Run locally: `flutter analyze`
   - Note: CI excludes generated files from analysis (configured in `analysis_options.yaml`)

3. **Generated Code**: Ensures generated translations and model files are current
   - Run locally: `scripts/codegen.sh --check`

4. **Tests**: Runs unit and widget tests (when available)
   - Run locally: `scripts/run_tests.sh`
   - This is `flutter test` with `-j` set to the core count. The default is half your cores, which
     leaves most of the machine idle because the suite is dominated by per-file compilation.
     Arguments are forwarded, so `scripts/run_tests.sh test/widgets/some_test.dart` works.

All these checks must pass before your changes can be merged.

### Maestro end-to-end tests

Android E2E tests use [Maestro](https://maestro.mobile.dev/) against a disposable, pre-seeded Jellyfin container.

Prerequisites: Java 17, Flutter and Android SDK/platform tools, a running Android emulator, Docker, and the
[Maestro CLI](https://docs.maestro.dev/getting-started/installing-maestro).

Run the suites from the repository root (`py -3` can replace `python3` on Windows):

```bash
python3 scripts/maestro/run_maestro.py basic    # Basic user flows
python3 scripts/maestro/run_maestro.py catalog  # Catalog and music flows
python3 scripts/maestro/run_maestro.py media    # Codec playback and track selection
```

Run one flow with `--flow`:

```bash
python3 scripts/maestro/run_maestro.py basic --flow .maestro/flows/04_search.yaml
```

Use `--skip-build` to reuse the debug APK and `--skip-jellyfin-build` to reuse the Jellyfin image. Set
`--device <adb-serial>` when multiple devices are connected; physical devices also require `--adb-reverse`.

Top-level flows live in `.maestro/flows/`, shared setup in `.maestro/subflows/`, and focused regressions in
`.maestro/regression_flows/`. Automatic groups are declared in `scripts/maestro/run_maestro_ci.py::GROUPS`. Every top-level
regression flow must be registered either there or in `DESTRUCTIVE_MANUAL_TARGETS`; reusable subflows are not
independent tests. A manual-only classification must state why the flow cannot run automatically.

The profile-isolation and profile-teardown regressions create and remove profile connections, so they are a destructive
manual target rather than an automatic group. Run them only against the pre-seeded Jellyfin fixture and a disposable
emulator, using the required opt-in:

```bash
python3 scripts/maestro/run_maestro_ci.py profile-regressions --disposable-emulator
```

The target refuses to start without `--disposable-emulator`. Each profile flow writes to its own Jellyfin log and
diagnostics directory under `build/maestro-profile-regressions/`.

### Agent controls

Opted-in debug and profile builds expose `ext.plezy.agent` over Flutter's authenticated Dart VM service.
Release builds never register it. Use a disposable installation/profile: a worktree does not isolate installed app data.
Sign in through the ordinary UI; these commands do not expose credentials, bypass profile locks, or perform onboarding.

```bash
flutter run -d DEVICE --dart-define=PLEZY_AGENT_CONTROL=true
# Add --profile when testing a profile build on a supported device.
export PLEZY_VM_SERVICE_URI='AUTHENTICATED_VM_URI_FROM_FLUTTER'

bun scripts/agent.mjs app status
bun scripts/agent.mjs app status --wait
bun scripts/agent.mjs settings list
bun scripts/agent.mjs settings set theme_mode '"dark"'
bun scripts/agent.mjs settings set enable_hardware_decoding false
bun scripts/agent.mjs settings set mpv_config_text --text-file mpv.conf
bun scripts/agent.mjs settings apply --file agent-settings.json
bun scripts/agent.mjs settings reset enable_hardware_decoding

bun scripts/agent.mjs media servers
bun scripts/agent.mjs media search --server SERVER_ID --query 'Example'
bun scripts/agent.mjs media get --server SERVER_ID --item ITEM_ID
bun scripts/agent.mjs playback start --server SERVER_ID --item ITEM_ID --from-start --wait playing
bun scripts/agent.mjs playback status
bun scripts/agent.mjs playback stop --wait
```

`app status` reports readiness and authentication/profile blockers; `--wait` waits for a usable profile session.
The CLI requires an explicit `--uri` or `PLEZY_VM_SERVICE_URI`. It never selects a device, restarts an app, clears data,
or changes ADB forwarding. Supply a host-reachable URI, preserving its authentication token, and keep it private.
Do not expose the VM service publicly. The Maestro runner can build the same opt-in variant with `--agent-control`.

Settings discovery describes types, defaults, bounds, support, storage ownership, and application timing. Unsupported
writes are rejected. Use `settings list --scope TYPE --profile PROFILE_ID` to discover scoped targets, then pass the
returned target with `--scope-json`. Scopes include `player`, `server`, `library`, `profile`, `catalog`, `account`,
`syncRule`, `liveTvFavorites`, and `dvrRule`, in addition to the default `app` scope. Resource contents such as shortcuts,
custom shaders, and external-player definitions require an explicit `settings get`; discovery does not dump them.
Player overrides may be shared across profiles where the existing storage contract says so.

Values are JSON; string values need JSON quotes. Batch files contain an array of `{key, value, scope?}` or
`{key, reset: true, scope?}` entries. The whole batch is validated first, then applied in order; it is not a transaction.
Inspect `persisted`, application timing, pending effects, and partial-failure details rather than assuming a saved value
has changed the current player. Download paths still require the platform's existing native access grants.

Playback targets are exact server/item IDs. Use `media children` to select a concrete item inside a show, season, album,
or playlist. Use `--start resume` or `--position-ms N` instead of `--from-start` for other start policies,
`--media-source-id ID` for an explicit version from `media get`, `--offline` for a completed profile-owned download,
and `--target-kind channel` for live TV. An accepted launch is not confirmed playback: `--wait playing` observes the
matching native player. An external-player handoff reports `externalLaunched`, not internally verified playback.
Stop the existing session before starting another; `playback stop --operation ID` stops only that operation.

Commands return JSON and exit nonzero on failure. `--timeout-ms` bounds the entire invocation; mutations are never
retried automatically. After a timeout/disconnect, inspect the returned request/operation identity and
`playback status --operation ID` before retrying: the mutation may already have executed. Use Maestro or native UI tools
alongside these controls to verify rendering, pointer/touch, keyboard, D-pad, and gamepad interaction.
Run `bun scripts/agent.mjs --help` for the full command and structured-file options.

### Production container image updates

Production images in `server/Dockerfile` and `server/docker-compose.yml` use a readable version or source-revision tag
plus an authoritative multi-platform index digest. The adjacent `Platforms` declaration records the supported
`linux/amd64` and `linux/arm64` variants. Never replace these references with a mutable tag or a single-platform child
manifest.

Update a production image only through a reviewed change:

1. For the Bugs service, first record the running container's image ID, repository digest, platform, and OCI source
   revision without printing its environment. Prefer that reviewed running identity; selecting anything else is a
   service upgrade, not a routine pin refresh.
2. Review the upstream source revision and changelog, provenance, vulnerability results, and manifest contents. Resolve
   the readable tag and digest-qualified reference independently and confirm they identify the same OCI index in two
   clean caches. The index must contain both declared platforms; provenance/attestation descriptors do not count as
   runnable platforms.
3. Change the readable tag, full `sha256` index digest, and adjacent platform declaration together. Include the old and
   new identities, manifest/platform evidence, review findings, smoke results, and rollback notes in the change.
4. Before changing the Bugs digest, exercise it with non-production configuration and a disposable volume. Review
   migrations, take a restorable `bugs_data` backup, then validate a cloned volume. A forward-only migration rolls back
   with the prior digest and pre-change backup, not by changing the image reference alone.
5. Run `python3 scripts/checks/check_container_image_pins.py`, `python3 scripts/checks/test_check_container_image_pins.py`, and
   `(cd server && go test ./...)`. Inspect the rendered Compose configuration and rebuilt images locally without
   exposing configuration values. Do not publish or deploy from a review checkout, and never fall back to `latest` when
   a digest is unavailable.

## Internationalization (i18n)

This project uses `slang` for internationalization with JSON files.

### Adding New Strings

1. Add your string to `lib/i18n/strings.i18n.json`:
   ```json
   {
     "section": {
       "myNewString": "My new text"
     }
   }
   ```

2. Run `dart run slang` to regenerate translation files

3. Use in your code:
   ```dart
   Text(t.section.myNewString)
   ```

### Adding New Languages

1. Create new JSON file: `lib/i18n/[locale].i18n.json`
2. Copy structure from `en.i18n.json` and translate values
3. Run `dart run slang` to regenerate files

### Guidelines

- Organize strings logically in nested objects
- Use camelCase for keys
- Keep strings concise and clear
- Always run `dart run slang` after changes
