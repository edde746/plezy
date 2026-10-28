# Visualizer implementation status

Updated: 2026-10-28

This delivery is tracked by [PlezyNG PR #55](https://github.com/snapetech-org/PlezyNG/pull/55) and [MilkRust PR #20](https://github.com/snapetech-org/MilkRust/pull/20). The original end-to-end plan remains in [`COMPLETION_PLAN.md`](COMPLETION_PLAN.md).

## Implemented on the PR branches

- PlezyNG keeps the six existing original scenes and now exposes a theme-styled Visualizer Library sheet from their on-screen controls.
- The sheet can download the versioned CC0 MilkRust fixture pack from an immutable commit URL and SHA-256, verify its package and per-file integrity indexes, enforce archive size/path/file-count limits, validate per-asset author/license/source/notice coverage, and activate the completed pack atomically.
- The sheet can save individual user-provided `.milk` and `.milk2` text files in a separate local-import area. Imports are size- and format-bounded.
- The sheet exposes upstream links for historical projectM collections whose repository catalog records `NOASSERTION`; PlezyNG does not rehost those packs.
- MilkRust's compatibility parser recognizes the classic numbered `warp_N` and `comp_N` shader keys and several community indexed-object key forms. The CLI retains files it cannot decode and reports them as unsupported.
- MilkRust's import and compatibility gates reject blank or comments-only preset files instead of treating the absence of unsupported syntax as proof of compatibility.
- MilkRust's intermediate two-state frame set now resolves shader sources and texture samplers for each preset independently.
- MilkRust now has a deterministic `.rmpack` builder which refuses packs without explicit redistributable status, per-asset author/license/source records, complete content-file coverage and shipped license notices. The first catalog archive contains only the small CC0-authored sample fixtures.
- Root npm scripts use the checked-in tool filenames. The stale gap audit was replaced with a source-linked remaining-work inventory.

## Still open; no release claim

- PlezyNG has not integrated a MilkDrop renderer. The downloaded and imported `.milk` files are stored locally and shown in the library, but cannot be selected for playback. The six original scenes remain the only playback visualizers.
- The current audio path does not expose decoded PCM or live FFT to the visualizer. Plex analyzed loudness and ambient animation remain the existing inputs; neither is reported as live spectrum.
- MilkRust's expression and shader support is partial. Numbered shader parsing does not complete HLSL semantics, separate warp/composite rendering, feedback/transition behavior, or MilkDrop 3 `.milk2` double-preset behavior.
- The repo's historical community packs remain `NOASSERTION` and separated from the redistributable fixture. The sample archive is a packaging demonstration, not the requested complete community library.
- Pack update/migration, resumable or cancellable downloads, a signed remote catalog, pack search/favorites/playlists, preset thumbnails/previews, and app-side compatibility diagnostics remain open. Basic install and remove actions exist for the one fixture pack and local imports.
- Web storage is explicitly unsupported by this first pack store. Native platform builds, actual renderer fidelity, audio latency, memory/performance, TV navigation and physical-device qualification have not been established.

## Commit and qualification record

The source and packaging changes are committed on the draft PR branches. No checks or CI were run, consistent with the current project constraint. The private ephemeral JIT runners and required device/GPU matrix remain the qualification path when enabled. Neither PR is ready to merge as a completed MilkDrop feature until the open engine, audio, licensing and platform gates above are addressed.
