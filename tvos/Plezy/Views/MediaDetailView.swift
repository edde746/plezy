//
//  MediaDetailView.swift
//  Plezy tvOS
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
    @State private var isLoading = true
    @State private var selectedSeason: PlexMetadata?
    @State private var showVideoPlayer = false

    var body: some View {
        let _ = print("📄 [MediaDetailView] body evaluated for: \(media.title)")
        ZStack {
            // Background with backdrop
            if let artURL = artworkURL {
                AsyncImage(url: artURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 50)
                        .opacity(0.3)
                } placeholder: {
                    Color.black
                }
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Back button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 40)

                    // Main content
                    HStack(alignment: .top, spacing: 40) {
                        // Poster
                        AsyncImage(url: posterURL) { image in
                            image
                                .resizable()
                                .aspectRatio(2/3, contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(2/3, contentMode: .fill)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 400, height: 600)
                        .cornerRadius(15)
                        .shadow(radius: 20)

                        // Info
                        VStack(alignment: .leading, spacing: 20) {
                            Text(displayMedia.title)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)

                            // Metadata
                            HStack(spacing: 15) {
                                if let year = displayMedia.year {
                                    Text(String(year))
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }

                                if let rating = displayMedia.contentRating {
                                    Text(rating)
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .stroke(Color.gray, lineWidth: 2)
                                        )
                                }

                                if let duration = displayMedia.duration {
                                    Text(formatDuration(duration))
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }

                                if let audienceRating = displayMedia.audienceRating {
                                    HStack(spacing: 5) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", audienceRating))
                                            .foregroundColor(.white)
                                    }
                                    .font(.title3)
                                }
                            }

                            // Summary
                            if let summary = displayMedia.summary, !summary.isEmpty {
                                Text(summary)
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(5)
                                    .padding(.top, 10)
                            }

                            // Genres
                            if let genres = displayMedia.genre, !genres.isEmpty {
                                HStack {
                                    ForEach(genres.prefix(4), id: \.tag) { genre in
                                        Text(genre.tag)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.2))
                                            )
                                    }
                                }
                                .padding(.top, 10)
                            }

                            // Actions
                            HStack(spacing: 20) {
                                // Play button
                                Button {
                                    print("▶️ [MediaDetailView] Play button tapped for: \(displayMedia.title)")
                                    print("▶️ [MediaDetailView] Setting showVideoPlayer = true")
                                    showVideoPlayer = true
                                    print("▶️ [MediaDetailView] showVideoPlayer is now: \(showVideoPlayer)")
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: displayMedia.progress > 0 ? "play.fill" : "play.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                        Text(displayMedia.progress > 0 ? "Resume" : "Play")
                                            .font(.system(size: 24, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(ClearGlassButtonStyle())

                                // Mark as watched/unwatched
                                Button {
                                    Task {
                                        await toggleWatched()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: displayMedia.isWatched ? "checkmark.circle.fill" : "checkmark.circle")
                                            .font(.system(size: 20))
                                        Text(displayMedia.isWatched ? "Watched" : "Mark Watched")
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(CardButtonStyle())
                            }
                            .padding(.top, 20)

                            // Cast
                            if let cast = displayMedia.role?.prefix(5), !cast.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Cast")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.top, 20)

                                    ForEach(Array(cast), id: \.tag) { actor in
                                        HStack {
                                            Text(actor.tag)
                                                .foregroundColor(.white)
                                            if let role = actor.role {
                                                Text("as \(role)")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .font(.headline)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // TV Show seasons
                    if media.type == "show" && !seasons.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Seasons")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 20) {
                                    ForEach(seasons) { season in
                                        SeasonCard(season: season) {
                                            selectedSeason = season
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 40)
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
        .fullScreenCover(isPresented: $showVideoPlayer) {
            let _ = print("🎬 [MediaDetailView] FullScreenCover triggered. showVideoPlayer: \(showVideoPlayer), media type: \(media.type ?? "unknown")")
            if media.type == "show" {
                // For shows, need to pick an episode first
                if let season = seasons.first {
                    let _ = print("🎬 [MediaDetailView] Presenting SeasonDetailView for first season: \(season.title)")
                    SeasonDetailView(season: season, show: displayMedia)
                        .environmentObject(authService)
                } else {
                    let _ = print("❌ [MediaDetailView] No seasons available for show: \(media.title)")
                    EmptyView()
                }
            } else {
                let _ = print("🎬 [MediaDetailView] Presenting VideoPlayerView for: \(displayMedia.title)")
                VideoPlayerView(media: displayMedia)
                    .environmentObject(authService)
            }
        }
        .onChange(of: showVideoPlayer) { oldValue, newValue in
            print("🔄 [MediaDetailView] showVideoPlayer changed from \(oldValue) to \(newValue)")
        }
    }

    private var displayMedia: PlexMetadata {
        detailedMedia ?? media
    }

    private var posterURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let thumb = displayMedia.thumb else {
            return nil
        }

        var urlString = baseURL.absoluteString + thumb
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
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

    private func loadDetails() async {
        guard let client = authService.currentClient,
              let ratingKey = media.ratingKey else {
            return
        }

        isLoading = true

        do {
            let detailed = try await client.getMetadata(ratingKey: ratingKey)
            detailedMedia = detailed

            // If it's a TV show, load seasons
            if media.type == "show" {
                seasons = try await client.getChildren(ratingKey: ratingKey)
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
                AsyncImage(url: posterURL) { image in
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
            .scaleEffect(isFocused ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onFocusChange(true) { focused in
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = focused
            }
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
