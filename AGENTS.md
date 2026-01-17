# Agent Instructions

This file contains instructions for agents on how to setup the environment, compile, and test this codebase.

## Environment Setup

1.  **Install Flutter**: Ensure you have the Flutter SDK installed.
    *   The project requires a Dart SDK version matching `^3.8.1` (check `pubspec.yaml`).
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

## Building and Testing

### Code Generation

This project uses `build_runner` for code generation (JSON serialization, Drift, etc.) and `slang` for i18n. You must run this before building or testing if you have modified relevant files or just checked out the repo.

```bash
# Generate code (from README.md)
dart run build_runner build --delete-conflicting-outputs

# Generate translations (from CONTRIBUTING.md)
dart run slang
```

### Static Analysis

Run the analyzer to check for linting errors.

```bash
flutter analyze
```

### Testing

Run the tests to verify changes.

```bash
flutter test
```

## Formatting

Format code using:

```bash
dart format .
```
