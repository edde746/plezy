# Conditional delivery and validation plan

**Status: FUTURE MAYBE. Every stage below is not started and requires a separate future activation decision.** This is a handoff for possible later work, not a backlog assignment or approved release plan. Documentation merging does not satisfy any implementation gate.

## Activation record

Before writing implementation code, add a dated decision here recording:

1. The owner who activated the project and the minimum useful experience: chat-only, social/lobby integration, embedded Discord, or a full native-client direction.
2. The intended distribution: local experiment, private builds, or public release; the authentication, Discord account-policy, and license assessment appropriate to that distribution.
3. The initial devices/platforms and the owner of protocol/security/dependency maintenance.
4. The available time/budget for a bounded feasibility experiment and the evidence that will stop or advance it. No calendar estimate is justified by this research alone.
5. The current repository revision, current Discord documentation/SDK/protocol versions, and pinned dependency candidates.

Current record: **not activated; no implementation owner, budget, delivery date, selected transport, or qualified platform**.

## Ordered stages and decision gates

| Stage | Work only after activation | Evidence required to advance | Status |
| --- | --- | --- | --- |
| 0 — Refresh and select scope | Re-audit code, API access, terms/licenses, candidate maintenance and native toolchains | Written scope and acceptable authentication/distribution path; revised source matrix | Not started |
| 1 — Transport/media feasibility | Bounded native-client experiment; embedded-web comparator if useful; SDK experiment only for an acceptable SDK-shaped product | Current real Discord interoperation and preserved PlezyNG playback; explicit route decision | Not started |
| 2 — Account/text/workspace | Profile-safe connection, minimum conversation UI, history/composer, retained surfaces | Text and layout/privacy acceptance tests pass on initial devices | Not started |
| 3 — Voice and concurrent audio | Call lifecycle, current encryption, audio policy, device selection and call dock | Film plus reliable two-way call; independent audio/mic controls; lifecycle and echo tests pass | Not started |
| 4 — Incoming video | Camera/screen-stream subscription, native textures, admission limits | Received video remains correct across workspace changes and call membership churn | Not started |
| 5 — Outgoing capture | Explicit camera/screen source selection, permission handling, share audio and mix-minus | No unintended capture/loopback; start/stop/revoke tests and performance gate pass | Not started |
| 6 — Wider platforms and continuation | Mobile lifecycle, native PiP, desktop pop-out, then separately qualified TV backends | Platform-specific qualification records; no automatic parity claim | Not started |
| 7 — Optional Watch Together | Invitations and independent lifecycle integration | No credential leakage; each participant retains independent media authorization | Not started |

The stage-1 prototype must exercise voice/video early even if polished text UI is delivered first. This prevents spending months on UI before discovering that the chosen media engine cannot implement current DAVE or coexist with the movie renderer. Stop or narrow scope when a gate fails; do not silently redefine a failed full-client route as success.

### Stage 0: refresh the dated evidence

