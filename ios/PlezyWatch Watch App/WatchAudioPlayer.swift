import Foundation
import AVFoundation
import Combine
import MediaPlayer
import WatchKit

/// Repeat mode for queue playback
enum RepeatMode: Int, CaseIterable {
    case off = 0
    case one = 1
    case all = 2

    var icon: String {
        switch self {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }

    var isActive: Bool {
        self != .off
    }

    func next() -> RepeatMode {
        let allCases = RepeatMode.allCases
        let currentIndex = allCases.firstIndex(of: self)!
        let nextIndex = (currentIndex + 1) % allCases.count
        return allCases[nextIndex]
    }
}

/// Audio player for the Apple Watch app
/// Handles streaming audio playback from Plex servers
class WatchAudioPlayer: NSObject, ObservableObject {
    static let shared = WatchAudioPlayer()

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    // Published state
    @Published var isPlaying = false
    @Published var currentPosition: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading = false
    @Published var error: String?

    // Queue management
    @Published var queue: [QueueItem] = []
    @Published var currentIndex: Int = 0

    // Queue mode settings
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffled: Bool = false

    // Original queue order (for un-shuffling)
    private var originalQueue: [QueueItem] = []
    private var shuffledIndices: [Int] = []
    private var isFetchingMore = false

    // Extended runtime session keeps the app alive when the screen sleeps
    private var extendedSession: WKExtendedRuntimeSession?

    // Play queue reference for refreshing from Plex
    var playQueueRef: PlayQueueReference?

    var currentItem: QueueItem? {
        guard currentIndex >= 0 && currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    /// Whether there's a queue loaded (even if paused)
    var hasQueue: Bool {
        !queue.isEmpty
    }

    var canGoNext: Bool {
        // Can always go next if repeat all is on
        if repeatMode == .all && queue.count > 0 {
            return true
        }
        return currentIndex < queue.count - 1
    }

    var canGoPrevious: Bool {
        // Can always go previous if repeat all is on
        if repeatMode == .all && queue.count > 0 {
            return true
        }
        return currentIndex > 0
    }

    override init() {
        super.init()
        setupNotifications()
        setupRemoteCommandCenter()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            rlog("[WatchAudio] Audio session interrupted")
            DispatchQueue.main.async { self.isPlaying = false }
        case .ended:
            rlog("[WatchAudio] Audio session interruption ended — always resuming")
            // Always resume playback after interruption on watchOS.
            // The shouldResume flag is unreliable when the screen sleeps.
            DispatchQueue.main.async {
                self.player?.play()
                self.isPlaying = true
                self.updateNowPlayingInfo()
            }
        @unknown default:
            break
        }
    }

    // MARK: - Extended Runtime Session

    /// Start an extended runtime session to keep audio playing when the screen sleeps
    private func startExtendedSession() {
        guard extendedSession == nil || extendedSession?.state == .invalid else {
            rlog("[WatchAudio] Extended session already active")
            return
        }
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        extendedSession = session
        rlog("[WatchAudio] Extended runtime session started")
    }

    /// Stop the extended runtime session
    private func stopExtendedSession() {
        guard let session = extendedSession, session.state == .running else { return }
        session.invalidate()
        extendedSession = nil
        rlog("[WatchAudio] Extended runtime session stopped")
    }

