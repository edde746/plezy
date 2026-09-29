import Libmpv
import FlutterMacOS
import XCTest

@testable import Plezy

final class ControllablePropertyCore: MpvPlayerCoreBase {
  var nextResult: Result<Void, Error>?
  private(set) var propertyCalls: [(String, String)] = []
  private var pendingCompletion: ((Result<Void, Error>) -> Void)?

  override func setPropertyAsync(
    _ name: String,
    value: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    propertyCalls.append((name, value))
    if let nextResult {
      self.nextResult = nil
      completion(nextResult)
    } else {
      pendingCompletion = completion
    }
  }

  func finish(_ result: Result<Void, Error>) {
    let completion = pendingCompletion
    pendingCompletion = nil
    completion?(result)
  }
}

final class RecordingMpvPlugin: MpvPluginShared {
  var coreBase: MpvPlayerCoreBase?
  var eventSink: FlutterEventSink?
  var nameToId: [String: Int] = [:]
  private(set) var pauseHookValues: [String] = []

  init(core: MpvPlayerCoreBase?) {
    coreBase = core
  }

  func setPlayerVisible(_ visible: Bool, restoreOnWindowVisible: Bool) {}
  func updatePlayerFrame() {}

  func didSetPauseProperty(value: String) {
    pauseHookValues.append(value)
  }
}

final class RecordingLifecycleDelegate: MpvPlayerDelegate {
  private(set) var events: [String] = []
  private(set) var properties: [String] = []

  func onPropertyChange(name: String, value: Any?, sourceId: Int64?) { properties.append(name) }
  func onEvent(name: String, data: [String: Any]?) { events.append(name) }
}

final class EventOrderRecorder: MpvPlayerDelegate {
  private(set) var events: [(name: String, data: [String: Any]?)] = []
  var onEndFile: (() -> Void)?

  func onPropertyChange(name: String, value: Any?, sourceId: Int64?) {}
  func onEvent(name: String, data: [String: Any]?) {
    events.append((name, data))
    if name == "end-file" { onEndFile?() }
  }
}

final class MpvPlayerContractTests: XCTestCase {
  private let failure = NSError(
    domain: "MpvPlayerContractTests",
    code: 1,
    userInfo: [NSLocalizedDescriptionKey: "controlled failure"]
  )

  func testSharedTransportEmitsSourceQualifiedPayloads() {
    let plugin = RecordingMpvPlugin(core: nil)
    plugin.nameToId["time-pos"] = 27
    var messages: [Any?] = []
    plugin.eventSink = { messages.append($0) }
    let sourceId = Int64.max - 7

    plugin.onPropertyChange(name: "time-pos", value: 12.5, sourceId: sourceId)
    plugin.onPropertyChange(name: "time-pos", value: nil, sourceId: nil)
    plugin.onEvent(
      name: "playback-restart",
      data: ["sourceId": sourceId, "positionSeconds": 12.5]
    )

    XCTAssertEqual(messages.count, 3)
    guard
      let sourcedProperty = messages[0] as? [Any?],
      let preStartProperty = messages[1] as? [Any?],
      let lifecycleEvent = messages[2] as? [String: Any],
      let lifecycleData = lifecycleEvent["data"] as? [String: Any]
    else {
      return XCTFail("Expected property triples and a lifecycle event map")
    }
    XCTAssertEqual(sourcedProperty.count, 3)
    XCTAssertEqual(sourcedProperty[0] as? Int, 27)
    XCTAssertEqual(sourcedProperty[1] as? Double, 12.5)
    XCTAssertEqual(sourcedProperty[2] as? Int64, sourceId)
    XCTAssertEqual(preStartProperty.count, 3)
    XCTAssertNil(preStartProperty[1])
    XCTAssertNil(preStartProperty[2])
    XCTAssertEqual(lifecycleEvent["name"] as? String, "playback-restart")
    XCTAssertEqual(lifecycleData["sourceId"] as? Int64, sourceId)
    XCTAssertEqual(lifecycleData["positionSeconds"] as? Double, 12.5)
  }

