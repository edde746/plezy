#if os(iOS)
import UIKit
#endif
import XCTest

/// Casting from this device (the sender) on iPhone, iPad, Apple TV and the Mac, in a `--dev` session signed into the
/// test Jellyfin with the development receiver "Demo TV" running in the app (`cast.demo=receiver`: it is found on the
/// network, asks for pairing and allows it 5 s later, then plays "Demo Movie" for what is cast and answers every
/// control). A movie's cast button opens the picker (This device checked, then Demo TV), choosing Demo TV shows the
/// pairing code until it allows, then the picker closes and the cast bar shows "Ready to cast" (Apple TV: the Casting
/// tab); Play then plays on Demo TV, the bar opens the controls, whose Stop leaves Demo TV named over "Ready to cast"
/// and whose Disconnect ends it. Cancel during pairing closes the picker and keeps This device.
final class CastSenderTests: CastTestCase {
    func testPickPairAndControl() {
        openMovie(settings: ["cast.demo=receiver"])
        let button = require("detail.castTo", timeout: 30, "the cast button beside Play")
        XCTAssertFalse(button.isSelected, "the cast button isn't active before casting")
        shot("cast button")
        activate("detail.castTo", from: "detail.play", moving: .right, "the cast button")
        require("cast.picker.thisDevice", timeout: 10, "the cast button opens the device picker")
        XCTAssertEqual(element("cast.picker.thisDevice").value as? String, "selected", "This device carries the check")
        shot("picker searching")
        let demo = demoRow()
        if !demo.exists(within: 30) { fail("the picker lists no Demo TV within 30 s") }
        shot("picker")
        activate(demo.identifier, from: "cast.picker.thisDevice", moving: .down, "Demo TV")
        let code = require("cast.pairing.code", timeout: 15, "choosing Demo TV shows the pairing code")
        requireCode(code)
        require("cast.pairing.cancel", "the pairing's Cancel")
        shot("pairing")
        // Demo TV allows it after 5 s: the picker closes by itself and the bar shows. (Apple TV's panel doesn't name
        // the pairing view to accessibility: the rows and the code tell what shows.)
        if !waitUntil(20, { !self.pickerShows() }) { fail("the picker stays up after Demo TV allowed this device") }
        let casting = require("detail.castTo", "the cast button while casting")
        let active = waitUntil(10) { casting.isSelected || (casting.value as? String ?? "").contains("Demo TV") }
        XCTAssertTrue(active, "the cast button shows it casts: \(casting.debugDescription)")
        #if !os(tvOS)
        let bar = require("cast.bar", timeout: 15, "the cast bar once Demo TV is the target")
        XCTAssertTrue(element("cast.bar.open").label.contains("Demo TV"), "the bar names Demo TV: \(element("cast.bar.open").label)")
        shot("bar ready")
        #endif
        // Play now plays on Demo TV.
        activate("detail.play", moving: .left, "the movie's Play")
        #if os(tvOS)
        openCastingTab()
        shot("casting tab")
        #else
        require("cast.bar.playPause", timeout: 20, "the bar's Play/Pause once Demo TV plays")
        XCTAssertTrue(element("cast.bar.open").label.contains("Demo Movie"), "the bar shows Demo Movie: \(bar.label)")
        shot("bar")
        activate("cast.bar.open", "the bar")
        require("cast.controls", timeout: 10, "the bar opens the controls")
        #endif
        for id in ["previous", "seekBack", "playPause", "seekForward", "next", "seek"] {
            require("cast.controls.\(id)", timeout: 10, "the controls' \(id)")
        }
        shot("controls")
        let playPause = element("cast.controls.playPause")
        let before = playPause.label
        activate("cast.controls.playPause", moving: .right, "Play/Pause")
        if !waitUntil(10, { playPause.label != before }) { fail("Play/Pause still reads \(before): Demo TV didn't answer") }
        for id in ["audio", "subtitles", "quality", "volume", "stop", "disconnect"] {
            reveal("cast.controls.\(id)", "the controls' \(id)")
        }
        shot("controls tracks and volume")
        #if !os(tvOS)
        // Demo TV applies a track or volume picked here and reports it back: the controls show what it plays now.
        pick("Commentary", in: "cast.controls.audio", "the audio")
        pick("English", in: "cast.controls.subtitles", "the subtitles")
        let volume = element("cast.controls.volume")
        volume.adjust(toNormalizedSliderPosition: 0.3)
        _ = waitUntil(5) { (Int(Self.value(volume)) ?? 100) < 60 }
        shot("controls tracks and volume changed")
        // What the slider shows once the controls open again is Demo TV's volume, not the drag's.
        reopenControls()
        reveal("cast.controls.volume", "the controls' volume")
        if !waitUntil(10, { (Int(Self.value(volume)) ?? 100) < 60 }) { fail("Demo TV's volume stays at \(Self.value(volume))") }
        XCTAssertTrue(Self.value(element("cast.controls.audio")).contains("Commentary"), "Demo TV keeps Commentary")
        #endif
        // Stop ends what plays and keeps Demo TV: the controls name it over "Ready to cast", no longer "Casting to" it.
        reveal("cast.controls.stop", "Stop")
        activate("cast.controls.stop", "Stop")
        #if !os(tvOS)
        // The controls close as what played ends, the bar naming Demo TV; the bar opens them again.
        if !waitUntil(15, { !self.element("cast.bar.playPause").exists }) { fail("the bar still plays after Stop") }
        XCTAssertTrue(element("cast.bar.open").label.contains("Demo TV"), "the bar names Demo TV after Stop: \(element("cast.bar.open").label)")
        // The ending's notice sits in a band of its own above the bar, never over the bar's text.
        let notice = element("cast.notice")
        if notice.exists(within: 3) {
            let barFrame = element("cast.bar").frame
            XCTAssertFalse(notice.frame.intersects(barFrame), "the notice \(notice.frame) lies over the cast bar \(barFrame)")
        }
        shot("bar stopped")
        checkPageEndClearsBar()
        if !element("cast.controls").exists(within: 2) {
            activate("cast.bar.open", "the bar")
            require("cast.controls", timeout: 10, "the bar opens the controls with nothing playing")
        }
        #endif
        // A Mac's text reports its words as its value.
        let says = { (text: XCUIElement) in text.label.isEmpty ? text.value as? String ?? "" : text.label }
        let title = require("cast.controls.title", timeout: 10, "the controls' title after Stop")
        if !waitUntil(10, { says(title) == "Demo TV" }) { fail("after Stop the controls' title reads \(says(title)), not Demo TV") }
        XCTAssertEqual(says(element("cast.controls.target")), "Ready to cast", "after Stop the line under Demo TV")
        shot("controls stopped")
        reveal("cast.controls.disconnect", "Disconnect")
        activate("cast.controls.disconnect", "Disconnect")
        #if os(tvOS)
        if !waitUntil(10, { !self.element("nav.casting").exists }) { fail("the Casting tab stays after Disconnect") }
        #else
        if !waitUntil(10, { !self.element("cast.bar").exists }) { fail("the cast bar stays after Disconnect") }
        #endif
        shot("disconnected")
    }

