# Find your next — interaction and visual contract

The first runtime delivery now follows this contract for the deck, filters, visible actions, saved picks and entry points. The remaining rows describe the planned extension and are not claims about implemented behavior. Existing runtime geometry wins over illustrative numbers; current scope is recorded in [DELIVERY.md](DELIVERY.md).

## Entry and exit

| Entry | Initial scope | Return behavior |
| --- | --- | --- |
| Home / Discover toolbar's existing menu | Enabled profile libraries, all actionable media, Available now | Restore original Home scroll, focused control and spotlight |
| Library toolbar menu | This library, its current applicable filters, its medium | Return to exact library/tab/filter/scroll; selection mode is not activated |
| Explore toolbar menu | Connected catalog scope, with explicit “Include unavailable” context | Apply the same Explore visibility/PIN policy before fetching or showing cached catalog items |
| Downloads menu | Valid completed profile-owned downloads | Offline operation; no network request merely to enter |
| Item menu: Find similar | Selected item as a removable session seed | Preserve detail route/scroll and original playback state |
| Saved picks entry in Home's existing menu | Profile's saved choices | Also reachable from the discovery header, including when the deck is empty |
| Saved picks action on the available offline destination | Cached profile-owned choices; no automatic network access | Add to that screen's existing app-bar overflow: Downloads normally, Settings on tvOS where Downloads/Home may be absent |

Initially expose one ordinary text-labelled menu action at these locations. A Home row for saved picks is opt-in through the existing organizer, not a new permanently inserted hero or tab. Do not rename the existing Home `NavigationTabId.discover` or conflate it with Explore. Add neither a second Discover destination nor a nested modal for the deck itself. Use a regular profile-owned route and the normal Back transitions. Because Home/Libraries are online-only in the current tab policy, verify offline entry explicitly rather than assuming their toolbar remains visible. tvOS offline Saved picks is metadata-only unless a validated local capability actually exists.

Back/Escape closes the topmost menu, sheet, details or sample first. From the deck it exits without a “discard decisions?” dialog: local decisions are already durable. Back never means reject the current title. Re-entry restores the session's current card only after authorization, expiry and availability checks; otherwise show the next valid card with a quiet explanation.

## First card, with no setup tax

The header contains Back, **Find your next**, **Saved picks (n)** and the existing overflow pattern. The content begins with one context control, such as **Listen · 30 min · Offline**. Tapping it opens the existing adaptive sheet. There is no forced tutorial or initial settings dialog.

Show a dismissible one-line hint near the ordinary buttons on the first session: “Swipe or use the buttons. Save picks for later.” A Help menu entry explains the actual direction mapping. No tooltip is required to discover a core action.

The context sheet uses connected preference rows, existing chips/pickers and normal Apply/Cancel actions. Cancel leaves the session unchanged; Apply creates a new filter generation, preserves saved picks and neutral history, and refreshes candidates without mixing late responses.

| Context option | Default and interpretation |
| --- | --- |
| Activity | Anything; offer Watch, Listen and Read only when there are corresponding enabled adapters |
| Time | Any; 10 / 20 / 30 / 60 minutes plus custom positive minutes. Choose “Finish something” or “Spend this long” when the distinction matters |
| Availability | Available now; optionally Offline only or Include unavailable. An expired loan is never available now |
| Sources | Current library on entry, otherwise configured profile sources; existing picker style, no provider setup wizard inside the sheet |
| Familiarity | New to me; allow Continue something, Revisit favorites or a mix. Music repeat listening is not treated as watched video |
| Mood | Optional small vocabulary grounded in known tags: Calm, Light, Tense, Thoughtful, Surprise me. Show “Match when known”; do not claim inferred emotions as facts |
| Language/access needs | Follow existing preferences; explicit required audio/subtitle/reader language and captions can be strict filters |
| Details | Source-specific genre, author/narrator, year, rating, series order, explicit-content exclusions and saved seeds; shown only where supported |

New to me means exclude reliably completed items for completion-oriented media, prefer unstarted choices and retain unknown history as unknown. Continue something selects useful units using actual progress, never invents it. Strict access, language and rating restrictions remain hard gates even if the deck is small. Offer explicit filter relaxation; never silently relax restrictions.

## Stable decision surface

The information hierarchy is artwork → title → type/duration/availability → one reason → brief description → actions. Covers retain their natural aspect ratio. Backdrops may crop within the existing hero treatment; book/album covers must not be stretched or used as illegible full-bleed text backgrounds. Absent artwork uses the shared placeholder.

Example card copy, illustrative rather than catalog facts:

> The Glass Coast · Audiobook
>
> Next chapter: 18 min at 1.25× · 8 hr 40 min left in the book
>
> Available offline · Narrated by Maya Chen
>
> Because you saved another book by this author.

