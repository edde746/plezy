# Source register and evidence limits

Reviewed **2026-10-28 (America/Regina)** using current web retrieval, official provider documentation and the repository snapshots identified in AUDIT. Prices, terms, APIs, branding and service availability require rechecking immediately before implementation/release. A crawl or page update date is not proof that PlezyNG has been accepted into a program.

**High confidence** means a cited primary source directly documents the narrow capability or condition. **Moderate** describes a reasoned integration recommendation or incomplete operational evidence. **Low** describes speculative readiness/effort. **Unknown** means no qualifying evidence or approval was obtained. No provider was contacted or enrolled, and no live API credential was exercised.

Searches used official developer/help/commercial sources for technical claims. The wider market candidate rows are triage, not a claim of individual API availability. Negative findings are phrased as “no supported public route established,” because public documentation cannot rule out a private partnership. Service names and regional catalogs should be supplied by current licensed data, not frozen from this document.

## S01

Netflix: [supported browsers and system requirements](https://help.netflix.com/en/node/30081), [unsupported browser guidance](https://help.netflix.com/en/node/2090). Establishes official browser destinations and platform variation, including limited Linux assurances; does not establish a third-party playback SDK. High for the documented route; unknown partnership eligibility.

## S02

Prime Video: [Prime Video APIs](https://videocentral.amazon.com/support/prime-video-apis?language=en_US), [API onboarding](https://videocentral.amazon.com/support/api-onboarding?language=en_US). These cover managed content-partner supply/analytics workflows, not a general consumer library/player API. High.

## S03

Disney+: [supported devices](https://help.disneyplus.com/in/article/disneyplus-devices-supported), [computer/browser requirements](https://help.disneyplus.com/pl/article/disneyplus-computer-browser-requirements). Official supported-client route; not permission to build a replacement client. Country-specific help pages must not be treated as a global device guarantee. High source facts; moderate cross-platform inference.

## S04

Google: [Widevine overview](https://developers.google.com/widevine/drm/overview), [Chromium CDM license](https://chromium.googlesource.com/chromium/src/third_party/%2B/master/widevine/LICENSE). Establishes licensing and proprietary-CDM boundaries. DRM technology access and a service's subscriber/content authorization are separate. High facts; architecture recommendation is an inference.

## S05

JustWatch: [content partner integrations](https://apis.justwatch.com/docs/content_partner/), [partner API](https://apis.justwatch.com/docs/api/), [partnerships](https://partners.justwatch.com/), [data export](https://apis.justwatch.com/docs/data_export/). Supported contracted availability-data route; quote, rights and coverage for PlezyNG unknown. High API existence.

## S06

TMDB: [TV watch providers](https://developer.themoviedb.org/reference/tv-series-watch-providers), [FAQ/licensing](https://developer.themoviedb.org/docs/faq). Country/provider availability, required JustWatch attribution, lack of full service deep links and commercial-license distinction. High.

## S07

OverDrive: [application process](https://developer.overdrive.com/getting-started/application-process), [API overview](https://developer.overdrive.com/getting-started/api-overview), [circulation](https://developer.overdrive.com/api-docs/circulation-apis), [integration environment](https://developer.overdrive.com/getting-started/integration-library), [authentication](https://developer.overdrive.com/api-docs/authentication). Establishes separate approvals/environments and discovery/circulation capabilities. Existing repo gateway behavior is code evidence, not provider approval. High.

## S08

Hoopla: [developer access](https://developer.hoopladigital.com/dev-access), [patron endpoints](https://developer.hoopladigital.com/endpoints/patrons), [search](https://developer.hoopladigital.com/endpoints/search), [current partner API/testing guidance](https://developer.hoopladigital.com/api-use-guidelines). Documents search/entitlements/patron circulation and staging access. Old examples may show HTTP; production transport and current OpenAPI must be verified. High API existence; unknown PlezyNG eligibility.

## S09

Palace: [official FAQ](https://thepalaceproject.org/faq/), [web-patron](https://github.com/ThePalaceProject/web-patron), [circulation manager](https://github.com/ThePalaceProject/circulation). OPDS/library architecture and borrowing/download UI are documented; upstream content access still depends on contracts. High.

## S10

OCLC: [cloudLibrary integration](https://help.wise.oclc.org/OPAC/Configuration/OPAC_integrations/CloudLibrary_integration), [WorldCat Discovery API](https://www.oclc.org/developer/api/oclc-apis/worldcat-discovery-api.en.html), [API catalog](https://www.oclc.org/developer/api/oclc-apis.en.html). Shows institution/vendor integration and subscription requirements; not open credentials for every consumer app. High.

## S11

PRETNUMERIQUE: [member-library API guide](https://reseaubibliocnca.pretnumerique.ca/docs/api?l=en), [authentication/general concepts](https://reseaubibliobsl.pretnumerique.ca/docs/api/general?l=en), [Bibliopresto service description](https://www.bibliopresto.ca/pretnumerique.php). Institutional APIs/SSO and service scope. High; current production contract needed.

## S12

Readium/EDRLab: [LCP FAQ and fees](https://www.edrlab.org/readium-lcp/faq/), [reading-system certification steps](https://www.edrlab.org/readium-lcp/how-to-lcp-reading-system-provider/), [specifications](https://readium.org/lcp-specs/), [certified apps](https://www.edrlab.org/readium-lcp/certified-apps-servers/). A dedicated certified reader path with annual fees, not generic browser EPUB decryption. High.

## S13

Kobo: [export purchased books](https://help.kobo.com/hc/en-us/articles/360019527954-Download-books-from-your-Kobo-account-to-export-to-another-device-or-app), [Adobe Digital Editions fulfillment](https://help.kobo.com/hc/en-us/articles/360017814074-Add-eBooks-with-Adobe-Digital-Editions). Distinguishes DRM-free exports from protected fulfillment. The latter page also reflects evolving ADE identity-provider instructions; avoid hardcoded old sign-in help. High.

## S14

Kobo: [Canadian standard affiliate page](https://www.kobo.com/ca/en/p/affiliate), [Canadian influencer page](https://www.kobo.com/ca/en/p/influencers), [official onboarding explanation](https://www.kobo.com/kobo-writing-life/blog/join-kobos-affiliate-program?noamp=mobile). Standard and influencer offers differ; actual accepted terms control. High published observations; PlezyNG rate/eligibility unknown.

## S15

Amazon KDP: [Digital Rights Management](https://kdp.amazon.com/en_US/help/topic/GDDXGH9VR22ACM8U). Eligible confirmed DRM-free verified purchases have EPUB/PDF downloads from Jan 20, 2026; this is not a general protected-Kindle or borrowed-title export API. High.

## S16

Amazon: [Creators API introduction](https://affiliate-program.amazon.com/creatorsapi/docs/), [locale reference](https://affiliate-program.amazon.com/creatorsapi/docs/en-us/locale-reference), [registration eligibility](https://affiliate-program.amazon.com/creatorsapi/docs/en-us/onboarding/register-for-creators-api), [PA-API 5 deprecation](https://affiliate-program.amazon.com/creatorsapi/docs/en-us/paapiv5-deprecation), [migration/auth changes](https://affiliate-program.amazon.com/creatorsapi/docs/en-us/migrating-to-creatorsapi-from-paapi). The locale reference supports marketplace-aware routing for official searches; catalog API use still requires eligibility. High.

## S17

Amazon: [US Associates program policies](https://affiliate-program.amazon.com/help/operating/policies?ac-ms-src=ac-nav), [Canadian policies](https://associates.amazon.ca/help/operating/policies?ac-ms-src=ac-nav), [mobile application policy](https://affiliate-program.amazon.com/help/node/topic/GHBY6W8UPTEFD3ZX), [mobile links approval](https://affiliate-program.amazon.com/help/node/topic/GQZMCDD9PB7CXV7N). Explicit software/TV restrictions and mobile approval conditions; accepted marketplace/property terms must be recorded. High.

## S18

Indigo: [ebooks help](https://help.indigo.ca/app/answers/detail/a_id/256/kw/redeem%20on%20ebooks/related/1), [an ebook listing showing Kobo fulfillment](https://www.indigo.ca/products/start-and-market-your-affiliate-program-successfully). Establishes seller/fulfillment separation; the sample product's book subject is irrelevant to the integration recommendation. High.

## S19

Sovrn/VigLink: [Indigo merchant listing](https://www.viglink.com/merchants/4926/indigo-books-and-music-affiliate-program). CJ: [publisher support and advertiser discovery](https://www.cj.com/support). First-party network/intermediary evidence of a commercial lead, not an accepted Indigo contract or rate. Moderate; direct/current advertiser verification pending. Unverified affiliate-directory rate claims were excluded.

## S20

Libro.fm: [download MP3/M4B files](https://support.libro.fm/support/solutions/articles/48000695426-how-do-i-download-audiobook-files-to-listen-on-my-computer-), [multiple-device/DRM-free explanation](https://support.libro.fm/support/solutions/articles/48000695425-can-i-listen-to-my-audiobooks-on-multiple-devices-). Supports user-directed file import. Does not establish an automatic consumer-library API. High.

## S21

Libro.fm: [affiliate program](https://support.libro.fm/support/solutions/articles/48001200043-what-is-the-libro-fm-affiliate-program-), [commission help](https://support.libro.fm/support/solutions/articles/48001200239-how-much-do-libro-fm-affiliates-earn-), [product links](https://support.libro.fm/support/solutions/articles/48001200334-as-an-affiliate-can-i-link-to-specific-products-). Published terms support evaluation; app/channel acceptance still required. High observations.

## S22

Apple: [working with Apple Services](https://www.apple.com/ca/working-with-apple-services/), [Performance Partners commissions](https://performance-partners.apple.com/commissions-payments), [Books affiliate explanation](https://authors.apple.com/support/3977-apple-affiliate-program-books-audiobooks). Affiliate opportunity distinct from app-store payment permissions and playback rights. High.

## S23

Apple: [Search API](https://performance-partners.apple.com/search-api), [archived Search API overview](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/). Catalog lookup and promotional-content conditions; no consumer purchased-library API established. Prefer the current Performance Partners page where old terminology differs. High documented scope.

## S24

Apple: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [reader-app account-link entitlement](https://developer.apple.com/support/reader-apps). Storefront and entitlement-specific purchase/account-link rules; not a blanket third-party-store exception. High current-source basis; applicability to a final app needs review.

## S25

Google: [Payments policy explanation](https://support.google.com/googleplay/android-developer/answer/10281818?hl=en-CA-3), [Developer Program Policy](https://support.google.com/googleplay/android-developer/answer/18258653), [US external-content/billing policy updates](https://support.google.com/googleplay/android-developer/answer/15582165?hl=en-CA-3). Region/program conditions are time-sensitive. High; recheck immediately before release.

## S26

Google Books: [getting started](https://developers.google.com/books/docs/v1/getting_started), [using the API](https://developers.google.com/books/docs/v1/using). Public catalog and authorized personal-shelf operations; content access depends on supplied access/format information and rights. High documented API; no general protected-book client conclusion.

## S27

Bookshop: [affiliate introduction](https://bookshop.org/affiliates/profile/introduction), [ebook revenue sharing](https://support.bookshop.org/en/support/solutions/articles/65000189188-how-does-the-shared-revenue-program-work-for-ebooks-), [reader/device and DRM-free exceptions](https://support.bookshop.org/en/support/solutions/articles/65000189169-can-i-read-my-ebooks-on-my-kindle-kobo-or-nook-etc-). High; regional/app eligibility not established.

## S28

eBooks.com: [affiliate program](https://www.ebooks.com/en-us/information/affiliates/), [premium affiliate program](https://about.ebooks.com/ebooks-coms-premium-affiliate-program/). Official referral/fulfillment route; premium article is older and must be reconfirmed. High program existence, moderate current negotiated applicability.

## S29

Barnes & Noble: [current affiliate terms/onboarding](https://www.barnesandnoble.com/terms/affiliates). Current first-party page points to Impact. High; older secondary CJ instructions were not used as the implementation source.

## S30

Audible: [affiliate program](https://www.audible.com/ep/affiliates), [Associates explanation](https://www.audible.com/ep/affiliate-intro?language=%2Fep%2Fpodcast-intro%3Flanguage%3Den_US). Country/product-specific referral route, not a public playback contract. High program existence; accepted local payout unknown.

## S31

Watchmode: [API overview](https://api.watchmode.com/), [pricing](https://api.watchmode.com/pricing). Availability/links rather than video; commercial tiers, credits and plan differences. High published facts; no sample coverage test was run.

## S32

Movie of the Night: [documentation](https://docs.movieofthenight.com/), [authentication](https://docs.movieofthenight.com/guide/authentication), [show queries](https://docs.movieofthenight.com/guide/shows), [official OpenAPI](https://github.com/movieofthenight/streaming-availability-api/blob/main/openapi.yaml), [terms](https://github.com/movieofthenight/streaming-availability-api/blob/main/TERMS.md). Country offers, prices/links and commercial attribution route. Docs/README country counts differ; do not hardcode them. High interface, unknown tested coverage.

## S33

Spotify: [developer policy](https://developer.spotify.com/policy), [Web Playback SDK](https://developer.spotify.com/documentation/web-playback-sdk), [2026 developer-access update](https://developer.spotify.com/blog/2026-02-06-update-on-developer-access-and-platform-security). Commercial SDK approval, multi-service restrictions and limited development access make this a gated workstream. High.

## S34

Apple: [MusicKit](https://developer.apple.com/musickit/), [user authentication](https://developer.apple.com/documentation/applemusicapi/user-authentication-for-musickit?changes=_2). Supported catalog/account/playback SDKs differ by platform. High SDK existence; actual Flutter bridge/device quality untested.

## S35

TIDAL: [developer guidelines](https://developer.tidal.com/documentation/guidelines/guidelines-developer-guidelines), [official iOS Player module](https://github.com/tidal-music/tidal-sdk-ios/blob/main/Sources/Player/README.md), [Android Player docs](https://tidal-music.github.io/tidal-sdk-android/player/index.html). Official Player requirement; public preview examples do not establish PlezyNG full-track/commercial approval. High requirement, moderate current access details because some SDK documentation is older.

## S36

Amazon Music: [Web API V2 overview](https://www.developer.amazon.com/zh/docs/music/API_web_overview_v2.html), [authentication](https://www.developer.amazon.com/zh/docs/music/API_web_LWA.html), [playback sessions](https://www.developer.amazon.com/docs/music/API_playback_sessions.html), [program requirements](https://www.developer.amazon.com/docs/music/requ_AM-Program-Requirements.html). Published account/playback APIs are closed-beta/approval and certification dependent. High.

## S37

SoundCloud: [API guide](https://developers.soundcloud.com/docs/api/guide?trk=article-ssr-frontend-pulse_little-text-block), [app registration](https://developers.soundcloud.com/docs/api/register-app.html). Current auth/PKCE and registration requirements; verify app eligibility and per-track playback rights. High documentation, no enrolled app.

## S38

Qobuz: [partnerships](https://www.qobuz.com/gb-en/page/annonceurs-partenariats), [API terms](https://static.qobuz.com/apps/api/QobuzAPI-TermsofUse.pdf). Own approved app credentials/device rights required. High route; unknown acceptance/current commercial quote.

## S39

YouTube: [IFrame API](https://developers.google.com/youtube/iframe_api_reference), [required minimum functionality](https://developers.google.com/youtube/terms/required-minimum-functionality), [player parameters](https://developers.google.com/youtube/player_parameters). Official embedded-player path with identity, viewport and controls constraints. High.

## S40

Vimeo: [Player SDK](https://developer.vimeo.com/player/sdk), [embed options](https://developer.vimeo.com/player/sdk/embed). SDK controls an authorized embed and is separate from the account API/OTT entitlement product. High.

## S41

Twitch: [video and clips embeds](https://dev.twitch.tv/docs/embed/video-and-clips). Official embed path and constraints; native TV suitability needs validation. High documentation.

## S42

OpenSubsonic: [API reference and authentication](https://opensubsonic.netlify.app/docs/api-reference/), [artists](https://opensubsonic.netlify.app/docs/endpoints/getartists/), [artist](https://opensubsonic.netlify.app/docs/endpoints/getartist/), [album](https://opensubsonic.netlify.app/docs/endpoints/getalbum/), [search](https://opensubsonic.netlify.app/docs/endpoints/search3/), [stream](https://opensubsonic.netlify.app/docs/endpoints/stream/), and [API-key authentication](https://opensubsonic.netlify.app/docs/extensions/apikeyauth/). Versioned protocol and auth variants; implementations/extensions require server tests. High protocol evidence.

## S43

Funkwhale: [API](https://docs.funkwhale.audio/developer/api/index.html), [OAuth authentication](https://docs.funkwhale.audio/developer/api/authentication.html), [Subsonic password](https://docs.funkwhale.audio/develop/user/subsonic/password/request.html). Supported native and compatibility routes. High.

## S44

Podcast Index: [official API repository](https://github.com/Podcastindex-org/docs-api), [episode endpoint schema](https://github.com/Podcastindex-org/docs-api/blob/master/api_src/paths/episodes/byfeedid.yaml). Discovery API, not rights to every enclosure/subscription. High.

## S45

Kavita: [API/authentication guide](https://wiki.kavitareader.com/guides/api/). Current auth-key guidance/OpenAPI reference; pin a supported server schema rather than assuming development head. High.

## S46

Audiobookshelf: [current API-key guidance](https://audiobookshelf.org/docs/documentation/server-management/api-keys/), [third-party-app guidance](https://audiobookshelf.org/docs/documentation/community/community-apps/), [old API reference](https://api.audiobookshelf.org/), and the [maintainer's JWT endpoint contract](https://github.com/advplyr/audiobookshelf/discussions/4460). Current docs direct third-party apps to JWT login/refresh and reserve API keys for server-to-server automation; the old API reference is unmaintained. This branch implements the mobile token flow, but server/version/runtime compatibility remains unqualified.

## S47

MusicBrainz: [API and commercial-use distinction](https://musicbrainz.org/doc/MusicBrainz_API), [rate limits](https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting). High metadata-route evidence; artwork/fingerprint services need separate terms.

## S48

Hardcover: [official API](https://api.hardcover.app/), [documentation repository](https://github.com/hardcoverapp/hardcover-docs/). GraphQL/token route; commercial terms and actual reading-state schema need implementation review. High API existence.

## S49

Letterboxd: [API access conditions](https://letterboxd.com/api-beta/), [API reference](https://api-docs.letterboxd.com/). Selective application-based access and user import/export/RSS alternative. High.

## S50

IGDB: [API documentation](https://api-docs.igdb.com/index.html), [commercial FAQ](https://api-docs.igdb.com/?trk=public_post-text). Free API with commercial partnership/attribution process; no game ownership or launch authority. High.

## S51

GOG: [official affiliate program](https://affiliate.gog.com/). Published commission, tracking and product-feed API. High; native promotional-property acceptance unknown.

## S52

Fanatical: [current affiliate landing page](https://www.fanatical.com/en/affiliates), [older FAQ](https://support.fanatical.com/hc/en-us/articles/360001415777-Affiliate-Partner-FAQ). Landing page names Awin while older help names CJ/Tapfiliate. Confirm the current accepted channel/network; do not copy old setup blindly. High program existence, moderate onboarding details.

## S53

Microsoft: [Movies & TV support](https://support.microsoft.com/en-au/windows/apps/watch-movies-and-tv-shows-on-the-microsoft-movies-tv-app). New movie/TV sales ended; existing purchased-content access remains described. High.

## S54

Palace: [Boundless migration/shutdown notice](https://thepalaceproject.org/boundless-to-palace/). Prefer migration-aware handling over new Boundless development despite older integration lists. High.

## S55

Affiliate networks: [CJ Link Search](https://docs.cj.com/docs/linksearch-api), [CJ Product Feed Search](https://docs.cj.com/docs/productfeed-api-search), [Rakuten product search](https://developers.rakutenadvertising.com/guides/product_search), [Rakuten deep links](https://developers.rakutenadvertising.com/guides/deep_link), [Awin feed guide](https://help.awin.com/developers/docs/product-feed-publisher-guide-intro). Supported feed/link mechanics; advertiser approval remains distinct. High.

## S56

Home Assistant: [Plex](https://www.home-assistant.io/integrations/plex), [Jellyfin](https://www.home-assistant.io/integrations/jellyfin/), [Android TV Remote](https://www.home-assistant.io/integrations/androidtv_remote). Relevant control ecosystem, not proof PlezyNG implements every detected-player protocol. High docs; moderate proposed attachment.

## S57

HDHomeRun: [technical HTTP/lineup guidance](https://info.hdhomerun.com/info/tech), [DVR record-engine status](https://info.hdhomerun.com/info/dvr_api%3Arecord_engine_status). Native local-TV integration route; model/channel/DRM qualification remains required. High.

## S58

Owncast: [official embedding guide](https://owncast.online/docs/embed/). Authorized instance embed route. High; no broad rights inference for third-party streams.

## S59

Plex: [Discover](https://support.plex.tv/articles/discover/), [Universal Watchlist](https://support.plex.tv/articles/universal-watchlist/). Useful product precedent and existing provider scope; not permission to extract/redistribute Plex partner data. Some examples use older service names, so they are not the source for current market availability. High behavior description.

## S60

Open Library: [API guidance](https://openlibrary.org/developers/api), [developer center](https://openlibrary.org/developers), [OpenAPI](https://openlibrary.org/docs). Low-volume discovery versus bulk dumps, current use guidance, and documented account endpoints. Existence of loan endpoints is not a blanket content/DRM permission. High.

## S61

Standard Ebooks: [feed access](https://standardebooks.org/feeds), [OPDS setup](https://standardebooks.org/help/how-to-add-an-opds-feed-to-your-ereader). Full feed eligibility/membership differs from open new-release feeds. High.

## S62

Komga: [API/authentication](https://komga.org/fr/docs/openapi/komga-api/), [OPDS guide](https://komga.org/docs/guides/opds/), [official repository](https://github.com/gotson/komga). Native API, OPDS, device/sync capabilities are distinct. High.

## S63

Bandcamp: [purchase formats](https://get.bandcamp.help/en/articles/15263234-in-which-formats-can-i-download-my-purchases), [where to download](https://get.bandcamp.help/en/articles/15263100-where-do-i-download-my-purchase). User-directed compatible downloads; no general fan-library API established. High.

## S64

Booklore: [official OPDS/Komga-compatible API documentation](https://github.com/booklore-app/booklore-docs/blob/master/docs/integration/opds.md). Preset/compatibility opportunity; exact progress/page-streaming parity must be tested. High documented route.

## S65

OpenSubtitles: [getting started](https://opensubtitles.tawk.help/article/getting-started), [official API reference](https://ai.opensubtitles.com/api-docs). Current REST API key and user-token distinction. High.

## S66

Podcast formats: [RSS 2.0 specification](https://www.rssboard.org/rss-specification), [Atom syndication format (RFC 4287)](https://www.rfc-editor.org/rfc/rfc4287), and [OPML 2.0 specification](https://opml.org/spec2.opml). These describe feed/subscription formats, not rights to replay every linked enclosure. High format evidence.

## S67

Project Gutenberg: [official offline catalog documentation](https://www.gutenberg.org/help/offline_catalogs.html). The public OPDS 1.2 search catalog is `https://www.gutenberg.org/ebooks/search.opds/`; Gutenberg says its XML feeds are expected to sunset in 2027 and that OPDS 2.0 remains a testing route. The app preset uses the documented public OPDS endpoint; recheck the migration notice before relying on it for a release. High.

## S68

Tubi: [free/ad-supported service explanation](https://tubitv.com/help-center/About-Tubi/articles/4409975158043), [official partner intake](https://corporate.tubitv.com/partners/partner-with-us/). Confirms ad-supported viewing and a partner route; no public app-referral rate identified. Checked 2026-10-28.

## S69

Pluto TV: [why the service has ads](https://support.pluto.tv/s/article/PTV-Why-does-Pluto-TV-have-ads?language=en_US), [distribution, content and advertising partners](https://pluto.tv/partners). Confirms free ad-supported viewing and partner inquiry channels; no public app-referral rate identified. Checked 2026-10-28.

## S70

Roku: [The Roku Channel partner overview](https://developer.roku.com/dev/docs/overview), [monetization](https://developer.roku.com/dev/docs/monetization), and [publisher payouts](https://developer.roku.com/dev/docs/payouts). Current public documentation describes app and content partner routes, Roku Pay's published 80/20 app-transaction share, and separate Roku Channel content payouts/terms. These are publisher/platform economics, not referral commissions for sending traffic to Roku. Checked 2026-10-28.

## S71

Samsung TV Plus: [official free/ad-supported service support](https://www.samsung.com/us/support/answer/ANS10000933/) and [advertising options](https://www.samsungtvplus.com/advertise.html). The service is device and region dependent; the public commercial page addresses advertisers and does not publish a viewer-referral rate. Checked 2026-10-28.

## S72

Xumo: [Xumo Play service information](https://www.xumo.com/about) and [Xumo Enterprise](https://www.xumo.com/enterprise). Xumo describes free ad-supported viewing and enterprise monetization/distribution for content owners and distribution partners; no public fixed referral payout was found. Checked 2026-10-28.

## S73

Plex: [free streaming FAQ](https://support.plex.tv/articles/frequently-asked-questions-vod/) and [Terms of Service](https://www.plex.tv/about/privacy-legal/plex-terms-of-service/). Ad-supported distributor economics and consumer terms do not establish a third-party client playback license or general revenue share. No public PlezyNG referral rate was found. Checked 2026-10-28.

## Conflicts and unresolved research

- Kobo standard versus influencer rates: retained as different program offers, not averaged.
- Fanatical network and B&N old third-party onboarding: current first-party landing pages take precedence; signed terms still control.
- Amazon old PA-API “latest version” help: superseded by explicit current Creators deprecation/migration documentation.
- Palace old supported-provider list versus Boundless shutdown: migration notice controls greenfield planning.
- Audiobookshelf old API reference versus maintained authentication docs: current source/runtime qualification required.
- Humble official partner page could not be retrieved in this run; no payout or API promise is made from third-party directories.
- Indigo direct accepted commercial terms were not available; intermediary evidence is a lead only.
- No Netflix/Disney/Prime Video public consumer playback contract was established; no private partnership was ruled out.
- Broad regional/specialty candidates without a dedicated source row remain research-only for native/API/affiliate support.
