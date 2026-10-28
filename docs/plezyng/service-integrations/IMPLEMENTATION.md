# Luna implementation plan and delivery record

Status updated **2026-10-28** for service integrations PR #52 against `main` `90ad28df9fc4bd3d808b4a4509a195bab632fa9a`. The code adds official destination handoffs for video, rentals, books, audiobooks, comics, music and games; title-prefilled launch flows; exclusions for Netflix, Prime Video and Disney+; Open Library/Google Books catalog search; OpenSubsonic/Subsonic music browsing and playback; podcast RSS/Atom feed sources and OPML import/export; profile-scoped integration contracts/preferences; connected-catalog search; Hardcover status/shelf sync; and exact Steam game-store links. This update adds free/ad-supported TV handoffs and a typed, pre-key licensed-availability boundary. Private feed URLs and credentials remain encrypted.

This is a handoff and public-catalog slice, not a universal provider-account, entitlement, playback, comparison-shopping or affiliate implementation. Existing local files, media servers, trackers, OPDS and lending continue through their current owners. Do not claim partner-gated features based on search fixtures or official links alone.

W03 has curated, policy-checked official handoffs. W04 has profile-scoped country and preferred-provider ordering plus optional user-entered plan labels; these preferences do not imply account linkage or entitlement. W05 preserves validated ISBN-10/ISBN-13 values from Open Library, Google Books and OPDS and uses them for edition-aware official store searches with title/creator fallback; approved merchant feeds/tracking remain gated. W09 federates global Search across connected catalog sources with local/server/Files and Seerr results, exact cross-catalog IDs, profile-confirmed catalog-to-server matches, and bounded Find Next sampling from connected sources; the Explore tab itself keeps its existing selected-source model. W10 adds initial OpenSubsonic and podcast feed playback through existing sources; OPML intentionally imports HTTPS feeds only. W12 adds Hardcover read-only shelf import and previewed, status-only writes with an undo path. W13 uses an exact Steam AppID when available and title search otherwise. Remaining packages still need fixtures, upstream access, platform/device qualification or business approval as stated below.

## First session

1. Read current `AGENTS.md`, `DESIGN.md`, `UX-CONTRACT.md`, this folder, `docs/LENDING_SETUP.md`, `docs/plezyng/connected-media/DELIVERY.md`, `docs/games/STEAM_LIBRARY.md` and the current remote-stream handoff.
2. Recheck the current main and active integration branch SHAs recorded below before touching shared catalog/source types. The debrid/Stremio account/source work remains separate; do not reset or overwrite its branch.
3. Create an implementation branch from the agreed current base. Reuse this assessment as documentation; no need to cherry-pick unrelated integration implementations blindly.
4. Inventory existing tests and dependency injection around profiles, catalogs, sources, playback, lending, navigation and service settings. Reuse fake HTTP/clock/platform seams.
5. Extend the delivered handoff slice only through supported public/approved routes. Keep store offers, affiliate tracking, service accounts and playback capability separate.
6. Keep the provider capability/qualification ledger current. This PR's new code is not live-provider qualified; follow-up work must add evidence instead of unsupported capability claims.

## Work packages

Effort estimates are **low confidence**, in engineering-day equivalents including review and local verification, not agent runtime or calendar promises. Business approval, device availability and major upstream changes are additional unknowns. Optional breadth is not all required for the first release.

