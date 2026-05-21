import SwiftUI

struct LibraryContentView: View {
    let libraryKey: String
    let libraryTitle: String

    @Environment(AppState.self) private var appState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var viewModel = LibraryViewModel()
    @State private var showFilterSheet = false
    @State private var showSortSheet = false
    @State private var contentReady = false

    private var client: PlexClient? {
        guard let server = appState.activeServer, let token = appState.authToken else { return nil }
        return PlexClient(
            baseURL: server.baseURL,
            token: server.accessToken ?? token,
            clientIdentifier: appState.clientIdentifier,
            serverId: server.clientIdentifier,
            serverName: server.name
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar: title + filter/sort pills
            headerBar
                .padding(.top, 20)
                .padding(.bottom, 10)

            // Content grid
            ScrollView {
                if !contentReady {
                    Color.clear.frame(height: 1)
                } else if viewModel.items.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    MediaGrid(
                        items: viewModel.items,
                        baseURL: appState.activeServer?.baseURL ?? "",
                        token: appState.serverToken,
                        onItemSelected: { item in
                            coordinator.showMediaDetail(ratingKey: item.ratingKey)
                        },
                        onLoadMore: {
                            if let client {
                                await viewModel.loadMore(client: client)
                            }
                        }
                    )
                    .padding(.vertical, 30)

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(
                filters: viewModel.filters,
                activeFilters: viewModel.activeFilters,
                loadValues: { filter in
                    guard let client else { return [] }
                    return (try? await client.getFilterValues(filterKey: filter.key)) ?? []
                },
                onApply: { key, value in
                    showFilterSheet = false
                    Task {
                        if let client {
                            await viewModel.applyFilter(key: key, value: value, client: client)
                        }
                    }
                },
                onClear: {
                    showFilterSheet = false
                    Task {
                        if let client {
                            await viewModel.clearFilters(client: client)
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showSortSheet) {
            SortSheet(
                sorts: viewModel.sorts,
                activeSort: viewModel.activeSort,
                isDescending: viewModel.isSortDescending,
                onApply: { key, descending in
                    showSortSheet = false
                    Task {
                        if let client {
                            await viewModel.applySort(key, descending: descending, client: client)
                        }
                    }
                }
            )
        }
        .task {
            await loadLibrary()
        }
        .onChange(of: libraryKey) {
            Task { await loadLibrary() }
        }
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(white: 0.15), location: 0),
                    .init(color: Color(white: 0.06), location: 0.5),
                    .init(color: .black, location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text(libraryTitle)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 12) {
                filterPill
                sortPill
            }
        }
        .padding(.horizontal, 50)
    }

    private var filterPill: some View {
        let hasActiveFilter = !viewModel.activeFilters.isEmpty
        let label: String = {
            if hasActiveFilter, let firstValue = viewModel.activeFilters.values.first {
                return firstValue
            }
            return "Genres"
        }()
        return LibraryPillButton(
            icon: "line.3.horizontal.decrease",
            label: label,
            isActive: hasActiveFilter,
            action: { showFilterSheet = true }
        )
    }

    private var sortPill: some View {
        let hasActiveSort = viewModel.activeSort != nil
        let sortLabel: String = {
            guard let sortKey = viewModel.activeSort,
                  let sort = viewModel.sorts.first(where: { $0.key == sortKey }) else {
                return "Sort"
            }
            return sort.title + (viewModel.isSortDescending ? " ↓" : " ↑")
        }()
        return LibraryPillButton(
            icon: "arrow.up.arrow.down",
            label: sortLabel,
            isActive: hasActiveSort,
            action: { showSortSheet = true }
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            Text("No items found")
                .font(.title3)
                .foregroundStyle(.secondary)
            if !viewModel.activeFilters.isEmpty {
                Text("Try adjusting your filters")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 100)
    }

    // MARK: - Loading

    private func loadLibrary() async {
        guard let client else { return }
        contentReady = false
        // Find the matching library and select it
        if viewModel.libraries.isEmpty {
            await viewModel.loadLibraries(client: client)
        }
        if let library = viewModel.libraries.first(where: { $0.key == libraryKey }),
           viewModel.selectedLibrary?.key != libraryKey {
            await viewModel.selectLibrary(library, client: client)
        }
        withAnimation(.easeIn(duration: 0.3)) {
            contentReady = true
        }
    }
}

// MARK: - Pill Button

private struct LibraryPillButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
            Text(label)
                .font(.subheadline)
                .lineLimit(1)
        }
        .foregroundStyle(isFocused ? .black : .white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(isFocused ? .white : isActive ? .white.opacity(0.25) : .white.opacity(0.12))
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onPlayPauseCommand { action() }
        .onTapGesture { action() }
    }
}
