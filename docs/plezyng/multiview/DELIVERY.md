# Multiview delivery ledger

Status: **in progress; no pull request yet.** This ledger is for the feature branch and must be updated from evidence as implementation continues.

Source baseline: PlezyNG main `62b2ed0f4dd8c287e026bcc356e65395366c6b4a`. The user requires this work to stay on `codex/multiview-workspace-20261026`, be tested thoroughly, and not be merged to main.

## Implemented in code, not yet verified

| Area | Current implementation |
|---|---|
| Workspace state | Profile-scoped session descriptors, floating/split/fullscreen layouts, focus, placement history, audio and game-input leases, restore/park/tray actions, schema migration and safe metadata persistence. |
| Shared interaction | Flutter overlay shell; tap focuses; video panes support long-press drag; title-bar drag and explicit keyboard/remote Move mode work across panes; title double-tap and explicit fullscreen action promote; resize and screen-reader resize actions. Reader gestures remain available. |
| Video | Keeps the existing screen-owned video session while its video widget is presented in the workspace. Native rectangle hooks are implemented in code for Android, Apple, Windows and Linux, with the latest bounds retained until player initialization; webOS retains its own video surface widget path. This is currently one live video owner, not independent concurrent video decoding. |
| Music | Reuses the existing queue, visualizer and transport; workspace audio ownership gates output without changing saved volume; video/source playback claims can retain the music service when it is part of the workspace. |
| Source media | Source audiobook/video playback has a workspace pane and route restore/close flow. Its existing progress owner remains authoritative. |
| Publication readers | Existing PDF/EPUB/comic reader route can be presented in a workspace pane. Read-along and TTS update its audio capability and transfer workspace audio ownership. |

## Cross-platform target map

This is a code-path map, **not device qualification**. No target has been verified by this implementation pass.

| Target | Intended path | Current blocker/evidence |
|---|---|---|
| Android phone/tablet/TV | Shared Flutter overlay; MPV/Exo native surface bounds | Native adapter edits are unbuilt and untested. One video core remains. |
| iOS/iPadOS/tvOS | Shared Flutter overlay; Apple native video layer bounds | iOS source is also wired into tvOS; platform builds and remote/focus behavior are unverified. |
| macOS | Shared Flutter overlay; native video layer bounds | Native build and window-scale behavior are unverified. Separate desktop pop-out windows are not implemented. |
| Windows | Shared Flutter overlay; child HWND bounds | Native build, DPI/monitor moves and z-order behavior are unverified. |
| Linux | Shared Flutter overlay; Wayland video plane | Wayland-only path; X11 support is not claimed. Native build and compositor behavior are unverified. |
| webOS TV | Shared Flutter overlay; existing webOS surface widget | No device validation; platform-specific overlay and remote focus remain open. |

## Not complete

- Independent concurrent video cores and event/lifecycle identity. Two live videos can currently collide through the existing singleton player channels; the UI must not claim dual-video support until this is fixed and tested.
- A real compositor/software fallback for overlapping video, reader and game surfaces; native plane clipping, z-order and occlusion are not yet qualified.
- Games integration. The current main baseline has no Games engine/API to host. Keep this scenario open until a compatible engine lands; do not import unrelated dirty worktree changes into this branch.
- Portable EPUB/PDF/comic reader implementations and semantics on every target, especially TV/webOS.
- Desktop detached-window hosts and crash/dock recovery.
- Complete resource admission, thermal behavior, fallback diagnostics and full localization/semantics review.
- Native builds, deterministic suite results and device qualification.

## Verification record

- Flutter/Dart SDK: unavailable in the current workspace at the time of this update.
- Tests authored but not run: workspace controller/persistence/ownership, playback coordinator retention, MPV/Exo rect channel contract, and Flutter video pane bounds on move.
- Tests/builds: not run.
- Device qualification: none.
- Do not mark a package verified or create the draft PR until its required code and evidence are present.
