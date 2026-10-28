# Debrid, Stremio and remote streaming

Status: the connected-stream feature is on
`codex/debrid-stremio-integration-20261028`. The working tree now also includes
a durable cloud-file source, a bounded cloud-video index and Home poster row,
encrypted background download renewal, and a persisted debrid preparation
journal. The branch is not publish-ready: an embedded native P2P engine and
platform packaging are absent. Streams and verified cloud-file matches opened
from a server movie or episode use the shared video player and server queue;
catalog-only playback and standalone cloud files still use the separate
`SourcePlayback` player contract. External viewing queues local resume updates
without starting a false server now-playing session. See
[IMPLEMENTATION.md](IMPLEMENTATION.md) for the exact implementation and
qualification boundary.

Prepared 2026-10-27 (America/Regina). The planning baseline was inspected at
`a7b172b00ff437eb431fb5d3e7b8b758f4a5c422` on `main`.

## Current behavior

- Connect Real-Debrid or AllDebrid through a QR/code flow; connect Premiumize
  or TorBox with an API key.
- Link a Stremio account with its QR approval flow, preview installed
  add-ons, and select which secure HTTPS add-ons to import. PlezyNG does not
  ask for the Stremio password, persist the account authorization key, or
  change the remote add-on collection. Add-ons can also be connected by
  manifest URL.
- Open Files and books from the existing library picker or its single nested
  Libraries rail row. Connected accounts live together in the screen's Cloud
  & add-on streaming group. Browse ready video files with the focused list,
  load more from paged provider inventories, refresh, and recover from empty or
  unavailable states without losing account setup. Each linked account also
  appears as a virtual source in that same browser. Browsed video metadata is
  cached without signed URLs, searchable from Search, and reopened through the
  existing detail and player flow.
- Cached cloud videos appear in the existing Videos shelf and Search. Home gets
  a bounded Cloud files poster row after background indexing; Trakt title/year
  matching is opt-in under the existing online-metadata privacy control. TV's
  dedicated spotlight layout does not yet include this row.
- Browse supported Stremio add-on catalogs in the existing Explore source
  switcher; search catalogs and use each catalog's required choice or text
  filters from the existing View All filter sheet. Open installation-scoped
  title details without creating a new navigation destination.
- Check installed add-ons for manifest changes and review the proposed version
  before applying it. Updates keep the saved installation and enabled state;
  changed add-on identities require an explicit reinstall.
- Fetch add-on stream options for supported library and catalog movie/episode
  details, with show episodes listed and selectable inside the existing title
  detail screen.
- Play direct HTTP streams, select add-on subtitles, open explicit external
  links, or resolve supported hash/file-host candidates through a selected
  connected provider.
- When a Stremio result is launched from a uniquely matched server movie or
  episode, use the regular video player and its existing queue, next-item
  flow, subtitle controls and PiP. Signed stream URLs and headers stay behind
  the session loopback gateway. Expired primary links get one single-flight
  re-resolution of the same add-on candidate or provider job. Resume offsets
  are durably queued for the owning server without sending an active “now
  playing” session for an external stream.
- Show a cloud-file result in that same “Watch with services” flow when the
  file already has matching external IDs plus a compatible title and year.
  Keep the match local and profile-scoped; play it in the server queue when
  that server is online and renew the same account/file lease after expiry.
- Keep provider credentials and add-on URLs encrypted and scoped to the active
  profile; use the existing source-player surface and local resume journal for
  catalog-only playback and standalone cloud files.
  Unreadable saved settings remain intact until the user explicitly clears
  them to reconnect; a temporarily locked device uses a retry path.
- Read the authorization QR's service label and copy the activation code with
  assistive technology; use the Services/settings hub to manage connections.

Cloud inventory is browsed on demand and warmed through a bounded background
index; signed playback URLs remain memory-only. Eligible files use the existing
durable Downloads queue. Android/iOS native transfers store an encrypted
provider recipe and request the same provider file again after link expiry.
Torrent preparation jobs persist non-secret provider checkpoints and
automatically reconcile every recoverable job after profile restore, outside
the stream picker, with at most two jobs running concurrently. Recovery reuses
saved provider job identities and never stores a signed stream URL. TorBox
recovery polls the saved torrent ID and does not create a replacement.
Transient failures receive a capped retry with backoff. The queue is cancelable
from the existing streaming settings screen; cancel stops local polling and
retries but leaves provider-side work untouched. Recovery runs in the app
runtime, so OS suspension can pause it; this is not an OS-scheduled background
worker, and jobs without a reusable provider ID still need a user action. A
Stremio choice from a matched server item now uses
the normal video player and queue, with resume offsets reconciled through the
existing watch queue. This does not merge cloud files into server library
cards or make the standalone source player queue-aware. Preparation remains
app-runtime work, not an always-running OS worker. A native torrent engine
and platform P2P packages are absent. Home's cloud poster row is not currently
shown in the dedicated TV spotlight composition.

## Target experience after full completion

Connect a service, authorize it in a browser or with a QR code, and return to
populated PlezyNG screens. Movies remain movies; episodes remain episodes.
Cloud files, add-on catalogs and existing Plex/Jellyfin/Emby copies contribute
to the same browsing experience. Press Play to use the best eligible source;
open the adjacent source control when a choice matters.

The product concept is **connected sources**, not another app inside PlezyNG.
Keep Home, Libraries, Explore, Search, Downloads, Find Next, details, profiles
and the existing player. Add service management and contextual source choices
inside these surfaces. Do not create a Debrid or Stremio navigation tab.

Debrid authentication alone can reveal the account's existing files and jobs.
It does not provide a universal movie catalog or discover every title's links.
Stremio-compatible add-ons supply those discovery and stream-resolution
capabilities. Treat that separation explicitly in code and explain it with one
help sentence at setup, rather than requiring users to learn the architecture.

