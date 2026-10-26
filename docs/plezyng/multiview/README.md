# PlezyNG Multiview — implementation handoff

Status: **planned, not implemented by this change**. Prepared 2026-10-26 for Luna. Source audit: `snapetech-org/PlezyNG` main at `b32e396c036b465136228b6ddc2e7c5b7fec3c4b` (2.24.1+157). Recheck moved interfaces before implementation. This directory is a documentation-only delivery.

## Decision

Build **Multiview** as a profile-scoped media workspace that preserves sessions while their presentation changes. The user can put a film beside a book, float a match above a comic, listen to music with its existing visualizer, or keep media beside a supported embedded game. Promote, swap, resize, park, and restore content without starting it over.

**User direction, incorporated 2026-10-26:** Plezy's own PiP/compositor is the primary implementation on every supported app platform. Build missing rendering adapters; do not depend on OS PiP availability to expose the feature. System PiP is an optional outside-app continuation route. The target is the same interaction model and media combinations across platforms, with quality scaling and alternative rendering backends before a quick-switch fallback.

Use one interaction vocabulary across these presentation mechanisms:

| User action | Mechanism | Scope |
|---|---|---|
| Open alongside | Two or more layout regions | Inside PlezyNG |
| Float in Plezy | Movable, resizable application panel | Inside PlezyNG |
| Picture in picture | OS-managed eligible video surface | Outside PlezyNG where supported |
| Pop out | Separate application window, optional keep-on-top | Qualified desktop platforms |

**High confidence:** a common app-owned PiP/layout model is feasible. **Moderate confidence:** native/custom-compositor/software paths can cover the full target on qualified devices; uninterrupted native transfers and constrained-TV performance require the specified spikes. **Low confidence:** identical maximum resolution, stream count and latency on every device. **Unknown:** market-wide uniqueness. The differentiated product is the integrated cross-media experience, not a claim that nobody has split screens or PiP.

“Universal” means the same app-owned actions and layouts, preserved state, and a full cross-media target across all current platforms. A missing OS PiP API is never a reason to omit in-app PiP. Use the backend ladder in [COMPOSITOR.md](COMPOSITOR.md) to address missing native functionality. Physical memory/compute limits and outside-app window restrictions still exist; no architecture can guarantee unlimited streams or arbitrary external iOS windows. Capability failure must produce a useful alternative, not a black tile or a false success.

## Does Plezy already support PiP?

Yes. The upstream `lib/services/pip_service.dart` and the audited fork expose native **Android handheld, iOS/iPadOS, and macOS video PiP**. This is source evidence, not fresh device qualification. In the fork:

- Android uses activity PiP on API 26+ with feature and permission checks; `isPipSupportedDevice()` explicitly excludes TV devices.
- iOS uses `AVSampleBufferDisplayLayer` and `AVPictureInPictureController`, with an iOS 15+ implementation path.
- macOS lends the existing video and OSD layers to a PiP window; its current controller explicitly uses private `PIP.framework`.
- tvOS has an explicit unsupported stub. Windows, Linux, and webOS have no native implementation through `PipService`.
- Music already has a persistent mini-player and visualizer. Neither establishes a general multi-session workspace.

The current `PlaybackCoordinator` deliberately tears down conflicting media. Native event channels have one current owner per channel. Simply placing two existing player screens in a `Row` would break ownership, progress, focus, or rendering. These are foundational changes, not just a new PiP button.

See [RESEARCH.md](RESEARCH.md) for immutable code references, platform evidence, and confidence levels.

## Product contract

