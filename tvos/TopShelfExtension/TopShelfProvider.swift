import CryptoKit
import Foundation
import TVServices

private enum TopShelfShared {
  static let schemaVersion = 3
  static let appGroupIdentifier = "group.com.edde746.plezy"
  static let cacheDataKey = "PlezySystemShelfCacheData"
  static let artworkDirectoryName = "SystemShelfArtwork"
  /// English fallback for sources persisted before the localized title existed.
  static let fallbackSectionTitle = "Continue Watching"

  static var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupIdentifier) }
  static var artworkRoot: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
      .appendingPathComponent(artworkDirectoryName, isDirectory: true)
  }
}

private struct TopShelfCachePayload: Decodable {
  struct Section: Decodable {
    let id: String
    let title: String
    let items: [Item]
  }

  struct Item: Decodable {
    let contentId: String
    let title: String
    let episodeTitle: String?
    let description: String?
    let artworkKey: String?
    let posterUrl: String?
    let type: String?
    let duration: Double?
    let lastPlaybackPosition: Double?
    let seasonNumber: Int?
    let episodeNumber: Int?

    private enum CodingKeys: String, CodingKey {
      case contentId
      case title
      case episodeTitle
      case description
      case artworkKey
      case posterUrl
      case type
      case duration
      case lastPlaybackPosition
      case seasonNumber
      case episodeNumber
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      contentId = try container.decode(String.self, forKey: .contentId)
      title = try container.decode(String.self, forKey: .title)
      episodeTitle = try container.decodeIfPresent(String.self, forKey: .episodeTitle)
      description = try container.decodeIfPresent(String.self, forKey: .description)
      artworkKey = try container.decodeIfPresent(String.self, forKey: .artworkKey)
      posterUrl = try container.decodeIfPresent(String.self, forKey: .posterUrl)
      type = try container.decodeIfPresent(String.self, forKey: .type)
      duration = container.decodeFlexibleDoubleIfPresent(.duration)
      lastPlaybackPosition = container.decodeFlexibleDoubleIfPresent(.lastPlaybackPosition)
      seasonNumber = container.decodeFlexibleIntIfPresent(.seasonNumber)
      episodeNumber = container.decodeFlexibleIntIfPresent(.episodeNumber)
    }

    init(fetched: ShelfFetchedItem) {
      contentId = fetched.contentId
      title = fetched.title
      episodeTitle = fetched.episodeTitle
      description = nil
      artworkKey = nil
      posterUrl = fetched.posterUrl
      type = fetched.type
      duration = fetched.durationMilliseconds
      lastPlaybackPosition = fetched.lastPlaybackPositionMilliseconds
      seasonNumber = fetched.seasonNumber
      episodeNumber = fetched.episodeNumber
    }
  }

  let schemaVersion: Int
  let ownerId: String
  let sections: [Section]
}

private extension KeyedDecodingContainer {
  func decodeFlexibleDoubleIfPresent(_ key: Key) -> Double? {
    if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
    if let value = try? decodeIfPresent(Int.self, forKey: key) { return Double(value) }
    return nil
  }

  func decodeFlexibleIntIfPresent(_ key: Key) -> Int? {
    if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
    if let value = try? decodeIfPresent(Double.self, forKey: key) { return Int(value) }
    return nil
  }
}

