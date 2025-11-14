# Plex API Endpoint Analysis Report

## Overview
Analyzed PlexAPIClient.swift and related views to identify API usage patterns, potential issues, and missing features.

## API Endpoints Used

### Library Management
| Endpoint | Method | Purpose | Location |
|----------|--------|---------|----------|
| `/library/sections` | GET | Get all libraries | `getLibraries()` |
| `/library/sections/{key}/all` | GET | Get library content with pagination | `getLibraryContent()` |
| `/library/metadata/{ratingKey}` | GET | Get detailed media metadata | `getMetadata()` |
| `/library/metadata/{ratingKey}/children` | GET | Get children (seasons/episodes) | `getChildren()` |
| `/library/metadata/{ratingKey}/chapters` | GET | Get chapter information | `getChapters()` |
| `/library/onDeck` | GET | Get "Continue Watching" items | `getOnDeck()` |
| `/library/recentlyAdded` | GET | Get recently added items | `getRecentlyAdded()` |

### Content Discovery
| Endpoint | Method | Purpose | Location |
|----------|--------|---------|----------|
| `/hubs` or `/hubs/sections/{key}` | GET | Get content hubs (curated collections) | `getHubs()` |
| `/hubs/search` | GET | Global search across libraries | `search()` |
| `/hubs/{hubKey}` | GET | Get content from specific hub | `getHubContent()` |

### Playback & Progress
| Endpoint | Method | Purpose | Location |
|----------|--------|---------|----------|
| `/:/timeline` | GET | Update playback progress | `updateTimeline()` |
| `/:/scrobble` | GET | Mark media as watched | `scrobble()` |
| `/:/unscrobble` | GET | Mark media as unwatched | `unscrobble()` |

### Authentication (Plex.tv)
| Endpoint | Method | Purpose | Location |
|----------|--------|---------|----------|
| `/api/v2/pins` | POST | Create PIN for authentication | `createPin()` |
| `/api/v2/pins/{id}` | GET | Check PIN authentication status | `checkPin()` |
| `/api/v2/user` | GET | Get current user info | `getUser()` |
| `/api/v2/resources` | GET | Get available Plex servers | `getServers()` |
| `/api/v2/home/users` | GET | Get home users | `getHomeUsers()` |
| `/api/v2/home/users/{userId}/switch` | POST | Switch to home user | `switchHomeUser()` |

---

## Critical Issues Found

### 1. **Client Identifier Not Persisted (HIGH PRIORITY)**
**Location:** `PlexAPIClient.swift:18`

```swift
static let plexClientIdentifier = UUID().uuidString  // ❌ PROBLEM
```

**Issue:** 
- Generates a new UUID every time the app launches
- Plex servers use client identifiers to track device sessions
- Results in the server treating each app launch as a new device
- Can lead to stale session tracking and server confusion

**Impact:** Server-side session management and device history tracking will be broken

**Recommendation:** Persist the client identifier to UserDefaults or Keychain
```swift
static let plexClientIdentifier: String = {
    let key = "com.plezy.client_identifier"
    if let existing = UserDefaults.standard.string(forKey: key) {
        return existing
    }
    let new = UUID().uuidString
    UserDefaults.standard.set(new, forKey: key)
    return new
}()
```

---

### 2. **Suspicious Pagination Parameter Format**
**Location:** `PlexAPIClient.swift:122-123`

```swift
let queryItems = [
    URLQueryItem(name: "X-Plex-Container-Start", value: "\(start)"),
    URLQueryItem(name: "X-Plex-Container-Size", value: "\(size)")
]
```

**Issue:** 
- Standard Plex API uses lowercase query parameters: `X-Plex-Container-Start`, `X-Plex-Container-Size`
- These look like HTTP headers but are being sent as query parameters
- May not work correctly with all Plex server versions
- Need to verify against official Plex API documentation

**Recommendation:** Verify correct parameter format:
```swift
// According to plexapi.dev, should verify if these are correct:
// Standard pagination: ?X-Plex-Container-Start=0&X-Plex-Container-Size=50
// Some APIs use: ?start=0&size=50
```

---

### 3. **Missing Authentication Validation**
**Location:** `PlexAPIClient.swift:57-111` (request method)

**Issue:**
- No check if `accessToken` is present before making authenticated requests
- Requests proceed even when token is `nil`
- Server responds with 401 Unauthorized but error handling is generic

**Current Error Handling:**
```swift
guard (200...299).contains(httpResponse.statusCode) else {
    throw PlexAPIError.httpError(statusCode: httpResponse.statusCode)
}
```

**Recommendation:** 
- Add early validation for protected endpoints
- Distinguish between 401 (auth failure) and other 4xx/5xx errors
- Trigger re-authentication on 401

---

