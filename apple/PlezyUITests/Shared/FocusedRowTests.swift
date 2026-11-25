#if os(tvOS)
import XCTest

/// Apple TV controls that turn white with focus (the system's button style, the app's focused surface): each one's
/// title stays readable while it has focus, dark on the white platter rather than the theme's white text or accent
/// vanishing into it. The metadata editor's rows (a text field's, an artwork field's) and its tag sheet's tags need
/// `PLEZY_DEV_SERVER` and `PLEZY_DEV_EDIT` (an item with a genre); a recent room needs `PLEZY_WATCH_RELAY`; an album's
/// artist link and a library's alphabet index need `PLEZY_DEV_SERVER` (the test server's Sine Album, its Movies).
final class FocusedRowTests: PlezyUITestCase {
    private static let environment = ProcessInfo.processInfo.environment

    private lazy var steps = LibrarySteps(test: self)

    func testMetadataEditorRowsStayReadableFocused() throws {
        guard let server = Self.value("PLEZY_DEV_SERVER"), let edit = Self.value("PLEZY_DEV_EDIT") else {
            throw XCTSkip("needs PLEZY_DEV_SERVER and PLEZY_DEV_EDIT")
        }
        launchDev(arguments: ["--dev-server", server, "--dev-edit", edit])
        let title = require("metadata.field.title", timeout: 90, "once the item's editor loads")
        // Every row is checked, not only the first unreadable one.
        continueAfterFailure = true
        requireReadableFocused(title, "the Title row")

        // Rows further down exist once scrolled to: looked up as focus reaches them.
        let genre = element("metadata.field.genre")
        focus(genre, "the Genre row")
        XCUIRemote.shared.press(.select)
        require("metadata.tags.field", timeout: 10, "the Genre tag sheet")
        requireReadableFocused(require("metadata.tags.tag.0", "the item's first genre"), "a genre in the tag sheet")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(genre.waitForExistence(timeout: 10), "Menu returns to the editor")

        requireReadableFocused(element("metadata.field.artwork:Primary"), "the Poster row")
    }

