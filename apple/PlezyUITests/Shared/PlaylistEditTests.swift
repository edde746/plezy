import XCTest
#if os(iOS)
import UIKit
#endif

/// Editing a playlist end to end on both of its pages: an audio playlist's music page and a video playlist's page.
/// Each test signs in as a new account of the test server (`PLEZY_SERVER`, `--dev-server`'s
/// `<kind>=<user>:<password>@<url>`, an administrator; the default Jellyfin without it) that owns a playlist of four
/// items made for it, opens it (`--dev-playlist`), enters Edit mode, moves the first row down (iPhone and iPad: the
/// list's grip dragged; the Mac: the handle dragged onto the third row; Apple TV: the handle selected, Down, the
/// handle again), removes the first row (the list's minus and Delete; the Mac and Apple TV: its ✕), each change checked
/// on the server, leaves Edit mode, then deletes the playlist (asked first) and checks it is gone. The account and
/// whatever of its playlists is left go as the test ends, by their Ids.
final class PlaylistEditTests: PlezyUITestCase {
    private var account: PlaylistTestAccount?

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://192.168.0.15:28096" : value
    }

    nonisolated override func tearDown() {
        MainActor.assumeIsolated {
            app.terminate()
            if let account {
                do { try account.remove() } catch { XCTFail("deleting the test account failed: \(error)") }
            }
            account = nil
        }
        super.tearDown()
    }

    func testEditsAnAudioPlaylistOnItsMusicPage() throws {
        try edit(audio: true, page: "music.playlist", edit: "music.playlist.edit", row: "music.track", more: "music.playlist.more", delete: "music.playlist.delete")
    }

    func testEditsAVideoPlaylist() throws {
        try edit(audio: false, page: "playlist", edit: "playlist.edit", row: "playlist.row", more: "playlist.more", delete: "playlist.delete")
    }

    // MARK: - The flow

    private func edit(audio: Bool, page: String, edit editId: String, row: String, more: String, delete: String) throws {
        executionTimeAllowance = 600
        let account = try PlaylistTestAccount.create(on: Self.server)
        self.account = account
        let kind = audio ? "audio" : "video"
        let playlist = try account.makePlaylist(audio: audio)
        let original = try account.items(of: playlist)
        XCTAssertEqual(original.count, 4, "the \(kind) playlist starts with four items")

        launchDev(settings: ["theme_mode=dark"], arguments: ["--dev-server", account.spec, "--dev-playlist", "jellyfin:\(playlist)"])
        require(page, timeout: 90, "the \(kind) playlist's page")
        let first = require("\(row).0", timeout: 30, "the first row")
        // Apple TV's video rows run past the screen, and a lazy stack holds no row it doesn't show.
        require("\(row).2", "the third row")
        // The artwork comes over the network.
        Thread.sleep(forTimeInterval: 4)
        shot("\(device) \(kind) at rest")
        #if os(tvOS)
        requireFocus(require(audio ? "music.play" : "playlist.play", "the playlist's Play"), "the page opens with focus on Play")
        #endif
        #if os(iOS)
        requireNoLoneIconPills(beside: require(audio ? "music.play" : "playlist.play", "the playlist's Play"), "\(kind) at rest")
        #endif
        XCTAssertFalse(element("\(row).0.remove").exists, "no ✕ outside Edit mode")
        XCTAssertFalse(element("\(row).0.handle").exists, "no handle outside Edit mode")
        XCTAssertTrue(listControls(beside: first).isEmpty, "no list edit controls outside Edit mode")

        let edit = require(editId, "the playlist's Edit")
        XCTAssertEqual(edit.label, "Edit", "Edit says what it does")
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // One rule on both pages: where the row has room, Shuffle shows its label.
            let shuffle = require(audio ? "music.shuffle" : "playlist.shuffle", "the playlist's Shuffle")
            XCTAssertEqual(shuffle.label, "Shuffle")
            XCTAssertGreaterThan(shuffle.frame.width, shuffle.frame.height * 1.5, "Shuffle is a pill with its label, not a circle: \(shuffle.frame)")
        }
        #endif
        #if os(tvOS)
        let afterEdit = element(audio ? more : delete)
        let restingAfterEdit = afterEdit.frame
        #endif
        #if os(iOS)
        // The bar's title (the video page's; the music page names itself in its content) stays where it is.
        let title = app.navigationBars.staticTexts.firstMatch
        let titleAtRest = title.exists ? title.frame : nil
        #endif
        activate(edit, "Edit")
        waitForLabel(edit, "Done", "Edit didn't turn into Done")
        #if os(iOS)
        if let titleAtRest {
            // Stability check: the title must not move over this period as Edit mode starts.
            Thread.sleep(forTimeInterval: 1)
            XCTAssertEqual(title.frame.minX, titleAtRest.minX, accuracy: 1, "the bar's title stays where it is in Edit mode")
        }
        #endif
        #if os(tvOS)
        requireFocus(edit, "focus stays on Done as Edit mode starts")
        XCTAssertEqual(afterEdit.frame.minX, restingAfterEdit.minX, accuracy: 1, "the button after Edit stays put as Edit turns into Done")
        #endif
        _ = waitUntil(5) { !self.listControls(beside: first).isEmpty || self.element("\(row).0.remove").exists }
        shot("\(device) \(kind) editing")
        #if os(iOS)
        requireNoLoneIconPills(beside: require(audio ? "music.play" : "playlist.play", "the playlist's Play"), "\(kind) editing")
        #endif
        #if os(iOS)
        let controls = listControls(beside: first)
        XCTAssertTrue(controls.contains { $0.identifier == "minus.circle.fill" }, "the first row offers the list's minus")
        XCTAssertTrue(controls.contains { $0.label.hasPrefix("Reorder") }, "the first row offers the list's grip")
        #else
        require("\(row).0.handle", "the first row's handle")
        require("\(row).0.remove", "the first row's ✕")
        #endif

        // The first row moves down past the second and third (the Mac: past the second, onto which it is dropped).
        #if os(iOS)
        guard let grip = listControls(beside: first).first(where: { $0.label.hasPrefix("Reorder") }) else { return fail("no grip on the first row") }
        let target = element("\(row).2")
        grip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.8, thenDragTo: target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)))
        #elseif os(macOS)
        // A mouse drag, as the queue's test makes it (`press` is a touch gesture); by coordinates, which a handle in a
        // scroll view needs (it reports itself not hittable there). A row dropped onto another takes its place.
        element("\(row).0.handle").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .click(forDuration: 0.5, thenDragTo: element("\(row).1").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        #else
        let handle = element("\(row).0.handle")
        // Back in move mode puts the row back and leaves move mode, not Edit mode or the page.
        let firstLabel = element("\(row).0").label
        activate(handle, "the first row's handle")
        // Paces the presses: the focus engine drops presses that come too close together.
        Thread.sleep(forTimeInterval: 0.6)
        XCUIRemote.shared.press(.down)
        // Paces the presses: the focus engine drops presses that come too close together.
        Thread.sleep(forTimeInterval: 0.6)
        XCUIRemote.shared.press(.menu)
        _ = waitUntil(5) {
            edit.label == "Done" && self.element("\(row).0").label == firstLabel && self.element("\(row).1.handle").isEnabled
        }
        XCTAssertTrue(element(page).exists, "Back in move mode stays on the page")
        XCTAssertEqual(edit.label, "Done", "Back in move mode leaves move mode, not Edit mode")
        XCTAssertEqual(element("\(row).0").label, firstLabel, "Back in move mode puts the row back")
        XCTAssertTrue(element("\(row).1.handle").isEnabled, "the other rows' handles take focus again after move mode")
        activate(handle, "the first row's handle")
        // Lets move mode's animation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(device) \(kind) move mode")
        // The header's buttons dim as move mode starts: once more when that has settled.
        Thread.sleep(forTimeInterval: 2)
        shot("\(device) \(kind) move mode settled")
        XCUIRemote.shared.press(.down)
        // Paces the presses: the focus engine drops presses that come too close together.
        Thread.sleep(forTimeInterval: 0.6)
        XCUIRemote.shared.press(.down)
        // Lets the move's animation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(device) \(kind) moved")
        XCUIRemote.shared.press(.select)
        #endif
        #if os(macOS)
        let moved = [original[1], original[0], original[2], original[3]]
        #else
        let moved = [original[1], original[2], original[0], original[3]]
        #endif
        waitForServer("the move reached the server", playlist, account) { $0 == moved }
        // Lets the rows' animation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(device) \(kind) reordered")

        // The first row (the old second) goes.
        #if os(iOS)
        guard let minus = listControls(beside: element("\(row).0")).first(where: { $0.identifier == "minus.circle.fill" }) else {
            return fail("no minus on the first row")
        }
        minus.tap()
        let confirm = app.buttons.matching(NSPredicate(format: "label == 'Delete'")).firstMatch
        if !confirm.exists(within: 5) { return fail("the minus offered no Delete") }
        confirm.tap()
        #else
        #if os(tvOS)
        // Focus follows the moved row down, and the lazy stack holds no row it doesn't show: back up to the first row.
        for _ in 0..<4 where !element("\(row).0.remove").exists {
            XCUIRemote.shared.press(.up)
            _ = waitUntil(0.6) { self.element("\(row).0.remove").exists }
        }
        #endif
        activate(require("\(row).0.remove", "the first row's ✕"), "the first row's ✕")
        #endif
        let removed = Array(moved.dropFirst())
        waitForServer("the removal reached the server", playlist, account) { $0 == removed }
        #if !os(tvOS)
        if !element("\(row).3").waitForNonExistence(timeout: 10) { fail("the page still shows four rows") }
        #endif
        // Lets the removal's animation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(device) \(kind) removed")

        // Back (Apple TV, Escape on the Mac) or Done leaves Edit mode.
        #if os(tvOS)
        XCUIRemote.shared.press(.menu)
        #elseif os(macOS)
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        #else
        activate(edit, "Done")
        #endif
        waitForLabel(edit, "Edit", "Edit mode didn't end")
        #if os(tvOS)
        requireFocus(edit, "focus comes back to Edit as Back ends Edit mode")
        #endif
        XCTAssertFalse(element("\(row).0.remove").exists, "the ✕ goes with Edit mode")
        XCTAssertTrue(listControls(beside: element("\(row).0")).isEmpty, "the list's edit controls go with Edit mode")
        require(page, "the playlist's page, still open")
        // Lets Edit mode's closing animation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(device) \(kind) done")

        // Delete Playlist, asked first.
        var inMenu = false
        if !element(delete).exists(within: 2) {
            activate(require(more, "the playlist's ⋯"), "⋯")
            inMenu = true
        }
        let entry = require(delete, "Delete Playlist")
        if inMenu {
            // A pick while the menu still opens goes nowhere: it waits until the entry stands still.
            var last = CGRect.null
            let settled = Date.now.addingTimeInterval(5)
            while Date.now < settled, !(entry.isHittable && entry.frame == last) {
                last = entry.frame
                Thread.sleep(forTimeInterval: 0.3)
            }
            shotOfMenu("\(device) \(kind) menu")
            #if os(tvOS)
            // The menu opens on its only entry; a menu's items report no focus.
            XCUIRemote.shared.press(.select)
            #elseif os(iOS)
            // iOS reports the open menu's entry about 30 pt above where it draws it (the tree's frame against the
            // shot's pill): its reported lower edge is the part inside the pill as drawn.
            entry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
            #else
            activate(entry, "Delete Playlist")
            #endif
        } else {
            activate(entry, "Delete Playlist")
        }
        let ok = element("menu.confirm.ok")
        if !ok.exists(within: 10) { return fail("Delete Playlist didn't ask first") }
        // Lets the question's presentation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shotOfMenu("\(device) \(kind) delete asks")
        #if os(tvOS)
        // The alert's focus sits on the system's button around each answer, which carries its label, not its identifier.
        let focusedOk = app.buttons.matching(NSPredicate(format: "hasFocus == true AND label == %@", ok.label)).firstMatch
        for _ in 0..<3 where !focusedOk.exists {
            XCUIRemote.shared.press(.right)
            _ = waitUntil(0.5) { focusedOk.exists }
        }
        if !focusedOk.exists { return fail("focus never reached the question's \(ok.label)") }
        XCUIRemote.shared.press(.select)
        #else
        activate(ok, "the question's Delete")
        #endif
        if !element(page).waitForNonExistence(timeout: 20) { fail("the deleted playlist's page stayed") }
        _ = waitUntil(15, every: 0.5) { !((try? account.playlists().contains(playlist)) ?? true) }
        XCTAssertFalse(try account.playlists().contains(playlist), "the playlist is gone from the server")
        // Lets the page's closing animation finish before the screenshot.
        Thread.sleep(forTimeInterval: 1)
        shot("\(device) \(kind) deleted")
    }

    // MARK: - Helpers

    private var device: String {
        #if os(macOS)
        "mac"
        #elseif os(tvOS)
        "tv"
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        #endif
    }

    /// Waits until the playlist's item Ids on the server pass `done`.
    private func waitForServer(_ what: String, _ playlist: String, _ account: PlaylistTestAccount, _ done: ([String]) -> Bool) {
        var items: [String] = []
        if waitUntil(15, every: 0.5, {
            items = (try? account.items(of: playlist)) ?? []
            return done(items)
        }) { return }
        fail("\(what): the server has \(items)")
    }

    #if os(iOS)
    /// Every control in Play's row is a circle or a pill that shows its title: a pill whose icon sits in its middle,
    /// with no room taken by a title after it, is a label dropped for width that should have been a circle.
    private func requireNoLoneIconPills(beside play: XCUIElement, _ what: String) {
        let line = play.frame
        let row = app.buttons.allElementsBoundByIndex.filter {
            !$0.identifier.isEmpty && abs($0.frame.midY - line.midY) < 2 && abs($0.frame.height - line.height) < 2
        }
        XCTAssertGreaterThan(row.count, 1, "\(what): Play's row has its controls")
        for control in row where control.frame.width > control.frame.height + 2 {
            let icon = control.images.firstMatch
            guard icon.exists else { continue }
            let leading = icon.frame.minX - control.frame.minX
            let trailing = control.frame.maxX - icon.frame.maxX
            XCTAssertGreaterThan(
                trailing - leading, 20,
                "\(what): \(control.identifier) is a \(Int(control.frame.width))×\(Int(control.frame.height)) pill with its icon alone in it (\(Int(leading)) pt before it, \(Int(trailing)) after)"
            )
        }
    }
    #endif

    /// The list's own edit controls on `row`'s line (iPhone and iPad): its minus (named by its symbol) and its grip
    /// ("Reorder …").
    private func listControls(beside row: XCUIElement) -> [XCUIElement] {
        #if os(iOS)
        let frame = row.frame
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'minus.circle.fill' OR (elementType == %d AND label BEGINSWITH 'Reorder')", XCUIElement.ElementType.button.rawValue))
            .allElementsBoundByIndex
            .filter { $0.frame.midY > frame.minY && $0.frame.midY < frame.maxY }
        #else
        []
        #endif
    }

    /// Waits until `button` says `label`.
    private func waitForLabel(_ button: XCUIElement, _ label: String, _ what: String) {
        _ = waitUntil(5, every: 0.3) { button.label == label }
        if button.label != label { fail("\(what): it says \(button.label)") }
    }

    /// Presses `target`: a tap, a click, or on Apple TV focus moved to it and Select.
    private func activate(_ target: XCUIElement, _ what: String) {
        #if os(tvOS)
        focus(target, what)
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        #else
        target.tap()
        #endif
    }

    #if os(tvOS)
    /// `target` has focus within 3 s, with no press.
    private func requireFocus(_ target: XCUIElement, _ what: String) {
        _ = waitUntil(3, every: 0.2) { target.hasFocus }
        if !target.hasFocus { fail(what) }
    }

    /// Moves focus with the remote toward `target` until it has it: each press goes the way the target lies from the
    /// focused element (out of the tab bar first, then up or down, then sideways).
    private func focus(_ target: XCUIElement, _ what: String) {
        guard target.exists(within: 30) else { return fail("No \(what)") }
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        func reached() -> Bool {
            target.hasFocus || target.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.exists
        }
        for _ in 0..<24 {
            if reached() { return }
            let to = target.frame, from = focused.exists ? focused.frame : .zero
            let direction: XCUIRemote.Button
            if focused.exists, focused.identifier.hasPrefix("nav.") {
                direction = .down
            } else if to.minY >= from.maxY - 1 {
                direction = .down
            } else if to.maxY <= from.minY + 1 {
                direction = .up
            } else {
                direction = to.midX > from.midX ? .right : .left
            }
            XCUIRemote.shared.press(direction)
            _ = waitUntil(0.5) { reached() }
        }
        if !reached() { fail("Focus never reached \(what)") }
    }
    #endif
}

