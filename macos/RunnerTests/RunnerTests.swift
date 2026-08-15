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

  func onPropertyChange(name: String, value: Any?) { properties.append(name) }
  func onEvent(name: String, data: [String: Any]?) { events.append(name) }
}

final class MpvPlayerContractTests: XCTestCase {
  private let failure = NSError(
    domain: "MpvPlayerContractTests",
    code: 1,
    userInfo: [NSLocalizedDescriptionKey: "controlled failure"]
  )

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

  func testMacOSVideoCoreUsesCoreAudioOutput() {
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
    XCTAssertEqual(optionValue.map { String(cString: $0) }, "coreaudio")
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
      core.dispatchDelegateProperty(name: "time-pos", value: 1.0)
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
