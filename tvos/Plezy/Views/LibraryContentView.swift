//
//  LibraryContentView.swift
//  Plezy tvOS
//
//  Content browser for a specific library
//

import SwiftUI

struct LibraryContentView: View {
    let library: PlexLibrary
    @EnvironmentObject var authService: PlexAuthService
    @Environment(\.dismiss) var dismiss
    @State private var items: [PlexMetadata] = []
    @State private var filteredItems: [PlexMetadata] = []
    @State private var isLoading = true
    @State private var selectedMedia: PlexMetadata?
    @State private var filterStatus: FilterStatus = .all
    @State private var sortOption: SortOption = .recentlyAdded
    @State private var errorMessage: String?

    private let cache = CacheService.shared

    enum FilterStatus {
        case all
        case unwatched
        case watched
    }

    enum SortOption: String, CaseIterable {
        case recentlyAdded = "Recently Added"
        case titleAsc = "Title (A-Z)"
        case titleDesc = "Title (Z-A)"
        case yearDesc = "Year (Newest)"
        case yearAsc = "Year (Oldest)"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header with title - only show back button if presented as sheet
                HStack {
                    if dismiss != nil {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(library.title)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 80)
                .padding(.top, 30)
                .padding(.bottom, 20)

                // Filters
                HStack(spacing: 30) {
                    // Status Filter
                    HStack(spacing: 15) {
                        FilterButton(title: "All", isSelected: filterStatus == .all) {
                            filterStatus = .all
                        }

                        FilterButton(title: "Unwatched", isSelected: filterStatus == .unwatched) {
                            filterStatus = .unwatched
                        }

                        FilterButton(title: "Watched", isSelected: filterStatus == .watched) {
                            filterStatus = .watched
                        }
                    }

                    Spacer()

                    // Sort Menu
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOption.rawValue)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 20)

                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Loading content...")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 30) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 80))
                            .foregroundColor(.red)

                        Text("Error Loading Library")
                            .font(.title)
                            .foregroundColor(.white)

                        Text(error)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 100)

                        Button {
                            print("🔄 [LibraryContent] Retry button tapped")
                            Task {
                                await loadContent()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.title3)
                        }
                        .buttonStyle(ClearGlassButtonStyle())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)

                        Text(items.isEmpty ? "No content found" : "No items match filters")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 30)
                        ], spacing: 40) {
                            ForEach(filteredItems) { item in
                                MediaCard(media: item) {
                                    print("🎯 [LibraryContent] Item tapped in \(library.title): \(item.title)")
                                    print("🎯 [LibraryContent] Setting selectedMedia to trigger sheet")
                                    selectedMedia = item
                                    print("🎯 [LibraryContent] selectedMedia set to: \(String(describing: selectedMedia?.title))")
                                }
                            }
                        }
                        .padding(80)
                    }
                }
            }
        }
        .task {
            await loadContent()
        }
        .onChange(of: filterStatus) { oldValue, newValue in
            print("🔄 [LibraryContent] Filter status changed from \(oldValue) to \(newValue)")
            Task {
                // Invalidate cache when filters change
                if let serverID = authService.selectedServer?.clientIdentifier {
                    let cacheKey = CacheService.libraryContentKey(serverID: serverID, libraryKey: library.key)
                    cache.invalidate(cacheKey)
                }
                await loadContent()
            }
        }
        .onChange(of: sortOption) { oldValue, newValue in
            print("🔄 [LibraryContent] Sort option changed from \(oldValue) to \(newValue)")
            Task {
                // Invalidate cache when sort changes
                if let serverID = authService.selectedServer?.clientIdentifier {
                    let cacheKey = CacheService.libraryContentKey(serverID: serverID, libraryKey: library.key)
                    cache.invalidate(cacheKey)
                }
                await loadContent()
            }
        }
        .sheet(item: $selectedMedia) { media in
            let _ = print("📱 [LibraryContent] Sheet presenting MediaDetailView for: \(media.title)")
            MediaDetailView(media: media)
                .environmentObject(authService)
                .onAppear {
                    print("📱 [LibraryContent] MediaDetailView appeared for: \(media.title)")
                }
        }
    }

    private func loadContent() async {
        guard let client = authService.currentClient,
              let serverID = authService.selectedServer?.clientIdentifier else {
            return
        }

        let cacheKey = CacheService.libraryContentKey(serverID: serverID, libraryKey: library.key)

        // Check cache first
        if let cached: [PlexMetadata] = cache.get(cacheKey) {
            print("📚 [LibraryContent] Using cached content for \(library.title)")
            self.items = cached
            applyFilters()
            isLoading = false
            return
        }

        print("📚 [LibraryContent] Loading fresh content for \(library.title)...")
        isLoading = true
        errorMessage = nil

        do {
            // Map sort option to Plex API sort parameter
            let sortParam: String? = {
                switch sortOption {
                case .recentlyAdded:
                    return "addedAt:desc"
                case .titleAsc:
                    return "titleSort:asc"
                case .titleDesc:
                    return "titleSort:desc"
                case .yearDesc:
                    return "year:desc"
                case .yearAsc:
                    return "year:asc"
                }
            }()

            // Map filter status to unwatched parameter
            let unwatchedParam: Bool? = {
                switch filterStatus {
                case .unwatched:
                    return true
                case .all, .watched:
                    return nil // Server-side filtering only supports unwatched
                }
            }()

            let fetchedItems = try await client.getLibraryContent(
                sectionKey: library.key,
                size: 200,
                sort: sortParam,
                unwatched: unwatchedParam
            )
            self.items = fetchedItems

            // Cache the results with 10 minute TTL
            cache.set(cacheKey, value: fetchedItems, ttl: 600)

            applyFilters() // Still apply client-side filters for watched items
            print("📚 [LibraryContent] Content loaded: \(fetchedItems.count) items")
            errorMessage = nil
        } catch {
            print("Error loading library content: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func applyFilters() {
        var filtered = items

        // Apply client-side watch status filter only for "watched" items
        // (unwatched is handled server-side)
        switch filterStatus {
        case .all, .unwatched:
            break // Server handles unwatched filtering
        case .watched:
            filtered = filtered.filter { $0.isWatched }
        }

        // Sorting is now handled server-side via API parameters
        // No need for client-side sorting

        filteredItems = filtered
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isFocused = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.white : Color.white.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .onFocusChange(true) { focused in
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = focused
            }
        }
    }
}

#Preview {
    LibraryContentView(library: PlexLibrary(
        key: "1",
        title: "Movies",
        type: "movie",
        agent: nil,
        scanner: nil,
        language: nil,
        uuid: UUID().uuidString,
        updatedAt: nil,
        createdAt: nil,
        scannedAt: nil,
        thumb: nil,
        art: nil
    ))
    .environmentObject(PlexAuthService())
}
