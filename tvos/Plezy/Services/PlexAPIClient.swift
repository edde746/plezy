//
//  PlexAPIClient.swift
//  Plezy tvOS
//
//  Plex API HTTP client
//

import Foundation
import Combine

class PlexAPIClient {
    private let baseURL: URL
    private let accessToken: String?
    private let session: URLSession

    // Plex.tv API constants
    static let plexTVURL = "https://plex.tv"
    static let plexClientIdentifier: String = {
        let key = "PlexClientIdentifier"
        if let stored = UserDefaults.standard.string(forKey: key) {
            return stored
        } else {
            let newIdentifier = UUID().uuidString
            UserDefaults.standard.set(newIdentifier, forKey: key)
            return newIdentifier
        }
    }()
    static let plexProduct = "Plezy tvOS"
    static let plexVersion = "1.0.0"
    static let plexPlatform = "tvOS"
    static let plexDevice = "Apple TV"

    // Standard Plex headers
    private var headers: [String: String] {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-Plex-Product": Self.plexProduct,
            "X-Plex-Version": Self.plexVersion,
            "X-Plex-Client-Identifier": Self.plexClientIdentifier,
            "X-Plex-Platform": Self.plexPlatform,
            "X-Plex-Platform-Version": self.getSystemVersion(),
            "X-Plex-Device": Self.plexDevice,
            "X-Plex-Device-Name": self.getDeviceName()
        ]

        if let token = accessToken {
            headers["X-Plex-Token"] = token
        }