1. Existing Play/Read actions keep their existing single-session behavior. **Open alongside** is explicit and never silently interrupts the current session.
2. Keep a small set of visible layout controls in existing player/reader controls and context menus. Do not add a new top-level navigation category, a dashboard of feature cards, or a separate visual language.
3. Preserve media identity, timeline, audio/subtitle choices, reader locator/zoom, game transport, and history when changing layout. A warm in-app swap must not reopen the source.
4. Visual prominence, keyboard/remote focus, audible output, and game input are separate ownership concepts. Moving focus must never unexpectedly change audio or send input into a game.
5. Default to one audible session. Offer explicit **Listen to this** and qualified **Mix audio**. Display which session is audible and which is controlled.
6. Support every media pair at the model and UI layers, including two videos and game plus media. Build native and custom/software renderers to extend actual coverage. At runtime select a viable backend/quality combination and admit only resources it can really provide.
7. When a pair cannot run together, offer **Keep open for quick switching**. A parked session is clearly paused or disconnected; it is never presented as live.
8. Minimize navigation disruption: browsing keeps the workspace available; profile/auth boundaries cover and retire all owned surfaces correctly.
9. Reuse `MonoTokens`, `MonoMotion`, `AppMenu`, existing overlay sheets, focus primitives, mini-player behavior, and the localization pipeline.
10. Accessibility, TV/controller operation, resource recovery, progress correctness, and platform fallbacks are release requirements.

## The experiences to deliver

| Example | Intended experience |
|---|---|
| Film + ebook/PDF | Open the publication alongside; film continues; document text reflows or page scales locally; either pane can expand without losing the other |
| TV + comic | Floating video avoids page controls and captions; comic reading direction remains independent of UI direction |
| Music + reading | Existing music session persists; artwork, lyrics, or visualizer occupies the companion pane; reading aloud requests narration ownership |
| Audiobook + matching ebook | Independent pair by default; use existing authored read-along alignment only when actually available; do not invent text/audio synchronization |
| Game + film/music/guide | Qualified embedded game retains its transport; switching input releases all held controls; a guide can expand without quitting the host game |
| Two live channels | Two independently identified streams when capacity permits, one audible; swapping prominence does not cross-wire EPG, tuner sessions, or DVR actions |
| Desktop reader pop-out + main film | Document becomes a real application window; it remains fully interactive and returns to its previous place |
| Limited TV | Attempt native/hybrid/custom rendering and suitable companion quality; offer an optional helper route if implemented, then preserved switching only when simultaneous rendering remains impossible |

## Read and implement in this order

1. [RESEARCH.md](RESEARCH.md): evidence and constraints.
2. [UX.md](UX.md): exact controls, layout, audio, help, and input behavior.
3. [ARCHITECTURE.md](ARCHITECTURE.md): session, transaction, surface, and persistence contracts.
4. [PLATFORMS.md](PLATFORMS.md): native adapter work and fallback decisions.
5. [COMPOSITOR.md](COMPOSITOR.md): app-owned PiP, custom rendering, software fallbacks, and parity policy.
6. [IMPLEMENTATION.md](IMPLEMENTATION.md): ordered work packages, concrete files, and completion gates.
7. [VALIDATION.md](VALIDATION.md): test cases and device qualification.
8. [wireframes.svg](wireframes.svg): schematic layouts using audited dark-theme tokens; these are proposed layouts, not screenshots of working functionality.

## First implementation slice

Start with MV01–MV05: characterize current single-player behavior; add identity and admission contracts; extract session lifetime from routes; introduce the profile workspace; deliver **one video plus one reader** and **music plus one reader** behind a flag. The first slice must already preserve positions and survive swap, navigation, profile change, and failed admission.

Then finish multi-instance native isolation before enabling two video decoders. Complete desktop windows, OS PiP adaptation, embedded games, multi-pane expansion, and qualification in the dependency order. Do not equate a mock adapter, a capability flag, a launcher, or this plan with a working media backend.

## Handoff boundaries

Games is a dependency, not an assumed completed backend. No `lib/games/` exists in the audited main tree. An in-progress local Games implementation inspected during this audit has `GameStreamingClient.open()` and an Android Moonlight activity, not a retained embeddable workspace surface. Its integration contract is captured here; Luna must locate the landed Games revision before editing it. Steam, beta codecs, and other game engines are only eligible when the actual engine implements the session/surface contract.

The current comic delivery document still lists renderer and device work as incomplete, and the publication reader rejects TV. Existing work may land during this handoff. Preserve it and integrate at the adapter boundary; do not replace the comic, localization, audiobook-sync, or Dolby Vision projects with parallel implementations.

No application tests, native builds, or device qualification were performed for this documentation change. Document structure, references, and wireframe rendering are checked separately. Release status must be recorded per backend and scenario as defined in VALIDATION.md.
