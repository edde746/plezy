import AppKit
import XCTest

/// The Mac's keyboard and game-controller input against the server `PLEZY_DEV_SERVER` names (the default seeded Jellyfin):
///
/// - A game controller, which the test Macs lack, pressed through the controller bridge's own entry
///   (`plezy://dev-gamepad`, DEBUG builds): B goes back from a detail, and at Home's root arms the exit;
///   the shoulder buttons step through Libraries' tabs, stopping at the ends, and not under an overlay. With the
///   system's keyboard navigation on (System Settings → Keyboard, which AppKit reads from the system's settings alone:
///   a launch argument doesn't reach it), the D-pad and the stick move the keyboard's focus, A opens the focused card,
///   a held A and X open its menu, and a controller unplugged with A held opens neither the card nor its menu;
///   skipped on a Mac where it is off.
/// - With keyboard navigation on, the arrow keys move focus between cards and rows: a library's grid, Home, a detail.
/// - In the sidebar, clicked into, Down and Up (the keyboard's, and a controller's D-pad) pick the next and previous row.
/// - Escape goes back on its release: from a detail to Home, from Libraries' root to Home; Escape that closed a menu
///   goes no further; at Home's root it only takes the window out of full screen and never arms the exit; after the
///   player closes, Escape goes back from the detail under it.
/// - A diagonal scroll over a row of cards moves the page or the row, not both.
final class MacInputTests: PlezyUITestCase {
    private func server() throws -> String {
        try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
    }

