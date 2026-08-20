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
