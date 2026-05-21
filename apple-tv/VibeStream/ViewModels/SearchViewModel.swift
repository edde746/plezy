import Foundation
import Observation

@Observable
final class SearchViewModel {
    private(set) var results: [PlexMetadata] = []
    private(set) var isSearching = false
    private(set) var hasSearched = false

    var query = "" {
        didSet { scheduleSearch() }
    }

    private var searchTask: Task<Void, Never>?
    private weak var client: PlexClient?

    func setClient(_ client: PlexClient) {
        self.client = client
    }

    func search(client: PlexClient) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            hasSearched = false
            return
        }

        isSearching = true
        hasSearched = true

        do {
            results = try await client.search(query: trimmed, limit: 30)
        } catch {
            results = []
        }

        isSearching = false
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let client else { return }
            await search(client: client)
        }
    }

    func clear() {
        query = ""
        results = []
        hasSearched = false
        searchTask?.cancel()
    }
}
