//
//  PlexAuthService.swift
//  Plezy tvOS
//
//  Handles Plex authentication, server discovery, and connection management
//

import Foundation
import SwiftUI
import Combine

class PlexAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: PlexUser?
    @Published var availableServers: [PlexServer] = []
    @Published var selectedServer: PlexServer?
    @Published var currentClient: PlexAPIClient?
    @Published var isLoading = false
    @Published var error: String?

    private var plexToken: String?
    private var pinCheckTask: Task<Void, Never>?

    // MARK: - Authentication

    func setToken(_ token: String) {
        self.plexToken = token
        self.isAuthenticated = true
    }

    @MainActor
    func validateToken() async -> Bool {
        guard let token = plexToken else { return false }

        do {
            let client = PlexAPIClient.createPlexTVClient(token: token)
            let user = try await client.getUser()
            self.currentUser = user
            self.isAuthenticated = true
            return true
        } catch {
            self.plexToken = nil
            self.isAuthenticated = false
            return false
        }
    }

    func logout() {
        plexToken = nil
        currentUser = nil
        selectedServer = nil
        currentClient = nil
        availableServers = []
        isAuthenticated = false

        // Clear stored data
        let storage = StorageService()
        Task {
            await storage.clearAll()
        }
    }

    // MARK: - PIN Authentication

    @MainActor
    func startPinAuth() async -> PlexPin? {
        isLoading = true
        error = nil

        do {
            let client = PlexAPIClient.createPlexTVClient()
            let pin = try await client.createPin()
            isLoading = false
            return pin
        } catch {
            self.error = "Failed to create PIN: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }

    func startPinPolling(pinId: Int, completion: @escaping (Bool) -> Void) {
        pinCheckTask?.cancel()

        pinCheckTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                    let client = PlexAPIClient.createPlexTVClient()
                    let pin = try await client.checkPin(id: pinId)

                    if let token = pin.authToken, !token.isEmpty {
                        self.plexToken = token
                        self.isAuthenticated = true

                        // Load user info
                        let authedClient = PlexAPIClient.createPlexTVClient(token: token)
                        let user = try await authedClient.getUser()
                        self.currentUser = user

                        // Save token
                        await StorageService().savePlexToken(token)

                        completion(true)
                        return
                    }
                } catch {
                    if !Task.isCancelled {
                        print("Pin polling error: \(error)")
                    }
                }
            }
        }
    }

    func cancelPinPolling() {
        pinCheckTask?.cancel()
        pinCheckTask = nil
    }

    // MARK: - Server Discovery

    @MainActor
    func loadServers() async {
        guard let token = plexToken else { return }

        isLoading = true
        error = nil

        do {
            let client = PlexAPIClient.createPlexTVClient(token: token)
            let servers = try await client.getServers()

            // Filter to only owned servers that provide "server"
            let validServers = servers.filter { server in
                server.isOwned && server.provides.contains("server")
            }

            self.availableServers = validServers

            isLoading = false
        } catch {
            self.error = "Failed to load servers: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Server Connection

    @MainActor
    func selectServer(_ server: PlexServer) async {
        isLoading = true
        error = nil

        // Find best connection
        if let bestConnection = await findBestConnection(for: server) {
            guard let url = bestConnection.url else {
                error = "Invalid server URL"
                isLoading = false
                return
            }

            let client = PlexAPIClient(baseURL: url, accessToken: server.accessToken ?? plexToken)
            self.currentClient = client
            self.selectedServer = server

            // Save selected server
            await StorageService().saveSelectedServer(server)

            isLoading = false
        } else {
            error = "Could not connect to server"
            isLoading = false
        }
    }

    func selectServer(from data: Data) {
        guard let server = try? JSONDecoder().decode(PlexServer.self, from: data) else {
            return
        }

        Task {
            await selectServer(server)
        }
    }

    private func findBestConnection(for server: PlexServer) async -> PlexConnection? {
        // Sort connections: HTTPS > HTTP, Local > Remote > Relay
        let sortedConnections = server.connections.sorted { conn1, conn2 in
            // Prefer HTTPS
            if conn1.protocol == "https" && conn2.protocol != "https" { return true }
            if conn1.protocol != "https" && conn2.protocol == "https" { return false }

            // Then prefer by connection type
            return conn1.connectionType < conn2.connectionType
        }

        // Test each connection
        for connection in sortedConnections {
            if await testConnection(connection, token: server.accessToken ?? plexToken) {
                print("✅ Connected via \(connection.uri) (\(connection.connectionType))")
                return connection
            }
        }

        return nil
    }

    private func testConnection(_ connection: PlexConnection, token: String?) async -> Bool {
        guard let url = connection.url else { return false }

        do {
            let client = PlexAPIClient(baseURL: url, accessToken: token)
            _ = try await client.getLibraries()
            return true
        } catch {
            print("❌ Connection failed: \(connection.uri) - \(error)")
            return false
        }
    }

    // MARK: - Home Users

    func loadHomeUsers() async -> [PlexHomeUser] {
        guard let token = plexToken else { return [] }

        do {
            let client = PlexAPIClient.createPlexTVClient(token: token)
            return try await client.getHomeUsers()
        } catch {
            print("Failed to load home users: \(error)")
            return []
        }
    }

    @MainActor
    func switchUser(to user: PlexHomeUser, pin: String?) async -> Bool {
        guard let token = plexToken else { return false }

        do {
            let client = PlexAPIClient.createPlexTVClient(token: token)
            let newToken = try await client.switchHomeUser(userId: user.id, pin: pin)

            self.plexToken = newToken
            await StorageService().savePlexToken(newToken)

            // Reload servers with new token
            await loadServers()

            return true
        } catch {
            self.error = "Failed to switch user: \(error.localizedDescription)"
            return false
        }
    }
}
