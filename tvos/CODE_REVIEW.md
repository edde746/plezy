# tvOS Code Review - Potential Issues & Fixes

## 🔴 Critical Issues

### 1. **Force Unwrap in PlexAPIClient** ⚠️
**Location:** `PlexAPIClient.swift:235`

```swift
// Current (unsafe)
static func createPlexTVClient(token: String? = nil) -> PlexAPIClient {
    PlexAPIClient(baseURL: URL(string: plexTVURL)!, accessToken: token)
}
```

**Issue:** Force unwrapping URL creation. While `plexTVURL` is a constant "https://plex.tv", it's bad practice.

**Fix:**
```swift
static func createPlexTVClient(token: String? = nil) -> PlexAPIClient? {
    guard let url = URL(string: plexTVURL) else { return nil }
    return PlexAPIClient(baseURL: url, accessToken: token)
}
```

**Impact:** Low (URL is constant) but should still fix for safety.

---

### 2. **Date Decoding Mismatch** ⚠️
**Location:** `PlexModels.swift` - `PlexServer`

**Issue:** `PlexServer` has:
```swift
let createdAt: Date
let lastSeenAt: Date
```

But Plex API returns Unix timestamps (integers), not ISO8601 strings.

**Current decoder:**
```swift
decoder.dateDecodingStrategy = .iso8601  // ❌ Wrong for Plex API
```

**Fix Options:**

**Option A:** Change model to use Int timestamps
```swift
struct PlexServer: Codable, Identifiable {
    let createdAt: Int  // Unix timestamp
    let lastSeenAt: Int // Unix timestamp

    var createdAtDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt))
    }
}
```

**Option B:** Custom date decoding
```swift
decoder.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let timestamp = try container.decode(Int.self)
    return Date(timeIntervalSince1970: TimeInterval(timestamp))
}
```

**Recommended:** Option A - More flexible and explicit

---

### 3. **API Response Structure Inconsistency** ⚠️
**Location:** `PlexAPIClient.swift:295` - `getServers()`

**Issue:** Conflicting response structures:
```swift
func getServers() async throws -> [PlexServer] {
    struct ResourcesResponse: Decodable {
        let servers: [PlexServer]?
        // ...
    }

    // But then uses different structure:
    let container: PlexMediaContainer<PlexServer> = try await request(path: "/api/v2/resources")
    return container.items
}
```

The `ResourcesResponse` struct is defined but never used!

**Actual Plex API Response:**
```json
{
  "MediaContainer": {
    "size": 2,
    "Device": [
      { /* PlexServer data */ }
    ]
  }
}
```

**Fix:**
```swift
func getServers() async throws -> [PlexServer] {
    struct ServersResponse: Decodable {
        let mediaContainer: MediaContainer

        enum CodingKeys: String, CodingKey {
            case mediaContainer = "MediaContainer"
        }

        struct MediaContainer: Decodable {
            let device: [PlexServer]

            enum CodingKeys: String, CodingKey {
                case device = "Device"
            }
        }
    }

    let response: ServersResponse = try await request(path: "/api/v2/resources")
    return response.mediaContainer.device
}
```

---

## 🟡 Medium Priority Issues

### 4. **Missing Error Handling in Task Blocks**
**Location:** Multiple files

**Issue:** Several `Task {}` blocks don't handle errors:

```swift
// PlexAuthService.swift:58
Task {
    await storage.clearAll()  // No error handling
}

// AuthView.swift:87
Task {
    await authService.loadServers()  // No error handling
}
```

**Fix:** Add error handling:
```swift
Task {
    do {
        try await authService.loadServers()
    } catch {
        print("Error loading servers: \(error)")
    }
}
```

---

### 5. **Potential Race Condition in PinPolling** ⚠️
**Location:** `PlexAuthService.swift:85`

**Issue:** `pinCheckTask` can be accessed from multiple threads without protection.

**Current:**
```swift
func startPinPolling(pinId: Int, completion: @escaping (Bool) -> Void) {
    pinCheckTask?.cancel()  // Not thread-safe
    pinCheckTask = Task { ... }
}
```

**Fix:** Use actor or @MainActor:
```swift
@MainActor
func startPinPolling(pinId: Int, completion: @escaping (Bool) -> Void) {
    pinCheckTask?.cancel()
    pinCheckTask = Task { ... }
}
```

---

### 6. **Missing Combine Import Check**
**Location:** All files using `@Published`

**Status:** ✅ Already fixed, but verify:
- PlexAuthService.swift ✅
- StorageService.swift ✅
- SettingsService.swift ✅
- VideoPlayerView.swift ✅
- PlexAPIClient.swift ✅

