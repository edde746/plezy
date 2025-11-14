//
//  TVShowsLibraryView.swift
//  Plezy tvOS
//
//  TV Shows library tab
//

import SwiftUI
import Combine

struct TVShowsLibraryView: View {
    @EnvironmentObject var authService: PlexAuthService
    @State private var libraries: [PlexLibrary] = []
    @State private var isLoading = true

    private let cache = CacheService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading TV Shows...")
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            } else if let tvLibrary = libraries.first(where: { $0.mediaType == .show }) {
                LibraryContentView(library: tvLibrary)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "tv.badge.questionmark")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)

                    Text("No TV Shows library found")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
        }
        .task {
            await loadLibraries()
        }
    }

    private func loadLibraries() async {
        guard let client = authService.currentClient,
              let serverID = authService.selectedServer?.clientIdentifier else {
            return
        }

        let cacheKey = CacheService.librariesKey(serverID: serverID)

        // Check cache first
        if let cached: [PlexLibrary] = cache.get(cacheKey) {
            print("📺 [TVShowsLibraryView] Using cached libraries")
            self.libraries = cached
            isLoading = false
            return
        }

        print("📺 [TVShowsLibraryView] Loading fresh libraries...")
        isLoading = true

        do {
            let fetchedLibraries = try await client.getLibraries()
            self.libraries = fetchedLibraries

            // Cache the results with 10 minute TTL
            cache.set(cacheKey, value: fetchedLibraries, ttl: 600)

            print("📺 [TVShowsLibraryView] Libraries loaded: \(fetchedLibraries.count)")
        } catch {
            print("Error loading libraries: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    TVShowsLibraryView()
        .environmentObject(PlexAuthService())
}
