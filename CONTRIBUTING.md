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
