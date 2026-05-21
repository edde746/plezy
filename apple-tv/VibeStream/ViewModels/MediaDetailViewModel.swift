import Foundation
import Observation

@Observable
final class MediaDetailViewModel: ErrorReporting {
    private(set) var metadata: PlexMetadata?
    private(set) var onDeckEpisode: PlexMetadata?
    private(set) var activeEpisode: PlexMetadata?
    private(set) var activeEpisodeFileInfo: PlexFileInfo?
    private(set) var fileInfo: PlexFileInfo?
    private(set) var seasons: [PlexMetadata] = []
    private(set) var episodes: [PlexMetadata] = []
    private(set) var relatedItems: [PlexMetadata] = []
    private(set) var extras: [PlexMetadata] = []
    private(set) var collectionItems: [PlexMetadata] = []
    private(set) var collectionTitle: String?
    private(set) var isLoading = false
    /// When an episode redirects to its show, stores the original episode key
    /// so the view can pre-select it in the carousel.
    private(set) var redirectedEpisodeKey: String?
    var error: String?
    var isAuthError = false

    func load(ratingKey: String, client: PlexClient) async {
        isLoading = true
        error = nil
        isAuthError = false

        do {
            let result = try await client.getMetadataWithOnDeck(ratingKey: ratingKey)
            metadata = result.metadata
            onDeckEpisode = result.onDeck

            guard let meta = metadata else {
                error = "Could not load metadata"
                isLoading = false
                return
            }

            // If this is an episode belonging to a show, redirect to the show
            // so the detail page is consistent regardless of entry point.
            // The episode will be picked up as the on-deck/active episode.
            if meta.mediaType == .episode, let showKey = meta.grandparentRatingKey {
                // Store the episode so we can pre-select it in the carousel
                let episodeKey = meta.ratingKey
                let episodeResult = try await client.getMetadataWithOnDeck(ratingKey: showKey)
                metadata = episodeResult.metadata
                onDeckEpisode = episodeResult.onDeck
                guard let showMeta = metadata else {
                    isLoading = false
                    return
                }
                // If no on-deck from API, use the original episode
                if onDeckEpisode == nil {
                    onDeckEpisode = result.metadata
                }
                // Set the episode ratingKey for carousel focus
                redirectedEpisodeKey = episodeKey

                async let seasonsFetch = client.getChildren(ratingKey: showKey)
                async let extrasFetch = client.getExtras(ratingKey: showKey)
                seasons = try await seasonsFetch
                extras = (try? await extrasFetch) ?? []
                await resolveActiveEpisode(for: showMeta, client: client)
                isLoading = false
                return
            }

            // Mark loading done early for non-show types.
            // Shows stay loading until activeEpisode is resolved.
            if meta.mediaType != .show {
                isLoading = false
            }

            // Load additional data based on type
            switch meta.mediaType {
            case .movie:
                async let fileInfoFetch = client.getFileInfo(ratingKey: ratingKey)
                async let extrasFetch = client.getExtras(ratingKey: ratingKey)
                fileInfo = try? await fileInfoFetch
                extras = (try? await extrasFetch) ?? []
                await loadCollectionItems(for: meta, client: client)
            case .show:
                async let seasonsFetch = client.getChildren(ratingKey: ratingKey)
                async let extrasFetch = client.getExtras(ratingKey: ratingKey)
                seasons = try await seasonsFetch
                extras = (try? await extrasFetch) ?? []
                await resolveActiveEpisode(for: meta, client: client)
                isLoading = false
            case .season:
                episodes = try await client.getChildren(ratingKey: ratingKey)
            case .episode:
                // Fetch file info concurrently with episode carousel data
                async let fileInfoFetch: PlexFileInfo? = try? client.getFileInfo(ratingKey: ratingKey)

                // Load episodes in background — only for carousel mode
                // (list mode loads per-season episodes from the view)
                if EpisodeViewMode.current == .carousel {
                    Task {
                        await loadAllEpisodes(for: meta, client: client)
                    }
                }

                fileInfo = try? await fileInfoFetch
            default:
                break
            }
        } catch {
            handlePlexError(error)
            isLoading = false
        }
    }

