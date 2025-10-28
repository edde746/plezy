<h1>
  <img src="assets/plezy.png" alt="Plezy Logo" height="24" style="vertical-align: middle;" />
  Plezy
</h1>

Plezy is a modern Plex media client that provides a seamless streaming experience across desktop and mobile platforms. Built with Flutter, it offers native performance and a clean, intuitive interface for browsing and playing your Plex media library.

<p align="center">
  <img src="screenshots/macos-home.png" alt="Plezy macOS Home Screen" width="800" />
</p>

*See more screenshots in the [screenshots folder](screenshots/#readme)*

## Download

### Mobile
Coming soon

### Desktop
- [Windows (x64)](https://github.com/edde746/plezy/releases/latest/download/plezy-windows-installer.exe)
- [macOS (Universal)](https://github.com/edde746/plezy/releases/latest/download/plezy-macos.zip)
- [Linux (x64)](https://github.com/edde746/plezy/releases/latest/download/plezy-linux.tar.gz)

> Download the latest release from the [Releases page](https://github.com/edde746/plezy/releases)

## Features

### 🔐 Authentication & Server Management
- Sign in with Plex
- Automatic server discovery with smart connection selection
- Persistent sessions with auto-login

### 📚 Media Browsing
- Browse libraries with rich metadata
- Discover featured content
- Advanced search across all media
- Season and episode navigation

### 🎬 Video Playback
- Wide codec support including HEVC, AV1, VP9, and more
- Advanced subtitle rendering with full ASS/SSA support
- Audio and subtitle track selection with user profile preferences
- Playback progress sync and resume functionality
- Auto-play next episode

## Prerequisites

- Flutter SDK 3.8.1 or higher
- A Plex account
- Access to a Plex Media Server (local or remote)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/edde746/plezy.git
cd plezy
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate required code:
```bash
dart run build_runner build
```

4. Run the application:
```bash
flutter run
```

## Development

### Code Generation

The project uses code generation for JSON serialization. After modifying model classes, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### Desktop
```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Media playback powered by [MediaKit](https://github.com/media-kit/media-kit)
- Designed for [Plex Media Server](https://www.plex.tv)
