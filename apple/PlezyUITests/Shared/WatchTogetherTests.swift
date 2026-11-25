import XCTest

/// Watch Together's screens. `PLEZY_DEV_SERVER` (`--dev-server`'s `<kind>=<user>:<password>@<url>`) gives the session
/// its profile for the Home test; `PLEZY_WATCH_RELAY` (`TEST_ENV` `WATCH_RELAY=<url>`, passed as the device setting
/// `watch_party_relay_url`) is a relay the device reaches, for the room test, skipped without one.
///
/// - Home's Watch Together action opens the lobby (iPhone, iPad, Mac: a tap; Apple TV: the remote moves focus to it),
///   Create Room focused; the join sheet formats a typed code, and Cancel closes it.
/// - A room made from the launch (`--dev-watch-room <code>`: the session opens the screen and hosts the room of a new
///   code), its code shown as `K7M-Q2X`; Leave asks first, and the lobby lists the room under Recent Rooms. Create Room
///   makes another room with the user as host, its code's card focused on Apple TV, white with the focus. On Apple TV a
///   room opens with every control of it on screen, the very large code beside them.
/// - In a room the player plays `PLEZY_PLAY` (`--dev-play`'s `<server>:<item>`, with the server): the room pill counts
///   the host and opens the session (a sheet; on Apple TV the Options menu's page), whose participants and offset open
///   as its pages.
final class WatchTogetherTests: PlezyUITestCase {
    private static let environment = ProcessInfo.processInfo.environment

    private static var relay: String? { environment["PLEZY_WATCH_RELAY"].flatMap { $0.isEmpty ? nil : $0 } }

    func testHomeLobbyAndJoinSheet() throws {
        guard let server = Self.environment["PLEZY_DEV_SERVER"].flatMap({ $0.isEmpty ? nil : $0 }) else {
            throw XCTSkip("needs PLEZY_DEV_SERVER")
        }
        launchDev(settings: Self.relay.map { ["watch_party_relay_url=\($0)"] } ?? [], arguments: ["--dev-server", server])
        let button = require("home.watchTogether", timeout: 60, "Home's Watch Together action")
        // The sign-in finishes after Home shows: a press meanwhile can go to the Home it replaces.
        Thread.sleep(forTimeInterval: 5)
        let create = element("watch.create")
        for _ in 0..<3 where !create.exists(within: 5) {
            #if os(tvOS)
            moveFocus(to: "home.watchTogether", "Home's Watch Together action")
            shot("home-focus")
            press(.select)
            #else
            shot("home")
            tap(button)
            #endif
        }
        require("watch.create", "the lobby's Create Room")
        // Lets the lobby's appearance finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("lobby")
        #if os(tvOS)
        requireFocus("watch.create", "the lobby focuses Create Room")
        #endif
        #if os(iOS)
        // The lobby's buttons clear the floating tab bar, the phone upright and on its side.
        assertLobbyClearsTabBar("portrait")
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCUIDevice.shared.orientation = .landscapeLeft
            _ = waitUntil(5) { let bounds = self.app.windows.firstMatch.frame; return bounds.width > bounds.height }
            shot("lobby-landscape")
            assertLobbyClearsTabBar("landscape")
            XCUIDevice.shared.orientation = .portrait
            _ = waitUntil(5) { let bounds = self.app.windows.firstMatch.frame; return bounds.height > bounds.width }
        }
        #endif

