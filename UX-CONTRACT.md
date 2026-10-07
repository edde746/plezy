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