| ID | Package / dependencies | Concrete deliverable | Exit criteria / estimate |
| --- | --- | --- | --- |
| W00 | Reconcile baseline; none | **Reconciled:** audited the active debrid/Stremio branch at `497a98886d18c80291409c9289bda48c8a67682f` (12 commits beyond merge base `2d08006cea19c6a661aed457a1f104c4e74cdfaa`) and current `main`; kept its account/source ownership separate because its broad source/search changes are not part of this PR | Recheck the branch before touching its registries; no duplicate debrid account store or catalog-key migration is introduced here |
| W01 | Capability contracts and fixtures; W00 | **Partially delivered:** typed entity/identifier/relation/offer/evidence/target/connection models, deny-by-default commercial action policy, and an availability-adapter boundary with runtime checks for exact title identity, territory, result bounds and official seller hosts | Fake providers and sanitized fixtures remain; unknown capabilities cannot imply playback, ownership, download or connection; malformed/ambiguous IDs are rejected; 4–7 days |
| W02 | Persistence/profile lifecycle; W01 | **Partially delivered:** profile-scoped country/provider/tier preference storage and reversible confirmed identity crosswalk storage; Hardcover credentials and snapshots use the existing encrypted source repository | Generic connection lifecycle remains service-owned; no licensed offer cache is persisted before retention rights. Profile-switch/delete/key-loss checks remain; 4–6 days |
| W03 | External destination dispatch; W01/W02 | **Delivered for curated official links:** title-prefilled HTTPS destinations, official-host policy validation, marketplace-aware routing, profile-scoped country preference, preferred-provider ordering, exact Steam AppID routing, platform launcher fallback and return to the existing detail route | Warm/cold link and platform handler qualification remain; dispatch never updates watched/owned/loan state; 3–5 days |
| W04 | Access rows and service preferences; W01/W02/W03 | **Partially delivered:** searchable Settings Services directory; profile-scoped country and preferred-provider choices influence official title searches; optional user-entered plan labels are shown as notes only; existing tracker/Seerr/Hardcover account settings retain their service owners | Verified entitlement and unified detail access rows, plus large-text/RTL/device checks remain; 4–7 days |
| W05 | Book commerce/import slice; W04 | **Partial code delivered:** public Open Library/Google Books results and OPDS/source books retain validated ISBNs; official storefront searches use ISBN for edition matching and fall back to title/creator. Existing imported-file flow remains the fulfillment path. | Libro/Kobo or other approved fixture/live route; no account-sync claim; DRM/protected-file handoff; approved merchant feed/tracking and attribution tests; 5–8 days total |
| W06 | Licensed availability slice; W04 | **Pre-key code delivered:** typed `AccessOffer`/evidence models, provider readiness gates, bounded lookup request/result, adapter registry, exact-identity validation and official seller-host checks. No data adapter, offer cache or offer rows are enabled. | Supplier bake-off and an approved live adapter still need CA sample evidence, correct channel/rental/price semantics, retention/attribution terms, partner approval and backend credentials. Keep confidential keys server-side; no private API or fabricated deep links; 4–7 days plus vendor access |
| W07 | Existing-source maintenance; W00 | **Partially delivered:** Audiobookshelf JWT login/refresh with encrypted rotation persistence and legacy bearer compatibility; OPDS explicit open-access/sample classification, known supported file-extension fallback, first-supported format selection for mixed-format entries, and a Project Gutenberg OPDS setup preset | Generic/protected OPDS acquisitions excluded from the normal file path; existing sources retained. Versioned auth/feed fixtures and server/redirect qualification remain; 4–8 days total |
| W08 | Lending expansion; W02/W04/W07 | Existing OverDrive native code remains behind `ENABLE_OVERDRIVE=false`; this work adds no library connector. Hoopla adapter or Palace pilot requires separate approved access | Live sandbox auth/circulation/expiry/reconciliation/fulfillment evidence; gate remains closed otherwise; 8–15 days excluding approval |
| W09 | Unified query projections; W04/W05/W06 | **Partially delivered:** connected Plex Discover, Trakt, MAL, AniList, Simkl and MDBList title search alongside server, Files and Seerr; bounded provider requests, isolated failures, provider filters, exact same-kind ID deduplication, reversible user-confirmed catalog-to-server crosswalks, and bounded Find Next sampling from connected catalogs | Explore continues to show the user-selected catalog source; no cross-edition progress merge; provider/runtime qualification remains; 7–12 days |
| W10 | Open audio; W02/W04/W07 | **Initial code slice delivered:** OpenSubsonic/Subsonic catalog and stream adapter, RSS/Atom episode adapter, HTTPS OPML import/export, Music shelf, and local progress/offline integration. Continue server-version and audio-format qualification. | Existing source/player/progress/offline owners reused; private feed URL/credentials encrypted; OPML export disclosed and confirmed. Server-specific fixtures and device playback qualification remain. |
| W11 | Official music SDK pilot; W02/W04 | Official music title handoffs and OpenSubsonic/Subsonic files are available; no Apple Music/TIDAL/Qobuz/SoundCloud native subscription SDK is shipped | Actual SDK/auth/audio ownership on each enabled target; capability-specific controls; 10–20 days for one qualified provider family plus eligibility/access decisions |
| W12 | Reading/history integrations; W02/W09 | **Initial Hardcover slice delivered:** profile-scoped API token, encrypted read-only library snapshot with undo, exact ISBN matches to local source details, and confirmed status-only export with remote/local rechecks and undo | Main-library shelf projection, adding missing Hardcover entries, reading-position sync and optional Letterboxd export remain; protected text is never exported; 6–12 days total |
| W13 | Games/retailer extension; W05 | **Partial:** exact Steam AppID storefront routing for Steam games, with safe title-search fallback | GOG/Fanatical approved product feeds, offers, canonical activation-platform/edition mapping and regional key/DLC fixtures remain; 5–9 days |
| W14 | Devices/live/DRM research; W00 and relevant owners | Separate bounded spikes for HDHomeRun/TV server, Home Assistant control or LCP certified-reader feasibility | Written go/no-go, actual protocol/device evidence, costs and exact unsupported targets; 8–15 days per selected combined tranche; LCP implementation separately estimated |
| W15 | Release qualification and operator docs; selected packages | Cross-platform matrix, partner/policy decisions, licenses/attribution, recovery/rollback, evidence manifest | All enabled cells proven or disabled; owner review, private-JIT checks where appropriate; 5–10 days |