    func testCancelPairingKeepsThisDevice() {
        openMovie(settings: ["cast.demo=receiver"])
        activate("detail.castTo", from: "detail.play", moving: .right, "the cast button")
        let demo = demoRow()
        if !demo.exists(within: 30) { fail("the picker lists no Demo TV within 30 s") }
        activate(demo.identifier, from: "cast.picker.thisDevice", moving: .down, "Demo TV")
        require("cast.pairing.code", timeout: 15, "the pairing code")
        activate("cast.pairing.cancel", "the pairing's Cancel")
        if !waitUntil(10, { !self.pickerShows() }) { fail("Cancel leaves the picker up") }
        // Past Demo TV's 5 s: the cancelled pairing never connects.
        Thread.sleep(forTimeInterval: 7)
        XCTAssertFalse(element("cast.bar").exists || element("nav.casting").exists, "no cast after a cancelled pairing")
        XCTAssertFalse(element("detail.castTo").isSelected, "the cast button stays inactive")
        shot("pairing cancelled")
    }

    #if !os(tvOS)
    /// Scrolled to its end, the movie's page stops above the cast bar: its last row (a related shelf, the cast or the
    /// information) ends over the bar's top, none of it left under the bar.
    private func checkPageEndClearsBar() {
        let page = require("detail.screen", "the movie's page")
        for _ in 0..<6 {
            #if os(macOS)
            page.scroll(byDeltaX: 0, deltaY: -600)
            #else
            page.swipeUp()
            #endif
        }
        // Lets the swipes' momentum settle: no element signals the page has stopped moving.
        Thread.sleep(forTimeInterval: 1.5)
        let rows = page.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.' OR identifier IN {'detail.cast', 'detail.info', 'detail.extras'}"))
            .allElementsBoundByIndex.filter { $0.exists && !$0.frame.isEmpty }
        shot("page end over the bar")
        guard let last = rows.max(by: { $0.frame.maxY < $1.frame.maxY }) else {
            return fail("the movie's page shows no related shelf, cast or information")
        }
        let bar = element("cast.bar").frame
        XCTAssertLessThanOrEqual(last.frame.maxY, bar.minY + 1, "the page's last row \(last.identifier) \(last.frame) runs under the cast bar \(bar)")
    }

