//
//  VideoPlayerView.swift
//  Plezy tvOS
//
//  Video player with AVKit
//

import SwiftUI
import AVKit
import AVFoundation
import Combine

struct VideoPlayerView: View {
    let media: PlexMetadata
    @EnvironmentObject var authService: PlexAuthService
    @Environment(\.dismiss) var dismiss
    @StateObject private var playerManager: VideoPlayerManager
    @State private var showControls = true

    init(media: PlexMetadata) {
        self.media = media
        _playerManager = StateObject(wrappedValue: VideoPlayerManager(media: media))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = playerManager.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        Task {
                            await playerManager.setupPlayer(authService: authService)
                        }
                    }
                    .onDisappear {
                        playerManager.cleanup()
                    }
            } else if playerManager.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Loading video...")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            } else if let error = playerManager.error {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Error loading video")
                        .font(.title)
                        .foregroundColor(.white)

                    Text(error)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 100)

                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(CardButtonStyle())
                }
            }
        }
    }
}

@MainActor
class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var error: String?

    private let media: PlexMetadata
    private var timeObserver: Any?
    private var playerItem: AVPlayerItem?

    init(media: PlexMetadata) {
        self.media = media
    }

    func setupPlayer(authService: PlexAuthService) async {
        guard let client = authService.currentClient,
              let server = authService.selectedServer else {
            error = "No server connection"
            isLoading = false
            return
        }

        isLoading = true
        error = nil

        do {
            // Get detailed metadata
            let detailedMedia = try await client.getMetadata(ratingKey: media.ratingKey)

            // Build video URL
            guard let mediaItem = detailedMedia.media?.first,
                  let part = mediaItem.part?.first else {
                error = "No media available"
                isLoading = false
                return
            }

            guard let connection = server.connections.first,
                  let baseURL = connection.url else {
                error = "Invalid server connection"
                isLoading = false
                return
            }

            var urlString = baseURL.absoluteString + part.key

            // Add transcoding parameters for compatibility
            let params = [
                "X-Plex-Platform": "tvOS",
                "directPlay": "1",
                "directStream": "1",
                "protocol": "hls",
                "fastSeek": "1",
                "path": part.key,
                "mediaIndex": "0",
                "partIndex": "0",
                "X-Plex-Token": server.accessToken ?? ""
            ]

            let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            urlString += "?" + queryString

            guard let videoURL = URL(string: urlString) else {
                error = "Invalid video URL"
                isLoading = false
                return
            }

            // Create player item
            let asset = AVURLAsset(url: videoURL)
            playerItem = AVPlayerItem(asset: asset)

            // Note: externalSubtitleOptionLanguages is not available on tvOS
            // External subtitle options need to be handled differently

            // Create player
            let player = AVPlayer(playerItem: playerItem)
            player.allowsExternalPlayback = true

            // Resume from saved position if available
            if let viewOffset = media.viewOffset, viewOffset > 0 {
                let seconds = Double(viewOffset) / 1000.0
                await player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
            }

            self.player = player

            // Start playback
            player.play()

            // Setup progress tracking
            setupProgressTracking(client: client, player: player)

            isLoading = false

        } catch {
            self.error = "Failed to load video: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func setupProgressTracking(client: PlexAPIClient, player: AVPlayer) {
        // Update progress every 10 seconds
        let interval = CMTime(seconds: 10, preferredTimescale: 600)

        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = player.currentItem?.duration,
                  duration.isNumeric else {
                return
            }

            let currentTime = CMTimeGetSeconds(time)
            let totalDuration = CMTimeGetSeconds(duration)

            // Update timeline
            Task {
                do {
                    try await client.updateTimeline(
                        ratingKey: self.media.ratingKey,
                        state: player.rate > 0 ? .playing : .paused,
                        time: Int(currentTime * 1000),
                        duration: Int(totalDuration * 1000)
                    )

                    // Mark as watched when 90% complete
                    if currentTime / totalDuration > 0.9 {
                        try await client.scrobble(ratingKey: self.media.ratingKey)
                    }
                } catch {
                    print("Error updating timeline: \(error)")
                }
            }
        }
    }

    func cleanup() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        player?.pause()
        player = nil
        playerItem = nil
    }

    deinit {
        Task { @MainActor in
            cleanup()
        }
    }
}

#Preview {
    VideoPlayerView(media: PlexMetadata(
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
        country: nil
    ))
    .environmentObject(PlexAuthService())
}
