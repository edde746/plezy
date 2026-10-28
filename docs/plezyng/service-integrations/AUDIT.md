# Repository audit

## Scope and evidence

Inspected `snapetech-org/PlezyNG` at **main `0d0626cc375b8fa95124775365a6b37e2a03c9be`**. The recursive tree was complete, and a shallow local checkout was used to read the integration, navigation, source, lending, tracker and design owners. This is a focused architecture audit, not an exhaustive security audit or a device test.

Before publication, refreshed main to **`fb371d5046d16ecfaa7af9869b028b253f06ff83`** and compared the intervening changes. They affect the private-JIT Windows CI marker, its workflow guards/tests and changelog only; none of the audited application owners changed. This documentation branch incorporates that updated base.

Also inspected the README and changed integration paths of **`codex/debrid-stremio-integration-20261028` at `5b7f8578b6dae95b8818cfcb5e50aca2052a13f6`**. Its source is separate from the inspected main baseline. No code from that branch is copied or merged here. Live branch heads can move; recheck before follow-up work that touches shared provider/source registries.

Confidence is **high** for statements grounded in these files. Runtime behavior on real accounts/devices is **unknown** unless a cited existing delivery document explicitly records evidence; this planning PR did not reproduce those tests.

## Existing owners and extension points

| Area | Inspected owner | What exists; implication for this plan |
| --- | --- | --- |
| Design | `DESIGN.md`, `UX-CONTRACT.md`, `lib/theme/mono_theme.dart`, `mono_tokens.dart` | Artwork-led shelves, quiet monochrome controls, existing geometry, adaptive menus/sheets, accessibility and Slang. Provider work must inherit these contracts. |
| Navigation | `lib/navigation/navigation_tabs.dart` | Home (`discover` internally), Libraries, Live TV, Explore, Search, Downloads, Games, Settings. Feature/profile/platform visibility is already conditional; tvOS hides Downloads. |
| Services management | `lib/screens/settings/services_settings_screen.dart` | Existing grouped tracker/Seerr rows plus Games and Discord settings. Extend this hub, retaining service-specific owners. |
| Server media | `lib/media/`, `lib/providers/multi_server_provider.dart`, `lib/services/playback_source_resolver.dart` | Plex/Jellyfin/Emby have established server identity, permissions, metadata and playback routes. Do not pretend a retail service is a server. |
| External catalogs | `lib/services/catalog/catalog_source.dart`, `lib/providers/catalog_sources_provider.dart`, `lib/models/catalog/catalog_item.dart` | Explore adapters for Plex, Trakt, MAL, AniList, SIMKL, Seerr and MDBList. `CatalogSourceId` is a fixed enum; `CatalogItemIds` is video/anime oriented. Optional interfaces already avoid making all adapters implement irrelevant features. |
| Search | `lib/screens/search_screen.dart`, `lib/media/search_hit.dart` | Main search combines server items, indexed source entries and Seerr. It does not crawl every remote provider. `SourceSearchHit` deliberately keeps file identity separate. |
| Files/publications | `lib/sources/source_models.dart`, `source_controller.dart`, `source_database.dart` | `FileSource`, `SourceEntry`, `PublicationFile`, `ContentLease` and capability-aware adapters; profile ownership and edition/file-qualified progress. |
| Existing transports | `lib/sources/adapters/` | Local, WebDAV, SMB, FTP, SFTP, NFS, DLNA, Google Drive, OneDrive, Dropbox, S3, OPDS, Audiobookshelf, Komga. Productized presets can reuse protocols instead of adding redundant adapters. |
| OPDS | `lib/sources/adapters/opds_source.dart` | OPDS JSON/Atom, direct/open-access/sample acquisition relations and comic page streaming. Existing parsing is not a complete authenticated lending/DRM implementation. |
| Lending | `lib/lending/lending_service.dart`, `lib/screens/lending/public_libraries_screen.dart`, `docs/LENDING_SETUP.md` | Open Library search; stored official links for library services; extensive native OverDrive code with `ENABLE_OVERDRIVE=false`. Regional service selection does not establish native circulation. |
| Lending backend | `tools/lending_gateway/` | Provider secrets and QR exchange isolated from the client. The documented gateway is single-process with memory-only pending sessions; deployment is separate. |
| Credential/profile boundaries | `lib/services/credential_vault.dart`, `lib/profiles/active_profile_binder.dart`, `profile_connection_registry.dart`, `lib/sources/source_oauth.dart` | Encrypted secrets, profile-generation invalidation and existing auth owners. Reuse lifecycle patterns; do not turn the media-server join registry into a universal unrelated account table. |
| Detail/play/read | `lib/screens/catalog_item_detail_screen.dart`, `media_detail_screen.dart`, `sources/source_detail_screen.dart`, `sources/source_navigation.dart`, `sources/source_player_screen.dart`, `sources/publication_reader_screen.dart` | Canonical routes already exist. Add contextual access options to them; retain player, reader and progress ownership. |
| Downloads | `lib/sources/offline_readiness.dart`, `content_access.dart`, `lib/providers/download_provider.dart` | Complete local representations and ephemeral access leases matter. A remote store download entitlement is not an existing offline file. |
| Cross-media discovery | `lib/discovery/`, `lib/screens/discovery/find_next_screen.dart`, `docs/plezyng/swipe/` | Reversible profile-local Save/Not now and bounded revalidation. Borrow/buy/play stay explicit, never side effects of a swipe. |
| Artwork | `lib/widgets/provider_mark.dart`, `catalog_source_logo.dart`, `assets/provider_marks/` | Official unmodified marks at service affordances; attribution/provenance retained. No vendor-colored redesign. |
| Games | `lib/games/`, `docs/games/ARCHITECTURE.md`, `docs/games/STEAM_LIBRARY.md` | Steam identity/visible library and paired-host routes are separate. Ownership does not imply installation, an available host or a qualified stream. Use the existing game grid. |
| Backend | `server/`, existing OAuth proxy and Steam integration | A place for confidential partner credentials, if deployment is approved. Do not make local-file playback dependent on it. |