/// A new account on a Jellyfin test server, added by the spec's administrator, with playlists of its own made through
/// the server's API. `remove()` deletes those playlists still in the account's own listing, by Id, then the account.
private final class PlaylistTestAccount {
    struct Failure: LocalizedError, CustomStringConvertible {
        let description: String
        var errorDescription: String? { description }
    }

    /// The account's `--dev-server` spec.
    let spec: String
    private let base: String
    private let adminToken: String
    private let token: String
    private let user: String
    /// The Ids of the playlists `makePlaylist` made.
    private var made: [String] = []

    private init(spec: String, base: String, adminToken: String, token: String, user: String) {
        self.spec = spec
        self.base = base
        self.adminToken = adminToken
        self.token = token
        self.user = user
    }
    private static let client = "MediaBrowser Client=\"Plezy UI tests\", Device=\"ui-tests\", DeviceId=\"plezy-ui-tests-\(UUID().uuidString)\", Version=\"1\""

    static func create(on server: String) throws -> PlaylistTestAccount {
        guard let equals = server.firstIndex(of: "="), let at = server.lastIndex(of: "@") else {
            throw Failure(description: "no <kind>=<user>:<password>@<url> in \(server)")
        }
        let kind = String(server[..<equals])
        guard kind == "jellyfin" else { throw XCTSkip("\(kind): the playlists are made through Jellyfin's API") }
        let credentials = server[server.index(after: equals)..<at].split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let base = String(server[server.index(after: at)...])
        let admin = try call("POST", "\(base)/Users/AuthenticateByName", token: nil, body: ["Username": credentials[0], "Pw": credentials.count > 1 ? credentials[1] : ""])
        guard let adminToken = admin["AccessToken"] as? String else { throw Failure(description: "the administrator's sign-in answered no token") }
        let name = "ui-tests-\(UUID().uuidString.prefix(8).lowercased())"
        let made = try call("POST", "\(base)/Users/New", token: adminToken, body: ["Name": name])
        guard let user = made["Id"] as? String else { throw Failure(description: "the new account came without an Id") }
        let auth: [String: Any]
        do {
            auth = try call("POST", "\(base)/Users/AuthenticateByName", token: nil, body: ["Username": name, "Pw": ""])
        } catch {
            _ = try? call("DELETE", "\(base)/Users/\(user)", token: adminToken, body: nil)
            throw error
        }
        guard let token = auth["AccessToken"] as? String else {
            _ = try? call("DELETE", "\(base)/Users/\(user)", token: adminToken, body: nil)
            throw Failure(description: "the new account's sign-in answered no token")
        }
        return PlaylistTestAccount(spec: "\(kind)=\(name):@\(base)", base: base, adminToken: adminToken, token: token, user: user)
    }