  func testSharedSetPropertyMapsSuccessFailureMissingCoreAndInvalidArguments() {
    let core = ControllablePropertyCore()
    let plugin = RecordingMpvPlugin(core: core)

    core.nextResult = .success(())
    let success = invokeSetProperty(plugin, name: "pause", value: "no")
    XCTAssertEqual(success.count, 1)
    XCTAssertNil(success[0])
    XCTAssertEqual(plugin.pauseHookValues, ["no"])

    core.nextResult = .failure(failure)
    let rejected = invokeSetProperty(plugin, name: "pause", value: "yes")
    XCTAssertEqual(rejected.count, 1)
    XCTAssertEqual((rejected[0] as? FlutterError)?.code, "SET_PROPERTY_FAILED")
    XCTAssertEqual(plugin.pauseHookValues, ["no"])

    plugin.coreBase = nil
    let missing = invokeSetProperty(plugin, name: "volume", value: "50")
    XCTAssertEqual(missing.count, 1)
    XCTAssertEqual((missing[0] as? FlutterError)?.code, "NOT_INITIALIZED")

    var invalidResults: [Any?] = []
    plugin.handleSetProperty(
      call: FlutterMethodCall(methodName: "setProperty", arguments: ["name": "pause"])
    ) {
      invalidResults.append($0)
    }
    XCTAssertEqual(invalidResults.count, 1)
    XCTAssertEqual((invalidResults[0] as? FlutterError)?.code, "INVALID_ARGS")
  }

  func testSharedSetPropertyMapsLifecycleCancellationAsNotInitialized() {
    let core = ControllablePropertyCore()
    let plugin = RecordingMpvPlugin(core: core)
    core.nextResult = .failure(MpvLifecycleUnavailableError("controlled cancellation"))

    let cancelled = invokeSetProperty(plugin, name: "volume", value: "50")

    XCTAssertEqual(cancelled.count, 1)
    XCTAssertEqual((cancelled[0] as? FlutterError)?.code, "NOT_INITIALIZED")
  }

  func testRealSetPropertyValidInvalidNonexistentAndPauseCache() {
    let core = MpvAudioPlayerCore()
    XCTAssertTrue(core.initialize())
    defer {
      core.dispose()
      core.queue.sync {}
    }

    XCTAssertSuccess(awaitProperty(core, name: "volume", value: "50"))
    XCTAssertTrue(core.isPaused)

    XCTAssertFailure(awaitProperty(core, name: "pause", value: "not-a-flag"))
    XCTAssertTrue(core.isPaused, "A rejected raw pause write must not change the cache")

    XCTAssertFailure(
      awaitProperty(core, name: "plezy-property-does-not-exist", value: "ignored")
    )
    XCTAssertTrue(core.isPaused)

    XCTAssertSuccess(awaitProperty(core, name: "pause", value: "no"))
    XCTAssertFalse(core.isPaused, "The accepted pause write must commit before completion")
  }

  func testMacOSVideoCoreUsesCoreAudioWithAVFoundationFallback() {
    guard let mpv = mpv_create() else {
      return XCTFail("mpv_create failed")
    }
    var initialized = false
    defer {
      if initialized {
        mpv_terminate_destroy(mpv)
      } else {
        mpv_destroy(mpv)
      }
    }

    MpvPlayerCore().configurePlatformMpvOptions(mpv: mpv)
    let initializeResult = mpv_initialize(mpv)
    XCTAssertGreaterThanOrEqual(initializeResult, 0)
    guard initializeResult >= 0 else { return }
    initialized = true

    let optionValue = "options/ao".withCString {
      mpv_get_property_string(mpv, $0)
    }
    defer { mpv_free(optionValue) }
    XCTAssertEqual(optionValue.map { String(cString: $0) }, "coreaudio,avfoundation")
  }

  func testPauseIntentUpdatesCacheBeforeAsyncWriteCompletes() {
    let core = MpvAudioPlayerCore()
    XCTAssertTrue(core.initialize())
    defer {
      core.dispose()
      core.queue.sync {}
    }

    let queueEntered = expectation(description: "mpv queue blocked")
    let releaseQueue = DispatchSemaphore(value: 0)
    core.queue.async {
      queueEntered.fulfill()
      releaseQueue.wait()
    }
    wait(for: [queueEntered], timeout: 2)

    let completion = expectation(description: "pause write completed")
    core.setPropertyAsync("pause", value: "no") { result in
      if case .failure(let error) = result {
        XCTFail("Pause write failed: \(error)")
      }
      completion.fulfill()
    }

    XCTAssertFalse(core.isPaused, "The public pause intent must be visible before the native write completes")
    releaseQueue.signal()
    wait(for: [completion], timeout: 2)
  }

