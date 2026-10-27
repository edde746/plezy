# Open media and local media tools

PlezyNG’s **Files and books → Open media** screen is a session-oriented entry point for media that is not already in a Plex, Jellyfin, Emby, or file-source library. It reuses the app’s normal player, playback coordinator, track controls, and profile lifecycle. The entry stays out of source catalogs and playback history unless the user explicitly saves an eligible stream favorite.

Open media is a single entry in the existing Files and books area. Local conversion, Wi-Fi transfer, capture/share, search extensions, and CLI help stay grouped in the same flow instead of adding top-level navigation entries.

## Open and play

### Stream address

Paste a direct `https://` address and choose **Play now**. PlezyNG accepts HLS/DASH-capable HTTP(S) streams the selected player can decode. A credential-free `http://` address can be enabled deliberately; HTTPS remains the default. URLs containing user information in the authority are rejected. Query signatures and tokens may be used for the current playback, but recognized credential/signature parameters cannot be saved in favorites. Direct URLs are never written to playback history or source records. The default player title uses the host rather than a potentially sensitive path; supply a display name if you prefer a friendly title.

HTTP(S) requests run through a short-lived, loopback-only stream gateway owned by the playback session. The native player receives a localhost capability instead of the remote URL. Redirects retain the source transport’s HTTPS downgrade and cross-origin header protections. HLS manifests and HTTP(S) child playlists are rewritten through the same gateway so relative variants, segments, and HTTP(S) key URLs keep working without exposing the original address to the native player. An HTTPS manifest cannot downgrade a child request to HTTP. Remote manifests cannot direct the native player to local files or another network protocol; platform `skd:` DRM URIs are left to the native player. DRM is not bypassed. Stopping playback or switching profile closes the gateway and retires its in-memory URLs.

The player title uses the address host unless a display name is supplied. A “live” switch hides the seek bar, skip, and go-to-time controls and disables seek actions in system media controls. Turn it off for a seekable recording. An explicit live/session cue explains what is and is not saved.

RTSP, RTMP, RTMPS, UDP, and RTP are advanced inputs shown only when the current device uses an MPV backend. These protocols are passed directly to MPV because the HTTP gateway cannot proxy them. They are session-only and cannot be saved as favorites. Build options and protocol support vary by platform.

### Playlists and radio

Choose a local `.m3u`, `.m3u8`, or `.pls` file, or enter an HTTP(S) playlist address. Entries are bounded to 1,000 and 2 MiB total; overlong or unsupported entries are skipped with a count cue. Relative entries in remote playlists resolve against the playlist address. HLS manifests are played as adaptive streams rather than expanded into fixed segment queues. Negative M3U/PLS lengths are treated as live. HLS media playlists without `#EXT-X-ENDLIST` are treated as live unless marked `#EXT-X-PLAYLIST-TYPE:VOD`. Master playlists do not say whether their variants are live or on demand, so PlezyNG leaves their seeking behavior to the player.

Playlist directives are not interpreted as player options. Local playlist paths are not followed, except when an HLS `.m3u8` file is opened directly by the player. Save a direct credential-free HTTP(S) station as a favorite from the Stream address form. Favorites are profile-local, capped at 100, and reject user info and credential/signature query keys. They are opt-in; opening a URL or playlist never saves it automatically.

### Device files and disc images

Choose audio or video files for a temporary queue, or select an ISO image where the platform’s player supports it. The file picker gives PlezyNG the selected file access; transient selections do not create a catalog item, bookmark, or progress record. Local files normally open by file URI. If the platform returns a read stream without a usable file path, PlezyNG makes a temporary copy and removes it when playback ends.

Local `.m3u`/`.pls` entries that name sibling files are currently skipped; use a direct local file selection, or an HLS `.m3u8` file instead. Playlist file paths are deliberately not treated as permission to open arbitrary filesystem paths.

The desktop MPV menu can also request a DVD, Blu-ray, or audio CD from the computer’s optical drive. This depends on the MPV build, device path, drive, and operating-system permissions. It does not bypass commercial disc protection. Opening an ISO from Device files is the portable alternative when supported by the local player.

## Picture and recording tools

The player’s picture-adjustment sheet appears only for MPV video playback. Brightness, contrast, gamma, hue, and saturation sliders are named for screen readers and show their current values. **Reset picture** restores the defaults. A separate 360° flat-view control is offered for equirectangular footage when MPV’s FFmpeg `v360` filter exists; yaw, pitch, and field-of-view controls update the labelled filter. Filter support depends on the MPV/FFmpeg build, and the UI reports if it cannot apply the filter. These changes apply only to the current playback.

