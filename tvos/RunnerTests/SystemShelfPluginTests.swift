import Foundation
import Flutter
import XCTest

@testable import Runner

private final class ShelfArtworkURLProtocol: URLProtocol {
  private static let lock = NSLock()
  private static var startHandler: ((ShelfArtworkURLProtocol) -> Void)?
  private static var stopHandler: (() -> Void)?

  static func configure(
    start: @escaping (ShelfArtworkURLProtocol) -> Void,
    stop: (() -> Void)? = nil
  ) {
    lock.lock()
    startHandler = start
    stopHandler = stop
    lock.unlock()
  }

  static func reset() {
    lock.lock()
    startHandler = nil
    stopHandler = nil
    lock.unlock()
  }

  override class func canInit(with request: URLRequest) -> Bool { true }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.lock.lock()
    let handler = Self.startHandler
    Self.lock.unlock()
    guard let handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
      return
    }
    handler(self)
  }

  override func stopLoading() {
    Self.lock.lock()
    let handler = Self.stopHandler
    Self.lock.unlock()
    handler?()
  }

  func sendResponse(contentLength: Int? = nil) {
    var headers = ["Content-Type": "image/png"]
    if let contentLength { headers["Content-Length"] = String(contentLength) }
    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: headers
    )!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
  }

  func send(_ data: Data) {
    client?.urlProtocol(self, didLoad: data)
  }

  func finish() {
    client?.urlProtocolDidFinishLoading(self)
  }
}

private final class SystemShelfSyncHarness {
  let defaults: UserDefaults
  let root: URL
  private(set) var state = SystemShelfMutationState()
  private(set) var epoch: UInt64 = 0

  private struct ScheduledPrune {
    let deadline: TimeInterval
    let batch: SystemShelfPruneBatch
  }

  private let suiteName: String
  private var pruneClock: TimeInterval = 0
  private var scheduledPrunes: [ScheduledPrune] = []

  var now: () -> Date = { Date(timeIntervalSince1970: 1_000) }
  var loaderShouldFail = false
  private(set) var requestedURLs: [URL] = []
  private(set) var notificationCount = 0

  init() throws {
    suiteName = "SystemShelfSyncHarness.\(UUID().uuidString)"
    defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    root = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    epoch = state.beginEngineSession()
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  }

  func cleanup() {
    defaults.removePersistentDomain(forName: suiteName)
    try? FileManager.default.removeItem(at: root)
  }

  @discardableResult
  func beginEngineSession() -> UInt64 {
    epoch = state.beginEngineSession()
    return epoch
  }

  func sync(
    generation: Int64,
    items: [[String: Any]],
    ownerId: String = "profile-a",
    engineEpoch: UInt64? = nil,
    sectionTitle: String? = nil
  ) -> Bool {
    let environment = SystemShelfSyncEnvironment(
      defaults: defaults,
      artworkRoot: root,
      now: now,
      loadArtwork: { [unowned self] url, _, _ in
        requestedURLs.append(url)
        guard !loaderShouldFail else { return nil }
        return BoundedArtworkDownload(data: Self.png, mimeType: "image/png")
      },
      schedulePrune: { [unowned self] batches in
        scheduledPrunes.append(
          contentsOf: batches.map {
            ScheduledPrune(deadline: pruneClock + $0.delay, batch: $0)
          }
        )
      },
      notifyChange: { [unowned self] in
        notificationCount += 1
      }
    )
    return SystemShelfPlugin.sync(
      envelope: envelope(
        generation: generation,
        ownerId: ownerId,
        engineEpoch: engineEpoch
      ),
      rawItems: items,
      sectionTitle: sectionTitle,
      state: &state,
      environment: environment
    )
  }

  func clear(generation: Int64, ownerId: String = "profile-a") -> Bool {
    SystemShelfPlugin.clearCache(
      envelope: envelope(generation: generation, ownerId: ownerId),
      state: &state,
      defaults: defaults,
      artworkRoot: root,
      notifyChange: { [unowned self] in
        notificationCount += 1
      }
    )
  }

