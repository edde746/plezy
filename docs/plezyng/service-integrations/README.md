# PlezyNG service integration audit and Luna handoff

Prepared **2026-10-27, America/Regina**. Scope and implementation update **2026-10-28**: the three explicitly excluded streaming services are removed from PlezyNG's provider directory and catalog-launch surface. The code now includes broad official-site handoffs, an in-app Google Books search, OpenSubsonic/Subsonic music sources, podcast RSS/Atom playback, OPML import/export, Audiobookshelf JWT session renewal with legacy-token compatibility, and OPDS open-access/sample classification. Server/feed qualification, partner accounts and affiliate tracking remain outstanding.

**Recommendation — high confidence:** make PlezyNG the place to find a title, see the copies/subscriptions/loans/offers available to the active profile, and choose the right way to use it. Implement native playback where a supported content API or SDK permits it; use official app/site handoff elsewhere. Keep the current navigation, artwork-led presentation, profiles, readers and player owners.

## Direct answers

| Question | Assessment | Confidence |
| --- | --- | --- |
| What is excluded from this delivery? | Netflix, Prime Video and Disney+ are not offered as connected providers, title destinations or availability sources. Amazon Books, Kindle and Music storefront links remain distinct retail/music handoffs; they do not enable Prime Video. | Explicit product scope |
| Can we connect to Kobo? | Affiliate storefront links and catalog feeds by agreement; official Kobo reading/Plus handoff; import exported DRM-free EPUB/PDF. Do not promise automatic account-library import or DRM playback. | High for exports and affiliate program; unknown for consumer account API access |
| Amazon/Kindle/Audible? | Eligible Kindle DRM-free purchases now have an EPUB/PDF export path. Ordinary protected Kindle/Audible content stays in provider apps. Use Creators API for approved product-catalog work, not deprecated PA-API 5. Associates distribution restrictions make desktop/TV monetization a blocker under standard terms. | High; exact marketplace/product eligibility needs confirmation |
| Indigo? | Offer Canadian print-book commerce and verified ebook offers. Current Indigo ebooks are Kobo fulfilled. Model seller and fulfillment provider separately. Affiliate participation is a commercial lead; PlezyNG-specific app approval and payout are unverified. | High for Kobo fulfillment; moderate for affiliate lead |
| Best near-term paid integrations? | Libro.fm, Kobo, Apple Performance Partners, eBooks.com, Bookshop.org where regionally available; GOG/Fanatical for the existing Games surface. Approve the specific app/channel before adding tracking. | Moderate prioritization; no revenue forecast |
| Best integrations without commission? | Qualify OverDrive; expand approved Hoopla/Palace/regional-library access; improve OPDS/Audiobookshelf; add book-tracker imports and licensed streaming availability. OpenSubsonic and podcasts/RSS now have initial code slices. | High architectural fit; access and effort differ |

Sources and precise limits are in [PROVIDERS.md](PROVIDERS.md), [COMMERCIAL.md](COMMERCIAL.md) and [SOURCES.md](SOURCES.md). “No public route established” is a research result, not a claim that a private agreement can never exist.

## Read in this order

1. [AUDIT.md](AUDIT.md): inspected source baseline, existing functionality, gaps and branch coordination.
2. [PROVIDERS.md](PROVIDERS.md): broad service landscape, achievable depth, integration mechanism, gates and priorities.
3. [ARCHITECTURE.md](ARCHITECTURE.md): proposed contracts, identity, credentials, backend and synchronization.
4. [UX.md](UX.md): how each connection fits existing screens, interactions and styling.
5. [COMMERCIAL.md](COMMERCIAL.md): affiliate programs, distribution rules, costs and business decisions.
6. [IMPLEMENTATION.md](IMPLEMENTATION.md): ordered, reviewable Luna work packages and starting instructions.
7. [VALIDATION.md](VALIDATION.md): acceptance matrix, platform qualification and release evidence.
8. [SOURCES.md](SOURCES.md): primary-source register, freshness and uncertainty.

## Current code delivery

- A region-aware official destination directory covers subscription/ad-supported video, rentals, books, audiobooks, comics, music and game storefronts. It is searchable and opens in the platform's official app/browser.
- Explore details, media details, source-backed book/audio/video/comic details, game context menus and Settings → Services link into the same directory.
- Catalog-supplied streaming links to the excluded services are filtered. Native server/file playback and existing library flows retain their own state and actions.
- The existing public library catalogue can switch between Open Library and the unauthenticated Google Books public catalogue API. Google sale metadata is shown only when the API supplies a provider purchase link, price and currency; purchase opens Google Books.
- OpenSubsonic/Subsonic-compatible servers now appear as music sources with artist, album, recent-album and search browsing, streaming through the existing audio player, and profile-local resume progress (optionally synced through a configured WebDAV state folder). Podcast RSS/Atom feeds can be added directly or transferred in bulk through OPML; private feed URLs and Basic credentials stay encrypted at rest. Neither adapter claims provider-side scrobbling or universal server/device qualification.
- Audiobookshelf can sign in with server username/password and refresh rotating JWT sessions through the encrypted source vault; existing bearer-token entries remain supported. OPDS now admits only explicit open-access/sample file relations, labels samples as previews, and leaves generic acquisition, lending and licensed fulfillment outside the unrestricted reader/download path.
- No third-party provider account, entitlement, playback, live price comparison, affiliate attribution or commission is claimed by the handoff directory.

## Product rules to carry into implementation

- Availability, subscription preference, verified entitlement, a local file and a playable session are separate facts.
- An external launch is not evidence of playback, completion, purchase or a successful loan.
- A book work, its print/ebook/audio editions and a film adaptation are related entities, not interchangeable copies or progress timelines.
- Existing/offline access and free library choices remain visible irrespective of commission. Revenue does not determine default access ranking.
- Extend Settings → Services, Libraries/Files and books, public-library screens, Search, Explore, details and Find your next. Do not add a top-level tab per vendor or a second media library implementation.
- Protected fulfillment requires an explicitly supported DRM/SDK path. A system codec or DRM module alone does not authorize a service integration.
- Every release claim is scoped by provider, territory, account type, platform, distribution channel and demonstrated capability.

## Initial release target

Ship a coherent vertical slice: an existing book/movie detail can show **Your copies**, **Your libraries**, **Your services**, and **Buy or rent**, only where applicable; a Canadian user can open an approved store, import an eligible file through the existing import flow, and resume it through the existing reader/player. Streaming services launch externally with a reliable return to the same detail. Partner-gated features remain disabled until evidence exists.

Do not make “integrate every provider” one release. The provider landscape is intentionally broader than the first implementation tranche; the work packages distinguish build-now, qualify-next, partner-pending and research-only work.
