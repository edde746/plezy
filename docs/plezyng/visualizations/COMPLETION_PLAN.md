# PlezyNG visualization and community preset implementation plan

PlezyNG has a working set of six original music scenes, but the requested MilkDrop-compatible engine and downloadable community-preset library are not integrated. MilkRust contains reusable engine work and a substantial imported corpus; its existing compatibility totals do not establish faithful rendering.

This is the implementation handoff for Luna, prepared October 27, 2026, for **PlezyNG**. Complete the app experience, community-pack distribution, and the custom MilkRust compatibility track. Planning is complete here; implementation and release qualification remain the work below.

**Confidence:** high for the source findings; moderate for the proposed architecture pending the native integration probe; unknown for current visual pass rates and hardware performance. Audit anchors: PlezyNG `bae33540a1bad9d230c519d1043d58da5c291f32`; MilkRust `bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e`. Recheck current heads and open work before editing.

# What exists and what remains

| Area | Verified baseline | Remaining work |
| --- | --- | --- |
| PlezyNG scenes | Aurora, Bloom, Orbitals, Prism, Tunnel and Track Map; native Flutter drawing, theme tokens, previous/next controls, lifecycle and reduced-motion handling | Live audio analysis, persistent browser/settings, community formats and packs |
| Audio input | Optional Plex analyzed loudness; ambient motion when unavailable | Playback-owned PCM tap and truthful live-audio capability status |
| MilkRust engine | Rust parser/runtime, expression crate, WASM WebGL2 path, web SDK, CLI and folder-pack tools | Correct community syntax and semantics, full shader stages, native rendering and Flutter ABI |
| Community collection | Committed report lists 14,576 presets and 107 textures in five packs | Reconcile every file, test actual rendering, package versioned downloads |
| Converted presets | Catalog lists 1,754 Butterchurn JSON presets under MIT | Conversion or compatible execution adapter; these are not currently native-renderable MilkRust presets |
| Notices | Catalog, license scope, per-pack provenance/removal notices and default-build exclusions already exist | Resolve distribution status per pack; carry notices into every archive and the app |
| PlezyNG pack management | No MilkRust dependency or pack-download path found in the inspected main integration | Catalog, download/install/update/remove, local imports, offline storage and UI |
| Release | PlezyNG 2.24.1 is a draft; MilkRust release query returned no releases | Built, installed and qualified artifacts plus an actual published pack catalog |

Sources: [PlezyNG visualizer](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/widgets/music/music_visualizer.dart), [scene enum](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/widgets/music/music_visualizer_preset.dart), [Now Playing](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/screens/music/now_playing_screen.dart), [music service interface](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/services/music/music_playback_service.dart), [pack summary](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/content/generated/community-pack-summary.json), [catalog](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/content/catalog.json), [pack format](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/docs/PRESET_PACKS.md).

This is early integration work in PlezyNG, with useful foundations elsewhere. A single percentage would conflate asset collection, partial engine implementation and a working app feature.

# Fix the compatibility evidence first

The current “all supported” result is not a completion gate.

- The generated community report counts 14,576 presets but its four preset-pack compatibility denominators total **14,539**, leaving **37 files unaccounted for**. The CLI uses `fs::read_to_string(file).ok()?` inside `filter_map`, so read/encoding failures can disappear from the denominator. The cause of each of the 37 omissions must be recorded rather than assumed.
- The parser recognizes `warp_shader...` and `comp_shader...`, while an actual vendored preset uses `warp_1`, `warp_2`, `comp_1` and so on. These standard shader lines currently fall through into base values. Compatibility analysis examines the parsed shader fields, so it can approve a preset whose real shaders were never analyzed.
- Audit `shapecode_N_*`, `shape_N_*`, `wavecode_N_*`, `wave_N_*`, and `per_frame_init_*` separately. The visible parser uses different prefixes for parts of this model, and its general per-frame match precedes initialization handling.
- The shader translator explicitly rejects several constructs, including loops and matrix operations. Runtime frame construction chooses a translated composite shader or a warp shader as one source; full MilkDrop rendering needs their distinct behavior.
- The desktop UI prototype renders several primitive types as wireframes. It is not the production native MilkDrop renderer.
- `GAPS.md` is stale in places: `milkrust-expr` now exists. Audit code rather than translating roadmap checkmarks into completion claims.
- Root npm commands refer to several `tools/*milkrust*` filenames while the inspected tool tree contains `*rustymilk*` names. Reconcile the executable entrypoints before using npm output as release evidence.

