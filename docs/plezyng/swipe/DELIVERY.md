# Luna implementation handoff

This document is the execution checklist for [Find your next](README.md). The first runtime slice is implemented; the remaining package rows and acceptance cases describe follow-up scope. A package is complete only with its stated implementation and actual validation evidence; a model or unconnected screen does not count.

## Current implementation status

| Area | Delivered in this branch | Boundary or evidence still needed |
| --- | --- | --- |
| Entry and presentation | Discover and direct Home entry to Saved picks, plus library, Explore and Downloads deck entry points; responsive artwork card, optional horizontal swipe, visible Save/Not now/Play/Listen/Read/Watch live/details controls, reduced-motion behavior, adaptive medium/time/source/genre sheet with quick chips and searchable full source/genre pickers | No Home saved-content shelf, Item-menu entry, or mood/familiarity filters |
| Candidate adapters | Bounded pages from visible server libraries, gated Explore catalog rows (only when entered from Explore after its profile visibility/PIN gate), up to nine configured file-source roots plus a bounded local index, current live-TV guide rows, completed video/music downloads and locally available source files | Public-library/lending candidates and every platform's physical-device behavior are not included |
| Local state | Profile-local saved snapshots, bounded neutral seen set, reversible decision history, fresh mix, persistent Undo, saved-pick removal, capacity feedback, searchable Saved picks, timestamped recent-history screen with safe details revisit, and a Shuffle action limited to visible search results that returns to the deck without starting playback | No discovery cloud sync, taste profile, shortlist comparison, or cross-device conflict handling; history, search and Shuffle have not run their feature acceptance suite |
| Revalidation and actions | Server item refetch and library visibility check; source entry lookup/hydration; catalog source and exact entry resolution; current live program/channel check; completed-download check before offline play; displayed-source filtering and metadata-backed genre filtering use exact matching, with a direct filter reset when no choice matches | No isolated preview/sample mode or verified alternate-edition/adaptation matching |
| Media mapping | Movies, shows, seasons, episodes, clips, music artists/albums/tracks, collection/playlist details, supported publication/source kinds, live programs and catalog movie/show details | Photos are excluded because no canonical viewer exists; folders/unknown kinds are not recommendations. Lending, votes and AI ranking are not enabled |
| Validation | Capability manifest, hardcoded-string guard, JSON parsing, and `git diff --check` have passed for the delivered slices | Dart and Flutter are unavailable in the current work environment, so formatting, Slang generation, analyzer, feature suites, native builds and physical-device evidence have not been run. Release-gate / PDFium / `clang` and native `swift-format` qualification remains open |

The core is usable without a network connection when validated local downloads or local source files are available. Catalog-only titles are explicitly detail choices and must not be mistaken for owned/playable items. No play, watchlist, request, borrowing or download write is triggered by a swipe.

## Preparation and dependency ordering

Read the current `CONTRIBUTING.md`, `DESIGN.md`, `UX-CONTRACT.md` and this directory. Re-fetch main and inspect open work before editing. The research baseline is a snapshot, not permission to replace newer changes. There was no `AGENTS.md` in the audited main tree; follow any subsequently added instructions.

Resolve these dependencies explicitly:

| Dependency | Observed status | Required handling |
| --- | --- | --- |
| Server/catalog/music/TV/navigation/theme/focus | Present on audited main | Build the first real vertical slice here; reuse owners without changing their behavior |
| Files/books/lending/accessibility foundation | Confirmed on final main `bea4d3f0fe8cd869e0727bbe372cae0da534b253`; initially inspected on its branch | Integrate the current main owners; preserve the merged reader, source, profile and accessibility contracts |
| Cloud reading/listening sync | Recovery plan on `codex/audiobook-cloud-sync-20261026` | Complete/qualify that work before SW12; don't import nonexistent reconstructed code as production |
| Comprehensive localization | Separate branch | Rebase with it; preserve new locale/formatting helpers; regenerate with the actual main toolchain |
| Selected logo/security fixes | Concurrent branches/main work | No artwork or security rollback; this feature needs no new product logo |
| OverDrive developer activation | Coming soon / disabled in source foundation | Preserve the gate; fixtures may test enabled behavior, release cannot enable it merely to satisfy a matrix |

