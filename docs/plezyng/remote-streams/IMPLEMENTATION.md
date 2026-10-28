# Luna implementation and remaining work register

This register now tracks the code on
`codex/debrid-stremio-integration-20261028`. The branch implements connected
debrid accounts, an on-demand cloud-file browser, Stremio account linking and
add-on import, catalog browsing in Explore, and stream choices within existing
title-detail flows. It does **not** complete the full R01–R16 product plan:
cloud files are not indexed as poster rows; native P2P, background lease
renewal, downloads and unified cross-surface media merging remain separate
packages below. Keep those limits explicit in release notes and UI.

The owner requested implementation on a PR branch. Commit and push only to that
branch; do not dispatch GitHub Actions or use hosted runners. The repository
requires private ephemeral JIT runners for any later authorized build/CI work.

## Implemented on this branch

| Area | Current implementation | Scope limit |
| --- | --- | --- |
| Profile ownership and secrets | `RemoteStreamingProvider` follows `ActiveProfileProvider`; accounts, signed manifest URLs and descriptors are protected by `CredentialVault` in profile-scoped preferences. Unreadable ciphertext is preserved until the user explicitly clears it. | Cloud inventory is fetched on demand and not persisted as source records. OS keychain lock errors use the retry path; unrecoverable ciphertext loss requires explicit clearing and reconnect. |
| Connection setup | Real-Debrid device authorization and AllDebrid PIN flow use the shared QR/code dialog. Premiumize and TorBox API keys are validated with their account endpoints before encrypted save. | Premiumize uses API-key setup because PlezyNG does not yet have a registered OAuth client. TorBox device flow is not wired. |
| Stremio add-ons | HTTPS manifest validation, manual install, first-party QR account link and read-only installed-add-on import preview; catalog and stream resources, catalog search/paging, title metadata, per-installation enable/remove, external links, HTTPS streams, hash/file index, request headers and subtitles. Imported account keys are memory-only; imported manifest URLs are revalidated before encrypted profile save. | Required catalog filters/configuration, account add-on ordering, automatic manifest update review, and native JavaScript add-ons are not implemented. HTTP add-ons require manual setup with explicit opt-in. |
| Playback | Stream choices open the existing standalone `SourcePlayback`/`SourcePlayerScreen`, retain the title's external identifiers and duration, and persist local resume progress. Subtitle selection downloads a bounded file and uses the existing external-subtitle path. | This does not join the server video queue/player chrome or report remote playback to a Plex/Jellyfin/Emby server. PiP/multiview and background playback qualification are outstanding. |
| Resolver services | Real-Debrid, AllDebrid and Premiumize resolve v1 hashes and supported file-host links. TorBox resolves cached v1 torrents only and only creates items with `add_only_if_cached`. All four providers expose on-demand video-file browsing from their cloud inventory. When multiple services are connected, the picker asks which account to use. | No v2 hash resolution, uncached TorBox jobs, durable operation ledger or same-copy lease renewal. A generated CDN link can expire during long playback. |
| Network boundary | Add-on request headers are bounded and validated, then held in memory behind the loopback media gateway. HTTP is opt-in per add-on. HLS children inherit headers only on the same origin; redirect policy prevents HTTPS downgrade and strips sensitive headers on cross-origin redirects. | Provider-specific DNS/IP egress blocking, DASH nested-resource handling and native-engine fetch auditing remain unqualified. |
| App integration | The existing Services hub manages accounts and add-ons; Explore loads enabled Stremio catalogs and search; Stremio catalog titles resolve metadata and movie stream options; supported library title details offer contextual stream discovery; Files and books remains one destination in the picker and nested Libraries rail. Cloud browsing has refresh, empty/error recovery, and a path back to connection management. Shared authorization QR, copyable codes, catalog source marks, keyboard focus, and loading/error cues reuse existing UI contracts. | Cloud inventory remains on-demand and is not indexed as poster libraries or merged into Home, Search or Downloads. Remote playback does not write progress to a Plex/Jellyfin/Emby server; the native player/P2P engine remains separate. |

