# Localization maintenance

PlezyNG offers 37 locale choices, including Arabic, Persian, Hebrew, Bengali,
Hindi, Indonesian, Malay, Thai, Vietnamese, Chinese (Simplified and Traditional),
Japanese and Korean. The locale catalog is the source of truth for supported
languages, explicit regional inheritance, RTL scripts and technical names that
must remain unchanged.

## Viewer experience

- Interface language, regional date/number formats and metadata language are
  independent preferences. The language picker always includes **Follow system**
  and recognizable native language names. Search accepts native names, localized
  names, language codes and Latin names typed without accents.
- Language choices load serially. A slower deferred load cannot overwrite a newer
  choice. Android 13+ app-language settings synchronize in both directions, including
  restoration of the system default. Regional formatting reads Android's actual
  system locales, independent of the app override.
- The server metadata preference is sent to Plex. Jellyfin/Emby library metadata
  remains controlled by the server; changing this preference does not rewrite a
  shared library or promise translations that a server cannot supply.
- CLDR data supplies language/territory names, native endonyms, duration grammar,
  unit names and list punctuation. Protocol identifiers, stored values and media
  timecodes retain their established representations. Numeric setting inputs
  accept Arabic, Persian, Indic, Thai and full-width decimal digits.
- Arabic, Persian and Hebrew use RTL Material controls, logical reading-order
  focus traversal, mirrored navigation rails and hero content. Playback timelines,
  spatial video gestures and numeric keypads retain their physical meaning.
- Mixed-direction media titles use Unicode isolates. Explicit bidi overrides in
  isolated display strings are removed without changing stored metadata.
- Books, cloud sources and lending use the same locale and formatting preferences.
  Reader page entry accepts localized decimal digits. The browser reader receives
  language and direction metadata, formats progress and numeric settings, and
  serves the bundled Noto fonts when system fonts lack Arabic or Asian glyphs.
- The existing bundled Go Noto fonts cover Arabic, Hebrew, Devanagari, Bengali,
  Thai, CJK and Hangul for Linux installations without complete system fonts.
  Other platforms retain native font fallback and native IMEs. Chinese script
  resolution is preserved independently of the region.

## Translation status and sources

Coverage checks measure complete messages, valid interpolation and plural
structure. They do **not** measure fluency or certify native-speaker review.

Existing translations were retained. Matching Jellyfin Web translations were
reused with attribution; Unicode CLDR provides generated language and unit data.
New language catalogs and previously empty messages also include M2M100 machine
translation drafts with targeted AI corrections. Selected security warnings, destructive
confirmations, key navigation labels and missing placeholders received targeted
review. Native-speaker review remains necessary, especially for long descriptions,
media terminology and accessibility announcements. Do not label these new
catalogs professionally translated or native-reviewed without that review.

An independent AI language QA pass is recorded in [LANGUAGE_QA.md](LANGUAGE_QA.md).
It separates semantic sample review from automated scans, records before/after
corrections, and documents the review limits. Its coverage applies to the
catalog snapshot named in the report; it is not approval of every message.

The 3.0.0 deep-link and playback screen-lock strings are recorded separately in
[LANGUAGE_QA_3_0_0.md](LANGUAGE_QA_3_0_0.md), with per-message origins and a
correction ledger. Structural coverage and targeted AI corrections do not
replace native-speaker review.

The [universal media QA addendum](LANGUAGE_QA_UNIVERSAL_MEDIA.md) records the 112 new feature messages, M2M100 draft provenance, two explicit plural fallbacks, and the lack of native-speaker review.

The [integration QA addendum](LANGUAGE_QA_INTEGRATION.md) records the discovery
and source-setup additions, SMB guidance, and further Italian corrections. Its exact reviewed messages
and catalog hashes are separate from the original review, so later feature
additions cannot silently inherit language approval. The [merge QA overlay](LANGUAGE_QA_MERGE.md)
records the subsequently reviewed swipe hints and retains newer messages without
extending semantic approval to them.

The [VLC feature parity addendum](LANGUAGE_QA_VLC_PARITY.md) records the 36
playback and converter messages, the explicit English fallbacks, and the review
limits for those drafts.

The five Steam audio setting labels currently use the documented English
fallback for non-English catalogs until reviewed translations are available.
They are listed in `lib/i18n/english_fallbacks.json`; this fallback is not a
claim of translation or native-speaker review.

`sources.json` records source blob identifiers, model provenance and licenses.
`translation-provenance.json` records message origins and review status;
`coverage.json` is a reproducible structural report. Bundled attribution appears
in the application's license screen. Model weights and translation tooling
caches are not shipped.

## Updating messages

1. Edit `lib/i18n/en.i18n.json` and the affected locale catalogs together. Keep a
   whole sentence in one message and retain interpolation names. Use cardinal
   plural forms for quantities; Arabic needs zero/one/two/few/many/other where
   the grammar differs. Do not concatenate translated fragments.
2. Regional files (`es-419`, `fr-CA`, `pt-BR`, `pt-PT`) contain deliberate overrides
   and inherit their language-only parent. An empty string is never an approved
   translation. Do not copy English into a missing entry to inflate coverage.
3. Run `scripts/codegen.sh`. It refreshes CLDR-based quantity messages, native
   permission resources and Slang output. For a deliberate CLDR refresh, run
   `node scripts/codegen/generate_locale_names.mjs` first and review the recorded
   ICU/CLDR version in generated headers. Normal builds use committed data and
   require no translation service or Node runtime.
4. Run `python3 scripts/checks/check_localizations.py --record-source` only after
   reviewing changed source messages. This records source hashes; it does not
   mark a translation as language-reviewed.
5. Run the checks below and the relevant feature tests. Commit generated output
   and native resource changes with the source catalogs.

```sh
python3 scripts/checks/clean_translations.py --check --strict
python3 scripts/checks/check_localizations.py --report docs/localization/coverage.json
python3 scripts/codegen/generate_localized_quantities.py --check
python3 scripts/codegen/generate_platform_locales.py --check
flutter test test/i18n test/utils/formatters_test.dart
```

## Review on real devices

Check Arabic and an Asian script at 200% text size in both themes. Traverse
language selection, settings, home shelves, media details, playback, downloads,
search, profiles, Watch Together and dialogs using touch, keyboard, TV remote and
a screen reader. Verify mixed Arabic/Latin titles, regional punctuation, zero,
one, two and larger counts, keyboard composition, and permission prompts. Repeat
with Follow system after changing the OS language while the app is backgrounded.

Automated tests cover locale loading, inheritance, script/region resolution,
preference persistence, formatting, selection semantics, large text, RTL card
order and focus. Browser integration tests exercise Arabic interface direction,
localized page input, EPUB search and comic navigation. Apple resource structure can be checked on Linux; final native
permission presentation, shaping and speech quality need device testing.
