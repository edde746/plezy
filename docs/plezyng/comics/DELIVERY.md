# Comic display delivery

The comic renderer now supports single pages, automatic or explicit double-page
spreads, isolated covers, right-to-left reading, splitting wide pages into halves,
and continuous vertical scrolling. Mixed image dimensions use a common spread
scale. Fit page, width, height and actual size work with zoom, drag-to-pan, touch
pinch, swipe navigation and keyboard controls. The existing reader shell continues
to own themes, notes, progress and profile lifetime.

Display preferences are scoped to the comic edition and profile, inheriting the
existing reader defaults. Physical-page locators retain split halves and vertical
scroll offsets; existing Foliate CBZ bookmarks migrate on navigation. The contents
view provides thumbnails with accessible page labels and metadata bookmarks.
Browser thumbnail groups contain eight pages. Continuous scrolling retains the
visible pages plus two neighbors on each side, with placeholder heights bounding
image residency even for strips made of short panels. Search and speech controls
are hidden for image-only comics rather than presenting nonfunctional actions.

The backend foundation from PR #22 remains: ComicInfo metadata, naturally ordered
archive images, OPDS-PSE and Komga page APIs, reading lists, collections, and
Komga progress. This follow-up refreshes removed OPDS streams, keeps sub-page
positions when Komga agrees on the physical page, and restores the `streamOnly`
model field lost during the preceding main integration. Streaming requests share
a bounded queue with three concurrent upstream transfers, reject non-image bodies
and oversized responses, and abort when the reader closes. Provider credentials
stay in native transport. Downloadable editions fall back to acquisition if the
page API is unavailable or unsupported; authentication and malformed responses
remain visible errors. Cached editions retain priority.

## Dependencies and reproducibility

`tools/reader-tests` pins Playwright 1.62.1 and its dependency lock. Its runner
requires an installed Chromium and fails if it is missing. CI installs the browser
and Linux system dependencies, explicitly provisions Clang/build-essential for
native hooks, and runs the real browser checks. Playwright is not shipped with the
app. `shared_preferences_foundation` is now an explicit, version-constrained
Flutter dependency because main imports its API directly.

The integrated main snapshot also needed small Dart compatibility and merge
repairs in the source adapters, metadata lookup, directional padding, semantics,
license notices and remote dialog. The changes preserve the shared navigation and
source interfaces. Generated translations and formatting were refreshed.

## Validation scope

The automated suites exercise the real loopback server and Chromium with generated
EPUB/CBZ fixtures: spreads, differing dimensions, RTL, wide-page halves, legacy
bookmarks, thumbnails, vertical resume, zoom, swipe/pinch, retry, resizing, Arabic
chrome and localized page input. Unit tests exercise Komga and OPDS contracts,
credential boundaries, concurrency, cancellation and invalid response handling.
Flutter widget checks cover reader controls on a narrow display with large text.
The dedicated EPUB regression retains search and publisher-content sanitization.

The new messages cover all 37 locale choices through 32 translated language
catalogs, English, and four regional inheritance paths. The six missing SMB setup
messages on the integrated main snapshot were filled at the same time so the
localization checks remain complete. These additions are AI-authored translations;
structural validation and Arabic UI tests do not constitute native-speaker review.

Native Android/iOS WebView, WebKit/Windows, TV reading, live Komga installations
and live OPDS catalogs still require platform/service qualification. These tests
do not certify service compatibility or translation fluency. Native CBR/CB7
extraction, guided-panel recognition/OCR, secure Kavita token-path onboarding,
server thumbnail APIs and arbitrary OPDS progress writes remain separate work.
The research plan is a roadmap, not a claim of completed industry-wide parity.

Model: GPT-6 (Codex).
