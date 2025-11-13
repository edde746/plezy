# Plezy tvOS - Setup Guide

This guide will help you set up and run the Plezy tvOS application.

## Quick Start

### Prerequisites

1. **macOS** 13.0 (Ventura) or later
2. **Xcode** 15.0 or later (with tvOS SDK)
3. **Apple Developer Account** (for deployment to physical device)

### Creating the Xcode Project

Since this is a SwiftUI-based tvOS app, you'll need to create an Xcode project manually or use the provided files.

#### Option 1: Manual Xcode Project Creation

1. Open Xcode
2. File → New → Project
3. Select **tvOS** → **App**
4. Configure:
   - Product Name: `Plezy`
   - Organization Identifier: `com.plezy` (or your domain)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we use UserDefaults)

5. **Add Files to Project:**
   - Drag the `App/`, `Models/`, `Services/`, `Views/`, and `Utils/` folders into your Xcode project
   - Ensure "Copy items if needed" is checked
   - Select "Create groups"
   - Add to target: Plezy

6. **Configure Info.plist:**
   - Replace the default Info.plist with `Resources/Info.plist`

#### Option 2: Using Provided Structure

The complete source code is already organized. You just need to:

1. Create a new tvOS App project in Xcode (as above)
2. Delete the default `ContentView.swift` and `PlezyApp.swift`
3. Add all files from the `Plezy/` directory to your project
4. Update `Info.plist` with the one from `Resources/`

### Project Configuration

#### 1. General Settings

- **Display Name:** Plezy
- **Bundle Identifier:** `com.plezy.tvos` (or your custom identifier)
- **Version:** 1.0.0
- **Build:** 1
- **Deployment Target:** tvOS 16.0

#### 2. Signing & Capabilities

1. Select your development team
2. Enable **Automatic Signing**
3. Add capabilities:
   - ✅ **Background Modes** → Audio
   - ✅ **Local Network** (for Plex server discovery)

#### 3. Build Settings

- **Swift Language Version:** Swift 5
- **Optimization Level (Debug):** None [-Onone]
- **Optimization Level (Release):** Optimize for Speed [-O]

### Running on Simulator

1. Select **Apple TV** or **Apple TV 4K** simulator
2. Press **⌘R** to build and run

### Running on Device

1. Connect Apple TV via USB-C (Apple TV HD) or wirelessly
2. Pair device in Xcode (Window → Devices and Simulators)
3. Select your Apple TV as the run destination
4. Press **⌘R**

## File Structure Explanation

```
tvos/Plezy/
│
├── App/                          # Application entry point
│   ├── PlezyApp.swift           # @main app definition
│   └── ContentView.swift        # Root view (handles auth state)
│
├── Models/                       # Data models
│   └── PlexModels.swift         # Codable structs for Plex API
│
├── Services/                     # Business logic
│   ├── PlexAPIClient.swift      # Network layer
│   ├── PlexAuthService.swift   # Authentication & server management
│   ├── StorageService.swift    # Persistence (UserDefaults)
│   └── SettingsService.swift   # App settings
│
├── Views/                        # SwiftUI views
│   ├── AuthView.swift           # PIN authentication screen
│   ├── ServerSelectionView.swift # Server picker
│   ├── MainTabView.swift        # Tab navigation
│   ├── HomeView.swift           # Home feed
│   ├── LibrariesView.swift      # Library browser
│   ├── LibraryContentView.swift # Content grid
│   ├── SearchView.swift         # Search interface
│   ├── SettingsView.swift       # Settings screen
│   ├── MediaDetailView.swift   # Movie/Show details
│   ├── SeasonDetailView.swift  # Episode list
│   └── VideoPlayerView.swift   # AVKit player
│
├── Utils/                        # Helpers
│   └── Extensions.swift         # View extensions, button styles
│
└── Resources/                    # Assets
    └── Info.plist               # App configuration
```

## Environment Setup

### For Local Testing

No special configuration needed! The app will:
1. Prompt for Plex authentication
2. Automatically discover local Plex servers
3. Test all connections and select the best one

### For Production Deployment

#### 1. Fastlane Setup

```bash
cd tvos/
bundle init
bundle add fastlane
bundle exec fastlane init
```

