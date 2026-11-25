import XCTest

/// Every page header's action row (a primary pill and round actions) against the test servers: a movie, a show, a
/// season, an episode, a collection, an album, an artist, an audio playlist on the music playlist screen, a video
/// playlist on the playlist screen, a Seerr title (the fake Seerr) and, where the device has downloads, a
/// downloaded movie's detail. On each, every button on the primary pill's line (the element tree's buttons whose frame
/// crosses the pill's centre line) is as tall as the pill and centred on its centre, within 1 pt; on Apple TV the
/// focused one, grown by its focus, aside. At the default text size, and on iPhone and iPad at an accessibility one
/// (the app's own content size, `UIPreferredContentSizeCategoryName` at launch). Each row is kept as a screenshot with
/// its element tree and its measures (`<screen> heights.txt`).
final class ActionRowTests: PlezyUITestCase {
    #if os(macOS)
    // The Mac's test runs reach the test servers through tunnels on its loopback.
    private static let host = "127.0.0.1"
    #else
    private static let host = "192.168.0.15"
    #endif
    private static let server = "jellyfin=maestro:maestro@http://\(host):28096"
    private let seerrAccount = "maestro@plezy.test:maestro@http://\(ActionRowTests.host):28099/run/\(UUID().uuidString)"

    func testMovie() { check("movie", item: "Maestro_Movie", primary: "detail.play") }
    func testShow() { check("show", item: "Maestro_Show", primary: "detail.play") }
    func testSeason() { check("season", item: "Maestro_Show/Season_1", primary: "detail.play") }
    func testEpisode() { check("episode", item: "Maestro_Show/Season_1/Maestro_Episode_2", primary: "detail.play") }
    func testCollection() { check("collection", item: "Plezy_Picks", primary: "collection.play") }
    func testAlbum() { check("album", music: "album=Sine Album", primary: "music.play") }
    func testArtist() { check("artist", music: "artist=Plezy Test Artist", primary: "music.play") }
    func testMusicPlaylist() { check("music playlist", music: "playlist=Plezy Mix", primary: "music.play") }
    func testVideoPlaylist() { check("video playlist", playlist: "Binge") }
    func testCatalogTitle() { checkCatalog(large: false) }
    #if !os(tvOS)
    func testDownloadedMovie() { checkDownloaded(large: false) }
    #endif

    #if os(iOS)
    func testMovieAtLargeText() { check("movie", item: "Maestro_Movie", primary: "detail.play", large: true) }
    func testShowAtLargeText() { check("show", item: "Maestro_Show", primary: "detail.play", large: true) }
    func testSeasonAtLargeText() { check("season", item: "Maestro_Show/Season_1", primary: "detail.play", large: true) }
    func testEpisodeAtLargeText() {
        check("episode", item: "Maestro_Show/Season_1/Maestro_Episode_2", primary: "detail.play", large: true)
    }
    func testCollectionAtLargeText() { check("collection", item: "Plezy_Picks", primary: "collection.play", large: true) }
    func testAlbumAtLargeText() { check("album", music: "album=Sine Album", primary: "music.play", large: true) }
    func testArtistAtLargeText() { check("artist", music: "artist=Plezy Test Artist", primary: "music.play", large: true) }
    func testMusicPlaylistAtLargeText() { check("music playlist", music: "playlist=Plezy Mix", primary: "music.play", large: true) }
    func testVideoPlaylistAtLargeText() { check("video playlist", playlist: "Binge", large: true) }
    func testCatalogTitleAtLargeText() { checkCatalog(large: true) }
    func testDownloadedMovieAtLargeText() { checkDownloaded(large: true) }
    func testMusicPlaylistAtLargeTextKeepsEveryAction() {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open-music", "playlist=Plezy Mix"] + textSize(true))
        requireEveryAction("music playlist", primary: "music.play", more: "music.playlist.more", actions: ["music.shuffle": "Shuffle", "music.playlist.delete": "Delete Playlist"])
    }

    func testVideoPlaylistAtLargeTextKeepsEveryAction() {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-playlist", "jellyfin:Binge"] + textSize(true))
        requireEveryAction("video playlist", primary: "playlist.play", more: "playlist.more", actions: ["playlist.shuffle": "Shuffle", "playlist.delete": "Delete Playlist"])
    }
    #endif

    /// Every one of `actions` (identifier: title) is on the row or, where the row folds it away, in its ⋯ (`more`).
    private func requireEveryAction(_ name: String, primary: String, more: String, actions: [String: String]) {
        require(primary, timeout: 60, "the \(name)'s Play")
        _ = waitUntil(5) { actions.keys.allSatisfy { element($0).exists } }
        let folded = actions.filter { !element($0.key).exists }
        if folded.isEmpty { return }
        press(require(more, "the \(name)'s ⋯, holding \(folded.values.sorted())"))
        for (id, title) in folded {
            XCTAssertTrue(element(id).exists(within: 5), "\(name) at large text: \(title) is neither on the row nor in ⋯")
        }
        shotOfMenu("\(name) large text menu")
    }

