<h1>
  <img src="assets/plezy.png" alt="PlezyNG Logo" height="24" style="vertical-align: middle;" />
  PlezyNG
</h1>

A cross-platform media client for Plex, Jellyfin, and Emby, maintained as a fork of [Plezy](https://github.com/edde746/plezy).

PlezyNG is a downstream fork for feature requests that Plezy upstream has declined, left open, or not yet shipped. The table below maps those upstream gaps to the corresponding downstream implementation. If upstream provides equivalent behavior with comparable Plex, Jellyfin, and Emby coverage, PlezyNG can retire the duplicate implementation and converge on upstream. Until then, the fork maintains and validates the capabilities listed here.

See [Files, books and listening](docs/FILES_AND_BOOKS.md) for standard/cloud sources, readers and offline behavior, and [Public-library setup](docs/LENDING_SETUP.md) for the staged OverDrive integration.

## Dolby Vision experiments

PlezyNG has developed genuine Profile 7 FEL reconstruction alongside native and
compatibility playback. The isolated Linux engine has rendered the FEL mark in a
real P7 sample through standalone mpv and embedded libmpv; full app playback and
independent reference-pixel accuracy still need qualification. Linux users can
opt in under **Settings → Playback**, with a separate compatibility fallback and
video experiment logging switch. A separate engine build is required.

An experimental Android AAR now passes a synthetic FEL-on versus explicit
EL-dropped pixel comparison through mpv's real `gpu-next` Surface output on an
API 36 x86_64 emulator.

The repository also includes a pinned Apple dual-layer experiment host for
macOS/iOS/tvOS, an offline FEL-to-HDR/SDR companion pipeline, and platform testing
instructions. These are experimental paths, not a claim of universal or certified
Dolby Vision support. P7→P8.1 compatibility discards EL and is labelled separately.
Cross-platform playback and native Dolby Vision output are qualified separately;
native Dolby Vision signaling depends on the platform and connected display path.
See the [buildout, setup and Luna handoff](docs/maintainers/dv-platform-buildout.md)
and [Linux engine evidence](docs/maintainers/dv-engine-luna-handoff.md).

## What PlezyNG has built

PlezyNG builds on upstream Plezy with a broad set of features for Plex, Jellyfin, and Emby, wherever each server's APIs allow. The table below highlights what's been delivered, links related upstream work for context, and notes platform or server limitations.

| Area | Related upstream work | PlezyNG status |
| --- | --- | --- |
| Downloads | Converted download quality; per-rule quality; auto-download Continue Watching items and remove them when they leave the shelf (#1145, #1413, #1847, #1978, #2181, #2206) | Implemented for Plex, Jellyfin, and Emby |
| Downloads | Local Plex connections (#1447/#2248); download size and storage usage (#2376); manual sync and random episode selection (#1197, #1199) | Implemented in PlezyNG |
| Downloads | Playlist downloads and watched-item cleanup (#1721, #2600, #1413, #2181); orphan cleanup | Playlist downloads and watched-item cleanup are implemented. The Downloads screen can review and remove orphaned tagged files in the default app-managed folders; custom/SAF roots, legacy files, shared artwork, and iOS Documents are left untouched. |
| Profiles and privacy | PIN-gate download deletion, settings, and Explore; hide Explore per profile (#1924, #2514) | Local profile PIN gates Settings, download deletion, and entry to Explore; Explore can also be hidden per profile. Plex Home PINs remain server-owned. |
| Audio and subtitles | Remember choices per show; choose tracks before playback; always-on subtitles and preferred-language fetching; per-item sync offsets (#84, #1758, #1956, #2116, #2182, #2346, #2382, #2792) | Per-show memory, optional pre-play selection, device-local preferred-language selection and opt-in provider downloads, and scoped sync offsets are implemented across Plex, Jellyfin, and Emby; explicit server-selected tracks, account Off, and local picks remain authoritative |
| Files and books | Standalone file sources, metadata, subtitles, ebooks and audiobooks | SMB2/3, optional encrypted NFSv3 RPC-with-TLS, FTP-family, SFTP, DLNA, Komga, WebDAV, S3, OPDS, cloud drives and Audiobookshelf; local Kodi/Jellyfin NFO/posters, confidence-gated Trakt metadata/cast/artwork/trailers, and OpenSubtitles search (including SMB); EPUB/PDF/CBZ, multipart audiobook playback and progress sync. Availability varies by platform; see the [setup guide](docs/FILES_AND_BOOKS.md) for limits and security. |
| Universal media tools | Direct media URLs, radio playlists, local files, Wi-Fi transfer, conversion, recording and picture controls | The new **Open media** flow opens session-only HTTP(S)/MPV streams, M3U/PLS/HLS playlists, file queues and supported ISO/disc inputs; safe favorites are profile-local. Desktop/Android Wi-Fi transfer, desktop FFmpeg conversion, desktop MPV stream recording, and MPV picture/360° adjustments are capability-gated. See the [Open media guide](docs/UNIVERSAL_MEDIA.md) for privacy and platform limits. |
| Subtitle controls | Live styling preview (#2347); in-player size and position controls (#95, #689, #2174); load a local subtitle file (#1431) | Live preview, in-player size/position, and local subtitle loading are implemented; other style controls remain in Settings |
| Playback | Swipe-to-seek (#2601), frame stepping (#1584), subtitle-delay hotkeys (#2824), remembered version across episodes (#2563), video playlist repeat (#1757/#1985) | Implemented in PlezyNG |
| Playback | Plex cinema pre-rolls (#970/#2483); random local pre-rolls (#2271); theme music (#791/#2170/#2596) | Configured cinema intros work on Plex, Jellyfin, and Emby; local pre-rolls, detail-page theme songs, and home spotlight music are implemented |
| Playback | Background video/audio-only mode (#367), mpv equalizer (#2292), local/remote quality presets (#2064), opt-in TheIntroDB fallback (#389, #1110, #1886) | Optional audio-only background playback is implemented on handheld Android and iOS; Android uses the OS media playback service. A five-band device-local equalizer is available in mpv, and opt-in intro fallback is implemented. |
| Browsing | Director links (#2762), library item counts (#1516), Watchlist filters (#2725), MDBList Explore lists (#2740), Seerr search results (#2811) | Implemented in PlezyNG |
| Browsing | Search by actor or director (#1517, #2368); random movie or library shuffle (#1561, #2741, #2757); show end time on detail pages (#2671) | People search, random movie selection, and shuffled playback of movie and TV libraries are implemented across connected servers; detail-page finish time is shown on media details |
| Home screen | Configurable rows, merged library and collection rows, organizer controls, and Plex account layout sync (#1652/#2203) | Implemented; Plex account sync applies to Plex profiles. Custom rows can combine selected libraries across connected servers |
| Home screen | Separate Next Up; hide empty libraries or backdrop art; Continue Watching row sizing (#2498, #2690, #2701, #2723, #2784) | Continue Watching and Next Up now have separate Home rows and independent visibility/order; empty-library filtering, backdrop visibility, and row sizing are implemented. The legacy hero banner visibility setting and TV clock already exist. |
| Servers and links | Preferred server (#591, #1529, #2720); `plezy://watch` links (#2681); return from external players with synced progress (#2738) | Preferred server is stored per profile and moves first in aggregate queries across Plex, Jellyfin, and Emby; watch links and external-player return sync are implemented |
| Live TV | Timeshift timeline (#2300) | Plex implementation is in the fork; Jellyfin/Emby DVR-window support remains under investigation because their public playback APIs do not expose the tuner's seekable capture window |
| Integrations | Google Cast (#126); new-episode notifications (#1146); content screensaver (#401) | Google Cast handoff is implemented on Android and iOS through the default media receiver, subject to receiver codec/container support and server reachability. Profile-scoped episode alerts poll connected Plex, Jellyfin, and Emby libraries while the app is foregrounded on Android/iOS; the screensaver rotates artwork from selected connected libraries after an idle timeout. |
| Automation | Home Assistant control and Android automation intents (#823, #1996) | Android `ACTION_VIEW` links can open cross-server `plezy://watch` media, select an existing profile with `plezy://profile?id=…`, and control the active video session with `plezy://control?command=play|pause|toggle|stop`. Home Assistant can invoke these through an Android intent bridge; this does not expose Plezy as a native Plex Companion player in Home Assistant. See the [Android automation guide](docs/plezyng/android-automation.md). |
| Settings and diagnostics | Save logs to a file (#2496); cloud settings backup (#1795) | Log export is implemented; cloud settings backup uploads and restores the portable settings export through an HTTPS WebDAV file endpoint |

This table is a snapshot of downstream work and its current limits. The linked upstream requests provide context for the gap PlezyNG addresses; equivalent upstream implementations can replace the corresponding downstream code when their behavior and server coverage match.

<p>
  <a href="https://github.com/edde746/plezy">Upstream Plezy</a> ·
  <a href="https://github.com/snapetech-org/PlezyNG/issues">PlezyNG issues</a> ·
  <a href="#download">Download</a> ·
  <a href="CONTRIBUTING.md">Contributing</a> ·
  <a href="LICENSE">License</a>
</p>

<p align="center">
  <img src="assets/readme-showcase.webp" alt="Plezy mobile screenshots" width="900" />
</p>

## Download

Published PlezyNG downloads appear on the [GitHub Releases page](https://github.com/snapetech-org/PlezyNG/releases). The 2.24.1 build is currently a draft, so there is no public “latest” download yet. Mobile and TV packages are listed when a release is published.

| Platform | Download |
| --- | --- |
| Desktop and mobile | Download links are added after the corresponding release is published. |
| webOS TV | Experimental ARMv7 IPK; one LG C6 running webOS 26 has been tested. LG's native Flutter floor is webOS 26 Re:New+, and older firmware or other models are not qualified. No webOS package is published yet; see the [compatibility matrix and port status](docs/maintainers/webos-tv.md) |
| Samsung Tizen TV | Experimental ARM TPK builds for Tizen 6–9, with a prebuilt tester handoff/re-signing path. TV qualification and the 2026/Tizen 10 target remain pending. See the [research, build guide and rollout plan](docs/maintainers/tizen-tv.md). |

<details>
<summary>Install with a package manager</summary>

### macOS — Homebrew

The `snapetech-plezyng` Cask is being prepared. It will be installable after a signed and notarized macOS release is published and the generated Cask is added to this repository.

```bash
# After the Cask is published in this tap
brew tap snapetech-org/PlezyNG https://github.com/snapetech-org/PlezyNG
brew install --cask snapetech-plezyng
```

### Linux — Flatpak

Install Flatpak with your distribution's package manager, download the bundle for your architecture above, then run:

```bash
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.freedesktop.Platform//25.08
flatpak install --user ./plezy-linux-x64.flatpak
flatpak run com.edde746.plezy
```

On arm64, install `plezy-linux-arm64.flatpak`.

<details>
<summary>Sandbox, playback, and folder access</summary>

- Not on Flathub — the remote supplies the Freedesktop runtime only.
- Video playback needs a Wayland session; a pure X11 session shows the interface but cannot create the video plane.
- No host or home filesystem access; app data lives in `~/.var/app/com.edde746.plezy/`. Add host folders through the desktop file chooser portal, and keep download folders writable.
- Network, display, audio, and device access are enabled. `--device=all` (Flatpak 1.14 compatibility) exposes more than GPUs and controllers; session-bus access stays filtered.

</details>

### Arch Linux — Pacman

[Distribution package](https://archlinux.org/packages/extra/x86_64/plezy/).

```bash
sudo pacman -S plezy
```

### Fedora / Red Hat — DNF

[Installation instructions](https://github.com/aldobarr/plezy-rpm) · Community repository by [@aldobarr](https://github.com/aldobarr).

### Nix

[Community package](https://search.nixos.org/packages?channel=unstable&query=plezy) maintained by [@mio-19](https://github.com/mio-19) and [@MiniHarinn](https://github.com/MiniHarinn).

### aerynOS — Moss

[Distribution package](https://github.com/aerynOS/recipes/tree/main/p/plezy).

```bash
sudo moss it plezy
```

</details>

## Android closed beta

PlezyNG's Google Play closed test is being prepared. Once the test release is published, invited testers can opt in at [the PlezyNG Google Play test page](https://play.google.com/apps/testing/org.snapetech.plezyng). The link is inactive until then, and only accounts added to the test can join. Google Play requires at least 12 testers to stay opted in continuously for 14 days before production access.

## Features

### <img src="assets/readme_icons/browse.svg" height="20" alt="" align="center" /> Browse & Discover
- Libraries, collections, and playlists — video and audio
- Discover hub — Continue Watching, Next Up, trending, and recommendations
- Configurable Home rows: merge Recently Added / Recently Released across whichever libraries you pick, or a collections row scoped to specific libraries or collections
- Hide Home backdrop artwork and choose compact, standard, or large Continue Watching cards
- Cross-server search across connected Plex, Jellyfin, and Emby libraries, including actors and directors
- Filtering, sorting, and alphabetical jump navigation
- Folder browsing and folder playback — home-video libraries open in folder view
- Resolution, HDR/Dolby Vision, and audio-format badges on cards and detail pages
- Favorites and unwatched library filters[^mb]
- Extras — trailers, deleted scenes, behind-the-scenes

### <img src="assets/readme_icons/explore.svg" height="20" alt="" align="center" /> Explore & Requests
- Explore tab — watchlist, trending, popular, and recommendation rows from Plex Discover[^plex], Trakt, MyAnimeList, AniList, Simkl, and Seerr[^connect]
- Search any connected catalog source
- Catalog titles matched back to your own libraries by external ID
- Seerr — request movies and shows with per-season, 4K, and advanced destination options, and see request status inline
- Watchlist sync — add and remove titles on Plex, Trakt, MyAnimeList, AniList, and Simkl from anywhere in the app

### <img src="assets/readme_icons/playback.svg" height="20" alt="" align="center" /> Playback
- Wide codec support (HEVC, AV1, VP9, and more)
- HDR and Dolby Vision[^hdr]
- Direct play, or transcode presets from 240p/320 kbps to 1080p/20 Mbps
- Multi-version switching with per-version file details
- Full ASS/SSA subtitles with customizable styling
- Optional TheIntroDB intro timings when Plex, Jellyfin, or Emby has no intro marker; disabled by default
- Online subtitle search & download[^plex]
- Audio and subtitle track selection with server-provided defaults
- Progress sync and resume
- Auto-play next episode with skip intro / skip credits
- Optional audio-only continuation when the app backgrounds on Android and iOS
- Chapter navigation with thumbnail scrub previews
- Playback speed from 0.25x to 8x, audio sync offset, sleep timer (fixed durations or end of video)
- Video zoom 50-200% with pinch, presets, and hotkeys
- Audio passthrough[^pass], output channel limit (5.1 or stereo, with center-channel boost), and loudness normalization
- Five-band device-local audio equalizer for mpv playback
- File Info sheet — every version, file, and stream the server reports
- Ambient lighting and GLSL shader presets[^mpv]
- Picture-in-Picture[^pip]
- Refresh-rate matching[^rrm]
- External player launch (VLC, MX Player, etc.) with progress sync back[^android]
- **Open media** — session-only HTTP(S) streams, HLS and M3U/PLS playlists, profile-local safe favorites, and temporary local file queues
- Advanced RTSP/RTMP/RTMPS/UDP/RTP inputs, optical-disc/ISO playback, and Wi-Fi file transfer on supported builds
- MPV picture adjustments and optional 360° flat view; desktop MPV live-stream recording
- Desktop local conversion to MP4 (H.264/AAC), M4A, or MP3 with user-installed FFmpeg
- Direct HTTP(S) playback uses a session-owned loopback gateway; recognized credential/signature parameters cannot be saved. Platform boundaries and transfer limits are in the [Open media guide](docs/UNIVERSAL_MEDIA.md).

### <img src="assets/readme_icons/music.svg" height="20" alt="" align="center" /> Music
- Music libraries — artist, album, and track browsing with square artwork
- Album and artist screens with play, shuffle, and Instant Mix
- Gapless playback with a full play queue — reorder, remove, play next, add to queue
- Now Playing with synced lyrics[^lyrics], persistent mini-player, and sleep timer
- Background playback with lock-screen, media-key, and notification controls[^bgaudio]
- Offline playback of downloaded albums and tracks
- Streaming quality presets — Original, 320, 192, or 128 kbps

### <img src="assets/readme_icons/live-tv.svg" height="20" alt="" align="center" /> Live TV & DVR
- Live TV channel browsing, tuning, and favorites
- EPG guide with What's On and per-show schedules
- DVR recording rules, scheduled recordings, and a rememberable recording target library[^plex]
- Multi-server Live TV support where available

### <img src="assets/readme_icons/downloads.svg" height="20" alt="" align="center" /> Downloads & Offline
- Download movies, shows, and music for offline playback[^dl]
- Background queue with pause / resume
- Sync rules for automatic downloads, with per-show "Include Specials"
- Per-rule download quality, plus automatic Continue Watching downloads with cleanup when an item leaves the shelf
- Converted video downloads for Plex, Jellyfin, and Emby; progressive server transcodes may restart after an interrupted transfer
- Optional download-quality prompt per item, quality per sync rule, and Continue Watching download rules with shelf cleanup
- Offline browsing with watch state sync-back on reconnect
- Local profile PIN gates for Settings and download deletion; per-profile Explore visibility
- Random movie picker, end-time estimate on detail pages, hide-empty-library preference, and diagnostic log export

### <img src="assets/readme_icons/watch-together.svg" height="20" alt="" align="center" /> Watch Together
- Rooms on [Open Watch Party](https://openwatch.party) — share a six-character code; friends join from Plezy or another Open Watch Party app
- Everyone plays their own copy from their own server — Plex, Jellyfin, or Emby — matched by catalogue IDs, with a picker when several copies fit
- Synchronized play / pause / seek, host or shared control, room lock, and host handoff
- Public relays by default, or point Plezy at your own self-hosted relay

### <img src="assets/readme_icons/integrations.svg" height="20" alt="" align="center" /> Integrations
- Discord Rich Presence[^desktop]
- Trakt, MyAnimeList, AniList, and Simkl — ratings, watched sync, and real-time scrobbling[^rt]
- Scores from connected trackers on detail pages — Trakt, Simkl, MyAnimeList, and AniList, plus Rotten Tomatoes, Metacritic, Letterboxd, IMDb, and TMDB through MDBList
- Plezy Remote — control desktop and TV from mobile
- Watch Next row and tvOS Top Shelf[^shelf]
- Android automation links for media launch, active-video controls, and profile selection
- [`plezy://` links](#plezy-links) to open a profile, play a title, or tune a channel from Home Assistant, launchers, or an NFC tag; any movie, show, or episode menu shows its link[^links]

### <img src="assets/readme_icons/customization.svg" height="20" alt="" align="center" /> Platform & Customization
- Desktop, mobile, and TV — full D-pad, keyboard, and gamepad support
- Multiple servers at once — Plex, Jellyfin, and Emby side by side
- Profiles with per-profile downloads, watch state, and settings; Plex Home switching with PIN
- Jellyfin and Emby local-server discovery and multiple URLs per server; Quick Connect sign-in[^jf]
- TV layout options — corner spotlight backdrop, full-card artwork, and Force TV mode on desktop
- Customizable keyboard shortcuts[^desktop]
- Metadata and artwork editing
- Settings import/export
- Localized across 37 locale choices

[^jf]: Jellyfin only.
[^mb]: Jellyfin and Emby only.
[^plex]: Plex only.
[^connect]: Requires connecting the service under Settings > Services.
[^hdr]: In-app HDR toggle on Windows, macOS, iOS, tvOS, and Linux — Linux needs a colour-managed Wayland compositor. Dolby Vision on Android, macOS, and Apple TV.
[^pass]: Desktop, Android TV, and Apple TV.
[^mpv]: Requires mpv's GPU renderer — unavailable on iOS, tvOS, and macOS, and Android defaults to ExoPlayer.
[^pip]: Android, iOS, and macOS — not on Android TV or Apple TV.
[^rrm]: Windows, Android, and tvOS.
[^android]: Progress sync on Android.
[^lyrics]: Where your server provides lyrics.
[^bgaudio]: tvOS pauses music when the app is backgrounded.
[^dl]: Not available on tvOS.
[^desktop]: Desktop only.
[^rt]: Real-time scrobbling on Trakt and Simkl; MyAnimeList and AniList update on completion.
[^shelf]: Android TV / Fire TV and tvOS.
[^links]: Android, iOS, macOS, and tvOS.

## plezy:// links

PlezyNG accepts both `plezy://` and `plezxyng://` schemes; links shown by the app continue using `plezy://` for compatibility. Use either scheme with the hosts and parameters below. Links start Plezy from outside the app. Any link may add `profile=<profile>`: a profile id, a Plex Home user UUID, or a display name (ignoring case; it must match one profile). Plezy switches to that profile first, and a protected profile still asks for its PIN. A link replaces whatever is playing.

| Link | Does |
|---|---|
| `plezy://open` | Opens Plezy |
| `plezy://play?server=<server>&id=<item>` | Plays one item on one server, any backend |
| `plezy://play?type=movie\|show&tmdb=<n>` | Plays a title from whichever server has it. Use `tmdb`, `tvdb`, `imdb=tt<n>`, or `plex=<hash>` (the Plex GUID without `plex://movie/`) |
| `plezy://live?channel=<channel>` | Tunes a Live TV channel by key, number, or call sign. Optional `server=<server>` and `start=beginning\|live` |

For a show, `mode=next` (the default) plays the next episode to watch, and `mode=shuffle` plays the show shuffled. The menu of any movie, show, or episode has **Show link**, and each profile's menu in **Switch Profile** has **Show profile link**. Both show the link as text and a QR code.

```sh
# Android / Android TV, over adb (Home Assistant: remote.turn_on with activity: plezy://...)
adb shell am start -a android.intent.action.VIEW -d "plezy://play?type=show\&tvdb=81189\&profile=Kids"
# macOS
open "plezy://play?type=movie&tmdb=603"
```

On iOS, use the Open URLs action in Shortcuts.

## Building from Source

### Prerequisites
- Flutter SDK 3.47.0+
- A Plex account, or a Jellyfin or Emby server with user credentials

### Setup

```bash
git clone https://github.com/snapetech-org/PlezyNG.git
cd PlezyNG
flutter pub get
scripts/codegen.sh
flutter run
```

<details>
<summary>Code generation</summary>

After modifying model classes or other generated sources:

```bash
scripts/codegen.sh
```

After modifying translations:

```bash
dart run slang
```

</details>

<details>
<summary>Packaging a Flatpak bundle</summary>

Packages an **already fully resolved Linux release bundle** — pinned libmpv and bundled libraries included, not a Flathub source-build manifest. Run it on Linux, on the same architecture as the bundle, after following the bundle preparation steps in [the Linux release workflow](.github/workflows/build.yml): `flutter build linux` alone does not produce all the required bundled libraries.

Install the packaging tools (Debian/Ubuntu shown) plus the native-architecture SDK and runtime:

```bash
sudo apt-get update
sudo apt-get install -y flatpak flatpak-builder imagemagick
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08

BUNDLE_DIR=build/linux/x64/release/bundle
python3 linux/packaging/build-flatpak.py --bundle "$BUNDLE_DIR" --arch x64 --output "$PWD"
```

That writes `plezy-linux-x64.flatpak`, installable with the Flatpak commands above; on arm64, use the prepared arm64 bundle directory and `--arch arm64`. Package from the checkout matching the bundle, since the version comes from `pubspec.yaml`.

Cross-architecture packaging needs native Flatpak tools, a registered binfmt interpreter, and the target SDK/runtime installed with `flatpak install --user --arch=x86_64` (or `aarch64`) — never run Flatpak's namespace tools under emulation. Pass `--arch x64` or `--arch arm64` to the checker and the matching Flatpak architecture to `flatpak run --arch=...`.

Check the installed package against the runtime (not just the SDK), then launch it on a Wayland desktop and exercise streaming, audio, downloads/offline playback, and file chooser portals:

```bash
python3 linux/packaging/check-flatpak.py
```

The check fails on a non-executable entry point or an unresolved bundled ELF dependency. A container without a GPU can use `flatpak run --env=GALLIUM_DRIVER=softpipe com.edde746.plezy` for software-rendered verification; this is not a hardware-decoding or HDR test.

</details>

<details>
<summary>Local checks</summary>

```bash
scripts/ci_checks.sh
```

To install the same pre-commit checks locally:

```bash
scripts/setup_hooks.sh
```

End-to-end tests (Android emulator plus a Dockerized Jellyfin fixture):

```bash
python3 scripts/maestro/run_maestro.py basic
```

</details>

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, formatting, tests, and translation guidelines.

## License

Plezy is licensed under [GPL-3.0](LICENSE).

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Supports [Plex Media Server](https://www.plex.tv), [Jellyfin](https://jellyfin.org), and [Emby](https://emby.media)
- Playback powered by [mpv](https://mpv.io) via our [mpv-build](https://github.com/edde746/mpv-build) pipeline (started as a fork of [MPVKit](https://github.com/mpvkit/MPVKit); on Android through its mpv-android library, whose Kotlin/JNI glue descends from [libmpv-android](https://github.com/jarnedemeulemeester/libmpv-android)), Android [ExoPlayer](https://developer.android.com/media/media3/exoplayer), and [libass-android](https://github.com/peerless2012/libass-android)
