<h1>
  <img src="assets/plezy.png" alt="Plezy Logo" height="24" style="vertical-align: middle;" />
  Plezy
</h1>

A modern Plex client for desktop and mobile. Built with Flutter for native performance and a clean interface.

<p align="center">
  <img src="assets/screenshots/macos-home.png" alt="Plezy macOS Home Screen" width="800" />
</p>

*More screenshots in the [screenshots folder](assets/screenshots/#readme)*

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
- Discover hub — On Deck, trending, and personalized recommendations
- Cross-server search
- Filtering, sorting, and alphabetical jump navigation
- Extras — trailers, deleted scenes, behind-the-scenes

### <img src="assets/readme_icons/playback.svg" height="20" alt="" align="center" /> Playback
- Wide codec support (HEVC, AV1, VP9, and more)
- HDR and Dolby Vision (not Linux)
- Full ASS/SSA subtitles with customizable styling
- Online subtitle search & download
- Audio & subtitle preferences synced with Plex profile
- Progress sync and resume
- Auto-play next episode with skip intro / skip credits
- Chapter navigation with BIF thumbnail scrub previews
- Playback speed, audio sync offset, sleep timer
- Ambient lighting and GLSL shader presets
- Picture-in-Picture on Android, iOS, and macOS
- Refresh-rate matching on Windows and Android
- External player launch (VLC, MX Player, etc.)

### <img src="assets/readme_icons/live-tv.svg" height="20" alt="" align="center" /> Live TV & DVR
- EPG guide grid
- Channel tuning with favorites
- DVR recording rules and scheduled recordings
- Multi-server DVR support

### <img src="assets/readme_icons/downloads.svg" height="20" alt="" align="center" /> Downloads & Offline
- Download media for offline viewing
- Background queue with pause / resume
- Sync rules for automatic downloads
- Offline browsing with watch state sync-back on reconnect

### <img src="assets/readme_icons/watch-together.svg" height="20" alt="" align="center" /> Watch Together
- Synchronized playback with friends
- Real-time play / pause / seek sync

### <img src="assets/readme_icons/integrations.svg" height="20" alt="" align="center" /> Integrations
- Discord Rich Presence
- Trakt scrobbling
- Plezy Remote — control desktop and TV from mobile
- Android TV Watch Next row

### <img src="assets/readme_icons/customization.svg" height="20" alt="" align="center" /> Platform & Customization
- Desktop, mobile, and TV — full D-pad, keyboard, and gamepad support
- Customizable keyboard shortcuts on desktop
- In-app metadata and artwork editing
- Localized in 14 languages

## Building from Source

### Prerequisites
- Flutter SDK 3.8.1+
- A Plex account with server access

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
- Designed for [Plex Media Server](https://www.plex.tv)
- Playback powered by [mpv](https://mpv.io) via [MPVKit](https://github.com/mpvkit/MPVKit) and [libmpv-android](https://github.com/jarnedemeulemeester/libmpv-android)
