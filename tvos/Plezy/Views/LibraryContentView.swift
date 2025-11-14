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
                            applyFilters()
                        }

                        FilterButton(title: "Unwatched", isSelected: filterStatus == .unwatched) {
                            filterStatus = .unwatched
                            applyFilters()
                        }

                        FilterButton(title: "Watched", isSelected: filterStatus == .watched) {
                            filterStatus = .watched
                            applyFilters()
                        }
                    }

                    Spacer()

                    // Sort Menu
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                                applyFilters()
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
                                    selectedMedia = item
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
        .sheet(item: $selectedMedia) { media in
            MediaDetailView(media: media)
        }
    }

    private func loadContent() async {
        guard let client = authService.currentClient else {
            return
        }

        isLoading = true

        do {
            items = try await client.getLibraryContent(sectionKey: library.key, size: 200)
            applyFilters()
        } catch {
            print("Error loading library content: \(error)")
        }

        isLoading = false
    }

    private func applyFilters() {
        var filtered = items

        // Apply watch status filter
        switch filterStatus {
        case .all:
            break
        case .unwatched:
            filtered = filtered.filter { !$0.isWatched }
        case .watched:
            filtered = filtered.filter { $0.isWatched }
        }

        // Apply sort
        switch sortOption {
        case .recentlyAdded:
            filtered.sort { ($0.addedAt ?? 0) > ($1.addedAt ?? 0) }
        case .titleAsc:
            filtered.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDesc:
            filtered.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .yearDesc:
            filtered.sort { ($0.year ?? 0) > ($1.year ?? 0) }
        case .yearAsc:
            filtered.sort { ($0.year ?? 0) < ($1.year ?? 0) }
        }

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