Use a compact fact row, not multiple bordered cards or a score dashboard. Omit unsupported fields instead of rendering “N/A” badges. A reason must be backed by an actual source or user event. Generic recommendations use “From your library” or an attributed catalog row, never fabricated personalization.

The primary action area has **Not now**, **Save**, and the medium's explicit **Play / Listen / Read / Watch live** action. Match the main detail screen's primary button emphasis for consumption; the two decision actions use the existing quieter variants. **Undo** and **Details** remain reachable in a secondary row; **Sample** appears only when available. On narrow screens, split actions into natural rows without shrinking labels or tap targets. Overflow contains less frequent actions.

Playback is not a swipe outcome. A swipe can be repeated quickly without accidentally launching a video or placing a hold. If only discovery is supported, replace the consumption action with **Details**, **Check availability** or **Open in [service]**, as appropriate; avoid a disabled “Play” that suggests a broken player.

## Action semantics

| Action | Durable effect | Effect on deck and taste | Undo |
| --- | --- | --- | --- |
| Not now | Session decision with neutral meaning | Advance; exclude for the current session, modest recent-exposure penalty afterwards; no genre/author dislike | Restore previous card and decision state |
| Save | Profile Saved pick with exact work/edition intent and available targets | Advance; weak positive discovery signal only | Revert only the save operation this session created |
| Play / Listen / Read | Revalidated canonical launch | Leave deck suspended; actual subsequent consumption may inform recommendations | Ordinary player/reader Back; no automatic removal from Saved picks |
| Sample | Ephemeral isolated preview | Freeze active card; no taste inference from sample duration | Stop/Back restores card, focus and untouched resume point |
| Hide this title | Explicit title-level discovery exclusion | Remove after acknowledged local write; reason optional | Persistent History → Restore |
| Less like this | Explicit, inspectable preference on a chosen trait | Re-rank unseen candidates; no broad hidden inference | Remove preference in normal sheet/history |
| Already finished | Explicit canonical watch/read completion action if supported | Existing confirmation and exact scope; do not confuse with “I know this title” | Existing history semantics, not generic deck undo |
| Add to [provider] watchlist | Explicit external operation via source owner | Does not change local Save unless separately requested | Provider's normal remove operation; report failure honestly |
| Request / Borrow / Hold / Download | Existing service workflow and current permission checks | Save may remain independent; canceled/failed actions leave card intact | Their canonical owner, not swipe history |

Repeated Save on an already-saved item is idempotent and labelled **Saved**. Undo must not remove a save that existed before this session or one modified elsewhere after this operation. Failed local persistence keeps the card in place with Retry; do not animate success that disappears after a crash. Use the shared snackbar only for meaningful feedback; ordinary swipe feedback is the action label/state, not a flood of toasts.

## Shortlist and decision completion

**Saved picks** uses the existing media grid/list and context menus. It retains type/edition, source and truthful availability. Recently added comes first by default; Activity and Available now filters are ordinary controls. Removing a pick affects only this list.

From the list, **Compare** selects two or three choices in the existing selection idiom. The adaptive sheet shows only decision-useful differences: duration/unit, medium, language/access support, availability, narrator/edition and a short synopsis. It is a stacked list on narrow screens and a side-by-side comparison where space permits. No global cross-media star-score ranking.

**Choose for me** operates on this explicitly selected shortlist, after rechecking hard filters and availability. It reveals one choice and a normal start button; it does not start playback on a timer. If nothing qualifies, explain the failing constraint and let the user edit it.

**Choose together** is an optional co-present mode inside the shortlist menu. Each guest privately selects Yes / Maybe / Not tonight from the same active profile's permitted pool, passing the device or remote behind a neutral handoff screen. A privacy cover hides completed ballots. Default result: maximize minimum approval, then total approval, then deterministic session order; any Not tonight veto excludes that choice. No common option produces a visible no-match state with explicit choices to widen the pool. Never turn vetoes into another person's taste profile. Guest identities are temporary names; discard ballots on exit/profile change. This does not log into protected household profiles, fetch their histories or invent remote multi-device matchmaking.

## Same story, another way

When verified relationships exist, show one quiet **Other ways to enjoy this** affordance under availability. The sheet can contain an ebook edition, audiobook narration or an adaptation, each with its own label and action. An adaptation is a related work, never another encoding of the same work. Abridged and unabridged audio, translations and narrator variants remain distinct editions.

Do not equate ebook percentage with audiobook time. Do not infer a relation from a similar title alone. Switching format opens its own progress. Unsupported devices can save a target for a suitable device. “Continue on another device” is shown only once the existing pairing/sync capability can resolve that exact target on the destination; otherwise say **Save for later**, not a fictional handoff.

## Component ownership — reuse, do not restyle

