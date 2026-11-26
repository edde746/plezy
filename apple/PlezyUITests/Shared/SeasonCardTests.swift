import XCTest

/// A season card opens its show's page with that season's chip selected, never a page of the season's own, and Back
/// returns to the grid it was pressed in: each of Maestro Show's season cards in Shows › Seasons on the development
/// Jellyfin server (`PLEZY_DEV_SERVER`). The first show page is kept as a screenshot.
final class SeasonCardTests: PlezyUITestCase {
    private static let show = "Maestro Show"

    private lazy var steps = LibrarySteps(test: self)

    func testSeasonCardsOpenTheirShowAtTheirSeason() throws {
        executionTimeAllowance = 600
        launchDev(arguments: ["--dev-server", try steps.libraryServer(), "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Shows")
        steps.showLibraryTab("browse")
        steps.openFilterMenu("libraries.grouping")
        steps.pickOption("libraries.grouping", label: "Seasons")
        let cards = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'card.' AND NOT (identifier ENDSWITH '.menu') AND label == %@", Self.show)
        )
        if !cards.firstMatch.exists(within: 30) { return fail("Shows › Seasons lists no season of \(Self.show)") }
        let ids = cards.allElementsBoundByIndex.map(\.identifier)
        XCTAssertGreaterThanOrEqual(ids.count, 2, "\(Self.show) has several season cards: \(ids)")
        shot("seasons grid")

        var picked: [String: String] = [:]
        #if os(tvOS)
        moveFocus(with: .down, limit: 6, "Down reaches a card") { $0.identifier.hasPrefix("card.") }
        for _ in 0..<40 where picked.count < ids.count {
            let card = focusedElement
            if ids.contains(card.identifier), picked[card.identifier] == nil {
                let id = card.identifier
                XCUIRemote.shared.press(.select)
                guard let season = selectedSeason(shot: picked.isEmpty) else { return }
                picked[id] = season
                // The focus engine drops a press made while the detail still pushes in.
                sleep(1)
                XCUIRemote.shared.press(.menu)
                if !waitUntil(10, { self.focusedElement.identifier == id }) { return fail("Menu from the show comes back to its season card") }
            }
            nextCard()
        }
        #else
        for id in ids {
            let card = element(id)
            if !card.exists(within: 10) { return fail("the Seasons grid lists \(id)") }
            steps.press(card)
            guard let season = selectedSeason(shot: picked.isEmpty) else { return }
            picked[id] = season
            goBack()
            if !element(id).exists(within: 10) { return fail("Back from the show comes back to the Seasons grid") }
        }
        #endif
        XCTAssertEqual(picked.count, ids.count, "every season card opened: \(picked)")
        XCTAssertEqual(Set(picked.values).count, ids.count, "each season card selects its own season: \(picked)")
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

    /// Focus onto the grid's next card: right along the row, else down to the next row and back to its start.
    private func nextCard() {
        let from = focusedElement.identifier
        XCUIRemote.shared.press(.right)
        usleep(600_000)
        guard focusedElement.identifier == from else { return }
        XCUIRemote.shared.press(.down)
        usleep(600_000)
        for _ in 0..<10 {
            let at = focusedElement.identifier
            XCUIRemote.shared.press(.left)
            usleep(600_000)
            if focusedElement.identifier == at { return }
        }
    }
    #else
    private func goBack() {
        #if os(macOS)
        app.buttons.matching(identifier: "chevron.backward").firstMatch.click()
        #else
        backButton.tap()
        #endif
    }
    #endif
}
