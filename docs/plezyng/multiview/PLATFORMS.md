# Adapter work and integration map

App-owned PiP is the default on every current target. Implement the common compositor/session contract first. Native PiP and detached OS windows extend that experience; they do not define feature availability.

## Shared files to modify carefully

| Existing area | Integration |
|---|---|
| `lib/navigation/profile_session_screen.dart` | Provide registry/workspace/audio/focus owners; insert workspace shell within profile and cover all surfaces for root auth |
| `lib/screens/main_screen.dart`, mini-player inset controller | Preserve existing navigation and browser position; reserve tray/companion space without duplicate mini-player |
| `lib/services/playback_coordinator.dart` | Compatibility facade plus explicit single-session replace versus workspace-add intents |
| `lib/screens/video_player_screen.dart`, `lib/screens/video_player/parts/*` | Extract retained playback/session lifecycle and split route shell from embeddable content; preserve watch-together, Live TV and display matching |
| `lib/mpv/player/player.dart`, `player_base.dart`, `player_native.dart`, platform backends | Session factory, identity, event routing, safe retirement and per-surface output |
| `lib/mpv/video.dart`, `video_rect_support.dart` | Window/view-aware placement, clipping and revisioned surface leases |
| `lib/services/pip_service.dart`, player PiP part | Scoped adapter; preserve existing working native PiP while adding ownership/results |
| `lib/services/music/*`, `lib/widgets/music/*` | Retained single music session reused by compact/full/companion views; suppress duplicate queue/player construction |
| `lib/services/media_controls_manager.dart` | Explicit transport owner and coordinated OS publication |
| `lib/sources/source_playback.dart`, `lib/screens/sources/*`, `assets/reader/*` | Independent retained source/reader sessions; canonical locator and progress writing |
| `lib/focus/*`, gamepad service, shortcut settings | Pane scope, capture lease, no stale focus restoration or control leakage |
| `lib/theme/*`, `lib/widgets/app_menu.dart`, overlay sheets | Reuse exact design contracts and token/motion behavior |
| Existing Games paths when landed | Retained engine session and embeddable surface; never infer capability from a game launcher |

New proposed Dart areas: `lib/multiview/models/`, `session_registry.dart`, `workspace_controller.dart`, `workspace_admission.dart`, `workspace_audio_coordinator.dart`, `workspace_input_router.dart`, `workspace_store.dart`, `adapters/`, `widgets/`. Keep pure state/geometry logic independent of Flutter render widgets where practical.

## Android phones, tablets and foldables

Extend the mpv and Exo plugins with independently addressed instances and views. Audit `AudioFocusManager`, media sessions, wake locks, subtitle/ASS surfaces, fullscreen/orientation, refresh switching and background callbacks for application-global assumptions. Keep the main Activity alive across resizing and avoid resurrecting disposed sessions after configuration changes.

In-app Float does not enter Android PiP and needs no overlay permission. Compose native surfaces or use the qualified custom texture path. Ensure Flutter reader/WebView gestures and native video Z-order cooperate. Test both mpv and Exo; one passing backend is not proof of the other.

For optional system PiP, preserve the existing API 26+ behavior and permission path. Scope it to a selected video. The current implementation moves `PlezyActivity` itself; reduce the outgoing scene to the chosen surface before entering. Returning restores the exact workspace. If simultaneous full application navigation while an independent OS PiP Activity remains active is added, build a retained native-session host Activity rather than trying to show two copies of the same Flutter activity. Do not implement arbitrary system-alert overlays.

Provide supported request/restore/close semantics instead of assuming `PipService.exit()` is implemented. Observe lifecycle callbacks as authority, handle rejected/late entry, and retain the audio/video surface until the OS completes exit. Keep one selected auto-PiP candidate; opening readers, auth screens or games does not automatically nominate them.

## iOS and iPadOS

Keep existing sample-buffer PiP as an optional adapter. Own sessions above route views so PiP can outlive the original screen safely. Warm/readiness/timeout logic in the current controller must survive the refactor. System PiP transitions keep subtitles, aspect ratio, play/pause, seekability and source identity correct.

Build in-app PiP with retained native surfaces or the qualified Metal/composition path, plus Flutter reader/visualizer content. Coordinate one AVAudioSession for the application, background-audio entitlement/use, interruptions and remote controls. Do not make multiple independent audio plugins fight for category or output configuration.

Interactive books, PDFs, comics and games remain full application panes. Native sample-buffer video is not an arbitrary interactive widget window. Background suspension checkpoints other panes; retain only permitted active video/audio. iPad scene/multiple-window support is a separate adapter after the primary one-window workspace works; respect current window size, safe areas and external-display changes without assuming a specific OS multitasking UI.

## macOS

Build app-owned floating panels and detached reader/media windows with public AppKit hosting. Use a regular key-capable window for keyboard-heavy readers; a nonactivating compact panel may suit passive media. Keep-on-top is explicit, respects Spaces/fullscreen behavior, and must not float over authentication/profile gates.

Existing native PiP uses private PIP.framework. Keep it isolated as a legacy adapter while qualifying a public playback route or public application-owned window. Do not spread this dependency into the universal compositor. A deployment that cannot use the legacy route still gets our own PiP and pop-outs.

