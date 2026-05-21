import Foundation

actor PlexAuthService {
    private let session: URLSession
    private let clientIdentifier: String
    private let plexTVBaseURL = "https://plex.tv/api/v2"
    private let plexClientsURL = "https://clients.plex.tv/api/v2"

    struct PinResponse {
        let pinId: Int
        let code: String
    }

    /// Maximum response size (10 MB) to prevent memory exhaustion.
    private static let maxResponseSize = 10 * 1024 * 1024

    init(clientIdentifier: String, session: URLSession = .shared) {
        self.clientIdentifier = clientIdentifier
        self.session = session
    }

    private var commonHeaders: [String: String] {
        [
            "X-Plex-Product": "Vibe",
            "X-Plex-Client-Identifier": clientIdentifier,
            "X-Plex-Platform": "tvOS",
            "X-Plex-Device": "Apple TV",
            "Accept": "application/json"
        ]
    }

    // MARK: - PIN Auth Flow

    func createPin() async throws -> PinResponse {
        var request = URLRequest(url: URL(string: "\(plexTVBaseURL)/pins")!)
        request.httpMethod = "POST"
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, _) = try await session.data(for: request)
        guard data.count <= Self.maxResponseSize else { throw PlexAuthError.invalidPinResponse }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let pinId = json["id"] as? Int,
              let code = json["code"] as? String else {
            throw PlexAuthError.invalidPinResponse
        }

        return PinResponse(pinId: pinId, code: code)
    }

    func checkPin(pinId: Int) async throws -> String? {
        var request = URLRequest(url: URL(string: "\(plexTVBaseURL)/pins/\(pinId)")!)
        request.httpMethod = "GET"
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, _) = try await session.data(for: request)
        guard data.count <= Self.maxResponseSize else { throw PlexAuthError.invalidPinResponse }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        let authToken = json["authToken"] as? String
        return authToken?.isEmpty == false ? authToken : nil
    }

    func pollPinUntilClaimed(pinId: Int, timeout: TimeInterval = 300, interval: TimeInterval = 2) async throws -> String {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if let token = try await checkPin(pinId: pinId) {
                return token
            }
            try await Task.sleep(for: .seconds(interval))
        }

        throw PlexAuthError.pinTimeout
    }

    // MARK: - Token Verification

    func verifyToken(_ token: String) async throws -> Bool {
        var request = URLRequest(url: URL(string: "\(plexTVBaseURL)/user")!)
        request.httpMethod = "GET"
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (_, response) = try await session.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    // MARK: - Server Discovery

    func fetchServers(token: String) async throws -> [PlexServer] {
        var request = URLRequest(url: URL(string: "\(plexClientsURL)/resources?includeHttps=1&includeRelay=1&includeIPv6=1")!)
        request.httpMethod = "GET"
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (data, _) = try await session.data(for: request)
        guard data.count <= Self.maxResponseSize else { throw PlexAuthError.noServersFound }
        let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []

        return jsonArray.compactMap { serverJson -> PlexServer? in
            guard let name = serverJson["name"] as? String,
                  let clientIdentifier = serverJson["clientIdentifier"] as? String,
                  let provides = serverJson["provides"] as? String,
                  provides.contains("server") else {
                return nil
            }

            let connectionsJson = serverJson["connections"] as? [[String: Any]] ?? []
            let connections = connectionsJson.compactMap { connJson -> PlexConnection? in
                guard let uri = connJson["uri"] as? String else { return nil }
                return PlexConnection(
                    uri: uri,
                    protocol: connJson["protocol"] as? String,
                    address: connJson["address"] as? String,
                    port: connJson["port"] as? Int,
                    local: connJson["local"] as? Bool,
                    relay: connJson["relay"] as? Bool
                )
            }

            guard !connections.isEmpty else { return nil }

            return PlexServer(
                name: name,
                clientIdentifier: clientIdentifier,
                connections: connections,
                activeConnectionUri: nil,
                owned: serverJson["owned"] as? Bool,
                sourceTitle: serverJson["sourceTitle"] as? String,
                accessToken: serverJson["accessToken"] as? String,
                machineIdentifier: serverJson["clientIdentifier"] as? String
            )
        }
    }

    // MARK: - User Info

    func getUserInfo(token: String) async throws -> PlexUser {
        var request = URLRequest(url: URL(string: "\(plexTVBaseURL)/user")!)
        request.httpMethod = "GET"
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (data, _) = try await session.data(for: request)
        guard data.count <= Self.maxResponseSize else { throw PlexAuthError.switchUserFailed }
        return try JSONDecoder().decode(PlexUser.self, from: data)
    }

    // MARK: - Home Users

    func getHomeUsers(token: String) async throws -> [PlexHomeUser] {
        var request = URLRequest(url: URL(string: "\(plexClientsURL)/home/users")!)
        request.httpMethod = "GET"
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (data, _) = try await session.data(for: request)
        guard data.count <= Self.maxResponseSize else { return [] }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let usersJson = json["users"] as? [[String: Any]] else { return [] }

        let usersData = try JSONSerialization.data(withJSONObject: usersJson)
        return try JSONDecoder().decode([PlexHomeUser].self, from: usersData)
    }

    func switchToUser(uuid: String, pin: String?, token: String) async throws -> String {
        var urlString = "\(plexClientsURL)/home/users/\(uuid)/switch"
        if let pin {
            urlString += "?pin=\(pin)"
        }
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (data, _) = try await session.data(for: request)
        guard data.count <= Self.maxResponseSize else { throw PlexAuthError.switchUserFailed }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let newToken = json["authToken"] as? String, !newToken.isEmpty else {
            throw PlexAuthError.switchUserFailed
        }
        return newToken
    }

    // MARK: - Connection Testing

    func findBestConnection(for server: PlexServer, token: String) async -> PlexConnection? {
        // Sort: local first, then remote, then relay
        let sorted = server.connections.sorted { a, b in
            if a.local == true && b.local != true { return true }
            if a.relay == true && b.relay != true { return false }
            return false
        }

        // First pass: try connections as-is
        for connection in sorted {
            if await testConnection(uri: connection.uri, token: token) {
                return connection
            }
        }

        // Second pass: for non-local connections with explicit ports,
        // try without the port (handles reverse proxy setups on port 443)
        for connection in sorted where connection.local != true {
            guard var components = URLComponents(string: connection.uri),
                  components.port != nil else { continue }
            // Skip plex.direct addresses (they need the port)
            if components.host?.contains("plex.direct") == true { continue }
            components.port = nil
            if let altUri = components.string,
               await testConnection(uri: altUri, token: token) {
                // Return a modified connection with the working URI
                return PlexConnection(
                    uri: altUri,
                    protocol: connection.protocol,
                    address: connection.address,
                    port: nil,
                    local: connection.local,
                    relay: connection.relay
                )
            }
        }

        return nil
    }

    func testConnection(uri: String, token: String) async -> Bool {
        guard let url = URL(string: "\(uri)/identity") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

enum PlexAuthError: LocalizedError {
    case invalidPinResponse
    case pinTimeout
    case switchUserFailed
    case noServersFound
    case noConnectionAvailable

    var errorDescription: String? {
        switch self {
        case .invalidPinResponse: return "Invalid PIN response from Plex"
        case .pinTimeout: return "PIN authentication timed out"
        case .switchUserFailed: return "Failed to switch user"
        case .noServersFound: return "No Plex servers found"
        case .noConnectionAvailable: return "Could not connect to server"
        }
    }
}
