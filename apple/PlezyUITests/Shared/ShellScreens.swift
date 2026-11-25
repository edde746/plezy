import XCTest
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The shell and its destinations in a `--dev` session with the server `PLEZY_DEV_SERVER` names (the default seeded
/// Jellyfin or Emby; without one the destinations show their empty states), in several themes and layouts, each kept
/// as a screenshot of the result bundle: Home (the hero and hub rows; on Apple TV the spotlight under the top tab bar),
/// Libraries (grid and list), the offline shell; iPad's and the Mac's sidebar with Libraries' libraries; Home's
/// actions in the header row, which answer a tap where they are drawn; each screen's header row, its filters and actions
/// on one line, on iPad under the floating tab bar's tabs; a sheet, an item's menu, a question and a text prompt over
/// Home (a Debug build's `-overlaySample`); on the Mac the sidebar in full screen.
final class ShellScreens: PlezyUITestCase {
    /// Starts a dev session on `destination` with the run's server, `settings` and the launch arguments `extra`, and
    /// waits for `screen`.
    private func open(_ destination: String, screen: String, settings: [String], extra: [String] = []) {
        let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        launchDev(settings: settings, arguments: ["--dev-open", destination] + (server.isEmpty ? [] : ["--dev-server", server]) + extra)
        require(screen, timeout: 60, "the \(destination) screen")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 6)
    }

    /// Each sample presentation over Home in `theme`, shot as `<prefix> overlay <kind> <theme>`.
    private func overlays(_ prefix: String, theme: String) {
        let samples = [
            ("sheet", "sample.sheet.row.0"), ("menu", "sample.menu.0"), ("confirm", "sample.confirm.ok"),
            ("toggle", "sample.toggle.on"), ("text", "sample.text.ok"),
        ]
        for (kind, probe) in samples {
            open("home", screen: "home.screen", settings: ["theme_mode=\(theme)"], extra: ["-overlaySample", kind])
            require(probe, timeout: 15, "the sample \(kind)")
            shot("\(prefix) overlay \(kind) \(theme)")
        }
    }

    /// A sign-in shows no offline status while its server is still being connected: from the launch, which signs the
    /// run's server in, until Home has shown for a few seconds, the offline line never shows. Shot as Home appears.
    func testSignInShowsNoOffline() throws {
        let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        if server.isEmpty { throw XCTSkip("needs the run's server (PLEZY_DEV_SERVER)") }
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-open", "home", "--dev-server", server])
        let offline = element("shell.offline")
        let home = element("home.screen")
        let deadline = Date().addingTimeInterval(60)
        var homeAt: Date?
        while Date() < deadline {
            if offline.exists {
                shot("sign in offline")
                return XCTFail("the offline line showed while the sign-in connected")
            }
            if homeAt == nil, home.exists {
                homeAt = Date()
                shot("sign in home")
            }
            if let homeAt, Date().timeIntervalSince(homeAt) > 8 { return }
        }
        XCTFail("no home.screen 60 s after the launch")
    }

    #if os(iOS)
    private var device: String { UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone" }

    /// The iPad turned to landscape, once the app runs; false on iPhone.
    @discardableResult
    private func iPadLandscape() -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        XCUIDevice.shared.orientation = .landscapeLeft
        // Lets the rotation's animation and the new layout finish before the shot.
        Thread.sleep(forTimeInterval: 3)
        return true
    }

    func testHomeDark() {
        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        require("nav.home", "the chrome's Home")
        shot("\(device) home dark")
        if iPadLandscape() { shot("\(device) home dark landscape") }
    }

    func testHomeLight() {
        open("home", screen: "home.screen", settings: ["theme_mode=light"])
        shot("\(device) home light")
        app.swipeUp()
        // Lets the scroll come to rest and the rows' artwork arrive before the shot.
        Thread.sleep(forTimeInterval: 2)
        shot("\(device) home light rows")
    }

    func testHomeLandscapeEmber() {
        open("home", screen: "home.screen", settings: ["theme_mode=ember"])
        XCUIDevice.shared.orientation = .landscapeLeft
        // Lets the rotation's animation and the new layout finish before the shot.
        Thread.sleep(forTimeInterval: 4)
        shot("\(device) home landscape ember")
    }

    func testLibrariesOled() {
        open("libraries", screen: "libraries.screen", settings: ["theme_mode=oled"])
        shot("\(device) libraries grid oled")
        if iPadLandscape() { shot("\(device) libraries grid oled landscape") }
    }

    func testLibrariesListPaper() {
        open("libraries", screen: "libraries.screen", settings: ["theme_mode=paper", "view_mode=list"])
        shot("\(device) libraries list paper")
    }

    /// Offline after the server signed in: a dev session started offline has no stored connection of its server to
    /// keep, and its launch ends.
    func testOffline() {
        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        changeDevSetting("offline=true")
        require("downloads.screen", timeout: 30, "the offline shell's Downloads")
        require("offline.reconnect", "the offline status's Reconnect")
        shot("\(device) offline downloads dark")
    }

    func testSearchAndSettings() {
        open("search", screen: "search.screen", settings: ["theme_mode=forest"])
        shot("\(device) search forest")
        open("settings", screen: "settings.screen", settings: ["theme_mode=forest"])
        shot("\(device) settings forest")
    }

    func testOverlays() {
        overlays(device, theme: "dark")
        overlays(device, theme: "light")
    }

    /// iPad: the floating tab bar opens into the sidebar, which lists Libraries' libraries; one picked shows Libraries.
    func testSidebarLibraries() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPad's sidebar") }
        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        shot("ipad tab bar dark")
        let library = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.'")).firstMatch
        if !library.exists(within: 3) {
            let toggle = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'sidebar'")).firstMatch
            XCTAssertTrue(toggle.exists(within: 5), "the tab bar's sidebar button")
            toggle.tap()
        }
        XCTAssertTrue(library.exists(within: 15), "the sidebar lists a library")
        shot("ipad sidebar libraries dark")
        library.tap()
        require("libraries.screen", timeout: 15, "Libraries from the sidebar's library")
        shot("ipad sidebar library picked dark")
    }

    /// iPad, in landscape and portrait, with the sidebar hidden (its toggle, where landscape shows it) and shown (Always
    /// Keep Sidebar Open): under the floating tab bar each screen's header row starts below the tabs (Libraries,
    /// Downloads, Search, Explore); each screen and Settings shot as `ipad <orientation> <tabs|sidebar> <screen>`. A row
    /// under the tabs is reported and the test goes on.
    func testHeaderRowsClearTheTabBar() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPad's floating tab bar") }
        if (ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? "").isEmpty {
            throw XCTSkip("needs the run's server (PLEZY_DEV_SERVER)")
        }
        let seerr = "\(ProcessInfo.processInfo.environment["PLEZY_SEERR_URL"] ?? "http://192.168.0.15:28099")/run/\(UUID().uuidString)"
        let screens: [(String, String, String?, [String])] = [
            ("libraries", "libraries.screen", "libraries.library", []),
            ("downloads", "downloads.screen", "downloads.tab", []),
            ("search", "search.screen", "search.field", []),
            ("explore", "explore.screen", "explore.search", ["--dev-seerr", "maestro@plezy.test:maestro@\(seerr)"]),
            ("settings", "settings.screen", nil, []),
        ]
        for (orientation, turned) in [(UIDeviceOrientation.landscapeLeft, "landscape"), (.portrait, "portrait")] {
            XCUIDevice.shared.orientation = orientation
            for sidebar in [false, true] {
                for (destination, screen, row, extra) in screens {
                    open(destination, screen: screen, settings: ["theme_mode=dark", "always_keep_sidebar_open=\(sidebar)"], extra: extra)
                    if !sidebar { hideSidebar() }
                    shot("ipad \(turned) \(sidebar ? "sidebar" : "tabs") \(destination)")
                    guard !sidebar, let row else { continue }
                    let top = require(row, timeout: 30, "\(destination)'s header row").frame.minY
                    let tabs = require("nav.home", "the floating tab bar's Home").frame.maxY
                    continueAfterFailure = true
                    XCTAssertGreaterThanOrEqual(top, tabs, "\(turned): \(destination)'s header row under the tabs")
                    continueAfterFailure = false
                }
            }
        }
    }

    /// Hides iPad's sidebar where it shows (landscape starts with it), for the floating tab bar, which holds Home on its
    /// toggle's line.
    private func hideSidebar() {
        let home = require("nav.home", "the chrome's Home")
        let toggle = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'sidebar'")).firstMatch
        XCTAssertTrue(toggle.exists(within: 10), "the sidebar's toggle")
        let onTabBar = { abs(home.frame.midY - toggle.frame.midY) < 3 }
        if onTabBar() { return }
        toggle.tap()
        _ = waitUntil(10, every: 0.5, onTabBar)
        XCTAssertTrue(onTabBar(), "the sidebar hidden by its toggle")
        // Lets the sidebar's closing animation finish before the shot.
        Thread.sleep(forTimeInterval: 1)
    }
    #endif

    #if !os(tvOS)
    /// Home's chips answer a touch or a click where they are drawn: Watch Together's opens its screen.
    func testHomeChipsAnswerTouch() {
        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        let watch = require("home.watchTogether", timeout: 30, "Home's Watch Together chip")
        shot("home header actions dark")
        #if os(macOS)
        watch.click()
        #else
        watch.tap()
        #endif
        XCTAssertTrue(element("watch.screen").exists(within: 15), "Watch Together from its chip")
    }
    #endif

    #if !os(tvOS)
    /// Each screen's header row, shot as `header <screen>`: Libraries' Browse, Downloads, Explore, Search, Live TV, an
    /// artist and Home. Where the controls sit and that none clips or overlaps another is ScreenTopsTests'.
    func testHeaderRows() throws {
        let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        if server.isEmpty { throw XCTSkip("needs the run's server (PLEZY_DEV_SERVER)") }
        open("libraries", screen: "libraries.screen", settings: ["theme_mode=dark"])
        LibrarySteps(test: self).showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse grid")
        requireSortReachable()
        // Lets the ⋯ menu, where the sort was looked for, finish closing before the shot.
        sleep(2)
        shot("header libraries browse")
        require("libraries.library", timeout: 30, "Libraries' library menu")

        open("downloads", screen: "downloads.screen", settings: ["theme_mode=dark"])
        shot("header downloads")
        require("downloads.tab", timeout: 30, "Downloads' view")

        #if os(iOS)
        let seerr = "\(ProcessInfo.processInfo.environment["PLEZY_SEERR_URL"] ?? "http://192.168.0.15:28099")/run/\(UUID().uuidString)"
        open("explore", screen: "explore.screen", settings: ["theme_mode=dark"], extra: ["--dev-seerr", "maestro@plezy.test:maestro@\(seerr)"])
        shot("header explore")
        require("explore.search", timeout: 30, "Explore's field")
        #endif

        open("search", screen: "search.screen", settings: ["theme_mode=dark"])
        shot("header search")

        open("live_tv", screen: "livetv.screen", settings: ["theme_mode=dark"])
        shot("header live tv")

        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", server, "--dev-open-music", "artist=Plezy Test Artist"])
        require("music.artist", timeout: 90, "the artist screen")
        // The artist's artwork comes over the network.
        Thread.sleep(forTimeInterval: 4)
        shot("header artist")

        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        shot("header home")
    }

    /// Browse's sort: in the header row, else on a phone in the ⋯ menu, which the row gives it to after Shuffle where it
    /// would leave the library's name fewer than its first twelve characters (Codec Samples, with its symbol, on a
    /// 402 pt wide iPhone).
    private func requireSortReachable() {
        if element("libraries.sort").exists(within: 10) { return }
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            let more = require("libraries.more", timeout: 10, "the ⋯ menu")
            // iOS 27 can report the ⋯ with the whole header's frame; its glyph keeps the ⋯'s own.
            let glyph = more.images["ellipsis"]
            (glyph.exists ? glyph : more).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(element("libraries.sort").exists(within: 10), "Browse's sort in the ⋯ menu, which the row has no room for")
            LibrarySteps(test: self).dismissMenu()
            return
        }
        #endif
        XCTFail("Browse's sort: no libraries.sort in the header row")
    }
    #endif

    #if os(tvOS)
    func testHomeTabBar() {
        open("home", screen: "home.screen", settings: ["theme_mode=oled"])
        shot("tv home oled")
        XCUIRemote.shared.press(.right)
        // Lets the focus animation finish before the shot.
        Thread.sleep(forTimeInterval: 2)
        shot("tv home oled next card")
        XCUIRemote.shared.press(.menu)
        // Lets the tab bar's animation finish before the shot.
        Thread.sleep(forTimeInterval: 2)
        shot("tv home tab bar oled")
    }

    func testHomeFullCard() {
        open("home", screen: "home.screen", settings: ["theme_mode=dark", "tv_full_card_layout=true"])
        shot("tv home full card dark")
    }

    /// Light: the shortcut chips rest grey and only the focused one turns white.
    func testHomeLight() {
        open("home", screen: "home.screen", settings: ["theme_mode=light"])
        shot("tv home light")
        XCUIRemote.shared.press(.down)
        // Lets the focus animation finish before the shot.
        Thread.sleep(forTimeInterval: 2)
        shot("tv home light chip focused")
    }

    func testLibrariesGrid() {
        open("libraries", screen: "libraries.screen", settings: ["theme_mode=oled"])
        shot("tv libraries grid oled")
    }

    func testSettings() {
        open("settings", screen: "settings.screen", settings: ["theme_mode=plum"])
        shot("tv settings plum")
    }

    func testOverlays() {
        overlays("tv", theme: "oled")
    }
    #endif

    #if os(macOS)
    func testHomeDark() {
        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        shot("mac home dark")
    }

    func testLibrariesPaper() {
        open("libraries", screen: "libraries.screen", settings: ["theme_mode=paper"])
        shot("mac libraries paper")
    }

    func testHomeLight() {
        open("home", screen: "home.screen", settings: ["theme_mode=light"])
        shot("mac home light")
    }

    /// Home scrolled down holds its place: no timer of Home's scrolls it back to the top.
    func testHomeHoldsItsScroll() {
        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        element("home.screen").scroll(byDeltaX: 0, deltaY: -600)
        Thread.sleep(forTimeInterval: 2)
        shot("mac home scrolled")
        let top = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'hub.'")).firstMatch.frame.minY
        Thread.sleep(forTimeInterval: 10)
        shot("mac home scrolled after 10 s")
        let later = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'hub.'")).firstMatch.frame.minY
        XCTAssertEqual(later, top, accuracy: 2, "Home stays where it was scrolled to")
    }

    /// The sidebar lists the destinations and Libraries' libraries; one picked shows Libraries.
    func testSidebarLibraries() {
        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        shot("mac sidebar dark")
        let library = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.'")).firstMatch
        XCTAssertTrue(library.exists(within: 15), "the sidebar lists a library")
        library.click()
        require("libraries.screen", timeout: 15, "Libraries from the sidebar's library")
        shot("mac sidebar library picked dark")
    }

    /// A launch on Live TV loads Libraries' libraries too: the sidebar lists them and one picked shows its items.
    func testLiveTvLaunchLoadsLibraries() {
        open("live_tv", screen: "livetv.screen", settings: ["theme_mode=dark"])
        let library = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.'")).firstMatch
        let listed = library.exists(within: 30)
        shot("mac live tv launch sidebar")
        XCTAssertTrue(listed, "the sidebar lists a library after a Live TV launch")
        guard listed else { return }
        library.click()
        require("libraries.screen", timeout: 15, "Libraries from the sidebar's library")
        let item = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        let loaded = item.exists(within: 30)
        shot("mac live tv launch library picked")
        XCTAssertTrue(loaded, "the library picked after a Live TV launch shows its items")
    }

    /// Force TV mode lays Home out as a TV's (larger cards): at the launch, and at once when Settings › General's switch
    /// turns it on while the app runs, as it does at the launch.
    func testForceTv() {
        open("home", screen: "home.screen", settings: ["theme_mode=oled", "force_tv_mode=true"])
        shot("mac home force tv oled")
        let tv = firstCardWidth()

        open("home", screen: "home.screen", settings: ["theme_mode=oled"])
        let regular = firstCardWidth()
        XCTAssertGreaterThan(tv, regular + 10, "a Force TV launch's cards are larger")
        require("nav.settings", "the sidebar's Settings").click()
        require("settings.row.general", timeout: 20, "Settings → General").click()
        let force = require("settings.row.force_tv_mode", timeout: 20, "Force TV mode")
        force.click()
        let on = { (force.value as? String) == "1" || (force.value as? NSNumber)?.intValue == 1 }
        if !waitUntil(10, on) { fail("Force TV mode's switch stays off") }
        require("nav.home", "the sidebar's Home").click()
        require("home.screen", timeout: 20, "Home again")
        Thread.sleep(forTimeInterval: 3)
        shot("mac home force tv switched on live oled")
        XCTAssertEqual(firstCardWidth(), tv, accuracy: 1, "switched on while running, Home lays out as at a Force TV launch")
    }

    /// The width of Home's first card (Continue Watching's).
    private func firstCardWidth() -> CGFloat {
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND NOT identifier ENDSWITH '.menu'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 30), "Home's first card")
        return card.frame.width
    }

    func testOverlays() {
        overlays("mac", theme: "dark")
        overlays("mac", theme: "paper")
    }

    /// The sidebar in full screen. The window's green button enters full screen; the app quits in it at the test's end.
    func testSidebarFullScreen() {
        open("home", screen: "home.screen", settings: ["theme_mode=dark"])
        let window = app.windows.firstMatch
        let fullScreen = window.buttons[XCUIIdentifierFullScreenWindow]
        XCTAssertTrue(fullScreen.waitForExistence(timeout: 5), "the window's full screen button")
        fullScreen.click()
        Thread.sleep(forTimeInterval: 4)
        XCTAssertEqual(window.frame.size, NSScreen.screens[0].frame.size, "the window in full screen")
        shot("mac sidebar full screen dark")
    }
    #endif
}
