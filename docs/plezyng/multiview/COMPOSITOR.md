# Plezy-owned PiP and the cross-platform rendering ladder

This document incorporates the user's follow-up: **build our own PiP, make it the default, and pursue the same experience across platforms**. Native OS PiP is optional. A missing OS API does not block a floating or split view inside Plezy.

## Same product, several rendering adapters

Own the layout, pane chrome, drag/resize, snap/keep-clear, swap, audio selection, session tray, focus, checkpoints and help in shared Flutter code. The same actions must have the same meaning on Android, iOS/iPadOS, Windows, macOS, Linux/SteamOS, Android/Fire TV, tvOS and webOS.

Under that shared contract, choose the fastest qualified rendering path for a particular combination. Different native implementations are compatible with a consistent product. Do not make the user select “Metal PiP” or “Software PiP.” Normal UI says Float, Split, Swap and Listen; diagnostics report the actual path.

Target all pairs of video/Live TV, music/visualization, audiobook/narration, EPUB/PDF/comic and embedded game. Two independent videos and game-plus-video are required qualification scenarios, not categorically excluded product features. A parked substitute does not pass simultaneous-playback parity.

## Rendering ladder

| Priority | Path | Required engineering | Use |
|---|---|---|---|
| 1 | App-owned layout with native hardware video surfaces | Per-session surface IDs, atomic geometry, z-order and clipping | Best fidelity/latency where native surfaces compose correctly |
| 2 | App-owned GPU composition | Native decoder textures or supported libmpv render contexts, synchronized with Flutter chrome | Overlap, multiple native layers, independent cropping and consistent floating behavior |
| 3 | Hybrid | Main on hardware plane; companion decoded/rendered through a custom texture path | TVs or APIs with one hardware media plane but sufficient CPU/GPU for a small companion |
| 4 | Local software decode + GPU upload/composition | Bounded libavcodec/libmpv software path, proper timestamps/color and memory limits | Hardware-slot or unsupported interop fallback at qualified quality |
| 5 | Source-provided lower rendition or permitted server transcode | Existing Plex/Jellyfin/Emby/source negotiation | Reduce actual decode workload when the source permits it |
| 6 | Optional explicitly paired helper | Authenticated control and a composited stream for suitable media | Advanced constrained-device extension; separate deliverable and opt-in |
| Last | Preserved quick switching | Checkpoints/retained sessions as capacity permits | Honest failure containment when no simultaneous path is viable |

This is a decision tree, not an instruction to try every path blindly. Probe capability, output requirements and resource cost first. A backend switch is transactional, and quality changes obey the user's saved quality policy. Never re-encode the whole workspace by default. DRM/protected surfaces may forbid export/software decoding; use the authorized protected path and explain the actual restriction.

Software decoding is useful but not unlimited. Scaling an already decoded 4K frame down to a 360p pane usually does not avoid decoding the 4K source. Prefer an actual smaller source rendition when decode cost is the bottleneck. A tiny floating pane can still exhaust memory or decode bandwidth if fed a high-complexity source. Do not “fix” this by dropping timestamps or stopping the main session.

## Custom compositor contract

Proposed native module: `WorkspaceSurfaceBroker`, with platform hosts and a narrow engine-neutral frame/surface interface. Keep shared orchestration in Dart; native graphics calls remain native. Frame delivery never serializes raw pixels through a MethodChannel or sends per-frame Dart maps.

`FrameDescriptor` carries session/generation, frame sequence, presentation timestamp/duration, native resource handle, fence/lifetime token, coded/visible size, crop/rotation, pixel format/bit depth, color primaries/transfer/matrix/range, HDR metadata where supported, protection/export permissions, and subtitle composition mode. Resource handles are process-local and cannot be persisted.

The compositor must:

1. Acquire and release frames with explicit native lifetime/fence management; no producer reuse before the consumer finishes.
2. Present each session against its own media clock. Repeating a film frame at display vsync must not advance its position; a game session has its own low-latency scheduling policy.
3. Bound queued presentation frames separately from decoder-required reference frames. Prefer latest-frame presentation for games; never discard codec reference frames arbitrarily.
4. Composite in a defined color space with correct transfer/range conversion. Keep HDR/SDR mixing and alpha/UI luminance under the existing output policy; reject unqualified dynamic-metadata paths.
5. Apply viewport clip/crop, aspect-fit, subtitles and safe-area transforms without stretching or changing reader coordinates.
6. Synchronize native output and Flutter overlays to prevent stale rectangles, black seams, wrong-window frames or drawing over protected dialogs.
7. Survive resize, display-scale change, minimized windows, device/context loss and engine shutdown with bounded recovery.

A native plane may remain the compositor's output for the main video while companion UI uses another path. “Our own PiP” does not require rewriting codecs or copying every existing efficient native frame.

