# Visualizer implementation status

Updated: 2026-10-28. Source work is on [PlezyNG PR #55](https://github.com/snapetech-org/PlezyNG/pull/55) and [MilkRust PR #20](https://github.com/snapetech-org/MilkRust/pull/20). The [original plan](COMPLETION_PLAN.md) and its completion gates remain authoritative. **The end-to-end plan is not complete and neither PR is release-qualified.**

## Implemented source

### Native playback and renderer

- Pinned mpv 0.41.0 and projectM 4.1.8 patches add a bounded same-player PCM tap, caller-owned framebuffer output, and pause-aware monotonic equation/transition clocks. Source revisions, patch digests and upstream notices are committed under `native/visualizer/`.
- The PCM patch composes after all 23 common/Linux patches in the app's locked mpv-build revision. This was source preparation only. The app's binary dependency lock remains unchanged; no replacement artifact or checksum has been invented.
- The Linux host negotiates the optional APIs at runtime, uses playback-clock timestamps, preserves original sample rate/channel layout in the tap, downmixes/resamples on a worker, and resets engine state across audio generations. It does not change audio output or open another decoder.
- The worker owns surfaceless Mesa EGL/GLES 3, projectM, an FBO and RGBA snapshots supplied to a Flutter pixel-buffer texture. PCM and pixels do not cross Dart channels. Rendering is capped at 1280×720 and approximately 30 FPS; this copy/readback path is unmeasured and provisional.
- Native session leases protect against stale controls/disposal. The controller serializes operations and polls status at 2 Hz. Original scenes remain visible during startup, missing audio, unsupported dependencies and failures. Hidden, paused and reduced-motion states suspend native rendering; profile/player disposal stops its reader before destroying the player.

### Library, packs and controls

- The library bundles the unmodified, immutable CC0 sample archive for first-open offline activation and explicit restoration after removal, alongside remote catalog installation, local `.milk`/`.milk2` import, validated local `.rmpack` import, upstream links for unresolved historical collections, and selectable installed presets when a native renderer is available.
- Archive/digest, portable path/case/symlink, expanded-size, file-count, attribution, license and notice checks precede activation. Executable asset types and shader includes are rejected. Header checks bound supported textures to 4096 pixels per side, 8 MP per image and 32 MP per pack; a 512 MB device-library budget prevents unlimited installed growth. Declared missing textures/dependencies fail activation. Local archive imports first take a bounded private snapshot. Store mutations are serialized; canceled downloads are checked again before activation. Interrupted replacements restore the previous directory on startup, and partial downloads restart cleanly.
- Pinned catalog updates can retain previous installed versions and expose Download update when the app ships a newer entry. The catalog remains compiled into the app; this is not a signed remote catalog or resumable transfer service.
- The browser searches title, author, pack and tags; shows license/content notices; distinguishes `.milk` candidates from unavailable `.milk2` playback; and provides per-preset favorites.
- Favorites, selection, current list, quality, shuffle/lock, interval and transition choices are scoped by profile. Named playlists support creation, ordering, deletion and bounded JSON import/export of references only. Export does not redistribute preset files or artwork.
- Previous/next, shuffle, lock, timed changes, transition duration, lower resolution, reload, original-scene selection and fullscreen controls are implemented. Fullscreen reuses the native texture/session; it does not start a second decoder or renderer. Keyboard left/right and Escape are wired. Touch, TV, focus and accessibility behavior remain unqualified.
- Preference writes are serialized and keep a recovery copy. Asset files are shared at device level. Missing or removed preset references are not automatically downloaded.

### MilkRust

- Standard numbered shader keys and additional object-key families parse into their intended scopes. Initialization handling, UTF-8/read diagnostics, blank-preset rejection and report denominators have been corrected in source. Render/fidelity stages remain explicitly unassessed.
- Targeted EEL fixes cover lazy branches, boolean thresholds/operators, power/remainder operations and bounded memory helpers. Assignment destinations are resolved once, avoiding duplicate side effects; integer remainder handles signed-minimum overflow without panicking. Regression source is committed but unrun.
- Two-state frame construction resolves each preset's shader/texture data independently. Separate warp/composite rendering and saved `.milk2` blend semantics remain blockers; the intermediate frame container does not close either.
- The report also blocks composite-only shaders and warp shaders that the current per-pixel mesh path bypasses. WebGPU subset status includes unsupported equation calls, and incomplete one-state `.milk2` files cannot evade the saved-blend blocker.
- A deterministic `.rmpack` builder requires a redistribution basis, per-asset provenance and shipped notices. One CC0 fixture archive is published on an immutable repository commit. Historical `NOASSERTION` collections remain link/import sources in PlezyNG.

## Completion gates

| Package | Current source state | Remaining exit evidence or work |
| --- | --- | --- |
| V0 Audit/harness | Identified false-positive and denominator paths repaired | Regenerate the full corpus ledger, account for every original omission, reference/negative-control runs |
| V1 Native integration | Linux worker/texture/control path implemented | Built shader-preset playback, resize/dispose/context recovery; Apple and other native hosts |
| V2 Audio | Optional patched PCM ABI and Linux consumer implemented | Patched artifacts on each platform; timing, seeks, gapless, layout/rate/speed, passthrough and overload qualification; live analysis for original scenes |
| V3 Parser/VM | Targeted syntax/EEL fixes | Full state/reference/RNG/encoding conformance; bounded parser/evaluator coverage |
| V4 MilkRust rendering | Existing partial web/headless paths | Production native renderer/ABI, complete HLSL and distinct stages, feedback/transition fidelity, `.milk2`, other supported formats |
| V5 Packaging/catalog | Reproducible builder, bundled cleared fixture with acknowledgements, pinned app catalog | Broader rights-cleared packs, dependencies, real thumbnails, signed remote catalog and key/revocation operations |
| V6 Local management | Bounded install/import, serialization and crash recovery | Executed hostile/interrupted-input cases, compile-time budgets, shared dependency accounting, migration and broader folder/archive workflows |
| V7 Downloads | Install/cancel/retry/update/remove source and offline browsing | Actual fresh-install download/play/offline/update flows; persisted transfer metadata/resume policy evidence |
| V8 UI | Selection, profile preferences, favorites/playlists and controls | Interaction/accessibility/platform review, translations, previews, richer per-preset diagnostics, optional beat switching and content export policy |
| V9 Qualification | Regression source and concrete gates recorded | Private JIT builds/tests and physical GPU/audio/platform evidence; no cells passed |
| V10 Release | Draft PRs with plan/source/notices | Produced and verified artifacts, complete corresponding source/dependency notices, release catalog and installed-release checks |

## Native boundaries that prevent a release claim

The Linux host requires the patched dependencies and Mesa surfaceless EGL. Default binary artifacts have not gained these extensions. Windows, macOS, iOS/tvOS, Android/TV, webOS and Tizen do not have this native host implementation. Storage/import availability and engine availability are separate.

The in-process renderer catches exceptions, but cannot contain a hung shader compiler or GPU driver. Teardown joins the worker and can therefore block in that case. Process isolation/watchdog behavior, resource budgets and driver recovery remain required work before claiming arbitrary community inputs are safely supported.

A selected `.milk` file is a candidate, not evidence of fidelity. Missing textures and legacy format semantics need explicit corpus validation. `.milk2` is stored but not played by this adapter. Butterchurn JSON, `.shape`/`.wave` fragments and other corpus formats are not completed by this host.

Disclaimers preserve provenance; they do not establish redistribution rights. The two authored fixture presets are not the complete community library. No unsupported family, platform or license state is counted as complete.

## Validation record

Source was inspected and dependency revisions/APIs were read from pinned upstream files. The Linux mpv patch series was composed into a separate clean source checkout. Controller regression source covers disposal during creation, stale leases, missing PCM capability and double-preset rejection. Import-limit regression source covers path aliases, shader includes, executable assets and oversized/truncated texture headers. Both suites remain unrun.

**No tests, compiler builds, CI jobs, render captures, benchmarks or device qualification ran in this session.** Do not convert source preparation into a test-pass claim. All executable qualification must use compatible private ephemeral JIT runners and the required device matrix under the repository policy. Both PRs remain draft.