### 4. **Limited Library Content Parameters**
**Location:** `PlexAPIClient.swift:120-130`

```swift
func getLibraryContent(sectionKey: String, start: Int = 0, size: Int = 50) async throws -> [PlexMetadata] {
    let queryItems = [
        URLQueryItem(name: "X-Plex-Container-Start", value: "\(start)"),
        URLQueryItem(name: "X-Plex-Container-Size", value: "\(size)")
    ]
    // ...
}
```

**Missing Parameters:**
- `type` - filter by item type (movie, episode, track, etc.)
- `sort` - sort by (title, rating, recently added, etc.)
- `filters` - advanced filtering (year, rating, duration, etc.)
- `includeGuids` - include external GUIDs
- `includeExtras` - include extra features
- `includeRelated` - include related content

**Impact:** UI cannot provide sorting, filtering, or advanced browsing

---

### 5. **getHubContent Implementation Issues**
**Location:** `PlexAPIClient.swift:202-205`

```swift
func getHubContent(hubKey: String) async throws -> [PlexMetadata] {
    let response: PlexResponse<PlexMetadata> = try await request(path: hubKey)
    return response.MediaContainer.items
}
```

**Issues:**
- `hubKey` is used directly as a path without validation
- Assumes hubKey is a full path, but might be relative
- No pagination support for hub content
- No validation of response structure
- Actually never called in the app code

---

### 6. **Scrobble/Unscrobble Parameter Validity**
**Location:** `PlexAPIClient.swift:242-262`

```swift
func scrobble(ratingKey: String) async throws {
    let queryItems = [
        URLQueryItem(name: "identifier", value: "com.plexapp.plugins.library"),
        URLQueryItem(name: "key", value: ratingKey)
    ]
    // ...
}
```

**Potential Issue:**
- `identifier: "com.plexapp.plugins.library"` - need to verify this is still correct
- Parameter format might be outdated
- No documentation in code about where this format comes from

**Recommendation:** Add comment with reference to official docs

---

### 7. **Aggressive Timeline Updates**
**Location:** `VideoPlayerView.swift:300-332`

```swift
let interval = CMTime(seconds: 10, preferredTimescale: 600)  // Every 10 seconds

timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
    // ...
    try await client.updateTimeline(...)
    
    if currentTime / totalDuration > 0.9 {
        try await client.scrobble(ratingKey: ratingKey)  // Mark as watched
    }
}
```

**Issues:**
- Updates every 10 seconds = 6 API calls per minute
- No debouncing or rate limiting
- Errors are silently caught with no retry logic
- Multiple simultaneous updateTimeline calls possible if tasks overlap

**Recommendation:**
- Increase interval to 30 seconds minimum
- Implement debouncing to prevent overlapping calls
- Add error logging and retry logic

---

### 8. **Generic Error Handling**
**Location:** `PlexAPIClient.swift:415-442`

```swift
enum PlexAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noData
    case unauthorized
    case serverNotReachable
}
```

**Issues:**
- Status code 401 should automatically trigger `unauthorized` case
- No distinction between client errors (4xx) and server errors (5xx)
- No handling for specific status codes:
  - 404 Not Found (item deleted)
  - 429 Too Many Requests (rate limited)
  - 500+ Server errors (temporary vs permanent)
- No retry logic
- Missing `timeoutError` case

---

### 9. **Unused Response Type Assumptions**
**Location:** `PlexAPIClient.swift:236, 247`

```swift
let _: PlexMediaContainer<PlexMetadata> = try await request(
    path: "/:/timeline",
    queryItems: queryItems
)
```

**Issues:**
- Response is discarded with `let _:`
- No validation that response contains expected data
- Timeline and scrobble endpoints may not return proper MediaContainer
- Should verify response structure before discarding

---

### 10. **Search Endpoint Choice Unclear**
**Location:** `PlexAPIClient.swift:209-221`

```swift
func search(query: String, sectionKey: String? = nil) async throws -> [PlexMetadata] {
    var queryItems = [
        URLQueryItem(name: "query", value: query)
    ]
    if let sectionKey = sectionKey {
        queryItems.append(URLQueryItem(name: "sectionId", value: sectionKey))
    }
    let response: PlexResponse<PlexMetadata> = try await request(
        path: "/hubs/search",
        queryItems: queryItems
    )
    return response.MediaContainer.items
}
```

**Issue:**
- Uses `/hubs/search` endpoint
- Alternative `/search` endpoint exists - need to understand difference
- `/hubs/search` returns hub-style results while `/search` returns flat results
- No distinction between search types (library vs Plex suggestions)

---

### 11. **Hub Request Parameters**
**Location:** `PlexAPIClient.swift:180-200`

