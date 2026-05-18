<h1>
  <img src="assets/plezy.png" alt="Plezy Logo" height="24" style="vertical-align: middle;" />
  Plezy
</h1>

A modern client for Plex and Jellyfin on desktop, mobile, and TV. Built with Flutter for native performance and a clean interface.

<p align="center">
  <img src="assets/readme-showcase.webp" alt="Plezy mobile screenshots" width="900" />
</p>

*More screenshots: https://plezy.app/#screenshots*

## Download

<a href='https://apps.apple.com/us/app/id6754315964'><img height='60' alt='Download on the App Store' src='./assets/app-store-badge.png'/></a>
<a href='https://play.google.com/store/apps/details?id=com.edde746.plezy'><img height='60' alt='Get it on Google Play' src='./assets/play-store-badge.png'/></a>
<a href='https://www.amazon.com/gp/product/B0GK65CVS1'><img height='60' alt='Available at the Amazon App Store' src='./assets/amazon-badge.png'/></a>

- [Windows (x64, arm64)](https://github.com/edde746/plezy/releases/latest/download/plezy-windows-installer.exe)
- [macOS (x64, arm64)](https://github.com/edde746/plezy/releases/latest/download/plezy-macos.dmg)
- [Linux (x64, arm64)](https://github.com/edde746/plezy/releases/latest) - .deb, .rpm, .pkg.tar.zst, and portable tar.gz available
- [Nix](https://search.nixos.org/packages?channel=unstable&query=plezy) - Community package by [@mio-19](https://github.com/mio-19) and [@MiniHarinn](https://github.com/MiniHarinn)
- **Homebrew** (macOS):
  ```bash
  brew tap edde746/plezy https://github.com/edde746/plezy
  brew install --cask plezy
  ```
- [AUR](https://aur.archlinux.org/packages/plezy-bin) (Arch Linux) - Community maintained by [@jianglai](https://github.com/jianglai):
  ```bash
  yay -S plezy-bin
  ```
- **WinGet** (Windows):
  ```bash
  winget install edde746.plezy
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
- Plezy Remote — control desktop and TV from mobile
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
git clone https://github.com/edde746/plezy.git
cd plezy
flutter pub get
dart run build_runner build
flutter run
```

### Code Generation

After modifying model classes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Supports [Plex Media Server](https://www.plex.tv) and [Jellyfin](https://jellyfin.org)
- Playback powered by [mpv](https://mpv.io) via [MPVKit](https://github.com/mpvkit/MPVKit) and [libmpv-android](https://github.com/jarnedemeulemeester/libmpv-android)