    /// Set up MPRemoteCommandCenter for system Now Playing controls (Digital Crown volume, etc.)
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    /// Update MPNowPlayingInfoCenter with current track info
    private func updateNowPlayingInfo() {
        var info = [String: Any]()

        if let item = currentItem {
            info[MPMediaItemPropertyTitle] = item.title
            info[MPMediaItemPropertyArtist] = item.artist ?? ""
            info[MPMediaItemPropertyPlaybackDuration] = duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentPosition
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    @objc private func playerItemDidFinish(_ notification: Notification) {
        // Only handle if it's the current player item (not a discarded one)
        guard let finishedItem = notification.object as? AVPlayerItem,
              finishedItem === playerItem else { return }
        switch repeatMode {
        case .one:
            // Repeat current track
            seek(to: 0)
            play()
        case .all:
            // Go to next, wrapping to beginning if at end
            if currentIndex < queue.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = 0 // Wrap to beginning
            }
            if let item = currentItem {
                loadAndPlay(item)
            }
        case .off:
            // Normal behavior: go to next or stop
            if currentIndex < queue.count - 1 {
                currentIndex += 1
                if let item = currentItem {
                    loadAndPlay(item)
                }
            } else if playQueueRef != nil {
                // Radio/continuous queue — try to fetch more tracks from Plex
                rlog("[WatchAudio] End of queue, fetching more tracks from Plex...")
                fetchMoreTracks()
            } else {
                isPlaying = false
                updateNowPlayingInfo()
            }
        }

        // Pre-fetch more tracks when we're a few tracks from the end
        if playQueueRef != nil && currentIndex >= queue.count - 3 && queue.count > 1 {
            rlog("[WatchAudio] Near end of queue (\(currentIndex)/\(queue.count)), pre-fetching more...")
            prefetchMoreTracks()
        }
    }

    /// Fetch more tracks and continue playing (called when queue is exhausted)
    private func fetchMoreTracks() {
        isLoading = true
        Task {
            let success = await refreshQueueFromPlex()
            await MainActor.run {
                self.isLoading = false
                if success && !self.queue.isEmpty {
                    // Queue was replaced with fresh tracks — start from beginning
                    self.currentIndex = 0
                    if let item = self.currentItem {
                        self.loadAndPlay(item)
                    }
                } else {
                    rlog("[WatchAudio] Failed to fetch more tracks, stopping")
                    self.isPlaying = false
                    self.updateNowPlayingInfo()
                }
            }
        }
    }

    /// Pre-fetch more tracks and append them to the current queue
    private func prefetchMoreTracks() {
        guard !isFetchingMore else { return }
        isFetchingMore = true
        Task {
            let newItems = await fetchAdditionalTracks()
            await MainActor.run {
                self.isFetchingMore = false
                if !newItems.isEmpty {
                    self.queue.append(contentsOf: newItems)
                    self.originalQueue.append(contentsOf: newItems)
                    rlog("[WatchAudio] Appended \(newItems.count) tracks, queue now \(self.queue.count)")
                }
            }
        }
    }

    /// Fetch additional tracks from the play queue without replacing current queue
    private func fetchAdditionalTracks() async -> [QueueItem] {
        guard let ref = playQueueRef else { return [] }

        let urlString = "\(ref.plexServerUrl)/playQueues/\(ref.playQueueId)?X-Plex-Token=\(ref.plexToken)"
        guard let url = URL(string: urlString) else { return [] }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return [] }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let mediaContainer = json["MediaContainer"] as? [String: Any],
                  let metadata = mediaContainer["Metadata"] as? [[String: Any]] else { return [] }

            let existingIds = Set(queue.map { $0.id })
            let audioTypes: Set<String> = ["track"]

            let client = PlexWatchClient.shared
            // Parse into MusicItems first, then enrich with partKeys
            let musicItems: [MusicItem] = metadata.compactMap { item in
                let itemType = item["type"] as? String ?? ""
                guard audioTypes.contains(itemType) else { return nil }
                guard let key = item["ratingKey"] as? String else { return nil }
                guard !existingIds.contains(key) else { return nil }
                return client.parseMusicItemPublic(item)
            }
            let enriched = await client.enrichWithPartKeys(musicItems)
            return enriched.compactMap { $0.toQueueItem(client: client) }
        } catch {
            rlog("[WatchAudio] Error fetching additional tracks: \(error)")
            return []
        }
    }

