# Service integration roadmap closeout

Status: code-level work for the selected first-release scope is delivered on `codex/service-roadmap-closeout-final-20261028`, based on `main` at `6fba6ab6d0c257c20b9470adf39dea13ffa6495f`. This records implementation boundaries and the remaining operator gates; it does not claim production qualification, partner acceptance, or earned revenue.

## Delivery by work package

| Package | Code state | What remains |
| --- | --- | --- |
| W00–W03 | Existing source, profile, route, and official handoff owners are retained. Profile-scoped preferences and reversible crosswalks are implemented. | Standard review and exact platform/runtime qualification. |
| W04 | Access is integrated into existing details, source routes, Settings → Services, and the existing Links flow. Comic storefront choices sit beside the local Read action. Watchmode title rows use the current detail Links route; MusicKit stays inside the music Links flow. | Provider entitlement is never inferred. Broader title-specific offers require licensed data and regional evidence. Accessibility/device review remains. |
| W05 | Validated ISBN handoffs, comic purchase/rental/reader links, and the server-side, deny-by-default comic affiliate broker are implemented. The broker falls back to direct merchant URLs and discloses eligible commission links. | Merchant/property approval, exact network credentials, feed/cache terms, and conversion reporting remain external. There is no checkout, order sync, or purchased-state mutation. |
| W06 | Watchmode uses typed TMDB movie/TV IDs and profile country; the relay holds the API key, limits upstream requests, returns curated HTTPS destinations, and keeps a bounded six-hour in-memory cache. The app shows results only in the existing title Links flow. | Keep disabled until the current commercial plan and app use are approved, deployment secrets are set, and regional/title samples are qualified. It does not check user subscription or play video. |
| W07 | Audiobookshelf JWT refresh and safe OPDS open-access/sample handling are implemented. Generic purchase/acquisition relations do not enter the unrestricted file path. | Supported server/feed and playback qualification. |
| W08 | Existing OverDrive gateway/native flows are present behind `ENABLE_OVERDRIVE=false`; official Libby handoff remains available. | OverDrive credentials, assigned scopes/environments, branding permission, and sandbox/production qualification. No Hoopla or Palace adapter is shipped for this release. |
| W09–W10 | Connected-catalog Search/Find Next, OpenSubsonic/Subsonic playback, podcast RSS/Atom, and HTTPS OPML transfer reuse current owners. | Provider-version, feed, and device playback qualification. |
| W11 | iOS Apple MusicKit catalog search/play is implemented in the existing music Links flow behind `ENABLE_APPLE_MUSICKIT=false` by default. | Enable MusicKit for the correct Apple App ID, use matching signing, build with `ENABLE_APPLE_MUSICKIT=true`, then qualify authorization, subscription, interruption, and profile teardown on supported devices. |
| W12 | Hardcover guarded shelf projection/sync and local Trakt-to-Letterboxd CSV export are implemented. | Live token-scope, mutation, and file-save qualification. Letterboxd export remains a manual local handoff. |
| W13 | Exact Steam AppID handoff and the Fanatical/Awin game-link path are implemented with direct-link fallback. | Advertiser/publisher acceptance, exact app-surface approval, and optional product-feed access. No price, ownership, activation platform, or installation is inferred. |
| W14 | Research is closed for this release with explicit no-go decisions for Home Assistant control, native HDHomeRun, and Readium LCP. Current Cast/remote controls, Live TV/M3U, and supported local readers remain. | Reopen only for a selected product use case, target hardware, commercial/legal rights, and funded certification where required. |
| W15 | Setup, architecture, UX, provider, commercial, source, and validation records are updated. | Attach exact-commit private-JIT, build, live-account, relay, and device receipts before making provider/platform support claims. |

## Operator activation gates

- **Watchmode:** use a current plan that permits the intended commercial app use, review the current retention/deletion terms, then configure `WATCHMODE_API_KEY` and set `WATCHMODE_COMMERCIAL_APPROVED=true` in the relay secret store. Keep the flag false until those gates and live title/region checks pass. A non-default relay can be set with `PLEZY_WATCHMODE_AVAILABILITY_BASE_URL`. The bounded memory cache contains no images and must be purged when the service is disabled or canceled.
- **Apple MusicKit:** enable the MusicKit App Service for the iOS bundle ID, retain `NSAppleMusicUsageDescription`, use the matching signed profile, and build with `ENABLE_APPLE_MUSICKIT=true`. Each user grants access; Apple owns its subscription and playback state.
- **Comic/game affiliate links:** configure only the approved merchant/network pairs in `server/comic-commerce.env.example`. All approval switches default to false. Network credentials and publisher/advertiser identifiers stay server-side; never enable a surface outside the accepted property terms. A click is not a sale or commission.
- **OverDrive:** keep `ENABLE_OVERDRIVE=false` until the assigned credentials, scopes, environments, IDs, branding terms, and provider qualification are in place.
- **Hoopla/Palace:** no adapter is included. Hoopla requires its signed API license, library-specific access, and express written permission for any income derived from its API/data. Palace requires a selected institution/vendor agreement and an agreed fulfillment/DRM path. These are separate partner-approved projects, not key-only activation.
- **Validation:** the repository records no tests, analyzer, platform build, live provider request, relay deployment, or device qualification for this closeout. Root `AGENTS.md` requires compatible private ephemeral JIT runners for GitHub Actions; hosted fallback is not authorized.

## W14 decisions

- **Home Assistant — no-go for this release.** REST control is feasible, but no distinct household action was selected beyond existing Cast, remote-stream, server, and deep-link controls. Avoid adding a second token/entity management surface without a product use case.
- **HDHomeRun — no-go for a native tuner adapter.** Keep the existing Live TV and user-provided M3U routes. A tuner adapter needs selected hardware, channel/DRM coverage, EPG/DVR rights, and any required vendor discovery approval.
- **Readium LCP — no-go for protected-reader work.** Existing readers cannot open an LCP-protected book through generic EPUB parsing. Proceed only with certified-reader status, fees, rights, secure license storage, offline expiry handling, and target-platform qualification.

No partner applications, messages, agreements, payments, deployments, or live qualification actions were performed in this closeout.