No automated tests or app builds were run for this implementation. The current
workspace does not include the Dart or Flutter SDK, and the user requested no
CI dispatch. `git diff --check` and source/document inspection are the local
review gates for this branch; live account linking, imported descriptor
fixtures, playback behavior and packaged-device behavior remain unverified.

## Start here

1. Read this folder and current `AGENTS.md`; inspect the current PR branch.
   Current code is authoritative over this design baseline.
2. Before implementing a remaining package, inspect its profile-binding,
   startup, source, catalog, playback, download, PiP and multiview contracts.
   Use existing dependency injection, HTTP factories, clocks and platform
   abstractions.
3. Establish a provider fixture harness using synthetic public test media and
   sanitized captured protocol shapes. Keep live accounts out of unit tests.
4. Promote the on-demand provider inventory into existing source/catalog
   queries with stable account and file identities. The current Stremio
   catalog/account-import slice is a compatibility baseline; add fixture
   coverage for its exact first-party and add-on response shapes before
   broadening it. Do not rewrite server clients or the entire player at once.

## Current implementation map

| File | Responsibility |
| --- | --- |
| `lib/services/remote_streams/stremio_account_client.dart` | Isolated first-party link-code polling, memory-only token exchange, read-only account add-on collection and HTTPS descriptor filtering |
| `lib/services/remote_streams/stremio_addon_client.dart` | Manifest/resource validation, stream lookup, Stremio catalog extras encoding, catalog/meta requests and response bounds |
| `lib/services/catalog/stremio_catalog_source.dart` | One existing catalog-source adapter exposing per-installation catalogs to Explore and search, with installation-scoped catalog/detail identity |
| `lib/providers/catalog_sources_provider.dart` | Profile-aware registration and disposal of the composite Stremio Explore source |
| `lib/screens/settings/remote_streaming_settings_screen.dart` | Nested QR account import, selection preview and manual manifest install in the existing settings screen |
| `lib/screens/catalog_item_detail_screen.dart` | Contextual movie streams and an accessible episode list for Stremio catalog entries, using the existing stream picker/player |
| `lib/models/catalog/catalog_item.dart` | Optional add-on installation/item identity carried through existing catalog routes |

Catalog source identity remains one `CatalogSourceId.stremio` value for the
existing source contract. An item's originating installation ID and item ID
are carried on the item and in the catalog route; identical manifest IDs from
two add-ons therefore remain addressable without adding an entry per add-on to
navigation or the source enum.

## Proposed code layout

Names may follow current repository conventions at implementation time; keep
the responsibility boundaries and update this table if names change.

| New area | Responsibility |
| --- | --- |
| `lib/models/remote_streams/` | Account/install identities, candidate descriptors, capabilities, intent, lease, typed failures and job state |
| `lib/services/remote_streams/account_registry.dart` | One client/auth owner per scoped account and generation |
| `lib/services/remote_streams/auth/` | Provider auth adapters plus extracted generic cancellable device-code driver |
| `lib/services/remote_streams/providers/` | Real-Debrid, AllDebrid, Premiumize, TorBox and later qualified clients |
| `lib/services/remote_streams/stremio/` | Manifest/resource parser, routing, account import client and fixtures mapping |
| `lib/services/remote_streams/remote_media_repository.dart` | SourceRepository extension, identities, copies, import transactions and jobs |
| `lib/services/remote_streams/unified_media_queries.dart` | Progressive browse/search/Home projections over existing backends |
| `lib/services/remote_streams/stream_resolver.dart` | Eligibility, ranking, single-flight resolution, preparation and lease renewal |
| `lib/services/remote_streams/request_policy.dart` | Destination/redirect/header policy, scheduling and sanitized diagnostics |
| `lib/services/remote_streams/preparation_manager.dart` | Durable operation ledger, reconciliation, ownership and polling |
| `lib/services/remote_streams/remote_playback_binding.dart` | Typed playback dispatch and existing player/session integration |
| `lib/sources/adapters/remote_cloud_source.dart` | File-source projection for a registered account |
| `lib/screens/settings/streaming/` | Connection/detail/import screens built from existing widgets |
| `lib/widgets/stream_source_sheet.dart` | Shared source picker for detail and player version/quality controls |
| `native/remote_streams/`, platform packaging | Optional native P2P engine and narrow bridge, only after engine selection |
| `test/remote_streams/`, `test/fixtures/remote_streams/` | Contract fixtures, fault injection, identity, lifecycle and integration tests |

