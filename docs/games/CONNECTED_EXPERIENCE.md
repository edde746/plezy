# Connected games implementation ledger

This is the review ledger for the connected Steam / GameStream experience.
The product remains PlezyNG: existing poster geometry, theme tokens, focus,
adaptive menus, profile boundaries and Multiview ownership apply to games.
Steam identity, game ownership, a computer's inventory and a live streaming
session are separate facts. No API response, discovery packet or saved
shortcut establishes entitlement, authentication, reachability or playback.

## Scope and acceptance

The complete requested scope is tracked below. A checked item means implemented
and verified by the evidence linked in this document; design, an interface or
an unavailable capability alone does not count as an implementation.

- [ ] One canonical library for Steam account entries and computer routes;
      migrate existing favorites/recents without merging unrelated shortcuts.
- [ ] One accessible poster grid, search, details, actions and connections UI;
      source attribution, theme inheritance, RTL and controller/keyboard focus.
- [ ] Profile-scoped preferred routes; explicit availability and action states;
      host discovery retains useful hints without treating them as trust.
- [ ] Catalog refresh independently of OpenID; played free games; bounded cache,
      actionable failure reasons, disconnect and account-switch isolation.
- [ ] Host inventory through authenticated, capability-negotiated connections;
      optional desktop library sharing with narrowly scoped permissions.
- [ ] Steam metadata, achievements and news; privacy-respecting social context;
      safe community/store/workshop destinations and explicit browser consent.
- [ ] Session state and first-frame evidence; recents only after connection;
      reconnect and disconnect distinct from quit; release held input reliably.
- [ ] Fullscreen and Multiview share session lifetime; independent audio/input
      ownership; view recreation and profile retirement cancel safely.
- [ ] Adaptive streaming presets with negotiated metrics; explicit codec,
      resolution, bitrate and latency preferences; bounded resource budgets.
- [ ] Direct GPU Pyrowave presentation and measured fallback; capability-gated
      4:4:4, HDR, higher resolutions, surround and multiple controllers.
- [ ] Linux / SteamOS, Windows, macOS, iOS / iPadOS / tvOS embedded receivers;
      safe browsing and capability behavior on webOS / Tizen / other targets.
- [ ] Steam Input glyphs and remapping, keyboard/IME and accessible touch
      controls; Together / host overlay affordances without pretending the
      Steamworks game-side API is a general-purpose receiver API.
- [ ] Host-authoritative install, cloud conflict and family-availability states;
      LAN transfer assistance and captures where authenticated host APIs allow.
- [ ] Versioned companion remote game launch and session actions with explicit
      permission; high-rate controller input stays on the streaming transport.
- [ ] Internet connection diagnostics, authenticated signaling, NAT traversal
      and relay deployment; no dependence on ungranted Valve SDR access.
- [ ] Threat model, compatibility/migration tests, platform build evidence,
      performance measurements and real-device accessibility qualification.

## Architecture

`Game identity -> host routes -> capability/preflight -> session -> views`.
Steam AppIDs identify Steam games. Computer-local shortcut IDs remain scoped
to their computer/protocol. A Steam game can be streamed using GameStream;
source branding and transport branding must not be conflated. Route preference
is a preference, never a claim that the preferred computer is online.

Catalog browsing must work independently of embedded receiver support. Missing
native channels return unavailable capabilities without an exception escaping
into navigation. No external streaming application substitutes for an embedded
receiver. Unsupported features stay unavailable with a useful explanation.

## Security requirements

1. Preserve existing OpenID verification and server-side Web API keys. Never
   collect Steam passwords, Steam Guard codes, account cookies or refresh tokens.
2. Discovery is untrusted. Validate and bound IDs, names, addresses, message
   sizes and collection counts. Discovery metadata must never replace trusted
   host identity, authorize commands or introduce arbitrary fetch URLs.
3. A refresh credential is scoped to one verified Steam identity, expiring and
   revocable. Rate-limit upstream reads; redact credentials and private data.
4. Network operations are cancellable and bounded. Retired profiles and stale
   operations cannot publish, launch or restore session state.
