import Foundation
import WatchKit

/// Centralizes Plex playback actions so every screen shares the same behavior.
@MainActor
final class MusicPlaybackCoordinator {
  static let shared = MusicPlaybackCoordinator()

  private let client = PlexWatchClient.shared
  private let player = WatchAudioPlayer.shared
  private let recent = RecentlyPlayedManager.shared

  private init() {}

  private static let unreachable = "Can't reach your Plex server"

  enum PlayStyle {
    case playAll(shuffle: Bool)
    case radio
    case singleTrack(index: Int = 0)
  }

  // MARK: - Public API

  func play(item: MusicItem, style: PlayStyle, connectivity: WatchConnectivityManager) async -> String? {
    let span = WatchInstrument.begin("playback.play", detail: "\(style) '\(item.title)'")
    defer { span.end() }
    WatchInstrument.action("play", detail: "\(item.type) '\(item.title)' style=\(String(describing: style))")
    switch style {
    case .playAll(let shuffle):
      return await playAll(
        ratingKey: item.ratingKey, title: item.title, type: item.type,
        thumb: item.thumb, shuffle: shuffle, connectivity: connectivity)
    case .radio:
      return await startRadio(
        ratingKey: item.ratingKey, title: item.title, type: item.type,
        thumb: item.thumb, artist: item.artist, connectivity: connectivity)
    case .singleTrack(let index):
      return await playAll(
        ratingKey: item.ratingKey, title: item.title, type: item.type,
        thumb: item.thumb, shuffle: false, connectivity: connectivity,
        startIndex: index)
    }
  }

  func playRecent(_ item: RecentlyPlayedManager.RecentItem, connectivity: WatchConnectivityManager) async -> String? {
    switch item.playStyle {
    case .artistRadio, .albumRadio, .trackRadio:
      return await startRadio(
        ratingKey: item.ratingKey,
        title: item.title,
        type: item.plexType,
        thumb: item.thumb,
        artist: item.subtitle,
        connectivity: connectivity
      )
    case .playAll(let shuffle):
      return await playAll(
        ratingKey: item.ratingKey,
        title: item.title,
        type: item.plexType,
        thumb: item.thumb,
        shuffle: shuffle,
        connectivity: connectivity
      )
    }
  }

  func playPlaylist(
    _ playlist: MusicItem,
    shuffle: Bool = false,
    startIndex: Int = 0,
    connectivity: WatchConnectivityManager
  ) async -> String? {
    guard client.hasCredentials else { return "No server credentials" }
    WatchInstrument.action("playPlaylist", detail: "'\(playlist.title)' shuffle=\(shuffle) start=\(startIndex)")

    guard let result = await client.createPlaylistQueue(ratingKey: playlist.ratingKey, shuffle: shuffle) else {
      WKInterfaceDevice.current().play(.failure)
      return client.isServerUnreachable ? Self.unreachable : "Failed to create play queue"
    }
    return await start(
      result,
      startIndex: startIndex,
      isShuffled: shuffle,
      connectivity: connectivity
    ) {
      self.recent.record(
        ratingKey: playlist.ratingKey,
        title: playlist.title,
        type: .album,
        thumb: playlist.thumb
      )
    }
  }

  func recordNowPlaying(_ item: QueueItem) {
    WatchInstrument.recent("nowPlaying '\(item.title)' by \(item.artist ?? "?")")
    let thumb = item.albumArtUrl.flatMap { extractThumbPath(from: $0) }
    if let artistKey = item.grandparentRatingKey, let artistName = item.artist {
      recent.recordArtist(ratingKey: artistKey, title: artistName, thumb: thumb)
    }
    if let albumKey = item.parentRatingKey, let albumName = item.album {
      recent.record(
        ratingKey: albumKey,
        title: albumName,
        type: .album,
        thumb: thumb,
        subtitle: item.artist
      )
    }
    recent.record(
      ratingKey: item.id,
      title: item.title,
      type: .track,
      thumb: thumb,
      subtitle: item.artist
    )
  }

