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
- Run `flutter test` if tests are available
- Test your changes thoroughly

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
   - Run locally: `flutter test`

All these checks must pass before your changes can be merged.

### Maestro end-to-end tests

Android E2E tests use [Maestro](https://maestro.mobile.dev/) against a disposable, pre-seeded Jellyfin container.

Prerequisites: Java 17, Flutter and Android SDK/platform tools, a running Android emulator, Docker, and the
[Maestro CLI](https://docs.maestro.dev/getting-started/installing-maestro).

Run the suites from the repository root (`py -3` can replace `python3` on Windows):

```bash
python3 scripts/run_maestro.py basic    # Basic user flows
python3 scripts/run_maestro.py catalog  # Catalog and music flows
python3 scripts/run_maestro.py media    # Codec playback and track selection
```

Run one flow with `--flow`:

```bash
python3 scripts/run_maestro.py basic --flow .maestro/flows/04_search.yaml
```

Use `--skip-build` to reuse the debug APK and `--skip-jellyfin-build` to reuse the Jellyfin image. Set
`--device <adb-serial>` when multiple devices are connected; physical devices also require `--adb-reverse`.

Top-level flows live in `.maestro/flows/`, shared setup in `.maestro/subflows/`, and focused regressions in
`.maestro/regression_flows/`. CI runs the same suites from `.github/workflows/e2e.yml` and uploads diagnostics on
failure.

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
5. Run `python3 scripts/check_container_image_pins.py`, `python3 scripts/test_check_container_image_pins.py`, and
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
