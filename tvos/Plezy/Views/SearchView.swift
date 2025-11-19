//
//  SearchView.swift
//  Beacon tvOS
//
//  Global search across all libraries
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var authService: PlexAuthService
    @EnvironmentObject var tabCoordinator: TabCoordinator
    @State private var searchQuery = ""
    @State private var searchResults: [PlexMetadata] = []
    @State private var isSearching = false
    @State private var selectedMedia: PlexMetadata?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 30) {
                // Spacer for top navigation
                Color.clear.frame(height: 100)

                // Header
                Text("Search")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.beaconTextSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 80)

                // Search field with Liquid Glass
                TextField("Search for movies, shows, and more...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.title2)
                    .padding(20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                .fill(.regularMaterial)
                                .opacity(0.5)

                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.beaconBlue.opacity(0.1),
                                            Color.beaconPurple.opacity(0.08)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .blendMode(.plusLighter)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                            .strokeBorder(
                                Color.beaconPurple.opacity(0.3),
                                lineWidth: DesignTokens.borderWidthUnfocused
                            )
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 80)
                    .onChange(of: searchQuery) { _, newValue in
                        Task {
                            await performSearch(query: newValue)
                        }
                    }

                // Results
                if isSearching {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Searching...")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchQuery.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)

                        Text("Start typing to search")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)

                        Text("No results found")
                            .font(.title2)
                            .foregroundColor(.gray)

                        Text("Try a different search term")
                            .font(.headline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 30)
                        ], spacing: 40) {
                            ForEach(searchResults) { item in
                                MediaCard(media: item) {
                                    selectedMedia = item
                                }
                            }
                        }
                        .padding(80)
                    }
                }
            }

            // Top navigation overlay
            VStack {
                TopNavigationMenu()
                    .padding(.top, 60)
                Spacer()
            }
        }
        .sheet(item: $selectedMedia) { media in
            MediaDetailView(media: media)
        }
    }

    private func performSearch(query: String) async {
        guard !query.isEmpty, let client = authService.currentClient else {
            searchResults = []
            return
        }

        // Debounce search
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Check if query has changed
        guard query == searchQuery else { return }

        isSearching = true

        do {
            let results = try await client.search(query: query)
            searchResults = results
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }

        isSearching = false
    }
}

#Preview {
    SearchView()
        .environmentObject(PlexAuthService())
}