  // MARK: - Private

  private func playAll(
    ratingKey: String,
    title: String,
    type: String,
    thumb: String?,
    shuffle: Bool,
    connectivity: WatchConnectivityManager,
    startIndex: Int = 0
  ) async -> String? {
    guard client.hasCredentials else { return "No server credentials" }

    guard let result = await client.createPlayAllQueue(ratingKey: ratingKey, shuffle: shuffle) else {
      WKInterfaceDevice.current().play(.failure)
      return client.isServerUnreachable ? Self.unreachable : "Failed to create play queue"
    }

    return await start(
      result,
      startIndex: startIndex,
      isShuffled: shuffle,
      connectivity: connectivity
    ) {
      let recentType: RecentlyPlayedManager.RecentItemType = type == "artist" ? .artist : .album
      self.recent.record(ratingKey: ratingKey, title: title, type: recentType, thumb: thumb)
    }
  }

  /// Hand a play queue to the player and wait to hear whether it played, so
  /// that every way of starting music fails the same way.
  private func start(
    _ result: PlayQueueResult,
    startIndex: Int = 0,
    isShuffled: Bool = false,
    isContinuous: Bool = false,
    noPlayableTracks: String = "No playable tracks",
    connectivity: WatchConnectivityManager,
    recordRecent: () -> Void
  ) async -> String? {
    guard
      let prepared = await result.prepareForPlayback(
        client: client,
        startIndex: min(startIndex, max(result.items.count - 1, 0))
      )
    else {
      WKInterfaceDevice.current().play(.failure)
      return noPlayableTracks
    }

    WKInterfaceDevice.current().play(.click)
    connectivity.startLocalPlayback()
    player.loadQueue(
      prepared.queueItems,
      queueRef: result.toQueueReference(isContinuous: isContinuous),
      catalog: prepared.catalog,
      catalogStartIndex: prepared.catalogIndex,
      isShuffled: isShuffled
    )
    recordRecent()

    if let playbackError = await player.awaitReadyOrFailed() {
      WKInterfaceDevice.current().play(.failure)
      connectivity.stopLocalPlayback()
      return playbackError
    }
    WKInterfaceDevice.current().play(.success)
    return nil
  }

  private func startRadio(
    ratingKey: String,
    title: String,
    type: String,
    thumb: String?,
    artist: String?,
    connectivity: WatchConnectivityManager
  ) async -> String? {
    guard client.hasCredentials else { return "No server credentials" }

    let (radioResult, radioError) = await client.createRadioStation(ratingKey: ratingKey)
    guard let result = radioResult else {
      if type == "artist" {
        WatchInstrument.playback("radio empty — falling back to playAll for '\(title)'")
        return await playAll(
          ratingKey: ratingKey, title: title, type: type, thumb: thumb,
          shuffle: false, connectivity: connectivity
        )
      }
      WKInterfaceDevice.current().play(.failure)
      if client.isServerUnreachable { return Self.unreachable }
      return radioError ?? "Radio failed"
    }

    return await start(
      result,
      isContinuous: true,
      noPlayableTracks: "No playable tracks for radio",
      connectivity: connectivity
    ) {
      let recentType: RecentlyPlayedManager.RecentItemType
      switch type {
      case "artist": recentType = .artist
      case "album": recentType = .album
      default: recentType = .track
      }
      self.recent.record(
        ratingKey: ratingKey,
        title: title,
        type: recentType,
        thumb: thumb,
        subtitle: artist,
        playStyle: .radio(for: recentType)
      )
    }
  }

  private func extractThumbPath(from urlString: String) -> String? {
    guard let url = URL(string: urlString) else { return nil }
    var path = url.path
    if path.hasPrefix("/") { path = String(path.dropFirst()) }
    return path.isEmpty ? nil : path
  }
}
