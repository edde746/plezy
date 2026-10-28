# Debrid, Stremio and remote streaming

Status: initial remote-streaming implementation is on
`codex/debrid-stremio-integration-20261028`; the broader design below remains
the target. This implementation is not full native P2P or a merged cloud
library. See [IMPLEMENTATION.md](IMPLEMENTATION.md) for completed behavior and
the exact remaining packages.

Prepared 2026-10-27 (America/Regina). The planning baseline was inspected at
`a7b172b00ff437eb431fb5d3e7b8b758f4a5c422` on `main`.

## Current behavior

- Connect Real-Debrid or AllDebrid through a QR/code flow; connect Premiumize
  or TorBox with an API key.
- Open connected cloud accounts from the existing Files and books screen, in
  one nested Cloud & add-on streaming group. Browse ready video files with the
  focused list, refresh, and recover from empty or unavailable states without
  losing account setup.
- Install a Stremio-compatible add-on by manifest URL and fetch its stream
  options for a Plex/Jellyfin/Emby movie or episode detail.
- Play direct HTTP streams, select add-on subtitles, open explicit external
  links, or resolve supported hash/file-host candidates through a selected
  connected provider.
- Keep provider credentials and add-on URLs encrypted and scoped to the active
  profile; use the existing standalone video player and local resume journal.
  Unreadable saved settings remain intact until the user explicitly clears
  them to reconnect; a temporarily locked device uses a retry path.
- Read the authorization QR's service label and copy the activation code with
  assistive technology; use the Services/settings hub to manage connections.

Unified cloud-source records and poster rows in Libraries/Home/Search, Stremio catalogs and account
import, shared server player reporting, remote job management,
renewable/background leases and an embedded P2P engine are not part of this
implementation. Cloud inventory is fetched on demand and is not cached or
merged into catalog surfaces; Files and books shortcuts open the same
cloud-file browser.

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
   branch supports manifest and stream lookup only. Run no add-on
   JavaScript, Node server, downloaded executable or arbitrary script in the app.
3. Support configured manifest URLs and Stremio account import. The latter uses
   the first-party account/link protocol behind an isolated compatibility client;
   do not invent a public Stremio OAuth/PKCE contract.
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
| Implemented stream slice | Real-Debrid device sign-in, AllDebrid PIN sign-in, Premiumize/TorBox API-key validation; profile-scoped settings; on-demand cloud file browsing; Stremio manifest/stream requests; direct, hash, file-host and subtitle choices; existing standalone player and local resume |
| First useful vertical slice still needed | Unified cloud source rows, source metadata, durable identity, server-style player integration, profile teardown evidence and same-copy expired-link recovery |
| Core integration | Cloud catalog surfaces, Stremio catalogs/account import; shared Home/Explore/Search/details; source choice; preparation queue; next episode; all regression gates |
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
- Stremio import restores installed catalog choices and ordering, with a clear
  preview; one malformed add-on cannot invalidate the whole account.
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
**Moderate:** Stremio account-link compatibility outside its own clients;
cross-provider metadata matching; the proposed migration effort.
**Unknown until exercised:** live account behavior, startup latency, rate-limit
headroom, device secure storage, casting across networks, and native P2P on
each packaged target. Performance numbers in this handoff are test targets,
not measured results. No credentials were used and no transfers were started
while preparing the plan.

The repository's inspected workflows are manual/reusable, rather than triggered
by ordinary pushes. Preserve that policy. The owner requires private JIT runners
for any later authorized CI/build work; see [AGENTS.md](../../../AGENTS.md).
