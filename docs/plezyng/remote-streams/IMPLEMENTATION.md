# Luna implementation and remaining work register

This register tracks the feature branch
`codex/debrid-stremio-integration-20261028`. The working code includes connected
debrid accounts, Stremio account linking/catalogs/stream choices, virtual cloud
sources, a bounded cloud-video index and Home poster row, durable preparation
checkpoints, local downloads with encrypted mobile lease renewal, the source
player for standalone files, and shared native-video playback for provider
streams launched from a matched server library item. It does **not** complete
the full R01–R16 product plan: native P2P engine/package support and canonical
cloud/server library merging remain incomplete. Do not describe this branch as
publish-ready.

The owner requested implementation on a PR branch. Commit and push only to that
branch; do not dispatch GitHub Actions or use hosted runners. The repository
requires private ephemeral JIT runners for any later authorized build/CI work.

## Implemented on this branch

| Area | Current implementation | Scope limit |
| --- | --- | --- |
| Profile ownership and secrets | `RemoteStreamingProvider` follows `ActiveProfileProvider`; accounts, signed manifest URLs and descriptors are protected by `CredentialVault` in profile-scoped preferences. Browsed cloud file metadata uses the existing profile-scoped source index; signed playback links remain memory-only. Unreadable ciphertext is preserved until the user explicitly clears it. | Cloud inventory is fetched on demand and account credentials remain in the remote-stream store. OS keychain lock errors use the retry path; unrecoverable ciphertext loss requires explicit clearing and reconnect. |
| Connection setup | Real-Debrid device authorization and AllDebrid PIN flow use the shared QR/code dialog. Premiumize and TorBox API keys are validated with their account endpoints before encrypted save. | Premiumize uses API-key setup because PlezyNG does not yet have a registered OAuth client. TorBox device flow is not wired. |
| Stremio add-ons | HTTPS manifest validation, manual install, first-party QR account link and read-only installed-add-on import preview; catalog and stream resources, catalog search/paging, required catalog filters (including finite choice limits and free-text extras), title metadata, per-installation enable/remove, explicit manifest update check and confirmation, external links, HTTPS streams, hash/file index, request headers and subtitles. Both current per-extra `isRequired` declarations and legacy catalog-level `extraRequired` are recognized. Imported account keys are memory-only; imported manifest URLs are revalidated before encrypted profile save. Update review preserves installation identity and refuses a changed manifest ID. | Add-on configuration pages, account add-on ordering, background manifest checks, and native JavaScript add-ons are not implemented. HTTP add-ons require manual setup with explicit opt-in. |
| Playback | A Stremio candidate or verified matching cloud file launched from a Plex/Jellyfin/Emby movie or episode enters `VideoPlayerScreen` with the actual `MediaItem` identity. Cloud matching uses the existing local index, exact IMDb/TMDB/TVDB identity, compatible title/year and the user's opt-in online metadata; episode files also need the exact season and episode. No signed URL enters the index. The server player supplies its existing chrome, queue/next-item behavior, PiP, subtitle track UI and controls. An opaque loopback gateway keeps signed URIs and headers out of mpv; direct 401/403/410 renewal is single-flight and re-resolves the same add-on candidate, provider job or cloud file. Renewable HLS child references refresh their parent manifest and reuse the same ordinal only when its path still matches; duplicate playlist references keep independent renewal callbacks. Progress is written to the durable local watch queue and later reconciled as resume state, without opening a server “now playing” session for an external stream. | Catalog-only playback and standalone cloud files still use `SourcePlayback`/`SourcePlayerScreen`; they do not join the server queue. Cloud files are not merged into server library cards. HLS renewal, exact-reference behavior, casting and multiview have not been device-qualified. |
| Resolver services | Real-Debrid, AllDebrid, Premiumize and TorBox expose cloud files and supported v1 hash or file-host resolution. Torrent preparations persist provider job IDs/stages; profile restore reconciles every recoverable Real-Debrid, AllDebrid or TorBox job through a two-worker app-runtime queue. Users can stop local polling and retry from the existing streaming settings screen's queue. TorBox recovery follows the saved torrent ID and polls until its files are ready without creating a replacement. | This is not an OS-scheduled worker and can pause when the OS suspends the app. Cancel stops PlezyNG's local polling/retry; it does not cancel or delete provider-side work. Premiumize has no reusable provider job ID here. No v2 hash resolution or local P2P fallback. Provider APIs/live accounts are not qualified here. |
| Network boundary | Add-on request headers are bounded and validated, then held in memory behind the loopback media gateway. HTTP is opt-in per add-on. HLS children inherit headers only on the same origin; redirect policy prevents HTTPS downgrade and strips sensitive headers on cross-origin redirects. | Provider-specific DNS/IP egress blocking, DASH nested-resource handling and native-engine fetch auditing remain unqualified. |
| Downloads and cloud posters | Cloud files are downloadable through the existing Files and books flow. Android/iOS native tasks persist encrypted renewal recipes that reacquire the same provider item and validate file size/revision. Other targets use the existing app-managed transfer path. Bounded background indexing populates the existing Videos shelf, Search and non-TV Home cloud poster rail. Optional Trakt metadata matching is controlled by the existing privacy disclosure. | Native background task behavior and every provider endpoint need fixture/device qualification. The index is bounded/recent and not a complete universal catalog. Home TV spotlight does not show the cloud rail. Downloads remain local copies and do not imply provider-side deletion. |
| App integration | Existing Services, Explore, Search, Files and books, details, and player surfaces are reused. Each debrid account is a virtual source. Folder/file identities survive relaunch without persisting signed URLs. Source cards use the current poster cache and profile-local progress journal. Matched Stremio results and verified cloud-file matches can enter the server video queue under the server item's global key. Cloud external IDs are included in the existing bounded local source-search index. | Cloud and Plex/Jellyfin/Emby entries are not deduplicated into one canonical library card or source-agnostic identity record. Source-player sessions remain separate, and provider viewing does not create a false active-server playback session. |

