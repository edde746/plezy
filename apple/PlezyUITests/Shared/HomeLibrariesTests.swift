import XCTest
#if os(iOS)
import UIKit
#endif

/// Home and Libraries against the server `PLEZY_DEV_SERVER` names (`--dev-server`'s `<kind>=<user>:<password>@<url>`,
/// the default seeded Jellyfin or Emby). Home: Continue Watching first, no hero, the hubs as shelves (Apple TV: the
/// shortcuts under Continue Watching), a library's shortcut chip opening it in Libraries (with `PLEZY_SECOND_SERVER`, the
/// chips of namesakes naming their servers), a hub's View all opening its hub detail by its heading or, with keys, its
/// last card; Home's rows and chips keep their places as it loads. Libraries: the library menu (iPhone, iPad, Apple
/// TV) or the Mac's sidebar's Libraries section, the tabs from the view menu, the grid and the list, the sort and
/// grouping menus and the filters' sheet, the alphabet index's jump, Collections, Playlists opening a playlist; Manage
/// libraries hiding a library, which the library menu drops (the
/// Mac's sidebar moves it to its hidden group), then showing it again (the server's state unchanged). On Apple TV focus
/// enters Home and Libraries on their content.
/// Continue Watching takes the server's latest as Home shows again, focus following its card on Apple TV.
/// Shuffle on the Music library plays its tracks shuffled.
final class HomeLibrariesTests: PlezyUITestCase {
    private func server() throws -> String {
        try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
    }

    private func launch(_ destination: String, settings: [String] = []) throws {
        launchDev(settings: settings, arguments: ["--dev-server", try server(), "--dev-open", destination])
    }

    // MARK: - Home

    func testHomeHubsAndViewAll() throws {
        try launch("home")
        require("home.screen", timeout: 60, "Home")
        require("home.rail", timeout: 30, "the shelves")
        XCTAssertFalse(element("home.hero").exists, "Home has no hero")
        #if os(tvOS)
        // Focus lands on Continue Watching's first card, no press needed.
        guard let first = focusedCard(within: 15) else { return fail("no card took focus as Home loaded") }
        XCTAssertTrue(element("hub.continue_watching").exists, "Continue Watching is the first row")
        let firstLabel = first.label
        // Lets the shelves' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("home shelves")
        // Down from Continue Watching reaches the shortcuts, Up goes back; Up again reaches the tab bar.
        XCUIRemote.shared.press(.down)
        if !waitUntil(3, { focused(prefix: "home.refresh") }) { fail("Down from Continue Watching doesn't land on the first shortcut") }
        shot("home shortcuts")
        // VoiceOver says what each of Home's buttons does, its cards' and chips'.
        requireSpokenNames(in: element("home.screen"), "Home")
        // A chip per library after Home's own, which Right reaches as it does the others.
        let library = require("home.library.0", "the first library's chip")
        requireServerLibrary(library.label)
        for _ in 0..<12 where !focused(prefix: "home.library.0") {
            XCUIRemote.shared.press(.right)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(350_000)
        }
        if !focused(prefix: "home.library.0") { fail("Right along the shortcuts doesn't reach the first library's chip") }
        // Lets the chip's focus lift finish before the shot.
        sleep(1)
        shot("home library chip")
        for _ in 0..<12 where !focused(prefix: "home.refresh") {
            XCUIRemote.shared.press(.left)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(350_000)
        }
        XCUIRemote.shared.press(.up)
        if !waitUntil(3, { focusedCard(within: 1)?.label == firstLabel }) { fail("Up from the shortcuts doesn't go back to Continue Watching") }
        XCUIRemote.shared.press(.up)
        if !waitUntil(3, { tabBarFocused }) { fail("Up from the first shelf doesn't reach the tab bar") }
        shot("home tab bar")
        #else
        let continueWatching = require("hub.continue_watching", timeout: 30, "Continue Watching")
        XCTAssertTrue(app.staticTexts["Continue Watching"].exists, "Continue Watching's heading")
        let firstHub = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'hub.' AND NOT identifier BEGINSWITH 'hub.continue_watching' AND NOT identifier CONTAINS '.viewAll'")).firstMatch
        if firstHub.exists(within: 30) {
            XCTAssertLessThan(continueWatching.frame.minY, firstHub.frame.minY, "Continue Watching above the hubs")
        }
        // Lets the shelves' artwork load before the shot; nothing signals it.
        sleep(4)
        shot("home")
        #endif
        openViewAll()
        XCTAssertTrue(anyCard.firstMatch.exists(within: 20), "the hub detail's items")
        XCTAssertTrue(element("hubDetail.sort").exists(within: 10), "the hub detail's sort")
        // Lets the items' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("hub detail")
        #if os(tvOS)
        // Select on a library's chip opens that library in Libraries. Back on Home, Up to the shortcuts, then
        // along them.
        XCUIRemote.shared.press(.menu)
        require("home.rail", timeout: 20, "Home again")
        let onShortcut = element("home.shortcuts").descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        steps.tvFocus([(.up, 10)]) { onShortcut.exists }
        for button in Array(repeating: XCUIRemote.Button.right, count: 12) + Array(repeating: .left, count: 12) where !focused(prefix: "home.library.") {
            XCUIRemote.shared.press(button)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(350_000)
        }
        let chip = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'home.library.'")).firstMatch
        guard chip.exists else { return fail("focus never reached a library's chip") }
        let name = chip.label
        XCUIRemote.shared.press(.select)
        requireLibrarySelected(name)
        // Lets the library's artwork load before the shot; nothing signals it.
        sleep(2)
        shot("library from its chip")
        #endif
    }

    /// Home with no server signed in says it could not load, with Retry, rather than show loading shelves for good.
    func testHomeWithoutAServerShowsItsErrorWithRetry() throws {
        launchDev(arguments: ["--dev-open", "home"])
        require("home.screen", timeout: 60, "Home")
        require("browse.error", timeout: 30, "Home's error")
        XCTAssertTrue(element("state.retry").exists, "the error offers Retry")
        XCTAssertFalse(element("home.continueWatching.loading").exists, "no loading shelf stays")
        shot("home without a server")
    }

    /// A hub's View all shows its spinner alone until its items are in (the test's proxy holds them), then its
    /// grid.
    func testViewAllShowsASpinnerUntilItsItems() throws {
        let spec = try server()
        guard let upstream = ServerProxy.upstream(of: spec), let proxy = ServerProxy(upstream: upstream) else {
            return fail("no proxy on the loopback in front of \(spec)")
        }
        addTeardownBlock {
            let log = XCTAttachment(string: proxy.log)
            log.name = "proxy requests"
            log.lifetime = .keepAlways
            self.add(log)
            proxy.stop()
        }
        launchDev(arguments: ["--dev-server", proxy.server(for: spec), "--dev-open", "home"])
        require("home.screen", timeout: 60, "Home")
        require("home.rail", timeout: 30, "the shelves")
        // Lets the shelves settle (focus on Apple TV) before moving through them.
        sleep(3)
        // A Recently Added hub's items: the bare items path.
        proxy.hold(path: "/Items")
        openViewAll()
        if proxy.heldPath(within: 30) == nil { fail("View all asked for no items") }
        _ = element("hubDetail.loading").exists(within: 5)
        shot("view all loading")
        require("hubDetail.loading", "View all's spinner while its items load")
        XCTAssertFalse(anyCard.firstMatch.exists, "no grid beside the spinner")
        proxy.release()
        XCTAssertTrue(anyCard.firstMatch.exists(within: 30), "the items once they are in")
        XCTAssertFalse(element("hubDetail.loading").exists, "the spinner gone with the grid shown")
        // Lets the items' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("view all loaded")
    }