Add one `FileSourceKind.remoteCloud` (or equivalent registry dispatch) referencing
an account ID. Do not replicate account secrets in `FileSource.options` or add a
file-source enum member for every commercial provider. Give Stremio catalogs
installation keys rather than shoehorning all manifests into one enum value.

## Work sequence and exit criteria

| ID | Package and dependencies | Concrete deliverable | Exit evidence |
| --- | --- | --- | --- |
| R01 | Contracts and fixtures; none | Domain types, fake clock/HTTP harness, read-only versus mutation boundaries, safe diagnostics | Malformed response and secret-redaction fixtures pass; unknown capability stays unknown |
| R02 | Persistence/profile lifecycle; R01 | Additive SourceDatabase migration, account registry, vault records, profile-generation cancellation | Upgrade/restart/key-loss/profile-switch tests; existing source/server data unchanged |
| R03 | Connection UI/auth; R02 | Generic auth driver, native provider auth adapters, existing dialog integration, account detail and shortcut routes | QR/code expiry/cancel/reconnect tests; no duplicate callback/account; no hardcoded shared secrets |
| R04 | Real-Debrid vertical slice; R03 | Cloud adapter, paged files, targeted file mapping, same-copy resolution/renewal and source progress | A fixture-backed end-to-end play/resume path plus live qualification when credentials exist |
| R05 | Shared video presentation; R04 | Typed playback target, common chrome/controls, source/reporting adapters, next episode and slot lifecycle | Server and standalone regressions; remote subtitles/PiP/multiview tests; no fake server client |
| R06 | Dynamic catalog identity; R02 | Partial: one composite Stremio catalog source with per-item installation identity; broader dynamic source-key migration and episode capability | Two installations with identical manifest IDs coexist; legacy preferences still select correctly |
| R07 | Stremio protocol; R01/R06 | Partial: HTTPS manifest/catalog/meta/stream/subtitles, bounded search/paging and extras; required filters and account ordering remain | Protocol compatibility corpus, configured-prefix routing and timeout isolation pass |
| R08 | Stremio account import; R03/R07 | Partial: current first-party QR link, read-only descriptor fetch, secure selected-add-on preview; no Stremio auth key is persisted; optional history import is not included | Actual serialization fixtures; QR/sign-in live check; no remote collection/progress mutations |
| R09 | Identity and queries; R04/R06/R07 | Identity/copy index, progressive Search/Home/Libraries/Explore projections, manual match/undo | Duplicate and conflicting-ID cases; cloud-only cold start; no forced Plex sign-in |
| R10 | Source selection and preparation; R05/R07/R09 | Adaptive source sheet, ranking, explicit preparation authority, durable queue/reconciliation | Lost-POST response cannot duplicate work; episode packs select correctly; unknown cache is truthful |
| R11 | Remaining core providers; R03/R04/R10 | AllDebrid, Premiumize and TorBox using the same contracts | Provider-specific auth/envelope/file mapping/delayed/limit tests and account smoke evidence |
| R12 | Downloads, progress and sync; R05/R09/R10/R11 | Shared queue presentation, qualified background renewal, one progress writer, tracker acknowledgements | Process-death/renewal/quota tests; existing sync unchanged; no plaintext native task descriptors |
| R13 | Ecosystem adapters; R07/R11 | put.io/Debrid-Link/Seedr when contracts obtained; aggregator and file/Usenet-bridge fixtures | Per-provider capability matrix; unsupported fields produce actionable typed results |
| R14 | Native P2P; R05/R10 | Engine selection evidence, native bridge, piece scheduling, quotas, lifecycle, packaging | Controlled swarm playback/seek tests and real target evidence; no default P2P fallback |
| R15 | Complete UX integration; R08/R09/R10/R12 | Find Next, existing version/quality sheet, source visibility, help, localization and accessibility | Cross-surface profile gating; D-pad/RTL/large-text checks; zero duplicate settings stores |
| R16 | Full qualification and docs; preceding packages | Completed validation matrix, setup/troubleshooting guide, changelog/README feature entry, measured budgets | Exact commit/build/target results and explicitly enumerated external dependencies |