    /// The playlists it made that its listing still has, then the account, by Id.
    func remove() throws {
        for playlist in try playlists() where made.contains(playlist) {
            _ = try Self.call("DELETE", "\(base)/Items/\(playlist)", token: token, body: nil)
        }
        _ = try Self.call("DELETE", "\(base)/Users/\(user)", token: adminToken, body: nil)
    }

    /// A playlist of the account's own, of the first four tracks (`audio`) or movies and episodes of the server; its Id.
    func makePlaylist(audio: Bool) throws -> String {
        let types = audio ? "Audio" : "Movie,Episode"
        let found = try Self.call("GET", "\(base)/Users/\(user)/Items?Recursive=true&IncludeItemTypes=\(types)&SortBy=SortName&Limit=4", token: token, body: nil)
        let ids = ((found["Items"] as? [[String: Any]]) ?? []).compactMap { $0["Id"] as? String }
        guard ids.count == 4 else { throw Failure(description: "the test server has \(ids.count) \(types) items, not 4") }
        let name = audio ? "Edit Test Tracks" : "Edit Test Videos"
        let answer = try Self.call("POST", "\(base)/Playlists", token: token, body: ["Name": name, "Ids": ids, "UserId": user, "MediaType": audio ? "Audio" : "Video"])
        guard let id = answer["Id"] as? String else { throw Failure(description: "the new playlist came without an Id") }
        made.append(id)
        return id
    }

