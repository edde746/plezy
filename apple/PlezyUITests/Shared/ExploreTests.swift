import XCTest

/// Explore over a Seerr instance (`--dev-seerr`, the fake Seerr at `PLEZY_SEERR_URL`, else the default: on the Mac
/// through its loopback): its header row (the search field and Refresh; Apple TV: Search and Refresh, reachable from the
/// shelves) over its shelves, a shelf's View all as a grid, an available title's detail (Available in its stats, the
/// title or its logo), then (not on Apple TV) the requestable movie Unrequested Utopia requested through the request
/// sheet, which the detail then shows as requested and the instance records. The test takes a run of its own on the
/// fake (its `/run/<id>`), which starts from the fixtures: the movie is requestable, and other test runs sharing the
/// fake neither see nor undo the request.
final class ExploreTests: PlezyUITestCase {
    #if os(macOS)
    // The Mac's test runs reach the test servers through tunnels on its loopback: an app started there unattended gets
    // no local network access, and a development launch whose Seerr it can't reach ends before it shows a window.
    private nonisolated static let host = "127.0.0.1"
    #else
    private nonisolated static let host = "192.168.0.15"
    #endif
    private let seerrUrl = "\(ProcessInfo.processInfo.environment["PLEZY_SEERR_URL"] ?? "http://\(ExploreTests.host):28099")/run/\(UUID().uuidString)"

    func testRequestFromExplore() throws {
        launchDev(arguments: ["--dev-open", "explore", "--dev-seerr", "maestro@plezy.test:maestro@\(seerrUrl)"])
        require("explore.screen", timeout: 60, "Explore")
        require("hub.explore:seerr:popularMovies", timeout: 30, "the Popular Movies shelf")
        require("hub.explore:seerr:trending", "the Trending shelf")
        #if os(tvOS)
        require("explore.searchScreen", "the header row's Search")
        #else
        require("explore.search", "the header row's search field")
        #endif
        require("explore.refresh", "Refresh")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 3)
        shot("explore")

        // A shelf with more opens its View all as a grid under its title, its Sort on the title's row.
        #if os(tvOS)
        let viewAll = element("hub.viewAll")
        #else
        let viewAll = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.explore:' AND identifier ENDSWITH '.viewAll'")).firstMatch
        #endif
        if viewAll.exists(within: 10) {
            press(viewAll)
            require("exploreRow.screen", timeout: 20, "the shelf's View all")
            let title = require("exploreRow.title", timeout: 20, "View all's title")
            let sort = require("exploreRow.sort", "View all's sort")
            XCTAssertGreaterThan(sort.frame.minX, title.frame.maxX, "the sort after the title")
            XCTAssertTrue(sort.frame.minY < title.frame.maxY && sort.frame.maxY > title.frame.minY, "the sort on the title's row")
            // The grid's artwork comes over the network before the screenshot; nothing signals it.
            Thread.sleep(forTimeInterval: 2)
            shot("explore view all")
            goBack()
        }
        require("explore.screen", timeout: 20, "Explore again")

        activate(card("Maestro Movie"))
        require("catalogDetail.screen", "Maestro Movie's detail")
        // Seerr has it: Request shows Available in its place, a status label and no button (the stats line doesn't
        // repeat it).
        let available = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'catalogDetail.request' AND (label CONTAINS 'Available' OR value CONTAINS 'Available')")).firstMatch
        if !available.exists(within: 15) { fail("Maestro Movie's Request doesn't say Available") }
        XCTAssertNotEqual(available.elementType, .button, "Available drawn as a button")
        if !(element("catalogDetail.title").exists || element("catalogDetail.logo").exists) { fail("the detail shows no title") }
        // The backdrop comes over the network before the screenshot; nothing signals it.
        Thread.sleep(forTimeInterval: 2)
        shot("detail available")
        #if os(iOS)
        // The bar shows no title and keeps its height while the page scrolls past its own.
        let hero = element("catalogDetail.title").exists ? element("catalogDetail.title") : element("catalogDetail.logo")
        let barHeight = requireSteadyScroll("Maestro Movie", hero: hero, anchor: element("catalogDetail.stats"), "the detail")
        shot("detail past title")
        app.swipeUp()
        app.swipeUp()
        // Lets the swipes' momentum settle before the screenshot and the bar's check: nothing signals their end.
        Thread.sleep(forTimeInterval: 2)
        shot("detail scrolled")
        requireSteadyBar("Maestro Movie", height: barHeight, "the detail scrolled")
        #endif
        #if os(tvOS)
        XCTAssertTrue(element("catalogDetail.request").exists || element("catalogDetail.watchlist").exists, "the detail's actions")
        // Available is a status: focus opens on the first action that takes a press, never on it.
        let focusedAction = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'catalogDetail.'")).firstMatch
        if !focusedAction.exists(within: 10) { fail("no action has the focus on Maestro Movie's detail") }
        XCTAssertNotEqual(focusedAction.identifier, "catalogDetail.request", "focus on the Available status")
        XCTAssertTrue(focusedAction.isEnabled, "\(focusedAction.identifier) has the focus and takes a press")
        #else
        goBack()

