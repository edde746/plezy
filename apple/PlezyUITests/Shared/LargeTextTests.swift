import XCTest

#if os(iOS)
/// Dynamic Type where text had fixed sizes or was cut short: at the accessibility size L (AX3, the app's own content
/// size at launch, `UIPreferredContentSizeCategoryName`) Search's result rows and a movie's tracks line on its detail
/// ("90p · H.264 · Off") are drawn larger than at the default size, as the text around them is, and Home's hub headings
/// show whole beside a whole View all.
final class LargeTextTests: PlezyUITestCase {
    private static let movie = "Maestro Movie"

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://192.168.0.15:28096" : value
    }

    func testSearchRowsAndTheTracksLineFollowTheTextSize() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("typing into Search ends the app on the iPad simulator; the phones cover the rows")
        }
        let normal = heights(largeText: false)
        let large = heights(largeText: true)
        // The artwork keeps its size: the text grows the row past it.
        XCTAssertGreaterThan(large.row, normal.row + 4, "the movie's result row at AX3 (\(large.row)) against the default size (\(normal.row))")
        XCTAssertGreaterThan(large.tracks, normal.tracks * 1.5, "the tracks line at AX3 (\(large.tracks)) against the default size (\(normal.tracks))")
    }

    /// At AX3 Home's hub headings show their titles whole, over more lines: each heading's View all stays whole on
    /// screen and clear of every other control.
    func testHomeHeadingsKeepTheirControlsWholeAtLargeText() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("the phones' accessibility sizes") }
        launchDev(arguments: ["--dev-server", Self.server, "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
        require("home.screen", timeout: 90, "Home")
        _ = app.buttons.matching(NSPredicate(format: "identifier ENDSWITH '.viewAll'")).firstMatch.exists(within: 10)
        let window = app.windows.firstMatch.frame
        for _ in 0..<3 {
            shot("ax3 home")
            let buttons = app.buttons.allElementsBoundByIndex.map(\.frame).filter { !$0.isEmpty && window.intersects($0) }
            let viewAlls = app.buttons.matching(NSPredicate(format: "identifier ENDSWITH '.viewAll'")).allElementsBoundByIndex.map(\.frame)
            for frame in viewAlls where window.intersects(frame) && frame.maxY < window.maxY - 120 {
                XCTAssertTrue(window.contains(frame), "View all \(frame) whole in the window \(window)")
                for other in buttons where other != frame && !other.contains(frame) && !frame.contains(other) {
                    XCTAssertFalse(other.intersects(frame.insetBy(dx: 0.5, dy: 0.5)), "View all \(frame) clear of \(other)")
                }
            }
            app.swipeUp()
            // Lets the swipe's momentum settle before the next frames are read: nothing signals its end.
            Thread.sleep(forTimeInterval: 2)
        }
    }

    /// The movie's Search result row's height and its detail's tracks line's, at AX3 or the default text size.
    private func heights(largeText: Bool) -> (row: CGFloat, tracks: CGFloat) {
        let size = largeText ? ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"] : []
        let name = largeText ? "ax3" : "default"
        launchDev(arguments: ["--dev-open", "search", "--dev-server", Self.server] + size)
        require("search.screen", timeout: 90, "the Search screen")
        let field = require("search.field", "the search field")
        // XCUITest's own attribute, which its API doesn't name: the field takes the keys only once it has the focus.
        let hasFocus = { field.value(forKey: "hasKeyboardFocus") as? Bool == true }
        for _ in 0..<3 where !hasFocus() {
            field.tap()
            _ = waitUntil(1, hasFocus)
        }
        field.typeText(Self.movie)
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == %@", Self.movie)).firstMatch
        if !result.exists(within: 30) { fail("typing \(Self.movie) lists no \(Self.movie)") }
        _ = waitUntil(5) { result.isHittable }
        shot("\(name) search")
        let row = result.frame.height
        result.tap()
        require("detail.title", timeout: 30, "\(Self.movie)'s detail")
        let tracks = require("detail.tracks", timeout: 30, "\(Self.movie)'s tracks line")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 3)
        shot("\(name) detail")
        return (row, tracks.frame.height)
    }
}
#endif
