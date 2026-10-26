# Multiview delivery ledger

Status: **in progress; no pull request yet.** This ledger is for the feature branch and must be updated from evidence as implementation continues.

Source baseline: PlezyNG main `62b2ed0f4dd8c287e026bcc356e65395366c6b4a`. The user requires this work to stay on `codex/multiview-workspace-20261026`, be tested thoroughly, and not be merged to main.

## Implemented in code; platform qualification remains open

| Area | Current implementation |
|---|---|
| Workspace state | Profile-scoped session descriptors, floating/split/fullscreen layouts, focus, placement history, audio and game-input leases, restore/park/tray actions, schema migration and safe metadata persistence. |
| Shared interaction | Flutter overlay shell; tap focuses; video, music and audiobook panes support long-press drag; title-bar drag works across panes. Explicit Move mode enables body-drag for readers, comics and games while preserving their normal gestures otherwise; keyboard/remote arrows move and resize. Title double-tap and the explicit fullscreen action promote, and the session tray offers an accessible return to the source screen. |
| Video | Keeps the existing screen-owned video session while its video widget is presented in the workspace. Native rectangle hooks are implemented in code for Android, Apple, Windows and Linux, with the latest bounds retained until player initialization; webOS keeps its existing video surface widget path. A second retained video claim currently fails closed because the native channels still have one video owner. This does not provide independent concurrent video decoding. |
| Music | Reuses the existing queue, visualizer and transport; workspace audio ownership gates output without changing saved volume; video/source playback claims can retain the music service when it is part of the workspace. |
| Source media | Source audiobook/video playback has a workspace pane and route restore/close flow. Its existing progress owner remains authoritative. |
| Publication readers | Existing PDF/EPUB/comic reader route can be presented in a workspace pane. Read-along and TTS update its audio capability and transfer workspace audio ownership. |

## Shared cross-platform interaction

The workspace uses one Flutter interaction and state model across supported targets. Placement is stored as normalized app-window geometry, while each video backend applies physical-pixel bounds through its platform adapter. This keeps focus, pane actions, audio/input ownership and restore behavior consistent without depending on operating-system PiP.

Touch users tap to focus and can long-press-drag floating video, Live TV, music and audiobook panes. Floating panes also support title-bar dragging; reader, comic and game panes use an explicit Move mode for body dragging so page turns, zoom and gameplay gestures remain intact. Keyboard and remote arrows move in Move mode, Enter commits, and Escape cancels; accessibility semantics expose incremental resize actions. Double-tapping the pane title promotes it to fullscreen; the visible fullscreen control provides the same action to assistive and single-tap users. Companions stay available from the workspace tray until explicitly restored or closed.

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

- Independent concurrent video cores and event/lifecycle identity. Workspace-aware playback claims now refuse a second retained video session, but every video-opening path still needs auditing and the backend has no independent per-session channels. Dual-video support remains blocked.
- A real compositor/software fallback for overlapping video, reader and game surfaces; native plane clipping, z-order and occlusion are not yet qualified.
- Games integration. The current main baseline has no Games engine/API to host. Keep this scenario open until a compatible engine lands; do not import unrelated dirty worktree changes into this branch.
- Portable EPUB/PDF/comic reader implementations and semantics on every target, especially TV/webOS.
- Desktop detached-window hosts and crash/dock recovery.
- Complete resource admission, thermal behavior, fallback diagnostics and full localization/semantics review.
- Native builds, deterministic suite results and device qualification.

## Verification record

- Flutter/Dart SDK: Flutter 3.47.1, Dart 3.13.1.
- Formatting: `dart format --output=none --set-exit-if-changed` passed for all changed Dart files.
- Focused tests: 43 passed across workspace controller/placement/persistence/ownership, overlay drag/fullscreen, playback coordination, MPV/Exo deferred rectangle application, and video-pane geometry on move.
- Core analysis: `dart analyze` passed with “No issues found” for the workspace model/controller/overlay, music surface, playback coordinator, native player adapters, video rectangle contract, music player surface, and focused tests.
- Test environment caveat: the local complete checkout was an older `785fd870` tree, while the feature base is `62b2ed0`. The isolated test copy overlaid the feature branch files, but used small test-only compatibility adaptations for the older checkout’s missing WebOS plugin/source files, generated reader strings and settings entries. The focused results validate the changed workspace path; they do not replace testing on the exact feature base.
- Full repository analysis and test suite: not qualified on the exact feature base. Analyzer runs against the older checkout report missing source-reader modules, plugin packages and generated localization data that are present in the feature branch.
- Native builds and device qualification: not run. No platform is marked verified.
- Pull request: not created; the branch remains in progress.