    /// A library shows its spinner alone until its items are in (the test's proxy holds them), then its grid.
    func testLibraryShowsASpinnerUntilItsItems() throws {
        let spec = try server()
        guard let upstream = ServerProxy.upstream(of: spec), let proxy = ServerProxy(upstream: upstream) else {
            return fail("no proxy on the loopback in front of \(spec)")
        }
        addTeardownBlock {
            let log = XCTAttachment(string: proxy.log)
            log.name = "proxy requests"
            log.lifetime = .keepAlways
            self.add(log)
            proxy.stop()
        }
        // The library's items: the bare items path.
        proxy.hold(path: "/Items")
        launchDev(arguments: ["--dev-server", proxy.server(for: spec), "--dev-open", "libraries"])
        if proxy.heldPath(within: 90) == nil { fail("the library asked for no items") }
        _ = element("libraries.items.loading").exists(within: 10)
        shot("library loading")
        require("libraries.items.loading", "the library's spinner while its items load")
        XCTAssertFalse(anyCard.firstMatch.exists, "no grid beside the spinner")
        proxy.release()
        XCTAssertTrue(anyCard.firstMatch.exists(within: 30), "the items once they are in")
        XCTAssertFalse(element("libraries.items.loading").exists, "the spinner gone with the grid shown")
        #if os(tvOS)
        // Focus lands on the grid's first card once the items are in.
        guard let card = focusedCard(within: 10) else { return fail("no card took focus once the items came in") }
        XCTAssertEqual(card.identifier, anyCard.firstMatch.identifier, "focus on the library's first card")
        #endif
        // Lets the items' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("library loaded")
    }

    /// Home keeps its places as it loads: the test's proxy holds the server's Live TV answer 1.5 s, Continue Watching's
    /// 3 s. From the first frame each shows on, the chip row, its Watch Together chip (after Live TV's), Continue
    /// Watching's row (its loading shelf, then its cards) and the shelves under the chips keep their places as Live TV,
    /// the libraries and Continue Watching arrive. A burst of shots is kept.
    func testHomeHoldsItsPlacesAsItLoads() throws {
        let spec = try server()
        guard let upstream = ServerProxy.upstream(of: spec), let proxy = ServerProxy(upstream: upstream) else {
            return fail("no proxy on the loopback in front of \(spec)")
        }
        addTeardownBlock {
            let log = XCTAttachment(string: proxy.log)
            log.name = "proxy requests"
            log.lifetime = .keepAlways
            self.add(log)
            proxy.stop()
        }
        let liveTv = "/LiveTv/Channels"
        let nextUp = "/Shows/NextUp"
        proxy.hold(path: liveTv)
        proxy.hold(path: nextUp)
        launchDev(arguments: ["--dev-server", proxy.server(for: spec), "--dev-open", "home"])
        require("home.screen", timeout: 60, "Home")
        let start = Date()
        var places: [String: [(time: TimeInterval, frame: CGRect)]] = [:]
        var shots = 0
        // Samples the places, a shot each, for `seconds` or, given `until`, until it holds of the last sample (at most
        // 30 s).
        func sample(for seconds: TimeInterval, until done: (([String: CGRect]) -> Bool)? = nil) {
            let end = Date().addingTimeInterval(done == nil ? seconds : 30)
            while Date() < end {
                let time = Date().timeIntervalSince(start)
                guard let snapshot = try? app.snapshot() else { continue }
                let found = Self.homePlaces(in: snapshot)
                for (name, frame) in found { places[name, default: []].append((time, frame)) }
                shots += 1
                let attachment = XCTAttachment(screenshot: screen())
                attachment.name = String(format: "burst %02d at %.2f s", shots, time)
                attachment.lifetime = .keepAlways
                add(attachment)
                if let done, done(found) { return }
            }
        }
        sample(for: 1.5)
        proxy.release(path: liveTv)
        sample(for: 1.5)
        proxy.release(path: nextUp)
        sample(for: 0) { $0["Continue Watching"] != nil && $0["the shelves under the chips"] != nil && $0["the chip row"] != nil }
        sample(for: 2)
        shot("home loaded")
        XCTAssertTrue(element("hub.continue_watching").exists, "Continue Watching's cards once its answer is in")
        XCTAssertTrue(element("home.liveTv").exists, "Live TV's chip once its answer is in")
        // Each place's first frame, then each sample where it stood elsewhere than in the one before.
        var moves: [String] = []
        for (name, seen) in places.sorted(by: { $0.key < $1.key }) {
            let steps = seen.indices.filter { index in
                index == 0 || abs(seen[index].frame.minX - seen[index - 1].frame.minX) > 0.5
                    || abs(seen[index].frame.minY - seen[index - 1].frame.minY) > 0.5
            }
            guard steps.count > 1 else { continue }
            let path = steps.map { String(format: "%.2f s (%.0f, %.0f)", seen[$0].time, seen[$0].frame.minX, seen[$0].frame.minY) }
            moves.append("\(name): \(path.joined(separator: " → "))")
        }
        XCTAssertNotNil(places["the chip row"], "the chip row showed")
        if !moves.isEmpty { XCTFail("moved as Home loaded: \(moves.joined(separator: "; "))") }
    }

    /// The frames of Home's places in `snapshot`: the chip row, its Watch Together chip, Continue Watching's row (its
    /// loading shelf or its cards) and the first shelf under the chips (the loading shelves or the first hub).
    private static func homePlaces(in snapshot: XCUIElementSnapshot) -> [String: CGRect] {
        var found: [String: CGRect] = [:]
        func visit(_ element: XCUIElementSnapshot) {
            let id = element.identifier
            switch id {
            case "home.shortcuts": found["the chip row"] = element.frame
            case "home.watchTogether": found["Watch Together's chip"] = element.frame
            case "hub.continue_watching", "home.continueWatching.loading": found["Continue Watching"] = element.frame
            case "browse.loading", _ where Self.isHub(id):
                if found["the shelves under the chips"] == nil { found["the shelves under the chips"] = element.frame }
            default:
                break
            }
            element.children.forEach(visit)
        }
        visit(snapshot)
        return found
    }

    /// A hub's shelf other than Continue Watching (`hub.<id>`), not one of the elements in a shelf's heading.
    private static func isHub(_ id: String) -> Bool {
        id.hasPrefix("hub.") && !id.hasPrefix("hub.continue_watching") && !id.hasSuffix(".viewAll")
            && id != "hub.totalResults" && id != "hub.viewAll"
    }

    /// A screenshot of what the app shows: on the Mac its window.
    private func screen() -> XCUIScreenshot {
        #if os(macOS)
        app.windows.firstMatch.screenshot()
        #elseif os(iOS)
        XCUIScreen.main.screenshot()
        #else
        app.screenshot()
        #endif
    }

