# Comic storefront and revenue-share setup

Status: the handoff and link-broker code is implemented. Partner tracking is disabled until its agreement gate and provider credentials are configured.

## What ships

PlezyNG keeps comic reading and local file ownership in the existing source and reader owners. Title-specific storefront actions are embedded in the existing source-backed comic detail beside the local Read action: the highest-priority options appear inline and View All expands the remaining official destinations without leaving the detail. The generic full destination directory remains for other service categories. It does not take payment, assert that an issue is in stock, claim that a subscription covers an issue, proxy protected content, or mark an item purchased.

The POST endpoint at /commerce/comic-link is the server-side affiliate-link broker. It accepts only curated provider IDs and HTTPS destination shapes, including Fanatical game title search. It validates exact hosts, paths, and query keys, limits requests by source IP, applies CORS only for exact configured origins, sends no titles or credentials to logs, and returns a URL plus a tracked flag. It returns the direct official URL whenever an approval gate is closed or a network request fails. API tokens remain on the relay server.

The app calls the broker only after the user taps an eligible comic store or Fanatical game search. The title query and optional ISBN reach Plezy's relay at that moment. The destination URL is forwarded to Awin, FlexOffers, or Rakuten only when that network's link builder is used; Bookshop ISBN links are formed locally. Eligible rows disclose that PlezyNG may earn a commission. The final purchase, territory, age eligibility, price, and license period are controlled by the storefront.

## Provider setup

Every approval variable defaults to false. Set a gate to true only after approval for PlezyNG's actual app or website property and the current contract terms. Keep secrets in a deployment secret manager or an untracked .env file; never place partner keys in the Flutter app.

| Provider | Environment configuration | Behavior |
| --- | --- | --- |
| DriveThruComics | DRIVETHRU_COMICS_AFFILIATE_ID, DRIVETHRU_COMICS_AFFILIATE_APPROVED | Adds affiliate_id to its official browse URL. Affiliate status must be confirmed for the PlezyNG property. |
| Fanatical | AWIN_PUBLISHER_ID, AWIN_API_TOKEN, FANATICAL_AWIN_ADVERTISER_ID, FANATICAL_AWIN_APPROVED, FANATICAL_GAMES_AWIN_APPROVED | Calls Awin's official Link Builder API for the curated comic/book or game search URL. Comic/book and game surfaces have separate approval gates; the returned URL must use an approved Awin tracking host. |
| Renta! | FLEXOFFERS_API_KEY, optional FLEXOFFERS_API_KEY_HEADER and FLEXOFFERS_API_KEY_PREFIX, RENTA_FLEXOFFERS_ADVERTISER_ID, RENTA_FLEXOFFERS_APPROVED | Calls the FlexOffers deep-link API for an advertiser accepted by the account. Link creation failure falls back to the direct Renta! site. |
| eBooks.com | EBOOKS_COM_AFFILIATE_ID, EBOOKS_COM_AFFILIATE_APPROVED | Produces the published aff.asp AID and ISBN URL only for a checksum-valid ISBN. Without an ISBN it opens the normal search. |
| Bookshop.org | BOOKSHOP_AFFILIATE_ID, BOOKSHOP_AFFILIATE_APPROVED | Builds Bookshop's affiliate ISBN URL from the configured ID only when a valid ISBN is available (ISBN-10 is converted to ISBN-13). Otherwise the app opens the direct title search. No API key is required. |
| Kobo | KOBO_RAKUTEN_ADVERTISER_ID, KOBO_RAKUTEN_API_TOKEN, KOBO_RAKUTEN_APPROVED | Calls Rakuten's official deep-link API for the Kobo search URL. If Kobo declines deep linking or the request fails, the app opens the direct Kobo search. |
| Humble book bundles | FLEXOFFERS_API_KEY settings above, HUMBLE_FLEXOFFERS_ADVERTISER_ID, HUMBLE_FLEXOFFERS_APPROVED | Uses FlexOffers only if Humble appears as an approved advertiser in the account. No payout rate is embedded. |
| Gumroad | GUMROAD_DISCOVER_AFFILIATE_URL, GUMROAD_CREATOR_LINKS_JSON, GUMROAD_AFFILIATE_APPROVED | Uses the approved Discover affiliate URL and preserves the title query. Exact creator product URLs can be mapped by normalized title and creator after that creator approves PlezyNG. |

