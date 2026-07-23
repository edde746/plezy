import AVFoundation
import Libmpv
import UIKit
import Flutter
import XCTest

@testable import Runner

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

  func onPropertyChange(name: String, value: Any?) {
    properties.append(name)
  }

  func onEvent(name: String, data: [String: Any]?) {
    events.append(name)
  }
}

final class FakePictureInPictureController: MpvPictureInPictureControlling {
  var isPictureInPicturePossible = false
  private(set) var startCount = 0
  private(set) var stopCount = 0
  private(set) var automaticStartValues: [Bool] = []
  private(set) var invalidateCount = 0

  func startPictureInPicture() { startCount += 1 }
  func stopPictureInPicture() { stopCount += 1 }
  func setAutomaticStart(_ enabled: Bool) { automaticStartValues.append(enabled) }
  func invalidatePlaybackState() { invalidateCount += 1 }
}

final class RecordingPipDelegate: MpvPipDelegate {
  private(set) var events: [String] = []
  var onDidStart: (() -> Void)?
  func pipWillStart() { events.append("willStart") }
  func pipDidStart() {
    onDidStart?()
    events.append("didStart")
  }
  func pipDidStop(restored: Bool) { events.append("didStop:\(restored)") }
  func pipDidFailToStart(error: Error?) { events.append("failed") }
  func pipSetPlaying(_ playing: Bool) {}
  func pipSkip(byInterval seconds: Double, completion: @escaping () -> Void) { completion() }
  var isPipPlaying: Bool { true }
  var pipDuration: Double { 60 }
}

final class ReleaseTrackingCore: MpvPlayerCoreBase {
  let onDeinit: () -> Void
  init(onDeinit: @escaping () -> Void) {
    self.onDeinit = onDeinit
    super.init()
  }
  deinit { onDeinit() }
}

final class ProbeURLProtocol: URLProtocol {
  private static let lock = NSLock()
  private static var startHandler: ((ProbeURLProtocol) -> Void)?
  private static var stopHandler: (() -> Void)?

  static func configure(
    start: @escaping (ProbeURLProtocol) -> Void,
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
    handler?(self)
  }

  override func stopLoading() {
    Self.lock.lock()
    let handler = Self.stopHandler
    Self.lock.unlock()
    handler?()
  }
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

  func testOlderPauseReplyCannotOverwriteNewerUserIntent() {
    let core = ControllablePropertyCore()
    let olderResume = core.beginCachedPauseIntent(false)
    let newerPause = core.beginCachedPauseIntent(true)
    XCTAssertTrue(core.isPaused)

    core.finishCachedPauseIntent(olderResume, result: .success(()))
    XCTAssertTrue(
      core.isPaused,
      "An older resume reply must not overwrite a newer pending pause intent"
    )

    core.finishCachedPauseIntent(newerPause, result: .success(()))
    XCTAssertTrue(core.isPaused)
  }

  func testPauseObservationAndUserIntentResolveInEventOrder() {
    let core = ControllablePropertyCore()
    let olderResume = core.beginCachedPauseIntent(false)

    core.observeCachedPauseForTesting(true)
    core.finishCachedPauseIntent(olderResume, result: .success(()))
    XCTAssertTrue(
      core.isPaused,
      "A native pause observation must invalidate the older resume write's delayed reply"
    )

    let newerResume = core.beginCachedPauseIntent(false)
    core.finishCachedPauseIntent(newerResume, result: .success(()))
    XCTAssertFalse(
      core.isPaused,
      "A user intent created after the native observation must remain authoritative"
    )
  }

