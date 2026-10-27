# VLC feature comparison

This comparison focuses on the VLC capabilities that matter to a cross-server media client: opening and playing media, working with local inputs, changing playback, capture/recording, sending a stream to another device, and extending the player. VLC’s official overview describes broad local/network playback, conversion, recording, capture and streaming; its extension system and stream-output tooling are documented separately ([VLC features](https://images.videolan.org/vlc/features.html), [streaming features](https://images.videolan.org/streaming-features.html), [stream output](https://docs.videolan.me/vlc-user/desktop/3.0/en/advanced/stream_out_introduction.html), [extensions](https://docs.videolan.me/vlc-user/desktop/3.0/en/addons/extensions.html)).

PlezyNG has a different center of gravity: it is a Plex/Jellyfin/Emby and personal-file client with a shared account, library, playback and offline workflow. A feature is treated as present when the app already offers the user-facing capability on a supported backend. Platform and server differences remain visible rather than being represented by disabled controls.

## Capability matrix

| VLC capability area | PlezyNG status | Notes |
| --- | --- | --- |
| Local file playback and queues | Present | Open media supports temporary audio/video file queues. Files and URLs do not create library history. Codec and container support depend on the selected platform player. |
| Direct network streams | Present | HTTP(S), HLS/DASH-capable playback, and MPV-specific RTSP/RTMP/RTMPS/UDP/RTP inputs are available where the backend supports them. HTTP is explicit opt-in; sensitive addresses remain session-only. |
| Playlists and radio | Present | Local and remote M3U/M3U8/PLS input, relative URL resolution, HLS handling, entry bounds, and live-stream cues. |
| Optical media and images | Present with limits | ISO and desktop optical-disc inputs are available where the MPV build, drive, and OS support them. Protected-disc restrictions are not bypassed. |
| Playback controls and tracks | Present | Track/subtitle selection, offsets, speed, chapters, intro/credit skipping, zoom, sleep timer, audio controls and player-specific picture/effect controls are already part of PlezyNG. |
| Local conversion | Present with limits | Desktop FFmpeg conversion to MP4, M4A, and MP3. FFmpeg is user-installed; this does not remove DRM or download a remote stream. |
| Live-stream recording | Present with limits | Desktop MPV recording of supported live inputs. Containers and reliability depend on the source stream. |
| Screen and camera capture | Added in this branch | Desktop screen/camera recording to H.264 MP4, with optional audio input, local destination selection, overwrite confirmation, progress and safe publication. Requires compatible FFmpeg capture devices and OS permission. |
| Send a local file as a stream | Added in this branch | Temporary HLS output on private IPv4 interfaces, with a random bearer token, QR/copy affordances, expiry and stop cleanup. Requires desktop FFmpeg and a foreground app. It is not a persistent relay or arbitrary protocol-output wizard. |
| Media search extensions | Added in this branch | Profile-local declarative JSON manifests map one HTTPS JSON search endpoint into the existing Open media form. Query disclosure is shown before use. Manifests cannot execute code, issue custom headers, read files or launch commands. |
| CLI/plugin host | Added in this branch, bounded | `tools/plezyctl` validates and searches the same manifest format and can hand a safe result to PlezyNG’s existing Open media form. It does not expose a remote-control interface or execute third-party plugins. |
| Wi-Fi transfer | Present | Open media already groups local upload from another device, with request limits and a temporary private address. |
| Cast and external-player handoff | Present with limits | Google Cast and platform external-player paths already exist; receiver, codec and device support vary. |

## Gaps closed by this branch

The audit identified four missing capability groups: capture, outgoing stream sharing, extension-based media search, and a command-line entry point. Each now has a working implementation and lives under **Files and books → Open media → Media tools**. The screen uses the existing `SourceTile`, mono theme, focused scroll scaffold, shared dialogs, clipboard, icons, and input navigation. It adds no top-level navigation section.

Capture and HLS sharing are desktop-only because they require FFmpeg capture/output support and a local filesystem path. Extension search appears on non-TV builds. The CLI is a Python 3 script at `tools/plezyctl`; packaged Linux and Windows builds register the `plezy:` URL scheme used to open safe results. Existing Apple URL registration forwards these links to the app as well.

## Deliberate boundaries

This work closes the four audited gaps with capabilities that fit PlezyNG’s existing client and safety model. It does not promise binary feature parity with VLC:

- VLC’s arbitrary Lua extension runtime is not reproduced. Search extensions are data-only mappings with HTTPS-only requests, no redirects or custom headers, a 1 MiB response cap, and a 20-result cap.
- VLC’s general stream-output protocol matrix is not reproduced. PlezyNG shares a selected local file as temporary HLS over private IPv4, with no external relay, TLS endpoint, user accounts, or persistent server.
- `plezyctl` is not a player-control or scripting API. It only validates/searches extension manifests and opens eligible results in the existing app flow.
- Native protected-screen capture, Wayland portal capture, mobile capture, and TV capture are not claimed. Linux screen capture uses X11/XWayland only.
- VLC’s downloadable GUI skins are not an input/playback capability and are not part of PlezyNG’s feature-parity target; PlezyNG retains its own theme and shared interface patterns.

These boundaries are shown in the UI and in the [Open media guide](UNIVERSAL_MEDIA.md), so a result or control does not imply that a feature is supported by every device.
