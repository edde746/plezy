import XCTest
@testable import Runner

final class TvosEventDeliveryCoordinatorTests: XCTestCase {
  func testColdLaunchTransitionsToLiveWithoutChangingFlutterEnvelope() {
    var now: TimeInterval = 10
    let coordinator = TvosDeepLinkDeliveryCoordinator(now: { now })

    XCTAssertEqual(coordinator.receive(contentId: "server:item"), .retained)
    let launchEvent = try! XCTUnwrap(coordinator.beginLiveDelivery())
    XCTAssertEqual(launchEvent.contentId, "server:item")
    XCTAssertEqual(launchEvent.flutterArguments, ["contentId": "server:item"])
    XCTAssertNil(coordinator.complete(launchEvent, succeeded: true))
    XCTAssertNil(coordinator.retainedContentId)

    now += 0.5
    XCTAssertEqual(coordinator.receive(contentId: "server:item"), .duplicate)
  }

  func testFailedLiveDeliveryRemainsRetainedAndRetryable() {
    var now: TimeInterval = 20
    let coordinator = TvosDeepLinkDeliveryCoordinator(now: { now })
    XCTAssertNil(coordinator.beginLiveDelivery())

    guard case let .deliver(first) = coordinator.receive(contentId: "server:item") else {
      return XCTFail("Expected live delivery")
    }
    XCTAssertNil(coordinator.complete(first, succeeded: false))
    XCTAssertEqual(coordinator.retainedContentId, "server:item")

    now += 0.1
    guard case let .deliver(retry) = coordinator.receive(contentId: "server:item") else {
      return XCTFail("Expected failed delivery to retry")
    }
    XCTAssertEqual(retry, first)
    XCTAssertNil(coordinator.complete(retry, succeeded: true))
    XCTAssertNil(coordinator.retainedContentId)
  }

  func testDeduplicationWindowExpiresForASecondDeliberateTap() {
    var now: TimeInterval = 30
    let coordinator = TvosDeepLinkDeliveryCoordinator(deduplicationWindow: 2, now: { now })
    XCTAssertNil(coordinator.beginLiveDelivery())

    guard case let .deliver(first) = coordinator.receive(contentId: "server:item") else {
      return XCTFail("Expected first delivery")
    }
    _ = coordinator.complete(first, succeeded: true)

    now += 1.99
    XCTAssertEqual(coordinator.receive(contentId: "server:item"), .duplicate)
    now += 0.02
    guard case let .deliver(second) = coordinator.receive(contentId: "server:item") else {
      return XCTFail("Expected delivery after bounded window")
    }
    XCTAssertNotEqual(second, first)
  }

  func testInFlightDeliveryCoalescesDuplicateAndThenDeliversNewestEvent() {
    var now: TimeInterval = 40
    let coordinator = TvosDeepLinkDeliveryCoordinator(now: { now })
    XCTAssertNil(coordinator.beginLiveDelivery())

    guard case let .deliver(first) = coordinator.receive(contentId: "server:first") else {
      return XCTFail("Expected first delivery")
    }
    now += 0.1
    XCTAssertEqual(coordinator.receive(contentId: "server:first"), .duplicate)
    XCTAssertEqual(coordinator.receive(contentId: "server:second"), .retained)

    let second = try! XCTUnwrap(coordinator.complete(first, succeeded: true))
    XCTAssertEqual(second.contentId, "server:second")
    XCTAssertNil(coordinator.complete(second, succeeded: true))
    XCTAssertNil(coordinator.retainedContentId)
  }

  func testEngineRebindRetainsLaunchEventAndRequiresInitialReadAgain() {
    let coordinator = TvosDeepLinkDeliveryCoordinator(now: { 50 })
    XCTAssertNil(coordinator.beginLiveDelivery())
    guard case let .deliver(event) = coordinator.receive(contentId: "server:item") else {
      return XCTFail("Expected live delivery")
    }
    XCTAssertNil(coordinator.complete(event, succeeded: false))

    coordinator.bindEngine()
    XCTAssertEqual(coordinator.receive(contentId: "server:item"), .duplicate)
    XCTAssertEqual(coordinator.beginLiveDelivery()?.contentId, "server:item")
  }
}
