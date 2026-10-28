# Visualizer implementation status

Updated: 2026-10-28

This delivery is tracked by [PlezyNG PR #55](https://github.com/snapetech-org/PlezyNG/pull/55) and [MilkRust PR #20](https://github.com/snapetech-org/MilkRust/pull/20). The original end-to-end plan remains in [`COMPLETION_PLAN.md`](COMPLETION_PLAN.md).

## Implemented on the PR branches

- PlezyNG keeps the six existing original scenes and now exposes a theme-styled Visualizer Library sheet from their on-screen controls.
- The sheet can download the versioned CC0 MilkRust fixture pack from an immutable commit URL and SHA-256, verify its package and per-file integrity indexes, enforce archive size/path/file-count limits, validate per-asset author/license/source/notice coverage, show the pack's content notice, cancel downloads, remove canceled partials, and activate completed packs atomically.
- The sheet can batch import user-provided `.milk` and `.milk2` files into a separate local-import area. Batch count/total bytes and per-file sizes are bounded, and failures are reported without discarding successful imports.
- The sheet can import `.rmpack` archives from local storage. Archive and expanded sizes are bounded; installation verifies safe paths, every indexed digest, complete attribution coverage, allowlisted redistributable licenses, shipped notices and HTTPS provenance before an atomic install or replacement. Imported packs can be removed from the library.
- The library now searches pinned-pack metadata, imported pack names/authors/preset titles/tags, and imported loose-preset filenames. Device-local favorites are available for catalog pack entries, imported packs and loose imports; they are not profile-specific and do not make stored presets playable.
- The sheet exposes upstream links for historical projectM collections whose repository catalog records `NOASSERTION`; PlezyNG does not rehost those packs.
- MilkRust's compatibility parser recognizes the classic numbered `warp_N` and `comp_N` shader keys and several community indexed-object key forms. The CLI retains files it cannot decode and reports them as unsupported.
- Both MilkRust expression evaluators now preserve `&&` / `||` short-circuiting and lazy `if()` / ternary branches, apply the reference evaluator's 1e-5 boolean threshold, distinguish boolean `band` / `bor` / `bnot` from bitwise `&` / `|`, and treat `^` as left-associative power. They also implement `invsqrt`, integer `%` / `mod`, `^=` / `%=` / `&=` / `|=`, simple variable/megabuf `if()` lvalue passthrough, `memcpy`/`memset` destination-reference assignment targets, bounded `memset` and the documented no-op `freembuf`; unsupported `bxor` was removed from the claimed MilkDrop function set. Regression cases are committed on MilkRust PR #20 but unrun.
- The community CLI report now exposes per-file read/parse/current-subset status and per-preset diagnostics, with render and visual-fidelity stages explicitly unassessed. It marks presets that need separate warp/composite stages or MilkDrop 3 saved `.milk2` blend state as blocked by current renderer gaps. Generated pack summaries include a deterministic source-corpus SHA-256.
- MilkRust's import and compatibility gates reject blank or comments-only preset files instead of treating the absence of unsupported syntax as proof of compatibility.
- MilkRust's intermediate two-state frame set now resolves shader sources and texture samplers for each preset independently.
- MilkRust now has a deterministic `.rmpack` builder which refuses packs without explicit redistributable status, per-asset author/license/source records, complete content-file coverage and shipped license notices. The first catalog archive contains only the small CC0-authored sample fixtures.
- Root npm scripts use the checked-in tool filenames. The stale gap audit was replaced with a source-linked remaining-work inventory.

## Native renderer feasibility probe

Read [NATIVE_INTEGRATION_PROBE.md](NATIVE_INTEGRATION_PROBE.md) for the 2026-10-28 API check. Flutter's Linux external-texture API expects a GL texture, while projectM 4.1.8's released API renders to framebuffer 0; projectM's user-FBO entry point is marked for 4.2.0 and is not yet in the released version. The dedicated libmpv music core also exposes no PCM stream through PlezyNG's existing Dart bridge. V1/V2 therefore remain unimplemented pending a pinned native dependency path for both user-FBO rendering and a same-player PCM tap. No test/build/CI was run.

## Still open; no release claim

- PlezyNG has not integrated a MilkDrop renderer. The downloaded and imported `.milk` files are stored locally and shown in the library, but cannot be selected for playback. The six original scenes remain the only playback visualizers.
- The current audio path does not expose decoded PCM or live FFT to the visualizer. Plex analyzed loudness and ambient animation remain the existing inputs; neither is reported as live spectrum.
- MilkRust's expression and shader support is partial. The targeted EEL fixes in PR #20 do not complete generic reference propagation through nested calls/arithmetic, RNG fidelity, complete memory-index edge cases, HLSL semantics, separate warp/composite rendering, feedback/transition behavior, or MilkDrop 3 `.milk2` double-preset behavior.
- The repo's historical community packs remain `NOASSERTION` and separated from the redistributable fixture. The sample archive is a packaging demonstration, not the requested complete community library.
- A signed remote catalog, broader cleared community downloads, per-preset favorites/playlists, thumbnails/previews, and app-side compatibility diagnostics remain open. Local `.rmpack` import validates the package's own index and rights metadata but does not authenticate the pack author; it cannot establish MilkDrop compatibility or playback support.
- Web storage is explicitly unsupported by this first pack store. Native platform builds, actual renderer fidelity, audio latency, memory/performance, TV navigation and physical-device qualification have not been established.

## Commit and qualification record

The source and packaging changes are committed on the draft PR branches. No checks or CI were run, consistent with the current project constraint. The private ephemeral JIT runners and required device/GPU matrix remain the qualification path when enabled. Neither PR is ready to merge as a completed MilkDrop feature until the open engine, audio, licensing and platform gates above are addressed.

### EEL memory-reference follow-up

MilkRust PR #20 now also preserves the destination reference for `memcpy(...) = value` and `memset(...) = value` assignment targets in both expression evaluators. Targeted regression cases cover these forms and remain unrun. Generic references through nested calls/arithmetic and full memory semantics remain open.