A window can host native video and a lightweight Flutter control view. Prove plugin registration across engines before using a full secondary Flutter UI. Native session ownership stays in the broker; secondary UI engines receive snapshots/commands, not database credentials or a second media player. Main-window close follows the app's chosen quit/minimize convention; detached sessions remain discoverable or close predictably.

## Windows

Extend `windows/runner/mpv/` and the Win32 window host with session maps, surface ownership, per-window geometry and clean shutdown. Use public native windows and optional `HWND_TOPMOST` behavior for generic pop-outs. `window_manager` alone manages the existing window; it does not provide the full multi-window session architecture.

CompactOverlay/AppWindow is an optional host, evaluated against the actual minimum supported Windows build and packaging. Prefer the existing runner when it gives the needed behavior. Qualify D3D/device loss, mixed DPI/monitors, GPU switching, fullscreen exit, minimize, accessibility and window-close races. Preserve subtitles and HDR at transfers or disclose a compatible route before changing output.

## Linux desktop and SteamOS

Extend the native mpv plugin/window host with independently identified surfaces. Qualify X11, Wayland and SteamOS desktop separately. An always-on-top request is a window-manager hint; show Keep on top only with accurate semantics and do not rely on it for reachability.

Gamescope/Gaming Mode is a separate compositor environment. The standard fallback is the same in-app workspace, not a promised overlay above unrelated games. Test docking/undocking, fractional scale, controller focus, keyboard summon, monitor disconnect and audio-device changes. Do not use privileged layer-shell/external-window capture as a hidden substitute for ordinary application windows.

## Android TV, Google TV and Fire TV

Own the in-app split and floating view. Existing Android TV exclusion in system PiP must remain for media under the published usage rules. Handle external PiP's keep-clear regions where relevant; do not misdeclare media as a ticker or communication app.

Use native/custom/hybrid rendering to pursue the same media pairs. Qualify weak and strong TV SoCs independently; actual decoder counts and thermal behavior matter. Fire models/OS versions require their own evidence; Android compatibility is not blanket PiP permission.

Build the TV reader adapters in COMPOSITOR.md, rather than removing the current TV rejection and leaving unusable touch-only controls. Use remote pane headers, move/size presets, readable typography and overscan safe areas. Embedded games use physical input by default; touch overlay is absent unless the device actually supports it.

## Apple TV

The current native PiP class is a stub. Deliver our own two-pane/float layout first with isolated mpv sessions and the app-owned compositor. Extend readers and games through supported tvOS adapters.

For optional system PiP, verify the actual supported AVKit content source. Apple's documented dual-video flow ties AVPlayer instances to MPNowPlayingSession. Do not cast the current mpv controller into that API or claim all mpv formats now use native PiP. A compatible AVPlayer source route may handle a subset; mpv content retains app-owned PiP unless a real supported bridge is built. Test remote play/pause targeting and system-initiated swaps/restoration.

## webOS

The experimental Flutter-webOS port uses `PLEZY_WEBOS=true` because dart:io reports Linux. Never route it through generic Linux desktop window assumptions. Preserve the verified LG media backend and its credential/source handling.

Build the shared layout and TV reader adapters. Audit the LG plugin's multiple-player allocation and native plane behavior; do not infer support from the emulator. Default reservations conservatively until evidence improves them. For dual video, implement/probe the hybrid or software companion pipeline in COMPOSITOR.md, using reproducible native ARM dependencies and supported rendering APIs. Do not claim a second hardware decoder by constructing a second Dart controller.

The current plugin does not expose usable per-stream gain; music/video mixing needs a genuine custom decoded audio path before sliders become functional. System volume is not an acceptable surrogate. Validate on the user's C6 and at least one lower-capacity target. The C6's existing single-video success says nothing about dual video, software decode or multiview HDR.

## Future web, Tizen and console ports

Keep the session/layout contract portable, but do not add support badges for absent builds. A web port can use in-document panes and feature-detected Document PiP for supported browsers, with video PiP or an ordinary window as alternatives. Observe user activation, opener lifetime, focus, source/CORS and protected-content limitations. It also needs a browser-compatible source/player layer; the current dart:io/native app does not become a web app through a PiP widget.

Tizen and consoles need native port/SDK qualification work before this feature can be certified there. Treat these as future adapter targets, not current app-owned parity failures on shipping platforms.

## Dependency and build policy

- Reuse Provider, existing native player bindings, `window_manager`, focus/gamepad primitives, Slang, Foliate, pdfrx and the comic renderer where capable.
- Reuse and pin current mpv/FFmpeg/libass builds before adding alternative decoder stacks. A new compositor bridge must record source revision, patches, license notices, reproducible build commands and target artifacts.
- Evaluate a desktop multi-window package only after plugin/engine ownership tests. If adopted, pin it and add lifecycle tests; its demo is not proof of video/reader portability.
- Keep optional game and software decoder modules build-gated with typed unavailable results; production capability probes must match what was actually compiled.
- Never download executable codecs or native libraries at runtime to satisfy a capability flag.
- Include native build/packaging verification for every modified target. Do not edit generated plugin registrants as the sole dependency integration.
