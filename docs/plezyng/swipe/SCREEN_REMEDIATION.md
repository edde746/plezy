# Find your next: fitted screen and controls

Implemented after the 2026-10-26 usability report. This supersedes the original
scrolling card presentation and the plan's navigation-only left/right TV behavior.

## Interaction and layout

- The current pick fills a bounded stage. Its artwork also supplies the full-page
  background: a backdrop is preferred, then the title's cover. A theme-colored
  scrim keeps foreground text legible. A new pick or profile replaces the artwork
  identity; a late cover load cannot repaint the next pick. Retry refreshes both
  foreground and background artwork.
- Decision controls sit outside that stage and remain visible. Short windows use
  compact controls and put the selected title in the app bar. The cover shrinks
  to the remaining space; summaries are excerpts and the existing Details route
  contains the full information. There is no scrolling deck or action area.
- Physical left skips and physical right saves in LTR. Both directions and their
  button positions mirror in RTL. The center button retains each media type's
  normal Play, Watch, Read, Listen, or Details route.
- The focused cover accepts left/right on keyboard and TV remotes with the same
  mapping. Select/Enter opens details; up/down and Tab leave the cover for normal
  focus navigation. A held direction produces one decision, not a deck-wide run
  of decisions. Direction keys on other controls remain normal navigation.
- Touch or mouse dragging shows the action and a release-to-confirm cue only
  after crossing the distance threshold. Short/cancelled drags do nothing.
  Reduced motion suppresses translation. Accessible navigation uses the explicit
  controls without gesture or horizontal-key interception.
- How it works explains skipping, device/profile-local Saved picks, the fact that
  saving does not download, opening titles, keyboard/remote controls, and Undo.
  Save/skip feedback is announced. The same help is available when the deck is
  empty. New text is supplied in all 37 shipped locales.

## Artwork remediation

The previous screen did not consult DownloadProvider's downloaded artwork paths,
never tried alternate posters/album art after a failure, and rendered missing
source covers as an unexplained icon. It also used a generic swipe instruction
without a direction mapping and allowed descriptions to push actions off screen.

The screen now tries local artwork before network artwork, carries the library's
server identity onto sparse library items, ignores empty image paths, and tries
bounded same-title fallback paths. Source covers use the existing authenticated
SourceController route. Loading, unavailable, and retry states are distinct; no
retry control is offered when no artwork path or source resolver exists. Source
retry invalidates the cached miss and bypasses a corrupt cached cover file.
Artwork URLs and credentials are still omitted from saved-pick snapshots.

An item whose provider supplies no artwork still has a labeled fallback. The
screen does not download a book/video merely to manufacture a thumbnail.

## Validation

- Flutter widget coverage: 320×320, 320×568, 390×844, 844×390, 1280×720, and
  3840×2160 at 100% and 200% text scaling. Checks include all visible decision,
  Details, Undo, and help controls; a very long title/synopsis; and no scrollable
  deck widgets. A small-window empty-deck check keeps restart reachable, too.
- Gesture/keyboard parity in LTR and RTL, short drags, repeat suppression across
  a card change, reduced motion, disabled actions, screen-reader button semantics,
  help open/close, and Arabic control positioning.
- Artwork checks cover local download precedence, alternate paths, stale future
  completions, loading/missing/retry transitions, cached misses, and corrupt local
  cover recovery. Existing optimized-image and RTL suites are also exercised.
- Namespace and placeholder checks pass for all new discovery copy. The existing
  repository-wide localization check has 216 unrelated missing SMB translations
  at the starting main revision b32e396c; baseline comparison confirms no added
  locale errors. Only discovery source hashes are updated here.
- The app-level TV discover focus regression passes after integrating main
  cdeebbd5. Targeted Dart analysis reports no issues.
- Hardware TV, phone and server-account qualification remains a device check;
  the tests exercise their Flutter layout and input paths.