The planning merge preceded this runtime branch. Remaining cloud-sync recovery must be completed through its own verified integration, not by creating duplicate source OAuth, reader or sync implementations inside discovery.

## Packages and concrete ownership

File names under new directories are proposed; adapt to established repository conventions after rebasing. Existing files are integration points, not instructions to replace them wholesale.

| Package | Deliverable and proposed files | Depends on | Exit evidence |
| --- | --- | --- | --- |
| SW01 | `lib/discovery/discovery_target.dart`, `discovery_candidate.dart`, `discovery_context.dart`, `discovery_capabilities.dart`; adapter interfaces and exhaustive kind map | Current main audit | Tests for every enum/family, stable namespaced identity, unknown/empty ID handling, edition separation and capability states |
| SW02 | `lib/discovery/discovery_repository.dart`; discovery Drift tables/migration via `lib/database/tables.dart` and `app_database.dart`; profile teardown hooks | SW01 | Migration up/reopen, atomic save/decision/cursor, pre-existing-save Undo, full-disk failure, crash recovery, deletion/isolation |
| SW03 | `lib/discovery/adapters/server_discovery_adapter.dart`, `catalog_discovery_adapter.dart`, `download_discovery_adapter.dart`; use current query/matcher/provider owners | SW01–02 | Real fake-client paged fixtures for Plex/Jellyfin/Emby/catalog/offline; bounded retrieval, permissions, season IDs and duplicate offers |
| SW04 | `lib/discovery/discovery_ranker.dart`, `consumption_unit.dart`, `discovery_reasons.dart`; bounded scheduler | SW03 | Deterministic cold-start/mixed-medium diversity, neutral skips, time semantics, sparse metadata, strict filters and no starvation |
| SW05 | `lib/discovery/discovery_session_controller.dart`, `discovery_gesture_policy.dart`; local transaction/epoch/undo state | SW02–04 | Every state/event cancellation race, repeat activation, stale cursor, background/resume, profile switch during each await |
| SW06 | `lib/screens/discovery/find_next_screen.dart`, `lib/widgets/discovery/discovery_surface.dart`, `discovery_action_bar.dart`; Home/Library/Explore/Downloads menu entries | SW03–05 | End-to-end movie and album path: open → choose → save → undo → details → canonical start → Back; theme and focus regressions |
| SW07 | Context editing is implemented; Saved picks is separate from the deck; recent decision history now has a bounded browse surface and opens only revalidated details; Shuffle returns an eligible saved pick to the deck without launching it. Compact shortlist comparison, restore/hide and taste reset remain open. | SW02, SW06 | Apply/Cancel isolation; saved list works without deck; history profile/gate isolation; restore/hide/taste reset; persistent Undo; Shuffle selection honors active filters and never auto-starts |
| SW08 | `lib/discovery/adapters/live_discovery_adapter.dart`, `discovery_action_router.dart`; remaining server/container/catalog operations | SW03, SW06 | Episode order/spoilers, live program expiry/tuner use, request/record/download only explicit, version and watchlist routing |
| SW09 | `lib/discovery/adapters/publication_discovery_adapter.dart`, `lending_discovery_adapter.dart`; source/offline capability wiring | SW01–08 and landed source foundation | EPUB/PDF/CBZ/audiobook/cloud source flows, multipart identity, disabled lending, TV browse/save and correct supported launch |
| SW10 | `lib/discovery/discovery_preview_controller.dart`, proposed explicit preview policy/lease in existing playback and reader owners | SW06, SW08–09 | Before/after progress/report/queue/sync snapshots equal for samples, exact one owner, teardown on all exits, restricted metadata/URL safety |
| SW11 | `lib/discovery/discovery_relations.dart`; alternate edition/adaptation sheet; co-present shortlist choice controller/screen | SW07–10 | Verified relationships only, no shared cursors, no duplicate work merges, no guest/profile history leakage, no-match voting behavior |
| SW12 | `lib/discovery/discovery_sync_adapter.dart`, separate schema namespace and mapping into qualified source sync | SW02, SW07, completed cloud-sync dependency | Offline adds/removals, causal conflicts/tombstones, copied device IDs, schema mismatch, revoked scope, no lost local saves |
| SW13 | Optional `lib/discovery/discovery_reranker.dart` with baseline implementation and strictly validated configured model adapter | SW04–05; explicit user opt-in setting | Invalid/unknown/duplicate IDs and stale results ignored, deterministic fallback, no restricted payload, offline/core behavior identical without AI |
| SW14 | All new Slang copy/reasons/semantics, shared accessibility preferences and TV/desktop/mobile adaptive polishing | Continuous from SW06; final pass after SW09–13 | Goldens and semantic/input scenarios across light/dark/OLED/custom, RTL/CJK/long text, reduced motion, remote and screen readers |
| SW15 | Integration fixtures, profile-build performance harness and manual platform runs | SW01–14 | Full matrix below, measured resource budgets, real-device evidence recorded per supported target; no blanket “all tested” claim |
| SW16 | Feature gate, production enablement policy, docs/screenshots/help/changelog and recovery behavior | SW15 | Clean required checks, capability-specific release notes, rollback preserves data, runtime state distinguished from roadmap |

