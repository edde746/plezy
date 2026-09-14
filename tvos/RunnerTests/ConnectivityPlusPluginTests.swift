import Flutter
import UIKit
import XCTest

@testable import Runner

private final class FakeConnectivityProvider: NSObject, ConnectivityProvider {
  var currentConnectivityTypes: [ConnectivityType] = [.none]
  var connectivityUpdateHandler: ConnectivityUpdateHandler?
  private(set) var startCount = 0
  private(set) var stopCount = 0

  func start() {
    startCount += 1
  }

  func stop() {
    stopCount += 1
  }

  func emit(_ connectivityTypes: [ConnectivityType]) {
    currentConnectivityTypes = connectivityTypes
    connectivityUpdateHandler?(connectivityTypes)
  }
}

final class ConnectivityPlusPluginTests: XCTestCase {
  func testBackgroundUpdatesCoalesceAndReplayNewestStateOnceInOrder() {
    let provider = FakeConnectivityProvider()
    let notificationCenter = NotificationCenter()
    var applicationState = UIApplication.State.background
    let plugin = ConnectivityPlusPlugin(
      connectivityProvider: provider,
      notificationCenter: notificationCenter,
      applicationState: { applicationState }
    )
    var events: [[String]] = []

    XCTAssertNil(
      plugin.onListen(withArguments: nil) { value in
        if let value = value as? [String] { events.append(value) }
      })
    provider.emit([.wifi])
    provider.emit([.wiredEthernet])
    drainMainQueue()
    XCTAssertTrue(events.isEmpty)

    applicationState = .active
    notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    drainMainQueue()
    XCTAssertEqual(events, [["ethernet"]])

    notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    drainMainQueue()
    XCTAssertEqual(events, [["ethernet"]], "The buffered snapshot must replay only once")
  }

  func testCancelAndReattachReplayPendingStateBeforeCurrentWithoutDuplicate() {
    let provider = FakeConnectivityProvider()
    let notificationCenter = NotificationCenter()
    var applicationState = UIApplication.State.active
    let plugin = ConnectivityPlusPlugin(
      connectivityProvider: provider,
      notificationCenter: notificationCenter,
      applicationState: { applicationState }
    )
    var firstEvents: [[String]] = []
    XCTAssertNil(
      plugin.onListen(withArguments: nil) { value in
        if let value = value as? [String] { firstEvents.append(value) }
      })
    drainMainQueue()
    XCTAssertEqual(firstEvents, [["none"]])

    applicationState = .background
    provider.emit([.wifi])
    drainMainQueue()
    XCTAssertNil(plugin.onCancel(withArguments: nil))

    applicationState = .active
    var replacementEvents: [[String]] = []
    XCTAssertNil(
      plugin.onListen(withArguments: nil) { value in
        if let value = value as? [String] { replacementEvents.append(value) }
      })
    drainMainQueue()
    XCTAssertEqual(replacementEvents, [["wifi"]])
    XCTAssertEqual(provider.startCount, 2)
    XCTAssertEqual(provider.stopCount, 1)
  }

  func testBackgroundReattachLeavesPendingStateUntilActivation() {
    let provider = FakeConnectivityProvider()
    let notificationCenter = NotificationCenter()
    var applicationState = UIApplication.State.active
    let plugin = ConnectivityPlusPlugin(
      connectivityProvider: provider,
      notificationCenter: notificationCenter,
      applicationState: { applicationState }
    )
    XCTAssertNil(plugin.onListen(withArguments: nil) { _ in })
    drainMainQueue()

    applicationState = .background
    provider.emit([.wifi])
    drainMainQueue()
    XCTAssertNil(plugin.onCancel(withArguments: nil))

    var replacementEvents: [[String]] = []
    XCTAssertNil(
      plugin.onListen(withArguments: nil) { value in
        if let value = value as? [String] { replacementEvents.append(value) }
      })
    drainMainQueue()
    XCTAssertTrue(replacementEvents.isEmpty)

    notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    drainMainQueue()
    XCTAssertTrue(replacementEvents.isEmpty, "A premature notification must not bypass background gating")

    applicationState = .active
    notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    drainMainQueue()
    XCTAssertEqual(replacementEvents, [["wifi"]])
  }

  func testQueuedUpdateFromCancelledListenerIsNotDeliveredToReplacement() {
    let provider = FakeConnectivityProvider()
    let notificationCenter = NotificationCenter()
    let plugin = ConnectivityPlusPlugin(
      connectivityProvider: provider,
      notificationCenter: notificationCenter,
      applicationState: { .active }
    )
    var firstEvents: [[String]] = []
    XCTAssertNil(
      plugin.onListen(withArguments: nil) { value in
        if let value = value as? [String] { firstEvents.append(value) }
      })
    drainMainQueue()
    XCTAssertEqual(firstEvents, [["none"]])

    provider.emit([.wifi])
    XCTAssertNil(plugin.onCancel(withArguments: nil))
    provider.currentConnectivityTypes = [.wiredEthernet]

    var replacementEvents: [[String]] = []
    XCTAssertNil(
      plugin.onListen(withArguments: nil) { value in
        if let value = value as? [String] { replacementEvents.append(value) }
      })
    drainMainQueue()

    XCTAssertEqual(firstEvents, [["none"]])
    XCTAssertEqual(replacementEvents, [["ethernet"]])
  }

  func testCancellationBreaksObserverAndProviderOwnership() {
    let provider = FakeConnectivityProvider()
    let notificationCenter = NotificationCenter()
    weak var releasedPlugin: ConnectivityPlusPlugin?

    autoreleasepool {
      var plugin: ConnectivityPlusPlugin? = ConnectivityPlusPlugin(
        connectivityProvider: provider,
        notificationCenter: notificationCenter,
        applicationState: { .active }
      )
      releasedPlugin = plugin
      XCTAssertNil(plugin?.onListen(withArguments: nil) { _ in })
      XCTAssertNil(plugin?.onCancel(withArguments: nil))
      plugin = nil
    }

    XCTAssertNil(releasedPlugin)
  }

  func testPathMonitorHandlerCanDetachItselfDuringDelivery() {
    let provider = PathMonitorConnectivityProvider()
    var received: [[ConnectivityType]] = []
    provider.connectivityUpdateHandler = { types in
      received.append(types)
      provider.connectivityUpdateHandler = nil
    }

    provider.deliver([.wifi])
    provider.deliver([.wiredEthernet])
    provider.stop()

    XCTAssertEqual(received.count, 1)
    if case .wifi? = received.first?.first {
      // Expected.
    } else {
      XCTFail("Expected the first delivered type to be Wi-Fi")
    }
  }

  func testPathMonitorHandlerAccessIsSafeDuringConcurrentDetachAndDelivery() {
    let provider = PathMonitorConnectivityProvider()
    let queue = DispatchQueue(label: "connectivity-handler-race", attributes: .concurrent)
    let group = DispatchGroup()

    for index in 0..<200 {
      group.enter()
      queue.async {
        if index.isMultiple(of: 2) {
          provider.connectivityUpdateHandler = { _ in }
        } else {
          provider.connectivityUpdateHandler = nil
        }
        _ = provider.connectivityUpdateHandler
        provider.deliver([.wifi])
        group.leave()
      }
    }

    XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
    provider.connectivityUpdateHandler = nil
    provider.stop()
  }

  private func drainMainQueue() {
    let drained = expectation(description: "main queue drained")
    DispatchQueue.main.async { drained.fulfill() }
    wait(for: [drained], timeout: 2)
  }
}
