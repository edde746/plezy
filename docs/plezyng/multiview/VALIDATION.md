# Verification and device qualification

This is a test specification. No results below have been claimed or executed for the feature by the planning change. Targets are initial engineering gates, not benchmark results. Tune only with recorded evidence and preserve the user-visible contract.

## Automated test layers

1. Pure Dart models/reducer/admission: property and adversarial event sequences, transaction rollback, resource release, persistence migrations, content identity and stale-generation rejection.
2. Widget tests: real existing theme/focus primitives, geometry, overflow, semantics and actionable controls; fake transport only at the adapter boundary.
3. Adapter contract tests: run the same lifecycle and ownership contract against every native/media/reader/game adapter; a fake adapter can validate the harness, not certify a real backend.
4. Native tests: instance registry/event identity, teardown races, view/window ownership, input release, audio focus, texture/fence lifetimes and malicious/invalid bridge arguments.
5. Integration/device tests: actual media, source server, reader corpus and embedded game, with measured positions/frame/input/audio results and captured logs.
6. Existing full regression suites relevant to player, source, music, reader, navigation, focus, profile and localization. Broaden only after changed behavior justifies it; record baseline failures separately.

Use the repo's current toolchain and CI commands. Suggested focused additions are `test/multiview/`, native test targets beside each plugin, and a device scenario harness under existing integration/automation tooling. `flutter analyze` and `flutter test` are required where runnable; native packages need their actual platform build/test commands. Record exact commands, tool versions, exit status and blockers in DELIVERY.md.

## Required scenarios

