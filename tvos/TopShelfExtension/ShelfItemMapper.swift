import Foundation

// Pure response-to-item mapping for the live Top Shelf fetch. No Flutter
// import: compiles into both TopShelfExtension and RunnerTests.

/// One Continue Watching entry mapped from a media-server response, in the
/// cached-payload item shape (durations/positions in milliseconds).
struct ShelfFetchedItem {
  let contentId: String
  let title: String
  let episodeTitle: String?
  let type: String?
  let seasonNumber: Int?
  let episodeNumber: Int?
  let durationMilliseconds: Double?
  let lastPlaybackPositionMilliseconds: Double?
  let posterUrl: String?
  /// Epoch seconds of the last engagement; 0 when the server did not say.
  let recency: Double

  var playbackProgress: Double? {
    guard let duration = durationMilliseconds, duration > 0,
      let position = lastPlaybackPositionMilliseconds, position > 0
    else { return nil }
    return min(max(position / duration, 0), 1)
  }
}

extension ShelfFetchedItem: CustomStringConvertible, CustomDebugStringConvertible {
  // posterUrl embeds the server token; keep it out of any diagnostic string.
  var description: String { "ShelfFetchedItem(contentId: \(contentId))" }
  var debugDescription: String { description }
}

enum ShelfItemMapper {
  static let posterWidth = 600
  static let posterHeight = 900

  // MARK: - Plex

  /// Parses `MediaContainer.Metadata`, tolerating the hub-wrapped
  /// `MediaContainer.Hub[].Metadata` shape `/hubs` responses use.
  static func plexItems(
    fromResponse object: Any,
    serverId: String,
    baseUrl: String,
    token: String
  ) -> [ShelfFetchedItem] {
    guard let root = object as? [String: Any],
      let container = root["MediaContainer"] as? [String: Any]
    else { return [] }
    var metadata = container["Metadata"] as? [[String: Any]] ?? []
    if metadata.isEmpty, let hubs = container["Hub"] as? [[String: Any]] {
      metadata = hubs.flatMap { $0["Metadata"] as? [[String: Any]] ?? [] }
    }
    return metadata.compactMap {
      plexItem($0, serverId: serverId, baseUrl: baseUrl, token: token)
    }
  }

