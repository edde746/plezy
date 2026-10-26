# Comic reading expansion

Research and implementation plan, 2026-10-26. Baseline: main e98fe120.

## Evidence and product decisions

| Evidence | Decision |
| --- | --- |
| [Komga DIVINA reader](https://komga.org/docs/guides/webreader-divina/): direction, continuous strip, scale choices, landscape-page isolation, thumbnails and contextual help | Give comics a dedicated image renderer within the existing reader shell; keep EPUB/PDF engines. |
| [Kavita reader](https://wiki.kavitareader.com/guides/readers/comic-manga/): wide-page splitting, spread offset, webtoon and reading profiles | Support single/double/automatic, cover pairing, RTL splitting, continuous vertical reading and per-publication preferences. |
| [Mihon #3644](https://github.com/mihonapp/mihon/issues/3644), 2026-07-25, closed as duplicate: repeated spread requests and corrections to pairing | Test pairing as a deterministic function; preserve physical page identity when layout changes. This is evidence of a repeated request, not a market-share survey. |
| [Mihon issues](https://github.com/mihonapp/mihon/issues): large-image decoder crashes (#4070), local page preview (#4097), double-click fit (#4120) | Bound resident images, release URLs, report failed pages with retry, provide direct page navigation and thumbnails. |
| [Panels progress discussion](https://community.panels.app/t/tracking-progress-in-opds-stream-library/1610), 2022–2023 | Preserve source + book + edition identity through streaming/downloads and retain the durable conflict-aware outbox. Historical complaint, not a claim about today's Panels. |
| [Panels sessions](https://guides.panels.app/read-content/reading-sessions) | Make progress continuity a basic feature, with local recovery and explicit conflicts. |
| [OPDS-PSE 1.2](https://anansi-project.github.io/docs/opds-pse/specs/v1.2): pages zero-based, lastRead one-based, no write-back standard | Implement standard page streaming for Komga, Kavita, Codex and LANraragi feeds; do not invent generic OPDS write-back. |
| [ComicInfo](https://anansi-project.github.io/docs/comicinfo/documentation) | Read series/issue/creator/language/direction, bookmarks, page sizes and spread hints from bounded XML; never execute metadata. |
| [Komga OpenAPI](https://github.com/gotson/komga/blob/master/komga/docs/openapi.json) | Native server browsing, search, readlists, page streaming, archive downloads, authenticated covers and progress. Preserve reverse-proxy base paths. |

Confidence: high in documented protocol behavior and the usability needs above; moderate in prioritization across PlezyNG's audience. No industry-leadership claim follows from a feature checklist.

## Execution packages

1. **Comic document contract:** ordered image manifest; stable physical page locators; bounded ComicInfo parser; hidden-file filtering; deterministic natural ordering; malformed metadata fallback.
2. **Comic display:** single/automatic/double spreads, cover pairing, wide-page isolation and splitting, RTL, vertical/webtoon mode, fit page/width/height/original, zoom/pan, keyboard/touch controls, viewport-aware loading and page retry.
3. **Navigation and accessibility:** thumbnail explorer in the existing contents action; explicit page labels, page jump, notes/bookmarks, reduced-motion handling, localized controls, persistent per-book preferences. Image labels describe page numbers, not invented artwork descriptions.
4. **Page streaming:** common server-side page source behind the existing loopback capability; credentials remain in Dart; bounded downloads, no arbitrary remote URL proxy, cancellation on profile retirement; full-file offline fallback remains available when the feed offers it.
5. **Third parties:** OPDS-PSE 1.2 and native Komga. Reuse existing WebDAV, S3, Google Drive, OneDrive, Dropbox, local import and public-library routes. Native Komga progress uses existing conflict-aware durable state.
6. **Validation and delivery:** transport/metadata/layout tests, real Chromium reader tests, Flutter source tests and analysis, translation generation, changelog, review and merge via GitHub connector.

## Integration boundaries

- Kavita/Codex/LANraragi: standard OPDS catalog + PSE; arbitrary OPDS does not promise remote progress writes. Kavita's token-bearing feed URLs need a private credential field, not a token stored in public connection records.
- CBR/CB7: server-rendered pages can be read through PSE/Komga. Local RAR/7z extraction is separate codec work, not a renamed ZIP decoder. PDF continues through pdfrx; EPUB through Foliate.
- ComicTagger/Komf/Mylar metadata workflows interoperate through ComicInfo/Komga. Comic Vine and manga trackers require work matching, attribution/rate-limit handling and separate consent before changing an external reading history.
- Guided panels/OCR/translation require a separate validated engine, correction UI and device performance work. Cropping must not silently cut dialogue. No false claim that a page label is OCR or panel detection.
- DRM storefronts (Marvel Unlimited, DC Universe Infinite, Kindle, commercial WEBTOON) have no universal owned-file API. Existing approved lending handoffs remain; no invented private integration.
- Reader device qualification remains required for iOS/Android/Windows/macOS; Linux uses the existing session-bound browser route. Existing TV reading gates remain until a usable TV reader is qualified.

Implementation evidence and remaining qualification are recorded in DELIVERY.md after validation.
