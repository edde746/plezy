# Commercial options, affiliate revenue and distribution

**Recommendation — moderate confidence:** start with merchants that fit existing reading/listening/game flows and have documented programs, then measure approved net commissions. Prefer a useful discovery and import experience to an affiliate-store redesign. Revenue potential is **unknown** without active users, regional mix, click-throughs, conversions, accepted terms and reversals.

All public terms below were reviewed for this audit on 2026-10-27. They are observations, not an accepted PlezyNG offer. Store the actual signed/network terms, effective dates and approved promotional properties before production.

## Affiliate shortlist

| Partner | Verified public commercial route | Published economics observed | PlezyNG action / gate |
| --- | --- | --- | --- |
| Libro.fm | Affiliate program; title/membership/gift/credit links. [S21](SOURCES.md#s21) | Official help lists 10% on audiobooks/credit bundles and 30% one-time on new monthly membership; 30-day attribution. | First application candidate. Ask explicitly about native desktop/mobile/TV links, product feeds, app-to-app attribution and Canadian payout currency. Strong DRM-free import fit. |
| Kobo | Affiliate program through Rakuten; approved product links/catalog access. [S14](SOURCES.md#s14) | Canadian standard page says up to 5% on ebooks/audiobooks/devices, up to 10% accessories, 14-day tracking. Separate influencer page advertises different 10% terms. | Do not use the influencer rate as the default forecast. Obtain the exact accepted app/channel offer and territory rules. |
| Apple Performance Partners | Links from websites/apps to eligible Apple services. [S22](SOURCES.md#s22) | Current standard page lists 7% sales revenue for Books and TV/Movies, 30-day window; eligible memberships have one-time payments without a universal amount. | Good book/rental/subscription breadth. Confirm country, device attribution, product class, current rate and placement; comply separately with App Store purchase-link rules. |
| eBooks.com | Standard affiliate and negotiated premium program. [S28](SOURCES.md#s28) | Public standard page advertises 45-day tracking and commission but no single accepted PlezyNG rate. | Request ISBN feed, mobile/desktop approval, digital fulfillment classifications and negotiated rate. A useful business-development priority. |
| Bookshop.org | Non-bookstore affiliate program; ebook revenue sharing. [S27](SOURCES.md#s27) | Public non-bookstore materials advertise 10%; ebook-specific page confirms 10% list price for that class. | Confirm eligible country, currency, ebook coverage and app/channel approval. Do not assume Canadian access or bookstore-level commission. |
| Indigo | Current Sovrn merchant listing is an intermediary lead; CJ/merchant verification remains needed. [S19](SOURCES.md#s19) | Accepted rate, cookie window, feed and native-app permissions are unknown. | High Canadian relevance. Verify the advertiser directly/in the network; negotiate ISBN/condition/format feed and clarify Kobo ebook attribution so the same sale is not double counted. |
| Amazon Associates / Kindle / Audible / eligible Prime offers | Associates with product or bounty rules; Creators API is current catalog successor. [S16](SOURCES.md#s16), [S17](SOURCES.md#s17), [S30](SOURCES.md#s30) | Category, locale, product, bounty and traffic-source rules vary; no universal percentage. | Do not enable standard desktop/TV affiliate links. Mobile needs explicit approval and qualifying app distribution. Obtain terms for each intended surface before implementation. |
| Barnes & Noble | First-party page currently directs affiliates to Impact. [S29](SOURCES.md#s29) | No rate accepted/verified for PlezyNG. | US print/NOOK expansion. Prefer current first-party onboarding over old CJ blog instructions. |
| GOG | Official affiliate program and product-feed API. [S51](SOURCES.md#s51) | Public page advertises 6% of net sales and seven-day last-click tracking. | Natural fit for Games detail; confirm native app/channel eligibility and product region. No ownership API implied. |
| Fanatical | Official affiliate program; current landing page points to Awin. [S52](SOURCES.md#s52) | No universal rate verified. Older FAQ points to CJ/Tapfiliate, so accepted current terms must resolve the difference. | Feed/key-store integration after approval; model Steam/GOG/other activation platform and region. |
| Humble, Green Man Gaming, Audiobooks.com, Chirp, Downpour, specialty retailers, subscription-video partners | Commercial leads to investigate. | Unknown in this audit; third-party affiliate directories are insufficient to publish a rate. | Ask for the exact program, feed, app permissions, products and payout; keep ordinary permitted handoffs useful without commission. |

**High confidence:** a payout program does not grant playback, user-library access, synchronization, private metadata, artwork redistribution or general DRM rights.

## FAST services: distribution deals are not referral commissions

The video directory exposes official handoffs for Tubi, Pluto TV, The Roku Channel, Plex, Samsung TV Plus and Xumo Play. These are useful to users without a PlezyNG affiliate deal. Their published partner routes are primarily for content owners, publishers, distributors or advertisers—not a general commission on a link from PlezyNG to the viewing app.

| Service | Public partner/revenue route | What it means for PlezyNG |
| --- | --- | --- |
| Roku / The Roku Channel | Roku documents partner payouts for accepted publishers and content partners, including monetization through ads, subscriptions and Roku Pay. Its published 80/20 split applies to qualifying app transactions through Roku Pay; The Roku Channel content payouts follow a separate distribution agreement/reporting path. [S70](SOURCES.md#s70) | Strongest published revenue-sharing route in this group **if PlezyNG or its content is accepted for Roku distribution**. It does not pay us merely for directing a user to The Roku Channel. The TV app itself would be a separate Roku platform build and approval. |
| Tubi | Official partner intake and content/distribution relationships; advertising is sold to brands. [S68](SOURCES.md#s68) | Partner access may support licensed content distribution or advertising; no public fixed referral commission or split for a third-party app link was found. Ask for a written PlezyNG app, content and distribution proposal. |
| Pluto TV | Official distribution, content and advertising partner inquiries. [S69](SOURCES.md#s69) | A negotiated content/distribution/ad deal may include economics, but no public payout schedule for app referrals is published. No unofficial streams or private APIs. |
| Samsung TV Plus | Official advertising opportunities and device-bound service distribution. [S71](SOURCES.md#s71) | The public route is primarily advertising and content partnership; no public viewer-referral commission is listed. Device/platform qualification is central. |
| Xumo Play | Xumo Enterprise invites content owners, distribution services and advertisers to use its FAST monetization and distribution systems. [S72](SOURCES.md#s72) | Business-development route, not a posted affiliate percentage. Request the content/distribution terms and the required player/ad integration before estimating revenue. |
| Plex free streaming | Plex has ad sales and content partners; its consumer terms do not create a general right to share Plex revenue. [S73](SOURCES.md#s73) | No public outbound-referral commission or client playback API was verified. Keep the official handoff; ask Plex for an explicit agreement if a deeper integration is pursued. |

**Recommendation:** treat Roku as the first revenue-sharing inquiry because payout mechanics are publicly documented, but pitch PlezyNG as a publisher/platform or content partner only if that is genuinely the proposed product. For a neutral guide linking viewers to services, count **zero** commission until a provider signs written referral terms for PlezyNG's exact app/storefront. Content revenue share, ad-inventory share, subscription billing share and affiliate referrals are different contracts.

## Amazon is a special gating case

Current Associates policies restrict Special Links/Program Content in client software other than approved mobile apps, and restrict television/set-top devices. The relevant clause also uses broader linking language, so an untagged link or redirect must not be treated as an automatic workaround inside an Associates integration. [S17](SOURCES.md#s17)

Therefore:

- Keep desktop/TV Amazon commerce disabled unless an explicit written arrangement covers it.
- Mobile eligibility and app-store availability do not automatically grant acceptance; register the exact app/properties and obtain approval.
- Do not render Amazon shopping pages in a WebView or reproduce its shopping app.
- Use Creators API rather than new PA-API 5 code. Keep confidential credentials on the backend; catalog access requires eligible Associates status. [S16](SOURCES.md#s16)
- Evaluate ordinary Prime/Kindle official-service handoffs separately from the commerce program; record the exact applicable permission instead of silently mixing them.

This is a concrete product constraint, not a reason to block independent file import, library work or other stores.

## Platform and storefront policy matrix

Do not encode one global `allowExternalPurchases` boolean. Evaluate OS, app distribution, store storefront, country, merchant program, product type, permission/entitlement and policy version.

| Distribution | Initial implementation policy | Required production evidence |
| --- | --- | --- |
| Linux/Windows/macOS direct distribution | External merchant checkout can be implemented where merchant terms permit it. | Per-merchant software eligibility; Amazon requires its specific exception/arrangement. No assumption that desktop is universally unrestricted. |
| Apple App Store: iOS/iPadOS/tvOS/macOS | Consumption and official service launch separate from purchase steering. Enable commercial links only for an applicable storefront rule/entitlement/program. | Current Apple guideline review for the exact app and storefront. US exceptions cannot be applied globally. A reader account-link entitlement is not blanket permission to link to arbitrary third-party stores. [S24](SOURCES.md#s24) |
| Google Play Android/mobile/TV | Same separation; use current country/program-specific payment/external-content policy. | Required enrollment, disclosures, APIs/reporting/fees and app review as applicable. US/EEA arrangements are not Canadian defaults. [S25](SOURCES.md#s25) |
| Android outside Google Play / other app stores | Merchant and distribution-store rules still apply. | Verify the store/channel, billing rules and affiliate property approval. Do not reuse Google Play approval blindly. |
| webOS / Tizen / other TV distribution | Handoff and commerce disabled until platform actions and store rules are qualified. | Actual app-launch/companion behavior, supported browser path and channel approval. |
| Optional companion website | A separate approved promotional property with its own commerce flow. | A link/QR from a restricted app is still evaluated as steering; a website is not a bypass. No new site is created by this PR. |

Country selection supports catalog relevance; it is not proof of legal storefront or account region. Use official storefront/account information when required and avoid covert IP-based policy decisions. Physical book purchases and digital unlocks may follow different rules; keep product type explicit.

## Feed and attribution implementation

Use accepted merchant catalogs or affiliate network APIs, not HTML price scraping. Rakuten provides product search/deep links; CJ provides link and product-feed APIs; Awin offers product feeds. A network account does not approve every advertiser. [S55](SOURCES.md#s55)

Normalize merchant product ID, ISBN/EAN/ASIN where authorized, format, region, price/currency, availability, canonical destination, tracking destination, attribution/license and observation timestamp. Keep source provenance on every field. A vendor logo feed is not automatically an artwork redistribution license.

Link generation occurs only for an approved merchant/product/channel/region. Use deterministic campaign/sub-ID mappings without profile IDs, library-card numbers, emails or reading-history data. Do not replace another person's affiliate tags on user-supplied links. Do not cloak destinations; the UI names the merchant and uses only approved network redirects. Preserve app-to-web fallback without losing permitted attribution, and test actual attribution in partner sandbox/reporting.

Track **eligible impression → deliberate outbound click → reported conversion → approved commission → paid commission** as separate states. Order attribution, cookie loss, app switching, cancellations and returns make clicks a poor sales proxy. If a signed postback/report API exists, deduplicate its transaction IDs and verify origin; otherwise import official reports. Client callbacks cannot confirm an order.

Keep paid and free options in one neutral comparison. Offer ranking uses access, edition match, user preference and price; commission is not an input. Paid placement, if ever introduced, is a separate explicit product decision and must not masquerade as the best available copy.

## Costs and economic decision rule

Known public benchmark: Watchmode currently lists Startup at **US$349/month for 40,000 credits**, Business at **US$599/month for 100,000 credits**; its free developer plan is noncommercial. Credits are not necessarily one user action or one title. JustWatch requires a quote; alternate suppliers and caching terms require review. [S31](SOURCES.md#s31)

Other cost centers: backend hosting/observability, authorized product-feed access, native SDK support, provider approvals, device tests and licensed DRM. Readium LCP involves annual certification fees; use the actual organization quote instead of assuming open-source code is cost free. [S12](SOURCES.md#s12)

Use this model, **high confidence in arithmetic, unknown inputs**:

`net contribution = approved commissions + approved bounties - reversals - data/API charges - hosting - attributable support costs`

Illustration only: an approved sale paying US$2 net commission requires 175 such sales to cover a US$349 monthly data bill, before other costs. This is not a predicted conversion rate or a claim that movie availability costs will be funded by book commissions. Choose the data supplier on measured user value and licensed coverage, then compare actual contribution.

Do not commit to annual data/DRM contracts before a limited pilot establishes match quality, reliable launch destinations and useful engagement. User value from free library access is a valid outcome even where direct commission is zero.

## Concrete partner-request packets

These are prepared requirements, not messages sent or applications submitted. Product owner/business owner supplies company/contact details and approves any commercial commitment.

| Partner group | Include in the request | Answers needed to unblock Luna |
| --- | --- | --- |
| Kobo, Libro.fm, Indigo, eBooks.com, Apple, Bookshop | PlezyNG repo/site, screenshots of existing book/audio detail and proposed access rows, supported platforms, CA-first geography, optional other markets, expected traffic marked unknown, external checkout and no credential scraping | Approved native/web/TV properties; product feed/API; edition identifiers; artwork/price cache terms; exact commissions/exclusions; app-link attribution; sandbox/reporting; permitted user download/import guidance |
| Amazon/Audible | Same product packet plus explicit desktop/TV/mobile distribution list and the proposed read/launch/commerce separation | Written exceptions if offered; approved mobile property; marketplace/Creators eligibility; allowed product categories/bounties; placement/linking restrictions |
| JustWatch/Watchmode/Movie of the Night | Region/title/episode/sample matrix, request budget, caching architecture, private profile data excluded, proposed attribution | CA/French coverage; direct title/app links; channel/tier distinctions; commercial license; cache expiry/deletion; affiliate link compatibility; SLA/changes; total quote |
| OverDrive | Existing application status and gateway design, library IDs, intended Discovery/Circulation scopes, QR support and sandbox tests | Approved credentials/environment; actual callback/scopes; authorized libraries; branding; fulfillment; production sign-off |
| Hoopla/Palace/cloudLibrary/Cantook | Institution/vendor model, supported patron-auth surface, required catalog/loan/hold/return functions and no protected-stream extraction | Eligibility; staging; API versions; auth; per-library scope; limits; licensed fulfillment; certification and production approval |
| Apple Music/TIDAL/Qobuz/SoundCloud/Spotify/Amazon Music | Multi-service product description, explicit SDK/player boundaries, platform list, commercial model and intended queue behavior | Whether this product is eligible; commercial/native playback approval; full-track entitlement; supported platforms; SDK/DRM rules; mixed-content/queue restrictions; certification |

Record each answer in a provider decision record with date, owner, contract reference, approved capabilities and outstanding conditions. Continue independent implementation while partner requests are pending; do not simulate their approval.