  static func plexItem(
    _ metadata: [String: Any],
    serverId: String,
    baseUrl: String,
    token: String
  ) -> ShelfFetchedItem? {
    guard let ratingKey = flexibleString(metadata["ratingKey"]), !ratingKey.isEmpty,
      let rawTitle = metadata["title"] as? String, !rawTitle.isEmpty
    else { return nil }
    let type = (metadata["type"] as? String)?.lowercased()
    let seriesTitle = (metadata["grandparentTitle"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    let isEpisode = type == "episode" && seriesTitle != nil
    let posterPath = ["parentThumb", "grandparentThumb", "thumb"]
      .compactMap { metadata[$0] as? String }
      .first { !$0.isEmpty }
    return ShelfFetchedItem(
      contentId: "plezy_\(serverId)_\(ratingKey)",
      title: isEpisode ? seriesTitle! : rawTitle,
      episodeTitle: isEpisode ? rawTitle : nil,
      type: type,
      seasonNumber: isEpisode ? flexibleInt(metadata["parentIndex"]) : nil,
      episodeNumber: isEpisode ? flexibleInt(metadata["index"]) : nil,
      durationMilliseconds: flexibleDouble(metadata["duration"]),
      lastPlaybackPositionMilliseconds: flexibleDouble(metadata["viewOffset"]),
      posterUrl: posterPath.flatMap { plexPosterUrl(path: $0, baseUrl: baseUrl, token: token) },
      recency: flexibleDouble(metadata["lastViewedAt"]) ?? 0
    )
  }

  /// Mirrors PlexClient.thumbnailUrl's cover transcode (`minSize=1&upscale=1`)
  /// at poster size, with the token carried exactly once as the outer
  /// `X-Plex-Token` query parameter.
  static func plexPosterUrl(path: String, baseUrl: String, token: String) -> String? {
    guard let base = normalizedBaseUrl(baseUrl), path.hasPrefix("/"), !token.isEmpty,
      let encodedPath = encodeQueryComponent(path),
      let encodedToken = encodeQueryComponent(token)
    else { return nil }
    return "\(base)/photo/:/transcode?width=\(posterWidth)&height=\(posterHeight)"
      + "&minSize=1&upscale=1&url=\(encodedPath)&X-Plex-Token=\(encodedToken)"
  }

  // MARK: - Jellyfin / Emby (MediaBrowser)

  static func mediaBrowserItems(
    fromResponse object: Any,
    serverId: String,
    baseUrl: String,
    token: String
  ) -> [ShelfFetchedItem] {
    guard let root = object as? [String: Any],
      let items = root["Items"] as? [[String: Any]]
    else { return [] }
    return items.compactMap {
      mediaBrowserItem($0, serverId: serverId, baseUrl: baseUrl, token: token)
    }
  }

  static func mediaBrowserItem(
    _ item: [String: Any],
    serverId: String,
    baseUrl: String,
    token: String
  ) -> ShelfFetchedItem? {
    guard let id = flexibleString(item["Id"]), !id.isEmpty,
      let name = item["Name"] as? String, !name.isEmpty
    else { return nil }
    let type = (item["Type"] as? String)?.lowercased()
    let seriesName = (item["SeriesName"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    let isEpisode = type == "episode" && seriesName != nil
    let userData = item["UserData"] as? [String: Any] ?? [:]
    // Season poster, then series poster, then the item's own primary image.
    let posterItemId =
      ["SeasonId", "SeriesId"]
      .compactMap { flexibleString(item[$0]) }
      .first { !$0.isEmpty } ?? id
    return ShelfFetchedItem(
      contentId: "plezy_\(serverId)_\(id)",
      title: isEpisode ? seriesName! : name,
      episodeTitle: isEpisode ? name : nil,
      type: type,
      seasonNumber: isEpisode ? flexibleInt(item["ParentIndexNumber"]) : nil,
      episodeNumber: isEpisode ? flexibleInt(item["IndexNumber"]) : nil,
      durationMilliseconds: flexibleDouble(item["RunTimeTicks"]).map { $0 / 10_000 },
      lastPlaybackPositionMilliseconds: flexibleDouble(userData["PlaybackPositionTicks"])
        .map { $0 / 10_000 },
      posterUrl: mediaBrowserPosterUrl(itemId: posterItemId, baseUrl: baseUrl, token: token),
      recency: (userData["LastPlayedDate"] as? String).flatMap(parseMediaBrowserDate) ?? 0
    )
  }

  /// Mirrors JellyfinClient.thumbnailUrl's `maxWidth`/`maxHeight`/`api_key`
  /// parameters at poster size.
  static func mediaBrowserPosterUrl(itemId: String, baseUrl: String, token: String) -> String? {
    guard let base = normalizedBaseUrl(baseUrl), !itemId.isEmpty, !token.isEmpty,
      let encodedId = encodeQueryComponent(itemId),
      let encodedToken = encodeQueryComponent(token)
    else { return nil }
    return "\(base)/Items/\(encodedId)/Images/Primary"
      + "?maxWidth=\(posterWidth)&maxHeight=\(posterHeight)&api_key=\(encodedToken)"
  }

  /// Jellyfin emits seven fractional-second digits, which
  /// ISO8601DateFormatter rejects; retry with the fraction stripped.
  static func parseMediaBrowserDate(_ value: String) -> Double? {
    if let date = isoFormatter.date(from: value) { return date.timeIntervalSince1970 }
    guard let dotIndex = value.firstIndex(of: ".") else { return nil }
    var end = value.index(after: dotIndex)
    while end < value.endIndex, value[end].isNumber { end = value.index(after: end) }
    let stripped = String(value[..<dotIndex]) + String(value[end...])
    return isoFormatter.date(from: stripped).map(\.timeIntervalSince1970)
  }

  // MARK: - Merge

  /// Merges per-server successes by recency (descending), deduplicates by
  /// contentId (first occurrence wins), and caps at [maxItems]. Ties keep
  /// their input order.
  static func merge(_ groups: [[ShelfFetchedItem]], maxItems: Int) -> [ShelfFetchedItem] {
    var seen = Set<String>()
    var all: [ShelfFetchedItem] = []
    for item in groups.joined() where seen.insert(item.contentId).inserted {
      all.append(item)
    }
    let sorted = all.enumerated()
      .sorted { lhs, rhs in
        if lhs.element.recency != rhs.element.recency {
          return lhs.element.recency > rhs.element.recency
        }
        return lhs.offset < rhs.offset
      }
      .map(\.element)
    return Array(sorted.prefix(max(0, maxItems)))
  }

  // MARK: - URL building blocks

  static func normalizedBaseUrl(_ baseUrl: String) -> String? {
    var trimmed = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    while trimmed.hasSuffix("/") { trimmed.removeLast() }
    guard let url = URL(string: trimmed),
      ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
      url.host?.isEmpty == false
    else { return nil }
    return trimmed
  }

  /// Matches Dart's `Uri.encodeComponent`: everything but the RFC 2396
  /// unreserved characters is percent-encoded.
  static func encodeQueryComponent(_ value: String) -> String? {
    value.addingPercentEncoding(withAllowedCharacters: dartUnreservedCharacters)
  }

  private static let dartUnreservedCharacters = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()"
  )

  private static let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  // MARK: - Flexible scalar readers (server JSON mixes Int/Double/String)

  private static func flexibleString(_ value: Any?) -> String? {
    if let value = value as? String { return value }
    if let value = value as? NSNumber, CFGetTypeID(value) != CFBooleanGetTypeID() {
      return value.stringValue
    }
    return nil
  }

  private static func flexibleDouble(_ value: Any?) -> Double? {
    guard let value = value as? NSNumber, CFGetTypeID(value) != CFBooleanGetTypeID() else {
      return nil
    }
    return value.doubleValue.isFinite ? value.doubleValue : nil
  }

  private static func flexibleInt(_ value: Any?) -> Int? {
    flexibleDouble(value).map { Int($0) }
  }
}