    /// View all's Sort sits at the trailing end of its title's row and scrolls away with it and the grid; on
    /// Apple TV, Up from the grid's top row reaches it.
    func testViewAllSortScrollsWithItsTitle() throws {
        try launch("home")
        require("home.screen", timeout: 60, "Home")
        require("home.rail", timeout: 30, "the shelves")
        // Lets the shelves settle (focus on Apple TV) before moving through them.
        sleep(3)
        openViewAll()
        XCTAssertTrue(anyCard.firstMatch.exists(within: 30), "View all's items")
        // Lets the items' artwork and the title row settle before the shot and the frames are read.
        sleep(3)
        shot("view all top")
        let title = require("hubDetail.title", "View all's title")
        let sort = require("hubDetail.sort", "View all's sort")
        XCTAssertGreaterThan(sort.frame.minX, title.frame.maxX, "the sort after the title")
        XCTAssertTrue(sort.frame.minY < title.frame.maxY && sort.frame.maxY > title.frame.minY, "the sort on the title's row")
        let top = sort.frame.minY
        #if os(tvOS)
        for _ in 0..<3 {
            XCUIRemote.shared.press(.down)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(600_000)
        }
        #elseif os(macOS)
        element("hubDetail").scroll(byDeltaX: 0, deltaY: -600)
        #else
        app.swipeUp()
        #endif
        _ = waitUntil(5) { !sort.exists || sort.frame.maxY < top }
        shot("view all scrolled")
        XCTAssertTrue(!sort.exists || sort.frame.maxY < top, "the sort scrolled away with the grid")
        #if os(tvOS)
        // The menu's own button takes focus inside the capsule, which carries the identifier.
        let sortFocused = { [self] in
            app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).allElementsBoundByIndex
                .contains { sort.exists && sort.frame.contains(CGPoint(x: $0.frame.midX, y: $0.frame.midY)) }
        }
        for _ in 0..<8 where !sortFocused() {
            XCUIRemote.shared.press(.up)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(600_000)
        }
        if !sortFocused() { fail("Up from the grid doesn't reach the sort") }
        shot("view all sort focused")
        #endif
    }

    /// In the list view mode a hub's View all lists its items as the library's list rows.
    func testHubDetailListMode() throws {
        try launch("home", settings: ["view_mode=list"])
        require("home.screen", timeout: 60, "Home")
        require("hub.continue_watching", timeout: 30, "Continue Watching")
        // Lets the shelves settle (focus on Apple TV) before moving through them.
        sleep(3)
        openViewAll()
        let row = anyCard.firstMatch
        XCTAssertTrue(row.exists(within: 20), "the hub detail's items")
        // Lets the rows' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("hub detail list")
        let width = app.windows.firstMatch.exists ? app.windows.firstMatch.frame.width : app.frame.width
        XCTAssertGreaterThan(row.frame.width, width / 2, "an item is a list row across the screen (\(row.frame.width) of \(width))")
    }

    #if os(tvOS)
    /// Apple TV's grids hold as many cards across as a TV's grids always have: a hub's View all 4 episode thumbnails or
    /// 7 posters, a library's Browse grid 7 posters, at the default density.
    func testTvGridColumns() throws {
        try launch("home")
        require("home.screen", timeout: 60, "Home")
        require("hub.continue_watching", timeout: 30, "Continue Watching")
        // Lets the shelves settle their focus before moving through them.
        sleep(3)
        openViewAll()
        XCTAssertTrue(anyCard.firstMatch.exists(within: 20), "the hub detail's items")
        // Lets the items' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("hub detail columns")
        requireColumns(wide: 4, poster: 7, "View all")
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Movies")
        steps.showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse grid")
        XCTAssertTrue(anyCard.firstMatch.exists(within: 30), "the library's cards")
        // Lets the cards' artwork load before the shot; nothing signals it.
        sleep(4)
        shot("library grid columns")
        requireColumns(wide: 4, poster: 7, "Movies' Browse grid")
    }

    /// The cards in the grid's first row number `wide` for episode thumbnails, `poster` for posters.
    private func requireColumns(wide: Int, poster: Int, _ what: String) {
        let cards = anyCard.allElementsBoundByIndex.map(\.frame).filter { !$0.isEmpty }
        guard let top = cards.map(\.minY).min(), let first = cards.first(where: { $0.minY == top }) else { return fail("\(what): no cards") }
        // A focused card lifts out of its row: a row is the cards within half a card of the top one.
        let row = cards.filter { abs($0.minY - top) < first.height / 2 }
        let expected = first.width > first.height ? wide : poster
        XCTAssertEqual(row.count, expected, "\(what): cards across, each \(first.width) wide, the row \(row.map(\.minX).min() ?? 0)–\(row.map(\.maxX).max() ?? 0)")
    }
    #endif

    /// Opens a hub's View all from Home: on Apple TV the card ending a row, elsewhere a hub's heading link.
    private func openViewAll() {
        #if os(tvOS)
        var seen: [String] = []
        for _ in 0..<10 where !viewAllFocused {
            // Lets focus leave the tab bar before the next press.
            if tabBarFocused { XCUIRemote.shared.press(.down); sleep(1); continue }
            for _ in 0..<30 where !viewAllFocused && !tabBarFocused {
                XCUIRemote.shared.press(.right)
                // Paces the presses so the focus engine doesn't coalesce them.
                usleep(250_000)
            }
            let now = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).allElementsBoundByIndex.last
            seen.append(now.map { "\($0.identifier):\($0.label)" } ?? "nothing")
            // Lets focus settle on the next row before pressing along it.
            if !viewAllFocused { XCUIRemote.shared.press(.down); sleep(1) }
        }
        if !viewAllFocused { shot("no view all"); return fail("no row ends in View all; focus ended rows on \(seen)") }
        shot("home view all card")
        XCUIRemote.shared.press(.select)
        #else
        let viewAll = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.' AND identifier ENDSWITH '.viewAll'")).firstMatch
        // Clear of iPhone's floating tab bar, which a tap there reaches instead.
        let clear = { [self] in onScreen(viewAll) && viewAll.frame.maxY < app.windows.firstMatch.frame.maxY - 140 }
        // Steps shorter than the band where the link counts as clear: a short Mac window doesn't scroll past it.
        for _ in 0..<16 where !clear() {
            scrollDown(120)
        }
        XCTAssertTrue(clear(), "a hub's heading opens View all")
        shot("home hubs")
        hit(viewAll)
        #endif
        require("hubDetail", timeout: 20, "the hub's View all")
    }

    #if !os(tvOS)
    /// Home's shortcuts, chips under Continue Watching as on Apple TV: Watch Together before Downloads, then a
    /// chip per library where no sidebar lists the libraries (iPhone), on iPhone the profile menu last; nothing
    /// in a bar (no ⋯). Where the sidebar lists them (iPad, the Mac) Home has no library chips, its own chips stay.
    /// ⌘R reloads Home; a library's chip opens it in Libraries; Settings is its tab.
    func testHomeShortcuts() throws {
        #if os(iOS)
        if sidebarListsLibraries {
            // Landscape, where the kept sidebar sits beside Home rather than over it.
            XCUIDevice.shared.orientation = .landscapeLeft
            addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        }
        #endif
        try launch("home", settings: sidebarListsLibraries ? ["always_keep_sidebar_open=true"] : [])
        require("home.screen", timeout: 60, "Home")
        let continueWatching = require("hub.continue_watching", timeout: 30, "Continue Watching")
        let shortcuts = require("home.shortcuts", "Home's shortcut chips")
        XCTAssertLessThan(continueWatching.frame.minY, shortcuts.frame.minY, "the chips under Continue Watching")
        let watch = require("home.watchTogether", "Watch Together's chip")
        let downloads = element("home.downloads")
        if downloads.exists {
            XCTAssertLessThan(watch.frame.minX, downloads.frame.minX, "Watch Together before Downloads")
        }
        XCTAssertFalse(element("home.more").exists, "no ⋯ menu: Home's actions are its chips")
        requireSpokenNames(in: shortcuts, "Home's chips")
        let libraries = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'home.library.'"))
        if sidebarListsLibraries {
            // The sidebar's rows are the libraries' only list; Home's own chips stay.
            let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.'")).firstMatch
            XCTAssertTrue(row.exists(within: 30), "the sidebar lists the libraries")
            // Lets the chips and artwork finish drawing before the shot.
            sleep(2)
            shot("home shortcuts beside the sidebar")
            #if os(macOS)
            watch.hover()
            sleep(1)
            shot("home chip hovered")
            #endif
            XCTAssertEqual(libraries.count, 0, "no library chips where the sidebar lists the libraries")
            app.typeKey("r", modifierFlags: .command)
            XCTAssertTrue(element("hub.continue_watching").exists(within: 30), "Home back after ⌘R")
            XCTAssertTrue(watch.exists(within: 10), "Home's own chips after ⌘R")
            XCTAssertEqual(libraries.count, 0, "no library chips after ⌘R")
        } else {
            // The libraries' chips after Home's own, each named for a library of the server.
            let library = require("home.library.0", "the first library's chip")
            XCTAssertLessThan((downloads.exists ? downloads : watch).frame.minX, library.frame.minX, "the libraries after Home's own chips")
            let name = library.label
            requireServerLibrary(name)
            let lastLibrary = libraries.element(boundBy: max(libraries.count - 1, 0))
            XCTAssertLessThan(lastLibrary.frame.minX, require("home.userMenu", "iPhone's profile chip").frame.minX, "the profile chip last")
            shot("home shortcuts")
            scrollShortcuts(to: lastLibrary)
            // Lets the row's scroll come to rest before the shot.
            sleep(1)
            shot("home library chips")
            app.typeKey("r", modifierFlags: .command)
            XCTAssertTrue(element("hub.continue_watching").exists(within: 30), "Home back after ⌘R")
            scrollShortcuts(to: library)
            hit(library)
            requireLibrarySelected(name)
            shot("library from its chip")
        }
        let settings = require("nav.settings", "the Settings tab")
        #if os(macOS)
        settings.click()
        #else
        settings.tap()
        #endif
        require("settings.screen", timeout: 15, "Settings from its tab")
    }

    /// A sidebar lists the libraries, so Home leaves out their chips: iPad (full screen, regular width) and the Mac.
    private var sidebarListsLibraries: Bool {
        #if os(macOS)
        true
        #else
        UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    /// Beside a second server (`PLEZY_SECOND_SERVER`, the Emby test server, whose libraries share the first's
    /// names) the chips of namesakes name their servers after their titles; the first chip of the second server's opens
    /// its library in Libraries. Where the sidebar lists the libraries (iPad, the Mac) Home has no library chips.
    func testLibraryChipsNameTheirServers() throws {
        try XCTSkipIf(sidebarListsLibraries, "the sidebar lists the libraries: Home has no library chips")
        guard let second = ProcessInfo.processInfo.environment["PLEZY_SECOND_SERVER"].flatMap({ $0.isEmpty ? nil : $0 }) else {
            throw XCTSkip("PLEZY_SECOND_SERVER names no second server")
        }
        launchDev(arguments: ["--dev-server", try server(), "--dev-server", second, "--dev-open", "home"])
        require("home.screen", timeout: 60, "Home")
        require("home.shortcuts", timeout: 30, "Home's shortcut chips")
        let named = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'home.library.' AND label CONTAINS ' · '")).firstMatch
        guard named.exists(within: 60) else {
            shot("library chips without servers")
            return fail("no library's chip names its server beside a namesake")
        }
        let firstServer = named.label.components(separatedBy: " · ").last ?? ""
        let other = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'home.library.' AND label CONTAINS ' · ' AND NOT label ENDSWITH %@", " · \(firstServer)"
        )).firstMatch
        guard other.exists(within: 30) else { return fail("no chip of the second server's names it beside \(named.label)") }
        // Where the first server's chips meet the second's.
        scrollShortcuts(to: other)
        // Lets the row's scroll come to rest before the shot.
        sleep(2)
        shot("home library chips two servers")
        let title = other.label.components(separatedBy: " · ")[0]
        hit(other)
        requireLibrarySelected(title)
        shot("library from a second server's chip")
    }

    /// Home's shortcut row scrolled sideways until `chip` is within the window.
    private func scrollShortcuts(to chip: XCUIElement) {
        let row = element("home.shortcuts")
        let window = app.windows.firstMatch.frame
        let within = { chip.frame.maxX <= window.maxX && chip.frame.minX >= window.minX }
        for _ in 0..<12 where !within() {
            let frame = chip.frame
            let forward = frame.maxX > window.maxX
            #if os(macOS)
            row.scroll(byDeltaX: forward ? -300 : 300, deltaY: 0)
            #else
            // A held drag by the chip's overhang, up to most of the window's width: a swipe flings the row past it.
            let shift = min(forward ? frame.maxX - window.maxX : window.minX - frame.minX, window.width * 0.7) + 24
            let start = row.coordinate(withNormalizedOffset: CGVector(dx: forward ? 0.9 : 0.1, dy: 0.5))
            start.press(
                forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: forward ? -shift : shift, dy: 0)),
                withVelocity: .slow, thenHoldForDuration: 0.3
            )
            #endif
            _ = waitUntil(1) { within() }
        }
        if !within() { fail("Home's shortcuts don't scroll to \(chip.label)") }
    }

    #if os(iOS)
    /// Home's chips press like glass buttons, lighting up and swelling under a finger (a held press on
    /// Watch Together, slid off so it doesn't run; the run's recording shows it mid-press), and a card's menu entry over
    /// the chips still runs: the chips' glass stops taking touches while a menu is open (`OpenItemMenu`). The entry is
    /// one that changes nothing (Show link, File Info): its sheet shows it ran. Home Videos is hidden first (Manage
    /// libraries, this session's own setting): its short shelf would sit between Codec Samples' and Movies', leaving
    /// Movies' cards too low on the screen to press, and the cards above open their menus below the chips.
    func testHomeChipsPressAndLetMenusOverThemRun() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        require("libraries.library", timeout: 60, "the library menu")
        setVisibility("Home Videos")
        element("nav.home").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        require("home.screen", timeout: 60, "Home")
        let shortcuts = require("home.shortcuts", timeout: 30, "Home's shortcut chips")
        let watch = require("home.watchTogether", "Watch Together's chip")
        _ = waitUntil(5) { watch.isHittable }
        let start = watch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 2, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 160)), withVelocity: .slow, thenHoldForDuration: 0.5)
        // Gives a stray run of the chip time to show before checking it didn't run.
        sleep(1)
        XCTAssertTrue(watch.exists, "Watch Together's chip, slid off, doesn't run")
        shot("home chips after a press")
        let chips = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'home.'"))
            .allElementsBoundByIndex.map(\.identifier).filter { $0 != "home.shortcuts" && $0 != "home.screen" && $0 != "home.rail" }
        guard let entry = menuEntryOverGlass(
            chips, pressing: NSPredicate(format: "identifier BEGINSWITH 'card.' AND NOT identifier ENDSWITH '.menu'"),
            below: shortcuts.frame.maxY, allowed: ["menu.show_link", "menu.fileinfo"]
        ) else {
            if UIDevice.current.userInterfaceIdiom == .pad { throw XCTSkip("no card's menu opens over Home's chips") }
            return fail("no card's menu opens over Home's chips")
        }
        shot("\(entry.id) over \(entry.glass)")
        tap(at: entry.point)
        if !element(entry.id).waitForNonExistence(timeout: 5) {
            fail("\(entry.id) over \(entry.glass) doesn't run: the menu stays open")
        }
        let sheet = entry.id == "menu.show_link" ? "menu.link" : "menu.fileInfo"
        require(sheet, timeout: 15, "\(entry.id)'s sheet")
        shot("after \(entry.id)")
    }
    #endif
    #endif

    #if os(macOS)
    /// With the Mac's keyboard: Tab moves through Home's cards to a row's View all card, and Return there opens the
    /// hub's View all.
    func testHomeKeysReachViewAll() throws {
        try requireKeyboardNavigation()
        // Into Home from Search's field by ⌘1, so the keys are in the content rather than the sidebar's list.
        try launch("search")
        require("search.field", timeout: 60, "Search's field")
        _ = waitUntil(5) { keyboardFocus == "search.field" }
        app.typeKey(.escape, modifierFlags: [])
        app.typeKey("1", modifierFlags: .command)
        require("home.screen", timeout: 60, "Home")
        require("hub.continue_watching", timeout: 30, "Continue Watching")
        var tabs = 0
        for _ in 0..<80 where keyboardFocus != "hub.viewAll" {
            let before = keyboardFocus
            app.typeKey(.tab, modifierFlags: [])
            // The probe reads the focus four times a second, slower than the keys come: a Tab read before it moved on
            // passes the View all card unseen.
            _ = waitUntil(1) { keyboardFocus != before }
            tabs += 1
            if tabs == 3 {
                // The focused card's backdrop fades in for the shot.
                sleep(1)
                shot("home keys on a card")
            }
        }
        shot("view all card focused")
        guard keyboardFocus == "hub.viewAll" else { return fail("Tab never reached a View all card, focus on \(keyboardFocus)") }
        app.typeKey(.return, modifierFlags: [])
        require("hubDetail", timeout: 20, "Return on the card opens the hub's View all")
    }
    #endif

    // MARK: - Continue Watching

    /// Continue Watching takes the server's latest as Home shows again, and on Apple TV focus
    /// follows its card when the row reorders. Signed in as an account of the test's own, whose row holds only what the
    /// test plays: Maestro Show's episode leads the row, Resume Movie second; then the server records Resume Movie as
    /// played now (the test server's clips are too short for a real playback to keep a position), which the row doesn't
    /// take while Home stays in view. iPhone, iPad and the Mac: a hub's card opened and closed again, Resume Movie leads
    /// the row. Apple TV, its card focused: the app back at the front refreshes the row, Resume Movie leads it with focus
    /// still on it; then Second Show's Pilot (in the row from the start), its card focused,
    /// marked watched on the server leaves the row on the next return, and focus moves to the show's Second Episode that
    /// replaces it.
    func testContinueWatchingRefreshesAsHomeShows() throws {
        let records = try WatchRecords.ownAccount(on: server())
        addTeardownBlock { try records.removeAccount() }
        try records.set("Maestro Episode 2", seconds: 70, ago: 0)
        try records.set("Resume Movie", seconds: 90, ago: 60)
        #if os(tvOS)
        try records.set("Pilot", seconds: 40, ago: 120)
        #endif
        launchDev(arguments: ["--dev-server", records.server, "--dev-open", "home"])
        require("home.screen", timeout: 60, "Home")
        require("hub.continue_watching", timeout: 30, "Continue Watching")
        if !waitUntil(10, { continueWatching().prefix(2) == ["Maestro Show", "Resume Movie"] }) {
            return fail("Continue Watching starts \(continueWatching()), not Maestro Show then Resume Movie")
        }
        #if os(tvOS)
        // Onto Resume Movie's card (Home's first focus is testHomeHubsAndViewAll's).
        // The focus engine drops presses made before Home settles its first focus.
        sleep(2)
        let onCard = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'card.'")).firstMatch
        steps.tvFocus([(.up, 2), (.left, 4), (.right, 1)]) { onCard.exists && onCard.label == "Resume Movie" }
        #endif
        try records.set("Resume Movie", seconds: 90, ago: -60)
        // Gives a stray refresh time to show before checking the row stayed as it was.
        sleep(4)
        XCTAssertEqual(Array(continueWatching().prefix(2)), ["Maestro Show", "Resume Movie"], "the row stays as it was while Home shows")
        #if os(tvOS)
        backToTheFront()
        #else
        openAndCloseAHubCard()
        #endif
        if !waitUntil(20, { continueWatching().first == "Resume Movie" }) {
            shot("continue watching not refreshed")
            return fail("Continue Watching doesn't take the server's latest as Home shows again: \(continueWatching())")
        }
        shot("continue watching refreshed")
        #if os(tvOS)
        if !waitUntil(5, { focusedCard(within: 1)?.label == "Resume Movie" && isFirstInContinueWatching(focusedCard(within: 1)) }) {
            return fail("focus didn't follow Resume Movie's card to the row's front")
        }

        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.right)
        guard waitUntil(3, { focusedCard(within: 1)?.label == "Second Show" }), let episode = focusedCard(within: 1)?.identifier else {
            return fail("Right doesn't reach Second Show's card: \(continueWatching())")
        }
        try records.set("Pilot", seconds: 0, played: true, ago: -120)
        backToTheFront()
        let replaced = waitUntil(30) {
            guard let focused = focusedCard(within: 1) else { return false }
            return !element(episode).exists && focused.label == "Second Show" && focused.identifier != episode
        }
        shot("continue watching replaced")
        if !replaced { fail("focus didn't move to the show's next episode as the watched one left: \(continueWatching())") }
        #endif
    }

    /// Picking the Home tab while Home shows refreshes it: Continue Watching takes the server's latest (Resume
    /// Movie, played on the server after Home loaded, comes to the front), signed in as an account of the test's own. On
    /// Apple TV through the tab bar: Up to it from the first shelf, then Select on Home.
    func testPickingHomeAgainRefreshesIt() throws {
        let records = try WatchRecords.ownAccount(on: server())
        addTeardownBlock { try records.removeAccount() }
        try records.set("Maestro Episode 2", seconds: 70, ago: 0)
        try records.set("Resume Movie", seconds: 90, ago: 60)
        launchDev(arguments: ["--dev-server", records.server, "--dev-open", "home"])
        require("home.screen", timeout: 60, "Home")
        require("hub.continue_watching", timeout: 30, "Continue Watching")
        if !waitUntil(10, { continueWatching().first == "Maestro Show" }) {
            return fail("Continue Watching starts \(continueWatching()), not Maestro Show")
        }
        try records.set("Resume Movie", seconds: 90, ago: -60)
        // Gives a stray refresh time to show before checking the row stayed as it was.
        sleep(3)
        XCTAssertEqual(continueWatching().first, "Maestro Show", "the row stays as it was until Home is picked again")
        #if os(tvOS)
        guard focusedCard(within: 15) != nil else { return fail("no card took focus as Home loaded") }
        for _ in 0..<3 where !tabBarFocused { XCUIRemote.shared.press(.up); _ = waitUntil(1) { tabBarFocused } }
        guard element("nav.home").hasFocus else { return fail("Up from the first shelf doesn't reach Home's tab") }
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        element("nav.home").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        element("nav.home").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #endif
        if !waitUntil(20, { continueWatching().first == "Resume Movie" }) {
            shot("home picked again not refreshed")
            return fail("picking Home again doesn't refresh Continue Watching: \(continueWatching())")
        }
        shot("home picked again refreshed")
    }

    #if os(tvOS)
    /// The app sent to the Home screen and brought back (Continue Watching refreshes as the app comes back to the front).
    private func backToTheFront() {
        XCUIRemote.shared.press(.home)
        // Leaves the app in the background a moment; nothing in it signals the system's Home screen.
        sleep(3)
        app.activate()
    }
    #endif

    /// Continue Watching's card titles, left to right.
    private func continueWatching() -> [String] {
        let cards = element("hub.continue_watching").descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND NOT identifier ENDSWITH '.menu'")).allElementsBoundByIndex
        var seen = Set<String>()
        return cards.filter { seen.insert($0.identifier).inserted }.sorted { $0.frame.minX < $1.frame.minX }.map(\.label)
    }

    #if os(tvOS)
    private func isFirstInContinueWatching(_ card: XCUIElement?) -> Bool {
        guard let card else { return false }
        let cards = element("hub.continue_watching").descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND NOT identifier ENDSWITH '.menu'")).allElementsBoundByIndex
        return cards.min { $0.frame.minX < $1.frame.minX }?.identifier == card.identifier
    }
    #else
    /// Opens the first card of a hub other than Continue Watching (its detail over Home) and goes back to Home.
    private func openAndCloseAHubCard() {
        let hub = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'hub.' AND NOT identifier BEGINSWITH 'hub.continue_watching' AND NOT identifier CONTAINS 'viewAll' AND NOT identifier == 'hub.totalResults'"
        )).firstMatch
        let card = hub.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND NOT identifier ENDSWITH '.menu'")).firstMatch
        // Clear of the tab bar at the foot, which would take the press.
        let window = app.windows.firstMatch.frame
        for _ in 0..<6 where !(onScreen(card) && card.frame.maxY < window.maxY - 160) { scrollDown() }
        hit(card)
        require("detail.screen", timeout: 20, "the hub card's detail over Home")
        // Lets the detail finish pushing in; a back press during it is dropped.
        sleep(2)
        #if os(macOS)
        app.buttons.matching(identifier: "chevron.backward").firstMatch.click()
        #else
        backButton.tap()
        #endif
        require("home.screen", timeout: 20, "Home again")
        for _ in 0..<3 {
            #if os(macOS)
            element("home.screen").scroll(byDeltaX: 0, deltaY: 300)
            #else
            app.swipeDown()
            #endif
        }
    }
    #endif

    // MARK: - Libraries

    /// The library picked from the library menu (iPhone, iPad, Apple TV) or the Mac's sidebar, opened fresh on Browse
    /// (no saved tab), its grid loaded; Browse's grouping, sort and filters, the alphabet index's Z, then
    /// Recommended and Collections from the view menu.
    func testLibraryTabsSheetsAndAlphabet() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        require("libraries.view", timeout: 30, "the view menu")
        require("libraries.grid", timeout: 30, "the Browse grid, a fresh library's first tab")
        #if os(tvOS)
        // Focus enters the library on its first item.
        XCTAssertNotNil(focusedCard(within: 15), "the library's first item takes focus")
        #endif
        XCTAssertTrue(anyCard.firstMatch.exists(within: 30), "the grid's items")
        // Lets the grid's artwork load before the shot; nothing signals it.
        sleep(3)
        shot("libraries opened on browse")
        sheets()
        alphabet()

        steps.showLibraryTab("recommended")
        require("libraries.recommended", timeout: 30, "Recommended")
        XCTAssertTrue(anyCard.firstMatch.exists(within: 30), "Recommended's hubs")
        // Lets the hubs' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("libraries recommended")

        steps.showLibraryTab("collections")
        let picks = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label == 'Plezy Picks'")).firstMatch
        XCTAssertTrue(picks.exists(within: 30), "the collection Plezy Picks")
        // Lets the collections' artwork load before the shot; nothing signals it.
        sleep(2)
        shot("libraries collections")
    }

    func testLibraryList() throws {
        try launch("libraries", settings: ["view_mode=list"])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse list")
        XCTAssertTrue(anyCard.firstMatch.exists(within: 30), "the list's rows")
        // Lets the rows' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("libraries list")
    }

    #if os(tvOS)
    /// Menu from deep in the grid, from the grid after a letter of the alphabet index filtered it, and once Select on
    /// the letter cleared it, reaches Libraries' tab with the app still answering, and Down leaves it.
    func testRailFromTheGridAfterALetter() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        require("libraries.grid", timeout: 30, "the Browse grid")
        XCTAssertNotNil(steps.focusedCard(within: 15), "the grid's first item takes focus")
        for _ in 0..<6 {
            XCUIRemote.shared.press(.down)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(400_000)
        }
        tabBarAndBack("deep in the grid")

        let z = require("libraries.alpha.Z", timeout: 20, "the alphabet index's Z")
        steps.tvFocus([(.down, 2), (.right, 12)]) { z.hasFocus || alphaFocused }
        steps.tvFocus([(.down, 30)]) { z.hasFocus }
        XCTAssertTrue(steps.card(prefix: "Zulu").exists(within: 15), "the Z titles")
        // The focus engine drops a press made while the grid still reloads under Z.
        sleep(2)
        XCUIRemote.shared.press(.left)
        XCTAssertNotNil(steps.focusedCard(within: 5), "Left from the index goes back to the grid")
        tabBarAndBack("with the letter")

        steps.tvFocus([(.down, 2), (.right, 12)]) { z.hasFocus || alphaFocused }
        steps.tvFocus([(.down, 30)]) { z.hasFocus }
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(steps.card(prefix: "Alpha Archive").exists(within: 15), "Select on the active Z clears the letter")
        // The focus engine drops a press made while the grid still reloads.
        sleep(2)
        XCUIRemote.shared.press(.left)
        XCTAssertNotNil(steps.focusedCard(within: 5), "Left from the index goes back to the grid")
        tabBarAndBack("after the letter")
    }

    /// Menu until the tab bar holds focus, on Libraries; the app answers there, and Down leaves it.
    private func tabBarAndBack(_ when: String) {
        for _ in 0..<4 where !steps.tabBarFocused {
            XCUIRemote.shared.press(.menu)
            _ = waitUntil(0.8) { steps.tabBarFocused }
        }
        XCTAssertTrue(element("nav.libraries").hasFocus, "Libraries' tab holds focus \(when)")
        shot("tab bar \(when)")
        XCUIRemote.shared.press(.down)
        XCTAssertTrue(waitUntil(10) { !steps.tabBarFocused }, "Down leaves the tab bar \(when)")
        // Lets focus settle in the content before the next press.
        sleep(2)
    }
    #endif

    func testPlaylistsTabOpensAPlaylist() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Shows")
        steps.showLibraryTab("playlists")
        let binge = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label == 'Binge'")).firstMatch
        XCTAssertTrue(binge.exists(within: 30), "the playlist Binge")
        // Lets the playlists' artwork load before the shot; nothing signals it.
        sleep(2)
        shot("libraries playlists")
        #if os(tvOS)
        steps.tvFocus([(.down, 3)]) {
            app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND label BEGINSWITH 'Binge'")).firstMatch.exists
        }
        XCUIRemote.shared.press(.select)
        #else
        hit(binge)
        #endif
        require("playlist", timeout: 30, "Binge's screen")
        require("playlist.row.2", timeout: 30, "Binge's third row")
        // Lets the playlist's artwork load before the shot; nothing signals it.
        sleep(2)
        shot("playlist detail")
    }

    /// Shuffle on the Music library (the header row's, else a phone's ⋯ menu's) starts a shuffled queue of its tracks,
    /// shuffle on, with a next track: on the Mac in the playback bar; elsewhere in Now Playing (from the mini-player;
    /// Apple TV opens it at once), which plays from Music.
    func testMusicLibraryShuffles() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Music")
        require("libraries.grid", timeout: 30, "the Music library's Browse grid")
        XCTAssertTrue(anyCard.firstMatch.exists(within: 30), "the library's artists")
        // Lets the artists' artwork load before the shot; nothing signals it.
        sleep(2)
        shot("music library")
        let shuffle = element("libraries.shuffle")
        #if os(iOS)
        if !shuffle.exists(within: 5) {
            let more = require("libraries.more", timeout: 10, "the ⋯ menu")
            let glyph = more.images["ellipsis"]
            (glyph.exists ? glyph : more).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(shuffle.exists(within: 10), "Music's Shuffle in the ⋯ menu, which the row has no room for")
            shot("music shuffle in more")
        }
        #else
        XCTAssertTrue(shuffle.exists(within: 10), "Music's Shuffle in the header row")
        #endif
        steps.press(shuffle)
        #if os(macOS)
        require("music.bar", timeout: 30, "the playback bar")
        let shuffled = require("music.bar.shuffle", "the playback bar's Shuffle")
        let next = require("music.bar.next", "the playback bar's Next")
        #else
        #if os(iOS)
        require("music.mini", timeout: 30, "the mini-player")
        // Lets the mini-player's artwork load before the shot; nothing signals it.
        sleep(3)
        shot("music library shuffled")
        steps.press(require("music.mini.open", "the mini-player's track"))
        #endif
        require("music.np.screen", timeout: 30, "Now Playing")
        let from = require("music.np.playingFrom", "Now Playing's Playing from")
        XCTAssertTrue(from.label.contains("Music"), "Now Playing plays from Music (\(from.label))")
        let shuffled = require("music.np.shuffle", "Now Playing's Shuffle")
        let next = require("music.np.next", "Now Playing's Next")
        #endif
        XCTAssertTrue(waitUntil(5) { (shuffled.value as? String) == "On" }, "Shuffle is on (\(String(describing: shuffled.value)))")
        XCTAssertTrue(next.isEnabled, "the shuffled queue has a next track")
        // Lets Now Playing's artwork load before the shot; nothing signals it.
        sleep(2)
        shot("music library now playing")
    }

    /// Manage libraries (the ⋯ menu; Apple TV: the header row's button) hides Home Videos and shows it again: the
    /// library menu drops it and lists it again; the Mac's sidebar moves it to its hidden group and back.
    func testManageLibrariesHidesAndShows() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        require("libraries.library", timeout: 60, "the library menu")
        let library = "Home Videos"
        XCTAssertTrue(listed(library), "\(library) among the libraries")
        shot("library list")

        setVisibility(library)
        #if os(macOS)
        XCTAssertTrue(element("nav.hiddenLibraries").exists(within: 10), "the sidebar's hidden libraries group")
        #endif
        XCTAssertFalse(listed(library), "\(library) left the visible libraries")
        shot("library list hidden")

        setVisibility(library)
        XCTAssertTrue(listed(library), "\(library) back among the libraries")
        XCTAssertFalse(element("nav.hiddenLibraries").exists, "no hidden libraries")
    }

    #if os(macOS)
    /// The sidebar's Hidden libraries group opens and closes from a click on its title, as from its chevron: closed at
    /// first, a click at the title's trailing end opens it (its library listed), a click on the title's middle closes
    /// it, its chevron opens and closes it still.
    func testClickingTheHiddenLibrariesTitleTogglesTheGroup() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        let library = "Home Videos"
        require("nav.library.\(library)", timeout: 60, "\(library) in the sidebar")
        sleep(2)
        shot("sidebar")
        setVisibility(library)
        let title = require("nav.hiddenLibraries", timeout: 10, "the sidebar's hidden libraries group")
        let hidden = element("nav.library.\(library)")
        XCTAssertFalse(hidden.exists, "the hidden libraries group starts closed")
        shot("sidebar hidden closed")
        title.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).click()
        XCTAssertTrue(hidden.exists(within: 5), "a click at the title's trailing end opens the group")
        sleep(1)
        shot("sidebar hidden open")
        title.hover()
        sleep(1)
        shot("sidebar hidden title hovered")
        hit(title)
        XCTAssertTrue(hidden.waitForNonExistence(timeout: 5), "a click on the title closes the group")
        shot("sidebar hidden closed again")
        let chevron = app.outlineRows.containing(.any, identifier: "nav.hiddenLibraries").disclosureTriangles.firstMatch
        chevron.click()
        XCTAssertTrue(hidden.exists(within: 5), "the chevron opens the group")
        chevron.click()
        XCTAssertTrue(hidden.waitForNonExistence(timeout: 5), "the chevron closes the group")
        setVisibility(library)
    }

    /// The Mac's library header names the library the sidebar picked and offers no picker of its own: Movies, then
    /// Shows, each picked in the sidebar.
    func testMacLibraryHeaderNamesTheLibraryWithoutAPicker() throws {
        try launch("libraries")
        require("libraries.screen", timeout: 60, "Libraries")
        for library in ["Movies", "Shows"] {
            steps.pickLibrary(library)
            let title = require("libraries.library", timeout: 30, "the library's name in the header")
            let name = { (title.value as? String).flatMap { $0.isEmpty ? nil : $0 } ?? title.label }
            if !waitUntil(10, { name() == library }) { fail("the header names \(name()), not \(library)") }
            XCTAssertFalse(app.menuButtons["libraries.library"].exists, "no library picker in the header")
            require("libraries.view", "the view menu beside the name")
            shot("library header \(library)")
        }
        element("libraries.library").hover()
        sleep(2)
        shot("library header title hovered")
    }
    #endif

    /// Whether the library menu (the Mac: the sidebar) lists `library`, the menu closed again.
    private func listed(_ library: String) -> Bool {
        #if os(macOS)
        return element("nav.library.\(library)").exists(within: 5)
        #else
        steps.openFilterMenu("libraries.library")
        let shown = steps.option("libraries.library", label: library).exists(within: 3)
        steps.dismissMenu()
        XCTAssertTrue(steps.option("libraries.library").waitForNonExistence(timeout: 10), "the library menu closed")
        return shown
        #endif
    }

    // MARK: - Steps

    /// Browse's grouping and sort menus and its filters' sheet, each shot, closed without a change.
    private func sheets() {
        for (id, name) in [("libraries.sort", "sort"), ("libraries.grouping", "grouping")] {
            steps.openFilterMenu(id)
            // Lets the menu finish opening before the shot.
            sleep(1)
            shot("libraries \(name)")
            steps.dismissMenu()
            XCTAssertTrue(steps.option(id).waitForNonExistence(timeout: 10), "the \(name) menu closed")
        }
        steps.pressInHeader("libraries.filters", "the Filters capsule")
        let field = steps.prefixed("libraries.filter.")
        XCTAssertTrue(field.exists(within: 10), "the filters' fields")
        // Lets the sheet finish opening before the shot.
        sleep(1)
        shot("libraries filters")
        closeSheet()
        XCTAssertTrue(field.waitForNonExistence(timeout: 10), "the filters closed")
    }

    /// Closes the open sheet: a swipe down (iPhone), its Close (iPad), Escape (the Mac), Menu (Apple TV).
    private func closeSheet() {
        #if os(iOS)
        if element("sheet.close").exists {
            element("sheet.close").tap()
        } else {
            app.swipeDown(velocity: .fast)
        }
        #elseif os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #else
        XCUIRemote.shared.press(.menu)
        #endif
    }

    /// The alphabet index's Z brings the Z titles into view. Apple TV: Right from the grid's last column reaches the
    /// index, Down to Z jumps there once the moves settle, Select on the active letter clears it again (Jellyfin and
    /// Emby filter by the letter), Left goes back to the grid.
    private func alphabet() {
        let z = require("libraries.alpha.Z", timeout: 20, "the alphabet index's Z")
        #if os(tvOS)
        steps.tvFocus([(.down, 2), (.right, 12)]) { z.hasFocus || alphaFocused }
        shot("libraries alphabet focus")
        steps.tvFocus([(.down, 30)]) { z.hasFocus }
        #elseif os(macOS)
        z.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        z.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #endif
        let zulu = steps.card(prefix: "Zulu")
        if !(zulu.exists(within: 15) && waitUntil(10, { steps.onScreen(zulu) })) {
            fail("the Z titles in view after the alphabet index's Z")
        }
        // Lets the reloaded artwork draw before the shot; on Apple TV also gives a stray focus move time to show.
        sleep(2)
        shot("libraries alphabet Z")
        #if os(tvOS)
        XCTAssertTrue(z.hasFocus, "the index keeps focus while the items reload")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(steps.card(prefix: "Alpha Archive").exists(within: 15), "Select on the active Z clears the letter")
        XCUIRemote.shared.press(.left)
        XCTAssertNotNil(steps.focusedCard(within: 5), "Left from the index goes back to the grid")
        #endif
    }

    /// Manage libraries' switch of `library` on its settings page, then back to Libraries.
    private func setVisibility(_ library: String) {
        steps.openManageLibraries()
        let toggle = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'settings.libraries.row.' AND label CONTAINS %@", library)).firstMatch
        XCTAssertTrue(toggle.exists(within: 10), "\(library)'s switch")
        #if os(tvOS)
        steps.tvFocus([(.down, 12), (.up, 12)]) { steps.hasFocus(toggle) }
        // Lets the focused row's lift finish before the shot.
        sleep(1)
        shot("manage libraries")
        XCUIRemote.shared.press(.select)
        // Lets the switch's change save before Menu leaves the page.
        sleep(2)
        XCUIRemote.shared.press(.menu)
        #else
        // Lets the page finish pushing in before the shot.
        sleep(1)
        shot("manage libraries")
        hit(toggle)
        // Lets the switch's change save before Back leaves the page.
        sleep(2)
        #if os(macOS)
        app.buttons.matching(identifier: "chevron.backward").firstMatch.click()
        #else
        backButton.tap()
        #endif
        #endif
        require("libraries.screen", timeout: 20, "Libraries again")
        // Lets the libraries reload; callers check one is gone, which nothing else signals.
        sleep(2)
    }

    // MARK: - Helpers

    private var steps: LibrarySteps { LibrarySteps(test: self) }

    /// `name`, a library chip's label, is one of the server's libraries (where the server is Jellyfin, whose API lists
    /// them).
    private func requireServerLibrary(_ name: String) {
        guard let records = try? WatchRecords(server: server()) else { return }
        do {
            let names = try records.libraries()
            XCTAssertTrue(names.contains(name), "the library chip's \(name) is none of the server's libraries \(names)")
        } catch {
            fail("the server's libraries: \(error)")
        }
    }

    /// Libraries shows with the library `name` selected (its library menu names it), as a library's chip opens it.
    private func requireLibrarySelected(_ name: String) {
        require("libraries.screen", timeout: 20, "Libraries from the library's chip")
        let menu = require("libraries.library", timeout: 30, "Libraries' library menu")
        // The menu's label (a Mac menu button's title).
        let shown = { menu.label.isEmpty ? menu.title : menu.label }
        if !waitUntil(15, { shown() == name }) { fail("the chip of \(name) opened Libraries on \(shown())") }
    }

    private var anyCard: XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
    }

    private func onScreen(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        return !frame.isEmpty && app.windows.firstMatch.frame.insetBy(dx: 0, dy: 40).contains(frame)
    }

    /// A press on `target`'s own frame (a tap, a click).
    private func hit(_ target: XCUIElement) {
        #if os(macOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #elseif os(iOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #endif
        // Paces presses: a press during the previous one's transition is dropped.
        sleep(1)
    }

    /// On the Mac `points` down; elsewhere a swipe.
    private func scrollDown(_ points: CGFloat = 300) {
        #if os(macOS)
        element("home.screen").scroll(byDeltaX: 0, deltaY: -points)
        #elseif os(iOS)
        app.swipeUp()
        #endif
        // Lets the scroll come to rest before frames are read.
        sleep(1)
    }

    #if os(tvOS)
    private var viewAllFocused: Bool { steps.focused(prefix: "hub.viewAll") }
    private var alphaFocused: Bool { steps.focused(prefix: "libraries.alpha.") }

    private func focusedCard(within seconds: Int) -> XCUIElement? { steps.focusedCard(within: seconds) }
    private var tabBarFocused: Bool { steps.tabBarFocused }
    private func focused(prefix: String) -> Bool { steps.focused(prefix: prefix) }
    #endif
}

