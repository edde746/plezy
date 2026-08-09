import Foundation

// Live Continue Watching fetch for the Top Shelf extension. No Flutter
// import: compiles into both TopShelfExtension and RunnerTests.

enum ShelfFetcher {
  /// Per-request budget; servers are queried in parallel, so the overall
  /// fetch stays inside the ~4 s extension budget.
  static let perRequestTimeout: TimeInterval = 3.5
  static let maxResponseBytes = 4 * 1024 * 1024

  /// Fetches Continue Watching from every source in parallel. Per-server
  /// failures are dropped silently; returns nil unless at least one server
  /// responded, so callers can fall back to the cached payload.
  static func fetchContinueWatching(sources: ShelfSourceStore.Sources) async -> [ShelfFetchedItem]? {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = perRequestTimeout
    configuration.timeoutIntervalForResource = perRequestTimeout
    configuration.waitsForConnectivity = false
    let session = URLSession(configuration: configuration)
    defer { session.finishTasksAndInvalidate() }

    var groups = [[ShelfFetchedItem]?](repeating: nil, count: sources.servers.count)
    await withTaskGroup(of: (Int, [ShelfFetchedItem]?).self) { group in
      for (index, server) in sources.servers.enumerated() {
        group.addTask {
          let items = await fetchServer(server, maxItems: sources.maxItems, session: session)
          return (index, items)
        }
      }
      for await (index, items) in group {
        groups[index] = items
      }
    }
    let succeeded = groups.compactMap { $0 }
    guard !succeeded.isEmpty else { return nil }
    return ShelfItemMapper.merge(succeeded, maxItems: sources.maxItems)
  }

  // MARK: - Request construction (pure; exercised by RunnerTests)

  static func plexContinueWatchingRequest(
    baseUrl: String,
    token: String,
    maxItems: Int
  ) -> URLRequest? {
    guard !token.isEmpty,
      let url = serverURL(
        baseUrl: baseUrl,
        path: "/hubs/continueWatching",
        query: "count=\(maxItems)&includeGuids=1"
      )
    else { return nil }
    var request = URLRequest(url: url)
    request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    return request
  }

  static func mediaBrowserResumeRequest(
    baseUrl: String,
    token: String,
    userId: String,
    maxItems: Int
  ) -> URLRequest? {
    mediaBrowserRequest(
      baseUrl: baseUrl,
      token: token,
      userId: userId,
      path: "/UserItems/Resume",
      trailingQuery: "MediaTypes=Video&Recursive=true&EnableTotalRecordCount=false",
      maxItems: maxItems
    )
  }

  static func mediaBrowserNextUpRequest(
    baseUrl: String,
    token: String,
    userId: String,
    maxItems: Int
  ) -> URLRequest? {
    mediaBrowserRequest(
      baseUrl: baseUrl,
      token: token,
      userId: userId,
      path: "/Shows/NextUp",
      trailingQuery: "EnableResumable=false&EnableTotalRecordCount=false",
      maxItems: maxItems
    )
  }

  private static func mediaBrowserRequest(
    baseUrl: String,
    token: String,
    userId: String,
    path: String,
    trailingQuery: String,
    maxItems: Int
  ) -> URLRequest? {
    guard !token.isEmpty, !userId.isEmpty,
      let encodedUserId = ShelfItemMapper.encodeQueryComponent(userId),
      let url = serverURL(
        baseUrl: baseUrl,
        path: path,
        query: "userId=\(encodedUserId)&Limit=\(maxItems)&\(trailingQuery)"
      )
    else { return nil }
    var request = URLRequest(url: url)
    request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    return request
  }

  private static func serverURL(baseUrl: String, path: String, query: String) -> URL? {
    guard let base = ShelfItemMapper.normalizedBaseUrl(baseUrl) else { return nil }
    return URL(string: "\(base)\(path)?\(query)")
  }

  // MARK: - Transport

  private static func fetchServer(
    _ server: ShelfServerSource,
    maxItems: Int,
    session: URLSession
  ) async -> [ShelfFetchedItem]? {
    let descriptor = server.descriptor
    switch descriptor.kind {
    case .plex:
      guard
        let request = plexContinueWatchingRequest(
          baseUrl: descriptor.baseUrl,
          token: server.token,
          maxItems: maxItems
        ),
        let object = await fetchJSON(request, session: session)
      else { return nil }
      return ShelfItemMapper.plexItems(
        fromResponse: object,
        serverId: descriptor.serverId,
        baseUrl: descriptor.baseUrl,
        token: server.token
      )
    case .jellyfin, .emby:
      guard let userId = descriptor.userId, !userId.isEmpty,
        let resumeRequest = mediaBrowserResumeRequest(
          baseUrl: descriptor.baseUrl,
          token: server.token,
          userId: userId,
          maxItems: maxItems
        ),
        let nextUpRequest = mediaBrowserNextUpRequest(
          baseUrl: descriptor.baseUrl,
          token: server.token,
          userId: userId,
          maxItems: maxItems
        )
      else { return nil }
      async let resumeObject = fetchJSON(resumeRequest, session: session)
      async let nextUpObject = fetchJSON(nextUpRequest, session: session)
      // Resume first so in-progress items win contentId deduplication.
      let responses = [await resumeObject, await nextUpObject].compactMap { $0 }
      guard !responses.isEmpty else { return nil }
      return responses.flatMap {
        ShelfItemMapper.mediaBrowserItems(
          fromResponse: $0,
          serverId: descriptor.serverId,
          baseUrl: descriptor.baseUrl,
          token: server.token
        )
      }
    }
  }

  private static func fetchJSON(_ request: URLRequest, session: URLSession) async -> Any? {
    await withCheckedContinuation { continuation in
      let task = session.dataTask(with: request) { data, response, error in
        guard error == nil,
          let http = response as? HTTPURLResponse,
          (200...299).contains(http.statusCode),
          let data,
          data.count <= maxResponseBytes,
          let object = try? JSONSerialization.jsonObject(with: data)
        else {
          continuation.resume(returning: nil)
          return
        }
        continuation.resume(returning: object)
      }
      task.resume()
    }
  }
}
