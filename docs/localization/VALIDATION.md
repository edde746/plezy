# Localization validation — 2026-10-26

The implementation covers 37 locale choices and 2,867 logical messages, including
the merged books, cloud-source, lending and accessibility features.

## Completed checks

- Full Flutter analysis: no issues.
- Regression run: all 480 executed tests passed. The three invalid test-path
  entries in that invocation were corrected in a separate 68-test run, which
  passed. These runs overlap and their counts must not be added as unique tests.
- Three real Chromium integration tests passed: EPUB rendering/search, comic
  zoom and navigation, and Arabic interface direction with localized page input.
  Arabic input rejects fractional page numbers and accepts Arabic decimal digits.
- All repository CI guard scripts passed, including 268 Python test executions.
- Clean isolated `scripts/codegen.sh --check` passed, including Slang,
  build_runner and native localization generation.
- Catalog coverage, placeholder validation, source hashes, translation hygiene,
  quantity-generation freshness and native-resource freshness passed.
- Changed Dart source formatting passed. The Kotlin locale channel was formatted
  with ktlint. Apple property lists and Android XML parsed successfully.
- The hardcoded English checker passed; intentional provider names are preserved.
- Browser screenshots were inspected after applying the bundled Noto font
  fallback. The final label added on main received a fresh Slang generation and
  catalog verification.

## Review boundaries

These checks establish structural and behavioral coverage. They do not certify
native fluency. Newly introduced translations include machine drafts and targeted
AI corrections; per-message provenance and catalog hashes are recorded alongside
the coverage report. Native speakers should review long descriptions, terminology,
and screen-reader announcements before a release claims reviewed translation
quality.

Physical Android, Apple TV, iOS and macOS permission dialogs, native IME behavior,
screen-reader voices and glyph shaping still require device QA. In particular,
check tvOS multiline entry, whose custom keyboard has different capabilities from
the native single-line keyboard. No native release build or device-lab run is
claimed by this report.