| ID | Scenario | Passing result |
|---|---|---|
| V01 | Ordinary single video/music/read action with feature off/on | Existing replacement, progress and navigation behavior unchanged |
| V02 | Video + EPUB, then swap 10 times | Same media instance; EPUB CFI retained; no duplicate opens/scrobbles |
| V03 | Video + PDF; resize at large text/DPI | Physical page and focal point preserved; controls/readable text reachable |
| V04 | Video + comic spread/webtoon/manga | Page/panel and independent reading direction retained; no gesture collision |
| V05 | Music + reader | One audio core/queue; reader changes do not interrupt music |
| V06 | Music visualizer + video | Actual existing visualizer data behavior; throttle hidden/secondary rendering; no extra audio source |
| V07 | Audiobook + ebook, aligned and unaligned editions | Correct independent resume; read-along only for actual alignment; no invented synchronization |
| V08 | Two VOD videos from different servers | Independent tracks, source IDs, timelines, progress and stop requests |
| V09 | Two Live TV channels | Independent tuner leases/EPG; audio selection correct; closing one preserves other |
| V10 | Video + source file/cloud media | Each authorization/proxy/renewal stays with its session; failure local |
| V11 | Game + video | Both real streams visible; stable game input/latency; video remains controllable |
| V12 | Game + music + guide | Input/audio focus distinct; guide can expand without host quit; constraints handled |
| V13 | Two readers including identical content | Separate content positions where intended; default same-item action promotes existing session; one progress writer |
| V14 | Three/four panes on admitted device | No session-crossed frames/events; layout and transport owner remain deterministic |
| V15 | Failed second decoder/source allocation | First session and layout unaffected; localized useful alternative |
| V16 | Rapid add/swap/close with delayed callbacks | Final revision wins; no resurrected session, stray sound or disposed-view draw |
| V17 | Stale A dispose after B creates on same backend | B continues emitting events and rendering |
| V18 | Native frame/surface preparation timeout | Transaction rolls back; no permanent black pane or leaked reservation |
| V19 | App navigation Back/menu/fullscreen transitions | Defined back order; no accidental close-all; browser position restored |
| V20 | Profile switch, lock/PIN or deletion | All old surfaces covered/stopped; no private frame, audio, title or input leakage |
| V21 | Theme changes including custom/Light/OLED | Token-consistent controls, contrast and focus; no hard-coded dark pane chrome |
| V22 | Text scale 1.0/1.5/2.0 and pseudo-localization | No clipped/overlapping actions; valid fallback layout |
| V23 | Arabic/Hebrew/CJK and manga | Layout/localized semantics correct; reader direction independent |
| V24 | Screen reader/Switch Control/keyboard | All actions possible without drag; region/status announcements useful and bounded |
| V25 | D-pad/gamepad/TV remote | Every pane/action reachable; no trapped focus or control leakage |
| V26 | Touch pinch/content swipe versus pane drag/resize | Correct gesture owner; no reader zoom causing panel motion or game input |
| V27 | Held game buttons/axes/touches during swap/dialog/unplug | Complete neutralization; no stuck keys/axes or synthetic gameplay |
| V28 | Relative mouse/keyboard capture to guide/editor | Explicit release and re-entry; text shortcuts/IME preserved |
| V29 | Focus a muted pane | Audio stays unchanged; speaker state accurately labeled |
| V30 | Listen to this / follow-main setting | Requested ownership only; gains/transport owner update coherently |
| V31 | Two-stream decoded audio mix | Separate gains, no clipping/drift, correct pause/seek/route changes |
| V32 | Passthrough/exclusive output then Mix | Clear supported conversion choice; cancellation leaves original output intact |
| V33 | Backend without real per-stream gain | No fake slider/OS-volume substitution; one-audible mode remains correct |
| V34 | Call/alarm/headphone/Bluetooth route changes | Coordinated pause/duck; resume only eligible prior-playing sessions |
| V35 | Hardware media keys and OS now playing | Commands/metadata belong to declared transport owner |
| V36 | TTS/read-along and theme-song autoplay | Explicit narration ownership; no accidental overlapping narration or theme audio |
| V37 | Native PiP enter/reject/auto-enter/restore/close | Selected video only; correct play state; workspace restores; no late callback hijack |
| V38 | Native PiP with subtitles/ASS and unusual aspect ratio | Captions visible and properly scaled or in-app alternative offered before change |
| V39 | Android TV/Fire constraints | App-owned PiP works; no unsupported system-mode claim or wrong usage declaration |
| V40 | tvOS native extension | Real supported bridge and correct Now Playing semantics; app-owned mode independent |
| V41 | Desktop pop-out/dock/repeated transfer | No duplicate source/player/progress owner; same state retained |
| V42 | Secondary window crash/close, main window close | Documented session policy; no orphan audio/game input or unreachable window |
| V43 | Mixed-DPI/multiple monitors, unplug/dock, Wayland/X11 | Correct physical bounds and scale; restore controls remain onscreen |
| V44 | Fold/rotate/resize/IME/overscan | Safe readable layout and retained positions; correct native surface rectangles |
| V45 | Native plane under dialogs/WebView/rounded frame | No surface bleed or wrong z-order; side-by-side alternative if overlap unqualified |
| V46 | HDR/SDR + subtitles and DV modes | Actual output accurately reported; no unannounced tone mapping/FEL loss; no magenta/green output |
| V47 | Two videos with different frame rates | Independent clocks; one display-mode owner; no refresh thrash |
| V48 | GPU/context/device loss | Bounded recreation or visible recoverable error; no use-after-free |
| V49 | Software/hybrid path on real constrained TV | Both actual streams render within envelope; compare native hardware-only baseline |
| V50 | High-resolution source in tiny pane | Admission reflects source decode work, not just pane dimensions |
| V51 | Thermal/memory/decoder pressure | Hidden work reduced first; quality policy followed; main/input stays responsive |
| V52 | App background/lock/suspend/resume | Permitted PiP/audio continue; other sessions checkpoint/pause; all game capture released |
| V53 | Process kill/restart with saved workspace | Restore paused descriptors; no secrets/old handles; no automatic host-game launch |
| V54 | Cloud progress conflict, offline rewind, delayed report | Existing conflict/rewind semantics; no stale write from a moved/closed pane |
| V55 | Provider revoke, loan expiry, source removed | Only relevant sessions stop; bookmark preserved; existing reconnect/renew flow |
| V56 | Watch Together plus unrelated companion | Only joined session participates; no cross-room seek/stop |
| V57 | Cast/external player alongside local content | Remote controller represented truthfully; no fake local video surface |
| V58 | Long run and repeated open/close | No accumulating handles, decoders, native observers, timers, audio focus or tuner leases |
| V59 | Invalid native/event payloads and stale profile IDs | Bounded typed failure; no other-session mutation, credential log or process crash |
| V60 | Tips/help and capability denial paths | User can discover every action; Retry/Cancel preserve current sessions; tips reset works |
| V61 | Portable TV EPUB/PDF/comic renderers | Actual reading, zoom/search/selection/semantics where applicable; stable canonical locators |
| V62 | Screenshot/app-switcher/profile privacy | Hidden/profile-protected surfaces and titles obey existing privacy policy |
| V63 | Feature flag off after saved workspace | Safe migration to one-session mode; checkpoints preserved, no orphan windows |
| V64 | Optional helper if implemented | Explicit pairing, source authorization, actual composition, disconnect/recovery and measured latency |

