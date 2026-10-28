# VLC feature comparison

This comparison expands the original four-row gap list into the capabilities people commonly mean when they call VLC a “killer app”: opening nearly any local or network source, managing playlists, inspecting and shaping playback, recording or converting media, sending media elsewhere, and extending the player. VLC’s own overview and desktop guide cover a much larger set of protocols, effects, menus, and device integrations than any cross-platform client can reproduce exactly ([VLC feature overview](https://images.videolan.org/vlc/features.html), [VLC desktop menu guide](https://docs.videolan.me/vlc-user/desktop/3.0/en/gettingstarted/desktopoverview/windows_and_linux/menu_bar.html)).

PlezyNG is centered on Plex, Jellyfin, Emby, and personal media sources. The comparison treats a capability as present when it is reachable in the existing product flow on a supported backend. It calls out where server APIs, operating systems, MPV builds, devices, or display paths change the result.

## Capability-by-capability status

| VLC capability | PlezyNG status | How it fits / limits |
| --- | --- | --- |
| Local audio and video files | Present | Open media creates a temporary queue through the normal player. It does not add files to a server library or playback history. |
| Network streams and adaptive playback | Present | HTTP(S), HLS, DASH-capable playback, and live cues use the existing Open media form and player. HTTP needs explicit consent; sensitive URLs remain session-only. |
| RTSP, RTMP, UDP, and RTP inputs | Present with limits | Direct MPV inputs are shown only on MPV builds. They are not proxied by the HTTP gateway and cannot be saved as favorites. |
| FTP and FTPS media | Present with limits | The authenticated file-source browser supports FTP/FTPS with credentials in the account vault. Direct FTP URLs are opt-in, MPV-only, unencrypted, and session-only; they cannot be saved as favorites. |
| M3U, M3U8, PLS, and radio queues | Present | Local and HTTP(S) playlists are bounded, live streams are identified, HLS manifests remain adaptive, and network-relative entries resolve against their playlist. Local relative media entries resolve inside the selected playlist folder. |
| Save and reopen a local file queue | Added in this follow-up | On desktop, the active player offers a quiet Save playlist action only for durable local files in one folder. It writes sibling-relative M3U entries beside the media, so the existing Open media playlist picker can reopen it safely. Temporary uploads, network URLs, mixed folders, and paths outside the selected folder are excluded. |
| Disc images and optical media | Present with limits | ISO and desktop DVD, Blu-ray, and audio-CD inputs depend on MPV, the build, drive, and OS permissions. Commercial protection is not bypassed; native TV players do not expose the desktop disc path. |
| Broad codecs and hardware decoding | Present with platform limits | PlezyNG uses its platform player and hardware-decoding paths. The supported codecs and acceleration depend on the backend and device; neither app can promise every codec on every platform. |
| Audio, video, and subtitle tracks | Present with limits | Audio/subtitle selection, device sidecars, subtitle search/download where supported, and sync controls are in the player. Multiple video tracks can be selected in the existing settings pane on MPV; the native TV/player adapters do not expose equivalent track IDs. |
| Audio output device and stereo downmix | Present with limits | Desktop MPV exposes available output devices and remembers the last available selection. Stereo downmix, a 5.1 channel cap, passthrough, and normalization use existing playback audio settings; actual output choices remain device/backend-dependent. |
| Speed, chapters, seek, zoom, and picture controls | Present | Playback speed, chapter navigation, seek, zoom, aspect/crop, picture adjustment, deinterlace, shaders, and 360° flat view use existing playback controls, gated by the player’s support. |
| Named playback bookmarks and segment looping | Added in this branch | The existing Chapters sheet saves marks for server media; Open media uses its current source-player controls and chapter area for one-off files and streams. MPV A/B looping sits in the existing chapter sheet or source-player playback-options menu. Bookmarks are device-local, accessible by keyboard, remote, touch, and screen reader, and do not alter server resume progress. |
| Ten-band equalizer | Added in this branch | The existing device-local MPV equalizer now has ten labelled frequency sliders, preserving the five original frequency settings. |
| Spatializer, stereo widener, and pitch effects | Added in this branch with limits | The existing equalizer pane adds room ambience, stereo widening, and pitch shift. These filters decode audio and disable passthrough. Stereo width depends on a compatible track; pitch needs the optional Rubber Band filter in that MPV build. Failed filters are reported and rolled back without stopping playback. |
| Loudness and compression | Present | Device-local normalization, limiter/compression behavior, downmix controls, and passthrough are already integrated with the player’s ordered audio-state handling. |
| Video effects, screenshots, and diagnostics | Present | Picture adjustments, shaders, screenshots, File Info, chapters, and the performance overlay are in the playback surface. They reuse existing sheets and overlays. |
| Media information | Expanded in this follow-up | Server playback keeps the existing File Info sheet. Direct MPV inputs now build the same sheet from the container, size, duration, codec, resolution, frame rate, and tracks MPV reports; unavailable properties are simply omitted, and credentials or full paths are not shown. |
| Music visualization | Present with limits | The existing accessible visualizer prefers Plex loudness profiles and can use MPV/FFmpeg's derived centroid and flatness metadata for live audio. Direct audio sources reuse the same scene and preset controls in place. Full PCM and per-bin FFT data remain unavailable; unsupported players and filters use the ambient scene. |
| Local media conversion | Expanded in this branch | Desktop FFmpeg profiles cover H.264/AAC MP4/MKV, MP4/MKV stream-copy remux, AAC M4A, MP3, FLAC, PCM WAV, Ogg Opus, and VP9/Opus WebM. Profiles are disabled when the installed FFmpeg lacks their encoders or output containers. |
| Live network recording | Present with limits | Desktop MPV records supported live inputs to MKV/MPEG-TS or MKA. Stream and container compatibility remain source-dependent. Recording seekable movie/file playback is not exposed because MPV writes demuxer input bytes, overwrites the target unless guarded, and warns that seeks or stream switches can break the recording. |
| Screen and camera capture | Added in PR #42 and expanded here | Desktop FFmpeg recording saves H.264 MP4 with optional audio. The existing Capture panel also previews a selected device in the normal player through MPV's avdevice input when that MPV build and OS permit it; preview is live, video-only, session-bound, and does not create a recording. |
| Send a file to another device | Added in PR #42, bounded | Temporary HLS sharing over private IPv4 with random access token, QR/copy affordances, expiry, and cleanup. It is not a persistent relay or a general-purpose VLC stream-output wizard. |
| Search extensions | Added in PR #42, bounded | Profile-local declarative HTTPS JSON mappings feed results into the existing Open media form. No extension code, shell commands, arbitrary headers, or file access are allowed. |
| CLI and scripting | Added in PR #42, bounded | `tools/plezyctl` validates/searches the same data-only manifests and opens eligible results through the app URL handler. It is not an arbitrary playback-control or plugin API. |
| Wi-Fi transfer | Present | The existing Open media tools group supports local transfer while the app remains active. |
| Cast and external-player handoff | Present with limits | Google Cast and supported platform player handoffs exist; receiver, codec, and device support vary. |
| Offline playback and server libraries | Present in PlezyNG’s core workflow | Downloads, playlists, search, and source catalogs build on Plex/Jellyfin/Emby and personal file-source APIs rather than a separate VLC-style local library database. |

## Full VLC menu-feature check

The official desktop guide groups VLC’s everyday capabilities under Media,
Playback, Audio, Video, Subtitle, Tools, View, and Help. This pass checked those
groups individually so features hidden inside a broad “playback controls” row
are accounted for:

| VLC menu group | PlezyNG coverage |
| --- | --- |
| Media | Open local files, network inputs, playlists, supported discs, and capture flows are available through Open media and Files and books. FFmpeg conversion and temporary private-LAN sharing are grouped in Media tools. |
| Playback | Seek, speed, chapters, repeat, bookmarks, A/B loops, subtitle/audio sync, and live recording use existing controls. MPV alternate video tracks and multi-edition/disc-title selection appear only when the input exposes choices. DVB program/tuner selection remains native/server-owned because PlezyNG does not expose a generic tuner input. |
| Audio | Track selection, remembered desktop MPV output device, stereo downmix, channel limits, volume, passthrough, normalization, EQ, and visualization use existing playback and music flows. On compatible MPV builds the visualizer consumes two throttled derived measurements; it does not transport PCM samples or FFT bins. |
| Video | Fullscreen, zoom, aspect/crop, picture adjustment, deinterlace, shader presets, screenshots, diagnostics, and optional 360° flat projection are present where the active player supports them. Desktop capture can save a file or preview a live device in the existing MPV player. |
| Subtitle | Track selection, local sidecars, server search/download where supported, styling, placement, and timing controls are present. |
| Tools | File Info, playback effects, audio/video synchronization, diagnostics, conversion, and capture reuse current sheets and tool groups. Third-party executable extensions are not loaded. |
| View | The app uses its existing adaptive layouts and media/library playlists. Local file queues can be saved as M3U; there is no separate VLC-style local media-library window or downloadable interface skin system. |
| Help | In-app contextual help, accessibility cues, setup guides, About, credits, and licenses use PlezyNG’s existing flows. Store-managed updates remain platform-owned instead of adding a second in-app updater. |

VLC also acts as a general-purpose capture, plugin, and stream-output framework.
Those capabilities do not imply identical behavior in PlezyNG: the available
capture devices, protocols, output codecs, server APIs, decoder properties,
and native-player controls differ by platform. The following boundaries are
intentional and documented below.

## Work completed in the comparison branch

PR #42 already adds desktop capture, temporary HLS sharing, data-only media search extensions, and the `plezyctl` CLI. PR #43 adds safe sibling media references in local playlists, additional FFmpeg output and remux profiles, MPV audio effects, named device-local bookmarks, and temporary A/B looping. This follow-up adds reusable local M3U export, MPV alternate video-track selection, direct-input File Info, MPV edition/disc-title selection, and a live capture preview action after checking the remaining VLC menu capabilities against PlezyNG’s supported player paths.

The additions stay in the current **Files and books → Open media → Media tools** and existing playback-settings/chapter sheets. They reuse PlezyNG’s source tiles, mono palette, focus handling, shared dialogs, player lifecycle, and semantic feedback. No new top-level navigation section or standalone settings window is added. See the [Open media and local media tools guide](UNIVERSAL_MEDIA.md) for operating details and exact platform behavior.

### Headless QA coverage

The regression checks exercise the source-player flow and narrow-screen navigation, including direct-input File Info privacy, edition refresh and selection, alternate video tracks, MPV audio effects, A/B loop actions, local playlist export boundaries, transient bookmark identity, and capture-preview argument validation. The Media tools screen check opens the capture, local sharing, and search-extension flows and verifies their phone layouts use the shared scrolling form, source tiles, palette, and accessible labels. A local FFmpeg integration test generates a short H.264/AAC sample, then checks that temporary sharing publishes an HLS media segment, rejects an invalid token and unsupported methods, and releases its listener when stopped. Encoder and network-interface prerequisites are detected and skipped explicitly. The new playback and capture strings are translated into the supported locale catalogs, with placeholder and source-catalog checks.

Run the source and focused playback checks with:

```sh
flutter test --no-pub test/sources
flutter test --no-pub test/media/media_playlist_test.dart
flutter test --no-pub test/mpv/player_native_bridge_test.dart
flutter test --no-pub test/widgets/video_settings_sheet_test.dart
flutter test --no-pub test/widgets/source_direct_player_features_test.dart
flutter test --no-pub test/services/video_bookmark_service_test.dart
python3 -m unittest test/tools/plezyctl_test.py
python3 scripts/checks/clean_translations.py --check --strict
python3 scripts/checks/check_localizations.py
flutter analyze --no-pub
```

For a desktop conversion smoke check, generate a small video/audio file and
run one profile from `LocalMediaConverterScreen` with the installed FFmpeg.
The output should be inspected with `ffprobe` to confirm its container and
audio/video streams. Encoder availability varies by FFmpeg build, matching the
screen's profile availability cues.

## Deliberate compatibility boundaries

This is a feature comparison, not a claim of binary parity. The following VLC capabilities are intentionally not recreated as if they worked everywhere:

- VLC’s arbitrary Lua extension runtime and downloadable interface skins are not adopted. Search extensions are declarative data, and PlezyNG keeps its existing interface system and visual style.
- VLC’s plugin manager, arbitrary scripts, wallpaper mode, and multiple desktop interfaces are not reproduced. They require desktop-specific windowing or executable third-party code, and conflict with PlezyNG’s shared UI, permission, and extension contracts.
- General multicast announcements and discovery (SAP/SDP, Bonjour), legacy MMS/DCCP inputs, DVB tuner devices, ActiveX/browser plugins, and SVCD menu navigation do not have a dependable cross-platform MPV/server abstraction in PlezyNG. Live TV and network discovery continue through their existing platform or server integrations where available.
- VLC’s full stream-output matrix is reduced to temporary private-network HLS sharing. There is no public relay, persistent streaming server, account system, or arbitrary protocol-output graph.
- Protected-disc decryption, unsupported device capture, and guaranteed codec playback are not promised. Hardware, DRM, permissions, MPV filter compilation, server APIs, and native-player behavior remain authoritative.
- MPV's `stream-record` writes demuxer bytes rather than a normalized capture of the rendered playback. The [MPV manual](https://mpv.io/manual/stable/#options-stream-record) warns that seeks and stream changes can break the output, so PlezyNG exposes recording only for supported live inputs. A seekable-file recording flow would need a separate verified capture path.
- Live audio visualization uses MPV's optional FFmpeg `aspectralstats` metadata for centroid and flatness while the existing visualizer is visible. The small metadata feed is throttled, never contains PCM or per-bin FFT data, and is removed when the visualizer closes. Audio passthrough suspends the filter; Plex loudness remains preferred when available, and unsupported builds fall back to ambient motion. This is a visual response to derived metrics, not a waveform or full-spectrum display.
- Desktop camera/display preview is available only through discovered devices in the existing Capture panel and MPV's `av://` device input. MPV must include the matching FFmpeg device backend and the OS must grant access; preview currently carries video only. Native mobile/TV players do not expose an equivalent capture path.
- Bookmarks are stored locally on the device; they do not sync between installs or update server-side resume state.

The detailed implementation limits and UI help are documented alongside each feature so controls appear only where they can work and unsupported cases fail visibly and safely.
