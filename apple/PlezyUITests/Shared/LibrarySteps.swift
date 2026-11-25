import XCTest

/// Steps on Libraries' header row (`LibrariesScreen`): its filter menus (`libraries.library`, `libraries.view`,
/// `libraries.grouping`, `libraries.sort`, each option `<id>.option.<i>`), Filters and the actions; and the waits and
/// remote moves the Libraries tests share, for `test`.
@MainActor
struct LibrarySteps {
    let test: PlezyUITestCase

    private var app: XCUIApplication { test.app }

    private func require(_ id: String, timeout: TimeInterval = 20, _ what: String) -> XCUIElement {
        test.require(id, timeout: timeout, what)
    }

    private func shot(_ name: String) { test.shot(name) }

    private func fail(_ message: String) { test.fail(message) }

    /// The server `PLEZY_DEV_SERVER` names (`--dev-server`'s `<kind>=<user>:<password>@<url>`).
    func libraryServer() throws -> String {
        try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
    }

    /// Picks the library `title`: the library menu (iPhone, iPad, Apple TV) or the Mac's sidebar.
    func pickLibrary(_ title: String) {
        #if os(macOS)
        require("nav.library.\(title)", timeout: 20, "\(title) in the sidebar").click()
        #else
        openFilterMenu("libraries.library")
        shot("library picker")
        pickOption("libraries.library", label: title)
        #endif
        // Lets the library's screen swap in; callers press into it next and nothing marks the swap done.
        sleep(2)
    }

    /// Shows the library's tab `key` (`recommended`, `browse`, `collections`, `playlists`, `genres`) from the view menu.
    func showLibraryTab(_ key: String) {
        openFilterMenu("libraries.view")
        pickOption("libraries.view", label: LibrarySteps.tabLabels[key] ?? key)
        // Lets the tab's page swap in; callers press into it next and nothing marks the swap done.
        sleep(2)
    }

    static let tabLabels = [
        "recommended": "Recommended", "browse": "Browse", "collections": "Collections", "playlists": "Playlists", "genres": "Genres",
    ]

    /// Opens the filter menu `id`, a native menu.
    func openFilterMenu(_ id: String) {
        pressInHeader(id, "the \(id) menu")
        XCTAssertTrue(option(id).exists(within: 10), "\(id)'s options")
    }

    /// A press on the header row's control `id` (`what`), brought into view first where the row's filters scroll
    /// sideways (a phone's, `header.filters`): a drag along the row toward it, by as much as it lies past the row's end, a
    /// margin added, at most half the row.
    func pressInHeader(_ id: String, _ what: String) {
        let target = require(id, timeout: 30, what)
        #if os(iOS)
        let row = test.element("header.filters")
        for _ in 0..<6 where row.exists {
            let visible = row.frame
            let frame = target.frame
            if frame.minX >= visible.minX - 0.5, frame.maxX <= visible.maxX + 0.5 { break }
            let pastTheEnd = frame.midX > visible.midX
            let outside = pastTheEnd ? frame.maxX - visible.maxX : visible.minX - frame.minX
            let half = (pastTheEnd ? -1 : 1) * min(max(outside, 0) + 24, visible.width / 2) / 2
            let middle = row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            middle.withOffset(CGVector(dx: -half, dy: 0))
                .press(forDuration: 0.05, thenDragTo: middle.withOffset(CGVector(dx: half, dy: 0)), withVelocity: .slow, thenHoldForDuration: 0.3)
        }
        #endif
        press(target)
    }

    /// The first option of the filter menu `id` whose label (a Mac menu item's title) starts with `label`, or any of its
    /// options.
    func option(_ id: String, label: String? = nil) -> XCUIElement {
        let format = label == nil ? "identifier BEGINSWITH %@" : "identifier BEGINSWITH %@ AND (label BEGINSWITH %@ OR title BEGINSWITH %@)"
        let arguments: [Any] = label.map { ["\(id).option.", $0, $0] } ?? ["\(id).option."]
        return app.descendants(matching: .any).matching(NSPredicate(format: format, argumentArray: arguments)).firstMatch
    }

