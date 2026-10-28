# Validation and qualification plan

Status: planned runtime tests. This audit PR only validates its documentation and source references; it does not certify new service integrations. **High confidence:** the following boundary tests are necessary because failure can misstate access, leak profile data or dispatch unwanted provider actions.

## Functional acceptance matrix

| ID | Scenario | Required result | Packages |
| --- | --- | --- | --- |
| V01 | Same movie available from an existing server, cached file, Netflix and a rental store | Native Play stays native; external rows are explicit; no synthetic entitlement | W01/W04 |
| V02 | Selected Netflix/Disney subscription with no account API | Preference saved; no auth token, connected account or synced library claimed | W02/W04 |
| V03 | Store click, app launch succeeds, user cancels purchase and returns | No purchased/owned/read/watched state; focus restored to originating detail | W03/W05 |
| V04 | App handler missing, website unavailable or TV has no browser | Safe tested fallback or clear recovery; no loop, silent success or unsupported URI dispatch | W03 |
| V05 | Profile/account switches during auth, search, token refresh, circulation or SDK launch | Old work retired; no state/credentials/audio published into new owner | W02/all |
| V06 | Two instances of same provider with different accounts/library tenants | Distinct state, rates, secrets and provenance; no accidental cache reuse | W02/W08 |
| V07 | Duplicate title but different ISBN/format/narrator/abridgement | Separate editions and progress; optional reversible relationship | W01/W05/W09 |
| V08 | TMDB movie/show ID collision, anime season mapping, game DLC/base edition | Typed namespaces preserve identity; no wrong offer or playable target | W01/W09/W13 |
| V09 | Availability data says Prime channel, user only selects base Prime | Channel requirement remains visible; no “included for you” claim | W04/W06 |
| V10 | Canadian locale, US-only offer, foreign currency or stale price | Correct country/price labeling or exclusion; unknown is not free; no invented FX guarantee | W05/W06 |
| V11 | Partner API times out/429/returns invalid schema | Local results continue; bounded retry/backoff; partial error; stale data clearly labeled | W06/W09 |
| V12 | Supplier changes cache terms or access is revoked | Required cache purge/feature disable without deleting user-owned media | W02/W06/W15 |
| V13 | Native owned EPUB/MP3/M4B imported after official store download | Existing reader/audio flow and file-qualified resume; retained after store disconnect | W05/W07 |
| V14 | ACSM, LCP license, encrypted ebook or incorrectly labeled HTML download | No unrestricted native import; supported fulfillment or precise recovery | W05/W07/W08 |
| V15 | Kindle eligible purchased export versus borrowed KU title | Only actual exported compatible file is importable; no borrowed-export promise | W05 |
| V16 | OverDrive disabled build | Coming soon retained; no native auth/circulation requests; external Libby works where qualified | W08 |
| V17 | Borrow/hold request times out after server accepted it | Reconcile state; no duplicate mutation from retry/double tap | W08 |
| V18 | Hold ready/pickup, suspend/resume, return, expiry, revoked card, changed collection | Provider-advertised actions only; confirmed mutation; correct due state and reader destination | W08 |
| V19 | Audiobookshelf supported legacy and new auth flows, token expiry and server upgrade | Preserved source/history, single refresh or reconnect, no exposed credentials | W07 |
| V20 | OPDS XML/JSON feed: open access, sample, buy, borrow, subscription, license and comic stream | Correct relation/format classification; partial feed still safe; no invalid owned-file promotion | W07 |
| V21 | Private podcast feed or signed asset redirects to another origin | No credential leakage; private URL absent from telemetry/exports; only approved redirects | W10 |
| V22 | Official music SDK stops, loses entitlement, backgrounds or switches profile | One audio owner; truthful commands; proper teardown and progress source | W11 |
| V23 | External launch or preview returns without qualified media playback | No tracker scrobble, watched completion or fabricated progress | W03/W11/W12 |
| V24 | Import history or reading list twice, then conflicting remote edits | Preview, bounded idempotency, explicit conflict resolution and undo where supported | W12 |
| V25 | Game bought externally but no paired host installation | Store offer never enables Play; existing game/host route owns launch | W13 |
| V26 | Purchase action disallowed by merchant/platform/storefront | Action unavailable with appropriate product copy; no alternate QR/redirect bypass | W04/W05 |
| V27 | Affiliate link disabled/unapproved/refund/reversal | Ordinary permitted access still works; click not counted as sale; report deduplication | W05/W15 |
| V28 | Malicious URL, private-network redirect, oversized feed, archive traversal, invalid cover | Correct trust boundary, bounds and sanitized error; local NAS behavior remains intentionally supported | W03/W06/W07 |
| V29 | Screen reader, D-pad, RTL, large text, reduced motion and high contrast | Labels and focus correct; no clipped decisive price/action; no gesture-only control | W04/W15 |
| V30 | Offline with playable files and unavailable remote services | Existing files/resume remain available; no false offline entitlement or hidden local result | W02/W04/W15 |