- Compare current Discord and Multiview source with the [audit baseline](README.md#read-this-plan), including any newer audio policy, compositor, profile lifecycle, and credential changes.
- Re-read official API/SDK scopes, rate limits, release notes, platform requirements, terms, and DAVE documentation. Record checked versions and dates, not just homepage links.
- Reinspect Bonfire/Firebridge or another candidate at an exact revision. Confirm actual call behavior rather than relying on a README feature list. Audit transitive licenses and required notices.
- Determine whether an official route can meet the chosen product. Obtain any required production access before describing that route as shippable.
- Identify native build dependencies, signing/distribution requirements, codec licensing questions, binary update strategy, and exact supported architectures.

### Stage 1: decisive experiments

For a native candidate, establish user-controlled authentication under the chosen policy, list a permitted conversation, and perform a real current encrypted call with ordinary Discord clients. Exercise join/leave, another participant joining/leaving, mute/deafen, loss/resume of network, and session teardown. Add one received screen/camera stream. Prove the native encoded-frame hook and `libdave` integration; a successful generic WebRTC demo does not satisfy this gate.

For an embedded candidate, load Discord in the exact engine/build intended for shipping. Test sign-in/challenges, history/composition, microphone/camera permissions, a current call, and retained rendering inside a floating PlezyNG pane. Verify profile isolation, navigation restrictions, audio coexistence, and permission revocation. Identify whether a persistent call indicator and safe close behavior can work without unstable DOM/internal-API hooks.

Run the defining scenario on a representative Linux/Wayland desktop first if available, then verify Windows/macOS before assuming desktop portability. A small standalone native harness can isolate protocol problems, but advancement also requires the actual PlezyNG compositor and movie engine in the same process/product configuration.

Record route comparison with measured memory, CPU/GPU load, video frame behavior, call latency observations, audio quality, required native patches, binary size, and maintenance burden. Set numerical release budgets from the baseline and intended hardware before wider implementation; this plan invents no performance results. Decide native, embedded, narrower official SDK, or stop, with the reason recorded.

### Stages 2–5: implementation boundaries

Suggested locations, subject to the current repository architecture:

| Area | Candidate location or existing seam | Constraint |
| --- | --- | --- |
| Domain and transport | New `lib/discord/` feature module or equivalent | Keep protocols out of widgets; operation-level capability model |
| Native call integration | Dedicated package/plugin with platform code | Explicit native ownership; pinned source and reproducible builds |
| UI | Discord screens/widgets integrated with current navigation | Reuse theme/localization/accessibility, avoid parallel design system |
| Session presentation | Existing `lib/multiview/` adapters/models/controller | Preserve old media behavior and snapshot compatibility |
| Audio routing | Extend the existing ownership boundary with communication policy | Do not bypass the controller by leaving hidden engines audible |
| Credentials/settings | Existing vault and profile settings boundaries | No token fields in layout or portable settings |
| Presence | Existing `DiscordRPCService`, optional coordinator | Avoid duplicate publishers and preserve standalone Rich Presence |
| Native PiP | Existing PiP service plus new eligible call adapter | Do not assume the movie surface can be reused for an RTC call |

These directories and interfaces are proposals; this documentation does not create them. Keep implementation reviewable in independent changes. Do not simultaneously rewrite unrelated comics, games, media-server access, Dolby Vision, or Watch Together code.

## Defining acceptance scenario

A qualified build must demonstrate the following as one continuous session:

1. Start a representative movie and record its session/player identity and playback position.
2. Open a conversation and join a real call with another ordinary Discord client, using authorized test participants and content.
3. Hear both movie and remote voice; independently change their volume, mute the microphone, and deafen the call without losing the movie.
4. Type/select text, resize and move the pane, split/promote it, and restore it. The call remains connected, the movie does not reopen, and no duplicate decoder/player is created.
5. Receive a screen/camera stream where the claimed feature set includes it. Add/remove a participant and confirm media recovers through encryption transitions.
6. Hide/close the visible call surface and confirm the active-call dock remains obvious, or that the documented leave behavior stops capture. Explicitly leave, then verify microphone/camera indicators and native resources clear.
7. Switch or lock the PlezyNG profile and verify no private conversation, stale event, or capture survives into another profile.

A text-only product can qualify a narrower subset, but its status must explicitly exclude calling/video. A Social SDK product must name lobby/linked-channel limits. A browser-pane product must identify that rendering model and any host-control limitations.

## Validation matrix

All rows are **unrun** for this proposal. Future evidence should include build SHA, dependency revisions, OS/architecture, hardware/GPU, media route, scenario, result, and diagnostic artifact with sensitive data removed.

| Area | Essential cases | Passing behavior |
| --- | --- | --- |
| Authentication | Success, cancel, expired/revoked access, challenge, key store locked, account switch | Clear recoverable states; no credentials logged or copied between profiles |
| Account isolation | Profile lock/switch while callbacks and cache writes are in flight | Private surfaces disappear; stale writes/events rejected; capture stops |
| Messages | Initial history, pagination, edit/delete events, reconnect/backfill, denied channel, rate limits | Correct order/deduplication and permission handling; bounded memory; no retry storm |
| Composition | IME, Unicode, links, selection, attachments, failed send, duplicate submit | Normal text behavior, explicit retry/outbox state, no movie/game shortcut leakage |
| Permissions | Channel access changes, removed membership, blocked user behavior, linked-lobby membership | Server decisions respected; no stale private content newly exposed; restricted SDK semantics visible |
| Workspace | Float/split/promote/resize, route changes, park/restore, renderer-transfer failure | Stable live session, rollback on failure, no hidden duplicate player or orphan view |
| Voice encryption | Current ordinary-client interop, join/leave, membership/key changes, incompatible version | Working protected media or explicit failure; no silent unencrypted fallback |
| Reconnection | Wi-Fi change, outage, gateway/voice restart, sleep/wake | Bounded retries, truthful connection state, no stuck capture or duplicated media |
| Audio | Film plus call, gains, mute/deafen, ducking, headphones/speakers, Bluetooth/unplug, OS interruptions | Correct independent control, no sustained echo/loopback, policy restored on exit |
| Focus/control | Chat typing, game input transfer, push-to-talk key release/focus loss, remote navigation | No accidental media actions, stuck key, or live microphone |
| Incoming video | Camera and screen share, source resize, hidden stream, participant removal, decoder exhaustion | Correct texture lifecycle; useful quality reduction or refusal; existing movie survives |
| Outgoing capture | Source picker cancel, selected window closes, permission revoked, share-audio toggle, protected content | Only explicit permitted source captured; visible stop control; no received-voice feedback |
| Resource use | Sustained representative movie/call, low memory, thermal pressure, GPU context loss | Measured limits, bounded recovery, no leak or false success; no invented universal capacity |
| Media regression | Existing solo playback, subtitles, HDR/DV paths, multiple-media ownership, progress/history | Prior media behavior retained; no call-induced player restart or progress corruption |
| Browser security | External origin/popup, malicious message link, cookie isolation, crash/update | Restricted navigation/bridge; no app-secret or local-file access; controlled capture teardown |
| Mobile lifecycle | Background/foreground, lock, interruption, permission revocation, service limits | Claims match OS behavior; ongoing-call support separated from incoming-call wake-up |
| System PiP/pop-out | Enter/exit, close, orientation/resize, app background/return | Native ownership remains valid; controls/capabilities accurately limited |
| Accessibility | Screen reader, keyboard-only, reduced motion, high text scale, TV remote | Call state and stop controls always reachable; no focus trap |
| Removal/recovery | Logout, disable integration, corrupt cache, dependency unavailable | Client can be removed/recovered without harming existing media or Rich Presence |

Use meaningful unit tests for event ordering, account generations, retry policy, capability decisions, and audio-state transitions. Use integration/native tests for renderer ownership and teardown. Real-device/real-client evidence is required for calls, DAVE, capture, audio routing, and OS lifecycle; mocks cannot establish those properties. Avoid live services in ordinary deterministic CI, and do not record participant content or credentials in fixtures.

## Build and release rules

Follow the root [AGENTS.md](../../../AGENTS.md): all GitHub Actions build, test, scan, packaging, and release work uses compatible private ephemeral JIT runners. Missing capacity is a provisioning blocker, not permission for GitHub-hosted fallback. Preserve OS/architecture constraints, isolated untrusted-code execution, active jobs, and unrelated work. A new workflow must be validated at its actual revision.

Future native/browser/crypto dependencies need pinned revisions, reproducible packaging, license/notice inventory, and an update/rollback owner. Test the binaries actually distributed, including codec support and browser sandbox configuration. Do not treat a dependency's supported-platform list as PlezyNG qualification.

Keep experimental implementation opt-in until the relevant stage is qualified. Only then update the [capability ledger](../../maintainers/capability-manifest.json) with precise scope and evidence. An implemented adapter, successful build, mock test, and live device qualification are separate statuses. Do not add download badges or “Discord supported” claims based only on source presence.

## Stop conditions and rollback

Stop or narrow the product if authentication/distribution has no acceptable path, required official access is unavailable, current encrypted calls cannot be implemented reliably, the embedded route cannot safely expose capture state, or media coexistence fails on intended hardware. Record the failed assumption and measured result so a later attempt does not repeat it blindly.

Keep a route-independent disable path. Disabling a future client should stop capture and network sessions, retire its surfaces, restore ordinary media audio policy, and leave the existing presence setting and movie player usable. Define uninstall/cache deletion and snapshot downgrade behavior before adding persistent fields. A failed call/browser plugin must not make PlezyNG unable to start or play local/server media.

Rollback should remove the optional client path without deleting unrelated user media settings. Retain sanitized qualification evidence and dependency revisions in the repo. If the project returns to deferred status, state that explicitly in the plan and capability ledger rather than leaving an abandoned preview presented as active support.

## Open decisions

| Decision | Current position | Resolution needed before |
| --- | --- | --- |
| Full native client versus embedded client versus official social features | Unselected; native offers most UI control, embedded is a useful comparator | Stage 2 architecture commitment |
| Discord application ownership, approved scopes, production limits | Unknown beyond the existing public presence ID | Official account/SDK production path |
| Authentication and unofficial-client policy exposure | Unresolved; no token-harvesting or challenge-bypass design assumed | Native account experiment |
| Proprietary SDK compatibility and dependency license obligations | Requires specific assessment | Import/distribution of affected code/binaries |
| DAVE/native encoded-frame seam | Not prototyped | Native calling architecture commitment |
| Audio graph and speaker echo strategy | Proposed responsibilities only | Calling acceptance |
| Embedded host call controls without internal DOM reliance | Unknown | Embedded route selection |
| Mobile incoming-call push delivery | Unknown and separate from foreground/ongoing calls | Incoming-call background claim |
| TV engines, microphone/storage support, and capacity | Unqualified per target | TV availability claim |
| Default cache/draft retention and account removal behavior | Not selected | Persistent account/text storage |
| Numerical performance budgets and supported stream counts | No measurements | Platform qualification/release |
| Ongoing protocol, security, and upstream maintenance owner | Unassigned | Any supported release |

No row is implicitly resolved by merging this plan.