        activate(card("Unrequested Utopia"))
        require("catalogDetail.screen", "Unrequested Utopia's detail")
        let request = require("catalogDetail.request", "the Request action")
        let trailer = element("catalogDetail.trailer")
        let requestFrame = request.frame
        let trailerX = trailer.exists ? trailer.frame.minX : nil
        press(request)
        require("seerrRequest.sheet", timeout: 30, "the request sheet")
        let submit = require("seerrRequest.submit", timeout: 30, "the sheet's Request")
        #if os(iOS)
        // The bar names the title; Request is only its button, never the bar's title too.
        XCTAssertTrue(app.navigationBars["Unrequested Utopia"].exists, "the sheet's bar names the title")
        XCTAssertFalse(app.navigationBars["Request"].exists, "Request is the bar's title as well as its button")
        #endif
        // Lets the sheet's presentation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("request sheet")
        press(submit)
        if !element("seerrRequest.sheet").waitForNonExistence(timeout: 20) { fail("the request sheet stayed open") }
        let submitted = require("app.notice", "the Request submitted message")
        // The notice's text is its label on iPhone and iPad, its value on the Mac.
        XCTAssertTrue(submitted.label == "Request submitted" || (submitted.value as? String) == "Request submitted", "the notice reads \(submitted.label)")
        shot("request submitted")

        // The detail's Request turns into a Requested status label inside Request's place, the actions beside it where
        // they were.
        let requested = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'catalogDetail.request' AND label CONTAINS 'Requested'")).firstMatch
        if !requested.exists(within: 20) { fail("the detail's Request didn't turn into Requested") }
        XCTAssertNotEqual(requested.elementType, .button, "Requested drawn as a button")
        XCTAssertTrue(
            requestFrame.insetBy(dx: -0.5, dy: -0.5).contains(requested.frame),
            "Requested at \(requested.frame), not in Request's place \(requestFrame)"
        )
        if let trailerX {
            XCTAssertEqual(element("catalogDetail.trailer").frame.minX, trailerX, accuracy: 0.5, "Watch trailer's leading edge")
        }
        shot("requested inline")

