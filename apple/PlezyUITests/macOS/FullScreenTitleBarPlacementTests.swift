import CoreGraphics
import XCTest

/// AppKit's full-screen title bar window is down (and takes the clicks over the top of the window) only once it has come
/// down below the full-screen window's top; resting there it lets them through to the window, on a screen with a camera
/// housing too, where the full-screen window and the resting title bar end below the housing. Frames in AppKit's screen
/// coordinates (origin at the bottom left).
final class FullScreenTitleBarPlacementTests: XCTestCase {
    /// A 1920 x 1080 display without a camera housing: the full-screen window fills it.
    private let plainWindow = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    /// A 13-inch MacBook Air's display (1470 x 956 points, a 32 pt camera housing): the full-screen window ends 33 pt
    /// below the screen's top.
    private let airWindow = CGRect(x: 0, y: 0, width: 1470, height: 923)

    /// A 14-inch MacBook Pro's display at its default scaling (1512 x 982 points, a 38 pt camera housing): the
    /// full-screen window ends 39 pt below the screen's top.
    private let proWindow = CGRect(x: 0, y: 0, width: 1512, height: 943)

    func testRestingTitleBarLetsClicksThroughWithoutACameraHousing() {
        // Without a toolbar, and with the screens' toolbar.
        XCTAssertFalse(down(CGRect(x: 0, y: 1048, width: 1920, height: 32), 1, plainWindow))
        XCTAssertFalse(down(CGRect(x: 0, y: 1014, width: 1920, height: 66), 1, plainWindow))
    }

    func testTitleBarUnderTheMenuBarTakesClicksWithoutACameraHousing() {
        XCTAssertTrue(down(CGRect(x: 0, y: 1024, width: 1920, height: 32), 1, plainWindow))
    }

    func testRestingTitleBarLetsClicksThroughUnderACameraHousing() {
        XCTAssertFalse(down(CGRect(x: 0, y: 891, width: 1470, height: 32), 1, airWindow))
        XCTAssertFalse(down(CGRect(x: 0, y: 857, width: 1470, height: 66), 1, airWindow))
        XCTAssertFalse(down(CGRect(x: 0, y: 911, width: 1512, height: 32), 1, proWindow))
        XCTAssertFalse(down(CGRect(x: 0, y: 877, width: 1512, height: 66), 1, proWindow))
    }

    func testTitleBarComeDownTakesClicksUnderACameraHousing() {
        XCTAssertTrue(down(CGRect(x: 0, y: 858, width: 1470, height: 32), 1, airWindow))
        XCTAssertTrue(down(CGRect(x: 0, y: 872, width: 1512, height: 32), 1, proWindow))
    }

    func testFadedOutTitleBarLetsClicksThrough() {
        XCTAssertFalse(down(CGRect(x: 0, y: 1024, width: 1920, height: 32), 0, plainWindow))
        XCTAssertFalse(down(CGRect(x: 0, y: 858, width: 1470, height: 32), 0, airWindow))
        XCTAssertFalse(down(CGRect(x: 0, y: 872, width: 1512, height: 32), 0, proWindow))
    }

    private func down(_ titleBar: CGRect, _ alpha: CGFloat, _ window: CGRect) -> Bool {
        FullScreenTitleBarPlacement.isDown(titleBar: titleBar, alpha: alpha, window: window)
    }
}
