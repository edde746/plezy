import XCTest

/// The player's centre while a video opens and once it fails: the loading indicator (`player.loading`) until the file
/// shows or fails, then the failure (`player.error`) in its place with Retry (focused on Apple TV) and Close; Retry
/// opens the video again and Close leaves the player. The video is a loopback port nothing listens on, which refuses
/// at once, or an address that never answers, which keeps the player loading.
final class PlayerFailureTests: PlezyUITestCase {
    func testAVideoThatNeverAnswersShowsTheLoadingIndicator() {
        launchDev(arguments: ["--url", "http://10.255.255.1/never.mkv"])
        _ = require("player.loading", timeout: 30, "the loading indicator while the video opens")
        XCTAssertFalse(element("player.error").exists, "no failure while it still opens")
        shot("loading")
    }

    func testAFailureReplacesTheLoadingIndicatorAndOffersRetryAndClose() {
        launchDev(arguments: ["--url", "http://127.0.0.1:9/missing.mkv"])
        _ = require("player.error", timeout: 60, "the failure")
        XCTAssertFalse(element("player.loading").exists, "the failure covers the loading indicator")
        let retry = require("player.error.retry", "Retry")
        _ = require("player.error.close", "Close")
        #if os(tvOS)
        XCTAssertTrue(retry.hasFocus, "Retry has the focus")
        #endif
        shot("failure")

        let engine = require("player.engine", "the player's engine probe")
        press(retry)
        let reopened = NSPredicate { _, _ in Self.reading(engine).hasPrefix("loads=2") }
        XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: reopened, evaluatedWith: nil)], timeout: 20), .completed, "Retry opens the video again: \(Self.reading(engine))")
        _ = require("player.error", timeout: 60, "the failure after the retry")
        press(element("player.error.close"))
        XCTAssertTrue(element("player.error").waitForNonExistence(timeout: 10), "Close leaves the player")
        shot("closed")
    }

    /// The probe's reading: the Mac's accessibility gives its label, the others its value.
    private static func reading(_ probe: XCUIElement) -> String {
        probe.label.isEmpty ? (probe.value as? String ?? "") : probe.label
    }

    private func press(_ button: XCUIElement) {
        #if os(tvOS)
        let deadline = Date().addingTimeInterval(5)
        while !button.hasFocus, Date() < deadline {
            XCUIRemote.shared.press(.right)
        }
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        button.click()
        #else
        button.tap()
        #endif
    }
}