/// The test server's watch records for an account, through its Jellyfin API: who played what and when, so Continue
/// Watching's order is known, and how much of a show is watched (`DetailEpisodesTests`); and its libraries. Signs in on
/// `server`, a `--dev-server` spec (`jellyfin=<user>:<password>@<url>`).
struct WatchRecords {
    struct Failure: LocalizedError, CustomStringConvertible {
        let description: String
        var errorDescription: String? { description }
    }

    /// The `--dev-server` spec of the account signed in.
    let server: String
    private let base: String
    /// The sign-in's own device: Jellyfin ends a device's earlier session as it signs in again, so a device shared with
    /// another run (or the administrator) would end that one's token.
    private let client: String
    private let token: String
    private let user: String
    /// The administrator's sign-in that added the account (`ownAccount`), which removes it.
    private var admin: (client: String, token: String)?

    init(server: String) throws {
        guard server.hasPrefix("jellyfin="), let at = server.lastIndex(of: "@"),
              let colon = server[server.index(server.startIndex, offsetBy: 9)..<at].firstIndex(of: ":") else {
            throw XCTSkip("the watch records are set through Jellyfin's API: \(server) is no Jellyfin server")
        }
        let name = String(server[server.index(server.startIndex, offsetBy: 9)..<colon])
        let password = String(server[server.index(after: colon)..<at])
        self.server = server
        base = String(server[server.index(after: at)...])
        client = "MediaBrowser Client=\"Plezy UI tests\", Device=\"ui-tests\", DeviceId=\"plezy-ui-tests-\(UUID().uuidString)\", Version=\"1\""
        let auth = try Self.call("POST", "\(base)/Users/AuthenticateByName", client: client, token: nil, body: ["Username": name, "Pw": password])
        guard let token = auth["AccessToken"] as? String, let user = (auth["User"] as? [String: Any])?["Id"] as? String else {
            throw Failure(description: "the sign-in as \(name) answered no token")
        }
        self.token = token
        self.user = user
    }