The first broad access/commerce/availability release is W00–W06 plus W15: **30–52 engineering days**, low confidence, excluding external approvals. A smaller release can stop after one merchant and external launch without enabling a paid availability backend. W07 can address existing-source reliability independently. W08–W14 are separate incremental product decisions, not prerequisites for useful handoff-only streaming support.

## Dependencies and release slices

```mermaid
flowchart TD
  W00["W00 baseline"] --> W01["W01 contracts"]
  W01 --> W02["W02 persistence"]
  W02 --> W03["W03 launch"]
  W03 --> W04["W04 access UI"]
  W04 --> W05["W05 book commerce"]
  W04 --> W06["W06 availability"]
  W05 --> W09["W09 queries"]
  W06 --> W09
  W09 --> W15["W15 qualification"]
  W04 --> W08["W08 approved lending"]
  W08 --> W15
```

The graph summarizes the main release path; the work-package table is authoritative for all dependencies. Partner research may proceed while implementation continues, but no approval is inferred from elapsed time.

## Implementation details by tranche

### W00–W02: avoid duplicate foundations

Current main has fixed `CatalogSourceId` and separate `SourceEntry` identities. Remote-stream planning already proposes dynamic catalog keys and account registries. Decide whether that work has landed before changing types. Add adapters/projections around existing values first; migrate persisted catalog selections only with backward readers and fixture coverage.

Use the existing profile provider/`SourceController` generation patterns and vault. Do not reuse server `ProfileConnectionRegistry` rows for unrelated merchant preferences. The registry must distinguish service definition, user-selected subscription, authenticated account and catalog installation. Store no tokens in `FileSource.options`, analytics or offer caches.

Initial fixtures must include one title with native and external access, a work with three different book formats, two conflicting ISBNs, a provider channel offer, a revoked account, stale price, unavailable handler and an unsupported protected file. These tests target integration boundaries, not trivial getters.

### W03–W06: first useful experience

Build the shared access-options query over existing local/server results plus fake external/merchant results. Add the compact section to the existing detail owners; use the existing adaptive source chooser if it can represent external actions without pretending they are playable copies. Otherwise add a small shared access sheet, keeping the native source picker intact.

Use approved official links with explicit per-platform fallback. Before adding production tracking, implement the action-policy evaluator from COMMERCIAL: the same offer can be visible as metadata yet not be permitted as a purchase action on a particular build/storefront. No QR or redirect bypass.

