import Foundation

/// Tracks recently played items for quick replay from the home screen.
/// Artists are surfaced separately — that's what people reach for on a watch.
class RecentlyPlayedManager: ObservableObject {
  static let shared = RecentlyPlayedManager()

  private let storageKey = "recentlyPlayed"
  private let artistsStorageKey = "recentArtists"
  private let maxItems = 20
  private let maxArtists = 12

  @Published var items: [RecentItem] = []
  @Published var recentArtists: [RecentItem] = []
  @Published var isSyncingFromPlex = false

  private var activeSync: Task<Void, Never>?
  private var lastSyncAt: Date?
  private let minSyncInterval: TimeInterval = 5 * 60

  init() {
    load()
  }

  enum PlayStyle: Codable, Equatable {
    case artistRadio
    case albumRadio
    case trackRadio
    case playAll(shuffle: Bool)

    static func radio(for type: RecentItemType) -> PlayStyle {
      switch type {
      case .artist: return .artistRadio
      case .album: return .albumRadio
      case .track, .station: return .trackRadio
      }
    }
  }

  struct RecentItem: Identifiable, Codable, Equatable {
    let ratingKey: String
    let title: String
    let type: RecentItemType
    let thumb: String?
    let subtitle: String?
    let timestamp: Date
    let playStyle: PlayStyle

    var id: String { "\(type.rawValue)-\(ratingKey)" }

    var plexType: String {
      switch type {
      case .artist: return "artist"
      case .album: return "album"
      case .track, .station: return "track"
      }
    }

    init(
      ratingKey: String,
      title: String,
      type: RecentItemType,
      thumb: String? = nil,
      subtitle: String? = nil,
      timestamp: Date = Date(),
      playStyle: PlayStyle? = nil
    ) {
      self.ratingKey = ratingKey
      self.title = title
      self.type = type
      self.thumb = thumb
      self.subtitle = subtitle
      self.timestamp = timestamp
      self.playStyle = playStyle ?? defaultPlayStyle(for: type)
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      ratingKey = try container.decode(String.self, forKey: .ratingKey)
      title = try container.decode(String.self, forKey: .title)
      type = try container.decode(RecentItemType.self, forKey: .type)
      thumb = try container.decodeIfPresent(String.self, forKey: .thumb)
      subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
      timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
      playStyle =
        try container.decodeIfPresent(PlayStyle.self, forKey: .playStyle)
        ?? defaultPlayStyle(for: type)
    }
  }

  enum RecentItemType: String, Codable {
    case album
    case artist
    case track
    case station
  }

  /// Record any recently played item (album, track, station).
  func record(
    ratingKey: String,
    title: String,
    type: RecentItemType,
    thumb: String? = nil,
    subtitle: String? = nil,
    playStyle: PlayStyle? = nil
  ) {
    let item = RecentItem(
      ratingKey: ratingKey,
      title: title,
      type: type,
      thumb: thumb,
      subtitle: subtitle,
      playStyle: playStyle
    )

    items.removeAll { $0.ratingKey == ratingKey && $0.type == type }
    items.insert(item, at: 0)
    if items.count > maxItems {
      items = Array(items.prefix(maxItems))
    }
    save()
  }

  /// Record an artist play — kept in a dedicated list for the home-screen strip.
  func recordArtist(ratingKey: String, title: String, thumb: String? = nil) {
    let item = RecentItem(
      ratingKey: ratingKey,
      title: title,
      type: .artist,
      thumb: thumb,
      playStyle: .artistRadio
    )

    recentArtists.removeAll { $0.ratingKey == ratingKey }
    recentArtists.insert(item, at: 0)
    if recentArtists.count > maxArtists {
      recentArtists = Array(recentArtists.prefix(maxArtists))
    }
    saveArtists()
  }

  /// Pull recently played artists from Plex server history and merge with local data.
  func syncFromPlex(force: Bool = false) async {
    if let activeSync {
      await activeSync.value
      return
    }

    guard PlexWatchClient.shared.hasCredentials else {
      WatchInstrument.recent("syncFromPlex skipped — no credentials")
      return
    }

    if !force, let lastSyncAt, Date().timeIntervalSince(lastSyncAt) < minSyncInterval {
      WatchInstrument.recent("syncFromPlex skipped — synced recently")
      return
    }

    let task = Task {
      let span = WatchInstrument.begin("recent.syncFromPlex")
      await MainActor.run { isSyncingFromPlex = true }
      WatchInstrument.recent("syncFromPlex started")

      async let remoteArtists = PlexWatchClient.shared.getRecentlyPlayedArtists(limit: maxArtists)
      async let remoteHistory = PlexWatchClient.shared.getPlayHistory(limit: 15)
      let (artists, history) = await (remoteArtists, remoteHistory)

      await MainActor.run {
        WatchInstrument.recent("syncFromPlex got artists=\(artists.count) history=\(history.count)")
        mergeArtists(artists)
        mergeHistory(history)
        isSyncingFromPlex = false
        lastSyncAt = Date()
        WatchInstrument.uiSnapshot(
          screen: "RecentData",
          fields: [
            "artists": recentArtists.count,
            "items": items.count,
          ])
      }
      span.end()
    }
    activeSync = task
    await task.value
    activeSync = nil
  }

  // MARK: - Private

  private func mergeArtists(_ remote: [MusicItem]) {
    for artist in remote.reversed() {
      let item = RecentItem(
        ratingKey: artist.ratingKey,
        title: artist.title,
        type: .artist,
        thumb: artist.thumb,
        playStyle: .artistRadio
      )
      recentArtists.removeAll { $0.ratingKey == artist.ratingKey }
      recentArtists.insert(item, at: 0)
    }
    if recentArtists.count > maxArtists {
      recentArtists = Array(recentArtists.prefix(maxArtists))
    }
    saveArtists()
  }

  private func mergeHistory(_ history: [MusicItem]) {
    for track in history.reversed() {
      if let artistKey = track.grandparentRatingKey, let artistName = track.artist {
        recordArtist(ratingKey: artistKey, title: artistName, thumb: track.thumb)
      }
      if let albumKey = track.parentRatingKey, let albumName = track.album {
        record(
          ratingKey: albumKey,
          title: albumName,
          type: .album,
          thumb: track.thumb,
          subtitle: track.artist
        )
      }
      record(
        ratingKey: track.ratingKey,
        title: track.title,
        type: .track,
        thumb: track.thumb,
        subtitle: track.artist
      )
    }
  }

  private func save() {
    if let data = try? JSONEncoder().encode(items) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
  }

  private func saveArtists() {
    if let data = try? JSONEncoder().encode(recentArtists) {
      UserDefaults.standard.set(data, forKey: artistsStorageKey)
    }
  }

  private func load() {
    if let data = UserDefaults.standard.data(forKey: storageKey),
      let saved = try? JSONDecoder().decode([RecentItem].self, from: data)
    {
      items = saved
    }
    if let data = UserDefaults.standard.data(forKey: artistsStorageKey),
      let saved = try? JSONDecoder().decode([RecentItem].self, from: data)
    {
      recentArtists = saved
    } else {
      // Migrate artists from the general list on first launch after upgrade
      recentArtists = items.filter { $0.type == .artist || $0.type == .station }
    }
  }
}

private func defaultPlayStyle(for type: RecentlyPlayedManager.RecentItemType) -> RecentlyPlayedManager.PlayStyle {
  switch type {
  case .artist: return .artistRadio
  case .album: return .playAll(shuffle: false)
  case .track, .station: return .trackRadio
  }
}
