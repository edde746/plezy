import Foundation

actor ServerDiscovery {
    private let authService: PlexAuthService

    init(authService: PlexAuthService) {
        self.authService = authService
    }

    struct ServerConnectionResult {
        let server: PlexServer
        let latencyMs: Int
    }

    func discoverServers(token: String) async throws -> [PlexServer] {
        let servers = try await authService.fetchServers(token: token)

        // Test connections and find best URI for each server
        var connectedServers: [PlexServer] = []
        for var server in servers {
            if let bestConnection = await authService.findBestConnection(for: server, token: token) {
                server.activeConnectionUri = bestConnection.uri
                connectedServers.append(server)
            }
        }

        return connectedServers
    }

    func testConnectionLatency(baseURL: String, token: String) async -> Int? {
        let start = Date()
        let success = await authService.testConnection(uri: baseURL, token: token)
        guard success else { return nil }
        return Int(Date().timeIntervalSince(start) * 1000)
    }
}
