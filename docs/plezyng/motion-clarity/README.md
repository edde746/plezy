# Motion & clarity: implementation handoff

Status: **design complete for implementation; no motion engine implemented or qualified by this PR**.

Prepared 2026-10-27 against PlezyNG `main` at
`af547078ff70df271b04fd35474b8caf7619fa6d`. Repository observations below refer
to that immutable snapshot. Reconcile later changes before implementation.

## Outcome

Build an optional player-side motion and clarity pipeline for movies, television,
local/network files, and live video. Its target is to meet or beat named TVs'
motion processing on measured content and hardware, with a restrained Cinema
preset as the preferred starting point. Support TV Game Mode or Cinema mode
with TV interpolation off. The player must actually deliver the processed frames
at the negotiated output rate, retain audio/subtitle synchronization and picture
format, and preserve ordinary playback whenever processing is unavailable.

The owner requested a detailed plan and a PR branch for another agent to
implement. This PR changes planning documents only. It does not enable settings,
install models, replace playback engines, or claim performance results.

## What can be achieved

| Problem | App action | Boundary | Confidence |
| --- | --- | --- | --- |
| Uneven cadence/judder | Recover telecine where justified; schedule rational timestamps; choose a compatible display mode; synthesize at actual output times when enabled | The OS/output path can refuse a requested mode; a 60 Hz app path cannot deliver 120 distinct images/s | High in method; device-specific support unknown |
| Low-rate stutter | Estimate motion and render intermediate positions; provide restrained and full smoothing | Completely removing 24 fps stepping changes its temporal appearance, even with perfect estimates | High in feasibility; low-SOE tuning moderate |
| Display persistence blur | Increase the rate of distinct, correctly timed images | App software does not control the panel's emission duty cycle or physical response; native BFI/strobing can retain an advantage | High |
| Camera/exposure blur already in the file | Optional conservative reconstruction, separate from interpolation and sharpening | Missing detail is not uniquely recoverable; deblur can invent detail or flicker | Moderate for selected SDR material; unknown for general HDR/film |
| Soft scaling | Preserve original resolution for reconstruction; apply one qualified scaler to the final picture | Upscaling does not recover ground truth and is not deblurring | High in integration approach |
| Better than TV processing | Paired, blinded tests on the same TV, source, output format and comparable motion appearance | No universal superiority claim; qualify model/firmware/preset/content combinations | Unknown until measured |

**All three problems can be addressed in the app. Complete elimination of every
kind of blur, zero stutter, unchanged 24 fps appearance, and superiority to every
TV are not jointly achievable guarantees.** The release criterion is a better
measured tradeoff, not a promise that contradicts those constraints.

## Read in this order

1. [Architecture and algorithms](architecture.md): frame ownership, scheduling,
   synthesis, restoration, HDR/Dolby Vision, platform adapters and resource policy.
2. [Presets, controls and user experience](presets-and-controls.md): exact initial
   settings, defaults, scope, help, comparison, accessibility and manual control.
3. [Implementation work packages](implementation.md): existing files, proposed
   files, dependencies, concrete completion criteria and handoff sequence.
4. [Qualification and TV comparison](qualification.md): deterministic tests,
   hardware matrix, visual tests, measurements and claim rules.
5. [Research and decisions](research.md): primary sources, evidence limits,
   selected approaches and rejected shortcuts.
6. [Preset seed data](presets.v1.json): machine-readable **design values**, not
   runtime configuration. Values are starting points to qualify, not optimality
   claims or benchmark results.

## Binding design decisions

- Product name: **Motion & clarity**. Presets: Original, Cinema, Balanced,
  Smooth, Animation, Sports; Custom appears after an edit. Quality and motion
  appearance are independent. Do not use proprietary TV preset names as our own.
- Existing installs and fresh installs start at **Original**, preserving current
  processing behavior and refresh preferences. The suggested opt-in is Cinema.
  Qualification is required before promoting any processed preset to a default.
- Use a native, bounded, timestamp-aware processing core, with engine adapters.
  Flutter sends configuration and receives low-rate status; it never shuttles
  full video frames or schedules frame generation.
- Baseline engines: a portable bidirectional block/flow implementation and
  a RIFE-family neural adapter. Start neural evaluation with Practical-RIFE
  4.25.lite and 4.25; test the established ncnn RIFE graph as a portability
  reference. New weights are not drop-in compatible with old ncnn graphs.
- Keep ordinary mpv/libplacebo temporal blending as an explicitly named
  cadence-blending comparison/fallback, never call it optical-flow generation.
- Camera-blur restoration is an explicit **experimental** control, off in every
  built-in preset. Implement and evaluate a bounded NAFNet adapter and compare
  joint interpolation/deblur research offline; fail the feature's quality gate
  if the results do not improve motion without unacceptable artifacts.
- The source, GPU, decoder, display mode, renderer, colour path, battery state,
  and concurrent sessions determine a capability tuple. Never equate an OS name,
  GPU model, successful property write, or requested Hz with qualified support.
- One owner negotiates output cadence. Source FPS and synthesized output FPS
  remain separate throughout Dart, native code, diagnostics and display voting.
- Preserve native Dolby Vision by default. If processing cannot preserve it,
  retain ordinary playback and explain why. A user may explicitly choose a
  qualified HDR10/SDR processing route; do not silently make that choice for them.
- Separate subtitles, OSD and controls are composited after motion processing.
  Burned-in text needs conservative handling; it cannot simply be removed.
- No per-frame image files, external Python process, unbounded queue, arbitrary
  downloaded model execution, or network service in the ordinary playback path.
- Local processing is the primary product. A separately enabled companion can
  prepare derived versions for constrained devices; it cannot exceed their
  decoder/output limits and does not replace the local implementation.
- Keep diagnostics honest: requested, effective and measured states, distinct
  generated-frame counts, fallback reasons, and qualification evidence IDs.
- Respect [AGENTS.md](../../../AGENTS.md): private ephemeral JIT runners only,
  existing trust boundaries, no hosted fallback. Do not turn workflow triggers
  back on or dispatch releases as part of this plan.

## Delivery gates

| Gate | Deliverable | Not sufficient |
| --- | --- | --- |
| G0 | Instrumented current playback baseline; verified clocks and frame IDs | A shader checkbox |
| G1 | Correct cadence and deterministic scheduler across all adapters | Average FPS only |
| G2 | Real intermediate-frame pixels in an embedded desktop SDR player | Standalone conversion output |
| G3 | Cinema/Balanced/Smooth and resource governor pass visual and timing tests | A successful model invocation |
| G4 | HDR/scaling/restoration and Android/Apple ports qualify separately | SDR results relabelled as HDR |
| G5 | TV-native capability outcomes and companion path verified where used | A panel's advertised refresh rate |
| G6 | Published reproducible comparison against named TVs, with film-look results | “AI” or “120 Hz” marketing |

Unqualified capability combinations remain unavailable with a useful explanation;
the application continues its established playback path. Completion of an adapter
is recorded independently from qualification on a physical device. The
implementation tracker must distinguish implemented, tested, qualified and blocked.
