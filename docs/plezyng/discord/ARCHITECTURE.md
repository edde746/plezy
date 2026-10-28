# Proposed Discord client architecture

**Status: deferred proposal. The components, contracts, and file locations below are design suggestions, not implemented APIs or an instruction to start building.** Activate only through the decisions in [DELIVERY.md](DELIVERY.md).

## Design objective

Make a Discord conversation or call another presentation within the profile-scoped PlezyNG workspace. The account, connection, call, and media engine must outlive layout changes. A widget rebuild must not log in again, rejoin a call, restart a movie, duplicate a native player, or publish a second presence session.

Keep the [existing Multiview architecture](../multiview/ARCHITECTURE.md) and [compositor strategy](../multiview/COMPOSITOR.md). Reconcile these proposals with the actual implementation when activated; several parts of the wider workspace still require device qualification.

## Component boundaries

Names in this table are proposed responsibilities. The future implementer should adapt them to the repository's then-current conventions.

| Component | Owns | Must not own |
| --- | --- | --- |
| Account/session service | Profile-account association, connection state, credential references, ordered account teardown | Widget placement or a second copy of media playback |
| Transport interface | Capability discovery, account events, message operations, reconnect/resume, rate-limit handling | Assumed parity among SDK, native, and web routes |
| Native protocol adapter | Selected REST/gateway protocol, caches, event normalization, permission changes | Cryptographic primitives reimplemented in Dart |
| Call service | Call membership, microphone/deafen state, participants, RTC engine lifecycle, media permissions | Automatic joining from layout restore or pane focus |
| Native media bridge | Audio device I/O, codecs, DAVE integration, frame rendering/capture, bounded native callbacks | UI layout or serialized user credentials |
| Workspace adapter | Surface registration, stable IDs, presentation state, focus routing, visibility/resource hints | Call membership or independent microphone activation |
| Audio policy coordinator | Media/call mix, gains, ducking, route changes, interruption policy | Accidental capture of all playback as outgoing microphone audio |
| Embedded-browser adapter, if selected | Retained web session/view, restricted permissions, profile-specific browser data | Privileged remote-content access to arbitrary Dart methods |

Keep the existing [`DiscordRPCService`](../../../lib/services/discord_rpc_service.dart) independent. A future presence coordinator may select which transport publishes one user's activity, but turning off the client must not remove today's presence feature. Never run two publishers that repeatedly overwrite each other. Account linking, media-presence publication, and call connection should have separate visible settings.

### Capability contract

Expose operation-level capabilities: account linking, server/channel navigation, DMs, history limits, message send/edit/delete, attachments, voice destinations, incoming camera, incoming screen share, outgoing capture, background continuity, and system PiP. Include reasons for unavailable operations and limits established by the selected adapter.

Distinguish “adapter implements it,” “backend/account grants it,” and “this device/build is qualified.” A general `discordSupported` boolean would conceal materially different products. Do not manufacture a full server browser around Social SDK linked-channel data, or show an outgoing-video button because a WebRTC dependency can theoretically capture a camera.

Use account-scoped IDs and generation counters. Cancel obsolete requests and reject late callbacks after account/profile changes. Deduplicate gateway events, preserve message ordering, bound caches, and apply server rate limits with backoff. Treat expired credentials, network loss, denied permissions, and incompatible protocol versions as different states with useful recovery actions.

## Authentication and stored state

Select the account flow only after the integration route and policy review. Use the supported authorization flow for an official SDK integration, with state/redirect validation and PKCE where applicable. Do not embed an application secret or bot token in distributed clients. Verify ownership/configuration of the Discord application rather than assuming the existing presence application can be repurposed.

For an embedded route, keep sign-in inside an appropriately isolated browser session and preserve authentication challenges. For an unofficial native route, establish a defensible user-controlled sign-in method before implementation. The plan does not authorize scraping credentials from other apps, bypassing challenges, or collecting user tokens through a service controlled by us.

Reuse the [`CredentialVault`](../../../lib/services/credential_vault.dart) boundary after auditing account-specific needs. Keep credentials out of workspace snapshots, portable settings exports, analytics, crash dumps, URLs, and ordinary logs. Validate secure-store behavior on each platform; do not infer that a desktop keychain design is available on a TV. If secure storage is unavailable, require a deliberate session-only mode or leave sign-in unavailable.

Treat messages, channel titles, member identities, draft text, and attachment previews as sensitive even when they are not credentials. Start with bounded local caches and a defined retention policy. Do not sync Discord history through Plex or generic PlezyNG settings backup. Define whether drafts survive restart, how cached content is protected, and what disconnect deletes before shipping.

On profile switch, lock, or account removal, immediately hide private surfaces and stop microphone/camera/capture according to the chosen explicit policy. Cancel subscriptions and discard callbacks from the retired account generation. Disconnect should remove account-owned cache and browser cookies when requested, without clearing unrelated media-server credentials. A locked or temporarily unavailable key store must not silently become a new unauthenticated account or corrupt stored credentials.

