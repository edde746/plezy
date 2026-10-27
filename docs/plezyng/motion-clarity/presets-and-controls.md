# Presets, controls and user experience

The full-feature values below are **proposed tuning seeds**, not measured best
values. The runtime currently exposes mpv's temporal-convolution subset, documented
in [the implementation status](README.md#current-implementation-boundary); it does
not use the continuous strength values in this design table. Version tuning only
using [qualification](qualification.md). The seed fixture is
[presets.v1.json](presets.v1.json). Confidence is unknown until tested.

## 1. Entry points and default behavior

The first **Motion & clarity** entry points now live in the existing in-player Video
Settings sheet and Settings -> Playback. The runtime reuses the existing settings
tiles, focus wrappers, dialogs and sliders. The full design below remains the target
for richer capability and performance status; this PR adds no always-visible
playback button, new main navigation entry, competing video overlay or separate
visual design system.

The collapsed row shows the selected preset and a short effective state, e.g.
`Cinema · Active`, `Cinema · Limited`, `Original`. Details include a truthful
readout such as `23.976 fps -> 119.88 fps`, processing resolution and picture format.
Requested 120 Hz with observed 60 Hz must show the latter as the limit. Technical
engine/model/queue details belong in the existing performance overlay and advanced
section, not the ordinary selection flow.

No automatic change on upgrade. Original is the saved default for existing and
new installs. When the user first opens the feature, highlight Cinema as the
suggested option, with `Reduce choppy motion while keeping a film-like look.`
Use `experimental` alongside unqualified trial features; a generic label does not
replace accurate effective-state reporting.

Selecting a preset uses capabilities already known for the current session. If
raw-frame processing is unavailable, show the preset with a concise disabled reason
and available alternatives. Do not present a slider that accepts input but does
nothing. Examples: `This playback mode does not support processing.` and
`This output supports up to 60 fps.` A preset can be stored as a preference, but
its effective state must clearly remain Original/Limited if it cannot run.

## Runtime mapping in this PR

| Runtime profile | mpv temporal kernel | Runtime behavior |
| --- | --- | --- |
| Original | Restores the options captured before the feature ran | No app-requested interpolation |
| Cinema | `oversample` | Least temporal blending; intended as the restrained starting profile |
| Balanced | `linear` | Light temporal blending |
| Smooth | `gaussian` | Stronger blending with greater softness risk |
| Animation | `mitchell` | Sharper compromise for drawn edges |
| Sports | `gaussian` | Stronger blending; matching high-frame-rate source cadence is left to mpv |
| Custom | User-selected kernel | Threshold is adjustable from 0% to 10%; the default is 1% |

These are kernel choices over mpv's temporal axis, not optical-flow strength values,
not a percentage of synthetic frames and not the complete target presets above.
The setting follows mpv's detected display clock; it does not choose or switch a
30/60/120/144 Hz display mode. Higher-rate modes, frame presentation and visual
quality need separate platform and device qualification. The displayed Hz value
is renderer-reported, not a measurement of panel scanout. A threshold of 0 maps
to mpv's documented always-interpolate sentinel. The in-player sheet offers a
quick A/B toggle that disables only the temporal filter; it is not a split-screen
comparison and does not change the selected or saved profile. With audio
passthrough, display-vdrop preserves the encoded audio path, but tiny refresh
mismatches can still periodically interrupt blending; the sheet explains this
and offers the continuous threshold setting.

## 2. Preset definitions

`S` is the 0..100 temporal-look strength from the architecture, not quality or
percent of frames generated. A device with a better GPU retains the same S.
Adaptive strength is off unless expressly selected. No preset adds BFI or changes
native HDR/Dolby output automatically.

| ID / name | Look and S seed | Target policy | Artifact policy | Other defaults | User description |
| --- | --- | --- | --- | --- | --- |
| `original` / Original | source / 0 | Existing source matching preference | No reconstruction | Restoration off; keep current scaler and filters | Keep the original motion. |
| `cinema` / Cinema | restrained / 20, cap 35 | Best compatible measured output | Conservative | Preserve source blur and grain; deblur off; high-rate sources bypass by default | Reduce choppy motion while keeping a film-like look. |
| `balanced` / Balanced | restrained / 55, cap 65 | Best compatible measured output | Standard | Deblur off; no automatic style change on fast scenes | Smoother motion with a moderate change in appearance. |
| `smooth` / Smooth | continuous / 100 | Highest sustainable compatible output | Standard | Deblur off | The smoothest motion; films may look more like live video. |
| `animation` / Animation | source / 0 by default | Compatible source cadence | Conservative | Preserve repeated drawings/stop-motion; keep existing scaler; optional smoothing remains explicit | Keep intentional pauses and drawn-frame timing. |
| `sports` / Sports | continuous / 100 | Highest sustainable compatible output | Standard with text/ball protections | 80 ms added-lookahead cap; deblur off; genuine field-rate source retained | Clearer fast motion, with some added playback delay. |
| `custom` / Custom | User's last edited named preset | Explicit or auto | Explicit | Retains a copy of all base values | Your motion and clarity settings. |

Cinema and Balanced use the proposed restrained timing method only after it passes
the perceptual gate. The user sees the same preset names if a better qualified
temporal method is selected during development, but the algorithm and preset
version change in the qualification record. Do not claim that S=20 eliminates the
soap-opera effect for every viewer.

Higher than 50 fps progressive material bypasses Cinema generation initially;
normal timing/scaling still apply. This rule uses normalized source cadence, not
container FPS or the output after generation. Sports never treats 1080i59.94 as
29.97 unique progressive motion if proper deinterlacing yields 59.94 fields/s.

Animation does not assume all 24 fps footage should become 120 independently
moving drawings. Offer `Smooth animation` in Custom, initially off; the user can
select it with a direct preview. Do not silently remove repeated drawings.

Avoid automatic Sports detection from genre metadata. If optional content-aware
selection is enabled later, it selects only within an explicitly configured
mapping. Unknown media uses the saved preset. Per-title choices always win.

## 3. Ordinary controls

The current sheet exposes Preset and Custom temporal controls, renderer status, and
a quick A/B switch when the temporal filter is active. The planned full engine
adds Quality, Compare, and Advanced controls. Quality options: Auto, Efficient,
High. A custom engine/model choice expands Expert controls and changes Quality to
Custom. Efficient/High influence processing resources and reconstruction quality,
not the selected motion appearance.

Every control has a localized one-line explanation; secondary help uses the
existing `?`/help affordance. A remote can focus and open help, and a screen reader
announces it. No hover-only explanation. Use plain descriptions below as source
copy, avoiding vendor names and algorithm acronyms in the basic UI.

| Control / serialized key | Domain and seed | Behavior/help text |
| --- | --- | --- |
| Preset / `preset` | Six presets + Custom; Original | Choose how motion should look. |
| Smoothness / `smoothness` | Integer 0..100; preset value | Higher values smooth motion more and change the film look. Zero uses source timing. |
| Quality / `quality` | auto, efficient, high, custom; auto | Balance processing quality with the power available on this device. |
| Output rate / `targetRate` | source, compatible_auto, sustainable_max, or explicit supported rational rate | Choose the number of pictures sent each second. Auto is displayed for the preset's compatible/sustainable policy; unsupported rates explain why. |
| Artifact protection / `artifactProtection` | conservative, standard, light; preset value | Reduce processing where movement is uncertain. Stronger protection can leave more choppiness. |
| Preserve animation timing / `preserveAnimationHolds` | Boolean; true in Animation, true as a safeguard otherwise | Keep repeated drawings and stop-motion timing. |
| Reduce camera blur / `deblurEnabled` | Boolean; false; experimental | Try to restore blur already in the recording. Can change detail. |
| Blur restoration / `deblurStrength` | Integer 0..100; 0 when off, initial enabled value 15 | Higher values restore more detail but can cause flicker or false edges. |
| Scaling / `scalerPolicy` | existing, auto, explicit existing preset ID; existing | Use the current picture scaler or choose a compatible one. |
| Picture format / `formatPriority` | preserve_source_format; processed_hdr10; processed_sdr; preserve by default | Keep the current HDR/Dolby format, or explicitly choose a compatible processing format. |
| Power / `powerPolicy` | auto, efficiency, performance; auto | Limit processing power and heat without changing your saved motion preference. |
| Remember for / `scope` | this_playback, title, library, device; device default in Settings | Apply the choice only where you want it. This playback is the preview default. |

`processed_hdr10` is available only when the complete source-to-HDR10 conversion
is qualified. `processed_sdr` similarly requires a correct tone-map path. Selecting
either describes the new output before applying and offers one-tap revert; there
is no surprise format downgrade hidden inside Auto quality.

## 4. Advanced and expert controls

Do not expose internal unstable research parameters as ordinary consumer sliders.
Expose stable controls with bounds and an effective-state readout. Editing one
converts the preset to Custom without discarding the prior preset's values.

| Key | Allowed values / initial default | Semantics and constraints |
| --- | --- | --- |
| `adaptiveStrength` | off, pan_assist; off | Pan assist can vary S within the saved cap; one-second minimum transition; never upgrades Original |
| `smoothnessCap` | 0..100, >= S | Maximum look change; higher engine quality does not increase it |
| `interpolationEngine` | auto, classical, neural; auto | Selects among qualified adapters; explain unavailable engines |
| `neuralModelId` | Installed verified model IDs; auto | No arbitrary URL/file selection in normal playback settings |
| `analysisScale` | auto, 1, 1/2, 1/4; auto | Motion estimation resolution; full-size reconstruction may still be retained |
| `synthesisResolution` | native, 1440p, 1080p, 720p, auto; auto | Caps generated RGB resolution where applicable; show when originals need matched filtering |
| `maxOutputRate` | auto or supported rational rate | Hard rate cap; must not conflict with an explicit targetRate; fractional labels retain their exact fractions internally |
| `maxAddedLookaheadMs` | 0..250; 150 VOD/80 Sports | Zero disallows bidirectional lookahead; fallback reason remains visible |
| `gpuBudgetPercent` | 30..90; 80 | Admission headroom target, not a promise about total GPU utilization |
| `maxAdditionalMemoryMiB` | 64..4096, clamped to safe device budget | Weights, scratch, retained frames and interop surfaces all count |
| `fallbackPolicy` | adaptive, timing_only; adaptive | Adaptive reduces cost; timing-only returns to source processing when the request misses budget |
| `preserveGrain` | true by default | Avoid interpreting film grain as recoverable blur; no automatic denoising |
| `burnedInTextProtection` | auto, off; auto | Conservative processing of embedded text/graphics; does not remove them |
| `deblurModelId` | Verified SDR-qualified IDs; auto | Separate from interpolation model; HDR availability is independently checked |
| `framePacingPolicy` | preserve_audio, pcm_display_sync; preserve_audio | PCM display sync is conditional on the audio path; never changes bitstream passthrough silently |
| `allowModeSwitch` | follow_existing, never, when_starting; follow_existing | Honors existing device/user refresh preferences; no switching for each slider move |
| `comparisonMode` | hold_original, replay, split; hold_original | Split needs spare processing budget and uses synchronized full-frame processing |
| `diagnostics` | off, summary, detailed; off | Display effective processing and measured timing; does not upload frames |

Scene cut protection cannot be disabled in release settings. Expose cut/confidence
thresholds, flow debug views, inferred shutter/exposure experiments and model export
selection only in an explicitly enabled developer diagnostics panel. Defaults for
those experiments must not leak into ordinary profiles or backup imports.

No software BFI control in release presets. The app does not have general panel
emission control; alternating black video frames trades brightness, flicker and
temporal resolution and is not equivalent to a TV's hardware strobing. A future
lab-only BFI experiment requires fixed verified scanout and separate measurement.

## 5. Preview and applying a change

Use the existing full video viewport. The current PR's quick A/B command toggles
mpv temporal blending while retaining display synchronization, scaling and audio
settings. The future `Compare` flow offers:

- **Hold Original:** show original video while held, return on release. Support
  pointer, keyboard and D-pad; also provide a toggle for users who cannot hold.
- **Replay comparison:** replay the same short VOD segment with identical timing,
  once original and once processed. Do not offer replay on unseekable live content.
- **Split view:** optional expert comparison; process the full frame first, then
  composite the two versions using the same PTS. Cropping each half before flow
  estimation would make the comparison invalid. Disable if the extra buffers miss
  budget. This view does not compare against TV interpolation.

Comparison is session-only until Apply. Cancel/Back restores the prior requested
and effective configuration, including picture format, without altering resume
intent. Preview writes cannot race with a title change. With processing active,
source comparison stays on the same negotiated output mode/latency where possible;
otherwise explain the temporary mode transition. Do not hide audio delay changes
by comparing different moments.

The ordinary active row has no permanent toast. Notify once if a requested route
cannot run or a format change is needed. Transient load downgrades update the sheet
and overlay; do not interrupt a film with repeated messages. Errors offer `Use
Original`, `Try Efficient`, or a relevant device/output explanation.

## 6. Settings scope and precedence

The target precedence is current comparison/session override -> explicit title ->
library -> device default. The current implementation follows the repository's
configured single scope, then global fallback; a per-title edit is not accidentally
shadowed by an older library entry. The profile, temporal kernel and threshold now
share that configured scope. The media and live-stream open paths resolve those values before a source opens
so decoder look-ahead is configured in time. Preserve server-scoped
media identity and existing
`ScopedPlayerPrefs` behavior. Do not accidentally introduce a new profile-isolated
store: the existing scoped player store is explicitly shared across app profiles.
Document that behavior in the settings scope help. Source files without a stable
library identity use this-playback/device scope rather than inventing a title key
from a credentialed URL.

Store portable look preferences separately from device capability/calibration.
Importing a settings backup may restore requested look values but must re-probe
hardware and cannot restore old model-cache paths, native handles, benchmark grades,
qualification claims or a display's raw identifiers. Add typed schema migration,
defaults and bounded normalization. Unknown optional values fall back visibly;
unknown incompatible versions are rejected without changing current playback.

One `SettingsBindingOwner` applies the motion preferences. Register them with the
same service/export/reset mechanisms as other playback settings, avoiding a second
listener in `SettingsMutationService` that applies changes twice. Preserve
`checkCurrent`/generation checks after every await during profile/session changes.
Native acknowledgment determines applied state; optimistic UI must not claim success
for a failed pipeline activation.

Keep the preset fixture and actual runtime schema distinct: `presets.v1.json`
records design seeds. The implementation adds a typed target-rate union (policy or
positive rational) and cross-field validation. For example, selecting a 120 fps
target with a 60 fps maximum must produce an inline conflict to resolve, not
silently save contradictory values. If S is raised above its cap in Custom, raise
the cap visibly with it; lowering the cap clamps S visibly. Switching between
source/restrained/continuous follows S=0, 0<S<100, S=100 respectively. Changing
model/quality alone never changes that mapping.

## 7. Accessibility, localization and device layouts

- Use existing sheet spacing, type scale, button shapes, accent and focus outlines.
  No decorative motion in the settings screen. Honor reduced UI motion separately
  from the video preference; never silently change movie processing from that OS flag.
- D-pad left/right adjusts a focused slider; Up/Down moves between rows; Back closes
  help/subpage before closing the sheet. Preserve TV focus after capability updates.
- Label current value, range, unit, limitation and reset action for screen readers.
  Never communicate active/limited/experimental states by colour alone.
- Use localized number/rate formatting and RTL-safe ordering of the FPS comparison.
  An arrow is decorative; accessible text says input and output explicitly.
- Support large text and 200% scaling without clipped help or inaccessible Apply/
  Cancel. Use the existing responsive sheet/scroll behavior; primary actions stay
  reachable on handheld, TV and ultrawide displays.
- Localize every preset, help line, limit reason and effective-state description
  through the existing Slang source/catalog generation flow. Do not hand-edit only
  generated translations. Test long German text, Arabic RTL and CJK wrapping.
- Provide reset for individual controls, Custom and all device motion preferences.
  Reset does not delete downloaded models unless the user explicitly selects that
  storage action.

## 8. TV setup help and diagnostics

Short setup help: `Turn off the TV's motion smoothing when using this feature.`
Explain that Game Mode is optional, input-specific, and may have different HDR or
picture controls. Do not claim to remotely detect or disable the TV's setting.
List vendor menu examples only in expandable help, with model/version caveats.
Avoid simultaneously applying player and TV interpolation in qualification.

The detailed overlay adds: normalized source rate; requested/effective output;
observed presentation type; generated/repeated/missed counts; active engine/model;
analysis and synthesis dimensions; output colour/bit depth; look strength;
restoration activity; queue/latency; memory; processing times; fallback reason.
Keep `unknown` distinct from zero and requested distinct from measured. A frame
counter must distinguish newly synthesized positions from repeated images.