Desktop MPV live streams can be recorded to MKV or MPEG-TS video, or MKA/MKV audio. PlezyNG writes to a unique temporary file in the destination directory, then finalizes it when recording stops or playback exits. If a destination already exists, the user confirms replacement; PlezyNG keeps a backup until finalization succeeds and restores it after a failure. Recording is not available on native TV players, Android ExoPlayer, or non-desktop builds. Container compatibility depends on the source stream. A stream that pauses or drops will produce corresponding gaps. Changing to another playlist item finalizes the current recording; the live input remains non-seekable. MPV documents stream recording as best-effort and warns that stream changes or seeks can stop or break the output ([MPV manual](https://mpv.io/manual/stable/#options-stream-record)); PlezyNG disables seeking for live sessions.

## Local conversion

Desktop users can convert a local audio/video file to MP4 (H.264/AAC), M4A (AAC), or MP3 (LAME). The screen uses `ffprobe` when available for duration feedback and runs `ffmpeg` with argument-list process invocation, not a shell. The output is written beside the destination as a temporary file and published only after a successful conversion. Replacing an existing destination requires an explicit confirmation and keeps a recoverable backup until the new file is in place.

Install FFmpeg on the computer and make `ffmpeg` available on `PATH`; include the H.264/AAC/MP3 encoders shown in the format labels. PlezyNG does not bundle FFmpeg, download remote media for conversion, remove DRM, or transcode a protected source. Conversion works on files the user can already open locally.

## Capture a screen or camera

Open **Media tools → Capture** from the existing Open media screen on desktop. Select a display or camera, choose 15, 30, or 60 fps, and optionally select an audio input. PlezyNG records H.264 MP4 locally through a user-installed `ffmpeg`; it never uploads the recording. A partial file is written beside the chosen destination and only replaces the destination after FFmpeg finishes successfully. Replacing an existing file requires confirmation, and the old file is restored if publication fails.

Capture is available on Windows, macOS, and Linux desktop builds when FFmpeg includes the platform capture device and `libx264`. Camera and microphone availability depends on operating-system permissions and the FFmpeg build. Linux uses X11 capture; in a Wayland session this sees only the XWayland display and does not capture native Wayland windows or portals. PlezyNG does not provide native TV, Android, or iOS capture.

## Share a local file on the private network

Open **Media tools → Share**, choose a local audio or video file, then start sharing. PlezyNG uses a temporary HLS stream transcoded by user-installed FFmpeg and shows a QR code plus copyable addresses for private IPv4 interfaces. The temporary bearer address uses a random 256-bit token, accepts only GET/HEAD requests from private IPv4 peers with an expected host header, expires after 60 minutes, and is invalidated immediately when sharing stops, the app backgrounds, or the profile changes. Temporary segments are removed after the encoder stops.

This share uses unencrypted HTTP and is intended for a trusted local network. Anyone who obtains the active address can watch the selected file; it is not an authenticated account share. A PlezyNG receiver must explicitly allow HTTP for that session. This is file-to-HLS sharing, not a general-purpose RTSP/RTMP/UDP output server, a remote relay, or a persistent server. The app must remain in the foreground.

## Search extensions and command line

**Media tools → Extensions and CLI** accepts a JSON search manifest. The schema has one credential-free HTTPS endpoint, one query parameter, and a short path to the JSON results array. It maps title, URL, and optional subtitle fields into up to 20 results. The user sees the service host and confirms the manifest before it is saved. Every search explains that the query is sent to that service. Results are loaded into the existing Open media form; playback still requires the user to select **Play now**.

The schema accepts only `schema_version` (currently `1`), `id`, `name`, optional `description`, `endpoint`, `query_parameter`, `results_path`, `title_field`, `url_field`, and optional `subtitle_field`. Field names use letters, digits, `_`, or `-`; `results_path` contains one to four object keys. Unknown keys are rejected. The [example manifest](../examples/extensions/search.example.json) uses the reserved `.invalid` host and must be replaced with a trusted service before use.

Extensions are data-only: the manifest cannot execute code, add request headers, access files, follow redirects, invoke a shell, or define arbitrary actions. Responses are limited to 1 MiB, searches to 200 characters, and results to 20. Only safe HTTPS media URLs are returned. Extension definitions are saved in the current profile and can be removed there.

The companion `tools/plezyctl` command (Python 3.10+) validates the same manifest format, searches with the same HTTPS/response bounds, and can open a selected credential-free result in PlezyNG. Review the endpoint before every search; in noninteractive use, `--yes` confirms that the endpoint receives the search text. Signed result URLs cannot be sent through app links, because operating systems may retain them; paste those into Open media for the current session.

```sh
python3 tools/plezyctl validate --manifest examples/extensions/search.example.json
python3 tools/plezyctl search --manifest examples/extensions/search.example.json "search terms"
python3 tools/plezyctl search --manifest examples/extensions/search.example.json "search terms" --yes --open --result 1
```

The example manifest uses the reserved `.invalid` domain and is a schema example only. Replace its endpoint with a service you trust before searching.

## Transfer files over Wi-Fi

Desktop and handheld Android builds can start a temporary local upload page from Open media. A random 256-bit bearer path is bound to a local IPv4 listener, the host header and private client address are checked, and uploads require a same-origin request. The URL expires after 15 minutes; stopping the transfer, leaving the screen, backgrounding the app, or switching profile retires it. The sender’s browser presents a labelled file input, upload button, and polite live status announcement.

The receiver accepts supported audio, video, ebook, and comic formats, up to 4 GiB per file, 10 GiB total, and 100 files per session. The receiver streams into a temporary directory and imports the completed file into the active profile’s local Files and books library. Temporary upload copies are removed after import or on shutdown. Anyone who obtains the address while it is active can upload, so share it only on a trusted network and stop the session when finished. The transfer does not expose a general file browser or download endpoint.

## Accessibility and help

- Forms have visible labels and short explanatory text; URL input is left-to-right, with autocomplete disabled.
- Screen-reader labels include slider names and values, button tooltips, file counts, and a live-session cue.
- Live streams remove seeking affordances instead of leaving controls that cannot work.
- Transfer and conversion progress use live announcements; transfer errors remain visible in both the app and browser.
- Capture, share, and extension status messages use polite live regions. The share QR code has a screen-reader label, a scan instruction, visible copyable URLs, and a date/time expiry cue.
- Sliders, buttons, choices, and sheets use PlezyNG’s existing focus, keyboard, D-pad, and adaptive-sheet patterns.
- Sensitive actions explain the scope next to the control: HTTP is opt-in, favorites are explicitly saved, recording overwrite is confirmed, and both transfer/share links expire.

The new interface strings use the repository’s documented machine-translation draft workflow. Native-speaker review remains necessary, especially for accessibility announcements and security guidance; no native-review claim is made for this feature.

## Platform matrix

| Capability | Availability |
| --- | --- |
| Direct HTTP(S) and HTTP playlists | All builds with source playback and a working native media player; codec and container support still depends on that player. |
| RTSP/RTMP/RTMPS/UDP/RTP | MPV builds only; not webOS/Tizen native TV or Android ExoPlayer. |
| Local files, temporary queues, ISO images | File-picker platforms; ISO playback depends on the native player. |
| Picture adjustments and 360° flat view | MPV video only; 360° also requires the v360 filter. |
| Stream recording | Desktop MPV live sessions only. |
| Optical discs | Desktop MPV only; build and OS drive support required. |
| FFmpeg local conversion | Desktop only, with a compatible user-installed FFmpeg on `PATH`. |
| Wi-Fi file transfer | Desktop and handheld Android, while the app stays active in the foreground. |
| Screen/camera recording | Windows, macOS, and Linux desktop with the matching FFmpeg capture device; Linux Wayland is XWayland-limited. |
| Private-network HLS sharing | Windows, macOS, and Linux desktop with FFmpeg, a local file, and a private IPv4 address; foreground only, 60-minute maximum. |
| Search extensions | Non-TV builds; HTTPS JSON endpoint only, profile-local, with bounded responses and no executable code. |
| `plezyctl` | Python 3.10+ on desktop; opening results depends on the installed PlezyNG URL handler. |

## Scope boundaries

This guide covers the full VLC comparison gaps selected for this client: desktop screen/camera capture, outgoing local-network streaming, search extensions, and a CLI entry point. It complements capabilities already present in PlezyNG such as direct media inputs, playlists, local files, optical-disc inputs on supported desktops, conversion, live-stream recording, MPV picture/effect/audio controls, subtitle tools, Google Cast handoff, and external-player launch. See the [comparison matrix](VLC_FEATURE_PARITY.md) for the feature-by-feature status and remaining platform limits.

The additions intentionally fit the existing Open media pane and use the app’s standard player and navigation. They do not claim full VLC parity: the stream-out path is bounded HLS file sharing; extensions are declarative search mappings rather than executable Lua modules; and `plezyctl` handles those manifests rather than controlling arbitrary playback sessions.

New localized strings belong in `lib/i18n/en.i18n.json`; run the repository’s localization and Slang generation workflow after editing the catalog. Platform checks and FFmpeg/disc requirements should remain explicit in future UI and release notes.
