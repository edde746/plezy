import Foundation
import Flutter
import XCTest

@testable import Runner

private final class TvosControllablePropertyCore: MpvPlayerCoreBase {
  var nextResult: Result<Void, Error>?

  override func setPropertyAsync(
    _ name: String,
    value: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let nextResult else {
      XCTFail("A controlled property result was not configured")
      return
    }
    self.nextResult = nil
    completion(nextResult)
  }
}

private final class TvosRecordingMpvPlugin: MpvPluginShared {
  var coreBase: MpvPlayerCoreBase?
  var eventSink: FlutterEventSink?
  var nameToId: [String: Int] = [:]

  init(core: MpvPlayerCoreBase?) {
    coreBase = core
  }

  func setPlayerVisible(_ visible: Bool, restoreOnWindowVisible: Bool) {}
  func updatePlayerFrame() {}
  func didSetPauseProperty(value: String) {}
}

final class MpvPlayerContractTests: XCTestCase {
  func testSharedTransportEmitsSourceQualifiedPayloads() {
    let plugin = TvosRecordingMpvPlugin(core: nil)
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

  func testSharedSetPropertyMapsLifecycleCancellationAsNotInitialized() {
    let core = TvosControllablePropertyCore()
    let plugin = TvosRecordingMpvPlugin(core: core)
    core.nextResult = .failure(MpvLifecycleUnavailableError("controlled cancellation"))

    let results = invokeSetProperty(plugin)

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual((results[0] as? FlutterError)?.code, "NOT_INITIALIZED")
  }

  func testSharedSetPropertyKeepsGenuineRejectionNonRecoverable() {
    let core = TvosControllablePropertyCore()
    let plugin = TvosRecordingMpvPlugin(core: core)
    core.nextResult = .failure(
      NSError(
        domain: "MpvPlayerContractTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "controlled rejection"]
      ))

    let results = invokeSetProperty(plugin)

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual((results[0] as? FlutterError)?.code, "SET_PROPERTY_FAILED")
  }

  private func invokeSetProperty(_ plugin: TvosRecordingMpvPlugin) -> [Any?] {
    var results: [Any?] = []
    plugin.handleSetProperty(
      call: FlutterMethodCall(
        methodName: "setProperty",
        arguments: ["name": "volume", "value": "50"]
      )
    ) {
      results.append($0)
    }
    return results
  }
}