  func testPendingSetPropertyIsCancelledExactlyOnceOnDispose() {
    let core = MpvAudioPlayerCore()
    XCTAssertTrue(core.initialize())

    let queueEntered = expectation(description: "mpv queue blocked")
    let releaseQueue = DispatchSemaphore(value: 0)
    core.queue.async {
      queueEntered.fulfill()
      releaseQueue.wait()
    }
    wait(for: [queueEntered], timeout: 2)

    let completion = expectation(description: "cancelled property completion")
    completion.assertForOverFulfill = true
    var completionCount = 0
    var completionError: Error?
    core.setPropertyAsync("volume", value: "51") { result in
      completionCount += 1
      switch result {
      case .success:
        XCTFail("Disposal must fail an accepted-but-pending property request")
      case .failure(let error):
        completionError = error
      }
      completion.fulfill()
    }

    core.dispose()
    releaseQueue.signal()
    wait(for: [completion], timeout: 2)
    core.queue.sync {}
    XCTAssertEqual(completionCount, 1)
    XCTAssertTrue(completionError is MpvLifecycleUnavailableError)
    let unavailableResult = awaitProperty(core, name: "volume", value: "52")
    XCTAssertFailure(unavailableResult)
    if case .failure(let error) = unavailableResult {
      XCTAssertTrue(error is MpvLifecycleUnavailableError)
    }
  }

  func testRapidAudioCoreReplacementOwnsLifecycleOnce() {
    for _ in 0..<5 {
      autoreleasepool {
        let core = MpvAudioPlayerCore()
        XCTAssertTrue(core.initialize())
        core.dispose()
        core.dispose()
        core.queue.sync {}
        XCTAssertFalse(core.hasActiveMpv)
      }
    }
  }

  func testQueuedDelegateDeliveryIsDroppedAfterTerminalTransition() {
    let core = MpvPlayerCoreBase()
    let delegate = RecordingLifecycleDelegate()
    core.delegate = delegate
    let enqueueAndDispose = {
      core.dispatchDelegateEvent(name: "file-loaded", data: nil)
      core.dispatchDelegateProperty(name: "time-pos", value: 1.0, sourceId: 7)
      XCTAssertTrue(core.beginDisposal())
    }
    if Thread.isMainThread {
      enqueueAndDispose()
    } else {
      DispatchQueue.main.sync(execute: enqueueAndDispose)
    }

    let drained = expectation(description: "main delivery drained")
    DispatchQueue.main.async { drained.fulfill() }
    wait(for: [drained], timeout: 2)
    XCTAssertTrue(delegate.events.isEmpty)
    XCTAssertTrue(delegate.properties.isEmpty)
  }

  func testUnavailablePropertyCompletionRunsExactlyOnceOnMainThread() {
    let core = MpvAudioPlayerCore()
    XCTAssertTrue(core.initialize())
    core.dispose()
    core.queue.sync {}

    let completed = expectation(description: "unavailable property completed")
    completed.assertForOverFulfill = true
    var completionCount = 0
    DispatchQueue.global().async {
      core.getPropertyAsync("volume") { result in
        XCTAssertTrue(Thread.isMainThread)
        if case .success = result { XCTFail("Expected unavailable property failure") }
        completionCount += 1
        completed.fulfill()
      }
    }
    wait(for: [completed], timeout: 2)
    XCTAssertEqual(completionCount, 1)
  }

  func testFailedOpenDeliversItsErrorLinesBeforeEndFileWhenTheEventQueueLags() {
    let core = MpvAudioPlayerCore()
    let recorder = EventOrderRecorder()
    core.delegate = recorder
    XCTAssertTrue(core.initialize())
    defer {
      core.dispose()
      core.queue.sync {}
    }

    let missingFile = FileManager.default.temporaryDirectory
      .appendingPathComponent("plezy-missing-\(UUID().uuidString).mkv").path
    let events = eventsOfOpenFailingBehindHeldQueue(core, recorder: recorder, url: missingFile)

    guard let endFile = events.firstIndex(where: { $0.name == "end-file" }) else {
      return XCTFail("No end-file delivered")
    }
    XCTAssertEqual(events[endFile].data?["reason"] as? Int, Int(MPV_END_FILE_REASON_ERROR.rawValue))
    XCTAssertTrue(
      events[..<endFile].contains { isLogLine($0, level: "error", containing: "Failed to open") },
      "The line explaining the failure must reach the delegate before the end-file"
    )
  }

