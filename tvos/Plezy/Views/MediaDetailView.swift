//
//  MediaDetailView.swift
//  Beacon tvOS
//
//  Detailed view for movies and TV shows
//

import SwiftUI

struct MediaDetailView: View {
    let media: PlexMetadata
    @EnvironmentObject var authService: PlexAuthService
    @Environment(\.dismiss) var dismiss
    @State private var detailedMedia: PlexMetadata?
    @State private var seasons: [PlexMetadata] = []
    @State private var onDeckEpisode: PlexMetadata?
    @State private var isLoading = true
    @State private var selectedSeason: PlexMetadata?
    @State private var showVideoPlayer = false
    @State private var playMedia: PlexMetadata?

    var body: some View {
        let _ = print("📄 [MediaDetailView] body evaluated for: \(media.title)")
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Banner Section
                    ZStack(alignment: .bottomLeading) {
                        // Background art
                        if let artURL = artworkURL {
                            CachedAsyncImage(url: artURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(height: 700)
                            .clipped()
                        }

                        // Gradient overlay
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.8), .black]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 700)

                        // Content overlay
                        VStack(alignment: .leading, spacing: 20) {
                            Spacer()

                            // Clear logo or title
                            if let clearLogo = displayMedia.clearLogo, let logoURL = logoURL(for: clearLogo) {
                                CachedAsyncImage(url: logoURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    Text(displayMedia.title)
                                        .font(.system(size: 60, weight: .heavy, design: .default))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: 600, maxHeight: 180, alignment: .leading)
                            } else {
                                Text(displayMedia.title)
                                    .font(.system(size: 60, weight: .heavy, design: .default))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .frame(maxWidth: 1000, alignment: .leading)
                            }

                            // Metadata chips
                            HStack(spacing: 12) {
                                // Content type
                                Text(displayMedia.type == "movie" ? "Movie" : "TV Show")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)

                                if displayMedia.audienceRating != nil || displayMedia.contentRating != nil || displayMedia.year != nil || displayMedia.duration != nil {
                                    ForEach(metadataComponents, id: \.self) { component in
                                        Text("·")
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(component)
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                            }

                            // Summary
                            if let summary = displayMedia.summary, !summary.isEmpty {
                                Text(summary)
                                    .font(.system(size: 26, weight: .regular))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(4)
                                    .frame(maxWidth: 1200, alignment: .leading)
                            }

                            // Action buttons
                            HStack(spacing: 20) {
                                // Play button (primary)
                                Button {
                                    handlePlayButton()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                        Text(playButtonLabel)
                                            .font(.system(size: 24, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(.clearGlass)

                                // Shuffle button (shows/seasons only)
                                if displayMedia.type == "show" && !seasons.isEmpty {
                                    Button {
                                        handleShufflePlay()
                                    } label: {
                                        Image(systemName: "shuffle")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(CardButtonStyle())
                                }

                                // Mark as watched/unwatched
                                Button {
                                    Task {
                                        await toggleWatched()
                                    }
                                } label: {
                                    Image(systemName: displayMedia.isWatched ? "checkmark.circle.fill" : "checkmark.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(CardButtonStyle())
                            }
                        }
                        .padding(.horizontal, 80)
                        .padding(.bottom, 80)
                    }
                    .frame(height: 700)

                    // Content sections below hero
                    VStack(alignment: .leading, spacing: 40) {
                        // Genres
                        if let genres = displayMedia.genre, !genres.isEmpty {
                            HStack(spacing: 12) {
                                ForEach(genres.prefix(5), id: \.tag) { genre in
                                    Text(genre.tag)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.15))
                                        )
                                }
                            }
                        }

                        // Cast
                        if let cast = displayMedia.role, !cast.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Cast")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 24) {
                                        ForEach(cast.prefix(10), id: \.tag) { actor in
                                            VStack(alignment: .leading, spacing: 8) {
                                                // Cast photo placeholder (Plex role doesn't include thumb in tvOS model)
                                                Circle()
                                                    .fill(Color.white.opacity(0.15))
                                                    .frame(width: 140, height: 140)
                                                    .overlay(
                                                        Image(systemName: "person.fill")
                                                            .font(.system(size: 50))
                                                            .foregroundColor(.white.opacity(0.5))
                                                    )

                                                Text(actor.tag)
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                    .frame(width: 140, alignment: .leading)

                                                if let role = actor.role {
                                                    Text(role)
                                                        .font(.system(size: 18, weight: .regular))
                                                        .foregroundColor(.gray)
                                                        .lineLimit(2)
                                                        .frame(width: 140, alignment: .leading)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 20)
                                }
                            }
                        }

                        // TV Show seasons
                        if media.type == "show" && !seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Seasons")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 30) {
                                        ForEach(seasons) { season in
                                            SeasonCard(season: season) {
                                                selectedSeason = season
                                            }
                                            .padding(.vertical, 40)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            print("👁️ [MediaDetailView] View appeared for: \(media.title)")
            print("👁️ [MediaDetailView] authService: \(authService)")
            print("👁️ [MediaDetailView] Has client: \(authService.currentClient != nil)")
        }
        .task {
            print("⚙️ [MediaDetailView] Task started for: \(media.title)")
            await loadDetails()
            print("⚙️ [MediaDetailView] Task completed for: \(media.title)")
        }
        .sheet(item: $selectedSeason) { season in
            let _ = print("📱 [MediaDetailView] Sheet presenting SeasonDetailView for: \(season.title)")
            SeasonDetailView(season: season, show: displayMedia)
                .environmentObject(authService)
        }
        .fullScreenCover(item: $playMedia) { mediaToPlay in
            let _ = print("🎬 [MediaDetailView] Playing: \(mediaToPlay.title)")
            VideoPlayerView(media: mediaToPlay)
                .environmentObject(authService)
        }
    }

    private var displayMedia: PlexMetadata {
        detailedMedia ?? media
    }

    private var playButtonLabel: String {
        if displayMedia.type == "show" {
            if let episode = onDeckEpisode {
                let seasonNum = episode.parentIndex ?? 1
                let episodeNum = episode.index ?? 1
                if episode.progress > 0 {
                    return "Resume S\(seasonNum)E\(episodeNum)"
                } else {
                    return "Play S\(seasonNum)E\(episodeNum)"
                }
            }
            return "Play S1E1"
        }
        return displayMedia.progress > 0 ? "Resume" : "Play"
    }

    private var metadataComponents: [String] {
        var components: [String] = []

        if let rating = displayMedia.audienceRating {
            components.append("★ \(String(format: "%.1f", rating))")
        }

        if let contentRating = displayMedia.contentRating {
            components.append(contentRating)
        }

        if let year = displayMedia.year {
            components.append(String(year))
        }

        if let duration = displayMedia.duration {
            components.append(formatDuration(duration))
        }

        return components
    }

    private var artworkURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let art = displayMedia.art else {
            return nil
        }

        var urlString = baseURL.absoluteString + art
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }

    private func logoURL(for clearLogo: String) -> URL? {
        // clearLogo already includes the full URL from the Image array
        if clearLogo.starts(with: "http") {
            return URL(string: clearLogo)
        }

        // Fallback to building URL if it's a relative path
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url else {
            return nil
        }

        var urlString = baseURL.absoluteString + clearLogo
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }

    private func handlePlayButton() {
        if displayMedia.type == "show" {
            if let episode = onDeckEpisode {
                playMedia = episode
            } else if let firstSeason = seasons.first {
                selectedSeason = firstSeason
            }
        } else {
            playMedia = displayMedia
        }
    }

    private func handleShufflePlay() {
        // For future implementation: shuffle play
        print("🔀 [MediaDetailView] Shuffle play requested for: \(displayMedia.title)")
    }

    private func loadDetails() async {
        guard let client = authService.currentClient,
              let ratingKey = media.ratingKey else {
            return
        }

        isLoading = true

        do {
            let detailed = try await client.getMetadata(ratingKey: ratingKey)
            detailedMedia = detailed

            // If it's a TV show, load seasons and onDeck episode
            if media.type == "show" {
                seasons = try await client.getChildren(ratingKey: ratingKey)

                // Try to get the onDeck episode for this show
                let onDeckItems = try await client.getOnDeck()
                onDeckEpisode = onDeckItems.first { episode in
                    episode.grandparentRatingKey == ratingKey
                }

                print("📺 [MediaDetailView] OnDeck episode for show: \(onDeckEpisode?.title ?? "none")")
            }
        } catch {
            print("Error loading details: \(error)")
        }

        isLoading = false
    }

    private func toggleWatched() async {
        guard let client = authService.currentClient,
              let ratingKey = displayMedia.ratingKey else {
            return
        }

        do {
            if displayMedia.isWatched {
                try await client.unscrobble(ratingKey: ratingKey)
            } else {
                try await client.scrobble(ratingKey: ratingKey)
            }

            // Reload details
            await loadDetails()
        } catch {
            print("Error toggling watched: \(error)")
        }
    }

    private func formatDuration(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let minutes = seconds / 60
        let hours = minutes / 60

        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SeasonCard: View {
    let season: PlexMetadata
    let action: () -> Void
    @State private var isFocused = false
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                CachedAsyncImage(url: posterURL) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(2/3, contentMode: .fill)
                        .overlay(
                            Image(systemName: "tv")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 250, height: 375)
                .cornerRadius(10)

                Text(season.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 250, alignment: .leading)

                if let leafCount = season.leafCount {
                    Text("\(leafCount) episode\(leafCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: 250, alignment: .leading)
                }
            }
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
        }
        .buttonStyle(.plain)
        .onFocusChange(true) { focused in
            isFocused = focused
        }
    }

    private var posterURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let thumb = season.thumb else {
            return nil
        }

        var urlString = baseURL.absoluteString + thumb
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }
}

