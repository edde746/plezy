#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import XCTest

/// What every Plezy UI test shares: launching the app (the product, or a DEBUG `--dev` session), finding controls by
/// accessibility identifier (the Compose UI's probe names: `nav.home`, `home.screen`), and screenshots kept in the
/// result bundle.
@MainActor
class PlezyUITestCase: XCTestCase {
    lazy var app = XCUIApplication()
    private var shots = 0

    #if os(iOS)
    /// Starts every test with the device upright: the simulator keeps the orientation a test turned it to (the player's
    /// landscape on a phone, an iPad's wide layout) into the tests after it, in its run and the next.
    nonisolated override func setUp() {
        super.setUp()
        MainActor.assumeIsolated { XCUIDevice.shared.orientation = .portrait }
    }
    #endif

    /// Puts back the test server's watch state of the items the class's launches played (`WatchStateRestore`).
    nonisolated override class func tearDown() {
        MainActor.assumeIsolated {
            for failure in WatchStateRestore.restoreAll() { XCTFail(failure) }
        }
        super.tearDown()
    }

    #if os(macOS)
    /// Drags the window's bottom edge `points` down (up when negative), and waits for the page to lay out again: from
    /// just outside the edge, on it, then from the bottom trailing corner, until one takes.
    func resizeWindow(by points: CGFloat) {
        let window = app.windows.firstMatch
        let before = window.frame.height
        let grips: [(CGVector, CGVector)] = [
            (CGVector(dx: 0.5, dy: 1), CGVector(dx: 0, dy: 2)),
            (CGVector(dx: 0.5, dy: 1), CGVector(dx: 0, dy: -1)),
            (CGVector(dx: 1, dy: 1), CGVector(dx: -6, dy: -6)),
        ]
        for (corner, offset) in grips where abs(window.frame.height - before) < 1 {
            let grip = window.coordinate(withNormalizedOffset: corner).withOffset(offset)
            grip.click(forDuration: 0.5, thenDragTo: grip.withOffset(CGVector(dx: 0, dy: points)), withVelocity: .slow, thenHoldForDuration: 0.5)
            Thread.sleep(forTimeInterval: 1)
        }
        if abs(window.frame.height - before - points) > 40 { fail("the window went from \(before) to \(window.frame.height), not \(points) points") }
    }
    #endif

    /// Launches the product, as a user starts the app.
    func launchProduct() {
        launch([])
    }

    /// Launches a `--dev` session (an in-memory database), with this device's `settings` (`--dev-setting
    /// <key>=<value>`, e.g. `enable_hardware_decoding=false`) after the run's own (`harnessSettings`), in `languages` (most
    /// preferred first: `["fr"]`) where given, else the run's (`languages`), and with `arguments` (DEBUG builds' launch
    /// arguments) last. The test server's watch state of the item it plays (`--dev-play`) starts at the item's start in
    /// the class's first test and goes back as it was when the class ends (`WatchStateRestore`).
    func launchDev(settings: [String] = [], languages: [String]? = nil, arguments extra: [String] = []) {
        var arguments = ["--dev"]
        for setting in Self.harnessSettings + settings { arguments += ["--dev-setting", setting] }
        if let failure = WatchStateRestore.keep(extra) { fail(failure) }
        launch(arguments + extra, languages: languages)
    }

    /// Device settings every `--dev` launch of the run starts with: `PLEZY_DEV_SETTINGS` (`enable_hdr=false`, a run
    /// with HDR output off), passed as `TEST_RUNNER_PLEZY_DEV_SETTINGS`, split at spaces. A test's own settings come
    /// after them and win.
    static var harnessSettings: [String] {
        (ProcessInfo.processInfo.environment["PLEZY_DEV_SETTINGS"] ?? "").split(separator: " ").map(String.init)
    }

