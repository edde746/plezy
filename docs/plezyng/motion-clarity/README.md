# Motion & clarity: runtime and implementation roadmap

Status: **mpv temporal blending and an experimental FFmpeg motion-compensated path are implemented; source-blur restoration, native TV processing and hardware qualification remain unimplemented**.

The original repository inventory was prepared against PlezyNG `main` at
`af547078ff70df271b04fd35474b8caf7619fa6d`. The implementation changes were
rechecked against this PR branch before editing; the inventory tables below still
describe the original design baseline where stated.

## Outcome

Build an optional player-side motion and clarity pipeline for movies, television,
local/network files, and live video. Its target is to meet or beat named TVs'
motion processing on measured content and hardware, with a restrained Cinema
preset as the preferred starting point. Support TV Game Mode or Cinema mode
with TV interpolation off. The player must actually deliver the processed frames
at the negotiated output rate, retain audio/subtitle synchronization and picture
format, and preserve ordinary playback whenever processing is unavailable.

This PR adds two optional mpv processing paths. It exposes Original, Cinema, Balanced,
Smooth, Animation, Sports, OLED and Custom profiles in Playback Settings and
the in-player settings sheet. Temporal blend exposes a temporal kernel and
interpolation threshold. Experimental motion compensation uses FFmpeg
`minterpolate`, with a generated-rate choice and Fast/Balanced/High motion-search
effort. The opt-in OLED profile selects motion compensation at the current renderer-reported
display cadence when available. This can reduce perceived OLED sample-and-hold blur,
but it is not panel calibration; full-rate interpolation can look video-like and the
renderer-reported rate does not prove physical scanout. The settings share one global, library or title scope. VOD and live-stream
startup resolve those values before opening the decoder. The in-player sheet has
a quick A/B control that bypasses the active motion filter while keeping the
selected display mode, spatial scaling and audio settings in place. Original
remains the default.

Temporal blend requests display synchronization (`display-resample` with decoded
audio, `display-vdrop` with bitstream passthrough), mpv interpolation, a temporal
kernel, a threshold and bounded decoder reference surfaces on outputs with a GPU
render stage (`gpu`, `gpu-next`, `libmpv`). Threshold 0 maps to mpv's documented
always-interpolate sentinel. Motion compensation installs a labelled mpv `lavfi`
filter for FFmpeg `minterpolate`; if the filter is absent or rejects its options,
the service falls back to temporal blend and reports why. Android mpv suppresses
source-rate switching for generated video and can request the selected generated
rate instead; current-display mode keeps the active cadence. The operating system
may decline an explicit rate. Existing Shader presets remain responsible for spatial
upscaling, after the video filter. These are accepted requests, not measured
presentation or quality results.

## Product target and runtime boundary

### Current implementation boundary

Temporal blend uses mpv temporal convolution to combine adjacent decoded frames at
display-synchronous times. It can soften or double moving edges and is not optical
flow. The experimental motion-compensated path uses FFmpeg's block-based motion
estimation and compensation to synthesize intermediate frames at a selected rate.
It is CPU-intensive, can warp or ghost objects around occlusions and cuts, and its
search-effort tiers change computation cost rather than interpolation strength.
Neither path has automatic device benchmarking or a soap-opera-free guarantee.
The operating system and renderer determine whether generated cadence is presented.

The OLED profile can reduce perceived sample-and-hold blur by supplying distinct
intermediate pictures toward the active display rate. It cannot change the panel's
physical emission time or remove camera/exposure blur already captured in the source.
OLED refresh modes, response, processing limits and viewing conditions vary by set; It does not add neural RIFE interpolation,
NAFNet deblur/restoration, a hardware resource governor, native decoded-frame
adapters, Dolby Vision processing or webOS/Tizen frame access. MCI output-rate and
search-effort choices are manual and unqualified. No TV superiority, image-quality,
frame-rate, HDR, battery or performance result has been established. The broader
architecture and gates below remain the plan for that work.

The table below describes the broader product target, not the feature coverage
of this PR.

| Problem | Planned app action | Boundary | Confidence |
| --- | --- | --- | --- |
| Uneven cadence/judder | Recover telecine where justified; schedule rational timestamps; choose a compatible display mode; synthesize at actual output times when enabled | OS/output may refuse a mode; 60 Hz cannot present 120 distinct images/s | High in method; device-specific support unknown |
| Low-rate stutter | Estimate motion and render intermediate positions; offer restrained and full smoothing | Removing 24 fps stepping changes its temporal appearance | High in feasibility; low-SOE tuning moderate |
| Display persistence blur | Increase the rate of distinct, correctly timed images | App software cannot change panel emission duty or physical response | High |
| Camera/exposure blur | Optional conservative reconstruction, separate from interpolation and sharpening | Missing detail is not uniquely recoverable; restoration can invent detail or flicker | Moderate for selected SDR material; unknown for general HDR/film |
| Soft scaling | Preserve source detail for reconstruction; apply one qualified scaler to final picture | Upscaling is not deblurring | High in integration approach |
| Better than TV processing | Paired, blinded tests on same TV, source, output format and motion appearance | No universal superiority claim; qualify model/firmware/preset/content combinations | Unknown until measured |

**The app can improve some motion and clarity problems, but it cannot guarantee
zero blur, zero stutter, unchanged film cadence and superiority to every TV at
once. This PR implements cadence blending only.**

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
  Smooth, Animation, Sports, OLED; Custom appears after an edit. OLED is an
  opt-in display strategy, not an automatic panel detector or per-model calibration.
  It targets the renderer-reported current cadence through MCI and may produce a
  video-like look; users can switch to Cinema or Original at any time. Quality and motion
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
