import XCTest
#if os(iOS)
import UIKit
#endif

#if !os(tvOS)
/// A page header's controls across its states, against the development Jellyfin (`PLEZY_DEV_SERVER` or the default): a
/// detail's ⋯ offers none of the actions its row shows as buttons; an album's ⋯ none of its row's either, and a track's
/// ⋯ is the system's menu, saying Played and Unplayed; on iPhone the cast button sits in the navigation bar across from
/// Back, out of the row, and both, with the title and its facts, stand out over a bright backdrop. On iPhone's movie,
/// and on the Mac's movie, show, album and audio playlist, the bar naming the page fades in once its title has gone
/// under the bar (the Mac's toolbar), the page and Back holding still as it does and the title showing once, whole and
/// readable on the bar: the window's toolbar shows none.
final class DetailHeaderControlsTests: PlezyUITestCase {
    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        guard value.isEmpty else { return value }
        #if os(macOS)
        return "jellyfin=maestro:maestro@http://127.0.0.1:28096"
        #else
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
        #endif
    }

    /// A row button and the menu entries it stands for.
    private static let rowEntries: [(button: String, entries: [String])] = [
        ("detail.versions", ["menu.play_version"]),
        ("detail.trailer", ["menu.play_trailer"]),
        ("detail.shuffle", ["menu.shuffle_play"]),
        ("detail.download", ["menu.download", "menu.manage_sync", "menu.remove_sync", "menu.delete_download"]),
        ("detail.watched", ["menu.watch", "menu.unwatch"]),
        ("detail.watchlist", ["menu.watchlist_add", "menu.watchlist_remove"]),
    ]

    func testDetailMenuLeavesOutWhatTheRowShows() {
        for title in ["Maestro Movie", "Maestro Show"] {
            openDetail(title)
            let shown = Self.rowEntries.compactMap { row -> (button: String, entries: [String])? in
                let button = element(row.button)
                guard button.exists else { return nil }
                // The watched toggle marks the item one way, as its label says: a partly watched one keeps the other.
                guard row.button == "detail.watched" else { return row }
                return (row.button, [button.label.lowercased().contains("unwatched") ? "menu.unwatch" : "menu.watch"])
            }
            if shown.isEmpty { fail("\(title)'s row shows no button besides Play") }
            tap(require("detail.more", "\(title)'s ⋯"))
            requireMenu("\(title)'s menu")
            // Lets the menu's opening animation finish before the screenshot.
            Thread.sleep(forTimeInterval: 1)
            shot("\(title) more menu")
            for (button, entries) in shown {
                for entry in entries where element(entry).exists {
                    fail("\(title)'s ⋯ offers \(entry), which the row shows as \(button)")
                }
            }
            for (button, entries) in Self.rowEntries where !element(button).exists && button == "detail.watched" {
                if !entries.contains(where: { element($0).exists }) { fail("\(title)'s ⋯ lost the watched toggle the row shed") }
            }
        }
    }

    func testAlbumMenusAreTheSystemsAndSayPlayed() {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open-music", "album=Sine Album"])
        require("music.album", timeout: 60, "the album screen")
        require("music.track.1", timeout: 30, "the album's tracks")
        // The album's artwork comes over the network before the screenshot; nothing signals it.
        Thread.sleep(forTimeInterval: 2)
        shot("album")
        tap(require("music.album.more", "the album's ⋯"))
        requireMenu("the album's ⋯ opens the system's menu, headed by the album")
        for entry in ["menu.music_play", "menu.music_instant_mix", "menu.download", "menu.delete_download"] where element(entry).exists {
            fail("the album's ⋯ offers \(entry), which its row shows")
        }
        shot("album menu")
        dismissMenu()
        tap(require("music.track.1.more", "Low Hum's ⋯"))
        requireMenu("the track's ⋯ opens the system's menu, headed by the track")
        #if os(iOS)
        let title = element("menu.title").label
        if title != "Low Hum" { fail("Low Hum's ⋯ opened \(title)'s menu") }
        #endif
        let mark = app.descendants(matching: .any).matching(NSPredicate(format: "identifier IN {'menu.watch', 'menu.unwatch'}")).firstMatch
        if !mark.exists(within: 10) { return fail("the track's menu has no Played or Unplayed") }
        // A Mac's menu item reports its text as its title.
        let says = mark.label.isEmpty ? mark.title : mark.label
        if !says.contains("Played") && !says.contains("Unplayed") { fail("the track's menu says \(says), not Played") }
        shot("track menu")
    }

    #if os(iOS)
    func testPhoneCastSitsAcrossFromBack() throws {
        openDetail("Maestro Show", settings: ["cast.demo=receiver"])
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("the cast button leaves the row on phones only") }
        let cast = require("detail.castTo", timeout: 30, "the cast button")
        let back = app.navigationBars.buttons.firstMatch
        let play = require("detail.play", "Play")
        if !back.exists { return fail("the page has no Back") }
        if abs(cast.frame.midY - back.frame.midY) > 2 { fail("cast \(cast.frame) and Back \(back.frame) aren't on one line") }
        if cast.frame.minY >= play.frame.minY { fail("the cast button \(cast.frame) is still in the row with Play \(play.frame)") }
        shot("show with cast")
        tap(cast)
        require("cast.picker.thisDevice", timeout: 10, "the cast button opens the device picker")
        shot("cast picker")
    }

    /// Over Maestro Show's bright backdrop (green under Back, pink under the cast button, lime and pink beside the title)
    /// in the dark theme: Back's and the cast button's white symbols stand at least 3:1 from their glass, which takes the
    /// picture's colour under it; the title (large) at least 3:1 and the facts under it at least 4.5:1 from the
    /// brightest of the picture beside them.
    func testBarButtonsAndTitleStandOutOverABrightBackdrop() throws {
        openDetail("Maestro Show", settings: ["theme_mode=dark", "cast.demo=receiver"])
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("the navigation bar crosses the backdrop on phones") }
        let cast = require("detail.castTo", timeout: 30, "the cast button")
        let back = app.navigationBars.buttons.firstMatch
        if !back.exists { return fail("the page has no Back") }
        let title = require("detail.title", "the title")
        let facts = require("detail.facts", "the facts")
        // The backdrop loaded and settled.
        Thread.sleep(forTimeInterval: 3)
        shot("bar and title over bright backdrop")
        for (button, name) in [(back, "Back"), (cast, "cast button")] {
            let frame = button.frame
            guard let ratio = contrast(in: frame.insetBy(dx: frame.width * 0.2, dy: frame.height * 0.2), name) else { return }
            if ratio < 3 { fail(String(format: "\(name)'s symbol has a contrast of %.2f:1 on its glass over the backdrop, under 3:1", ratio)) }
        }
        for (text, name, minimum) in [(title, "title", 3.0), (facts, "facts", 4.5)] {
            guard let ratio = contrastOverPicture(text, name) else { return }
            if ratio < minimum { fail(String(format: "the \(name) has a contrast of %.2f:1 over the backdrop, under %.1f:1", ratio, minimum)) }
        }
    }
    #endif

    func testTitleBarFadesInPastTheTitleWithThePageStill() throws {
        #if os(iOS)
        // iPad's pages are wide: the title stays in the details' column, under no bar.
        guard UIDevice.current.userInterfaceIdiom == .phone else { throw XCTSkip("the bar shows on phones' narrow pages") }
        openDetail("Maestro Movie")
        checkTitleBar("movie", title: "Maestro Movie", heading: "detail.title", still: "detail.play")
        #else
        openDetail("Maestro Movie")
        checkTitleBar("movie", title: "Maestro Movie", heading: "detail.title", still: "detail.play")
        openDetail("Maestro Show")
        checkTitleBar("show", title: "Maestro Show", heading: "detail.title", still: "detail.play")
        // The album and the mix fit a full window: a short one scrolls them far enough for their titles to go 40 points
        // under the toolbar.
        openMusic("album=Sine Album", screen: "music.album")
        resizeWindow(by: -440)
        checkTitleBar("album", title: "Sine Album", heading: "music.header.title", still: "music.play")
        resizeWindow(by: 440)
        openMusic("playlist=Plezy Mix", screen: "music.playlist")
        resizeWindow(by: -440)
        checkTitleBar("playlist", title: "Plezy Mix", heading: "music.header.title", still: "music.play")
        resizeWindow(by: 440)
        #endif
    }

    // MARK: - Steps

    /// Opens a music screen (`--dev-open-music <what>`) and waits for its header and rows.
    private func openMusic(_ what: String, screen: String) {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open-music", what])
        require(screen, timeout: 60, "the \(what) screen")
        require("music.header.title", timeout: 30, "\(what)'s title")
        require("music.track.1", timeout: 30, "\(what)'s tracks")
        Thread.sleep(forTimeInterval: 2)
    }

    /// The page at its top shows no bar; scrolled until its title (`heading`) has gone under the bar, the bar naming
    /// the page (`title`) fades in over 40 points (a frame shot mid-fade) and then shows whole, its title readable on it,
    /// `still` and Back where they were as it does, and the title showing once.
    private func checkTitleBar(_ page: String, title: String, heading: String, still: String) {
        let headline = require(heading, "the \(page)'s title")
        let anchor = require(still, "the \(page)'s \(still)")
        if element("detail.titleBar").exists { fail("the \(page)'s bar shows while its title does") }
        #if os(iOS)
        let back = app.navigationBars.buttons.firstMatch
        #else
        // The toolbar's Back, named by its symbol.
        let back = app.buttons.matching(identifier: "chevron.backward").firstMatch
        #endif
        if !back.exists { return fail("the \(page) has no Back") }
        let backFrame = back.frame
        shot("\(page) top")
        let band = element("detail.titleBar")
        #if os(iOS)
        let bar = app.navigationBars.firstMatch
        let distance = headline.frame.maxY - (bar.exists ? bar.frame.maxY : 0) + 60
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -distance)), withVelocity: .slow, thenHoldForDuration: 0.5)
        let settled = anchor.frame
        // Stability check: the page must not move over this period as the bar shows.
        Thread.sleep(forTimeInterval: 1.5)
        if anchor.frame != settled { fail("the \(page) moved from \(settled) to \(anchor.frame) as the bar showed") }
        #else
        // Small steps over the column holding the title, a frame kept as the title's foot reaches Back's and the first
        // time the bar shows in part. The Mac's element tree carries no value for the bar: how far it shows is read off
        // the frames, whole once the title's foot is 40 points over the bar's (its height less its 1-point rule).
        let window = app.windows.firstMatch
        let column = window.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: headline.frame.minX + 20 - window.frame.minX, dy: window.frame.height * 0.6))
        func shown() -> CGFloat? {
            guard band.exists else { return nil }
            return min(max((band.frame.maxY - 1 - headline.frame.maxY) / 40, 0), 1)
        }
        // Each half of the fade shot once: the material covering the page's title, then the bar's title coming in.
        var fading: Set<Int> = [], atBack = false, idle = 0, last = headline.frame.maxY
        // Until the bar shows whole, or the page stops scrolling.
        while shown() != 1, idle < 5 {
            column.scroll(byDeltaX: 0, deltaY: -8)
            usleep(150_000)
            let foot = headline.frame.maxY
            idle = foot == last ? idle + 1 : 0
            last = foot
            if !atBack, foot <= backFrame.maxY + 8 {
                atBack = true
                shot("\(page) title at back")
            }
            if let part = shown(), part < 1, fading.insert(part < 0.5 ? 0 : 1).inserted {
                shot("\(page) mid-fade \(Int(part * 100)) percent")
            }
        }
        let midFade = !fading.isEmpty
        if !midFade {
            shot("\(page) scrolled")
            fail("the \(page)'s bar never showed part way")
        }
        let settled = anchor.frame
        Thread.sleep(forTimeInterval: 1.5)
        if anchor.frame != settled { fail("the \(page) moved from \(settled) to \(anchor.frame) as the bar showed") }
        #endif
        if !band.exists(within: 5) { return fail("no bar names the \(page) past its title") }
        #if os(iOS)
        XCTAssertEqual(band.value as? String, "1.00", "the \(page)'s bar shows whole past its title")
        #else
        // Never stuck part way, the page's title covered and the page not named: the page scrolls far enough.
        XCTAssertEqual(shown(), 1, "the \(page)'s bar shows whole past its title")
        #endif
        XCTAssertEqual(band.label, title)
        // Once: the page's own title is under the bar, and the bar (the toolbar) shows no other than the bar's own
        // (which iOS lists under the bar).
        if headline.frame.maxY > band.frame.maxY { fail("the \(page)'s title \(headline.frame) shows below the bar \(band.frame)") }
        let own = band.staticTexts.allElementsBoundByIndex.map(\.frame)
        let named = app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", title, title))
            .allElementsBoundByIndex.filter { $0.identifier != heading && $0.frame.intersects(band.frame) && !own.contains($0.frame) }
        if !named.isEmpty { fail("the \(page)'s title shows twice over the bar: \(named.map(\.frame))") }
        if !back.exists { return fail("Back went with the bar") }
        if back.frame != backFrame { fail("Back moved from \(backFrame) to \(back.frame) as the bar showed") }
        if page == "movie" || page == "show" { require("detail.more", "⋯ stays") }
        shot("\(page) past title")
        requireBarTitleReadable(band, back: back, page)
    }

    /// The bar's title reads on the bar, faded in whole: in the title's place (past Back on the Mac; on iPhone mid-bar,
    /// over its foot, clear of Back and the cast button) the pixel standing out most from the bar has a contrast ratio
    /// of at least 4.5 to it (`contrast(in:)`). A title under the band's fade, near black on black, measured 1.1. The
    /// ratio is kept as `<page> bar title contrast`.
    private func requireBarTitleReadable(_ bar: XCUIElement, back: XCUIElement, _ page: String) {
        let frame = bar.frame
        #if os(macOS)
        // The title starts 48 points past the bar's leading edge, after Back; the bar's 1-point rule left out.
        let start = max(frame.minX + 46, back.frame.maxX + 1)
        let place = CGRect(x: start, y: frame.minY, width: min(160, frame.maxX - start), height: frame.height - 1)
        #else
        let place = CGRect(x: frame.midX - 60, y: frame.maxY - 49, width: 120, height: 44)
        #endif
        guard let ratio = contrast(in: place, "\(page) bar title") else { return }
        if ratio < 4.5 { fail(String(format: "the \(page)'s bar title has a contrast of %.2f:1 on the bar, under 4.5:1", ratio)) }
    }

    /// Light text (`text`, in the dark theme) over a picture: the contrast ratio of its colour (the brightest of its
    /// own pixels, its 99.5th percentile) to the brightest of the picture beside it in its band (the window's width at
    /// its height, the text's own frame left out; its 99th percentile, past a stray bright speck), kept as
    /// `<what> contrast`; nil, failed, without a shot or with no picture beside it.
    private func contrastOverPicture(_ text: XCUIElement, _ what: String) -> Double? {
        let frame = text.frame
        let window = app.windows.firstMatch.frame
        guard let own = luminances(in: frame, what)?.sorted(), !own.isEmpty else { return nil }
        let sides = [
            CGRect(x: window.minX, y: frame.minY, width: frame.minX - window.minX, height: frame.height),
            CGRect(x: frame.maxX, y: frame.minY, width: window.maxX - frame.maxX, height: frame.height),
        ].filter { $0.width >= 8 }
        let picture = sides.flatMap { luminances(in: $0, what) ?? [] }.sorted()
        guard !picture.isEmpty else {
            fail("no picture beside the \(what) at \(frame)")
            return nil
        }
        let colour = own[min(Int(Double(own.count) * 0.995), own.count - 1)]
        let ground = picture[min(Int(Double(picture.count) * 0.99), picture.count - 1)]
        let ratio = (colour + 0.05) / (ground + 0.05)
        keep(ratio, ground: ground, what)
        return ratio
    }

    /// Starts on Search, types `title`, opens its result and waits for its detail.
    private func openDetail(_ title: String, settings: [String] = []) {
        launchDev(settings: settings, arguments: ["--dev-server", Self.server, "--dev-open", "search"])
        require("search.screen", timeout: 90, "the Search screen")
        let field = require("search.field", "the search field")
        // Just after a relaunch the field can be in the tree before it has a frame.
        _ = waitUntil(5) { field.frame.minX.isFinite }
        tap(field)
        field.typeText(title)
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == %@", title)).firstMatch
        if !result.exists(within: 30) { return fail("typing \(title) lists no \(title)") }
        tap(result)
        require("detail.title", timeout: 30, "\(title)'s title")
        // The artwork and the scores come over the network.
        Thread.sleep(forTimeInterval: 4)
    }

    /// The system's menu is open: on iOS headed by what it acts on (`menu.title`, which no dialog has), on the Mac its
    /// first entry.
    private func requireMenu(_ what: String) {
        #if os(iOS)
        require("menu.title", timeout: 10, what)
        #else
        if !app.menuItems.matching(NSPredicate(format: "identifier BEGINSWITH 'menu.'")).firstMatch.exists(within: 10) { fail(what) }
        #endif
    }

    /// Closes the open menu and waits for it to go: Escape on the Mac, a tap on the page beside the menu elsewhere. A tap
    /// on the status bar goes to the status bar and leaves the menu open, so the next tap lands on the menu (closing it,
    /// or running the entry under it) instead of the control it aims at.
    private func dismissMenu() {
        #if os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        let open = app.menuItems.matching(NSPredicate(format: "identifier BEGINSWITH 'menu.'")).firstMatch
        #else
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        let open = element("menu.title")
        #endif
        if !open.waitForNonExistence(timeout: 5) { fail("the menu didn't close") }
    }

    /// A tap, on the Mac a click at the element's centre: a row's right-click catcher hides its activation point.
    private func tap(_ element: XCUIElement) {
        #if os(macOS)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        element.tap()
        #endif
    }
}
#endif
