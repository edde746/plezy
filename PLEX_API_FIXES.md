# Recommended Fixes for Plex API Issues

## Fix #1: Persist Client Identifier (HIGH PRIORITY)

**Problem:** App creates a new device ID on each launch
**Current Location:** `PlexAPIClient.swift:18`

### Implementation:

Create a new utility module:
```swift
// ClientIdentifierManager.swift
import Foundation

class ClientIdentifierManager {
    static let shared = ClientIdentifierManager()
    
    private let key = "com.plezy.client_identifier"
    
    var clientIdentifier: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
    
    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
```

**Update PlexAPIClient.swift:**
```swift
class PlexAPIClient {
    private let baseURL: URL
    private let accessToken: String?
    private let session: URLSession

    // Use persistent client identifier
    static let plexClientIdentifier = ClientIdentifierManager.shared.clientIdentifier
    // ... rest of code
}
```

---

## Fix #2: Add Proper Error Handling (HIGH PRIORITY)

**Problem:** Cannot distinguish between different HTTP error types

### Enhanced Error Enum:
```swift
enum PlexAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case noData
    case unauthorized  // 401
    case forbidden     // 403
    case notFound      // 404
    case rateLimited   // 429
    case serverError(Int)  // 5xx
    case timeout
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code, let message):
            return message ?? "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noData:
            return "No data received from server"
        case .unauthorized:
            return "Unauthorized - please login again"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests - please wait"
        case .serverError(let code):
            return "Server error: \(code)"
        case .timeout:
            return "Request timed out"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

### Update Request Method:
```swift
func request<T: Decodable>(
    path: String,
    method: String = "GET",
    queryItems: [URLQueryItem]? = nil,
    body: Data? = nil
) async throws -> T {
    var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
    urlComponents?.queryItems = queryItems

    guard let url = urlComponents?.url else {
        throw PlexAPIError.invalidURL
    }

    print("🌐 [API] \(method) \(url)")

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.httpBody = body
    request.timeoutInterval = 30

    for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
    }

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw PlexAPIError.invalidResponse
    }

    print("🌐 [API] Response: \(httpResponse.statusCode) - \(data.count) bytes")

    // Handle specific status codes
    switch httpResponse.statusCode {
    case 200...299:
        break  // Success, continue processing
    case 401:
        throw PlexAPIError.unauthorized
    case 403:
        throw PlexAPIError.forbidden
    case 404:
        throw PlexAPIError.notFound
    case 429:
        throw PlexAPIError.rateLimited
    case 500...599:
        throw PlexAPIError.serverError(httpResponse.statusCode)
    default:
        throw PlexAPIError.httpError(statusCode: httpResponse.statusCode, message: nil)
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .useDefaultKeys

    do {
        if let jsonString = String(data: data, encoding: .utf8) {
            let preview = String(jsonString.prefix(500))
            print("🔍 [API] Response preview: \(preview)")
        }
        return try decoder.decode(T.self, from: data)
    } catch {
        print("🔴 [API] Decoding error: \(error)")
        if let jsonString = String(data: data, encoding: .utf8) {
            let preview = String(jsonString.prefix(1000))
            print("🔴 [API] Failed JSON preview: \(preview)")
        }
        throw PlexAPIError.decodingError(error)
    }
}
```

---

## Fix #3: Add Authentication Validation

**Problem:** No check for auth token on protected endpoints

```swift
extension PlexAPIClient {
    private func requiresAuth(path: String) -> Bool {
        // These endpoints require authentication
        let protectedPaths = [
            "/library/",
            "/hubs/",
            "/:/timeline",
            "/:/scrobble",
            "/:/unscrobble"
        ]
        return protectedPaths.contains { path.hasPrefix($0) }
    }
    
