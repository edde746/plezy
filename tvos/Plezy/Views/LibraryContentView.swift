//
//  LibraryContentView.swift
//  Beacon tvOS
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
    @State private var currentOffset = 0
    @State private var hasMoreItems = true
    @State private var isLoadingMore = false

    private let cache = CacheService.shared
    private let pageSize = 50

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

                    // Sort Menu with Liquid Glass
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
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 20))
                            Text(sortOption.rawValue)
                                .font(.system(size: 20, weight: .semibold, design: .default))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                .padding(.bottom, 30)

                if isLoading {
                    ScrollView {
                        LibraryGridSkeleton()
                    }
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
                        // Group items into rows of 5
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(stride(from: 0, to: filteredItems.count, by: 5)), id: \.self) { rowIndex in
                                let rowItems = Array(filteredItems[rowIndex..<min(rowIndex + 5, filteredItems.count)])

                                // Keep the horizontal rows un-clipped so rounded corners and
                                // focus scaling aren't flattened along the top edge
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(rowItems) { item in
                                            MediaCard(media: item, config: .libraryGrid) {
                                                print("🎯 [LibraryContent] Item tapped in \(library.title): \(item.title)")
                                                print("🎯 [LibraryContent] Setting selectedMedia to trigger sheet")
                                                selectedMedia = item
                                                print("🎯 [LibraryContent] selectedMedia set to: \(String(describing: selectedMedia?.title))")
                                            }
                                            .padding(.vertical, 20) // Padding for focus scale
                                        }
                                    }
                                    .padding(.horizontal, 40)
                                }
                                .tvOSScrollClipDisabled()
                                // NOTE: Do not add .clipped() here - it cuts off the rounded corners
                                // when cards scale up on focus. Cards need to extend beyond their
                                // bounds to maintain their rounded appearance when focused.
                            }

                            // Load more indicator
                            if hasMoreItems {
                                VStack {
                                    if isLoadingMore {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .tint(.white)
                                    } else {
                                        Color.clear.frame(height: 1)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .onAppear {
                                    Task {
                                        await loadMoreContent()
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 80)
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
        guard let _ = authService.currentClient,
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
        currentOffset = 0
        hasMoreItems = true

        do {
            let fetchedItems = try await fetchItems(start: 0, size: pageSize)
            self.items = fetchedItems

            // Check if there are more items
            hasMoreItems = fetchedItems.count == pageSize
            currentOffset = pageSize

            // Cache the results with 10 minute TTL
            cache.set(cacheKey, value: fetchedItems, ttl: 600)

            applyFilters() // Still apply client-side filters for watched items
            print("📚 [LibraryContent] Content loaded: \(fetchedItems.count) items, hasMore: \(hasMoreItems)")
            errorMessage = nil
        } catch {
            print("Error loading library content: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadMoreContent() async {
        guard hasMoreItems, !isLoadingMore else { return }
        guard authService.currentClient != nil else { return }

        print("📚 [LibraryContent] Loading more content from offset \(currentOffset)")
        isLoadingMore = true

        do {
            let fetchedItems = try await fetchItems(start: currentOffset, size: pageSize)

            // Append new items
            self.items.append(contentsOf: fetchedItems)

            // Check if there are more items
            hasMoreItems = fetchedItems.count == pageSize
            currentOffset += fetchedItems.count

            applyFilters()
            print("📚 [LibraryContent] Loaded \(fetchedItems.count) more items, total: \(items.count), hasMore: \(hasMoreItems)")
        } catch {
            print("Error loading more content: \(error)")
        }

        isLoadingMore = false
    }

    private func fetchItems(start: Int, size: Int) async throws -> [PlexMetadata] {
        guard let client = authService.currentClient else {
            throw PlexAPIError.unauthorized
        }

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

        return try await client.getLibraryContent(
            sectionKey: library.key,
            start: start,
            size: size,
            sort: sortParam,
            unwatched: unwatchedParam
        )
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
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .default))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        if isSelected {
                            // Selected state with Liquid Glass
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium, style: .continuous)
                                .fill(.white)
                        } else {
                            // Unselected state with subtle material
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium, style: .continuous)
                                .fill(.regularMaterial.opacity(DesignTokens.materialOpacitySubtle))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium, style: .continuous)
                        .strokeBorder(
                            isFocused && !isSelected ? Color.white.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .buttonStyle(FilterButtonStyle(isFocused: $isFocused, isSelected: isSelected))
    }
}

/// Button style for filter buttons with Apple's focus handling
/// Focus state is tracked for visual styling only - Apple handles focus behavior
struct FilterButtonStyle: ButtonStyle {
    let isFocused: FocusState<Bool>.Binding
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .focused(isFocused)
            .focusable()
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignTokens.Animation.quick.spring(), value: configuration.isPressed)
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
