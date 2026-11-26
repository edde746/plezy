import XCTest

/// Apple TV's remote and a game controller against the server `PLEZY_DEV_SERVER` names (the default seeded Jellyfin). The
/// focus engine moves for a controller's D-pad, stick, A and B; the app takes its X and shoulder buttons, pressed here
/// through the controller bridge's own entry (`plezy://dev-gamepad`, DEBUG builds), since the test machines have no
/// controller:
///
/// - A held Select opens the focused card's menu (the system's), which the remote's Menu closes, focus back on the card.
/// - One press of Menu on a detail goes back once: to Home, focus on the card that opened it.
/// - The shoulder buttons step through Libraries' tabs, stopping at the ends.
final class TvInputTests: PlezyUITestCase {
    private func server() throws -> String {
        try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
    }

    func testControllerMenuAndRemoteBack() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        // Lets Home's first focus land: a press while the screen still appears goes nowhere.
        sleep(3)
        let card = focusCard()
        shot("home card focused")

        XCUIRemote.shared.press(.select, forDuration: 1.2)
        if !menu.exists(within: 10) { fail("a held Select opens the focused card's menu") }
        shot("card menu")
        press(.menu)
        if !menu.waitForNonExistence(timeout: 10) { fail("Menu closes the card's menu") }
        if focusedId != card { fail("the menu closed: focus is on \(focusedId), not \(card)") }

        // Continue Watching's cards play: the next row's open their detail. Home's buttons (Refresh, Live TV…) sit
        // between the two rows, so Down goes on until a card outside Continue Watching has focus; the first press waits
        // for the closed menu's focus to settle.
        sleep(1)
        let continueWatching = element("hub.continue_watching")
        func inContinueWatching(_ id: String) -> Bool {
            continueWatching.descendants(matching: .any).matching(identifier: id).count > 0
        }
        for _ in 0..<4 where !focusedId.hasPrefix("card.") || focusedId == card || inContinueWatching(focusedId) {
            press(.down)
        }
        let opener = focusedId
        if !opener.hasPrefix("card.") || inContinueWatching(opener) { fail("Down from Continue Watching: focus is on \(opener)") }
        press(.select)
        require("detail.screen", timeout: 30, "Select opens the card's detail")
        // The detail's artwork comes over the network.
        sleep(3)
        shot("detail")
        press(.menu)
        if !element("detail.screen").waitForNonExistence(timeout: 10) { fail("Menu leaves the detail") }
        require("home.screen", "one Menu goes back to Home")
        _ = waitUntil(5) { focusedId == opener }
        if focusedId != opener { fail("one Menu from the detail: focus is on \(focusedId), not \(opener) (back went further)") }
        shot("home after one menu")
    }

    func testShoulderButtonsStepThroughLibrariesTabs() throws {
        launchDev(arguments: ["--dev-server", try server(), "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        let tabs = viewMenuTabs()
        if tabs.count < 3 { fail("Libraries shows \(tabs)") }
        let at = selectedTab(of: tabs)
        shot("libraries tabs")

        gamepad("press=rightShoulder")
        expectTab(tabs, at + 1, "RB shows the next tab")
        _ = waitUntil(5) { LibrarySteps(test: self).hasFocus(element("libraries.view")) }
        if !LibrarySteps(test: self).hasFocus(element("libraries.view")) { fail("RB leaves focus on \(focusedId), not the view menu") }
        shot("libraries next tab")
        gamepad("press=leftShoulder")
        expectTab(tabs, at, "LB shows the previous tab")
        for _ in 0..<(tabs.count + 1) { gamepad("press=rightShoulder") }
        expectTab(tabs, tabs.count - 1, "RB stops at the last tab")
        gamepad("press=leftShoulder")
        expectTab(tabs, tabs.count - 2, "LB from the last tab")
        shot("libraries tabs after the shoulders")
    }

    // MARK: - Steps

    private func press(_ button: XCUIRemote.Button) {
        XCUIRemote.shared.press(button)
        // Paces the presses so the focus engine takes each one.
        Thread.sleep(forTimeInterval: 0.6)
    }

    private var focusedId: String {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        return (try? focused.snapshot())?.identifier ?? "nothing"
    }

    /// Off the side rail and down the rows until a card has focus; its identifier.
    private func focusCard() -> String {
        for _ in 0..<10 where !focusedId.hasPrefix("card.") {
            press(focusedId.hasPrefix("nav.") ? .right : .down)
        }
        if !focusedId.hasPrefix("card.") { fail("the remote brings focus to no card: it is on \(focusedId)") }
        return focusedId
    }

    /// An item menu: the shared one's entries (`menu.<entry>`), or a card's own (`card.<id>.menu.<n>`).
    private var menu: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(
            format: "(identifier BEGINSWITH 'menu.' AND identifier != 'menu.message') OR identifier CONTAINS '.menu.'"
        )).firstMatch
    }

    /// The selected library's tabs, as the view menu lists them.
    private func viewMenuTabs() -> [String] {
        if !element("libraries.view").exists(within: 60) { fail("Libraries shows no view menu") }
        // Lets the screen's first focus land before the menu opens.
        sleep(2)
        LibrarySteps(test: self).openFilterMenu("libraries.view")
        let options = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'libraries.view.option.'"))
        _ = options.firstMatch.exists(within: 10)
        let labels = (0..<options.count).compactMap { try? options.element(boundBy: $0).snapshot().label }
        press(.menu)
        _ = waitUntil(5) { !options.firstMatch.exists }
        return labels
    }

    /// The tab the view menu names as shown.
    private func selectedTab(of tabs: [String]) -> Int {
        let shown = element("libraries.view").label
        return tabs.firstIndex { shown.hasSuffix($0) } ?? -1
    }

    private func expectTab(_ tabs: [String], _ index: Int, _ what: String) {
        _ = waitUntil(5) { selectedTab(of: tabs) == index }
        if selectedTab(of: tabs) != index { fail("\(what): \(tabs) selects \(selectedTab(of: tabs)), not \(index)") }
    }
}
