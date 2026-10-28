# Provider branding coverage

Provider marks use a layered resolver across existing connection and title hand-off screens:

1. Bundled provider assets render first and work offline.
2. Curated Simple Icons marks render for known providers.
3. If neither source has a mark, a configured build can hotlink the official-domain logo from Brandfetch's Logo API.
4. If no logo can be loaded or no client ID is configured, the existing neutral provider monogram remains.

External-access entries supply their curated official host to the resolver. Connection-only services use a small map of canonical provider domains. The resolver validates host syntax and constructs a fixed HTTPS request to `cdn.brandfetch.io`; names, titles, search terms, account data, and credentials are never sent to Brandfetch. A remote request reveals the requested provider domain and the user's network address to Brandfetch.

Brandfetch's Logo API requires a public client ID and its published usage rules require hotlinking rather than caching. The app uses Flutter's network image pipeline and does not save remote logos as local or offline assets. Configure the ID in release builds with `--dart-define=BRANDFETCH_CLIENT_ID=...`. After written approval for a restricted provider, add its canonical domain to the comma-separated `BRANDFETCH_APPROVED_DOMAINS` list. AllDebrid (`alldebrid.com`) and TorBox (`torbox.app`) remain gated unless explicitly listed. The client ID is public and must not be treated as a secret. The service may be left unconfigured; all screens keep their bundled marks and monogram fallback.

## Existing connection marks

- Media-server choices use the existing Plex, Jellyfin, and Emby badges.
- Google Drive, OneDrive, Dropbox, Komga, and Audiobookshelf file-source choices use their bundled marks. Generic protocols continue to use neutral symbols.
- Tracker and Seerr connections use the existing catalog-source marks. Hardcover uses its bundled provider mark.
- Remote streaming connection actions use bundled marks for Stremio, Real-Debrid, and Premiumize. AllDebrid and TorBox can resolve through Brandfetch only after their domains are explicitly approved.
- Comic-commerce and other external hand-off buttons use the shared provider mark resolver, including the official host already curated for each destination.

## Partner approvals

- **AllDebrid:** its public legal terms reserve reproduction rights for its visual artwork. The resolver keeps its mark as a monogram unless `alldebrid.com` is included in `BRANDFETCH_APPROVED_DOMAINS` after written approval. This prevents enabling the general Brandfetch client ID from silently turning on the restricted logo.
- **TorBox:** its API Developer Terms require brand-asset use to follow published guidelines or written permission. Keep `torbox.app` out of `BRANDFETCH_APPROVED_DOMAINS` and leave its connection mark as the neutral monogram until permission is confirmed.
- **Other external destinations:** keep the provider's canonical host in the directory and do not substitute an unrelated company's logo. For future bundled artwork, record source, license, and attribution in `assets/provider_marks/sources.json` and `assets/provider_marks/NOTICE.txt`.

A build that has the Brandfetch client ID configured can render remote logos for the eligible destinations without adding individual logo assets. Provider API credentials, affiliate credentials, and commerce agreements remain separate and are used only by their existing connection or server-side broker flows.