    /// Picks `option` from the controls' menu `id` (a pop-up button on the Mac, a menu on iPhone and iPad) and waits for
    /// Demo TV's report to show it picked.
    private func pick(_ option: String, in id: String, _ what: String) {
        let menu = require(id, what)
        #if os(macOS)
        menu.click()
        let item = app.menuItems[option].firstMatch
        if !item.exists(within: 5) { fail("\(what) offers no \(option)") }
        item.click()
        #else
        menu.tap()
        let item = app.buttons[option].firstMatch
        if !item.exists(within: 5) { fail("\(what) offers no \(option)") }
        item.tap()
        #endif
        if !waitUntil(10, { Self.value(menu).contains(option) }) { fail("Demo TV's \(what) stays at \(Self.value(menu))") }
    }

    /// Closes the controls and opens them again from the bar.
    private func reopenControls() {
        let controls = element("cast.controls")
        let close = element("cast.controls.close")
        #if os(macOS)
        close.click()
        #else
        if close.exists && close.isHittable {
            close.tap()
        } else {
            // iPhone's sheet has no Close: pulled down by its top edge.
            let top = controls.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0)).withOffset(CGVector(dx: 0, dy: 8))
            top.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        }
        #endif
        if !waitUntil(10, { !controls.exists }) { fail("the controls stay up") }
        activate("cast.bar.open", "the bar")
        require("cast.controls", timeout: 10, "the bar opens the controls again")
    }

    /// What a control reads: its value (a menu's pick, a slider's level: a number on the Mac), else its label.
    private static func value(_ element: XCUIElement) -> String {
        guard element.exists else { return "" }
        let value = (element.value as? NSNumber).map { "\($0.intValue)" } ?? element.value as? String ?? ""
        return value.isEmpty ? element.label : value
    }
    #endif

    /// The picker's row of Demo TV.
    private func demoRow() -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'cast.picker.device.' AND label CONTAINS 'Demo TV'")).firstMatch
    }

    /// The picker or its pairing code shows.
    private func pickerShows() -> Bool {
        element("cast.picker.thisDevice").exists || element("cast.pairing.code").exists
    }

    #if os(tvOS)
    /// Back to the tab bar (Menu until a tab has focus: one more would leave the app), then along it to the Casting tab,
    /// whose page holds the controls.
    private func openCastingTab() {
        for _ in 0..<4 where !(focused.exists && focused.identifier.hasPrefix("nav.")) {
            press(.menu)
            _ = waitUntil(1.5) { self.focused.exists && self.focused.identifier.hasPrefix("nav.") }
        }
        for _ in 0..<10 where !focusIs("nav.casting") {
            press(.right)
        }
        if !focusIs("nav.casting") { fail("the tab bar has no Casting tab") }
        press(.down)
        require("cast.tab", timeout: 10, "the Casting tab's page")
    }
    #endif
}

/// This device as a receiver on iPhone, iPad, Apple TV and the Mac, with the development sender "Demo Phone" in the app
/// (`cast.demo=sender`: it connects 3 s after the start, or with `--dev-play` 12 s after that item started playing here,
/// and once allowed casts that item here). Its pairing question shows over the app (Apple TV: Allow focused first) and
/// over the player; Allow takes the cast, whose
/// player says "Casting from Demo Phone"; Don't Allow refuses.
final class CastReceiverTests: CastTestCase {
    func testPromptAllowsAndDenies() {
        launchDev(settings: ["cast.demo=sender"], arguments: ["--dev-open", "settings"])
        requirePrompt()
        shot("receiver prompt")
        activate("cast.prompt.deny", moving: .left, "Don't Allow")
        if !waitUntil(10, { !self.element("cast.prompt.allow").exists }) { fail("Don't Allow leaves the question up") }
        shot("refused")
    }