    /// Picks the open filter menu `id`'s option `label`.
    func pickOption(_ id: String, label: String) {
        let entry = option(id, label: label)
        XCTAssertTrue(entry.exists(within: 10), "\(label) among \(id)'s options")
        #if os(tvOS)
        // The menu opens with focus on its first option: down to the option's index; else down the rows, then up.
        let index = Int(entry.identifier.dropFirst("\(id).option.".count).prefix { $0.isNumber }) ?? 0
        for _ in 0..<index {
            XCUIRemote.shared.press(.down)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(300_000)
        }
        tvSelect(entry)
        #else
        pressOption(entry)
        #endif
        _ = entry.waitForNonExistence(timeout: 10)
    }

    #if os(tvOS)
    /// Focus onto `entry` of an open menu, down its rows then up them, then Select.
    func tvSelect(_ entry: XCUIElement) {
        let sweep = Array(repeating: XCUIRemote.Button.down, count: 14) + Array(repeating: .up, count: 14)
        for button in sweep {
            if hasFocus(entry) { break }
            XCUIRemote.shared.press(button)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(350_000)
        }
        XCTAssertTrue(hasFocus(entry), "focus on \(entry.label)")
        XCUIRemote.shared.press(.select)
    }
    #endif

    /// A press on an open menu's option. iOS: on its lower part: a menu's first row lies over the header row's capsules,
    /// and where it covers one (iPad: Sort's Title over Filters) a tap at the row's middle reaches neither.
    func pressOption(_ entry: XCUIElement) {
        #if os(iOS)
        entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        // Lets the menu finish closing; a tap during it is dropped.
        sleep(1)
        #else
        press(entry)
        #endif
    }

    /// Closes an open menu or panel without a pick: a tap over the content beside it (iOS; a tap on the status bar
    /// doesn't reach the menu's dimming), Escape (the Mac), Menu (Apple TV). iOS: below the middle of the screen where
    /// that is clear of the menu's options and popovers, else beside them: on a short screen (the iPhone Duo's) a long
    /// menu reaches past the screen's lower fifth, and a tap on its own edge leaves it open.
    func dismissMenu() {
        #if os(iOS)
        let window = app.windows.firstMatch.frame
        let open = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS '.option.' OR elementType == %d", XCUIElement.ElementType.popover.rawValue))
            .allElementsBoundByIndex.map(\.frame).filter { !$0.isEmpty }
            .reduce(CGRect.null) { $0.union($1) }
            .insetBy(dx: -24, dy: -24)
        let spots = [CGVector(dx: 0.5, dy: 0.8), CGVector(dx: 0.5, dy: 0.95), CGVector(dx: 0.06, dy: 0.6), CGVector(dx: 0.94, dy: 0.6)]
        let spot = spots.first { spot in
            !open.contains(CGPoint(x: window.minX + window.width * spot.dx, y: window.minY + window.height * spot.dy))
        } ?? spots[0]
        app.coordinate(withNormalizedOffset: spot).tap()
        #elseif os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #else
        XCUIRemote.shared.press(.menu)
        #endif
        // Lets the menu or panel finish closing; a press during it is dropped.
        sleep(1)
    }

