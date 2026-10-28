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
| Native Steam transport | Portable Linux build and 41 tests pass locally | Current-head sanitizer CI, Android packaging and live transport qualification |
| View-independent stream lifetime | Retained Android PlatformView and Linux/Apple texture surfaces | Native session still belongs to its retained surface; surface destruction stops it |
| Adaptive metrics / advanced codecs | Host-driven adaptive feedback, native stream diagnostics, request ceilings and one-to-four Android controller seats | Live adaptation/performance qualification, direct GPU Pyrowave, HDR, 4:4:4, 4K, multichannel mapping/host qualification and physical multi-controller qualification |
| Other embedded receiver platforms | Linux receiver implemented; Apple VideoToolbox/Core Audio and Xcode integration source added | Full Linux/SteamOS packaging and host qualification; Apple SDK/device qualification; Windows receiver |
| Rich Steam / host features | Achievements/news/optional friends-playing, Input/properties host actions, and confirmed Cloud/Families destinations implemented | Live API qualification, host cloud/family state APIs, live Steam Input configuration, Together and captures |
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
only fixed launch, install, library, downloads, Input configuration and game-properties actions; no caller-supplied path,
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
rumble, gyro and live Steam Input configuration qualification remain separate work.


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

### Linux embedded receiver

Linux now uses the existing Steam protocol/runtime with a dedicated GStreamer
receiver and Flutter pixel-buffer texture. It does not instantiate an mpv
player, spawn Steam Link, or send game data through the movie library. H.264
and HEVC use the installed/bundled libav decoder; this implementation reports
software decoding and SDR RGBA texture output, not direct GPU, HDR or Pyrowave.
Video parsing is restricted to bounded H.264/HEVC access units and 1920×1080
output caps before decode. Video input, outstanding frames, decoded output and
PCM queues all have fixed limits. Actual texture consumption settles the native
frame ticket; replacement drops the old frame instead of acknowledging it twice.

PIN trust is in libsecret's OS credential store, keyed by numeric Steam host
identity, never in Dart preferences. Missing/locked storage fails closed. DNS
resolution and keyring access are cancellable. Pairing is serialized. Session
creation is capped at eight receivers. Controller seats and keyboard input obey
workspace ownership and neutralize on release. Stop acknowledges only after
transport and decoder workers have exited and the texture has unregistered.
Late texture creation after a profile/view retirement is explicitly disconnected.

The current Linux port offers conventional codecs only. HEVC decoder failure
may retry H.264; unsupported multichannel layout/output may retry stereo. Each
retry removes a capability, with at most three attempts. Native capability
queries require the actual parser/decoder/audio plugins, so a build without
those plugins does not advertise a working receiver. The build can explicitly
omit it with `-DPLEZY_STEAM_RECEIVER=OFF`. Release bundles include the fixed
pipelines' plugins and matching scanner; the launcher confines plugin discovery
to that set. Distribution, Flatpak keyring/audio, full-runner builds and actual
Steam hosts still require private-JIT and hardware qualification.

Local verification: strict C++ compilation against Flutter Linux headers;
actual H.264 encode→decode pixel checks; common Opus/speaker and controller seat
tests; Flutter texture lifecycle, timeout and late-retirement tests. These are
not evidence of Apple/Windows receiver completion or live-host qualification.

### Steam Input, Cloud and Families — follow-up PR #54

The existing per-computer overflow menu now offers Steam Input and game
properties when the authenticated peer explicitly advertises those actions.
Older version-one peers retain only the four original verbs. These requests
require the existing off-by-default host permission, an inventory-bound peer,
a current installed-game manifest, and a confirmation identifying the computer.
Only a numeric AppID crosses the boundary. A layout URL, published-file ID, VDF
contents, command line or save-file write cannot be supplied. Steam owns the
configuration screen and any changes the user makes there. The client protocol
URIs (`controllerconfig/<appid>` and `gameproperties/<appid>`) require actual
Steam-client compatibility qualification; submission is not evidence that the
configuration screen appeared.

Game details use the shared adaptive menu for Store, Community, Workshop, News,
Cloud files and Families. Account destinations warn that the browser's Steam
sign-in may differ from PlezyNG's linked account. Cloud downloads and family
invites/permissions run on Steam's own account pages. This does not claim
programmatic cloud-conflict resolution, automatic family entitlement discovery,
or general cross-game Cloud OAuth authority. No Steam cookies are imported.


### Apple receiver and shared input

The macOS, iOS/iPadOS and tvOS Runner targets register the same Steam Games
capability and per-session channels as Linux. Xcode builds the pinned portable
transport without Vulkan, then compiles the shared Objective-C++ adapter. This
is source implementation, **not evidence of a successful Apple SDK build or
playback qualification**. Every target includes an XCTest decoding a real 64×64
H.264 frame and checking pixels and teardown; those tests must run on private
JIT Apple capacity before merge/release.