## Existing regression owners

Locate current filenames before running: existing suites include source adapters/downloads/playback/screens/database migrations, lending service/gateway, search/relevance, catalog detail/provider, trackers, navigation/main screen, game library/auth and profile lifecycle. Reuse these owners instead of creating one enormous integration test file. Current paths can change after the inspected baseline.

For each new adapter, use synthetic/sanitized HTTP fixtures and injected clocks/transports. Network calls are not unit tests. Meaningful fault tests cover expiration, ambiguous IDs, missing fields, partial success, rotation and revoked access. Do not add tests that merely reproduce data declarations.

## Live qualification record

One record per enabled provider/capability/platform/channel, containing:

- Exact source commit, build/version, OS/device model and artifact hash.
- Provider environment/API version, territory, account class and enabled scopes; no credentials or personal library history.
- Reproducer steps and expected/observed outcome for setup, browse/search, action, return, expiry/revocation and disconnect.
- Auth/network/unsupported-content errors and recovery behavior.
- Evidence of official deep-link destination and permitted attribution; price/availability match sampling.
- Partner approval reference, terms/branding version and allowed distribution surfaces.
- Automated test names/results and private-JIT workflow/job URLs when run.
- Remaining gaps and per-capability release flags.

`implemented_unqualified` is a useful delivery state. Do not convert it to “supported everywhere” because Flutter compiles or an SDK is listed in pubspec.

## Platform matrix

| Target | Required qualification focus | Initial promise |
| --- | --- | --- |
| Linux desktop | Browser launch, default handler, Wayland/X11 focus restoration, file import, secure storage | External service handoff only where browser/service actually works; DRM quality not promised |
| Windows desktop | App/universal links, browser fallback, file import, process restart, secure storage | Same capability-specific behavior |
| macOS direct and Mac App Store | Treat distribution policies separately; MusicKit/audio owner if enabled | No assumption that direct-distribution commerce approval covers App Store |
| Android phone/tablet | App Links/browser, scoped file import, lifecycle, rotation, audio service, merchant attribution | Per-storefront/program purchase actions only |
| Android TV / Fire TV | D-pad, QR supported auth, actual app launch, absent-browser behavior; separate store channels | No automatic mobile parity |
| iOS/iPadOS | Universal links, Safari return, share/file import, keychain, background audio, storefront policy | Protected playback through approved SDK only |
| tvOS | Focus and supported auth/app links; storage constraints; no inherited Downloads button | External/native/SDK actions individually qualified |
| webOS / Tizen | Existing experimental port status, browser/app-launch APIs, secure storage, platform distribution | Disabled new provider capabilities until native evidence |

No browser build is assumed. A provider's web player can be opened externally without claiming a PlezyNG web application or embedding it internally.

## Suggested measurable pilot criteria

These are **proposed acceptance targets**, not measurements:

- No wrong-title/edition native launch or merchant purchase route in the reviewed sample.
- Every live offer shows correct provider/channel, country and format; stale/unknown prices do not appear current.
- Local search and existing playback remain usable during total gateway failure.
- Remote response budgets are recorded, including requests/credits per detail and peak concurrency; loading one detail cannot trigger a full-provider crawl.
- All supported external launches return a usable PlezyNG detail/focus state; no external action fabricates completion.
- Profile switch/revocation tests show zero cross-profile publication or credential reuse.
- Provider/API outage and license revocation can be disabled independently without a client-wide outage.

The availability bake-off sample is specified in PROVIDERS. Publish observed results and failures instead of a subjective “works well.”

## Rollout and rollback

Start disabled behind provider/capability/distribution flags. Enable an internal pilot for one approved territory and target, then expand only tested cells. Keep stable local features unaffected by remote policy changes. Rollback disables the provider action/feed, retires in-flight operations and follows data-license deletion rules; it preserves owned downloads, annotations and existing server connections.

This assessment must not trigger CI, enroll partner accounts or deploy a gateway. Runtime implementation PRs use the current required checks and private ephemeral JIT policy. Manual releases remain separate owner actions.

## Validation performed for this planning PR

The final PR description records the actual documentation checks run. Planned runtime test cases above are not executed claims. No Flutter/native build, live paid-service login, partner sandbox circulation or storefront conversion was performed for this audit.
