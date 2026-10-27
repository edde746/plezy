# Qualification and comparison against TVs

This is a test specification, not test results. Numerical gates are proposed
engineering/review criteria and must be versioned before collecting the confirming
dataset. Confidence in comparative performance is **unknown** until these tests run.

## 1. Evidence and test corpus

Keep separate levels: unit/reference, native engine, embedded app, physical-device
presentation, perceptual/TV comparison. Passing a lower level never implies a higher
one. A model benchmark does not qualify an app; a submitted frame does not prove
scanout; a Dolby badge does not prove correct FEL pixels.

Build generated, redistributable fixtures with exact ground truth:

- Linear/accelerating pans, thin lines, text, rotating spokes and gratings.
- Several depths, moving occluders and newly revealed backgrounds; balls crossing
  goal nets; multiple independently moving objects.
- Hard cuts, one/two-frame flashes, dissolves, strobe lighting, fades and black bars.
- Source rates 12, 15, 23.976, 24, 25, 29.97, 30, 50, 59.94, 60 and 120; VFR, duplicate
  PTS, timestamp quantization and discontinuities; telecine and genuine interlace.
- Animation on twos/threes, stop-motion, repeated drawings with moving backgrounds,
  rolling credits, separate and burned-in captions.
- Clean sharp sources and known exposure integration at several shutter intervals;
  realistic noise/grain/compression on both clear and blurred inputs.
- SDR ramps, saturated colours, PQ/HLG highlights, clipping/range/chroma patterns,
  synthetic FEL-on versus EL-dropped controls where the existing engine supports them.

Construct low-rate/shutter-blurred inputs from a much higher-rate reference using
documented linear-light exposure integration and correct sample times. Do not
compare against unaligned high-rate frames or use gamma-space averaging as physical
exposure ground truth. Keep training/tuning fixtures separate from final evaluation.
Use permitted natural film/sports clips locally to catch domain failures; record
rights/source but do not commit restricted media. Do not select only flattering clips.

Per-result record: application/engine/model/export hashes; device/GPU/driver/OS;
source hash/rate/scan/format; display model/firmware/mode; requested/effective
configuration; timing observation method; copy path; warmup/thermal state; sample
count; metrics; confidence interval where meaningful; failures and raw evidence.

## 2. Deterministic correctness cases