  func remove(generation: Int64, contentId: String) -> Bool {
    SystemShelfPlugin.removeItem(
      envelope: envelope(generation: generation),
      contentId: contentId,
      state: &state,
      defaults: defaults,
      artworkRoot: root,
      schedulePrune: { [unowned self] batches in
        scheduledPrunes.append(
          contentsOf: batches.map {
            ScheduledPrune(deadline: pruneClock + $0.delay, batch: $0)
          }
        )
      },
      notifyChange: { [unowned self] in
        notificationCount += 1
      }
    )
  }

  func envelope(
    generation: Int64,
    ownerId: String = "profile-a",
    engineEpoch: UInt64? = nil
  ) -> SystemShelfMutationEnvelope {
    SystemShelfMutationEnvelope(
      ownerId: ownerId,
      generation: generation,
      engineEpoch: engineEpoch ?? epoch
    )
  }

  func currentItems() throws -> [[String: Any]] {
    let data = try XCTUnwrap(defaults.data(forKey: SystemShelfPlugin.cacheDataKey))
    let payload = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    let sections = try XCTUnwrap(payload["sections"] as? [[String: Any]])
    return sections.flatMap { $0["items"] as? [[String: Any]] ?? [] }
  }

  func currentSectionTitles() throws -> [String] {
    let data = try XCTUnwrap(defaults.data(forKey: SystemShelfPlugin.cacheDataKey))
    let payload = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    let sections = try XCTUnwrap(payload["sections"] as? [[String: Any]])
    return sections.compactMap { $0["title"] as? String }
  }

  func artworkURL(for key: String) -> URL? {
    guard
      let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: nil
      )
    else { return nil }
    return enumerator.compactMap { $0 as? URL }.first { $0.lastPathComponent == key }
  }

  func advancePrunes(by interval: TimeInterval) {
    pruneClock += interval
    let due = scheduledPrunes.filter { $0.deadline <= pruneClock }
    scheduledPrunes.removeAll { $0.deadline <= pruneClock }
    for scheduled in due {
      let candidates = state.claimPruning(scheduled.batch)
      SystemShelfPlugin.pruneUnreferenced(
        candidates,
        defaults: defaults,
        root: root
      )
    }
  }

  static func item(
    source: String? = nil,
    progress: Int = 0,
    contentId: String = "movie-1"
  ) -> [String: Any] {
    var item: [String: Any] = [
      "contentId": contentId,
      "title": "Movie",
      "lastPlaybackPosition": progress,
    ]
    if let source {
      item["posterSourceUri"] = source
    }
    return item
  }

  static let png = Data(
    base64Encoded:
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
  )!
}

final class SystemShelfPluginTests: XCTestCase {
  override func tearDown() {
    ShelfArtworkURLProtocol.reset()
    super.tearDown()
  }

