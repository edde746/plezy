# Troubleshooting Guide - Plezy tvOS

## Common Xcode Build Errors

### ❌ Error: Multiple commands produce Info.plist

**Error Message:**
```
Multiple commands produce '/path/to/Debug-appletvsimulator/plezy.app/Info.plist'
```

**Cause:** Info.plist is being processed by multiple build phases or incorrect build settings.

**Solutions:**

#### Solution 1: Remove from Copy Bundle Resources ⭐ (Most Common)

1. Open Xcode project
2. Select your **target** (left sidebar)
3. Click **Build Phases** tab
4. Expand **Copy Bundle Resources**
5. Find `Info.plist` in the list
6. Select it and click **−** (minus button)
7. **Product → Clean Build Folder** (Shift+Cmd+K)
8. **Product → Build** (Cmd+B)

#### Solution 2: Fix Info.plist File Path

1. Select **target** → **Build Settings**
2. Search for: `info.plist`
3. Find **"Info.plist File"** setting
4. Set value to: `Plezy/Resources/Info.plist`
5. Make sure it's a **relative path** from project root
6. Clean and rebuild

#### Solution 3: Check Target Membership

1. Select `Info.plist` in Project Navigator
2. Open **File Inspector** (right panel, ⌘⌥1)
3. Look at **Target Membership** section
4. Ensure:
   - ✅ Target is checked
   - But file should NOT appear in "Copy Bundle Resources"

#### Solution 4: Generate Info.plist (Fresh Start)

If all else fails:

1. Delete existing `Info.plist` reference from Xcode
2. Select target → **General** tab
3. Look for **"Generate Info.plist File"** checkbox
4. ✅ Check it
5. Build Settings will auto-generate Info.plist
6. Then manually merge your custom keys from `Resources/Info.plist`:
   ```xml
   <key>NSLocalNetworkUsageDescription</key>
   <string>Plezy needs to connect to your Plex Media Server</string>

   <key>NSBonjourServices</key>
   <array>
       <string>_plexmediasvr._tcp</string>
   </array>

   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsLocalNetworking</key>
       <true/>
   </dict>
   ```

---

## ❌ Error: No such module 'SwiftUI' or compilation errors

**Cause:** Wrong deployment target or missing imports.

**Solution:**

1. Select target → **General** tab
2. Set **Minimum Deployments** to: **tvOS 16.0** (or higher)
3. Check each `.swift` file has proper imports:
   ```swift
   import SwiftUI
   import AVKit        // For VideoPlayerView
   import AVFoundation // For audio session
   ```

---

## ❌ Error: Cannot find 'PlexAuthService' in scope

**Cause:** Files not added to target or missing from compile sources.

**Solution:**

1. Select target → **Build Phases**
2. Expand **Compile Sources**
3. Ensure ALL `.swift` files are listed:
   ```
   PlezyApp.swift
   ContentView.swift
   PlexModels.swift
   PlexAPIClient.swift
   PlexAuthService.swift
   StorageService.swift
   SettingsService.swift
   Extensions.swift
   AuthView.swift
   ServerSelectionView.swift
   MainTabView.swift
   HomeView.swift
   LibrariesView.swift
   LibraryContentView.swift
   SearchView.swift
   SettingsView.swift
   MediaDetailView.swift
   SeasonDetailView.swift
   VideoPlayerView.swift
   ```
4. If missing, click **+** and add them

---

## ❌ Error: Module compiled with Swift X.X cannot be imported

**Cause:** Swift version mismatch.

**Solution:**

1. Target → **Build Settings**
2. Search: `swift language version`
3. Set **Swift Language Version** to: **Swift 5**
4. Clean build folder and rebuild

---

## ❌ Error: Signing requires a development team

**Cause:** No Apple Developer account configured.

**Solution:**

### For Testing (Free Account):

1. Xcode → **Settings** → **Accounts**
2. Click **+** → Add your Apple ID
3. Select target → **Signing & Capabilities**
4. Team: Select your Apple ID
5. ✅ Enable **Automatically manage signing**
6. Change Bundle ID to something unique:
   ```
   com.yourname.plezy.tvos
   ```

### For Production (Paid Account):

1. Add your paid Apple Developer account
2. Select your **Team**
3. Use original bundle ID: `com.plezy.tvos`

---

## 🏗️ Clean Project Setup from Scratch

If you want to start fresh:

### Step 1: Create New tvOS Project

1. **Open Xcode**
2. **File → New → Project**
3. Select **tvOS** tab → **App** template
4. Click **Next**

**Configuration:**
```
Product Name:              Plezy
Team:                      [Your team]
Organization Identifier:   com.plezy (or your domain)
Bundle Identifier:         com.plezy.tvos
Interface:                 SwiftUI
Language:                  Swift
Storage:                   None
Include Tests:             ✅ (optional)
```

5. Save location: Choose `tvos/` folder in plezy repo
6. Click **Create**

### Step 2: Remove Default Files

