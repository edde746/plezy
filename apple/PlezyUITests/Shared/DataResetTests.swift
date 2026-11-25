import SQLite3
import XCTest

/// The product's start over a database an unreleased build changed in place (a column this version has, gone): the
/// startup failure screen says the saved data can't be read and offers Reset app data; confirmed, the app starts over
/// at the sign-in.
final class DataResetTests: PlezyUITestCase {
    func testUnreadableDataOffersAResetThatStartsOver() throws {
        let database = try databasePath()
        // A first start: the app's own database, whatever an earlier run left.
        for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: database + suffix) }
        launchProduct()
        require("signin.screen", timeout: 60, "the first start")
        app.terminate()

        try execute("ALTER TABLE downloaded_media DROP COLUMN transcode_quality", in: try databasePath())
        launchProduct()
        let reset = require("startup.reset", timeout: 60, "the start over the changed database")
        shot("unreadable")
        activate(reset)
        let confirm = require("startup.resetConfirm.confirm", "the reset's confirmation")
        shot("confirm")
        activate(confirm)
        require("signin.screen", timeout: 60, "the start after the reset")
        shot("after-reset")
    }

    /// Taps (clicks; on Apple TV, focuses and selects) `target`.
    private func activate(_ target: XCUIElement) {
        #if os(tvOS)
        // The screen or the question takes no press while it still animates in; paced presses, which the focus
        // engine would otherwise coalesce. The question opens on Cancel, Reset beside it.
        Thread.sleep(forTimeInterval: 1)
        // A question's button carries its identifier on an inner element; the focus is on the button around it.
        let focused = { XCUIApplication().descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch }
        let onTarget = { target.hasFocus || focused().frame == target.frame }
        for button in [XCUIRemote.Button.right, .right, .down, .down, .down, .up, .up, .up, .up, .up, .up] where !onTarget() {
            XCUIRemote.shared.press(button)
            _ = waitUntil(0.8) { onTarget() }
        }
        if !onTarget() { fail("\(target.identifier) never takes focus") }
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        target.click()
        #else
        target.tap()
        #endif
    }

    /// The product's database: the Mac app's under its bundle ID (the runner's sandbox may write there, its
    /// entitlements), else in the app's data container beside the runner's in the simulator (Caches on Apple TV).
    private func databasePath() throws -> String {
        #if os(macOS)
        let home = String(cString: try XCTUnwrap(getpwuid(getuid())).pointee.pw_dir)
        return home + "/Library/Application Support/com.edde746.plezy.dev/databases/plezy.db"
        #else
        #if os(tvOS)
        let relative = "Library/Caches/databases/plezy.db"
        #else
        let relative = "Library/Application Support/databases/plezy.db"
        #endif
        let containers = URL(fileURLWithPath: NSHomeDirectory()).deletingLastPathComponent()
        for container in try FileManager.default.contentsOfDirectory(at: containers, includingPropertiesForKeys: nil) {
            let metadata = NSDictionary(contentsOf: container.appending(path: ".com.apple.mobile_container_manager.metadata.plist"))
            if metadata?["MCMMetadataIdentifier"] as? String == "com.edde746.plezy" { return container.appending(path: relative).path }
        }
        // Not installed yet: no database to remove.
        return containers.appending(path: "none/\(relative)").path
        #endif
    }

    private func execute(_ sql: String, in path: String) throws {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            defer { sqlite3_close(db) }
            return fail("can't open \(path): \(String(cString: sqlite3_errmsg(db)))")
        }
        defer { sqlite3_close(db) }
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK { fail("\(sql): \(String(cString: sqlite3_errmsg(db)))") }
    }
}