Sources: [parser and shader pipeline](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/crates/milkrust-core/src/lib.rs), [CLI denominator](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/crates/milkrust-cli/src/lib.rs), [desktop drawing](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/crates/milkrust-desktop/src/runner_player_ui.rs), [tool commands](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/package.json). Reproduction preset: `content/community-unlicensed/projectm-milkdrop-original/Milkdrop-Original/Aderrasi + Geiss - Airhandler (Kali Mix) - Painterly Kaleidoscope 2.milk`; its warp section begins at line 231 and composite section at line 246.

Add real-format regression fixtures before changing these paths. A parser test using only MilkRust-specific invented keys cannot establish community compatibility.

# Product and architecture decisions

Keep PlezyNG’s six original scenes and current visual identity. Add a native visualization service behind the existing Now Playing surface, with one preset library and one pack manager shared by all rendering backends.

**Recommended architecture, moderate confidence:** retain a native backend interface with `original`, `projectm` and `milkrust` adapters. Use a pinned projectM revision as the first candidate for broad classic `.milk` playback and as a comparison implementation. Complete MilkRust behind the same interface; promote it only against measured compatibility and performance gates. This preserves the custom-engine objective without making app delivery depend on an unverified rewrite.

The backend boundary must include lifecycle, capabilities, source loading, texture resolution, PCM submission, preset switching/transitions, resize, pause, diagnostics and disposal. Distinguish engine support, platform availability and per-preset fidelity. Do not switch backends halfway through a preset; negotiate at load time and report the reason.