For GUMROAD_CREATOR_LINKS_JSON, use a JSON object whose key is the app's title plus creator search text (case and punctuation are normalized) and whose value is the exact affiliate URL generated for that product. The server accepts only HTTPS Gumroad product or affiliate paths, including creator subdomains. The app falls back to the official Discover search when a key is not mapped.

COMIC_COMMERCE_ALLOWED_ORIGINS is a comma-separated exact-origin list for Flutter Web. Native clients do not send an Origin header. Leave the list empty when the web client is not deployed. For local development, HTTP origins are allowed only for localhost, 127.0.0.1, or ::1 when explicitly listed.

## Revenue and access models

| Opportunity | PlezyNG path | Boundary |
| --- | --- | --- |
| Retailer affiliate commission | DriveThruComics, Fanatical/Awin (comic/book links and gated game searches), Renta!/FlexOffers, eBooks.com, Bookshop.org, Kobo/Rakuten, optional Humble/FlexOffers, optional Gumroad Discover | Merchant/network attribution applies only under the current account terms. PlezyNG does not independently report a sale. Game searches do not imply an offer, price, edition, region, or activation-key match. |
| Creator/publisher revenue share | GlobalComix publishing handoff | GlobalComix pays participating creators and publishers under its own publishing terms. This is not a PlezyNG referral fee. |
| Creator affiliate links | Gumroad | Use product or creator links only after that creator approves PlezyNG and issues the tracking link. |
| Institutional library access | Comics Plus / LibraryPass | School/library subscriptions and catalog APIs require an institutional relationship. The code includes no consumer referral checkout. |
| Subscription and reader handoffs | Marvel Unlimited, DC Universe Infinite, MANGA Plus, VIZ, Kindle Comics, WEBTOON | Plans, region rules, and issue coverage remain provider-owned. |
| Other booksellers | Kobo and Bookshop.org | Official search handoffs remain available; approved Kobo/Rakuten tracking and ISBN-based Bookshop affiliate links are optional. |

DriveThru's current partner FAQ describes a 15-day referral window and up to 5% affiliate credit, or up to 8% for community content or publishing partners, excluding gift certificates. It requires approved affiliate status and prohibits using a link to redirect traffic already bound for DriveThru.

Renta! says some titles offer a 48-hour rental or unlimited access, while publishers decide which choices are available for each title. Renta! terms require users to be at least 18. PlezyNG always hands off for the current issue-level offer and terms.

eBooks.com describes 45-day return tracking and an annual tier: 10% on the first US$100,000 in commissionable sales and 15% above that amount. The partner account and its current agreement control actual eligibility.

Bookshop.org's current non-bookstore affiliate materials describe a 10% standard commission, with enhanced rates available to qualified affiliates; the 30% bookstore rate is limited to qualifying ABA bookstores. Its official affiliate flow supports generated product links and ISBN-based links. Kobo offers a referral program, and Rakuten provides an approved-partner deep-link API; the account's current advertiser terms control commissions and link eligibility.

GlobalComix's published creator pages describe subscription and PDF sales revenue share, plus donations, paid to creators and publishers. Any percentages or requirements can change with their plan and contract; they are not an affiliate payout to PlezyNG.

## Deployment notes

Copy server/comic-commerce.env.example into the relay deployment's private environment and fill only the partner values whose approvals are complete. server/docker-compose.yml passes these variables through without storing values in Git. Store AWIN_API_TOKEN, FLEXOFFERS_API_KEY, and KOBO_RAKUTEN_API_TOKEN in a managed secret store in production.

