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
| Adaptive metrics / advanced codecs | Host-driven adaptive feedback, native stream diagnostics, request ceilings and one-to-four Android controller seats | Live adaptation/performance qualification, direct GPU Pyrowave, HDR, 4:4:4, 4K, surround and physical multi-controller qualification |
| Other embedded receiver platforms | Library browsing/sharing only | Linux/SteamOS, Windows, macOS, iOS/iPadOS/tvOS receivers and TV capability qualification |
| Rich Steam / host features | Achievements/news/optional friends-playing and confirmed Steam destinations implemented | Live API qualification, host cloud/family state APIs, Steam Input/remapping, Together and captures |
| Companion game control / internet transport | Inventory, permissioned host launch/install/views, and active stream audio/fullscreen/disconnect controls implemented | Signaling/NAT/relay, internet connection diagnostics and actual host/device qualification |

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

### Access review for the expanded implementation request

Rechecked against Valve's primary documentation on 2026-10-28. These are
implementation dependencies, not completed features or a reason to remove
requested work from scope.

| Requested area | Available integration path | Required completion evidence |
| --- | --- | --- |
| Desktop / Apple receivers | Port the embedded transport, native trust storage, decoder, presentation, audio and input adapters | Build each target; pair, render, reconnect and retire profiles on real hosts/devices |
| Direct GPU Pyrowave / HDR / 4:4:4 | Implement platform GPU presentation and negotiate only validated decoder/display combinations | No CPU readback on the direct path; color correctness, synchronization, fallback, frame timing and resource measurements |
| Advanced audio/controllers / adaptive streaming | Extend transport negotiation and native output/input ownership; drive adaptation from observed metrics | Channel layout, hotplug, seat isolation, neutralization, loss/recovery and adaptation tests |
| Achievements | Server-mediated GetPlayerAchievements and GetSchemaForGame with authenticated identity and privacy-aware unavailable states | Identity binding, response bounds, cache isolation, private profiles and live API exercise |
| News and social context | Separate public content from authenticated/private account context | Explicit scopes, safe content rendering, bounded caching and account-switch isolation |
| Steam Input / Together | Game-side SDK/overlay facilities must not be represented as a general remote-client API | Establish applicable SDK access and host-side integration; verify real controller/overlay behavior |
| Installation / cloud / family actions | Keep Steam authoritative; establish an authenticated host implementation for each action | Per-action permission, current host result, cancellation, entitlement/conflict handling; no inferred readiness |
| Companion game control | Extend the existing authenticated channel with versioned capabilities and operation-specific permission | Replay protection, denied commands, bounded requests, host identity and profile retirement tests |
| Automatic internet streaming | Provide PlezyNG-owned authenticated signaling, traversal and relay infrastructure unless separately granted Valve access | Deployment, relay authorization/expiry, abuse limits, encryption, restricted NAT and failure-path testing |

