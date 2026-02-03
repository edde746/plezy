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

### Mobile
<a href='https://apps.apple.com/us/app/id6754315964'><img height='60' alt='Download on the App Store' src='./assets/app-store-badge.png'/></a>
<a href='https://play.google.com/store/apps/details?id=com.edde746.plezy'><img height='60' alt='Get it on Google Play' src='./assets/play-store-badge.png'/></a>
<a href='https://www.amazon.com/gp/product/B0GK65CVS1'><img height='60' alt='Available at the Amazon App Store' src='./assets/amazon-badge.png'/></a>

### Desktop
- [Windows (x64)](https://github.com/edde746/plezy/releases/latest/download/plezy-windows-installer.exe)
- [macOS (Universal)](https://github.com/edde746/plezy/releases/latest/download/plezy-macos.dmg)
- [Linux (x64)](https://github.com/edde746/plezy/releases/latest) - .deb, .rpm, .pkg.tar.zst, and portable tar.gz available
- [NixOS/Nix](https://github.com/mio-19/nurpkgs/tree/main/pkgs/plezy) - Community package by [@mio-19](https://github.com/mio-19)
- **Homebrew** (macOS):
  ```bash
  brew tap edde746/plezy https://github.com/edde746/plezy
  brew install --cask plezy
  ```

## Features

### 🔐 Authentication
- Sign in with Plex
- Automatic server discovery and smart connection selection
- Persistent sessions with auto-login

### 📚 Media Browsing
- Browse libraries with rich metadata
- Advanced search across all media
- Collections and playlists

### 🎬 Playback
- Wide codec support (HEVC, AV1, VP9, and more)
- HDR and Dolby Vision (iOS, macOS, Windows)
- Full ASS/SSA subtitle support
- Audio and subtitle preferences synced with Plex profile
- Progress sync and resume
- Auto-play next episode

### 📥 Downloads
- Download media for offline viewing
- Background downloads with queue management

### 👥 Watch Together
- Synchronized playback with friends
- Real-time play/pause and seek sync

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