## Session and workspace integration

### Stable session identity

Add communication kinds only once semantics are settled, for example conversation and call. A call can expose more than one surface: controls/participants, an incoming screen stream, and possibly selected cameras. These surfaces share one call service and one audio graph. They must not each become independent call connections or duplicate the same incoming voice output.

IDs should include the profile/account namespace and stable conversation/call identity. The workspace descriptor stores display metadata and capabilities; the live adapter stores credential references, stream objects, and native handles. Persist only safe layout identifiers. On restart show a restorable entry, not an automatically active microphone, camera, screen share, or call join.

Give presentation callbacks explicit meanings:

- **Float, split, resize, promote, restore:** change presentation and possibly renderer attachment; preserve transport and playback identity.
- **Hide/park:** retain a clearly indicated call through a persistent call dock if that behavior is supported; release or reduce unnecessary video rendering. Do not display a disconnected pane as live.
- **Close conversation pane:** remove its view, preserving account state and drafts under the chosen policy.
- **Close call pane:** move controls to an always-visible active-call dock, or explicitly leave if no such dock can exist. Never leave an invisible active microphone behind.
- **Leave call:** stop capture, unsubscribe streams, disconnect voice, release audio resources, then retire call surfaces.
- **Disconnect account/profile teardown:** stop every account-owned call and subscription, clear private UI, and finish native resource disposal.

Use generation-safe teardown and reference-counted renderer ownership. Retain the native webview/RTC session across Flutter reparenting where necessary. When the OS requires a renderer transfer, stage the new target, commit ownership once it is ready, and roll back to the old target on failure. Do not claim seamless movement until tested with real platform views/textures.

### Input and interaction

Reuse PlezyNG typography, `MonoTokens`, `MonoMotion`, menus, overlay sheets, localization, and accessibility patterns. Add a compact account/conversation entry point without introducing a competing dashboard style. Chat selection, link activation, scrolling, IME, emoji input, and attachment actions need normal body gestures; use an intentional title/handle region for window dragging.

Typing into chat must not trigger movie hotkeys or held game controls. Switching focus must release game input safely. Scope push-to-talk deliberately: app-local by default, with a separately qualified desktop global binding only if requested. Focus loss must never leave push-to-talk stuck open. Back/Escape should dismiss a popup or composer state before accidentally leaving a call or closing the movie.

Provide visible mute, deafen, connection, and active-capture indicators at compact sizes. Make the active-call dock reachable by keyboard, screen reader, and TV remote. Layout motion and pane prominence must not change microphone state.

## Audio is a required workspace change

The current controller selects one `audibleSessionId`. Replace or extend that contract with an explicit communication-aware policy before claiming simultaneous movie and call support. Preserve the existing single-media behavior for sessions without communication enabled.

| Audio path | Proposed control | Important boundary |
| --- | --- | --- |
| Movie/music output | Existing media volume plus optional ducking while someone speaks | Joining a call must not silently lose media ownership |
| Incoming call voice | Call output volume and deafen | One shared call output even with multiple visible participants |
| Microphone | Explicit mute, push-to-talk, input device, capture permission | Independent of pane focus, prominence, and playback volume |
| Incoming shared-stream sound | Independent or clearly grouped stream volume | Avoid replaying the same audio through two render paths |
| Outgoing shared content | Explicit selected source and share-audio choice | Exclude received voice and unintended private media |
| UI notifications | Bounded notification gain and quiet modes | No notification storm during reconnect/backfill |

Model these as logical routes; a single cross-platform software mixer is not automatically necessary. Some native/OS audio paths can mix safely, while others need explicit graph integration. Choose based on measured behavior, latency, hardware routing, and licensing/build constraints.

Define mute versus deafen precisely; do not equate either with ending the call. Make ducking optional and restore previous gain on call exit or errors. Test speaker/headphone echo, Bluetooth route/profile changes, unplugged devices, OS interruptions, and simultaneous media playback. Echo cancellation needs an appropriate output reference; simply playing two unrelated audio engines through speakers is not sufficient evidence.

Outgoing sharing requires mix-minus behavior: remote participants must not hear their own received voice reflected into the outgoing stream. Capturing system audio can include more than the selected movie or app, so show the actual capture scope and provide an immediate stop action. Do not enable outgoing media sharing just because local movie playback is active.

## Native calling and rendering