    func testPromptOverThePlayerAndCastingFrom() {
        launchDev(settings: ["cast.demo=sender"], arguments: ["--dev-server", Self.server, "--dev-play", Self.play])
        require("player.video", timeout: 90, "the player")
        requirePrompt()
        shot("receiver prompt over the player")
        activate("cast.prompt.allow", "Allow")
        if !waitUntil(10, { !self.element("cast.prompt.allow").exists }) { fail("Allow leaves the question up") }
        require("player.video", timeout: 60, "the cast's player")
        let line = element("player.castingFrom")
        // The line is in the controls: brought up whenever they are down (a tap while they show would hide them).
        _ = waitUntil(30) {
            if line.exists { return true }
            if !self.element("player.title").exists { self.showControls() }
            _ = waitUntil(1) { line.exists }
            return line.exists
        }
        if !line.exists { fail("the player shows no Casting from line") }
        // A Mac's text reads as its value, elsewhere as its label.
        let text = line.label.isEmpty ? (line.value as? String ?? "") : line.label
        XCTAssertTrue(text.contains("Demo Phone"), "the line names Demo Phone: \(text)")
        shot("casting from")
    }

    /// The question with its 4-digit code, whole on screen (inset from its edges off Apple TV); on Apple TV Allow has
    /// focus first.
    private func requirePrompt() {
        let code = require("cast.prompt.code", timeout: 45, "Demo Phone's pairing question")
        requireCode(code)
        let allow = require("cast.prompt.allow", "Allow")
        let deny = require("cast.prompt.deny", "Don't Allow")
        #if os(macOS)
        let screen = app.windows.firstMatch.frame
        #else
        let screen = app.frame
        #endif
        #if os(tvOS)
        let inset: CGFloat = 0
        #else
        let inset: CGFloat = 8
        #endif
        let room = screen.insetBy(dx: inset, dy: inset)
        // Apple TV's panel names the question by the panel, not its card: its buttons tell where it is there.
        let parts = [(element("cast.prompt"), "The question's card"), (deny, "Don't Allow"), (allow, "Allow")].filter { $0.0.exists }
        for (part, name) in parts where !room.contains(part.frame) {
            fail("\(name) at \(part.frame) runs past the screen's edges \(screen)")
        }
        #if os(tvOS)
        requireFocus("cast.prompt.allow", "Allow has focus first")
        #endif
    }

    /// Brings the player's controls up: a tap on the video, a click on the Mac, Select on Apple TV's remote.
    private func showControls() {
        #if os(tvOS)
        press(.select)
        #elseif os(macOS)
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).hover()
        #else
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        #endif
    }
}

/// What the cast tests share: the test server, opening a movie's detail from Search, pressing a control the way the
/// platform does (a tap, a click, the remote's focus and Select) and waiting.
class CastTestCase: PlezyUITestCase {
    /// Which way the remote moves focus towards a control (`activate`); unused off Apple TV.
    enum Move { case right, left, down }