  func testPauseObservationRetiresOutOfOrderIntentsForSuccessAndFailure() {
    let newerResults: [Result<Void, Error>] = [
      .success(()),
      .failure(failure),
    ]

    for newerResult in newerResults {
      let core = ControllablePropertyCore()
      let generationOneResume = core.beginCachedPauseIntent(false)
      let generationTwoPause = core.beginCachedPauseIntent(true)

      core.observeCachedPauseForTesting(true)
      core.finishCachedPauseIntent(generationTwoPause, result: newerResult)
      XCTAssertTrue(
        core.isPaused,
        "The observed native pause must survive the newer pending pause's completion"
      )

      core.finishCachedPauseIntent(generationOneResume, result: .success(()))
      XCTAssertTrue(
        core.isPaused,
        "A late older resume must be inert after a newer intent resolves"
      )

      let postObservationResume = core.beginCachedPauseIntent(false)
      core.finishCachedPauseIntent(postObservationResume, result: .success(()))
      XCTAssertFalse(
        core.isPaused,
        "A resume created after the native observation must remain authoritative"
      )
    }
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
    core.setPropertyAsync("volume", value: "51") { result in
      completionCount += 1
      if case .success = result {
        XCTFail("Disposal must fail an accepted-but-pending property request")
      }
      completion.fulfill()
    }

    core.dispose()
    releaseQueue.signal()
    wait(for: [completion], timeout: 2)
    core.queue.sync {}
    XCTAssertEqual(completionCount, 1)
    XCTAssertFailure(awaitProperty(core, name: "volume", value: "52"))
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
    core.dispatchDelegateEvent(name: "file-loaded", data: nil)
    core.dispatchDelegateProperty(name: "time-pos", value: 1.0)
    XCTAssertTrue(core.beginDisposal())

    let drained = expectation(description: "main delivery drained")
    DispatchQueue.main.async { drained.fulfill() }
    wait(for: [drained], timeout: 2)
    XCTAssertTrue(delegate.events.isEmpty)
    XCTAssertTrue(delegate.properties.isEmpty)
  }

  func testWakeupContextDoesNotRetainCallbackTarget() {
    let released = expectation(description: "callback target released")
    var core: ReleaseTrackingCore? = ReleaseTrackingCore { released.fulfill() }
    weak var weakCore = core
    let context = MpvWakeupCallbackContext(core: core!)

    core = nil
    wait(for: [released], timeout: 2)
    XCTAssertNil(weakCore)
    context.dispatchWakeup()
    context.detach()
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

    var invalidList = mpv_node_list()
    invalidList.num = -1
    withUnsafeMutablePointer(to: &invalidList) { listPointer in
      var root = mpv_node()
      root.format = MPV_FORMAT_NODE_ARRAY
      root.u.list = listPointer
      XCTAssertNil(core.convertNode(root))
    }
    XCTAssertTrue(core.validateSideDataDimensions(width: 3_840, height: 2_160))
    XCTAssertFalse(core.validateSideDataDimensions(width: 0, height: 2_160))
    XCTAssertFalse(core.validateSideDataDimensions(width: 65_536, height: 2_160))
    XCTAssertFalse(core.validateSideDataDimensions(width: 16_384, height: 16_384))
  }

  func testRawEc3LoaderBoundsAndIgnoresLateCallbacksForBothModes() {
    for finiteLength in [false, true] {
      let loader = RawEc3Loader(
        source: URL(string: "https://example.invalid/test.ec3")!,
        finiteLength: finiteLength,
        maximumBufferedBytes: 8,
        sessionConfiguration: .ephemeral
      )
      let session = URLSession(configuration: .ephemeral)
      let task = session.dataTask(with: URL(string: "https://example.invalid/test.ec3")!)

      loader.urlSession(session, dataTask: task, didReceive: Data([1, 2, 3, 4]))
      var snapshot = loader.statusSnapshot()
      XCTAssertEqual(snapshot.bytesReceived, 4)
      XCTAssertEqual(snapshot.retainedBytes, 4)
      XCTAssertNil(snapshot.errorCode)

      loader.urlSession(session, dataTask: task, didReceive: Data([5, 6, 7, 8, 9]))
      snapshot = loader.statusSnapshot()
      XCTAssertEqual(snapshot.bytesReceived, 4)
      XCTAssertEqual(snapshot.retainedBytes, 0)
      XCTAssertEqual(snapshot.errorCode, "response_too_large")

      loader.urlSession(session, dataTask: task, didReceive: Data([10]))
      let lateSnapshot = loader.statusSnapshot()
      XCTAssertEqual(lateSnapshot.bytesReceived, snapshot.bytesReceived)
      XCTAssertEqual(lateSnapshot.retainedBytes, 0)
      loader.cancel()
      loader.cancel()
      XCTAssertEqual(loader.statusSnapshot().pendingRequestCount, 0)
      let cancelledLoader = RawEc3Loader(
        source: URL(string: "https://example.invalid/cancel.ec3")!,
        finiteLength: finiteLength,
        maximumBufferedBytes: 8,
        sessionConfiguration: .ephemeral
      )
      cancelledLoader.urlSession(session, dataTask: task, didReceive: Data([1, 2, 3, 4]))
      XCTAssertEqual(cancelledLoader.statusSnapshot().retainedBytes, 4)
      cancelledLoader.cancel()
      cancelledLoader.cancel()
      let cancelledSnapshot = cancelledLoader.statusSnapshot()
      XCTAssertEqual(cancelledSnapshot.retainedBytes, 0)
      XCTAssertEqual(cancelledSnapshot.pendingRequestCount, 0)
      session.invalidateAndCancel()
    }
  }