    func testGamepadGoesBack() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        click(rowCard())
        require("detail.screen", timeout: 30, "a card's detail")
        // Lets the detail's push finish before B.
        sleep(2)
        gamepad("press=b")
        if !element("detail.screen").waitForNonExistence(timeout: 10) { fail("B leaves the detail") }
        require("home.screen", "B goes back to Home")
        // Gives B time to arm the exit too; checked after that it didn't.
        sleep(1)
        if element("shell.exitPrompt").exists { fail("B from the detail also armed the exit") }
        gamepad("press=b")
        require("shell.exitPrompt", timeout: 5, "B at Home's root arms the exit, as a remote's Back does")
        shot("gamepad exit prompt")
    }

    func testGamepadMovesFocusOpensAndGoesBack() throws {
        // Bit 2 of the system's AppleKeyboardUIMode: keyboard navigation.
        let mode = CFPreferencesGetAppIntegerValue("AppleKeyboardUIMode" as CFString, kCFPreferencesAnyApplication, nil)
        try XCTSkipUnless(mode & 2 != 0, "the Mac's keyboard navigation is off: no key or controller moves focus")
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        _ = firstCard()
        // Home's artwork comes over the network.
        sleep(3)
        shot("home")

        focusCard()
        let first = keyboardFocus
        gamepad("press=dpadRight")
        let second = keyboardFocus
        if second == first { fail("the D-pad's Right left focus on \(first)") }
        gamepad("stick=1,0")
        gamepad("stick=0,0")
        let third = keyboardFocus
        if third == second { fail("the stick's Right left focus on \(second)") }
        shot("gamepad moved focus")

        focusOpeningCard()
        gamepad("press=a")
        require("detail.screen", timeout: 30, "A opens the focused card's detail")
        // The detail's artwork comes over the network.
        sleep(2)
        shot("gamepad opened detail")
        gamepad("press=b")
        if !element("detail.screen").waitForNonExistence(timeout: 10) { fail("B leaves the detail") }
        require("home.screen", "B goes back to Home")

        // An open menu holds back the links until it closes: B is sent first, pressed once the menu is open.
        focusCard()
        gamepad("press=b&after=3000")
        gamepad("press=x")
        if !menu.exists(within: 1) { fail("X opens the focused card's menu; focus is on \(keyboardFocus)") }
        shot("gamepad menu")
        if !menu.waitForNonExistence(timeout: 10) { fail("B closes the menu") }
        if element("shell.exitPrompt").exists { fail("B closing the menu also armed the exit") }

        focusCard()
        gamepad("press=b&after=5000")
        gamepad("press=a&hold=900")
        if !menu.exists(within: 1) { fail("A held opens the focused card's menu") }
        // Gives the held A time to open the card too; checked after that it didn't.
        sleep(1)
        if element("detail.screen").exists { fail("A held also opened the card") }
        shot("gamepad held a menu")
        if !menu.waitForNonExistence(timeout: 10) { fail("B closes the held A's menu") }

        gamepad("press=b")
        require("shell.exitPrompt", timeout: 5, "B at Home's root arms the exit, as a remote's Back does")
        shot("gamepad exit prompt")
    }

    /// A controller unplugged with A held on Home's focused card neither opens the card nor its menu; A pressed there
    /// then opens it. The focused card is whichever the controller's first press brings focus to, seen in the shots.
    func testGamepadUnpluggedWithAHeldOpensNothing() throws {
        let mode = CFPreferencesGetAppIntegerValue("AppleKeyboardUIMode" as CFString, kCFPreferencesAnyApplication, nil)
        try XCTSkipUnless(mode & 2 != 0, "the Mac's keyboard navigation is off: no key or controller moves focus")
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        _ = firstCard()
        // Home's rows settle as the rest of its content comes.
        sleep(3)
        gamepad("press=dpadDown")
        shot("gamepad focus before unplug")

        gamepad("down=a&disconnect")
        // Gives the held A time to open something; checked after that nothing opened.
        sleep(2)
        shot("gamepad unplugged holding a")
        if menu.exists { fail("a controller unplugged with A held opened the card's menu") }
        if element("detail.screen").exists { fail("a controller unplugged with A held opened the card") }
        if element("player.video").exists { fail("a controller unplugged with A held played the card") }

        gamepad("press=a")
        let opened = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'detail.screen' OR identifier == 'player.video'")
        ).firstMatch
        if !opened.exists(within: 30) { fail("A on the focused card opens it, so the unplug had a card to open") }
        shot("gamepad a opened the card")
    }

    func testShoulderButtonsStepThroughLibrariesTabs() throws {
        launchDev(arguments: ["--dev-server", try server(), "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        let tabs = viewMenuTabs()
        if tabs.count < 3 { fail("Libraries shows \(tabs)") }
        var at = selectedTab(of: tabs)
        shot("libraries tabs")

        gamepad("press=rightShoulder")
        expectTab(tabs, at + 1, "RB shows the next tab")
        at += 1
        gamepad("press=leftShoulder")
        expectTab(tabs, at - 1, "LB shows the previous tab")
        at -= 1
        for _ in 0..<(tabs.count + 1) { gamepad("press=rightShoulder") }
        expectTab(tabs, tabs.count - 1, "RB stops at the last tab")
        shot("libraries last tab")

        // Under Manage libraries, pushed over it, the screen keeps its tab, which shows once it closes.
        LibrarySteps(test: self).openManageLibraries()
        gamepad("press=leftShoulder")
        shot("libraries under manage")
        app.buttons.matching(identifier: "chevron.backward").firstMatch.click()
        require("libraries.screen", timeout: 20, "Libraries after Manage libraries")
        // Gives LB time to change the tab; checked after that it stayed.
        sleep(2)
        expectTab(tabs, tabs.count - 1, "LB under Manage libraries leaves the tab")
        gamepad("press=leftShoulder")
        expectTab(tabs, tabs.count - 2, "LB with Manage libraries closed shows the previous tab")
    }

    func testEscapeGoesBackAndLeavesFullScreenAtHome() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        // Clicked as soon as it is in view (the hero's turns can take the page back to its top), at its middle: the
        // row's scroll view answers the accessibility hit test there.
        click(rowCard())
        require("detail.screen", timeout: 30, "a card's detail")
        // Lets the detail's push finish before Escape.
        sleep(2)
        app.typeKey(.escape, modifierFlags: [])
        if !element("detail.screen").waitForNonExistence(timeout: 10) { fail("Escape leaves the detail") }
        require("home.screen", "Escape goes back to Home")

        // Escape closing the detail's menu goes no further: its release reaches the window with no press.
        click(rowCard())
        require("detail.screen", timeout: 30, "the card's detail again")
        let more = require("detail.more", timeout: 20, "the detail's More")
        _ = waitUntil(5) { more.isHittable }
        more.click()
        // The open menu isn't in the element tree: its animation given time before the shot.
        sleep(1)
        shot("detail more menu")
        app.typeKey(.escape, modifierFlags: [])
        // Gives Escape time to leave the detail too; checked after that it didn't.
        sleep(2)
        if !element("detail.screen").exists { fail("Escape closing the More menu also left the detail") }
        shot("detail after the menu")
        app.typeKey(.escape, modifierFlags: [])
        if !element("detail.screen").waitForNonExistence(timeout: 10) { fail("Escape leaves the detail after its menu") }

        app.typeKey("2", modifierFlags: .command)
        require("libraries.screen", timeout: 30, "Libraries (⌘2)")
        // Lets Libraries' screen settle before Escape.
        sleep(2)
        app.typeKey(.escape, modifierFlags: [])
        require("home.screen", timeout: 10, "Escape at Libraries' root goes to Home")

        _ = waitUntil(5) { self.app.windows.firstMatch.buttons["_XCUI:FullScreenWindow"].isHittable }
        app.windows.firstMatch.buttons["_XCUI:FullScreenWindow"].click()
        if !waitUntil(10, { self.fullScreen }) { fail("the window's full screen button puts it in full screen") }
        // Lets the full screen animation finish before the shot.
        sleep(2)
        shot("home full screen")
        app.typeKey(.escape, modifierFlags: [])
        if !waitUntil(10, { !self.fullScreen }) { fail("Escape at Home's root leaves full screen") }
        // Gives Escape time to arm the exit; checked after that it didn't.
        sleep(1)
        if element("shell.exitPrompt").exists { fail("Escape at Home's root armed the exit") }
        app.typeKey(.escape, modifierFlags: [])
        // Gives Escape time to arm the exit or leave; checked after that it did neither.
        sleep(2)
        if element("shell.exitPrompt").exists { fail("a second Escape at Home's root armed the exit") }
        if app.state != .runningForeground { fail("Escape at Home's root left the app") }
        shot("home after escapes")
    }

    func testEscapeGoesBackAfterThePlayerCloses() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        require("nav.library.Shows", timeout: 30, "the sidebar's Shows").click()
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 30) { return fail("Shows lists no card") }
        click(card)
        require("detail.play", timeout: 30, "the show's Play").click()
        let video = require("player.video", timeout: 60, "the player")
        // The controls come up as the pointer moves over the video.
        video.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).hover()
        video.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
        require("player.back", timeout: 10, "the player's Close").click()
        if !video.waitForNonExistence(timeout: 10) { return fail("Close left the player up") }
        require("detail.screen", "the show's detail under the player")
        app.typeKey(.escape, modifierFlags: [])
        if !element("detail.screen").waitForNonExistence(timeout: 10) {
            return fail("Escape after the player closed left the detail up, focus on \(keyboardFocus)")
        }
        require("libraries.grid", timeout: 10, "Escape goes back to Shows' grid")
    }

    func testSidebarArrowsPickTheNextRow() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        // Libraries' rows: their screens leave the keys in the sidebar (Search's takes them into its field).
        require("nav.library.Home Videos", timeout: 30, "Home Videos' row").click()
        if !waitUntil(10, { self.shownLibrary.contains("Home Videos") }) { return fail("the click shows \(shownLibrary)") }
        app.typeKey(.downArrow, modifierFlags: [])
        if !waitUntil(5, { self.shownLibrary.contains("Movies") }) {
            return fail("Down from Home Videos' row shows \(shownLibrary), focus on \(keyboardFocus)")
        }
        app.typeKey(.upArrow, modifierFlags: [])
        if !waitUntil(5, { self.shownLibrary.contains("Home Videos") }) {
            return fail("Up from Movies' row shows \(shownLibrary), focus on \(keyboardFocus)")
        }
        gamepad("press=dpadDown")
        if !waitUntil(5, { self.shownLibrary.contains("Movies") }) { return fail("the D-pad's Down shows \(shownLibrary)") }
    }

    /// The library Libraries' header names.
    private var shownLibrary: String {
        let header = element("libraries.library")
        guard header.exists else { return "no library" }
        return [header.label, header.title, (header.value as? String) ?? ""].joined(separator: " ")
    }

    func testDiagonalScrollMovesOneAxis() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        // The card queried inside its row: the same item can show in another row (Continue Watching) under the same
        // identifier, so an app-wide lookup by it can find that copy instead.
        let card = rowCard()
        // Home's rows settle as the rest of its content comes, before the card's frame is read.
        sleep(3)
        let before = card.frame
        // Mostly down: the page scrolls, the row doesn't. A short scroll, so the row stays in the window for the next.
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).scroll(byDeltaX: -25, deltaY: -100)
        // Lets the scroll come to rest; checked after that the row didn't move.
        sleep(2)
        let down = card.frame
        if abs(down.minX - before.minX) > 2 { fail("a mostly vertical scroll moved the row from x \(before.minX) to \(down.minX)") }
        if abs(down.minY - before.minY) < 20 { fail("a mostly vertical scroll didn't move the page (y \(before.minY) to \(down.minY))") }
        shot("after a vertical diagonal scroll")
        // The row back in the window by straight vertical scrolls over the page, if that one took it out.
        let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 60)
        for _ in 0..<20 where !window.contains(card.frame) {
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
                .scroll(byDeltaX: 0, deltaY: card.frame.minY < window.minY ? 40 : -40)
            _ = waitUntil(1) { window.contains(card.frame) }
        }
        if !window.contains(card.frame) { fail("the row doesn't come back into the window (card at \(card.frame))") }
        let shown = card.frame
        // Mostly across: the row scrolls, the page doesn't.
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).scroll(byDeltaX: -300, deltaY: -60)
        // Lets the scroll come to rest; checked after that the page didn't move.
        sleep(2)
        let across = card.frame
        if abs(across.minY - shown.minY) > 2 { fail("a mostly horizontal scroll moved the page from y \(shown.minY) to \(across.minY)") }
        if abs(across.minX - shown.minX) < 20 { fail("a mostly horizontal scroll didn't move the row (x \(shown.minX) to \(across.minX))") }
        shot("after a horizontal diagonal scroll")
    }

    /// With the system's keyboard navigation on, the arrow keys move focus as an iPad's keyboard does: in a library's
    /// grid to the card beside or under the focused one and back, on Home down the page and up again, on a detail page
    /// from Play down to what lies under it and back up to Play.
    func testArrowsMoveFocusBetweenCards() throws {
        try requireKeyboardNavigation()
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "Home")
        _ = firstCard()
        // Home's rows settle as the rest of its content comes.
        sleep(3)
        click(element("nav.library.Movies"))
        _ = firstCard()
        // Movies' grid settles as the rest of its content comes, before Tab walks it.
        sleep(3)
        guard let start = tabToCard() else { return fail("Tab reaches no card in Movies: focus on \(keyboardFocus)") }
        let from = element(start).frame
        guard let right = arrow(.rightArrow) else { return fail("Right leaves focus on \(start) in Movies") }
        let beside = element(right).frame
        if !(beside.minX >= from.maxX - 1 && abs(beside.midY - from.midY) < from.height / 2) {
            fail("Right moves focus from \(start) at \(from) to \(right) at \(beside), not beside it")
        }
        shot("movies right")
        if arrow(.leftArrow) != start { fail("Left from \(right) doesn't come back to \(start): focus on \(keyboardFocus)") }
        guard let down = arrow(.downArrow) else { return fail("Down leaves focus on \(start) in Movies") }
        let under = element(down).frame
        if !(under.minY >= from.maxY - 1 && abs(under.midX - from.midX) < from.width / 2) {
            fail("Down moves focus from \(start) at \(from) to \(down) at \(under), not under it")
        }
        shot("movies down")
        if arrow(.upArrow) != start { fail("Up from \(down) doesn't come back to \(start): focus on \(keyboardFocus)") }

        click(element("nav.home"))
        require("home.screen", timeout: 30, "Home again")
        // Home settles as it comes back, before Tab walks it.
        sleep(2)
        guard let first = tabToCard() else { return fail("Tab reaches no card on Home: focus on \(keyboardFocus)") }
        var lower = first
        for _ in 0..<4 {
            guard let next = arrow(.downArrow) else { break }
            lower = next
        }
        if lower == first { fail("Down leaves focus on Home's \(first)") }
        // Its ring, a few points out, and its title under it show too.
        let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 24)
        _ = waitUntil(5) { window.contains(element(lower).frame) }
        if !window.contains(element(lower).frame) {
            fail("Down moves focus to \(lower) at \(element(lower).frame), not well inside the window (less 24 pt): the page didn't scroll to show it")
        }
        shot("home down")
        if arrow(.upArrow) == nil { fail("Up leaves focus on Home's \(lower)") }

        click(element("nav.library.Shows"))
        // Lets Shows replace Home's cards before one is picked.
        sleep(3)
        click(firstCard())
        require("detail.screen", timeout: 30, "a show's detail")
        _ = waitUntil(5) { element("detail.play").exists }
        for _ in 0..<10 where keyboardFocus != "detail.play" {
            app.typeKey(.tab, modifierFlags: [])
            _ = waitUntil(0.3) { keyboardFocus == "detail.play" }
        }
        guard keyboardFocus == "detail.play" else { return fail("Tab never reaches Play on the detail: focus on \(keyboardFocus)") }
        guard let below = arrow(.downArrow) else { return fail("Down leaves focus on the detail's Play") }
        shot("detail down")
        for _ in 0..<3 where keyboardFocus != "detail.play" { _ = arrow(.upArrow) }
        if keyboardFocus != "detail.play" { fail("Up from \(below) never comes back to Play: focus on \(keyboardFocus)") }
    }

    // MARK: - Steps

    /// Tab until a card has the keyboard's focus, 40 presses at most: the card, or nil.
    private func tabToCard() -> String? {
        for _ in 0..<40 where !keyboardFocus.hasPrefix("card.") {
            app.typeKey(.tab, modifierFlags: [])
            _ = waitUntil(0.3) { keyboardFocus.hasPrefix("card.") }
        }
        return keyboardFocus.hasPrefix("card.") ? keyboardFocus : nil
    }

    /// Presses an arrow key: what has the keyboard's focus after it, or nil when focus stayed (2 s).
    private func arrow(_ key: XCUIKeyboardKey) -> String? {
        let from = keyboardFocus
        app.typeKey(key, modifierFlags: [])
        if waitUntil(2, every: 0.1, { keyboardFocus != from }) { return keyboardFocus }
        return nil
    }

    /// The controller's D-pad down the screen until a card has focus.
    private func focusCard() {
        for _ in 0..<8 where !keyboardFocus.hasPrefix("card.") {
            gamepad("press=dpadDown")
        }
        if !keyboardFocus.hasPrefix("card.") { fail("the D-pad brings focus to no card: it is on \(keyboardFocus)") }
    }

    /// The controller's D-pad down the screen until a card that opens its detail has focus: not Continue Watching's,
    /// which play.
    private func focusOpeningCard() {
        for _ in 0..<10 where !keyboardFocus.hasPrefix("card.") || inContinueWatching(keyboardFocus) {
            gamepad("press=dpadDown")
        }
        if !keyboardFocus.hasPrefix("card.") || inContinueWatching(keyboardFocus) {
            fail("the D-pad brings focus to no card outside Continue Watching: it is on \(keyboardFocus)")
        }
    }

    /// A click at `element`'s middle, where it is whatever the accessibility hit test answers.
    private func click(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
    }

    private func inContinueWatching(_ id: String) -> Bool {
        element("hub.continue_watching").descendants(matching: .any).matching(identifier: id).firstMatch.exists
    }

    /// The first card of Home's longest row but Continue Watching (whose cards play), the page scrolled until it is
    /// wholly in the window, and kept there a moment: Home's rows still loading can take the page back to its top.
    private func rowCard() -> XCUIElement {
        let hubs = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'hub.' AND identifier != 'hub.continue_watching' AND NOT (identifier ENDSWITH '.viewAll')"
        ))
        if !hubs.firstMatch.exists(within: 60) { fail("Home shows no row but Continue Watching") }
        // Home's rows settle as the rest of its content comes.
        sleep(3)
        let isCard = NSPredicate(format: "identifier BEGINSWITH 'card.'")
        let rows = (0..<min(hubs.count, 10)).map { hubs.element(boundBy: $0) }
        guard let row = rows.max(by: {
            $0.descendants(matching: .any).matching(isCard).count < $1.descendants(matching: .any).matching(isCard).count
        }) else { fail("Home shows no row"); return hubs.firstMatch }
        let card = row.descendants(matching: .any).matching(isCard).firstMatch
        if !card.exists(within: 30) { fail("\(row.identifier) shows no card") }
        let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 60)
        // The scroll's sign is the page's: flipped once a scroll moves the card the wrong way.
        var delta: CGFloat = -200
        for _ in 0..<12 {
            if window.contains(card.frame) {
                // Kept in the window a moment: Home's rows still loading can take the page back to its top.
                sleep(1)
                if window.contains(card.frame) { return card }
                continue
            }
            let before = card.frame.minY
            let up = card.frame.maxY > window.maxY
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
                .scroll(byDeltaX: 0, deltaY: up ? delta : -delta)
            // Lets the scroll come to rest before the move is measured.
            sleep(1)
            let moved = card.frame.minY - before
            if (up && moved > 0) || (!up && moved < 0) { delta = -delta }
        }
        fail("\(card.identifier) never stayed wholly in the window")
        return card
    }

    /// An item menu: the shared one's entries (`menu.<entry>`), or a card's own (`card.<id>.menu.<n>`).
    private var menu: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(
            format: "(identifier BEGINSWITH 'menu.' AND identifier != 'menu.message') OR identifier CONTAINS '.menu.'"
        )).firstMatch
    }

    /// The first card wholly in the window.
    private func firstCard() -> XCUIElement {
        let cards = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        if !cards.firstMatch.exists(within: 60) { fail("Home shows no card") }
        let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 60)
        for index in 0..<min(cards.count, 30) {
            let card = cards.element(boundBy: index)
            if window.contains(card.frame) { return card }
        }
        return cards.firstMatch
    }

    /// The selected library's tabs, as the view menu lists them.
    private func viewMenuTabs() -> [String] {
        let menu = element("libraries.view")
        if !menu.exists(within: 60) { fail("Libraries shows no view menu") }
        // The header row settles as the screen opens: a click meanwhile can land beside the menu.
        sleep(2)
        menu.click()
        let options = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'libraries.view.option.'"))
        _ = options.firstMatch.exists(within: 10)
        let labels = (0..<options.count).compactMap { try? options.element(boundBy: $0).snapshot() }
            .map { $0.title.isEmpty ? $0.label : $0.title }
        app.typeKey(.escape, modifierFlags: [])
        _ = waitUntil(5) { !options.firstMatch.exists }
        return labels
    }

    /// The tab the view menu names as shown: its title on the Mac, where its label is empty.
    private func selectedTab(of tabs: [String]) -> Int {
        let menu = element("libraries.view")
        let shown = menu.label.isEmpty ? menu.title : menu.label
        return tabs.firstIndex { shown.hasSuffix($0) } ?? -1
    }

    private func expectTab(_ tabs: [String], _ index: Int, _ what: String) {
        if !waitUntil(5, { self.selectedTab(of: tabs) == index }) {
            fail("\(what): \(tabs) selects \(selectedTab(of: tabs)), not \(index)")
        }
    }

    /// The window fills its screen, as it does in full screen.
    private var fullScreen: Bool {
        guard let screen = NSScreen.main else { return false }
        let window = app.windows.firstMatch.frame
        return abs(window.width - screen.frame.width) < 2 && abs(window.height - screen.frame.height) < 2
    }
}
