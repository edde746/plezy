# Public-library services and OverDrive activation

OverDrive/Libby native integration ships **Coming soon**. `LendingService.overdriveEnabled` defaults to `false` and blocks native authorization, discovery and circulation requests. Users can still save their library's official site and open Libby normally. The app contains the catalogue, loans/holds, availability, checkout, hold placement/pickup, hold-email editing, suspension/resumption, cancellation/early-return and fulfillment flows. The companion token gateway is in `tools/lending_gateway/`; it is not deployed by building the client.

Native release activation is a deliberate rebuild with `--dart-define=ENABLE_OVERDRIVE=true`, after the approved developer integration has passed its assigned sandbox and branding checks. The flag is not a claim of provider approval or live-service certification. No credentials have been embedded or deployed.

## Which credentials belong where

| Service | Maintainer | Individual user |
| --- | --- | --- |
| OverDrive / Libby | Approved application key/secret, assigned website/library IDs and allowed scopes/environments | Library-card authorization in OverDrive's hosted QR/device flow. The app stores the resulting encrypted patron/refresh tokens. |
| Hoopla | Integration agreement and developer credentials from its developer program | Uses Hoopla's own app/site sign-in. Native patron authorization is not enabled without an approved supported flow. |
| Open Library | No app key for public catalogue search | Signs into Open Library/Internet Archive on its own site for borrowing/reading where offered. |
| Palace, cloudLibrary, BorrowBox, Cantook, Onleihe or another library | Provider-specific agreement/API if native circulation is desired | Saved official library/service link; hosted account and reader flow. |

These services are not interchangeable OAuth providers. SCIM provisions accounts; it is not a consumer sign-in mechanism. Do not collect library-card PINs in a generic PlezyNG password form or scrape private Libby/Hoopla endpoints. Native Open Library search is available; actual availability/borrowing stays on its official site. Provider handoffs preserve that service's lending/DRM rules rather than importing a loan as a perpetual owned file.

The maintainer has already applied for OverDrive API access. When the response arrives, confirm Discovery **and** Circulation, integration and production environments, website IDs, an approved app display name, QR/device authorization eligibility, `PATRON`/`PATRONINT` scope assignments, callback parameter name and branding/fulfillment permissions. Start at [OverDrive request access](https://developer.overdrive.com/request-access) for later maintainers. Ask OverDrive about organization/partner eligibility if necessary. Hoopla publishes [developer documentation](https://developer.hoopladigital.com/) and lists `hdiscovery@midwesttape.com` for integration inquiries; a personal Hoopla account is not a substitute for an integration agreement. This implementation sends no application or email on your behalf.

## Gateway configuration

Copy `tools/lending_gateway/config.example.json` to a private file outside the checkout. Replace every placeholder with assigned values. Keep it mode 0600, owned by the unprivileged service account. Generate a random signing key of at least 32 characters. It binds refresh proofs to the selected library/environment; rotating it requires users to authorize again. Run a single gateway process behind your HTTPS reverse proxy:

```sh
PLEZY_LENDING_CONFIG=/etc/plezy-lending/config.json python3 tools/lending_gateway/server.py
```

The server binds only `127.0.0.1:8788` (override `PORT` locally if necessary). Configure TLS and a real hostname at the proxy, preserve `Host`, overwrite `X-Real-IP` with the actual remote address, cap request bodies/connections, and disable access/query logging for these routes. A sample Nginx location is included. Do not expose the Python listener to the public network or log callback URLs, token bodies, authorization headers or config files. Supervise the process with your existing service manager; do not run it as root.

- The gateway exposes only explicitly configured libraries, never arbitrary caller-selected website IDs.
- Authorization uses a random request ID, a secret callback capability, a ten-minute lifetime and S256 PKCE binding between the app and gateway.
- Polling consumes a provider code before exchange, so replay cannot exchange it twice. Refresh uses a signed library-bound proof. OverDrive developer secrets stay exclusively at the gateway.
- The upstream exchange uses the official static HTTPS endpoints and refuses redirects. Responses are no-store; origins/CORS are rejected. Rate, body and pending-session limits are enforced.
- Pending sessions are memory-only and disappear on restart. A single process is required; multiple replicas need a shared atomic session store before deployment. Existing encrypted refresh tokens keep working across restarts while the signing key is stable.
- The callback query parameter defaults to `code`; OverDrive's public QR guide describes the returned code without naming the parameter. Confirm the actual approved integration and set `code_parameter` accordingly before activation.

## Activation sequence

1. Put the assigned integration credentials and website IDs in private gateway configuration. Set `integration: true`; configure `circulation` only if that scope is approved. Complete the provider's callback/display-name setup and confirm the logo/partner-branding terms.
2. Run `python3 -m unittest discover -s tools/lending_gateway -p 'test_*.py' -v`. Build a private client with `--dart-define=ENABLE_OVERDRIVE=true`.
3. In Files and books → Public libraries → Libby / OverDrive, open app registration, enter the gateway's HTTPS origin and select an allowed library. Save it, then authorize using the hosted screen. Users enter personal card/PIN details only there.
4. Validate fresh sign-in, cancellation, expiry, refresh rotation, revoked-card recovery and profile changes. Confirm the exact patron collection (including Advantage), paging, availability and cover metadata using the assigned sandbox.
5. Exercise checkout, holds including ready-for-pickup, suspension/resumption, email updates, cancellation, supported early return, due dates and download/reader redirects. A loan never downloads into owned-file storage. Kindle/service-specific fulfillment remains provider-owned.
6. Verify physical platform/browser accessibility and branding. Replace integration libraries with approved production IDs, keep production credentials server-side, and rebuild the release with the flag. Follow the repository's normal manual release process; do not merely distribute a developer-key-containing client.

Returning a loan or cancelling a hold always requires a user confirmation. Availability is fetched explicitly before deciding between checkout and hold. Only provider-advertised early-return/remove/suspend actions are offered; eligibility and actual DRM formats remain provider-controlled. The implementation does not decrypt licensed content or reverse-engineer Libby's private APIs. Hoopla and regional services currently use official handoffs; their native circulation cannot truthfully be enabled solely with an OverDrive key.

## Official API references

- [QR/device authentication](https://developer.overdrive.com/api-docs/authentication/qr-code-authentication)
- [Patron information and personal collection links](https://developer.overdrive.com/api-docs/circulation-apis/patron-information)
- [Catalogue search](https://developer.overdrive.com/api-docs/discovery-apis/search)
- [Checkouts and fulfillment](https://developer.overdrive.com/api-docs/circulation-apis/checkouts)
- [Holds and suspension](https://developer.overdrive.com/api-docs/circulation-apis/holds)
- [Open Library API guidance](https://openlibrary.org/developers/api)
- [Official Libby assets](https://resources.overdrive.com/library/marketing-outreach-community/libby-website-assets/)
