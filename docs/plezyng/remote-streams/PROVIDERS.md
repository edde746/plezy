# Provider research and adapter requirements

Research date: 2026-10-27. Statements under **Observed** summarize the linked
primary source. The remaining behavior is PlezyNG's proposed design. Public
documentation is evidence of an interface, not a successful account test.

## Ecosystem map

| Family | Examples | Role in PlezyNG | Delivery route |
| --- | --- | --- | --- |
| Debrid / cloud transfer | Real-Debrid, AllDebrid, Premiumize, TorBox | Account files, jobs, host-link resolution, torrent-to-HTTP resolution | Four native adapters |
| Catalog and stream protocol | Stremio-compatible add-ons | Catalogs, metadata, candidate streams, subtitles | Generic HTTP protocol client |
| Add-on aggregators | AIOStreams, Comet, MediaFusion, Torrentio configurations | User-selected discovery/resolution endpoints | Import configured manifest; qualify each returned stream form |
| Cloud seedbox services | put.io, Seedr, Debrid-Link | Persistent files and transfer lifecycle | Native adapters after contract qualification; existing file protocol where supported |
| Personal seedbox / NAS / mount | WebDAV, SFTP, SMB, HTTPS, S3 | Browse and play existing files | Reuse existing sources; no duplicate network stack |
| Indexers / automation | Prowlarr, Jackett, Torznab, Newznab, NZBHydra2 | Search candidates; they are not players or universal content catalogs | User-owned add-on/bridge first; direct indexer client is an optional later capability |
| Usenet / archive streaming | TorBox capability, AIOStreams, NzbDAV, AltMount | Provider or bridge supplies seekable HTTP/file access | Resolve on selected service; native NNTP/archive engines are a separate transport project |
| Local swarm streaming | BitTorrent v1/v2; engine implementation to qualify | On-device acquisition and seekable byte stream | Optional native P2P work package |
| Other cloud resolvers | Offcloud, EasyDebrid, Debrider, PikPak and similar | Additional accounts or already-resolved add-on streams | Generic add-on coverage first; never advertise an untested native adapter |

Examples identify compatibility targets, not bundled endorsements, automatic
installations, guaranteed availability or a claim that every endpoint implements
the entire protocol. Verify manifest capabilities per installation.

## Native provider contracts

### Real-Debrid

