# Test Suite Documentation

This directory contains unit tests for the Plezy application, focusing on critical utility functions and business logic.

## Test Coverage

### Utility Functions

#### 1. Content Rating Formatter (`content_rating_formatter_test.dart`)
Tests the `formatContentRating()` function which removes country prefixes from content ratings.

**Coverage (15 tests):**
- Null and empty input handling
- Country prefix removal (US, UK, DE, FR, etc.)
- 2-letter and 3-letter country codes
- Case insensitive matching
- Edge cases (no prefix, invalid format, special characters)
- Whitespace preservation in rating values

#### 2. Duration Formatter (`duration_formatter_test.dart`)
Tests multiple duration formatting functions used throughout the app.

**Coverage (26 tests):**
- `formatDurationTimestamp()`: Converts durations to H:MM:SS or M:SS format
  - Hours, minutes, seconds formatting
  - Zero-padding logic
  - Edge cases (zero duration, very long durations)
- `formatSyncOffset()`: Formats sync offsets with sign indicators
  - Positive and negative offsets
  - Rounding behavior
  - Zero handling
- `formatDurationTextual()`: Localized human-readable durations
  - Abbreviated and full formats
  - Locale-aware formatting
- `formatDurationWithSeconds()`: Sleep timer countdown format

#### 3. Language Codes (`language_codes_test.dart`)
Tests ISO 639 language code conversion and lookup functionality.

**Coverage (20 tests):**
- `getVariations()`: Convert between ISO 639-1 and 639-2 codes
  - 2-letter code lookup
  - 3-letter code lookup
  - Bibliographic variants (e.g., ger/deu for German)
  - Case normalization
  - Whitespace trimming
  - Unknown code handling
- `getLanguageName()`: Get English name from language code
  - Both 2-letter and 3-letter codes
  - Bibliographic code variants
  - Null return for unknown codes

#### 4. Platform Detector (`platform_detector_test.dart`)
Tests device platform and form factor detection.

**Coverage (23 tests):**
- `isMobile()`: Detects iOS and Android platforms
- `isDesktop()`: Detects macOS, Windows, and Linux platforms
- `isTablet()`: Screen size-based tablet detection
  - iPad detection (large screen iOS)
  - Android tablet detection
  - Diagonal screen size calculation
  - 7-inch threshold validation
- `isPhone()`: Mobile platform but not tablet
  - iPhone detection
  - Android phone detection
  - Exclusion of tablets

#### 5. Grid Size Calculator (`grid_size_calculator_test.dart`)
Tests responsive grid sizing for media libraries.

**Coverage (21 tests):**
- `getMaxCrossAxisExtent()`: Calculate grid item size
  - Desktop size (>1200px) for all density modes
  - Tablet size (600-1200px) for all density modes
  - Mobile size (<600px) for all density modes
  - Exact breakpoint boundary testing
  - Comfortable, compact, and normal density modes
- Screen type detection helpers:
  - `isDesktop()`: Width > 1200px
  - `isTablet()`: Width between 600-1200px
  - `isMobile()`: Width <= 600px

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/utils/duration_formatter_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Tests in Watch Mode (for development)
```bash
flutter test --watch
```

## Test Statistics

- **Total Test Files:** 5
- **Total Test Cases:** 105
- **Total Lines of Code:** 1,127

## Test Organization

Tests are organized following Flutter conventions:
- Test files mirror the source file structure
- Test files use `_test.dart` suffix
- Tests are grouped using `group()` for better organization
- Individual tests use descriptive names with `test()` or `testWidgets()`

## Dependencies

Tests use the standard Flutter testing framework:
- `flutter_test`: Core testing framework
- `test`: Dart test package (included with flutter_test)

No additional test dependencies are required.

## Future Test Coverage

Additional tests could be added for:
- Network services (with mocking)
- State management providers
- Widget integration tests
- Model serialization/deserialization
- Complex user flows (maestro tests already exist)

## Notes

- Widget tests require `TestWidgetsFlutterBinding.ensureInitialized()` when using Flutter APIs
- Asset loading in `language_codes_test.dart` uses the real asset file (`lib/data/iso_639_codes.json`) via `rootBundle`
- Platform detection tests use `Theme.of(context).platform` which can be easily mocked
- Grid size tests use `MediaQuery` data which is easily injectable for testing