    /// Load a queue of items to play
    func loadQueue(_ items: [QueueItem], startIndex: Int = 0, queueRef: PlayQueueReference? = nil) {
        queue = items
        originalQueue = items
        currentIndex = startIndex
        playQueueRef = queueRef
        isShuffled = false
        shuffledIndices = []

        rlog("[WatchAudio] Loading queue with \(items.count) items, startIndex: \(startIndex)")
        if let ref = queueRef {
            rlog("[WatchAudio] Play queue ref: \(ref.playQueueId) at \(ref.plexServerUrl)")
        }

        if let item = currentItem {
            loadAndPlay(item)
        }
    }

    /// Refresh the queue from Plex using the stored play queue reference
    func refreshQueueFromPlex() async -> Bool {
        guard let ref = playQueueRef else {
            rlog("[WatchAudio] No play queue reference to refresh from")
            return false
        }

        rlog("[WatchAudio] Refreshing queue from Plex: \(ref.playQueueId)")

        // Build the play queue URL
        let urlString = "\(ref.plexServerUrl)/playQueues/\(ref.playQueueId)?X-Plex-Token=\(ref.plexToken)"
        guard let url = URL(string: urlString) else {
            rlog("[WatchAudio] Invalid URL for play queue")
            return false
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                rlog("[WatchAudio] Failed to fetch play queue: bad response")
                return false
            }

            // Parse the play queue response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let mediaContainer = json["MediaContainer"] as? [String: Any],
                  let metadata = mediaContainer["Metadata"] as? [[String: Any]] else {
                rlog("[WatchAudio] Failed to parse play queue response")
                return false
            }

            // Convert metadata to MusicItems, enrich with partKeys, then to QueueItems
            let audioTypes: Set<String> = ["track"]
            let client = PlexWatchClient.shared
            let musicItems: [MusicItem] = metadata.compactMap { item in
                let itemType = item["type"] as? String ?? ""
                guard audioTypes.contains(itemType) else { return nil }
                return client.parseMusicItemPublic(item)
            }
            let enriched = await client.enrichWithPartKeys(musicItems)
            let items = enriched.compactMap { $0.toQueueItem(client: client) }

            if !items.isEmpty {
                await MainActor.run {
                    self.queue = items
                    rlog("[WatchAudio] Refreshed queue with \(items.count) items")
                }
                return true
            }

            return false
        } catch {
            rlog("[WatchAudio] Error refreshing queue: \(error)")
            return false
        }
    }

    /// Load and play a specific item
    private func loadAndPlay(_ item: QueueItem) {
        isLoading = true
        error = nil

        guard let url = URL(string: item.streamUrl) else {
            error = "Invalid URL: \(item.streamUrl.prefix(50))"
            isLoading = false
            return
        }

        rlog("[WatchAudio] loadAndPlay: \(item.title)")
        rlog("[WatchAudio] URL: \(item.streamUrl.prefix(100))")

        // Set category synchronously, then activate asynchronously (watchOS requirement)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
        } catch {
            rlog("[WatchAudio] Audio session setCategory failed: \(error)")
            self.error = "Audio category: \(error.localizedDescription)"
            isLoading = false
            return
        }

        // watchOS requires async activation for longFormAudio
        Task { @MainActor in
            do {
                try await AVAudioSession.sharedInstance().activate()
                rlog("[WatchAudio] Audio session activated")
            } catch {
                rlog("[WatchAudio] Audio session activate() failed: \(error)")
                self.error = "Audio activate: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            self.startPlayback(url: url, item: item)
        }
    }

    /// Actually start AVPlayer playback (called after audio session is activated)
    @MainActor
    private func startPlayback(url: URL, item: QueueItem) {
        // Token is already in the URL query string — no custom headers needed
        let asset = AVURLAsset(url: url)
        let newItem = AVPlayerItem(asset: asset)
        playerItem = newItem

        // Clear old subscriptions before adding new ones
        cancellables.removeAll()

        // Observe player item status
        newItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handlePlayerItemStatus(status)
            }
            .store(in: &cancellables)

        // Observe playback stalls and recover
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: newItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                rlog("[WatchAudio] Playback stalled — attempting recovery")
                self?.player?.pause()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.player?.play()
                }
            }
            .store(in: &cancellables)

        if player == nil {
            player = AVPlayer(playerItem: newItem)
        } else {
            player?.replaceCurrentItem(with: newItem)
        }

        setupTimeObserver()
        updateNowPlayingInfo()

        // Check status immediately in case it's already ready (race condition fix)
        if newItem.status == .readyToPlay {
            handlePlayerItemStatus(.readyToPlay)
        } else if newItem.status == .failed {
            handlePlayerItemStatus(.failed)
        }
    }

    private func handlePlayerItemStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            guard isLoading else { return } // avoid double-handling
            rlog("[WatchAudio] Ready to play")
            isLoading = false
            duration = playerItem?.duration.seconds ?? 0
            player?.play()
            isPlaying = true
            startExtendedSession()
            updateNowPlayingInfo()
        case .failed:
            let underlyingError = playerItem?.error as NSError?
            let domain = underlyingError?.domain ?? "?"
            let code = underlyingError?.code ?? 0
            let desc = underlyingError?.localizedDescription ?? "Playback failed"
            let urlPrefix = currentItem?.streamUrl.prefix(60) ?? "?"
            let fullErr = "\(desc) [\(domain) \(code)] url:\(urlPrefix)"
            rlog("[WatchAudio] Player item FAILED: \(fullErr)")
            error = fullErr
            isLoading = false
        default:
            break
        }
    }

    private func setupTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            self?.currentPosition = time.seconds
            self?.updateNowPlayingInfo()
        }
    }

    // MARK: - Playback Controls

    func play() {
        if playerItem == nil, let item = currentItem {
            loadAndPlay(item)
        } else {
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func next() {
        guard queue.count > 0 else { return }

        if currentIndex < queue.count - 1 {
            currentIndex += 1
        } else if repeatMode == .all {
            // Wrap to beginning
            currentIndex = 0
        } else {
            return // Can't go next
        }

        if let item = currentItem {
            loadAndPlay(item)
        }
    }

    func previous() {
        guard queue.count > 0 else { return }

        // If more than 3 seconds in, restart current track
        if currentPosition > 3 {
            seek(to: 0)
            return
        }

        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            // Wrap to end
            currentIndex = queue.count - 1
        } else {
            return // Can't go previous
        }

        if let item = currentItem {
            loadAndPlay(item)
        }
    }

    func seek(to position: Double) {
        let time = CMTime(seconds: position, preferredTimescale: 1)
        player?.seek(to: time)
        currentPosition = position
        updateNowPlayingInfo()
    }

    /// Stop playback and clear the queue entirely
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerItem = nil
        isPlaying = false
        currentPosition = 0
        queue = []
        originalQueue = []
        currentIndex = 0
        isShuffled = false
        shuffledIndices = []
        stopExtendedSession()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Queue Management

    /// Toggle repeat mode (off -> one -> all -> off)
    func toggleRepeatMode() {
        repeatMode = repeatMode.next()
        rlog("[WatchAudio] Repeat mode: \(repeatMode)")
    }

    /// Toggle shuffle mode
    func toggleShuffle() {
        if isShuffled {
            unshuffle()
        } else {
            shuffle()
        }
    }

    /// Shuffle the queue, keeping current track at the front
    private func shuffle() {
        guard queue.count > 1 else { return }

        // Get the current item
        let currentItem = self.currentItem

        // Create shuffled version (excluding current item)
        var itemsToShuffle = queue.filter { $0.id != currentItem?.id }
        itemsToShuffle.shuffle()

        // Put current item at front
        if let current = currentItem {
            queue = [current] + itemsToShuffle
            currentIndex = 0
        } else {
            queue.shuffle()
        }

        isShuffled = true
        rlog("[WatchAudio] Queue shuffled, \(queue.count) items")
    }

    /// Restore original queue order
    private func unshuffle() {
        guard !originalQueue.isEmpty else { return }

        // Find current item's position in original queue
        let currentItemId = currentItem?.id
        queue = originalQueue

        if let id = currentItemId,
           let originalIndex = originalQueue.firstIndex(where: { $0.id == id }) {
            currentIndex = originalIndex
        } else {
            // Current item not found in original queue — clamp to valid range
            currentIndex = min(currentIndex, max(0, queue.count - 1))
            rlog("[WatchAudio] Unshuffle: current item not found in original queue, clamped to \(currentIndex)")
        }

        isShuffled = false
        rlog("[WatchAudio] Queue unshuffled, restored to original order")
    }

    /// Restart the queue from the beginning
    func restartQueue() {
        guard !queue.isEmpty else { return }

        currentIndex = 0
        if let item = currentItem {
            loadAndPlay(item)
        }
        rlog("[WatchAudio] Queue restarted from beginning")
    }

    /// Skip to a specific index in the queue
    func skipTo(index: Int) {
        guard index >= 0 && index < queue.count else { return }
        currentIndex = index
        if let item = currentItem {
            loadAndPlay(item)
        }
    }
}