The native call engine is a separate subsystem from mpv/Exo media playback. Its protocol responsibilities are documented in the [DAVE research](RESEARCH.md#encrypted-calls-are-a-separate-engineering-project). Keep network signaling/state transitions coordinated with native encoded-frame transforms. Do not assume that adding an AES key to a generic frame cryptor implements MLS membership or Discord's negotiation.

The transport/media seam must expose negotiation state, encrypted-call readiness, participant stream identity, reconnect outcomes, and terminal failures. Protect native lifetime boundaries against callbacks after disposal. Bound queued events and maintain backpressure; a reconnect storm must not allocate unbounded messages or textures.

Keep audio processing and frame encryption/decryption on suitable native threads. Feed decoded video into Flutter-compatible textures or a qualified compositor adapter. Avoid copying full-resolution video frames or real-time PCM through Dart on every callback. Use small typed control/events across the bridge, with explicit ownership of native resources.

Prove **received** screen/camera streams before adding outgoing capture. Outgoing capture adds screen portals or OS capture APIs, window selection, permission lifetimes, encoding, bandwidth control, and audio-routing concerns. Respect protected-content and OS capture restrictions; a black protected surface is not an invitation to bypass them.

### Resource admission

Extend the workspace's resource policy beyond native movie-player slots. Account for hardware/software video decoders, encoders, resolution/frame rate, GPU memory, texture copies, CPU, network bandwidth, and thermal pressure. A device may decode a movie comfortably but fail with several low-latency RTC streams.

Start the future proof with one movie, one voice call, and one received video stream. Measure before choosing default limits. Reduce companion resolution/frame rate or pause invisible video decoding where safe. Visibility changes must not stop necessary call signaling, key transitions, or voice audio. When capacity is exhausted, decline the additional stream or offer explicit switching without terminating the current movie/call.

Keep the main movie's HDR/Dolby Vision, subtitle composition, timing, and audio behavior under regression observation. A browser/texture route that forces costly full-frame copies or changes color handling may be unsuitable even if chat renders correctly.

## Embedded-browser route

If selected, the browser owns its Discord session and protocol. PlezyNG owns the retained view, app layout, permissions, lifecycle indicators, and documented host controls. This architecture may deliver a useful complete web-client pane earlier, but offers less reliable control over independent participants, call state, and audio buses. Record that tradeoff rather than representing it as native parity.

Do not depend on scraping Discord's internal DOM/state to maintain a call dock or extract streams. Test whether the host can provide sufficient safe lifecycle controls without that dependency. If it cannot, constrain the browser product honestly or reject that route. A webview crash must stop or clearly terminate capture and leave the movie usable.

Isolate cookies/cache by profile; allow microphone/camera only for intended origins and explicit user actions. Handle auth popups and external links through a constrained navigation policy. Keep sandboxing enabled, deny arbitrary local-file access, and avoid injecting app secrets. Engine updates and security patches become an ongoing maintenance responsibility.

## Platform policy

| Target | First meaningful proof | Additional unresolved work |
| --- | --- | --- |
| Linux, especially Wayland | Real encrypted call plus movie and retained in-app pane | Browser/RTC backend, portals, audio devices, GPU path; test representative AMD hardware rather than assuming vendor parity |
| Windows | Same session/audio/rendering invariant | Capture and audio loopback, device changes, GPU/driver combinations, packaging |
| macOS | Same invariant with native permissions and signing | Capture APIs, audio routing, renderer transfer, optional pop-out/PiP |
| Android handheld | Foreground conversation/call plus media pane | Foreground-service/microphone restrictions, audio focus, Bluetooth, background continuation and native PiP |
| iOS/iPadOS | Foreground conversation/call plus media pane | Audio-session policy, native call PiP rendering, background limits and incoming-call delivery |
| Android TV/tvOS/webOS/Tizen | Verify available engine, input, microphone, storage, and runtime budget | No inherited handset/desktop support claim; remote UI and each native backend need separate proof |

This is an experiment order, not a permanent exclusion of other platforms. Start with desktop to retire the main protocol/rendering risks, then qualify portable pieces. Preserve OS/architecture distinctions and explicit unavailable states. A separate desktop pop-out should be an app-owned window sharing the session, not an attempt to embed another process's Discord window.

System PiP remains an optional continuation adapter. Use [platform evidence](RESEARCH.md#system-pip-and-background-operation), not platform-name checks, to decide which call video can be shown. Chat remains interactive in the in-app workspace; no promise is made of full chat interaction in OS PiP. Incoming calls while the app is suspended require an independently designed event-delivery path and must not be inferred from successful foreground calling.

## Watch Together integration

PlezyNG already has [Watch Together state](../../../lib/watch_together/providers/watch_together_provider.dart) and [player integration](../../../lib/screens/video_player/parts/watch_together.dart). Keep synchronization of independently accessible media separate from Discord voice/chat and from screen rebroadcasting.

A later integration could share an expiring, unguessable room reference through an explicitly initiated invite. Recipients must still have their own media access, and invitation links must not contain Plex/Jellyfin/Emby credentials, raw stream URLs, or stored Discord credentials. A Discord call ending should not corrupt playback synchronization; a watch party ending should not unexpectedly disconnect an unrelated conversation. This is an optional later stage, not a prerequisite for the first useful client.
