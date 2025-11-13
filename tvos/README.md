# Plezy for tvOS

A native tvOS application for Plex Media Server, built with SwiftUI and modern Apple frameworks.

## Features

### ✨ Core Features
- **Plex Authentication** - Secure PIN-based authentication with QR code support
- **Server Discovery** - Automatic discovery of local and remote Plex servers
- **Smart Connection** - Intelligent connection prioritization (Local > Remote > Relay)
- **Library Browsing** - Browse all your Plex libraries (Movies, TV Shows, Music, Photos)
- **Content Discovery** - Featured content, Continue Watching, and personalized hubs
- **Global Search** - Search across all libraries with real-time results
- **Video Playback** - Native AVPlayer with progress tracking and resume support
- **Plex Home Support** - Switch between Plex Home users with PIN protection

### 📺 tvOS-Specific Features
- **Focus Engine** - Native tvOS focus-based navigation
- **Siri Remote Support** - Full Siri Remote gesture support
- **Background Audio** - Continue playback in the background
- **Local Network Discovery** - Automatic Plex server discovery via Bonjour
- **Top Shelf Support** - (Coming soon) Continue watching on tvOS home screen

### 🎬 Media Features
- **Direct Play** - Hardware-accelerated video playback
- **Resume Playback** - Automatically resume from where you left off
- **Progress Sync** - Real-time progress updates to Plex server
- **Watch Status** - Mark as watched/unwatched
- **Chapter Navigation** - Skip to chapters (Coming soon)
- **Subtitle Support** - External and embedded subtitles
- **Audio Track Selection** - Multiple audio track support
- **Auto-play Next** - Automatically play next episode

## Requirements

- **tvOS 16.0+**
- **Xcode 15.0+**
- **Swift 5.9+**
- **Plex Media Server** (v1.20.0 or later recommended)

## Architecture

### Project Structure

```
tvos/Plezy/
├── App/
│   ├── PlezyApp.swift              # App entry point
│   └── ContentView.swift           # Root view with auth logic
├── Models/
│   └── PlexModels.swift            # Plex API data models
├── Services/
│   ├── PlexAPIClient.swift         # HTTP client for Plex API
│   ├── PlexAuthService.swift      # Authentication & server management
│   ├── StorageService.swift        # UserDefaults persistence
│   └── SettingsService.swift      # App settings management
├── Views/
│   ├── AuthView.swift              # PIN authentication
│   ├── ServerSelectionView.swift  # Server picker
│   ├── MainTabView.swift           # Tab navigation
│   ├── HomeView.swift              # Home feed
│   ├── LibrariesView.swift         # Library browser
│   ├── LibraryContentView.swift   # Library content grid
│   ├── SearchView.swift            # Global search
│   ├── SettingsView.swift          # App settings
│   ├── MediaDetailView.swift      # Movie/Show details
│   ├── SeasonDetailView.swift     # Episode list
│   └── VideoPlayerView.swift      # AVKit video player
├── Utils/
│   └── Extensions.swift            # Helper extensions
└── Resources/
    └── Info.plist                  # App configuration
```

### Key Technologies

- **SwiftUI** - Modern declarative UI framework
- **AVKit/AVFoundation** - Native video playback
- **Combine** - Reactive programming for state management
- **UserDefaults** - Local data persistence
- **URLSession** - HTTP networking
- **@StateObject/@EnvironmentObject** - Dependency injection

## Setup Instructions

### 1. Prerequisites

```bash
# Install Xcode from App Store
xcode-select --install

# Install fastlane (optional, for deployment)
sudo gem install fastlane

# Install CocoaPods (if using dependencies)
sudo gem install cocoapods
```

### 2. Project Setup

```bash
# Clone the repository
cd tvos/

# Open in Xcode
open Plezy.xcodeproj

# Or use Xcode CLI
xed .
```

### 3. Configuration

Update the following in Xcode:

1. **Bundle Identifier**
   - Go to Project Settings → General
   - Change bundle ID: `com.yourcompany.plezy.tvos`

2. **Signing & Capabilities**
   - Select your development team
   - Enable automatic signing

3. **Info.plist** (already configured)
   - Local network usage description
   - Bonjour services for Plex discovery
   - Background audio mode

### 4. Build & Run

```bash
# Build for simulator
xcodebuild -scheme Plezy -destination 'platform=tvOS Simulator,name=Apple TV' build

# Or in Xcode
# Select "Apple TV" simulator
# Press Cmd+R to build and run
```

## Deployment

### TestFlight Deployment

```bash
cd tvos/
fastlane beta
```

This will:
1. Increment build number
2. Build release IPA
3. Upload to TestFlight
4. Notify beta testers

### App Store Release

```bash
fastlane release
```

This will:
1. Increment version number
2. Build release IPA
3. Upload to App Store Connect
4. Create git tag
5. Push to repository

## API Integration

