#if !os(tvOS)
import XCTest

/// Downloads on iPhone, iPad and the Mac (Apple TV has none), each step kept as a screenshot of the result bundle:
/// - Libraries' Downloads view of a `--dev` session with nothing downloaded: Manage's empty tree, the content tabs'
///   empty states (picked from the header row's `downloads.tab` menu), the Movies grouping menu and the Active sync
///   rules screen;
/// - Downloads opened as the app starts signed in to a server, whose libraries the same destination holds: it shows
///   and answers its menus;
/// - a movie and a season downloaded from the dev Jellyfin server (`--dev-download`, `PLEZY_JELLYFIN` overriding the
///   server's address; `_` stands for a space in its titles) shown completed in Manage's tree, the show opened down to
///   its episodes, and in the Movies and TV Shows tabs; then the device offline (the session's `offline` switch: the
///   network reported gone and every request of the app failing) with its downloads still there, and back online;
/// - Settings' Downloads section: the Mac's location row and its dialog, no location row on iPhone and iPad.
final class DownloadsTests: PlezyUITestCase {
    /// The dev Jellyfin server: the Mac reaches it on its own loopback (a tunnel), a simulator at its LAN address.
    private var server: String {
        if let address = ProcessInfo.processInfo.environment["PLEZY_JELLYFIN"] { return address }
        #if os(macOS)
        return "http://127.0.0.1:28096"
        #else
        return "http://192.168.0.15:28096"
        #endif
    }

    /// The movie (a 30-s film) and the season (three episodes) the download test takes from the dev server.
    private let movie = "Maestro Movie"
    private let show = "Maestro Show"
    private let season = "Season 1"

    override func setUp() {
        super.setUp()
        // The Mac's "quit unexpectedly" dialog of an app an earlier run left would take the test's clicks.
        addUIInterruptionMonitor(withDescription: "a crash report dialog") { dialog in
            let ignore = dialog.buttons["Ignore"]
            guard ignore.exists else { return false }
            self.press(ignore)
            return true
        }
    }

    /// Waits for the Downloads screen; on the Mac brings its window to the front, which then takes the clicks, and shows
    /// its sidebar where the window came back with it collapsed (the offline line sits at its foot).
    private func opened() {
        require("downloads.screen", timeout: 60, "the Downloads screen")
        #if os(macOS)
        app.activate()
        let show = app.buttons.matching(NSPredicate(format: "label == 'Show Sidebar'")).firstMatch
        if show.exists {
            show.click()
            require("nav.home", timeout: 10, "the sidebar")
        }
        #endif
    }

    func testDownloadsScreen() {
        launchDev(arguments: ["--dev-open", "downloads"])
        opened()
        require("downloads.tree.empty", "Manage's empty tree")
        shot("downloads manage empty")
        #if os(iOS)
        // The header row's glass menus (the tab, its filters) each read as one named button.
        requireSpokenNames(in: element("downloads.screen"), "Downloads")
        #endif

        show("TV Shows")
        require("downloads.empty", "TV Shows' empty state")
        shot("downloads tv shows empty")

        show("Movies")
        require("downloads.empty", "Movies' empty state")
        press(require("downloads.grouping", "the grouping menu"))
        let grouping = option("downloads.grouping")
        if !grouping.exists(within: 5) { fail("the grouping menu's options") }
        // Lets the menu's opening animation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("downloads movies grouping")
        dismissMenu()
        if !grouping.waitForNonExistence(timeout: 5) { fail("the grouping menu stays open") }

        show("Music")
        require("downloads.empty", "Music's empty state")
        shot("downloads music empty")

        press(element("downloads.syncRules"))
        require("syncRules.empty", "the empty sync rules")
        shot("downloads sync rules empty")
    }

    /// Downloads asked for as the app starts signed in to a server: the screen shows and answers its menus, though the
    /// Libraries destination it opens in holds the server's libraries too (the Libraries screen laid out before it
    /// showed kept the main thread laying its header out, and the app never answered again).
    func testOpensOverTheServersLibraries() {
        launchDev(arguments: ["--dev-open", "downloads", "--dev-server", "jellyfin=maestro:maestro@\(server)"])
        opened()
        require("downloads.tree.empty", "Manage's empty tree")
        show("Movies")
        require("downloads.empty", "Movies' empty state")
    }