The [mpv render API](https://github.com/mpv-player/mpv/blob/master/include/mpv/render.h), [mpv playback documentation](https://mpv.io/manual/stable/) and [FFmpeg hardware decode example](https://ffmpeg.org/doxygen/trunk/hw_decode_8c-example.html) are starting points. Pin the versions actually bundled by Plezy; a standalone mpv GPU output backend is not automatically an equivalent libmpv embedding API. Validate render-thread requirements, GL context ownership and supported output format before choosing it. Reuse the existing mpv/FFmpeg builds where possible; do not ship a second unrelated codec stack without a concrete missing capability.

## Platform candidates to prove

| Platform | Candidate native/custom path | Specific proof required |
|---|---|---|
| Android | Separate Surface/SurfaceView outputs; qualified SurfaceTexture/AHardwareBuffer/EGL texture path | Texture import supported by actual decoder/output, correct overlay order, no extra latency, secure-surface behavior |
| iOS/iPadOS/tvOS | Retained display layers; CVPixelBuffer/IOSurface and Metal where the backend exposes them | Color/OSD parity, supported APIs, independent sessions, no hidden CPU copies; tvOS reader and game hosts are separate work |
| macOS | Existing native layers or qualified Metal/render context, public window hosting | Move between windows/displays without wrong scale, lost subtitles or legacy private-PiP dependence |
| Windows | Per-session native output, D3D11-compatible resource composition/Flutter interop | Texture ownership, synchronization, HDR swap chain/output, native child/window geometry |
| Linux/SteamOS | Per-session native plane; EGL/OpenGL or qualified dma-buf path | Actual embedder/driver support, X11/Wayland differences, synchronization, Gamescope behavior |
| webOS | Retain LG hardware plane; test a native software-decoded companion uploaded to supported GLES/Flutter texture path | Public SDK permits path, target ARM builds, model-specific CPU/GPU/thermal headroom, simultaneous primary plane + texture correctness |

These are engineering candidates, **not verified adapter availability**. In particular, LGPL/GPL library build feasibility alone does not prove webOS can sustain the requested decode workload. The milestone must demonstrate a real video-plus-video workload on a TV before claiming parity there.

## Readers on every current platform

Do not leave TV readers permanently disabled merely because the existing WebView screen rejects TV. Build `ReaderSurfaceAdapter` behind the same session contract:

- Comics: retained Flutter image/tile renderer, bounded decoded-image cache, spread/webtoon/panel mode, canonical page IDs, zoom and D-pad/controller navigation. Integrate the comic project rather than duplicating its page/progress model.
- PDF: qualify the existing pdfrx/PDFium path per target. Where native binaries are missing, build the renderer for that target or a compatible adapter, with text selection/search/semantics and page tiles. Raster-only pages do not satisfy full accessible reader parity.
- EPUB: keep the current Foliate/WebView adapter where supported. On targets without a supported WebView, evaluate a native/Flutter reflow renderer with EPUB spine/CSS/text layout, links, ruby/CJK/RTL, tables/images, selection/search, TTS, annotations and stable CFI mapping. A local packaged HTML page is not proof of a supported tvOS WebView. Fixed-layout raster fallback may be offered for a particular book but is not full reflow/accessibility parity.
- Independent reader settings remain per session/profile; paired audio and read-along reuse the existing sync/narration model.

Reader portability is a substantial package with content-corpus tests. Do not mark it complete with a placeholder page or a platform-wide `unsupported` return. Until qualification, the limitation must remain visible and the delivery ledger must stay open.

## Games and latency

The game engine must offer retained rendering and input independent of a full-screen Activity/ViewController. Prioritize native surfaces and avoid an extra encode/decode hop. A game stream and movie can share the workspace without sharing transport buffering rules. Test codec families, including beta codecs only when implemented, through the same surface contract.

If software decode or composition exceeds the game's latency budget, reduce the companion cost first. Never lower input sampling or accumulate game frames to preserve visualizer smoothness. An optional helper cannot be called seamless game support unless end-to-end latency is actually qualified.

## Optional helper extension

Reserve a `RemoteCompositionAdapter` interface; implement only after local paths and its own scope/qualification. Pair explicitly, use encrypted authenticated transport and per-session authorization, and send only the selected sources. Do not copy the entire credential vault to a helper or silently expose a LAN listener.

A helper may render permitted media streams into one output with metadata describing pane bounds and per-source timelines. The client still owns layout controls, focus and interactive reading. Layout changes require versioned requests/acknowledgements; audio ownership and source progress remain separately tracked. Network loss restores local checkpoints. This incurs latency, quality and deployment costs; UI must show an active helper and offer disconnect. It is not a universal answer for protected media or game input.

## Parity acceptance

Each current platform needs the same core actions, session/checkpoint rules, first-use help, and at least the qualified test combinations in VALIDATION.md. A source/OS-native limitation should trigger custom backend work, not an automatic product exclusion. Keep a per-platform outstanding list until parity scenarios pass.

Quality may scale with available resources; semantics must not. Outside-app floating windows remain an OS-specific extension. Maintain separate statuses for **app-owned PiP parity**, **simultaneous media combinations**, **native OS PiP**, **desktop pop-out**, and **HDR/audio fidelity** so one success cannot conceal another gap.