| ID | Case | Required result |
| --- | --- | --- |
| TIM-01 | 24->60/120/144 and 30->60/120/144 | Exact scheduled phases; real intermediates where selected; no accidental 3:2 in full smoothing |
| TIM-02 | 24000/1001, 30000/1001, 60000/1001, 120000/1001 | No integer rounding; long-run rational schedule matches oracle |
| TIM-03 | 25/50 at 50/100 and at fixed 60/120 | Preferred compatible family or correctly sampled arbitrary-rate conversion |
| TIM-04 | VFR, unknown/false nominal FPS, quantized/duplicate PTS | Actual PTS governs; duplicates/gaps handled without division by zero or invented chronology |
| TIM-05 | 29.97 telecine, true 59.94i, mixed edits | IVTC only where justified; full field-rate motion retained; no double deinterlace |
| TIM-06 | Playback 0.5x/1x/1.25x/2x and unsupported extremes | Rate applied once; audio policy retained; explicit fallback outside qualified speeds |
| TIM-07 | Ten-hour virtual clock, clock drift and audio passthrough | No cumulative rational timing error; no silent bitstream conversion or speed change |
| TIM-08 | OS denies mode switch; 120 Hz display with 60 Hz app surface | Effective capability/metrics reflect actual submission/presentation limit |
| TIM-09 | Source matcher fires after motion activation | One owner; cannot change generated output back to source FPS |
| TIM-10 | Pause/seek/EOF/discontinuity/start-paused | No future/stale frames; source clock, paused intent and EOF behavior preserved |
| TIM-11 | Display hotplug/window move/rotation/HDR renegotiation | Reprobe; restore only owned display changes; no endless switching |
| TIM-12 | 48 generated fps on 120 versus 96/144 Hz | Detect incompatible repeat cadence; do not describe 48->120 repetition as uniform |
| OLED-01 | OLED preset on renderer-reported 60/120/144 Hz outputs | Select current reported cadence when MCI can configure it; surface fallback and distinguish reported Hz from panel scanout |
| OLED-02 | 24/30 fps on 60/120/144 Hz OLED panels, with panel motion processing off | Measure distinct presented frames, motion blur, judder, interpolation artifacts and film-look preference per panel; no cross-model claim from one set |
| SYN-01 | Translating object with known position at u=0/.2/.5/.8/1 | Endpoints and arbitrary intermediate positions agree with expected method |
| SYN-02 | Foreground/background occlusion | No persistent duplicated edges or revealed-content hallucination accepted silently |
| SYN-03 | Cuts/flashes/dissolves | No cross-shot synthesis; flash timing survives; no invented dissolve |
| SYN-04 | Fences/rain/smoke/fast hands/balls/grain | Quantify artifacts and fallback; compare full-speed viewing, not PSNR alone |
| SYN-05 | Held drawings/credits/text | Intentional holds preserved; text remains legible; separate OSD never warped |
| SYN-06 | Restrained timing curve | Endpoints, monotonicity, bounds and s=1 identity; s=0 exact bypass; evaluate acceleration pulses |
| SYN-07 | Quality changes, scaled analysis, model padding | Same temporal look, no spatial pulsing/crop/tile seams; consistent source geometry |
| SYN-08 | Runtime export/FP16 vs reference and non-midpoint model input | Documented tolerances and no unsupported model graph substitution |
| BLR-01 | Exposure-blurred known reference | Restored result improves relevant detail without excessive temporal errors |
| BLR-02 | Already sharp film, grain, text and skin | No unnecessary restoration, waxy texture or invented high-frequency detail |
| BLR-03 | Occlusion/cut/flash during restoration | Residual/history cannot leak across boundaries |
| BLR-04 | Real camera blur versus synthetic benchmark | Report domain failures; qualify the narrower scope if needed |
| BLR-05 | SDR-only model selected on HDR | Bypass with reason; no clipping/tone-map-inversion shortcut |
| COL-01 | Limited/full range, 709/2020, PQ/HLG, 10/12-bit source | Correct output transforms, no gamut shift or unintentional 8-bit intermediate |
| COL-02 | Static HDR ramps/highlights with generation enabled | No new banding, clipped highlights or tone-map pumping relative to same output baseline |
| COL-03 | P5, P7 MEL/FEL, P8 identified sources | Native bypass or explicitly qualified conversion; no fake HDR10 P5 or hidden EL loss |
| COL-04 | Post-FEL generated frames and RPU changes | Source-pair association and residual evidence correct; no copied native-DV claim |
| COL-05 | HDR10+/DV dynamic metadata around cuts | Explicit supported treatment or declared bypass; no blind metadata copying |
| COL-06 | Existing scaling, custom shaders, zoom, ambient light and subtitles | Defined order; no filter clobber or double tone map; original modes remain reversible |
| RES-01 | Startup compile, warm/cold cache, model not installed | Responsive UI, bounded wait, accurate state and ordinary playback fallback |
| RES-02 | GPU load/thermal/battery saver/OOM/device loss | Bounded memory/work, no hang; coherent fallback with reason |
| RES-03 | Native + neural copy-heavy path | Report actual transfer bytes/times; admission includes transfers |
| RES-04 | Main + companion video, PiP, background/resume | Shared budget; per-session epochs and release; focused session priority |
| RES-05 | 100 repeated seek/start/stop/dispose cycles | No growing retained buffers, stale callbacks, leaking decoder surfaces or deadlocks |
| INT-01 | Plex/Jellyfin/Emby/local/SMB/download playback | Same feature contract; credentials never appear in logs/cache keys |
| INT-02 | Audio passthrough/PCM/Apple audio, subtitle types and offsets | A/V/sub timing retained; rendering capability does not change track selection |
| INT-03 | Episode transition, multiversion, chapters and Watch Together | Source timeline and explicit play intent preserved |
| INT-04 | Exo fallback, native DV, secure/opaque/tunneled route | Supported path identified; no silent backend/format substitution |
| INT-05 | Steam/Moonlight, Cast and external player handoff | No movie-processing latency injected into interactive streams; receiver truth shown |
| UX-01 | Preset/custom edits, rapid slider writes, Cancel and Back | Last current revision wins; cancel restores preview state |
| UX-02 | Scope/title identity/import/export/reset/profile switch | Correct precedence, safe migration, no stale capability claims |
| UX-03 | Remote/keyboard/touch/screen reader/large text/RTL/CJK | Controls/help/actions reachable and clearly labelled |
| UX-04 | Requested120/effective60, unsupported HDR/model, temporary load | Clear status; no inactive control masquerading as successful processing |
| SEC-01 | Malformed dimensions/PTS/schema/model metadata/config | Native boundary rejects safely; overflow/fuzz/sanitizer checks |
| SEC-02 | Modified/truncated/wrong model pack or stale compiled cache | Hash/manifest rejection and known-good fallback; no runtime pickle execution |
| SEC-03 | Malicious media URL/title/credential in diagnostics | Redacted structured reports; no shell argument construction or media exfiltration |