    /// Loads seasons + episodes for the carousel without blocking the main load.
    private func loadAllEpisodes(for meta: PlexMetadata, client: PlexClient) async {
        if let showKey = meta.grandparentRatingKey {
            await loadAllEpisodesForCarousel(showRatingKey: showKey, client: client)
        } else if let seasonKey = meta.parentRatingKey {
            episodes = (try? await client.getChildren(ratingKey: seasonKey)) ?? []
        }
    }

    func loadEpisodes(seasonRatingKey: String, client: PlexClient) async {
        do {
            episodes = try await client.getChildren(ratingKey: seasonRatingKey)
        } catch {
            // Non-critical
        }
    }

    /// Loads seasons for list mode display. Called for episode pages that need
    /// season pills and per-season episode loading.
    func loadSeasonsForShow(showRatingKey: String, client: PlexClient) async {
        do {
            seasons = try await client.getChildren(ratingKey: showRatingKey)
        } catch {
            // Non-critical
        }
    }

    /// Loads all seasons and their episodes for carousel display.
    /// Pass the show's ratingKey directly.
    func loadAllEpisodesForCarousel(showRatingKey: String, client: PlexClient) async {
        do {
            let allSeasons = try await client.getChildren(ratingKey: showRatingKey)
            seasons = allSeasons
            await withTaskGroup(of: (Int, [PlexMetadata]).self) { group in
                for (index, season) in allSeasons.enumerated() {
                    group.addTask {
                        let eps = (try? await client.getChildren(ratingKey: season.ratingKey)) ?? []
                        return (index, eps)
                    }
                }
                var results: [(Int, [PlexMetadata])] = []
                for await result in group {
                    results.append(result)
                }
                results.sort { $0.0 < $1.0 }
                episodes = results.flatMap { $0.1 }
            }
        } catch {
            // Non-critical — carousel won't appear
        }
    }

    /// Resolves the active episode for a show: on-deck if available, else S1E1.
    /// Skips Season 0 (Specials) when falling back.
    private func resolveActiveEpisode(for showMeta: PlexMetadata, client: PlexClient) async {
        // Case 1: on-deck exists (partially watched or next unwatched)
        if let onDeck = onDeckEpisode {
            activeEpisode = onDeck
            activeEpisodeFileInfo = try? await client.getFileInfo(ratingKey: onDeck.ratingKey)
            return
        }

        // Case 2: no on-deck — fall back to first episode of first real season
        guard !seasons.isEmpty else { return }
        // Skip Season 0 (Specials), find lowest index >= 1
        let realSeasons = seasons.filter { ($0.index ?? 0) >= 1 }
        guard let firstSeason = realSeasons.sorted(by: { ($0.index ?? 0) < ($1.index ?? 0) }).first else { return }

        let episodes = (try? await client.getChildren(ratingKey: firstSeason.ratingKey)) ?? []
        guard let firstEpisode = episodes.first else { return }

        activeEpisode = firstEpisode
        activeEpisodeFileInfo = try? await client.getFileInfo(ratingKey: firstEpisode.ratingKey)
    }

    func switchToEpisode(_ episode: PlexMetadata, client: PlexClient) async {
        let previous = metadata
        // Immediately update with episode data, preserving show-level fields
        var switched = episode
        switched.art = episode.art ?? previous?.art
        switched.grandparentTitle = episode.grandparentTitle ?? previous?.grandparentTitle
        switched.grandparentThumb = episode.grandparentThumb ?? previous?.grandparentThumb
        switched.grandparentArt = episode.grandparentArt ?? previous?.grandparentArt
        switched.grandparentRatingKey = episode.grandparentRatingKey ?? previous?.grandparentRatingKey
        switched.clearLogo = episode.clearLogo ?? previous?.clearLogo
        switched.role = episode.role ?? previous?.role
        switched.contentRating = episode.contentRating ?? previous?.contentRating
        metadata = switched
        fileInfo = nil

        // Background: fetch full metadata + file info
        do {
            let result = try await client.getMetadataWithOnDeck(ratingKey: episode.ratingKey)
            if let fullMeta = result.metadata {
                metadata = fullMeta
            }
            onDeckEpisode = result.onDeck
            fileInfo = try? await client.getFileInfo(ratingKey: episode.ratingKey)
        } catch {
            // Non-critical — carousel data serves as fallback
        }
    }

    func markWatched(ratingKey: String, client: PlexClient) async {
        try? await client.markAsWatched(ratingKey: ratingKey)
        await reloadAfterWatchedChange(client: client)
    }