  func testRawEc3LoaderCompletesThroughInjectedURLProtocolForBothModes() {
    defer { ProbeURLProtocol.reset() }
    for finiteLength in [false, true] {
      let requestStarted = expectation(description: "probe request started")
      let loaderFinished = expectation(description: "probe loader finished")
      ProbeURLProtocol.configure { protocolInstance in
        let response = URLResponse(
          url: protocolInstance.request.url!,
          mimeType: "audio/eac3",
          expectedContentLength: -1,
          textEncodingName: nil
        )
        protocolInstance.client?.urlProtocol(
          protocolInstance,
          didReceive: response,
          cacheStoragePolicy: .notAllowed
        )
        protocolInstance.client?.urlProtocol(protocolInstance, didLoad: Data([1, 2, 3, 4]))
        protocolInstance.client?.urlProtocolDidFinishLoading(protocolInstance)
        requestStarted.fulfill()
      }

      let configuration = URLSessionConfiguration.ephemeral
      configuration.protocolClasses = [ProbeURLProtocol.self]
      let loader = RawEc3Loader(
        source: URL(string: "https://probe.test/audio.ec3")!,
        finiteLength: finiteLength,
        maximumBufferedBytes: 8,
        sessionConfiguration: configuration,
        terminalHandlerForTesting: { loaderFinished.fulfill() }
      )
      loader.begin()
      wait(for: [requestStarted, loaderFinished], timeout: 2)

      let snapshot = loader.statusSnapshot()
      XCTAssertTrue(snapshot.isFinished)
      XCTAssertEqual(snapshot.bytesReceived, 4)
      XCTAssertEqual(snapshot.retainedBytes, 4)
      XCTAssertNil(snapshot.errorCode)

      loader.cancel()
      let cancelled = loader.statusSnapshot()
      XCTAssertEqual(cancelled.retainedBytes, 0)
      XCTAssertEqual(cancelled.pendingRequestCount, 0)
    }
  }

  func testPipStartWaitsForDelegateAndCompletesOnce() {
    let fake = FakePictureInPictureController()
    fake.isPictureInPicturePossible = true
    let controller = MpvPipController(
      controller: fake,
      readiness: { (true, true, true) },
      retryScheduler: { $0() }
    )
    let delegate = RecordingPipDelegate()
    controller.delegate = delegate
    var results: [Bool] = []

    delegate.onDidStart = {
      XCTAssertEqual(results, [true], "Manual result must resolve before delegate suspension")
    }
    controller.startPip { results.append($0) }
    XCTAssertEqual(fake.startCount, 1)
    XCTAssertTrue(results.isEmpty)
    controller.pictureInPictureWillStart()
    controller.pictureInPictureDidStart()
    XCTAssertEqual(Array(delegate.events.prefix(2)), ["willStart", "didStart"])
    XCTAssertEqual(results, [true])

    controller.pictureInPictureDidStart()
    controller.teardown()
    XCTAssertEqual(results, [true])
  }

  func testRepeatedAutoStartDuringCurrentControllerStartDoesNotRejectDidStart() {
    let fake = FakePictureInPictureController()
    let controller = MpvPipController(
      controller: fake,
      readiness: { (true, true, true) },
      retryScheduler: { $0() }
    )
    let delegate = RecordingPipDelegate()
    controller.delegate = delegate

    controller.setAutoStart(true)
    controller.pictureInPictureWillStart(from: fake)
    controller.setAutoStart(true)
    controller.pictureInPictureDidStart(from: fake)

    XCTAssertEqual(fake.automaticStartValues, [true, true])
    XCTAssertEqual(delegate.events, ["willStart", "didStart"])
    XCTAssertEqual(
      fake.stopCount,
      0,
      "Reasserting an enabled auto-start setting must not reject the in-flight system start"
    )
  }

  func testPipStartTimesOutWithoutDelegateOutcome() {
    let fake = FakePictureInPictureController()
    var timeouts: [() -> Void] = []
    let controller = MpvPipController(
      controller: fake,
      readiness: { (true, true, true) },
      retryScheduler: { $0() },
      startTimeoutScheduler: { timeouts.append($0) }
    )
    var results: [Bool] = []

    controller.startPip { results.append($0) }
    XCTAssertEqual(fake.startCount, 1)
    XCTAssertTrue(results.isEmpty)
    XCTAssertEqual(timeouts.count, 1)

    timeouts[0]()
    XCTAssertEqual(results, [false])
    XCTAssertEqual(fake.stopCount, 1)

    controller.pictureInPictureDidStart()
    controller.pictureInPictureFailedToStart(error: NSError(domain: "late", code: 1))
    XCTAssertEqual(results, [false])
  }

