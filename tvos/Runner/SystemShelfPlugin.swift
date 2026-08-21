import CryptoKit
import Foundation
import ImageIO
import Security
import TVServices

#if os(tvOS)
  import Flutter

  struct SystemShelfMutationEnvelope {
    let ownerId: String
    let generation: Int64
    let engineEpoch: UInt64
  }

  struct SystemShelfPruneBatch {
    let token: UInt64
    let candidates: Set<URL>
    let delay: TimeInterval
  }

  struct SystemShelfMutationState {
    private(set) var activeEngineEpoch: UInt64 = 0
    private(set) var ownerId = ""
    private(set) var generation: Int64 = 0
    private static let maximumPruneCandidatesPerBatch = 64
    private var nextPruneToken: UInt64 = 0
    private var pendingPrunes: [URL: UInt64] = [:]

    mutating func beginEngineSession() -> UInt64 {
      activeEngineEpoch &+= 1
      ownerId = ""
      generation = 0
      pendingPrunes.removeAll()
      return activeEngineEpoch
    }

    func accepts(_ envelope: SystemShelfMutationEnvelope, clearing: Bool = false) -> Bool {
      guard envelope.engineEpoch == activeEngineEpoch else { return false }
      if envelope.generation < generation { return false }
      if envelope.generation > generation { return true }
      return clearing
        ? ownerId.isEmpty || ownerId == envelope.ownerId
        : ownerId == envelope.ownerId
    }

    mutating func commit(
      _ envelope: SystemShelfMutationEnvelope,
      clearing: Bool = false,
      operation: () -> Bool
    ) -> Bool {
      guard accepts(envelope, clearing: clearing), operation() else { return false }
      ownerId = clearing ? "" : envelope.ownerId
      generation = envelope.generation
      return true
    }

    mutating func adoptPersistedOwner(_ persistedOwnerId: String) -> SystemShelfMutationEnvelope? {
      guard !persistedOwnerId.isEmpty, ownerId.isEmpty, generation == 0 else { return nil }
      ownerId = persistedOwnerId
      return SystemShelfMutationEnvelope(
        ownerId: persistedOwnerId,
        generation: 0,
        engineEpoch: activeEngineEpoch
      )
    }

    mutating func cancelPruning(keeping files: Set<URL>) {
      for file in files {
        pendingPrunes.removeValue(forKey: file.standardizedFileURL)
      }
    }

    mutating func cancelAllPruning() {
      pendingPrunes.removeAll()
    }

    mutating func preparePruning(
      removing files: Set<URL>,
      after delay: TimeInterval
    ) -> [SystemShelfPruneBatch] {
      let candidates = Set(files.map(\.standardizedFileURL))
        .sorted { $0.path < $1.path }
      guard !candidates.isEmpty else { return [] }
      var batches: [SystemShelfPruneBatch] = []
      batches.reserveCapacity(
        (candidates.count + Self.maximumPruneCandidatesPerBatch - 1)
          / Self.maximumPruneCandidatesPerBatch
      )
      for start in stride(
        from: 0,
        to: candidates.count,
        by: Self.maximumPruneCandidatesPerBatch
      ) {
        let end = min(start + Self.maximumPruneCandidatesPerBatch, candidates.count)
        nextPruneToken &+= 1
        let batchCandidates = Set(candidates[start..<end])
        for file in batchCandidates {
          pendingPrunes[file] = nextPruneToken
        }
        batches.append(
          SystemShelfPruneBatch(
            token: nextPruneToken,
            candidates: batchCandidates,
            delay: max(0, delay)
          )
        )
      }
      return batches
    }

    mutating func claimPruning(_ batch: SystemShelfPruneBatch) -> Set<URL> {
      var claimed = Set<URL>()
      for file in batch.candidates {
        let candidate = file.standardizedFileURL
        guard pendingPrunes[candidate] == batch.token else { continue }
        pendingPrunes.removeValue(forKey: candidate)
        claimed.insert(candidate)
      }
      return claimed
    }
  }

  struct BoundedArtworkDownload {
    let data: Data
    let mimeType: String
  }

  final class BoundedArtworkLoader: NSObject, URLSessionDataDelegate {
    private let maximumBytes: Int
    private let configuration: URLSessionConfiguration
    private let terminalSemaphore = DispatchSemaphore(value: 0)
    private let stateLock = NSLock()
    private var buffer: Data
    private var responseMimeType: String?
    private var terminalResult: BoundedArtworkDownload?
    private var isFinished = false
    private var _peakBufferedBytes = 0
    private var _exceededLimit = false

    init(maximumBytes: Int, configuration: URLSessionConfiguration = .ephemeral) {
      precondition(maximumBytes > 0)
      self.maximumBytes = maximumBytes
      self.configuration = configuration
      buffer = Data()
      super.init()
    }

    var peakBufferedBytes: Int {
      stateLock.lock()
      defer { stateLock.unlock() }
      return _peakBufferedBytes
    }

    var exceededLimit: Bool {
      stateLock.lock()
      defer { stateLock.unlock() }
      return _exceededLimit
    }

    func load(url: URL, timeout: TimeInterval) -> BoundedArtworkDownload? {
      let delegateQueue = OperationQueue()
      delegateQueue.maxConcurrentOperationCount = 1
      let session = URLSession(
        configuration: configuration,
        delegate: self,
        delegateQueue: delegateQueue
      )
      let task = session.dataTask(with: url)
      task.resume()
      if terminalSemaphore.wait(timeout: .now() + timeout) == .timedOut {
        finish(nil)
        task.cancel()
        session.invalidateAndCancel()
      } else {
        session.finishTasksAndInvalidate()
      }
      stateLock.lock()
      defer { stateLock.unlock() }
      return terminalResult
    }

    func urlSession(
      _ session: URLSession,
      dataTask: URLSessionDataTask,
      didReceive response: URLResponse,
      completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
      guard let http = response as? HTTPURLResponse,
        (200...299).contains(http.statusCode),
        ["http", "https"].contains(http.url?.scheme?.lowercased() ?? ""),
        let mimeType = http.mimeType?.lowercased(),
        http.expectedContentLength < 0 || http.expectedContentLength <= Int64(maximumBytes)
      else {
        completionHandler(.cancel)
        return
      }
      stateLock.lock()
      responseMimeType = mimeType
      stateLock.unlock()
      completionHandler(.allow)
    }

    func urlSession(
      _ session: URLSession,
      dataTask: URLSessionDataTask,
      didReceive data: Data
    ) {
      var exceeded = false
      stateLock.lock()
      if !isFinished {
        if data.count > maximumBytes - buffer.count {
          _exceededLimit = true
          exceeded = true
        } else {
          buffer.append(data)
          _peakBufferedBytes = max(_peakBufferedBytes, buffer.count)
        }
      }
      stateLock.unlock()
      if exceeded {
        finish(nil)
        dataTask.cancel()
      }
    }

    func urlSession(
      _ session: URLSession,
      task: URLSessionTask,
      didCompleteWithError error: Error?
    ) {
      stateLock.lock()
      let result: BoundedArtworkDownload?
      if error == nil, !_exceededLimit, let mimeType = responseMimeType {
        result = BoundedArtworkDownload(data: buffer, mimeType: mimeType)
      } else {
        result = nil
      }
      stateLock.unlock()
      finish(result)
    }

    private func finish(_ result: BoundedArtworkDownload?) {
      stateLock.lock()
      guard !isFinished else {
        stateLock.unlock()
        return
      }
      isFinished = true
      terminalResult = result
      stateLock.unlock()
      terminalSemaphore.signal()
    }
  }

  struct SystemShelfSyncEnvironment {
    typealias ArtworkLoader = (URL, Int, TimeInterval) -> BoundedArtworkDownload?

    let defaults: UserDefaults
    let artworkRoot: URL
    let now: () -> Date
    let loadArtwork: ArtworkLoader
    let schedulePrune: ([SystemShelfPruneBatch]) -> Void
    let notifyChange: () -> Void
  }

  final class SystemShelfPlugin: NSObject, FlutterPlugin {
    static let schemaVersion = 3
    static let appGroupIdentifier = "group.com.edde746.plezy"
    static let cacheDataKey = "PlezySystemShelfCacheData"
    static let sourcesKey = "PlezySystemShelfSources"
    static let tokenKeychainService = "com.edde746.plezy.systemshelf.tokens"
    static let artworkDirectoryName = "SystemShelfArtwork"
    private static let maxItems = 20
    private static let maxImageBytes = 2 * 1024 * 1024
    private static let maxSyncBytes = 8 * 1024 * 1024
    private static let syncTimeout: TimeInterval = 8
    private static let imageTimeout: TimeInterval = 2.5
    private static let staleArtworkGracePeriod: TimeInterval = 60
    private static let mutationQueue = DispatchQueue(label: "com.plezy.system-shelf", qos: .utility)
    private static let deepLinkDelivery = TvosDeepLinkDeliveryCoordinator()
    private static var methodChannel: FlutterMethodChannel?
    private static var mutationState = SystemShelfMutationState()
    private let engineEpoch: UInt64

    private init(engineEpoch: UInt64) {
      self.engineEpoch = engineEpoch
      super.init()
    }

    static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: "com.plezy/system_shelf", binaryMessenger: registrar.messenger())
      let engineEpoch = mutationQueue.sync {
        mutationState.beginEngineSession()
      }
      methodChannel = channel
      deepLinkDelivery.bindEngine()
      registrar.addMethodCallDelegate(SystemShelfPlugin(engineEpoch: engineEpoch), channel: channel)
      mutationQueue.async { scrubLegacyPayload() }
    }

    static func handleOpenURL(_ url: URL) -> Bool {
      guard let contentId = contentId(from: url) else { return false }
      switch deepLinkDelivery.receive(contentId: contentId) {
      case let .deliver(event):
        deliverLive(event)
      case .retained, .duplicate:
        break
      }
      return true
    }

    private static func contentId(from url: URL) -> String? {
      guard url.scheme == "plezy", url.host == "play" else { return nil }
      return URLComponents(url: url, resolvingAgainstBaseURL: false)?
        .queryItems?.first { $0.name == "content_id" }?.value
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "isSupported":
        result(Self.sharedDefaults != nil && Self.artworkRoot != nil)
      case "sync":
        guard let envelope = Self.envelope(call.arguments, engineEpoch: engineEpoch),
          let raw = call.arguments as? [String: Any],
          let items = raw["items"] as? [[String: Any]],
          items.count <= Self.maxItems
        else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid shelf envelope", details: nil))
          return
        }
        Self.perform(result) { Self.sync(envelope: envelope, rawItems: items) }
      case "updateSources":
        guard let envelope = Self.envelope(call.arguments, engineEpoch: engineEpoch),
          let raw = call.arguments as? [String: Any],
          let servers = raw["servers"] as? [[String: Any]]
        else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid shelf envelope", details: nil))
          return
        }
        let maxItems = (raw["maxItems"] as? NSNumber)?.intValue
        Self.perform(result) {
          Self.updateSources(envelope: envelope, rawServers: servers, maxItems: maxItems)
        }
      case "clear":
        guard let envelope = Self.envelope(call.arguments, engineEpoch: engineEpoch) else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid shelf envelope", details: nil))
          return
        }
        Self.perform(result) { Self.clearCache(envelope: envelope) }
      case "remove":
        guard let envelope = Self.envelope(call.arguments, engineEpoch: engineEpoch),
          let raw = call.arguments as? [String: Any],
          let contentId = raw["contentId"] as? String
        else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid shelf envelope", details: nil))
          return
        }
        Self.perform(result) { Self.removeItem(envelope: envelope, contentId: contentId) }
      case "getInitialDeepLink":
        let event = Self.deepLinkDelivery.beginLiveDelivery()
        result(event?.contentId)
        if let event, let next = Self.deepLinkDelivery.complete(event, succeeded: true) {
          Self.deliverLive(next)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    private static func deliverLive(_ event: TvosDeepLinkDeliveryCoordinator.Event) {
      guard let channel = methodChannel else { return }
      channel.invokeMethod("onShelfItemTap", arguments: event.flutterArguments) { reply in
        let succeeded = flutterDeliverySucceeded(reply)
        if let next = deepLinkDelivery.complete(event, succeeded: succeeded) {
          deliverLive(next)
        }
      }
    }

    private static func flutterDeliverySucceeded(_ reply: Any?) -> Bool {
      reply as? Bool == true
    }

    private static func perform(_ result: @escaping FlutterResult, operation: @escaping () -> Bool) {
      mutationQueue.async {
        let value = operation()
        DispatchQueue.main.async { result(value) }
      }
    }

    private static func envelope(
      _ arguments: Any?,
      engineEpoch: UInt64
    ) -> SystemShelfMutationEnvelope? {
      guard let args = arguments as? [String: Any],
        (args["schemaVersion"] as? NSNumber)?.intValue == schemaVersion,
        let owner = args["ownerId"] as? String,
        !owner.isEmpty,
        let generation = (args["generation"] as? NSNumber)?.int64Value,
        generation > 0
      else { return nil }
      return SystemShelfMutationEnvelope(
        ownerId: owner,
        generation: generation,
        engineEpoch: engineEpoch
      )
    }

    static var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupIdentifier) }

    static var artworkRoot: URL? {
      FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
        .appendingPathComponent(artworkDirectoryName, isDirectory: true)
    }

    private struct CommittedArtwork {
      let sourceHash: String?
      let key: String
    }

    private static func sync(envelope: SystemShelfMutationEnvelope, rawItems: [[String: Any]]) -> Bool {
      guard let defaults = sharedDefaults, let root = artworkRoot else { return false }
      let environment = SystemShelfSyncEnvironment(
        defaults: defaults,
        artworkRoot: root,
        now: Date.init,
        loadArtwork: { url, maximumBytes, timeout in
          let configuration = URLSessionConfiguration.ephemeral
          configuration.timeoutIntervalForRequest = timeout
          configuration.timeoutIntervalForResource = timeout
          return BoundedArtworkLoader(
            maximumBytes: maximumBytes,
            configuration: configuration
          ).load(url: url, timeout: timeout)
        },
        schedulePrune: { batches in
          schedulePrune(batches)
        },
        notifyChange: {
          TVTopShelfContentProvider.topShelfContentDidChange()
        }
      )
      return sync(
        envelope: envelope,
        rawItems: rawItems,
        state: &mutationState,
        environment: environment
      )
    }

    static func sync(
      envelope: SystemShelfMutationEnvelope,
      rawItems: [[String: Any]],
      state: inout SystemShelfMutationState,
      environment: SystemShelfSyncEnvironment
    ) -> Bool {
      let defaults = environment.defaults
      let root = environment.artworkRoot
      guard state.accepts(envelope) else { return false }
      let previouslyCommittedArtwork = committedArtworkFiles(defaults: defaults, root: root)
      let deadline = environment.now().addingTimeInterval(syncTimeout)
      let ownerDirectory = root.appendingPathComponent(ownerHash(envelope.ownerId), isDirectory: true)
      do {
        try FileManager.default.createDirectory(at: ownerDirectory, withIntermediateDirectories: true)
      } catch {
        return false
      }
      let priorArtwork = committedArtworkByContentId(
        defaults: defaults,
        ownerId: envelope.ownerId,
        directory: ownerDirectory
      )

      var remaining = maxSyncBytes
      var files = Set<String>()
      var materializedFiles = Set<String>()
      let items = rawItems.compactMap { raw -> [String: Any]? in
        guard let contentId = raw["contentId"] as? String, !contentId.isEmpty,
          let title = raw["title"] as? String
        else { return nil }
        var item: [String: Any] = ["contentId": contentId, "title": title]
        for key in [
          "episodeTitle", "description", "type", "duration", "lastPlaybackPosition",
          "lastEngagementTime", "seriesTitle", "seasonNumber", "episodeNumber",
        ] {
          if let value = sanitizedJSONValue(raw[key] as Any) { item[key] = value }
        }
        if let source = raw["posterSourceUri"] as? String,
          let sourceHash = artworkSourceHash(source)
        {
          item["artworkSourceHash"] = sourceHash
          let prior = priorArtwork[contentId]
          if let prior, prior.sourceHash == sourceHash {
            item["artworkKey"] = prior.key
            files.insert(prior.key)
          } else {
            let materialized =
              environment.now() < deadline
              ? materialize(
                source: source,
                directory: ownerDirectory,
                remaining: &remaining,
                deadline: deadline,
                now: environment.now,
                loader: environment.loadArtwork
              )
              : nil
            if let materialized {
              item["artworkKey"] = materialized
              files.insert(materialized)
              materializedFiles.insert(materialized)
            } else if let prior {
              // Retain the last committed image on a transient download failure.
              // Preserve its source identity when known so a changed source is
              // retried, and leave legacy identity absent for the same reason.
              if let priorSourceHash = prior.sourceHash {
                item["artworkSourceHash"] = priorSourceHash
              } else {
                item.removeValue(forKey: "artworkSourceHash")
              }
              item["artworkKey"] = prior.key
              files.insert(prior.key)
            }
          }
        }
        return item
      }

      let payload: [String: Any] = [
        "schemaVersion": schemaVersion,
        "ownerId": envelope.ownerId,
        "updatedAt": Date().timeIntervalSince1970,
        "sections": [["id": "continue_watching", "title": "Continue Watching", "items": items]],
      ]
      guard
        state.commit(
          envelope,
          operation: {
            writePayload(payload, defaults: defaults)
          })
      else {
        pruneRejectedSync(ownerDirectory: ownerDirectory, removing: materializedFiles)
        return false
      }
      let committedArtwork = Set(
        files.map { ownerDirectory.appendingPathComponent($0, isDirectory: false) }
      )
      state.cancelPruning(keeping: committedArtwork)
      environment.schedulePrune(
        state.preparePruning(
          removing: previouslyCommittedArtwork.subtracting(committedArtwork),
          after: staleArtworkGracePeriod
        )
      )
      environment.notifyChange()
      return true
    }

    private static func updateSources(
      envelope: SystemShelfMutationEnvelope,
      rawServers: [[String: Any]],
      maxItems: Int?
    ) -> Bool {
      guard let defaults = sharedDefaults else { return false }
      return updateSources(
        envelope: envelope,
        rawServers: rawServers,
        maxItems: maxItems,
        state: &mutationState,
        defaults: defaults,
        storeTokens: storeSourceTokens,
        notifyChange: {
          TVTopShelfContentProvider.topShelfContentDidChange()
        }
      )
    }

    /// Persists token-free source descriptors to app-group defaults and the
    /// serverId-to-token map to the keychain so the Top Shelf extension can
    /// fetch Continue Watching live. Tokens never touch defaults or logs.
    static func updateSources(
      envelope: SystemShelfMutationEnvelope,
      rawServers: [[String: Any]],
      maxItems: Int?,
      state: inout SystemShelfMutationState,
      defaults: UserDefaults,
      storeTokens: (String, [String: String]) -> Bool,
      notifyChange: () -> Void
    ) -> Bool {
      guard state.accepts(envelope) else { return false }
      var descriptors: [[String: Any]] = []
      var tokens: [String: String] = [:]
      for raw in rawServers {
        guard let serverId = raw["serverId"] as? String, !serverId.isEmpty,
          tokens[serverId] == nil,
          let kind = raw["kind"] as? String, ["plex", "jellyfin", "emby"].contains(kind),
          let name = raw["name"] as? String,
          let baseUrl = raw["baseUrl"] as? String, isHttpUrl(baseUrl),
          let token = raw["token"] as? String, !token.isEmpty
        else { continue }
        var descriptor: [String: Any] = [
          "serverId": serverId, "kind": kind, "name": name, "baseUrl": baseUrl,
        ]
        if let userId = raw["userId"] as? String, !userId.isEmpty {
          descriptor["userId"] = userId
        }
        descriptors.append(descriptor)
        tokens[serverId] = token
      }
      let payload: [String: Any] = [
        "schemaVersion": schemaVersion,
        "ownerId": envelope.ownerId,
        "updatedAt": Date().timeIntervalSince1970,
        "maxItems": min(max(maxItems ?? Self.maxItems, 1), Self.maxItems),
        "servers": descriptors,
      ]
      guard
        state.commit(
          envelope,
          operation: {
            guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              storeTokens(envelope.ownerId, tokens)
            else { return false }
            defaults.set(data, forKey: sourcesKey)
            defaults.synchronize()
            return true
          }
        )
      else { return false }
      notifyChange()
      return true
    }

    private static func isHttpUrl(_ value: String) -> Bool {
      guard let url = URL(string: value) else { return false }
      return ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        && url.host?.isEmpty == false
    }

    private static func materialize(
      source: String,
      directory: URL,
      remaining: inout Int,
      deadline: Date,
      now: () -> Date,
      loader: SystemShelfSyncEnvironment.ArtworkLoader
    ) -> String? {
      guard remaining > 0, let url = URL(string: source), ["http", "https"].contains(url.scheme?.lowercased() ?? "")
      else { return nil }
      let available = min(maxImageBytes, remaining)
      let timeout = min(imageTimeout, deadline.timeIntervalSince(now()))
      guard timeout > 0,
        let download = loader(url, available, timeout),
        download.data.count <= available,
        isSupportedImage(download.data, mimeType: download.mimeType)
      else { return nil }
      let data = download.data
      let key = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "") + ".art"
      let destination = directory.appendingPathComponent(key)
      do {
        try data.write(
          to: destination,
          options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
        remaining -= data.count
        return key
      } catch {
        return nil
      }
    }

    private static func artworkSourceHash(_ source: String) -> String? {
      guard let url = URL(string: source),
        ["http", "https"].contains(url.scheme?.lowercased() ?? "")
      else { return nil }
      return SHA256.hash(data: Data(source.utf8))
        .map { String(format: "%02x", $0) }
        .joined()
    }

    private static func committedArtworkByContentId(
      defaults: UserDefaults,
      ownerId: String,
      directory: URL
    ) -> [String: CommittedArtwork] {
      guard let data = defaults.data(forKey: cacheDataKey),
        let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        (payload["schemaVersion"] as? NSNumber)?.intValue == schemaVersion,
        payload["ownerId"] as? String == ownerId,
        let sections = payload["sections"] as? [[String: Any]]
      else { return [:] }
      var artwork: [String: CommittedArtwork] = [:]
      for item in sections.flatMap({ $0["items"] as? [[String: Any]] ?? [] }) {
        guard let contentId = item["contentId"] as? String, !contentId.isEmpty,
          let key = item["artworkKey"] as? String,
          validatedArtworkFile(key: key, directory: directory) != nil
        else { continue }
        let sourceHash: String?
        if let persistedHash = item["artworkSourceHash"] as? String {
          guard
            persistedHash.range(
              of: "^[a-f0-9]{64}$",
              options: .regularExpression
            ) != nil
          else { continue }
          sourceHash = persistedHash
        } else {
          sourceHash = nil
        }
        artwork[contentId] = CommittedArtwork(sourceHash: sourceHash, key: key)
      }
      return artwork
    }

    private static func validatedArtworkFile(key: String, directory: URL) -> URL? {
      guard isArtworkKey(key) else { return nil }
      let canonicalDirectory = directory.standardizedFileURL.resolvingSymlinksInPath()
      let candidate = directory.appendingPathComponent(key, isDirectory: false).standardizedFileURL
      guard
        let values = try? candidate.resourceValues(
          forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
        ),
        values.isRegularFile == true,
        values.isSymbolicLink != true
      else { return nil }
      let canonicalCandidate = candidate.resolvingSymlinksInPath()
      guard canonicalCandidate.deletingLastPathComponent() == canonicalDirectory else { return nil }
      return canonicalCandidate
    }

    private static func isArtworkKey(_ key: String) -> Bool {
      key.range(of: "^[a-f0-9]{32}\\.art$", options: .regularExpression) != nil
    }

    private static func isSupportedImage(_ data: Data, mimeType: String) -> Bool {
      let supportedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"]
      guard supportedTypes.contains(mimeType),
        let source = CGImageSourceCreateWithData(data as CFData, nil),
        CGImageSourceGetCount(source) > 0,
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
        let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
        let height = properties[kCGImagePropertyPixelHeight] as? NSNumber
      else { return false }
      let w = width.int64Value
      let h = height.int64Value
      return (1...4096).contains(w) && (1...4096).contains(h) && w * h <= 16_777_216
    }

    static func committedArtworkKeys(defaults: UserDefaults, ownerId: String) -> Set<String> {
      guard let data = defaults.data(forKey: cacheDataKey),
        let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        (payload["schemaVersion"] as? NSNumber)?.intValue == schemaVersion,
        payload["ownerId"] as? String == ownerId,
        let sections = payload["sections"] as? [[String: Any]]
      else { return [] }
      return Set(
        sections.flatMap { section in
          (section["items"] as? [[String: Any]])?.compactMap { item in
            guard let key = item["artworkKey"] as? String, isArtworkKey(key) else { return nil }
            return key
          } ?? []
        })
    }

    private static func committedArtworkFiles(defaults: UserDefaults, root: URL) -> Set<URL> {
      guard let data = defaults.data(forKey: cacheDataKey),
        let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        (payload["schemaVersion"] as? NSNumber)?.intValue == schemaVersion,
        let ownerId = payload["ownerId"] as? String,
        !ownerId.isEmpty
      else { return [] }
      let ownerDirectory = root.appendingPathComponent(ownerHash(ownerId), isDirectory: true)
      return Set(
        committedArtworkKeys(defaults: defaults, ownerId: ownerId).map {
          ownerDirectory.appendingPathComponent($0, isDirectory: false)
        }
      )
    }

    private static func writePayload(_ payload: [String: Any], defaults: UserDefaults) -> Bool {
      guard JSONSerialization.isValidJSONObject(payload),
        let data = try? JSONSerialization.data(withJSONObject: payload)
      else { return false }
      defaults.set(data, forKey: cacheDataKey)
      defaults.synchronize()
      return true
    }

    private static func clearCache(envelope: SystemShelfMutationEnvelope) -> Bool {
      guard let defaults = sharedDefaults else { return false }
      return clearCache(
        envelope: envelope,
        state: &mutationState,
        defaults: defaults,
        artworkRoot: artworkRoot,
        clearSourceTokens: {
          deleteAllSourceTokens()
        },
        notifyChange: {
          TVTopShelfContentProvider.topShelfContentDidChange()
        }
      )
    }

    static func clearCache(
      envelope: SystemShelfMutationEnvelope,
      state: inout SystemShelfMutationState,
      defaults: UserDefaults,
      artworkRoot: URL?,
      clearSourceTokens: () -> Void = {},
      notifyChange: () -> Void
    ) -> Bool {
      guard
        state.commit(
          envelope,
          clearing: true,
          operation: {
            defaults.removeObject(forKey: cacheDataKey)
            defaults.removeObject(forKey: sourcesKey)
            defaults.synchronize()
            return true
          }
        )
      else { return false }
      state.cancelAllPruning()
      clearSourceTokens()
      if let artworkRoot {
        try? FileManager.default.removeItem(at: artworkRoot)
      }
      notifyChange()
      return true
    }

    private static func removeItem(
      envelope: SystemShelfMutationEnvelope,
      contentId: String
    ) -> Bool {
      guard let defaults = sharedDefaults, let root = artworkRoot else { return false }
      return removeItem(
        envelope: envelope,
        contentId: contentId,
        state: &mutationState,
        defaults: defaults,
        artworkRoot: root,
        schedulePrune: schedulePrune,
        notifyChange: {
          TVTopShelfContentProvider.topShelfContentDidChange()
        }
      )
    }

    static func removeItem(
      envelope: SystemShelfMutationEnvelope,
      contentId: String,
      state: inout SystemShelfMutationState,
      defaults: UserDefaults,
      artworkRoot root: URL,
      schedulePrune: ([SystemShelfPruneBatch]) -> Void,
      notifyChange: () -> Void
    ) -> Bool {
      guard state.accepts(envelope),
        let data = defaults.data(forKey: cacheDataKey),
        var payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        (payload["schemaVersion"] as? NSNumber)?.intValue == schemaVersion,
        payload["ownerId"] as? String == envelope.ownerId,
        let sections = payload["sections"] as? [[String: Any]]
      else { return false }
      let previouslyCommittedArtwork = committedArtworkFiles(defaults: defaults, root: root)
      var removed = false
      payload["sections"] = sections.map { section -> [String: Any] in
        var next = section
        if let items = section["items"] as? [[String: Any]] {
          let filtered = items.filter { $0["contentId"] as? String != contentId }
          removed = removed || filtered.count != items.count
          next["items"] = filtered
        }
        return next
      }
      guard removed,
        state.commit(
          envelope,
          operation: {
            writePayload(payload, defaults: defaults)
          }
        )
      else { return false }
      let committedArtwork = committedArtworkFiles(defaults: defaults, root: root)
      state.cancelPruning(keeping: committedArtwork)
      schedulePrune(
        state.preparePruning(
          removing: previouslyCommittedArtwork.subtracting(committedArtwork),
          after: staleArtworkGracePeriod
        )
      )
      notifyChange()
      return true
    }

    private static func scrubLegacyPayload() {
      guard let defaults = sharedDefaults else { return }
      scrubLegacySources(defaults: defaults)
      var validOwner: String?
      if let data = defaults.data(forKey: cacheDataKey),
        let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        (payload["schemaVersion"] as? NSNumber)?.intValue == schemaVersion,
        let owner = payload["ownerId"] as? String,
        !owner.isEmpty
      {
        validOwner = owner
      }
      if let validOwner {
        if let root = artworkRoot {
          pruneStaging(root: root)
          let keeping = committedArtworkFiles(defaults: defaults, root: root)
          mutationState.cancelPruning(keeping: keeping)
          if mutationState.adoptPersistedOwner(validOwner) != nil {
            let recovered = Set(
              recoverableArtwork(
                root: root,
                keeping: keeping,
                now: Date()
              ).keys
            )
            schedulePrune(
              mutationState.preparePruning(
                removing: recovered,
                after: staleArtworkGracePeriod
              )
            )
          }
        }
        return
      }
      mutationState.cancelAllPruning()
      defaults.removeObject(forKey: cacheDataKey)
      defaults.synchronize()
      if let root = artworkRoot { try? FileManager.default.removeItem(at: root) }
      TVTopShelfContentProvider.topShelfContentDidChange()
    }

    private static func ownerHash(_ owner: String) -> String {
      SHA256.hash(data: Data(owner.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Removes stale live-fetch sources (and their keychain tokens) whose
    /// persisted payload no longer matches the current schema or lost its
    /// owner; valid sources are left alone even when the item cache is empty.
    private static func scrubLegacySources(defaults: UserDefaults) {
      guard let data = defaults.data(forKey: sourcesKey) else { return }
      if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        (payload["schemaVersion"] as? NSNumber)?.intValue == schemaVersion,
        let owner = payload["ownerId"] as? String,
        !owner.isEmpty
      {
        return
      }
      defaults.removeObject(forKey: sourcesKey)
      defaults.synchronize()
      deleteAllSourceTokens()
    }

    private static func storeSourceTokens(ownerId: String, tokens: [String: String]) -> Bool {
      guard JSONSerialization.isValidJSONObject(tokens),
        let data = try? JSONSerialization.data(withJSONObject: tokens)
      else { return false }
      var attributes: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: tokenKeychainService,
        kSecAttrAccessGroup as String: appGroupIdentifier,
        kSecAttrAccount as String: ownerHash(ownerId),
      ]
      SecItemDelete(attributes as CFDictionary)
      attributes[kSecValueData as String] = data
      attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
      return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    private static func deleteAllSourceTokens() {
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: tokenKeychainService,
        kSecAttrAccessGroup as String: appGroupIdentifier,
      ]
      SecItemDelete(query as CFDictionary)
    }

    static func pruneRejectedSync(ownerDirectory: URL, removing: Set<String>) {
      for key in removing {
        let file = ownerDirectory.appendingPathComponent(key, isDirectory: false)
        try? FileManager.default.removeItem(at: file)
      }
    }

    private static func schedulePrune(_ batches: [SystemShelfPruneBatch]) {
      for batch in batches {
        mutationQueue.asyncAfter(deadline: .now() + batch.delay) {
          executePrune(batch)
        }
      }
    }

    private static func executePrune(_ batch: SystemShelfPruneBatch) {
      let candidates = mutationState.claimPruning(batch)
      guard !candidates.isEmpty, let defaults = sharedDefaults, let root = artworkRoot else {
        return
      }
      pruneUnreferenced(candidates, defaults: defaults, root: root)
    }

    static func recoverableArtwork(
      root: URL,
      keeping: Set<URL>,
      now: Date
    ) -> [URL: Date] {
      guard
        let enumerator = FileManager.default.enumerator(
          at: root,
          includingPropertiesForKeys: nil,
          options: [.skipsHiddenFiles]
        )
      else { return [:] }
      var recovered: [URL: Date] = [:]
      let deadline = now.addingTimeInterval(staleArtworkGracePeriod)
      for case let file as URL in enumerator
      where file.pathExtension == "art" && !keeping.contains(file) {
        // Supersession may have happened immediately before termination, so
        // creation/mtime cannot safely shorten recovery grace.
        recovered[file] = deadline
      }
      return recovered
    }

    static func pruneUnreferenced(
      _ candidates: Set<URL>,
      defaults: UserDefaults,
      root: URL
    ) {
      let lexicalRoot = root.standardizedFileURL
      let lexicalRootPrefix =
        lexicalRoot.path.hasSuffix("/")
        ? lexicalRoot.path
        : lexicalRoot.path + "/"
      let canonicalRoot = lexicalRoot.resolvingSymlinksInPath()
      let canonicalRootPrefix =
        canonicalRoot.path.hasSuffix("/")
        ? canonicalRoot.path
        : canonicalRoot.path + "/"
      let committed = Set(
        committedArtworkFiles(defaults: defaults, root: root)
          .map(\.standardizedFileURL)
      )
      let removable = Set(
        candidates.lazy
          .map(\.standardizedFileURL)
          .filter {
            let canonicalCandidate = $0.resolvingSymlinksInPath()
            return $0.pathExtension == "art"
              && $0.path.hasPrefix(lexicalRootPrefix)
              && canonicalCandidate.path.hasPrefix(canonicalRootPrefix)
              && !committed.contains($0)
          }
      )
      for file in removable {
        try? FileManager.default.removeItem(at: file)
      }
    }

    private static func pruneStaging(root: URL) {
      guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return }
      for case let file as URL in enumerator where file.lastPathComponent.hasPrefix(".") {
        try? FileManager.default.removeItem(at: file)
      }
    }

    private static func sanitizedJSONValue(_ value: Any) -> Any? {
      if value is NSNull { return nil }
      if let value = value as? String { return value }
      if let value = value as? NSNumber {
        if CFGetTypeID(value) == CFBooleanGetTypeID() { return value.boolValue }
        return value.doubleValue.isFinite ? value : nil
      }
      if let value = value as? Bool { return value }
      if let value = value as? Int { return value }
      if let value = value as? Int64 { return value }
      if let value = value as? Double { return value.isFinite ? value : nil }
      return nil
    }
  }
#endif