---

## 🟢 Low Priority / Improvements

### 7. **Hardcoded Sleep Duration**
**Location:** `PlexAuthService.swift:87`

```swift
try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
```

**Improvement:** Make configurable:
```swift
private let pinPollingInterval: UInt64 = 1_000_000_000 // 1 second
try await Task.sleep(nanoseconds: pinPollingInterval)
```

---

### 8. **Missing Cancellation Checks**
**Location:** `PlexAuthService.swift:183`

```swift
func selectServer(from data: Data) {
    Task {
        await selectServer(server)  // No cancellation check
    }
}
```

**Improvement:**
```swift
func selectServer(from data: Data) {
    Task {
        guard !Task.isCancelled else { return }
        await selectServer(server)
    }
}
```

---

### 9. **Optional Chaining Could Be Safer**
**Location:** `VideoPlayerView.swift:214`

```swift
player?.removeTimeObserver(timeObserver)
```

**Current:** ✅ Safe with optional chaining

---

### 10. **Memory Leak Potential in VideoPlayerManager**
**Location:** `VideoPlayerView.swift:181`

**Issue:** Retain cycle in closure:
```swift
timeObserver = player.addPeriodicTimeObserver(...) { [weak self] time in
    guard let self = self, ... // ✅ Good - uses weak self
```

**Status:** ✅ Already handled correctly with `[weak self]`

---

## 📊 Summary

| Priority | Count | Status |
|----------|-------|--------|
| 🔴 Critical | 3 | Need fixes |
| 🟡 Medium | 4 | Should fix |
| 🟢 Low | 3 | Nice to have |

---

## 🔧 Recommended Fixes (Priority Order)

### Immediate (Before Production)
1. ✅ Fix date decoding for PlexServer
2. ✅ Fix getServers() API response structure
3. ✅ Add @MainActor to startPinPolling()

### Before TestFlight
4. ✅ Remove force unwrap in createPlexTVClient()
5. ✅ Add error handling to Task blocks

### Nice to Have
6. Make polling interval configurable
7. Add cancellation checks to tasks

---

## 🧪 Testing Checklist

- [ ] Test authentication flow
- [ ] Test server discovery
- [ ] Test server connection with different network types
- [ ] Test video playback
- [ ] Test progress tracking
- [ ] Test with no internet connection
- [ ] Test with slow connection
- [ ] Test memory leaks with Instruments
- [ ] Test focus navigation
- [ ] Test on physical Apple TV (not just simulator)

---

## 💡 Additional Recommendations

### Performance
1. **Image Caching:** AsyncImage already caches, but consider SDWebImageSwiftUI for more control
2. **Lazy Loading:** Already implemented with LazyVGrid/LazyHStack ✅
3. **Connection Pooling:** URLSession already handles ✅

### User Experience
1. **Loading States:** Already implemented ✅
2. **Error Messages:** Could be more user-friendly (currently technical)
3. **Offline Mode:** Not implemented (requires local database)
4. **Top Shelf:** Not implemented yet (future enhancement)

### Code Quality
1. **Unit Tests:** None implemented
2. **Documentation:** Minimal inline docs
3. **Logging:** Using print() - consider os_log
4. **Analytics:** Not implemented

---

## 🚀 Next Steps

1. **Fix Critical Issues** (Items 1-3)
2. **Test thoroughly on simulator**
3. **Fix Medium Priority Issues** (Items 4-6)
4. **Test on physical Apple TV**
5. **Deploy to TestFlight**
6. **Gather feedback**
7. **Implement enhancements**

---

## 🔍 Additional Findings – 2024-06-01 (gpt-5-codex)

### 1. Playback Ignores the Vetted Connection
**Location:** `PlexAuthService.selectServer` & `VideoPlayerView.setupPlayer`

`selectServer(_:)` puts a lot of work into finding a working connection/URL, but the information is never persisted. `VideoPlayerView.setupPlayer` simply grabs `server.connections.first` and tries to stream through whatever happens to be first in the original list, which may be the very connection that just failed (relay/local ordering is not guaranteed). On shared servers this frequently produces 401/timeout errors right before playback.

**Fix:** Persist the `workingURL` returned by `findBestConnectionWithURL` (either by storing it on `selectedServer`, or by exposing it through `authService.currentClient?.baseURL`) and reuse that exact URL inside `setupPlayer`. Alternatively, reuse `authService.currentClient` instead of re-deriving URLs from `server`.

