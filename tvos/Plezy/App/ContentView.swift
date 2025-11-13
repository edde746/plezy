//
//  ContentView.swift
//  Plezy tvOS
//
//  Main content view with navigation logic
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var authService: PlexAuthService
    @EnvironmentObject var storageService: StorageService
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if authService.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .task {
            await initializeApp()
        }
    }

    private func initializeApp() async {
        print("📺 [ContentView] initializeApp started")

        // Load stored credentials
        await storageService.loadStoredData()
        print("📺 [ContentView] Storage loaded. Has token: \(storageService.plexToken != nil), Has saved server: \(storageService.selectedServer != nil)")

        // Check if user has valid token
        if let token = storageService.plexToken {
            print("📺 [ContentView] Found stored token, setting it...")
            authService.setToken(token)

            // Validate token and load servers
            print("📺 [ContentView] Validating token...")
            if await authService.validateToken() {
                print("📺 [ContentView] Token is valid! Loading servers...")
                await authService.loadServers()
                print("📺 [ContentView] Servers loaded: \(authService.availableServers.count)")

                // Auto-select last used server OR the only available server
                if let serverData = storageService.selectedServer {
                    print("📺 [ContentView] Auto-selecting saved server...")
                    authService.selectServer(from: serverData)
                } else if authService.availableServers.count == 1, let server = authService.availableServers.first {
                    // If only one server and no saved server, auto-select it
                    print("📺 [ContentView] Only one server found, auto-selecting: \(server.name)")
                    await authService.selectServer(server)
                } else {
                    print("📺 [ContentView] No saved server and \(authService.availableServers.count) servers available")
                }
            } else {
                print("📺 [ContentView] Token validation failed")
            }
        } else {
            print("📺 [ContentView] No stored token found")
        }

        isLoading = false
        print("📺 [ContentView] initializeApp complete. isAuthenticated: \(authService.isAuthenticated)")
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "tv.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("Plezy")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PlexAuthService())
        .environmentObject(SettingsService())
        .environmentObject(StorageService())
}