## Reading order

| Document | Purpose |
| --- | --- |
| [PROVIDERS.md](PROVIDERS.md) | Current primary-source research, ecosystem coverage, provider protocols and unknowns |
| [UX.md](UX.md) | Screen integration, setup journeys, defaults, copy, focus and accessibility |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Repository integration, identities, persistence, resolution, playback, security and efficiency |
| [IMPLEMENTATION.md](IMPLEMENTATION.md) | Ordered work packages, concrete file changes, migration and Luna instructions |
| [VALIDATION.md](VALIDATION.md) | Behavioral acceptance cases, platform coverage and evidence required for completion |

## Decisions

1. Implement Real-Debrid, AllDebrid, Premiumize and TorBox as native account,
   cloud-library and resolution adapters. Use each service's actual auth flow.
   The current branch has account, supported stream-resolution paths, and
   on-demand video-file browsing, but not a unified cloud catalog.
2. Implement the Stremio HTTP add-on protocol as a data adapter. The current
   branch supports manifests, catalogs, search/paging, metadata and streams.
   Run no add-on JavaScript, Node server, downloaded executable or arbitrary
   script in the app.
3. Support configured manifest URLs and read-only Stremio account add-on import.
   The latter uses the first-party account/link protocol behind an isolated
   compatibility client; do not invent a public Stremio OAuth/PKCE contract.
4. Preserve configured add-ons. Native debrid credentials resolve raw candidates
   locally; they are never automatically copied into third-party add-on URLs.
5. Separate catalog identity, playable copies and ephemeral playback leases.
   One logical title can have several copies without duplicate resume cards.
6. Extend the current catalog and source abstractions. Never implement a fake
   Plex server or add dozens of unsupported methods to `MediaServerClient`.
7. Bring remote video into the same player chrome, queue, subtitle, picture,
   PiP and multiview contracts. Sharing the decoder alone is insufficient.
8. Prefer existing/offline copies and ready remote sources. Remote preparation
   is visible and cancellable; browsing never creates provider download jobs.
9. Native P2P is a separately qualified transport, disabled by default. A cloud
   failure never silently switches to a local swarm. Remote HTTP/cloud viewing
   is useful independently of an embedded torrent engine.
10. Preserve profile isolation, PIN gates, source visibility, localization,
    source-specific limits, and existing server progress-reporting behavior.
11. No PlezyNG-hosted stream proxy or credential service is required for the core
    feature. Optional companion input and user-owned bridges remain optional.
12. Commit implementation in coherent checkpoints on the owner-authorized PR
    branch. Do not dispatch CI or use hosted runners without authorization.

## Delivery scope

| Completion level | Required outcome |
| --- | --- |
| Implemented connected-source slice | Real-Debrid device sign-in, AllDebrid PIN sign-in, Premiumize/TorBox API-key validation; profile-scoped settings; on-demand cloud files and virtual sources; Stremio QR add-on import and manual manifest connection; Explore catalog/search and metadata; direct, hash, file-host and subtitle choices; source player and local resume; durable preparation checkpoints; cloud downloads with encrypted Android/iOS lease renewal; bounded Search/Videos shelf/Home poster integration with opt-in metadata |
| Remaining core integration | Shared server/source player queue and chrome, canonical media identity and matching into server Libraries, TV spotlight composition, autonomous preparation polling/cancellation, and all regression gates; Stremio catalog/account, provider APIs, downloads, and background callbacks still need fixture, live, and device qualification |
| Ecosystem breadth | put.io, Debrid-Link and Seedr qualification; user-configured aggregators; seedboxes and Usenet bridges through the existing file/HTTP adapters; capability-aware downloads and casting |
| Native P2P | An actual bounded streaming engine, byte-range bridge, seek scheduling, native builds and device tests; a `magnet:` parser is not completion |
| Full handoff scope | All preceding work packages either implemented and evidenced, or explicitly recorded with the exact external credential/device/API dependency; no placeholder success states |

Core clients target Windows, Linux, macOS, Android/mobile and Android TV,
iOS and tvOS. webOS and Tizen use the same Dart architecture but require
separate secure-storage, network and player qualification. A browser build is
not presumed to exist or inherit native playback/CORS capabilities.

## What makes this feel effortless

- A connected cloud account immediately gains a library in the existing picker.
  First results appear incrementally; enrichment continues without blocking use.
- Stremio import previews installed add-ons and imports selected HTTPS entries;
  one malformed add-on cannot invalidate the rest of the account collection.
- A title detail page offers one primary Play/Resume action and one compact
  Sources action, rather than a wall of filenames.
- Provider expiry, queueing and missing files have specific recovery actions.
  The user stays on the title they selected throughout recovery.
- Search, Find Next, Continue Watching and next-episode playback work across
  source families with deterministic identity and eligibility rules.
- Advanced settings appear only where useful. Every setting has a short
  explanation; provider internals remain in diagnostics.

## Confidence and evidence boundary

**High:** the architectural fit and the repository gaps identified here; the
documented core-provider and Stremio add-on interfaces cited in PROVIDERS.
**Moderate:** live Stremio account-link compatibility outside its own clients;
cross-provider metadata matching; the proposed migration effort.
**Unknown until exercised:** live account behavior, startup latency, rate-limit
headroom, device secure storage, casting across networks, and native P2P on
each packaged target. Performance numbers in this handoff are test targets,
not measured results. No credentials were used and no transfers were started
while preparing the plan.

The repository's inspected workflows are manual/reusable, rather than triggered
by ordinary pushes. Preserve that policy. The owner requires private JIT runners
for any later authorized CI/build work; see [AGENTS.md](../../../AGENTS.md).