### 2. Playback Token Falls Back to Empty String
**Location:** `VideoPlayerView.setupPlayer` (`tvos/Plezy/Views/VideoPlayerView.swift` lines 249-266)

When constructing the playback URL the code appends `X-Plex-Token=\(server.accessToken ?? "")`. Shared/remote servers frequently omit `accessToken`, so the request is sent without a token even though the authenticated account token already lives on `authService.currentClient`. This causes the stream to fail for any server that requires authentication (most of them).

**Fix:** Reuse the token that authenticated the current client (e.g., pass the token down from `authService.currentClient`), and only fall back to `server.accessToken` if the server actually provides one.

### 3. PIN Polling Updates Published State Off the Main Actor
**Location:** `PlexAuthService.startPinPolling` (`tvos/Plezy/Services/PlexAuthService.swift` lines 82-120)

`startPinPolling` launches a detached `Task` that runs on a background executor and directly mutates `@Published` properties (`plexToken`, `isAuthenticated`, `currentUser`). SwiftUI requires these mutations to happen on the main actor; running them off-thread can trigger runtime warnings (“Publishing changes from background threads is not allowed”) and racy UI state.

**Fix:** Mark `startPinPolling` as `@MainActor` and wrap the polling loop in `Task { @MainActor in ... }`, or call `await MainActor.run { ... }` before mutating published properties. Also ensure `completion` is invoked on the main actor.

### 4. `getServers()` Still Assumes a Flat Array
**Location:** `PlexAPIClient.getServers` (`tvos/Plezy/Services/PlexAPIClient.swift` lines 520-531)

The current implementation decodes `/api/v2/resources` directly into `[PlexServer]`, but Plex still wraps those objects inside `MediaContainer.Device`. The method will continue to throw `keyNotFound`/`typeMismatch` as soon as it hits the first response, preventing server discovery altogether.

**Fix:** Decode the documented envelope (`{ "MediaContainer": { "Device": [...] } }`) or reuse the existing `PlexMediaContainer<PlexServer>` helper so that `availableServers` actually gets populated.

---

**Review Date:** 2024-11-13
**Reviewer:** Claude Code
**Status:** Ready for fixes

---

## 🔍 Additional Findings – tvOS26 Liquid Glass Review (gpt-5-codex)

### 1. Liquid Glass button styles never observe focus state
**Location:** `tvos/Plezy/Utils/Extensions.swift` (`CardButtonStyle` and `ClearGlassButtonStyle`)

Both button styles try to drive their glass gradients off `@FocusState private var isFocused`, but property wrappers such as `@FocusState` only work inside `View`/`DynamicProperty` types. Inside a `ButtonStyle` they are re‑initialized every render and never bound to the system focus engine, so `isFocused` never flips to `true`. The end result is that the "focused" Liquid Glass look (thicker border, brighter gradient, beacon glow) never appears, so focused buttons remain visually identical to unfocused ones. Use the pattern already adopted by `FilterButton` (keep the `@FocusState` on the view that applies the style and pass a binding into the style) or query `Environment(\.isFocused)` from a wrapper view so the style actually knows when it is focused.

### 2. No Reduce Transparency fallback for Liquid Glass materials
**Location:** `tvos/Plezy/Utils/Extensions.swift` (`liquidGlassBackground`, `thinLiquidGlass`, and both button styles)

Every Liquid Glass layer unconditionally renders `regularMaterial`/`ultraThinMaterial` plus a translucent gradient (e.g. lines 160‑210). When "Reduce Transparency" is enabled in Settings ▸ Accessibility, tvOS expects apps to drop translucency and render solid colors for readability, but the code never checks `Environment(\.accessibilityReduceTransparency)` nor provides a fallback. You should read that environment value once per view and swap in a solid `Color` fill (or at least bump the opacity to 1.0) so text and icons remain legible for users who disable transparency.

### 3. Focus/Hit testing area stays rectangular despite rounded Liquid Glass visuals
**Location:** `tvos/Plezy/Utils/Extensions.swift` (`liquidGlassBackground`/`thinLiquidGlass`) and any button that uses them

The helpers add rounded `RoundedRectangle` backgrounds, but they never clip the content or set `contentShape`. On tvOS the focus engine operates on the view's layout bounds, not the background shape, so the highlight and touch target remain a big rectangle even though the glass effect is visually rounded. This causes focus rings to bleed outside the faux glass edges and makes neighboring controls overlap while animating. Wrap the content with `.clipShape(RoundedRectangle(...))` (or at least `.contentShape`) inside the modifier so the focus/touch geometry matches the Liquid Glass shape.