**Observed — high confidence:** [official API](https://api.real-debrid.com/)
documents the open-source device flow: request `/oauth/v2/device/code` with
`new_credentials=yes`, poll `/device/credentials`, then exchange the device
code at `/token` using the returned user-bound client credentials and the
documented device grant. Store the refresh token and user-bound credentials.
REST methods include `/user`, `/torrents`, `/torrents/info/{id}`,
`/torrents/addMagnet`, `/torrents/selectFiles/{id}`, `/downloads`, and
`/unrestrict/link`. Bearer authentication is supported. The current page does
not document `instantAvailability`; do not depend on it. The documented ceiling
is 250 requests/minute, including refused calls. The documented open-source
client ID is available; a PlezyNG registration can provide distinct branding.
The `/torrents` list accepts `offset` and `limit`; the cloud browser requests
bounded 100-item pages and lets the user continue explicitly.

**Adapter design:** provide cloud inventory plus selected-link resolution.
Keep the original provider file ID, hash, normalized relative path and size.
On Play, reuse the correct account job when possible, otherwise create exactly
one operation, fetch metadata, select only the intended files, and resolve the
resulting host link. A Stremio zero-based file index must never be passed as a
Real-Debrid file ID. Verify mapping by metadata ordering/path/size; request a
file choice when ambiguous. Do not mutate a pre-existing user's file selection
to satisfy a different playback request. Use a separate app-owned operation
where the service permits it, or surface the conflict.

Unknown cache status remains unknown. Do not add/delete torrents to simulate a
read-only cache probe. Do not enable remote-traffic options automatically.
Disconnect removes local authorization; it does not delete account files.

### AllDebrid

**Observed — high confidence:** [official API](https://docs.alldebrid.com/)
documents `/v4.1/pin/get`, `/v4/pin/check`, and bearer API keys. The PIN response
contains a user URL and expiry. Inventory/resolution uses `/v4/user`,
`/v4/user/links`, `/v4/user/history`, `/v4/magnet/upload`,
`/v4.1/magnet/status`, `/v4/magnet/files`, `/v4/link/unlock`, and
`/v4/link/delayed`. Status has a documented live/delta mode. The current page
does not list an instant-cache endpoint. API responses have their own
success/error envelope as well as HTTP status.

**Adapter design:** turn PIN auth into the common connection session, not a
fake OAuth refresh flow. Use a bounded inventory snapshot and delta updates
while the queue is visible. Persist the delta cursor only after applying the
page transactionally; a full-sync indication rebuilds that provider snapshot.
Traverse nested file trees lazily. A delayed link becomes a preparation job
with Retry/Cancel, not a media URL. Reauthorization and provider verification
are separate states. Never retry an authentication failure as a download error.

### Premiumize

**Observed — high confidence:** [official API](https://www.premiumize.me/api)
documents bearer API keys, OAuth authorization code with PKCE, and device-code
authorization. A registered client is required for OAuth. The device protocol
uses `POST /token` with `response_type=device_code`, then
`grant_type=device_code` and `code`. Files/folders, transfers and
`/api/cache/check` are documented. `/api/transfer/directdl` returns a content
list; use each entry's `link`. The docs identify `stream_link` and
`transcode_status` as legacy, and describe transcoding infrastructure as retired.
Business errors can arrive in HTTP 200 responses.

**Adapter design:** use PKCE on personal devices and device-code on TV; offer
API-key entry when a registered PlezyNG client is unavailable. Do not ship a
confidential client secret. Model fairness/quota exhaustion independently from
expired credentials. A cache hit is a short-lived observation, not a guarantee
that a particular episode is selectable. Default to existing cloud files;
choose direct resolution versus saved transfer from an explicit preparation
policy. Treat multiple returned files as a selection problem. Infer no
transcode capability from legacy response fields.

### TorBox

**Observed — high confidence:** [OpenAPI](https://api.torbox.app/openapi.json)
lists `/v1/api/user/auth/device/start` and `/auth/device/token` under the user
namespace. Device responses distinguish pending, expired and already-collected
codes. The [main API reference](https://api-docs.torbox.app/) documents bearer
keys, torrents, web downloads and Usenet. Torrent methods include `mylist`,
`checkcached`, `createtorrent`, `controltorrent`, `requestdl`. The inspected
OpenAPI requires a query `token` for `requestdl`: do not assume every endpoint
accepts header-only auth. `mylist` accepts `offset` and `limit`; the cloud
browser requests bounded 100-item pages and lets the user continue explicitly.
[Official WebDAV help](https://support.torbox.app/en/articles/14662867-torbox-webdav)
supports API-key credentials and describes a 15-minute refresh interval;
deleting one WebDAV file can delete its whole underlying item.

**Adapter design:** primary setup is provider device/QR auth, with API key as
fallback. Choose the native API for fresh inventory/job state and WebDAV only
as an alternate browsing preset. Keep token-bearing link requests inside the
redacted adapter; request a JSON URL response and do not hand an API-key URL to
the player. Preserve the native file ID. Use entitlement-derived torrent,
web-download and Usenet capabilities, never a hardcoded premium-plan guess.
Never implement generic file deletion through the TorBox WebDAV preset.

## Common adapter behavior

Implement one capability descriptor per account: auth methods, browse/search,
host-link resolution, torrent submission, cache observation, file selection,
Usenet submission, job cancellation, native download renewal and remote delete.
Each capability can be supported, unavailable, or unknown with an evidence
timestamp. Provider errors may lower a capability for the session; an unknown
response must not accidentally enable it.

Each adapter implements read-only inventory/search separately from mutation.
For any mutation whose response is lost, reconcile by provider object identity
before retrying. A local operation key alone cannot make a remote non-idempotent
POST safe. Account disconnect, local hide, remove from watchlist, cancel job,
delete cloud object and delete offline file are distinct operations.

Keep documented provider ceilings in adapter policy and central scheduling.
Do not copy a stale universal quota from another client. Start below ceilings,
honor Retry-After and structured business errors, share the budget across
catalog, queue and playback work, and expose a reconnect or wait action.

## Stremio add-on compatibility

**Observed — high confidence:** the [protocol](https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/protocol.md)
uses a manifest and resource URLs. The [manifest contract](https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md)
declares resources, types, catalogs and filtering. The
[resource guide](https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/README.md)
defines catalog/meta/stream/subtitle roles and resource dispatch. The
[metadata contract](https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/meta.md)
includes videos/episodes and presentation metadata. Implement the protocol in
Dart; the JavaScript SDK is for serving add-ons and is not a client dependency.

Preserve a configured manifest's path prefix and secret parameters in encrypted
storage. Do not reconstruct it from the hostname. Validate route encoding with
identifiers containing colons, slashes, Unicode, spaces, `&`, `%` and `=`.
Support string and object resource declarations; resource-specific type/ID
filters override only as specified. Honor required `extra` fields, search,
skip and genre independently. Required-search catalogs do not become Home rows.
Fetch only applicable resources and give each installation an independent
deadline and error boundary.

Translate `skip` pagination only for catalogs that declare it; preserve opaque
provider cursors where present. Bound repeated/empty pages so an add-on cannot
create an endless fetch loop. Apply supported response cache hints only within
the app's maximum TTL and privacy policy. A `notWebReady` hint is not proof that
a native player cannot play the stream, and its absence is not proof that a
browser can. Hash/size/filename hints may assist subtitles and matching but
cannot override verified file metadata. Normalize supported torrent hash forms
before comparing them; do not claim v2 support from a v1-only resolver.

Dynamic catalog IDs are local to the installation. Ordering is preserved across
refresh; an add-on cannot reorder the user's Home. `addon_catalog` can suggest
installations but cannot install them recursively. An update adding new host
access, configuration or resource families must be reviewed in connection
settings before those new privileges activate.

**Observed stream forms:** the [stream contract](https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/stream.md)
includes direct `url`, `infoHash`/`fileIdx`, `ytId`, `externalUrl`, subtitles,
`bingeGroup`, `proxyHeaders`, and newer NZB/archive forms including `nzbUrl`,
`servers`, archive URL lists and `fileMustInclude`.

| Input | Proposed handling |
| --- | --- |
| Direct HTTP(S) URL | Validate and acquire an ephemeral lease; headers stay bound to the intended origin |
| Torrent hash plus file index | Native debrid resolver; local P2P only when enabled and supported |
| Opaque external identity | Retain namespace; request metadata/streams from matching installations |
| `bingeGroup` | Continuity preference scoped to installation; never bypass identity or capability checks |
| `proxyHeaders` | Narrow request-header policy; never apply arbitrary response headers to PlezyNG's HTTP server |
| Subtitle URL | Bounded validated fetch, subtitle-specific origin policy, then existing subtitle controls |
| `externalUrl` | Explicit external action with a different icon; never call it in-app playback |
| `ytId` | Use an existing qualified YouTube route if present; otherwise show external action |
| NZB plus NNTP servers | Use an explicitly configured remote provider/bridge; keep server credentials secret; unsupported locally until its engine package exists |
| Archive URL lists | Remote prepared-file bridge first; no arbitrary local extraction during Play |
| `fileMustInclude` | Treat as untrusted input; use a bounded linear-time matcher or reject unsupported expressions |
| Other schemes / ambiguous payload | Typed unsupported result; never pass raw input to mpv or a shell |

Compatibility is a tested matrix of fields and transports, not “all Stremio
add-ons work.” Add-on labels, cached badges and advertised HDR are untrusted
claims until corroborated. Status/error videos returned as ordinary URLs need
provider-specific recognition where available; do not scrobble them as a title.

## Stremio account import and QR linking

**Observed — high confidence in source, moderate in third-party interoperability:**
first-party [request types](https://github.com/Stremio/stremio-core/blob/719ac32f9ab63c8b29fb7466935936cc946f1b33/src/types/api/request.rs),
[response types](https://github.com/Stremio/stremio-core/blob/719ac32f9ab63c8b29fb7466935936cc946f1b33/src/types/api/response.rs),
[URL construction](https://github.com/Stremio/stremio-core/blob/719ac32f9ab63c8b29fb7466935936cc946f1b33/src/types/api/fetch_api.rs),
and [constants](https://github.com/Stremio/stremio-core/blob/719ac32f9ab63c8b29fb7466935936cc946f1b33/src/constants.rs)
define `api.strem.io/api/login`, `addonCollectionGet`, datastore operations,
and `link.stremio.com/api/create` / `api/read`. Link responses contain code,
link, QR information and ultimately an auth key. This is first-party application
protocol evidence, not a published external OAuth specification.

Build `StremioAccountClient` separately from `StremioAddonClient`. Use verified
upstream serialization fixtures, including request tags and response envelopes.
Qualify QR linking first with an owner account. Generate the QR locally from a
validated first-party link rather than loading a remote QR image. Bound polling
and cancellation; the source schema does not establish a universal expiry or
poll interval, so confirm behavior before advertising automatic renewal.

Fallbacks: direct sign-in sent only to the pinned first-party endpoint, with
password retained only during the request; or import configured manifests
without a Stremio account. Social-login-only accounts use verified linking or
manifest import, not password guesses or browser-storage scraping.

Default to a one-time, read-only import: fetch installed descriptors and order,
validate each independently, show the summary, and save selected installations.
Offer saved titles and resume import as a separate selected option after the
datastore schema is qualified. Keep the auth key only if “Keep connected” is
selected; it has account authority beyond catalog access and belongs in the
vault. A discarded session must not invoke a global account logout blindly.
Never call `addonCollectionSet` or write progress back during import. Future
sync is opt-in and requires conflict/tombstone semantics, not snapshot overwrite.

## Broader services and bridges

- **put.io:** its [official SDK](https://github.com/putdotio/putio-sdk-typescript)
  exposes auth/device/OOB helpers, files, transfers and app-specific passwords.
  Its [help center](https://help.put.io/en/articles/1559158-do-you-have-an-api-documentation)
  points to the API reference, which was not retrievable in this research
  session. Implement from pinned SDK/schema evidence after verifying the native
  client flow. Do not ship a confidential OAuth secret. Until qualified, use a
  configured file source or existing add-on route. Confidence: moderate.
- **Seedr:** [official integration information](https://www.app.seedr.cc/products/integrations/)
  describes API, OAuth and file-protocol access; [support guidance](https://support.seedr.cc/pulse/articles/69205dfe119627033a392909-seedr-api-more-accessible/)
  describes account enablement. Confirm current access requirements and obtain
  the actual contract before implementing a native preset. Confidence: moderate.
- **Debrid-Link:** the [official device page](https://debrid-link.com/device)
  exists, but the endpoint contract was not retrievable. Add a research/fixture
  task, not an adapter filled with inferred URLs. Confidence: unknown for exact
  native protocol; generic configured-add-on use remains independent.
- **Offcloud:** [official API documentation](https://github.com/Offcloud/offcloud-api)
  describes key authentication and remote/cloud operations. Treat it as a later
  native qualification target; validate current service/API behavior before
  committing to a preset. Confidence: moderate in documented interface only.
- **AIOStreams:** the [project documentation](https://github.com/Viren070/AIOStreams)
  describes aggregation of catalogs, streams, services and Usenet bridges.
  Preserve its configured manifest and candidate order by default. Avoid
  querying both an aggregator and all its underlying add-ons unless the user
  explicitly enabled both; otherwise duplicate discovery and quotas multiply.
- **Comet:** its [maintainer documentation](https://github.com/g0ldyy/comet)
  describes add-on resolution, account-library lookup and indexer integrations.
  Support it through protocol fixtures. Do not replicate its scraper network
  inside PlezyNG or use a proxy to evade an account's IP/concurrency limits.
- **Seedboxes and Usenet bridges:** present existing WebDAV/SFTP/HTTPS sources
  with useful presets only after verifying their actual auth and file semantics.
  A bridge can make a native-unavailable transport playable without embedding a
  second runtime. PlezyNG does not auto-deploy or discover arbitrary LAN services.

## Native P2P engineering direction

[libtorrent's streaming documentation](https://www.libtorrent.org/streaming.html)
distinguishes piece-deadline scheduling from simple sequential download.
Use it as the reference implementation candidate. Evaluate the organization's
TorrentNG engine against the same measurable contract before choosing reuse;
this research did not inspect or qualify TorrentNG's streaming API.

The chosen engine must support metadata acquisition, correct file selection,
verified piece reads, seek reprioritization, bounded memory/disk, cancellation,
session teardown, network-interface policy and packaged native builds. A local
HTTP bridge exposes only an opaque selected-file capability, never a torrent
directory. Reject path traversal, symlink escapes, oversized metadata and
malicious trackers; preserve private-torrent discovery semantics. Do not derive
a private/public decision from a hash alone. If metadata/privacy is unknown,
do not silently enable DHT or PEX. Add explicit transport preferences and test
them, including resume after sleep and network changes.

Seeding lifetime is a visible setting. Playback stop releases its demand;
background seeding occurs only if expressly enabled and supported on the target.
Cloud streaming continues to work when this engine is absent.