#Preview {
    MediaDetailView(media: PlexMetadata(
        ratingKey: "1",
        key: "/library/metadata/1",
        guid: nil,
        studio: nil,
        type: "movie",
        title: "Sample Movie",
        titleSort: nil,
        librarySectionTitle: nil,
        librarySectionID: nil,
        librarySectionKey: nil,
        contentRating: "PG-13",
        summary: "A great movie about something interesting.",
        rating: nil,
        audienceRating: 8.5,
        year: 2024,
        tagline: nil,
        thumb: nil,
        art: nil,
        duration: 7200000,
        originallyAvailableAt: nil,
        addedAt: nil,
        updatedAt: nil,
        audienceRatingImage: nil,
        primaryExtraKey: nil,
        ratingImage: nil,
        viewOffset: nil,
        viewCount: nil,
        lastViewedAt: nil,
        grandparentRatingKey: nil,
        grandparentKey: nil,
        grandparentTitle: nil,
        grandparentThumb: nil,
        grandparentArt: nil,
        parentRatingKey: nil,
        parentKey: nil,
        parentTitle: nil,
        parentThumb: nil,
        parentIndex: nil,
        index: nil,
        childCount: nil,
        leafCount: nil,
        viewedLeafCount: nil,
        media: nil,
        role: nil,
        genre: nil,
        director: nil,
        writer: nil,
        country: nil,
        Image: nil
    ))
    .environmentObject(PlexAuthService())
}
