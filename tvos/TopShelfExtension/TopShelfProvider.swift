import Foundation
import TVServices

private enum TopShelfShared {
  static let appGroupIdentifier = "group.com.edde746.plezy"
  static let cacheDataKey = "PlezySystemShelfCacheData"

  static var sharedDefaults: UserDefaults? {
    UserDefaults(suiteName: appGroupIdentifier)
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
    let posterUri: String?
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
      case posterUri
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
      posterUri = try container.decodeIfPresent(String.self, forKey: .posterUri)
      type = try container.decodeIfPresent(String.self, forKey: .type)
      duration = container.decodeFlexibleDoubleIfPresent(.duration)
      lastPlaybackPosition = container.decodeFlexibleDoubleIfPresent(.lastPlaybackPosition)
      seasonNumber = container.decodeFlexibleIntIfPresent(.seasonNumber)
      episodeNumber = container.decodeFlexibleIntIfPresent(.episodeNumber)
    }
  }

  let sections: [Section]
}

private extension KeyedDecodingContainer {
  func decodeFlexibleDoubleIfPresent(_ key: Key) -> Double? {
    if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
    if let value = try? decodeIfPresent(Int.self, forKey: key) { return Double(value) }
    if let value = try? decodeIfPresent(String.self, forKey: key) { return Double(value) }
    return nil
  }

  func decodeFlexibleIntIfPresent(_ key: Key) -> Int? {
    if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
    if let value = try? decodeIfPresent(Double.self, forKey: key) { return Int(value) }
    if let value = try? decodeIfPresent(String.self, forKey: key) { return Int(value) }
    return nil
  }
}

final class TopShelfProvider: TVTopShelfContentProvider {
  override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
    return buildContent()
  }

  private func buildContent() -> TVTopShelfContent? {
    guard let defaults = TopShelfShared.sharedDefaults else {
      return nil
    }

    guard let data = defaults.data(forKey: TopShelfShared.cacheDataKey) else {
      return nil
    }

    let payload: TopShelfCachePayload
    do {
      payload = try JSONDecoder().decode(TopShelfCachePayload.self, from: data)
    } catch {
      return nil
    }

    let sections = payload.sections.compactMap { section -> TVTopShelfItemCollection<TVTopShelfSectionedItem>? in
      let items = section.items.compactMap(makeTopShelfItem)
      guard !items.isEmpty else { return nil }

      let collection = TVTopShelfItemCollection(items: items)
      collection.title = section.title
      return collection
    }

    guard !sections.isEmpty else {
      return nil
    }

    return TVTopShelfSectionedContent(sections: sections)
  }

  private func makeTopShelfItem(_ cacheItem: TopShelfCachePayload.Item) -> TVTopShelfSectionedItem? {
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

    if let posterUri = cacheItem.posterUri, let imageURL = URL(string: posterUri) {
      item.setImageURL(imageURL, for: .screenScale1x)
      item.setImageURL(imageURL, for: .screenScale2x)
    }

    return item
  }

  private func displayTitle(for item: TopShelfCachePayload.Item) -> String {
    guard let episodeTitle = item.episodeTitle, !episodeTitle.isEmpty else {
      return item.title
    }

    let episodePrefix: String? = {
      if let seasonNumber = item.seasonNumber, let episodeNumber = item.episodeNumber {
        return "S\(seasonNumber) E\(episodeNumber)"
      }
      if let episodeNumber = item.episodeNumber {
        return "E\(episodeNumber)"
      }
      return nil
    }()

    if let episodePrefix {
      return "\(item.title) - \(episodePrefix) - \(episodeTitle)"
    }
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
