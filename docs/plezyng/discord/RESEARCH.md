# Discord integration research

**Status: deferred research. No implementation or platform qualification is claimed.** See the [plan status](README.md) before treating any recommendation as work to execute.

Evidence collected 2026-10-27 America/Regina and checked while documenting on 2026-10-28 UTC. Repository observations are source inspection; external behavior comes from the linked primary documentation or upstream source. A library declaring a platform does not establish that Discord works on that platform inside PlezyNG.

Confidence labels: **high** means directly supported by inspected code or explicit documentation; **moderate** means an engineering inference with identified dependencies; **low** means a weakly supported expectation; **unknown** means the research did not establish the answer.

## Existing PlezyNG wiring

| Area | Inspected evidence | What it establishes |
| --- | --- | --- |
| Rich Presence | [`DiscordRPCService`](../../../lib/services/discord_rpc_service.dart), [`pubspec.yaml`](../../../pubspec.yaml) | Uses `dart_discord_presence ^1.2.1`, desktop availability checks, local Discord IPC, playback metadata/artwork/timing, and reconnect handling |
| Settings and startup | [`services_settings_screen.dart`](../../../lib/screens/settings/services_settings_screen.dart), [`settings_service.dart`](../../../lib/services/settings_service.dart), [`main.dart`](../../../lib/main.dart) | `enableDiscordRPC` controls the integration and the service is initialized at startup |
| Existing regression coverage | [`discord_rpc_service_test.dart`](../../../test/services/discord_rpc_service_test.dart) | Presence has a fake-client test seam; test existence does not imply a live Discord call was tested |
| Release announcements | [workflow](../../../.github/workflows/discord-release.yml), [announcement script](../../../scripts/announce_discord.py) | CI webhook announcement plumbing; deployed secret configuration and delivery were not verified |
| Workspace | [models](../../../lib/multiview/workspace_models.dart), [controller](../../../lib/multiview/workspace_controller.dart), [overlay](../../../lib/multiview/workspace_overlay.dart) | Reusable layout, focus, ownership, and runtime-surface boundary |
| Native PiP | [`PipService`](../../../lib/services/pip_service.dart), [video player adapter](../../../lib/screens/video_player/parts/pip.dart) | Existing video continuation path, distinct from the app's workspace compositor |

The presence service uses application ID `1453773470306402439`. This is a public identifier, not a credential. Ownership of that application and permission to reuse it for broader account features were not established. The poster path uploads bounded artwork to the configured Plezy service; it is not an account-authentication or video-transport path. Playback presence and CI webhooks grant no Discord message-history or call access. **Confidence: high** for the code boundaries; operational setup remains unverified.

Immutable starting points: [presence at the audited revision](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/services/discord_rpc_service.dart), [workspace controller](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/multiview/workspace_controller.dart), and [vendored webview manifest](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/packages/flutter_inappwebview/pubspec.yaml).

## What the workspace already supplies

`WorkspaceSurfaceRegistration` supplies a descriptor, a surface builder, restore/close callbacks, audio/input ownership handlers, and an optional native video-player slot. The real media session remains owned by its adapter or service. This is the right seam for preserving a communication session while its presentation moves.

Important constraints in the audited implementation:

- `MultiviewMediaKind` has video, live TV, music, audiobook, publication, comic, and game kinds. There is no Discord/chat/call kind.
- A single `audibleSessionId` and boolean ownership callback select audible output. Switching ownership disables the previous owner. The desired film-plus-call mix needs an explicit policy change; merely registering an audio surface is insufficient.
- Visual focus, input ownership, and audio ownership are separate. Preserve that distinction and add microphone control independently.
- Registration checks required handlers and duplicate occupied video slots. Those player slots are not a complete admission budget for WebRTC decoders or capture.
- Snapshot version 2 preserves profile-local layout and descriptions, not runtime handles or an instruction to restart streams. A restored call pane must not automatically reopen a microphone.
- The overlay already retains some game surfaces offstage. Communication renderers likewise need lifecycle work; widget rebuilding does not guarantee native-view continuity.
- Long-press move gestures can compete with message selection and text editing. Chat requires a deliberate drag region and input handling.