  func testErrorEndFileDefersBehindAtMostAFullVerboseLogBufferAndItsOverflowNotice() {
    let core = MpvAudioPlayerCore()
    let recorder = EventOrderRecorder()
    core.delegate = recorder
    XCTAssertTrue(core.initialize())
    defer {
      core.dispose()
      core.queue.sync {}
    }
    // At `v` mpv keeps up to 10000 lines for a client before dropping the oldest.
    core.setLogLevel("v")
    guard let observer = core.createClientForTesting() else {
      return XCTFail("No second mpv client")
    }
    defer { mpv_destroy(observer) }

    let queueHeld = expectation(description: "mpv queue held")
    let releaseQueue = DispatchSemaphore(value: 0)
    core.queue.async {
      queueHeld.fulfill()
      releaseQueue.wait()
    }
    wait(for: [queueHeld], timeout: 2)

    // Overflow the core's log buffer ahead of the failure. The second client's
    // synchronous commands put nothing in the core's event queue.
    let rejected = (0..<10_100).filter { mpv_command_string(observer, "print-text plezy-fill-\($0)") < 0 }
    XCTAssertTrue(rejected.isEmpty)
    let endFileDelivered = expectation(description: "end-file delivered")
    endFileDelivered.assertForOverFulfill = false
    recorder.onEndFile = { endFileDelivered.fulfill() }
    let missingFile = FileManager.default.temporaryDirectory
      .appendingPathComponent("plezy-missing-\(UUID().uuidString).mkv").path
    core.command(["loadfile", missingFile])
    var endFilePosted = false
    while !endFilePosted, let event = mpv_wait_event(observer, 5), event.pointee.event_id != MPV_EVENT_NONE {
      endFilePosted = event.pointee.event_id == MPV_EVENT_END_FILE
    }
    XCTAssertTrue(endFilePosted, "mpv never ended the file")
    // Until the core goes quiet it broadcasts to both clients alike, and the
    // core's client observes no property: these are the events other than
    // log lines that it dequeues after its END_FILE.
    var eventsAfterEndFile = 0
    while mpv_wait_event(observer, 0.25).pointee.event_id != MPV_EVENT_NONE {
      eventsAfterEndFile += 1
    }
    releaseQueue.signal()
    wait(for: [endFileDelivered], timeout: 5)
    core.queue.sync {}
    let landed = expectation(description: "the drain's deliveries landed")
    DispatchQueue.main.async { landed.fulfill() }
    wait(for: [landed], timeout: 5)

    let events = recorder.events
    guard let startFile = events.lastIndex(where: { $0.name == "start-file" }),
      let endFile = events.firstIndex(where: { $0.name == "end-file" })
    else {
      return XCTFail("No start-file or end-file delivered")
    }
    let linesBeforeEndFile = events[startFile..<endFile].filter { $0.name == "log-message" }.count
    let linesAfterEndFile = events[endFile...].filter { $0.name == "log-message" }.count
    XCTAssertGreaterThan(
      linesAfterEndFile, 0, "The end-file must not wait for more than a full buffer and its overflow notice")
    XCTAssertEqual(
      linesBeforeEndFile + eventsAfterEndFile, 10_001,
      "The end-file waits through exactly a full verbose buffer plus the overflow notice after it"
    )
    XCTAssertTrue(
      events[startFile..<endFile].contains { isLogLine($0, level: "error", containing: "Failed to open") },
      "The failure, among the newest lines, must still reach the delegate before the end-file"
    )
  }

  func testFailedStreamOpenIsExplainedByMpvWithoutRunningTheYtdlHook() {
    let core = MpvAudioPlayerCore()
    let recorder = EventOrderRecorder()
    core.delegate = recorder
    XCTAssertTrue(core.initialize())
    defer {
      core.dispose()
      core.queue.sync {}
    }

    // Nothing listens on port 1, so the open fails at connect.
    let events = eventsOfOpenFailingBehindHeldQueue(
      core,
      recorder: recorder,
      url: "http://127.0.0.1:1/plezy-missing.mkv"
    )

    guard let endFile = events.firstIndex(where: { $0.name == "end-file" }) else {
      return XCTFail("No end-file delivered")
    }
    XCTAssertFalse(
      events.contains { $0.data?["prefix"] as? String == "ytdl_hook" },
      "A failed open must not hand the stream URL to yt-dlp"
    )
    let lastErrorLine = events[..<endFile].last { $0.name == "log-message" && $0.data?["level"] as? String == "error" }
    XCTAssertEqual(lastErrorLine?.data?["prefix"] as? String, "stream")
  }

  func testNormalizedPlaybackDelayStringsPassThroughUnchanged() {
    let core = ControllablePropertyCore()
    let plugin = RecordingMpvPlugin(core: core)
    let values = ["0.25", "-0.5", "0", "0.25"]

    for value in values {
      core.nextResult = .success(())
      let result = invokeSetProperty(plugin, name: "audio-delay", value: value)
      XCTAssertEqual(result.count, 1)
      XCTAssertNil(result[0])
    }
    XCTAssertEqual(core.propertyCalls.map(\.1), values)
  }