Algorithm-specific image tolerances must be set from fixed fixtures before
regression testing. Do not require pixel identity between every GPU's floating
point path; do require source endpoint/color correctness within a justified bound,
deterministic scheduling and no unexplained quality regressions.

## 3. Performance and physical presentation gates

At each advertised resolution/format/output/engine tuple:

For the currently implemented experimental FFmpeg path, record the exact mpv and
FFmpeg build hashes and prove `lavfi`/`minterpolate` availability on every shipped
artifact. Characterize 23.976/24, 25, 29.97/30, 50, 59.94/60 source rates against
each selectable 48–144 fps target the device can actually request. Exercise hard
cuts, flashes, dissolves, occlusion, pans, animation holds, subtitles, HDR metadata,
seek, pause/resume, audio passthrough and live retunes. Record CPU, GPU,
hardware-decoder readback, peak memory, p50/p95/p99 processing time, dropped and
repeated frames, A/V skew, filter activation/fallback reason and actual display
mode. For the OLED profile, include at least one 60 Hz OLED and one 120 Hz OLED with their
native motion features disabled. A device-reported refresh request alone is not
evidence of panel presentation. The OLED result must be reported independently
for each display model, firmware, input cadence and picture mode; no general OLED
or TV superiority claim follows from this profile.

The current adapter has no multi-signal resource governor or device benchmark.
A runtime circuit breaker watches mpv's cumulative `frame-drop-count` and falls
back to temporal blending after three consecutive 2-second windows with new drops.
This counter is a heuristic and cannot identify processor headroom or prove physical
scanout. Verify the trigger, fallback and visible reason, and still record every
missed deadline as a qualification failure; the guard must never turn a failed run
into a pass. A successful filter insertion is not a qualification result.

- Ten-minute nominal run after warmup: zero unexplained missed presentation slots
  caused by the motion pipeline. Explicit cut/source repeats are separately counted.
- Two-hour steady playback plus load transitions: no monotonic memory growth,
  unbounded queue, sustained thermal collapse or A/V drift. Exercise fallback and
  recovery; reported effective tiers must match actual work.
- Admission starting target: end-to-end p95 <= 0.8 output periods and p99 <= one
  period, including decode/interop/presentation cost and per-interval bursts.
  Report CPU and GPU timelines separately; average FPS is insufficient.
- Added A/V skew relative to Original: <= 10 ms in steady state, with absolute
  audio/video skew separately reported. After a seek or mode change, return within
  that bound within one second of actual playback resuming. These are engineering
  targets, not an assertion about perceptual thresholds for all viewers.
- Report deliberate content-sample offsets from restrained retiming independently
  of clock skew; inspect lip motion and flash/audio events against Original. A
  correct logical clock cannot excuse objectionable apparent audiovisual timing.
- Memory stays within the reserved cap with all concurrently active sessions and
  model scratch included. Record p50/p95/p99 frame age and deadline slack.
- Capture a synthetic frame-ID marker/object trajectory to establish actual
  presentation. Use a sufficiently fast camera/photodiode or verified presentation
  instrumentation. A 240 fps camera has ~4.17 ms sample spacing and cannot alone
  establish sub-millisecond timing accuracy; state measurement uncertainty.
- Persistence/motion clarity needs pursuit-camera or equivalent tracking
  measurement at controlled velocity. A static screenshot or pause frame cannot
  prove reduced sample-and-hold blur. Correct for camera exposure/rolling shutter.

Record Hz versus distinct content samples: a 120 Hz scanout containing repeated
60 fps images is not 120 fps reconstruction. Restrained Cinema can deliberately
retain nonuniform motion positions while presenting frames uniformly; count this
separately from accidental scheduler judder.

## 4. Hardware/format matrix

Use capability tuples, not a blanket OS support checkmark. Minimum test families:

| Family | Required representative cases |
| --- | --- |
| Desktop AMD | User's RX 9070 XT/RX 7900 XT if available; Linux Wayland and Windows where available; full and reduced analysis; driver identity recorded |
| Desktop Intel/NVIDIA | Integrated GPU and discrete GPU; portable path; optional vendor runtime reported separately |
| Apple | Apple Silicon Mac, iPhone/iPad and Apple TV; built-in versus external displays; PiP and thermal behavior |
| Android | High-end and constrained ARM64, TV box/stick; mpv and Exo routes; surface recreation and native DV |
| Native TV | Available LG webOS device and physical Samsung/Tizen tester; API/frame-access proof and app cadence, not simulator-only evidence |
| Displays | Fixed 60, 120, 144; 50/100 where available; fractional modes; supported VRR; SDR/HDR; HDMI bandwidth/format limits |

