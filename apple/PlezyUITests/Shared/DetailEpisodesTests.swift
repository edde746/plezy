import XCTest

#if !os(tvOS)
/// A show's season tabs and episode rows on a phone, a tablet or the Mac, against the development Jellyfin server:
/// Maestro Show's season chips, a held (right-clicked) chip opens the season's shared menu (on iOS titled by the season
/// alone, an episode's by the episode's title), a chip says how much of its season is watched and follows an episode
/// marked watched, a downloaded episode's row says its download's state to VoiceOver, an
/// offline show's episode row has its menu, which marks that one episode watched, Continue Watching's episode
/// (opened to its details) lands on its show with that episode's row in view (in the middle where the page is one
/// column), and on the Mac, with the system's keyboard navigation on, Tab reaches an episode row and its ⋯. Each step is
/// kept as a screenshot.
final class DetailEpisodesTests: PlezyUITestCase {
    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        guard value.isEmpty else { return value }
        #if os(macOS)
        return "jellyfin=maestro:maestro@http://127.0.0.1:28096"
        #else
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
        #endif
    }

    func testSeasonTabsMenuAndEpisodeDownload() {
        openMaestroShow(as: Self.server)
        let tab = require("detail.season.1", timeout: 30, "the show's season chips")
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'detail.episode.' AND NOT (identifier ENDSWITH '.menu')")).firstMatch
        // The show opens on its next episode's season, which other runs move, once its episodes show: Season 1 is picked
        // then.
        if !row.exists(within: 20) { fail("the show lists no episode") }
        if !tab.isSelected {
            #if os(macOS)
            // The chip's own frame, not its hittability: the right-click catcher over it hides its activation point.
            tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
            #else
            tap(tab)
            #endif
        }
        _ = waitUntil(5) { tab.isSelected }
        shot("season chips")

        openMenu(on: tab)
        require("menu.shuffle_play", timeout: 10, "a held season chip opens the season's menu")
        shotOfMenu("season menu")
        #if os(iOS)
        XCTAssertEqual(element("menu.title").label, "Season 1", "the season's menu is titled by the season alone")
        #endif
        dismissMenu()

        if !row.exists(within: 20) { fail("the season lists no episode") }
        #if os(macOS)
        // The row's ⋯ opens the same menu, under itself.
        tap(require("\(row.identifier).menu", "the episode's ⋯"))
        require("menu.download", timeout: 10, "the episode's ⋯ opens its menu")
        shotOfMenu("episode more menu")
        dismissMenu()
        #endif
        openMenu(on: row)
        let download = require("menu.download", timeout: 10, "the episode's menu offers Download")
        shotOfMenu("episode menu")
        #if os(iOS)
        XCTAssertEqual(element("menu.title").label, "Maestro Episode 1", "the episode's menu is titled by its title alone")
        #endif
        tap(download)
        // The row's value says the download's state; downloading it takes a while over the network.
        if !waitUntil(180, every: 1, { (row.value as? String)?.contains("Download complete") == true }) {
            fail("the downloaded episode's row never says Download complete: \(row.value ?? "")")
        }
        scroll()
        shot("episode downloaded")
    }

    /// As an account of the test's own: Specials watched, Season 1 one episode of three (Maestro Episode 2 started, which
    /// doesn't count), Season 2 none. The chips say so (VoiceOver's value: watched, 33 percent watched, nothing), and
    /// Season 1's follows Maestro Episode 2 marked watched from its row's menu.
    func testSeasonChipsSayHowMuchIsWatched() throws {
        let records = try WatchRecords.ownAccount(on: Self.server)
        addTeardownBlock { try records.removeAccount() }
        try records.set("Behind the Pattern", seconds: 0, played: true, ago: 120)
        try records.set("Maestro Episode 1", seconds: 0, played: true, ago: 60)
        try records.set("Maestro Episode 2", seconds: 70, ago: 30)
        openMaestroShow(as: records.server)
        let chips = (0..<3).map { element("detail.season.\($0)") }
        let values = { chips.map { $0.value as? String ?? "" } }
        let started = ["watched", "33 percent watched", ""]
        if !waitUntil(20, { values() == started }) { return fail("the season chips say \(values()), not \(started)") }
        if !chips[1].isSelected { tap(chips[1]) }
        _ = waitUntil(5) { chips[1].isSelected }
        shot("season chips watched partly and not")

        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'detail.episode.' AND NOT (identifier ENDSWITH '.menu') AND label CONTAINS 'Maestro Episode 2'")).firstMatch
        if !row.exists(within: 20) { return fail("Season 1 lists no Maestro Episode 2") }
        openMenu(on: row)
        tap(require("menu.watch", timeout: 10, "Maestro Episode 2's menu offers Mark as watched"))
        if !waitUntil(20, { values()[1] == "67 percent watched" }) {
            return fail("after Maestro Episode 2 is marked watched Season 1's chip says \(values()[1]), not 67 percent watched")
        }
        shot("season chip after an episode marked watched")
    }

    /// Launches signed in as `server` and opens Maestro Show: on the Mac from the Shows grid, typing nothing
    /// (`LibrarySteps.openCard`: Search's typing leaves later right clicks reaching no item), elsewhere from Search.
    private func openMaestroShow(as server: String) {
        #if os(macOS)
        launchDev(arguments: ["--dev-open", "libraries", "--dev-server", server])
        require("libraries.screen", timeout: 90, "Libraries")
        LibrarySteps(test: self).openCard("Maestro Show", in: "Shows")
        #else
        launchDev(arguments: ["--dev-open", "search", "--dev-server", server])
        require("search.screen", timeout: 90, "the Search screen")
        type("Maestro Show")
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == %@", "Maestro Show")).firstMatch
        if !result.exists(within: 30) { fail("typing Maestro Show lists no Maestro Show") }
        _ = waitUntil(5) { result.isHittable }
        tap(result)
        #endif
        require("detail.title", timeout: 30, "Maestro Show's title")
    }

    #if os(macOS)
    /// With the system's keyboard navigation on, Tab reaches the episode rows (which are buttons only while the keyboard
    /// is in the list) and then the row's ⋯, whose Space opens the episode's menu.
    func testKeyboardReachesEpisodeRows() throws {
        guard [2, 3].contains(UserDefaults.standard.integer(forKey: "AppleKeyboardUIMode")) else {
            throw XCTSkip("the system's keyboard navigation is off")
        }
        launchDev(arguments: ["--dev-open", "libraries", "--dev-server", Self.server])
        require("libraries.screen", timeout: 90, "Libraries")
        LibrarySteps(test: self).openCard("Maestro Show", in: "Shows")
        require("detail.title", timeout: 30, "Maestro Show's title")
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'detail.episode.' AND NOT (identifier ENDSWITH '.menu')")).firstMatch
        if !row.exists(within: 20) { fail("the show lists no episode") }
        // The Debug build's probe (`KeyboardFocusProbe`): XCUITest's `hasKeyboardFocus` can't tell on the Mac.
        let probe = require("app.keyboardFocus", "the keyboard focus probe")
        let focused = { String(probe.label.dropFirst("focus=".count)) }
        var reached = ""
        var path: [String] = []
        for _ in 0..<40 {
            app.typeKey(.tab, modifierFlags: [])
            // The stop at the list's top hands the focus on to a row a moment later; the probe looks 4 times a second.
            _ = waitUntil(1) { focused().hasPrefix("detail.episode.") }
            reached = focused()
            path.append(reached)
            if reached.hasPrefix("detail.episode.") { break }
        }
        if !reached.hasPrefix("detail.episode.") || reached.hasSuffix(".menu") {
            fail("Tab never reaches an episode row: \(path.joined(separator: " > "))")
        }
        shot("keyboard on an episode row")
        app.typeKey(.tab, modifierFlags: [])
        _ = waitUntil(3) { focused() == "\(reached).menu" }
        XCTAssertEqual(focused(), "\(reached).menu", "Tab goes on from the row to its ⋯")
        app.typeKey(" ", modifierFlags: [])
        require("menu.download", timeout: 10, "Space on the row's ⋯ opens the episode's menu")
        shotOfMenu("episode menu from the keyboard")
        dismissMenu()
    }
    #endif

    func testOfflineEpisodeMenuMarksItWatched() {
        launchDev(arguments: [
            "--dev-open", "downloads", "--dev-server", Self.server, "--dev-download", "Maestro_Show/Season_1/Maestro_Episode_3",
        ])
        require("downloads.screen", timeout: 60, "the Downloads screen")
        #if os(macOS)
        app.activate()
        #endif
        let show = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'downloads.row.' AND label CONTAINS 'Maestro Show'")).firstMatch
        if !show.exists(within: 180) { fail("no Manage row of Maestro Show after 180 s") }
        // A download still running offers Pause all in its ⋯ menu.
        let done = waitUntil(300, every: 5) {
            self.tap(self.element("\(show.identifier).menu"))
            let running = self.element("\(show.identifier).pauseAll").exists(within: 2)
            self.dismissMenu()
            return !running
        }
        if !done { fail("Maestro Episode 3 was still downloading after 300 s") }

        // Offline: the app knows its server is gone once the offline chrome's Reconnect, pressed, ends its attempt.
        changeDevSetting("offline=true")
        let reconnect = require("offline.reconnect", timeout: 30, "the offline chrome's Reconnect")
        _ = waitUntil(5) { reconnect.isHittable && reconnect.isEnabled }
        tap(reconnect)
        if !waitUntil(60, { reconnect.isEnabled }) { fail("Reconnect still runs offline after 60 s") }

        let steps = LibrarySteps(test: self)
        tap(require("downloads.tab", "the Downloads tab menu"))
        let tvShows = steps.option("downloads.tab", label: "TV Shows")
        if !tvShows.exists(within: 5) { fail("TV Shows in the Downloads tab menu") }
        steps.pressOption(tvShows)
        let card = require("downloads.items", "the TV Shows tab's titles")
            .descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 10) { fail("the TV Shows tab lists no Maestro Show") }
        #if os(macOS)
        // The card's own frame: the right-click catcher over it hides its activation point.
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        card.tap()
        #endif
        require("detail.title", timeout: 30, "Maestro Show's offline detail")
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'detail.episode.' AND NOT (identifier ENDSWITH '.menu') AND label CONTAINS 'Maestro Episode 3'")).firstMatch
        if !row.exists(within: 20) { fail("the offline show lists no Maestro Episode 3") }
        shot("offline episodes")

        openMenu(on: row)
        let watch = require("menu.watch", timeout: 10, "the offline episode's menu offers Mark as watched")
        shotOfMenu("offline episode menu")
        tap(watch)
        _ = waitUntil(5) { !self.element("menu.watch").exists }
        shot("offline episode marked watched")
        openMenu(on: row)
        require("menu.unwatch", timeout: 10, "once marked, the offline episode's menu offers Mark as unwatched")
        shotOfMenu("offline episode menu watched")
        dismissMenu()
    }

    func testContinueWatchingEpisodeOpensAtItsRow() {
        launchDev(settings: ["continue_watching_action=details"], arguments: ["--dev-server", Self.server])
        let hub = require("hub.continue_watching", timeout: 60, "Continue Watching")
        let card = hub.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND (label CONTAINS 'Episode' OR label CONTAINS 'Maestro Show')")).firstMatch
        if !card.exists(within: 30) { fail("Continue Watching holds no episode") }
        _ = waitUntil(5) { self.app.windows.firstMatch.frame.contains(card.frame) }
        #if os(macOS)
        // Home scrolled towards the card only where it sits outside the window: Continue Watching leads Home.
        for _ in 0..<4 where !app.windows.firstMatch.frame.contains(card.frame) {
            let up = card.frame.minY < app.windows.firstMatch.frame.minY
            app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: up ? 200 : -200)
            sleep(1)
        }
        #endif
        #if os(iOS)
        // Its whole frame on screen (it may sit past the row's end on a phone): the row dragged towards it, a third of
        // the screen at a time, slowly (a swipe's fling ran the row to its end, past the card).
        let screen = app.windows.firstMatch.frame
        for _ in 0..<6 where !screen.contains(card.frame) {
            let towardsEnd = card.frame.maxX > screen.maxX
            let from = hub.coordinate(withNormalizedOffset: CGVector(dx: towardsEnd ? 0.7 : 0.3, dy: 0.5))
            let to = hub.coordinate(withNormalizedOffset: CGVector(dx: towardsEnd ? 0.37 : 0.63, dy: 0.5))
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.3)
            _ = waitUntil(1) { screen.contains(card.frame) }
        }
        if !app.windows.firstMatch.frame.contains(card.frame) { fail("the episode's card never came whole onto the screen: \(card.frame)") }
        #endif
        shot("home")
        // The card's episode, whichever the server's watch state puts first: its caption ("S2 E1 · Title") leads its
        // value, the episode's title after the code.
        let caption = ((card.value as? String) ?? "").components(separatedBy: ", ").first ?? ""
        // The Mac's card reports no value (its right-click catcher is the element): any of the show's rows there.
        let episode = caption.contains(" · ") ? caption.components(separatedBy: " · ").last ?? "" : ""
        // The card's own frame, not its hittability: the right-click catcher over it hides its activation point (the
        // Mac), and iOS 27.0 at times reports none for a card under the bar's soft edge.
        #if os(macOS)
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).click()
        #else
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        #endif
        require("detail.title", timeout: 30, "the episode's show")
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'detail.episode.' AND NOT (identifier ENDSWITH '.menu') AND (%@ == '' OR label CONTAINS %@)", episode, episode)).firstMatch
        if !row.exists(within: 20) { fail("the show lists no \(episode.isEmpty ? "episode" : episode)") }
        _ = waitUntil(5) {
            let frame = self.app.windows.firstMatch.frame
            if frame.width >= 1000 { return frame.contains(row.frame) }
            return frame.insetBy(dx: 0, dy: frame.height / 4).contains(CGPoint(x: row.frame.midX, y: row.frame.midY))
        }
        let window = app.windows.firstMatch.frame
        if window.width >= 1000 {
            // Wide windows list the episodes in a column of their own beside the details, from its top: the row shows
            // whole there (a short season's column has nothing to scroll).
            XCTAssertTrue(window.contains(row.frame), "the deep link's row shows: \(row.frame) in \(window)")
        } else {
            // Centred: clear of the screen's top and bottom quarters.
            let middle = window.insetBy(dx: 0, dy: window.height / 4)
            XCTAssertTrue(middle.contains(CGPoint(x: row.frame.midX, y: row.frame.midY)), "the deep link's row is in the middle: \(row.frame) in \(window)")
        }
        shot("deep link row")
    }

    private func type(_ text: String) {
        let field = require("search.field", "Search's field")
        #if os(macOS)
        field.click()
        #else
        // XCUITest's own attribute: the field takes the keys only once it has the focus.
        let hasFocus = { field.value(forKey: "hasKeyboardFocus") as? Bool == true }
        for _ in 0..<3 where !hasFocus() {
            field.tap()
            _ = waitUntil(2, hasFocus)
        }
        #endif
        field.typeText(text)
    }

    private func scroll() {
        #if os(macOS)
        app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: -300)
        #else
        app.swipeUp()
        #endif
        // Lets the scroll settle before the screenshot: nothing signals its end.
        sleep(1)
    }

    private func tap(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }

    private func openMenu(on target: XCUIElement) {
        #if os(macOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).rightClick()
        #else
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.0)
        #endif
    }

    private func dismissMenu() {
        #if os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        sleep(1)
        if element("menu.shuffle_play").exists { app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.1)).click() }
        #else
        // Beside the system's menu, which keeps clear of the screen's edges.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
        #endif
        _ = waitUntil(5) { !self.element("menu.shuffle_play").exists && !self.element("menu.download").exists }
    }
}
#endif
