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
| M3U, M3U8, PLS, and radio queues | Present | Local and HTTP(S) playlists are bounded, live streams are identified, HLS manifests remain adaptive, and network-relative entries resolve against their playlist. Local relative media entries now resolve inside the selected playlist folder. |
| Disc images and optical media | Present with limits | ISO and desktop DVD, Blu-ray, and audio-CD inputs depend on MPV, the build, drive, and OS permissions. Commercial protection is not bypassed; native TV players do not expose the desktop disc path. |
| Broad codecs and hardware decoding | Present with platform limits | PlezyNG uses its platform player and hardware-decoding paths. The supported codecs and acceleration depend on the backend and device; neither app can promise every codec on every platform. |
| Audio/subtitle selection, sidecars, search, and sync | Present | Track selection, device subtitles, subtitle search/download where the server supports it, and per-item sync controls are already in the player. |
| Speed, chapters, seek, zoom, and picture controls | Present | Playback speed, chapter navigation, seek, zoom, aspect/crop, picture adjustment, deinterlace, shaders, and 360° flat view use existing playback controls, gated by the player’s support. |
| Named playback bookmarks and segment looping | Added in this branch | The existing Chapters sheet saves marks for server media; Open media uses its current source-player controls and chapter area for one-off files and streams. MPV A/B looping sits in the existing chapter sheet or source-player playback-options menu. Bookmarks are device-local, accessible by keyboard, remote, touch, and screen reader, and do not alter server resume progress. |
| Ten-band equalizer | Added in this branch | The existing device-local MPV equalizer now has ten labelled frequency sliders, preserving the five original frequency settings. |
| Spatializer, stereo widener, and pitch effects | Added in this branch with limits | The existing equalizer pane adds room ambience, stereo widening, and pitch shift. These filters decode audio and disable passthrough. Stereo width depends on a compatible track; pitch needs the optional Rubber Band filter in that MPV build. Failed filters are reported and rolled back without stopping playback. |
| Loudness and compression | Present | Device-local normalization, limiter/compression behavior, downmix controls, and passthrough are already integrated with the player’s ordered audio-state handling. |
| Video effects, screenshots, and diagnostics | Present | Picture adjustments, shaders, screenshots, File Info, chapters, and the performance overlay are in the playback surface. They reuse existing sheets and overlays. |
| Music visualization | Present with limits | PlezyNG has a native, accessible, progress-aware visualizer using server-provided analysis when available. It does not claim a generic live-PCM/FFT visualizer for every input. |
| Local media conversion | Expanded in this branch | Desktop FFmpeg profiles cover H.264/AAC MP4/MKV, MP4/MKV stream-copy remux, AAC M4A, MP3, FLAC, PCM WAV, Ogg Opus, and VP9/Opus WebM. Profiles are disabled when the installed FFmpeg lacks their encoders or output containers. |
| Live network recording | Present with limits | Desktop MPV records supported live inputs to MKV/MPEG-TS or MKA. Stream and container compatibility remain source-dependent. |
| Screen and camera capture | Added in PR #42 | Desktop FFmpeg capture to H.264 MP4, optional audio input, local destination selection, overwrite confirmation, progress, safe publication, and OS permission cues. |
| Send a file to another device | Added in PR #42, bounded | Temporary HLS sharing over private IPv4 with random access token, QR/copy affordances, expiry, and cleanup. It is not a persistent relay or a general-purpose VLC stream-output wizard. |
| Search extensions | Added in PR #42, bounded | Profile-local declarative HTTPS JSON mappings feed results into the existing Open media form. No extension code, shell commands, arbitrary headers, or file access are allowed. |
| CLI and scripting | Added in PR #42, bounded | `tools/plezyctl` validates/searches the same data-only manifests and opens eligible results through the app URL handler. It is not an arbitrary playback-control or plugin API. |
| Wi-Fi transfer | Present | The existing Open media tools group supports local transfer while the app remains active. |
| Cast and external-player handoff | Present with limits | Google Cast and supported platform player handoffs exist; receiver, codec, and device support vary. |
| Offline playback and server libraries | Present in PlezyNG’s core workflow | Downloads, playlists, search, and source catalogs build on Plex/Jellyfin/Emby and personal file-source APIs rather than a separate VLC-style local library database. |

## Work completed in the comparison branch

PR #42 already adds desktop capture, temporary HLS sharing, data-only media search extensions, and the `plezyctl` CLI. This expanded pass closes additional gaps that the first matrix hid inside broad “present” rows: local playlist files can reference safe sibling media, the FFmpeg converter offers more useful formats and remux profiles, the MPV equalizer has ten bands, MPV adds common audio effects, and the existing Chapters sheet adds named local bookmarks and temporary A/B looping.

The additions stay in the current **Files and books → Open media → Media tools** and existing playback-settings/chapter sheets. They reuse PlezyNG’s source tiles, mono palette, focus handling, shared dialogs, player lifecycle, and semantic feedback. No new top-level navigation section or standalone settings window is added. See the [Open media and local media tools guide](UNIVERSAL_MEDIA.md) for operating details and exact platform behavior.

## Deliberate compatibility boundaries

This is a feature comparison, not a claim of binary parity. The following VLC capabilities are intentionally not recreated as if they worked everywhere:

- VLC’s arbitrary Lua extension runtime and downloadable interface skins are not adopted. Search extensions are declarative data, and PlezyNG keeps its existing interface system and visual style.
- General multicast announcements and discovery (SAP/SDP, Bonjour), legacy MMS/DCCP inputs, DVB tuner devices, ActiveX/browser plugins, and SVCD menu navigation do not have a dependable cross-platform MPV/server abstraction in PlezyNG. Live TV and network discovery continue through their existing platform or server integrations where available.
- VLC’s full stream-output matrix is reduced to temporary private-network HLS sharing. There is no public relay, persistent streaming server, account system, or arbitrary protocol-output graph.
- Protected-disc decryption, unsupported device capture, and guaranteed codec playback are not promised. Hardware, DRM, permissions, MPV filter compilation, server APIs, and native-player behavior remain authoritative.
- Bookmarks are stored locally on the device; they do not sync between installs or update server-side resume state.

The detailed implementation limits and UI help are documented alongside each feature so controls appear only where they can work and unsupported cases fail visibly and safely.