### Plex API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| `POST /api/v2/pins` | Create authentication PIN |
| `GET /api/v2/pins/{id}` | Check PIN status |
| `GET /api/v2/user` | Get user info |
| `GET /api/v2/resources` | Discover servers |
| `GET /library/sections` | Get libraries |
| `GET /library/sections/{id}/all` | Get library content |
| `GET /library/metadata/{key}` | Get item details |
| `GET /library/metadata/{key}/children` | Get seasons/episodes |
| `GET /library/onDeck` | Continue watching |
| `GET /library/recentlyAdded` | Recently added |
| `GET /hubs` | Content hubs |
| `GET /hubs/search` | Search |
| `GET /:/timeline` | Update progress |
| `GET /:/scrobble` | Mark as watched |

### Authentication Flow

```
1. App requests PIN from plex.tv
2. User visits plex.tv/link and enters PIN
3. App polls PIN endpoint every 1 second
4. Upon auth, receives Plex token
5. Token stored in UserDefaults
6. App fetches available servers
7. App tests all server connections
8. Best connection selected (local > remote > relay)
```

### Connection Priority

1. **HTTPS Local** - Secure local connection
2. **HTTP Local** - Fallback local connection
3. **HTTPS Remote** - Secure internet connection
4. **HTTP Remote** - Fallback internet connection
5. **Relay** - Plex relay as last resort

## Settings & Preferences

### Stored Locally (UserDefaults)

- Plex authentication token
- Selected server configuration
- Current user UUID
- Theme preference (Light/Dark/System)
- Auto-play next episode
- Subtitle preferences
- Skip intro/credits settings

### Synced with Plex

- Watch progress
- Watch history
- Ratings
- Collections

## Troubleshooting

### Common Issues

**Can't connect to server**
- Verify server is online
- Check network connectivity
- Ensure Plex server allows insecure connections (if needed)
- Check firewall settings

**Authentication fails**
- Verify internet connection
- Try clearing app data and re-authenticating
- Check plex.tv status

**Video won't play**
- Check server transcoding settings
- Verify codec compatibility
- Check network bandwidth
- Try enabling/disabling direct play

**Search not working**
- Verify server connection
- Check library scanning is complete
- Try refreshing metadata

## Development

### Adding New Features

1. **New API Endpoint**
   - Add method to `PlexAPIClient.swift`
   - Add corresponding model to `PlexModels.swift`
   - Call from appropriate service/view

2. **New View**
   - Create SwiftUI view in `Views/`
   - Add navigation in `MainTabView.swift` or as sheet
   - Connect to services via `@EnvironmentObject`

3. **New Setting**
   - Add property to `SettingsService.swift`
   - Add UI in `SettingsView.swift`
   - Use via `@EnvironmentObject`

### Code Style

- Use SwiftUI best practices
- Follow Apple's Human Interface Guidelines for tvOS
- Use `async/await` for asynchronous operations
- Use `@MainActor` for UI updates
- Document public APIs with doc comments

## Security

### Best Practices Implemented

✅ **NSAllowsLocalNetworking** - Only allows local network access, not arbitrary loads
✅ **Secure token storage** - Tokens stored in UserDefaults (consider Keychain for production)
✅ **HTTPS preferred** - Always attempts HTTPS before HTTP
✅ **No hardcoded credentials** - All auth via Plex OAuth
✅ **Connection validation** - Tests all connections before use

### Recommended Improvements

- [ ] Migrate token storage to Keychain
- [ ] Add certificate pinning for plex.tv
- [ ] Implement biometric authentication
- [ ] Add encrypted local database

## Testing

### Manual Testing Checklist

- [ ] Authentication flow (PIN entry)
- [ ] Server discovery and connection
- [ ] Library browsing
- [ ] Search functionality
- [ ] Video playback
- [ ] Resume playback
- [ ] Progress tracking
- [ ] Mark as watched/unwatched
- [ ] Settings persistence
- [ ] User switching (Plex Home)
- [ ] Remote control navigation
- [ ] Focus engine behavior

### Automated Testing

```bash
# Run unit tests
fastlane test

# Or in Xcode
# Press Cmd+U
```

## Performance Optimization

- **Image caching** - AsyncImage automatically caches
- **Lazy loading** - LazyVGrid/LazyHStack for large lists
- **Progress throttling** - Timeline updates every 10 seconds
- **Connection pooling** - URLSession reuses connections
- **Debounced search** - 500ms delay before searching

## Roadmap

### Phase 1 (Current)
- [x] Basic authentication
- [x] Server discovery
- [x] Library browsing
- [x] Video playback
- [x] Search
- [x] Settings

### Phase 2 (Coming Soon)
- [ ] Top Shelf integration
- [ ] Picture-in-Picture
- [ ] Live TV support
- [ ] Download for offline
- [ ] Enhanced subtitle styling
- [ ] Audio/subtitle sync adjustment
- [ ] Playback speed control

### Phase 3 (Future)
- [ ] Collections support
- [ ] Playlists
- [ ] Music library support
- [ ] Photo library support
- [ ] Multi-user profiles
- [ ] Enhanced recommendations
- [ ] Watch together feature

## Contributing

This is currently a private project. For contributions:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on tvOS simulator
5. Submit a pull request

## License

Copyright © 2024 Plezy. All rights reserved.

## Support

For issues, questions, or feature requests:
- GitHub Issues: [Create an issue]
- Email: support@plezy.app

## Credits

Built with:
- Swift & SwiftUI
- AVFoundation & AVKit
- Plex Media Server API

---

**Made with ❤️ for tvOS**
