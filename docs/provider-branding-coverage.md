# Provider branding coverage

Provider artwork stays bundled and renders offline. The connector directory does not download logos from vendor sites. `ConnectorBrandMark` uses a provider-specific alias or the matching Simple Icons mark when available, then falls back to a neutral name monogram; it never borrows another provider's icon.

## Existing connection marks

- Media-server choices use the existing Plex, Jellyfin, and Emby badges.
- Google Drive, OneDrive, Dropbox, Komga, and Audiobookshelf file-source choices use their bundled marks. Generic protocols continue to use neutral symbols.
- Tracker and Seerr connections use the existing catalog-source marks. Hardcover uses its bundled provider mark.
- Remote streaming connection actions use bundled marks for Stremio, Real-Debrid, and Premiumize. Discord Rich Presence uses the Discord mark.
- Comic-commerce and other external hand-off buttons use the shared provider mark resolver.

## Vendor approvals before release

- **TorBox:** no logo is bundled until the partner/API agreement confirms the required brand-asset permission.
- **AllDebrid:** its public legal terms reserve reproduction rights for its visual artwork. No logo is bundled pending written permission or a provider-supplied asset under an approved agreement; its connection action uses the neutral “AD” monogram until then.
- **Other external destinations:** when the bundled Simple Icons set has no matching mark, the destination uses its neutral name monogram. Do not substitute an unrelated company logo. Add new assets only with source, license, and attribution recorded in `assets/provider_marks/sources.json` and `assets/provider_marks/NOTICE.txt`.

These are partner setup items, not API-key placeholders. The existing connector actions and authentication flows remain usable once their separate provider credentials and API agreements are configured.