## Findings

| ID | Finding and impact | Recommendation | Confidence |
| --- | --- | --- | --- |
| A01 | Current abstractions distinguish owned files from server items but do not provide a general retail offer/entitlement/fulfillment layer. Adding stores as `FileSourceKind` values would conflate these. | Add an access-option model beside current media models and expose optional provider capabilities. | High |
| A02 | Existing catalog IDs favor video/anime; a blanket expansion to books/music/games would introduce false equivalence. | Typed external IDs and explicit work/edition relationships, preserving original owner keys. | High |
| A03 | Native OverDrive is present but compiled off. Having code and gateway tests is not production approval. | Keep Coming soon; execute the existing activation sequence and add concrete circulation/fulfillment evidence. | High |
| A04 | Hoopla has documented partner search and patron operations, including borrowing and holds. It merits more than a permanent launch-only assumption. [S08](SOURCES.md#s08) | Plan a separate approved Hoopla adapter, hosted/supported patron authorization and staging qualification. Fulfillment remains provider-owned until documented otherwise. | High API existence; unknown PlezyNG access |
| A05 | Current Audiobookshelf source setup uses a stored bearer `token`; inspected adapter has no refresh flow. New official guidance directs third-party clients to standard JWT authentication and marks old API docs unmaintained. [S46](SOURCES.md#s46) | Prioritize auth/version compatibility investigation; preserve existing token connections during any migration. Do not label all current servers broken without testing. | High observed mismatch; unknown live failure rate |
| A06 | OPDS supports direct acquisitions but an ACSM/LCP license or borrow link is not a file. | Classify relation, media type, rights and license status before dispatch; preserve official-reader fallback. | High |
| A07 | Main Search is partly federated, not a universal external catalog engine. One request per provider per keystroke would be expensive and slow. | Progressive, cancellable query legs; local-first results; explicitly enabled remote categories and bounded budgets. | High |
| A08 | Debrid/Stremio branch already introduces scoped accounts, clouds, manifest/stream lookup and standalone playback. Its README explicitly defers unified catalogs, account import, durable jobs and renewable/background leases. | Share future provider/session and access-option contracts after reconciliation; do not reimplement its account store or mark its deferred work complete. | High at inspected branch |
| A09 | A universal “Connected” badge would misrepresent selected subscriptions and stores with no account API. | Use Selected, Linked, Reconnect, Open externally, Partner access pending, and Unsupported on this device based on actual evidence. | High |
| A10 | Affiliate commerce makes data licensing and distribution conditions relevant to the whole product. Free developer access does not automatically cover a monetized app. | Record accepted licenses, channel eligibility and revocation behavior before enabling production data or tracking. | High |
| A11 | External apps cannot generally send PlezyNG reliable progress or purchase receipts. | Record launch intent separately; import receipts/files only through verified routes; no automatic scrobbling on return. | High |
| A12 | Broadening services increases profile/session race surfaces. | Every async result, callback, queued mutation and provider SDK instance must be bound to an immutable owner and generation; test account replacement and disconnect. | High |

## Branch coordination

Other branches visible during inspection included connected-media continuity, network-aware playback ranking, Steam connected experience, household setup/diagnostics, motion planning and VLC parity. Their existence is not implementation evidence. Main already contains a connected-media delivery document and Steam-library work; use the actual current code, not old branch descriptions, to resolve overlap.

Luna should compare current main and the active debrid branch before choosing shared type names. This plan proposes responsibility boundaries rather than instructing a blind cherry-pick. The older remote-stream planning document's historical main/no-PR instruction belongs to its earlier task. **This request explicitly requires a PR branch and push.** Preserve concurrent changes; do not force-push or merge to main as part of this assessment.

`AGENTS.md` requires private ephemeral JIT runners and no hosted fallback. The inspected CI workflow is manually dispatched. This documentation change does not need a runtime build or CI dispatch; future implementation must follow the current policy and record exact checks.
