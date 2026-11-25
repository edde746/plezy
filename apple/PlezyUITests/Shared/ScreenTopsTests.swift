import XCTest

/// The top of every top-level screen against the test servers, in the dark theme, each kept as a screenshot at rest and
/// scrolled: Home, Libraries (Movies, Shows, Music, Home Videos, each in Browse), Discover, Live TV, Downloads, Search.
/// Library's header row lies whole on the screen, no control over another; its type is the row's last filter and shows
/// its symbol alone, read by VoiceOver with its name; where iOS 27.1's vertical bar shows (the iPhone Duo), Library's
/// Shuffle and ⋯ are in the bar's column, beside the tabs, not in the row; and Home's and Discover's content scrolled up
/// under the top of the window
/// fades there into the screen's black. Without Live TV on any server (Emby's lists no channels
/// without Emby Premiere) Home offers no Live TV shortcut. The library picker names the library, Movies' and Music's
/// whole on iOS, and Movies' and Music's Shuffle is in the row or the ⋯ menu; where the vertical bar shows, nothing of
/// the content (Home's and Discover's shelves, Live TV's guide) runs on under its column.
final class ScreenTopsTests: PlezyUITestCase {
    #if os(macOS)
    // The Mac's runs reach the test servers through tunnels on its loopback.
    private nonisolated static let host = "127.0.0.1"
    #else
    private nonisolated static let host = "192.168.0.15"
    #endif