**Confidence: high** for these code observations; **moderate** for reuse without changes to individual renderers. Existing Multiview [architecture](../multiview/ARCHITECTURE.md), [compositor plan](../multiview/COMPOSITOR.md), and [qualification work](../multiview/VALIDATION.md) remain authoritative for the wider feature.

## Official interfaces and their limits

### Social SDK

The [Social SDK overview](https://discord.com/developers/docs/social-sdk/index.html) and [client reference](https://discord.com/developers/docs/social-sdk/classdiscordpp_1_1Client.html) describe a native SDK without a ready-made PlezyNG UI. It offers account linking, social features, and communication primitives. A Flutter integration still needs an audited native bridge, lifecycle handling, and UI.

The documented [communication model](https://docs.discord.com/developers/discord-social-sdk/core-concepts/communication-features) includes app lobbies, DMs, linked channels, and lobby calls. At research time the app-wide development limits per two hours were 100 lobby create/join operations, 100 lobby updates, 20 channel link/unlink operations, 100 lobby messages, and 100 DMs. Increased production limits require review; requirements include account linking, Rich Presence/join support, friends access, and completed feature behavior. PlezyNG's eligibility and approval are **unknown**. These limits must be rechecked before a product or capacity decision.

[DM documentation](https://docs.discord.com/developers/discord-social-sdk/development-guides/sending-direct-messages) describes a 25-message in-memory cache per channel and history retrieval capped at 200 messages within 72 hours. Both users must have used the application for the relevant history path; otherwise it can return 404. Some rich content is represented through placeholder information or links back to Discord. This is not an unrestricted replacement for the user's entire Discord inbox.

[Linked channels](https://docs.discord.com/developers/discord-social-sdk/development-guides/linked-channels) connect an app lobby to an eligible server text channel. Linking requires Manage Channels, View Channel, Send Messages, and a lobby member with `CanLinkLobby`; age-restricted or already-linked channels are excluded. Lobbies created client-side using secrets are ineligible for linking, and persistent lobbies are recommended. Plan qualifying lobby creation and any required backend credentials explicitly; this is distinct from embedding an OAuth application secret in a client. Crucially, every lobby member can see and reply to a linked private channel through the lobby. Membership is therefore a product authorization boundary, not a faithful mirror of all guild permissions. Do not expose a private channel to a broader watch-party membership by accident.

The [voice guide](https://docs.discord.com/developers/discord-social-sdk/development-guides/managing-voice-chat) documents lobby calling. The reviewed public SDK surface did not establish arbitrary guild voice-channel, DM/group-call, camera, or Go Live client parity. **Confidence: high** about the documented scope; **unknown** whether additional partner capabilities could satisfy the complete product. Absence from the reviewed documentation is not proof that no private capability exists.

[Platform compatibility](https://docs.discord.com/developers/discord-social-sdk/core-concepts/platform-compatibility) lists Windows/macOS, experimental Linux requiring glibc 2.31+, Android 7+, and iOS 15.1+. Current standalone integrations require C++20 on these targets; older pre-1.9 guidance used C++17. Mobile general availability was [announced in August 2026](https://discord.com/blog/mobile-platform-support-arrives-in-discord-social-sdk). No tvOS, webOS, or Tizen support was established. Check exact architecture, SDK version, and packaging requirements again at activation; platform names do not imply Flutter or TV compatibility. The [release notes](https://discord.com/developers/docs/social-sdk/release_notes.html) showed 1.10.19337 dated 2026-09-01 when inspected.

### OAuth, RPC, bots, and Activities

The [OAuth scope table](https://docs.discord.com/developers/topics/oauth2) marks capabilities such as `voice`, `dm_channels.read`, and several RPC scopes as requiring approval. `messages.read` concerns the local RPC API, not general permission for arbitrary REST message history. Ordinary sign-in scopes and the existing presence integration do not unlock a full client.

[Local RPC](https://docs.discord.com/developers/topics/rpc) depends on a Discord desktop client and appropriate authorization. It can be a companion integration where permitted, but does not make PlezyNG independently capable of Discord calls. A bot operates under its own identity and permissions; a webhook posts to its configured destination. Neither is the user's personal client. The [Embedded App SDK](https://docs.discord.com/developers/activities/overview) hosts Activities inside Discord, the opposite embedding direction to Discord inside PlezyNG.

### Terms and redistribution

The repository is [GPL-3.0 licensed](../../../LICENSE). Review the [Social SDK terms](https://support-dev.discord.com/hc/en-us/articles/30225844245271-Discord-Social-SDK-Terms) against the actual intended distribution and dependency licenses before adopting proprietary SDK binaries. The [GNU licensing FAQ](https://www.gnu.org/licenses/gpl-faq.html.en) is relevant background, not a project-specific legal clearance. A wrapper, dynamic link, or separate process does not automatically settle compatibility; an exception would require appropriate rights holders. **Status: unresolved**, not a claim of either compliance or impossibility.

Discord's [self-bot policy](https://support.discord.com/hc/en-us/articles/115002192352-Automated-User-Accounts-Self-Bots) prohibits normal-account automation outside supported OAuth/bot mechanisms and warns of account termination. Do not infer that every manually operated third-party client is technically identical to an automated self-bot. Equally, do not promise that a personal, noncommercial client is approved or immune to enforcement. Unofficial-client distribution, authentication, and account-policy exposure require a specific future decision; enforcement probability is **unknown**.

## Native client reuse candidates

| Project | Useful evidence | Reuse conclusion |
| --- | --- | --- |
| [Bonfire](https://github.com/OpenBonfire/bonfire) | Flutter Discord client, GPL-3.0; Firebridge is a user-account adaptation of Nyxx | Best structural starting point found for Dart models/REST/gateway research; audit exact files, licenses, and current maintenance before importing |
| [Dissent](https://github.com/diamondburned/dissent) | Go/GTK client; explicitly lacks voice | Useful text-client reference; not a calling solution |
| [Vesktop](https://github.com/Vencord/Vesktop) | Electron/Vencord Discord web client; Linux screen-sharing/audio work | Useful browser/desktop reference; not a native Flutter transport module |
| [Dorion](https://github.com/SpikeHD/Dorion) | Tauri Discord web client targeting desktop | Useful embedding reference; no proof of PlezyNG compositor or mobile/TV support |

Bonfire inspection used revision [`97a989e2c179e9e4c2f3282f1c6bfe7f04fcac6b`](https://github.com/OpenBonfire/bonfire/tree/97a989e2c179e9e4c2f3282f1c6bfe7f04fcac6b). Its [join path](https://github.com/OpenBonfire/bonfire/blob/97a989e2c179e9e4c2f3282f1c6bfe7f04fcac6b/lib/features/voice/repositories/join.dart) advertises `maxSecureFramesVersion: 0`; the inspected [voice connection](https://github.com/OpenBonfire/bonfire/blob/97a989e2c179e9e4c2f3282f1c6bfe7f04fcac6b/packages/firebridge/lib/src/voice_gateway/connection.dart) handles string JSON frames, and its [opcode model](https://github.com/OpenBonfire/bonfire/blob/97a989e2c179e9e4c2f3282f1c6bfe7f04fcac6b/packages/firebridge/lib/src/models/voice_gateway/opcode.dart) does not describe the newer DAVE message family. **Moderate-confidence inference:** this inspected path is not a ready-made current DAVE implementation. No live test established the status of every Bonfire branch or build.

Copying a client UI wholesale would also bypass PlezyNG's navigation, accessibility, localization, profile model, and session ownership. Prefer narrow, attributed reuse after a protocol and license audit. Pin revisions and record patches; do not depend on an untracked upstream branch.

## Encrypted calls are a separate engineering project

Discord announced DAVE across platforms and required it for ordinary DM/group calls, guild voice, and Go Live from March 1, 2026; Stage channels are a documented exception. Its [rollout announcement](https://discord.com/blog/bringing-dave-to-all-discord-platforms) and [enforcement follow-up](https://discord.com/blog/every-voice-and-video-call-on-discord-is-now-end-to-end-encrypted) mean an old unencrypted voice implementation is not a suitable baseline for normal calls.

Use the official [voice connection documentation](https://docs.discord.com/developers/topics/voice-connections), [DAVE protocol](https://github.com/discord/dave-protocol/blob/main/protocol.md), and [MIT-licensed libdave](https://github.com/discord/libdave). Native integration must coordinate voice signaling, binary MLS messages, protocol transitions, membership changes, reconnection, and encoded-frame protection. Transport encryption and DAVE end-to-end encryption are separate responsibilities. Never silently fall back to unencrypted media when negotiation fails.

The [libdave C++ build](https://github.com/discord/libdave/blob/main/cpp/README.md) has native crypto/build dependencies, including MLS and TLS-library integration. [flutter_webrtc's E2EE support](https://github.com/flutter-webrtc/flutter-webrtc/blob/main/Documentation/E2EE.md) provides frame-cryptor primitives, not evidence of Discord/DAVE protocol interoperability. **Moderate-confidence inference:** a custom native integration or maintained fork may be required to reach the necessary encoded-frame hooks. Prove that seam before committing to a Flutter WebRTC package or a client fork. The existing mpv movie player is not this RTC engine.

## Embedded web feasibility

Loading Discord's own web UI delegates its evolving UI, authentication, and call protocol to Discord. It does not by itself prove that embedding is supported, that calls work in the chosen engine, or that individual video tiles can become native workspace surfaces. A whole webview is one pane; DOM/internal-API extraction would create another brittle integration.

PlezyNG vendors [`flutter_inappwebview` 6.2.0-beta.3](../../../packages/flutter_inappwebview/pubspec.yaml) with [local patches](../../../packages/flutter_inappwebview/PLEZY_PATCH.md). Its manifest registers Android, iOS, macOS, web, and Windows, **not Linux**. Thus the present package cannot simply be assumed to provide the desired Linux Discord surface.

Upstream's [WPE Linux backend](https://github.com/pichillilorenzo/flutter_inappwebview/blob/master/flutter_inappwebview_linux/WPE_BACKEND.md) is a candidate for texture integration; actual WebRTC, codec, permission, and encoded-transform support depends on its build/runtime. [webview_cef](https://github.com/hlwhl/webview_cef) is another candidate: inspect offscreen rendering, native texture sharing versus CPU copies, and the exact per-platform support of a pinned revision. [FlutterFlow's flutter_cef](https://github.com/FlutterFlow/flutter_cef) was experimental with incomplete platform coverage at research time. None was run inside PlezyNG during this investigation.

Qualification must cover login redirects/popups, cookies, MFA/challenges, microphone and camera prompts, current encrypted calls, screen capture, IME, accessibility, sandboxing, resource use, and surface moves. Do not disable browser security or expose a broad privileged JavaScript bridge to remote Discord content. Reparenting an external Discord desktop window is not a dependable cross-platform strategy, especially under Wayland.

## System PiP and background operation

[Android PiP](https://developer.android.com/develop/ui/views/picture-in-picture) is a constrained activity/video presentation with limited actions, not ordinary full chat interaction. [Apple video-call PiP](https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-for-video-calls) requires the appropriate native content source and rendering integration. A Flutter widget or existing movie PiP bridge does not automatically satisfy it. These are optional adapters after in-app PiP works.

Ongoing mobile voice and receiving a new call while suspended are different problems. Android has [foreground-service start and while-in-use permission restrictions](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start). Apple requires appropriate [PushKit integration](https://developer.apple.com/documentation/pushkit/supporting-pushkit-notifications-in-your-app) and [VoIP notification handling](https://developer.apple.com/documentation/pushkit/responding-to-voip-notifications-from-pushkit) for that class of call wake-up behavior. A foreground Discord gateway connection alone does not establish an app-owned incoming-call push path. How PlezyNG could provide one for an unofficial client remains **unknown**; uploading user tokens to a relay is not an assumed solution.

## What remains unproven

No research step authenticated an account, sent a message, joined a call, measured latency/resource use, tested DAVE interoperation, embedded Discord in a PlezyNG build, or qualified any platform. No SDK production approval, account-policy exemption, licensing clearance, or ownership of a Discord application was obtained. Those are explicit [future gates](DELIVERY.md), not hidden prerequisites presumed complete.