    /// A new account on `server`'s Jellyfin, added by its user (an administrator): every library, nothing played or
    /// started (blanked: `FreshAccountWatchState`), no other run signed in to it. Its Continue Watching holds only what
    /// the test sets, whatever other runs play as the server's own accounts meanwhile. `removeAccount()` deletes it.
    static func ownAccount(on server: String) throws -> WatchRecords {
        let admin = try WatchRecords(server: server)
        let name = "ui-tests-\(UUID().uuidString.prefix(8).lowercased())"
        _ = try call("POST", "\(admin.base)/Users/New", client: admin.client, token: admin.token, body: ["Name": name, "Password": name])
        var records = try WatchRecords(server: "jellyfin=\(name):\(name)@\(admin.base)")
        records.admin = (admin.client, admin.token)
        let (client, token) = (records.client, records.token)
        do {
            try FreshAccountWatchState.blank(kind: "jellyfin", base: records.base, user: records.user) {
                try call($0, $1, client: client, token: token, body: $2)
            }
        } catch {
            try? records.removeAccount()
            throw error
        }
        return records
    }

    /// Deletes the account `ownAccount` added.
    func removeAccount() throws {
        guard let admin else { throw Failure(description: "the account \(user) is none the test added") }
        _ = try Self.call("DELETE", "\(base)/Users/\(user)", client: admin.client, token: admin.token, body: nil)
    }

