# Localization validation — 2026-10-26

The implementation covers 37 locale choices and 3,079 logical messages, including
discovery, books, cloud sources, lending, source setup and subtitle search.
The initial follow-up used main `027059a836f62dc6aab7212eef9d1935273188e8`.
Required PR merge-conflict resolution preserves the later main snapshot
`9a17bbd0bff73071079c8b1bc4d85b77557b42fe`, including its 19 additional source paths.

## Merge-resolution verification

- Full Flutter analysis: no issues. Structural coverage, placeholders, source
  checkpoint, hardcoded-English, native/quantity freshness and translation hygiene
  checks pass for all 37 locales and 3,079 logical messages.
- All 327 tests passed in the final single-worker run, including the newly merged
  discovery and comic-source coverage plus the original locale, RTL, large-text,
  reader, input and source suites. A cloud-setup dependency found in the first
  merged run was fixed by treating the optional tracker provider as optional;
  this complete rerun passes with that fix. All 33 Dart files changed relative
  to the incoming main tree pass formatting.
- The [merge QA overlay](LANGUAGE_QA_MERGE.md) verifies every current catalog hash,
  all 36 physical swipe hints, the complete pre-merge review snapshot and the
  original published-input hashes. All 1,300 existing catalog corrections remain
  present. The Malay cover-image hint received one additional correction.
- The 19 incoming source paths are retained with explicit main provenance and
  remain outside this semantic review. Their presence does not expand the earlier
  language review claims. The current complete scan covers 110,844 resolved
  non-English pairs and finds no corruption, repeated words or checked opposite
  label collisions; the same 23 short CJK cases remain adequately translated.

## Initial follow-up verification

- Full Flutter analysis: no issues.
- Slang regenerated from the frozen catalogs. All 37 resolved catalogs contain
  3,060 logical messages with valid placeholders and current English hashes.
- All 37 provenance files match the catalog hashes, exact message keys and
  recorded origin counts. Native-resource and localized-quantity freshness
  checks passed without changes. Translation hygiene reports zero unused keys;
  the hardcoded-English check and formatting of 30 changed Dart files passed.
- All 296 tests passed in the final single-worker run, including locale and
  regional formatting, source adapters and layouts, real Chromium readers,
  localized destructive dialogs, detail sheets, focus and TV input behavior,
  Arabic subtitle search at 200% text, service language codes, and Trakt title/ID
  lookup arrays. The earlier concurrent run stalled after 91 passes without a
  reported test failure; it was stopped and replaced by this complete run.
- The integration QA scan verifies all current catalog hashes, 4,656 exact
  reviewed locale/message values, the original 1,218 corrections and 82 further
  catalog corrections. The historical projection reproduces all 37 original
  published-input hashes. Forty-seven source-setup draft refinements are tracked
  separately, before those new translations entered the catalogs.
- The current scan covers 110,160 resolved non-English message pairs and finds
  zero corruption, repeated-word runs or checked opposite-label collisions.
  Its 23 short-translation candidates are explicitly adjudicated; compressed
  Chinese labels are not treated as mistranslations merely for being short.

The [integration QA report](LANGUAGE_QA_INTEGRATION.md) distinguishes independent
review of root-authored wording from authored/self-reviewed additions. These
checks do not certify every message as fluent or native-reviewed.

## Earlier implementation validation

The following results belong to the earlier implementation and language-review
snapshots. They remain useful history; their overlapping counts are not added to
the current follow-up suite.

- Full Flutter analysis: no issues.
- Analysis was repeated after the final main integration with no issues. A focused
  22-test run of locale selection, preferences and source screens also passed.
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
- After the initial independent AI language QA corrections, Flutter analysis again found
  no issues and all 76 focused locale, formatting, source-screen and real Chromium
  reader tests passed. This suite overlaps the earlier runs. Slang and native
  permission resources were regenerated; catalog, hygiene, quantity and native
  freshness checks passed.
- Final language remediation verified all 1,218 correction records against their
  original and corrected values, including all 291 first-pass residual findings.
  All 37 provenance hashes and origin counts match. Slang, native permissions and
  the English source checkpoint were regenerated after the final corrections.
  The source/placeholder, hygiene, quantity/native freshness, six catalog unit
  tests and hardcoded-text checks passed. The review scan verifies zero remaining
  corruption, repeated-word or checked opposite-label collision findings.
- The final combined run passed all 141 tests: locale and formatting behavior,
  source layouts, real Chromium readers, destructive-action dialogs, detail
  sheets and queue subtitles. Arabic/Egypt year digits and localized episode
  labels are covered. Stale English label/unit assertions were updated to the
  shared localized format. A disk-space failure in the test runner was resolved
  by clearing task-owned disposable caches before this successful run.

## Review boundaries

These checks establish structural and behavioral coverage. They do not certify
native fluency. Newly introduced translations include machine drafts and targeted
AI corrections; per-message provenance and catalog hashes are recorded alongside
the coverage report. The independent [language QA report](LANGUAGE_QA.md) records
3,466 directly inspected non-English locale/message pairs, 1,218 corrections and
zero unaddressed findings from this bounded pass. Native speakers should review
long descriptions, terminology and screen-reader announcements before a release
claims native-speaker approval.

Physical Android, Apple TV, iOS and macOS permission dialogs, native IME behavior,
screen-reader voices and glyph shaping still require device QA. In particular,
check tvOS multiline entry, whose custom keyboard has different capabilities from
the native single-line keyboard. No native release build or device-lab run is
claimed by this report.
