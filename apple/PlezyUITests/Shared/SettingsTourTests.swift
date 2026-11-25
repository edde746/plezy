import XCTest
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Settings in a `--dev` session signed into the test Jellyfin server (`--dev-server`, `PLEZY_DEV_SERVER` or the
/// default): the hub and every page it opens, each kept as a screenshot of the result bundle, with the dialogs a row
/// opens; Theme → Light repainting the app's background; Library Density changing the Libraries grid's cards. On
/// Apple TV everything goes through the remote, and focus comes back to the hub row that opened a page.
final class SettingsTourTests: PlezyUITestCase {
    /// The test server: the Mac reaches it through a loopback tunnel, the simulators over the network.
    private var server: String {
        if let given = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"], !given.isEmpty { return given }
        #if os(macOS)
        return "jellyfin=maestro:maestro@http://127.0.0.1:28096"
        #else
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
        #endif
    }

    private var platform: String {
        #if os(macOS)
        "mac"
        #elseif os(tvOS)
        "tv"
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        #endif
    }

    override func setUp() {
        super.setUp()
        // A tour of many pages, each found by scrolling, takes longer than the default five minutes.
        executionTimeAllowance = 600
    }

    /// Starts a session on `destination` in `theme` and waits for `screen`.
    private func open(_ destination: String, screen: String, theme: String = "dark") {
        launchDev(settings: ["theme_mode=\(theme)"], arguments: ["--dev-open", destination, "--dev-server", server])
        require(screen, timeout: 90, "the \(destination) screen")
        // The first frames fade in: the shots and pixel reads that follow have no element to wait on.
        Thread.sleep(forTimeInterval: 2)
    }

    // MARK: The tour

    func testTour() {
        open("settings", screen: "settings.screen")
        require("settings.row.general", "the hub's General row")
        profileFirst()
        shot("\(platform) settings hub")
        #if os(tvOS)
        tourTv()
        #else
        supporterIfShown()
        scrollDown()
        shot("\(platform) settings hub scrolled")
        scrollDown()
        scrollDown()
        shot("\(platform) settings hub bottom")
        backToHub()

        visit("settings.row.general", page: "settings.page.general", shot: "general") {
            self.scrollDown()
            self.shot("\(self.platform) settings general scrolled")
        }
        visit("settings.row.appearance", page: "settings.page.appearance", shot: "appearance") {
            self.scrollDown()
            self.shot("\(self.platform) settings appearance scrolled")
            self.open(row: "settings.row.theme", page: "settings.page.theme", shot: "theme picker", back: false)
            if self.reveal("settings.theme.custom").exists {
                // Custom opens the editor, a sheet over the picker: Cancel (nothing changed) closes it.
                self.press(self.element("settings.theme.custom"))
                self.require("settings.page.custom_theme", "the custom theme editor")
                // The sheet's presentation ends with nothing to wait on before the shot.
                Thread.sleep(forTimeInterval: 1.5)
                self.shot("\(self.platform) settings custom theme")
                #if os(iOS)
                // A colour well is drawn 28 pt and takes taps in the 44 pt square around it: a tap 7.5 pt outside the
                // drawing (half a point inside the square, clear of its edge) opens the colour picker over the editor.
                // The picker runs out of process, and its first opening waits for that process (about 3 s on an idle
                // Mac, longer on a loaded one, against under 1 s after); the very first on a freshly erased simulator
                // can open nothing at all, where a second tap opens it in 3 s. Taps on the drawing open it first
                // (up to three), so the edge's tap is timed as any later tap is.
                let well = self.require("settings.custom.slot.0.color", "the first colour's well")
                let cancel = self.element("settings.custom.cancel")
                let origin = well.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                @MainActor func opens(_ tap: XCUICoordinate, within timeout: TimeInterval) -> Bool {
                    tap.tap()
                    let covered = NSPredicate(format: "hittable == false")
                    return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: covered, object: cancel)], timeout: timeout) == .completed
                }
                // The picker's X isn't in the tree: a tap outside it closes it, above the iPhone's half-height sheet,
                // beside the iPad's popover (never on the picker's colours).
                @MainActor func closes() -> Bool {
                    let uncovered = NSPredicate(format: "hittable == true")
                    for outside in [CGVector(dx: 0.5, dy: 0.12), CGVector(dx: 0.02, dy: 0.5)] {
                        self.app.coordinate(withNormalizedOffset: outside).tap()
                        if XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: uncovered, object: cancel)], timeout: 4) == .completed {
                            return true
                        }
                    }
                    return false
                }
                var warmed = false
                for _ in 0..<3 where !warmed { warmed = opens(origin, within: 15) }
                XCTAssertTrue(warmed, "three taps on the well's drawing opened no colour picker")
                XCTAssertTrue(closes(), "the colour picker stayed over the editor")
                let opened = opens(origin.withOffset(CGVector(dx: -(14 + 7.5), dy: 0)), within: 10)
                XCTAssertTrue(opened, "a tap 7.5 pt outside the well's drawing (well \(well.frame)) opened no colour picker")
                self.shot("\(self.platform) settings colour picker from the well's edge")
                if opened { XCTAssertTrue(closes(), "the colour picker stayed over the editor") }
                #endif
                self.press(self.require("settings.custom.cancel", "the editor's Cancel"))
                self.requireGone("settings.page.custom_theme", "Cancel closes the editor")
            }
            self.backOne(to: "settings.page.appearance")
            // Home Screen's choices: Continue Watching Action and Episode Action, each a menu.
            if self.reveal("settings.row.episode_action").exists {
                #if os(iOS)
                // The whole row opens the menu: at least 44 pt tall and as wide as the row, its title included.
                let choice = self.element("settings.row.episode_action")
                XCTAssertGreaterThanOrEqual(choice.frame.height, 44, "Episode Action's tap target is \(choice.frame.height) pt tall")
                XCTAssertTrue(choice.label.contains("Episode Action"), "Episode Action's tap target is \(choice.label), not the row")
                XCTAssertGreaterThan(choice.frame.width, self.app.frame.width / 2, "Episode Action's tap target is the picker alone")
                #endif
                self.shot("\(self.platform) settings appearance home screen")
            }
        }
        visit("settings.row.services", page: "services.screen", shot: "services") {
            // Seerr follows the trackers, with its mark and its connection like theirs.
            self.require("settings.seerr", "Services lists Seerr")
        }
        visit("settings.row.account_preferences", page: "settings.page.account_preferences", shot: "account preferences")
        #if os(macOS)
        visit("settings.row.video_player_controls", page: "settings.page.keyboard_shortcuts", shot: "keyboard shortcuts") {
            let row = self.app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'settings.keys.row.'")).firstMatch
            if row.exists {
                row.click()
                self.require("settings.keys.capture", "the shortcut recorder")
                self.shot("mac settings shortcut recorder")
                self.element("settings.keys.cancel").click()
            }
        }
        // The download location's dialog, the Mac's alone: the folder now, Select folder, Cancel.
        let location = reveal("settings.row.download_location")
        XCTAssertTrue(location.exists, "the hub's Download location row")
        if location.exists {
            press(location)
            require("settings.downloads.location.cancel", "the download location dialog")
            shot("mac settings download location")
            press(element("settings.downloads.location.cancel"))
            Thread.sleep(forTimeInterval: 1)
        }
        #endif
        visit("settings.row.view_logs", page: "settings.page.logs", shot: "logs")
        visit("settings.row.about", page: "settings.page.about", shot: "about") {
            self.open(row: "settings.row.licenses", page: "settings.page.licenses", shot: "licenses", back: false)
            self.open(row: "settings.licenses.0", page: "settings.page.license", shot: "license detail")
        }
        // A question: Clear Image Cache asks first.
        let clear = reveal("settings.row.clear_image_cache")
        press(clear)
        require("settings.confirm.cancel", "the Clear Image Cache question")
        shot("\(platform) settings confirm")
        press(element("settings.confirm.cancel"))
        #endif
    }

    /// The app started again on Settings with its profile kept (`--dev-data`), as a launch restores it: the profile card
    /// and the rows on screen keep their frames from the first frame the hub draws rows to the loaded page (no stand-in
    /// profile card, no rows arriving above them), Manage Libraries among them from the start.
    func testHubRowsKeepTheirPlacesWhileTheSessionLoads() throws {
        let data = ["--dev-data", "hubrows\(Int(Date().timeIntervalSince1970))"]
        launchDev(settings: ["theme_mode=dark"], arguments: data + ["--dev-open", "settings", "--dev-server", server])
        require("settings.row.general", timeout: 90, "the first launch's hub")
        // Its sign-in made the profile and stored its connection.
        sleep(8)
        app.terminate()
        launchDev(settings: ["theme_mode=dark"], arguments: data + ["--dev-open", "settings", "--dev-server", server])
        require("settings.screen", timeout: 90, "the settings screen")
        let ids: Set<String> = ["settings.profile.switch", "settings.row.general", "settings.row.manage_libraries", "settings.row.services",
                                "settings.row.add_connection", "settings.row.profiles", "settings.row.account_preferences", "settings.row.logout"]
        // One snapshot of the tree at a time, taken as fast as they come: the first with the hub's rows is its first frame.
        var first: [String: (frame: CGRect, label: String)] = [:]
        let deadline = Date().addingTimeInterval(60)
        while first["settings.row.general"] == nil, Date() < deadline {
            first = try Self.find(ids, in: app.snapshot())
        }
        let profile = try XCTUnwrap(first["settings.profile.switch"], "the profile card shows with the rows")
        XCTAssertFalse(profile.label.hasPrefix("Profiles"), "the profile card's first frame is a stand-in: \(profile.label)")
        XCTAssertNotNil(first["settings.row.manage_libraries"], "Manage Libraries shows with the first rows")
        shot("\(platform) settings hub first rows")
        // The rows are watched over the session's load: none may move.
        Thread.sleep(forTimeInterval: 10)
        let loaded = try Self.find(ids, in: app.snapshot())
        shot("\(platform) settings hub loaded")
        // Each row against the profile card at the page's top: the rows keep their places within the page (a notice line
        // over the whole screen, the shell's, moves the page itself: the iPhone's token-less relaunch shifts it once).
        let top = try XCTUnwrap(loaded["settings.profile.switch"], "the profile card once loaded").frame.minY
        func placed(_ frame: CGRect, from origin: CGFloat) -> CGRect { frame.offsetBy(dx: 0, dy: -origin) }
        let moved = first.keys.filter { id in
            loaded[id].map { placed($0.frame, from: top) } != placed(first[id]!.frame, from: profile.frame.minY)
        }.sorted()
        XCTAssertTrue(moved.isEmpty, "moved within the page as the session loaded: \(moved.map { "\($0) \(first[$0]!.frame) → \(loaded[$0]?.frame ?? .null)" }); first frame had \(first.keys.sorted())")
    }

    /// The frames and labels of the elements of `snapshot` named by `ids`.
    private static func find(_ ids: Set<String>, in snapshot: any XCUIElementSnapshot) -> [String: (frame: CGRect, label: String)] {
        var found: [String: (frame: CGRect, label: String)] = [:]
        var stack = [snapshot]
        while let next = stack.popLast() {
            if ids.contains(next.identifier), found[next.identifier] == nil { found[next.identifier] = (next.frame, next.label) }
            stack.append(contentsOf: next.children)
        }
        return found
    }

    /// The hub's top tile in the build's own Supporter mode (`--dev-supporter build`): the
    /// App Store's iPhone, iPad and Apple TV builds (the test build's flavor; Apple TV in every build) sell the perks,
    /// so the Supporter tile leads the hub; the Mac's DMG gives them free and links to donations instead.
    func testSupporterTileFollowsTheBuild() {
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-open", "settings", "--dev-server", server, "--dev-supporter", "build"])
        require("settings.screen", timeout: 90, "the settings screen")
        let general = require("settings.row.general", "the hub's General row")
        // The hidden tile must not turn up while the hub settles.
        Thread.sleep(forTimeInterval: 2)
        #if os(macOS)
        let shown = "settings.donate", hidden = "settings.supporter"
        #else
        let shown = "settings.supporter", hidden = "settings.donate"
        #endif
        let tile = require(shown, "the hub's \(shown) tile")
        XCTAssertFalse(element(hidden).exists, "the hub has no \(hidden) tile")
        XCTAssertLessThan(tile.frame.minY, general.frame.minY, "\(shown) comes before General")
        shot("\(platform) settings hub build supporter")
    }

    /// In a build that sells it (`--dev-supporter iap`), the hub's top tile names the purchase, the Theme & Icon Pack,
    /// and opens its sheet.
    func testSupporterTileOpensTheThemeAndIconPack() {
        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-open", "settings", "--dev-server", server, "--dev-supporter", "iap"])
        require("settings.screen", timeout: 90, "the settings screen")
        let tile = require("settings.supporter", "the hub's Supporter tile")
        _ = waitUntil(5) { tile.label.contains("Theme & Icon Pack") }
        XCTAssertTrue(tile.label.contains("Theme & Icon Pack"), "the tile names the pack: \(tile.label)")
        shot("\(platform) settings theme and icon pack tile")
        #if os(tvOS)
        XCTAssertTrue(focus("settings.supporter"), "focus on the Supporter tile")
        XCUIRemote.shared.press(.select)
        #else
        press(tile)
        #endif
        require("supporter.sheet", "the Theme & Icon Pack sheet")
        // The sheet's presentation ends with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1.5)
        shot("\(platform) theme and icon pack sheet")
    }

    #if !os(tvOS)
    /// Video Playback and what it opens: a number, a text and a colour dialog, Subtitle Styling, mpv.conf and (where
    /// videos can go to another app) External Player.
    func testPlaybackPages() {
        open("settings", screen: "settings.screen")
        visit("settings.row.playback", page: "settings.page.video_playback", shot: "video playback") {
            self.scrollDown()
            self.shot("\(self.platform) settings video playback scrolled")
            if self.reveal("settings.row.audio_passthrough").exists {
                self.shot("\(self.platform) settings audio passthrough")
            }
            self.dialog("settings.row.seek_time_small", probe: "settings.number.cancel", shot: "number dialog")
            self.dialog("settings.row.intro_pattern", probe: "settings.text.cancel", shot: "text dialog")
            self.open(row: "settings.row.subtitle_styling", page: "settings.page.subtitle_styling", shot: "subtitle styling", back: false)
            self.dialogIfShown("settings.row.subtitle_text_color", probe: "settings.color.cancel", shot: "color dialog")
            self.backOne(to: "settings.page.video_playback")
            self.open(row: "settings.row.mpv_config", page: "settings.page.mpv_config", shot: "mpv config")
            if self.reveal("settings.row.external_player").exists {
                self.open(row: "settings.row.external_player", page: "settings.page.external_player", shot: "external player")
            }
        }
    }
    #endif

    #if os(iOS)
    /// Play Next Countdown set to 0 in its dialog reads "Play immediately": in the languages where that runs longest, at
    /// a large text size, its row on Video Playback shows it whole and stays inside the screen.
    func testCountdownAtZeroShowsWholeInLongLanguages() {
        let immediate = [
            "da": "Afspil med det samme", "en": "Play immediately", "es": "Reproducir de inmediato", "pl": "Odtwarzaj natychmiast",
            "pt": "Reproduzir imediatamente", "ru": "Воспроизводить сразу",
        ]
        for (language, value) in immediate.sorted(by: { $0.key < $1.key }) {
            launchDev(settings: ["theme_mode=dark"], languages: [language], arguments: [
                "--dev-open", "settings", "--dev-server", server, "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL",
            ])
            require("settings.screen", timeout: 90, "the settings screen in \(language)")
            let playback = reveal("settings.row.playback")
            guard playback.exists else { return fail("no Video Playback row in \(language)") }
            press(playback)
            require("settings.page.video_playback", "the Video Playback page in \(language)")
            let row = reveal("settings.row.play_next_countdown")
            guard row.exists else { return fail("no Play Next Countdown row in \(language)") }
            press(row)
            require("settings.number.field", "the countdown's dialog in \(language)")
            // The dialog slides in: keys typed before it settles are lost.
            Thread.sleep(forTimeInterval: 1.5)
            app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4) + "0")
            // On iPad the number pad takes the first tap outside it to go away, as a popover does, and a Save tapped
            // then only closes the pad: the dialog's hint takes that tap.
            press(require("settings.number.hint", "the dialog's hint in \(language)"))
            press(require("settings.number.save", "the dialog's Save in \(language)"))
            requireGone("settings.number.field", "Save closes the countdown's dialog in \(language)")
            _ = waitUntil(5) { row.label.contains(value) }
            XCTAssertTrue(row.label.contains(value), "in \(language) the row reads \(row.label), not \(value)")
            let window = app.windows.firstMatch.frame
            XCTAssertTrue(row.frame.minX >= window.minX && row.frame.maxX <= window.maxX, "in \(language) the row \(row.frame) runs off the screen \(window)")
            shot("\(platform) countdown at zero \(language)")
        }
    }
    #endif

    #if !os(tvOS)
    /// The hub's Manage Libraries opens its page: every library with its switch.
    func testManageLibrariesPage() {
        open("settings", screen: "settings.screen")
        open(row: "settings.row.manage_libraries", page: "settings.page.manage_libraries", shot: "manage libraries", back: false)
        XCTAssertTrue(element("settings.libraries.row.0").exists(within: 20), "the libraries with their switches")
        // The switches finish drawing with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(platform) settings manage libraries")
    }
    #endif

    #if !os(tvOS)
    /// Every page with values, shot a screen at a time from its top to its foot: where each row's value sits beside
    /// its title and where it goes under it.
    func testEveryPageScrolledThrough() {
        executionTimeAllowance = 900
        open("settings", screen: "settings.screen")
        require("settings.row.general", "the hub's General row")
        scrollThrough("hub")
        backToHub()
        for (row, page, name) in [
            ("settings.row.general", "settings.page.general", "general"),
            ("settings.row.appearance", "settings.page.appearance", "appearance"),
            ("settings.row.account_preferences", "settings.page.account_preferences", "account preferences"),
            ("settings.row.about", "settings.page.about", "about"),
        ] {
            visit(row, page: page, shot: name) { self.scrollThrough(name) }
        }
        visit("settings.row.playback", page: "settings.page.video_playback", shot: "video playback") {
            self.scrollThrough("video playback")
            self.open(row: "settings.row.subtitle_styling", page: "settings.page.subtitle_styling", shot: "subtitle styling", back: false)
            self.scrollThrough("subtitle styling")
            self.backOne(to: "settings.page.video_playback")
            if self.reveal("settings.row.external_player").exists {
                self.open(row: "settings.row.external_player", page: "settings.page.external_player", shot: "external player", back: false)
                self.scrollThrough("external player")
            }
        }
        #if os(macOS)
        visit("settings.row.video_player_controls", page: "settings.page.keyboard_shortcuts", shot: "keyboard shortcuts") {
            self.scrollThrough("keyboard shortcuts")
        }
        #endif
    }

    /// Shoots the page on screen a screen at a time, from where it is to its foot: until a scroll no longer moves it.
    private func scrollThrough(_ name: String) {
        var last: [UInt8] = []
        for part in 1...25 {
            let content = pageContent()
            guard !content.isEmpty else { return fail("the \(name) page's screenshot unreadable") }
            if content == last { return }
            shot("\(platform) settings \(name) part \(part)")
            last = content
            scrollDown()
        }
    }

    /// The window's pixels below the status bar and left of the scroll indicator (which shows as the page moves and
    /// fades after), drawn at a quarter of their size: what changes only when the page moves.
    private func pageContent() -> [UInt8] {
        #if os(macOS)
        let image = app.windows.firstMatch.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        let image = app.windows.firstMatch.screenshot().image.cgImage
        #endif
        guard let image, let crop = image.cropping(to: CGRect(
            x: 0, y: image.height / 10, width: image.width * 9 / 10, height: image.height * 8 / 10
        )) else { return [] }
        let width = crop.width / 4, height = crop.height / 4
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? pixels : []
    }
    #endif

    #if !os(tvOS)
    /// The number and pattern dialogs open with their field focused (typed into without a tap) and say
    /// what is wrong while typing, before Save: a number out of bounds, a pattern that isn't one.
    func testDialogsSayWhatIsWrongWhileTyping() {
        open("settings", screen: "settings.screen")
        press(reveal("settings.row.playback"))
        require("settings.page.video_playback", "Video Playback")
        press(reveal("settings.row.seek_time_small"))
        require("settings.number.field", "the number dialog's field")
        // No error may show while the dialog settles, and keys typed as it slides in are lost.
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertFalse(element("settings.number.error").exists, "an error as the dialog opens")
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4) + "999")
        require("settings.number.error", timeout: 5, "the number's error while typing")
        shot("\(platform) settings number error while typing")
        cancelDialog(element("settings.number.cancel"))
        _ = waitUntil(5) { element("settings.row.intro_pattern").isHittable }

        press(reveal("settings.row.intro_pattern"))
        require("settings.text.field", "the pattern dialog's field")
        // No error may show while the dialog settles, and keys typed as it slides in are lost.
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertFalse(element("settings.text.error").exists, "an error as the dialog opens")
        app.typeText("(")
        require("settings.text.error", timeout: 5, "the pattern's error while typing")
        shot("\(platform) settings pattern error while typing")
        cancelDialog(element("settings.text.cancel"))
    }
    #endif

    // MARK: Theme → Light

    /// Light picked in the theme picker repaints the app: the background's luminance goes from Dark's to Light's.
    func testThemeLightRepaints() {
        open("settings", screen: "settings.screen", theme: "dark")
        let before = backgroundLuminance()
        XCTAssertLessThan(before, 0.3, "Dark paints a dark background")
        #if os(tvOS)
        XCTAssertTrue(focus("settings.row.appearance"), "Appearance focused")
        XCUIRemote.shared.press(.select)
        require("settings.page.appearance", "Appearance")
        XCTAssertTrue(focus("settings.row.theme"), "Theme focused")
        XCUIRemote.shared.press(.select)
        require("settings.page.theme", "the theme picker")
        _ = waitUntil(5) { focused("settings.theme.dark") }
        XCTAssertTrue(focused("settings.theme.dark"), "the picker opens on Dark, the theme in use")
        XCTAssertTrue(focus("settings.theme.light"), "Light focused")
        XCUIRemote.shared.press(.select)
        #else
        press(reveal("settings.row.appearance"))
        require("settings.page.appearance", "Appearance")
        press(reveal("settings.row.theme"))
        require("settings.page.theme", "the theme picker")
        press(reveal("settings.theme.light"))
        #endif
        _ = waitUntil(5) { element("settings.theme.light").isSelected }
        XCTAssertTrue(element("settings.theme.light").isSelected, "Light is the theme checked")
        shot("\(platform) settings theme light")
        #if os(tvOS)
        // Reached from below (down the list, then up), the focused row shows under the title, not behind it.
        let light = element("settings.theme.light").frame, bar = app.navigationBars.firstMatch.frame
        XCTAssertGreaterThanOrEqual(light.minY, bar.maxY, "focused Light \(light) below the title's bar \(bar)")
        #endif
        _ = waitUntil(5) { backgroundLuminance() > 0.7 }
        let after = backgroundLuminance()
        XCTAssertGreaterThan(after, 0.7, "Light paints a light background (luminance \(before) before)")
    }

    /// OLED paints black screens and Dark a near-black one: the two themes the picker offers look different.
    func testOledPaintsBlackerThanDark() {
        open("settings", screen: "settings.screen", theme: "dark")
        let dark = backgroundLuminance()
        shot("\(platform) settings dark")
        open("settings", screen: "settings.screen", theme: "oled")
        let oled = backgroundLuminance()
        shot("\(platform) settings oled")
        XCTAssertLessThan(oled, 0.01, "OLED paints black")
        XCTAssertGreaterThan(dark, oled + 0.03, "Dark paints lighter than OLED (luminance \(dark) vs \(oled))")
    }

    // MARK: Library Density

    /// Library Density moved to its other end changes the size of the Libraries grid's cards (the library's Browse view;
    /// Recommended is shelves, which keep their size).
    func testLibraryDensityChangesGrid() {
        open("libraries", screen: "libraries.screen")
        // Browse from the header row's view menu (on Apple TV through the remote).
        LibrarySteps(test: self).showLibraryTab("browse")
        require("libraries.grid", timeout: 30, "the Browse grid")
        let card = firstCard()
        XCTAssertTrue(card.exists(within: 30), "a card in the Libraries grid")
        let id = card.identifier
        let before = card.frame.width
        shot("\(platform) libraries density before")
        #if os(macOS)
        // Online the Mac's sidebar lists the libraries themselves, with no Libraries row: back by the shown one's row,
        // the button drawn selected (the list has no selection of its own).
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.' AND selected == true")).firstMatch
        XCTAssertTrue(row.exists(within: 10), "the shown library's row selected in the sidebar")
        let libraryRow = row.identifier
        #endif
        goTo("settings", screen: "settings.screen")
        #if os(tvOS)
        XCTAssertTrue(focus("settings.row.appearance"), "Appearance focused")
        XCUIRemote.shared.press(.select)
        require("settings.page.appearance", "Appearance")
        XCTAssertTrue(focus("settings.row.library_density"), "Library Density focused")
        let value = element("settings.row.library_density").value as? String
        // Presses paced so the focus engine takes each one.
        for _ in 0..<4 { XCUIRemote.shared.press(.left); Thread.sleep(forTimeInterval: 0.4) }
        _ = waitUntil(2) { element("settings.row.library_density").value as? String != value }
        if element("settings.row.library_density").value as? String == value {
            // Presses paced so the focus engine takes each one.
            for _ in 0..<4 { XCUIRemote.shared.press(.right); Thread.sleep(forTimeInterval: 0.4) }
        }
        #else
        press(reveal("settings.row.appearance"))
        require("settings.page.appearance", "Appearance")
        let slider = reveal("settings.row.library_density")
        XCTAssertTrue(slider.exists, "the Library Density slider")
        let value = slider.value as? String
        slider.adjust(toNormalizedSliderPosition: 0)
        _ = waitUntil(2) { slider.value as? String != value }
        if slider.value as? String == value { slider.adjust(toNormalizedSliderPosition: 1) }
        #endif
        _ = waitUntil(5) { element("settings.row.library_density").value as? String != value }
        shot("\(platform) settings density changed")
        #if os(macOS)
        pressNav(require(libraryRow, "the sidebar's \(libraryRow)"))
        require("libraries.grid", timeout: 30, "the library's grid")
        #else
        goTo("libraries", screen: "libraries.grid")
        #endif
        _ = waitUntil(10) { abs(element(id).frame.width - before) > 1 }
        let after = element(id)
        XCTAssertTrue(after.exists(within: 20), "the same card after the change")
        shot("\(platform) libraries density after")
        XCTAssertNotEqual(after.frame.width, before, accuracy: 1, "the card's width changed with Library Density")
    }

    // MARK: Always Keep Sidebar Open

    #if !os(tvOS)
    /// With Always Keep Sidebar Open, iPad's and the Mac's sidebar shows from the start (iPad's otherwise starts
    /// as the floating tab bar) and stays beside the screen, which still takes presses: iPad's toggle (in landscape,
    /// where the sidebar sits beside the screen rather than over it) shows it again at once, the Mac's has no toggle and
    /// its View menu's Hide Sidebar (⌃⌘S) leaves it.
    func testAlwaysKeepSidebarOpen() throws {
        #if os(iOS)
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPhone has no sidebar") }
        XCUIDevice.shared.orientation = .landscapeLeft
        #endif
        launchDev(settings: ["theme_mode=dark", "always_keep_sidebar_open=true"], arguments: ["--dev-open", "home", "--dev-server", server])
        require("home.screen", timeout: 90, "Home")
        let library = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'nav.library.'")).firstMatch
        XCTAssertTrue(hittable(library, within: 20), "the sidebar shows from the start")
        // The sidebar's appearance ends with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(platform) sidebar kept open")
        #if os(iOS)
        let toggle = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'sidebar'")).firstMatch
        XCTAssertTrue(toggle.exists(within: 5), "the sidebar's toggle")
        toggle.tap()
        #else
        let toggle = app.toolbars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'sidebar'")).firstMatch
        XCTAssertFalse(toggle.exists, "the toolbar has no sidebar toggle")
        app.typeKey("s", modifierFlags: [.control, .command])
        #endif
        // The sidebar must stay shown over the period a hide would take.
        Thread.sleep(forTimeInterval: 2)
        XCTAssertTrue(hittable(library, within: 5), "the sidebar stays shown")
        shot("\(platform) sidebar kept open after hide")
        // The screen beside it still takes presses: a hub's View all opens its hub. Which hubs have one is the server's,
        // so the first may lie below the window.
        let firstViewAll = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.' AND identifier ENDSWITH '.viewAll'")).firstMatch
        XCTAssertTrue(firstViewAll.waitForExistence(timeout: 20), "a hub with a View all")
        let viewAll = reveal(firstViewAll.identifier)
        XCTAssertTrue(hittable(viewAll, within: 5), "a hub's View all beside the sidebar")
        press(viewAll)
        require("hubDetail", timeout: 20, "View all's hub beside the kept sidebar")
        XCTAssertTrue(hittable(library, within: 5), "the sidebar still shown over the hub")
    }

    private func hittable(_ target: XCUIElement, within timeout: TimeInterval) -> Bool {
        let shown = expectation(for: NSPredicate(format: "exists == true AND hittable == true"), evaluatedWith: target)
        return XCTWaiter.wait(for: [shown], timeout: timeout) == .completed
    }
    #endif

    #if os(iOS)
    /// Appearance's App icon row names the icon picked in its picker as soon as the picker closes, not only
    /// after a relaunch; Default picked again restores it.
    func testAppIconRowFollowsPick() throws {
        open("settings", screen: "settings.screen")
        press(reveal("settings.row.appearance"))
        require("settings.page.appearance", "Appearance")
        let row = reveal("settings.appIcon")
        guard row.exists else { throw XCTSkip("this build offers no app icons") }
        for (icon, other) in [("ember", "default"), ("default", "ember")] {
            press(row)
            let tile = require("appIcon.\(icon)", "the picker's \(icon) icon")
            let name = tile.label
            let otherName = element("appIcon.\(other)").label
            tile.tap()
            // The system's "You have changed the icon" alert, over the app, takes taps until it is answered; it can
            // come up late.
            let ok = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["OK"]
            if ok.waitForExistence(timeout: 10) { ok.tap() }
            let close = require("appIcon.close", "the picker's Close")
            for _ in 0..<4 where close.exists {
                if ok.exists { ok.tap() }
                if close.exists, close.isHittable { press(close) }
                _ = waitUntil(3) { !close.exists }
            }
            requireGone("appIcon.close", "Close closes the picker")
            let shown = expectation(for: NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", name, name), evaluatedWith: row)
            if XCTWaiter.wait(for: [shown], timeout: 10) != .completed { fail("the App icon row doesn't name \(name): \(row.label)") }
            XCTAssertFalse(row.label.contains(otherName) || (row.value as? String ?? "").contains(otherName), "the row no longer names \(otherName)")
            shot("\(platform) settings app icon \(icon)")
        }
    }
    #endif

    // MARK: The profile

    /// The hub starts with the running profile: its row above General, which opens the profile picker.
    private func profileFirst() {
        let profile = require("settings.profile.switch", "the hub's profile row")
        let general = element("settings.row.general")
        XCTAssertLessThan(profile.frame.minY, general.frame.minY, "the profile row comes before General")
    }

    #if !os(tvOS)
    /// The Supporter sheet, where the build offers it (the hub's or Appearance's tile): opened, shot and closed.
    private func supporterIfShown() {
        let tile = reveal("settings.supporter")
        guard tile.exists else { return }
        press(tile)
        require("supporter.sheet", "the Supporter sheet")
        // The sheet's presentation ends with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1.5)
        shot("\(platform) settings supporter")
        let close = element("supporter.close")
        if close.exists(within: 2) { press(close) } else { app.swipeDown(velocity: .fast) }
        requireGone("supporter.sheet", "the Supporter sheet closes")
    }

    private func requireGone(_ id: String, _ what: String) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element(id))
        if XCTWaiter.wait(for: [gone], timeout: 10) != .completed { fail("\(what): \(id) still there") }
    }
    #endif

    // MARK: Apple TV

    #if os(tvOS)
    /// The hub and its pages through the remote: each page opened from its row, shot, and left with Menu, after which
    /// the row that opened it has focus again.
    private func tourTv() {
        // Presses paced so the focus engine takes each one, then the scroll ends before the shot.
        for _ in 0..<12 { XCUIRemote.shared.press(.down); Thread.sleep(forTimeInterval: 0.2) }
        Thread.sleep(forTimeInterval: 1)
        shot("tv settings hub scrolled")
        let pages: [(String, String, String)] = [
            ("settings.row.general", "settings.page.general", "general"),
            ("settings.row.appearance", "settings.page.appearance", "appearance"),
            ("settings.row.playback", "settings.page.video_playback", "video playback"),
            ("settings.row.account_preferences", "settings.page.account_preferences", "account preferences"),
            ("settings.row.view_logs", "settings.page.logs", "logs"),
            ("settings.row.about", "settings.page.about", "about"),
        ]
        for (row, page, name) in pages {
            XCTAssertTrue(focus(row), "\(row) focused")
            XCUIRemote.shared.press(.select)
            require(page, "the \(name) page")
            // The page's transition ends with nothing to wait on before the shot.
            Thread.sleep(forTimeInterval: 1.5)
            shot("tv settings \(name)")
            if name == "appearance" {
                tvThemeEditor()
            } else if name == "video playback" {
                // Presses paced so the focus engine takes each one.
                for _ in 0..<10 { XCUIRemote.shared.press(.down); Thread.sleep(forTimeInterval: 0.2) }
                shot("tv settings video playback scrolled")
                tvOpen(row: "settings.row.mpv_config", page: "settings.page.mpv_config", shot: "mpv config")
                tvOpen(row: "settings.row.subtitle_styling", page: "settings.page.subtitle_styling", shot: "subtitle styling")
                if focus("settings.row.seek_time_small") {
                    XCUIRemote.shared.press(.select)
                    require("settings.number.spinner", "the number dialog")
                    // The dialog's presentation ends with nothing to wait on before the shot.
                    Thread.sleep(forTimeInterval: 1)
                    shot("tv settings number dialog")
                    XCUIRemote.shared.press(.menu)
                    _ = element("settings.number.spinner").waitForNonExistence(timeout: 5)
                }
            } else if name == "about" {
                tvOpen(row: "settings.row.licenses", page: "settings.page.licenses", shot: "licenses")
            }
            XCUIRemote.shared.press(.menu)
            require("settings.screen", "the hub after Back")
            _ = waitUntil(5) { focused(row) }
            XCTAssertTrue(focused(row), "focus back on \(row) after its page")
        }
        shot("tv settings hub focus restored")
    }

    /// Theme, then where offered the custom theme editor (a page here) and its first colour's panel, each shot; Menu
    /// back out of each to Appearance.
    private func tvThemeEditor() {
        XCTAssertTrue(focus("settings.row.theme"), "Theme focused")
        XCUIRemote.shared.press(.select)
        require("settings.page.theme", "the theme picker")
        // The page's transition ends with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1.5)
        shot("tv settings theme picker")
        if element("settings.theme.custom").exists, focus("settings.theme.custom") {
            XCUIRemote.shared.press(.select)
            require("settings.page.custom_theme", "the custom theme editor")
            // The page's transition ends with nothing to wait on before the shot.
            Thread.sleep(forTimeInterval: 1.5)
            shot("tv settings custom theme")
            XCTAssertTrue(focus("settings.custom.slot.0"), "the first colour focused")
            XCUIRemote.shared.press(.select)
            require("settings.custom.slot.panel", "the colour's panel")
            // The panel's presentation ends with nothing to wait on before the shot.
            Thread.sleep(forTimeInterval: 1.5)
            shot("tv settings custom theme colour")
            XCUIRemote.shared.press(.menu)
            _ = element("settings.custom.slot.panel").waitForNonExistence(timeout: 5)
            XCUIRemote.shared.press(.menu)
            require("settings.page.theme", "the theme picker after the editor")
            // Menu pressed while the page still moves in is dropped.
            Thread.sleep(forTimeInterval: 1.5)
        }
        XCUIRemote.shared.press(.menu)
        _ = element("settings.page.theme").waitForNonExistence(timeout: 5)
    }

    private func tvOpen(row: String, page: String, shot name: String) {
        XCTAssertTrue(focus(row), "\(row) focused")
        XCUIRemote.shared.press(.select)
        require(page, "the \(name) page")
        // The page's transition ends with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1.5)
        shot("tv settings \(name)")
        XCUIRemote.shared.press(.menu)
        _ = element(page).waitForNonExistence(timeout: 5)
    }

    /// The number dialog opens on its value, which Left and Right step, and a held Right keeps stepping (after
    /// 400 ms, every 100 ms), its range hint readable under it; Select moves to Save, which stores the value the row
    /// then shows.
    func testNumberDialogStepsWithTheRemote() {
        open("settings", screen: "settings.screen")
        XCTAssertTrue(focus("settings.row.playback"), "Video Playback focused")
        XCUIRemote.shared.press(.select)
        require("settings.page.video_playback", "Video Playback")
        XCTAssertTrue(focus("settings.row.seek_time_small"), "Small Skip Duration focused")
        XCUIRemote.shared.press(.select)
        let spinner = require("settings.number.spinner", "the number dialog")
        _ = waitUntil(5) { focused("settings.number.spinner") }
        XCTAssertTrue(focused("settings.number.spinner"), "the value focused as the dialog opens")
        requireReadable(require("settings.number.hint", "the dialog's range hint"), "the range hint")
        let start = Int((spinner.value as? String ?? "").prefix { $0.isNumber }) ?? -1
        // Presses paced so the focus engine takes each one.
        for _ in 0..<3 { XCUIRemote.shared.press(.right); Thread.sleep(forTimeInterval: 0.4) }
        XCUIRemote.shared.press(.left)
        _ = waitUntil(5) { (Int((spinner.value as? String ?? "").prefix { $0.isNumber }) ?? -1) == start + 2 }
        let stepped = Int((spinner.value as? String ?? "").prefix { $0.isNumber }) ?? -1
        XCTAssertEqual(stepped, start + 2, "three Rights and a Left step the value by 2 from \(start)")
        shot("tv settings number stepped")
        // Held 1.5 s: the press's step, then one at 400 ms and every 100 ms after: about 12. The simulator's remote
        // holds as the hardware's does as far as the app sees (a press begun and ended), not its timing.
        XCUIRemote.shared.press(.right, forDuration: 1.5)
        // The steps the hold made are counted once they have all landed.
        Thread.sleep(forTimeInterval: 0.6)
        let held = Int((spinner.value as? String ?? "").prefix { $0.isNumber }) ?? -1
        XCTAssertGreaterThanOrEqual(held, stepped + 6, "holding Right 1.5 s keeps stepping from \(stepped)")
        XCTAssertLessThanOrEqual(held, stepped + 16, "holding Right 1.5 s steps at most every 100 ms from \(stepped)")
        shot("tv settings number held")
        XCUIRemote.shared.press(.select)
        _ = waitUntil(5) { focused("settings.number.save") }
        XCTAssertTrue(focused("settings.number.save"), "Select on the value moves to Save")
        XCUIRemote.shared.press(.select)
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: spinner)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 10), .completed, "Save closes the dialog")
        let row = element("settings.row.seek_time_small")
        let shows = expectation(for: NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "\(held)", "\(held)"), evaluatedWith: row)
        XCTAssertEqual(XCTWaiter.wait(for: [shows], timeout: 10), .completed, "the row shows \(held): \(row.label)")
        shot("tv settings number saved")
    }

    /// Add line in the mpv.conf editor puts focus in the new line's field, ready for Select's keyboard; Right
    /// moves on to the line's Remove, the line's number readable beside either; the line is removed again after.
    func testAddLineFocusesTheNewLine() {
        open("settings", screen: "settings.screen")
        XCTAssertTrue(focus("settings.row.playback"), "Video Playback focused")
        XCUIRemote.shared.press(.select)
        require("settings.page.video_playback", "Video Playback")
        XCTAssertTrue(focus("settings.row.mpv_config"), "mpv.conf focused")
        XCUIRemote.shared.press(.select)
        require("settings.page.mpv_config", "mpv.conf")
        _ = element("settings.mpv.addLine").exists(within: 5)
        var count = 0
        while element("settings.mpv.line.\(count)").exists { count += 1 }
        XCTAssertTrue(focus("settings.mpv.addLine"), "Add line focused")
        XCUIRemote.shared.press(.select)
        let line = require("settings.mpv.line.\(count)", "the new line \(count)")
        _ = line.wait(for: \.hasFocus, toEqual: true, timeout: 5)
        shot("tv mpv line added")
        XCTAssertTrue(line.hasFocus, "the new line's field has focus after Add line")
        let number = require("settings.mpv.line.\(count).number", "the new line's number")
        requireReadable(number, "the line's number beside its focused field")
        XCUIRemote.shared.press(.right)
        _ = element("settings.mpv.line.\(count).remove").wait(for: \.hasFocus, toEqual: true, timeout: 5)
        shot("tv mpv line remove focused")
        XCTAssertTrue(element("settings.mpv.line.\(count).remove").hasFocus, "Right moves to the new line's Remove")
        requireReadable(number, "the line's number beside its focused Remove")
        XCUIRemote.shared.press(.select)
        _ = element("settings.mpv.line.\(count)").waitForNonExistence(timeout: 5)
        XCTAssertFalse(element("settings.mpv.line.\(count)").exists, "the added line removed")
    }

    /// The hub's focused row comes back when the Settings tab shows again after another: Down from the tab bar
    /// lands on it, not on the row under the bar.
    func testHubKeepsItsRowAcrossTabs() {
        open("settings", screen: "settings.screen")
        XCTAssertTrue(focus("settings.row.playback"), "Video Playback focused")
        // Focus rests on the row before Menu, as a user's would: the row kept is what is tested.
        Thread.sleep(forTimeInterval: 0.5)
        XCUIRemote.shared.press(.menu)
        _ = waitUntil(5) { app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.identifier.hasPrefix("nav.") }
        reachTab("home")
        require("home.screen", timeout: 30, "Home")
        reachTab("settings")
        require("settings.screen", "the hub")
        // Down pressed while the tab still switches is dropped; nothing signals the switch's end.
        Thread.sleep(forTimeInterval: 1.5)
        XCUIRemote.shared.press(.down)
        _ = waitUntil(5) { focused("settings.row.playback") }
        shot("tv settings hub back from another tab")
        XCTAssertTrue(focused("settings.row.playback"), "focus back on Video Playback")
    }

    /// Moves focus with the remote until `id` has it: down first, then up; false when it never does.
    @discardableResult
    private func focus(_ id: String, presses: Int = 40) -> Bool {
        for direction in [XCUIRemote.Button.down, .up] {
            for _ in 0..<presses {
                if focused(id) { return true }
                XCUIRemote.shared.press(direction)
                _ = waitUntil(0.25) { focused(id) }
            }
        }
        if focused(id) { return true }
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "element tree: no focus on \(id)"
        tree.lifetime = .keepAlways
        add(tree)
        return false
    }

    /// Whether the element `id` has focus, or the focused element holds it (a form's row: its cell takes focus).
    private func focused(_ id: String) -> Bool {
        let all = app.descendants(matching: .any)
        if all.matching(NSPredicate(format: "identifier == %@ AND hasFocus == true", id)).count > 0 { return true }
        let focusedElement = all.matching(NSPredicate(format: "hasFocus == true")).firstMatch
        return focusedElement.exists && focusedElement.descendants(matching: .any).matching(identifier: id).count > 0
    }
    #endif

    // MARK: Helpers

    /// Shows the top-level destination `destination`: its tab (on Apple TV the top tab bar, reached with Menu and Up,
    /// then along it; the Search tab takes focus into its field as focus passes it, and Up brings it back).
    private func goTo(_ destination: String, screen: String) {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        _ = waitUntil(5) { app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.identifier.hasPrefix("nav.") }
        reachTab(destination)
        XCUIRemote.shared.press(.select)
        #else
        pressNav(require("nav.\(destination)", "the chrome's \(destination)"))
        #endif
        require(screen, timeout: 30, "the \(destination) screen")
    }

    #if os(tvOS)
    /// Moves focus along Apple TV's tab bar (Up onto it first) until `destination`'s tab has it, which shows its screen.
    private func reachTab(_ destination: String) {
        let item = element("nav.\(destination)")
        let current = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        let reached = { self.focused("nav.\(destination)") || item.hasFocus }
        for _ in 0..<20 where !reached() {
            if current.exists, current.identifier.hasPrefix("nav.") {
                XCUIRemote.shared.press(current.frame.midX < item.frame.midX ? .right : .left)
            } else {
                XCUIRemote.shared.press(.up)
            }
            _ = waitUntil(0.5) { reached() }
        }
        if !reached() { fail("focus never reached nav.\(destination)") }
    }
    #endif

    #if !os(tvOS)
    /// Opens the hub row `row`, shoots its page and runs `then` there, then goes back to the hub.
    private func visit(_ row: String, page: String, shot name: String, then: (() -> Void)? = nil) {
        open(row: row, page: page, shot: name, back: false)
        then?()
        backToHub()
    }

    /// Opens `row` of the page shown, waits for `page` and shoots it; with `back`, goes back a page after.
    private func open(row: String, page: String, shot name: String, back: Bool = true) {
        let found = reveal(row)
        guard found.exists else { return fail("no \(row)") }
        let from = currentPage()
        press(found)
        require(page, "the \(name) page")
        // The page's transition ends with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1.5)
        shot("\(platform) settings \(name)")
        if back, let from { backOne(to: from) }
    }

    /// Opens the dialog of `row`, shoots it, and closes it with `probe` (its Cancel).
    private func dialog(_ row: String, probe: String, shot name: String) {
        let found = reveal(row)
        guard found.exists else { return fail("no \(row)") }
        press(found)
        let cancel = require(probe, "the \(name)")
        // The dialog's presentation ends with nothing to wait on before the shot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(platform) settings \(name)")
        cancelDialog(cancel)
        _ = waitUntil(5) { found.isHittable }
    }

    /// Closes a dialog with its Cancel (`cancel`), pressed until the dialog goes. On iPhone the test's typed keys
    /// (hardware key events) put the keyboard away and the sheet down to half height; about a second later the keyboard
    /// comes back and lifts the sheet to full height, and a press as it rises ends off Cancel, which moves from under
    /// it, leaving the dialog up. On iPad its field, focused as it opens, brings up the number pad as a popover over the
    /// sheet (over Cancel at times: a tap there types a digit), whose dismiss region takes the next tap elsewhere, or the
    /// docked keyboard, which lifts the sheet: the keyboard is hidden, or the popover closed by a tap on the sheet's
    /// empty foot, first.
    private func cancelDialog(_ cancel: XCUIElement) {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            let hide = app.keyboards.buttons["Hide keyboard"]
            if hide.exists, app.windows.firstMatch.frame.contains(CGPoint(x: hide.frame.midX, y: hide.frame.midY)) {
                hide.tap()
                _ = app.keyboards.firstMatch.waitForNonExistence(timeout: 5)
            }
            if app.otherElements["PopoverDismissRegion"].exists {
                app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)).tap()
                _ = app.otherElements["PopoverDismissRegion"].waitForNonExistence(timeout: 5)
            }
        }
        for _ in 0..<3 where cancel.exists {
            press(cancel)
            let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: cancel)
            _ = XCTWaiter.wait(for: [gone], timeout: 3)
        }
        XCTAssertFalse(cancel.exists, "the dialog closes with Cancel")
        #else
        press(cancel)
        #endif
    }

    private func dialogIfShown(_ row: String, probe: String, shot name: String) {
        if reveal(row).exists { dialog(row, probe: probe, shot: name) }
    }

    /// The settings page on screen's identifier (the innermost one shown).
    private func currentPage() -> String? {
        let pages = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'settings.page.'"))
        return pages.allElementsBoundByIndex.last(where: { $0.exists && $0.frame.width > 0 })?.identifier
    }

    /// Back one page, to `page`: the system's back button, or mpv.conf's own (the Mac's toolbar has Show Sidebar before
    /// it).
    private func backOne(to page: String) {
        #if os(iOS)
        let back = element("settings.mpv.back").exists ? element("settings.mpv.back") : backButton
        if back.exists { back.tap() }
        #else
        let back = element("settings.mpv.back").exists ? element("settings.mpv.back") : app.toolbars.buttons["chevron.backward"]
        if back.exists { back.click() }
        #endif
        if !element(page).exists(within: 10) {
            #if os(macOS)
            app.typeKey("[", modifierFlags: .command)
            #endif
        }
        require(page, timeout: 10, "\(page) after Back")
    }

    /// Back to the hub: Settings picked again pops its stack.
    private func backToHub() {
        pressNav(require("nav.settings", "the chrome's Settings"))
        require("settings.screen", "the hub")
        // The pop's animation ends before the next scroll or shot, with nothing to wait on.
        Thread.sleep(forTimeInterval: 1)
    }

    private func press(_ target: XCUIElement) {
        #if os(macOS)
        target.click()
        #else
        target.tap()
        #endif
    }

    /// Picks a destination of the chrome. The Mac's rail opens under the pointer with taller items than collapsed: the
    /// pointer rests on the item first, and the click finds it where the open rail moved it.
    private func pressNav(_ item: XCUIElement) {
        #if os(macOS)
        item.hover()
        Thread.sleep(forTimeInterval: 0.8)
        #endif
        press(item)
    }

    /// The scrolling form of the page on screen.
    #if os(iOS)
    private var scroller: XCUIElement {
        let list = app.collectionViews.firstMatch
        return list.exists ? list : app
    }
    #else
    /// The pointer over the page's column: the Mac's first scroll view is the sidebar's.
    private var scroller: XCUICoordinate {
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
    }
    #endif

    private func scrollDown() {
        #if os(iOS)
        scroller.swipeUp(velocity: .slow)
        #else
        scroller.scroll(byDeltaX: 0, deltaY: -400)
        #endif
        // The scroll's deceleration ends before the next shot or pixel read, with nothing to wait on.
        Thread.sleep(forTimeInterval: 1)
    }

    private func scrollUp() {
        #if os(iOS)
        scroller.swipeDown(velocity: .slow)
        #else
        scroller.scroll(byDeltaX: 0, deltaY: 400)
        #endif
        // The scroll's deceleration ends, with nothing to wait on.
        Thread.sleep(forTimeInterval: 0.5)
    }

    /// `id`, scrolled into view and at rest: up first when it is laid out above the window, else down first, then the
    /// other way; an element that never shows is returned as it is.
    private func reveal(_ id: String) -> XCUIElement {
        let target = element(id)
        if visible(target) { return target }
        let above = target.exists && target.frame.maxY < app.windows.firstMatch.frame.midY
        let passes: [(count: Int, scroll: () -> Void)] = above ? [(20, scrollUp), (10, scrollDown)] : [(10, scrollDown), (20, scrollUp)]
        for pass in passes {
            for _ in 0..<pass.count {
                pass.scroll()
                if visible(target) {
                    // A list still moving takes a tap as the end of its scroll.
                    Thread.sleep(forTimeInterval: 1)
                    return target
                }
            }
        }
        return target
    }

    private func visible(_ target: XCUIElement) -> Bool {
        guard target.exists, target.isHittable else { return false }
        let window = app.windows.firstMatch.frame
        #if os(iOS)
        // iPhone's tab bar covers the window's foot; iPad's floats at its top and the iPhone Duo's stands along its side
        // (`besideVerticalBar`), where the list ends 40 pt over the foot. The page's navigation bar covers its top: on
        // iPad under the floating tab bar, to 150 pt.
        let sideBar = besideVerticalBar.width < window.width
        let foot: CGFloat = UIDevice.current.userInterfaceIdiom == .pad || sideBar ? 40 : 100
        let bar = app.navigationBars.firstMatch
        let top = max(window.minY + 100, bar.exists ? bar.frame.maxY : 0)
        let bounds = CGRect(x: window.minX, y: top, width: window.width, height: window.maxY - foot - top)
        #else
        // The toolbar's band over the window's top; nothing covers its foot, where a page's last row can end.
        let bounds = CGRect(x: window.minX, y: window.minY + 60, width: window.width, height: window.height - 60 - 12)
        #endif
        return bounds.contains(CGPoint(x: target.frame.midX, y: target.frame.midY))
    }
    #endif

    private func firstCard() -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
    }

    /// The luminance (0 black – 1 white) of the app's background: the window's right edge halfway down, beside the
    /// page's centred column, averaged over a few pixels.
    private func backgroundLuminance() -> Double {
        #if os(macOS)
        let image = app.windows.firstMatch.screenshot().image
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return -1 }
        #else
        guard let cgImage = app.screenshot().image.cgImage else { return -1 }
        #endif
        let x = Int(Double(cgImage.width) * 0.985)
        let y = Int(Double(cgImage.height) * 0.5)
        guard let crop = cgImage.cropping(to: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)) else { return -1 }
        var pixels = [UInt8](repeating: 0, count: 4 * 4 * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 16,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: 4, height: 4))
            return true
        }
        guard drawn else { return -1 }
        var total = 0.0
        for pixel in 0..<16 {
            let r = Double(pixels[pixel * 4]), g = Double(pixels[pixel * 4 + 1]), b = Double(pixels[pixel * 4 + 2])
            total += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
        }
        return total / 16
    }
}