Copy the provided `Fastfile` and `Appfile` to `fastlane/` directory.

#### 2. Environment Variables

Create `.env` file in `tvos/` directory:

```bash
# Apple Developer
APPLE_ID="your.email@example.com"
TEAM_ID="XXXXXXXXXX"
ITC_TEAM_ID="XXXXXXXXXX"

# App Store Connect
APP_IDENTIFIER="com.plezy.tvos"
```

#### 3. App Store Connect Setup

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app:
   - Platform: **tvOS**
   - Name: **Plezy**
   - Bundle ID: **com.plezy.tvos**
   - SKU: **plezy-tvos**
3. Fill in app metadata, screenshots, description
4. Submit for review

## Building & Deployment

### Debug Build (Simulator)

```bash
xcodebuild \
  -scheme Plezy \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  -configuration Debug \
  build
```

### Release Build (Archive)

```bash
xcodebuild \
  -scheme Plezy \
  -archivePath ./build/Plezy.xcarchive \
  -configuration Release \
  archive
```

### TestFlight Deployment

```bash
cd tvos/
bundle exec fastlane beta
```

This will:
- Build release IPA
- Upload to TestFlight
- Available to beta testers within hours

### App Store Release

```bash
bundle exec fastlane release
```

## Testing

### Manual Testing Checklist

Before each release, test:

- [ ] Authentication flow
- [ ] Server connection (local and remote)
- [ ] Library browsing
- [ ] Search
- [ ] Video playback
  - [ ] Direct play
  - [ ] Resume from position
  - [ ] Progress updates
  - [ ] Mark as watched
- [ ] Settings persistence
- [ ] Siri Remote navigation
- [ ] Focus engine behavior

### Automated Testing

Create unit tests in `PlezyTests/`:

```swift
import XCTest
@testable import Plezy

class PlexAPIClientTests: XCTestCase {
    func testPinCreation() async throws {
        let client = PlexAPIClient.createPlexTVClient()
        let pin = try await client.createPin()
        XCTAssertNotNil(pin.code)
        XCTAssertEqual(pin.code.count, 4)
    }
}
```

Run tests:
```bash
xcodebuild test \
  -scheme Plezy \
  -destination 'platform=tvOS Simulator,name=Apple TV'
```

## Troubleshooting

### Build Errors

**"Module not found"**
- Clean build folder: **⇧⌘K**
- Rebuild: **⌘B**

**"Code signing error"**
- Check Signing & Capabilities tab
- Ensure valid Apple Developer account
- Try manual signing if automatic fails

### Runtime Issues

**App crashes on launch**
- Check Xcode console for error logs
- Verify Info.plist is properly configured
- Ensure all @EnvironmentObject dependencies are provided

**Can't discover Plex servers**
- Check local network permissions
- Verify Plex server is running
- Check firewall settings
- Ensure Bonjour is enabled

**Video won't play**
- Check server transcoding settings
- Verify network connection
- Check Xcode console for errors

### Debugging

Enable debug logging:

```swift
// In PlezyApp.swift init()
if ProcessInfo.processInfo.environment["DEBUG"] != nil {
    print("🐛 Debug mode enabled")
}
```

Run with debug flag:
```bash
xcodebuild build \
  -scheme Plezy \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  DEBUG=1
```

## Next Steps

1. **Customize branding:**
   - Add app icon (`Assets.xcassets/App Icon & Top Shelf Image.brandassets`)
   - Add Top Shelf images
   - Update colors in `Extensions.swift`

2. **Configure server:**
   - Set up Plex Media Server
   - Enable remote access
   - Add media libraries

3. **Test thoroughly:**
   - Test on multiple tvOS versions
   - Test with different Plex server versions
   - Test various network conditions

4. **Deploy:**
   - Submit to TestFlight
   - Gather feedback
   - Submit to App Store

## Resources

- [Apple tvOS Documentation](https://developer.apple.com/tvos/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AVKit Documentation](https://developer.apple.com/documentation/avkit/)
- [Plex API Documentation](https://www.plexopedia.com/plex-media-server/api/)
- [Fastlane Documentation](https://docs.fastlane.tools/)

## Support

Need help? Contact:
- GitHub Issues: Create an issue
- Email: support@plezy.app

---

Happy coding! 🚀