In Xcode Project Navigator, **delete** these files (Move to Trash):
- `ContentView.swift`
- `PlezyApp.swift`
- `Assets.xcassets` (we'll add back later)

### Step 3: Add Source Files

**Method 1: Drag & Drop (Recommended)**
1. Open Finder, navigate to `tvos/Plezy/`
2. Drag folders into Xcode:
   - `App/`
   - `Models/`
   - `Services/`
   - `Views/`
   - `Utils/`
   - `Resources/`
3. In dialog box:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ Add to targets: **Plezy**

**Method 2: Add Files (Alternative)**
1. Right-click target in Project Navigator
2. **Add Files to "Plezy"...**
3. Select all `.swift` files
4. ✅ Copy items if needed
5. Add to target: Plezy

### Step 4: Configure Info.plist

1. Select **target** in navigator
2. Click **Build Settings** tab
3. Search: `info.plist`
4. Find **"Info.plist File"**
5. Double-click value field
6. Enter: `Plezy/Resources/Info.plist`
7. Press Enter

### Step 5: Configure Build Settings

**Required settings:**

| Setting | Value |
|---------|-------|
| Product Name | Plezy |
| Product Bundle Identifier | com.plezy.tvos |
| iOS Deployment Target | iOS 16.0 |
| Swift Language Version | Swift 5 |

### Step 6: Add Capabilities

1. Select target → **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Background Modes**
   - ✅ Audio, AirPlay, and Picture in Picture

### Step 7: Build & Run

1. Select **Apple TV** simulator from device list
2. Press **⌘R** to build and run

---

## 🔍 Debugging Build Issues

### Enable Detailed Build Logging

**Xcode:**
1. **Product → Scheme → Edit Scheme** (⌘<)
2. Select **Build** in left sidebar
3. Expand **Build** → Check "Find Implicit Dependencies"
4. Close

**Terminal:**
```bash
# Build with verbose output
xcodebuild \
  -project Plezy.xcodeproj \
  -scheme Plezy \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  -verbose \
  clean build
```

### Check Build Phase Order

Should be in this order:
1. **Dependencies**
2. **Compile Sources** (all .swift files)
3. **Link Binary With Frameworks**
4. **Copy Bundle Resources** (NO Info.plist here!)

### Common File Issues

**File appears red in Xcode:**
- File is missing from disk
- Path is incorrect
- Fix: Re-add file from Finder

**File not compiling:**
- Not added to target
- Fix: Select file → File Inspector → Target Membership

---

## 🚀 Runtime Issues

### App crashes on launch

**Check Console Output:**
1. Run app in simulator
2. When crashed, check Xcode console
3. Look for error message

**Common issues:**
- Missing @EnvironmentObject
- Force unwrapping nil optional
- Invalid URL formation

**Fix:** Add breakpoints and debug step-by-step

### "Could not connect to server"

**Causes:**
- No Plex server running
- Network issues
- Incorrect server URL

**Debug:**
```swift
// Add to PlexAuthService
print("🔍 Testing connection to: \(connection.uri)")
```

### Video won't play

**Causes:**
- Invalid video URL
- Transcoding issues
- Network timeout

**Debug:**
```swift
// Add to VideoPlayerManager
print("🎬 Video URL: \(videoURL)")
print("🎬 Player status: \(player?.status.rawValue)")
```

---

## 📱 Simulator Issues

### Simulator is slow

**Solutions:**
1. Quit and restart simulator
2. Reset simulator: **Device → Erase All Content and Settings**
3. Reduce graphics: **Simulator → Preferences → Graphics Quality → Low**

### Can't install app

**Solutions:**
1. Clean build: **Shift + Cmd + K**
2. Delete app from simulator
3. Rebuild and run

### Remote simulation not working

**Solutions:**
- Use **Hardware → Show Apple TV Remote** (Cmd+Shift+R)
- Use keyboard shortcuts:
  - Arrow keys: Navigate
  - Space/Enter: Select
  - Escape: Menu/Back

---

## 🔐 Signing Issues

### Provisioning profile errors

**For Development:**
1. Use free Apple ID
2. Change bundle ID to be unique
3. Enable automatic signing

**For Production:**
1. Create App ID in Apple Developer portal
2. Create provisioning profile
3. Download and install in Xcode

### Certificate issues

**Fix:**
1. Xcode → **Settings → Accounts**
2. Select your Apple ID
3. Click **Manage Certificates**
4. Click **+** → **Apple Development** or **Apple Distribution**

---

## 📦 Deployment Issues

### TestFlight upload fails

**Common causes:**
- Invalid provisioning profile
- Missing export compliance
- App icon issues

**Solutions:**
1. Validate archive before upload
2. Check App Store Connect for errors
3. Ensure app icon is correct size

### App Store rejection

**Common issues:**
- Missing privacy descriptions
- Crashes on launch
- UI/UX violations

**Fix:**
- Test thoroughly before submission
- Follow App Store Review Guidelines
- Respond to reviewer feedback

---

## 🆘 Still Having Issues?

### Gather Debug Information

1. **Xcode Version:**
   ```bash
   xcodebuild -version
   ```

2. **Swift Version:**
   ```bash
   swift --version
   ```

3. **Project Structure:**
   ```bash
   cd tvos/
   tree -L 3 Plezy/
   ```

4. **Build Log:**
   - **Product → Show Build Log**
   - Copy full error message

5. **Screenshot:**
   - Take screenshot of error
   - Include full Xcode window

### Create GitHub Issue

Include:
- Xcode version
- macOS version
- Error message (full text)
- Steps to reproduce
- What you've tried

---

## 📚 Additional Resources

- [Apple tvOS Documentation](https://developer.apple.com/tvos/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Need more help?** Open an issue with detailed error logs and screenshots.