5. Host sharing requires explicit pairing and per-operation authorization.
   Never expose a shell, unrestricted files, Steam account tokens or an
   unauthenticated command/stream listener. No automatic firewall/port changes.
6. Distinguish hiding a computer in a profile from revoking this device's trust;
   explain device-wide effects. Never silently revoke another profile's access.
7. Release input on focus loss, transport failure, disconnect and ownership
   transfer. A video surface is not authorization to send controller input.
8. Treat game metadata and artwork as untrusted. Only fixed HTTPS providers or
   authenticated host artwork; enforce bounds, no arbitrary webviews or scripts.
9. No automatic installation, purchase, sharing, quitting a game, cloud-save
   replacement or guest invitation. Host Steam remains the entitlement authority.
10. Preserve private ephemeral JIT CI, pinned dependencies and license notices.

## Compatibility and rollout

Preserve the existing preference key and read version 1/2 libraries. Keep legacy
route fields and IDs intact. New fields are optional; unknown capabilities are
false, unknown session state is not connected, unknown status is not offline.
Do not widen minimum OS versions just to expose an optional codec. Negotiation
must use the intersection of app, native backend, host, decoder and display
capabilities. Keep conventional streaming available when Pyrowave is disabled
or fails qualification.

## Validation ledger

Baseline: `de5033eb` on 2026-10-28 UTC. This work starts from the current merged
Games, Multiview and connected-media continuity implementations.

Validation must distinguish source inspection, automated tests, platform
compilation and measured hardware behavior. No real Steam hosts, consoles,
Apple devices or TVs are attached to the development session. Do not infer
hardware support from a platform enum or a successful native compilation.

Each implementation commit records its tests here. Features requiring Valve
approval, a deployment or hardware qualification remain explicitly incomplete
until that evidence exists.

## External contracts

- [OpenID and identity](https://partner.steamgames.com/doc/features/auth)
- [Public library API](https://partner.steamgames.com/doc/webapi/IPlayerService)
- [Remote Play game APIs](https://partner.steamgames.com/doc/api/isteamremoteplay)
- [Steamworks OAuth eligibility](https://partner.steamgames.com/doc/webapi_overview/OAuth)
- [Steam Datagram Relay eligibility](https://partner.steamgames.com/doc/features/multiplayer/steamdatagramrelay)
- [Pyrowave](https://github.com/Themaister/pyrowave)
- [Steam branding](https://partner.steamgames.com/doc/marketing/branding)

The original Steam Link SDK targets the Steam Link hardware; it is not an SDK
for embedding the Steam Link client. Pyrowave is a codec, not discovery,
authentication or a streaming transport. Open-source GameNetworkingSockets
does not grant Valve signaling or relay service access. Pyrofling and
Aurora/Solarflare are distinct host/protocol combinations and require separate
interop qualification; their codec name alone does not imply compatibility.

### Stage 1 — unified identity and presentation

Implemented canonical Steam identities, explicit cross-transport mappings,
profile favorites and successful-route preferences, v1/v2 recovery, catalog
AppID launch candidates, one poster grid and search, accessible details/menu
buttons, and library browsing independent of decoder availability. A route
candidate makes no installation or reachability claim. Steam Library is a
computer action rather than a synthetic game card.

Android Steam now opens fullscreen through the existing retained Multiview
surface. Native first-frame/state callbacks (with attachment replay) drive
recents and route preference. Native stop sends neutral input before cancelling.
This does not yet separate native session ownership from PlatformView lifetime.

Validation: focused Dart static analysis; new identity/migration/isolation tests
added. Executing Flutter tests initially blocked by a missing local C compiler
required by the unrelated PDF native asset hook; toolchain repair in progress.
No new hardware qualification is claimed.

### Multi-computer requirement

The Steambox, desktop and BC250 contribute separate installation snapshots to
one game catalog. Installed, reachable, paired, entitled and actively streaming
are independent states. Snapshot source and freshness must remain visible;
removing one computer must not erase a favorite still represented elsewhere.