Native engines render to a platform texture or surface consumed by Flutter’s `Texture` path. Audio samples and rendered frames must not be serialized through per-frame Dart method-channel messages. Use platform channels/FFI for control, a bounded native PCM buffer for audio, and native GPU resources for frames. The Flutter [Texture contract](https://api.flutter.dev/flutter/widgets/Texture-class.html) is the host model; [projectM audio](https://github.com/projectM-visualizer/projectm/blob/master/src/api/include/projectM-4/audio.h) and [rendering APIs](https://github.com/projectM-visualizer/projectm/blob/master/src/api/include/projectM-4/render_opengl.h) are integration references. Pin available APIs rather than assuming development-only functions exist in a release.

Proposed ownership:

| Location | Responsibility |
| --- | --- |
| PlezyNG `lib/services/visualization/` | Session state, capability negotiation, preset library and pack lifecycle |
| PlezyNG `lib/models/visualization/` | Versioned catalog, installed pack, preset and diagnostics models |
| PlezyNG `packages/plezy_visualizer/` | Flutter platform plugin and common native control interface |
| PlezyNG `lib/widgets/music/` and `lib/screens/music/` | Existing scene integration, browser, fullscreen and controls |
| MilkRust `crates/` | Parser/VM/shader fixes, native renderer and stable C ABI |
| MilkRust `content/` and `tools/` | Canonical corpus, manifests, provenance, reproducible pack builder and compatibility harness |
| PlezyNG `docs/plezyng/visualizations/` | Design, user guide, platform matrix, qualification evidence and Luna progress ledger |

Keep community assets canonical in MilkRust; PlezyNG pins the catalog and downloads immutable release assets. Do not duplicate the large corpus into multiple repositories.

# Completion contract

“All community presets” is an engineering target, not an unbounded claim about every future file. Establish a versioned corpus that includes every current imported file plus representative MilkDrop 1, MilkDrop 2, MilkDrop 3 double presets, texture dependencies, fragments and converted formats. Preserve arbitrary local import so users are not limited to curated packs.

Every discovered file must receive a result: discovered, readable, parsed, compiled, rendered, visually reviewed, failed, or excluded with a reason. Report counts per format, engine, platform and corpus hash. A parse success, nonempty frame, fallback drawing, or static shader translation must never be called faithful rendering.

| Compatibility family | Required behavior |
| --- | --- |
| Classic `.milk` | Canonical keys/defaults, legacy encoding handling, equations, custom waves/shapes, motion vectors, mesh warping, echo/feedback and transitions |
| Shader `.milk` | Separate warp and composite stages, shader model metadata, HLSL semantics, constants, sampling, blur/noise textures and q/t/register state |
| MilkDrop 3 `.milk2` | Two independent preset states and render targets, real saved blending parameters/patterns, assets and timing; compare with actual reference files |
| Texture and sprite assets | Relative resolution, case/alias policy, canonical noise/blur resources, common legacy formats including TGA/DDS where used; embedded-image limits |
| `.shape` and `.wave` | Import/export with state and equations preserved; deterministic composition into the owning preset |
| Butterchurn JSON | Declarative converter or compatible bounded evaluator; preserve attribution; never evaluate downloaded JavaScript |
| Other corpus formats | Inventory legacy `.prjm` and ancillary files; provide an importer where semantically required, otherwise identify them explicitly |

MilkDrop 3’s [documented double-preset format](https://github.com/milkdrop2077/MilkDrop3/blob/main/README.md) has saved blending behavior. Splitting a file at `[preset01]` and cross-fading is insufficient evidence of equivalence.

**Two independent completion gates:** the PlezyNG product gate requires the full user workflow and all claimed platform/format cells to pass. The custom-engine gate requires MilkRust to meet the same conformance suite. Shipping a projectM adapter does not close MilkRust work; a working MilkRust CLI does not close PlezyNG work. Exceptions remain visible and prevent a universal compatibility claim.

# Ordered implementation packages

| Package | Deliverable | Exit gate |
| --- | --- | --- |
| V0 Audit and harness | Rebase audit, fix denominator/unknown-key reporting, add real preset regression fixtures, reconcile tool names | Every corpus file accounted for; known false-positive cases fail before fixes |
| V1 Native integration probe | Backend contract, projectM adapter, native Flutter texture, deterministic PCM fixture; start on Linux, then Apple interop probe | Real shader preset renders in PlezyNG with resize/dispose and clean error fallback |
| V2 Playback audio tap | Optional PCM-analysis capability on the dedicated music player; timestamped bounded native transport | Audio-reactive visuals from actual playback, no second decoder or output change |
| V3 MilkRust parser and VM | Standard key families, initialization/state scopes, expression semantics, encoding, diagnostics and limits | Reference equation traces and real-format fixtures agree |
| V4 MilkRust rendering | Separate warp/composite pipeline, shader compiler/translation, native GPU renderer, stable C ABI and `.milk2` semantics | Golden sequences and feature fixtures meet conformance targets; no fake fallback passes |
| V5 Pack build and catalog | Deterministic archives, provenance/license records, texture dependencies, thumbnails, checksums and catalog authentication | Fresh build reproduces contents; every entry has a recorded distribution route |
| V6 Local pack manager | Import, validation, deduplication, database/index, atomic installs, migration and remove/rollback | Corrupt/interrupted/malicious packages leave installed library and playback intact |
| V7 In-app downloads | Browse catalog, inspect notices, download/cancel/retry/install/update/remove and offline operation | Fresh PlezyNG install downloads and plays a pack, then works offline |
| V8 Finished visualizer UI | Original/MilkDrop library, search/favorites/playlists, shuffle/lock/timing, quality, fullscreen and remote controls | Desktop, touch and TV flows match PlezyNG’s theme and pass interaction tests |
| V9 Platform qualification | Native builds, actual devices, performance/lifecycle/audio-output checks and accessibility | Supported matrix has evidence per platform; unsupported cells are explicit |
| V10 Release and handoff | Versioned engine/pack artifacts, catalog, source/notices, docs, changelog and capability ledger | Installed release artifacts pass end-to-end tests; published downloads are checked after publication |

Dependency order: V0 precedes compatibility claims. V1 and V2 establish the audio-to-screen path. V3–V4 form the custom-engine track. V5 precedes V6–V7. V8 consumes both rendering and pack services. V9 covers the integrated result; V10 closes delivery. Treat each package as a reviewable PR or small PR series, not a single giant change.

# Audio and renderer implementation requirements

PlezyNG’s `Player.audio()` uses a dedicated mpv audio core on Android, Apple, Windows and Linux, independently of Android’s video-backend choice. webOS and Tizen use their own audio-only players. Start with this actual music path, not ExoPlayer or microphone capture. See [player factory](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/mpv/player/player.dart), [native player](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/mpv/player/player_native.dart) and [music implementation](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/lib/services/music/music_playback_service_impl.dart).

Add an optional `MusicVisualizationAudioService` capability. Feed interleaved float PCM with sample rate, channel layout, presentation timestamp and session generation. The native callback only copies into a preallocated bounded ring; it must not allocate, block on rendering, perform network work or call Dart. Drop analysis samples on overflow rather than delaying playback. Reset buffers and equation state appropriately for seek, track changes, profile switches and source discontinuities.

Place the analysis tap after decode and the relevant timing-changing audio processing, before hardware output, with an explicitly documented policy for normalization, volume and downmixing. Preserve stereo information and actual sample rate. Produce waveform/spectrum/energy features for the six original scenes; let each compatibility engine perform its required analysis from PCM. Test sample rates, mono/stereo/multichannel input, playback speed, crossfade/gapless behavior, pause, buffering and Bluetooth latency.

Do not assume libmpv exposes an arbitrary decoded-PCM callback. Prove the chosen tap in the pinned mpv build. If an engine patch is required, maintain it in the correct build source, produce all affected binaries, and update dependency locks with checksums. The audited [mpv lock](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/mpv-build.lock.json) still names `edde746/mpv-build`; do not assume the SnapeTech fork is already the active dependency.

When passthrough, protected paths, remote casting, or a TV backend cannot expose suitable PCM, show an accurate capability state. Preserve the existing output mode; do not silently disable Atmos/passthrough or start another decoder. Offer the original loudness/ambient scenes where available. A change to decoded output is a separate explicit user action.

The native renderer must own its graphics context/thread and texture lifecycle. Verify GL/GLES versus Flutter graphics-backend interop on each platform. Prefer GPU resource sharing where available; measure any copy/readback path before accepting it. For Apple, explicitly qualify the GL-to-native-texture route or a supported translation layer/native MilkRust renderer; desktop OpenGL success does not prove iOS/tvOS support. Cache shader programs and textures, dispose on session shutdown, and handle surface loss/resume without retaining stale IDs.

# MilkRust compatibility closure

Preserve the existing crates and web SDK where useful. Repair behavior before undertaking cosmetic crate splits.

1. Normalize actual MilkDrop document keys and historical encodings without silently dropping source. Preserve unknown fields for round trips and issue structured diagnostics with filename, section and line. Place limits on source size, indexed-entry counts and embedded assets.
2. Match expression evaluation and state lifetimes: initialization versus frame versus vertex/point code; preset/global versus shape/wave scopes; q/t/register arrays, memory buffers, math and boolean behavior, random seeds and edge cases. Use reference traces and bounded execution rather than matching only function names.
3. Model separate warp, drawing, feedback, blur and final composite stages. Preserve the feedback history and resolution/aspect conventions that determine the image. A shader fallback must carry an explicit degraded status.
4. Replace the narrow string translator with a tested compiler/translation path for the required HLSL subset and semantics. Pin upstream parser/compiler dependencies and document their licenses. Generate GLSL or WGSL through a typed representation and validate each target on real GPUs.
5. Implement a production native renderer and C ABI with opaque handles, ownership/error rules, version negotiation and panic containment. Do not present WebGPU batch structs, a backend enum or headless statistics as a functioning GPU renderer.
6. Implement `.milk2` using reference fixtures, independent state/textures and the saved blend pattern/settings. Add sprites, embedded images and injection behavior to the matrix where the corpus requires them.
7. Add the Butterchurn converter/evaluator only after deciding a safe declarative representation. Treat package-level MIT metadata as evidence to audit alongside embedded preset/asset provenance, not a reason to relabel unrelated raw presets.
8. Run projectM and MilkDrop reference comparisons where appropriate. Compare multiple timestamps and sequences with fixed audio/seed/settings. Use tolerant image metrics and feature assertions plus manual review of representative differences; a single pixel-identical screenshot is not the universal cross-GPU criterion.

The reference harness must validate itself with deliberate failures: missing shaders, empty preset fields, omitted files, missing textures, an always-black renderer, and a renderer that always draws the same image. Record original-source hashes and transformed-source hashes separately.

# Preset repository and downloadable packs

Build from MilkRust’s existing content tree. Keep a small original starter pack in the PlezyNG application bundle so the feature works before any download. Host larger pack archives as immutable release assets; commit source manifests, provenance, build tooling, notices and compatibility results. Pin content revisions instead of fetching moving branches at install time.

The existing community lane already has `NOASSERTION` status, attribution/source notes, removal instructions and default-build exclusions. Preserve those facts. Resolve the policy’s conflicting “no-license not vendorable” and “community imports allowed” language in one authoritative distribution matrix. Do not delete or rewrite repository history as part of this work.

A disclaimer records provenance; it does not create redistribution permission. For each downloadable pack, record the actual redistribution basis and obligations. Cleared content can be bundled or hosted; unresolved entries remain discoverable through source links and local import until a distribution decision is supported. This affects hosting, not the engine’s ability to load user-provided presets. References: [existing content policy](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/docs/THIRD_PARTY_CONTENT_POLICY.md), [existing notice](https://github.com/snapetech-org/MilkRust/blob/bca17689c4c8a1a9e0554d3a576f6bbe8672cc7e/content/community-unlicensed/projectm-milkdrop-original/RUSTYMILK-COMMUNITY-NOTICE.md), [upstream license note](https://github.com/projectM-visualizer/presets-cream-of-the-crop/blob/master/LICENSE.md), [GitHub licensing explanation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).

Each versioned pack manifest must include pack ID/version, format/schema version, engine requirements, source revision/URLs, authors, per-asset license exceptions, notices, file hashes and sizes, compressed/expanded totals, preset counts, tags, thumbnails and texture-pack dependencies. Catalog entries add immutable archive URL/hash, compatibility-report reference, availability/distribution status and superseded/revoked state. Preserve original filenames and authors; separate content deduplication from attribution.

Use deterministic zip-based `.rmpack` archives over the existing folder-manifest model. Define schema migration and compatibility behavior. Authenticate the catalog with a pinned signing key and rotation/revocation strategy; hashes verify archive integrity but are not a substitute for a trusted catalog. A bad signature or unavailable network must leave installed packs usable.

Notices must appear in the repository, archive `licenses/` or equivalent, pack detail screen, and app acknowledgements. Keep code licenses separate: PlezyNG’s GPL text, MilkRust’s AGPL-3.0-only scope and projectM’s LGPL obligations all need a recorded distribution implementation. Do not silently relabel the combined distribution or downloaded artwork.

Create thumbnails from deterministic rendering only for publishable assets. Resolve texture dependencies before calling a preset ready, and retain missing-texture diagnostics. Include an author-removal process that updates future catalogs/releases without deleting user-created content.

# Pack manager and app experience

Use **Now Playing → Visualizer → Browse → Get more presets** as the primary path, with local file/folder import beside it. Keep the app’s typography, coral accent, spacing, surfaces, focus behavior and existing transport controls.

The browser should provide Original scenes, Installed presets, Favorites and Downloads, with search by title/author/pack, tags, compatibility filters, thumbnail or lightweight preview, next/previous, shuffle, preset lock, timed changes, transition length and optional beat-based switching. Remember the selected engine/preset, favorites, playlists and display choices per profile. Deduplicate immutable assets at device level while keeping profile choices separate.

Pack details show author/source, version, download and installed size, preset count, requirements, current compatibility evidence and notices. Offer Install, Cancel, Retry, Update, Remove and source/import actions as appropriate. Show download progress and failure reasons without interrupting the playing track. No catalog fetch or asset download should occur merely because music playback starts.

Use the app’s existing download, storage, archive and network abstractions where suitable, with a distinct visualization namespace. Install through download → verify → bounded extraction → schema/dependency validation → index → atomic activation. Keep the previous version until the replacement is complete. Persist task state for crash/restart recovery; resume only when range/ETag identity is valid, otherwise restart cleanly. An incomplete pack must never become selectable.

Reject archive traversal, absolute paths, symlinks, case-collision ambiguity, oversized/decompression-bomb input, executable plugins and remote shader includes. Budgets for file count, expanded bytes, image dimensions, parse/compile time and cache size must be explicit and tested. Treat user-created presets as separate copies so updates/removals cannot overwrite them. Shared textures use dependency reference counts.

Installed packs play offline; browsing cached metadata works offline; updates fail gracefully. Local imports support loose `.milk`/`.milk2`, folders and supported archives. Export selected presets/playlists and permitted assets with provenance preserved.

Fullscreen controls must work with mouse, keyboard, touch, D-pad and gamepad, retain focus, and exit predictably with Back/Escape. Hide transport chrome after inactivity, but keep it recoverable. Reuse app accessibility/reduced-motion preferences; provide a static/original scene fallback. Do not show advancing “live spectrum” status when the source is only ambient or analyzed loudness.

# Qualification and release gates

| Gate | Required evidence |
| --- | --- |
| Corpus accounting | Every enumerated preset appears in the result set, including failures; no `filter_map` disappearance |
| Parser and semantics | Real-format fixtures, encoding cases, state-scope traces, `.milk2` fixtures, texture dependencies and negative controls |
| Rendering | Actual engine/GPU sequences for the claimed corpus; separate parse, compile, draw and fidelity results |
| Audio | Known waveform/sweep/impulse tests, timestamp/reset checks and a playback soak with visualization on/off; no analysis-induced underruns |
| Downloads | New install, cancellation, restart, network loss, bad hash/signature, disk-full, corrupt archive, update rollback and offline reuse |
| Lifecycle | Repeat open/close/fullscreen/resize/seek/profile changes, surface loss/resume and music-to-video ownership transfer |
| UX | Desktop/touch/TV navigation, focus, localization, screen-reader labels and reduced-motion behavior |
| Packaging | Native dependencies and starter pack included in installed builds; downloadable packs available at immutable catalog URLs |
| Performance | Named hardware, resolution, preset corpus, audio source, engine revision and frame-time/memory/thermal measurements |
| Release | Versioned reports, source/notices, correct capability ledger and verified published assets |

Initial performance targets are **targets, not measurements**: 60 fps at 1080p on the primary desktop class, with p95 visualization frame time within 16.7 ms; a measured 30 fps/720p tier for constrained devices; adaptive render scale and shader/texture limits; no visualization render loop while hidden. Quantify baseline audio reliability and memory before setting final regression thresholds. Run a two-hour mixed-preset soak and repeated install/update/dispose cycles; investigate sustained memory growth.

Qualify Linux x64/arm64 and Wayland, Windows x64/arm64, macOS Apple Silicon and any supported Intel build, Android handheld/TV, iOS/iPadOS and tvOS separately. webOS/Tizen require explicit native-rendering and PCM feasibility evidence; keep their integration tickets open until actual device qualification. An ambient fallback is useful but does not count as MilkDrop support on that platform. Linux AMD hardware and the M4 Mac are useful early targets, not substitutes for the remaining matrix.

For the initial imported corpus, every file must be accounted for and every advertised preset must pass the declared renderer tier. Full custom compatibility requires the MilkRust gate too. Newly discovered valid formats/features add tracked conformance cases; exceptions remain visible rather than quietly shrinking the denominator.

CI must follow both repositories’ **private ephemeral JIT runner** requirement, including GPU/device-capable coverage where necessary. Never add GitHub-hosted fallback or disturb active builds. Missing hardware/capacity is an explicit unresolved qualification item. Update [PlezyNG’s capability ledger](https://github.com/snapetech-org/PlezyNG/blob/bae33540a1bad9d230c519d1043d58da5c291f32/docs/maintainers/capability-manifest.json) with implementation, test, device and release states separately.

Luna should deliver reviewable PRs, exact engine/content pins, reports, logs and representative captures; update the user guide, acknowledgements and changelog. A merged PR, successful build or draft release alone does not establish downloadable delivery.

# Luna start prompt

```codex-prompt
Implement the PlezyNG visualization completion plan on this Page. The host is snapetech-org/PlezyNG and the reusable custom engine/content source is snapetech-org/MilkRust. Read current AGENTS.md files and preserve unrelated work.

Start with V0: reproduce the standard MilkDrop shader/key parsing blind spots, report every corpus file including read/encoding failures, and reconcile npm tool entrypoints. Then implement V1 and V2 as a real audio-to-native-texture vertical slice in PlezyNG. Use the dedicated Player.audio() path; do not substitute microphone capture, a second playback decoder, synthetic FFT or a wireframe preview for actual playback visualization.

Proceed through the pack builder, transactional importer, in-app download catalog and finished theme-consistent controls. Complete MilkRust parser/VM, separate warp/composite rendering, native ABI and MilkDrop 3 double-preset compatibility against the same conformance harness. A projectM integration does not close the MilkRust track.

Keep the existing six original scenes and feed live features where supported. Preserve passthrough and playback ownership. Package community content with exact provenance, author credits, notices and recorded distribution status. Treat parsing, rendering fidelity, device qualification and published availability as separate gates.

Work in reviewable PR-sized packages, use private JIT runners only, and keep a progress ledger with implemented/tested/qualified/released evidence. Do not claim all presets work from static parser reports, and do not stop at scaffolding. If a platform or external distribution requirement blocks completion, finish independent work and record the exact remaining dependency and next action.
```

## Current implementation ledger — 2026-10-28

The audit and completion contract above are retained as the original plan.
[IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) is the current source and
qualification ledger; [USER_GUIDE.md](USER_GUIDE.md) documents the implemented
workflow. The draft PRs carry the original plan and incremental source commits.

V1/V2 now have a Linux host implementation: pinned projectM FBO/pause-clock
patches, a bounded same-player PCM extension, native resampling, worker-owned
EGL rendering, leased Flutter texture sessions, and Dart selection/control.
The PCM patch has been composed with the 23 existing common/Linux patches from
the locked mpv-build revision. There are still no new native binary artifacts.

V6–V8 now include preset selection, profile-scoped favorites/display choices,
named playlists and reference import/export, ordering, shuffle/lock/timing,
transition length, quality reduction, fullscreen, download cancellation,
version-aware updates, serialized mutations and startup replacement recovery.
These are source implementations, not executed user-flow or renderer results.

The full completion contract remains open. In particular, a complete native
MilkRust renderer, faithful shader/.milk2 handling, other platform hosts,
broader cleared content and signed catalog publication, bounded compiler/GPU
hang containment, and real artifact/device/conformance evidence are not done.
No tests, builds, CI, render captures or device qualification were run in this
session. Source preparation is recorded separately from those checks.