    /// The launch arguments of the text size: an accessibility one where `large`.
    private func textSize(_ large: Bool) -> [String] {
        large ? ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"] : []
    }

    private func check(_ name: String, item: String? = nil, music: String? = nil, playlist: String? = nil, primary: String = "playlist.play", large: Bool = false) {
        var arguments = ["--dev-server", Self.server]
        if let item { arguments += ["--dev-open-item", item] }
        if let music { arguments += ["--dev-open-music", music] }
        if let playlist { arguments += ["--dev-playlist", "jellyfin:\(playlist)"] }
        launchDev(arguments: arguments + textSize(large))
        checkRow(name, primary: primary, large: large)
    }

    /// Explore over the fake Seerr, the requestable movie's card pressed: its detail's row.
    private func checkCatalog(large: Bool) {
        launchDev(arguments: ["--dev-open", "explore", "--dev-server", Self.server, "--dev-seerr", seerrAccount] + textSize(large))
        require("explore.screen", timeout: 60, "Explore")
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label == 'Unrequested Utopia'")).firstMatch
        if !card.exists(within: 30) { fail("no card Unrequested Utopia") }
        #if os(iOS)
        // Its shelf scrolls sideways: dragged until the card is on screen.
        let width = app.windows.firstMatch.frame.width
        for _ in 0..<8 where card.frame.maxX > width || card.frame.minX < 0 {
            dragSideways(atY: card.frame.midY, from: 0.8, to: 0.3)
            _ = waitUntil(2) { card.frame.maxX <= width && card.frame.minX >= 0 }
        }
        #endif
        reach(card, "Unrequested Utopia's card")
        require("catalogDetail.screen", timeout: 30, "Unrequested Utopia's detail")
        let actions = ["catalogDetail.watchlist", "catalogDetail.request", "catalogDetail.trailer"]
        let first = app.descendants(matching: .any).matching(NSPredicate(format: "identifier IN %@", actions)).firstMatch
        if !first.exists(within: 30) { fail("Unrequested Utopia's detail shows no action") }
        checkRow("catalog title", primary: first.identifier, large: large, actions: actions)
    }