SW06 must be a usable thin vertical slice, not a placeholder deck followed by a giant “implement later” list. SW09 integrates the now-merged source foundation. SW10 is required for promising progress-safe samples; omit a particular unsupported Sample action until that adapter satisfies the test. SW12/13 are enhancements with explicit dependency/opt-in gates, not prerequisites for using local discovery. SW11's co-present voting is scoped; internet multiplayer voting is outside this plan.

Do not mark the whole plan code-complete while packages in the selected delivery scope remain interfaces, mocked-only implementations or unconnected screens. If releasing the useful core before optional enhancements, describe the precise enabled package set and keep the rest visibly planned.

## Required automated acceptance scenarios

Use real domain fixtures and observable outcomes. Avoid tests that only assert the new class exists or repeat the implementation's constants. Proposed new test folders: `test/discovery/`, `test/screens/discovery/`, `test/widgets/discovery/`; add integration flows through the current Maestro registration mechanism.

| ID | Scenario | Required result |
| --- | --- | --- |
| A01 | Empty profile starts Find your next | Existing add/connect action, no endless spinner, no invented content or mandatory AI setup |
| A02 | One allowed movie, one album, one publication library | Each supported eligible medium gets exposure; no track/library-size dominance; context changes preserve picks |
| A03 | A restricted Explore catalog is cached, enter from Home | No restricted titles, art, reasons or saved-detail bypass before the normal gate |
| A04 | Same numeric item ID on two servers; same TMDB integer for movie/show | Operational identities do not collide; exact equivalent offers can group only after verified IDs/kind |
| A05 | MAL/AniList season entries share the series ID | Distinct season identity and correct next episode/season action survive grouping |
| A06 | Same title, translated EPUB, alternate narrator, abridged audio, remake | Remain separate editions/works; relation never transfers progress or falsely hides all versions |
| A07 | Empty external ID or ambiguous filename match | No match-all behavior, false dedup or accidental launch; stable fallback or safe exclusion |
| A08 | Available-now deck includes an owned movie and catalog-only movie | Owned title remains eligible; catalog-only title requires verified playable offer or explicit include-unavailable scope |
| A09 | 20-minute Finish something with a 14-hour book, known 15-minute chapter, unknown PDF timing | Chapter can fit with truthful total label; whole book/PDF do not acquire fake short runtimes |
| A10 | Change listening speed or timer while deck is open | Display duration updates from source time; actual progress and existing timer stay unchanged unless explicitly chosen |
| A11 | Skip five thrillers with Not now | No permanent genre dislike; same session does not repeat them; later Undo restores full original card |
| A12 | Save already-saved item, then Undo | Previous membership survives; only the current operation's delta can be reversed |
| A13 | Save/Not now database transaction fails or app dies at each transaction/animation boundary | No phantom save, duplicate decision or skipped card; exactly one durable outcome after recovery |
| A14 | Duplicate tap, held remote Select, rapid click/drag release | One decision per intentional activation; no accidental activation on successor card |
| A15 | Vertical card scroll, OS edge Back, text selection, slider drag, touch exploration | No unwanted decision; normal platform behavior owns gesture |
| A16 | Arabic layout and locale change mid-drag | Logical direction, labels and semantics agree; drag canceled on direction change; focus/undo still correct |
| A17 | Open context sheet, edit, Cancel; then Apply with older fetch delayed | Cancel leaves state intact; Apply uses only new generation; no late card injection |
| A18 | Profile lock/switch/delete during cache read, art load, page fetch, save, sample, launch, sync | No previous-profile metadata/action/focus/toast; remote/local operations keep their original ownership |
| A19 | One provider slow, one 429, one healthy, repeated cursor | Healthy deck works within bounds; scoped retry/backoff; no duplicate loop or request storm |
| A20 | 100k library and long browsing session | Bounded pages/hydration/cache; no full scan; measured memory remains within documented target |
| A21 | Spoiler-protected unwatched episode and missing previous episode | No spoiler thumbnail/description leak; explicit eligible unit and no silent leap in order |
| A22 | Live EPG program ends while focused; server clock changes; no tuner available | Recheck current program/rights; current/unknown state is honest; no stale auto-tune or phantom restart |
| A23 | Revoke permission, expire loan, remove download or replace multipart file before Play | Revalidate and refuse/resolve through normal flow; retain safe saved metadata; no stale URL launch |
| A24 | Request/borrow/hold/download action canceled or fails | No swipe-side side effect or silent retry; existing approval/quota/service chooser remains authoritative |
| A25 | Preview each sample type, stop early/late, close route, lose audio focus | Progress, completion, scrobble, queue, notes and sync state unchanged; server reporting mocks show no ordinary consumption event |
| A26 | Existing music/video owns playback when Sample is pressed | Explicit owner handoff/confirmation, or honest unavailable sample; no overlap or surprise stop on card focus |
| A27 | Preview to full playback races with profile switch or new playback | Exact single owner; fresh capability check; no cursor adoption or delayed auto-resume |
| A28 | Reader sample on Linux, malformed archive, external link/script | Existing sandbox/loopback lifetime maintained; no token or filesystem escape; closing app retires preview bridge |
| A29 | TV opens ebook/comic pick and audiobook alternate | Book discover/save works, unsupported reader is explained; exact audio target can use existing supported playback |
| A30 | Tiny viewport, long CJK/Arabic title, 200–300% text, high contrast/reduced motion | No clipped/covered core actions, accessible text/scroll, stable focus, no decorative animation |
| A31 | Guest shortlist vote has no common Yes/Maybe choice | Honest no-match, no invented winner, guest ballots discarded, no taste/history mutation |
| A32 | Matching title has verified adaptation and a misleading name-only match | Only verified relation is labelled; different works/editions retain independent state |
| A33 | Offline save then sync conflicts with remote removal; clocks disagree | Causal rules/conflict UI and tombstones apply; no automatic resurrection or loss by clock order |
| A34 | Sync code absent, corrupt payload, future schema, write scope denied | Core remains useful; no new implicit source scope, secrets in diagnostics or empty overwrite |
| A35 | AI returns nonexistent IDs/URLs, duplicated IDs, invalid JSON or late generation | Only eligible provided IDs accepted; baseline fallback; no UI stall or provider text injection |
| A36 | Deep link to a discovery/saved target after profile change | Normal authentication/profile gate; exact authorized resolver; untrusted caller cannot launch privileged content |
| A37 | Existing random/shuffle, normal details, music, downloads, library selection; offline navigation including tvOS without Downloads | Existing behavior/ownership remains unchanged; discovery doesn't steal arrows/Back; cached Saved picks remains reachable from the available offline destination |
| A38 | New media enum value or new adapter registered | Exhaustiveness test fails until supported mapping or explicit exclusion is supplied |

