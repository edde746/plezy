# Luna work packages and completion ledger

All packages start **not implemented** in this handoff. Read the audited main revision and the user's app-owned-PiP direction in README.md. A complete package requires real wiring and its checks; fake adapters, platform constants and documentation alone do not complete it.

## Working procedure

1. Fetch current main using the approved GitHub connector/workflow. Read applicable repository instructions. Preserve concurrent comic, localization, Games, sources, audiobook and DV work.
2. Identify changes since `62b2ed0f4dd8c287e026bcc356e65395366c6b4a`, particularly player lifecycle/native ownership and any newly landed Games interfaces. Update the evidence ledger without treating this old baseline as current code.
3. Establish existing analysis/test results before refactoring. Separate pre-existing failures from changes caused by Multiview.
4. Implement packages in dependency order, committing coherent slices and preserving single-player regression coverage. Follow the user's current publication/merge instructions; this plan does not authorize unrelated code or infrastructure changes.
5. Maintain DELIVERY.md with package status, commit, tests actually run, device evidence, unresolved issues and the next exact action. The implementation package creates that file; do not overwrite this plan's status with “complete” merely because an initial UI lands.
6. Keep app-owned PiP primary. Exhaust the appropriate native/custom/software paths before declaring a platform cannot run a combination. Never fake a live pane, game stream, visualizer data source, source sync or capability probe.

Proposed status values: `not_started`, `in_progress`, `implemented_unverified`, `verified_in_tests`, `qualified_on_listed_devices`, `blocked_with_evidence`. Track each platform independently for native packages. A package with a blocked required target remains incomplete.

## Packages