The app defaults to Plezy's hosted relay at ice.plezy.app. Deploy the new server route there with the app release, or set the Flutter build define PLEZY_COMIC_COMMERCE_BASE_URL to the separate relay's base URL. Until the route is deployed, the client falls back to direct official storefront links.

Before enabling a provider, record the approved property, permitted distribution channels, territories, agreement version, and effective/expiry dates in the partner source record. Set the approval flag back to false to disable tracking. If a retailer or network changes its host or link format, the exact-host check fails closed and the screen continues to the official handoff.

## Remaining partner/API boundaries

- eBooks.com publishes a Book API, but this code does not claim a verified comic-specific catalog/availability schema. It supports the official ISBN affiliate URL; title search stays an official storefront handoff.
- Bookshop.org commission links are generated only for valid ISBNs. The provider owns the affiliate contract, attribution, and checkout.
- Comics Plus catalog access is available through a library relationship and LibraryPass approval. Its institutional credentials and catalog schema are not public in this repository.
- Gumroad does not provide one universal commission for all comic creators. Discover and creator/product links have separate approval and attribution rules.
- GlobalComix creator/publisher revenue is paid to the creator or publisher under GlobalComix terms, not to PlezyNG as a referral commission.
- Humble's current account-specific rates, restrictions, and advertiser availability are not hardcoded. Enable it only after the partner account confirms the approved FlexOffers advertiser and use.
- There is no retailer price scraping, DRM bypass, consumer account automation, in-app checkout, or automatic purchase-import behavior.

## Primary references

- DriveThru Partners, Affiliate Program FAQ: https://help.drivethrupartners.com/hc/en-us/articles/12780762767767-Affiliate-Program-FAQ
- Awin, Generate Tracking Link API: https://help.awin.com/apis/apidocs/generatelink
- FlexOffers, API endpoints and deep link response: https://www.flexoffers.com/new-features/api-endpoints-update/
- FlexOffers, Web Services API key instructions: https://supportbeta.flexoffers.com/knowledge/how-to-access-api-data-with-the-flexoffers-web-services-tool
- Renta!, How to choose a rental period: https://www.ebookrenta.com/renta/sc/frm/page/help/hajimete_en.htm
- Renta!, Terms of Service: https://www.ebookrenta.com/renta/sc/frm/page/help/condition.htm
- eBooks.com, Affiliate Program: https://www.ebooks.com/en-us/information/affiliates/
- eBooks.com, affiliate ISBN link format: https://about.ebooks.com/how-to-link-your-website-visitors-to-ebooks-com-for-ebook-sales-and-fulfilment/
- Bookshop.org, affiliate program: https://support.bookshop.org/en/support/solutions/articles/65000191390-can-you-explain-bookshop-org-s-affiliate-program-
- Bookshop.org, affiliate-link guide: https://support.bookshop.org/en/support/solutions/articles/65000189603-how-do-affiliate-links-widgets-work-on-bookshop-org-
- Bookshop.org, affiliate ISBN URL format: https://uk-assets.bookshop.org/bookshop_author_brochure.pdf
- Kobo, affiliate program: https://www.kobo.com/ca/en/p/influencers
- Rakuten Advertising, Deep Links API: https://developers.rakutenadvertising.com/guides/deep_link
- Gumroad, Becoming an affiliate: https://gumroad.com/help/article/249-affiliate-faq
- Gumroad, Discover eligibility and listings: https://gumroad.com/help/article/79-gumroad-discover
- GlobalComix, creator publishing and monetization: https://globalcomix.com/publish
- GlobalComix, creator revenue and payout FAQ: https://globalcomix.com/support/faq
- LibraryPass, Comics Plus catalog integrations: https://support.librarypass.com/portal/en/kb/articles/comics-plus-catalog-integrations
