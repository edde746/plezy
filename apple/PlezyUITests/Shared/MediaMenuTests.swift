#if os(macOS)
import AppKit
#endif
import XCTest

/// Items' menus and a playlist's screen against the server `PLEZY_DEV_SERVER` names (`--dev-server`'s
/// `<kind>=<user>:<password>@<url>`, the default seeded Jellyfin or Emby). A Home card of the alphabet catalog (a movie no
/// other seed touches) opens its menu (a long press, Select held on Apple TV, a right click on the Mac); Mark as Watched
/// and Mark as Unwatched each go round, the menu reopened after each offering the other, so the server ends as it
/// started. The playlist Binge opens (`--dev-playlist`) with its rows, and a row's menu opens. On Apple TV the closed
/// menu gives focus back to the playlist's row that opened it.
final class MediaMenuTests: PlezyUITestCase {
    /// The alphabet catalog's titles: Alpha Archive … Zulu Zone 4.
    private static let titles =
        "^(Alpha|Bravo|Charlie|Delta|Echo|Foxtrot|Golf|Hotel|India|Juliett?|Kilo|Lima|Mike|November|Oscar|Papa|Quebec|Romeo|Sierra|Tango|Uniform|Victor|Whiskey|X-?ray|Yankee|Zulu) .*"
    private static let catalog = NSPredicate(format: "identifier BEGINSWITH 'card.' AND label MATCHES %@", titles)

    private func server() throws -> String {
        try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
    }

