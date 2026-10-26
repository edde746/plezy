# Multiview delivery ledger

Status: **feature code complete; draft PR #32 opened; CI and device validation pending.** This ledger is for `codex/multiview-workspace-20261026`; the PR remains draft and the branch is not to be merged to main before release review.

Source baseline: PlezyNG main `62b2ed0f4dd8c287e026bcc356e65395366c6b4a`. The user requires this work to stay on `codex/multiview-workspace-20261026`, be tested thoroughly, and not be merged to main.

## Implemented in code; platform qualification remains open

| Area | Current implementation |
|---|---|
| Workspace state | Profile-scoped session descriptors, floating/split/fullscreen layouts, focus, placement history, audio ownership and exclusive gamepad-input leases, restore/park/tray actions, schema migration and safe metadata persistence. `WorkspaceGameInputBinding` routes raw controller events only to the focused interactive adapter while its pane retains Flutter focus and is not in Move mode, stops app-navigation repeats at handoff, captures mapped desktop key mirrors without dropping raw input, and signals control resets on lease release, focus loss, app backgrounding and controller disconnect. A dialog, positioning action or another route taking focus suspends the gamepad lease. |
| Shared interaction | Flutter overlay shell; tap focuses; long-press drag works on every pane surface, with title-bar drag and accessible Move mode as alternatives. Keyboard/remote arrows move and resize. Title double-tap and the explicit fullscreen action promote. Floating media windows expose a direct, labeled return action in the title bar; the session tray offers the same action for parked and hidden sessions. |
| Video | Keeps each existing screen-owned video session while its widget is presented in the workspace. Primary and companion MPV channels are registered independently on Android, iOS, macOS, Windows and Linux; Android Exo also has separate channel/core/event instances. `PlaybackCoordinator` reserves a free slot before async teardown and retains it through native disposal; admission caps video at two sessions. webOS continues to use its independent VideoPlayerController surfaces. |
| Games | Merged the Games library and native engines into this feature branch. Android Steam now exposes a retained PlatformView with independent native transport/decoder/audio, workspace audio ownership and exclusive gamepad/key routing. Full-screen Steam and GameStream remain available through their existing activity flow. GameStream/Moonlight and all non-Android targets do not advertise an embedded game surface. |
| Music | Reuses the existing queue, visualizer and transport; workspace audio ownership gates output without changing saved volume; video/source playback claims can retain the music service when it is part of the workspace. |
| Source media | Source audiobook/video playback has a workspace pane and route restore/close flow. Its existing progress owner remains authoritative. |
| Publication readers | Existing PDF/EPUB/comic reader route can be presented in a workspace pane. Read-along and TTS update its audio capability and transfer workspace audio ownership. |

## Shared cross-platform interaction

The workspace uses one Flutter interaction and state model across supported targets. Placement is stored as normalized app-window geometry, while each video backend applies physical-pixel bounds through its platform adapter. This keeps focus, pane actions, audio/input ownership and restore behavior consistent without depending on operating-system PiP.

Touch users tap to focus and can long-press-drag any floating pane. Short taps and normal content gestures remain available; title-bar dragging, the explicit Move control and keyboard/remote Move mode provide alternatives. Arrow keys move in Move mode, Enter commits, and Escape cancels; accessibility semantics expose incremental resize actions. Double-tapping the pane title promotes it to fullscreen; the visible fullscreen control provides the same action to assistive and single-tap users. Companions stay available from the workspace tray until explicitly restored or closed.

### Turn Multiview on and off

Entry stays beside the current media workflow: video playback uses the picture-in-picture control in playback controls; music uses the matching control in Now Playing; audiobook/source playback uses its player action; PDF, EPUB and comic readers use the reader app-bar action; supported Steam games use the game-card menu. The action is labeled **Open mini player** and its tooltip/semantic label changes to **Return to full player** or **Return to full view** while that session is floating. The main video player and publication reader keep the same control in their floating surfaces, so the viewer can toggle back without reopening the item.

Every non-game floating window repeats the return action in its title bar. The close action is labeled as closing the mini player/window; closing ends that session, while returning preserves playback or reading progress in its normal full view. The workspace dock names the floating and side-by-side layout switch and opens **Manage media sessions** for swapping, parking or restoring another session. Games use the title-bar fullscreen action to expand their embedded surface; closing the game window ends that embedded session.

Native operating-system PiP remains a separate outside-app continuation path. The in-app controls above use the shared Flutter workspace on supported targets and do not depend on the native PiP API.

## Cross-platform target map

This is a code-path map, **not device qualification**. No target has been verified by this implementation pass.