  func testPipTimeoutRecreatesControllerAndRejectsRetiredCallbacks() {
    let displayLayer = AVSampleBufferDisplayLayer()
    let retired = FakePictureInPictureController()
    let replacement = FakePictureInPictureController()
    retired.isPictureInPicturePossible = true
    replacement.isPictureInPicturePossible = true
    var timeouts: [() -> Void] = []
    var replacementLayers: [AVSampleBufferDisplayLayer?] = []
    let controller = MpvPipController(
      controller: retired,
      sampleBufferDisplayLayer: displayLayer,
      readiness: { (true, true, true) },
      retryScheduler: { $0() },
      startTimeoutScheduler: { timeouts.append($0) },
      replacementControllerFactory: { layer in
        replacementLayers.append(layer)
        return replacement
      }
    )
    let delegate = RecordingPipDelegate()
    controller.delegate = delegate
    controller.setAutoStart(true)
    var results: [Bool] = []

    controller.startPip { results.append($0) }
    XCTAssertEqual(retired.startCount, 1)
    XCTAssertEqual(timeouts.count, 1)

    timeouts[0]()
    XCTAssertEqual(results, [false])
    XCTAssertEqual(retired.stopCount, 1)
    XCTAssertEqual(retired.automaticStartValues, [true, false])
    XCTAssertEqual(replacementLayers.count, 1)
    XCTAssertTrue(replacementLayers[0] === displayLayer)
    XCTAssertEqual(replacement.automaticStartValues, [true])

    controller.startPip { results.append($0) }
    XCTAssertEqual(replacement.startCount, 1)
    XCTAssertEqual(timeouts.count, 2)

    controller.pictureInPictureWillStart(from: retired)
    controller.pictureInPictureDidStart(from: retired)
    controller.pictureInPictureFailedToStart(
      from: retired,
      error: NSError(domain: "late-retired-controller", code: 1)
    )
    controller.pictureInPictureDidStop(from: retired)
    XCTAssertEqual(results, [false])
    XCTAssertTrue(delegate.events.isEmpty)
    XCTAssertEqual(retired.stopCount, 1)
    XCTAssertEqual(
      replacement.startCount,
      1,
      "A retired controller callback must not disturb the replacement's pending start"
    )

    controller.pictureInPictureWillStart(from: replacement)
    controller.pictureInPictureDidStart(from: replacement)
    XCTAssertEqual(results, [false, true])
    XCTAssertEqual(delegate.events, ["willStart", "didStart"])
    XCTAssertEqual(replacementLayers.count, 1)
  }

  func testPipTeardownCancelsRetryAndLateWork() {
    let fake = FakePictureInPictureController()
    var possible = false
    var retries: [() -> Void] = []
    let controller = MpvPipController(
      controller: fake,
      readiness: { (possible, true, true) },
      retryScheduler: { retries.append($0) }
    )
    var results: [Bool] = []

    controller.startPip { results.append($0) }
    XCTAssertEqual(retries.count, 1)
    controller.teardown()
    XCTAssertEqual(results, [false])
    possible = true
    retries.forEach { $0() }
    XCTAssertEqual(fake.startCount, 0)
    XCTAssertEqual(results, [false])
  }

  func testPipFailureAndLateRestoreRemainSingleShot() {
    let fake = FakePictureInPictureController()
    let controller = MpvPipController(
      controller: fake,
      readiness: { (true, true, true) },
      retryScheduler: { $0() }
    )
    let delegate = RecordingPipDelegate()
    controller.delegate = delegate
    var startResults: [Bool] = []

    controller.startPip { startResults.append($0) }
    controller.pictureInPictureWillStart()
    controller.pictureInPictureFailedToStart(error: NSError(domain: "test", code: 1))
    controller.pictureInPictureFailedToStart(error: NSError(domain: "test", code: 2))
    XCTAssertEqual(startResults, [false])
    XCTAssertEqual(delegate.events.filter { $0 == "failed" }.count, 1)

    controller.startPip { startResults.append($0) }
    controller.pictureInPictureWillStart()
    controller.pictureInPictureDidStart()
    XCTAssertEqual(startResults, [false, true])

    var restoreResults: [Bool] = []
    controller.restoreUserInterface { restoreResults.append($0) }
    controller.teardown()
    controller.restoreUserInterface { restoreResults.append($0) }
    XCTAssertEqual(restoreResults, [true, false])
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