    func testMarksAHomeCardWatchedAndBack() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "after the launch")
        let card = try catalogCard()
        let title = card.label
        let id = card.identifier
        shot("home")

        // The menu offers one mark or the other.
        let first = openMenu(on: card, showing: ["menu.unwatch", "menu.watch"], "the menu of \(title)")
        let second = first == "menu.unwatch" ? "menu.watch" : "menu.unwatch"
        #if os(iOS)
        XCTAssertTrue(element("menu.title").exists, "the menu names what it acts on")
        #elseif os(tvOS)
        _ = waitUntil(5) { self.entryHasFocus(self.element(first)) }
        XCTAssertTrue(entryHasFocus(element(first)), "the system's menu opens with focus on its first entry")
        #endif
        shot("menu")
        activate(element(first))
        require("menu.message", timeout: 15, "the mark's message")
        shot("marked")

        openMenu(on: hittable(id) ?? card, showing: [second], "the reopened menu of \(title) offering the other mark")
        XCTAssertFalse(element(first).exists, "the reopened menu still offers \(first)")
        shot("menu after the mark")
        activate(element(second))
        require("menu.message", timeout: 15, "the second mark's message")

        openMenu(on: hittable(id) ?? card, showing: [first], "the menu of \(title) back where it started")
        shot("menu after the round trip")
        dismissMenu()
        XCTAssertFalse(element(first).exists(within: 1) && element(first).isHittable, "the menu closes")
        #if os(tvOS)
        XCTAssertNotNil(focusedCard(id), "focus comes back to \(title) as its dismissed menu closes")
        #endif
    }

    #if os(macOS)
    /// On the Mac a Control-click on a card opens its menu as a right click does, and doesn't open the card; a plain
    /// click on it still opens it.
    func testControlClickOpensACardsMenuNotTheCard() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "after the launch")
        let card = try catalogCard()
        let title = card.label
        let point = card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        XCUIElement.perform(withKeyModifiers: .control) { point.click() }
        sleep(1)
        if !(element("menu.watch").exists(within: 10) || element("menu.unwatch").exists) {
            fail("a Control-click on \(title) opens no menu")
        }
        shot("control-click menu")
        XCTAssertFalse(element("detail.screen").exists, "the Control-click opened \(title) too")
        dismissMenu()
        point.click()
        require("detail.screen", timeout: 20, "a click on \(title) opens it")
    }
    #endif

    #if !os(tvOS)
    /// A card offers VoiceOver a Show menu action. On the Mac the action opens the card's menu at the card, where
    /// VoiceOver's focus is, wherever the pointer is; on iOS, where XCUITest can only list an element's custom actions,
    /// the action is listed.
    func testCardOffersAShowMenuAction() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "after the launch")
        let card = try catalogCard()
        let title = card.label
        #if os(macOS)
        // The pointer away from the card, in the window's bottom-left corner.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.98)).hover()
        let cardFrame = card.frame
        try performCustomAction("Show menu", on: card)
        if !(element("menu.watch").exists(within: 10) || element("menu.unwatch").exists) {
            fail("Show menu on \(title) opens no menu")
        }
        let menuFrame = app.menus.firstMatch.frame
        shot("show menu action")
        XCTAssertTrue(menuFrame.insetBy(dx: -2, dy: -2).intersects(cardFrame), "the menu at \(menuFrame) is at \(title) at \(cardFrame)")
        dismissMenu()
        #else
        let actions = try customActions(of: card)
        XCTAssertTrue(actions.contains("Show menu"), "\(title)'s actions \(actions) offer Show menu")
        #endif
    }

    /// XCUITest's own accessibility interface (private: XCUITest has no API for custom actions, and its runner may not
    /// use the accessibility API itself) and `element`'s accessibility element there.
    private func accessibility(of element: XCUIElement) throws -> (interface: AnyObject, target: AnyObject) {
        let target = try XCTUnwrap((try element.snapshot() as AnyObject).value(forKey: "accessibilityElement") as AnyObject?)
        return (XCUIDevice.shared.value(forKey: "accessibilityInterface") as AnyObject, target)
    }

    #if os(macOS)
    /// Performs `element`'s accessibility custom action `name` as VoiceOver does, by the name AppKit gives it.
    private func performCustomAction(_ name: String, on element: XCUIElement) throws {
        let (interface, target) = try accessibility(of: element)
        let actionClass = try XCTUnwrap(NSClassFromString("XCUIAccessibilityAction"), "XCUITest's action class") as AnyObject
        let action = actionClass.perform(NSSelectorFromString("alloc")).takeUnretainedValue()
            .perform(NSSelectorFromString("initWithActionName:"), with: "Name:\(name)\nTarget:0x0\nSelector:(null)")
            .takeUnretainedValue()
        typealias Perform = @convention(c) (AnyObject, Selector, AnyObject, AnyObject, AnyObject?, UnsafeMutablePointer<NSError?>?) -> Bool
        let selector = NSSelectorFromString("performAction:onElement:value:error:")
        let perform = unsafeBitCast(interface.method(for: selector), to: Perform.self)
        var error: NSError?
        XCTAssertTrue(perform(interface, selector, action, target, nil, &error), "\(name) on \(element.label): \(error.map { "\($0)" } ?? "")")
    }
    #else
    /// The names of `element`'s accessibility custom actions.
    private func customActions(of element: XCUIElement) throws -> [String] {
        let (interface, target) = try accessibility(of: element)
        typealias Attributes = @convention(c) (AnyObject, Selector, AnyObject, NSArray, UnsafeMutablePointer<NSError?>?) -> NSDictionary?
        let selector = NSSelectorFromString("attributesForElement:attributes:error:")
        let attributes = unsafeBitCast(interface.method(for: selector), to: Attributes.self)
        var error: NSError?
        let key = "XC_kAXXCAttributeCustomActions"
        let values = try XCTUnwrap(attributes(interface, selector, target, [key] as NSArray, &error), "\(error.map { "\($0)" } ?? "")")
        return ((values[key] as? [NSDictionary]) ?? []).compactMap { $0["CustomActionName"] as? String }
    }
    #endif
    #endif

    /// A Home card's File info (every Home row is of movies, episodes or clips, which all have it): the item's title and
    /// chips, then every version's cards; a tap on the path copies it and says so (Apple TV: no pasteboard, so the
    /// remote walks the fields instead; the Mac: the path shows and takes a click, never given one, as the Mac's
    /// pasteboard belongs to whoever works at it).
    func testShowsAHomeCardsFileInfo() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "after the launch")
        #if os(tvOS)
        let card = try walk { _ in true }
        #else
        let cards = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        var found: XCUIElement?
        for _ in 0..<30 where found == nil {
            let window = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 60)
            for index in 0..<min(cards.count, 80) {
                // A row lets cards go as Home scrolls: one gone since the count is skipped.
                let candidate = cards.element(boundBy: index)
                guard candidate.exists else { continue }
                let frame = candidate.frame
                if !frame.isEmpty, window.contains(CGPoint(x: frame.midX, y: frame.midY)) {
                    found = app.descendants(matching: .any).matching(identifier: candidate.identifier).firstMatch
                    break
                }
            }
            guard found == nil else { break }
            // The hero can fill the first screen: Home a little further down.
            #if os(macOS)
            if cards.count > 0 { element("home.screen").scroll(byDeltaX: 0, deltaY: -200) }
            #else
            if cards.count > 0 { app.swipeUp(velocity: .slow) }
            #endif
            // Lets the scroll settle before the cards are looked for again: nothing signals its end.
            sleep(1)
        }
        let card = try XCTUnwrap(found, "a Home card in the window (\(cards.count) cards, the first at \(cards.firstMatch.frame), the window at \(app.windows.firstMatch.frame))")
        #endif
        // The open menu hides the card from accessibility on the Mac: its name first.
        let title = card.label
        openMenu(on: card, showing: ["menu.fileinfo"], timeout: 10, "the menu of \(title)")
        activate(element("menu.fileinfo"))
        require("menu.fileInfo", timeout: 20, "the file info sheet")
        let path = require("menu.fileInfo.path.0.0", timeout: 20, "the file's path")
        // Lets the sheet's presentation finish before the screenshot.
        sleep(1)
        shot("file info")
        #if os(tvOS)
        XCTAssertTrue(path.exists)
        for index in 0..<8 {
            XCUIRemote.shared.press(.down)
            // Paces the presses: the focus engine drops presses that come too close together.
            usleep(500_000)
            if index % 3 == 2 { shot("file info down \(index)") }
        }
        #else
        #if os(macOS)
        let pathText = [path.label, path.value as? String ?? ""].joined()
        XCTAssertFalse(pathText.trimmingCharacters(in: .whitespaces).isEmpty, "the file's path reads nothing")
        XCTAssertTrue(path.isHittable, "the file's path takes a click")
        #else
        path.tap()
        require("menu.fileInfo.copied", timeout: 5, "the copy's toast")
        // Lets the toast's animation finish before the screenshot.
        usleep(800_000)
        shot("path copied")
        #endif
        for index in 0..<3 {
            #if os(macOS)
            element("menu.fileInfo").scroll(byDeltaX: 0, deltaY: -400)
            #else
            element("menu.fileInfo").swipeUp()
            #endif
            // Lets the scroll settle before the screenshot: nothing signals its end.
            sleep(1)
            shot("file info scrolled \(index)")
        }
        #endif
        dismissMenu()
    }

    /// Signed in as the server's admin, a catalog movie's menu offers Edit..., Quick Tag... and Show link; Edit... opens the movie's
    /// editor, which changes nothing until saved.
    func testOffersMetadataEditsAndOpensTheEditor() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "after the launch")
        let card = try catalogCard()
        // Read now: on Apple TV the card is the focused one, which the menu takes focus from.
        let title = card.label
        openMenu(on: card, showing: ["menu.edit_metadata"], timeout: 10, "Edit... in the menu of \(title)")
        require("menu.quick_tag", "Quick Tag... in the menu")
        require("menu.show_link", "Show link in the menu")
        shot("menu with edits")
        activate(element("menu.edit_metadata"))
        require("metadata.field.title", timeout: 30, "the editor that Edit... opens")
        shot("editor from the menu")
    }

    /// Quick Tag... opens the tag sheet with its Add tag field focused (the keyboard up on iPhone and iPad); on Apple TV
    /// Down from the field goes to the first suggestion chip, the most recent. Cancel leaves the tags as they were.
    func testQuickTagFocusesTheFieldAndTheFirstChip() throws {
        launchDev(arguments: ["--dev-server", try server()])
        require("home.screen", timeout: 60, "after the launch")
        let card = try catalogCard()
        openMenu(on: card, showing: ["menu.quick_tag"], timeout: 10, "Quick Tag... in the menu")
        activate(element("menu.quick_tag"))
        let field = require("metadata.tags.field", timeout: 30, "the tag sheet's field")
        #if os(tvOS)
        XCTAssertTrue(field.wait(for: \.hasFocus, toEqual: true, timeout: 5), "the field has focus as the sheet opens")
        let chip = require("metadata.tags.chip.0", timeout: 15, "the first suggestion chip")
        shot("tag sheet")
        XCUIRemote.shared.press(.down)
        if !chip.wait(for: \.hasFocus, toEqual: true, timeout: 5) {
            let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
            fail("Down from the field lands on \(focused.exists ? focused.identifier : "nothing"), not the first chip")
        }
        shot("tag sheet first chip")
        XCUIRemote.shared.press(.menu)
        #else
        #if os(iOS)
        if !app.keyboards.firstMatch.exists(within: 10) { fail("the tag sheet opens without the keyboard") }
        #else
        // The field's own keyboard focus, which macOS reports for a text field; the app's probe reads a focused text
        // field as the field only within a redraw of the window's content, which it makes only as focus moves.
        if !waitUntil(5, { field.value(forKey: "hasKeyboardFocus") as? Bool == true }) {
            fail("the field doesn't have the keyboard as the sheet opens, focus on \(keyboardFocus)")
        }
        #endif
        shot("tag sheet")
        activate(require("metadata.tags.cancel", "the tag sheet's Cancel"))
        #endif
        XCTAssertTrue(field.waitForNonExistence(timeout: 10), "the tag sheet closes")
    }

    /// A playlist's rows and a row's item menu; the row's length stays outside its button at rest and as the menu lifts
    /// the row (`requireLengthClear`).
    func testOpensAPlaylistAndARowsMenu() throws {
        let server = try server()
        let kind = String(server.prefix { $0 != "=" })
        launchDev(arguments: ["--dev-server", server, "--dev-playlist", "\(kind):Binge"])
        require("playlist", timeout: 60, "the playlist's screen")
        let row = require("playlist.row.0", timeout: 30, "the playlist's first row")
        #if os(tvOS)
        // From wherever focus starts (the tab bar, the header, another row) onto the first row; outside Edit mode the
        // rows have no handle or ✕ to land on.
        for _ in 0..<10 where !row.hasFocus {
            let press: XCUIRemote.Button = focusedPlaylistRow() != nil ? .up : .down
            XCUIRemote.shared.press(press)
            _ = waitUntil(0.5) { row.hasFocus }
        }
        XCTAssertTrue(row.hasFocus, "the first row takes focus")
        #endif
        require("playlist.row.2", "the playlist's third row")
        require("playlist.play", "Play")
        // The rows' artwork comes over the network before the screenshot; nothing signals it.
        sleep(3)
        shot("playlist")
        requireLengthClear("at rest")
        #if os(tvOS)
        let restingWidth = row.frame.width
        #endif

        openMenu(on: row, showing: ["menu.fileinfo"], "the row's item menu")
        shotOfMenu("playlist row menu")
        requireLengthClear("with the row's menu open")
        dismissMenu()
        #if os(tvOS)
        _ = waitUntil(5) { row.hasFocus }
        XCTAssertTrue(row.hasFocus, "focus comes back to the playlist's row as its dismissed menu closes")
        shot("playlist row after the menu")
        // Once the menu's lift has settled the focused row is as wide as it was before the menu.
        sleep(1)
        shot("playlist row a second after the menu")
        XCTAssertEqual(row.frame.width, restingWidth, accuracy: 2, "the row grows back to its focused size after its menu")
        #endif
    }

    // MARK: - Helpers

    /// The first row's length: on Apple TV inside the row's button, in its focus highlight (the row reads it out); else
    /// beside the button, not in what the item menu lifts (the button, scaled up on iPad), and clear of its ✕ where Edit
    /// mode shows one.
    private func requireLengthClear(_ when: String) {
        #if os(tvOS)
        let row = require("playlist.row.0", "the first row")
        XCTAssertNotNil(row.label.range(of: #", \d+ (min|h|s)"#, options: .regularExpression), "\(when): the row \(row.label) reads out its length")
        let length = app.staticTexts.matching(identifier: "playlist.row.0.duration").firstMatch
        XCTAssertTrue(length.exists && row.frame.contains(length.frame), "\(when): the length \(length.frame) inside the row's button \(row.frame), in its focus highlight")
        #else
        let length = require("playlist.row.0.duration", "the first row's length").frame
        let button = element("playlist.row.0").frame
        XCTAssertFalse(length.intersects(button), "\(when): the length \(length) outside the row's button \(button)")
        let remove = element("playlist.row.0.remove")
        if remove.exists {
            XCTAssertFalse(length.intersects(remove.frame), "\(when): the length \(length) clear of ✕ \(remove.frame)")
        }
        #endif
    }


    /// A Home card of the alphabet catalog that can be pressed, focused on Apple TV.
    private func catalogCard() throws -> XCUIElement {
        #if os(tvOS)
        return try walk { $0.label.range(of: Self.titles, options: .regularExpression) != nil }
        #else
        let cards = app.descendants(matching: .any).matching(Self.catalog)
        let all = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        for _ in 0..<10 {
            if let card = visibleCatalogCard(cards) { return card }
            // A row's later cards aren't drawn until it scrolls: each row on screen along a few pages.
            if all.firstMatch.exists(within: 10) {
                let window = app.windows.firstMatch.frame
                var rows: [CGFloat] = []
                for index in 0..<min(all.count, 40) {
                    let frame = all.element(boundBy: index).frame
                    // By its middle: on a short screen (the iPhone Duo's cover) a row the page's end leaves at the top
                    // shows cut there, its cards' tops above the window's.
                    guard frame.midY > window.minY + 60, frame.midY < window.maxY - 60,
                          !rows.contains(where: { abs($0 - frame.midY) < 20 }) else { continue }
                    rows.append(frame.midY)
                }
                for row in rows {
                    let y = (row - window.minY) / window.height
                    for _ in 0..<3 {
                        #if os(macOS)
                        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: y)).scroll(byDeltaX: -600, deltaY: 0)
                        #else
                        dragSideways(atY: row, from: 0.9, to: 0.05, fling: true)
                        #endif
                        _ = waitUntil(1) { self.visibleCatalogCard(cards) != nil }
                        if let card = visibleCatalogCard(cards) { return card }
                    }
                }
            }
            #if os(macOS)
            element("home.screen").scroll(byDeltaX: 0, deltaY: -300)
            #else
            app.swipeUp()
            #endif
            _ = waitUntil(1) { self.visibleCatalogCard(cards) != nil }
        }
        fail("no card of the alphabet catalog on screen")
        throw XCTSkip("unreachable")
        #endif
    }

    private func visibleCatalogCard(_ cards: XCUIElementQuery) -> XCUIElement? {
        let area = besideVerticalBar
        for index in 0..<min(cards.count, 40) where onScreen(cards.element(boundBy: index), in: area) {
            return cards.element(boundBy: index)
        }
        return nil
    }

    #if os(tvOS)
    /// Focus off the tab bar into the content, then down the rows and along each to a card `matches` takes.
    private func walk(to matches: (XCUIElement) -> Bool) throws -> XCUIElement {
        let tab = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'nav.'"))
        for _ in 0..<12 {
            for _ in 0..<14 {
                guard let focused = focusedCard() else {
                    XCUIRemote.shared.press(tab.firstMatch.exists ? .down : .right)
                    _ = waitUntil(0.6) { self.focusedCard() != nil }
                    continue
                }
                if matches(focused) { return focused }
                XCUIRemote.shared.press(.right)
                // Paces the presses: focus stays on the card it leaves until the move lands, so no state to wait for.
                usleep(400_000)
            }
            XCUIRemote.shared.press(.down)
            // Paces the presses: focus stays on the card it leaves until the move lands, so no state to wait for.
            sleep(1)
        }
        fail("no card of the alphabet catalog took focus")
        throw XCTSkip("unreachable")
    }
    #endif

    /// Wholly inside `area` (the window beside the vertical bar) short of its foot, so a press lands on it (`isHittable`
    /// throws on a card a lazy row has let go of). Its top may meet the window's: on a short screen (the iPhone Duo's
    /// cover) the page's end leaves a row there.
    private func onScreen(_ element: XCUIElement, in area: CGRect) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        return !frame.isEmpty && CGRect(x: area.minX, y: area.minY, width: area.width, height: area.height - 40).contains(frame)
    }

    /// The card `id` where it can be pressed (an item can show in more than one row); on Apple TV the focused one: the
    /// menu gives focus back to the card it opened from as it closes.
    private func hittable(_ id: String) -> XCUIElement? {
        #if os(tvOS)
        let card = focusedCard(id)
        XCTAssertNotNil(card, "focus comes back to \(id) as its menu closes")
        return card
        #else
        let matches = app.descendants(matching: .any).matching(identifier: id)
        let area = besideVerticalBar
        for index in 0..<matches.count where onScreen(matches.element(boundBy: index), in: area) {
            return matches.element(boundBy: index)
        }
        return nil
        #endif
    }

    #if os(tvOS)
    private func focusedCard() -> XCUIElement? {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'card.'")).firstMatch
        return focused.exists ? focused : nil
    }

    /// The card `id` once it has focus, within 5 s.
    private func focusedCard(_ id: String) -> XCUIElement? {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier == %@", id)).firstMatch
        return focused.exists(within: 5) ? focused : nil
    }

    /// A focused part of a playlist row other than the first's.
    private func focusedPlaylistRow() -> XCUIElement? {
        let focused = app.descendants(matching: .any).matching(NSPredicate(
            format: "hasFocus == true AND identifier BEGINSWITH 'playlist.row.' AND NOT identifier BEGINSWITH 'playlist.row.0'"
        )).firstMatch
        return focused.exists ? focused : nil
    }

    /// Whether the system menu's entry `target` has focus: itself, or the focused cell around it.
    private func entryHasFocus(_ target: XCUIElement) -> Bool {
        guard let there = try? target.snapshot() else { return false }
        if there.hasFocus { return true }
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        guard let here = try? focused.snapshot(), !here.frame.isEmpty else { return false }
        return here.frame.insetBy(dx: -4, dy: -4).contains(there.frame) && here.frame.height < app.frame.height / 2
    }
    #endif

    /// Opens `target`'s menu and waits for one of `entries` in it, failing with `what` where none shows within `timeout`;
    /// the one that shows. On the Mac, where a crash alert came up meanwhile and closed the menu, the menu opens again
    /// (`reopenMenuClosedByAlert`).
    @discardableResult
    private func openMenu(on target: XCUIElement, showing entries: [String], timeout: TimeInterval = 20, _ what: String) -> String {
        #if os(macOS)
        menuTarget = target
        alertsBeforeMenu = Self.crashAlertsClosed
        rightClick(target)
        #elseif os(tvOS)
        XCUIRemote.shared.press(.select, forDuration: 1.2)
        #else
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.0)
        #endif
        var shown: String?
        let shows = { shown = entries.first { self.element($0).exists }; return shown != nil }
        _ = waitUntil(timeout, shows)
        #if os(macOS)
        if shown == nil, reopenMenuClosedByAlert() { _ = waitUntil(timeout, shows) }
        #endif
        guard let shown else {
            fail("\(what): no \(entries.joined(separator: " or ")) after \(Int(timeout)) s")
            return entries[0]
        }
        return shown
    }

    private func activate(_ target: XCUIElement) {
        #if os(macOS)
        if !target.exists, reopenMenuClosedByAlert() { _ = target.exists(within: 5) }
        target.click()
        #elseif os(tvOS)
        for _ in 0..<16 where !entryHasFocus(target) {
            XCUIRemote.shared.press(.down)
            _ = waitUntil(0.3) { self.entryHasFocus(target) }
        }
        XCTAssertTrue(entryHasFocus(target), "\(target.identifier) takes focus")
        XCUIRemote.shared.press(.select)
        #else
        target.tap()
        #endif
    }

    #if os(macOS)
    /// What the last menu opened from (`openMenu`), and the crash alerts closed before it opened (`crashAlertsClosed`).
    private var menuTarget: XCUIElement?
    private var alertsBeforeMenu = 0

    /// Right-clicks `target` in its own frame, not at its hittability: the right-click catcher over a card hides its
    /// activation point.
    private func rightClick(_ target: XCUIElement) {
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).rightClick()
    }

    /// Opens the last menu (`menuTarget`) again where a crash alert (another run's crashed app, `closeCrashAlerts`) came
    /// up since it opened, now or closed already by the monitor (`closeCrashAlertsMidTest`). The alert took the front
    /// from the app, which closes the menu, or, where the menu opened just as the alert came, leaves it on the screen but
    /// out of the app's accessibility tree, where Escape closes it first. Once per alert; whether it did.
    @discardableResult
    private func reopenMenuClosedByAlert() -> Bool {
        Self.closeCrashAlertsMidTest()
        guard let target = menuTarget, Self.crashAlertsClosed > alertsBeforeMenu else { return false }
        alertsBeforeMenu = Self.crashAlertsClosed
        if menuOnScreen { app.typeKey(.escape, modifierFlags: []) }
        rightClick(target)
        return true
    }

    /// Whether the app shows a menu (a window at the menus' level), in its accessibility tree or not. Escape goes to an
    /// open menu, never to the screen under it.
    private var menuOnScreen: Bool {
        let pids = NSRunningApplication.runningApplications(withBundleIdentifier: "com.edde746.plezy.dev").map(\.processIdentifier)
        let level = Int(CGWindowLevelForKey(.popUpMenuWindow))
        let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.contains { window in
            guard let owner = window[kCGWindowOwnerPID as String] as? pid_t else { return false }
            return pids.contains(owner) && window[kCGWindowLayer as String] as? Int == level
        }
    }
    #endif

    private func dismissMenu() {
        #if os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #elseif os(tvOS)
        XCUIRemote.shared.press(.menu)
        #else
        // Beside the system's menu (a card's context menu, a ⋯'s menu), which keeps clear of the screen's edges.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
        #endif
        let open = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'menu.' AND identifier != 'menu.message'")).firstMatch
        _ = waitUntil(5) { !(open.exists && open.isHittable) }
    }
}