| Target | Intended path | Current blocker/evidence |
|---|---|---|
| Android phone/tablet/TV | Shared Flutter overlay; separate MPV/Exo video cores; Android Steam PlatformView | Native adapter edits and app composition are unbuilt and untested. SurfaceView composition, audio/input handoff and two concurrent decoders need device qualification. |
| iOS/iPadOS/tvOS | Shared Flutter overlay; separate Apple MPV plugin instances and native video layers | iOS source is also wired into tvOS; platform builds and remote/focus behavior are unverified. |
| macOS | Shared Flutter overlay; separate MPV plugin instances and native video layers | Native build and window-scale behavior are unverified. Separate desktop pop-out windows are not implemented. |
| Windows | Shared Flutter overlay; separate MPV plugin instances and child HWNDs | Native build, DPI/monitor moves, task-message isolation and z-order behavior are unverified. |
| Linux | Shared Flutter overlay; separate MPV plugin instances and Wayland video planes | Wayland-only path; X11 support is not claimed. Native build and two-plane compositor behavior are unverified. |
| webOS TV | Shared Flutter overlay; existing webOS surface widget | No device validation; platform-specific overlay and remote focus remain open. |

## Not complete

- Native dual-video channels and slot leases are implemented across the existing MPV/Exo platform backends; server video and source-file video admission use the lease contract. The builds and target-specific simultaneous-decoder behavior are still unverified; physical plane z-order, HDR/DRM combinations and resource pressure need qualification.
- A real compositor/software fallback for overlapping video, reader and game surfaces; native plane clipping, z-order and occlusion are not yet qualified.
- Retained game coverage outside Android Steam. Moonlight still launches an Activity; iOS, tvOS, macOS, Windows, Linux and webOS have no in-app game surface yet.
- Portable EPUB/PDF/comic reader implementations and semantics on every target, especially TV/webOS.
- Desktop detached-window hosts and crash/dock recovery.
- Complete resource admission, thermal behavior, fallback diagnostics and full localization/semantics review.
- Native builds, deterministic suite results and device qualification.

## Verification record

- Flutter/Dart SDK: Flutter 3.47.1, Dart 3.13.1.
- Formatting: `dart format --output=none --set-exit-if-changed` passed for all changed Dart files.
- Focused tests: 44 passed across workspace controller/placement/persistence/ownership, overlay drag/fullscreen and reader Move mode, playback coordination, MPV/Exo deferred rectangle application, and video-pane geometry on move.
- A focused overlay widget test now covers the visible return and close labels for video and music windows and verifies that the return action restores the session. It is authored for CI but has not been run locally.
- Core analysis: `dart analyze` passed with “No issues found” for the workspace model/controller/overlay, music surface, playback coordinator, native player adapters, video rectangle contract, music player surface, and focused tests.
- New game-input bridge checks are pending: raw button/axis routing, inactive-owner safety, duplicate suppression, pane-focus gating, route-focus lease suspension, Move-mode suspension and held-control reset tests for lease release, focus loss, app backgrounding and controller disconnect were added after the 44-test checkpoint above. The 44-test result does not include these changes.
- Test environment caveat: the local complete checkout was an older `785fd870` tree, while the feature base is `62b2ed0`. The isolated test copy overlaid the feature branch files, but used small test-only compatibility adaptations for the older checkout’s missing WebOS plugin/source files, generated reader strings and settings entries. The focused results validate the changed workspace path; they do not replace testing on the exact feature base.
- Full repository analysis and test suite: not qualified on the exact feature base. Analyzer runs against the older checkout report missing source-reader modules, plugin packages and generated localization data that are present in the feature branch.
- Native builds and device qualification: not run. No platform is marked verified.
- Flutter verification is currently blocked in this workspace: the first-run Flutter CLI attempted to contact a link-local cloud metadata endpoint and automatic approval review rejected that access. I did not retry through Flutter, Dart, or another invocation path.
- This continuation adds native player-channel isolation, reserved primary/companion slots, a retained Android Steam PlatformView, capability-gated game admission, game audio/input lease routing, source-video slot selection, Dart/JVM regression tests and CI coverage. The new tests and Android app build are authored but not executed locally; the earlier Flutter first-run auto-review rejection bars another Flutter/Dart or Gradle-triggered Flutter invocation here. The dedicated workflow defines the focused tests, Steam unit tests and Android app build, but no hosted run or status is reported for the current draft head yet.
- Pull request #32: https://github.com/snapetech-org/PlezyNG/pull/32. It must remain draft until automated checks and device qualification are reviewed.
