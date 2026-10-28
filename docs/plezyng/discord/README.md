# Discord client and PiP — deferred feasibility plan

**Status: FUTURE MAYBE — research and design only. Implementation is not approved, scheduled, or started by this document.** Merging these documents does not activate the project or advertise a new supported capability.

Recorded 2026-10-28 UTC following research on 2026-10-27 America/Regina. The owner requested a detailed repository record for possible future use, including the possibility of building our own Discord client. There is no delivery date, assigned implementation owner, or commitment to ship.

## Answer and recommendation

PlezyNG already has Discord **Rich Presence** and release-announcement plumbing. It does not have the full Discord account, messaging, and calling client proposed here. The existing Multiview workspace is a useful foundation for presenting chat, call controls, and received video alongside media, including floating them inside PlezyNG. The difficult work is the Discord connection and media engine, concurrent audio, and platform qualification.

**High confidence:** the audited code supports this distinction, and a communication surface can be designed around the existing workspace boundary. **Moderate confidence:** a native Flutter client with a separate native calling engine could deliver the intended desktop experience. **Unknown:** production access through Discord's official SDK for this product, acceptable distribution terms for each approach, and working voice/video on every PlezyNG target. No prototype, account login, real call, or device qualification was performed for this research.

If this is activated later, investigate a native client as the long-term design and use a bounded embedded-web experiment to compare feasibility. Decide the transport after proving the hard parts. Do not assume either that the official SDK is a complete Discord replacement or that an existing open-source client already handles current calls.

## Intended experience

A user starts a film, opens a Discord conversation alongside it, joins a call, and floats chat or a participant's video inside PlezyNG. Movie audio and call audio remain independently controllable. Resizing, promoting, splitting, or parking a surface preserves the underlying session. Keyboard input goes to the selected pane; microphone state changes only through explicit call controls or lifecycle/privacy rules.

The long-term client scope to evaluate includes account access, servers and channels, DMs, message history and composition, unread state, attachments, voice, received camera/screen streams, and eventually outgoing camera/screen sharing. These are separate delivery gates. Text support alone must not be labelled a complete Discord client, and lobby voice must not be labelled arbitrary Discord voice-channel support.

There are four distinct presentation targets:

| Target | Meaning | Planning position |
| --- | --- | --- |
| In-app PiP | A floating, interactive PlezyNG workspace pane | Primary target; includes chat and call controls |
| Split view | Communication and media in adjacent PlezyNG regions | Same session model as in-app PiP |
| Desktop pop-out | A separate application-owned window | Later, independently qualified; not the existing Discord window |
| System PiP | An OS-managed eligible video surface outside PlezyNG | Optional platform adapter; not a generic interactive chat window |

The in-app target must not depend on system PiP support. Preserve the broader [Multiview product contract](../multiview/README.md), while keeping Discord-specific support claims tied to measured results.

## Routes worth considering

| Route | What it could provide | Principal limitation | Position if activated |
| --- | --- | --- | --- |
| Existing local Rich Presence | Watching/listening status in a running Discord desktop client | No chat or calling client | Preserve as an independent feature |
| Official Social SDK | Account linking, friends, app DMs/lobbies, linked text channels, lobby voice | Restricted product semantics, access/rate limits, licensing review; no documented complete video client surface found | Choose only if its actual feature set satisfies an explicitly narrower product |
| Official Discord web app in an embedded browser | Discord's own UI and protocol implementation | Engine, permissions, authentication, compositing, audio control, and platform compatibility need proof | Useful feasibility comparator and possible first usable route |
| Native Flutter client with our own transport/media integration | Full control of PlezyNG UI, participant surfaces, audio, and layout | Unofficial user-account integration, protocol maintenance, DAVE, substantial native work | Most flexible long-term candidate; conditional, not selected |
| Bot, webhook, local RPC, or Discord Activity | Specific integration features | Different identity, permissions, or hosting direction | Adjuncts, not substitutes for the requested client |

“From scratch” should mean owning the missing product and integration code. Reuse audited protocol libraries and Discord's `libdave` where appropriate; writing cryptography from scratch is not part of the plan.

## Read this plan

1. [RESEARCH.md](RESEARCH.md) records current wiring, evidence, API restrictions, candidate projects, and primary sources.
2. [ARCHITECTURE.md](ARCHITECTURE.md) defines proposed session, transport, audio, rendering, privacy, and platform boundaries.
3. [DELIVERY.md](DELIVERY.md) defines activation decisions, ordered experiments, acceptance criteria, qualification evidence, and rollback.

The initial repository audit used [`bae33540a1bad9d230c519d1043d58da5c291f32`](https://github.com/snapetech-org/PlezyNG/commit/bae33540a1bad9d230c519d1043d58da5c291f32). Core Discord, workspace, PiP, settings/vault, startup, and webview source snapshots were compared against documentation baseline [`b8dca283e069bc86db59926257b27ab974999b33`](https://github.com/snapetech-org/PlezyNG/commit/b8dca283e069bc86db59926257b27ab974999b33) and were unchanged. File links below the documentation tree are navigation aids to current code; pinned references in the research preserve audit context.

## Conditions before any implementation

- The owner explicitly activates the project and chooses the minimum useful experience and acceptable integration route.
- Recheck Discord APIs, SDK availability, protocol versions, terms, upstream projects, and the current PlezyNG workspace. This is a dated research record, not an evergreen compatibility guarantee.
- Establish an acceptable authentication, licensing, and distribution approach. Personal use alone does not establish official support or remove account-policy uncertainty.
- Prove movie playback plus a current real Discord call, with independent audio and preserved session identity when surfaces move. For native voice, current DAVE interoperability is a prerequisite.
- Choose qualified platform targets and a maintenance owner. Keep unsupported targets explicit rather than promising identical capacity everywhere.

Until those conditions are deliberately actioned, all implementation stages remain **not started**. This documentation change adds no dependency, feature flag, account flow, permission, workflow, telemetry, capability-manifest entry, or release claim.