    /// Changes a device setting of the running `--dev` session, as `--dev-setting` sets one at the launch (`spec`,
    /// `<key>=<value>`: `offline=true`): opens `plezy://dev-setting?<spec>` in the app under test (`openFromOutside`),
    /// which applies it at once (DEBUG builds' `AppModel.followDevLink`).
    func changeDevSetting(_ spec: String) {
        guard let query = spec.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "plezy://dev-setting?\(query)") else {
            return fail("no dev-setting link for '\(spec)'")
        }
        openFromOutside(url)
    }

    /// Opens `url` in the running app under test through the system, as a link opened elsewhere (a browser, another
    /// app) reaches it: `XCUIApplication.open` launches the app again with it, which ends a dev session. On the Mac it
    /// goes to the running app's own bundle by path (the latest launched), since a Mac may have other builds registered
    /// for the app's scheme; the tests run the Debug build, whose bundle ID on the Mac is com.edde746.plezy.dev
    /// (project.yml).
    func openFromOutside(_ url: URL) {
        #if os(macOS)
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: "com.edde746.plezy.dev")
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }
        guard let bundle = running?.bundleURL else {
            return fail("no running app to send \(url.scheme ?? "the") link to")
        }
        NSWorkspace.shared.open([url], withApplicationAt: bundle, configuration: NSWorkspace.OpenConfiguration())
        #else
        XCUIDevice.shared.system.open(url)
        #endif
    }

    /// The languages the app starts with: `PLEZY_LANGUAGE`'s (a tag, or a list most preferred first such as
    /// en-US,es-US, passed as `TEST_RUNNER_PLEZY_LANGUAGE`), else English: the labels the tests look for are English,
    /// and a simulator takes its languages from the Mac it runs on.
    static var languages: [String] {
        let environment = ProcessInfo.processInfo.environment["PLEZY_LANGUAGE"] ?? ""
        return environment.isEmpty ? ["en"] : environment.split(separator: ",").map(String.init)
    }

    /// Launches the app with `arguments` in `languages` (default: the run's, `Self.languages`), stopping the test at its
    /// first failure. On the Mac, AppKit would take unknown arguments' values for documents to open and open no window,
    /// and would restore the window as the last run left it, so each launch ignores the saved state and opens the window
    /// at `launchWindowFrame`, with no crash alert over it (`closeCrashAlerts`). With `PLEZY_MUTE=1` (passed as
    /// `TEST_RUNNER_PLEZY_MUTE` for a run on the Mac someone works at) the player starts muted (`-mpvMute YES`).
    func launch(_ arguments: [String], languages: [String]? = nil) {
        continueAfterFailure = false
        // The app starts with the languages as the system's, its region the first one's.
        let languages = languages ?? Self.languages
        var arguments = arguments + [
            "-AppleLanguages", "(\(languages.joined(separator: ",")))",
            "-AppleLocale", languages[0].replacingOccurrences(of: "-", with: "_"),
        ]
        if ProcessInfo.processInfo.environment["PLEZY_MUTE"] == "1" { arguments += ["-mpvMute", "YES"] }
        #if os(macOS)
        Self.closeCrashAlerts()
        app.launchArguments = [
            "-NSTreatUnknownArgumentsAsOpen", "NO", "-ApplePersistenceIgnoreState", "YES",
            "-NSWindow Frame main", Self.launchWindowFrame,
        ] + arguments
        #else
        app.launchArguments = arguments
        #endif
        #if os(iOS)
        let opensPlayer = arguments.contains("--dev-play") || arguments.contains("--url")
        waitForAnimations(!(UIDevice.current.userInterfaceIdiom == .pad && opensPlayer))
        #endif
        app.launch()
    }

    #if os(iOS)
    /// Whether XCTest waits for the app's animations to end before and after each action, besides its main run loop
    /// going idle (`XCUIApplication`'s private `idleAnimationWaitEnabled`, on by default). Off on iPad for a launch that
    /// opens the player as the session starts (`--dev-play`, `--url`): XCTest's first look at the app then falls while
    /// the player's cover comes up, and makes SwiftUI give each of the floating tab bar's tabs its accessibility label
    /// and identifier, for each of which the bar rebuilds its items with an animation. The cover, done meanwhile, takes
    /// the bar out of the window, and those animations never end: nothing moves and the app's main thread is idle, but
    /// XCTest counts them as running and waited 60 s for them before each action. A launch's tests wait for what they
    /// need themselves.
    private func waitForAnimations(_ wait: Bool) {
        let setter = NSSelectorFromString("setIdleAnimationWaitEnabled:")
        guard app.responds(to: setter) else {
            return fail("XCUIApplication has no idleAnimationWaitEnabled any more: iPad's player launches wait 60 s per action")
        }
        app.setValue(wait, forKey: "idleAnimationWaitEnabled")
    }
    #endif

    #if os(macOS)
    /// Closes the "quit unexpectedly" alerts on the Mac's screen: one that a crashed simulator app (another run's) or
    /// an earlier launch left would cover the window, taking the test's clicks and showing in its screenshots.
    /// UserNotificationCenter shows a simulator app's, Problem Reporter a Mac app's; launchd starts either again for
    /// the next alert.
    private static func closeCrashAlerts() {
        for id in ["com.apple.UserNotificationCenter", "com.apple.ProblemReporter"] {
            NSRunningApplication.runningApplications(withBundleIdentifier: id).forEach { $0.forceTerminate() }
        }
    }

    /// The window's frame at every launch: the app's size (1280×720, the scene's `defaultSize`) in the middle of the main
    /// display's area for windows. It is the window's saved frame as AppKit writes it (`NSWindow Frame main`, the
    /// window scene's id: x y width height from the display's bottom left, then the display without the menu bar), passed
    /// as an argument, which AppKit reads before the app's saved defaults.
    private static var launchWindowFrame: String {
        let screen = NSScreen.screens[0]
        let visible = screen.visibleFrame
        let display = screen.frame
        return "\(Int(visible.midX - 640)) \(Int(visible.midY - 360)) 1280 720 "
            + "\(Int(display.minX)) \(Int(display.minY)) \(Int(display.width)) \(Int(visible.maxY - display.minY))"
    }
    #endif

    #if os(macOS)
    /// Skips a test of the Mac's keyboard focus unless the system's keyboard navigation is on (System Settings ›
    /// Keyboard › Keyboard navigation, `defaults write -g AppleKeyboardUIMode -int 2`: Tab and the arrows reach every
    /// control). AppKit reads it from the user's global preferences alone, which a test's sandbox can't write.
    func requireKeyboardNavigation() throws {
        guard NSApplication.shared.isFullKeyboardAccessEnabled else {
            throw XCTSkip("the Mac's keyboard navigation is off (defaults write -g AppleKeyboardUIMode -int 2)")
        }
    }

    /// What has the keyboard's focus: its accessibility identifier, else its role (`AXWindow`), else `none`, as the app's
    /// debug probe reads it (`app.keyboardFocus`). XCUITest's `hasKeyboardFocus` can't tell on macOS 27: every row of
    /// the sidebar reports it whatever has focus, and a SwiftUI view made focusable (a card, the player's timeline)
    /// never does.
    var keyboardFocus: String {
        let probe = element("app.keyboardFocus")
        guard probe.exists, probe.label.hasPrefix("focus=") else { return "none" }
        return String(probe.label.dropFirst("focus=".count))
    }
    #endif

    /// The element with accessibility identifier `id`, of any type.
    func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Waits for `id` to exist; fails the test with `what` (and a screenshot and the element tree) when it doesn't.
    @discardableResult
    func require(_ id: String, timeout: TimeInterval = 20, _ what: String) -> XCUIElement {
        let found = element(id)
        if !found.exists(within: timeout) { fail("\(what): no \(id) after \(Int(timeout)) s") }
        return found
    }

    #if !os(tvOS)
    /// Taps (on the Mac clicks) a menu entry `target` once the menu has finished presenting: hittable with the same
    /// frame twice, half a second apart. A tap while the system menu still grows lands on no entry and leaves it open.
    func tapSettled(_ target: XCUIElement) {
        var last = CGRect.null
        let settled = waitUntil(10, every: 0.5) {
            let frame = target.frame
            defer { last = frame }
            return target.isHittable && frame == last
        }
        if !settled { fail("\(target.identifier) never settles hittable: \(target.frame)") }
        #if os(macOS)
        target.click()
        #else
        target.tap()
        #endif
    }
    #endif

    /// Closes the open sheet `sheet` as a user does: its Close (`closeId`) where it shows one (iPad, a full-height sheet,
    /// the Mac), else a drag down from its bar (an iPhone's resizable sheet, which has the grabber and no Close); the
    /// remote's Menu on Apple TV.
    func dismissSheet(_ sheet: XCUIElement, close closeId: String) {
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #else
        let close = element(closeId)
        if close.exists(within: 2), close.isHittable {
            #if os(macOS)
            close.click()
            #else
            close.tap()
            #endif
            return
        }
        #if os(iOS)
        // The sheet's content starts under its bar: 24 pt above it is the bar, which drags the sheet.
        let bar = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0)).withOffset(CGVector(dx: 0, dy: -24))
        bar.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        #else
        fail("the sheet \(sheet.identifier) shows no \(closeId)")
        #endif
        #endif
    }

    /// A screenshot of the app (or of `source`; on the Mac its window), kept in the result bundle as `NN name` (numbered
    /// in the order taken), and beside it the app's element tree as `NN name.tree.txt` (two shots' trees compare their
    /// controls). On iPhone and iPad a landscape screen comes from the simulator in its portrait
    /// pixels: the shot is turned to the device's orientation.
    func shot(_ name: String, of source: (any XCUIScreenshotProviding)? = nil) {
        shots += 1
        #if os(macOS)
        // The pointer off the window's buttons, whose hover popover (the green button's Move & Resize) would cover the
        // shot: parked at the window's foot, mid-width, over no control's chrome.
        if source == nil, app.windows.firstMatch.exists {
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.995)).hover()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let screenshot = (source ?? app.windows.firstMatch).screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        #elseif os(iOS)
        let attachment = XCTAttachment(image: Self.upright((source ?? XCUIScreen.main).screenshot().image))
        #else
        let attachment = XCTAttachment(screenshot: (source ?? app).screenshot())
        #endif
        attachment.name = String(format: "%02d %@", shots, name)
        attachment.lifetime = .keepAlways
        add(attachment)
        if app.state == .runningForeground {
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = String(format: "%02d %@.tree.txt", shots, name)
            tree.lifetime = .keepAlways
            add(tree)
        }
    }

    /// The open menu shot as `name`: on the Mac the screen (a menu is a window of its own, which may reach past the
    /// app's window, and the pointer stays where it is, off the menu's entries), elsewhere as `shot` takes it.
    func shotOfMenu(_ name: String) {
        #if os(macOS)
        shot(name, of: XCUIScreen.main)
        #else
        shot(name)
        #endif
    }

    #if os(iOS)
    /// `image` as the device shows it: a portrait-shaped capture of a landscape screen turned a quarter.
    private static func upright(_ image: UIImage) -> UIImage {
        let orientation = XCUIDevice.shared.orientation
        guard orientation.isLandscape, let cgImage = image.cgImage, cgImage.height > cgImage.width else { return image }
        // The capture is the landscape screen turned a quarter counterclockwise (landscape left) or clockwise.
        let turned = UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation == .landscapeLeft ? .left : .right)
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: turned.size, format: format).image { _ in turned.draw(at: .zero) }
    }
    #endif

    /// The system's back button of the page on top (`BackButton`): in its navigation bar, or in the column iOS 27.1
    /// lays along the screen's side (the iPhone Duo), where no navigation bar holds it.
    var backButton: XCUIElement { app.buttons.matching(identifier: "BackButton").firstMatch }

    /// The part of the window beside the tabs where they stand one under another along a side (the column iOS 27.1 lays
    /// along the iPhone Duo's screen, which the content runs under), else the whole window: where a drag or a tap
    /// reaches the content.
    var besideVerticalBar: CGRect {
        let window = app.windows.firstMatch.frame
        let home = element("nav.home").frame, settings = element("nav.settings").frame
        guard element("nav.home").exists, element("nav.settings").exists, abs(home.midX - settings.midX) < 1 else { return window }
        let bar = home.union(settings)
        return bar.midX > window.midX
            ? CGRect(x: window.minX, y: window.minY, width: bar.minX - window.minX, height: window.height)
            : CGRect(x: bar.maxX, y: window.minY, width: window.maxX - bar.maxX, height: window.height)
    }

    #if os(iOS)
    /// The top of the floating tab bar: its Home button's top edge.
    func tabBarTop() -> CGFloat {
        require("nav.home", "the tab bar").frame.minY
    }

    /// Skips unless the app lays its tabs out as a bar along the foot of the window (Home and Settings side by side in
    /// its lower half), the premise of the floating tab bar's checks: a vertical rail (iPhone Duo) has no foot to clear.
    func requireBottomTabBar() throws {
        let home = require("nav.home", "the tab bar").frame
        let settings = require("nav.settings", "the tab bar's Settings").frame
        let window = app.windows.firstMatch.frame
        if abs(home.midY - settings.midY) > home.height / 2 || home.midY < window.midY {
            throw XCTSkip("the tabs aren't a bar at the window's foot (Home at \(home), Settings at \(settings))")
        }
    }

    /// Drags along the window at height `y` (the window's points) from `from` to `to` of the width beside the vertical bar
    /// (`besideVerticalBar`): a row scrolled sideways, never a drag that starts on the bar. Held at its end, the row stops
    /// there; `fling` lets it run on.
    func dragSideways(atY y: CGFloat, from: CGFloat, to: CGFloat, fling: Bool = false) {
        let area = besideVerticalBar
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: area.minX + area.width * from, dy: y))
        let end = origin.withOffset(CGVector(dx: area.minX + area.width * to, dy: y))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: fling ? .fast : .default, thenHoldForDuration: fling ? 0 : 0.3)
    }

    /// Scrolls `container` to its end, then fails with `what` where a text of it lies under the floating tab bar: a
    /// screen's content ends clear of the bar. The swipes go to `container`: the app's own swipe misses the screen's
    /// scroll in landscape.
    func requireEndClearsTabBar(_ container: XCUIElement, _ what: String) {
        let window = app.windows.firstMatch.frame
        var last: [CGRect] = []
        for _ in 0..<20 {
            let frames = container.staticTexts.allElementsBoundByIndex.map(\.frame)
            if frames == last { break }
            last = frames
            container.swipeUp()
            // The swipe's momentum ends before the frames are compared again.
            Thread.sleep(forTimeInterval: 0.5)
        }
        let top = tabBarTop()
        let under = container.staticTexts.allElementsBoundByIndex.filter { text in
            let frame = text.frame
            return frame.minX < window.maxX && frame.maxX > window.minX && frame.maxY > top + 1 && frame.minY < window.maxY
        }
        if let text = under.first {
            fail("\(what): '\(text.label)' at \(text.frame) lies under the tab bar (its top at \(top)) at the end of the scroll")
        }
    }

    /// Scrolls `container` back to its top, then up until `target` lies wholly in the window above the floating tab
    /// bar, at most `limit` short drags, and returns it; fails with `what` where it never does.
    @discardableResult
    func scrollClearOfTabBar(_ target: XCUIElement, in container: XCUIElement, limit: Int = 12, _ what: String) -> XCUIElement {
        for _ in 0..<6 { container.swipeDown() }
        let window = app.windows.firstMatch.frame
        for _ in 0..<limit {
            let frame = target.frame
            if target.exists, frame.minY >= window.minY, frame.maxY <= tabBarTop() { return target }
            container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
                .press(forDuration: 0.05, thenDragTo: container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)))
            // The drag's scroll settles before the frame is read again.
            Thread.sleep(forTimeInterval: 0.5)
        }
        fail("\(what): \(target.identifier) at \(target.frame) never comes clear of the tab bar (its top at \(tabBarTop()))")
        return target
    }

    /// Fails with `what` unless the navigation bar is `height` tall (its height at the page's top) and shows no `title`:
    /// a detail page names itself in its hero, and its bar keeps one look at every scroll position, so nothing under it
    /// moves as the page scrolls. A window whose Back is in iOS 27.1's vertical bar (the iPhone Duo's) has no navigation
    /// bar to check.
    func requireSteadyBar(_ title: String, height: CGFloat, _ what: String) {
        let bar = app.navigationBars.firstMatch
        guard bar.exists else { return }
        if bar.staticTexts[title].exists { fail("\(what): the bar shows \(title)") }
        if abs(bar.frame.height - height) > 0.5 { fail("\(what): the bar is \(bar.frame.height) tall, not \(height)") }
    }

    /// From the page's top, drags the page until its hero title (`hero`) has just gone under the navigation bar and
    /// holds it there: `anchor` (an element under the hero) stays where the drag left it and the bar keeps its height
    /// and shows no `title` (`requireSteadyBar`). Returns the bar's height.
    @discardableResult
    func requireSteadyScroll(_ title: String, hero: XCUIElement, anchor: XCUIElement, _ what: String) -> CGFloat {
        let bar = app.navigationBars.firstMatch
        let height = bar.exists ? bar.frame.height : 0
        requireSteadyBar(title, height: height, "\(what) at its top")
        let distance = hero.frame.maxY - (bar.exists ? bar.frame.maxY : 0) + 24
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -distance)), withVelocity: .slow, thenHoldForDuration: 0.5)
        let settled = anchor.frame
        Thread.sleep(forTimeInterval: 1)
        if anchor.frame != settled { fail("\(what): the page moved from \(settled) to \(anchor.frame) past its title") }
        requireSteadyBar(title, height: height, "\(what) past its title")
        return height
    }
    #endif

    /// Every button and menu VoiceOver reaches in `container` (itself where it is one) has a name it reads: letters or
    /// digits, not "button". VoiceOver reads a button as one element, so what XCUITest lists inside one (iOS draws a
    /// `Menu` as a named button around an unnamed one) is part of it, not a button of its own. On iOS the system's
    /// accessibility audit also finds no element without a description on the screen.
    func requireSpokenNames(in container: XCUIElement, _ what: String) {
        #if os(iOS)
        var issues: [String] = []
        do {
            try app.performAccessibilityAudit(for: .sufficientElementDescription) { issue in
                issues.append("\(issue.compactDescription): id '\(issue.element?.identifier ?? "")' at \(issue.element?.frame ?? .zero)")
                return true
            }
        } catch {
            return fail("\(what): the accessibility audit failed: \(error)")
        }
        if !issues.isEmpty { return fail("\(what): \(issues.joined(separator: "; "))") }
        #endif
        guard let root = try? container.snapshot() else { return fail("\(what): no \(container.identifier) to read") }
        var buttons: [any XCUIElementSnapshot] = []
        func collect(_ node: any XCUIElementSnapshot) {
            if node.elementType == .button || node.elementType == .menuButton {
                buttons.append(node)
            } else {
                node.children.forEach(collect)
            }
        }
        collect(root)
        if buttons.isEmpty { return fail("\(what): no buttons") }
        for button in buttons where !button.label.contains(where: { $0.isLetter || $0.isNumber }) || button.label.lowercased() == "button" {
            return fail("\(what): a button VoiceOver can't name: id '\(button.identifier)', label '\(button.label)' at \(button.frame)")
        }
    }

    #if os(tvOS)
    /// Checks that the focused `element`'s title keeps its glyphs apart from the platter under them: at least a
    /// hundredth of the title's pixels differ from its background by a third of the luminance range (white on white:
    /// none; a short code in dark type: some 3 %). The title is the element's first text, else (a button whose text is
    /// its label) the middle of the element itself, away from its corners and whatever shows around its platter.
    func requireReadable(_ element: XCUIElement, _ what: String) {
        let frame = element.frame
        let texts = app.staticTexts.allElementsBoundByIndex.filter { !$0.label.isEmpty && frame.contains($0.frame) }
        let title = texts.min(by: { ($0.frame.minY, $0.frame.minX) < ($1.frame.minY, $1.frame.minX) })
        guard var image = (title ?? element).screenshot().image.cgImage else { return fail("\(what): no screenshot") }
        if title == nil {
            let middle = CGRect(x: image.width / 4, y: image.height / 4, width: image.width / 2, height: image.height / 2)
            image = image.cropping(to: middle) ?? image
        }
        let pixels = Self.luminances(of: image)
        var counts = [Int](repeating: 0, count: 256)
        for pixel in pixels { counts[Int(pixel)] += 1 }
        let background = counts.indices.max { counts[$0] < counts[$1] } ?? 0
        let share = Double(pixels.reduce(0) { $0 + (abs(Int($1) - background) > 85 ? 1 : 0) }) / Double(max(pixels.count, 1))
        XCTAssertGreaterThan(share, 0.01, "\(what)'s title \"\((title ?? element).label)\" readable focused: \(share) of its pixels stand out")
    }

    /// Fails unless focus shows on `focused`, which holds it, beside `resting`, a control of its kind without focus:
    /// their pixels' mean luminances lie at least a quarter of the range apart, as a control the focus turns white
    /// gives (a focus drawn only as a lift and a dark shadow, on a dark screen, moved it by a few hundredths).
    func requireFocusShows(on focused: XCUIElement, beside resting: XCUIElement, _ what: String) {
        guard focused.exists, resting.exists else { return fail("\(what): no element to compare") }
        // The focus look's animation ends first.
        Thread.sleep(forTimeInterval: 0.5)
        let lit = Self.meanLuminance(of: focused), unlit = Self.meanLuminance(of: resting)
        XCTAssertGreaterThan(abs(lit - unlit), 0.25, "\(what) shows its focus: mean luminance \(lit) focused, \(unlit) without")
    }

    /// The mean luminance of `element`'s pixels, 0 (black) to 1 (white).
    private static func meanLuminance(of element: XCUIElement) -> Double {
        guard let image = element.screenshot().image.cgImage else { return 0 }
        let pixels = luminances(of: image)
        return Double(pixels.reduce(0) { $0 + Int($1) }) / Double(max(pixels.count, 1) * 255)
    }

    /// `image`'s pixels' luminances, 0 to 255.
    private static func luminances(of image: CGImage) -> [UInt8] {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return [] }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }
    #endif

    /// In `place` of the window's shot, the contrast ratio (WCAG's, of relative luminances) of the pixel standing out
    /// most from the place's ground (its most common luminance), kept as `<what> contrast`; nil, failed, without a shot.
    func contrast(in place: CGRect, _ what: String) -> Double? {
        guard let values = luminances(in: place, what) else { return nil }
        var counts = [Int](repeating: 0, count: 256)
        for value in values { counts[Int((value * 255).rounded())] += 1 }
        let ground = Double(counts.indices.max { counts[$0] < counts[$1] } ?? 0) / 255
        let ratio = values.map { (max($0, ground) + 0.05) / (min($0, ground) + 0.05) }.max() ?? 1
        keep(ratio, ground: ground, what)
        return ratio
    }

    /// `ratio` and the `ground` it was taken against, kept as `<what> contrast`.
    func keep(_ ratio: Double, ground: Double, _ what: String) {
        let note = XCTAttachment(string: String(format: "%.2f:1 (ground %.4f)", ratio, ground))
        note.name = "\(what) contrast"
        note.lifetime = .keepAlways
        add(note)
    }

    /// The relative luminances of `place` in the window's shot; nil, failed, without one. The window is the first with a
    /// frame: an iPad can list an empty one first.
    func luminances(in place: CGRect, _ what: String) -> [Double]? {
        let window = app.windows.allElementsBoundByIndex.first { !$0.frame.isEmpty } ?? app.windows.firstMatch
        #if os(macOS)
        let screenshot = window.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        let screenshot = window.screenshot().image.cgImage
        #endif
        guard let image = screenshot else {
            fail("no shot of the \(what)")
            return nil
        }
        let scale = CGFloat(image.width) / window.frame.width
        let pixels = place.offsetBy(dx: -window.frame.minX, dy: -window.frame.minY)
            .applying(CGAffineTransform(scaleX: scale, y: scale)).integral
        guard let crop = image.cropping(to: pixels) else {
            fail("the \(what)'s place \(place) is off the window")
            return nil
        }
        return Self.relativeLuminances(of: crop)
    }

    /// `image`'s pixels' relative luminances (WCAG's, from sRGB), 0 (black) to 1 (white).
    private static func relativeLuminances(of image: CGImage) -> [Double] {
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        func linear(_ byte: UInt8) -> Double {
            let value = Double(byte) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return stride(from: 0, to: bytes.count, by: 4).map {
            0.2126 * linear(bytes[$0]) + 0.7152 * linear(bytes[$0 + 1]) + 0.0722 * linear(bytes[$0 + 2])
        }
    }

    /// Fails the test with `message`, keeping a screenshot and the app's element tree for the run's report.
    func fail(_ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "element tree"
        tree.lifetime = .keepAlways
        add(tree)
        shot("failure")
        XCTFail(message, file: file, line: line)
    }
}

/// Whether `condition` holds within `timeout` seconds, looked at every `interval` seconds and once more at the end.
@MainActor
func waitUntil(_ timeout: TimeInterval, every interval: TimeInterval = 0.25, _ condition: () -> Bool) -> Bool {
    let end = Date().addingTimeInterval(timeout)
    while Date() < end {
        if condition() { return true }
        Thread.sleep(forTimeInterval: interval)
    }
    return condition()
}

@MainActor
extension XCUIElement {
    /// Whether the element exists now or comes within `timeout`. XCUITest's `waitForExistence` looks first a second
    /// after it starts, even for an element already there; `exists` answers at once, so the wait starts only for an
    /// element that isn't there yet. Use this, not `waitForExistence`.
    func exists(within timeout: TimeInterval) -> Bool {
        exists || waitForExistence(timeout: timeout)
    }
}