| ID | Deliverable and concrete integration | Dependencies | Required acceptance |
|---|---|---|---|
| MV01 | Baseline audit; inspect all fixed channels, profile lifetimes, player creation/retirement, PiP, current Games and reader adapters. Add characterization tests only for behavior this refactor can regress. Record runtime/SDK/dependency pins. | None | Baseline test results and architecture inventory; current source refs; no silent changes to default playback |
| MV02 | `lib/multiview/models/*`, typed IDs/commands/capabilities, pure workspace reducer and admission decisions. Versioned snapshots and progress-owner identity. | MV01 | Stale/duplicate commands, failed admission and profile-generation cases pass; no source credentials in snapshots |
| MV03 | Extract video/Live TV session from `VideoPlayerScreenState`; retained owner supplies the old fullscreen route and a new pane. Preserve timeline, seek, chapters, tracks, watch-together, retries, scrobble, display mode and teardown. | MV02 | Existing fullscreen tests pass; one video survives browse/resize/move without native reopen or duplicate report |
| MV04 | Retained music/source/publication adapters. Reuse queue/visualizer; separate reader checkpoint/controller lifetime, narration and loopback routes; fix singleton callbacks at the coordinator boundary. | MV02 | Music + reader coexist; two reader sessions never share locator/events/annotations; source profile checks remain effective |
| MV05 | Profile-scoped workspace shell, minimal Layout/Add another/Swap actions, session tray and route integration. First slice: video + current reader and music + current reader on currently working reader targets. | MV03, MV04 | Both sessions retain identity/position through ten swaps, browse/back and cancelled add; profile switch retires everything; legacy path works with flag off |
| MV06 | Per-instance native factories, command/event identity and retirement for Android mpv/Exo, Apple, Windows, Linux and webOS backends. Audit shared audio/display/OS-control ownership separately. | MV03 | Concurrent A/B open/play/seek/close does not cross-wire events or dispose B; native allocation failure leaves A intact; per-platform build/tests |
| MV07 | `WorkspaceSurfaceBroker`, window/view-aware placements, native clipping/visibility/z-order, lease transactions, occlusion and resize/scale acknowledgements. | MV05, MV06 | Two real video surfaces, reader/WebView overlap, profile-cover occlusion and swap rollback verified on each enabled path |
| MV08 | App-owned GPU-composition adapter candidates from COMPOSITOR.md. Integrate supported decoder/render-context outputs; implement frame lifetime/fence/color and independent clocks. | MV06, MV07 | No per-frame channel pixel copies; real overlapping video/reader/game surfaces; no incorrect timestamps, buffer reuse, color or subtitle regressions |
| MV09 | Hybrid/software fallback, especially webOS/TV companion. Reproducible native builds, bounded queues, actual source-rendition negotiation and measured admission. | MV08 | Real dual-video workload on target device; no false relief from downscaling after expensive decode; pressure recovery keeps main alive |
| MV10 | Portable reader surfaces: comic tiles; PDF native build/semantics; EPUB adapter for targets lacking a supported WebView. Integrate ongoing comic work and canonical locators. | MV04, MV07 | EPUB/PDF/comic corpus works with selection/search/zoom/resume/semantics as applicable; TV D-pad and CJK/RTL qualification; no fake unsupported-only adapter |
| MV11 | `WorkspaceAudioCoordinator`, transport-owner routing, single-audible policy, gain/mute, explicit qualified mix, TTS/duck/interruption handling and passthrough negotiation. | MV04, MV06 | Audio never changes on ordinary focus; two decoded streams mix where advertised; unsupported gain/passthrough produces real alternatives; OS keys target correct session |
| MV12 | Cross-media source semantics: server stream/tuner IDs, Live TV/DVR, Watch Together, cloud/offline/lending state, same-item deduplication and source failure containment. | MV03, MV04, MV06 | Closing pane A cannot terminate B's server session; no duplicate scrobble/progress; independent reconnect and source revoke behavior |
| MV13 | Complete responsive layouts, floating drag/resize/snap, safe regions, persisted ratios, pane-fullscreen, 3/4-pane presets, and parked tray. Generic layout model supports more slots subject to measured admission, not OS-name hard caps. | MV05, MV07 | Phone/tablet/foldable/TV/desktop text-scale and resize cases; every operation has a nongesture equivalent; no unreachable pane |
| MV14 | Workspace input router and focus scopes. Game-control lease protocol, input neutralization, relative mouse, multi-touch ownership, keyboard shortcuts and explicit TV pane switching. | MV05, MV13 | All held inputs released on every transfer/interruption; no focus stealing behind auth; complete touch, keyboard, remote and controller operations |
| MV15 | Real Games adapter: retained transport plus embeddable surface/resize/input/disconnect for each landed Moonlight/Steam engine. Refactor activity-only host; expose only actual engine capability; connect touch controls to viewport. | MV06–MV08, MV11, MV14; actual Games engines | Game + media simultaneously on each claimed platform; swap does not reconnect/quit host; beta codec claim only from actual negotiated decoder; input/latency device evidence |
| MV16 | Desktop pop-out hosts for Windows/macOS/Linux, UI-engine broker, plugin initialization, position/DPI persistence and dock-back. One owner for sessions, database writes and source auth. | MV07, MV11, MV13 | Move/dock without source reopen where promised; close/crash/monitor disconnect recover; second engine never duplicates playback or profile data |
| MV17 | Optional system PiP adaptation: scoped Android/iOS ownership, explicit restore semantics, legacy mac isolation/public route, supported tvOS bridge. System limitations do not disable our own PiP. | MV03, MV06, MV07, MV11 | Native lifecycle and restore/dismiss tests; captions and selected session correct; no Android TV media-category violation; no fabricated tvOS bridge |
| MV18 | Atomic workspace store, migrations, checkpoint/restore, error recovery, profile/auth/source revoke gates and window-close policy. Full teardown across windows/native planes. | MV04, MV12, MV16 | Crash/restart restores paused descriptors; no secret leakage or auto-game launch; revoked profiles cannot reappear from late callbacks |
| MV19 | Discoverability/help, first-use hints, localized strings and affordances, semantics, screen-reader actions, high contrast/reduced motion and large text. Reuse existing menus, controls and icons. | MV13, MV14 | All operations possible without drag/long-press; expanded translations and RTL/CJK pass; theme and focus visual review |
| MV20 | Device/resource modes, preflight/failure budgets, visualizer throttling, companion quality policy, thermal recovery and redacted diagnostics. Feature flags per implemented capability. | MV08–MV12, MV15 | No arbitrary OS exclusion for app PiP; measured limits; pressure does not kill main playback; truthful quality/fidelity state |
| MV21 | Full contract/integration/native regression suite and qualification harness; pairwise and lifecycle matrix from VALIDATION.md. Build all modified targets. | All preceding implemented packages | Evidence for each advertised combination/platform; retained old fullscreen/PiP behavior; failures reproduced and fixed rather than only documented |
| MV22 | Staged rollout, capability/help documentation, code/native/device ledger and final default enablement on qualified targets. | MV19–MV21 | Final claims match evidence; no remaining required package hidden behind “complete”; fallback paths and feature-off migration verified |