For the first merchant choose whichever of Libro.fm/Kobo/eBooks.com/Apple has actual property approval and usable data. If none is approved, complete neutral model/UI/fixture work and ordinary permitted official handoffs; record the missing approval instead of putting a fake affiliate ID into the app. Do not scrape store results to manufacture a catalog.

For availability, execute the proposed sample comparison and select one provider. The client-side adapter boundary is in `lib/integrations/availability_provider.dart`; it intentionally accepts no API-key field. Put confidential API credentials in the existing Go backend extension only after the provider, license and cache terms are approved. Do not require a backend for reading local files. Persist upstream attribution and cache deletion rules. Implement exact title links before enabling a provider badge on a title.

### W07–W08: libraries and owned books

Audiobookshelf now logs in through the current JWT endpoint when username/password are supplied, stores access and rotating refresh tokens through the encrypted profile vault, refreshes before expiry, and retries one unauthorized request after renewal. Existing bearer token/API-key credentials remain accepted. OPDS also carries checksum-validated ISBN-10/13 identifiers into book-detail storefront handoffs. Validate the response shape and refresh behavior against supported server versions and reverse proxies; keep source identities and reading/listening history intact.

Keep OPDS browse/acquisition separate from lending/auth. Only explicit `open-access` and `sample` relations enter the file path; generic acquisition, borrow, buy, subscribe and license links are excluded because their fulfillment may be protected or licensed. The sample relation is carried through cached source models and shown as a localized preview label. When one entry advertises several files, use the first recognized supported format for its shelf kind while retaining every file option. The source form offers the public Project Gutenberg OPDS endpoint as a preset. External fulfillment handoff is still a separate feature. Qualify content type, extension mismatch, redirect, expiry and duplicate-import behavior before release.

OverDrive uses the existing activation document. The required maintainer application is already described there; check its status rather than sending another request. Hoopla requires its own credentials and patron-auth contract. Reuse circulation UI structure only where semantics agree; do not reuse OverDrive token/scopes or make unsupported hold actions appear.

Palace/Cantook/cloudLibrary integrations require a concrete institution/vendor agreement. Implement one approved pilot before building a generic “all libraries” adapter. A library-authenticated OPDS feed can be useful without native DRM playback.

### W09–W13: broader connections

Generalize progressive search only after useful detail-level offers work. Keep provider leg errors isolated and cached local sources first. Cross-media relations belong in detail navigation, while exact-copy deduplication requires the correct edition/episode/game identity.

For OpenSubsonic, the initial adapter uses API-key or legacy MD5 auth, artist/album/search endpoints and the existing music session owner; qualify named server versions and formats before broad support claims. For podcasts, the initial RSS/Atom adapter uses feed-scoped GUID/enclosure identity, encrypted private feeds and explicit OPML import/export. Existing Audiobookshelf podcast support remains a separate route; do not duplicate its owner. Global Search federates every connected non-Seerr catalog with source chips and exact same-kind external-ID deduplication. Find Next uses the active Explore provider's bounded rows and one bounded row from each remaining connected provider; request failures/timeouts are isolated. A profile-confirmed catalog-to-server crosswalk suppresses that duplicate in Search and Find Next and can be removed from Settings → Services → Linked catalog titles. It relates the work only; progress, ownership and access stay separate.

For MusicKit or other SDKs, implement a single supported native platform first and prove audio focus and profile teardown before enabling more. A Flutter UI bridge is not a cross-platform audio engine. Spotify's mixed-service/commercial restrictions make it a business gate before implementation, not simply another adapter task.

Tracker imports begin with preview-only/read-only behavior. Optional writes use idempotency/conflict handling, clear consent and existing tracker queue concepts. Source-file progress remains authoritative for local resume; tracker status is a separate projection. Game offers use the existing grid/detail and never imply host installation.

### W14–W15: bounded experiments and release

Every spike ends with supported targets, implementation/deployment cost, unresolved questions and an explicit go/no-go. Do not leave a partially implemented protected-player toggle visible. LCP feasibility must cover certificate fees, certified binaries, secure license handling, offline expiry, format coverage and distribution compatibility before estimating a full reader integration.

