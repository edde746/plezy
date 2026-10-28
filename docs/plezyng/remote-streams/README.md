# Debrid, Stremio and remote streaming

Status (2026-10-28): the connected-stream feature is on
`codex/debrid-stremio-integration-20261028`. Native libtorrent playback and
source-build packaging, OS-scheduled provider preparation, and a persistent
cloud/server canonical library are implemented. The existing shared player
and mixed server/cloud/add-on episode queue remain the playback boundary.
See [COMPLETION.md](COMPLETION.md) for the code map, platform behavior and
measured verification. Packaged-device and live-account qualification remain
release gates; this status does not claim those checks have passed.

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
  spotlight Home now includes a compact focusable cloud row above the existing
  hub rail when indexed videos are available.
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
- When a Stremio result is launched from a server movie or episode, use the
  regular video player with that item's identity and existing queue, next-item
  flow, subtitle controls and PiP. Catalog-only streams also use that player
  and keep resume state source-local. Signed stream URLs and headers stay behind
  the session loopback gateway. Expired primary links get one single-flight
  re-resolution of the same add-on candidate or provider job. Resume offsets
  are durably queued for the owning server without sending an active “now
  playing” session for an external stream.
- Catalog-only episode queues use the same player queue, previous/next flow,
  and controls as server playback. Queue rows retain stable catalog identity;
  the next cloud lease or Stremio stream is re-resolved on advance, so expiring
  links and credentials do not enter queue metadata.
- Show a cloud-file result in that same “Watch with services” flow when the
  file already has matching external IDs plus a compatible title and year;
  episode files must also match the requested season and episode.
  Keep the match local and profile-scoped; preserve the matched server item and
  queue, and renew the same account/file lease after expiry.
- Find Next uses verified external IDs to avoid offering a cloud/source copy as
  a second recommendation when the same movie or exact episode is already in
  its bounded server sample. The selected server item remains the recommendation
  and keeps its normal details, queue, and source-choice actions.
- Keep provider credentials and add-on URLs encrypted and scoped to the active
  profile; use the shared video-player surface and source-local resume journal
  for unmatched catalog streams and standalone cloud files. The existing source
  player remains for multi-file source sessions and other file types.
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
Transient failures receive a capped retry with backoff. The existing streaming
settings queue can cancel local polling or manually retry an exhausted job
using its saved provider ID; cancellation leaves provider-side work untouched.
Android WorkManager and iOS BGProcessingTask resume saved provider jobs in
headless Flutter engines. Desktop installs a per-user Task Scheduler job,
launchd agent or systemd timer. Each worker reads encrypted state from SQLite
and acquires an expiring job claim, so a foreground retry and another process
cannot poll the same job concurrently. OS dispatch timing is discretionary.
TV targets and unavailable schedulers use the existing app-runtime recovery.
Jobs without a reusable provider ID still need a user action.

The existing Videos shelf now presents persistent canonical cards containing
both cloud and server copies. Exact typed external IDs and episode coordinates
join copies; aliases and old-card redirects survive restarts. Conflicting IDs
stay separate. Home, server library browsing and cloud indexing feed this graph,
and the existing source sheet opens the chosen copy without adding a top-level
navigation entry. Profile isolation and hidden libraries are respected.

Native peer playback is an explicit opt-in in existing streaming settings.
Eligible v1 magnet choices use pinned libtorrent sources through a private
loopback byte-range lease in the shared player. Playback owns peer traffic and
spool cleanup. Android, Apple, desktop, webOS and Tizen build/package hooks are
included; local single-file and multi-file transfer/seek tests pass. Signed
packages, background callbacks and TV focus/large-text behavior still require
the corresponding target hardware and toolchains.

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
| [COMPLETION.md](COMPLETION.md) | Implemented native transport, workers, persistent cards and current evidence |
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
| Implemented connected-source slice | Real-Debrid device sign-in, AllDebrid PIN sign-in, Premiumize/TorBox API-key validation; profile-scoped settings; on-demand cloud files and virtual sources; Stremio QR add-on import and manual manifest connection; Explore catalog/search and metadata; direct, hash, file-host and subtitle choices; shared video player for server-matched, catalog-only, local/offline and multi-file source playback; source-local resume; durable preparation checkpoints; cloud downloads with encrypted Android/iOS lease renewal; bounded Search/Videos shelf/Home poster integration with opt-in metadata |
| Implemented integration and release gates | Mixed server/cloud/Stremio queues, persistent canonical cards, OS-scheduled preparation and native P2P build hooks are present. Signed target builds, live provider accounts, OS callbacks, downloads and device behavior still require qualification |
| Ecosystem breadth | put.io, Debrid-Link and Seedr qualification; user-configured aggregators; seedboxes and Usenet bridges through the existing file/HTTP adapters; capability-aware downloads and casting |
| Native P2P | Pinned libtorrent 2.0.11 with Boost 1.86, verified-piece byte ranges, seek deadlines, quotas and playback-owned cleanup. Controlled single/multi-file transfer tests pass; packaged device testing remains |
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
not measured results. No live service credentials were used. Native transfer verification used a
locally generated fixture and a loopback-only seeder.

The repository's inspected workflows are manual/reusable, rather than triggered
by ordinary pushes. Preserve that policy. The owner requires private JIT runners
for any later authorized CI/build work; see [AGENTS.md](../../../AGENTS.md).