    static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        guard value.isEmpty else { return value }
        #if os(macOS)
        return "jellyfin=maestro:maestro@http://127.0.0.1:28096"
        #else
        return "jellyfin=maestro:maestro@http://192.168.0.15:28096"
        #endif
    }

    /// Maestro Episode 2, whose watch state goes back as it was when the class ends (`launchDev`).
    static var play: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_DEV_PLAY"] ?? ""
        return value.isEmpty ? "jellyfin:b18dffe6dedf0bd83157a3f2fa0da3fe" : value
    }

    /// Starts on Search with `settings`, types Maestro Movie and opens its detail.
    func openMovie(settings: [String]) {
        let title = "Maestro Movie"
        launchDev(settings: settings, arguments: ["--dev-open", "search", "--dev-server", Self.server])
        require("search.screen", timeout: 90, "the Search screen")
        type(title)
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == %@", title)).firstMatch
        if !result.exists(within: 30) { fail("typing \(title) lists no \(title)") }
        _ = waitUntil(5) { result.isHittable }
        #if os(tvOS)
        for _ in 0..<8 where focused.label != title { press(.down) }
        if focused.label != title { fail("Down reaches no \(title)") }
        press(.select)
        #elseif os(macOS)
        result.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        result.tap()
        #endif
        let play = require("detail.play", timeout: 30, "\(title)'s Play")
        _ = waitUntil(5) { play.isHittable }
    }

    /// Presses the control `id`: a tap or click; on Apple TV focus moved onto it (from `start` by `moving`, where given)
    /// and Select.
    func activate(_ id: String, from start: String? = nil, moving: Move = .down, _ what: String) {
        let target = require(id, timeout: 10, what)
        #if os(tvOS)
        if !focusIs(id) {
            if let start { requireFocus(start, "focus on \(start) before \(what)") }
            for _ in 0..<10 where !focusIs(id) {
                press(moving == .right ? .right : moving == .left ? .left : .down)
                _ = waitUntil(1.5) { focusIs(id) }
            }
        }
        if !focusIs(id) { fail("focus doesn't reach \(what)") }
        press(.select)
        _ = target
        #elseif os(macOS)
        target.click()
        #else
        target.tap()
        #endif
    }

    /// Brings the control `id` of a long form into view: the form scrolled up (on iPhone the sheet pulled up first), on
    /// Apple TV focus moved down to it.
    func reveal(_ id: String, _ what: String) {
        let target = element(id)
        for _ in 0..<8 where !(target.exists && target.isHittable) {
            #if os(tvOS)
            press(.down)
            #elseif os(macOS)
            element("cast.controls").scroll(byDeltaX: 0, deltaY: -200)
            Thread.sleep(forTimeInterval: 0.5)
            #else
            element("cast.controls").swipeUp()
            _ = waitUntil(0.5) { target.exists && target.isHittable }
            #endif
        }
        if !target.exists { fail("\(what): no \(id) in the form") }
    }

    /// A pairing code's text (a Mac's static text reports it as its value) is four digits.
    func requireCode(_ code: XCUIElement) {
        let text = code.label.isEmpty ? (code.value as? String ?? "") : code.label
        XCTAssertNotNil(text.range(of: "^[0-9]{4}$", options: .regularExpression), "a 4-digit code, not \(text)")
    }

    /// Types `text` into Search's field (on Apple TV through the system's search keyboard).
    private func type(_ text: String) {
        #if os(tvOS)
        let field = app.searchFields.firstMatch
        if !field.exists(within: 10) { fail("Search shows no search field") }
        let keyboardFocus = app.descendants(matching: .any).matching(NSPredicate(format: "hasKeyboardFocus == 1"))
        for _ in 0..<3 where keyboardFocus.count == 0 {
            press(.down)
            _ = waitUntil(3) { keyboardFocus.count > 0 }
        }
        if keyboardFocus.count == 0 { fail("Down from the search field reaches no keyboard") }
        field.typeText(text)
        #else
        let field = require("search.field", "the search field")
        #if os(macOS)
        field.click()
        #else
        let hasFocus = { field.value(forKey: "hasKeyboardFocus") as? Bool == true }
        for _ in 0..<3 where !hasFocus() {
            field.tap()
            _ = waitUntil(3, hasFocus)
        }
        if !hasFocus() { fail("the search field doesn't take the keyboard focus") }
        if UIDevice.current.userInterfaceIdiom == .pad {
            // The iPad simulator ends the app when typeText switches to the hardware keyboard: the software keys.
            for character in text.lowercased() {
                let name = character == " " ? "space" : String(character)
                let key = app.keyboards.keys.matching(NSPredicate(format: "label ==[c] %@ OR identifier ==[c] %@", name, name)).firstMatch
                if !key.exists(within: 5) { fail("the keyboard has no \(character) key") }
                key.tap()
            }
            return
        }
        #endif
        field.typeText(text)
        #endif
    }

    #if os(tvOS)
    func press(_ button: XCUIRemote.Button) {
        XCUIRemote.shared.press(button)
        // Paces presses: the focus engine drops or coalesces presses that come too close together.
        Thread.sleep(forTimeInterval: 0.6)
    }

    var focused: XCUIElement {
        app.descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
    }

    func focusIs(_ id: String) -> Bool {
        guard focused.exists else { return false }
        if focused.identifier == id { return true }
        let element = app.descendants(matching: .any).matching(identifier: id).firstMatch
        guard focused.identifier.isEmpty, element.exists else { return false }
        // A focused list row reports its cell, a little larger than the row's button, or the button inside it.
        return element.frame.insetBy(dx: -4, dy: -4).contains(focused.frame) || focused.frame.insetBy(dx: -24, dy: -24).contains(element.frame)
    }

    func requireFocus(_ id: String, timeout: TimeInterval = 20, _ what: String) {
        if waitUntil(timeout, every: 0.5, { self.focusIs(id) }) { return }
        fail("\(what): focus is on \(focused.exists ? focused.identifier : "nothing"), not \(id)")
    }
    #endif
}
