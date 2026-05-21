import Foundation
import Observation
import TVServices

@Observable
final class HomeViewModel: ErrorReporting {
    private(set) var hubs: [PlexHub] = []
    private(set) var continueWatching: [PlexMetadata] = []
    private(set) var isLoading = false
    var error: String?
    var isAuthError = false
    private(set) var trendingMovies: [(rank: Int, metadata: PlexMetadata)] = []
    private(set) var trendingShows: [(rank: Int, metadata: PlexMetadata)] = []
    private var trendingCache: [String: (date: Date, movies: [(rank: Int, metadata: PlexMetadata)], shows: [(rank: Int, metadata: PlexMetadata)])] = [:]
    private static let cacheTTL: TimeInterval = 6 * 60 * 60

    func loadHubs(client: PlexClient, serverIdentifier: String = "default") async {
        isLoading = true
        error = nil
        isAuthError = false

        do {
            async let globalHubs = client.getGlobalHubs()
            async let onDeck = client.getOnDeck()

            let (fetchedHubs, fetchedOnDeck) = try await (globalHubs, onDeck)
            continueWatching = fetchedOnDeck
            hubs = reorderHubs(fetchedHubs.filter { hub in
                guard hub.size > 0 else { return false }
                // Filter out on-deck/continue watching hubs since we show them separately
                let id = hub.hubIdentifier?.lowercased() ?? ""
                let title = hub.title.lowercased()
                if id.contains("ondeck") || id.contains("continue") { return false }
                if title.contains("continue watching") { return false }
                return true
            })
        } catch {
            handlePlexError(error)
        }

        isLoading = false

        // Load trending in background (non-blocking)
        await loadTrending(client: client, serverIdentifier: serverIdentifier)
    }

    /// Reorder hubs so "Recently Released" is right after "Recently Added"
    /// of the same category (Movies/TV), and "Top Unwatched" follows after that.
    private func reorderHubs(_ hubs: [PlexHub]) -> [PlexHub] {
        var result = hubs

        /// Moves a hub whose title contains `keyword` so it sits right after
        /// the hub whose title contains `anchor` **and** shares the same
        /// trailing category word (e.g. "Movies", "Shows").
        func moveHub(matching keyword: String, afterKeyword anchor: String) {
            // Collect all hubs that match the keyword
            let sources = result.enumerated().filter {
                $0.element.title.localizedCaseInsensitiveContains(keyword)
            }
            // Process in reverse so index removal doesn't shift later matches
            for source in sources.reversed() {
                let hub = result.remove(at: source.offset)
                let category = hub.title.split(separator: " ").last?.lowercased() ?? ""
                // Find the anchor hub with the same category suffix
                if let anchorIndex = result.firstIndex(where: {
                    $0.title.localizedCaseInsensitiveContains(anchor) &&
                    ($0.title.split(separator: " ").last?.lowercased() ?? "") == category
                }) {
                    result.insert(hub, at: anchorIndex + 1)
                } else {
                    result.insert(hub, at: min(source.offset, result.count))
                }
            }
        }

        moveHub(matching: "Recently Released", afterKeyword: "Recently Added")
        moveHub(matching: "Top Unwatched", afterKeyword: "Recently Released")

        return result
    }

    private var isTrendingLoading = false

    private func loadTrending(client: PlexClient, serverIdentifier: String = "default") async {
        guard !isTrendingLoading else { return }
        isTrendingLoading = true
        defer { isTrendingLoading = false }
        let cacheKey = serverIdentifier
        if let cached = trendingCache[cacheKey],
           Date().timeIntervalSince(cached.date) < Self.cacheTTL {
            trendingMovies = cached.movies
            trendingShows = cached.shows
            return
        }

        do {
            let libraries = try await client.getLibraries()
            let movieSections = libraries.filter { $0.type == "movie" }
            let showSections = libraries.filter { $0.type == "show" && !$0.title.localizedCaseInsensitiveContains("anime") }

            async let movieMap = buildTmdbLookup(client: client, sections: movieSections)
            async let showMap = buildTmdbLookup(client: client, sections: showSections)
            let (movieLookup, showLookup) = await (movieMap, showMap)

            async let movies = matchTrending(mediaType: "movie", lookup: movieLookup)
            async let shows = matchTrending(mediaType: "tv", lookup: showLookup)
            let (matchedMovies, matchedShows) = await (movies, shows)

            trendingMovies = matchedMovies.count >= 3 ? matchedMovies : []
            trendingShows = matchedShows.count >= 3 ? matchedShows : []
            trendingCache[cacheKey] = (date: Date(), movies: trendingMovies, shows: trendingShows)
            if !trendingMovies.isEmpty {
                writeTopShelfCache(trendingMovies)
            }
        } catch {
            // Non-critical
        }
    }

    private func buildTmdbLookup(client: PlexClient, sections: [PlexLibrary]) async -> [String: PlexMetadata] {
        var lookup: [String: PlexMetadata] = [:]
        for section in sections {
            if let items = try? await client.getLibraryContent(sectionId: section.key) {
                for item in items {
                    if let tmdbId = item.tmdbId {
                        lookup[tmdbId] = item
                    }
                }
            }
        }
        return lookup
    }

    private func matchTrending(mediaType: String, lookup: [String: PlexMetadata]) async -> [(rank: Int, metadata: PlexMetadata)] {
        var matched: [(rank: Int, metadata: PlexMetadata)] = []
        var seen: Set<String> = []
        for page in 1...5 {
            let trendingIds = await TmdbService.shared.getTrending(mediaType: mediaType, page: page)
            if trendingIds.isEmpty { break }
            for tmdbId in trendingIds {
                if let metadata = lookup[tmdbId], seen.insert(metadata.ratingKey).inserted {
                    matched.append((rank: matched.count + 1, metadata: metadata))
                    if matched.count >= 10 { return matched }
                }
            }
        }
        return matched
    }

    func refresh(client: PlexClient, serverIdentifier: String = "default") async {
        trendingCache.removeAll()
        await loadHubs(client: client, serverIdentifier: serverIdentifier)
    }

    private func writeTopShelfCache(_ movies: [(rank: Int, metadata: PlexMetadata)]) {
        let items: [[String: String]] = movies.map { item in
            [
                "ratingKey": item.metadata.ratingKey,
                "title": item.metadata.title,
                "thumbPath": item.metadata.posterThumb() ?? item.metadata.thumb ?? "",
            ]
        }
        let defaults = UserDefaults(suiteName: "group.com.amaze.vibestream")
        defaults?.set(items, forKey: "topshelf_trending")
        TVTopShelfContentProvider.topShelfContentDidChange()
    }
}