    private static var jellyfin: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://\(host):28096" : value
    }

    private static let emby = "emby=maestro:maestro@http://\(host):28097"

    private let seerrUrl = "\(ProcessInfo.processInfo.environment["PLEZY_SEERR_URL"] ?? "http://\(ScreenTopsTests.host):28099")/run/\(UUID().uuidString)"

    private func open(_ destination: String, screen: String, server: String = ScreenTopsTests.jellyfin, extra: [String] = []) {
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", server, "--dev-open", destination] + extra)
        require(screen, timeout: 90, "the \(destination) screen")
        // The artwork comes over the network.
        sleep(5)
    }

    func testHome() {
        open("home", screen: "home.screen")
        shot("home")
        requireNothingUnderBar("Home's shelves")
        require("home.liveTv", timeout: 30, "Home's Live TV shortcut (the Jellyfin server has Live TV)")
        scrollDown()
        shot("home scrolled")
        requireNothingUnderBar("Home's shelves scrolled")
        #if os(iOS)
        let brightness = topBrightness()
        XCTAssertLessThan(brightness, 0.1, "Home's shelves fade into the black under the top of the window (brightness \(brightness))")
        #endif
    }

    func testHomeWithoutLiveTv() {
        open("home", screen: "home.screen", server: Self.emby)
        shot("home emby")
        XCTAssertFalse(element("home.liveTv").exists(within: 10), "Home offers Live TV with no server having it")
    }

    func testLibraryMovies() {
        library("Movies")
        requireLibraryNamed("Movies", whole: true)
        requireShuffleReachable()
    }

    func testLibraryShows() {
        library("Shows")
        requireTypeLast()
        requireActionsWhereThePlatformPutsThem()
    }

    func testLibraryMusic() {
        library("Music")
        requireLibraryNamed("Music", whole: true)
        requireShuffleReachable()
    }

    func testLibraryHomeVideos() {
        library("Home Videos")
        requireLibraryNamed("Home Videos")
    }

    func testLibraryCodecSamples() {
        library("Codec Samples")
        requireLibraryNamed("Codec Samples", whole: true)
    }

    #if os(iOS)
    /// iPhone's Libraries tab tapped again while it shows: Movies' grid, scrolled down past its first row, comes back to
    /// its top, its first card on the screen again.
    func testLibrariesTabReselectedScrollsToTheTop() throws {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "iPad's sidebar has no Libraries row to tap again")
        open("libraries", screen: "libraries.screen")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Movies")
        steps.showLibraryTab("browse")
        let first = steps.prefixed("card.")
        if !first.exists(within: 30) { return fail("Movies' grid shows no card") }
        let id = first.identifier
        let card = element(id)
        for _ in 0..<3 { drag(from: 0.8, to: 0.2) }
        if steps.onScreen(card) { return fail("Movies' first card (\(id)) still shows after three drags down the grid") }
        shot("libraries scrolled")
        let tab = app.tabBars.buttons.matching(identifier: "nav.libraries").firstMatch
        (tab.exists(within: 5) ? tab : require("nav.libraries", "the Libraries tab")).tap()
        _ = waitUntil(5) { steps.onScreen(card) }
        shot("libraries tab tapped again")
        XCTAssertTrue(steps.onScreen(card), "the Libraries tab tapped again brings Movies' grid back to its first card (\(id))")
    }
    #endif

    func testExplore() {
        open("explore", screen: "explore.screen", extra: ["--dev-seerr", "maestro@plezy.test:maestro@\(seerrUrl)"])
        require("hub.explore:seerr:trending", timeout: 30, "Discover's Trending shelf")
        // The shelves' artwork comes over the network.
        sleep(3)
        shot("explore")
        requireNothingUnderBar("Discover's shelves")
        scrollDown()
        scrollDown()
        shot("explore scrolled")
        #if !os(tvOS)
        let brightness = topBrightness()
        XCTAssertLessThan(brightness, 0.1, "Discover's shelves fade into the black under the top of the window (brightness \(brightness))")
        #endif
    }

    func testLiveTv() {
        open("live_tv", screen: "livetv.screen")
        require("livetv.guide.channel.0", timeout: 60, "the guide's channels")
        // The channels' logos come over the network.
        sleep(3)
        shot("live tv")
        requireNoOverlap(["livetv.tab.guide", "livetv.tab.whatsOn", "livetv.tab.recordings", "livetv.action.search", "livetv.action.refresh"])
        let channel = require("livetv.guide.channel.0", "the first channel").frame
        let window = app.windows.firstMatch.frame
        requireNothingUnderBar(
            "the first channel's airings", top: (channel.minY - window.minY) / window.height, bottom: (channel.maxY - window.minY) / window.height
        )
        #if os(iOS)
        // Part of a half hour on: the time scrolled past the channel column held whole beside it.
        dragSideways(atY: channel.midY - window.minY, from: 0.7, to: 0.6)
        shot("live tv scrolled")
        #endif
    }

    #if !os(tvOS)
    func testDownloads() {
        open("downloads", screen: "downloads.screen")
        shot("downloads")
    }
    #endif

    func testSearch() {
        open("search", screen: "search.screen")
        shot("search")
    }

    /// The library `title` in Browse, shot at rest and scrolled; its header row's controls each whole on the screen
    /// (beside the vertical bar, where it shows) and none over another.
    private func library(_ title: String) {
        open("libraries", screen: "libraries.screen")
        let steps = LibrarySteps(test: self)
        steps.pickLibrary(title)
        steps.showLibraryTab("browse")
        // The cards' artwork comes over the network.
        sleep(3)
        shot("libraries \(title)")
        requireHeaderUnclipped()
        scrollDown()
        shot("libraries \(title) scrolled")
    }

    /// Library's header row: its filters lie whole inside the content area, and they, Shuffle and ⋯ lie side by side.
    /// A control's frame is its smallest element of that identifier, and no bar: iPad's toolbar carries its items' too.
    private func requireHeaderUnclipped() {
        let row = ["libraries.library", "libraries.view", "libraries.sort", "libraries.filters", "libraries.grouping"]
        require("libraries.library", timeout: 30, "Library's library menu")
        let frames = (row + ["libraries.shuffle", "libraries.more"]).compactMap { id -> (String, CGRect)? in
            let matches = app.descendants(matching: .any).matching(identifier: id).allElementsBoundByIndex.map(\.frame)
                .filter { !$0.isEmpty && $0.height < 100 }
            return matches.min { $0.width * $0.height < $1.width * $1.height }.map { (id, $0) }
        }
        let area = besideVerticalBar.insetBy(dx: -1, dy: -1)
        for (id, frame) in frames where row.contains(id) {
            XCTAssertTrue(area.contains(frame), "\(id) \(frame) is cut off by the edge of \(area)")
        }
        for (i, a) in frames.enumerated() {
            for b in frames.dropFirst(i + 1) {
                XCTAssertFalse(a.1.insetBy(dx: 1, dy: 1).intersects(b.1.insetBy(dx: 1, dy: 1)), "\(a.0) \(a.1) overlaps \(b.0) \(b.1)")
            }
        }
    }

    /// Library's type is the header row's last filter, its symbol alone, read with its name.
    private func requireTypeLast() {
        let type = require("libraries.grouping", timeout: 30, "Library's type")
        // A Mac menu button carries its label as its title.
        let spoken = type.label.isEmpty ? type.title : type.label
        XCTAssertTrue(spoken.contains(":"), "the type reads its name and pick (\(spoken))")
        for other in ["libraries.view", "libraries.sort", "libraries.filters"] {
            let control = element(other)
            guard control.exists else { continue }
            XCTAssertLessThan(control.frame.midX, type.frame.midX, "\(other) comes before the type")
        }
        XCTAssertLessThan(type.frame.width, type.frame.height * 2.5, "the type shows its symbol alone (\(type.frame.size))")
    }

    /// Where iOS 27.1's vertical bar shows, Library's ⋯ is in its column, beside the tabs, not in the header row.
    private func requireActionsWhereThePlatformPutsThem() {
        #if os(iOS)
        let tabs = require("nav.home", "the tabs").frame
        let settings = require("nav.settings", "the tabs' Settings").frame
        guard abs(tabs.midX - settings.midX) < 1 else { return }
        let more = app.buttons.matching(NSPredicate(format: "label == %@", "Options")).firstMatch
        XCTAssertTrue(more.exists(within: 10), "Library's ⋯ shows")
        XCTAssertEqual(more.frame.midX, tabs.midX, accuracy: tabs.width, "Library's ⋯ is in the vertical bar's column")
        #endif
    }

    /// The controls `ids` that show lie side by side, none over another.
    private func requireNoOverlap(_ ids: [String]) {
        let frames = ids.map(element).filter(\.exists).map(\.frame)
        for (i, a) in frames.enumerated() {
            for b in frames.dropFirst(i + 1) {
                XCTAssertFalse(a.insetBy(dx: 1, dy: 1).intersects(b.insetBy(dx: 1, dy: 1)), "\(a) overlaps \(b)")
            }
        }
    }

    /// The library picker names the library `title` in the header row, which stays at the top as the grid scrolls:
    /// wider than the type, which shows its symbol alone; where `whole`, at least as wide as it takes to show all of
    /// `title` (`pickerWidth`), not cut short. A control's frame is its widest element of that identifier in the row's
    /// height (iPad's toolbar carries its items' too). On iOS: the Mac's menus report their labels' text alone.
    private func requireLibraryNamed(_ title: String, whole: Bool = false) {
        #if os(iOS)
        require("libraries.library", timeout: 30, "the library picker")
        func frame(_ id: String) -> CGRect? {
            app.descendants(matching: .any).matching(identifier: id).allElementsBoundByIndex.map(\.frame)
                .filter { !$0.isEmpty && $0.height < 100 }
                .max { $0.width < $1.width }
        }
        guard let picker = frame("libraries.library"), let type = frame("libraries.grouping") else { return }
        XCTAssertGreaterThan(picker.width, type.width + 16, "the library picker names \(title) (\(picker.size) beside the type's \(type.size))")
        if whole {
            let needed = pickerWidth(showing: title)
            XCTAssertGreaterThanOrEqual(picker.width, needed - 1, "the library picker shows \(title) whole (\(picker.width) of \(needed) pt)")
        }
        #endif
    }

    #if os(iOS)
    /// The narrowest the library picker shows `title` whole: the text in the row's font (subheadline, medium), the
    /// capsule's 12 pt insets, then the 6 pt gap and the chevron (caption, bold) after it. Cut short it is narrower by
    /// at least the cut letters' width less an ellipsis'.
    private func pickerWidth(showing title: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .medium)
        let text = (title as NSString).size(withAttributes: [.font: font]).width
        let chevronFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .bold)
        let chevron = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(font: chevronFont))?.size.width ?? 0
        return ceil(text) + 2 * 12 + 6 + chevron
    }
    #endif

    /// Library's Shuffle is in the header row (or the bar), else the ⋯ menu's first entry. The Mac leaves an open menu
    /// out of the element tree: on iOS.
    private func requireShuffleReachable() {
        #if os(iOS)
        let inRow = element("libraries.shuffle").exists(within: 5)
        // iPad's row has the room: it moves no action into the menu.
        if UIDevice.current.userInterfaceIdiom == .pad { XCTAssertTrue(inRow, "Shuffle in iPad's header row") }
        guard !inRow else { return }
        let steps = LibrarySteps(test: self)
        let more = require("libraries.more", timeout: 10, "the ⋯ menu")
        let glyph = more.images["ellipsis"]
        (glyph.exists ? glyph : more).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(element("libraries.shuffle").exists(within: 10), "Shuffle in the ⋯ menu, which the row has no room for")
        shot("libraries shuffle in more")
        steps.dismissMenu()
        #endif
    }

    /// Where iOS 27.1's vertical bar shows (`besideVerticalBar`), the gap between the content's safe area and the
    /// bar's column from `top` to `bottom` (of the window's height; by default its upper part, beside the clock and the
    /// bar's first buttons) shows the screen's black: nothing of the content (a shelf's cards, the guide's airings)
    /// runs on under the column.
    private func requireNothingUnderBar(_ what: String, top: CGFloat = 0.1, bottom: CGFloat = 0.45) {
        #if os(iOS)
        let window = app.windows.firstMatch.frame
        let area = besideVerticalBar
        guard area != window else { return }
        let x = area.maxX < window.maxX ? area.maxX - 12 : area.minX + 2
        let strip = CGRect(x: x - window.minX, y: window.height * top, width: 10, height: window.height * (bottom - top))
        let brightness = brightness(of: strip)
        XCTAssertLessThan(brightness, 0.02, "\(what) run on under the vertical bar's column (brightness \(brightness) at \(strip))")
        #endif
    }

    private func scrollDown() { drag(from: 0.7, to: 0.35) }

    /// The content moved by part of the window, without a fling (the Mac: a scroll over it), then left to settle.
    private func drag(from: CGFloat, to: CGFloat) {
        #if os(tvOS)
        for _ in 0..<3 { XCUIRemote.shared.press(to > from ? .up : .down) }
        #elseif os(macOS)
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6)).scroll(byDeltaX: 0, deltaY: (to - from) * 700)
        #else
        let area = besideVerticalBar
        let window = app.windows.firstMatch.frame
        let x = (area.midX - window.minX) / window.width
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: from))
        start.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: to)), withVelocity: .slow, thenHoldForDuration: 0.3)
        #endif
        // Lets the scroll come to rest before a shot or a brightness reading.
        sleep(2)
    }

    /// The mean brightness (0 black to 1 white) of a strip across the window's top, mid-width.
    private func topBrightness() -> Double {
        let frame = app.windows.firstMatch.frame
        return brightness(of: CGRect(x: frame.width * 0.35, y: 2, width: frame.width * 0.3, height: 4))
    }

    /// The mean brightness (0 black to 1 white) of `strip`, in points from the window's top leading corner.
    private func brightness(of strip: CGRect) -> Double {
        let window = app.windows.firstMatch
        let frame = window.frame
        let shot = window.screenshot()
        #if os(macOS)
        guard let image = shot.image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return 1 }
        #else
        guard let image = shot.image.cgImage else { return 1 }
        #endif
        let scale = CGFloat(image.width) / frame.width
        let crop = CGRect(x: strip.minX * scale, y: strip.minY * scale, width: strip.width * scale, height: strip.height * scale).integral
        guard let part = image.cropping(to: crop) else { return 1 }
        let width = part.width, height = part.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { bytes in
            CGContext(
                data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ).map { $0.draw(part, in: CGRect(x: 0, y: 0, width: width, height: height)); return true } ?? false
        }
        guard drawn, width * height > 0 else { return 1 }
        var sum = 0
        for pixel in 0..<(width * height) {
            sum += Int(pixels[pixel * 4]) + Int(pixels[pixel * 4 + 1]) + Int(pixels[pixel * 4 + 2])
        }
        return Double(sum) / Double(width * height * 3 * 255)
    }
}