Use a controllable fake clock for loan/EPG expiry and retention, seeded randomness for rank order, fake paged clients for cancellation, in-memory/temporary databases for transaction failures, and a spy reporting backend for sample isolation. Test forward and reversed completion order for every critical asynchronous pair.

## Visual and device acceptance

Create Flutter golden fixtures from the actual widgets, not HTML facsimiles or image-generated mockups. Use licensed test artwork or neutral fixture art. Reuse the current media detail/spotlight reference next to each new screenshot and inspect spacing, typography, focus ring, action emphasis and menu surfaces. New approved product logo/provider marks are reused as-is; no new art commission is necessary for this feature.

Required fixture set: populated first card, missing artwork, all media fact rows, loading, partial error, empty, saved, undo, context sheet, shortlist compare, edition sheet, sample controls, large text, RTL, reduced motion and narrow/short/TV layouts. Verify focus restoration after every overlay and route; snapshot alone cannot prove remote usability.

| Platform evidence | What must be exercised |
| --- | --- |
| Android handheld | Touch + TalkBack, swipe cancellation, portrait/landscape, large text, background, offline, native player and reader |
| iOS/iPadOS | VoiceOver, safe areas, keyboard/pointer on tablet, app interruptions, native playback and source reader |
| Windows | Keyboard, mouse, NVDA, DPI scaling, resize during sheet/drag, full playback and reader return |
| macOS | VoiceOver, keyboard/pointer, resizing/full screen, audio focus, player/reader return |
| Linux | Packaged player, keyboard/pointer, actual assistive-tech support status, system-browser EPUB/CBZ preview lifetime and PDF |
| Android TV/Fire TV | Physical remote on low-resource device, focus/repeat/Back, 720p/1080p/4K, decoder cleanup and accessible labels |
| tvOS | Physical Siri Remote/VoiceOver, normal focus engine, background pause, no download/reader claims |

