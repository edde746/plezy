# Fit with PlezyNG's existing flow and style

Status: proposed behavior. **High confidence:** the existing design and navigation contracts are suitable. No new visual identity or top-level store/provider dashboard is needed.

## Screen mapping

| Existing surface | Proposed addition | Preserve |
| --- | --- | --- |
| Settings → Services | Grouped rows for media servers/files, libraries, streaming preferences, stores, tracking and devices; one searchable Add service route when the directory grows | `FocusedScrollScaffold`, `SettingsGroup`, current service-specific screens, profile scope and PIN checks |
| Libraries → Files and books | Existing connected sources and import actions; clear shortcuts to public libraries and supported file providers | Existing library picker, shelves, reader/player routes and hidden empty shelves |
| Public libraries | Library cards/connections, loans/holds and official handoffs; provider-specific statuses | OverDrive Coming soon, explicit circulation confirmations and due-date semantics |
| Media/book detail | Compact access section below existing primary controls: Your copies, Your libraries, Your services, Buy or rent; show only applicable groups | Artwork, metadata, current Play/Read action, existing adaptive source/versions picker |
| Search | Progressive local/server results plus opt-in remote catalogs/offers, with source and media-kind distinction | Debounce, stable focus, independent errors and existing filters |
| Explore | Optional catalog/availability rows from enabled providers and saved picks | Existing poster/cover rows; no wall of provider tiles |
| Home | Actual native Continue Watching/Listening/Reading; optional due-soon loans and recent external launches as separately named rows | User-configured row order, offline-first copies, no assumed external progress |
| Find your next | Eligible catalog candidates with access hint and canonical detail route | Save/Not now/Undo only; a swipe never borrows, buys or starts a trial |
| Downloads | Only qualified native files or certified licensed offline assets | File completion checks, local storage policy, user-owned files independent of account disconnect |
| Games | Official-store offers on existing game detail/grid; host route remains Play authority | AppID/host identity, existing artwork cards and remote-input behavior |

## Setup journeys

### Streaming service with no account API

Settings → Services → Add service → Netflix → select country and optional subscription tier → **Add to my services**. The result is a local preference. Copy: “Show titles available with your service. Watching opens Netflix.” Do not show a Netflix password field, OAuth success message or “Library synced.”

On a title: **Open in Netflix**. If a verified title destination is unavailable, offer **Find on Netflix** only with a supported search/site route, and explain that the exact title link is unavailable. Do not turn a home-page launch into evidence that the title is available. Keep sign-in and account selection inside the official app/browser.

### Library with supported native access

Add library → select institution → see supported actions and official mark → authorize on the provider's supported surface → return to the original profile → show loans/holds/catalog. A library is “Linked” only after the expected account/circulation scope is validated. A failed account check leaves a clear reconnect state.

Title detail shows **Borrow**, **Place hold** or **Open loan** from current provider state. Confirm the action and any known borrowing limit before consuming it. A hold-ready state is not the same as a checked-out loan. Return/cancel actions retain confirmations. The fulfillment button names an external reader when the content cannot open in PlezyNG.

### Storefront and file import

Select country and optional preferred stores; this normally requires no store sign-in. Book detail → choose format/edition → compare available offers → **Buy ebook at Kobo** or **Buy audiobook at Libro.fm**. Show original currency, current price timestamp where required, and external destination.

After the user comes back, preserve the detail. Offer an unobtrusive **Import a file** action where compatible downloads are possible; never assert the purchase succeeded. Import uses the existing picker/share/open-file route, archive safeguards and publication shell. A file with an ACSM/LCP/encrypted payload opens a supported-fulfillment explanation, not a corrupt-file error or a fake imported book.

### Self-hosted service

Add service → choose Audiobookshelf/Navidrome/Komga/Kavita or a protocol → endpoint and supported authentication → test connection → select libraries/shelves → normal Libraries. A preset supplies labels/help/defaults but still uses one canonical adapter. Do not ask users to configure the same server twice for browsing and playback.

## Access option presentation

Recommended order, **moderate confidence**, subject to user preference and actual eligibility:

1. Resume a verified usable copy in PlezyNG; show edition and source if ambiguity matters.
2. Other verified owned/native copies, with a compact chooser when necessary.
3. A current usable loan, then borrow/hold opportunities from the user's libraries.
4. An offer on a service the user has selected, clearly marked as subscription availability rather than verified access.
5. Other free/ad-supported options.
6. Rent/buy/subscription offers, with optional price sort within the same format/territory.

This ordering is a UI recommendation, not a new automatic playback algorithm. Preserve the existing copy-ranking policy for native copies and the user's remembered destination. Do not silently switch formats, editions, countries or providers to maximize commission. Due-soon loans can be highlighted without outranking an explicitly selected copy.