    /// Opens Manage libraries: the ⋯ menu's entry (iPhone, iPad, the Mac), the header row's button (Apple TV).
    func openManageLibraries() {
        #if os(tvOS)
        press(require("libraries.manage", timeout: 30, "Manage libraries"))
        #else
        let more = require("libraries.more", timeout: 30, "the ⋯ menu")
        #if os(macOS)
        // macOS 27.2 reports a menu sharing the actions' glass capsule at the capsule's leading end, over Shuffle, and
        // leaves the menu it opens out of the element tree: a click where the ⋯ is drawn, after Shuffle, opens it, and
        // the keyboard picks its first entry, Manage libraries.
        let shuffle = test.element("libraries.shuffle")
        if shuffle.waitForExistence(timeout: 10), more.frame.minX < shuffle.frame.maxX {
            let offset = CGVector(dx: shuffle.frame.maxX - more.frame.minX + more.frame.width / 2, dy: more.frame.height / 2)
            more.coordinate(withNormalizedOffset: .zero).withOffset(offset).click()
        } else {
            more.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        }
        sleep(1)
        app.typeKey(.downArrow, modifierFlags: [])
        app.typeKey(.return, modifierFlags: [])
        #else
        // iOS 27 can report the ⋯ menu with the frame of the whole header, both its lines where it wraps (Browse's sort
        // and filters), whose middle lies between the lines, beside the ⋯ on Shuffle's edge: a tap there plays a
        // random item. The ⋯'s glyph keeps the ⋯'s own frame; iPad's ⋯, a toolbar button, has no glyph and its own
        // frame.
        let glyph = more.images["ellipsis"]
        (glyph.exists ? glyph : more).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        press(require("libraries.manage", timeout: 10, "Manage libraries in the ⋯ menu"))
        #endif
        #endif
        require("settings.page.manage_libraries", timeout: 20, "Manage libraries")
    }

    /// A press on `target`: a tap or a click on its own frame; on Apple TV focus moved onto it (a control of the header
    /// row: up to the row, never into the tab bar, then along it), then Select.
    func press(_ target: XCUIElement) {
        #if os(macOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #elseif os(iOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #else
        tvFocusHeader(target)
        XCUIRemote.shared.press(.select)
        #endif
        // Paces presses: a press during the previous one's transition is dropped.
        sleep(1)
    }

    /// The first element whose identifier starts with `prefix`.
    func prefixed(_ prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
    }

    /// The first card whose label starts with `prefix`.
    func card(prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label BEGINSWITH %@", prefix)).firstMatch
    }