MV06, MV08, MV09, MV10, MV15, MV16 and MV17 require sub-rows for each native target in DELIVERY.md. “All platforms” cannot be satisfied by compiling only Dart. Do not start unrelated game-protocol development inside Multiview if its engine has not landed; identify that exact dependency and keep the game scenario open while finishing independent work.

## Milestones

| Milestone | What a user can actually do | Completion boundary |
|---|---|---|
| A — retained sessions | Video + reader; music + reader; browse and swap | MV01–MV05 plus relevant tests; not full dual-video or TV parity |
| B — common app-owned PiP | Float/split real concurrent media with audio/focus controls | MV06–MV14 and relevant MV18–MV21 evidence |
| C — full media workspace | Qualified game + media, desktop pop-outs, retained state and all reader targets | MV15–MV16 and reader/compositor platform rows complete |
| D — release qualification | Consistent experience on every claimed platform, native PiP extensions separately labeled | MV17–MV22; all required parity scenarios recorded |

Optional helper composition from COMPOSITOR.md is an extension package **MV-H1**, after MV20: define protocol/pairing/authorization, implement a real media compositor server/client, validate latency and source restrictions, then qualify limited-device use. It cannot replace missing core local reader/game work or be used to mark universal local parity complete.

## Concrete first patch sequence

1. Add pure SessionKey/ContentRef/WorkspaceCommand/AdmissionDecision models and tests. No user-facing toggle yet.
2. Wrap the current video owner behind a retained single-session adapter without changing source open, track selection or disposal rules. Characterization suite passes.
3. Add profile-scoped registry with legacy `PlaybackCoordinator` forwarding; do not remove current retirement safeguards.
4. Extract reader checkpoint lifetime and music presentation. Wire a minimal two-pane shell under an internal flag.
5. Prove a playing video plus a real EPUB/PDF/comic on a qualified reader target, then ten swaps, close and profile replacement. Persist a useful failure if no reader backend exists on that target.
6. Build genuine native instance isolation before second-video UI is enabled. Move on to GPU/hybrid and portable-reader adapters without leaving their platform rows permanently stubbed.

This ordering produces useful working slices while retaining the full target. It is not permission to stop after milestone A and declare the requested feature finished.

## Definition of code complete versus qualified

**Code complete:** real adapter and UI implementations wired through the app, deterministic unit/integration/native contract checks pass, native builds pass for the modified targets, no production TODO/mock-only branches masquerading as support, required localization/semantics/persistence/error paths implemented.

**Qualified:** the named device/backend/content/output scenarios pass reproducibly with measured performance/fidelity and evidence. A native compile, simulator, fake player test or source review is not device qualification.

**Feature complete for this request:** app-owned PiP and its common cross-media actions work on all current claimed targets, including the required simultaneous combinations and portable readers, within documented measured resource envelopes. If a required platform fails, explicitly retain that outstanding item and its next implementation step. Native outside-app PiP may remain unavailable where the OS does not offer it, without disabling the in-app feature.

## Suggested handoff instruction

> Read docs/plezyng/multiview/README.md and every linked specification. Implement the full app-owned Multiview/PiP plan using current main and the existing design contracts. Start with MV01–MV05, preserve current playback, then complete the native isolation, compositor/software fallbacks, portable readers, audio/input routing, Games adapters and desktop windows. Keep a truthful per-package/per-platform delivery ledger and run the specified checks. Do not stop at UI placeholders or treat system PiP absence as a reason to omit our own PiP. Publish implementation changes according to the user's active GitHub instructions.
