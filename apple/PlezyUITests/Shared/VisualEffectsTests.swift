import XCTest

/// The visual effects tier (`visual_effects`) and Apple TV's value controls, against the test servers' Jellyfin
/// (`--dev-server`, `PLEZY_DEV_SERVER` or the default), signed in as maestro.
///
/// - iPhone and iPad: Now Playing and its lyrics over the track's blurred artwork at Full, then, the setting changed
///   while the app runs, over the plain background at Reduced (shots `full …`, `reduced …`).
/// - Apple TV: in Bulgarian, a colour setting's dialog naming its channels' steps ("Намали Нюанс") and its hex field, a
///   channel's step writing the hex digits anew in upper case, and the number dialog naming its steps ("Намали",
///   "Увеличи").
final class VisualEffectsTests: PlezyUITestCase {
    private var server: String {
        if let given = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"], !given.isEmpty { return given }
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
    }

    /// The element labelled `label`, of any type.
    private func labelled(_ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    #if os(iOS)
    func testNowPlayingBackground() {
        launchDev(
            settings: ["theme_mode=dark", "visual_effects=full"],
            // Music libraries browse in Libraries, which has no element of the library's own: the session opens on
            // the artist (as MusicTests' do).
            arguments: ["--dev-server", server, "--dev-open-music", "artist=Plezy Test Artist"]
        )
        require("music.artist", timeout: 90, "Plezy Test Artist's screen")
        let album = labelled("Sine Album")
        if !album.exists(within: 30) { fail("no Sine Album on the artist") }
        album.tap()
        require("music.album", "the album screen")
        require("music.track.1", "Low Hum's row").tap()
        require("music.mini", timeout: 30, "the mini-player")
        require("music.mini.open", "the mini-player's track").tap()
        require("music.np.screen", "Now Playing")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 4)
        shot("full now playing")
        require("music.np.lyrics", "the lyrics button").tap()
        require("music.lyrics", timeout: 30, "the synced lyrics")
        shot("full lyrics")

        changeDevSetting("visual_effects=reduced")
        // The background changes with no element to show it: given time before the shot.
        Thread.sleep(forTimeInterval: 3)
        require("music.lyrics", "the lyrics after the change")
        shot("reduced lyrics")
        require("music.np.lyrics", "the lyrics button").tap()
        require("music.np.artwork", "the artwork after the lyrics")
        shot("reduced now playing")
    }

    /// The System theme takes the device's appearance: Settings is light on a light device, where Dark keeps it
    /// dark. Where the simulator applies an appearance switch to its apps (its own Settings app turns dark), System
    /// follows the switch live, to dark and back; where it doesn't (iOS 27's simulators: every app stays light), the
    /// live part is noted as unproven and the rest still holds.
    func testSystemThemeFollowsTheDevice() {
        XCUIDevice.shared.appearance = .light
        launchDev(settings: ["theme_mode=system"], arguments: ["--dev-server", server, "--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        let light = luminance(within: 5) { $0 >= 0.6 }
        shot("system light device")
        if light < 0.6 { fail("System on a light device paints dark (luminance \(light))") }

        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", server, "--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        let dark = luminance(within: 5) { $0 <= 0.4 }
        shot("dark light device")
        if dark > 0.4 { fail("Dark on a light device paints light (luminance \(dark))") }

        let systemSettings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = .light }
        systemSettings.launch()
        let switches = luminance(within: 5) { $0 <= 0.4 } <= 0.4
        systemSettings.terminate()
        guard switches else {
            XCTContext.runActivity(named: "The simulator applies no appearance switch to its apps: System's live switch is unproven here") { _ in }
            return
        }
        launchDev(settings: ["theme_mode=system"], arguments: ["--dev-server", server, "--dev-open", "settings"])
        require("settings.screen", timeout: 60, "Settings")
        let darkDevice = luminance(within: 5) { $0 <= 0.4 }
        shot("system dark device")
        if darkDevice > 0.4 { fail("System on a dark device paints light (luminance \(darkDevice))") }
        XCUIDevice.shared.appearance = .light
        let lightAgain = luminance(within: 10) { $0 >= 0.6 }
        shot("system light device live")
        if lightAgain < 0.6 { fail("System doesn't turn light as the device does (luminance \(lightAgain))") }
        XCUIDevice.shared.appearance = .dark
        let darkAgain = luminance(within: 10) { $0 <= 0.4 }
        if darkAgain > 0.4 { fail("System doesn't turn dark as the device does (luminance \(darkAgain))") }
    }

    /// The screen's luminance once `settled` holds of it, or the last one read after `timeout` seconds.
    private func luminance(within timeout: TimeInterval, _ settled: (Double) -> Bool) -> Double {
        var value = -1.0
        _ = waitUntil(timeout, every: 0.5) {
            value = screenLuminance()
            return settled(value)
        }
        return value
    }

    /// The screen's mean luminance (0 black, 1 white), sampled on a grid over the app's screenshot.
    private func screenLuminance() -> Double {
        guard let image = XCUIScreen.main.screenshot().image.cgImage,
              let data = image.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return -1 }
        let step = image.bitsPerPixel / 8
        var total = 0.0
        var count = 0
        for y in stride(from: image.height / 10, to: image.height * 9 / 10, by: max(1, image.height / 40)) {
            for x in stride(from: 0, to: image.width, by: max(1, image.width / 20)) {
                let pixel = bytes + y * image.bytesPerRow + x * step
                total += (0.2126 * Double(pixel[0]) + 0.7152 * Double(pixel[1]) + 0.0722 * Double(pixel[2])) / 255
                count += 1
            }
        }
        return count > 0 ? total / Double(count) : -1
    }
    #endif

