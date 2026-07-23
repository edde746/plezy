import CryptoKit
import Foundation
import TVServices

private enum TopShelfShared {
  static let schemaVersion = 2
  static let appGroupIdentifier = "group.com.edde746.plezy"
  static let cacheDataKey = "PlezySystemShelfCacheData"
  static let artworkDirectoryName = "SystemShelfArtwork"

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
      type = try container.decodeIfPresent(String.self, forKey: .type)
      duration = container.decodeFlexibleDoubleIfPresent(.duration)
      lastPlaybackPosition = container.decodeFlexibleDoubleIfPresent(.lastPlaybackPosition)
      seasonNumber = container.decodeFlexibleIntIfPresent(.seasonNumber)
      episodeNumber = container.decodeFlexibleIntIfPresent(.episodeNumber)
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
  override func loadTopShelfContent() async -> (any TVTopShelfContent)? { buildContent() }

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
    item.imageShape = .hdtv

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
    if let key = cacheItem.artworkKey, let localURL = localArtworkURL(ownerId: ownerId, key: key) {
      item.setImageURL(localURL, for: .screenScale1x)
      item.setImageURL(localURL, for: .screenScale2x)
    }
    return item
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
    if let episodePrefix { return "\(item.title) - \(episodePrefix) - \(episodeTitle)" }
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
