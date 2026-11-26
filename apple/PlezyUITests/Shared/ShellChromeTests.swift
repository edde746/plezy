#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import XCTest

/// The shell's chrome against the server `PLEZY_DEV_SERVER` names: a destination keeps its screen (its scroll, the
/// screen over its root) while another shows, without its toolbar; on Apple TV the remote's Menu over a screen pushed
/// on Home (which hides the tab bar) pops that screen, and leaves the app only at Home's root.
final class ShellChromeTests: PlezyUITestCase {
    private func server() throws -> String {
        try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
    }

    private func launch(_ destination: String = "home", settings: [String] = []) throws {
        launchDev(settings: settings, arguments: ["--dev-server", try server(), "--dev-open", destination])
    }

    #if !os(tvOS)
    /// Home scrolled down, then Search, then Home again: Home is where it was left, not back at its top.
    func testADestinationKeepsItsScreenWhileAnotherShows() throws {
        try launch()
        require("home.screen", timeout: 60, "Home")
        let top = require("hub.continue_watching", timeout: 30, "Continue Watching")
        // Home's rows settle as the rest of its content comes.
        sleep(3)
        for _ in 0..<4 where onScreen(top) { scrollDown() }
        if onScreen(top) { fail("Home didn't scroll past Continue Watching") }
        shot("home scrolled")
        pick("nav.search")
        require("search.screen", "Search")
        pick("nav.home")
        require("home.screen", "Home again")
        // Gives Home time to come back where it was; checked after that it didn't go back to its top.
        sleep(1)
        shot("home again")
        XCTAssertFalse(onScreen(element("hub.continue_watching")), "Home kept its scroll: Continue Watching is still scrolled away")
    }

    /// Home scrolled down, then Movies (its row in the sidebar; Libraries' tab on the iPhone), then Home again: Home comes
    /// back on the row it was left on, at the same height.
    func testHomeComesBackOnTheRowItWasLeftOn() throws {
        #if os(iOS)
        let pad = UIDevice.current.userInterfaceIdiom == .pad
        if pad {
            launchDev(settings: ["always_keep_sidebar_open=true"], arguments: ["--dev-server", try server(), "--dev-open", "home"])
            // The sidebar beside the screens, as on the Mac.
            XCUIDevice.shared.orientation = .landscapeLeft
        } else {
            try launch()
        }
        let movies = pad ? "nav.library.Movies" : "nav.libraries"
        #else
        try launch()
        let movies = "nav.library.Movies"
        #endif
        require("home.screen", timeout: 90, "Home")
        let top = require("hub.continue_watching", timeout: 30, "Continue Watching")
        // Home's rows settle as the rest of its content comes.
        sleep(3)
        for _ in 0..<4 where onScreen(top) { scrollDown() }
        if onScreen(top) { fail("Home didn't scroll past Continue Watching") }
        // Lets the scroll come to rest before the rows are measured.
        sleep(1)
        let left = try XCTUnwrap(firstRowInSight(), "a row of Home's in sight")
        shot("home left")
        pick(movies)
        require("libraries.screen", timeout: 30, "Movies")
        pick("nav.home")
        require("home.screen", "Home again")
        let back = try XCTUnwrap(firstRowInSight(), "a row of Home's in sight again")
        shot("home again")
        XCTAssertEqual(back.id, left.id, "Home comes back on the row it was left on")
        XCTAssertEqual(back.top, left.top, accuracy: 2, "Home's first row in sight comes back at the same height")
    }