    func markUnwatched(ratingKey: String, client: PlexClient) async {
        try? await client.markAsUnwatched(ratingKey: ratingKey)
        await reloadAfterWatchedChange(client: client)
    }

    func reloadAfterWatchedChange(client: PlexClient) async {
        guard let meta = metadata else { return }

        // Refresh show-level metadata (viewedLeafCount, etc.)
        if let result = try? await client.getMetadataWithOnDeck(ratingKey: meta.ratingKey) {
            metadata = result.metadata
            onDeckEpisode = result.onDeck
        }

        // Refresh active episode metadata
        if let epKey = activeEpisode?.ratingKey,
           let epResult = try? await client.getMetadataWithOnDeck(ratingKey: epKey) {
            activeEpisode = epResult.metadata
            activeEpisodeFileInfo = try? await client.getFileInfo(ratingKey: epKey)
        }

        // Refresh episode tiles — re-fetch all episodes for their updated watch state
        if !episodes.isEmpty, !seasons.isEmpty {
            await withTaskGroup(of: (Int, [PlexMetadata]).self) { group in
                for (index, season) in seasons.enumerated() {
                    group.addTask {
                        let eps = (try? await client.getChildren(ratingKey: season.ratingKey)) ?? []
                        return (index, eps)
                    }
                }
                var results: [(Int, [PlexMetadata])] = []
                for await result in group {
                    results.append(result)
                }
                results.sort { $0.0 < $1.0 }
                episodes = results.flatMap { $0.1 }
            }
        }
    }

    func updateActiveEpisode(_ episode: PlexMetadata?, fileInfo: PlexFileInfo?) {
        activeEpisode = episode
        activeEpisodeFileInfo = fileInfo
    }

    private func reload(client: PlexClient) async {
        guard let ratingKey = metadata?.ratingKey else { return }
        await load(ratingKey: ratingKey, client: client)
    }

    private func loadCollectionItems(for meta: PlexMetadata, client: PlexClient) async {
        guard let collections = meta.collection, let first = collections.first,
              let sectionId = meta.librarySectionID else { return }
        collectionTitle = first.tag
        do {
            // Find the collection's ratingKey by listing library collections
            let libraryCollections = try await client.getLibraryCollections(sectionId: String(sectionId))
            guard let match = libraryCollections.first(where: { $0.title == first.tag }) else { return }
            // Fetch items in that collection, excluding the current movie
            let items = try await client.getCollectionItems(collectionId: match.ratingKey)
            collectionItems = items.filter { $0.ratingKey != meta.ratingKey }
        } catch {
            // Non-critical
        }
    }

    var firstTrailer: PlexMetadata? {
        extras.first(where: { $0.subtype == "trailer" })
    }

    var trailers: [PlexMetadata] {
        extras.filter { $0.subtype == "trailer" }
    }

    var bonusContent: [PlexMetadata] {
        extras.filter { $0.subtype != nil && $0.subtype != "trailer" }
    }

    var playableRatingKey: String? {
        if let activeEpisode {
            return activeEpisode.ratingKey
        }
        if let onDeckEpisode {
            return onDeckEpisode.ratingKey
        }
        if let meta = metadata {
            if meta.mediaType.isPlayable {
                return meta.ratingKey
            }
        }
        return nil
    }

    var showNeverWatched: Bool {
        guard metadata?.mediaType == .show else { return false }
        // A show is "never watched" if no episodes are fully watched AND
        // no episode is currently in progress (partially watched)
        if (metadata?.viewedLeafCount ?? 0) > 0 { return false }
        if onDeckEpisode != nil { return false }
        if let ep = activeEpisode, let offset = ep.viewOffset, offset > 0 { return false }
        return true
    }

    var playButtonTitle: String {
        // Show-specific logic
        if metadata?.mediaType == .show {
            if showNeverWatched {
                return "Play First Episode"
            }
            if let ep = activeEpisode {
                if let viewOffset = ep.viewOffset, viewOffset > 0 {
                    return "Resume"
                }
            }
            return "Play"
        }
        // Existing logic for episodes/movies
        if onDeckEpisode != nil {
            if let ep = onDeckEpisode {
                if let viewOffset = ep.viewOffset, viewOffset > 0 {
                    return "Resume"
                }
            }
            return "Play Next Episode"
        }
        if let viewOffset = metadata?.viewOffset, viewOffset > 0 {
            return "Play"
        }
        return "Play"
    }
}