    /// `title` at `seconds` in, watched or not, last played `ago` seconds back (a negative `ago` in the future, so it
    /// outranks what the app's own playback records).
    func set(_ title: String, seconds: Int, played: Bool = false, ago: TimeInterval) throws {
        _ = try Self.call("POST", "\(base)/UserItems/\(id(of: title))/UserData?userId=\(user)", client: client, token: token, body: [
            "PlaybackPositionTicks": seconds * 10_000_000, "Played": played,
            "LastPlayedDate": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-ago)),
        ])
    }

    /// The names of the account's libraries (the server's views).
    func libraries() throws -> [String] {
        let views = try Self.call("GET", "\(base)/Users/\(user)/Views", client: client, token: token, body: nil)
        return (views["Items"] as? [[String: Any]])?.compactMap { $0["Name"] as? String } ?? []
    }

    /// The server's id of the episode or movie `title`.
    private func id(of title: String) throws -> String {
        let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let found = try Self.call("GET", "\(base)/Users/\(user)/Items?Recursive=true&IncludeItemTypes=Episode,Movie&SearchTerm=\(query)", client: client, token: token, body: nil)
        guard let id = (found["Items"] as? [[String: Any]])?.first(where: { $0["Name"] as? String == title })?["Id"] as? String else {
            throw Failure(description: "the test server has no \(title)")
        }
        return id
    }

    /// `method` `url`, waited for: its JSON answer (empty for none); an error unless it answered 2xx.
    private static func call(_ method: String, _ url: String, client: String, token: String?, body: [String: Any]?) throws -> [String: Any] {
        var request = URLRequest(url: URL(string: url)!, timeoutInterval: 15)
        request.httpMethod = method
        request.setValue(client, forHTTPHeaderField: "X-Emby-Authorization")
        if let token { request.setValue(token, forHTTPHeaderField: "X-Emby-Token") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let done = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var answer: Result<[String: Any], any Error> = .failure(Failure(description: "\(method) \(url) never answered"))
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { done.signal() }
            if let error { answer = .failure(error); return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else { answer = .failure(Failure(description: "\(method) \(url) answered \(status)")); return }
            answer = .success(data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:])
        }.resume()
        done.wait()
        return try answer.get()
    }
}