/// Represents a playable item in the queue
struct QueueItem: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String?
    let album: String?
    let albumArtUrl: String?
    let streamUrl: String
    let plexToken: String
    let duration: Double
    /// Parent album ratingKey (for "Go to Album")
    let parentRatingKey: String?
    /// Grandparent artist ratingKey (for "Go to Artist")
    let grandparentRatingKey: String?

    init?(from dict: [String: Any]) {
        guard let streamUrl = dict["streamUrl"] as? String, !streamUrl.isEmpty else {
            rlog("[WatchAudio] QueueItem init failed: missing streamUrl")
            return nil
        }
        guard let plexToken = dict["plexToken"] as? String, !plexToken.isEmpty else {
            rlog("[WatchAudio] QueueItem init failed: missing plexToken")
            return nil
        }
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.title = dict["title"] as? String ?? "Unknown"
        self.artist = dict["artist"] as? String
        self.album = dict["album"] as? String
        self.albumArtUrl = dict["albumArtUrl"] as? String
        self.streamUrl = streamUrl
        self.plexToken = plexToken
        self.duration = dict["duration"] as? Double ?? 0
        self.parentRatingKey = dict["parentRatingKey"] as? String
        self.grandparentRatingKey = dict["grandparentRatingKey"] as? String
    }
}