| Concern | Existing canonical owner | Required use |
| --- | --- | --- |
| Palette, radii, spacing, motion | `lib/theme/mono_theme.dart`, `mono_tokens.dart` | `Theme.of`, `tokens(context)`; built-in light/dark/OLED/custom palettes; no hard-coded dark page |
| Layout breakpoints and TV inset | `lib/utils/layout_constants.dart` | Existing `ScreenBreakpoints` and `TvLayoutConstants`; consider height and text scale as well as width |
| Art loading and isolation | `lib/widgets/optimized_media_image.dart`, `lib/utils/media_image_helper.dart` | Existing authenticated image path; bounded decode size, shared placeholders/cache |
| Hero/TV composition | `hero_hub_section.dart`, `tv_spotlight_scaffold.dart`, `tv_spotlight_background.dart` | Reuse/extract presentational pieces without inheriting autoplay theme songs or whole Home state |
| Ordinary controls | `AppIcon`, `FocusableButton`, `FocusableMediaCard`, `FocusableFilterChip` | Existing icon family, focus chrome, keyboard/remote semantics and size conventions |
| Menus | `lib/widgets/app_menu.dart` | `AppMenuButton` and adaptive popup/sheet behavior |
| Sheets | `lib/widgets/overlay_sheet.dart` | `OverlaySheetController.showAdaptive`, with correct profile ownership and focus restoration |
| Confirmations | `lib/utils/dialogs.dart`, `DialogActionButton` | Scoped dialogs, normal Cancel/confirm placement; no custom nested alert stack |
| Feedback | `lib/utils/snackbar_helper.dart` | Existing localized safe messages; no raw provider errors |
| Input/focus | `lib/focus/`, especially `InputModeTracker`, `DpadNavigator`, `CoveredRouteFocusBoundary` | Stable focus, one activation, route coverage, host Back handling |
| Navigation | `profile_navigation_scope.dart`, `profile_session_screen.dart`, navigation helpers | Retire route on profile change; restore origin; honor PIN gates |
| Words and formatting | `lib/i18n/*.i18n.json`, `strings.g.dart`, `lib/utils/formatters.dart` | Slang keys, plural/select forms, existing duration/rating formatting |

Screenshot reference: [current mobile media detail](../../maintainers/store-listing-assets/google-play/phone-04-media-details-1080x1920.png). Retain that artwork, scrim, quiet metadata and primary-pill hierarchy. The screenshot is a reference, not a new mockup or evidence that the proposed route exists.

## Responsive storyboard

| Surface | Layout | Focus and consumption behavior |
| --- | --- | --- |
| Phone portrait | One cover/backdrop region, title/facts below, compact synopsis; action area within safe area; content can scroll above it | Primary actions always reachable, bottom navigation origin preserved; no fixed card height clipping text |
| Short phone / landscape / 200–300% text | Reduce artwork first, then reflow to one scrollable column with a reachable action section | Never shrink accessibility text to fit; safe-area/keyboard/sheet controls stay reachable |
| Tablet / resizable desktop | Art alongside text when actual width allows; generous empty space, narrow reading measure | Pointer buttons and keyboard focus are primary; trackpad scrolling does not make decisions |
| TV / ten-foot layout | Existing cinematic spotlight composition; artwork to one side, large readable content and stable action row | D-pad moves focus, Select activates; cards do not fly or rotate across the screen |
| Reduced motion | Static artwork and instant content replacement or permitted minimal opacity change | Outline, labels and focus remain; no drag-driven tilt, zoom, parallax or slide animation |
| Offline | Same composition using authorized cached metadata and validated local files | Source details and Save work locally; unavailable actions explain reconnect without losing session |

Tablet/desktop two-column composition is conditional on remaining text width, not a hard 600 px assumption. Follow existing 600/900/1200/1600 breakpoint constants and layout constraints. On TV, use existing scaling/insets, including 720p/1080p/4K tests; do not scale the phone layout.

## Input contract

| Input | Decision/navigation mapping | Collision prevention |
| --- | --- | --- |
| Touch | Swipe toward labelled Save side to save; opposite side Not now; visible buttons always work | Horizontal gesture only on artwork/noninteractive card region; vertical scroll, reader gestures and OS edge Back win |
| Mouse / pen | Click ordinary actions; optional drag on artwork | Text selection, sliders, scrollbars and menus never start a card gesture |
| Trackpad | Scroll content, click buttons | Two-finger horizontal/vertical navigation is not a destructive or implicit decision |
| Keyboard | Tab/Shift-Tab, Enter/Space on focused actions; Escape normal Back; optional scoped Ctrl/Cmd+Z undo | Bare arrows navigate focus/content, not accept/reject; no global letter shortcuts; composing text and covered routes own their keys |
| TV remote / D-pad | Left/right/up/down move focus; Select activates; Back follows route stack | No decision on focus change, touchpad flick or long press; key-repeat/release guard prevents skipping multiple cards |
| Gamepad | Same focus/action model where the existing platform maps controller events | Use actual mappings reported by the input layer; no unsupported controller promise |
| Screen reader / switch / voice control | Labelled ordinary controls and named semantic actions | Disable raw card-swipe capture while touch exploration is enabled; reading navigation never consumes a card |

