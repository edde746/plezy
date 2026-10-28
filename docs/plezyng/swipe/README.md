# Find your next — cross-media swipe discovery

Status: the runtime delivers a bounded mixed-media deck, profile-local Saved picks with search, Undo, safe Shuffle, timestamped review history with per-item Retry to the deck, exact medium/time/source/genre filters with a direct no-match reset, and opt-in encrypted Saved-pick sync with conflict resolution. It includes exact-public-ID adaptation matching, comparison for two or three Saved picks, and capped disposable OPDS sample previews. The filter sheet keeps quick chips and opens a searchable full picker for larger source or genre lists. It retains swipe plus labelled actions, gated Explore catalog details, live-TV revalidation, source details, offline checks and entry points from Discover, Libraries, Explore and Downloads. Catalog rows are included only when opened through Explore after its visibility/PIN gate. Mood/familiarity filters, taste controls, shortlist voting, AI reranking, public-library/lending candidates and physical-device evidence remain future work. Feature acceptance and physical-device qualification have not run on this branch. Photos remain excluded because Plezy has no canonical photo viewer. Initial plan audit: `1b12fd8bb2182a67a58aa8eb949c01006d8fbc31`; source/design reconciliation: `bea4d3f0fe8cd869e0727bbe372cae0da534b253`. See [delivery status](DELIVERY.md) for exact scope and validation.

## The product decision

Make choosing something feel as effortless as browsing Plezy. **Find your next** is an artwork-led, one-item-at-a-time discovery route, entered from Home, a library or Explore. Touch users can swipe; everyone has the same visible buttons. It leads to a useful next activity, not an ever-growing pile of ratings or requests.

The distinctive capability is a choice across **things you can actually enjoy in the time and context you have**. A short episode, the next audiobook chapter, an album and a reading session can be sensible alternatives. They keep their own identity, duration semantics and correct actions. The app must never imply that a 14-hour book can be finished in 20 minutes.

Keep the existing Plezy brand, Mono themes, artwork, typography, navigation ownership, menus, dialogs, focus treatments and player/reader flows. This is a new interaction within Plezy, not a separately branded mini-app. The technical module may be called `swipe`; user-facing copy must not make a gesture a prerequisite.

Confidence: **high** in the observed integration points and capability boundaries; **moderate** that this interaction will shorten decision time before usability testing; **unknown** whether it is unique in the market. “Ground-breaking” is a quality ambition, not a verified marketing claim.

## What the user experiences

1. Open **Find your next** from Discover, a library, Explore or Downloads. The deck reads bounded pages from visible media libraries, enabled file sources, live TV and completed downloads; Explore catalog rows enter only through the gated Explore route. No onboarding form or AI key is required.
2. A compact context control opens the adaptive sheet for Watch / Listen / Read, available time, source, and genre. Mood, familiarity, and taste controls remain future work.
3. The page shows the cover/backdrop, title, media kind, useful duration, one factual reason, availability and a concise description. It uses the existing detail/spotlight hierarchy.
4. **Not now** advances without a permanent dislike. **Save** adds the exact choice to **Saved picks** and advances. Play/listen/read/watch-live actions use existing Plezy routes; catalog-only choices open details and never imply ownership or direct play. OPDS provider-declared samples open through a bounded temporary preview that does not write progress, notes, or completion state.
5. **Undo** is always reachable after a reversible decision. It restores the complete previous card and its place. The user can stop at any time; saved picks remain available.
6. After eight decisions or three saves, show a quiet invitation to review the shortlist. It does not cover the next card or force a modal. From Saved picks, compare a few choices, select one, or explicitly ask the app to choose from those picks.

The initial eight/three thresholds are tuning defaults, not research findings. They are centralized, testable and revisable after observation.

## The features that earn their complexity

