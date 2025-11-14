//
//  MoviesLibraryView.swift
//  Plezy tvOS
//
//  Movies library tab
//

import SwiftUI

struct MoviesLibraryView: View {
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
                    Text("Loading Movies...")
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            } else if let movieLibrary = libraries.first(where: { $0.mediaType == .movie }) {
                LibraryContentView(library: movieLibrary)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "film.badge.questionmark")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)

                    Text("No Movies library found")
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
            print("🎬 [MoviesLibraryView] Using cached libraries")
            self.libraries = cached
            isLoading = false
            return
        }

        print("🎬 [MoviesLibraryView] Loading fresh libraries...")
        isLoading = true

        do {
            let fetchedLibraries = try await client.getLibraries()
            self.libraries = fetchedLibraries

            // Cache the results with 10 minute TTL
            cache.set(cacheKey, value: fetchedLibraries, ttl: 600)

            print("🎬 [MoviesLibraryView] Libraries loaded: \(fetchedLibraries.count)")
        } catch {
            print("Error loading libraries: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    MoviesLibraryView()
        .environmentObject(PlexAuthService())
}
