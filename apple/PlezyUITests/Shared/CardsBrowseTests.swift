#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import XCTest

/// The browse cards and their shared parts against the test Jellyfin server (`PLEZY_DEV_SERVER`, else the default), each
/// kept as a screenshot: a card's title and its episode caption's season part open their details (iPhone, iPad, Mac;
/// the Mac underlines a link under the pointer); a library's and Search's list rows (the metadata line, Search's
/// source line); the hub headers' "N results" over the fake Seerr's Explore shelves and a catalog detail's stats.
final class CardsBrowseTests: PlezyUITestCase {
    #if os(macOS)
    // The Mac runs reach the test servers through loopback tunnels: the local network needs a prompt answered.
    private nonisolated static let host = "127.0.0.1"
    #else
    private nonisolated static let host = "192.168.0.15"
    #endif

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://\(host):28096" : value
    }

    private func launch(_ destination: String, settings: [String] = [], extra: [String] = []) {
        launchDev(settings: settings, arguments: ["--dev-server", Self.server, "--dev-open", destination] + extra)
    }

    // MARK: - Cards

    #if !os(tvOS)
    /// A Continue Watching episode card: its caption's "S1" and its title both open the show at the episode's season;
    /// the Mac underlines the title under the pointer.
    func testCardTitleAndCaptionLinks() {
        restoreContinueWatching()
        launch("home")
        var card = episodeCard()
        // Lets the cards' artwork load before the shot; nothing signals it.
        sleep(3)
        shot("home cards")
        #if os(macOS)
        point(at: card, line: .title).hover()
        sleep(1)
        shot("title link under the pointer", of: card)
        #endif
        press(point(at: card, line: .caption))
        requireShowAtSeason1("the caption's S1")
        shot("season link opened")

        app.terminate()
        launch("home")
        card = episodeCard()
        press(point(at: card, line: .title))
        requireShowAtSeason1("the title")
        shot("title link opened")
    }

    /// Maestro Show's detail on its Season 1 tab (not the episode's own detail, which has no season tabs).
    private func requireShowAtSeason1(_ link: String) {
        require("detail.screen", timeout: 20, "\(link)'s detail")
        let season = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'detail.season.' AND label CONTAINS 'Season 1'")).firstMatch
        if !season.exists(within: 30) { fail("\(link) opens the show at Season 1") }
        // Lets the season's episodes and artwork load before the callers' shots; nothing signals it.
        sleep(3)
    }
    #endif

    // MARK: - List rows

    /// Search's results as list rows, with where each lives; the filter chips.
    func testSearchListRows() {
        launch("search")
        require("search.screen", timeout: 90, "the Search screen")
        type("Maestro")
        let result = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.'")).firstMatch
        if !result.exists(within: 30) { fail("typing Maestro lists no result") }
        // Lets the results' artwork load before the shot; nothing signals it.
        sleep(4)
        shot("search list rows")
        #if !os(tvOS)
        scrollDown()
        // Lets the scroll settle and the artwork load before the shot.
        sleep(2)
        shot("search list rows further")
        #endif
    }

    /// A library's Browse tab as a list (the metadata line), under its header row.
    func testLibraryListRows() {
        launch("libraries", settings: ["view_mode=list"])
        require("libraries.screen", timeout: 60, "Libraries")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Movies")
        steps.showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse list")
        if !app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch.exists(within: 30) {
            fail("the list's rows")
        }
        // Lets the rows' artwork load before the shot; nothing signals it.
        sleep(4)
        shot("library list rows")
    }

    // MARK: - Hub headers

    /// Explore over the fake Seerr: the shelves' headers count their results (not on Apple TV's rail), and a catalog
    /// detail's stats line shows its rating and votes but not the availability that Request shows in its place.
    func testExploreHeadersAndCatalogStats() {
        launch("explore", extra: ["--dev-seerr", "maestro@plezy.test:maestro@http://\(Self.host):28099"])
        require("explore.screen", timeout: 60, "Explore")
        require("hub.explore:seerr:popularMovies", timeout: 30, "the Popular Movies shelf")
        // Lets the shelves' artwork load before the shot; nothing signals it.
        sleep(4)
        shot("explore headers")
        #if !os(tvOS)
        // The count's text is its label on iPhone and iPad, its value on the Mac.
        let counted = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS ' results' OR value CONTAINS ' results'")).firstMatch
        if !counted.exists(within: 10) { fail("a shelf's header counts its results") }
        let movie = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label == 'Maestro Movie'")).firstMatch
        if !movie.exists(within: 20) { fail("no card Maestro Movie") }
        press(movie.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
        require("catalogDetail.screen", timeout: 20, "Maestro Movie's detail")
        // The stats line's text is its label on iPhone and iPad, its value on the Mac.
        let stats = require("catalogDetail.stats", timeout: 15, "Maestro Movie's stats line")
        let available = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier == 'catalogDetail.request' AND (label CONTAINS 'Available' OR value CONTAINS 'Available')"
        )).firstMatch
        if !available.exists(within: 15) { fail("Maestro Movie's Request doesn't say Available") }
        let statsText = "\(stats.label) \(stats.value as? String ?? "")"
        XCTAssertTrue(statsText.contains("votes"), "the stats line shows the votes: \(statsText)")
        XCTAssertFalse(statsText.contains("Available"), "the stats line repeats Request's Available: \(statsText)")
        // Lets the detail's artwork load before the shot; nothing signals it.
        sleep(2)
        shot("catalog detail stat chip")
        #endif
    }

    #if os(tvOS)
    /// A catalog title's library copies on Apple TV over the fake Seerr: Maestro Movie's copy row takes focus, keeps it
    /// while the second match pass (the full details' wider lookup) refreshes the list, opens the library's detail on
    /// Select, and has focus again once Menu comes back from it.
    func testTvLibraryCopiesTakeAndKeepFocus() {
        launch("explore", extra: ["--dev-seerr", "maestro@plezy.test:maestro@http://\(Self.host):28099"])
        require("hub.explore:seerr:popularMovies", timeout: 60, "the Popular Movies shelf")
        // The focus engine drops presses made before the screen settles its focus.
        sleep(3)
        moveFocus(with: .down, limit: 6, "Down reaches a card") { $0.identifier.hasPrefix("card.") }
        moveFocus(with: .right, limit: 20, "Right reaches Maestro Movie") { $0.label == "Maestro Movie" }
        XCUIRemote.shared.press(.select)
        require("catalogDetail.screen", timeout: 20, "Maestro Movie's detail")
        require("catalogDetail.library", timeout: 30, "Maestro Movie's library section")
        moveFocus(with: .down, limit: 20, "Down reaches a library copy") { $0.identifier.hasPrefix("catalogDetail.copy.") }
        let copy = focusedElement.identifier
        shot("library copy focused")
        // The match passes merge into the list while it shows: focus stays on the same copy.
        sleep(8)
        XCTAssertEqual(focusedElement.identifier, copy, "focus stays on the library copy as the list refreshes")
        XCUIRemote.shared.press(.select)
        require("detail.screen", timeout: 20, "Select on the copy opens the library's detail")
        // The focus engine drops a press made while the detail still pushes in.
        sleep(2)
        XCUIRemote.shared.press(.menu)
        require("catalogDetail.screen", timeout: 10, "Menu comes back to the catalog detail")
        _ = waitUntil(10) { focusedElement.identifier == copy }
        XCTAssertEqual(focusedElement.identifier, copy, "focus comes back to the copy that opened the detail")
        shot("library copy after back")
    }

    private var focusedElement: XCUIElement {
        app.descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
    }

    /// Presses `button` until the focused element matches `found`, at most `limit` times.
    private func moveFocus(with button: XCUIRemote.Button, limit: Int, _ what: String, found: (XCUIElement) -> Bool) {
        for _ in 0..<limit {
            if focusedElement.exists, found(focusedElement) { return }
            XCUIRemote.shared.press(button)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(600_000)
        }
        if focusedElement.exists, found(focusedElement) { return }
        fail("\(what): focus is on \(focusedElement.exists ? focusedElement.identifier : "nothing")")
    }
    #endif

    // MARK: - Steps

    #if !os(tvOS)
    private enum Line { case title, caption }

    /// A Continue Watching card of Maestro Show's (an episode), its title and caption on screen.
    private func episodeCard() -> XCUIElement {
        require("hub.continue_watching", timeout: 60, "Continue Watching")
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label == 'Maestro Show'")).firstMatch
        if !card.exists(within: 20) { fail("no Maestro Show card") }
        let window = besideVerticalBar
        // The links are the lines' starts (`point(at:line:)`): those in the window, the card may run past its edge.
        func linesShow() -> Bool {
            let frame = card.frame
            return frame.minX >= window.minX && frame.minX + 48 <= window.maxX
        }
        // Its row scrolled up from under the foot (and a tab bar there), its caption with it.
        for _ in 0..<6 where card.frame.maxY + 40 > window.maxY - 60 { scrollDown() }
        // Continue Watching's wide cards run past a phone's edge: its row dragged sideways to bring the card's start in.
        for _ in 0..<4 where !linesShow() {
            let y = (card.frame.midY - window.minY) / window.height
            #if os(macOS)
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: y)).scroll(byDeltaX: -300, deltaY: 0)
            #else
            // By as much as the card's start lies off a third of the way into the window, at most 0.9 of its width.
            let shift = max(-0.9, min(0.9, (window.minX + window.width / 3 - card.frame.minX) / window.width))
            dragSideways(atY: card.frame.midY, from: 0.5 - shift / 2, to: 0.5 + shift / 2)
            #endif
            _ = waitUntil(1) { linesShow() }
        }
        if !linesShow() { fail("the Maestro Show card's title never came into the window: \(card.frame) in \(window)") }
        return card
    }

    /// The middle of a card's title or the start of its caption (an episode's "S1"): the card's element is its artwork's
    /// button, and the title's line (about 14 points down) and the caption's (about 30) sit under it.
    private func point(at card: XCUIElement, line: Line) -> XCUICoordinate {
        let height = card.frame.height
        let offset = line == .caption ? CGVector(dx: 8, dy: height + 30) : CGVector(dx: min(40, card.frame.width / 3), dy: height + 14)
        return card.coordinate(withNormalizedOffset: .zero).withOffset(offset)
    }

    private func press(_ point: XCUICoordinate) {
        #if os(macOS)
        point.click()
        #else
        point.tap()
        #endif
        // Paces presses: a press during the previous one's transition is dropped.
        sleep(1)
    }

    private func scrollDown() {
        #if os(macOS)
        // The screen's own scroll view: the Mac's window as a whole doesn't take the scroll.
        let screen = element("home.screen")
        (screen.exists ? screen : app.windows.firstMatch).scroll(byDeltaX: 0, deltaY: -300)
        #else
        app.swipeUp()
        #endif
        // Lets the scroll come to rest before frames are read.
        sleep(1)
    }

    /// Puts the test server's two Continue Watching items back as its seed leaves them (Maestro Episode 2 at 70 s,
    /// Resume Movie at 90 s, in progress): other runs play or mark them watched, and the episode card needs both.
    private func restoreContinueWatching() {
        let base = "http://\(Self.host):28096"
        let client = "MediaBrowser Client=\"Plezy UI tests\", Device=\"ui-tests\", DeviceId=\"plezy-ui-tests\", Version=\"1\""
        guard let auth = jellyfin("POST", "\(base)/Users/AuthenticateByName", client: client, token: nil,
                                  body: ["Username": "maestro", "Pw": "maestro"]),
              let token = auth["AccessToken"] as? String,
              let user = (auth["User"] as? [String: Any])?["Id"] as? String else {
            return fail("the test server's sign-in as maestro failed")
        }
        let date = ISO8601DateFormatter().string(from: Date())
        for (title, seconds) in [("Maestro Episode 2", 70), ("Resume Movie", 90)] {
            let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
            let found = jellyfin("GET", "\(base)/Users/\(user)/Items?Recursive=true&IncludeItemTypes=Episode,Movie&SearchTerm=\(query)",
                                 client: client, token: token, body: nil)
            let items = found?["Items"] as? [[String: Any]] ?? []
            guard let id = items.first(where: { $0["Name"] as? String == title })?["Id"] as? String else {
                return fail("the test server has no \(title)")
            }
            _ = jellyfin("POST", "\(base)/UserItems/\(id)/UserData?userId=\(user)", client: client, token: token, body: [
                "PlaybackPositionTicks": seconds * 10_000_000, "Played": false, "LastPlayedDate": date,
            ])
        }
    }

    /// `method` `url` on the test server, waited for; its JSON answer (an empty one for none), nil when it failed.
    private func jellyfin(_ method: String, _ url: String, client: String, token: String?, body: [String: Any]?) -> [String: Any]? {
        var request = URLRequest(url: URL(string: url)!, timeoutInterval: 15)
        request.httpMethod = method
        request.setValue(client, forHTTPHeaderField: "X-Emby-Authorization")
        if let token { request.setValue(token, forHTTPHeaderField: "X-Emby-Token") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        let done = expectation(description: "\(method) \(url)")
        nonisolated(unsafe) var answer: [String: Any]?
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) {
                answer = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
            }
            done.fulfill()
        }.resume()
        wait(for: [done], timeout: 20)
        return answer
    }
    #endif

    /// Types `text` into Search's field: on Apple TV the system's search field (`searchable`), whose keyboard Down
    /// reaches; on an iPad with its software keyboard's keys (typeText switching it to the hardware keyboard ends the app).
    private func type(_ text: String) {
        #if os(tvOS)
        let field = app.searchFields.firstMatch
        if !field.exists(within: 10) { fail("Search shows no search field") }
        // Down pressed before the screen settles its focus moves nothing: pressed again until the keyboard has the focus.
        let keyboardFocus = app.descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == 1"))
        for _ in 0..<3 where keyboardFocus.count == 0 {
            XCUIRemote.shared.press(.down)
            _ = waitUntil(2) { keyboardFocus.count > 0 }
        }
        if keyboardFocus.count == 0 { fail("Down from the search field reaches no keyboard") }
        field.typeText(text)
        #else
        let field = require("search.field", "the search field")
        #if os(macOS)
        field.click()
        field.typeText(text)
        #else
        let hasFocus = { field.value(forKey: "hasKeyboardFocus") as? Bool == true }
        for _ in 0..<3 where !hasFocus() {
            field.tap()
            _ = waitUntil(2, hasFocus)
        }
        if !hasFocus() { fail("the search field doesn't take the keyboard focus") }
        if UIDevice.current.userInterfaceIdiom == .pad {
            for character in text.lowercased() {
                let name = character == " " ? "space" : String(character)
                let key = app.keyboards.keys.matching(NSPredicate(format: "label ==[c] %@ OR identifier ==[c] %@", name, name)).firstMatch
                if !key.exists(within: 5) { fail("the keyboard has no \(character) key") }
                key.tap()
            }
            return
        }
        field.typeText(text)
        #endif
        #endif
    }
}