| Feature | User value | Contract |
| --- | --- | --- |
| One coherent mixed deck | Choose an activity without visiting six different catalogs | Only enabled, authorized media kinds enter; medium-specific information and actions remain visible |
| Fit the moment | “I have 25 minutes” works for a chapter as well as an episode | Distinguish finishable duration, next meaningful unit and a timed session; unknown is never zero |
| Try without losing your place | Hear a narrator, preview music or inspect a book before committing | Explicit samples use isolated preview state; no progress, completion, scrobble or queue pollution |
| Same story, another way | Find an ebook, narration or adaptation that suits the current device | Verified relations only; editions and adaptations never share a cursor |
| A useful shortlist | Turn a few promising choices into a decision | Local profile-owned Saved picks, persistent undo/history, optional qualified sync |
| Understandable recommendations | Learn why something appeared and correct the app | Factual reason templates; explicit taste controls; neutral skips; bounded diversity |
| Choose together | Make a household decision without exposing everyone's history | Opt-in, co-present guest voting over the current authorized shortlist; no account impersonation |

## Boundaries that prevent a clunky result

- One primary item, one compact context control and a stable action area. No category wall, request dashboard, permanent filter form or mandatory preferences wizard.
- Swiping performs only reversible local discovery actions. Borrow, request, download, watchlist export, mark finished, rating and playback have distinct explicit actions through their canonical owners.
- Keep **Not now** separate from **Hide this title** and **Less like this**. The latter two live in the normal menu with inspectable/resettable preferences.
- Keep Find your next separate from Plex/Trakt/etc. watchlists and music queues. A save is not a star rating, favorite, request or played event.
- Do not copy ReadMeABook's colors, rotating card stack, emoji action buttons or request-on-right-swipe flow. Its valuable precedent is low-effort personalized discovery.
- Keep existing random/shuffle commands unchanged. Their immediate-play semantics differ; the new route may reuse paged retrieval and launch helpers, not their private screen methods.
- No autoplay previews, forced sign-in, hidden whole-library scans, external AI requirement or new top-level navigation destination.

## Scope and dependency truth

Main contains video, music, catalog Explore, live TV, downloads, profile isolation, Mono UI and keyboard/TV focus infrastructure. The ebooks, comics, audiobooks, cloud/file sources, lending and shared accessibility foundation also landed while this plan was being prepared: the final main snapshot `bea4d3f0fe8cd869e0727bbe372cae0da534b253` includes it. The source models and documentation match the inspected foundation branch. Integrate those actual owners; do not rebuild them inside discovery.

The reading/listening sync foundation is integrated in `PublicationSync`. Optional Saved-pick sync uses its encrypted store with a separate namespace and local-only item resolution. Keep discovery state separate from playback/progress records and preserve newer security, branding and localization changes. This plan does not authorize replacing main with any older snapshot.

All enabled and functional kinds must receive a deliberate outcome: browse/save/launch when supported, or a clear discover/save/handoff experience where the device cannot consume that kind. An enum value is not proof of a viewer. Photos are represented in `MediaKind`, but a functional photo viewer was not established in this audit. WebOS has no current application target. See the exhaustive [coverage matrix](COVERAGE.md).

## Handoff map

| Read | Purpose |
| --- | --- |
| [UX.md](UX.md) | Exact flow, shared component ownership, responsive layouts, input semantics, copy and accessibility |
| [COVERAGE.md](COVERAGE.md) | Every observed kind, source and platform; capability gates and honest fallback behavior |
| [ENGINEERING.md](ENGINEERING.md) | Data contracts, ranking, state machine, previews, identity, persistence, concurrency and resource budgets |
| [DELIVERY.md](DELIVERY.md) | Ordered implementation packages, concrete files, acceptance scenarios and release gates |
| [RESEARCH.md](RESEARCH.md) | Pinned evidence, ReadMeABook/SeerrNG observations, official guidance and confidence |

Use the Current implementation status at the top of DELIVERY as the starting point; the package table and acceptance cases below record remaining follow-up work. Extend the existing runtime files instead of rebuilding the delivered slice. An unfinished adapter stays hidden or explicitly browse-only; do not advertise all-media completeness until the coverage matrix has evidence for each enabled row.

The success measure is whether someone comfortably finds something worth starting, with fewer mistakes and less effort. Total swipes, time spent swiping and requests generated are not success targets.
