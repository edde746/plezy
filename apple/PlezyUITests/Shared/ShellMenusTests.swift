import XCTest

/// The shell's menus and banners against the server `PLEZY_DEV_SERVER` names, `--dev-server`'s
/// `<kind>=<user>:<password>@<url>`: the profile menu (the sidebar's; Settings → Profiles without one), the session
/// expired banner (`--dev-revoke-token`), Server Tasks (`--dev-server-tasks`, the Mac and Apple TV), an item menu's
/// Show link, and a playlist's menus on Apple TV.
final class ShellMenusTests: PlezyUITestCase {
    private func server() throws -> String {
        try XCTUnwrap(ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 }, "PLEZY_DEV_SERVER names a server")
    }

    private func launchHome(_ extra: [String] = [], settings: [String] = []) throws {
        launchDev(settings: settings, arguments: ["--dev-server", try server()] + extra)
        require("home.screen", timeout: 60, "after the launch")
    }

    // MARK: - Profile menu

    /// The running profile's menu at the sidebar's foot (`nav.profile`, iPad and the Mac): Settings and Log out, whose
    /// question Cancel closes (on the Mac Return, Cancel being a destructive question's default). iPhone and Apple TV
    /// have no sidebar: their profiles are Settings → Profiles.
    func testProfileMenuOpens() throws {
        #if os(macOS)
        try launchHome()
        profileMenu()
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            try launchHome()
            profileMenu()
        } else {
            try profilesFromSettings()
        }
        #else
        try profilesFromSettings()
        #endif
    }

    #if !os(tvOS)
    private func profileMenu() {
        let button = element("nav.profile")
        #if os(iOS)
        // iPad's tab bar: its sidebar button shows the sidebar, the profile at its foot.
        if !button.exists(within: 5) {
            let toggle = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'sidebar'")).firstMatch
            XCTAssertTrue(toggle.exists(within: 5), "the tab bar's sidebar button")
            toggle.tap()
        }
        #endif
        require("nav.profile", timeout: 30, "the sidebar's profile")
        // Lets the sidebar finish showing before the shot.
        sleep(2)
        shot("home")
        press(button)
        #if os(macOS)
        // The open menu shows to the eye but not to the accessibility tree: shot from the screen, its Log out picked by
        // typing its title, as AppKit's menus take.
        sleep(1)
        shot("profile menu", of: XCUIScreen.main)
        app.typeText("Log out")
        app.typeKey(.return, modifierFlags: [])
        #else
        require("nav.profile.settings", timeout: 10, "the profile menu's Settings")
        let logout = require("nav.profile.logout", "the profile menu's Log out")
        shot("profile menu")
        activate(logout)
        #endif
        require("confirm.cancel", timeout: 10, "Log out's question")
        shot("log out question")
        #if os(macOS)
        app.typeKey(.return, modifierFlags: [])
        #else
        activate(element("confirm.cancel"))
        #endif
        XCTAssertFalse(element("confirm.cancel").exists(within: 2) && element("confirm.cancel").isHittable, "the question closes")
        require("home.screen", "Home after Cancel")
    }
    #endif

    #if !os(macOS)
    private func profilesFromSettings() throws {
        launchDev(arguments: ["--dev-server", try server(), "--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        // Once the launch's sign-in has ended (Settings offers Manage Libraries once the server's libraries are in).
        // Until then Settings changes under the press: the profile the sign-in makes active makes the shell anew, and
        // Manage Libraries comes in above Profiles.
        require("settings.row.manage_libraries", timeout: 60, "Settings once the launch's sign-in has ended")
        #if os(iOS)
        // Settings makes its rows as they scroll in: on a short screen (the iPhone Duo's cover) Profiles lies below it.
        for _ in 0..<4 where !element("settings.row.profiles").exists(within: 5) { app.swipeUp() }
        #endif
        let row = require("settings.row.profiles", timeout: 30, "Settings → Profiles")
        _ = waitUntil(5) { row.isHittable }
        shot("settings")
        activate(row)
        require("picker.screen", timeout: 15, "the profiles from Settings → Profiles")
        shot("profiles")
    }
    #endif

    // MARK: - Session expired banner

    func testRevokedTokenShowsTheBanner() throws {
        try launchHome(["--dev-revoke-token"])
        let banner = require("app.authBanner.expired", timeout: 60, "the session expired banner")
        // A Mac's text reads as its value, elsewhere as its label.
        let words = banner.label + " " + ((banner.value as? String) ?? "")
        XCTAssertTrue(words.contains("Session expired"), "the banner says the session expired: \(words)")
        shot("session expired banner")
        let signIn = require("app.authBanner.signIn", "Sign in again")
        #if os(tvOS)
        focus(signIn)
        XCUIRemote.shared.press(.select)
        #else
        press(signIn)
        #endif
        // The expired Jellyfin server's own sign-in, its password asked; the banner above it doesn't offer it again.
        require("addserver.screen", timeout: 15, "the server's sign-in after Sign in again")
        // Gives the banner time to settle over the sign-in; checked after that it doesn't offer Sign in again.
        sleep(1)
        shot("sign in again")
        if element("app.authBanner.expired").exists {
            XCTAssertFalse(element("app.authBanner.signIn").exists, "the banner offers Sign in again over its open sign-in")
        }
    }

    // MARK: - Server Tasks

    #if os(macOS) || os(tvOS)
    func testServerTasksPanelCancels() throws {
        try launchHome(["--dev-server-tasks"])
        let button = require("home.serverTasks", timeout: 30, "the Server Tasks button")
        #if os(tvOS)
        focus(button)
        XCUIRemote.shared.press(.select)
        #else
        // Home's rows and its Live TV chip arrive after the chip shows, moving it down and right: a click meanwhile
        // lands on the chip that moved under the pointer. Click once a card shows and the chip has held still a second.
        let cards = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        XCTAssertTrue(cards.firstMatch.exists(within: 30), "Home's rows load")
        var last = CGRect.null
        for _ in 0..<20 {
            let frame = button.frame
            if frame == last { break }
            last = frame
            sleep(1)
        }
        button.click()
        #endif
        #if os(tvOS)
        // Apple TV's side panel carries its own name (`appSheet`'s `TrailingPanel`).
        require("home.serverTasks.sheet", timeout: 10, "the Server Tasks panel")
        #else
        require("home.serverTasks.panel", timeout: 10, "the Server Tasks panel")
        #endif
        let cancels = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'home.serverTasks.cancel.'"))
        XCTAssertTrue(cancels.firstMatch.exists(within: 15), "a cancellable task")
        // Lets every task's row arrive and the focus land; nothing signals the last one.
        sleep(2)
        let before = cancels.count
        shot("server tasks panel (\(before) cancellable)")
        #if os(tvOS)
        let focused = cancels.matching(NSPredicate(format: "hasFocus == true")).firstMatch
        XCTAssertTrue(focused.exists, "a task's ✕ takes focus as the panel opens")
        requireFocusShows(on: focused, beside: cancels.matching(NSPredicate(format: "hasFocus == false")).firstMatch, "the focused ✕")
        #endif
        let cancel = cancels.firstMatch
        let id = cancel.identifier
        #if os(tvOS)
        focus(cancel)
        XCUIRemote.shared.press(.select)
        #else
        cancel.click()
        #endif
        let gone = NSPredicate(format: "exists == false")
        let result = XCTWaiter().wait(for: [expectation(for: gone, evaluatedWith: element(id))], timeout: 20)
        XCTAssertEqual(result, .completed, "the cancelled task \(id) leaves the panel")
        shot("after cancel (\(cancels.count) cancellable)")
    }
    #endif

    // MARK: - Item menu: Show link

    func testItemMenuShowsTheLink() throws {
        try launchHome()
        let card = try anyCard()
        shot("home")
        openMenu(on: card)
        let link = require("menu.show_link", timeout: 10, "the item menu's Show link")
        shot("item menu")
        activate(link)
        require("menu.link", timeout: 20, "the link dialog")
        require("menu.link.qr", "the link's QR code")
        let text = element("menu.link.text").label
        shot("link dialog \(text.prefix(60))")
        activate(element("menu.link.close"))
    }

    // MARK: - Playlist menus on Apple TV

    #if os(tvOS)
    func testPlaylistMenusOfferNoDownloads() throws {
        let server = try server()
        let kind = String(server.prefix { $0 != "=" })
        launchDev(arguments: ["--dev-server", server, "--dev-playlist", "\(kind):Binge"])
        require("playlist", timeout: 60, "the playlist's screen")
        let row = require("playlist.row.0", timeout: 30, "the playlist's first row")
        // From wherever focus starts (the header, a row's handle or ✕) onto the first row. The ✕ may not exist yet as the
        // screen fades in: asking a missing element for its focus fails the test.
        for _ in 0..<6 where !row.hasFocus {
            let onHeader = ["playlist.play", "playlist.shuffle", "playlist.delete"].contains { element($0).hasFocus }
            let remove = element("playlist.row.0.remove")
            let press: XCUIRemote.Button = onHeader ? .down : remove.exists && remove.hasFocus ? .left : .right
            XCUIRemote.shared.press(press)
            _ = waitUntil(0.5) { row.hasFocus }
        }
        XCTAssertTrue(row.hasFocus, "the first row takes focus")
        // Lets the focus animation finish before the shot.
        sleep(2)
        shot("playlist")
        XCUIRemote.shared.press(.select, forDuration: 1.2)
        require("menu.fileinfo", "the row's item menu")
        let downloads = app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS[c] 'download' OR label CONTAINS[c] 'download'"))
        XCTAssertEqual(downloads.count, 0, "no download entries: \(downloads.allElementsBoundByIndex.map(\.identifier))")
        shot("playlist row menu")
        XCUIRemote.shared.press(.menu)
    }
    #endif

    // MARK: - Helpers

    private func press(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #elseif os(tvOS)
        focus(element)
        XCUIRemote.shared.press(.select)
        #else
        element.tap()
        #endif
    }

    #if os(tvOS)
    /// Moves focus onto `target`, each press towards it from the focused control (never along the tab bar, which would
    /// change the tab).
    private func focus(_ target: XCUIElement) {
        for _ in 0..<16 where !holdsFocus(target) {
            let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
            guard let here = try? focused.snapshot(), let there = try? target.snapshot() else { break }
            let rowsOverlap = there.frame.minY < here.frame.maxY && here.frame.minY < there.frame.maxY
            let across = there.frame.midX - here.frame.midX, down = there.frame.midY - here.frame.midY
            XCUIRemote.shared.press(rowsOverlap ? (across > 0 ? .right : .left) : (down > 0 ? .down : .up))
            _ = waitUntil(0.5) { holdsFocus(target) }
        }
        XCTAssertTrue(holdsFocus(target), "\(target.identifier) takes focus")
    }

    /// Whether `target` has focus: itself, or the focused control around it (a list row).
    private func holdsFocus(_ target: XCUIElement) -> Bool {
        guard let there = try? target.snapshot() else { return false }
        if there.hasFocus { return true }
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        guard let here = try? focused.snapshot(), !here.frame.isEmpty else { return false }
        // The focused control around it (a list row around the row's label), not a whole page.
        return here.frame.insetBy(dx: -4, dy: -4).contains(there.frame) && here.frame.height < app.frame.height / 2
    }
    #endif

    /// A Home card wholly on screen (on Apple TV the first one focus reaches).
    private func anyCard() throws -> XCUIElement {
        #if os(tvOS)
        for _ in 0..<10 {
            let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'card.'")).firstMatch
            if focused.exists { return focused }
            XCUIRemote.shared.press(.right)
            // Paces the presses so the focus engine takes each one.
            usleep(600_000)
            XCUIRemote.shared.press(.down)
            usleep(600_000)
        }
        #else
        let cards = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        // One whose upper part (where the menu's press goes) is inside the window, scrolling Home down to its rows.
        for _ in 0..<5 where cards.firstMatch.exists(within: 30) {
            let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 20)
            for index in 0..<min(cards.count, 30) {
                let card = cards.element(boundBy: index)
                guard card.exists else { continue }
                let frame = card.frame
                let upper = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height * 0.6)
                if !frame.isEmpty, window.contains(upper) { return card }
            }
            #if os(macOS)
            element("home.screen").scroll(byDeltaX: 0, deltaY: -200)
            #else
            app.swipeUp()
            #endif
            // Lets the scroll come to rest before the cards' frames are read.
            sleep(1)
        }
        #endif
        fail("no Home card")
        throw XCTSkip("unreachable")
    }

    private func openMenu(on target: XCUIElement) {
        #if os(macOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).rightClick()
        #elseif os(tvOS)
        XCUIRemote.shared.press(.select, forDuration: 1.2)
        #else
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.0)
        #endif
    }

    private func activate(_ target: XCUIElement) {
        #if os(macOS)
        target.click()
        #elseif os(tvOS)
        for direction in [XCUIRemote.Button.down, .up, .right, .left] {
            for _ in 0..<16 where !holdsFocus(target) {
                XCUIRemote.shared.press(direction)
                _ = waitUntil(0.3) { holdsFocus(target) }
            }
        }
        XCTAssertTrue(holdsFocus(target), "\(target.identifier) takes focus")
        XCUIRemote.shared.press(.select)
        #else
        target.tap()
        #endif
        // Lets what the press opens or closes finish its transition; a closing question still reads as hittable.
        sleep(2)
    }
}
