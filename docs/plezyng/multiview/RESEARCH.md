# Evidence and feasibility

Research date: 2026-10-26. Code findings are pinned to main commit `b32e396c036b465136228b6ddc2e7c5b7fec3c4b`. Confidence labels describe evidence, not whether implementation or device certification has happened.

## Repository audit

| Evidence | Finding | Consequence | Confidence |
|---|---|---|---|
| [Upstream PipService](https://github.com/edde746/plezy/blob/main/lib/services/pip_service.dart), blob `7ce66b203926f04f4e6e70f7e1235ea6b52d45ce` | Availability gate names Android, iOS, macOS | Existing video PiP is real source functionality | High |
| [Fork PipService](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/services/pip_service.dart) | Singleton Boolean state and unscoped method channel | Extend with session identity and platform results; keep a legacy facade during migration | High |
| [PlezyActivity](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/android/app/src/main/kotlin/com/edde746/plezy/PlezyActivity.kt) | Android TV excluded; main activity enters PiP; no `exit` branch in the inspected PiP handler | Do not shrink the whole workspace; specify and test restore/exit behavior | High |
| [iOS/tvOS controller](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/ios/Runner/MpvPlayer/MpvPipController.swift) | iOS sample-buffer controller; tvOS stub reports false | tvOS is new adapter work, not a flag flip | High |
| [macOS controller](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/macos/Runner/MpvPlayer/MpvPipController.swift) | Private `PIP.framework`; moves video plus OSD layers | New generic floating windows use public AppKit APIs; test legacy compatibility separately | High |
| [PlaybackCoordinator](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/services/playback_coordinator.dart) | One registered video, files session, music teardown and narration callback; claims stop conflicting sessions | Replace implicit exclusivity with explicit admission and ownership, preserving legacy behavior | High |
| [PlayerBase](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/mpv/player/player_base.dart), [PlayerNative](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/mpv/player/player_native.dart) | Per-channel event ownership and stale-retirement safeguards; separate fixed music/video channels | Preserve generation safety; genuine concurrent players need independently addressed native instances | High |
| [Video](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/mpv/video.dart) | Native rectangles/planes rather than a generic Flutter Texture composition path | Z-order, crop, opacity, dialogs, WebViews, HDR, and transfer require native surface tests | High |
| [ProfileSessionScreen](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/navigation/profile_session_screen.dart) | Profile-owned provider tree and nested navigator; protected root routes | Place registry/workspace here, not above authentication or inside MainScreen tabs | High |
| [PublicationReaderScreen](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/screens/sources/publication_reader_screen.dart) | WebView/PDF controllers, narration, locator flushes tied to widget; TV explicitly unsupported | Extract session state and qualify a TV renderer before enabling reader panes there | High |
| [SourcePlayback](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/sources/source_playback.dart) | Existing file/audio/video progress and playback routing | Adapter must keep source authorization and sync behavior intact | High |
| [MusicVisualizer](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/widgets/music/music_visualizer.dart) | Existing scenes react to analyzed loudness when available; raw PCM/live FFT not exposed | Reuse current visuals; any new spectrum mode needs real audio data | High |
| [MiniPlayer](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/widgets/music/mini_player.dart), [MonoTheme](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/theme/mono_theme.dart) | Existing compact transport, artwork, focus, and monochrome token geometry | Extend these primitives; preserve ordinary one-session mini-player behavior | High |
| [webOS port status](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/docs/maintainers/webos-tv.md), [PlayerWebOS](https://github.com/snapetech-org/PlezyNG/blob/b32e396c036b465136228b6ddc2e7c5b7fec3c4b/lib/mpv/player/platform/player_webos.dart) | Experimental native Flutter port with LG media plane; plugin lacks usable per-stream gain | Treat concurrency and mixing as unqualified; never use system volume as a per-pane substitute | High |

The Games working-tree review is a **non-main integration observation**: `lib/games/game_streaming_client.dart`, `android/moonlight/.../EmbeddedGameStream.java`, and `docs/games/ARCHITECTURE.md` in the concurrent Games workspace. The interface exposes capability/pair/list/open/cancel, and Android starts an internal `Game` activity. Do not infer a merged feature or a live dual-surface implementation from those files. Find and pin the final revision in MV01.

## Platform evidence

| Source | Verified constraint or affordance | Design decision | Confidence |
|---|---|---|---|
| [Android PiP guide](https://developer.android.com/develop/ui/views/picture-in-picture) | Handheld activity PiP begins at API 26; platform owns window controls/placement; feature and permission checks matter | Keep native video PiP separate from interactive in-app floating panels; no system-alert-window workaround | High |
| [Android TV multitasking](https://developer.android.com/training/tv/get-started/multitasking) | TV usage categories explicitly exclude media playback in system PiP | Retain exclusion for media; offer in-app split/float and keep-clear geometry | High |
| [Apple custom PiP](https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-in-a-custom-player), [AVPictureInPictureController](https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller) | Supported public APIs concern media playback/content sources and system-owned PiP behavior | Do not promise a fully interactive ebook/game UI inside iOS native PiP; use application panes | High |
| [Apple tvOS PiP session](https://developer.apple.com/videos/play/wwdc2020/10176/) | tvOS supports simultaneous video, swaps and AVPlayer-associated Now Playing sessions | Platform capability exists, but Plezy's mpv path still needs a supported bridge or qualified compatible AVPlayer route | High for platform; moderate for our integration |
| [AppKit NSPanel](https://developer.apple.com/documentation/appkit/nspanel), [NSWindow level](https://developer.apple.com/documentation/appkit/nswindow/level) | Public window/panel APIs support application window composition and levels | Desktop pop-outs use public, tested NSWindow/NSPanel hosting; keyboard-capable readers may require a regular window | High |
| [Win32 SetWindowPos](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos) | Public topmost-window and nonactivating-position flags | Use existing Win32 runner for general pop-outs and opt-in keep-on-top | High |
| [Windows AppWindow](https://learn.microsoft.com/en-us/windows/apps/develop/ui/manage-app-windows) | CompactOverlay is another window presentation mechanism | Optional adapter only if it fits current runner/deployment requirements; not a reason to replace Flutter/Win32 | High |
| [GTK keep-above](https://docs.gtk.org/gtk3/method.Window.set_keep_above.html) | Window-manager hint can be refused | Linux pop-out works as a window; never label keep-on-top guaranteed without observed support | High |
| [LG multi-sound guide](https://webostv.developer.lge.com/develop/guides/multi-sound-playback), [LG developer support, July 2026](https://forum.webostv.developer.lge.com/t/multiplay-video-does-not-play/28313) | LG documents media-resource restrictions; its web-app guidance permits only one video, with emulator/device differences | Conservative single-media budget; native Flutter plugin needs independent device proof before exceptions | High for web guidance; unknown for additional native concurrency |
| [Chrome Document PiP](https://developer.chrome.com/docs/web-platform/document-picture-in-picture) | Arbitrary HTML can inhabit an always-on-top same-origin PiP window; opener lifetime and activation constraints apply | A future web port can enhance supported browsers, but this does not grant native Flutter reader/game support | High |
| [Flutter embedding](https://docs.flutter.dev/add-to-app), [multiple Flutter instances](https://docs.flutter.dev/add-to-app/multiple-flutters) | Multi-engine instances are separate Dart programs; multi-view support differs by target | Audit plugin/window compatibility; do not assume Dart objects or textures can be shared between desktop engines | High |

All API capability statements need runtime checks. SDK version, entitlement, distribution channel, backend, codec, content protection, output route and actual device resources can narrow the result.

## Initial adapter coverage, not the final feature ceiling

The user's follow-up makes app-owned PiP the cross-platform baseline. The table below records where native paths start; it is not permission to leave a platform's feature incomplete. COMPOSITOR.md specifies the missing custom/software paths and the parity target. Build and qualify them before marking a platform complete.

| Target | In-app split/float | Outside-app video PiP | Interactive pop-out | Safe starting budget |
|---|---|---|---|---|
| Android handheld/tablet/foldable | Planned | Existing; migrate ownership | OS multi-window integration later, not arbitrary overlay | One video + reader; raise after probes |
| iPhone | Planned | Existing supported path | No general floating app window | One video + reader where viewport is usable |
| iPad | Planned, responsive to OS window size | Existing supported path | Separate scene/window is a distinct future adapter | One video + reader; qualify two decoders |
| Windows | Planned | App-owned compact window | Planned | Two live video surfaces only after isolation/probes |
| macOS | Planned | Existing legacy route; public alternative work | Planned | Same; qualify HDR and OSD transfer |
| Linux desktop | Planned | App-owned window | Planned; keep-above conditional | Same; X11 and Wayland separate |
| SteamOS Gaming Mode | Planned inside app | No guaranteed shell overlay | Unqualified; use in-app fallback | Game + companion only after native game adapter |
| Android TV / Google TV | Planned | Media category excluded | No general app window promise | One video + qualified companion |
| Fire TV | Planned | Keep disabled until exact device/policy proof | No general app window promise | One video + qualified companion |
| Apple TV | Planned | New bridge required | No generic desktop window model | One video initially; qualify dual-video path |
| webOS | Planned within experimental port | No verified public route | No generic desktop window model | One media decoder; qualified static companion |
| Browser / Tizen / consoles | Separate ports, absent from audited target set | API/platform dependent | API/platform dependent | No support advertised by this change |
| Automotive | Existing restrictions continue | No new moving-vehicle visual mode | Not applicable | Audio only while driving; any parked view separately qualified |

In-app rendering on a platform does not automatically make every reader or Games backend available there. Admission is the intersection of the workspace renderer and the actual content adapter capabilities.

## Alternatives considered

- **Put existing screens in a Stack:** rejects the lifetime/channel problem and creates global gestures, media controls and native-plane conflicts. Not viable.
- **Use native PiP for every media type:** cannot provide consistent interaction or multiple external windows across targets. Retain native PiP for qualified video.
- **Rasterize every pane into a synthetic video:** loses accessible text and interaction, adds latency/power cost, and jeopardizes HDR/protected content. Not the default or a hidden fallback.
- **Launch external game clients and capture them:** does not preserve first-class session/input ownership. Only embedded engines with explicit surface capability qualify.
- **Server-side composite stream:** an optional advanced extension for explicitly paired helpers and suitable owned media, after local render paths. Adds latency and transcoding; never silently required for ordinary operation. It is not a substitute for a local interactive reader or a qualified low-latency game path. See COMPOSITOR.md.
- **New universal UI/window package immediately:** risks replacing working native paths before lifecycle constraints are known. Prototype behind interfaces first; pin any chosen dependency after the spike.

## Questions the spikes must answer

1. Can two independently identified mpv/Exo cores render, dispose and report without sharing event sinks or native surfaces on each target?
2. Can a video surface move between a main window, companion and OS PiP without reopening, losing OSD, or changing output color unexpectedly?
3. Which native surface/WebView combinations support overlap? Where must layout use nonoverlapping regions?
4. Does a second decoder fail cleanly, and can the first remain untouched when allocation fails?
5. Can each game engine host a resizable retained view, release controls, and survive temporary visual detachment?
6. Which platforms can mix decoded streams without exclusive-output conflicts, and which must remain one-audible-session only?
7. Can the selected desktop host architecture isolate plugins and persistence across engines without duplicating sessions?

Record exact device, OS, engine build, test media, backend and result. “Should work” is not a capability result.
