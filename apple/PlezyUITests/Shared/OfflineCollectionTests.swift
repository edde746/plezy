#if !os(tvOS)
import XCTest

/// A downloaded collection opened from Downloads on iPhone, iPad and the Mac (Apple TV has no downloads), against the
/// dev Jellyfin server: the collection Plezy Picks downloaded whole from its card's menu in Movies' Collections,
/// Downloads (from Home's Downloads chip) on its Movies tab grouped by collections shows its folder, and the folder opens the offline
/// collection screen: its downloaded titles, Mark as watched or unwatched and Delete downloads, which asks
/// first (answered Cancel here, so the downloads stay). Each step is kept as a screenshot.
final class OfflineCollectionTests: PlezyUITestCase {
    private static let collection = "Plezy Picks"
    private static let titles = ["Maestro Movie", "Credits Movie", "Chapters Movie", "Two Versions"]

    func testDownloadedCollectionOpensOffline() throws {
        let steps = LibrarySteps(test: self)
        launchDev(arguments: ["--dev-server", try steps.libraryServer(), "--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        steps.pickLibrary("Movies")
        steps.showLibraryTab("collections")
        let picks = steps.card(prefix: Self.collection)
        if !picks.exists(within: 30) { fail("Movies' Collections shows no \(Self.collection)") }
        #if os(macOS)
        picks.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).rightClick()
        #else
        picks.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.0)
        #endif
        press(require("menu.download_collection", timeout: 10, "the collection's Download"))
        // The download's questions (which titles, the pre-flight): the first option, the confirmation's Download.
        let option = element("downloads.dialog.option.0"), confirm = element("downloads.dialog.confirm")
        for wait in [10.0, 3, 3, 3] {
            if option.exists(within: wait) {
                // An iPad's popover takes no tap while it still animates in.
                sleep(1)
                press(option)
            } else if confirm.exists {
                press(confirm)
            } else {
                break
            }
        }
        // Downloads opens from Home's Downloads chip.
        press(require("nav.home", "the chrome's Home"))
        let chip = require("home.downloads", timeout: 30, "Home's Downloads chip")
        #if os(iOS)
        // The chip row scrolls sideways: Downloads comes after the libraries' chips.
        for _ in 0..<6 where chip.frame.maxX > app.frame.maxX - 16 { element("home.shortcuts").swipeLeft() }
        #endif
        press(chip)
        require("downloads.screen", timeout: 30, "the Downloads screen")
        // The collection's titles download as the Manage tree's rows.
        for title in Self.titles {
            let row = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'downloads.row.' AND label == %@", title)).firstMatch
            if !row.exists(within: 180) { fail("no Manage row of \(title) after 180 s") }
            if !waitUntil(300, every: 5, { offers(row, "delete") }) { fail("\(title) didn't complete within 300 s") }
        }
        shot("collection downloaded")

        pick("downloads.tab", "Movies")
        pick("downloads.grouping", "Collections")
        let folder = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'card.' AND label CONTAINS %@", Self.collection)).firstMatch
        if !folder.exists(within: 20) { fail("the Movies tab grouped by collections shows no \(Self.collection)") }
        // Lets the folder's artwork load before the shot; nothing signals it.
        sleep(2)
        shot("collection folder in downloads")
        #if os(macOS)
        folder.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).click()
        #else
        folder.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        #endif

        require("collection.screen", timeout: 20, "the folder opens the collection's screen")
        require("collection.offline.watched", timeout: 20, "the offline collection's Mark as watched or unwatched")
        let delete = require("collection.offline.delete", "the offline collection's Delete downloads")
        let titles = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'"))
        if !waitUntil(20, { titles.count > 0 }) { fail("the offline collection lists none of its downloaded titles") }
        // Lets the titles' artwork load before the shot; nothing signals it.
        sleep(2)
        shot("offline collection")
        press(delete)
        require("collection.offline.delete.confirm", timeout: 10, "Delete downloads asks first")
        shot("offline collection delete question")
        press(require("collection.offline.delete.cancel", "the question's Cancel"))
        if !element("collection.offline.delete.confirm").waitForNonExistence(timeout: 10) { fail("Cancel leaves the question up") }
        XCTAssertTrue(element("collection.screen").exists, "Cancel keeps the collection's screen and its downloads")
    }

    // MARK: - Steps

    /// Picks the option `label` of the filter menu `id`, the menu reopened while the option doesn't show.
    private func pick(_ id: String, _ label: String) {
        let steps = LibrarySteps(test: self)
        let entry = steps.option(id, label: label)
        for _ in 0..<3 where !entry.exists {
            press(require(id, timeout: 20, "the \(id) menu"))
            _ = entry.exists(within: 5)
        }
        if !entry.exists { fail("\(label) in the \(id) menu") }
        steps.pressOption(entry)
        sleep(1)
    }

    private func press(_ element: XCUIElement) {
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
        sleep(1)
    }

    /// Whether the Manage row `row`'s ⋯ menu offers `action`, the menu closed again.
    private func offers(_ row: XCUIElement, _ action: String) -> Bool {
        press(element("\(row.identifier).menu"))
        let offered = element("\(row.identifier).\(action)").exists(within: 2)
        #if os(macOS)
        app.typeKey(.escape, modifierFlags: [])
        #else
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)).tap()
        #endif
        sleep(1)
        return offered
    }
}
#endif