[ISteamRemotePlay](https://partner.steamgames.com/doc/api/ISteamRemotePlay)
exposes game-session information and game-side Together functions. Its presence
does not supply an embedded receiver. The
[Web API overview](https://partner.steamgames.com/doc/webapi_overview) distinguishes
public and protected methods and the public and partner API hosts.
[ISteamUserStats](https://partner.steamgames.com/doc/webapi/ISteamUserStats)
documents player achievements and game schemas with Web API authentication.
The [SDR requirements](https://partner.steamgames.com/doc/features/multiplayer/steamdatagramrelay)
explicitly state that the open-source networking code does not grant access to
Valve's relay network. PlezyNG must not claim that service without the applicable
access; a separately deployed transport remains in scope.

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

### Stage 4 — Steam activity and companion host actions

Game details now load achievements and news on demand; friends playing the
selected game require an additional off-by-default opt-in. `/auth/steam/game`
accepts a bounded AppID request and derives the account from the verified,
revocable read capability. The existing credential now covers these read-only
public account/activity lookups as well as the catalog; it still grants no
Steam account or host action access. Social lookups are never automatic.

The server caps response bodies, achievements, news and friend summaries,
rejects upstream redirects, limits per-grant request frequency and total
in-flight game-context requests, and retires responses revoked during a fetch.
Locked hidden-achievement names/descriptions are omitted. The client validates
the game and account identity, retains metadata only within the detail view,
and uses text rather than rendering upstream HTML. External destinations are
constructed from known Steam domains and uint32 AppIDs; opening them requires
a confirmation. Old relays expose unavailable/relink behavior.

The appended `gameAction` companion command negotiates version 1. Host control
and installation each require separate profile permissions, off by default.
The viewing device requires a previously imported inventory pinned to the
same authenticated companion peer and confirms each action. The host accepts
only `launch`, `install`, `library` and `downloads`; no caller-supplied path,
URL, command line, account ID or credentials are accepted. Launch requests
require a current installed-game manifest. IDs are bounded uint32 values.
Requests have random IDs, replay suppression, one operation at a time, bounded
deadlines and permission/generation checks immediately before dispatch.

Host actions invoke the local Steam URI handler on the **host computer**;
they are separate from the embedded receiver and do not hand streaming off to
another client. Acknowledgement means only submission to Steam. It never
means installation finished, launch succeeded, a family copy is available or
a cloud conflict was resolved. No quit, uninstall, purchase or cloud overwrite
command is exposed. Once submitted, an action cannot be recalled by closing
the companion connection. Live Steam/OS-handler qualification remains required.


### Stage 5 — Independent controller seats

Android Steam sessions can now request one to four controller seats using the
existing Games settings UI. One remains the default for existing profiles and
older creation arguments. Invalid persisted counts fall back to one; malformed
native arguments fail before a transport starts. The legacy single-controller
JNI entry points remain available.

Physical device IDs are resolved to seats by one native allocator shared by the
Android and Flutter event paths. Events update only that device's controls;
Flutter button updates cannot erase native stick axes. Each advertised HID
controller has its own path and serial. Seats are assigned on first input,
remain stable across focus changes, and are reused only after disconnect.
Touch controls and navigation-only TV remotes assist player one; a TV remote
does not consume a physical controller seat. Excess gamepads are ignored instead of being
merged into another player's input. Device IDs stay local to the receiver.

Disconnect/remapping clears only the affected controller. Focus loss, input
lease loss, teardown and profile retirement neutralize every seat and keyboard
key. Local allocation is bounded to four devices. Game/host support, Android
hotplug and controller ordering still require physical-device qualification;
rumble, gyro and Steam Input configuration are separate unfinished features.


### Stage 6 — Measured streaming diagnostics and adaptive feedback

Steam's host-driven adaptation already receives frame outcomes through ihslib's
tracked-frame feedback. The receiver now consumes host target bitrate, target
frame-rate fractions and limiter reasons, and exposes them alongside local
counters. These are not reconstructed from quality preferences. Unknown targets
remain unknown; request presets continue to define ceilings, not actual quality.

The existing themed dialog is available from the stream surface and active
game details. It samples once a second only while visible, uses a bounded native
snapshot, and keeps all data on device. It reports negotiated format, decoder
kind where the OS exposes it, received compressed-video payload, submitted
presentation rate, frame completion time, queue depth and HID/reliable-packet
backlog. Reconnects change a local epoch so rates cannot span separate sessions.
Native counters ignore duplicate completion callbacks and separate reset frames.

Completion time includes receiver queuing/decode/surface submission; it is not
network latency or physical display scanout. Video payload excludes transport
overhead. Maximum reliable acknowledgement includes retries and is not RTT.
Opening the dialog neutralizes game input, and closing it respects the current
workspace lease. Missing/older native measurement methods produce an unavailable
state without stopping playback. No client-side reconnect loop changes quality.
Actual adaptation and presentation timings still need host/device measurements.


### Stage 7 — Companion control of active game streams

The paired remote's existing More tab offers Game sessions when the receiving
peer advertises `gameSessionVersion: 1`. A separate profile permission, disabled
by default, allows listing up to eight active game titles and requesting audio
selection, mute, fullscreen or disconnect. It uses the profile-owned Multiview
registrations, so movie/music sessions cannot be addressed as games. Muting an
old game cannot cancel a newer audio selection for another session.

No internal session ID, computer address or stream credential is sent. The
receiver issues random 128-bit handles tied to the actual live registration.
Disconnect/reconnect, profile retirement and replacing the game registration
invalidate those handles. Requests have bounded deadlines, strict fields,
version negotiation, replay suppression, bounded handle/request sets and a
monotonic per-operation rate limit. Permission is checked again at dispatch;
late acknowledgements cannot cross peer generations. Unknown/old peers do not
advertise this feature. The new command is appended, preserving old indices.

The phone confirms disconnect and explains that the host game stays running.
Acknowledgement means the request was accepted; refresh obtains new state.
Nothing synthesizes raw gamepad input, quits the host game, controls arbitrary
other media, exposes a shell or configures an internet listener. The same
connection control is protected against a peer change while its dialog is open.
Actual phone/receiver interoperability is still a release gate.

Host launch/install inspection now uses monotonic deadlines plus an explicit
active-operation guard. A scan that finishes after its timeout cannot launch a
game later, even if the wall clock changes during the request.

### Multichannel audio receiver

The Android receiver can request stereo (default), quad or 5.1 per profile.
The discovery request and streaming negotiation both carry the selected count.
The common decoder accepts 48 kHz Opus, with a maximum of six channels and
120 ms per packet. Legacy mono/stereo without codec metadata remains supported.
Surround requires a valid RFC 7845 OpusHead family-1 mapping; unknown or missing
multichannel mapping is deliberately rejected rather than guessed. Family-1
Vorbis order is converted to FL/FR/FC/LFE/BL/BR for Android PCM. Header gain and
pre-skip are applied. This is **not yet evidence that current Steam hosts supply
this header**: host capture and surround speaker qualification remain required.

AudioTrack uses the corresponding PCM channel mask. Queued packets retain the
output they belong to, so an old packet cannot be played through a newly
configured layout. Invalid layouts or unavailable outputs trigger one stereo
retry after the previous transport exits; Pyrowave and audio fallbacks only
remove capabilities and cannot create an infinite reconnect loop. Older JNI
entry points continue requesting stereo. Diagnostics report negotiated input
channels, not a guarantee about the OS's physical speaker routing.

Validation includes actual Opus multistream encode/decode with distinct tones
per channel, speaker isolation, malformed mapping/header rejection, request-wire
channel count and legacy defaults. Device/AVR output is unqualified.