An access row contains an approved provider mark, provider/action, relevant format/tier/price/due date, and a quiet external indicator when needed. Avoid duplicate artwork and nested decorative cards. Use an adaptive sheet only when choosing among several equivalent paths; a sole clear native route remains direct.

## Truthful labels

| State | Preferred user-facing language | Never imply |
| --- | --- | --- |
| Selected service, no account API | “In your services” / “Opens Disney+” | Verified subscription or synchronized library |
| Supported auth verified | “Linked” and safe account label | All media types or countries automatically supported |
| Data known but subscription unknown | “Available with Prime Video” plus channel/tier when supplied | “You own this” |
| Protected fulfillment | “Read in Kobo” / “Listen in Audible” | Native Read/Listen in PlezyNG |
| Store availability | “Buy paperback at Indigo” | Ebook access or local ownership |
| Stale price | “Check price at store” or clearly dated permitted cached value | Current cheapest price |
| Provider timeout | “Availability couldn't be checked” with retry | No available copies |
| Retired/unsupported capability | “Not available on this device” or targeted explanation | A disabled generic Play control with no recovery |
| Account API unavailable | “Open service” | “Connect account” |
| OverDrive gate closed | Existing “Coming soon” plus working Libby handoff | Enabled borrowing |
| External app return | Return to detail without success toast | Watched/read/purchased/borrowed completion |

For eligible affiliate rows, a concise adjacent disclosure such as “Purchases through these links may support PlezyNG” can coexist with detailed attribution/terms in service information. Merchant-mandated wording still governs. No disclosure banner over artwork or player controls.

## Design rules

Use `MonoTokens`, existing spacing/card geometry, system typography, shared icons, `AppMenuButton`, existing confirmations/snackbars and focused list tiles. Keep vendor colors in official marks; do not recolor them or theme an entire screen around a vendor. Add provenance/license entries to the provider-artwork manifest. Unknown logos use a neutral service/media symbol, not a guessed unofficial mark.

Prices, due dates and service names are secondary to the title and primary action. Do not put affiliate earnings, API quotas, DRM jargon or integration status codes into ordinary browsing. An unavailable action should explain the user consequence and next step, while diagnostics retain technical details.

## Input and accessibility

Every row/action works with touch, mouse, keyboard, D-pad and screen reader. Additions preserve stable focus IDs as offers arrive asynchronously. The external-app return restores the originating row; Back/Escape closes the chooser before leaving detail. Pending mutations cannot dispatch twice through double-click, Enter repetition or remote repeats.

At narrow widths and large text, price/status wrap beneath the provider rather than compressing the action target. Use existing high-contrast/reduced-motion behavior. Do not rely on color for free/paid/expired/linked states. Screen readers announce title, provider, action, relevant price/expiry and external destination once, not redundant nested labels.

TV setup uses the existing QR/device-code patterns when a provider supports them. TV may not support a browser or app link; show only tested actions. Companion/phone purchase links obey the same distribution policy as on-device links. File import and Downloads remain platform-qualified; do not add tvOS actions merely because mobile supports them.

## Profile and offline behavior

Service selections, country, connected accounts, libraries and saved picks are profile scoped. Shared family devices must not expose another profile's loans, store history or private feed names. Existing parental/PIN controls gate applicable catalog categories, connection edits and purchases. No app-install heuristic grants a child access to adult streaming catalogs.

Offline mode retains downloaded owned media and permitted cached metadata. Online offers can appear as cached reference only if the license allows it; launch/borrow actions explain connectivity needs. Missing remote data does not hide playable local copies. A disconnected library loan cannot be reclassified as an owned book.

## Concrete walkthroughs for Luna

- **Movie already on Plex and also on Netflix:** existing Play resumes Plex. Access section offers the other Plex versions and “Open in Netflix”; no Netflix authentication stored, no scrobble from external launch.
- **Novel with Kobo ebook, Indigo paperback and Libro audiobook:** one work overview may link to three explicit format/edition details; each price and fulfillment stays attached to its own product. Listening progress never overwrites ebook location.
- **Libby loan available, Kobo purchase also offered:** loan and expiry appear in Your libraries; official fulfillment is explicit. The paid offer remains discoverable without displacing the free borrowing path.
- **Canadian title only available through a Prime channel:** display the actual channel requirement. Selecting Prime does not mark every channel available.
- **Bandcamp album imported from FLAC files:** existing owned-music flow is authoritative. A store link is provenance/discovery, not required at every play.
- **Steam game sold at Fanatical but no paired host has it installed:** show a store action if eligible; Play remains unavailable until a real host route exists.