Gesture prototype defaults: use Flutter touch slop; require horizontal dominance of at least 1.5× vertical displacement before ownership; commit on release after 25% of artwork width clamped to 64–144 logical pixels. A faster flick may commit only after at least 48 logical pixels and 800 logical pixels/second in the same direction. Otherwise snap back. These are testable starting values, not claimed universal ergonomics. Add a gesture-off setting; all actions stay available.

Use logical leading/trailing directions. In LTR, trailing/right is Save; in RTL, trailing/left is Save, matching the mirrored labelled controls and hint. Keep the mapping stable for the session. Locale/direction changes cancel any in-flight drag before applying the new layout. Test Arabic/Hebrew users' expectations; if that requires a documented convention change, change hint/buttons/semantics together rather than silently reversing one layer.

Touch feedback moves only the artwork region and reveals the destination's text/icon in the active theme. No red/green dependence, dating hearts, card pile, rotation, confetti or sound. Use Mono timing tokens; haptics are optional, one light confirmation after commit and never required for understanding. Reduced motion disables the decorative movement; gesture detection can still dispatch the same actions.

## Accessibility and localization acceptance

- Ordinary controls meet at least 48 logical pixel targets; shared TV focus area is larger where its canonical style requires it. Focus rings and text must remain clear over any artwork. Text targets 4.5:1 contrast, large text and non-text focus/control boundaries 3:1, with actual theme/backdrop checks.
- Preserve the platform nonlinear text scaler; test 200% and a 300% stress case. Long titles/descriptions may scroll, not disappear. Truncation has an accessible full-text route. The action area cannot cover the last content line or trap scrolling.
- Semantic order: title, kind, commitment, availability, reason, description, actions. Announce “Saved [title]. Next: [title]” or equivalent once after commit; do not read the entire synopsis or every drag tick. Keep only the active card in semantics.
- On replacement, preserve the activated button's semantic/focus slot; announce the new title. Repeated physical key holds cannot activate the next card. If that action disappears, move to the nearest stable safe control, never to the page root or an unseen card.
- Undo is persistent in the header/history, not a three-second-only toast. Announce restored state and return focus predictably. Menus/sheets return to their opener; profile teardown cancels all restoration into retired routes.
- All controls, semantic hints, states, reasons, plural counts, duration qualifiers and shortcut labels use Slang. Never concatenate a translated verb with an assumed English media noun.
- Test English, German expansion, Arabic and Hebrew RTL, Simplified/Traditional Chinese, Japanese and Korean, plus locale-specific numerals/dates. Do not use English character counts to estimate CJK reading time. Wrap mixed-script titles/source names in direction-aware spans and use logical padding/alignment.
- Show original/localized titles when the provider supplies them. UI language is distinct from content language. Unknown narration/subtitle/text language stays unknown; strict language or captions requirements exclude unverified offers until resolved.
- Reduced motion, stronger contrast and larger-control preferences compose with system preferences. Reuse the now-merged `AppAccessibility` shell; do not create parallel settings with contradictory behavior.
- No sound or color is the sole cue. Video samples retain subtitle controls where available; audio samples retain accessible transport labels. Image-only comics do not acquire invented alt text or an OCR claim.

## Empty, slow and changed states

| State | User-facing outcome |
| --- | --- |
| First load, useful cache | Render authorized cached candidates and refresh behind them; label access freshness accurately |
| First load, no cache | Existing skeleton for one card; working source can respond without waiting for slow siblings |
| Zero configured sources | Existing Add source / Connect server entry; no blank stack or fake recommendations |
| No matches | “Nothing matches these choices.” Show the active constraints and one Edit choices action; no auto-relaxation |
| End of session | Review Saved picks, change choices or explicitly Get more; no duplicate-card loop |
| Partial provider failure | Keep other candidates; one source status in context sheet with Retry; no full-page failure |
| Expired auth | Offer reconnect through the standard connection flow; retain local picks, suppress inaccessible artwork/data |
| Item removed / loan expired / live program ended | Revalidate; show the change, keep recoverable save, offer another copy only after confirming its identity |
| Local write failed | Keep current card; explicit Retry and a safe explanation; no phantom save |
| Sample unavailable | Keep card and ordinary start/details route; no silent full playback fallback |
| Profile switch/lock, background or route covered | Cancel drag, sample and pending discovery work; never leak previous profile cards into the new session |

On app background, retain durable decisions and a compact session checkpoint; release decoders and sensitive preview resources. Resume revalidates the profile and current item. No overnight background generation or automatic downloads are introduced.