    #if !os(tvOS)
    /// A downloaded movie opened from Downloads' Movies tab: its offline detail's row.
    private func checkDownloaded(large: Bool) {
        launchDev(arguments: ["--dev-open", "downloads", "--dev-server", Self.server, "--dev-download", "Maestro_Movie"] + textSize(large))
        require("downloads.screen", timeout: 60, "the Downloads screen")
        #if os(macOS)
        app.activate()
        #endif
        let tab = require("downloads.tab", "the Downloads tab menu")
        let movies = LibrarySteps(test: self).option("downloads.tab", label: "Movies")
        // The header row settles as the screen opens: a press meant for the tab menu reached the view menu beside it on
        // the Mac. Closed and pressed again then.
        for _ in 0..<3 where !movies.exists {
            // Lets the header row settle; nothing signals the end of its layout.
            Thread.sleep(forTimeInterval: 2)
            press(tab)
            if movies.exists(within: 5) { break }
            #if os(macOS)
            app.typeKey(.escape, modifierFlags: [])
            #endif
        }
        if !movies.exists { fail("Movies in the Downloads tab menu") }
        LibrarySteps(test: self).pressOption(movies)
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 300) { fail("the Movies tab lists no downloaded Maestro Movie after 300 s") }
        #if os(macOS)
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        card.tap()
        #endif
        checkRow("downloaded movie", primary: "detail.play", large: large)
    }
    #endif

    /// Waits for `primary` and the row's settling, brings the row into the window, shoots it and checks every button on
    /// its line against it.
    private func checkRow(_ name: String, primary id: String, large: Bool, actions: [String] = []) {
        let label = "\(name)\(large ? " large text" : "")"
        let primary = require(id, timeout: 60, "the \(name)'s \(id)")
        // The artwork, the download state and the server's extras (trailers, the watchlist) come over the network.
        Thread.sleep(forTimeInterval: 5)
        let window = app.windows.firstMatch.frame
        #if os(iOS)
        for _ in 0..<4 where primary.frame.maxY > window.maxY - 90 {
            app.swipeUp(velocity: .slow)
            _ = waitUntil(2) { primary.frame.maxY <= window.maxY - 90 }
        }
        #endif
        guard let tree = try? app.snapshot() else { return fail("no element tree of the \(label)") }
        guard let pill = Self.buttons(in: tree).first(where: { $0.identifier == id }) else {
            return fail("the \(label)'s \(id) isn't a button in the element tree")
        }
        let line = pill.frame.midY
        let crossing = Self.buttons(in: tree)
            // The tab bar's items aside: on the iPhone Duo its column stands beside the row.
            .filter { !$0.identifier.isEmpty && !$0.identifier.hasPrefix("nav.") && $0.frame.minY < line && $0.frame.maxY > line }
            .filter { window.intersects($0.frame) }
            .reduce(into: [XCUIElementSnapshot]()) { kept, button in
                // A button nested in another of the same name (a menu's label) counts once.
                if !kept.contains(where: { $0.identifier == button.identifier }) { kept.append(button) }
            }
            .sorted { $0.frame.minX < $1.frame.minX }
        // The row: the pill and its neighbours each within a gap of the last, not what sits further along the line (a
        // show's episodes beside its details on iPad).
        let start = crossing.firstIndex { $0.identifier == id } ?? 0
        var lower = start, upper = start
        while lower > 0, crossing[lower].frame.minX - crossing[lower - 1].frame.maxX < Self.rowGap { lower -= 1 }
        while upper < crossing.count - 1, crossing[upper + 1].frame.minX - crossing[upper].frame.maxX < Self.rowGap { upper += 1 }
        let row = Array(crossing[lower...upper])
        let measures = row.map { button in
            String(format: "%@ height %.1f centre %.1f%@", button.identifier, button.frame.height, button.frame.midY, Self.focused(button) ? " focused" : "")
        }
        shot("\(label) row")
        let attachment = XCTAttachment(string: measures.joined(separator: "\n") + "\n")
        attachment.name = "\(label) heights.txt"
        attachment.lifetime = .keepAlways
        add(attachment)
        let onRow = Set(row.map(\.identifier))
        if actions.isEmpty {
            XCTAssertGreaterThan(row.count, 1, "the \(label)'s row holds \(id) and its round actions: \(measures)")
        } else {
            let shown = Set(Self.buttons(in: tree).map(\.identifier))
            let off = actions.filter { shown.contains($0) && !onRow.contains($0) }
            XCTAssertTrue(off.isEmpty, "the \(label)'s actions \(off) sit off \(id)'s line: \(measures)")
        }
        // Apple TV's focused button, grown by its focus, aside; a lone focused action has nothing to compare.
        let compared = row.filter { !Self.focused($0) }
        guard let reference = compared.first(where: { $0.identifier == id }) ?? compared.first else { return }
        let off = compared.filter {
            abs($0.frame.height - reference.frame.height) > 1 || abs($0.frame.midY - reference.frame.midY) > 1
        }
        XCTAssertTrue(off.isEmpty, "the \(label)'s row buttons share \(reference.identifier)'s height and centre (±1 pt): \(measures.joined(separator: "; "))")
    }

    /// The widest gap between two neighbours of one row: wider than every row's spacing (Apple TV's 24 pt), narrower
    /// than the gutter between the details and a show's episodes.
    private static let rowGap: CGFloat = 40

    /// The buttons of `tree` (buttons, menu buttons, pop-up buttons), depth first.
    private static func buttons(in tree: XCUIElementSnapshot) -> [XCUIElementSnapshot] {
        let types: Set<XCUIElement.ElementType> = [.button, .menuButton, .popUpButton]
        var found: [XCUIElementSnapshot] = []
        var stack = [tree]
        while let next = stack.popLast() {
            if types.contains(next.elementType), !next.frame.isEmpty { found.append(next) }
            stack.append(contentsOf: next.children.reversed())
        }
        return found
    }

    /// Whether `button` holds the focus, which on Apple TV grows it.
    private static func focused(_ button: XCUIElementSnapshot) -> Bool {
        #if os(tvOS)
        button.hasFocus
        #else
        false
        #endif
    }

    /// Taps or clicks `element`.
    private func press(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #elseif os(iOS)
        element.tap()
        #endif
    }

    /// Presses `target`: a tap or a click; on Apple TV focus walked to it (each press the way it lies from the focused
    /// element, out of the tab bar first), then Select.
    private func reach(_ target: XCUIElement, _ what: String) {
        #if os(tvOS)
        let focusedNow = { self.app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch }
        for _ in 0..<30 {
            let now = focusedNow()
            if now.exists, now.frame.insetBy(dx: -4, dy: -4).contains(target.frame) { break }
            let to = target.frame, from = now.exists ? now.frame : .zero
            let direction: XCUIRemote.Button = if now.exists, now.identifier.hasPrefix("nav.") {
                .down
            } else if to.minY >= from.maxY - 1 {
                .down
            } else if to.maxY <= from.minY + 1 {
                .up
            } else {
                to.midX > from.midX ? .right : .left
            }
            XCUIRemote.shared.press(direction)
            _ = waitUntil(2) { let moved = focusedNow(); return moved.exists && moved.frame != from }
        }
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        target.tap()
        #endif
    }
}