    #if os(macOS)
    /// Clicks the card `title` in `library`'s grid, typing nothing: on the Mac a typed key hides the pointer and
    /// SwiftUI's hover stays off until a real mouse move, which XCUITest's synthesized moves don't make, so a right
    /// click after Search's typing would reach no item. The grid is long and lazy: its alphabet index brings the title's
    /// letter in.
    func openCard(_ title: String, in library: String) {
        pickLibrary(library)
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label == %@", title)).firstMatch
        let window = app.windows.firstMatch
        let letter = test.element("libraries.alpha.\(title.prefix(1))")
        if letter.exists(within: 30) { letter.click() }
        if !card.exists(within: 15) {
            for _ in 0..<30 where !card.exists {
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).scroll(byDeltaX: 0, deltaY: -300)
                _ = card.exists(within: 1)
            }
        }
        if !card.exists { fail("the \(library) library lists no \(title)") }
        let shown = { window.frame.insetBy(dx: 0, dy: 40).contains(card.frame) }
        for _ in 0..<4 where !shown() {
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).scroll(byDeltaX: 0, deltaY: -150)
            _ = waitUntil(1, shown)
        }
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).click()
    }
    #endif

    /// `element` within the window, not cut by its top and bottom 40 points.
    func onScreen(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        return !frame.isEmpty && app.windows.firstMatch.frame.insetBy(dx: 0, dy: 40).intersects(frame)
    }

    #if os(tvOS)
    var tabBarFocused: Bool {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'nav.'")).firstMatch.exists
    }

    /// Whether `element` holds focus, or the cell or button it sits in does: a form row's focus is its cell's (Manage
    /// libraries' switches, the filter editor's rows: the cell carries the row's label), as a context menu entry's is
    /// (the entry inside it) and an alert action's (the system's button around it); a menu's is an element of the
    /// system's inside it, which carries none of the menu's identity (`inside`).
    func hasFocus(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        if element.hasFocus || inside(element) { return true }
        let id = element.identifier
        if !id.isEmpty, app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).containing(.any, identifier: id).firstMatch.exists {
            return true
        }
        let cell = app.cells.matching(NSPredicate(format: "hasFocus == true")).firstMatch
        let label = element.label
        return cell.exists && !label.isEmpty && cell.label.hasPrefix(label)
    }

    func focused(prefix: String) -> Bool {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH %@", prefix)).firstMatch.exists
    }

    func focusedCard(within seconds: Int) -> XCUIElement? {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'card.'")).firstMatch
        _ = waitUntil(TimeInterval(max(seconds, 1))) { focused.exists }
        return focused.exists ? focused : nil
    }

    /// Focus onto `target`, a control of the screen's header row or of an open panel: inside a panel along its rows;
    /// else up to the header row (back down once the tab bar takes focus, whose tabs switch as they take it), then
    /// toward it, by where the focused control lies, and failing that along the whole row and the panel's rows.
    func tvFocusHeader(_ target: XCUIElement) {
        for _ in 0..<8 {
            if hasFocus(target) || tabBarFocused || headerFocused { break }
            XCUIRemote.shared.press(.up)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(400_000)
        }
        if tabBarFocused {
            XCUIRemote.shared.press(.down)
            // Lets focus leave the tab bar before the next press.
            usleep(600_000)
        }
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        for _ in 0..<12 {
            if hasFocus(target) { return }
            guard let at = try? focused.snapshot().frame, target.exists else { break }
            let goal = target.frame
            let button: XCUIRemote.Button
            if goal.maxX <= at.minX { button = .left } else if goal.minX >= at.maxX { button = .right } else if goal.minY >= at.maxY { button = .down } else if goal.maxY <= at.minY { button = .up } else { break }
            XCUIRemote.shared.press(tabBarFocused ? .down : button)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(350_000)
        }
        let along = Array(repeating: XCUIRemote.Button.left, count: 8) + Array(repeating: .right, count: 12)
            + Array(repeating: .down, count: 10) + Array(repeating: .up, count: 10)
        for button in along {
            if hasFocus(target) { break }
            XCUIRemote.shared.press(tabBarFocused ? .down : button)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(350_000)
        }
        XCTAssertTrue(hasFocus(target), "focus on \(target.identifier)")
    }

    /// The focused element, without identity of its own, lies inside `element`: the system's button in a menu.
    func inside(_ element: XCUIElement) -> Bool {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        guard let focused = try? focused.snapshot(), focused.identifier.isEmpty, element.exists else { return false }
        return element.frame.contains(CGPoint(x: focused.frame.midX, y: focused.frame.midY))
    }

    /// A control of Libraries' header row holds focus.
    var headerFocused: Bool {
        let buttons = ["libraries.filters", "libraries.shuffle", "libraries.manage", "libraries.refresh"]
        let menus = ["libraries.library", "libraries.view", "libraries.grouping", "libraries.sort"]
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true AND (identifier IN %@)", buttons))
            .firstMatch.exists || menus.contains { inside(test.element($0)) }
    }

    /// Presses toward `done`: first `sweeps` (each a button pressed up to so many times), then up, right, down, left;
    /// never along the tab bar.
    func tvFocus(_ first: [(XCUIRemote.Button, Int)] = [], until done: () -> Bool) {
        let sweeps: [(XCUIRemote.Button, Int)] = first + [(.up, 6), (.right, 10), (.down, 10), (.left, 10), (.up, 6)]
        for (button, times) in sweeps {
            for _ in 0..<times {
                if done() { return }
                XCUIRemote.shared.press(tabBarFocused ? .down : button)
                // Paces the presses so the focus engine doesn't coalesce them.
                usleep(350_000)
            }
        }
        if !done() { fail("focus never reached its target") }
    }
    #endif
}
