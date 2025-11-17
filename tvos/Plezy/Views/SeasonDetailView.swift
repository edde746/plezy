//
//  SeasonDetailView.swift
//  Beacon tvOS
//
//  Episode list for a TV season
//

import SwiftUI

struct SeasonDetailView: View {
    let season: PlexMetadata
    let show: PlexMetadata
    @EnvironmentObject var authService: PlexAuthService
    @Environment(\.dismiss) var dismiss
    @State private var episodes: [PlexMetadata] = []
    @State private var isLoading = true
    @State private var selectedEpisode: PlexMetadata?
    @State private var showVideoPlayer = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
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

                    VStack(alignment: .leading, spacing: 5) {
                        Text(show.title)
                            .font(.title3)
                            .foregroundColor(Color.beaconTextTertiary)

                        Text(season.title)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.beaconTextSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }

                    Spacer()
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 30)

                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Loading episodes...")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(episodes) { episode in
                                EpisodeRow(episode: episode) {
                                    selectedEpisode = episode
                                    showVideoPlayer = true
                                }
                            }
                        }
                        .padding(60)
                    }
                }
            }
        }
        .task {
            await loadEpisodes()
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let episode = selectedEpisode {
                VideoPlayerView(media: episode)
                    .environmentObject(authService)
            }
        }
    }

    private func loadEpisodes() async {
        guard let client = authService.currentClient,
              let ratingKey = season.ratingKey else {
            return
        }

        isLoading = true

        do {
            episodes = try await client.getChildren(ratingKey: ratingKey)
        } catch {
            print("Error loading episodes: \(error)")
        }

        isLoading = false
    }
}

struct EpisodeRow: View {
    let episode: PlexMetadata
    let action: () -> Void
    @State private var isFocused = false
    @State private var isWatched: Bool
    @EnvironmentObject var authService: PlexAuthService

    init(episode: PlexMetadata, action: @escaping () -> Void) {
        self.episode = episode
        self.action = action
        self._isWatched = State(initialValue: episode.isWatched)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 30) {
                // Thumbnail
                CachedAsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(
                            Image(systemName: "tv")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 450, height: 253)
                .cornerRadius(10)
                .overlay(
                    ZStack {
                        // Progress bar with beacon gradient
                        if episode.progress > 0 && episode.progress < 0.98 {
                            VStack {
                                Spacer()
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background track
                                        Capsule()
                                            .fill(.regularMaterial)
                                            .opacity(0.4)

                                        // Progress fill with beacon gradient
                                        Capsule()
                                            .fill(Color.beaconGradient)
                                            .frame(width: geometry.size.width * episode.progress)
                                            .shadow(color: Color.beaconMagenta.opacity(0.5), radius: 4, x: 0, y: 0)
                                    }
                                }
                                .frame(height: 6)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                            }
                        }

                        // Watched indicator
                        if isWatched {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.green)
                                        .padding(15)
                                }
                                Spacer()
                            }
                        }

                        // Watch/Unwatch button (visible on focus)
                        if isFocused {
                            VStack {
                                HStack {
                                    Button {
                                        Task {
                                            await toggleWatched()
                                        }
                                    } label: {
                                        Image(systemName: isWatched ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(
                                                ZStack {
                                                    Circle()
                                                        .fill(.regularMaterial)
                                                        .opacity(0.8)

                                                    Circle()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [
                                                                    Color.beaconBlue.opacity(0.2),
                                                                    Color.beaconPurple.opacity(0.15)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .blendMode(.plusLighter)
                                                }
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(15)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }

                        // Play icon
                        if isFocused {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                        }
                    }
                )

                // Info
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Episode \(episode.index ?? 0)")
                            .font(.headline)
                            .foregroundColor(.gray)

                        if let duration = episode.duration {
                            Text("•")
                                .foregroundColor(.gray)
                            Text(formatDuration(duration))
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }

                    Text(episode.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    if let summary = episode.summary {
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.regularMaterial)
                        .opacity(isFocused ? 0.35 : 0.15)

                    if isFocused {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.beaconBlue.opacity(0.12),
                                        Color.beaconPurple.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.plusLighter)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(
                        LinearGradient(
                            colors: isFocused ? [
                                Color.beaconBlue,
                                Color.beaconPurple
                            ] : [.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 4 : 0
                    )
            )
            .shadow(color: isFocused ? Color.beaconPurple.opacity(0.4) : .clear, radius: isFocused ? 15 : 0, x: 0, y: isFocused ? 8 : 0)
        }
        .buttonStyle(.plain)
        .onFocusChange(true) { focused in
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = focused
            }
        }
    }

    private var thumbnailURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let thumb = episode.thumb else {
            return nil
        }

        var urlString = baseURL.absoluteString + thumb
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }

    private func formatDuration(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let minutes = seconds / 60
        return "\(minutes) min"
    }

    private func toggleWatched() async {
        guard let client = authService.currentClient,
              let ratingKey = episode.ratingKey else {
            return
        }

        do {
            if isWatched {
                try await client.unscrobble(ratingKey: ratingKey)
            } else {
                try await client.scrobble(ratingKey: ratingKey)
            }
            // Toggle the state
            isWatched.toggle()
        } catch {
            print("Error toggling watched status: \(error)")
        }
    }
}

#Preview {
    SeasonDetailView(
        season: PlexMetadata(
            ratingKey: "1",
            key: "/library/metadata/1",
            guid: nil,
            studio: nil,
            type: "season",
            title: "Season 1",
            titleSort: nil,
            librarySectionTitle: nil,
            librarySectionID: nil,
            librarySectionKey: nil,
            contentRating: nil,
            summary: nil,
            rating: nil,
            audienceRating: nil,
            year: nil,
            tagline: nil,
            thumb: nil,
            art: nil,
            duration: nil,
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
            leafCount: 10,
            viewedLeafCount: nil,
            media: nil,
            role: nil,
            genre: nil,
            director: nil,
            writer: nil,
            country: nil,
            Image: nil
        ),
        show: PlexMetadata(
            ratingKey: "0",
            key: "/library/metadata/0",
            guid: nil,
            studio: nil,
            type: "show",
            title: "Sample Show",
            titleSort: nil,
            librarySectionTitle: nil,
            librarySectionID: nil,
            librarySectionKey: nil,
            contentRating: nil,
            summary: nil,
            rating: nil,
            audienceRating: nil,
            year: nil,
            tagline: nil,
            thumb: nil,
            art: nil,
            duration: nil,
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
        )
    )
    .environmentObject(PlexAuthService())
}
