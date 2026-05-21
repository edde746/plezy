import Foundation
import Observation

@Observable
final class LibraryViewModel: ErrorReporting {
    private(set) var libraries: [PlexLibrary] = []
    private(set) var items: [PlexMetadata] = []
    private(set) var filters: [PlexFilter] = []
    private(set) var sorts: [PlexSort] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    var error: String?
    var isAuthError = false
    private(set) var totalCount = 0

    var selectedLibrary: PlexLibrary?
    var activeFilters: [String: String] = [:]
    var activeSort: String?
    var isSortDescending = false

    private let pageSize = 50
    private let maxItemsInMemory = 500
    private var currentPage = 0
    private var hasMore = true

    func loadLibraries(client: PlexClient) async {
        do {
            libraries = try await client.getLibraries()
            if selectedLibrary == nil, let first = libraries.first {
                selectedLibrary = first
                async let content: () = loadContent(client: client)
                async let filtersAndSorts: () = loadFiltersAndSorts(client: client)
                _ = await (content, filtersAndSorts)
            }
        } catch {
            handlePlexError(error)
        }
    }

    func selectLibrary(_ library: PlexLibrary, client: PlexClient) async {
        selectedLibrary = library
        items = []
        currentPage = 0
        hasMore = true
        activeFilters = [:]
        activeSort = nil

        async let loadContent: () = loadContent(client: client)
        async let loadFilters: () = loadFiltersAndSorts(client: client)
        _ = await (loadContent, loadFilters)
    }

    func loadContent(client: PlexClient) async {
        guard let library = selectedLibrary else { return }
        isLoading = true
        error = nil

        do {
            let sort = activeSort.map { isSortDescending ? "\($0):desc" : $0 }
            items = try await client.getLibraryContent(
                sectionId: library.key,
                start: 0,
                size: pageSize,
                sort: sort,
                filters: activeFilters.isEmpty ? nil : activeFilters
            )
            totalCount = try await client.getLibraryTotalCount(sectionId: library.key)
            currentPage = 1
            hasMore = items.count < totalCount
        } catch {
            handlePlexError(error)
        }

        isLoading = false
    }

    func loadMore(client: PlexClient) async {
        guard !isLoadingMore, hasMore, let library = selectedLibrary else { return }
        isLoadingMore = true

        do {
            let sort = activeSort.map { isSortDescending ? "\($0):desc" : $0 }
            // Use actual items count as offset to avoid gaps if a page returned fewer results
            let moreItems = try await client.getLibraryContent(
                sectionId: library.key,
                start: items.count,
                size: pageSize,
                sort: sort,
                filters: activeFilters.isEmpty ? nil : activeFilters
            )
            items.append(contentsOf: moreItems)
            currentPage += 1
            // Stop if we got fewer items than requested (end of library), reached total,
            // or hit the in-memory cap to prevent unbounded growth
            hasMore = moreItems.count >= pageSize && items.count < totalCount && items.count < maxItemsInMemory
        } catch {
            // Allow retry on next scroll
            hasMore = true
        }

        isLoadingMore = false
    }

    func applyFilter(key: String, value: String, client: PlexClient) async {
        activeFilters[key] = value
        items = []
        currentPage = 0
        hasMore = true
        await loadContent(client: client)
    }

    func clearFilters(client: PlexClient) async {
        activeFilters = [:]
        items = []
        currentPage = 0
        hasMore = true
        await loadContent(client: client)
    }

    func applySort(_ sortKey: String, descending: Bool, client: PlexClient) async {
        activeSort = sortKey
        isSortDescending = descending
        items = []
        currentPage = 0
        hasMore = true
        await loadContent(client: client)
    }

    private func loadFiltersAndSorts(client: PlexClient) async {
        guard let library = selectedLibrary else { return }
        do {
            async let f = client.getLibraryFilters(sectionId: library.key)
            async let s = client.getLibrarySorts(sectionId: library.key)
            let (fetchedFilters, fetchedSorts) = try await (f, s)
            filters = fetchedFilters
            sorts = fetchedSorts
        } catch {
            // Non-critical failure
        }
    }
}
