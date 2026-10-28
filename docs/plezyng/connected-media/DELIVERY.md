# Connected media delivery

This change connects the existing Search, Files and books, library-copy list and
source player. It preserves their layouts, playback routes and profile boundaries.

## Implemented behavior

- Main Search combines server results, indexed Files and books, and Seerr results.
  Each search leg can succeed independently. Source results retain their provider
  identity and use the existing reader/player detail route, media-kind filters and
  TV focus controls. Search remains available with configured Files sources while
  servers are offline. It searches cached entries; it does not crawl providers.
- Identified video titles join filenames, authors, narrators and series in the
  source search index. Schema 10 rebuilds this derived index in bounded batches
  without replacing source entries, credentials or progress. Results from an old
  profile generation are discarded.
- Files offline badges and filtering require a matching representation on disk,
  within the active profile's download directory, with the recorded byte length.
  A readable ebook is independently usable; an audiobook needs every chapter and
  a multipart video needs every part. Partial downloads remain distinguishable.
  Server versions with a known missing part are no longer considered playable.
- A source-player failure preserves the last reliable file position, ignores a
  decoder's error-related zero/EOF events, and exposes a manual Retry action.
  Retry reacquires the same file's content access through the existing cache and
  provider path. It respects profile invalidation and progress conflicts. Explicit
  seeking to zero still works. Failure does not finish a book or advance a chapter.
- The existing library-copy list favors verified local downloads, reachable
  complete copies, accepted video codecs and copies fitting playback's existing
  local/remote/cellular quality defaults before resolution. Connectivity changes
  refresh the ordering while retaining focused row identity. Unknown metadata and
  alternative copies remain visible. Ranking does not switch editions or transfer
  timestamps between copies.
- Android, iOS, macOS, tvOS, Linux and Windows accept `plezyng://` alongside
  `plezy://` and the legacy `plezxyng://` alias. Generated links retain the existing
  canonical scheme. A CI guard checks platform registration and dispatch wiring.

## Automated verification

Validated with Flutter 3.47.1 and Dart 3.13.1:

- 276 tests passed across deep links, search and relevance, offline readiness,
  downloads, source playback, database migrations, source state/screens, media
  versions and copy ranking, catalog detail, navigation, main-screen layout and
  data aggregation.
- After the final network-aware ranking refinement, 64 tests passed across copy
  ranking, catalog detail and transcode-quality presets. This run overlaps the
  earlier regression run; the counts are not a unique-test total.
- The repository analyzer passed with zero diagnostics, including after the final
  refinement. Localization validation passed for 37 locales and 3,593 messages.
- `bash scripts/ci_guard_checks.sh` passed, including the deep-link registration
  guard and the workflow, packaging and script regression checks.

Relevant regressions exercise truncated/deleted downloads, replacement file
fingerprints, profile isolation, incomplete audiobooks and multipart videos,
cancelled search refreshes, schema upgrades preserving progress, native error/EOF
events before retry, explicit zero seeks, and differing LAN/WAN quality limits.

## Native qualification still required

These results establish automated behavior, not device or store qualification.
Before release, install native packages and exercise cold/warm links on each
supported OS; interrupt an actual source stream and retry; verify offline access
after deleting a cached file; switch profiles during a search/retry; and navigate
the existing rows with touch, keyboard and a TV remote. No native release build,
hardware playback matrix or store submission was performed for this change.

Copy ordering is a recommendation based on available metadata and existing device
capabilities, not a guarantee of successful decoding. Offline verification checks
identity, containment and length, not a full content checksum. Cross-provider
timeline equivalence and automatic failover remain outside this change.
