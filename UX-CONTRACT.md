# Library bulk selection

Selection applies to explicitly chosen, loaded video items in the Browse tab.
It never implies selection of all server results. Shift-click selects loaded
items between the previous anchor and clicked item; individual clicks toggle.
Selection is held by server-qualified identity independently of cache eviction.

| Capability | Canonical owner | Source of truth | Allowed variants | Verification |
|---|---|---|---|---|
| Table Selection | LibrarySelection and MediaCard | This contract | Grid/list, loaded-item ranges | library_selection_test.dart and library_bulk_selection_test.dart |
| Menu | AppMenuButton | app_menu.dart | Desktop popup, mobile/TV sheet | library_bulk_selection_test.dart |
| Watch state | WatchActions | Backend client and WatchStateNotifier | Watched/unwatched | bulk_watch_actions_test.dart and library_bulk_selection_test.dart |
| Toast | snackbar_helper.dart | Existing shared helpers | Success/partial failure | library_bulk_selection_test.dart |

The watch operation reuses the backend-neutral behavior in
`lib/services/watch_actions.dart`. `MediaItemTypes.isVideoContent` defines
eligible kinds. No new server permissions or media-deletion actions are added.

Changing library, grouping, filters, sort, active tab, or authentication retires
selection. Leaving selection through Cancel, Escape, or Back returns focus to
content. Normal card navigation and context menus remain available outside
selection mode. Selection mode uses card activation to toggle a checkbox.

Watch mutations run serially, once per selected item, through WatchActions.
A confirmation states the selected count and descendant scope for shows or
seasons; unwatched also discloses progress reset. Pending operations disable
further dispatch. A retired library/session stops dispatching remaining items;
responses from a retired authentication session do not publish watch events.

After success, selection exits and the current query reloads so watch filters
reflect changed membership. Partial failures report succeeded/failed counts,
remove successful items from selection, and retain failures for explicit retry.
No automatic retry occurs. Raw server errors never appear in UI feedback.

Labels use Slang and existing English fallback. Widget tests cover desktop,
narrow layouts, keyboard selection, confirmations, failures, and session
replacement; physical TV and live-server validation are separate evidence.

# Publications, cloud files and public libraries

`SourceEntry`/`PublicationFile` own file-provider identities, independently of media-server items. Existing movies, shows and music remain in their original models. Reading, listening and watching each have edition-qualified progress; stale revisions cannot undo a newer session or explicit reset. Synced conflicts require a choice. Offline files become visible only after a validated complete download; disconnect retains those files/history, while deleting a profile removes its managed files and credentials.

| Capability | Canonical owner | Source of truth | Verification |
| --- | --- | --- | --- |
| File and shelf navigation | SourcesScreen, publication_shelf, existing library/rail menus | Configured shelves and indexed publication kinds | source_screens_test.dart |
| Provider marks | ProviderMark | Official unmodified assets and sources.json | source_screens_test.dart; artwork NOTICE |
| Reading and fixed-page zoom | PublicationReaderScreen, Foliate adapter, pdfrx | Edition CFI/page, theme and explicit reader preferences | publication_browser_test.dart; publication_archive_test.dart |
| Audiobook/media playback | SourcePlayback, PlaybackCoordinator, native Player | Source-time and file-time cursor; existing playback ownership | source_playback_test.dart |
| Cloud transport/offline data | SourceTransport, PublicationDownloads, SourceStreamGateway | Scoped credentials, renewable leases, representation validators | source_adapters_test.dart; source_downloads_test.dart |
| Lending | LendingService and public-library screens | Public catalogue APIs, provider-advertised circulation actions | lending_service_test.dart; gateway test_server.py |

Connection and detail rows use existing grouped surfaces, typography, icons, menus and confirmations; covers carry the visual emphasis. Provider colours are not recoloured to the app accent. Generic protocol names do not borrow a vendor's logo. Ebooks/Audiobooks/Comics use the same library picker and sidebar selection flow; unconfigured empty shelves stay hidden. Setup can create a standard local profile without requiring a media-server account. Existing protected profiles still go through the standard profile picker.

Cloud passwords/card PINs are entered only at a supported provider-hosted authorization surface. Native OverDrive circulation is compiled off and shown as Coming soon until approval and provider acceptance testing; ordinary service handoffs remain available. Holdings, due dates and fulfillment are not owned-file downloads. Native Hoopla/regional circulation is not invented from private endpoints.

Archive content is untrusted: bounded extraction, no traversal/symlinks, no publication scripts or external network access. The reader and stream server bind to loopback and require session capabilities. A profile transition retires readers, authorization and streams; neither expired sessions nor deleted profiles may publish new state. Provider tokens never enter publication JavaScript, native player URLs or cross-origin artwork requests.

# Accessibility across the app

Settings → Appearance → Accessibility adds to operating-system preferences, never disables them. Additional text scaling preserves the platform's nonlinear text scaler. Bold text, stronger contrast and larger shared controls apply at the app shell, including inherited screens. Custom source/provider artwork stays unaltered.

Reduced motion disables shared focus scaling, focus/TV scroll animation, Mono control transitions and page transitions; existing hero/visualizer consumers receive the same MediaQuery setting. Focus outlines and state feedback remain. Shared sliders retain screen-reader increase/decrease actions, respect RTL arrow direction, and support Home/End and Page Up/Down. Content, menus, dialogs and document navigation have keyboard alternatives to touch gestures.

Reader zoom does not replace readable text reflow. Fixed pages expose fit/actual-size/zoom/pan and page entry; EPUB text exposes size, spacing, alignment and layout. Image-only pages are not described by invented alt text, and OCR is not implied. Automated semantics, narrow-screen/large-text and real-engine tests establish specific coverage; they are not a blanket accessibility certification or a substitute for physical screen-reader checks.

# Planned Find your next discovery

The [implementation handoff](docs/plezyng/swipe/README.md) and [detailed interaction contract](docs/plezyng/swipe/UX.md) define the next discovery work. No discovery runtime is introduced by the plan itself.

Swipes map only to reversible profile-local Not now and Save decisions, with equivalent labelled buttons, persistent Undo and normal Back behavior. Playback, reading, requests, borrowing, downloading and provider watchlists remain explicit actions through their existing owners. Preview mode must preserve real progress, queues and reporting. Mixed-media candidates retain source-qualified identity, exact edition and current capability checks. Profile changes retire candidates, previews, async work and focus restoration. The [coverage matrix](docs/plezyng/swipe/COVERAGE.md) and [acceptance cases](docs/plezyng/swipe/DELIVERY.md) are the implementation completion criteria.