/// Reference to a Plex play queue for direct fetching
struct PlayQueueReference {
    let playQueueId: Int
    let plexServerUrl: String
    let plexToken: String
    let currentIndex: Int

    init(playQueueId: Int, plexServerUrl: String, plexToken: String, currentIndex: Int) {
        self.playQueueId = playQueueId
        self.plexServerUrl = plexServerUrl
        self.plexToken = plexToken
        self.currentIndex = currentIndex
    }

    init?(from dict: [String: Any]) {
        guard let id = dict["playQueueId"] as? Int,
              let url = dict["plexServerUrl"] as? String,
              let token = dict["plexToken"] as? String else {
            return nil
        }
        self.playQueueId = id
        self.plexServerUrl = url
        self.plexToken = token
        self.currentIndex = dict["currentIndex"] as? Int ?? 0
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate

extension WatchAudioPlayer: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        rlog("[WatchAudio] Extended session running — audio will continue when screen sleeps")
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        rlog("[WatchAudio] Extended session expiring — restarting")
        // Restart the session to keep audio alive
        startExtendedSession()
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        rlog("[WatchAudio] Extended session invalidated: reason=\(reason.rawValue) error=\(error?.localizedDescription ?? "none")")
        // Restart if we're still playing
        if isPlaying {
            rlog("[WatchAudio] Still playing — restarting extended session")
            extendedSession = nil
            startExtendedSession()
        }
    }
}
