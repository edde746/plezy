<h1>
  <img src="assets/vibe_stream.png" alt="Vibe Logo" height="24" style="vertical-align: middle;" />
  Vibe
</h1>

A modern client for Plex and Jellyfin on desktop, mobile, and TV. Built with Flutter for native performance and a clean interface.

<p>
  <a href="https://github.com/MazeDev7/alflix">GitHub</a> ·
  <a href="#download">Download</a> ·
  <a href="CONTRIBUTING.md">Contributing</a> ·
  <a href="LICENSE">License</a>
</p>

<p align="center">
  <img src="assets/readme-showcase.webp" alt="Vibe mobile screenshots" width="900" />
</p>

## Download

<a href='https://apps.apple.com/us/app/id6754315964'><img height='60' alt='Download on the App Store' src='./assets/app-store-badge.png'/></a>
<a href='https://play.google.com/store/apps/details?id=com.amaze.vibestream'><img height='60' alt='Get it on Google Play' src='./assets/play-store-badge.png'/></a>
<a href='https://www.amazon.com/gp/product/B0GK65CVS1'><img height='60' alt='Available at the Amazon App Store' src='./assets/amazon-badge.png'/></a>

| Platform | Download |
| --- | --- |
| Windows | [Installer (x64, arm64)](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-windows-installer.exe) · [Portable x64](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-windows-x64-portable.7z) · [Portable arm64](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-windows-arm64-portable.7z) |
| macOS | [DMG (x64, arm64)](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-macos.dmg) |
| Linux x64 | [.deb](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-linux-x64.deb) · [.rpm](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-linux-x64.rpm) · [.pkg.tar.zst](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-linux-x64.pkg.tar.zst) · [portable tar.gz](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-linux-x64.tar.gz) |
| Linux arm64 | [.deb](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-linux-arm64.deb) · [.rpm](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-linux-arm64.rpm) · [.pkg.tar.zst](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-linux-arm64.pkg.tar.zst) · [portable tar.gz](https://github.com/MazeDev7/alflix/releases/latest/download/vibe_stream-linux-arm64.tar.gz) |

Package managers:

- **Homebrew** (macOS):
  ```bash
  brew tap MazeDev7/alflix https://github.com/MazeDev7/alflix
  brew install --cask vibe_stream
  ```

## Features

### <img src="assets/readme_icons/browse.svg" height="20" alt="" align="center" /> Browse & Discover
- Libraries, collections, and playlists
- Discover hub — Continue Watching, Next Up, trending, and recommendations
- Cross-server search
- Filtering, sorting, and alphabetical jump navigation
- Extras — trailers, deleted scenes, behind-the-scenes

### <img src="assets/readme_icons/playback.svg" height="20" alt="" align="center" /> Playback
- Wide codec support (HEVC, AV1, VP9, and more)
- HDR and Dolby Vision[^1]
- Full ASS/SSA subtitles with customizable styling
- Online subtitle search & download[^2]
- Audio & subtitle choices remembered per title
- Progress sync and resume
- Auto-play next episode with skip intro / skip credits
- Chapter navigation with thumbnail scrub previews
- Playback speed, audio sync offset, sleep timer
- Ambient lighting and GLSL shader presets[^3]
- Picture-in-Picture[^4]
- Refresh-rate matching[^5]
- External player launch (VLC, MX Player, etc.)

### <img src="assets/readme_icons/live-tv.svg" height="20" alt="" align="center" /> Live TV & DVR
- Live TV channel browsing with favorites
- DVR support with EPG guide, recording rules, and scheduled recordings[^2]
- Multi-server Live TV support where available

### <img src="assets/readme_icons/downloads.svg" height="20" alt="" align="center" /> Downloads & Offline
- Download media for offline viewing
- Background queue with pause / resume
- Sync rules for automatic downloads
- Offline browsing with watch state sync-back on reconnect

### <img src="assets/readme_icons/watch-together.svg" height="20" alt="" align="center" /> Watch Together
- Synchronized playback with friends
- Real-time play / pause / seek sync

### <img src="assets/readme_icons/integrations.svg" height="20" alt="" align="center" /> Integrations
- Discord Rich Presence[^7]
- Trakt, MyAnimeList, AniList, and Simkl tracking & rating
- Companion Remote — control desktop and TV from mobile
- Watch Next row[^6]

### <img src="assets/readme_icons/customization.svg" height="20" alt="" align="center" /> Platform & Customization
- Desktop, mobile, and TV — full D-pad, keyboard, and gamepad support
- Customizable keyboard shortcuts[^7]
- Metadata and artwork editing[^2]
- Settings import/export
- Localized in English plus 14 translations

[^1]: Not available on Linux.
[^2]: Plex only.
[^3]: Not available on iOS or tvOS.
[^4]: Android, iOS, and macOS.
[^5]: Windows, Android, and tvOS.
[^6]: Android TV only.
[^7]: Desktop only.

## Building from Source

### Prerequisites
- Flutter SDK 3.38.4+
- A Plex account or Jellyfin server with user credentials

### Setup

```bash
git clone https://github.com/MazeDev7/alflix.git
cd alflix
flutter pub get
scripts/codegen.sh
flutter run
```

### Code Generation

After modifying model classes or other generated sources:

```bash
scripts/codegen.sh
```

After modifying translations:

```bash
dart run slang
```

### Local Checks

```bash
scripts/ci_checks.sh
```

To install the same pre-commit checks locally:

```bash
scripts/setup_hooks.sh
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, formatting, tests, and translation guidelines.

## License

Vibe is licensed under [GPL-3.0](LICENSE).

## Acknowledgments

- Forked from the upstream [Plezy](https://github.com/edde746/plezy) Flutter codebase by [@edde746](https://github.com/edde746)
- Built with [Flutter](https://flutter.dev)
- Supports [Plex Media Server](https://www.plex.tv) and [Jellyfin](https://jellyfin.org)
- Playback powered by [mpv](https://mpv.io), [MPVKit](https://github.com/mpvkit/MPVKit), Android [ExoPlayer](https://developer.android.com/media/media3/exoplayer), [libass-android](https://github.com/peerless2012/libass-android), and [libmpv-android](https://github.com/jarnedemeulemeester/libmpv-android)
