import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var viewModel = LibraryViewModel()
    @State private var showFilterSheet = false
    @State private var showSortSheet = false

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
            // Library tab selector
            if !viewModel.libraries.isEmpty {
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.libraries) { library in
                                let isSelected = viewModel.selectedLibrary?.key == library.key
                                Button {
                                    Task {
                                        if let client {
                                            await viewModel.selectLibrary(library, client: client)
                                        }
                                    }
                                } label: {
                                    LibraryTabLabel(
                                        title: library.title,
                                        icon: libraryIcon(for: library.type),
                                        isSelected: isSelected
                                    )
                                }
                                .buttonStyle(NoHighlightButtonStyle())
                                .focusEffectDisabled()
                            }
                        }
                        .padding(.leading, 50)
                    }

                    // Filter & Sort buttons (pinned)
                    HStack(spacing: 16) {
                        FilterSortButton(
                            icon: "line.3.horizontal.decrease.circle",
                            title: "Filter",
                            action: { showFilterSheet = true }
                        )
                        FilterSortButton(
                            icon: "arrow.up.arrow.down",
                            title: "Sort",
                            action: { showSortSheet = true }
                        )
                    }
                    .fixedSize()
                    .padding(.trailing, 50)
                }
                .padding(.vertical, 10)
            }

            // Content grid
            ScrollView {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Loading...")
                        .padding(.top, 100)
                } else if viewModel.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 60))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                        Text("No items found")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Try adjusting your filters")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 100)
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
        .task(id: appState.connectionStatus) {
            guard appState.connectionStatus == .connected else { return }
            if let client, viewModel.libraries.isEmpty {
                await viewModel.loadLibraries(client: client)
            }
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

    private func libraryIcon(for type: String) -> String {
        switch type {
        case "movie": return "film"
        case "show": return "tv"
        case "artist": return "music.note"
        case "photo": return "photo"
        default: return "rectangle.stack"
        }
    }
}

private struct FilterSortButton: View {
    let icon: String
    let title: String
    var action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
        .foregroundStyle(isFocused ? .primary : .secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .opacity(isFocused ? 1 : 0)
        )
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .hoverEffectDisabled()
        .onPlayPauseCommand { action() }
        .onTapGesture { action() }
    }
}

private struct LibraryTabLabel: View {
    let title: String
    let icon: String
    let isSelected: Bool

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(isSelected || isFocused ? .primary : .secondary)

            Rectangle()
                .fill(isSelected ? Color.accentColor : .clear)
                .frame(height: 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .opacity(isFocused ? 1 : 0)
        )
    }
}