    func testRecentRoomStaysReadableFocused() throws {
        guard let relay = Self.value("PLEZY_WATCH_RELAY") else { throw XCTSkip("needs PLEZY_WATCH_RELAY") }
        let code = String((0..<6).map { _ in Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789").randomElement()! })
        launchDev(settings: ["watch_party_relay_url=\(relay)"], arguments: ["--dev-watch-room", code])
        require("watch.code", timeout: 60, "the room's code")
        // Out of the code's card, which opens focused left of the room's form, into the form.
        // The focus engine drops a press made while the screen still settles.
        Thread.sleep(forTimeInterval: 1)
        XCUIRemote.shared.press(.right)
        let leave = require("watch.leave", "Leave Room")
        focus(leave, "Leave Room")
        XCUIRemote.shared.press(.select)
        let confirm = require("watch.leave.confirm", timeout: 10, "Leave's question")
        // The question opens on Cancel, Leave beside it.
        // The question takes no press while it still animates in.
        Thread.sleep(forTimeInterval: 1)
        XCUIRemote.shared.press(.right)
        focus(confirm, "Leave's confirmation")
        XCUIRemote.shared.press(.select)
        requireReadableFocused(require("watch.recent.\(code)", timeout: 20, "the room under Recent Rooms"), "a recent room")
    }

    func testAlbumArtistLinkStaysReadableFocused() throws {
        guard let server = Self.value("PLEZY_DEV_SERVER") else { throw XCTSkip("needs PLEZY_DEV_SERVER") }
        launchDev(arguments: ["--dev-server", server, "--dev-open-music", "album=Sine Album"])
        requireReadableFocused(require("music.header.artist", timeout: 90, "the album's artist link"), "the album's artist link")
        // At rest, focus moved down to the actions: the link's words where they were focused.
        XCUIRemote.shared.press(.down)
        // Lets focus's lift animation finish before the shot.
        Thread.sleep(forTimeInterval: 1.5)
        shot("the album's artist link at rest")
    }

    /// The letter focus enters the index on, none of them current while no letter narrows the grid.
    func testAlphabetLetterStaysReadableFocused() throws {
        guard let server = Self.value("PLEZY_DEV_SERVER") else { throw XCTSkip("needs PLEZY_DEV_SERVER") }
        launchDev(arguments: ["--dev-server", server, "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        require("libraries.alpha.Z", timeout: 30, "the alphabet index")
        steps.tvFocus([(.down, 2), (.right, 12)]) { steps.focused(prefix: "libraries.alpha.") }
        // Lets the focused platter finish animating before the shot and the colour check.
        Thread.sleep(forTimeInterval: 1)
        let letter = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'libraries.alpha.'")).firstMatch
        shot("alphabet letter focused")
        requireReadable(letter, "the focused letter \(letter.label)")
    }

    /// A library's alphabet index shows focused, applied and both apart: focus coming onto the index applies nothing,
    /// the focused letter dark on its platter; Down to Z applies it, still focused, dark on the platter in a ring; Left
    /// to the grid leaves Z applied, on a round tint.
    func testAlphabetFocusedAndAppliedReadApart() throws {
        guard let server = Self.value("PLEZY_DEV_SERVER") else { throw XCTSkip("needs PLEZY_DEV_SERVER") }
        launchDev(arguments: ["--dev-server", server, "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        let z = require("libraries.alpha.Z", timeout: 30, "the alphabet index")
        steps.tvFocus([(.down, 2), (.right, 12)]) { steps.focused(prefix: "libraries.alpha.") }
        // Gives a stray apply time to show before checking nothing is applied.
        Thread.sleep(forTimeInterval: 1)
        let focused = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasFocus == true AND identifier BEGINSWITH 'libraries.alpha.'")).firstMatch
        XCTAssertFalse(focused.isSelected, "focus onto the index applies nothing")
        shot("alphabet focused")
        requireReadable(focused, "the focused letter \(focused.label)")
        steps.tvFocus([(.down, 30)]) { z.hasFocus }
        XCTAssertTrue(steps.card(prefix: "Zulu").exists(within: 15), "Z applied")
        _ = waitUntil(5) { z.hasFocus && z.isSelected }
        XCTAssertTrue(z.hasFocus && z.isSelected, "Z focused and applied")
        shot("alphabet focused and applied")
        requireReadable(z, "the focused, applied Z")
        XCUIRemote.shared.press(.left)
        XCTAssertNotNil(steps.focusedCard(within: 5), "Left goes to the grid")
        // Gives a stray clear time to show before checking Z stays applied.
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(z.isSelected, "Z stays applied")
        shot("alphabet applied")
    }

    private static func value(_ name: String) -> String? {
        environment[name].flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Moves focus to `row` with the remote: down the screen, then back up, stopping as `row` has focus (each look is a
    /// query of the whole tree).
    private func focus(_ row: XCUIElement, _ what: String) {
        let sweep = Array(repeating: XCUIRemote.Button.down, count: 30) + Array(repeating: .up, count: 60)
        for button in sweep {
            if steps.hasFocus(row) { return }
            XCUIRemote.shared.press(button)
            // Paces the presses so the focus engine doesn't coalesce them.
            usleep(350_000)
        }
        XCTAssertTrue(steps.hasFocus(row), "focus on \(what)")
    }

    /// Focuses `row` and checks its title stays readable there (`requireReadable`).
    private func requireReadableFocused(_ row: XCUIElement, _ what: String) {
        focus(row, what)
        // Lets the focused platter finish animating before the shot and the colour check.
        Thread.sleep(forTimeInterval: 1)
        shot("\(what) focused")
        requireReadable(row, what)
    }
}
#endif