## Device matrix

For every row record exact model, OS, CPU/GPU, memory, Flutter/native engine revisions, backend/codec, content source and display/audio route. A row remains unqualified until real evidence is recorded.

| Family | Minimum qualification coverage |
|---|---|
| Android handheld | Oldest supported API/device class, current midrange and current flagship; mpv and Exo; denied PiP permission; hardware plus software path |
| Android tablet/foldable | Resizing/hinge, OS multi-window, rotation, external display if supported, touch controls |
| iPhone | Lowest supported performance class and current generation; native PiP, interruption and memory pressure |
| iPad | Compact/resizable application window, external display/scene behavior where implemented, two-decoder cases |
| Windows | Supported minimum/current OS; integrated and discrete GPU; mixed DPI; HDR and SDR outputs |
| macOS | Supported Intel where applicable and Apple silicon; public pop-outs, legacy PiP if retained, HDR/OSD/Spaces |
| Linux | At least X11 and Wayland with representative integrated GPU; window-manager keep-above rejection |
| SteamOS | Handheld and docked; desktop and Gaming Mode; gamepad capture and compositor behavior |
| Android/Google TV | Lower-resource model and current qualified model; remote-only UI, dual-video path and readers |
| Fire TV | Named representative models/OS versions; no assumption based on another Android TV result |
| Apple TV | Oldest supported and current device; app-owned two-pane playback, readers and game adapter; optional native PiP separately |
| webOS | User's LG C6 plus lower-capacity supported model; actual native ARM build; hardware/hybrid/software pairs and gain limitations |

Use content pairwise coverage rather than testing every Cartesian combination blindly. At minimum each current platform must prove video+reader, music+reader/visualizer, two videos, and supported embedded game+media before claiming full Multiview parity. If a source format/engine is not implemented, its corresponding parity row remains open; it cannot be replaced by a screenshot or parked session.

## Quantitative gates

These are proposed acceptance targets to measure, not promises already met:

- Warm in-app Swap: no source reopen/renegotiation; command-to-stable-placement p95 at most 250 ms on each reference device; no unexplained timeline jump. Reduced-motion path should settle without animation.
- Game composition: added p95 frame-presentation delay at most one display frame versus the same engine fullscreen baseline; log end-to-end input measurements separately. If this fails, change the path or lower companion work rather than masking it.
- Presentation UI: meet the target display's frame budget at p95 under the qualified pair; record dropped frames and input stalls. No synchronous decode/network work on Flutter's UI thread.
- Audio/video synchronization: within the app's existing qualified tolerance; initial review threshold ±80 ms for ordinary media. Mixed streams must not exhibit unbounded drift. Games use their tighter engine-specific baseline.
- Close/teardown: release input immediately on the control thread; all resource owners retire within a bounded timeout or report failure. No hidden indefinitely retained decoder.
- Soak: at least 30 minutes of a demanding admitted pair plus 100 open/swap/close cycles. Track RSS/GPU allocations and native handle counts after warm-up. Investigate any monotonic growth; no arbitrary “pass” based solely on the app not crashing.
- Decoder admission: failed second allocation must not create a black/muted first session. Count real native decoder instances and retained reference surfaces.
- Reader move: same logical locator after reflow and checkpoint; no accidental reading-completion increments from a layout operation.
- Fidelity: tested color range/transfer, caption appearance and actual DV mode must match the chosen output policy; performance cannot pass by silently lowering the declared fidelity.

Record per-device thresholds if a target legitimately needs a different frame or timing budget, together with the product impact and evidence. Do not manufacture measurements from timer settings or fixture outputs.

## Delivery evidence template

```text
Package/platform:
Code revision:
State (implemented / tests / qualified):
Device + OS + backend + source/output:
Commands and exit results:
Scenario IDs:
Measured latency/frame/memory/audio results:
Evidence artifact or log location:
Known failures and exact reproduction:
Next implementation step:
```

A final report must distinguish app-owned PiP, simultaneous-media support, reader portability, Games embedding, desktop windows, native OS PiP and fidelity. Never collapse these into a single misleading supported Boolean.