final class TopShelfProvider: TVTopShelfContentProvider {
  override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
    // Prefer a live fetch when the app has published server sources; any
    // failure falls back to replaying the last committed cache unchanged.
    if let sources = ShelfSourceStore.load(),
      let items = await ShelfFetcher.fetchContinueWatching(sources: sources)
    {
      let sectionTitle =
        sources.sectionTitle.flatMap { $0.isEmpty ? nil : $0 } ?? TopShelfShared.fallbackSectionTitle
      persistLiveSnapshot(items, ownerId: sources.ownerId, sectionTitle: sectionTitle)
      return buildLiveContent(items, ownerId: sources.ownerId, sectionTitle: sectionTitle)
    }
    return buildContent()
  }

  private func buildLiveContent(
    _ items: [ShelfFetchedItem],
    ownerId: String,
    sectionTitle: String
  ) -> TVTopShelfContent? {
    let sectionItems = items.compactMap {
      makeTopShelfItem(TopShelfCachePayload.Item(fetched: $0), ownerId: ownerId)
    }
    guard !sectionItems.isEmpty else { return nil }
    let collection = TVTopShelfItemCollection(items: sectionItems)
    collection.title = sectionTitle
    return TVTopShelfSectionedContent(sections: [collection])
  }

  /// Rewrites the shared cache with the live result so offline replay stays
  /// fresh. Token-bearing poster URLs stay inside the app group container.
  private func persistLiveSnapshot(_ items: [ShelfFetchedItem], ownerId: String, sectionTitle: String) {
    guard let defaults = TopShelfShared.sharedDefaults else { return }
    let itemDicts = items.map { item -> [String: Any] in
      var dict: [String: Any] = ["contentId": item.contentId, "title": item.title]
      if let episodeTitle = item.episodeTitle { dict["episodeTitle"] = episodeTitle }
      if let type = item.type { dict["type"] = type }
      if let duration = item.durationMilliseconds { dict["duration"] = duration }
      if let position = item.lastPlaybackPositionMilliseconds {
        dict["lastPlaybackPosition"] = position
      }
      if let seasonNumber = item.seasonNumber { dict["seasonNumber"] = seasonNumber }
      if let episodeNumber = item.episodeNumber { dict["episodeNumber"] = episodeNumber }
      if let posterUrl = item.posterUrl { dict["posterUrl"] = posterUrl }
      if item.recency > 0 { dict["lastEngagementTime"] = item.recency }
      return dict
    }
    let payload: [String: Any] = [
      "schemaVersion": TopShelfShared.schemaVersion,
      "ownerId": ownerId,
      "updatedAt": Date().timeIntervalSince1970,
      "sections": [["id": "continue_watching", "title": sectionTitle, "items": itemDicts]],
    ]
    guard JSONSerialization.isValidJSONObject(payload),
      let data = try? JSONSerialization.data(withJSONObject: payload)
    else { return }
    defaults.set(data, forKey: TopShelfShared.cacheDataKey)
    defaults.synchronize()
  }

  private func buildContent() -> TVTopShelfContent? {
    guard let defaults = TopShelfShared.sharedDefaults,
      let data = defaults.data(forKey: TopShelfShared.cacheDataKey)
    else { return nil }

    guard let payload = try? JSONDecoder().decode(TopShelfCachePayload.self, from: data),
      payload.schemaVersion == TopShelfShared.schemaVersion,
      !payload.ownerId.isEmpty
    else { return nil }

    let sections = payload.sections.compactMap { section -> TVTopShelfItemCollection<TVTopShelfSectionedItem>? in
      let items = section.items.compactMap { makeTopShelfItem($0, ownerId: payload.ownerId) }
      guard !items.isEmpty else { return nil }
      let collection = TVTopShelfItemCollection(items: items)
      collection.title = section.title
      return collection
    }
    guard !sections.isEmpty else { return nil }
    return TVTopShelfSectionedContent(sections: sections)
  }

  private func makeTopShelfItem(_ cacheItem: TopShelfCachePayload.Item, ownerId: String) -> TVTopShelfSectionedItem? {
    guard !cacheItem.contentId.isEmpty else { return nil }
    let item = TVTopShelfSectionedItem(identifier: cacheItem.contentId)
    item.title = displayTitle(for: cacheItem)
    item.imageShape = .poster

    if let duration = cacheItem.duration, duration > 0,
      let position = cacheItem.lastPlaybackPosition, position > 0
    {
      item.playbackProgress = min(max(position / duration, 0), 1)
    }
    if let url = deepLinkURL(contentId: cacheItem.contentId) {
      let action = TVTopShelfAction(url: url)
      item.displayAction = action
      item.playAction = action
    }
    if let remoteURL = remoteArtworkURL(cacheItem.posterUrl) {
      item.setImageURL(remoteURL, for: .screenScale1x)
      item.setImageURL(remoteURL, for: .screenScale2x)
    } else if let key = cacheItem.artworkKey, let localURL = localArtworkURL(ownerId: ownerId, key: key) {
      item.setImageURL(localURL, for: .screenScale1x)
      item.setImageURL(localURL, for: .screenScale2x)
    }
    return item
  }

  private func remoteArtworkURL(_ posterUrl: String?) -> URL? {
    guard let posterUrl, let url = URL(string: posterUrl),
      ["http", "https"].contains(url.scheme?.lowercased() ?? "")
    else { return nil }
    return url
  }

  private func localArtworkURL(ownerId: String, key: String) -> URL? {
    guard key.range(of: "^[a-f0-9]{32}\\.art$", options: .regularExpression) != nil,
      let root = TopShelfShared.artworkRoot
    else { return nil }
    let ownerHash = SHA256.hash(data: Data(ownerId.utf8)).map { String(format: "%02x", $0) }.joined()
    let canonicalRoot = root.standardizedFileURL.resolvingSymlinksInPath()
    let ownerDirectory = canonicalRoot.appendingPathComponent(ownerHash, isDirectory: true)
      .standardizedFileURL.resolvingSymlinksInPath()
    guard ownerDirectory.deletingLastPathComponent() == canonicalRoot else { return nil }
    let candidate = ownerDirectory.appendingPathComponent(key, isDirectory: false)
      .standardizedFileURL.resolvingSymlinksInPath()
    guard candidate.deletingLastPathComponent() == ownerDirectory else { return nil }
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDirectory), !isDirectory.boolValue
    else {
      return nil
    }
    return candidate
  }

  private func displayTitle(for item: TopShelfCachePayload.Item) -> String {
    guard let episodeTitle = item.episodeTitle, !episodeTitle.isEmpty else { return item.title }
    let episodePrefix: String? = {
      if let seasonNumber = item.seasonNumber, let episodeNumber = item.episodeNumber {
        return "S\(seasonNumber) E\(episodeNumber)"
      }
      if let episodeNumber = item.episodeNumber { return "E\(episodeNumber)" }
      return nil
    }()
    // S/E leads (official Plex app format) so it is readable immediately
    // instead of after the focused-item marquee scrolls a long series name;
    // the poster artwork already identifies the series. Without numbers the
    // series name is the only usable context, so it stays.
    if let episodePrefix { return "\(episodePrefix) - \(episodeTitle)" }
    return "\(item.title) - \(episodeTitle)"
  }

  private func deepLinkURL(contentId: String) -> URL? {
    var components = URLComponents()
    components.scheme = "plezy"
    components.host = "play"
    components.queryItems = [URLQueryItem(name: "content_id", value: contentId)]
    return components.url
  }
}