    /// Settings → Downloads: on the Mac the location row opens its dialog (Select folder, Cancel); iPhone and iPad keep
    /// downloads in the app's container and show no location row, only the section's switches.
    func testLocationSettings() {
        launchDev(arguments: ["--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        let autoRemove = element("settings.row.auto_remove_watched_downloads")
        for _ in 0..<8 where !autoRemove.isHittable {
            #if os(macOS)
            app.windows.firstMatch.scroll(byDeltaX: 0, deltaY: -300)
            #else
            app.swipeUp()
            #endif
        }
        require("settings.row.auto_remove_watched_downloads", "Downloads' Auto-remove watched downloads")
        shot("settings downloads")
        #if os(macOS)
        press(require("settings.row.download_location", "Downloads' location row"))
        require("settings.downloads.location.select", "the location dialog's Select folder")
        shot("settings downloads location dialog")
        let cancel = require("settings.downloads.location.cancel", "the location dialog's Cancel")
        press(cancel)
        if !cancel.waitForNonExistence(timeout: 5) { fail("the location dialog stays after its Cancel") }
        #else
        require("settings.row.download_on_wifi_only", "Downloads' Download on Wi-Fi only")
        if element("settings.row.download_location").exists { fail("iPhone and iPad show a download location row") }
        #endif
    }

    func testDownloadedThenOffline() {
        launchDev(arguments: [
            "--dev-open", "downloads",
            "--dev-server", "jellyfin=maestro:maestro@\(server)",
            "--dev-download", movie.replacingOccurrences(of: " ", with: "_"),
            "--dev-download", "\(show)/\(season)".replacingOccurrences(of: " ", with: "_"),
        ])
        opened()

        let movieRow = row(movie)
        if !movieRow.exists(within: 180) { fail("no Manage row of \(movie) after 180 s") }
        let showRow = row(show)
        if !showRow.exists(within: 180) { fail("no Manage row of \(show) after 180 s") }
        // A completed download offers Delete; one still running offers Pause or Cancel.
        if !waitUntil(300, every: 5, { offers(movieRow, "delete") }) { fail("\(movie) didn't complete within 300 s") }
        if !waitUntil(600, every: 5, { !offers(showRow, "pauseAll") }) { fail("\(show) was still downloading after 600 s") }
        shot("downloads manage completed")
        // A film's row, one line of title, is as tall as a show's, its title over its summary.
        XCTAssertEqual(movieRow.frame.height, showRow.frame.height, accuracy: 1, "\(movie)'s row \(movieRow.frame.size) is as tall as \(show)'s \(showRow.frame.size)")

        press(showRow)
        let seasonRow = row(season)
        if !seasonRow.exists(within: 10) { fail("\(show) opened no \(season) row") }
        press(seasonRow)
        let episodes = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'downloads.row.' AND identifier ENDSWITH '.menu'"))
        if !waitUntil(10, { episodes.count >= 4 }) { fail("\(show)'s season opened no episodes") }
        shot("downloads manage show open")

        show("TV Shows")
        require("downloads.items", "the TV Shows tab's titles")
        // The titles' artwork comes over the network before the screenshot; nothing signals it.
        Thread.sleep(forTimeInterval: 2)
        shot("downloads tv shows")

        show("Movies")
        require("downloads.items", "the Movies tab's titles")
        // The titles' artwork comes over the network before the screenshot; nothing signals it.
        Thread.sleep(forTimeInterval: 2)
        shot("downloads movies")

        // Unwatched set to No (watched movies only): stepped Any → Yes → No, on the Mac picked from its menu; Clear all
        // shows while a filter is on. Mac: the popover stages the edit until it closes; Escape on the Library page steps
        // back to the fields, then closes.
        press(require("downloads.filters", "the Filters capsule"))
        let sheet = require("downloads.filtersSheet", "the filters sheet")
        let unwatched = require("downloads.filters.unwatched", "the filters' Unwatched")
        press(unwatched)
        #if os(macOS)
        let no = app.menuItems["No"]
        if !no.exists(within: 5) { fail("the Unwatched menu has no No") }
        no.click()
        if !waitUntil(5, { (unwatched.value as? String) == "No" }) { fail("the Unwatched menu didn't pick No") }
        #else
        press(unwatched)
        #endif
        let clearAll = require("downloads.filters.clearAll", "the filters' Clear all")
        // Lets the stepped filter and the sheet settle before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("downloads movies filters")
        #if os(macOS)
        press(require("downloads.filters.library", "the filters' Library"))
        require("downloads.filters.all", "the Library page's All")
        Thread.sleep(forTimeInterval: 1)
        shot("downloads movies filters library page")
        app.typeKey(.escape, modifierFlags: [])
        if !unwatched.exists(within: 5) { fail("Escape on the Library page didn't step back to the fields") }
        if !sheet.exists { fail("Escape on the Library page closed the popover") }
        #endif
        closeSheet()
        if !sheet.waitForNonExistence(timeout: 5) { fail("the filters sheet stays after closing") }
        if !waitUntil(5, { element("downloads.filters").label.contains("1") }) { fail("the Unwatched filter didn't apply") }
        shot("downloads movies filtered")
        press(require("downloads.filters", "the Filters capsule"))
        press(require("downloads.filters.clearAll", "the filters' Clear all"))
        #if os(macOS)
        // The popover's Clear all stays, disabled while nothing is set.
        if !waitUntil(5, { !clearAll.isEnabled }) { fail("Clear all stays enabled after clearing the filters") }
        #else
        if !clearAll.waitForNonExistence(timeout: 5) { fail("Clear all stays after clearing the filters") }
        #endif
        closeSheet()
        if !sheet.waitForNonExistence(timeout: 5) { fail("the filters sheet stays after closing") }

        goOffline()
        shot("downloads offline")
        goOnline()
        // The page reloads over the network before the screenshot; nothing signals it.
        Thread.sleep(forTimeInterval: 2)
        shot("downloads online again")
    }

    /// A downloaded movie's detail opened offline shows its downloaded poster, the server out of reach: the band above
    /// its title holds the poster's colour bars, not the grey placeholder.
    func testOfflineDetailShowsDownloadedArtwork() {
        launchDev(arguments: [
            "--dev-open", "downloads",
            "--dev-server", "jellyfin=maestro:maestro@\(server)",
            "--dev-download", movie.replacingOccurrences(of: " ", with: "_"),
        ])
        opened()
        let movieRow = row(movie)
        if !movieRow.exists(within: 180) { fail("no Manage row of \(movie) after 180 s") }
        if !waitUntil(300, every: 5, { offers(movieRow, "delete") }) { fail("\(movie) didn't complete within 300 s") }
        goOffline()
        show("Movies")
        let card = require("downloads.items", "the Movies tab's titles")
            .descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 10) { fail("the Movies tab lists no \(movie)") }
        #if os(macOS)
        // The card's own frame: the right-click catcher over it hides its activation point.
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        card.tap()
        #endif
        let title = require("detail.title", timeout: 30, "\(movie)'s offline detail")
        _ = waitUntil(5) {
            self.colourfulShare(band: CGRect(
                x: self.element("detail.screen").frame.minX, y: title.frame.minY - 150,
                width: self.element("detail.screen").frame.width, height: 110
            )) > 0.04
        }
        shot("offline detail")
        let share = colourfulShare(band: CGRect(
            x: element("detail.screen").frame.minX, y: title.frame.minY - 150,
            width: element("detail.screen").frame.width, height: 110
        ))
        XCTAssertGreaterThan(share, 0.04, "the offline detail draws no downloaded poster above its title")
    }

    /// The share (0–1) of strongly coloured pixels (the poster's colour bars; the page, its placeholder and its text
    /// are greys) in `band`, a rectangle of the app's screen (the Mac: its window) in points.
    private func colourfulShare(band: CGRect) -> Double {
        #if os(macOS)
        let window = app.windows.firstMatch
        let origin = window.frame.origin
        guard let image = window.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return -1 }
        let scale = CGFloat(image.width) / window.frame.width
        #else
        let origin = CGPoint.zero
        guard let image = app.screenshot().image.cgImage else { return -1 }
        let scale = CGFloat(image.width) / app.frame.width
        #endif
        let rect = CGRect(
            x: (band.minX - origin.x) * scale, y: (band.minY - origin.y) * scale, width: band.width * scale, height: band.height * scale
        )
        guard let crop = image.cropping(to: rect) else { return -1 }
        let width = 64, height = 16
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return -1 }
        var colourful = 0
        for pixel in 0..<(width * height) {
            let channels = pixels[(pixel * 4)..<(pixel * 4 + 3)]
            if Int(channels.max()!) - Int(channels.min()!) > 100 { colourful += 1 }
        }
        return Double(colourful) / Double(width * height)
    }

    /// Holds the device offline (`offline=true`) and waits until the app knows its server is gone: the offline chrome's
    /// Reconnect, pressed, ends its attempt.
    private func goOffline() {
        changeDevSetting("offline=true")
        let reconnect = require("offline.reconnect", timeout: 30, "the offline chrome's Reconnect")
        _ = waitUntil(5) { reconnect.isHittable && reconnect.isEnabled }
        press(reconnect)
        let settled = NSPredicate(format: "enabled == true")
        if XCTWaiter.wait(for: [expectation(for: settled, evaluatedWith: reconnect)], timeout: 60) != .completed {
            fail("Reconnect still runs offline after 60 s")
        }
        // Lets the offline chrome finish settling after Reconnect before the screenshot or the next press.
        Thread.sleep(forTimeInterval: 1)
    }

    /// Lets the device back online and waits for the online chrome.
    private func goOnline() {
        changeDevSetting("offline=false")
        if !element("offline.reconnect").waitForNonExistence(timeout: 30) { fail("the offline chrome stays after going online") }
    }

    /// Taps `element` on touch, clicks it on the Mac.
    private func press(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }

    /// The Manage tree's row titled `title`.
    private func row(_ title: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'downloads.row.' AND label CONTAINS %@", title))
            .firstMatch
    }

    /// Shows the Downloads tab `label` from the header row's menu.
    private func show(_ label: String) {
        press(require("downloads.tab", "the Downloads tab menu"))
        let entry = option("downloads.tab", label: label)
        if !entry.exists(within: 5) { fail("\(label) in the Downloads tab menu") }
        LibrarySteps(test: self).pressOption(entry)
    }

    /// The filter menu `id`'s option whose label (a Mac menu item's title) starts with `label`, or any of its options.
    private func option(_ id: String, label: String? = nil) -> XCUIElement {
        LibrarySteps(test: self).option(id, label: label)
    }

    /// Closes an open menu without a pick: a tap below it, over the content (iOS; a tap on the status bar doesn't reach
    /// the menu's dimming), Escape (the Mac).
    private func dismissMenu() {
        #if os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #else
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)).tap()
        #endif
        // The menu's closing animation: a press during it lands on the menu; nothing generic signals its end.
        Thread.sleep(forTimeInterval: 1)
    }

    /// Closes the open sheet: its Close where it shows one, else a swipe down (iPhone); Escape on the Mac.
    private func closeSheet() {
        #if os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #else
        if element("sheet.close").exists {
            press(element("sheet.close"))
        } else {
            element("downloads.filtersSheet").swipeDown(velocity: .fast)
        }
        #endif
    }

    /// Whether the Manage row `row`'s ⋯ menu offers `action` (`delete`, `pauseAll`), the menu closed again.
    private func offers(_ row: XCUIElement, _ action: String) -> Bool {
        press(element("\(row.identifier).menu"))
        let offered = element("\(row.identifier).\(action)").exists(within: 2)
        dismissMenu()
        return offered
    }
}
#endif