VideoToolbox decodes H.264 and, after a hardware capability check, HEVC. Its
IOSurface-backed BGRA pixel buffer is retained directly by Flutter's texture
registry. Production rendering does not read the pixels back to the CPU.
Compressed frames and PCM have separate bounded queues; frame completion is
reported only when Flutter consumes a texture. Decoder/configuration changes,
late frames, backgrounding and acknowledged disconnect retire ownership before
reconnect. Codec parameters are parsed with explicit size/count limits and
validated against the negotiated resolution before decoder allocation.

The current Apple texture path is **SDR, at most 1080p60**. It rejects PQ/HLG
instead of clipping HDR into BGRA. The additional Metal Pyrowave path is described below.
Hardware/software decoder reporting uses the documented properties only on
supported OS versions; older mobile systems keep an unknown decoder-kind
value. The existing deployment floors are unchanged.

Core Audio uses explicit mono/stereo/quad/5.1 layouts at 48 kHz with bounded
AudioQueue buffers. Unsupported audio requests retry stereo; HEVC failure
retries H.264. Retries only remove capabilities and are capped at four when Pyrowave is enabled. The
workspace audio lease controls volume independently of input ownership.
Speaker routing, Bluetooth changes and TV/HDMI output require device tests.

Pairing trust remains in the OS Keychain with device-only accessibility, never
Dart preferences, settings backup or logs. Resolution uses cancellable
Network.framework IPv4 endpoints; pairing/forget operations are serialized.
The adapter preserves current native Steam pairing and encrypted transport.
It does not open ports, configure a router or confer internet relay access.

Desktop/Apple texture surfaces map pointer coordinates inside the video
rectangle, coalesce motion to one update per Flutter frame, and forward mouse
buttons and wheel directions. Touch can position/click the host pointer.
Physical USB keyboard usages preserve keyboard layout semantics, with named
key fallback. Controller seats, pointer buttons and held keys all release on
focus/lease reset. Shift+Escape releases game input to the existing workspace
controls; details dialogs suspend it without reclaiming another pane's lease.
Apple/Linux also offer an on-screen controller in the connection toolbar.
It defaults to the profile preference on iOS and stays hidden initially on
desktop. Its physical gamepad layout stays stable in RTL, uses theme colors,
48-pixel labeled buttons, independently captured fingers, dual sticks, click
gestures, shoulders/triggers and a compact landscape arrangement. Small panes
explain how to enlarge the window. Touch assistance merges into player one
without reserving or clearing a physical controller seat; removing the overlay
releases that assistance only. Focus, profile or session retirement releases
all held controls. Shift+Escape remains available to reach workspace menus.


### Native Metal Pyrowave

The Apple adapter now builds the already pinned upstream Metal decoder into the
application. The profile Pyrowave opt-in is available on Apple as well as
Android, and still defaults off. Apple advertises the codec only on a compatible
Apple7-family GPU; Intel/AMD Macs continue with conventional codecs. Pipeline
creation or decode failure removes Pyrowave on reconnect, then conventional
codec/audio fallback remains available. There are at most four attempts.

Compressed packets pass the same bounded parser before reaching the upstream
API. A sequence's dimensions and chroma cannot change under an active decoder.
The wrapper accepts SDR BT.709 4:2:0 and 4:4:4, full/limited range and the declared
chroma siting. It does not invent a Steam wire setting to force 4:4:4: the host
chooses its encoded chroma. Connection details report the observed format.

Metal decodes into private R16 plane textures and converts into an IOSurface
BGRA buffer on the same command buffer. The decoder worker waits for GPU
completion before publishing it to Flutter. A four-buffer allocation threshold
and fixed upload slots bound retained frames; pressure drops work instead of
allocating an unbounded queue. There is **no production decoded-pixel CPU
readback** in this path. The diagnostic decoder label distinguishes this from
Android's existing Vulkan/CPU-readback path.

The upstream Metal port is explicitly experimental, with limited maintainer
support. Its presence is not evidence of Apple SDK compatibility or measured
latency. RunnerTests now includes 4:2:0/4:4:4 neutral-color rendering, unsupported
HDR rejection and teardown on compatible Apple GPUs. CPU mapping is used only
by that test to inspect the completed output. These tests have not run here.

True HDR remains unfinished: Flutter's current Darwin texture implementation
accepts eight-bit BGRA and eight-bit NV12, and treats YUV as BT.601. The receiver
therefore uses explicit BT.709 GPU conversion and rejects PQ/BT.2020 streams.
An EDR/HDR native presentation layer, host negotiation and color/device tests
are required; adding an HDR toggle alone would misrepresent support.
