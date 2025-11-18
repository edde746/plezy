//
//  LibrariesView.swift
//  Beacon tvOS
//
//  Library browser
//

import SwiftUI

struct LibrariesView: View {
    @EnvironmentObject var authService: PlexAuthService
    @State private var libraries: [PlexLibrary] = []
    @State private var selectedTab: LibraryTab = .tvShows
    @State private var isLoading = true

    private let cache = CacheService.shared

    enum LibraryTab {
        case tvShows
        case movies
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Tab Selector
                HStack(spacing: 40) {
                    TabButton(title: "TV Shows", isSelected: selectedTab == .tvShows) {
                        selectedTab = .tvShows
                    }

                    TabButton(title: "Movies", isSelected: selectedTab == .movies) {
                        selectedTab = .movies
                    }

                    Spacer()
                }
                .padding(.horizontal, 80)
                .padding(.top, 40)
                .padding(.bottom, 20)

                // Content
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Loading libraries...")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let library = currentLibrary {
                    LibraryContentView(library: library)
                        .id(library.key) // Force refresh when library changes
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: selectedTab == .tvShows ? "tv.badge.questionmark" : "film.badge.questionmark")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)

                        Text("No \(selectedTab == .tvShows ? "TV Shows" : "Movies") library found")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            await loadLibraries()
        }
    }

    private var currentLibrary: PlexLibrary? {
        switch selectedTab {
        case .tvShows:
            return libraries.first { $0.mediaType == .show }
        case .movies:
            return libraries.first { $0.mediaType == .movie }
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
            print("📚 [LibrariesView] Using cached libraries")
            self.libraries = cached
            isLoading = false
            return
        }

        print("📚 [LibrariesView] Loading fresh libraries...")
        isLoading = true

        do {
            let fetchedLibraries = try await client.getLibraries()
            self.libraries = fetchedLibraries

            // Cache the results with 10 minute TTL
            cache.set(cacheKey, value: fetchedLibraries, ttl: 600)

            print("📚 [LibrariesView] Libraries loaded: \(fetchedLibraries.count)")
        } catch {
            print("Error loading libraries: \(error)")
        }

        isLoading = false
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isFocused = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(title)
                    .font(.title2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .gray)

                Rectangle()
                    .fill(isSelected ? Color.beaconGradient : Color.clear)
                    .frame(height: 4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? DesignTokens.focusScale : 1.0)
        .animation(DesignTokens.Animation.focus.spring(), value: isFocused)
        .onFocusChange(true) { focused in
            isFocused = focused
        }
    }
}

struct LibraryCard: View {
    let library: PlexLibrary
    let action: () -> Void
    @State private var isFocused = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: libraryIcon)
                    .font(.system(size: 50))
                    .foregroundColor(.beaconPurple)
                    .frame(width: 80)

                VStack(alignment: .leading, spacing: 8) {
                    Text(library.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(library.type.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge)
                    .fill(Color.white.opacity(isFocused ? DesignTokens.materialOpacitySubtle : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge)
                    .strokeBorder(
                        LinearGradient(
                            colors: isFocused ? [
                                Color.beaconBlue,
                                Color.beaconPurple,
                                Color.beaconMagenta
                            ] : [Color.white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? DesignTokens.borderWidthFocusedThick : 2
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? DesignTokens.focusScale : 1.0)
        .animation(DesignTokens.Animation.focus.spring(), value: isFocused)
        .onFocusChange(true) { focused in
            isFocused = focused
        }
    }

    private var libraryIcon: String {
        switch library.mediaType {
        case .movie:
            return "film.fill"
        case .show:
            return "tv.fill"
        case .artist:
            return "music.note.list"
        case .photo:
            return "photo.on.rectangle.angled"
        case .unknown:
            return "folder.fill"
        }
    }
}

#Preview {
    LibrariesView()
        .environmentObject(PlexAuthService())
}