        // The join sheet formats what is typed.
        activate("watch.join")
        let field = require("watch.join.field", timeout: 10, "the join sheet's field")
        type("k7m q2x", into: field)
        _ = waitUntil(5) { field.value as? String == "K7M-Q2X" }
        XCTAssertEqual(field.value as? String, "K7M-Q2X", "a typed code shows as K7M-Q2X")
        shot("join-sheet")
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #else
        activate("watch.join.cancel")
        #endif
        XCTAssertTrue(field.waitForNonExistence(timeout: 10), "Cancel closes the join sheet")
    }

    func testRoomLeaveAndCreate() throws {
        guard let relay = Self.relay else { throw XCTSkip("needs PLEZY_WATCH_RELAY") }
        let code = Self.newCode()
        launchDev(settings: ["watch_party_relay_url=\(relay)"], arguments: ["--dev-watch-room", code])
        let shown = require("watch.code", timeout: 60, "the room's code")
        // The Mac reports a text's string as its value, iOS and tvOS as its label.
        let text = shown.label.isEmpty ? shown.value as? String ?? "" : shown.label
        XCTAssertEqual(text, "\(code.prefix(3))-\(code.suffix(3))", "the code shows as K7M-Q2X")
        // Lets the room's appearance finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("room-host")
        reveal("watch.leave", "Leave Room")
        shot("room-host-bottom")

        // Leave asks first; the lobby then lists the room.
        activate("watch.leave")
        let confirm = require("watch.leave.confirm", timeout: 10, "Leave's question")
        shot("leave-question")
        #if os(tvOS)
        // The question opens on Cancel, not on Leave; the remote's Menu closes it, the room going on.
        requireFocus("watch.leave.cancel", "Leave's question focuses Cancel")
        press(.menu)
        if !confirm.waitForNonExistence(timeout: 10) { fail("Menu leaves Leave's question up") }
        require("watch.code", timeout: 5, "the room, still on after Menu")
        activate("watch.leave")
        require("watch.leave.confirm", timeout: 10, "Leave's question again")
        #endif
        activate(confirm)
        require("watch.create", timeout: 20, "the lobby after leaving")
        require("watch.recent.\(code)", timeout: 10, "the room under Recent Rooms")
        // Lets the lobby's appearance finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("lobby-recent")

        // Create Room: a room of its own, the user its host.
        activate("watch.create")
        require("watch.code", timeout: 60, "the created room's code")
        // Lets the room's appearance finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("room-created")
        #if os(tvOS)
        // The card is focusable, and reports its focus on one of its texts.
        let header = require("watch.header", "the code's card")
        if !header.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.exists(within: 10) {
            fail("a room focuses its code's card: focus is on \(focused.exists ? focused.identifier : "nothing")")
        }
        let participant = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'watch.participant.'")).firstMatch
        requireFocusShows(on: header, beside: participant, "the code's focused card")
        #endif
        reveal("watch.end", "the host's End Room")
    }

    #if os(tvOS)
    /// Apple TV: a room opens with every control of it on screen, whole, the code beside them and the largest text
    /// there: the code's card, the media, the participant, the host's two settings, Leave Room and End Room.
    func testRoomOpensWithEveryControlOnScreen() throws {
        guard let relay = Self.relay else { throw XCTSkip("needs PLEZY_WATCH_RELAY") }
        launchDev(settings: ["watch_party_relay_url=\(relay)"], arguments: ["--dev-watch-room", Self.newCode()])
        let code = require("watch.code", timeout: 60, "the room's code")
        require("watch.end", timeout: 10, "the host's End Room")
        _ = waitUntil(5) {
            let bounds = self.app.windows.firstMatch.frame
            return ["watch.header", "watch.media", "watch.everyone", "watch.lock", "watch.leave", "watch.end"].allSatisfy {
                let frame = self.element($0).frame
                return !frame.isEmpty && bounds.contains(frame)
            }
        }
        shot("room-open")
        let window = app.windows.firstMatch.frame
        let participant = requirePrefix("watch.participant.", timeout: 5, "the host's row")
        let controls = ["watch.header", "watch.media", "watch.everyone", "watch.lock", "watch.leave", "watch.end"].map { element($0) } + [participant]
        for control in controls {
            let frame = control.frame
            XCTAssertTrue(!frame.isEmpty && window.contains(frame), "\(control.identifier) whole on screen as the room opens: \(frame) in \(window)")
        }
        let tallest = app.staticTexts.allElementsBoundByIndex.filter { $0.identifier != "watch.code" }.map(\.frame.height).max() ?? 0
        XCTAssertGreaterThan(code.frame.height, tallest, "the code is the largest text on screen")
    }
    #endif

    #if os(iOS)
    /// An iPhone in landscape: the side safe areas inset the screen's form once. The tab bar floats at the foot, so the
    /// form spans the window, and the system's form keeps each row inside the side's safe area plus its own margin:
    /// as far from the left edge as from the right, more than the safe area (44 pt at least, 59-62 pt with a Dynamic
    /// Island) and less than twice it.
    func testLandscapeSideSafeAreaInsetsOnce() throws {
        guard let relay = Self.relay else { throw XCTSkip("needs PLEZY_WATCH_RELAY") }
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("an iPhone's landscape") }
        XCUIDevice.shared.orientation = .landscapeLeft
        launchDev(settings: ["watch_party_relay_url=\(relay)"], arguments: ["--dev-watch-room", Self.newCode()])
        require("watch.code", timeout: 60, "the room's code")
        XCUIDevice.shared.orientation = .landscapeLeft
        _ = waitUntil(5) { let bounds = self.app.windows.firstMatch.frame; return bounds.width > bounds.height }
        let window = app.windows.firstMatch.frame
        if window.width <= window.height { throw XCTSkip("the app's window stays portrait (\(window)): no landscape here") }
        // The form builds its rows lazily: scroll it up (the form itself, slowly: a swipe down here can land as the
        // edge's back gesture) until the host's row is on screen.
        let screen = element("watch.screen")
        let participant = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "watch.participant.")).firstMatch
        for _ in 0..<8 where !(participant.exists && participant.isHittable) {
            screen.swipeUp(velocity: .slow)
            _ = waitUntil(0.5) { participant.exists && participant.isHittable }
        }
        if !participant.exists { fail("the host's row: no watch.participant.…") }
        shot("landscape-room")
        let row = participant.frame
        let left = row.minX - window.minX, right = window.maxX - row.maxX
        XCTAssertEqual(left, right, accuracy: 2, "the row sits as far in from either side: \(row) in \(window)")
        XCTAssertGreaterThan(left, 44, "the row keeps clear of the side's safe area: \(left)")
        XCTAssertLessThan(left, 88, "the side's safe area applies once, not twice: \(left)")
    }

    /// At accessibility text size L on iPhone, in portrait and landscape, the lobby ends clear of the floating tab bar
    /// and Create Room scrolls clear of it.
    func testLargeTextLobbyClearsTheTabBar() throws {
        guard let server = Self.environment["PLEZY_DEV_SERVER"].flatMap({ $0.isEmpty ? nil : $0 }) else {
            throw XCTSkip("needs PLEZY_DEV_SERVER")
        }
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("iPhone's floating tab bar") }
        launchDev(arguments: ["--dev-server", server, "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
        let button = require("home.watchTogether", timeout: 60, "Home's Watch Together action")
        // The sign-in finishes after Home shows: a press meanwhile can go to the Home it replaces.
        Thread.sleep(forTimeInterval: 5)
        let create = element("watch.create")
        for _ in 0..<3 where !create.exists(within: 5) { tap(button) }
        require("watch.create", "the lobby's Create Room")
        try requireBottomTabBar()
        let screen = element("watch.screen")
        for (orientation, name) in [(UIDeviceOrientation.portrait, "portrait"), (.landscapeLeft, "landscape")] {
            XCUIDevice.shared.orientation = orientation
            _ = waitUntil(5) {
                let bounds = self.app.windows.firstMatch.frame
                return (bounds.width > bounds.height) == (orientation == .landscapeLeft)
            }
            shot("large text \(name) lobby")
            requireEndClearsTabBar(screen, "the lobby in \(name) at large text")
            shot("large text \(name) lobby end")
            scrollClearOfTabBar(create, in: screen, "Create Room in \(name) at large text")
        }
    }

    /// An iPhone on its side: a failed Create Room's error shows in the lobby clear of the floating tab bar, with the
    /// buttons. The relay is a closed port, so Create Room fails.
    func testLandscapeLobbyFailureClearsTheTabBar() throws {
        guard let server = Self.environment["PLEZY_DEV_SERVER"].flatMap({ $0.isEmpty ? nil : $0 }) else {
            throw XCTSkip("needs PLEZY_DEV_SERVER")
        }
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("an iPhone's landscape") }
        launchDev(settings: ["watch_party_relay_url=http://127.0.0.1:9"], arguments: ["--dev-server", server])
        let button = require("home.watchTogether", timeout: 60, "Home's Watch Together action")
        // The sign-in finishes after Home shows: a press meanwhile can go to the Home it replaces.
        Thread.sleep(forTimeInterval: 5)
        let create = element("watch.create")
        for _ in 0..<3 where !create.exists(within: 5) { tap(button) }
        require("watch.create", "the lobby's Create Room")
        try requireBottomTabBar()
        XCUIDevice.shared.orientation = .landscapeLeft
        _ = waitUntil(5) { let bounds = self.app.windows.firstMatch.frame; return bounds.width > bounds.height }
        let window = app.windows.firstMatch.frame
        if window.width <= window.height { throw XCTSkip("the app's window stays portrait (\(window)): no landscape here") }
        activate("watch.create")
        let error = require("watch.error", timeout: 30, "Create Room's failure")
        _ = waitUntil(5) { window.contains(error.frame) && error.frame.maxY <= self.tabBarTop() + 1 }
        shot("landscape lobby failure")
        let frame = error.frame
        XCTAssertTrue(window.contains(frame), "the failure whole on screen: \(frame) in \(window)")
        XCTAssertLessThanOrEqual(frame.maxY, tabBarTop() + 1, "the failure clear of the tab bar: \(frame), bar top \(tabBarTop())")
        assertLobbyClearsTabBar("landscape after the failure")
        XCUIDevice.shared.orientation = .portrait
    }
    #endif

    func testPlayerPillAndSessionSheet() throws {
        guard let relay = Self.relay, let server = Self.environment["PLEZY_DEV_SERVER"].flatMap({ $0.isEmpty ? nil : $0 }),
              let play = Self.environment["PLEZY_PLAY"].flatMap({ $0.isEmpty ? nil : $0 }) else {
            throw XCTSkip("needs PLEZY_WATCH_RELAY, PLEZY_DEV_SERVER and PLEZY_PLAY")
        }
        launchDev(
            settings: ["watch_party_relay_url=\(relay)"],
            arguments: ["--dev-server", server, "--dev-watch-room", Self.newCode(), "--dev-play", play]
        )
        require("player.video", timeout: 120, "the player opening on \(play)")
        let pill = roomPill()
        _ = waitUntil(5) { (pill.value as? String ?? "").hasPrefix("1 ") }
        XCTAssertTrue((pill.value as? String ?? "").hasPrefix("1 "), "the pill counts the host alone")
        shot("player-pill")
        #if os(tvOS)
        moveFocus(to: "player.watch", "the room pill")
        press(.select)
        require("watch.sheet.media", timeout: 10, "the session's media row")
        // Lets the panel's appearance finish before the screenshot.
        sleep(1)
        shot("session-panel")
        moveFocus(to: "watch.sheet.participants", "the participants row")
        press(.select)
        require("watch.page.title", timeout: 10, "the participants page")
        shot("session-participants")
        press(.menu)
        require("watch.sheet.media", timeout: 10, "Menu goes back to the session's first page")
        #else
        tap(roomPill())
        require("watch.sheet.code", timeout: 10, "the session sheet's code row")
        require("watch.sheet.copy", timeout: 5, "the session sheet's Copy Code row")
        // Lets the sheet's presentation finish before the screenshot.
        sleep(1)
        shot("session-sheet")
        tap(require("watch.sheet.participants", timeout: 5, "the participants row"))
        requirePrefix("watch.participant.", timeout: 5, "a participant")
        // Lets the page's push finish before the screenshot.
        sleep(1)
        shot("session-participants")
        #if os(macOS)
        // The page's back button, in the sheet's toolbar (the run is in English).
        let back = app.sheets.firstMatch.buttons.matching(NSPredicate(format: "label == 'Back' OR identifier == 'BackButton'")).firstMatch
        (back.exists(within: 5) ? back : app.sheets.firstMatch.toolbars.buttons.firstMatch).click()
        #else
        // The page's back button, in its bar (titled as the page is; the run is in English).
        app.navigationBars["Participants"].buttons.firstMatch.tap()
        #endif
        tap(require("watch.sheet.offset", timeout: 5, "the offset row"))
        require("watch.offset.reset", timeout: 5, "the offset page's Reset")
        // Lets the page's push finish before the screenshot.
        sleep(1)
        shot("session-offset")
        #endif
    }

    /// The room pill among the player's controls, raised again while they go down (they hide after a few idle
    /// seconds, before the room has connected).
    private func roomPill() -> XCUIElement {
        let pill = element("player.watch")
        for _ in 0..<20 {
            raiseControls()
            if pill.exists(within: 3) { return pill }
        }
        fail("the room pill: no player.watch")
        return pill
    }

    /// Shows the player's controls if they went down: Up on Apple TV (Select would pause), the pointer moved over the
    /// video on the Mac, a tap on the video on iOS.
    private func raiseControls() {
        #if os(tvOS)
        if element("player.watch").exists { return }
        press(.up)
        #elseif os(macOS)
        let video = element("player.video")
        // Somewhere else each time: the controls answer the pointer moving.
        let x = CGFloat.random(in: 0.3...0.7), y = CGFloat.random(in: 0.3...0.7)
        video.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).hover()
        #else
        let control = element("player.playPause")
        if control.exists && control.isHittable { return }
        tap(element("player.video"))
        #endif
    }

    /// Waits for an element whose identifier starts with `id`.
    @discardableResult
    private func requirePrefix(_ id: String, timeout: TimeInterval, _ what: String) -> XCUIElement {
        let found = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", id)).firstMatch
        if !found.exists(within: timeout) { fail("\(what): no \(id)… after \(Int(timeout)) s") }
        return found
    }

    /// A code nobody has: six symbols of the relay's alphabet (no 0, 1, I, L or O).
    private static func newCode() -> String {
        let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement()! })
    }

    /// Presses the element `id` names: a tap or click; on Apple TV focus moves to it and Select presses it.
    private func activate(_ id: String) {
        activate(reveal(id, id))
    }

    /// The element `id` names, the page scrolled down (on Apple TV, focus moved down) until the lazy form has built it.
    @discardableResult
    private func reveal(_ id: String, _ what: String) -> XCUIElement {
        let found = element(id)
        for _ in 0..<8 where !found.exists(within: 1) {
            #if os(tvOS)
            press(.down)
            #elseif os(macOS)
            app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: -300)
            #else
            app.swipeUp()
            #endif
        }
        if !found.exists(within: 5) { fail("\(what): no \(id)") }
        return found
    }

    private func activate(_ element: XCUIElement) {
        #if os(tvOS)
        moveFocus(to: element.identifier, element.identifier)
        press(.select)
        #else
        tap(element)
        #endif
    }

    private func type(_ text: String, into field: XCUIElement) {
        #if os(tvOS)
        // The field has focus as the sheet opens: Select opens the keyboard.
        requireFocus(field.identifier, timeout: 5, "the join field has focus")
        press(.select)
        let keyboard = app.keyboards.firstMatch
        if !keyboard.exists(within: 5) { fail("Select on the join field opens no keyboard") }
        app.typeText(text)
        for _ in 0..<3 where keyboard.exists {
            press(.menu)
        }
        #elseif os(macOS)
        field.click()
        field.typeText(text)
        #else
        field.tap()
        field.typeText(text)
        #endif
    }

    #if os(tvOS)
    private func press(_ button: XCUIRemote.Button) {
        XCUIRemote.shared.press(button)
        // Paces the presses: the focus engine drops presses that come too close together.
        Thread.sleep(forTimeInterval: 0.6)
    }

    private var focused: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
    }

    /// `target` has focus: itself, an element inside it (a system menu's or a card's text), or an unnamed element over
    /// it (an alert's button reports its focus on a twin without the identifier).
    private func hasFocus(_ target: XCUIElement) -> Bool {
        if target.hasFocus { return true }
        if target.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.exists { return true }
        let now = focused
        return now.exists && now.identifier.isEmpty && now.frame == target.frame
    }

    private func requireFocus(_ id: String, timeout: TimeInterval = 10, _ what: String) {
        let target = element(id)
        if waitUntil(timeout, every: 0.5, { target.exists && self.hasFocus(target) }) { return }
        fail("\(what): focus is on \(focused.exists ? focused.identifier : "nothing"), not \(id)")
    }

    /// Moves focus with the remote toward `id` until it has it: each press goes the way the target lies from the
    /// focused element (out of the tab bar first, then sideways to a column beside it, as Apple TV's room has the code's
    /// card left of its form, then up or down, then sideways).
    private func moveFocus(to id: String, _ what: String) {
        let target = element(id)
        guard target.exists(within: 10) else { return fail("\(what): no \(id)") }
        for _ in 0..<24 {
            if hasFocus(target) { return }
            let now = focused
            let to = target.frame, from = now.exists ? now.frame : .zero
            let direction: XCUIRemote.Button
            if to.isEmpty {
                // Not laid out yet: further down the lazy form.
                direction = .down
            } else if now.exists, now.identifier.hasPrefix("nav."), to.minY > from.maxY {
                direction = .down
            } else if now.exists, to.minX >= from.maxX - 1 {
                direction = .right
            } else if now.exists, to.maxX <= from.minX + 1 {
                direction = .left
            } else if to.minY >= from.maxY - 1 {
                direction = .down
            } else if to.maxY <= from.minY + 1 {
                direction = .up
            } else {
                direction = to.midX > from.midX ? .right : .left
            }
            press(direction)
        }
        if !hasFocus(target) { fail("\(what): focus is on \(focused.exists ? focused.identifier : "nothing"), not \(id)") }
    }
    #else
    private func tap(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }
    #endif

    #if os(iOS)
    /// The lobby's Create Room and Join Room are on screen whole and clear of the floating tab bar, as the screen is now
    /// (`orientation` names it in the failure).
    private func assertLobbyClearsTabBar(_ orientation: String) {
        let window = app.windows.firstMatch.frame
        let bar = app.tabBars.firstMatch
        for id in ["watch.create", "watch.join"] {
            let button = element(id)
            guard button.exists(within: 5) else { return fail("\(orientation): \(id) on screen") }
            let frame = button.frame
            XCTAssertTrue(window.contains(frame), "\(orientation): \(id) whole on screen: \(frame) in \(window)")
            if bar.exists && bar.isHittable {
                XCTAssertFalse(frame.intersects(bar.frame), "\(orientation): \(id) clear of the tab bar: \(frame), bar \(bar.frame)")
            }
        }
    }
    #endif
}
