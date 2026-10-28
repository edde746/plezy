# Luna implementation work packages

Every package below is planned, not implemented by this documentation commit.
Work sequentially through dependencies and commit coherent checkpoints to the
owner-authorized branch. For this request that branch is `main`; preserve
concurrent changes, use fast-forward updates, and do not create a PR or dispatch
CI. Local validation remains part of implementation. Future CI/build execution
must follow the repository's private-JIT policy.

## Start here

1. Read this folder and current `AGENTS.md`; inspect `main` again. The planning
   baseline is recorded in README, but current code is authoritative.
2. Find current profile-binding, startup, source, catalog, playback, download,
   PiP and multiview tests before editing. Use existing dependency injection,
   HTTP factories, clock and platform abstractions.
3. Establish a provider fixture harness using synthetic public test media and
   sanitized captured protocol shapes. Keep live accounts out of unit tests.
4. Build the Real-Debrid cloud vertical slice before generalizing every screen.
   Prove connection → inventory → metadata → playback → resume → teardown.
5. Generalize only the boundaries that this slice and the Stremio fixtures
   require. Do not rewrite server clients or the entire player at once.

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
| R06 | Dynamic catalog identity; R02 | CatalogSourceKey migration, per-installation providers, built-in compatibility, episode capability | Two installations with identical manifest IDs coexist; legacy preferences still select correctly |
| R07 | Stremio protocol; R01/R06 | Manifest/catalog/meta/stream/subtitles, extras, ordering, partial errors and encrypted transport URLs | Protocol compatibility corpus, configured-prefix routing and timeout isolation pass |
| R08 | Stremio account import; R03/R07 | Isolated QR/account client, read-only import preview, idempotent descriptors, optional qualified history import | Actual serialization fixtures; QR/sign-in live check; no remote collection/progress mutations |
| R09 | Identity and queries; R04/R06/R07 | Identity/copy index, progressive Search/Home/Libraries/Explore projections, manual match/undo | Duplicate and conflicting-ID cases; cloud-only cold start; no forced Plex sign-in |
| R10 | Source selection and preparation; R05/R07/R09 | Adaptive source sheet, ranking, explicit preparation authority, durable queue/reconciliation | Lost-POST response cannot duplicate work; episode packs select correctly; unknown cache is truthful |
| R11 | Remaining core providers; R03/R04/R10 | AllDebrid, Premiumize and TorBox using the same contracts | Provider-specific auth/envelope/file mapping/delayed/limit tests and account smoke evidence |
| R12 | Downloads, progress and sync; R05/R09/R10/R11 | Shared queue presentation, qualified background renewal, one progress writer, tracker acknowledgements | Process-death/renewal/quota tests; existing sync unchanged; no plaintext native task descriptors |
| R13 | Ecosystem adapters; R07/R11 | put.io/Debrid-Link/Seedr when contracts obtained; aggregator and file/Usenet-bridge fixtures | Per-provider capability matrix; unsupported fields produce actionable typed results |
| R14 | Native P2P; R05/R10 | Engine selection evidence, native bridge, piece scheduling, quotas, lifecycle, packaging | Controlled swarm playback/seek tests and real target evidence; no default P2P fallback |
| R15 | Complete UX integration; R08/R09/R10/R12 | Find Next, existing version/quality sheet, source visibility, help, localization and accessibility | Cross-surface profile gating; D-pad/RTL/large-text checks; zero duplicate settings stores |
| R16 | Full qualification and docs; preceding packages | Completed validation matrix, setup/troubleshooting guide, changelog/README feature entry, measured budgets | Exact commit/build/target results and explicitly enumerated external dependencies |

R06/R07 can be developed after the initial vertical slice without waiting for
every native adapter. R14 does not block useful cloud/add-on delivery, but must
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

At handoff report completed package IDs, commits, remaining exact work, local
test results and separately qualified targets. A provider adapter returning
empty lists, an “unsupported” implementation behind a visible Connect button,
a source route that opens a browser instead of the native player, or a parser
without an engine must not be reported as code-complete functionality.