Record hardware, OS/app/build commit, backend/provider fixture or live account, executed cases, result, measured performance and known limitation. Do not fill missing physical-device evidence with unit-test results. Read-only catalog mocks cannot qualify a real OAuth/loan flow.

## Usability checks

Use a small formative study across touch, desktop and remote, including people using large text or screen readers. This is a qualitative check, not statistically representative market validation. Give these tasks without explaining the gesture:

1. Find something available to enjoy for about twenty minutes.
2. Save a book, skip a movie, then bring the movie back.
3. Sample a narration and return to the previous listening position.
4. Find the same story in a supported format on this device.
5. Compare two saved choices and start one.
6. Recover from an unavailable source or expired loan.

Observe whether participants discover actions, distinguish Not now from dislike, understand Save versus request, notice unit/whole-work duration, trust preview progress, and can exit. Compare against their existing Plezy browsing path. Revise layout/labels/thresholds using these observations before describing the feature as unusually intuitive.

## Checks and release criteria

For runtime implementation, run the repository's actual pinned toolchain and required contribution checks: formatting, `scripts/codegen.sh --check`, strict translation hygiene, `flutter analyze`/repository analyzer, native formatting where touched, icon/hardcoded-string/workflow guards and the required unit/widget suite. Run existing profile, library, catalog, playback, source/reader/lending and accessibility regressions touched by integration. Register Maestro regressions according to CONTRIBUTING rather than adding unregistered YAML.

This branch contains a bounded runtime delivery plus profile-local choice history; it does not complete every planned package. Run the remaining adapter, persistence, accessibility, regression and device acceptance work before describing the full plan as complete. Do not treat static analysis as a substitute for those release gates.

Before enabling the feature, all enabled adapters need meaningful paths, observed launch/return behavior and passed acceptance cases. Unqualified optional capabilities remain gated with truthful labels. Add a concise user-visible changelog entry when the runtime ships; do not announce a shipped feature from this plan merge.

Ship behind a profile-aware feature gate until the first platform checks pass. The gate disables entry points and retires active sessions without erasing saved data; ordinary browsing remains available. Schema rollback must preserve or safely ignore the discovery tables. No auto-play/borrow/write can be resumed from a disabled feature's pending session.

Commit the implementation in coherent packages, push through the GitHub connector, open a PR with actual model/validation evidence as required by CONTRIBUTING, and merge to current main after resolving conflicts and checks. Do not alter branch protection or overwrite concurrent source/security/localization work. Report exactly which packages and device rows are complete.