Earlier branch work had focused service/provider/UI tests and analysis recorded
by its then-current implementation. The present working changes for durable
preparation, cloud renewal, poster indexing, and metadata opt-in have not been
run through Dart analysis, tests, or packaged builds in this turn. No live
account, provider playback, background transfer, or device behavior is
qualified. The repository requires private ephemeral JIT runners for any
authorized CI/build work; do not dispatch hosted CI.

## Start here

1. Read current `AGENTS.md` and inspect the feature branch before extending it.
2. Treat the following as the main remaining engineering packages: a qualified
   native P2P engine and target packaging; canonical cloud/server library
   matching and source presentation for cloud-file detail; TV Home cloud-row
   composition; renewable HLS child leases; and the required tests/device
   qualification.
3. Extend existing provider fixtures in
   `test/services/remote_streams/remote_cloud_paging_test.dart` and add focused
   tests for preparation recovery, same-file lease renewal, metadata consent,
   profile transitions, and download restoration. Keep live account secrets
   out of fixtures.
4. Do not turn the source inventory into an unbounded crawl or merge titles
   into server libraries without stable external identity evidence. Do not
   rewrite server clients or the whole player at once.

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
| `lib/services/remote_streams/remote_streaming_provider.dart` and `remote_stream_models.dart` | Profile-encrypted preparation journal, provider job checkpoint recovery and stable cloud file reacquisition |
| `lib/sources/content_access.dart` and `source_controller.dart` | Existing durable queue, encrypted provider-specific mobile lease renewal, bounded inventory warmup, and opt-in online metadata |
| `lib/screens/discovery/remote_cloud_home_rail.dart` and `source_widgets.dart` | Home poster rail and metadata-enriched source cards using existing cover cache, detail route and player |

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
| R04 | Real-Debrid vertical slice; R03 | Implemented: cloud adapter, paged files, targeted file mapping, same-copy resolution/renewal and source progress | Fixture-backed end-to-end play/resume and live qualification remain outstanding |
| R05 | Shared video presentation; R04 | Partial: Stremio streams and verified cloud-file matches launched from a uniquely matched server movie/episode use the existing video player, server queue and next-item behavior. Signed URLs/headers stay behind the loopback gateway; direct 401/403/410 lease renewal is single-flight, and renewable HLS children reacquire the same manifest reference only if its path remains unchanged. Cloud renewal reacquires the same account/file identity. Local durable progress syncs as a resume offset without server now-playing heartbeats. Catalog-only and standalone cloud files retain SourcePlayer. | Server and standalone regressions; queued local progress, remote subtitle/PiP/multiview, HLS renewal under changing live playlists, target renewal and lifecycle qualification remain |
| R06 | Dynamic catalog identity; R02 | Partial: one composite Stremio catalog source with per-item installation identity; broader dynamic source-key migration and episode capability | Two installations with identical manifest IDs coexist; legacy preferences still select correctly |
| R07 | Stremio protocol; R01/R06 | Partial: HTTPS manifest/catalog/meta/stream/subtitles, bounded search/paging, current and legacy required extras, existing filter-sheet UI and finite choice limits | Focused request/filter/paging tests pass; broader protocol corpus, account ordering, configured-prefix fixture breadth and timeout isolation remain |
| R08 | Stremio account import; R03/R07 | Partial: current first-party QR link, read-only descriptor fetch, secure selected-add-on preview; no Stremio auth key is persisted; optional history import is not included | Actual serialization fixtures; QR/sign-in live check; no remote collection/progress mutations |
| R09 | Identity and queries; R04/R06/R07 | Partial: profile/account/file identities, cached cloud rows in Search and Videos shelf, bounded Home rail, optional Trakt poster matching, and exact external-ID cloud availability matching from the existing service picker; episode matches require the cached season/episode identity too | Cloud files are not deduplicated into server library cards or shown in TV Spotlight; matching requires cached verified metadata; bounded warmup is not a complete catalog |
| R10 | Source selection and preparation; R05/R07/R09 | Partial: contextual provider selection, durable encrypted-store checkpoints, stage/status UI, cancelable local polling, and bounded app-runtime auto-reconciliation for saved Real-Debrid/AllDebrid/TorBox IDs, with capped retry/backoff after transient failures | No OS-scheduled worker; cancel does not stop or delete provider-side work. Premiumize has no reusable provider job ID in this flow; lost-POST idempotency needs provider-specific evidence |
| R11 | Remaining core providers; R03/R04/R10 | AllDebrid, Premiumize and TorBox using the same contracts | Provider-specific auth/envelope/file mapping/delayed/limit tests and account smoke evidence |
| R12 | Downloads, progress and sync; R05/R09/R10/R11 | Partial: cloud files use the existing local download queue; Android/iOS native callbacks hold encrypted service credentials and renew the same item; source-player progress stays profile-local; server-matched remote video writes resume updates to the durable watch queue without starting a server playback session | Provider fixture, process-death, task descriptor confidentiality, quota, remote player progress, and device qualification remain |
| R13 | Ecosystem adapters; R07/R11 | put.io/Debrid-Link/Seedr when contracts obtained; aggregator and file/Usenet-bridge fixtures | Per-provider capability matrix; unsupported fields produce actionable typed results |
| R14 | Native P2P; R05/R10 | Not implemented: choose and package a real bounded torrent engine behind a range-capable source adapter; add piece scheduling, quotas, lifecycle, and network policy | Controlled swarm playback/seek tests plus Android, iOS/tvOS, desktop, webOS and Tizen package evidence; no default P2P fallback |
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
