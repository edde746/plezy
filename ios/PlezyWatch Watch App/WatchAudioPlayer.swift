import Foundation
import AVFoundation
import Combine
import MediaPlayer

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

  /// Every track this queue knows about. [queue] is the part of it already
  /// resolved to a stream URL; resolving costs round trips, so the rest waits
  /// until playback gets there.
  private var catalog: [MusicItem] = []
  /// Index in [catalog] of the last entry resolved into [queue].
  private var catalogIndex = 0
  /// The order to go back to when shuffle is turned off.
  private var unshuffledCatalog: [MusicItem]?
  private var isAdvancing = false

  // Play queue reference for fetching more tracks from Plex
  private var playQueueRef: PlayQueueReference?
  private var serverQueueExhausted = false
  private var moreTracksTask: Task<Bool, Never>?

  /// Bumped when the queue is replaced or stopped. Work that awaited across a
  /// bump belongs to a queue that is gone and must drop its result.
  private var queueGeneration = 0
  /// Bumped per load, so a slow audio session activation cannot start a track
  /// that has since been skipped or stopped.
  private var loadGeneration = 0
  private var audioSessionActive = false
  /// One retry per track: a stream URL can be stale, a second failure is not that.
  private var retriedItemId: String?
  /// Where in the track the open stream starts. Zero except after a resume,
  /// when Plex transcodes from the point the last stream was cut off.
  private var streamOffset: Double = 0
  /// Resumes spent on the current track, so a stream that keeps dying
  /// moves on instead of looping on the same spot.
  private var resumes: (itemId: String, count: Int)?
  /// Where to seek once a resumed direct-play file is ready.
  private var pendingSeek: Double?

  /// A stream that "ends" further than this from the track's real length
  /// was cut off, not finished.
  private static let earlyEndTolerance: Double = 8
  private static let maxResumesPerTrack = 3

  var currentItem: QueueItem? {
    guard currentIndex >= 0 && currentIndex < queue.count else { return nil }
    return queue[currentIndex]
  }

  /// Whether there's a queue loaded (even if paused)
  var hasQueue: Bool {
    !queue.isEmpty
  }

  var canGoNext: Bool {
    if repeatMode == .all && queue.count > 0 { return true }
    if currentIndex < queue.count - 1 { return true }
    if catalogIndex + 1 < catalog.count { return true }
    if playQueueRef?.isContinuous == true { return true }
    return playQueueRef != nil && !serverQueueExhausted
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

  private func configureAudioSessionForPlayback() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
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
      let type = AVAudioSession.InterruptionType(rawValue: typeValue)
    else { return }

    switch type {
    case .began:
      WatchInstrument.playback("Audio session interrupted")
      DispatchQueue.main.async { self.isPlaying = false }
    case .ended:
      WatchInstrument.playback("Audio session interruption ended")
      if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) {
          WatchInstrument.playback("Resuming playback after interruption")
          DispatchQueue.main.async {
            guard self.hasQueue else { return }
            self.player?.play()
            self.isPlaying = true
            self.updateNowPlayingInfo()
          }
        }
      }
    @unknown default:
      break
    }
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
      info[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : item.duration
      info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentPosition
      info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
      info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  @objc private func playerItemDidFinish(_ notification: Notification) {
    guard let finishedItem = notification.object as? AVPlayerItem else { return }
    // Posted on whichever thread AVFoundation finished on.
    DispatchQueue.main.async { [weak self] in
      // Only handle if it's the current player item (not a discarded one)
      guard let self, finishedItem === self.playerItem else { return }
      if let item = self.currentItem, self.wasCutOff(item) {
        Task { @MainActor in await self.resumeCutOff(item) }
        return
      }
      if self.repeatMode == .one {
        self.seek(to: 0)
        self.play()
      } else {
        Task { @MainActor in await self.advance() }
      }
    }
  }

  /// Whether the stream for [item] stopped well short of the track's length.
  ///
  /// Most of the library is FLAC, which reaches the watch as a live MP3
  /// transcode with no length of its own. When that connection drops — Plex
  /// reaping a transcode the watch has buffered far ahead of, or a hop
  /// between Wi-Fi and cellular mid-run — AVPlayer plays out its buffer and
  /// reports the item finished, exactly as if the track had ended. Taking it
  /// at its word skipped to the next track partway through this one.
  private func wasCutOff(_ item: QueueItem) -> Bool {
    guard item.duration > 0, let player else { return false }
    let reached = player.currentTime().seconds + streamOffset
    guard reached.isFinite else { return false }
    return item.duration - reached > Self.earlyEndTolerance
  }

  /// Open a fresh stream from where the cut-off one stopped.
  @MainActor
  private func resumeCutOff(_ item: QueueItem) async {
    let reached = (player?.currentTime().seconds ?? 0) + streamOffset
    let count = resumes?.itemId == item.id ? resumes!.count + 1 : 1
    guard count <= Self.maxResumesPerTrack else {
      WatchInstrument.playback("Stream cut off again at \(Int(reached))s of \(Int(item.duration))s — moving on")
      await advance()
      return
    }
    resumes = (item.id, count)
    WatchInstrument.playback("Stream cut off at \(Int(reached))s of \(Int(item.duration))s — resuming (\(count))")
    let generation = loadGeneration
    PlexWatchClient.shared.invalidateStreamingBase()
    // A couple of seconds back, so nothing is lost across the join.
    let from = max(0, reached - 2)
    guard let stream = await PlexWatchClient.shared.resolveResumeStream(ratingKey: item.id, at: from),
      generation == loadGeneration, currentItem?.id == item.id
    else {
      if generation == loadGeneration { await advance() }
      return
    }
    loadAndPlay(item, url: stream.url, startsAt: stream.startsAt, seekTo: stream.startsAt == 0 ? from : nil)
  }

  /// Move to the next track, or end the queue if there is none. The one path
  /// for both a track finishing and the next button, so they cannot disagree
  /// about what comes after the last track.
  @MainActor
  private func advance() async {
    guard !isAdvancing else { return }
    isAdvancing = true
    defer { isAdvancing = false }
    let generation = queueGeneration

    if currentIndex < queue.count - 1 {
      currentIndex += 1
      playCurrent()
      return
    }

    if catalogIndex + 1 >= catalog.count {
      _ = await fetchMoreTracks()
      guard generation == queueGeneration else { return }
    }
    if catalogIndex + 1 < catalog.count {
      await advanceFromCatalog(generation: generation)
      return
    }

    // Radio has no last track. Plex only extends a queue for clients that
    // report their position, which this one does not, so it goes round.
    if repeatMode == .all || playQueueRef?.isContinuous == true {
      currentIndex = 0
      playCurrent()
      return
    }

    finishQueue()
  }

  /// Resolve the next catalog entry and play it, passing over tracks that
  /// cannot be resolved rather than ending the album at the first one.
  @MainActor
  private func advanceFromCatalog(generation: Int) async {
    var attempts = 0
    while catalogIndex + 1 < catalog.count, attempts < 3 {
      attempts += 1
      let next = catalog[catalogIndex + 1]
      let item = await next.toQueueItem(client: PlexWatchClient.shared)
      guard generation == queueGeneration else { return }
      catalogIndex += 1
      guard let item else {
        WatchInstrument.playback("Could not resolve '\(next.title)', skipping")
        continue
      }
      queue.append(item)
      currentIndex = queue.count - 1
      WatchInstrument.playback("Advanced catalog to \(catalogIndex + 1)/\(catalog.count)")
      playCurrent()
      return
    }
    isPlaying = false
    error = "Could not load the next track"
    updateNowPlayingInfo()
  }

  private func playCurrent() {
    if let item = currentItem { loadAndPlay(item) }
    if playQueueRef != nil && catalogIndex + 3 >= catalog.count {
      Task { @MainActor in _ = await self.fetchMoreTracks() }
    }
  }

  /// Add any tracks the server has that [catalog] lacks, returning whether
  /// there were some. The catalog is the only thing extended: tracks get a
  /// stream URL when playback reaches them, so nothing here can run ahead of
  /// [catalogIndex] and be played a second time.
  @MainActor
  private func fetchMoreTracks() async -> Bool {
    if let moreTracksTask { return await moreTracksTask.value }
    guard let ref = playQueueRef, !serverQueueExhausted else { return false }

    let generation = queueGeneration
    let task = Task { @MainActor [weak self] () -> Bool in
      let fetched = await PlexWatchClient.shared.fetchPlayQueue(queueId: ref.playQueueId)
      guard let self, generation == self.queueGeneration else { return false }
      self.moreTracksTask = nil
      guard let fetched else { return false }

      let known = Set(self.catalog.map(\.ratingKey))
      let newTracks = fetched.items.filter { $0.isTrack && !known.contains($0.ratingKey) }
      if newTracks.isEmpty {
        self.serverQueueExhausted = true
        return false
      }
      self.catalog.append(contentsOf: newTracks)
      self.unshuffledCatalog?.append(contentsOf: newTracks)
      WatchInstrument.playback("Added \(newTracks.count) tracks, catalog now \(self.catalog.count)")
      return true
    }
    moreTracksTask = task
    return await task.value
  }

  /// The last track ended with nothing to follow it: stay on it, stopped.
  @MainActor
  private func finishQueue() {
    WatchInstrument.playback("End of queue")
    player?.pause()
    player?.seek(to: .zero)
    isPlaying = false
    isLoading = false
    currentPosition = 0
    updateNowPlayingInfo()
    deactivateAudioSession()
  }

  private func deactivateAudioSession() {
    guard audioSessionActive else { return }
    audioSessionActive = false
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      WatchInstrument.playback("Audio session deactivation failed: \(error)")
    }
  }

  /// Load a queue of items to play
  func loadQueue(
    _ items: [QueueItem],
    startIndex: Int = 0,
    queueRef: PlayQueueReference? = nil,
    catalog: [MusicItem] = [],
    catalogStartIndex: Int = 0,
    isShuffled: Bool = false
  ) {
    queueGeneration += 1
    moreTracksTask = nil
    serverQueueExhausted = false
    retriedItemId = nil
    queue = items
    currentIndex = startIndex
    playQueueRef = queueRef
    self.catalog = catalog
    catalogIndex = catalogStartIndex
    unshuffledCatalog = nil
    self.isShuffled = isShuffled

    WatchInstrument.playback(
      "loadQueue count=\(items.count) startIndex=\(startIndex) ref=\(queueRef?.playQueueId.description ?? "nil")")
    if let item = currentItem {
      WatchInstrument.uiSnapshot(
        screen: "Player",
        fields: [
          "track": item.title,
          "artist": item.artist ?? "?",
          "queueSize": items.count,
          "index": startIndex,
        ])
    }

    if let item = currentItem {
      loadAndPlay(item)
    }
  }

  /// Load and play a specific item
  private func loadAndPlay(_ item: QueueItem, url override: String? = nil, startsAt: Double = 0, seekTo: Double? = nil)
  {
    loadGeneration += 1
    let generation = loadGeneration
    isLoading = true
    error = nil
    streamOffset = startsAt
    pendingSeek = seekTo
    if resumes?.itemId != item.id { resumes = nil }

    guard let url = URL(string: override ?? item.streamUrl) else {
      error = "This track has an invalid address"
      isLoading = false
      return
    }

    WatchInstrument.playback("loadAndPlay: \(item.title)")

    // watchOS: set category + activate once, then play. Same flow as Spotify / Books.
    Task { @MainActor in
      do {
        try self.configureAudioSessionForPlayback()
        // False, not an error, when the owner dismisses the route picker.
        let activated = try await AVAudioSession.sharedInstance().activate()
        guard generation == self.loadGeneration else { return }
        guard activated else {
          WatchInstrument.playback("Audio session not activated")
          self.error = "Connect Bluetooth headphones to play in the background"
          self.isLoading = false
          return
        }
        self.audioSessionActive = true
        let route = AVAudioSession.sharedInstance().currentRoute.outputs
          .map { "\($0.portName)(\($0.portType.rawValue))" }
          .joined(separator: ", ")
        WatchInstrument.playback("Audio session activated route=[\(route)]")
        self.updateNowPlayingInfo()
        self.startPlayback(url: url, item: item)
      } catch {
        guard generation == self.loadGeneration else { return }
        WatchInstrument.playback("Audio session setup failed: \(error)")
        self.error = "Connect Bluetooth headphones to play in the background"
        self.isLoading = false
      }
    }
  }

  /// Actually start AVPlayer playback (called after audio session is activated)
  @MainActor
  private func startPlayback(url: URL, item: QueueItem) {
    let headers = PlexWatchClient.shared.playbackHeaders(token: item.plexToken)
    let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
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
        WatchInstrument.playback("Playback stalled — attempting recovery")
        self?.player?.pause()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          guard self?.isPlaying == true else { return }
          self?.player?.play()
        }
      }
      .store(in: &cancellables)

    if player == nil {
      player = AVPlayer(playerItem: newItem)
      player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
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
      guard isLoading else { return }  // avoid double-handling
      WatchInstrument.playback("Ready to play")
      isLoading = false
      retriedItemId = nil
      // A resumed transcode is only the rest of the track.
      let streamLength = playerItem?.duration.seconds ?? 0
      duration = streamOffset > 0 ? (currentItem?.duration ?? 0) : streamLength
      if let pendingSeek {
        self.pendingSeek = nil
        player?.seek(to: CMTime(seconds: pendingSeek, preferredTimescale: 1000))
      }
      player?.play()
      isPlaying = true
      updateNowPlayingInfo()
      if let item = currentItem {
        Task { @MainActor in
          MusicPlaybackCoordinator.shared.recordNowPlaying(item)
        }
      }
    case .failed:
      let underlyingError = playerItem?.error as NSError?
      let domain = underlyingError?.domain ?? "?"
      let code = underlyingError?.code ?? 0
      let desc = underlyingError?.localizedDescription ?? "Playback failed"
      let fullErr = "\(desc) [\(domain) \(code)]"
      WatchInstrument.playback("Player item FAILED: \(fullErr)")
      if let item = currentItem, retriedItemId != item.id {
        retriedItemId = item.id
        Task { @MainActor in await self.retryWithFreshStream(item, failure: fullErr) }
        return
      }
      failPlayback(fullErr)
    default:
      break
    }
  }

  private func failPlayback(_ message: String) {
    error = message
    isLoading = false
    isPlaying = false
  }

  /// A queued URL was built for the network it was resolved on. If that was
  /// home and this is cellular it is dead, though the track is fine.
  @MainActor
  private func retryWithFreshStream(_ item: QueueItem, failure: String) async {
    let generation = loadGeneration
    PlexWatchClient.shared.invalidateStreamingBase()
    let streamUrl = await PlexWatchClient.shared.resolveStreamUrl(ratingKey: item.id)
    guard generation == loadGeneration else { return }
    guard let streamUrl, currentItem?.id == item.id else {
      failPlayback(failure)
      return
    }
    queue[currentIndex].streamUrl = streamUrl
    playCurrent()
  }

  private func setupTimeObserver() {
    if let observer = timeObserver {
      player?.removeTimeObserver(observer)
    }

    timeObserver = player?.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 1, preferredTimescale: 1),
      queue: .main
    ) { [weak self] time in
      guard let self else { return }
      self.currentPosition = time.seconds + self.streamOffset
      self.updateNowPlayingInfo()
    }
  }

  // MARK: - Playback Controls

  /// Wait until the current item starts playing or fails (used after loadQueue).
  @MainActor
  func awaitReadyOrFailed(timeout: TimeInterval = 30) async -> String? {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let error, !error.isEmpty { return error }
      // isLoading first: isPlaying is still true for the track being replaced.
      if isLoading {
        try? await Task.sleep(nanoseconds: 100_000_000)
        continue
      }
      if isPlaying { return nil }
      if playerItem?.status == .failed {
        return error ?? playerItem?.error?.localizedDescription ?? "Playback failed"
      }
      try? await Task.sleep(nanoseconds: 100_000_000)
    }
    return isPlaying ? nil : (error ?? "Playback timed out")
  }

  func play() {
    WatchInstrument.playback("play() isPlaying=\(isPlaying)")
    if playerItem == nil || !audioSessionActive, let item = currentItem {
      loadAndPlay(item)
    } else {
      player?.play()
      isPlaying = true
      updateNowPlayingInfo()
    }
  }

  func pause() {
    WatchInstrument.playback("pause() at \(Int(currentPosition))s")
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
    WatchInstrument.playback("next() from index \(currentIndex)")
    guard queue.count > 0 else { return }

    Task { @MainActor in await self.advance() }
  }

  func previous() {
    WatchInstrument.playback("previous() from index \(currentIndex) pos=\(Int(currentPosition))s")
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
      return  // Can't go previous
    }

    playCurrent()
  }

  func seek(to position: Double) {
    // Before the start of a resumed transcode there is nothing to seek to,
    // so that part of the track needs a stream of its own.
    if position < streamOffset, let item = currentItem {
      currentPosition = position
      if position < 1 {
        loadAndPlay(item)
      } else {
        Task { @MainActor in
          guard let stream = await PlexWatchClient.shared.resolveResumeStream(ratingKey: item.id, at: position),
            self.currentItem?.id == item.id
          else { return }
          self.loadAndPlay(
            item, url: stream.url, startsAt: stream.startsAt, seekTo: stream.startsAt == 0 ? position : nil)
        }
      }
      return
    }
    let time = CMTime(seconds: position - streamOffset, preferredTimescale: 1)
    player?.seek(to: time)
    currentPosition = position
    updateNowPlayingInfo()
  }

  /// Stop playback and clear the queue entirely
  func stop() {
    WatchInstrument.playback("stop() clearing queue")
    queueGeneration += 1
    loadGeneration += 1
    moreTracksTask = nil
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    playerItem = nil
    cancellables.removeAll()
    isPlaying = false
    isLoading = false
    error = nil
    currentPosition = 0
    queue = []
    catalog = []
    catalogIndex = 0
    currentIndex = 0
    unshuffledCatalog = nil
    isShuffled = false
    playQueueRef = nil
    serverQueueExhausted = false
    retriedItemId = nil
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    deactivateAudioSession()
  }

  // MARK: - Queue Management

  /// Toggle repeat mode (off -> one -> all -> off)
  func toggleRepeatMode() {
    repeatMode = repeatMode.next()
    WatchInstrument.playback("Repeat mode: \(repeatMode)")
  }

  /// Toggle shuffle mode
  func toggleShuffle() {
    if isShuffled {
      unshuffle()
    } else {
      shuffle()
    }
  }

  /// Shuffle everything in the catalog, keeping the current track playing.
  /// The catalog rather than [queue], which only holds the few tracks
  /// resolved so far and would leave the rest to arrive in album order.
  private func shuffle() {
    guard let current = currentItem,
      let entry = catalog.first(where: { $0.ratingKey == current.id })
    else { return }
    let others = catalog.filter { $0.ratingKey != current.id }
    guard !others.isEmpty else { return }

    unshuffledCatalog = catalog
    catalog = [entry] + others.shuffled()
    catalogIndex = 0
    queue = [current]
    currentIndex = 0
    isShuffled = true
    WatchInstrument.playback("Catalog shuffled, \(catalog.count) items")
  }

  /// Back to the original order, carrying on from the current track. A queue
  /// that arrived shuffled from Plex has no other order to go back to.
  private func unshuffle() {
    if let current = currentItem,
      let original = unshuffledCatalog,
      let index = original.firstIndex(where: { $0.ratingKey == current.id })
    {
      catalog = original
      catalogIndex = index
      queue = [current]
      currentIndex = 0
    }
    unshuffledCatalog = nil
    isShuffled = false
    WatchInstrument.playback("Queue unshuffled")
  }

  /// Restart the queue from the beginning
  func restartQueue() {
    guard !queue.isEmpty else { return }

    currentIndex = 0
    playCurrent()
    WatchInstrument.playback("Queue restarted from beginning")
  }

  /// Skip to a specific index in the queue
  func skipTo(index: Int) {
    guard index >= 0 && index < queue.count else { return }
    currentIndex = index
    playCurrent()
  }
}

/// Represents a playable item in the queue
struct QueueItem: Identifiable, Codable {
  let id: String
  let title: String
  let artist: String?
  let album: String?
  let albumArtUrl: String?
  var streamUrl: String
  let plexToken: String
  let duration: Double
  /// Parent album ratingKey (for "Go to Album")
  let parentRatingKey: String?
  /// Grandparent artist ratingKey (for "Go to Artist")
  let grandparentRatingKey: String?

  init?(from dict: [String: Any]) {
    guard let streamUrl = dict["streamUrl"] as? String, !streamUrl.isEmpty else {
      WatchInstrument.playback("QueueItem init failed: missing streamUrl")
      return nil
    }
    guard let plexToken = dict["plexToken"] as? String, !plexToken.isEmpty else {
      WatchInstrument.playback("QueueItem init failed: missing plexToken")
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
  /// A radio station, which has no last track.
  let isContinuous: Bool
}
