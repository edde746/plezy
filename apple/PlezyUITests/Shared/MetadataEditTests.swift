import XCTest

/// The metadata editor of a server's item: a `--dev` session signs into `PLEZY_DEV_SERVER` (`--dev-server`'s
/// `<kind>=<user>:<password>@<url>`) and opens the editor of `PLEZY_DEV_EDIT` (`--dev-edit`'s `<server>:<item>`). It
/// shows the item's sections, and the Title row opens its text dialog, which Cancel closes without a change.
final class MetadataEditTests: PlezyUITestCase {
    func testEditorShowsTheItemAndItsTextDialog() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let server = environment["PLEZY_DEV_SERVER"], let edit = environment["PLEZY_DEV_EDIT"] else {
            throw XCTSkip("needs PLEZY_DEV_SERVER and PLEZY_DEV_EDIT")
        }
        launchDev(arguments: ["--dev-server", server, "--dev-edit", edit])
        let title = require("metadata.field.title", timeout: 90, "once the item's editor loads")
        #if os(tvOS)
        _ = waitUntil(5) { title.hasFocus }
        #else
        _ = waitUntil(5) { title.isHittable }
        #endif
        shot("editor")
        #if os(tvOS)
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        title.click()
        #else
        title.tap()
        #endif
        require("metadata.text.field", timeout: 10, "after the Title row is pressed")
        // Lets the dialog's presentation finish before the screenshot.
        sleep(1)
        shot("title-dialog")
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #elseif os(macOS)
        element("metadata.text.cancel").click()
        #else
        element("metadata.text.cancel").tap()
        #endif
        _ = waitUntil(5) { !self.element("metadata.text.field").exists && self.element("metadata.field.title").exists }
        XCTAssertTrue(element("metadata.field.title").exists, "Cancel returns to the editor")
    }
}
