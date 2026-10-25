<h1>
  <img src="assets/plezy.png" alt="PlezyNG logo" height="24" style="vertical-align: middle;" />
  PlezyNG
</h1>

A modern Flutter client for Plex, Jellyfin, and Emby on desktop, mobile, and TV. PlezyNG is a community-maintained fork of [Plezy](https://github.com/edde746/plezy).

PlezyNG keeps upstream Plezy as its foundation and implements user-requested features that upstream has not accepted or delivered. We aim to support Plex, Jellyfin, and Emby wherever their server APIs allow the same capability.

> **Convergence policy:** PlezyNG is a delivery vehicle for these feature gaps, not a commitment to permanent divergence. When upstream releases equivalent capabilities, we intend to adopt its maintained implementation and remove duplicate fork-specific code. Until then, this fork maintains the missing work and documents the differences here.

<p>
  <a href="#download">Download</a> ·
  <a href="https://discord.gg/jz5rv5EUvr">Discord support</a> ·
  <a href="CONTRIBUTING.md">Contributing</a> ·
  <a href="LICENSE">License</a>
</p>

<p align="center">
  <img src="assets/readme-showcase.webp" alt="PlezyNG mobile screenshots" width="900" />
</p>

## Why this fork exists

The table tracks the feature work that currently distinguishes PlezyNG. “In fork” means the capability is present here; “Planned” means implementation remains. References point to the upstream requests or pull requests that motivated the work.

| Feature | Upstream reference | Status in PlezyNG |
| --- | --- | --- |
| Server-converted download quality | [#1145](https://github.com/edde746/plezy/issues/1145), [#1847](https://github.com/edde746/plezy/issues/1847), [#1418](https://github.com/edde746/plezy/issues/1418) | In fork for Plex; Jellyfin/Emby and per-sync-rule quality planned |
| Local-only Plex connections | [#1447](https://github.com/edde746/plezy/issues/1447), PR [#2248](https://github.com/edde746/plezy/pull/2248) | In fork |
| Download sizes and storage usage | PR [#2376](https://github.com/edde746/plezy/pull/2376) | In fork |
| `plezy://watch` links and iOS external-player progress return | PRs [#2681](https://github.com/edde746/plezy/pull/2681), [#2738](https://github.com/edde746/plezy/pull/2738) | In fork; Jellyfin/Emby link resolution planned |
| Buffer controls and subtitle-delay hotkeys | PRs [#2797](https://github.com/edde746/plezy/pull/2797), [#2824](https://github.com/edde746/plezy/pull/2824) | In fork |
| Directors, library item counts, watchlist filters, MDBList, and Seerr search | PRs [#2762](https://github.com/edde746/plezy/pull/2762), [#1516](https://github.com/edde746/plezy/pull/1516), [#2725](https://github.com/edde746/plezy/pull/2725), [#2740](https://github.com/edde746/plezy/pull/2740), [#2811](https://github.com/edde746/plezy/pull/2811) | In fork |
| Playlist repeat, swipe seeking, frame stepping, and bulk watched-state updates | PRs [#1757](https://github.com/edde746/plezy/pull/1757), [#2601](https://github.com/edde746/plezy/pull/2601), [#1584](https://github.com/edde746/plezy/pull/1584), [#2597](https://github.com/edde746/plezy/pull/2597) | In fork |
| Subtitle preview, Plex prerolls, theme songs, remembered versions, and Live TV timeshift | PRs [#2347](https://github.com/edde746/plezy/pull/2347), [#2483](https://github.com/edde746/plezy/pull/2483), [#2596](https://github.com/edde746/plezy/pull/2596), [#2563](https://github.com/edde746/plezy/pull/2563), [#2300](https://github.com/edde746/plezy/pull/2300) | In fork; Jellyfin/Emby parity for prerolls, links, and timeshift planned |
| Emby subtitle search and sync-rule controls | PRs [#2091](https://github.com/edde746/plezy/pull/2091), [#1197](https://github.com/edde746/plezy/pull/1197), [#1199](https://github.com/edde746/plezy/pull/1199) | In fork |
| Automatic Continue Watching downloads, quality rules, and cleanup after watching | [#1978](https://github.com/edde746/plezy/issues/1978), [#2181](https://github.com/edde746/plezy/issues/2181), [#1413](https://github.com/edde746/plezy/issues/1413), PR [#2117](https://github.com/edde746/plezy/pull/2117), [#2206](https://github.com/edde746/plezy/issues/2206) | Planned |
| Per-profile PIN protection and hiding Explore | [#1924](https://github.com/edde746/plezy/issues/1924), [#2514](https://github.com/edde746/plezy/issues/2514) | Planned |
| Per-show audio/subtitle choices, pre-play selection, language fallback, and per-item sync offsets | [#2382](https://github.com/edde746/plezy/issues/2382), [#84](https://github.com/edde746/plezy/issues/84), [#2346](https://github.com/edde746/plezy/pull/2346), [#1758](https://github.com/edde746/plezy/issues/1758), [#1956](https://github.com/edde746/plezy/pull/1956) | Planned |
| In-player subtitle styling and loading local subtitle files | [#2174](https://github.com/edde746/plezy/issues/2174), [#689](https://github.com/edde746/plezy/issues/689), [#95](https://github.com/edde746/plezy/issues/95), [#1431](https://github.com/edde746/plezy/issues/1431) | Planned |
| Background video audio, mpv equalizer, and local/remote quality policies | [#367](https://github.com/edde746/plezy/issues/367), [#2292](https://github.com/edde746/plezy/issues/2292), [#2064](https://github.com/edde746/plezy/issues/2064) | Planned |
| Intro database fallback and local preroll clips | [#389](https://github.com/edde746/plezy/issues/389), [#1110](https://github.com/edde746/plezy/issues/1110), PRs [#1886](https://github.com/edde746/plezy/pull/1886), [#2271](https://github.com/edde746/plezy/pull/2271) | Planned; intro database remains opt-in |
| Search by actor/director, random picks, library shuffle, and estimated finish time | [#1517](https://github.com/edde746/plezy/issues/1517), [#2368](https://github.com/edde746/plezy/issues/2368), [#1561](https://github.com/edde746/plezy/issues/1561), [#2741](https://github.com/edde746/plezy/issues/2741), [#2757](https://github.com/edde746/plezy/issues/2757), [#2671](https://github.com/edde746/plezy/issues/2671) | Planned |
| Home-row configuration, merged libraries, and spotlight theme music | [#1652](https://github.com/edde746/plezy/issues/1652), PRs [#2203](https://github.com/edde746/plezy/pull/2203), [#2170](https://github.com/edde746/plezy/pull/2170) | Planned |
| Display controls for the clock, artwork, home rows, libraries, Next Up, server choice, and file logs | [#1764](https://github.com/edde746/plezy/issues/1764), [#2784](https://github.com/edde746/plezy/issues/2784), [#2701](https://github.com/edde746/plezy/issues/2701), [#2723](https://github.com/edde746/plezy/issues/2723), [#2498](https://github.com/edde746/plezy/issues/2498), [#2690](https://github.com/edde746/plezy/issues/2690), [#591](https://github.com/edde746/plezy/issues/591), [#2720](https://github.com/edde746/plezy/issues/2720), [#1529](https://github.com/edde746/plezy/issues/1529), [#2496](https://github.com/edde746/plezy/issues/2496) | Planned |
| Content screensaver and new-episode notifications | [#401](https://github.com/edde746/plezy/issues/401), [#1146](https://github.com/edde746/plezy/issues/1146) | Planned |
| Settings backup, offline playlist downloads, Google Cast, and automation controls | [#1795](https://github.com/edde746/plezy/issues/1795), [#1721](https://github.com/edde746/plezy/issues/1721), [#2600](https://github.com/edde746/plezy/issues/2600), [#126](https://github.com/edde746/plezy/issues/126), [#823](https://github.com/edde746/plezy/issues/823), [#1996](https://github.com/edde746/plezy/issues/1996) | Planned |

When upstream covers a row above, we will prefer the maintained upstream implementation and update this table. The aim is to reduce the fork-specific delta over time; the fork remains useful only while these user-facing gaps remain.

## Download

| Platform | Download |
| --- | --- |
| macOS | [DMG (x64, arm64)](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-macos.dmg) |
| Linux x64 | [.deb](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-x64.deb) · [.rpm](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-x64.rpm) · [.pkg.tar.zst](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-x64.pkg.tar.zst) · [.flatpak](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-x64.flatpak) · [portable tar.gz](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-x64.tar.gz) |
| Linux arm64 | [.deb](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-arm64.deb) · [.rpm](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-arm64.rpm) · [.pkg.tar.zst](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-arm64.pkg.tar.zst) · [.flatpak](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-arm64.flatpak) · [portable tar.gz](https://github.com/snapetech-org/PlezyNG/releases/latest/download/plezy-linux-arm64.tar.gz) |

<details>
<summary>Install with a package manager</summary>

### macOS — Homebrew

```bash
brew tap snapetech-org/PlezyNG https://github.com/snapetech-org/PlezyNG
brew install --cask plezy
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

</details>

## Features

### <img src="assets/readme_icons/browse.svg" height="20" alt="" align="center" /> Browse & Discover
- Libraries, collections, and playlists — video and audio
- Discover hub — Continue Watching, Next Up, trending, and recommendations
- Cross-server search across every connected Plex, Jellyfin, and Emby server, including actors and directors
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
- Online subtitle search & download[^plex]
- Audio & subtitle choices remembered per title, or follow the server's per-episode selections
- Progress sync and resume
- Auto-play next episode with skip intro / skip credits
- Chapter navigation with thumbnail scrub previews
- Playback speed from 0.25x to 8x, audio sync offset, sleep timer (fixed durations or end of video)
- Video zoom 50-200% with pinch, presets, and hotkeys
- Audio passthrough[^pass], output channel limit (5.1 or stereo, with center-channel boost), and loudness normalization
- File Info sheet — every version, file, and stream the server reports
- Ambient lighting and GLSL shader presets[^mpv]
- Picture-in-Picture[^pip]
- Refresh-rate matching[^rrm]
- External player launch (VLC, MX Player, etc.) with progress sync back[^android]

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
- Offline browsing with watch state sync-back on reconnect

### <img src="assets/readme_icons/watch-together.svg" height="20" alt="" align="center" /> Watch Together
- Rooms on [Open Watch Party](https://openwatch.party) — share a six-character code; friends join from PlezyNG or another Open Watch Party app
- Everyone plays their own copy from their own server — Plex, Jellyfin, or Emby — matched by catalogue IDs, with a picker when several copies fit
- Synchronized play / pause / seek, host or shared control, room lock, and host handoff
- Public relays by default, or point PlezyNG at your own self-hosted relay

### <img src="assets/readme_icons/integrations.svg" height="20" alt="" align="center" /> Integrations
- Discord Rich Presence[^desktop]
- Trakt, MyAnimeList, AniList, and Simkl — ratings, watched sync, and real-time scrobbling[^rt]
- Scores from connected trackers on detail pages — Trakt, Simkl, MyAnimeList, and AniList, plus Rotten Tomatoes, Metacritic, Letterboxd, IMDb, and TMDB through MDBList
- PlezyNG Remote — control desktop and TV from mobile
- Watch Next row and tvOS Top Shelf[^shelf]

### <img src="assets/readme_icons/customization.svg" height="20" alt="" align="center" /> Platform & Customization
- Desktop, mobile, and TV — full D-pad, keyboard, and gamepad support
- Multiple servers at once — Plex, Jellyfin, and Emby side by side
- Profiles with per-profile downloads, watch state, and settings; Plex Home switching with PIN
- Jellyfin and Emby local-server discovery and multiple URLs per server; Quick Connect sign-in[^jf]
- TV layout options — corner spotlight backdrop, full-card artwork, and Force TV mode on desktop
- Customizable keyboard shortcuts[^desktop]
- Metadata and artwork editing
- Settings import/export
- Localized in English plus 21 translations

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

PlezyNG is a modified fork of [Plezy](https://github.com/edde746/plezy) and remains licensed under [GPL-3.0](LICENSE). Original source notices are retained, and bundled third-party license notices are in `assets/licenses/` and the relevant package directories.

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Supports [Plex Media Server](https://www.plex.tv), [Jellyfin](https://jellyfin.org), and [Emby](https://emby.media)
- Playback uses [mpv](https://mpv.io) built from the [Plezy upstream mpv-build project](https://github.com/edde746/mpv-build), which started as a fork of [MPVKit](https://github.com/mpvkit/MPVKit). Android uses its mpv-android library, whose Kotlin/JNI glue descends from [libmpv-android](https://github.com/jarnedemeulemeester/libmpv-android), as well as [ExoPlayer](https://developer.android.com/media/media3/exoplayer) and [libass-android](https://github.com/peerless2012/libass-android).
- Windows uses the [flutter-plezy patched Flutter engine](https://github.com/edde746/flutter-plezy) for DirectComposition video rendering and a Flutter window-resize fix.
- PlezyNG still uses Plezy upstream's hosted service at `ice.plezy.app` for tracker OAuth, optional diagnostic log uploads, and artwork used by Discord Rich Presence.