R06/R07/R08 can be qualified after the initial vertical slice without waiting
for every native adapter. R14 does not block useful cloud/add-on delivery, but must
remain visibly incomplete in the scope register until an engine actually plays
and seeks. R13's unavailable native API contracts do not prevent generic
configured-add-on and file-source coverage.

## Package implementation notes

### R01–R03: account and capability boundaries

Use the current profile binder as the lifecycle owner. Credentials enter the
vault before an account is considered durably connected. Validate the account
identity, then publish inventory and catalog projections atomically. If the
key store is unavailable, offer session-only access only if the UI explicitly
says it will not persist; never save plaintext. Treat restored settings without
the corresponding OS key as reconnect-needed, not as a blank replacement token.

Extract the tracker device-code driver's scheduling/cancellation into a generic
component while keeping tracker behavior unchanged. Real-Debrid's credentials
step, AllDebrid's PIN envelope, Premiumize's device grant and TorBox's error
codes are separate adapters; do not force them into one RFC-shaped parser.
Register callback routes without altering existing `plezy://`/PlezyNG links.
Do not hardcode a development client ID as PlezyNG's registered production app.

### R04–R05: playback before broad UI

Use one small known cloud movie and one multi-episode job as initial fixtures.
Wire the file adapter's resolve into a typed player boundary. Preserve
`SourcePlayback` publication/listening paths while extracting common video
controls. Keep the existing `PlaybackSourceResolver` server branch as-is first,
then share the minimum session/chrome interface. Compare server start, seek,
external-player return, subtitle selection and stop reporting before/after.

Audit HTTP redirects in the actual native player implementations. A Dart
request policy is not proof of downstream enforcement. Add gateway handling
only for protocols actually supported and tested; unknown nested fetch paths
remain ineligible rather than bypassing the policy.

### R06–R09: discovery without duplication

Search for every `CatalogSourceId` switch, serialization field, map key and
`item.source` lookup. Migrate instance addressing throughout provider registry,
detail, Explore, search, watchlist chooser, logos and cached state. Retain a
separate brand key so UI assets do not require installation IDs.

Do not overwrite stored profiles on Stremio import. Reconcile installations by
profile and encrypted-transport fingerprint; preserve user order and disabled
state on repeated imports. Keep source-attributed saved-title entries even
when their canonical title matches, so disconnecting one provider does not
remove another provider's ownership. Normalized list membership and underlying
provider membership are different records.

Use local cloud filenames immediately and enrich on demand/inventory scan.
Reuse the existing standalone metadata client and local NFO/artwork precedence.
Do not require a new metadata API key just to play a file. Optional default
catalog presets must explicitly identify their provider; public catalogs do
not prove that a title has an available stream.

### R10–R12: acquisition and continuity

Implement an operation ledger before wiring “Prepare & play.” Cover request
timeout after the provider accepted the job, app crash between create/select,
double taps, another device creating the same hash, and pre-existing user jobs.
Do not run destructive orphan cleanup against a provider account. Source-level
automatic fallback never reuses authorization for a different acquisition type.