    /// The Ids of the playlist's items, in its order.
    func items(of playlist: String) throws -> [String] {
        let found = try Self.call("GET", "\(base)/Playlists/\(playlist)/Items?userId=\(user)", token: token, body: nil)
        return ((found["Items"] as? [[String: Any]]) ?? []).compactMap { $0["Id"] as? String }
    }

    /// The Ids of the playlists in the account's own listing.
    func playlists() throws -> [String] {
        let found = try Self.call("GET", "\(base)/Users/\(user)/Items?Recursive=true&IncludeItemTypes=Playlist", token: token, body: nil)
        return ((found["Items"] as? [[String: Any]]) ?? []).compactMap { $0["Id"] as? String }
    }

    private static func call(_ method: String, _ url: String, token: String?, body: [String: Any]?) throws -> [String: Any] {
        var request = URLRequest(url: URL(string: url)!, timeoutInterval: 15)
        request.httpMethod = method
        request.setValue(client, forHTTPHeaderField: "X-Emby-Authorization")
        if let token { request.setValue(token, forHTTPHeaderField: "X-Emby-Token") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let done = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var answer: Result<[String: Any], any Error> = .failure(Failure(description: "\(method) \(url) never answered"))
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { done.signal() }
            if let error { answer = .failure(error); return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else { answer = .failure(Failure(description: "\(method) \(url) answered \(status)")); return }
            answer = .success(data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:])
        }.resume()
        done.wait()
        return try answer.get()
    }
}
