import XCTest

/// A row of cards scrolled by the pointer on the Mac, on Home's longest row against the server `PLEZY_DEV_SERVER` names
/// (the default seeded Jellyfin):
///
/// - Hovered, the row shows › (`row.forward`) and no ‹ (`row.back`) at its start; › scrolls it by about its width and
///   brings ‹; at its end › goes, and ‹ scrolls it back to its start, where ‹ goes.
/// - A press dragged along the row scrolls it and opens no card; a click on a card opens it.
final class RowScrollTests: PlezyUITestCase {
    func testButtonsPageTheRowAndHideAtItsEnds() throws {
        let (row, card) = try homeRow()
        let start = card.frame.minX
        row.hover()
        let forward = row.descendants(matching: .any)["row.forward"]
        let back = row.descendants(matching: .any)["row.back"]
        if !forward.exists(within: 5) { return fail("hovering \(row.identifier) at its start shows no › button") }
        if back.exists { fail("hovering \(row.identifier) at its start shows ‹") }
        // The window's shot, which leaves the pointer over the row.
        shot("hovered at the start", of: app.windows.firstMatch)

        let width = row.scrollViews.firstMatch.frame.width
        forward.click()
        _ = waitUntil(3) { card.frame.minX < start - width / 2 }
        let paged = start - card.frame.minX
        if paged < width / 2 || paged > width { fail("› scrolled \(row.identifier) \(paged) pt, not about its width \(width)") }
        if !back.exists(within: 3) { fail("‹ doesn't show once \(row.identifier) is scrolled from its start") }
        shot("after one page", of: app.windows.firstMatch)

        var pages = 1
        while forward.exists, pages < 40 {
            forward.click()
            pages += 1
            // The page's scroll comes to rest before the button is looked for again.
            sleep(1)
        }
        if forward.exists { return fail("› still shows after \(pages) pages of \(row.identifier)") }
        if !back.exists { fail("‹ doesn't show at the end of \(row.identifier)") }
        shot("at the end", of: app.windows.firstMatch)

        var backs = 0
        while back.exists, backs < pages + 2 {
            back.click()
            backs += 1
            sleep(1)
        }
        if back.exists { return fail("‹ still shows after \(backs) pages back along \(row.identifier)") }
        if abs(card.frame.minX - start) > 2 { fail("‹ brought the first card to x \(card.frame.minX), not back to \(start)") }
        if !forward.exists { fail("› doesn't show at the start of \(row.identifier) again") }
        shot("back at the start", of: app.windows.firstMatch)
    }

    func testDragScrollsTheRowAndOpensNoCard() throws {
        let (row, card) = try homeRow()
        let start = card.frame.minX
        let area = row.scrollViews.firstMatch
        let from = area.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        // Held still before letting go, so the row stops where the drag does.
        from.click(forDuration: 0.2, thenDragTo: from.withOffset(CGVector(dx: -300, dy: 0)), withVelocity: .slow, thenHoldForDuration: 0.3)
        _ = waitUntil(3) { card.frame.minX < start - 200 }
        if card.frame.minX > start - 200 { fail("a drag of 300 pt to the left moved \(row.identifier)'s card from x \(start) to \(card.frame.minX)") }
        if element("detail.screen").exists(within: 3) { fail("the drag opened the card it started on") }
        shot("after a drag")

        // Dragged back to its start, the row's first card takes a click.
        let back = area.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.4))
        back.click(forDuration: 0.2, thenDragTo: back.withOffset(CGVector(dx: 600, dy: 0)), withVelocity: .slow, thenHoldForDuration: 0.3)
        _ = waitUntil(3) { abs(card.frame.minX - start) < 2 }
        if abs(card.frame.minX - start) > 2 { fail("a drag back to the right left the card at x \(card.frame.minX), not \(start)") }
        if element("detail.screen").exists(within: 3) { fail("the drag back opened the card it started on") }
        let name = row.identifier
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).click()
        require("detail.screen", timeout: 30, "a click on \(name)'s card opens its detail")
        shot("a click opens the card")
    }

    // MARK: - Steps

    /// Home's row with the most cards but Continue Watching (whose cards play), and its first card, the page scrolled
    /// until the card is wholly in the window. The row must reach past the window.
    private func homeRow() throws -> (XCUIElement, XCUIElement) {
        let server = try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
        launchDev(arguments: ["--dev-server", server])
        require("home.screen", timeout: 60, "Home")
        let hubs = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'hub.' AND identifier != 'hub.continue_watching' AND NOT (identifier ENDSWITH '.viewAll')"
        ))
        if !hubs.firstMatch.exists(within: 60) { fail("Home shows no row but Continue Watching") }
        // Home's rows settle as the rest of its content comes.
        sleep(3)
        let isCard = NSPredicate(format: "identifier BEGINSWITH 'card.'")
        let rows = (0..<min(hubs.count, 10)).map { hubs.element(boundBy: $0) }
        let row = try XCTUnwrap(rows.max {
            $0.descendants(matching: .any).matching(isCard).count < $1.descendants(matching: .any).matching(isCard).count
        }, "Home shows no row")
        let card = row.descendants(matching: .any).matching(isCard).firstMatch
        if !card.exists(within: 30) { fail("\(row.identifier) shows no card") }
        let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 60)
        // The scroll's sign is the page's: flipped once a scroll moves the card the wrong way.
        var delta: CGFloat = -200
        for _ in 0..<12 where !window.contains(card.frame) {
            let before = card.frame.minY
            let up = card.frame.maxY > window.maxY
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
                .scroll(byDeltaX: 0, deltaY: up ? delta : -delta)
            // Lets the scroll come to rest before the move is measured.
            sleep(1)
            let moved = card.frame.minY - before
            if (up && moved > 0) || (!up && moved < 0) { delta = -delta }
        }
        if !window.contains(card.frame) { fail("\(card.identifier) never came wholly into the window") }
        // Kept in the window a moment: Home's rows still loading can take the page back to its top.
        sleep(1)
        let cards = row.descendants(matching: .any).matching(isCard)
        let last = cards.element(boundBy: cards.count - 1)
        try XCTSkipUnless(last.frame.maxX > window.maxX, "\(row.identifier) fits in the window: nothing to scroll")
        return (row, card)
    }
}