        let requests = try JSONSerialization.jsonObject(with: Data(fakeState().utf8)) as? [String: Any]
        let made = (requests?["requests"] as? [[String: Any]] ?? []).filter { ($0["tmdbId"] as? Int) == 990012 }
        XCTAssertEqual(made.count, 1, "the fake Seerr's requests for Unrequested Utopia: \(made)")
        #endif
    }

    /// Focus as Explore shows. iPhone, iPad and the Mac: with a search that found titles, Explore shown again
    /// (another tab, then Explore's) keeps its results and leaves the field without focus, the keyboard down; with a
    /// search that found nothing the field takes focus again. Apple TV, whose search is a screen of its own: focus enters
    /// on the first shelf's card, and Up from the first shelf reaches the header row's Search.
    func testFocusAsExploreShows() throws {
        launchDev(arguments: ["--dev-open", "explore", "--dev-seerr", "maestro@plezy.test:maestro@\(seerrUrl)"])
        require("explore.screen", timeout: 60, "Explore")
        require("hub.explore:seerr:trending", timeout: 30, "the Trending shelf")
        #if os(tvOS)
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 15) { return fail("no card took focus as Explore loaded") }
        XCUIRemote.shared.press(.up)
        let header = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true AND identifier IN {'explore.searchScreen', 'explore.refresh', 'explore.source'}")).firstMatch
        if !header.exists(within: 5) { fail("Up from the first shelf doesn't reach the header row") }
        shot("explore header row focused")
        #else
        search("Maestro")
        require("catalogSearch.results", timeout: 20, "the search's results")
        showAgain()
        XCTAssertTrue(element("catalogSearch.results").exists(within: 10), "the results stay as Explore shows again")
        // Negative check: the field must not take focus back over this period.
        sleep(2)
        XCTAssertFalse(fieldHasFocus, "the field doesn't take focus back while the search has results")
        #if os(iOS)
        XCTAssertFalse(app.keyboards.firstMatch.exists, "the keyboard stays down")
        #endif
        shot("explore results shown again")

        search("Zzqq")
        if !element("catalogSearch.results").waitForNonExistence(timeout: 20) { fail("a search for Zzqq found titles") }
        showAgain()
        let refocused = waitUntil(5) { fieldHasFocus }
        shot("explore empty search shown again")
        if !refocused { fail("the field doesn't take focus back while the search found nothing") }
        #endif
    }

    /// In the light theme a Seerr title's facts under its title (its year, length and rating, genres and score: secondary
    /// text in the theme's muted colour) read at least 4.5:1 on the page.
    func testCatalogFactsReadInTheLightTheme() throws {
        launchDev(settings: ["theme_mode=light"], arguments: [
            "--dev-open", "explore", "--dev-server", "jellyfin=maestro:maestro@http://\(Self.host):28096",
            "--dev-seerr", "maestro@plezy.test:maestro@\(seerrUrl)",
        ])
        require("explore.screen", timeout: 60, "Explore")
        // Seerr is Explore's one source: its shelves show with no switcher.
        require("hub.explore:seerr:popularMovies", timeout: 30, "Seerr's Popular Movies shelf")
        // The tab bar (or sidebar) the card's shelf scrolls beside comes into the tree a moment after the shelves.
        _ = element("nav.explore").exists(within: 5)
        activate(card("Maestro Movie"))
        require("catalogDetail.screen", "Maestro Movie's detail")
        let facts = ["catalogDetail.meta", "catalogDetail.genres", "catalogDetail.stats"].map { element($0) }.filter { $0.exists(within: 20) }
        if facts.isEmpty { return fail("Maestro Movie's detail shows no facts under its title") }
        // The backdrop over the facts loaded and settled.
        Thread.sleep(forTimeInterval: 3)
        shot("light theme catalog facts")
        for fact in facts {
            guard let ratio = contrast(in: fact.frame, fact.identifier) else { return }
            if ratio < 4.5 { fail(String(format: "\(fact.identifier) \"\(fact.label)\" has a contrast of %.2f:1, under 4.5:1", ratio)) }
        }
    }

    /// Explore with the test Jellyfin signed in and the fake trackers connected as well as Seerr: the header row leads
    /// with the source switcher, whose menu names the sources; Seerr picked there, Maestro Movie's detail names its
    /// scores' sources (the trackers' Rotten Tomatoes as "Rotten Tomatoes critics", not its key) and lists the server's
    /// copy of it in its library section, a row that opens the copy's own detail.
    func testLibraryCopiesOnCatalogDetail() throws {
        launchDev(arguments: [
            "--dev-open", "explore", "--dev-server", "jellyfin=maestro:maestro@http://\(Self.host):28096",
            "--dev-seerr", "maestro@plezy.test:maestro@\(seerrUrl)",
            "--dev-trackers", "http://\(Self.host):28100/run/\(UUID().uuidString)", "--dev-trackers-connected",
        ])
        require("explore.screen", timeout: 60, "Explore")
        let source = require("explore.source", timeout: 30, "the source switcher")
        require("explore.refresh", "Refresh")
        // Lets the header row's switcher settle as the sources load before the screenshot; nothing signals it.
        Thread.sleep(forTimeInterval: 3)
        shot("explore header")
        if !source.label.hasSuffix("Seerr") {
            press(source)
            let seerr = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'explore.source.option.' AND (label CONTAINS 'Seerr' OR title CONTAINS 'Seerr')")).firstMatch
            if !seerr.exists(within: 10) { return fail("the switcher's menu doesn't name Seerr") }
            #if os(tvOS)
            for _ in 0..<8 where !seerr.hasFocus {
                XCUIRemote.shared.press(.down)
                _ = waitUntil(0.3) { seerr.hasFocus }
            }
            XCUIRemote.shared.press(.select)
            #else
            press(seerr)
            #endif
        }
        require("hub.explore:seerr:popularMovies", timeout: 30, "Seerr's Popular Movies shelf")

        activate(card("Maestro Movie"))
        require("catalogDetail.screen", "Maestro Movie's detail")
        // The Ratings row names each score's source as people know it, never by its key (the trackers' Rotten Tomatoes).
        let ratings = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'catalogDetail.rating.'"))
        if !ratings.firstMatch.exists(within: 20) { return fail("Maestro Movie's detail shows no ratings") }
        let labels = ratings.allElementsBoundByIndex.map(\.label)
        XCTAssertFalse(labels.contains { $0.contains("rottenTomatoes") }, "a rating names its source by its key: \(labels)")
        XCTAssertTrue(labels.contains { $0.hasPrefix("Rotten Tomatoes critics ") }, "no Rotten Tomatoes critics score: \(labels)")
        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'catalogDetail.copy.'")).firstMatch
        if !copy.exists(within: 20) { return fail("Maestro Movie's detail lists no library copy") }
        // The copies' heading is the page's section heading, at the edge its rows start from, as the page's others are.
        let heading = element("catalogDetail.library").staticTexts["In these libraries"]
        if !heading.exists(within: 5) { return fail("the library copies have no heading") }
        XCTAssertEqual(heading.frame.minX, copy.frame.minX, accuracy: 2, "the heading \(heading.frame) starts off its rows \(copy.frame)")
        #if os(tvOS)
        for _ in 0..<12 where !copy.hasFocus {
            XCUIRemote.shared.press(.down)
            _ = waitUntil(0.3) { copy.hasFocus }
        }
        #else
        for _ in 0..<8 where !copy.isHittable {
            #if os(macOS)
            app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: -200)
            #else
            app.swipeUp()
            #endif
            _ = waitUntil(0.5) { copy.isHittable }
        }
        #endif
        // Lets the scroll settle before the screenshot: nothing signals its end.
        Thread.sleep(forTimeInterval: 1)
        shot("library copies")
        activate(copy)
        require("detail.screen", timeout: 20, "the copy's own detail")
    }

    #if os(iOS)
    /// A Seerr title's cast member opens their person page under their name; once the page scrolls under the navigation
    /// bar, the detail page's bar naming the person comes behind Back, so Back never sits bare over the portrait.
    func testCastOpensThePersonPageWithItsTitleBar() throws {
        launchDev(arguments: ["--dev-open", "explore", "--dev-seerr", "maestro@plezy.test:maestro@\(seerrUrl)"])
        require("explore.screen", timeout: 60, "Explore")
        require("hub.explore:seerr:popularMovies", timeout: 30, "the Popular Movies shelf")
        activate(card("Maestro Movie"))
        require("catalogDetail.screen", "Maestro Movie's detail")
        let cast = require("catalogDetail.cast.0", timeout: 20, "Maestro Movie's first cast member")
        for _ in 0..<8 where !cast.isHittable {
            app.swipeUp()
            _ = waitUntil(0.5) { cast.isHittable }
        }
        cast.tap()
        require("seerrPerson.screen", timeout: 30, "the person page")
        let name = require("seerrPerson.name", timeout: 20, "the person's name")
        let header = require("seerrPerson.header", "the person's header")
        let rest = header.frame.minY
        if element("detail.titleBar").exists { fail("the bar shows over the page at rest") }
        app.swipeUp()
        _ = waitUntil(2) { header.frame.minY < rest - 1 }
        // A page shorter than the screen (an iPad's) doesn't scroll, and nothing goes under Back.
        guard header.frame.minY < rest - 1 else { return }
        let bar = require("detail.titleBar", timeout: 5, "the bar behind Back once the page has scrolled")
        XCTAssertEqual(bar.label, name.label, "the bar names the person")
        let back = app.navigationBars.buttons.firstMatch
        if back.exists, bar.frame.maxY < back.frame.maxY { fail("the bar (to \(bar.frame.maxY)) ends above Back (to \(back.frame.maxY))") }
        // Lets the scroll and the bar's fade settle before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("person page scrolled")
    }
    #endif

    #if !os(tvOS)
    /// Searches Explore for `text` with the field's keyboard search, the field's earlier text cleared first: on iPhone and
    /// iPad the keyboard's Search key, which puts the keyboard away.
    private func search(_ text: String) {
        let field = require("explore.search", "the search field")
        let clear = element("explore.search.clear")
        if clear.exists { press(clear) }
        press(field)
        // One burst, as a fast typist's: the field keeps every key whatever the store echoes meanwhile.
        #if os(iOS)
        field.typeText(text)
        // The keyboard's own Search key, as a user does: the iPhone Duo's simulator takes the test's typed keys as a
        // hardware keyboard's, and a Return typed there leaves the software keyboard up with no field to type into.
        let key = app.keyboards.buttons["Search"]
        if !key.exists(within: 5) { return fail("the keyboard shows no Search key") }
        key.tap()
        if !app.keyboards.firstMatch.waitForNonExistence(timeout: 5) { fail("the keyboard stays after Search") }
        #else
        field.typeText(text + "\n")
        #endif
        _ = waitUntil(5) { (field.value as? String ?? "") == text }
        let shown = field.value as? String ?? ""
        XCTAssertEqual(shown, text, "the field keeps every key typed")
    }

    /// Another tab picked, then Explore's again.
    private func showAgain() {
        press(require("nav.settings", "Settings' tab"))
        require("settings.screen", timeout: 20, "Settings")
        _ = waitUntil(5) { self.element("nav.explore").isHittable }
        press(require("nav.explore", "Explore's tab"))
        require("explore.screen", timeout: 20, "Explore again")
    }

    private var fieldHasFocus: Bool {
        #if os(macOS)
        keyboardFocus == "explore.search"
        #else
        app.descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == true AND identifier == 'explore.search'")).firstMatch.exists
        #endif
    }
    #endif

    /// The card titled `title` in its shelf, its shelf scrolled sideways until it shows whole (iPhone, iPad, Mac).
    private func card(_ title: String) -> XCUIElement {
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label BEGINSWITH %@", title)).firstMatch
        if !card.exists(within: 20) { fail("no card \(title)") }
        #if !os(tvOS)
        let window = besideVerticalBar
        for _ in 0..<6 where card.frame.maxX > window.maxX - 8 {
            let y = (card.frame.midY - window.minY) / window.height
            #if os(macOS)
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: y)).scroll(byDeltaX: -300, deltaY: 0)
            #else
            dragSideways(atY: card.frame.midY, from: 0.85, to: 0.35)
            #endif
            _ = waitUntil(1) { card.frame.maxX <= window.maxX - 8 }
        }
        #endif
        return card
    }

    private func press(_ target: XCUIElement) {
        #if os(macOS)
        target.click()
        #elseif os(iOS)
        target.tap()
        #else
        activate(target)
        #endif
    }

    /// Opens `target`: a tap or a click; on Apple TV focus moved onto it along the page (never along the tab bar), then
    /// Select. A system menu's chip reports its focus on an unnamed element inside it (`LibrarySteps.hasFocus`).
    private func activate(_ target: XCUIElement) {
        #if os(tvOS)
        let steps = LibrarySteps(test: self)
        let tabBar = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'nav.'")).firstMatch
        for direction in [XCUIRemote.Button.down, .right, .down, .right, .down, .right, .up, .left] {
            for _ in 0..<12 where !steps.hasFocus(target) {
                XCUIRemote.shared.press(tabBar.exists ? .down : direction)
                _ = waitUntil(0.3) { steps.hasFocus(target) }
            }
        }
        XCTAssertTrue(steps.hasFocus(target), "\(target.identifier) takes focus")
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        target.click()
        #else
        target.tap()
        #endif
    }

    private func goBack() {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #elseif os(macOS)
        app.buttons.matching(identifier: "chevron.backward").firstMatch.click()
        #else
        backButton.tap()
        #endif
        _ = waitUntil(5) { !self.element("catalogDetail.screen").exists && !self.element("exploreRow.screen").exists }
    }

    /// The fake Seerr's state in this test's run (`GET /__fake/state`), as text.
    private func fakeState() throws -> String {
        let request = URLRequest(url: URL(string: "\(seerrUrl)/__fake/state")!)
        let done = expectation(description: "fake state")
        nonisolated(unsafe) var text = ""
        nonisolated(unsafe) var failure: (any Error)?
        URLSession.shared.dataTask(with: request) { data, _, error in
            failure = error
            text = data.map { String(decoding: $0, as: UTF8.self) } ?? ""
            done.fulfill()
        }.resume()
        wait(for: [done], timeout: 15)
        if let failure { throw failure }
        return text
    }
}