    private func validateAuthentication(for path: String) throws {
        if requiresAuth(path: path) && accessToken == nil {
            throw PlexAPIError.unauthorized
        }
    }
}
```

Update request method to call validation:
```swift
func request<T: Decodable>(
    path: String,
    method: String = "GET",
    queryItems: [URLQueryItem]? = nil,
    body: Data? = nil
) async throws -> T {
    // Validate auth before making request
    try validateAuthentication(for: path)
    
    // ... rest of request code
}
```

---

## Fix #4: Improve Library Content Parameters

**Problem:** Cannot filter or sort library content

```swift
func getLibraryContent(
    sectionKey: String,
    type: String? = nil,
    sort: String? = nil,
    filter: String? = nil,
    start: Int = 0,
    size: Int = 50
) async throws -> [PlexMetadata] {
    var queryItems = [
        URLQueryItem(name: "X-Plex-Container-Start", value: "\(start)"),
        URLQueryItem(name: "X-Plex-Container-Size", value: "\(size)")
    ]
    
    // Add optional filters
    if let type = type {
        queryItems.append(URLQueryItem(name: "type", value: type))
    }
    
    if let sort = sort {
        queryItems.append(URLQueryItem(name: "sort", value: sort))
    }
    
    // Add filters like year, rating, etc
    if let filter = filter {
        queryItems.append(URLQueryItem(name: "filters", value: filter))
    }
    
    // Include additional data
    queryItems.append(URLQueryItem(name: "includeGuids", value: "1"))
    queryItems.append(URLQueryItem(name: "includeRelated", value: "1"))
    
    let response: PlexResponse<PlexMetadata> = try await request(
        path: "/library/sections/\(sectionKey)/all",
        queryItems: queryItems
    )
    return response.MediaContainer.items
}

// Example sorts supported by Plex:
enum PlexSort: String {
    case titleAsc = "title:asc"
    case titleDesc = "title:desc"
    case dateAddedNewest = "addedAt:desc"
    case dateAddedOldest = "addedAt:asc"
    case ratingDesc = "rating:desc"
    case ratingAsc = "rating:asc"
}
```

---

## Fix #5: Reduce Timeline Update Frequency

**Problem:** 10-second interval causes 6 API calls per minute

```swift
private func setupProgressTracking(client: PlexAPIClient, player: AVPlayer, ratingKey: String) {
    // Increase to 30 seconds minimum
    let interval = CMTime(seconds: 30, preferredTimescale: 600)
    
    // Track last update to prevent duplicates
    var lastUpdate: Date = Date()
    let minUpdateInterval: TimeInterval = 15  // Minimum 15 seconds between updates

    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
        guard let self = self,
              let duration = player.currentItem?.duration,
              duration.isNumeric,
              Date().timeIntervalSince(lastUpdate) >= minUpdateInterval else {
            return
        }

        let currentTime = CMTimeGetSeconds(time)
        let totalDuration = CMTimeGetSeconds(duration)

        // Update timeline
        Task {
            do {
                try await client.updateTimeline(
                    ratingKey: ratingKey,
                    state: player.rate > 0 ? .playing : .paused,
                    time: Int(currentTime * 1000),
                    duration: Int(totalDuration * 1000)
                )
                lastUpdate = Date()

                // Mark as watched when 90% complete
                if currentTime / totalDuration > 0.9 {
                    try await client.scrobble(ratingKey: ratingKey)
                }
            } catch let error as PlexAPIError {
                // Handle specific errors
                switch error {
                case .unauthorized:
                    print("❌ [Timeline] Auth expired, need to re-login")
                case .notFound:
                    print("⚠️ [Timeline] Media no longer available")
                case .rateLimited:
                    print("⚠️ [Timeline] Rate limited, will retry")
                    lastUpdate = Date().addingTimeInterval(-10)  // Retry sooner
                default:
                    print("⚠️ [Timeline] Update failed: \(error)")
                }
            } catch {
                print("❌ [Timeline] Unexpected error: \(error)")
            }
        }
    }
}
```

---

## Fix #6: Add Documentation to Parameter Choices

**Problem:** Parameter formats are unclear/undocumented

```swift
func getHubs(sectionKey: String? = nil) async throws -> [PlexHub] {
    let path = sectionKey != nil ? "/hubs/sections/\(sectionKey!)" : "/hubs"
    print("📚 [API] Requesting Hubs from \(path)")

    // According to Plex API documentation:
    // - includeImages: includes thumbnail/poster images in response
    // - count: limit number of items returned per hub (max varies by server)
    // Reference: https://plexapi.dev/api-reference/hubs/get-hubs
    let queryItems = [
        URLQueryItem(name: "includeImages", value: "1"),
        URLQueryItem(name: "count", value: "20"),
        URLQueryItem(name: "includeRelated", value: "1"),
        URLQueryItem(name: "includeExtras", value: "1")
    ]

    let response: PlexResponse<PlexMetadata> = try await request(path: path, queryItems: queryItems)
    let container = response.MediaContainer
    let hubs = container.hub ?? []

    print("📚 [API] Hubs response - size: \(container.size), hubs: \(hubs.count)")
    for hub in hubs {
        print("📚 [API]   Hub: \(hub.title) - metadata count: \(hub.metadata?.count ?? 0)")
    }

    return hubs
}
```

---

## Fix #7: Add Device Name Configuration

**Problem:** Device name is hardcoded, can't differentiate between different Apple TVs

```swift
class PlexAPIClient {
    static let plexProduct = "Plezy tvOS"
    static let plexVersion = "1.0.0"
    static let plexPlatform = "tvOS"
    static let plexDevice = "Apple TV"
    