    /// The first of Home's rows (its hubs) whose foot is in sight under the window's top bars: its identifier and top.
    private func firstRowInSight() -> (id: String, top: CGFloat)? {
        let sight = app.windows.firstMatch.frame.minY + 80
        let rows = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'hub.' AND NOT identifier ENDSWITH '.viewAll' AND NOT (identifier IN %@)",
            ["hub.viewAll", "hub.totalResults"]
        )).allElementsBoundByIndex
        return rows.map { (id: $0.identifier, frame: $0.frame) }
            .filter { !$0.frame.isEmpty && $0.frame.maxY > sight }
            .min { $0.frame.minY < $1.frame.minY }
            .map { (id: $0.id, top: $0.frame.minY) }
    }

    #if os(macOS)
    /// A short window: the sidebar's list scrolls above its pinned footer (the running profile), which no row draws
    /// under.
    func testShortWindowSidebarListEndsAboveItsFooter() throws {
        try launch()
        require("home.screen", timeout: 60, "Home")
        let library = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.'")).firstMatch
        XCTAssertTrue(library.exists(within: 30), "the sidebar's libraries")
        resizeWindow(by: -440)
        sleep(1)
        shot("short window sidebar")
        let profile = require("nav.profile", "the sidebar's profile")
        let list = app.outlines.containing(.any, identifier: "nav.home").firstMatch
        XCTAssertTrue(list.exists, "the sidebar's list")
        // The footer's ground, above and below the profile, shows no row: one colour, where a row's name drew before.
        let window = app.windows.firstMatch
        let image = window.screenshot().image
        let cg = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let bitmap = NSBitmapImageRep(cgImage: cg)
        let scale = CGFloat(cg.width) / window.frame.width
        let xs = (list.frame.minX + 8)...(list.frame.maxX - 24)
        // Clear of the profile's edge and of the window's bottom edge, its border drawn there.
        for band in [(list.frame.maxY + 1)...(profile.frame.minY - 1), (profile.frame.maxY + 4)...(window.frame.maxY - 8)] where band.lowerBound < band.upperBound {
            var lightest: CGFloat = 0, darkest: CGFloat = 1
            for y in stride(from: band.lowerBound, through: band.upperBound, by: 1) {
                for x in stride(from: xs.lowerBound, through: xs.upperBound, by: 1) {
                    let px = Int((x - window.frame.minX) * scale), py = Int((y - window.frame.minY) * scale)
                    guard let colour = bitmap.colorAt(x: px, y: py)?.usingColorSpace(.deviceRGB) else { continue }
                    lightest = max(lightest, colour.brightnessComponent)
                    darkest = min(darkest, colour.brightnessComponent)
                }
            }
            XCTAssertLessThan(lightest - darkest, 0.2, "a row draws in the sidebar's footer between y \(band.lowerBound) and \(band.upperBound)")
        }
        resizeWindow(by: 440)
    }
    #endif

    /// A hidden destination's screen keeps its place on its stack and shows none of its controls: Home's View all (its
    /// sort in its title row), then Search, then Home again, on View all.
    func testAHiddenDestinationKeepsItsStackWithoutItsToolbar() throws {
        try launch()
        require("home.screen", timeout: 60, "Home")
        let viewAll = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.' AND identifier ENDSWITH '.viewAll'")).firstMatch
        XCTAssertTrue(viewAll.exists(within: 30), "a hub's View all")
        // Clear of the tab bar at the foot, which would take the press; a bar along the side (`besideVerticalBar`) leaves
        // the foot free.
        let window = app.windows.firstMatch.frame
        let foot: CGFloat = besideVerticalBar.width < window.width ? 40 : 160
        for _ in 0..<8 where !(onScreen(viewAll) && viewAll.frame.maxY < window.maxY - foot) { scrollDown() }
        hit(viewAll)
        require("hubDetail.sort", timeout: 20, "View all's sort")
        pick("nav.search")
        require("search.screen", "Search")
        shot("search over a hidden view all")
        let sort = element("hubDetail.sort")
        XCTAssertFalse(sort.exists && sort.isHittable, "Search shows without View all's sort")
        pick("nav.home")
        require("hubDetail", "Home again, still on View all")
    }

    /// A movie open over Home and Settings on its General page: switching between them (three times) shows each on its
    /// page as it was left. A stack the sidebar replaces empties its path as it goes; taken for a Back, it left the
    /// next destination on its root, under the page the navigator still had on top (Home without the movie; Settings'
    /// hub drawn before its General page).
    func testDestinationsComeBackOnTheirPages() throws {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            launchDev(settings: ["always_keep_sidebar_open=true"], arguments: ["--dev-server", try server(), "--dev-open", "home"])
            // The sidebar beside the screens, as on the Mac: in portrait it overlays Home, and a tap on a card only
            // closes it.
            XCUIDevice.shared.orientation = .landscapeLeft
        } else {
            try launch()
        }
        #else
        try launch()
        #endif
        require("home.screen", timeout: 90, "Home")
        openMovie("Two Versions")
        pick("nav.settings")
        require("settings.screen", timeout: 30, "Settings")
        // The rows settle first: Support Plezy's row comes in above General as the store answers.
        sleep(2)
        hit(require("settings.row.general", "Settings' General row"))
        require("settings.page.general", "General")
        for round in 1...3 {
            pick("nav.home")
            if !element("detail.screen").exists(within: 10) { fail("Home lost the movie open over it (return \(round))") }
            pick("nav.settings")
            if !element("settings.page.general").exists(within: 10) { fail("Settings lost its General page (return \(round))") }
        }
        shot("settings still on general")
        pick("nav.home")
        require("detail.screen", "Home still on the movie")
        shot("home still on the movie")
    }

    /// Opens `title`'s card on Home, scrolling down to it.
    private func openMovie(_ title: String) {
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label BEGINSWITH %@", title)).firstMatch
        if !card.exists(within: 60) { fail("no \(title) card on Home") }
        // Home's rows settle as the rest of its content comes.
        sleep(3)
        for _ in 0..<8 where !onScreen(card) {
            #if os(macOS)
            element("home.screen").scroll(byDeltaX: 0, deltaY: -300)
            #else
            element("home.screen").swipeUp()
            #endif
            _ = waitUntil(1) { onScreen(card) }
        }
        hit(card)
        require("detail.screen", timeout: 30, "\(title)'s detail over Home")
        // Lets the detail's push finish before the next pick.
        sleep(2)
    }

    /// The destinations' tabs (the bar's buttons, the Mac's sidebar rows) carry their identifiers and their names
    /// (VoiceOver reads them) from launch, and again after the shell goes offline (Downloads and Settings alone, iPhone's
    /// bar showing Downloads then) and comes back online; each picked then shows its screen.
    func testTabsKeepTheirNamesThroughOffline() throws {
        try launch()
        require("home.screen", timeout: 60, "Home")
        requireTabs("at launch")
        changeDevSetting("offline=true")
        require("offline.reconnect", timeout: 30, "the offline line")
        let settings = require("nav.settings", timeout: 20, "Settings' tab while offline")
        XCTAssertEqual(name(of: settings), "Settings", "Settings' tab keeps its name while offline")
        let downloads = require("nav.downloads", timeout: 20, "Downloads' tab while offline")
        XCTAssertEqual(name(of: downloads), "Downloads", "Downloads' tab reads as Downloads while offline")
        XCTAssertFalse(element("nav.libraries").exists, "no Libraries tab while offline")
        changeDevSetting("offline=false")
        if !element("offline.reconnect").waitForNonExistence(timeout: 30) { fail("the shell doesn't come back online") }
        requireTabs("back online")
        for (id, screen) in [("nav.search", "search.screen"), ("nav.settings", "settings.screen"), ("nav.home", "home.screen")] {
            pick(id)
            require(screen, "\(id) shows \(screen)")
        }
        shot("tabs back online")
    }

    /// Home, Libraries, Downloads, Search and Settings' tabs, each with its identifier and its name; the Mac's sidebar has
    /// no Libraries row online, its libraries standing for it, and iPhone's bar no Downloads tab online, Home's chip
    /// opening it.
    private func requireTabs(_ when: String) {
        var tabs = [("nav.home", "Home"), ("nav.search", "Search"), ("nav.settings", "Settings")]
        #if os(macOS)
        XCTAssertFalse(element("nav.libraries").exists, "no Libraries row beside the libraries \(when)")
        tabs.insert(("nav.downloads", "Downloads"), at: 1)
        #else
        tabs.insert(("nav.libraries", "Libraries"), at: 1)
        if UIDevice.current.userInterfaceIdiom == .pad {
            tabs.insert(("nav.downloads", "Downloads"), at: 2)
        } else {
            XCTAssertFalse(app.tabBars.buttons.matching(identifier: "nav.downloads").firstMatch.exists, "no Downloads tab in iPhone's bar \(when)")
        }
        #endif
        for (id, name) in tabs {
            let tab = require(id, "\(name)'s tab \(when)")
            XCTAssertEqual(self.name(of: tab), name, "\(id) reads as \(name) \(when)")
        }
    }

    /// An artist opened over Home, the sidebar shown (iPad, the Mac): its server's Music library is the highlighted row,
    /// not Home, and every destination keeps its row; Home picked then goes back to its root, highlighted again.
    func testAnArtistOverHomeHighlightsItsMusicLibrary() throws {
        #if os(iOS)
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "the iPhone's tab bar has no library rows")
        launchDev(settings: ["always_keep_sidebar_open=true"], arguments: ["--dev-server", try server(), "--dev-open-music", "artist=Plezy Test Artist"])
        #else
        launchDev(arguments: ["--dev-server", try server(), "--dev-open-music", "artist=Plezy Test Artist"])
        #endif
        require("music.artist", timeout: 90, "the artist")
        require("nav.library.Music", timeout: 30, "the sidebar's Music row")
        require("nav.home", "Home's row")
        if !waitUntil(10, { selected("nav.library.Music") }) { fail("the artist over Home leaves Music's row unhighlighted") }
        XCTAssertFalse(selected("nav.home"), "Home's row isn't highlighted over the artist")
        requireTabs("over the artist")
        // Lets the highlight's animation finish before the shot.
        sleep(2)
        shot("artist over home highlights music")
        pick("nav.home")
        require("home.screen", "Home's root once Home is picked")
        if !waitUntil(10, { selected("nav.home") && !selected("nav.library.Music") }) { fail("Home's row isn't highlighted at Home's root") }
        shot("home highlighted again")
    }

    /// A movie opened from its card on Home, the sidebar shown (iPad, the Mac): its own library, Movies, is the
    /// highlighted row, not Home nor another library.
    func testAMovieOpenedFromHomeHighlightsItsLibrary() throws {
        #if os(iOS)
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "the iPhone's tab bar has no library rows")
        launchDev(settings: ["always_keep_sidebar_open=true"], arguments: ["--dev-server", try server(), "--dev-open", "home"])
        // In portrait the sidebar overlays Home, and a tap on a card only closes it.
        XCUIDevice.shared.orientation = .landscapeLeft
        #else
        launchDev(arguments: ["--dev-server", try server(), "--dev-open", "home"])
        #endif
        require("home.screen", timeout: 90, "Home")
        require("nav.library.Movies", timeout: 30, "the sidebar's Movies row")
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label BEGINSWITH 'Two Versions'")).firstMatch
        if !card.exists(within: 60) { fail("no Two Versions card on Home") }
        // Home's rows settle as the rest of its content comes.
        sleep(3)
        for _ in 0..<6 where !card.isHittable {
            #if os(macOS)
            element("home.screen").scroll(byDeltaX: 0, deltaY: -300)
            #else
            element("home.screen").swipeUp()
            #endif
            _ = waitUntil(1) { card.isHittable }
        }
        #if os(macOS)
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #endif
        require("detail.screen", timeout: 30, "the movie's detail")
        if !waitUntil(10, { selected("nav.library.Movies") }) { fail("the movie over Home leaves Movies' row unhighlighted") }
        XCTAssertFalse(selected("nav.home"), "Home's row isn't highlighted over the movie")
        requireTabs("over the movie")
        // Lets the highlight's animation finish before the shot.
        sleep(2)
        shot("movie over home highlights movies")
    }

    /// Downloads shown, the sidebar shown (iPad, the Mac): its own row is highlighted, no library's, not even the one
    /// Libraries has selected.
    func testDownloadsHighlightNoLibrary() throws {
        #if os(iOS)
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "the iPhone's tab bar has no library rows")
        launchDev(settings: ["always_keep_sidebar_open=true"], arguments: ["--dev-server", try server(), "--dev-open", "downloads"])
        XCUIDevice.shared.orientation = .landscapeLeft
        #else
        launchDev(arguments: ["--dev-server", try server(), "--dev-open", "downloads"])
        #endif
        require("downloads.screen", timeout: 90, "the Downloads screen")
        require("nav.library.Movies", timeout: 30, "the sidebar's Movies row")
        // The libraries' section selects its first library meanwhile.
        sleep(3)
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.'")).allElementsBoundByIndex
        let highlighted = rows.map(\.identifier).filter(selected)
        XCTAssertEqual(highlighted, [], "a library's row is highlighted over the downloads")
        XCTAssertTrue(selected("nav.downloads"), "Downloads' row is highlighted over the downloads")
        shot("downloads highlight no library")
    }

    /// Movies, then Shows and its Maestro Show, then Home, then Movies again, the sidebar shown (iPad, the Mac): Movies
    /// shows its grid with its row highlighted, not the show left open under Shows (with Shows highlighted again).
    func testALibraryPickedOverATitleLeftOpenInAnotherShowsItsGrid() throws {
        #if os(iOS)
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "the iPhone's tab bar has no library rows")
        launchDev(settings: ["always_keep_sidebar_open=true"], arguments: ["--dev-server", try server(), "--dev-open", "home"])
        XCUIDevice.shared.orientation = .landscapeLeft
        #else
        try launch()
        #endif
        require("home.screen", timeout: 90, "Home")
        require("nav.library.Movies", timeout: 30, "the sidebar's Movies row")
        pick("nav.library.Movies")
        require("libraries.grid", timeout: 30, "Movies' grid")
        pick("nav.library.Shows")
        let show = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label BEGINSWITH 'Maestro Show'")).firstMatch
        if !show.exists(within: 30) { fail("no Maestro Show card in Shows") }
        _ = waitUntil(5) { show.isHittable }
        hit(show)
        require("detail.screen", timeout: 30, "Maestro Show's detail")
        pick("nav.home")
        require("home.screen", "Home")
        pick("nav.library.Movies")
        require("libraries.grid", timeout: 20, "Movies' grid again")
        // The show came back from about half a second after the click and stayed.
        sleep(2)
        shot("movies again")
        XCTAssertFalse(element("detail.screen").exists, "Movies shows its grid, not the show left open under Shows")
        let header = element("libraries.library")
        let named = [header.label, header.title, (header.value as? String) ?? ""].joined(separator: " ")
        XCTAssertTrue(named.contains("Movies"), "the grid is Movies', not that of \(named)")
        XCTAssertTrue(selected("nav.library.Movies"), "Movies' row is highlighted")
        XCTAssertFalse(selected("nav.library.Shows"), "Shows' row isn't highlighted")
    }

    /// Whether the sidebar row `id` names is the selected one (on the Mac the row's button, which the list's own
    /// selection never is).
    private func selected(_ id: String) -> Bool {
        element(id).isSelected
    }

    /// A tab's name as VoiceOver reads it: the bar button's label, or on the Mac the sidebar row's text (its value).
    private func name(of tab: XCUIElement) -> String {
        #if os(macOS)
        tab.label.isEmpty ? (tab.value as? String) ?? "" : tab.label
        #else
        tab.label
        #endif
    }
    #endif

    #if os(tvOS)
    /// Over a screen on Home, Menu pops the screen and stays in the app; at Home's root it leaves.
    func testMenuOverAScreenPopsIt() throws {
        try launch()
        require("home.screen", timeout: 60, "Home")
        // Home's rows settle and take the focus as its content comes.
        sleep(4)
        // Below Continue Watching (whose cards play) and Home's shortcuts, a hub's card opens its detail.
        XCUIRemote.shared.press(.down)
        // Paces the presses so the focus engine takes each one.
        sleep(1)
        XCUIRemote.shared.press(.down)
        sleep(1)
        XCUIRemote.shared.press(.select)
        require("detail.play", timeout: 30, "the card's detail")
        _ = waitUntil(5) { !app.tabBars.firstMatch.isHittable }
        XCTAssertFalse(app.tabBars.firstMatch.isHittable, "a pushed detail hides the tab bar")
        shot("detail without tab bar")
        XCUIRemote.shared.press(.menu)
        _ = waitUntil(5) { !element("detail.play").exists }
        XCTAssertEqual(app.state, .runningForeground, "Menu over the detail stays in the app")
        XCTAssertFalse(element("detail.play").exists, "and pops the detail")
        require("home.screen", "Home")
        for _ in 0..<2 where app.state == .runningForeground {
            // Paces the presses so each Menu lands after the last one's transition.
            sleep(2)
            XCUIRemote.shared.press(.menu)
        }
        if !app.wait(for: .runningBackground, timeout: 10) { fail("Menu at Home's root didn't leave for the home screen") }
    }

    #else
    private func onScreen(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        return !frame.isEmpty && app.windows.firstMatch.frame.insetBy(dx: 0, dy: 40).contains(frame)
    }

    /// A destination of the chrome picked: its tab, or its row in the Mac's sidebar. On iPhone Search's keyboard covers
    /// the tab bar: dragged away first.
    private func pick(_ id: String) {
        #if os(iOS)
        // On Search, a tap off the field (its empty prompt) puts the keyboard away, as in the system's apps.
        if element("search.screen").exists, app.keyboards.count > 0 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
            _ = waitUntil(3) { app.keyboards.count == 0 }
        }
        #endif
        hit(element(id))
    }

    private func hit(_ target: XCUIElement) {
        #if os(macOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #endif
        // Paces the taps on the chrome so each lands after the last one's transition.
        sleep(1)
    }

    private func scrollDown() {
        #if os(macOS)
        element("home.screen").scroll(byDeltaX: 0, deltaY: -400)
        #else
        // On the window: a gesture not aimed at an element can miss the app on the iPhone Duo, whose screens are two.
        app.windows.firstMatch.swipeUp()
        #endif
        // Lets the scroll come to rest before what's on screen is read.
        sleep(1)
    }
    #endif
}
