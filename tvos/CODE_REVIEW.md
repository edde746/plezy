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

**Review Date:** 2024-11-13
**Reviewer:** Claude Code
**Status:** Ready for fixes