```swift
let queryItems = [
    URLQueryItem(name: "includeImages", value: "1"),
    URLQueryItem(name: "count", value: "20")
]
```

**Issues:**
- `includeImages: 1` - not verified in official docs
- `count: 20` - arbitrary limit, should be configurable
- Missing parameters:
  - `includeExtras` - include special features
  - `includeRelated` - include related content
  - `includeCollections` - include collections
  - `includeExternalMetadata` - include external metadata

---

### 12. **OnDeck Query Parameters**
**Location:** `PlexAPIClient.swift:158-170`

```swift
let queryItems = [
    URLQueryItem(name: "includeImages", value: "1")
]
```

**Issue:**
- `includeImages: 1` not in official documentation
- Should use standard Plex API format
- Missing context about where this parameter came from

---

## Missing API Features

### Currently Not Implemented

1. **Advanced Library Filtering**
   - Filter by rating, year, content rating, duration
   - Filter by collection, genre, actor, director
   - Status: Not available in any endpoint

2. **Custom Sorting**
   - Sort by title, rating, date added, watch date
   - Status: Not available

3. **Metadata Management**
   - Rating content (1-10 stars)
   - Adding to watchlist
   - Custom tagging/collections
   - Status: Not available

4. **Playback Features**
   - Transcode profiles/quality selection
   - Subtitle/audio stream selection
   - Resume/continue watching (partially supported)
   - Status: Basic resume only

5. **Server Management**
   - Library refresh
   - Optimize database
   - Backup/export metadata
   - Status: Not available

6. **Advanced Search**
   - Advanced filter syntax
   - Search history
   - Saved searches
   - Status: Basic search only

7. **Multi-User Features**
   - Friend sharing
   - Server invitations
   - Managed users
   - Status: Basic home user switching only

8. **Media Info**
   - Subtitles list
   - Audio tracks with full details
   - Alternative versions
   - Status: Partial in PlexMedia/PlexStream models

---

## Header Configuration Analysis

**Location:** `PlexAPIClient.swift:25-43`

Headers being sent are correct and complete:
- ✅ `X-Plex-Product` - identifies app
- ✅ `X-Plex-Version` - app version
- ✅ `X-Plex-Client-Identifier` - device ID (but not persisted ❌)
- ✅ `X-Plex-Platform` - tvOS
- ✅ `X-Plex-Platform-Version` - OS version
- ✅ `X-Plex-Device` - Apple TV
- ✅ `X-Plex-Device-Name` - hardcoded as "Apple TV"
- ✅ `X-Plex-Token` - auth token (when available)
- ✅ `Accept: application/json`
- ✅ `Content-Type: application/json`

**Issue:** Device name is hardcoded and cannot differentiate between different Apple TV devices

---

## Session Configuration

**Location:** `PlexAPIClient.swift:49-52`

```swift
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30
configuration.timeoutIntervalForResource = 120
```

**Analysis:**
- ✅ Request timeout: 30 seconds (reasonable)
- ✅ Resource timeout: 120 seconds (2 minutes, good for large downloads)
- ❌ No timeout for connection: could be longer
- ❌ No URLCache configuration: wasting bandwidth
- ❌ No waitsForConnectivity: could fail on network transitions

**Recommendation:**
```swift
configuration.waitsForConnectivity = true
configuration.urlCache = URLCache(
    memoryCapacity: 50 * 1024 * 1024,  // 50 MB
    diskCapacity: 100 * 1024 * 1024,   // 100 MB
    diskPath: "plezy_cache"
)
```

---

## API Availability Check

**What's Checked:**
- ✅ Server connections are tested before use
- ✅ User authentication is validated
- ✅ Token is required for protected endpoints

**What's Missing:**
- ❌ No check for Plex server version compatibility
- ❌ No detection of which features are available on the server
- ❌ No graceful degradation if advanced features unavailable

---

## Data Validation

**Current Approach:**
- Relies on JSONDecoder with forced unwrapping in some cases
- No validation of critical fields before use

**Issues:**
- `ratingKey` is optional in models but required in API calls
- `media.part` is assumed to exist when accessing playback URL
- No null checks before dereferencing

---

## Recommendations Summary

| Priority | Issue | Fix Effort | Impact |
|----------|-------|-----------|--------|
| 🔴 HIGH | Client identifier not persisted | Low | High |
| 🔴 HIGH | Missing auth validation | Low | High |
| 🔴 HIGH | Generic error handling | Medium | Medium |
| 🟡 MEDIUM | Limited library parameters | Medium | Medium |
| 🟡 MEDIUM | Aggressive timeline updates | Low | Low |
| 🟡 MEDIUM | Missing advanced features | High | Medium |
| 🟢 LOW | Parameter format verification | Low | Low |
| 🟢 LOW | Search endpoint clarity | Low | Low |

