import AVFoundation
import Observation

@Observable
@MainActor
final class HeroPreviewManager {
    var isActive = false
    var player: AVPlayer?

    private var previewTask: Task<Void, Never>?
    private var trailerCache: [String: String?] = [:]
    private var endObserver: NSObjectProtocol?

    private let previewDelay: Duration = .milliseconds(1500)

    func onHeroChanged(ratingKey: String, client: PlexClient) {
        previewTask?.cancel()
        stop()

        previewTask = Task {
            do {
                try await Task.sleep(for: previewDelay)
            } catch { return }

            guard !Task.isCancelled else { return }

            // Check cache — nil value means "no trailer available"
            if let cached = trailerCache[ratingKey] {
                guard let urlString = cached else { return }
                startPlayback(urlString: urlString)
                return
            }

            // Fetch extras
            guard let extras = try? await client.getExtras(ratingKey: ratingKey),
                  !Task.isCancelled else {
                if !Task.isCancelled { trailerCache[ratingKey] = .some(nil) }
                return
            }

            // Find first trailer
            guard let trailer = extras.first(where: { $0.subtype == "trailer" }) else {
                trailerCache[ratingKey] = .some(nil)
                return
            }

            // Get video URL
            guard let data = try? await client.getVideoPlaybackData(ratingKey: trailer.ratingKey),
                  !Task.isCancelled else {
                return
            }

            let urlString = data.videoURL.absoluteString
            trailerCache[ratingKey] = urlString

            guard !Task.isCancelled else { return }

            startPlayback(urlString: urlString)
        }
    }

    func stop() {
        removeEndObserver()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        isActive = false
    }

    /// Returns the current player without stopping it (for handoff to detail page).
    func detachPlayer() -> AVPlayer? {
        removeEndObserver()
        let detached = player
        player = nil
        isActive = false
        previewTask?.cancel()
        return detached
    }

    func cleanup() {
        previewTask?.cancel()
        stop()
    }

    private func startPlayback(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let avPlayer = AVPlayer(url: url)
        applyBrowsingVolume(to: avPlayer)
        player = avPlayer
        isActive = true
        avPlayer.play()
        observeEnd(for: avPlayer)
    }

    /// When the trailer finishes, fade out `isActive` so the static wallpaper is revealed.
    private func observeEnd(for avPlayer: AVPlayer) {
        removeEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.player === avPlayer else { return }
            self.player?.pause()
            self.player = nil
            self.isActive = false
        }
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }

    /// Applies the user's preview audio setting for non-full-screen playback.
    static func applyBrowsingVolume(to player: AVPlayer) {
        let raw = UserDefaults.standard.string(forKey: "previewAudioMode") ?? "fullScreenOnly"
        switch raw {
        case "full":
            player.isMuted = false
            player.volume = 1.0
        case "low":
            player.isMuted = false
            player.volume = 0.3
        default:
            player.isMuted = true
        }
    }

    private func applyBrowsingVolume(to player: AVPlayer) {
        Self.applyBrowsingVolume(to: player)
    }
}
