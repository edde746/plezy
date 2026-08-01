import Foundation
import XCTest

@testable import Runner

final class AtmosProbeContractTests: XCTestCase {
  func testCancelCompletesStartExactlyOnce() {
    let completionDelivered = expectation(description: "start completion delivered")
    let duplicateCompletion = expectation(description: "start completion delivered twice")
    duplicateCompletion.isInverted = true
    var invocationCount = 0
    var probe: AsbarProbe? = makeProbe()

    probe?.start { message in
      invocationCount += 1
      if invocationCount == 1 {
        XCTAssertEqual(message, "cancelled")
        completionDelivered.fulfill()
      } else {
        duplicateCompletion.fulfill()
      }
    }
    probe?.cancel()
    probe = nil

    wait(for: [completionDelivered], timeout: 1)
    wait(for: [duplicateCompletion], timeout: 1)
    XCTAssertEqual(invocationCount, 1)
  }

  func testDeinitCompletesStartExactlyOnce() {
    let completionDelivered = expectation(description: "start completion delivered")
    let duplicateCompletion = expectation(description: "start completion delivered twice")
    duplicateCompletion.isInverted = true
    var invocationCount = 0
    var probe: AsbarProbe? = makeProbe()

    probe?.start { message in
      invocationCount += 1
      if invocationCount == 1 {
        XCTAssertEqual(message, "cancelled")
        completionDelivered.fulfill()
      } else {
        duplicateCompletion.fulfill()
      }
    }
    probe = nil

    wait(for: [completionDelivered], timeout: 1)
    wait(for: [duplicateCompletion], timeout: 1)
    XCTAssertEqual(invocationCount, 1)
  }

  private func makeProbe() -> AsbarProbe {
    AsbarProbe(
      source: URL(string: "http://127.0.0.1:1/probe.eac3")!,
      regenerateFormatDescription: false,
      sessionMode: .moviePlayback
    )
  }
}
