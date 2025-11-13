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
        // Load stored credentials
        await storageService.loadStoredData()

        // Check if user has valid token
        if let token = storageService.plexToken {
            authService.setToken(token)

            // Validate token and load servers
            if await authService.validateToken() {
                await authService.loadServers()

                // Auto-select last used server
                if let serverData = storageService.selectedServer {
                    authService.selectServer(from: serverData)
                }
            }
        }

        isLoading = false
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