Map full file metadata before selecting episodes. Persist a selected-file
fingerprint and revalidate after re-resolution. Renewal must preserve exact
content identity, not merely obtain any new URL. For local downloads, update
both Dart lease eligibility and each actual native renewal callback. Existing
allowlists cover specific providers; adding a provider name without its secure
callback implementation is not background-download support.

Use the existing local progress journal/sync mechanism where it fits and add
acknowledgement mappings. Avoid a second timer writing the same playback state.
Connect canonical Continue Watching to existing server state with provenance;
never back-write cloud progress to unrelated server items by default.

### R13–R14: broader transport support

For each additional native service, obtain an endpoint contract, sanitize
fixtures and record auth/client-registration/limits before showing Connect.
Do not infer undocumented APIs from another provider. Generic Stremio HTTP
streams remain useful even where their remote resolver is not a native account.

Evaluate libtorrent and TorrentNG behind the same selected-file/range contract.
Record binary size, startup, seek responsiveness, memory/disk use, packaging
burden and lifecycle behavior. Prefer the implementation that meets the
contract with the least unqualified new code; no full engine rewrite is part
of the core adapter work. Do not claim native P2P for iOS/tvOS/webOS/Tizen from
a Linux-only test. Direct NNTP and generic multipart archive extraction are
separate future engines; R13 provides service/bridge routes and clear capability
handling for these stream forms.

### R15–R16: polish is part of completion

Use the existing translation generation/QA workflow and update provenance where
the repository requires it. Include helper text for every new setting; localize
states and recovery actions. Preserve themes, focus geometry and player button
density. Run semantic/focus tests and manually exercise mobile and TV layouts.
Do not put credentials, hashes or release names into user-visible logs/toasts.

Add a user guide under the repository's existing docs convention when actual
features ship; link it from in-app help and README. Keep this folder as the
design/evidence register. Mark each work package with implementation commit,
tests and target evidence rather than replacing the plan with “complete.”

## External inputs and how to keep work moving

| Input | Owner / action | Work that proceeds without it |
| --- | --- | --- |
| Real service test accounts | Owner supplies through local app sign-in; never commit credentials | All parsers, mocked flows, schemas, UI and fault injection |
| Premiumize production OAuth client | Maintainer registers redirect/client configuration | API-key path and device/PKCE fixture-backed implementation |
| Branded Real-Debrid client | Maintainer chooses registration versus documented open-source client | Provider adapter and generic device flow |
| Stremio QR/account interoperability | Maintainer performs a live link/import session | Generic add-on support, manifest import, account parser fixtures |
| Debrid-Link/Seedr/put.io detailed contracts | Obtain official schema/SDK evidence and account enablement as needed | Core four providers and generic file/add-on routes |
| Provider marks | Bundle verified official assets and record provenance | Generic current icon treatment with accessible labels |
| Apple/TV secure storage and packaged playback | Actual signed target builds/devices | Dart implementation and local deterministic tests |
| Native P2P engine qualification | Build engineers / target tests | Complete cloud and remote HTTP integration |

Live account and packaged-device evidence are unknown at planning time. They
must be listed honestly; they are not a reason to leave executable code
unfinished when synthetic fixtures can exercise it. Conversely, mocked success is
not a live-provider qualification result.

## Commit and handoff discipline

Commit each working package or coherent subpackage with its tests/docs. Push
frequently; do not hold an entire feature in scratch until the last turn. Read
the current remote head before writing and replay additive changes if it moved.
Never force-push, replace another agent's files wholesale, merge unrelated
branches, or enable Actions to validate this feature without authorization.

At handoff report the implemented slice, commits, remaining exact work, local
review steps and separately qualified targets. A provider adapter returning
empty lists, an “unsupported” implementation behind a visible Connect button,
a source route that opens a browser instead of the native player, or a parser
without an engine must not be reported as code-complete functionality.
