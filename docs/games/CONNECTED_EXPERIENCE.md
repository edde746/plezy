# Connected games implementation ledger

This is the review ledger for the connected Steam / GameStream experience.
The product remains PlezyNG: existing poster geometry, theme tokens, focus,
adaptive menus, profile boundaries and Multiview ownership apply to games.
Steam identity, game ownership, a computer's inventory and a live streaming
session are separate facts. No API response, discovery packet or saved
shortcut establishes entitlement, authentication, reachability or playback.

## Scope and acceptance

**Overall status: not code complete; draft PR; not ready for all-platform release.**
The implemented slices below are not substitutes for the remaining scope.

| Area | Code on this branch | Outstanding evidence or implementation |
| --- | --- | --- |
| Unified account / multi-computer library | Implemented, shared-model tests pass | Actual Windows/macOS/Linux inventory exchange and large-library qualification |
| Catalog refresh and revocation | Implemented, Go race tests pass | Relay deployment and live account exercise |
| Grid, details, routes and filtering | Implemented using existing app components | Device accessibility, RTL, controller and visual qualification; new strings currently use the English fallback |
| Android stream preferences / recovery | Implemented through Flutter, Java and JNI | Full Android build/minification, real host reconnect and negotiated-quality measurements |
| Native Steam transport | Portable Linux build and 38 tests pass locally | Current-head sanitizer CI, Android packaging and live transport qualification |
| View-independent stream lifetime | Partial: retained Multiview surface | Native session still belongs to its PlatformView; surface destruction stops it |
| Adaptive metrics / advanced codecs | Fixed request presets only | Negotiated statistics, adaptive policy, direct GPU Pyrowave, HDR, 4:4:4, 4K, surround, multiple pads |
| Other embedded receiver platforms | Library browsing/sharing only | Linux/SteamOS, Windows, macOS, iOS/iPadOS/tvOS receivers and TV capability qualification |
| Rich Steam / host features | Not implemented | Achievements/news/social, host-authoritative install/cloud/family states, Steam Input/remapping, Together and captures |
| Companion game control / internet transport | Inventory extension only | Permissioned launch/session commands, signaling/NAT/relay, connection diagnostics |

No claim of “every Steam API” is made: public catalog APIs, game-side Steamworks
APIs, private client interfaces and services requiring Valve approval have
different access contracts. An unavailable API needs an explicit dependency or
unsupported state; a mock response or a menu item is not completion.

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

Validation: focused Dart static analysis and identity/migration/isolation tests
pass. The initial missing compiler was resolved; subsequent Games/Multiview
suites pass. No hardware qualification is claimed.

### Multi-computer requirement

The Steambox, desktop and BC250 contribute separate installation snapshots to
one game catalog. Installed, reachable, paired, entitled and actively streaming
are independent states. Snapshot source and freshness must remain visible;
removing one computer must not erase a favorite still represented elsewhere.

### Stage 2 — installed libraries and scoped catalog refresh

Added the read-only multi-computer inventory flow documented in
[HOST_INVENTORY.md](HOST_INVENTORY.md), desktop Steam folder discovery, bounded
KeyValues parsing, encrypted companion paging, permission checks, computer and
installed filters, snapshot dates and preservation of partial inventories.
Older companion command indices remain unchanged; the extension negotiates
version 1. No helper daemon, new open port or Steam account credential is used.

Added independent public-catalog refresh and revocation, digest-only relay
grants, encrypted client persistence, expiry/restart fallback, in-flight
revocation and played free games. This endpoint needs a relay deployment.

Validation: focused Games/Multiview/companion and Go race tests are run for this
commit; exact results are recorded in VALIDATION.md. Native OS/hardware support
is not inferred from these shared-library tests.

### Stage 3 — requested stream limits and explicit recovery

Android's retained Steam receiver now receives profile-scoped request presets:
1080p60/30 Mbps (unchanged default), 720p60/12 Mbps, 1080p60/50 Mbps and
1080p30/15 Mbps. Automatic H.264/HEVC or explicit H.264 also applies to the
Pyrowave compatibility fallback. Optional arguments preserve older callers;
Java and C++ reject malformed/excessive limits before connecting. These are
request ceilings, not observed metrics or an adaptive algorithm. Pyrowave's
bandwidth may exceed the conventional encoder bitrate request.

Flutter presents localized connection/reconnect/disconnect states using the
current theme and focus controls. Input is enabled only after first-frame
evidence and while the workspace grants ownership. Late state replay cannot
overwrite a newer event. Explicit reconnect awaits native worker termination
before replacing the surface, coalesces repeated taps and cannot resurrect a
retired profile. A five-second native shutdown deadline fails closed; the UI
can retry. Disconnect sends no host quit command. Settings apply to newly
opened sessions; a reconnect retains the original session's preferences.

Android reflection callbacks and teardown methods are kept during shrinking.
Current platform build/qualification limitations remain in the table above.
