import XCTest
@testable import Runner

final class DeepLinkDeliveryCoordinatorTests: XCTestCase {
  private let link = "plezy://play?content_id=plezy_server_item"

  func testColdLaunchTransitionsToLiveWithoutChangingFlutterEnvelope() {
    var now: TimeInterval = 10
    let coordinator = DeepLinkDeliveryCoordinator(now: { now })

    XCTAssertEqual(coordinator.receive(url: link), .retained)
    let launchEvent = try! XCTUnwrap(coordinator.beginLiveDelivery())
    XCTAssertEqual(launchEvent.url, link)
    XCTAssertEqual(launchEvent.flutterArguments, ["url": link])
    XCTAssertNil(coordinator.complete(launchEvent, succeeded: true))
    XCTAssertNil(coordinator.retainedURL)

    now += 0.5
    XCTAssertEqual(coordinator.receive(url: link), .duplicate)
  }

  func testFailedLiveDeliveryRemainsRetainedAndRetryable() {
    var now: TimeInterval = 20
    let coordinator = DeepLinkDeliveryCoordinator(now: { now })
    XCTAssertNil(coordinator.beginLiveDelivery())

    guard case let .deliver(first) = coordinator.receive(url: link) else {
      return XCTFail("Expected live delivery")
    }
    XCTAssertNil(coordinator.complete(first, succeeded: false))
    XCTAssertEqual(coordinator.retainedURL, link)

    now += 0.1
    guard case let .deliver(retry) = coordinator.receive(url: link) else {
      return XCTFail("Expected failed delivery to retry")
    }
    XCTAssertEqual(retry, first)
    XCTAssertNil(coordinator.complete(retry, succeeded: true))
    XCTAssertNil(coordinator.retainedURL)
  }

  func testDeduplicationWindowExpiresForASecondDeliberateOpen() {
    var now: TimeInterval = 30
    let coordinator = DeepLinkDeliveryCoordinator(deduplicationWindow: 2, now: { now })
    XCTAssertNil(coordinator.beginLiveDelivery())

    guard case let .deliver(first) = coordinator.receive(url: link) else {
      return XCTFail("Expected first delivery")
    }
    _ = coordinator.complete(first, succeeded: true)

    now += 1.99
    XCTAssertEqual(coordinator.receive(url: link), .duplicate)
    now += 0.02
    guard case let .deliver(second) = coordinator.receive(url: link) else {
      return XCTFail("Expected delivery after bounded window")
    }
    XCTAssertNotEqual(second, first)
  }

  func testInFlightDeliveryCoalescesDuplicateAndThenDeliversNewestEvent() {
    var now: TimeInterval = 40
    let coordinator = DeepLinkDeliveryCoordinator(now: { now })
    XCTAssertNil(coordinator.beginLiveDelivery())
    let first = "plezy://play?server=s&id=first"
    let second = "plezy://live?channel=5"

    guard case let .deliver(firstEvent) = coordinator.receive(url: first) else {
      return XCTFail("Expected first delivery")
    }
    now += 0.1
    XCTAssertEqual(coordinator.receive(url: first), .duplicate)
    XCTAssertEqual(coordinator.receive(url: second), .retained)

    let secondEvent = try! XCTUnwrap(coordinator.complete(firstEvent, succeeded: true))
    XCTAssertEqual(secondEvent.url, second)
    XCTAssertNil(coordinator.complete(secondEvent, succeeded: true))
    XCTAssertNil(coordinator.retainedURL)
  }

  func testEngineRebindRetainsLaunchEventAndRequiresInitialReadAgain() {
    let coordinator = DeepLinkDeliveryCoordinator(now: { 50 })
    XCTAssertNil(coordinator.beginLiveDelivery())
    guard case let .deliver(event) = coordinator.receive(url: link) else {
      return XCTFail("Expected live delivery")
    }
    XCTAssertNil(coordinator.complete(event, succeeded: false))

    coordinator.bindEngine()
    XCTAssertEqual(coordinator.receive(url: link), .duplicate)
    XCTAssertEqual(coordinator.beginLiveDelivery()?.url, link)
  }
}
