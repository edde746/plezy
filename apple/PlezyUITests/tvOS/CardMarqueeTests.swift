import XCTest

/// On Apple TV the focused card's title, cut short, scrolls along once the card has been focused about a second, as the
/// system's lockups scroll theirs, and is back at its start, cut short, once focus leaves. Against the server
/// `PLEZY_DEV_SERVER` names, else the test Jellyfin, whose Codec Samples library holds titles wider than a card.
final class CardMarqueeTests: PlezyUITestCase {
    private lazy var steps = LibrarySteps(test: self)

    /// The card Down from the header row focuses (the grid's second), its title cut short on its line.
    private static let longTitle = "Codec AV1 HDR"

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://192.168.0.15:28096" : value
    }

    func testFocusedLongTitleScrollsAndIsBackAtItsStartWhenFocusLeaves() {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Codec Samples")
        let card = steps.card(prefix: Self.longTitle)
        if !card.exists(within: 30) { fail("Codec Samples shows no \(Self.longTitle)") }
        steps.tvFocus([(.down, 1)]) { card.hasFocus }
        // Off the card at once, and back to it after the first look: the title rests as it does after a scroll.
        XCUIRemote.shared.press(.right)
        leave(card)
        let resting = titleStrip(of: card, "the title at rest")
        shot("title at rest")

        XCUIRemote.shared.press(.left)
        _ = waitUntil(5) { card.hasFocus }
        if !card.hasFocus { fail("Left goes back to the card") }
        // Past the second the title holds still: it scrolls, and keeps scrolling.
        Thread.sleep(forTimeInterval: 2)
        let scrolling = titleStrip(of: card, "the focused title")
        shot("title scrolling")
        Thread.sleep(forTimeInterval: 1)
        let later = titleStrip(of: card, "the focused title a second later")
        shot("title scrolling a second later")
        let moved = changedShare(scrolling, later)
        XCTAssertGreaterThan(moved, 0.01, "the focused title moves between two looks a second apart: \(moved) of its pixels changed")

        XCUIRemote.shared.press(.right)
        leave(card)
        let back = titleStrip(of: card, "the title once focus left")
        shot("title once focus left")
        let changed = changedShare(resting, back)
        XCTAssertLessThan(changed, 0.002, "once focus leaves, the title is back at its start as it rested: \(changed) of its pixels differ")
    }

    /// Waits for focus to leave `card`, then for the card to settle back from its lift.
    private func leave(_ card: XCUIElement) {
        _ = waitUntil(5) { !card.hasFocus }
        if card.hasFocus { fail("Right leaves the card") }
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// The relative luminances of the line under `card`'s artwork, where its title is (and the caption's top).
    private func titleStrip(of card: XCUIElement, _ what: String) -> [Double] {
        let frame = card.frame
        return luminances(in: CGRect(x: frame.minX, y: frame.maxY + 6, width: frame.width, height: 44), what) ?? []
    }

    /// The share of the pixels of `a` and `b` (two looks at one place) whose luminances differ by over 0.02; all of them
    /// when the places differ in size.
    private func changedShare(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 1 }
        return Double(zip(a, b).filter { abs($0 - $1) > 0.02 }.count) / Double(a.count)
    }
}