Release only the exact provider/platform/channel cells with evidence. Preserve working noncommercial integrations even if affiliate approval is delayed. Record policy/source freshness, accessible focus/labels, native package hashes and a recovery route for revoked access or unavailable backend services.

## Owner and dependency ledger

| Decision | Owner | Safe work while pending | Blocks |
| --- | --- | --- | --- |
| Data supplier/license/budget | Product/business owner | Interfaces, fixtures, sample harness, neutral detail UI | Production availability API and licensed images |
| Merchant property approval | Business owner | Offer schema, policy evaluator, explicit imports and permitted untracked destinations | Tracking/commission-enabled links for that surface |
| OverDrive/Hoopla/library access | Business/institution owner | Gateway tests, auth/circulation fixtures, existing handoffs | Live native circulation and release flag |
| DRM/SDK certification | Business/platform owner | Isolated SDK feasibility, external fallback | Protected internal playback/offline support |
| Database/catalog coordination | Luna plus owner of active integration work | Read-only reconciliation and additive contract design | Conflicting schema/key changes |
| Device/storefront qualification | Platform owner | Automated fixtures and desktop tests | Claims for untested native targets and store releases |

No messages, applications, payments, deployments or agreements were sent/accepted by this assessment.

## Commit and PR discipline

Use coherent PRs for contracts/persistence, launch/UI, each merchant/feed, each lending adapter and each SDK. Explain user-visible behavior and evidence; do not call a fixture-only provider supported. Avoid broad format churn, dependency upgrades or unrelated player rewrites. Preserve `AGENTS.md` private-JIT policy. Use the repository's normal verification path for code changes and affected suites for follow-up work.

For an implementation PR, run meaningful affected tests, formatting, analyzer/localization and required repository checks under the current instructions. CI results must identify the exact tested SHA and private runner workflow. Missing capacity is a blocker, not permission to switch to hosted runners. Manual device results require model/OS/build, account/library sandbox and reproducer.

## Copyable handoff prompt

> Continue the PlezyNG integration roadmap in `docs/plezyng/service-integrations/IMPLEMENTATION.md`. Current code also includes shared typed integration contracts, profile-scoped service preferences and confirmed crosswalk storage; connected-catalog global Search; Hardcover shelf snapshot and guarded status sync; country-aware official storefront handoffs; and exact Steam AppID store links. Debrid/Stremio remains on `codex/debrid-stremio-integration-20261028`; do not duplicate its account/source stores. This PR does not add licensed streaming availability, merchant feeds/commission, Hoopla/Palace, native subscription-video clients, Apple Music SDK playback, or device-certified DRM. Read the audit, architecture, UX, commercial gates, source register and validation plan. Preserve existing native source/player/profile/design owners. Do not claim external playback, purchases, entitlements, affiliate commissions or partner approval from links or local fixtures. Keep blocked capabilities disabled, record missing evidence, and follow current `AGENTS.md` checks and private-JIT runner policy.


## Comic commerce runtime

The official comic destination directory and purchase handoff are implemented in lib/services/external_access_directory.dart and lib/screens/external_access_screen.dart. The screen optionally resolves a tracked URL only after the user taps a storefront. server/comic_commerce.go implements /commerce/comic-link, enforces provider host/path allowlists and a per-IP limit, keeps Awin/FlexOffers credentials server-side, and falls back to direct retailer URLs when any partner capability is unavailable. The purchase/rent policy remains deny-by-default for actual acquisition; this code opens the retailer.

The runtime includes configuration paths for DriveThruComics, Fanatical/Awin, Renta!/FlexOffers, eBooks.com and Bookshop.org ISBN affiliate links, Kobo/Rakuten deep links, optional Humble/FlexOffers, Gumroad Discover links, and creator-approved Gumroad product links. GlobalComix creator payouts and Comics Plus library access are official handoffs only; neither is presented as a PlezyNG sales commission. See the comic commerce setup document for deployment configuration and partner gates.
