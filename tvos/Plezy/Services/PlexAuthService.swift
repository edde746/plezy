//
//  PlexAuthService.swift
//  Beacon tvOS
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
        print("🔑 [PIN] Starting PIN polling for ID: \(pinId)")
        pinCheckTask?.cancel()

        pinCheckTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    print("🔑 [PIN] Checking PIN status...")

                    let client = PlexAPIClient.createPlexTVClient()
                    let pin = try await client.checkPin(id: pinId)

                    if let token = pin.authToken, !token.isEmpty {
                        print("🔑 [PIN] ✅ PIN authenticated! Token received")

                        // Load user info
                        let authedClient = PlexAPIClient.createPlexTVClient(token: token)
                        let user = try await authedClient.getUser()
                        print("🔑 [PIN] User info loaded: \(user.username)")

                        // Save token
                        await StorageService().savePlexToken(token)
                        print("🔑 [PIN] Token saved to storage")

                        // Update @Published properties on the main actor
                        await MainActor.run {
                            self.plexToken = token
                            self.isAuthenticated = true
                            self.currentUser = user
                            print("🔑 [PIN] Set isAuthenticated = true")
                        }

                        // Call completion handler on the main actor
                        await MainActor.run {
                            completion(true)
                        }
                        return
                    }
                } catch {
                    if !Task.isCancelled {
                        print("🔴 [PIN] Pin polling error: \(error)")
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
        print("🟢 [PlexAuth] selectServer called for: \(server.name)")
        print("🟢 [PlexAuth] Server has \(server.connections.count) connections")
        isLoading = true
        error = nil

        // Find best connection and get working URL
        print("🟢 [PlexAuth] Starting findBestConnection...")
        if let (bestConnection, workingURL) = await findBestConnectionWithURL(for: server) {
            print("🟢 [PlexAuth] Best connection found: \(bestConnection.uri)")
            print("🟢 [PlexAuth] Working URL: \(workingURL)")

            print("🟢 [PlexAuth] Creating client with URL: \(workingURL)")
            let client = PlexAPIClient(baseURL: workingURL, accessToken: server.accessToken ?? plexToken)
            self.currentClient = client
            self.selectedServer = server
            print("🟢 [PlexAuth] Client and server set successfully")

            // Save selected server
            await StorageService().saveSelectedServer(server)
            print("🟢 [PlexAuth] Server saved to storage")

            isLoading = false
            print("🟢 [PlexAuth] selectServer completed successfully")
        } else {
            print("🔴 [PlexAuth] Could not find working connection")
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

    private func findBestConnectionWithURL(for server: PlexServer) async -> (PlexConnection, URL)? {
        print("🟡 [findBestConnection] Starting with \(server.connections.count) connections")
        // Sort connections: HTTPS > HTTP, Local > Remote > Relay
        let sortedConnections = server.connections.sorted { conn1, conn2 in
            // Prefer HTTPS
            if conn1.protocol == "https" && conn2.protocol != "https" { return true }
            if conn1.protocol != "https" && conn2.protocol == "https" { return false }

            // Then prefer by connection type
            return conn1.connectionType < conn2.connectionType
        }

        print("🟡 [findBestConnection] Sorted connections:")
        for (index, conn) in sortedConnections.enumerated() {
            print("  [\(index)] \(conn.protocol)://\(conn.address):\(conn.port) (local: \(conn.local), relay: \(conn.relay))")
        }

        // Test each connection
        for (index, connection) in sortedConnections.enumerated() {
            print("🟡 [findBestConnection] Testing connection [\(index)]: \(connection.uri)")
            if let workingURL = await testConnectionAndGetURL(connection, token: server.accessToken ?? plexToken) {
                print("🟢 [findBestConnection] Connection [\(index)] succeeded!")
                return (connection, workingURL)
            }
            print("🔴 [findBestConnection] Connection [\(index)] failed")
        }

        print("🔴 [findBestConnection] All connections failed")
        return nil
    }

    private func findBestConnection(for server: PlexServer) async -> PlexConnection? {
        let result = await findBestConnectionWithURL(for: server)
        return result?.0
    }

    private func testConnectionAndGetURL(_ connection: PlexConnection, token: String?) async -> URL? {
        print("🔵 [testConnection] Starting test for: \(connection.uri)")

        // Try .plex.direct URL first (secure DNS)
        if let url = connection.url {
            if await tryURL(url, token: token, label: "Plex.direct") {
                return url
            }
        }

        // Fallback to direct IP address if .plex.direct fails (DNS issues)
        if let directURL = connection.directURL {
            print("⚠️ [testConnection] Plex.direct failed, trying direct IP: \(directURL)")
            if await tryURL(directURL, token: token, label: "Direct IP") {
                return directURL
            }
        }

        print("🔴 [testConnection] All connection attempts failed")
        return nil
    }

    private func testConnection(_ connection: PlexConnection, token: String?) async -> Bool {
        return await testConnectionAndGetURL(connection, token: token) != nil
    }

    private func tryURL(_ baseURL: URL, token: String?, label: String) async -> Bool {
        do {
            // Create a client with shorter timeout for connection testing
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 5  // 5 second timeout for testing
            configuration.timeoutIntervalForResource = 10

            let session = URLSession(configuration: configuration)
            let testURL = baseURL.appendingPathComponent("/library/sections")
            print("🔵 [tryURL-\(label)] Testing: \(testURL)")

            var request = URLRequest(url: testURL)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            if let token = token {
                request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
            }

            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("🔴 [tryURL-\(label)] Invalid response")
                return false
            }

            print("✅ [tryURL-\(label)] Connected successfully!")
            return true
        } catch {
            print("🔴 [tryURL-\(label)] Failed: \(error.localizedDescription)")
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