    private let deviceName: String
    
    init(baseURL: URL, accessToken: String? = nil, deviceName: String? = nil) {
        self.baseURL = baseURL
        self.accessToken = accessToken
        
        // Allow custom device name, defaults to stored value or generated value
        if let name = deviceName {
            self.deviceName = name
        } else {
            self.deviceName = Self.getPersistedDeviceName()
        }
        
        // ... rest of init
    }
    
    private static func getPersistedDeviceName() -> String {
        let key = "com.plezy.device_name"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        
        #if os(tvOS)
        let name = UIDevice.current.name
        #else
        let name = "Apple TV"
        #endif
        
        UserDefaults.standard.set(name, forKey: key)
        return name
    }
    
    private func getDeviceName() -> String {
        deviceName
    }
}
```

---

## Fix #8: Add URLSession Caching

**Problem:** No caching configured, wasting bandwidth

```swift
init(baseURL: URL, accessToken: String? = nil, deviceName: String? = nil) {
    self.baseURL = baseURL
    self.accessToken = accessToken
    
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 120
    
    // Add caching for GET requests
    let cache = URLCache(
        memoryCapacity: 50 * 1024 * 1024,    // 50 MB
        diskCapacity: 200 * 1024 * 1024,     // 200 MB
        diskPath: "com.plezy.cache"
    )
    configuration.urlCache = cache
    configuration.requestCachePolicy = .useProtocolCachePolicy
    
    // Handle network transitions gracefully
    configuration.waitsForConnectivity = true
    
    self.session = URLSession(configuration: configuration)
}
```

---

## Fix #9: Validate Critical Fields

**Problem:** Assumptions about optional fields can cause crashes

```swift
extension PlexMetadata {
    /// Ensures critical fields exist for playback
    var isPlayable: Bool {
        guard let ratingKey = ratingKey, !ratingKey.isEmpty else {
            return false
        }
        guard let media = media, !media.isEmpty else {
            return false
        }
        guard let parts = media.first?.part, !parts.isEmpty else {
            return false
        }
        return true
    }
    
    /// Safely gets the playback path
    func getPlaybackPath() throws -> String {
        guard let media = media?.first else {
            throw PlexAPIError.noData
        }
        guard let part = media.part?.first else {
            throw PlexAPIError.noData
        }
        return part.key
    }
}
```

---

## Fix #10: Add Server Version Detection

**Problem:** No awareness of what features the server supports

```swift
extension PlexAPIClient {
    /// Get server version to check feature support
    func getServerVersion() async throws -> String {
        struct ServerInfo: Decodable {
            let version: String?
        }
        
        let info: ServerInfo = try await request(path: "/")
        return info.version ?? "unknown"
    }
    
    /// Check if server supports advanced search
    func supportsAdvancedSearch() async throws -> Bool {
        let version = try await getServerVersion()
        // Implement version comparison logic
        // Example: 1.32.0+ supports advanced search
        return version.compare("1.32.0", options: .numeric) != .orderedAscending
    }
}
```

---

## Testing Recommendations

```swift
// Test file: PlexAPIClientTests.swift

import XCTest

class PlexAPIClientTests: XCTestCase {
    var client: PlexAPIClient!
    
    override func setUp() {
        super.setUp()
        let testURL = URL(string: "http://localhost:32400")!
        client = PlexAPIClient(baseURL: testURL, accessToken: "test-token")
    }
    
    func testClientIdentifierPersists() {
        let id1 = ClientIdentifierManager.shared.clientIdentifier
        ClientIdentifierManager.shared.reset()
        let id2 = ClientIdentifierManager.shared.clientIdentifier
        XCTAssertNotEqual(id1, id2, "Reset should create new ID")
        
        let id3 = ClientIdentifierManager.shared.clientIdentifier
        XCTAssertEqual(id2, id3, "ID should persist after creation")
    }
    
    func testErrorHandlingFor401() async {
        let noAuthClient = PlexAPIClient(baseURL: URL(string: "http://localhost:32400")!, accessToken: nil)
        // Should throw .unauthorized
    }
    
    func testPlayableValidation() {
        let metadata = PlexMetadata(
            ratingKey: nil,  // Missing ratingKey
            key: "/library/metadata/1",
            // ... other fields
        )
        XCTAssertFalse(metadata.isPlayable)
    }
}
```

