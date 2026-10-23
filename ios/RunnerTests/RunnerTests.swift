import AVFoundation
import Libmpv
import UIKit
import Flutter
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
  func setPlayerVideoZoom(_ scale: Double) {}

  func didSetPauseProperty(value: String) {
    pauseHookValues.append(value)
  }
}

final class RecordingLifecycleDelegate: MpvPlayerDelegate {
  private(set) var events: [String] = []
  private(set) var properties: [String] = []

  func onPropertyChange(name: String, value: Any?, sourceId: Int64?) {
    properties.append(name)
  }

  func onEvent(name: String, data: [String: Any]?) {
    events.append(name)
  }
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

  func testMpvContextsPreferAVFoundationOverAudioUnit() {
    // ao_audiounit remixes 5.1/7.1 to stereo on AirPods (#2264); both the
    // video and the music core must probe AVFoundation first.
    let core = MpvAudioPlayerCore()
    XCTAssertTrue(core.initialize())
    defer {
      core.dispose()
      core.queue.sync {}
    }

    XCTAssertEqual(try awaitGetProperty(core, name: "options/ao").get(), "avfoundation,audiounit")
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

  // ao_avfoundation queues seconds of audio filtered at the old speed. A Watch
  // Together room pauses, changes its rate and plays; playback must run at the
  // new rate from the paused position, not drift off while that queue drains.
  func testSpeedWrittenWhilePausedTakesEffectOnPlay() throws {
    let (core, file) = try startSilentPlayback()
    defer { stopSilentPlayback(core, file: file) }

    XCTAssertSuccess(awaitProperty(core, name: "pause", value: "yes"))
    pump(0.5)
    let pausedAt = try timePos(core)
    XCTAssertSuccess(awaitProperty(core, name: "speed", value: "2"))
    pump(0.5)
    XCTAssertSuccess(awaitProperty(core, name: "pause", value: "no"))
    let playedAt = Date()
    pump(3)

    let expected = pausedAt + 2 * Date().timeIntervalSince(playedAt)
    XCTAssertEqual(try timePos(core), expected, accuracy: 0.5)
  }

  func testSpeedWrittenWhilePlayingTakesEffectAtOnce() throws {
    let (core, file) = try startSilentPlayback()
    defer { stopSilentPlayback(core, file: file) }

    let changedFrom = try timePos(core)
    let changedAt = Date()
    XCTAssertSuccess(awaitProperty(core, name: "speed", value: "2"))
    pump(3)

    let expected = changedFrom + 2 * Date().timeIntervalSince(changedAt)
    XCTAssertEqual(try timePos(core), expected, accuracy: 0.5)
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

  func testBackgroundedCoreStillDeliversAFailedOpensWarningsAndErrorsOnly() {
    let core = MpvAudioPlayerCore()
    let recorder = EventOrderRecorder()
    core.delegate = recorder
    core.setBackgrounded(true)
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
    XCTAssertTrue(
      events[..<endFile].contains { isLogLine($0, level: "error", containing: "Failed to open") },
      "A failure while backgrounded must keep its explanation"
    )
    let levels = Set(events.compactMap { $0.name == "log-message" ? $0.data?["level"] as? String : nil })
    XCTAssertTrue(
      levels.isSubset(of: ["fatal", "error", "warn"]),
      "Backgrounded, chattier lines stay native: \(levels)"
    )
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

  func testPipTimeoutKeepsTheLayersControllerForTheNextStart() {
    // A second AVKit controller on the same layer crashes once the timed-out
    // one is freed (AVSBDLPlayerControllerKey, #2884).
    let displayLayer = AVSampleBufferDisplayLayer()
    let fake = FakePictureInPictureController()
    var timeouts: [() -> Void] = []
    let controller = MpvPipController(
      controller: fake,
      sampleBufferDisplayLayer: displayLayer,
      readiness: { (true, true, true) },
      retryScheduler: { $0() },
      startTimeoutScheduler: { timeouts.append($0) }
    )
    let delegate = RecordingPipDelegate()
    controller.delegate = delegate
    controller.setAutoStart(true)
    var results: [Bool] = []

    controller.startPip { results.append($0) }
    timeouts[0]()
    XCTAssertEqual(results, [false])
    XCTAssertEqual(fake.stopCount, 1)
    XCTAssertEqual(fake.automaticStartValues, [true])

    controller.pictureInPictureDidStart(from: fake)
    XCTAssertEqual(fake.stopCount, 2, "A late start from the timed-out request must be stopped")
    XCTAssertTrue(delegate.events.isEmpty)

    controller.startPip { results.append($0) }
    XCTAssertEqual(fake.startCount, 2, "The next start must reuse the layer's controller")
    XCTAssertEqual(timeouts.count, 2)

    controller.pictureInPictureWillStart(from: fake)
    controller.pictureInPictureDidStart(from: fake)
    XCTAssertEqual(results, [false, true])
    XCTAssertEqual(delegate.events, ["willStart", "didStart"])

    timeouts[1]()
    XCTAssertEqual(results, [false, true])
    XCTAssertEqual(fake.stopCount, 2)
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

  /// An audio core playing 30 s of silence through ao_avfoundation for three
  /// seconds, long enough to fill the renderer's read-ahead.
  private func startSilentPlayback() throws -> (MpvAudioPlayerCore, URL) {
    let file = FileManager.default.temporaryDirectory
      .appendingPathComponent("plezy-silence-\(UUID().uuidString).wav")
    try silentWav(seconds: 30).write(to: file)
    let core = MpvAudioPlayerCore()
    XCTAssertTrue(core.initialize())
    core.command(["loadfile", file.path])
    XCTAssertSuccess(awaitProperty(core, name: "pause", value: "no"))
    pump(3)
    XCTAssertEqual(try awaitGetProperty(core, name: "current-ao").get(), "avfoundation")
    XCTAssertGreaterThan(try timePos(core), 2)
    return (core, file)
  }

  private func stopSilentPlayback(_ core: MpvAudioPlayerCore, file: URL) {
    core.dispose()
    core.queue.sync {}
    try? FileManager.default.removeItem(at: file)
  }

  /// 48 kHz stereo 16-bit PCM silence.
  private func silentWav(seconds: Int) -> Data {
    let sampleRate = 48_000
    let blockAlign = 4
    let dataSize = seconds * sampleRate * blockAlign
    var wav = Data()
    func append<T: FixedWidthInteger>(_ value: T) {
      withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) }
    }
    wav.append(contentsOf: Array("RIFF".utf8))
    append(UInt32(36 + dataSize))
    wav.append(contentsOf: Array("WAVEfmt ".utf8))
    append(UInt32(16))
    append(UInt16(1))
    append(UInt16(2))
    append(UInt32(sampleRate))
    append(UInt32(sampleRate * blockAlign))
    append(UInt16(blockAlign))
    append(UInt16(16))
    wav.append(contentsOf: Array("data".utf8))
    append(UInt32(dataSize))
    wav.append(Data(count: dataSize))
    return wav
  }

  private func pump(_ seconds: TimeInterval) {
    let elapsed = expectation(description: "\(seconds) s elapsed")
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { elapsed.fulfill() }
    wait(for: [elapsed], timeout: seconds + 2)
  }

  private func timePos(_ core: MpvPlayerCoreBase) throws -> Double {
    try XCTUnwrap(Double(try awaitGetProperty(core, name: "time-pos").get() ?? ""))
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

  private func awaitGetProperty(_ core: MpvPlayerCoreBase, name: String) -> Result<String?, Error> {
    let completion = expectation(description: "get \(name)")
    var propertyResult: Result<String?, Error>?
    core.getPropertyAsync(name) {
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
