# Visualizer implementation status

Updated: 2026-10-28. PlezyNG source work is merged in `main`; the upstream reference is [MilkRust PR #20](https://github.com/snapetech-org/MilkRust/pull/20). The [original plan](COMPLETION_PLAN.md) and its completion gates remain authoritative. **The end-to-end plan is not complete and the implementation is not release-qualified.**

## Implemented source

### Native playback and renderer

- Pinned mpv 0.41.0 and projectM 4.1.8 patches add a bounded same-player PCM tap, caller-owned framebuffer output, and pause-aware monotonic equation/transition clocks. Source revisions, patch digests and upstream notices are committed under `native/visualizer/`.
- The PCM patch composes after all 23 common/Linux patches in the app's locked mpv-build revision. This was source preparation only. The app's binary dependency lock remains unchanged; no replacement artifact or checksum has been invented.
- The Linux host negotiates the optional APIs at runtime, uses playback-clock timestamps, preserves original sample rate/channel layout in the tap, downmixes/resamples on a worker, and resets engine state across audio generations. It does not change audio output or open another decoder.
- The worker owns surfaceless Mesa EGL/GLES 3, projectM, an FBO and RGBA snapshots supplied to a Flutter pixel-buffer texture. PCM and pixels do not cross Dart channels. Rendering is capped at 1280×720 and approximately 30 FPS; this copy/readback path is unmeasured and provisional.
- The current main branch's local/source-audio visualizer and compact MPV spectral statistics are preserved. Both music-service and source-audio players expose native presets only while their dedicated audio core is ready. Original scenes prefer Plex loudness, then centroid/flatness metadata, then ambient animation; these scalars are not waveform samples or frequency-bin arrays. Live analysis is suspended while hidden, backgrounded, reduced-motion or covered by a native frame.
- Native session leases protect against stale controls/disposal. The controller serializes operations and polls status at 2 Hz. Original scenes remain visible during startup, missing audio, unsupported dependencies and failures. Hidden, paused and reduced-motion states suspend native rendering; profile/player disposal stops its reader before destroying the player.

### Library, packs and controls

- The library bundles the unmodified, immutable CC0 sample archive for first-open offline activation and explicit restoration after removal, alongside remote catalog installation, local `.milk`/`.milk2` import, validated local `.rmpack` import, bounded local folder snapshots with textures/notices and cancellation, upstream links for unresolved historical collections, and selectable installed presets when a native renderer is available.
- Archive/digest, portable path/case/symlink, expanded-size, file-count, attribution, license and notice checks precede activation. Executable asset types and shader includes are rejected. Header checks bound supported textures to 4096 pixels per side, 8 MP per image and 32 MP per pack; a 512 MB device-library budget prevents unlimited installed growth. Declared missing textures/dependencies fail activation. Local archive imports first take a bounded private snapshot. Store mutations are serialized; canceled downloads are checked again before activation. Interrupted replacements restore the previous directory on startup, and partial downloads restart cleanly.
- Pinned catalog updates can retain previous installed versions and expose Download update when the app ships a newer entry. A signed remote catalog now augments built-in pins. Ed25519 quorum verification, immutable archive URLs, expiry, persistent sequence checkpoints, revocations, explicit refresh and offline installation receipts are implemented in source. Release trust roots and production signed publication are not yet provisioned. Transfers restart cleanly; HTTP range resumption is not implemented.
- The browser searches title, author, pack and tags; shows license/content notices; distinguishes `.milk` candidates from unavailable `.milk2` playback; and provides per-preset favorites.
- Favorites, selection, current list, quality, shuffle/lock, interval and transition choices are scoped by profile. Named playlists support creation, ordering, deletion and bounded JSON import/export of references only. Export does not redistribute preset files or artwork.
- Previous/next, shuffle, lock, timed changes, transition duration, lower resolution, reload, original-scene selection and fullscreen controls are implemented. Fullscreen reuses the native texture/session; it does not start a second decoder or renderer. Keyboard left/right and Escape are wired. Touch, TV, focus and accessibility behavior remain unqualified.
- Preference writes are serialized and keep a recovery copy. Asset files are shared at device level. Missing or removed preset references are not automatically downloaded.

### MilkRust

- Standard numbered shader keys and additional object-key families parse into their intended scopes. Initialization handling, UTF-8/read diagnostics, blank-preset rejection and report denominators have been corrected in source. Render/fidelity stages remain explicitly unassessed.
- Targeted EEL fixes cover lazy branches, boolean thresholds/operators, power/remainder operations and bounded memory helpers. Assignment destinations are resolved once, avoiding duplicate side effects; integer remainder handles signed-minimum overflow without panicking. Regression source is committed but unrun.
- Preset/fragment input limits reject oversized text, sparse/overflowing object indices and excessive record sizes with retained compatibility diagnostics. Both EEL evaluators share bounded recursion and nested work. Checked stateful frame generation shares an aggregate equation-work limit, reports evaluation errors and resets failed state; WebGL/desktop playback and CLI/headless statistics consume that checked path. This is not native compiler/driver isolation or a wall-clock/memory guarantee. Regression source remains unrun.
- Two-state frame construction resolves each preset's shader/texture data independently. Experimental WebGL now has separate warp/composite programs, shader-aware mesh warping, feedback that excludes display-only composite, and explicit compile/texture/context failure status. A stage-order fixture and SDK/core regressions are committed but unrun. This is not a native MilkRust renderer or proof of visual fidelity.
- The generic report conservatively blocks unqualified stages; only the explicit WebGL import gate opts into the new stage implementation. Unsupported equations/shader features and saved `.milk2` blends remain blocked. WebGPU subset status includes unsupported equation calls. Named textures load with bounded cache/upload sizes and fail explicitly; browser image decoding still lacks allocation containment. Pack-provided JavaScript is not executed; Studio exports default to local-only/NOASSERTION.
- A deterministic `.rmpack` builder requires a redistribution basis, per-asset provenance and shipped notices. One CC0 fixture archive is published on an immutable repository commit. Historical `NOASSERTION` collections remain link/import sources in PlezyNG.

## Completion gates

| Package | Current source state | Remaining exit evidence or work |
| --- | --- | --- |
| V0 Audit/harness | Identified false-positive and denominator paths repaired | Regenerate the full corpus ledger, account for every original omission, reference/negative-control runs |
| V1 Native integration | Linux worker/texture/control path implemented | Built shader-preset playback, resize/dispose/context recovery; Apple and other native hosts |
| V2 Audio | Optional patched PCM ABI and Linux consumer implemented | Patched artifacts on each platform; timing, seeks, gapless, layout/rate/speed, passthrough and overload qualification; qualify original-scene live statistics |
| V3 Parser/VM | Targeted syntax/EEL fixes, input/depth/work limits and checked frame failures | Full state/reference/RNG/encoding conformance; bounded parser/evaluator coverage |
| V4 MilkRust rendering | Separate experimental WebGL stages, mesh shaders, explicit failures and resource disposal | Production native renderer/ABI, complete HLSL, stage/feedback/transition fidelity evidence, `.milk2`, other supported formats |
| V5 Packaging/catalog | Reproducible builder, bundled cleared fixture with acknowledgements, pinned app catalog | Broader rights-cleared packs, dependencies, real thumbnails, catalog key custody/publication and exercised rotation/revocation |
| V6 Local management | Bounded install/import, serialization and crash recovery | Executed hostile/interrupted-input cases, compile-time budgets, shared dependency accounting, migration and broader archive/format workflows |
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

**No tests, compiler builds, CI jobs, render captures, benchmarks or device qualification ran for these source increments.** Do not convert source preparation into a test-pass claim. All executable qualification must use compatible private ephemeral JIT runners and the required device matrix under the repository policy.

### Signed catalog source increment

The library performs remote refresh only on explicit user action. An expired, removed or revoked catalog entry cannot authorize a new installation; existing files remain browsable and removable. A second authorization check precedes activation. App-generated receipts preserve installed version metadata independently of catalog retention. Regression source covers signed payloads, expiry, quorum, rollback, tampering and offline reuse; it has not been run. No production private key or trust root was invented or committed. Confidence: moderate for source completeness in this increment; runtime behavior remains unverified.
