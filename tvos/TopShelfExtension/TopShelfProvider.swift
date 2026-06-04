import Foundation
import TVServices

private enum TopShelfShared {
  static let appGroupIdentifier = "group.com.edde746.plezy"
  static let cacheFileName = "PlezySystemShelfCache.json"

  static var cacheURL: URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
      .appendingPathComponent(cacheFileName, isDirectory: false)
  }

  static func log(_ message: String) {
    NSLog("PlezyTopShelf: %@", message)
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
  }

  let sections: [Section]
}

final class TopShelfProvider: TVTopShelfContentProvider {
  override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
    buildContent()
  }

  private func buildContent() -> TVTopShelfContent? {
    guard let url = TopShelfShared.cacheURL else {
      TopShelfShared.log("App Group container unavailable")
      return nil
    }

    guard FileManager.default.fileExists(atPath: url.path) else {
      TopShelfShared.log("Cache file missing")
      return nil
    }

    let payload: TopShelfCachePayload
    do {
      let data = try Data(contentsOf: url)
      payload = try JSONDecoder().decode(TopShelfCachePayload.self, from: data)
    } catch {
      TopShelfShared.log("Failed to read cache: \(error)")
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
      TopShelfShared.log("Cache has no displayable items")
      return nil
    }

    let itemCount = sections.reduce(0) { $0 + $1.items.count }
    TopShelfShared.log("Loaded \(itemCount) items")
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