At minimum test 720p/1080p/2160p, 23.976/24/25/29.97/30/50/59.94/60, SDR/HDR10/HLG,
and identified DV profiles through the appropriate supported route. Devices cannot
be marked failed merely for lacking a higher tier: a correct declared fallback is
a positive compatibility result, but does not qualify the missing enhancement.

## 5. TV comparison protocol

### Conditions

Use the same physical TV, firmware, input, cable, player/source version and matched
output format/bit depth. Match brightness, colour, sharpness, noise reduction,
overscan and scaling. Record all settings. Compare separate conditions:

1. Original source, TV interpolation off, proper source-rate output.
2. Original source, TV's restrained/cinema motion setting, manually tuned fairly.
3. Original source, TV's best strong smoothing setting for sports/motion clarity.
4. PlezyNG Cinema, TV interpolation off.
5. PlezyNG Smooth/Sports, TV interpolation off.

Run both Cinema picture mode and Game Mode when possible, but do not attribute
brightness/HDR/tone-map differences between TV modes to the interpolation engine.
The primary algorithm comparison uses matched picture processing. If the TV cannot
retain the same HDR path at the higher input rate, report that as a separate tradeoff.
Do not enable player and TV interpolation together in the main comparison.

Compare restrained settings at similar perceived smoothness, not our strongest
mode against a TV's nearly-off mode. TV settings are model-specific; record exact
names/levels, do not assume one “De-Judder 2” value transfers to another brand.
Include a BFI/strobing condition separately where supported: the app cannot claim
victory over physical persistence based only on an interpolation comparison.

### Objective measurements

- Frame pacing, repeated/dropped content samples, trajectory error and timing jitter.
- Tracking motion clarity/persistence at known velocities, with suitable capture.
- Occlusion/edge artifacts, text readability, exposure and grain changes.
- Colour/HDR ramps and peak clipping against the same output baseline.
- Native and added playback latency, A/V skew, CPU/GPU/memory/power and sustained heat.

Use full-reference interpolation/deblur error where an aligned reference exists,
plus temporal consistency and targeted object/text checks. PSNR/SSIM or a single
perceptual metric cannot measure “film-like” appearance or certify TV superiority.

### Blinded viewer test

Initial study target: at least 20 viewers, including motion-sensitive and film-look
viewers, and at least 24 independently held-out clips across pans, dialogue,
action, animation, sports, dark scenes and bright HDR. This is a study design
target, not proof of statistical power. Randomize order and hide condition labels.
Use paired presentations of the same moment; allow replay without exposing settings.

Rate smoothness, motion clarity, visible artifacts, film-like appearance and overall
preference separately. Record “no preference” and sensitivity to the soap-opera
look; do not turn dislike of smoothing into a participant exclusion. Analyze paired
effects with viewer and clip as repeated factors; bootstrap/model by those units,
not individual frames as independent samples. Report uncertainty and disagreements.

Proposed Cinema gate: improve motion comfort/overall preference relative to
Original for the intended audience, and be non-inferior to the TV's restrained
setting on artifacts and film-look rating. Pre-register a 0.3-point non-inferiority
margin on a five-point scale and a 95% interval before the confirming study; revise
the study design if sample size cannot resolve it. A “beats TV” claim additionally
needs a positive paired preference difference with its 95% interval above zero,
and no failed critical artifact/colour/timing gate. Non-inferiority alone is not
superiority. Publish clip-category failures rather than hiding them in an average.

Tune on one set, freeze model/preset versions, confirm on another. If restrained
retiming creates visible pulsing, reject it and evaluate the specified alternative;
do not use the study merely to justify an already chosen algorithm. If no Cinema
method passes, keep Original and the qualified smoother modes and state the limit.

## 6. Release and claim rules

| Evidence | Allowed conclusion |
| --- | --- |
| Engine test only | “Intermediate-frame generation works in the tested engine.” |
| Embedded playback with timing/pixels | “Player-side processing works on this app/backend/build tuple.” |
| Physical SDR/HDR/device qualification | “Supports this resolution/rate/format on the tested devices.” |
| Perceptual Cinema gate | “Restrained motion preset passed the documented film-look comparison.” |
| Controlled superiority result | “Preferred to [TV model/firmware/setting] in [study/content scope].” |

Never claim universal blur removal, artifact-free motion, original recovered detail,
zero added latency, native DV preservation from a badge, or no soap-opera effect for
every viewer. These are accuracy boundaries, not reasons to omit implementation.

Original must remain available; saved preferences survive temporary fallback.
Do not enable unqualified format/backend combinations through remote configuration
or marketing updates. Published capability tables link actual result files and
commits. Incomplete physical tests stay unknown, even if all code checks pass.