  func testNodeConversionBoundsAndDiscardsMalformedSiblings() {
    let core = MpvPlayerCoreBase()
    var valid = mpv_node()
    valid.format = MPV_FORMAT_INT64
    valid.u.int64 = 7
    var malformed = mpv_node()
    malformed.format = MPV_FORMAT_NONE
    var values = [valid, malformed, valid]
    var decoded: Any?

    let valueCount = values.count
    values.withUnsafeMutableBufferPointer { valuesPointer in
      var list = mpv_node_list()
      list.num = Int32(valueCount)
      list.values = valuesPointer.baseAddress
      withUnsafeMutablePointer(to: &list) { listPointer in
        var root = mpv_node()
        root.format = MPV_FORMAT_NODE_ARRAY
        root.u.list = listPointer
        decoded = core.convertNode(root)
      }
    }
    XCTAssertEqual(decoded as? [Int64], [7, 7])

    var oversizedBytes = mpv_byte_array()
    oversizedBytes.size = 16 * 1_024 * 1_024 + 1
    withUnsafeMutablePointer(to: &oversizedBytes) { bytePointer in
      var root = mpv_node()
      root.format = MPV_FORMAT_BYTE_ARRAY
      root.u.ba = bytePointer
      XCTAssertNil(core.convertNode(root))
    }
    XCTAssertTrue(core.validateSideDataDimensions(width: 3_840, height: 2_160))
    XCTAssertFalse(core.validateSideDataDimensions(width: 0, height: 2_160))
    XCTAssertFalse(core.validateSideDataDimensions(width: 65_536, height: 2_160))
    XCTAssertFalse(core.validateSideDataDimensions(width: 16_384, height: 16_384))
  }

  private func invokeSetProperty(
    _ plugin: RecordingMpvPlugin,
    name: String,
    value: String
  ) -> [Any?] {
    var results: [Any?] = []
    plugin.handleSetProperty(
      call: FlutterMethodCall(
        methodName: "setProperty",
        arguments: ["name": name, "value": value]
      )
    ) {
      results.append($0)
    }
    return results
  }

  /// Opens `url` while `core`'s event queue is held and releases the queue
  /// only once mpv has posted END_FILE, so the end-file and the lines logged
  /// before it are all pending when the drain runs: the lag under which mpv
  /// hands END_FILE out first. Returns the events delivered through the
  /// end-file.
  private func eventsOfOpenFailingBehindHeldQueue(
    _ core: MpvPlayerCoreBase,
    recorder: EventOrderRecorder,
    url: String
  ) -> [(name: String, data: [String: Any]?)] {
    guard let observer = core.createClientForTesting() else {
      XCTFail("No second mpv client")
      return []
    }
    defer { mpv_destroy(observer) }

    let queueHeld = expectation(description: "mpv queue held")
    let releaseQueue = DispatchSemaphore(value: 0)
    core.queue.async {
      queueHeld.fulfill()
      releaseQueue.wait()
    }
    wait(for: [queueHeld], timeout: 2)

    let endFileDelivered = expectation(description: "end-file delivered")
    endFileDelivered.assertForOverFulfill = false
    recorder.onEndFile = { endFileDelivered.fulfill() }
    core.command(["loadfile", url])
    var endFilePosted = false
    while !endFilePosted, let event = mpv_wait_event(observer, 5), event.pointee.event_id != MPV_EVENT_NONE {
      endFilePosted = event.pointee.event_id == MPV_EVENT_END_FILE
    }
    releaseQueue.signal()
    XCTAssertTrue(endFilePosted, "mpv never ended the file")
    wait(for: [endFileDelivered], timeout: 5)
    return recorder.events
  }

  private func isLogLine(
    _ event: (name: String, data: [String: Any]?),
    level: String,
    containing text: String
  ) -> Bool {
    event.name == "log-message" && event.data?["level"] as? String == level
      && (event.data?["text"] as? String)?.contains(text) == true
  }

  private func awaitProperty(
    _ core: MpvPlayerCoreBase,
    name: String,
    value: String
  ) -> Result<Void, Error> {
    let completion = expectation(description: "set \(name)")
    var propertyResult: Result<Void, Error>?
    core.setPropertyAsync(name, value: value) {
      propertyResult = $0
      completion.fulfill()
    }
    wait(for: [completion], timeout: 2)
    return propertyResult ?? .failure(failure)
  }

  private func XCTAssertSuccess(
    _ result: Result<Void, Error>,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    if case .failure(let error) = result {
      XCTFail("Expected success, received \(error)", file: file, line: line)
    }
  }

  private func XCTAssertFailure(
    _ result: Result<Void, Error>,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    if case .success = result {
      XCTFail("Expected failure", file: file, line: line)
    }
  }
}
