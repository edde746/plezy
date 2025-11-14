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
import MediaPlayer
import AVFAudio

struct VideoPlayerView: View {
    let media: PlexMetadata
    @EnvironmentObject var authService: PlexAuthService
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var playerManager: VideoPlayerManager

    init(media: PlexMetadata) {
        print("🎥 [VideoPlayerView] init() called for: \(media.title)")
        self.media = media
        _playerManager = StateObject(wrappedValue: VideoPlayerManager(media: media))
    }

    var body: some View {
        let _ = print("🎥 [VideoPlayerView] body evaluated for: \(media.title)")
        let _ = print("🎥 [VideoPlayerView] playerViewController: \(playerManager.playerViewController != nil)")
        let _ = print("🎥 [VideoPlayerView] isLoading: \(playerManager.isLoading)")
        let _ = print("🎥 [VideoPlayerView] error: \(playerManager.error ?? "none")")
        ZStack {
            Color.black.ignoresSafeArea()

            if playerManager.playerViewController != nil {
                TVPlayerViewController(playerManager: playerManager)
                    .ignoresSafeArea()
                    .onAppear {
                        print("👁️ [VideoPlayerView] TVPlayerViewController appeared for: \(media.title)")
                        print("👁️ [VideoPlayerView] Has authService: \(authService)")
                        print("👁️ [VideoPlayerView] Starting player setup...")
                        Task {
                            await playerManager.setupPlayer(authService: authService)
                        }
                    }
                    .onDisappear {
                        print("👋 [VideoPlayerView] TVPlayerViewController disappeared for: \(media.title)")
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

                    HStack(spacing: 20) {
                        Button {
                            print("🔄 [VideoPlayerView] Retry button tapped")
                            Task {
                                await playerManager.setupPlayer(authService: authService)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.title3)
                        }
                        .buttonStyle(ClearGlassButtonStyle())

                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            print("🔄 [VideoPlayerView] Scene phase changed from \(oldPhase) to \(newPhase)")
            switch newPhase {
            case .background:
                print("⏸️ [VideoPlayerView] App backgrounded - pausing playback")
                playerManager.player?.pause()
            case .active:
                print("▶️ [VideoPlayerView] App active - resuming playback if it was playing")
                // Only resume if we're not at the error or loading state
                if playerManager.player != nil && playerManager.error == nil {
                    playerManager.player?.play()
                }
            case .inactive:
                print("💤 [VideoPlayerView] App inactive")
            @unknown default:
                break
            }
        }
    }
}

// MARK: - AVPlayerViewController Wrapper

struct TVPlayerViewController: UIViewControllerRepresentable {
    @ObservedObject var playerManager: VideoPlayerManager

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()

        #if os(tvOS)
        // tvOS-specific configuration
        // Note: PiP settings not available on tvOS
        #else
        // iOS-specific configuration
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        #endif

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update player if it changes
        if uiViewController.player !== playerManager.player {
            uiViewController.player = playerManager.player
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        // Coordinator for future use if needed
    }
}

@MainActor
class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    @Published var playerViewController: AVPlayerViewController?
    @Published var isLoading = true
    @Published var error: String?
    @Published var availableAudioTracks: [AVMediaSelectionOption] = []
    @Published var availableSubtitleTracks: [AVMediaSelectionOption] = []
    @Published var currentAudioTrack: AVMediaSelectionOption?
    @Published var currentSubtitleTrack: AVMediaSelectionOption?

    private let media: PlexMetadata
    private var timeObserver: Any?
    private var playerItem: AVPlayerItem?
    private var remoteCommandsConfigured = false

    init(media: PlexMetadata) {
        self.media = media
        self.playerViewController = AVPlayerViewController()
    }

    func setupPlayer(authService: PlexAuthService) async {
        guard let client = authService.currentClient,
              let server = authService.selectedServer else {
            error = "No server connection"
            isLoading = false
            return
        }

        guard let ratingKey = media.ratingKey else {
            error = "Invalid media item"
            isLoading = false
            return
        }

        isLoading = true
        error = nil

        do {
            print("🎬 [Player] Loading video for: \(media.title)")

            // Get detailed metadata
            let detailedMedia = try await client.getMetadata(ratingKey: ratingKey)

            print("🎬 [Player] Detailed metadata received")
            print("🎬 [Player] Type: \(detailedMedia.type ?? "unknown")")
            print("🎬 [Player] Title: \(detailedMedia.title)")
            print("🎬 [Player] Has media array: \(detailedMedia.media != nil)")
            print("🎬 [Player] Media count: \(detailedMedia.media?.count ?? 0)")
            if let media = detailedMedia.media?.first {
                print("🎬 [Player] First media item exists")
                print("🎬 [Player] Has part array: \(media.part != nil)")
                print("🎬 [Player] Part count: \(media.part?.count ?? 0)")
                if let part = media.part?.first {
                    print("🎬 [Player] Part key: \(part.key)")
                }
            }

            // Build video URL
            guard let mediaItem = detailedMedia.media?.first,
                  let part = mediaItem.part?.first else {
                error = "No media available"
                isLoading = false
                print("❌ [Player] No media or part found")
                return
            }

            guard let connection = server.connections.first,
                  let baseURL = connection.url else {
                error = "Invalid server connection"
                isLoading = false
                print("❌ [Player] No connection found")
                return
            }

            // Build direct play URL with token
            var urlString = baseURL.absoluteString + part.key
            if !urlString.contains("?") {
                urlString += "?"
            } else {
                urlString += "&"
            }
            urlString += "X-Plex-Token=\(server.accessToken ?? "")"

            guard let videoURL = URL(string: urlString) else {
                error = "Invalid video URL"
                isLoading = false
                print("❌ [Player] Invalid URL: \(urlString)")
                return
            }

            print("🎬 [Player] Video URL: \(videoURL)")

            // Create player item with metadata
            let asset = AVURLAsset(url: videoURL)
            playerItem = AVPlayerItem(asset: asset)

            // Configure audio session for playback
            setupAudioSession()

            // Set up metadata for Now Playing
            setupNowPlayingMetadata(media: detailedMedia, server: server, baseURL: baseURL)

            // Create player
            let player = AVPlayer(playerItem: playerItem)
            player.allowsExternalPlayback = true

            // Resume from saved position if available
            if let viewOffset = detailedMedia.viewOffset, viewOffset > 0 {
                let seconds = Double(viewOffset) / 1000.0
                print("🎬 [Player] Resuming from \(seconds)s")
                await player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
            }

            self.player = player

            // Start playback
            player.play()
            print("🎬 [Player] Starting playback")

            // Setup progress tracking
            setupProgressTracking(client: client, player: player, ratingKey: ratingKey)

            // Setup remote command handling
            setupRemoteCommands(player: player)

            // Discover and configure audio/subtitle tracks
            discoverTracks()

            isLoading = false

        } catch {
            print("❌ [Player] Error: \(error)")
            self.error = "Failed to load video: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func setupAudioSession() {
        #if os(tvOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            try audioSession.setActive(true)
            print("🔊 [Player] Audio session configured for playback")
        } catch {
            print("⚠️ [Player] Failed to configure audio session: \(error)")
        }
        #endif
    }

    private func setupNowPlayingMetadata(media: PlexMetadata, server: PlexServer, baseURL: URL) {
        var nowPlayingInfo: [String: Any] = [:]

        // Title
        if media.type == "episode" {
            // For TV shows: "Show Name - S1E1 - Episode Title"
            if let showTitle = media.grandparentTitle {
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = showTitle
                nowPlayingInfo[MPMediaItemPropertyTitle] = media.title
                let seasonEpisode = media.formatSeasonEpisode()
                nowPlayingInfo[MPNowPlayingInfoPropertyChapterNumber] = seasonEpisode as Any
            }
        } else {
            // For movies
            nowPlayingInfo[MPMediaItemPropertyTitle] = media.title
        }

        // Duration
        if let duration = media.duration, duration > 0 {
            let seconds = Double(duration) / 1000.0
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = seconds
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("🎬 [Player] Set Now Playing metadata: \(media.title)")

        // Artwork - load asynchronously
        if let artPath = media.art ?? media.thumb {
            var artURLString = baseURL.absoluteString + artPath
            if let token = server.accessToken {
                artURLString += "?X-Plex-Token=\(token)"
            }
            if let artURL = URL(string: artURLString) {
                Task {
                    await loadArtwork(from: artURL)
                }
            }
        }
    }

    private func loadArtwork(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                print("🎬 [Player] Loaded artwork")
            }
        } catch {
            print("⚠️ [Player] Failed to load artwork: \(error)")
        }
    }

    private func setupProgressTracking(client: PlexAPIClient, player: AVPlayer, ratingKey: String) {
        // Update progress every 30 seconds (reduces server load while maintaining reasonable tracking)
        let interval = CMTime(seconds: 30, preferredTimescale: 600)

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
                        ratingKey: ratingKey,
                        state: player.rate > 0 ? .playing : .paused,
                        time: Int(currentTime * 1000),
                        duration: Int(totalDuration * 1000)
                    )

                    // Mark as watched when 90% complete
                    if currentTime / totalDuration > 0.9 {
                        try await client.scrobble(ratingKey: ratingKey)
                    }
                } catch {
                    print("Error updating timeline: \(error)")
                }
            }
        }
    }

    private func setupRemoteCommands(player: AVPlayer) {
        guard !remoteCommandsConfigured else { return }

        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            player.play()
            print("🎮 [RemoteCommands] Play command executed")
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            player.pause()
            print("🎮 [RemoteCommands] Pause command executed")
            return .success
        }

        // Toggle play/pause
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            if player.rate > 0 {
                player.pause()
                print("🎮 [RemoteCommands] Toggle pause executed")
            } else {
                player.play()
                print("🎮 [RemoteCommands] Toggle play executed")
            }
            return .success
        }

        // Skip forward (15 seconds)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                let currentTime = player.currentTime()
                let newTime = CMTimeAdd(currentTime, CMTime(seconds: skipEvent.interval, preferredTimescale: 600))
                player.seek(to: newTime)
                print("🎮 [RemoteCommands] Skip forward \(skipEvent.interval)s")
                return .success
            }
            return .commandFailed
        }

        // Skip backward (15 seconds)
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            if let skipEvent = event as? MPSkipIntervalCommandEvent {
                let currentTime = player.currentTime()
                let newTime = CMTimeSubtract(currentTime, CMTime(seconds: skipEvent.interval, preferredTimescale: 600))
                player.seek(to: max(newTime, CMTime.zero))
                print("🎮 [RemoteCommands] Skip backward \(skipEvent.interval)s")
                return .success
            }
            return .commandFailed
        }

        remoteCommandsConfigured = true
        print("🎮 [RemoteCommands] Remote command handling configured")
    }

    private func removeRemoteCommands() {
        guard remoteCommandsConfigured else { return }

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)

        remoteCommandsConfigured = false
        print("🎮 [RemoteCommands] Remote commands removed")
    }

    // MARK: - Audio & Subtitle Track Management

    /// Discover available audio and subtitle tracks from the player item
    private func discoverTracks() {
        guard let playerItem = playerItem else {
            print("⚠️ [Tracks] No player item available")
            return
        }

        // Get audio tracks
        if let audioGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            availableAudioTracks = audioGroup.options
            currentAudioTrack = playerItem.selectedMediaOption(in: audioGroup)

            print("🎵 [Tracks] Found \(availableAudioTracks.count) audio tracks")
            for (index, track) in availableAudioTracks.enumerated() {
                let language = track.locale?.identifier ?? "unknown"
                let title = track.displayName
                let selected = track == currentAudioTrack ? "✓" : " "
                print("🎵 [Tracks]   [\(selected)] \(index): \(title) (\(language))")
            }
        }

        // Get subtitle tracks
        if let subtitleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            availableSubtitleTracks = subtitleGroup.options
            currentSubtitleTrack = playerItem.selectedMediaOption(in: subtitleGroup)

            print("📝 [Tracks] Found \(availableSubtitleTracks.count) subtitle tracks")
            for (index, track) in availableSubtitleTracks.enumerated() {
                let language = track.locale?.identifier ?? "unknown"
                let title = track.displayName
                let selected = track == currentSubtitleTrack ? "✓" : " "
                print("📝 [Tracks]   [\(selected)] \(index): \(title) (\(language))")
            }
        }
    }

    /// Select an audio track
    func selectAudioTrack(_ track: AVMediaSelectionOption?) {
        guard let playerItem = playerItem,
              let audioGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else {
            print("⚠️ [Tracks] Cannot select audio track - no audio group")
            return
        }

        playerItem.select(track, in: audioGroup)
        currentAudioTrack = track

        if let track = track {
            print("🎵 [Tracks] Selected audio track: \(track.displayName)")
        } else {
            print("🎵 [Tracks] Disabled audio track")
        }
    }

    /// Select a subtitle track
    func selectSubtitleTrack(_ track: AVMediaSelectionOption?) {
        guard let playerItem = playerItem,
              let subtitleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
            print("⚠️ [Tracks] Cannot select subtitle track - no subtitle group")
            return
        }

        playerItem.select(track, in: subtitleGroup)
        currentSubtitleTrack = track

        if let track = track {
            print("📝 [Tracks] Selected subtitle track: \(track.displayName)")
        } else {
            print("📝 [Tracks] Disabled subtitles")
        }
    }

    /// Select audio track by language code (e.g., "en", "es", "fr")
    func selectAudioTrackByLanguage(_ languageCode: String) {
        let matchingTrack = availableAudioTracks.first { track in
            track.locale?.languageCode == languageCode
        }
        selectAudioTrack(matchingTrack)
    }

    /// Select subtitle track by language code
    func selectSubtitleTrackByLanguage(_ languageCode: String) {
        let matchingTrack = availableSubtitleTracks.first { track in
            track.locale?.languageCode == languageCode
        }
        selectSubtitleTrack(matchingTrack)
    }

    func cleanup() {
        print("🧹 [Player] Cleaning up player resources")

        // Remove remote command handlers
        removeRemoteCommands()

        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        player?.pause()
        player = nil
        playerItem = nil

        // Deactivate audio session
        #if os(tvOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("🔊 [Player] Audio session deactivated")
        } catch {
            print("⚠️ [Player] Failed to deactivate audio session: \(error)")
        }
        #endif
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
        country: nil,
        Image: nil
    ))
    .environmentObject(PlexAuthService())
}
