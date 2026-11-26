import XCTest

/// A season card opens its show's page with that season's chip selected, never a page of the season's own, and Back
/// returns to the grid it was pressed in: each of Maestro Show's season cards in Shows › Seasons on the development
/// Jellyfin server (`PLEZY_DEV_SERVER`), wherever in the grid other shows' seasons put them. The first show page is kept
/// as a screenshot.
final class SeasonCardTests: PlezyUITestCase {
    private static let show = "Maestro Show"

    private lazy var steps = LibrarySteps(test: self)

    /// The grid's season cards of `show`, those built so far.
    private var showCards: XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'card.' AND NOT (identifier ENDSWITH '.menu') AND label == %@", Self.show)
        )
    }

    func testSeasonCardsOpenTheirShowAtTheirSeason() throws {
        executionTimeAllowance = 600
        launchDev(arguments: ["--dev-server", try steps.libraryServer(), "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Shows")
        steps.showLibraryTab("browse")
        steps.openFilterMenu("libraries.grouping")
        steps.pickOption("libraries.grouping", label: "Seasons")
        if !steps.prefixed("card.").exists(within: 30) { return fail("Shows › Seasons lists no season") }
        shot("seasons grid")

        var picked: [String: String] = [:]
        #if os(tvOS)
        moveFocus(with: .down, limit: 6, "Down reaches a card") { $0.identifier.hasPrefix("card.") }
        // Down to the row of the show's first season card, to its start, then along the grid through the show's cards.
        moveFocus(with: .down, limit: 40, "Down reaches the row of \(Self.show)'s seasons") { focused in
            let row = focused.frame
            return showCards.allElementsBoundByIndex.contains { abs($0.frame.midY - row.midY) < row.height / 2 }
        }
        rowStart()
        for _ in 0..<40 {
            let card = focusedElement
            let id = card.identifier
            if card.label == Self.show {
                if picked[id] == nil {
                    XCUIRemote.shared.press(.select)
                    guard let season = selectedSeason(shot: picked.isEmpty) else { return }
                    picked[id] = season
                    // The focus engine drops a press made while the detail still pushes in.
                    sleep(1)
                    XCUIRemote.shared.press(.menu)
                    if !waitUntil(10, { self.focusedElement.identifier == id }) { return fail("Menu from the show comes back to its season card") }
                }
            } else if !picked.isEmpty {
                break
            }
            if !nextCard() { break }
        }
        #else
        guard let ids = revealShowCards() else { return }
        for id in ids {
            let card = element(id)
            if !card.exists(within: 10) { return fail("the Seasons grid lists \(id)") }
            if !bringIntoView(card) { return fail("\(id) scrolls into the Seasons grid's view") }
            steps.press(card)
            guard let season = selectedSeason(shot: picked.isEmpty) else { return }
            picked[id] = season
            goBack()
            if !element(id).exists(within: 10) { return fail("Back from the show comes back to the Seasons grid") }
        }
        #endif
        XCTAssertGreaterThanOrEqual(picked.count, 2, "\(Self.show)'s season cards all opened: \(picked)")
        XCTAssertEqual(Set(picked.values).count, picked.count, "each season card selects its own season: \(picked)")
    }

    /// The show page a season card opened (its season chips, which no season page has) and the label of its selected
    /// chip; nil after a failure.
    private func selectedSeason(shot first: Bool) -> String? {
        require("detail.season.0", timeout: 30, "\(Self.show)'s season chips: the card opened its show")
        let chips = app.descendants(matching: .any).matching(NSPredicate(format: "identifier MATCHES 'detail\\\\.season\\\\.[0-9]+'"))
        let selected = { chips.allElementsBoundByIndex.first { $0.isSelected }?.label }
        if !waitUntil(10, { selected() != nil }) {
            fail("no season chip is selected")
            return nil
        }
        if first { shot("season card opens its show") }
        return selected()
    }

    #if os(tvOS)
    private var focusedElement: XCUIElement {
        app.descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
    }

    /// Presses `button` until the focused element matches `found`, at most `limit` times.
    private func moveFocus(with button: XCUIRemote.Button, limit: Int, _ what: String, found: (XCUIElement) -> Bool) {
        for _ in 0..<limit {
            if focusedElement.exists, found(focusedElement) { return }
            XCUIRemote.shared.press(button)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(600_000)
        }
        if focusedElement.exists, found(focusedElement) { return }
        fail("\(what): focus is on \(focusedElement.exists ? focusedElement.identifier : "nothing")")
    }

    /// Focus onto the start of the focused card's row.
    private func rowStart() {
        for _ in 0..<10 {
            let at = focusedElement.identifier
            XCUIRemote.shared.press(.left)
            usleep(600_000)
            if focusedElement.identifier == at { return }
        }
    }

    /// Focus onto the grid's next card: right along the row, else down to the next row and back to its start; false at
    /// the grid's end.
    private func nextCard() -> Bool {
        let from = focusedElement.identifier
        XCUIRemote.shared.press(.right)
        usleep(600_000)
        guard focusedElement.identifier == from else { return true }
        XCUIRemote.shared.press(.down)
        usleep(600_000)
        guard focusedElement.identifier != from else { return false }
        rowStart()
        return true
    }
    #else
    /// Scrolls the grid down until a season card of the show is on screen, and returns the ids of the show's season
    /// cards built then (the lazy grid builds the rows next to the visible ones); nil after a failure.
    private func revealShowCards() -> [String]? {
        for _ in 0..<30 {
            if showCards.allElementsBoundByIndex.contains(where: steps.onScreen) {
                return showCards.allElementsBoundByIndex.map(\.identifier)
            }
            scrollGrid(down: true)
        }
        fail("Shows › Seasons lists no season of \(Self.show)")
        return nil
    }

    /// Scrolls the grid until `card`'s middle is in the grid's upper part, clear of the bars over its foot, or as far as
    /// the grid scrolls (a card of its last rows); false when it isn't hittable there.
    private func bringIntoView(_ card: XCUIElement) -> Bool {
        let grid = element("libraries.grid").frame
        for _ in 0..<8 {
            let y = card.frame.midY
            if y < grid.minY + grid.height * 0.15 {
                scrollGrid(down: false)
            } else if y > grid.minY + grid.height * 0.6 {
                scrollGrid(down: true)
            } else {
                return true
            }
            if card.frame.midY == y { return card.isHittable }
        }
        return false
    }

    /// Scrolls the grid a third of its height, `down` toward its end or up toward its start.
    private func scrollGrid(down: Bool) {
        let grid = element("libraries.grid")
        #if os(macOS)
        let delta = grid.frame.height / 3
        grid.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).scroll(byDeltaX: 0, deltaY: down ? -delta : delta)
        #else
        let (from, to) = down ? (0.6, 0.27) : (0.27, 0.6)
        grid.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: from))
            .press(forDuration: 0.1, thenDragTo: grid.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: to)))
        #endif
        // Lets the scroll settle and the cells it brings in build.
        sleep(1)
    }

    private func goBack() {
        #if os(macOS)
        app.buttons.matching(identifier: "chevron.backward").firstMatch.click()
        #else
        backButton.tap()
        #endif
    }
    #endif
}