  func testSyncRemoveAndClearUpdateCommittedShelf() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }

    XCTAssertTrue(
      harness.sync(
        generation: 1,
        items: [
          SystemShelfSyncHarness.item(
            source: "https://shelf.test/a.png",
            contentId: "movie-a"
          ),
          SystemShelfSyncHarness.item(
            source: "https://shelf.test/b.png",
            contentId: "movie-b"
          ),
        ]
      )
    )
    let initialItems = try harness.currentItems()
    XCTAssertEqual(Set(initialItems.compactMap { $0["contentId"] as? String }), ["movie-a", "movie-b"])
    let removedKey = try XCTUnwrap(
      initialItems.first { $0["contentId"] as? String == "movie-a" }?["artworkKey"] as? String
    )
    let removedArtwork = try XCTUnwrap(harness.artworkURL(for: removedKey))

    XCTAssertTrue(harness.remove(generation: 2, contentId: "movie-a"))
    XCTAssertEqual(try harness.currentItems().compactMap { $0["contentId"] as? String }, ["movie-b"])
    XCTAssertTrue(FileManager.default.fileExists(atPath: removedArtwork.path))
    harness.advancePrunes(by: 60)
    XCTAssertFalse(FileManager.default.fileExists(atPath: removedArtwork.path))

    XCTAssertTrue(harness.clear(generation: 3))
    XCTAssertNil(harness.defaults.data(forKey: SystemShelfPlugin.cacheDataKey))
    XCTAssertFalse(FileManager.default.fileExists(atPath: harness.root.path))
    XCTAssertEqual(harness.notificationCount, 3)
  }

  func testSyncPersistsLocalizedSectionTitleWithEnglishFallback() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }

    XCTAssertTrue(
      harness.sync(
        generation: 1,
        items: [SystemShelfSyncHarness.item()],
        sectionTitle: "Fortsett å se"
      )
    )
    XCTAssertEqual(try harness.currentSectionTitles(), ["Fortsett å se"])

    // Absent or empty titles fall back to the English literal so an older
    // app build keeps rendering a labelled shelf.
    XCTAssertTrue(
      harness.sync(
        generation: 2,
        items: [SystemShelfSyncHarness.item()],
        sectionTitle: ""
      )
    )
    XCTAssertEqual(try harness.currentSectionTitles(), ["Continue Watching"])

    XCTAssertTrue(harness.sync(generation: 3, items: [SystemShelfSyncHarness.item()]))
    XCTAssertEqual(try harness.currentSectionTitles(), ["Continue Watching"])
  }

  func testReplacementEngineRejectsStaleEngineMutation() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }
    let staleEpoch = harness.epoch

    XCTAssertTrue(
      harness.sync(
        generation: 50,
        items: [SystemShelfSyncHarness.item(progress: 50)]
      )
    )
    _ = harness.beginEngineSession()
    XCTAssertTrue(
      harness.sync(
        generation: 1,
        items: [SystemShelfSyncHarness.item(progress: 1)],
        ownerId: "profile-b"
      )
    )

    XCTAssertFalse(
      harness.sync(
        generation: 51,
        items: [SystemShelfSyncHarness.item(progress: 99)],
        engineEpoch: staleEpoch
      )
    )
    let item = try XCTUnwrap(harness.currentItems().first)
    XCTAssertEqual(item["lastPlaybackPosition"] as? Int, 1)
    let data = try XCTUnwrap(
      harness.defaults.data(forKey: SystemShelfPlugin.cacheDataKey)
    )
    let payload = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    XCTAssertEqual(payload["ownerId"] as? String, "profile-b")
  }

  func testHigherGenerationRemainsLastWriter() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }

    XCTAssertTrue(
      harness.sync(
        generation: 2,
        items: [SystemShelfSyncHarness.item(progress: 20)]
      )
    )
    XCTAssertFalse(
      harness.sync(
        generation: 1,
        items: [SystemShelfSyncHarness.item(progress: 10)]
      )
    )
    XCTAssertEqual(
      try harness.currentItems().first?["lastPlaybackPosition"] as? Int,
      20
    )
    XCTAssertEqual(harness.notificationCount, 1)
  }

  func testProgressOnlySyncReusesCommittedArtworkWithoutRequestingItAgain() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }
    let source = "https://shelf.test/movie-a.png"

    XCTAssertTrue(
      harness.sync(
        generation: 1,
        items: [SystemShelfSyncHarness.item(source: source, progress: 10)]
      )
    )
    let firstKey = try XCTUnwrap(harness.currentItems().first?["artworkKey"] as? String)
    let firstArtwork = try XCTUnwrap(harness.artworkURL(for: firstKey))

    XCTAssertTrue(
      harness.sync(
        generation: 2,
        items: [SystemShelfSyncHarness.item(source: source, progress: 45)]
      )
    )
    let updatedItem = try XCTUnwrap(harness.currentItems().first)
    XCTAssertEqual(updatedItem["lastPlaybackPosition"] as? Int, 45)
    XCTAssertEqual(updatedItem["artworkKey"] as? String, firstKey)
    XCTAssertEqual(harness.requestedURLs.map(\.absoluteString), [source])
    XCTAssertTrue(FileManager.default.fileExists(atPath: firstArtwork.path))
  }

  func testFailedReplacementKeepsLastCommittedArtwork() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }
    let firstSource = "https://shelf.test/movie-a.png"

    XCTAssertTrue(
      harness.sync(
        generation: 1,
        items: [SystemShelfSyncHarness.item(source: firstSource)]
      )
    )
    let firstKey = try XCTUnwrap(harness.currentItems().first?["artworkKey"] as? String)
    let firstArtwork = try XCTUnwrap(harness.artworkURL(for: firstKey))

    harness.loaderShouldFail = true
    XCTAssertTrue(
      harness.sync(
        generation: 2,
        items: [
          SystemShelfSyncHarness.item(source: "https://shelf.test/movie-b.png", progress: 20)
        ]
      )
    )

    let item = try XCTUnwrap(harness.currentItems().first)
    XCTAssertEqual(item["artworkKey"] as? String, firstKey)
    XCTAssertTrue(FileManager.default.fileExists(atPath: firstArtwork.path))
    XCTAssertEqual(
      harness.requestedURLs.map(\.absoluteString),
      [firstSource, "https://shelf.test/movie-b.png"]
    )
  }

  func testEachSupersededArtworkReceivesFullPruneGrace() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }

    XCTAssertTrue(
      harness.sync(
        generation: 1,
        items: [SystemShelfSyncHarness.item(source: "https://shelf.test/a.png")]
      )
    )
    let firstKey = try XCTUnwrap(harness.currentItems().first?["artworkKey"] as? String)
    let firstArtwork = try XCTUnwrap(harness.artworkURL(for: firstKey))
    XCTAssertTrue(
      harness.sync(
        generation: 2,
        items: [SystemShelfSyncHarness.item(source: "https://shelf.test/b.png")]
      )
    )
    let secondKey = try XCTUnwrap(harness.currentItems().first?["artworkKey"] as? String)
    let secondArtwork = try XCTUnwrap(harness.artworkURL(for: secondKey))

    harness.advancePrunes(by: 59)
    XCTAssertTrue(FileManager.default.fileExists(atPath: firstArtwork.path))
    XCTAssertTrue(
      harness.sync(
        generation: 3,
        items: [SystemShelfSyncHarness.item(source: "https://shelf.test/c.png")]
      )
    )
    let currentKey = try XCTUnwrap(harness.currentItems().first?["artworkKey"] as? String)
    let currentArtwork = try XCTUnwrap(harness.artworkURL(for: currentKey))

    harness.advancePrunes(by: 1)
    XCTAssertFalse(FileManager.default.fileExists(atPath: firstArtwork.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: secondArtwork.path))
    harness.advancePrunes(by: 58)
    XCTAssertTrue(FileManager.default.fileExists(atPath: secondArtwork.path))
    harness.advancePrunes(by: 1)
    XCTAssertFalse(FileManager.default.fileExists(atPath: secondArtwork.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: currentArtwork.path))
  }

  func testPruneRechecksCurrentArtworkAndRelaunchRecoveryPreservesIt() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }

    XCTAssertTrue(
      harness.sync(
        generation: 1,
        items: [SystemShelfSyncHarness.item(source: "https://shelf.test/a.png")]
      )
    )
    let firstKey = try XCTUnwrap(harness.currentItems().first?["artworkKey"] as? String)
    let firstArtwork = try XCTUnwrap(harness.artworkURL(for: firstKey))
    XCTAssertTrue(
      harness.sync(
        generation: 2,
        items: [SystemShelfSyncHarness.item(source: "https://shelf.test/b.png")]
      )
    )
    let secondKey = try XCTUnwrap(harness.currentItems().first?["artworkKey"] as? String)
    let secondArtwork = try XCTUnwrap(harness.artworkURL(for: secondKey))

    try replaceCommittedArtworkKey(
      in: harness.defaults,
      with: firstKey
    )
    harness.advancePrunes(by: 60)
    XCTAssertTrue(FileManager.default.fileExists(atPath: firstArtwork.path))

    let relaunchedAt = Date(timeIntervalSince1970: 10_000)
    let recovered = SystemShelfPlugin.recoverableArtwork(
      root: harness.root,
      keeping: [firstArtwork],
      now: relaunchedAt
    )
    XCTAssertEqual(
      recovered[secondArtwork],
      relaunchedAt.addingTimeInterval(60)
    )
    XCTAssertNil(recovered[firstArtwork])

    var relaunchedState = SystemShelfMutationState()
    _ = relaunchedState.beginEngineSession()
    XCTAssertNotNil(relaunchedState.adoptPersistedOwner("profile-a"))
    relaunchedState.cancelPruning(keeping: [firstArtwork])
    let batches = relaunchedState.preparePruning(
      removing: Set(recovered.keys),
      after: 60
    )
    XCTAssertEqual(batches.count, 1)
    XCTAssertEqual(batches.first?.delay, 60)
    let candidates = relaunchedState.claimPruning(try XCTUnwrap(batches.first))
    SystemShelfPlugin.pruneUnreferenced(
      candidates,
      defaults: harness.defaults,
      root: harness.root
    )
    XCTAssertFalse(FileManager.default.fileExists(atPath: secondArtwork.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: firstArtwork.path))
  }

  func testPruneDoesNotEscapeArtworkRoot() throws {
    let harness = try SystemShelfSyncHarness()
    defer { harness.cleanup() }
    let outside = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(UUID().uuidString).art")
    let inside = harness.root.appendingPathComponent("orphan.art")
    let outsideDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let outsideViaSymlink = outsideDirectory.appendingPathComponent("linked.art")
    let linkedDirectory = harness.root.appendingPathComponent("linked", isDirectory: true)
    let linkedCandidate = linkedDirectory.appendingPathComponent("linked.art")
    try Data([0x01]).write(to: outside)
    try Data([0x02]).write(to: inside)
    try FileManager.default.createDirectory(
      at: outsideDirectory,
      withIntermediateDirectories: true
    )
    try Data([0x03]).write(to: outsideViaSymlink)
    try FileManager.default.createSymbolicLink(
      at: linkedDirectory,
      withDestinationURL: outsideDirectory
    )
    defer {
      try? FileManager.default.removeItem(at: outside)
      try? FileManager.default.removeItem(at: outsideDirectory)
    }

    SystemShelfPlugin.pruneUnreferenced(
      [outside, inside, linkedCandidate],
      defaults: harness.defaults,
      root: harness.root
    )

    XCTAssertTrue(FileManager.default.fileExists(atPath: outside.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: outsideViaSymlink.path))
    XCTAssertFalse(FileManager.default.fileExists(atPath: inside.path))
  }

  func testArtworkLoaderCancelsUnknownLengthBodyAtConfiguredCap() {
    let stopped = expectation(description: "oversized request cancelled")
    ShelfArtworkURLProtocol.configure(
      start: { request in
        request.sendResponse()
        request.send(Data(repeating: 0x41, count: 5))
        request.send(Data(repeating: 0x42, count: 5))
        request.finish()
      },
      stop: { stopped.fulfill() }
    )
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ShelfArtworkURLProtocol.self]
    let loader = BoundedArtworkLoader(maximumBytes: 8, configuration: configuration)

    let result = loader.load(url: URL(string: "https://shelf.test/art.png")!, timeout: 1)

    XCTAssertNil(result)
    XCTAssertTrue(loader.exceededLimit)
    XCTAssertLessThanOrEqual(loader.peakBufferedBytes, 8)
    wait(for: [stopped], timeout: 1)
  }

  func testArtworkLoaderReturnsBoundedChunkedBodyAndMimeType() {
    let expected = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
    ShelfArtworkURLProtocol.configure { request in
      request.sendResponse()
      request.send(expected.prefix(3))
      request.send(expected.suffix(4))
      request.finish()
    }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ShelfArtworkURLProtocol.self]
    let loader = BoundedArtworkLoader(maximumBytes: 8, configuration: configuration)

    let result = loader.load(url: URL(string: "https://shelf.test/art.png")!, timeout: 1)

    XCTAssertEqual(result?.data, expected)
    XCTAssertEqual(result?.mimeType, "image/png")
    XCTAssertEqual(loader.peakBufferedBytes, expected.count)
    XCTAssertFalse(loader.exceededLimit)
  }

  private func replaceCommittedArtworkKey(
    in defaults: UserDefaults,
    with key: String
  ) throws {
    let data = try XCTUnwrap(
      defaults.data(forKey: SystemShelfPlugin.cacheDataKey)
    )
    var payload = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    var sections = try XCTUnwrap(payload["sections"] as? [[String: Any]])
    var items = try XCTUnwrap(sections.first?["items"] as? [[String: Any]])
    items[0]["artworkKey"] = key
    sections[0]["items"] = items
    payload["sections"] = sections
    defaults.set(
      try JSONSerialization.data(withJSONObject: payload),
      forKey: SystemShelfPlugin.cacheDataKey
    )
  }
}