        return headers
    }

    init(baseURL: URL, accessToken: String? = nil) {
        self.baseURL = baseURL
        self.accessToken = accessToken

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Generic Request Methods

    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil,
        retries: Int = 3
    ) async throws -> T {
        // Validate authentication for server endpoints (not plex.tv public endpoints)
        let requiresAuth = !path.hasPrefix("/api/v2/pins") && baseURL.host != "plex.tv"
        if requiresAuth && accessToken == nil {
            print("❌ [API] Unauthorized request to \(path) - no access token")
            throw PlexAPIError.unauthorized
        }

        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            throw PlexAPIError.invalidURL
        }

        var lastError: Error?

        for attempt in 0..<retries {
            if attempt > 0 {
                let delay = min(pow(2.0, Double(attempt)), 16.0) // Cap at 16 seconds
                print("🔄 [API] Retry attempt \(attempt + 1)/\(retries) after \(delay)s delay")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            print("🌐 [API] \(method) \(url) (attempt \(attempt + 1)/\(retries))")

            var request = URLRequest(url: url)
            request.httpMethod = method
            request.httpBody = body

            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw PlexAPIError.invalidResponse
                }

                print("🌐 [API] Response: \(httpResponse.statusCode) - \(data.count) bytes")

                guard (200...299).contains(httpResponse.statusCode) else {
                    // Provide specific error messages for common HTTP status codes
                    switch httpResponse.statusCode {
                    case 401:
                        print("❌ [API] Unauthorized - invalid or expired token")
                        throw PlexAPIError.unauthorized
                    case 404:
                        print("❌ [API] Not found - resource doesn't exist")
                        throw PlexAPIError.notFound
                    case 429:
                        print("❌ [API] Rate limited - too many requests")
                        throw PlexAPIError.rateLimited
                    case 500...599:
                        print("❌ [API] Server error (\(httpResponse.statusCode))")
                        throw PlexAPIError.serverError(statusCode: httpResponse.statusCode)
                    default:
                        print("❌ [API] HTTP error \(httpResponse.statusCode)")
                        throw PlexAPIError.httpError(statusCode: httpResponse.statusCode)
                    }
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .useDefaultKeys

                do {
                    // Debug: Print first 500 characters of response for inspection
                    if let jsonString = String(data: data, encoding: .utf8) {
                        let preview = String(jsonString.prefix(500))
                        print("🔍 [API] Response preview: \(preview)")
                    }
                    let result = try decoder.decode(T.self, from: data)
                    print("✅ [API] Request successful on attempt \(attempt + 1)")
                    return result
                } catch {
                    print("🔴 [API] Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        let preview = String(jsonString.prefix(1000))
                        print("🔴 [API] Failed JSON preview: \(preview)")
                    }
                    throw PlexAPIError.decodingError(error)
                }
            } catch {
                lastError = error
                print("⚠️ [API] Attempt \(attempt + 1)/\(retries) failed: \(error.localizedDescription)")

                // Don't retry on certain errors - they won't succeed on retry
                if let apiError = error as? PlexAPIError {
                    switch apiError {
                    case .unauthorized, .notFound, .decodingError:
                        print("❌ [API] Non-retryable error, failing immediately")
                        throw apiError
                    default:
                        break
                    }
                }

                // If this was the last attempt, don't sleep
                if attempt == retries - 1 {
                    print("❌ [API] All retry attempts exhausted")
                }
            }
        }

        // All retries exhausted, throw the last error
        throw lastError ?? PlexAPIError.serverNotReachable
    }

    // MARK: - Library Methods

    func getLibraries() async throws -> [PlexLibrary] {
        let response: PlexResponse<PlexLibrary> = try await request(path: "/library/sections")
        return response.MediaContainer.items
    }

    func getLibraryContent(
        sectionKey: String,
        start: Int = 0,
        size: Int = 50,
        sort: String? = nil,
        unwatched: Bool? = nil
    ) async throws -> [PlexMetadata] {
        var queryItems = [
            URLQueryItem(name: "X-Plex-Container-Start", value: "\(start)"),
            URLQueryItem(name: "X-Plex-Container-Size", value: "\(size)")
        ]

        // Add sort parameter if provided
        // Common values: "addedAt:desc", "titleSort:asc", "year:desc", "rating:desc"
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }

        // Add unwatched filter if provided
        if let unwatched = unwatched, unwatched {
            queryItems.append(URLQueryItem(name: "unwatched", value: "1"))
        }

        let response: PlexResponse<PlexMetadata> = try await request(
            path: "/library/sections/\(sectionKey)/all",
            queryItems: queryItems
        )
        return response.MediaContainer.items
    }

    func getMetadata(ratingKey: String) async throws -> PlexMetadata {
        // Include all necessary data for playback
        // Based on official Plex API docs: https://plexapi.dev/api-reference/library/get-metadata-by-ratingkey
        let queryItems = [
            URLQueryItem(name: "includeChapters", value: "1"),
            URLQueryItem(name: "includeExtras", value: "0"),
            URLQueryItem(name: "includeImages", value: "1")
        ]
        print("📡 [API] getMetadata for ratingKey: \(ratingKey)")
        let response: PlexResponse<PlexMetadata> = try await request(
            path: "/library/metadata/\(ratingKey)",
            queryItems: queryItems
        )
        print("📡 [API] Metadata response - items count: \(response.MediaContainer.items.count)")
        guard let metadata = response.MediaContainer.items.first else {
            throw PlexAPIError.noData
        }
        print("📡 [API] First metadata item - type: \(metadata.type ?? "unknown"), title: \(metadata.title)")
        print("📡 [API] Metadata has media array: \(metadata.media != nil), count: \(metadata.media?.count ?? 0)")
        return metadata
    }

    func getChildren(ratingKey: String) async throws -> [PlexMetadata] {
        let response: PlexResponse<PlexMetadata> = try await request(path: "/library/metadata/\(ratingKey)/children")
        return response.MediaContainer.items
    }

    func getOnDeck() async throws -> [PlexMetadata] {
        print("📚 [API] Requesting OnDeck from /library/onDeck")
        let queryItems = [
            URLQueryItem(name: "includeImages", value: "1"),
            URLQueryItem(name: "includeExtras", value: "1"),
            URLQueryItem(name: "includeCollections", value: "1")
        ]
        let response: PlexResponse<PlexMetadata> = try await request(
            path: "/library/onDeck",
            queryItems: queryItems
        )
        let container = response.MediaContainer
        print("📚 [API] OnDeck response - size: \(container.size), items: \(container.items.count)")

        // Debug: Check which items have clearLogos in the initial response
        for item in container.items {
            let hasLogo = item.clearLogo != nil
            print("📚 [API] Item '\(item.title)' (type: \(item.type ?? "unknown")) - has clearLogo: \(hasLogo)")
        }

        // Enrich episodes with show logos
        // The onDeck endpoint returns episode metadata, but clearLogos belong to the show (grandparent) level.
        // For episodes without clearLogos, we fetch the show metadata to get the show's logo.
        // This ensures logos display correctly in the Continue Watching row.
        var enrichedItems = container.items
        var showLogoCache: [String: String?] = [:] // Cache show logos by grandparentRatingKey to avoid duplicate API calls

        for (index, item) in enrichedItems.enumerated() {
            // For episodes: fetch show (grandparent) metadata to get the show's logo
            if item.type == "episode" && item.clearLogo == nil, let grandparentKey = item.grandparentRatingKey {
                // Check cache first to avoid duplicate API calls for the same show
                if let cachedLogo = showLogoCache[grandparentKey] {
                    if let logo = cachedLogo {
                        print("📚 [API] Using cached clearLogo for episode: \(item.title)")
                        var updatedItem = item
                        let logoImage = PlexImage(type: "clearLogo", url: logo)
                        updatedItem.Image = (item.Image ?? []) + [logoImage]
                        enrichedItems[index] = updatedItem
                    }
                } else {
                    print("📚 [API] Episode \(item.title) missing clearLogo, fetching show metadata from ratingKey: \(grandparentKey)")
                    do {
                        let showMetadata = try await getMetadata(ratingKey: grandparentKey)
                        showLogoCache[grandparentKey] = showMetadata.clearLogo

                        if let showLogo = showMetadata.clearLogo {
                            print("📚 [API] Found clearLogo for show: \(showMetadata.title)")
                            var updatedItem = item
                            let logoImage = PlexImage(type: "clearLogo", url: showLogo)
                            updatedItem.Image = (item.Image ?? []) + [logoImage]
                            enrichedItems[index] = updatedItem
                        } else {
                            print("📚 [API] Show \(showMetadata.title) has no clearLogo")
                        }
                    } catch {
                        print("📚 [API] Failed to fetch show metadata: \(error)")
                        showLogoCache[grandparentKey] = nil // Cache the failure
                    }
                }
            }

            // For movies: fetch movie metadata if clearLogo is missing
            else if item.type == "movie" && item.clearLogo == nil, let ratingKey = item.ratingKey {
                print("📚 [API] Movie '\(item.title)' missing clearLogo, fetching full metadata from ratingKey: \(ratingKey)")
                do {
                    let movieMetadata = try await getMetadata(ratingKey: ratingKey)
                    if let movieLogo = movieMetadata.clearLogo {
                        print("📚 [API] Found clearLogo for movie: \(movieMetadata.title)")
                        var updatedItem = item
                        let logoImage = PlexImage(type: "clearLogo", url: movieLogo)
                        updatedItem.Image = (item.Image ?? []) + [logoImage]
                        enrichedItems[index] = updatedItem
                    } else {
                        print("📚 [API] Movie \(movieMetadata.title) has no clearLogo available")
                    }
                } catch {
                    print("📚 [API] Failed to fetch movie metadata: \(error)")
                }
            }
        }

        return enrichedItems
    }

    func getRecentlyAdded(sectionKey: String? = nil) async throws -> [PlexMetadata] {
        let path = sectionKey != nil ? "/library/sections/\(sectionKey!)/recentlyAdded" : "/library/recentlyAdded"
        let response: PlexResponse<PlexMetadata> = try await request(path: path)
        return response.MediaContainer.items
    }

    // MARK: - Hub Methods (Content Discovery)

    func getHubs(sectionKey: String? = nil) async throws -> [PlexHub] {
        let path = sectionKey != nil ? "/hubs/sections/\(sectionKey!)" : "/hubs"
        print("📚 [API] Requesting Hubs from \(path)")

        // Include metadata and images in the response
        let queryItems = [
            URLQueryItem(name: "includeImages", value: "1"),
            URLQueryItem(name: "count", value: "20")
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

    func getHubContent(hubKey: String) async throws -> [PlexMetadata] {
        let response: PlexResponse<PlexMetadata> = try await request(path: hubKey)
        return response.MediaContainer.items
    }

    // MARK: - Search

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

    // MARK: - Playback & Progress

    func getMediaInfo(ratingKey: String) async throws -> PlexMetadata {
        try await getMetadata(ratingKey: ratingKey)
    }

    func updateTimeline(ratingKey: String, state: PlaybackState, time: Int, duration: Int) async throws {
        let queryItems = [
            URLQueryItem(name: "ratingKey", value: ratingKey),
            URLQueryItem(name: "state", value: state.rawValue),
            URLQueryItem(name: "time", value: "\(time)"),
            URLQueryItem(name: "duration", value: "\(duration)")
        ]
        let _: PlexMediaContainer<PlexMetadata> = try await request(
            path: "/:/timeline",
            queryItems: queryItems
        )
    }

    func scrobble(ratingKey: String) async throws {
        let queryItems = [
            URLQueryItem(name: "identifier", value: "com.plexapp.plugins.library"),
            URLQueryItem(name: "key", value: ratingKey)
        ]
        let _: PlexMediaContainer<PlexMetadata> = try await request(
            path: "/:/scrobble",
            queryItems: queryItems
        )
    }

    func unscrobble(ratingKey: String) async throws {
        let queryItems = [
            URLQueryItem(name: "identifier", value: "com.plexapp.plugins.library"),
            URLQueryItem(name: "key", value: ratingKey)
        ]
        let _: PlexMediaContainer<PlexMetadata> = try await request(
            path: "/:/unscrobble",
            queryItems: queryItems
        )
    }

    // MARK: - Chapters

    func getChapters(ratingKey: String) async throws -> [PlexChapter] {
        struct ChapterContainer: Codable {
            let chapters: [PlexChapter]?
        }
        let container: ChapterContainer = try await request(path: "/library/metadata/\(ratingKey)/chapters")
        return container.chapters ?? []
    }

    enum PlaybackState: String {
        case playing
        case paused
        case stopped
    }
}

// MARK: - Plex.tv API Client

extension PlexAPIClient {
    static func createPlexTVClient(token: String? = nil) -> PlexAPIClient {
        PlexAPIClient(baseURL: URL(string: plexTVURL)!, accessToken: token)
    }

    // MARK: - PIN Authentication

    func createPin() async throws -> PlexPin {
        struct PinRequest: Encodable {
            let strong: Bool = false
        }

        struct PinResponse: Decodable {
            let id: Int
            let code: String
        }

        let body = try JSONEncoder().encode(PinRequest())
        let response: PinResponse = try await request(
            path: "/api/v2/pins",
            method: "POST",
            body: body
        )

        return PlexPin(id: response.id, code: response.code, authToken: nil)
    }

    func checkPin(id: Int) async throws -> PlexPin {
        struct PinResponse: Decodable {
            let id: Int
            let code: String
            let authToken: String?
        }

        let response: PinResponse = try await request(path: "/api/v2/pins/\(id)")
        return PlexPin(id: response.id, code: response.code, authToken: response.authToken)
    }

    func getUser() async throws -> PlexUser {
        struct UserResponse: Decodable {
            let id: Int
            let uuid: String
            let username: String
            let title: String
            let email: String?
            let thumb: String?
        }

        let response: UserResponse = try await request(path: "/api/v2/user")
        return PlexUser(
            id: response.id,
            uuid: response.uuid,
            username: response.username,
            title: response.title,
            email: response.email,
            thumb: response.thumb,
            authToken: accessToken
        )
    }

    // MARK: - Server Discovery

    func getServers() async throws -> [PlexServer] {
        // The /api/v2/resources endpoint returns servers with query parameters
        let queryItems = [
            URLQueryItem(name: "includeHttps", value: "1"),
            URLQueryItem(name: "includeRelay", value: "1")
        ]

        let servers: [PlexServer] = try await request(
            path: "/api/v2/resources",
            queryItems: queryItems
        )
        return servers
    }

    // MARK: - Home Users

    func getHomeUsers() async throws -> [PlexHomeUser] {
        struct UsersResponse: Decodable {
            let users: [PlexHomeUser]

            enum CodingKeys: String, CodingKey {
                case users = "users"
            }
        }

        let response: UsersResponse = try await request(path: "/api/v2/home/users")
        return response.users
    }

    func switchHomeUser(userId: Int, pin: String?) async throws -> String {
        struct SwitchRequest: Encodable {
            let pin: String?
        }

        struct SwitchResponse: Decodable {
            let authToken: String
        }

        let body = try JSONEncoder().encode(SwitchRequest(pin: pin))
        let response: SwitchResponse = try await request(
            path: "/api/v2/home/users/\(userId)/switch",
            method: "POST",
            body: body
        )

        return response.authToken
    }

    // MARK: - Device Information Helpers

    private func getSystemVersion() -> String {
        #if os(tvOS)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return "Unknown"
        #endif
    }

    private func getDeviceName() -> String {
        #if os(tvOS)
        // tvOS doesn't have UIDevice.current.name
        return "Apple TV"
        #else
        return "Unknown Device"
        #endif
    }
}

// MARK: - Errors

enum PlexAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noData
    case unauthorized
    case notFound
    case rateLimited
    case serverError(statusCode: Int)
    case serverNotReachable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .unauthorized:
            return "Session expired. Please sign in again"
        case .notFound:
            return "Content not found on server"
        case .rateLimited:
            return "Too many requests. Please wait a moment"
        case .serverError(let code):
            return "Server error (\(code)). Please try again later"
        case .serverNotReachable:
            return "Server not reachable"
        }
    }
}
