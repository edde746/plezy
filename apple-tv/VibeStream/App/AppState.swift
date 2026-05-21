import Foundation
import Observation
import TVServices

@Observable
final class AppState {
    var authToken: String?
    var activeServer: PlexServer?
    var activeUser: PlexUser?
    var isAuthenticated: Bool { authToken != nil && activeServer != nil }
    var serverToken: String { activeServer?.accessToken ?? authToken ?? "" }
    var isLoading = false
    var errorMessage: String?

    // Deep linking
    enum DeepLinkAction: Equatable {
        case play(ratingKey: String)
        case detail(ratingKey: String)
    }
    var deepLinkAction: DeepLinkAction?


    private let tokenKey = "plex_auth_token"
    private let serverKey = "plex_active_server"
    private let userKey = "plex_active_user"
    private let clientIdentifierKey = "plex_client_identifier"

    var clientIdentifier: String {
        if let existing = UserDefaults.standard.string(forKey: clientIdentifierKey) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: clientIdentifierKey)
        return newId
    }

    init() {
        migrateFromUserDefaultsIfNeeded()
        loadPersistedState()
    }

    /// One-time migration from UserDefaults (plaintext) to Keychain (encrypted).
    private func migrateFromUserDefaultsIfNeeded() {
        let migrated = UserDefaults.standard.bool(forKey: "keychain_migrated")
        guard !migrated else { return }

        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            KeychainService.save(token, for: tokenKey)
            UserDefaults.standard.removeObject(forKey: tokenKey)
        }
        if let serverData = UserDefaults.standard.data(forKey: serverKey) {
            KeychainService.save(serverData, for: serverKey)
            UserDefaults.standard.removeObject(forKey: serverKey)
        }
        if let userData = UserDefaults.standard.data(forKey: userKey) {
            KeychainService.save(userData, for: userKey)
            UserDefaults.standard.removeObject(forKey: userKey)
        }

        UserDefaults.standard.set(true, forKey: "keychain_migrated")
    }

    func loadPersistedState() {
        authToken = KeychainService.loadString(for: tokenKey)
        if let serverData = KeychainService.loadData(for: serverKey) {
            activeServer = try? JSONDecoder().decode(PlexServer.self, from: serverData)
        }
        if let userData = KeychainService.loadData(for: userKey) {
            activeUser = try? JSONDecoder().decode(PlexUser.self, from: userData)
        }
        syncToSharedDefaults()
    }

    func setAuthenticated(token: String, server: PlexServer, user: PlexUser?) {
        authToken = token
        activeServer = server
        activeUser = user
        KeychainService.save(token, for: tokenKey)
        if let serverData = try? JSONEncoder().encode(server) {
            KeychainService.save(serverData, for: serverKey)
        }
        if let user, let userData = try? JSONEncoder().encode(user) {
            KeychainService.save(userData, for: userKey)
        }
        syncToSharedDefaults()
    }

    func updateServer(_ server: PlexServer) {
        activeServer = server
        if let serverData = try? JSONEncoder().encode(server) {
            KeychainService.save(serverData, for: serverKey)
        }
        syncToSharedDefaults()
    }

    func updateUser(_ user: PlexUser) {
        activeUser = user
        if let userData = try? JSONEncoder().encode(user) {
            KeychainService.save(userData, for: userKey)
        }
    }

    var connectionStatus: ConnectionStatus = .connected
    var libraries: [PlexLibrary] = []

    /// Fetch available libraries from the active server.
    func loadLibraries() async {
        guard let server = activeServer, let token = authToken else { return }
        let client = PlexClient(
            baseURL: server.baseURL,
            token: server.accessToken ?? token,
            clientIdentifier: clientIdentifier,
            serverId: server.clientIdentifier,
            serverName: server.name
        )
        libraries = (try? await client.getLibraries()) ?? []
    }

    enum ConnectionStatus: Equatable {
        case connected
        case checking
        case reconnecting
        case failed
    }

    func signOut() {
        authToken = nil
        activeServer = nil
        activeUser = nil
        KeychainService.delete(for: tokenKey)
        KeychainService.delete(for: serverKey)
        KeychainService.delete(for: userKey)
        syncToSharedDefaults()
    }

    /// Sync connection info to App Group UserDefaults so the Top Shelf extension can access it.
    private func syncToSharedDefaults() {
        let defaults = UserDefaults(suiteName: "group.com.amaze.vibestream")
        if let server = activeServer, let token = authToken {
            defaults?.set(server.baseURL, forKey: "topshelf_server_url")
            defaults?.set(server.accessToken ?? token, forKey: "topshelf_token")
            defaults?.set(clientIdentifier, forKey: "topshelf_client_identifier")
            defaults?.set(server.clientIdentifier, forKey: "topshelf_server_id")
            defaults?.set(server.name, forKey: "topshelf_server_name")
        } else {
            defaults?.removeObject(forKey: "topshelf_server_url")
            defaults?.removeObject(forKey: "topshelf_token")
            defaults?.removeObject(forKey: "topshelf_client_identifier")
            defaults?.removeObject(forKey: "topshelf_server_id")
            defaults?.removeObject(forKey: "topshelf_server_name")
        }
        TVTopShelfContentProvider.topShelfContentDidChange()
    }

    func validateConnection() async {
        guard let server = activeServer, let token = authToken else { return }
        let serverToken = server.accessToken ?? token

        connectionStatus = .checking
        let authService = PlexAuthService(clientIdentifier: clientIdentifier)

        // Test the current active connection
        if await authService.testConnection(uri: server.baseURL, token: serverToken) {
            connectionStatus = .connected
            await loadLibraries()
            return
        }

        // Current connection failed — try to find a new one
        connectionStatus = .reconnecting
        if let best = await authService.findBestConnection(for: server, token: serverToken) {
            var updatedServer = server
            updatedServer.activeConnectionUri = best.uri
            updateServer(updatedServer)
            connectionStatus = .connected
            await loadLibraries()
        } else {
            connectionStatus = .failed
        }
    }
}