    #if os(tvOS)
    func testValueControlsNameTheirSteps() {
        let strings = BulgarianStrings.self
        launchDev(settings: ["theme_mode=dark"], languages: ["bg"], arguments: ["--dev-open", "settings", "--dev-server", server])
        require("settings.screen", timeout: 90, "Settings")
        // Settings' rows settle as the rest of its content comes, before focus walks them.
        Thread.sleep(forTimeInterval: 2)
        open(row: "settings.row.playback", page: "settings.page.video_playback")
        open(row: "settings.row.subtitle_styling", page: "settings.page.subtitle_styling")

        // A colour: its channels' steps and its hex field, named in the interface language.
        open(row: "settings.row.subtitle_text_color", page: "settings.hsv.hue")
        let hue = element("settings.hsv.hue")
        XCTAssertEqual(hue.label, strings.hue, "the hue's name")
        for label in [strings.decreaseHue, strings.increaseHue, strings.decreaseSaturation, strings.increaseBrightness] {
            XCTAssertTrue(labelled(label).exists, "a step named \(label)")
        }
        XCTAssertFalse(labelled("Decrease Hue").exists, "no English step names")
        let hex = require("settings.hsv.hex", "the hex field")
        XCTAssertEqual(hex.label, strings.hexColor, "the hex field's name")
        // A grey has no hue to show, so saturation steps first: 5 % more changes any colour short of full saturation.
        XCTAssertTrue(focus("settings.hsv.saturation"), "the saturation focused")
        let before = hex.value as? String ?? ""
        XCUIRemote.shared.press(.right)
        _ = waitUntil(5) { (hex.value as? String ?? "") != before }
        let after = hex.value as? String ?? ""
        XCTAssertNotEqual(after, before, "a saturation step writes the hex digits anew")
        XCTAssertEqual(after.count, 6, "six hex digits: \(after)")
        XCTAssertEqual(after, after.uppercased(), "upper case: \(after)")
        XCTAssertTrue(focus("settings.hsv.hue"), "the hue focused")
        let hueBefore = Int((hue.value as? String ?? "").dropLast()) ?? -1
        XCUIRemote.shared.press(.right)
        _ = waitUntil(5) { hue.value as? String == "\((hueBefore + 5) % 360)°" }
        XCTAssertEqual(hue.value as? String, "\((hueBefore + 5) % 360)°", "a hue step is 5°")
        shot("tv colour dialog")
        // Back from the dialog, then from Subtitle styling to Video playback.
        for _ in 0..<2 {
            XCUIRemote.shared.press(.menu)
            // Paces the presses so each Back lands after the last one's transition.
            Thread.sleep(forTimeInterval: 1.5)
        }
        require("settings.page.video_playback", "Video playback after Back")

        // A number: its steps named without a channel.
        open(row: "settings.row.seek_time_small", page: "settings.number.spinner")
        XCTAssertTrue(labelled(strings.decrease).exists, "the step down named \(strings.decrease)")
        XCTAssertTrue(labelled(strings.increase).exists, "the step up named \(strings.increase)")
        XCTAssertFalse(labelled("Decrease").exists, "no English step names")
        shot("tv number dialog")
    }

    /// The Bulgarian names the tvOS value controls take.
    private enum BulgarianStrings {
        static let hue = "Нюанс"
        static let decreaseHue = "Намали Нюанс"
        static let increaseHue = "Увеличи Нюанс"
        static let decreaseSaturation = "Намали Наситеност"
        static let increaseBrightness = "Увеличи Яркост"
        static let hexColor = "Шестнадесетичен цвят"
        static let decrease = "Намали"
        static let increase = "Увеличи"
    }

    /// Moves focus onto the row `row`, selects it and waits for `page` (an element of what it opens).
    private func open(row: String, page: String) {
        XCTAssertTrue(focus(row), "\(row) focused")
        XCUIRemote.shared.press(.select)
        require(page, "what \(row) opens")
        // Lets the page's push finish before focus moves in it.
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// Moves focus with the remote until `id` has it: down first, then up; false when it never does.
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
}
