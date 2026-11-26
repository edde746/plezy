import XCTest
#if os(iOS)
import UIKit
#endif

/// The player's episode buttons, its clocks and its queue, shot over Maestro Show's first and second episodes as each
/// start path opens them, and a music playlist's Play beside an album's. Each episode test signs in as a new account of
/// the test server (`PLEZY_SERVER`, `--dev-server`'s `<kind>=<user>:<password>@<url>`, an administrator; the default
/// Jellyfin without it), on which nothing is played but what the test sets, and deletes it as it ends. With
/// `PLEZY_CLOCK=24` the app starts on a 24-hour clock, the device's own setting kept: its locale carries the hour cycle
/// as iOS stores the 24-Hour Time switch (`-AppleLocale en@hours=h23`), plus `-AppleICUForce24HourTime YES`.
///
/// Each player shot is followed by a note of what the controls read: the episode buttons' state, the time left and the
/// time the episode ends at, the player's state and Now Playing probes, and the queue's rows.
final class PlayerQueueClockShots: PlezyUITestCase {
    private var account: TestAccount?

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://192.168.0.15:28096" : value
    }

    private static var clock24: Bool { ProcessInfo.processInfo.environment["PLEZY_CLOCK"] == "24" }

    /// The base class's launch, on a 24-hour clock with `PLEZY_CLOCK=24`: the run's first language (English by
    /// default) with the hour cycle h23 as the locale, which the base class would set without it.
    override func launch(_ arguments: [String], languages: [String]? = nil) {
        guard Self.clock24 else { return super.launch(arguments, languages: languages) }
        continueAfterFailure = false
        let languages = languages ?? Self.languages
        var arguments = arguments + [
            "-AppleLanguages", "(\(languages.joined(separator: ",")))",
            "-AppleLocale", languages[0].replacingOccurrences(of: "-", with: "_") + "@hours=h23",
            "-AppleICUForce24HourTime", "YES",
        ]
        if ProcessInfo.processInfo.environment["PLEZY_MUTE"] == "1" { arguments += ["-mpvMute", "YES"] }
        app.launchArguments = arguments
        app.launch()
    }

    nonisolated override func tearDown() {
        MainActor.assumeIsolated {
            // The app stopped first: no progress report of its lands after the account went.
            app.terminate()
            if let account {
                do { try account.remove() } catch { XCTFail("deleting the test account failed: \(error)") }
            }
            account = nil
        }
        super.tearDown()
    }

    /// Signs in as a new account of the server and launches the app as it, with `arguments` after it.
    private func launchAsNewAccount(settings: [String] = [], _ arguments: [String], prepare: (TestAccount) throws -> Void = { _ in }) throws {
        executionTimeAllowance = 600
        let account = try TestAccount.create(on: Self.server)
        self.account = account
        try prepare(account)
        launchDev(settings: settings, arguments: ["--dev-server", account.spec] + arguments)
    }

    /// The Live TV guide: its times follow the system's clock (`DateFormatter`'s "j" template), so they show whether
    /// the app took the 24-hour setting.
    func testClockSettingInLiveTvGuide() throws {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open", "live_tv"])
        require("livetv.screen", timeout: 90, "the Live TV screen")
        require("livetv.guide.channel.0", timeout: 60, "the guide's channels")
        // The guide's programmes and artwork load before the shot; nothing signals it.
        sleep(3)
        shot("live tv guide")
    }

    #if os(iOS)
    /// Maestro Show's Play with nothing played: its first episode, a special (S0E1) before it in the show.
    func testFirstEpisodeFromShowPlay() throws {
        try startFromShowPlay("Maestro Show", "show play")
    }

    /// Maestro Show's first episode's own row on the show's page.
    func testFirstEpisodeFromItsRow() throws {
        try startFromRow("Maestro Show", "Maestro Episode 1", "episode 1 row")
    }

    /// Maestro Show's first episode in Continue Watching (40 s in, played just now), tapped there.
    func testFirstEpisodeFromContinueWatching() throws {
        try startFromContinueWatching("Maestro Show", "Maestro Episode 1", "continue watching")
    }

    /// Maestro Show's second episode's own row on the show's page: an episode with one before and one after it.
    func testMiddleEpisodeFromItsRow() throws {
        try startFromRow("Maestro Show", "Maestro Episode 2", "episode 2 row")
    }

    /// Yume Anime's Play with nothing played: its first episode, which nothing comes before (the show has no specials).
    func testAnimeFirstEpisodeFromShowPlay() throws {
        try startFromShowPlay("Yume Anime", "anime show play")
    }

    /// Yume Anime's first episode's own row.
    func testAnimeFirstEpisodeFromItsRow() throws {
        try startFromRow("Yume Anime", "Yume Dawn", "anime episode 1 row")
    }

    /// Yume Anime's first episode in Continue Watching.
    func testAnimeFirstEpisodeFromContinueWatching() throws {
        try startFromContinueWatching("Yume Anime", "Yume Dawn", "anime continue watching")
    }

    private func startFromShowPlay(_ show: String, _ name: String) throws {
        try launchAsNewAccount(["--dev-open", "search"])
        openShow(show)
        let play = require("detail.play", timeout: 30, "the show's Play")
        // The show page's artwork loads before the shot.
        sleep(2)
        shot("\(name) show page")
        play.tap()
        capturePlayer(name)
    }

    private func startFromRow(_ show: String, _ episode: String, _ name: String) throws {
        try launchAsNewAccount(["--dev-open", "search"])
        openShow(show)
        tapEpisodeRow(episode)
        capturePlayer(name)
    }

    private func startFromContinueWatching(_ show: String, _ episode: String, _ name: String) throws {
        try launchAsNewAccount([]) { try $0.setResume(show, episode, seconds: 40) }
        let hub = require("hub.continue_watching", timeout: 60, "Continue Watching")
        let card = hub.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 30) { return fail("Continue Watching holds no card") }
        // The row's layout and artwork settle before the scroll and the shot; nothing signals it.
        sleep(2)
        let screen = app.windows.firstMatch.frame
        for _ in 0..<6 where !screen.contains(card.frame) {
            let towardsEnd = card.frame.maxX > screen.maxX
            let from = hub.coordinate(withNormalizedOffset: CGVector(dx: towardsEnd ? 0.7 : 0.3, dy: 0.5))
            let to = hub.coordinate(withNormalizedOffset: CGVector(dx: towardsEnd ? 0.37 : 0.63, dy: 0.5))
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.3)
            _ = waitUntil(1) { screen.contains(card.frame) }
        }
        shot("\(name) home")
        record("\(name) card: \(card.label) / \(card.value as? String ?? "")")
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        capturePlayer(name)
    }

    /// Music → Playlists → Plezy Mix → Play, then an album's Play: which player each opens. The server's own account,
    /// which holds the playlist.
    func testMusicPlaylistPlayAndAlbumPlay() throws {
        launchDev(arguments: ["--dev-server", Self.server])
        require("nav.libraries", timeout: 90, "the Libraries tab")
        let tab = app.tabBars.buttons.matching(identifier: "nav.libraries").firstMatch
        (tab.exists(within: 5) ? tab : element("nav.libraries")).tap()
        _ = element("libraries.screen").exists(within: 5)
        let steps = LibrarySteps(test: self)
        steps.pickLibrary("Music")
        steps.showLibraryTab("playlists")
        let mix = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Plezy Mix")).firstMatch
        if !mix.exists(within: 30) { return fail("Music's playlists list no Plezy Mix") }
        shot("music playlists")
        mix.tap()
        let play = require("music.play", timeout: 30, "Plezy Mix's Play")
        // The playlist's artwork loads before the shot.
        sleep(2)
        shot("plezy mix")
        play.tap()
        _ = waitUntil(10) { self.element("player.video").exists || self.element("music.mini").exists || self.element("music.np.screen").exists }
        shot("plezy mix play")
        record("after Plezy Mix's Play: " + openedPlayer())
        if element("player.video").exists {
            raiseControls()
            shot("plezy mix play controls")
        }

        app.terminate()
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open-music", "album=Sine Album"])
        let albumPlay = require("music.play", timeout: 90, "Sine Album's Play")
        // The album's artwork loads before the shot.
        sleep(3)
        shot("sine album")
        albumPlay.tap()
        _ = waitUntil(10) { self.element("player.video").exists || self.element("music.mini").exists || self.element("music.np.screen").exists }
        shot("sine album play")
        record("after Sine Album's Play: " + openedPlayer())
    }

    /// Search → `show` → its page.
    private func openShow(_ show: String) {
        let field = require("search.field", timeout: 90, "Search's field")
        let hasFocus = { field.value(forKey: "hasKeyboardFocus") as? Bool == true }
        for _ in 0..<3 where !hasFocus() {
            field.tap()
            _ = waitUntil(2, hasFocus)
        }
        field.typeText(show)
        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'search.result.' AND label == %@", show)).firstMatch
        if !result.exists(within: 30) { return fail("typing \(show) lists no \(show)") }
        _ = waitUntil(5) { result.isHittable }
        result.tap()
        require("detail.title", timeout: 30, "\(show)'s title")
    }

    /// Season 1 picked where the show has season chips (one with a single season has none), then the row of `title`
    /// tapped.
    private func tapEpisodeRow(_ title: String) {
        let season = element("detail.season.1")
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'detail.episode.' AND NOT (identifier ENDSWITH '.menu') AND label CONTAINS %@", title)).firstMatch
        if season.exists(within: 10), !season.isSelected { season.tap() }
        if !row.exists(within: 20) { return fail("Season 1 lists no \(title)") }
        _ = waitUntil(5) { row.isHittable }
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        shot("show page \(title)")
        row.tap()
    }

    /// The player as it opened: paused with its controls up (shot), then its queue sheet (shot), each with a note.
    private func capturePlayer(_ name: String) {
        if UIDevice.current.userInterfaceIdiom == .phone { XCUIDevice.shared.orientation = .landscapeLeft }
        require("player.video", timeout: 90, "the player")
        if !waitUntil(30, { self.state("firstFrame") == "true" }) { fail("no first frame: \(stateReading)") }
        // The episode plays a few seconds before the pause.
        sleep(4)
        raiseControls()
        tapControl("player.playPause")
        if !waitUntil(5, { self.element("player.playPause").label == "Play" }) { record("the video didn't pause: \(stateReading)") }
        raiseControls()
        shot("\(name) controls")
        record("\(name) controls: " + controlsReading())
        raiseControls()
        guard element("player.queue").exists(within: 3) else {
            record("\(name): no queue button")
            return shot("\(name) no queue button")
        }
        // The controls can go down between the look and the tap, which then lands on the video: tapped again.
        let sheet = element("player.queue.sheet")
        for _ in 0..<3 where !sheet.exists {
            tapControl("player.queue")
            _ = sheet.exists(within: 5)
        }
        if !sheet.exists { return fail("the queue button opens no sheet: \(stateReading)") }
        _ = element("player.menu.item.0").exists(within: 5)
        shot("\(name) queue")
        let rows = (0..<60).map { element("player.menu.item.\($0)") }.prefix { $0.exists }
        record("\(name) queue: " + rows.enumerated().map { "\($0.offset): \($0.element.label)\($0.element.isSelected ? " [playing]" : "")" }.joined(separator: " | "))
        dismissSheet(sheet, close: "player.menu.close")
    }

    private func raiseControls() {
        for _ in 0..<3 where state("controls") == "false" || !element("player.playPause").exists {
            if state("controls") == "false" { element("player.video").tap() }
            _ = waitUntil(3) { self.state("controls") == "true" && self.element("player.playPause").exists }
        }
    }

    /// A control tapped where it shows, the controls brought up first (they hide on their timer).
    private func tapControl(_ id: String) {
        for _ in 0..<3 {
            raiseControls()
            if let frame = try? element(id).snapshot().frame {
                app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
                return
            }
            _ = waitUntil(6) { self.state("controls") == "false" }
        }
        fail("no \(id) to tap: \(stateReading)")
    }
    #endif

    #if os(tvOS)
    /// The first episode opened directly (`--dev-play` by title), its controls up and paused, then its panel's queue tab.
    func testFirstEpisodeOnTv() throws {
        try launchAsNewAccount(["--dev-play", "\(Self.kind):Maestro Episode 1"])
        captureTvPlayer("episode 1")
    }

    /// The second episode opened directly.
    func testMiddleEpisodeOnTv() throws {
        try launchAsNewAccount(["--dev-play", "\(Self.kind):Maestro Episode 2"])
        captureTvPlayer("episode 2")
    }

    /// Yume Anime's first episode opened directly: nothing comes before it in its show.
    func testAnimeFirstEpisodeOnTv() throws {
        try launchAsNewAccount(["--dev-play", "\(Self.kind):Yume Dawn"])
        captureTvPlayer("anime episode 1")
    }

    private func captureTvPlayer(_ name: String) {
        require("player.video", timeout: 90, "the player")
        if !waitUntil(30, { self.state("firstFrame") == "true" }) { fail("no first frame: \(stateReading)") }
        // The episode plays a few seconds before the pause.
        sleep(4)
        for _ in 0..<3 where !element("player.scrub").exists {
            XCUIRemote.shared.press(.up)
            _ = element("player.scrub").exists(within: 3)
        }
        XCUIRemote.shared.press(.playPause)
        // The pause lands before the controls are raised; nothing signals it.
        sleep(2)
        for _ in 0..<3 where !element("player.scrub").exists {
            XCUIRemote.shared.press(.up)
            _ = element("player.scrub").exists(within: 3)
        }
        shot("\(name) controls")
        record("\(name) controls: " + tvReading())
        XCUIRemote.shared.press(.down)
        let tabs = ["chapters", "queue", "info"].map { "player.panel.\($0)" }
        guard waitUntil(5, { tabs.contains { self.element($0).exists } }) else {
            shot("\(name) no panel")
            return record("\(name): Down opened no panel")
        }
        // The panel's slide-in ends before the shot.
        sleep(1)
        shot("\(name) panel")
        // Up from a card to the tabs, then along them to Queue.
        let shown = tabs.filter { element($0).exists }
        for _ in 0..<8 where focusedId != "player.panel.queue" {
            if let from = shown.firstIndex(of: focusedId), let to = shown.firstIndex(of: "player.panel.queue") {
                XCUIRemote.shared.press(to > from ? .right : .left)
            } else {
                XCUIRemote.shared.press(.up)
            }
            _ = waitUntil(1) { self.focusedId == "player.panel.queue" }
        }
        _ = element("player.menu.item.0").exists(within: 5)
        shot("\(name) panel queue")
        let rows = (0..<60).map { element("player.menu.item.\($0)") }.prefix { $0.exists }
        record("\(name) queue (focus \(focusedId)): " + rows.enumerated().map { "\($0.offset): \($0.element.label)\($0.element.isSelected ? " [playing]" : "")" }.joined(separator: " | "))
    }

    private var focusedId: String {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        return (try? focused.snapshot())?.identifier ?? "nothing"
    }

    private func tvReading() -> String {
        ["player.title", "player.previous", "player.next", "player.position", "player.remaining"].map { id in
            let found = element(id)
            return found.exists ? "\(id)=\(found.label) enabled=\(found.isEnabled)" : "\(id)=absent"
        }.joined(separator: "; ") + "\nstate: \(stateReading)"
    }
    #endif

    #if os(macOS)
    /// The first episode opened directly (`--dev-play` by title), its controls up and paused, then its queue sheet.
    func testFirstEpisodeOnMac() throws {
        try launchAsNewAccount(["--dev-play", "\(Self.kind):Maestro Episode 1"])
        captureMacPlayer("episode 1")
    }

    /// Yume Anime's first episode opened directly: nothing comes before it in its show.
    func testAnimeFirstEpisodeOnMac() throws {
        try launchAsNewAccount(["--dev-play", "\(Self.kind):Yume Dawn"])
        captureMacPlayer("anime episode 1")
    }

    /// Plezy Mix (`--dev-playlist`, the server's own account, which holds it) and its Play: which player opens.
    func testMusicPlaylistPlayOnMac() throws {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-playlist", "\(Self.kind):Plezy Mix"])
        let play = require("music.play", timeout: 60, "Plezy Mix's Play")
        sleep(2)
        shot("plezy mix")
        play.click()
        sleep(8)
        shot("plezy mix play")
        record("after Plezy Mix's Play: " + openedPlayer())
    }

    /// The player as it opened: paused with its controls up (shot), then its queue sheet (shot), each with a note. A
    /// click on the video toggles playback here, so the controls come up on the pointer moving over it.
    private func captureMacPlayer(_ name: String) {
        require("player.video", timeout: 90, "the player")
        if !waitUntil(30, { self.state("firstFrame") == "true" }) { fail("no first frame: \(stateReading)") }
        sleep(4)
        clickControl("player.playPause")
        if !waitUntil(5, { self.element("player.playPause").label == "Play" }) { record("the video didn't pause: \(stateReading)") }
        hoverControls()
        shot("\(name) controls")
        record("\(name) controls: " + controlsReading())
        hoverControls()
        guard element("player.queue").exists(within: 3) else {
            record("\(name): no queue button")
            return shot("\(name) no queue button")
        }
        let sheet = element("player.queue.sheet")
        for _ in 0..<3 where !sheet.exists {
            clickControl("player.queue")
            _ = sheet.exists(within: 5)
        }
        if !sheet.exists { return fail("the queue button opens no sheet: \(stateReading)") }
        sleep(2)
        shot("\(name) queue")
        let rows = (0..<60).map { element("player.menu.item.\($0)") }.prefix { $0.exists }
        record("\(name) queue: " + rows.enumerated().map { "\($0.offset): \($0.element.label)\($0.element.isSelected ? " [playing]" : "")" }.joined(separator: " | "))
        dismissSheet(sheet, close: "player.menu.close")
    }

    /// The controls brought up by the pointer moving over the video (a hover where it already rests is no move).
    private func hoverControls() {
        let video = element("player.video")
        for _ in 0..<3 where state("controls") == "false" || !element("player.playPause").exists {
            video.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).hover()
            video.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
            _ = waitUntil(3) { self.state("controls") == "true" && self.element("player.playPause").exists }
        }
    }

    /// A control clicked, the controls brought up first (they hide on their timer).
    private func clickControl(_ id: String) {
        hoverControls()
        let control = element(id)
        guard control.exists(within: 3) else { return fail("no \(id) to click: \(stateReading)") }
        control.click()
    }
    #endif

    #if !os(tvOS)
    private func openedPlayer() -> String {
        "video player (player.video): \(element("player.video").exists); mini player (music.mini): \(element("music.mini").exists); "
            + "Mac music bar (music.bar): \(element("music.bar").exists); Now Playing (music.np.screen): \(element("music.np.screen").exists)"
    }

    private func controlsReading() -> String {
        func read(_ id: String) -> String {
            guard let found = try? element(id).snapshot() else { return "\(id)=absent" }
            let value = found.value as? String ?? ""
            return "\(id)=\(found.label)\(value.isEmpty ? "" : " (\(value))") enabled=\(found.isEnabled)"
        }
        let probe = element("player.nowPlaying")
        return ["player.title", "player.previous", "player.next", "player.position", "player.remaining"].map(read).joined(separator: "; ")
            + "\nstate: \(stateReading)\nnowPlaying: \(probe.exists ? (probe.value as? String ?? probe.label) : "absent")"
    }
    #endif

    #if !os(iOS)
    private static var kind: String { String(server.prefix { $0 != "=" }) }
    #endif

    private var stateReading: String {
        let probe = element("player.state")
        guard probe.exists else { return "" }
        if let value = probe.value as? String, !value.isEmpty { return value }
        return probe.label
    }

    private func state(_ key: String) -> String {
        stateReading.components(separatedBy: "; ").first { $0.hasPrefix("\(key)=") }.map { String($0.dropFirst(key.count + 1)) } ?? ""
    }

    private func record(_ text: String) {
        let note = XCTAttachment(string: text)
        note.name = "note \(text.prefix { $0 != ":" })"
        note.lifetime = .keepAlways
        add(note)
    }
}

/// A new account on a Jellyfin or Emby test server, added by the spec's administrator: every library, Maestro Show's
/// episodes unplayed, no password. `remove()` deletes it.
private struct TestAccount {
    struct Failure: LocalizedError, CustomStringConvertible {
        let description: String
        var errorDescription: String? { description }
    }

    /// The account's `--dev-server` spec.
    let spec: String
    private let kind: String
    private let base: String
    private let adminToken: String
    private let token: String
    private let user: String
    private static let client = "MediaBrowser Client=\"Plezy UI tests\", Device=\"ui-tests\", DeviceId=\"plezy-ui-tests-\(UUID().uuidString)\", Version=\"1\""

    static func create(on server: String) throws -> TestAccount {
        guard let equals = server.firstIndex(of: "="), let at = server.lastIndex(of: "@") else {
            throw Failure(description: "no <kind>=<user>:<password>@<url> in \(server)")
        }
        let kind = String(server[..<equals])
        guard kind == "jellyfin" || kind == "emby" else { throw XCTSkip("\(kind) has no account API here") }
        let credentials = server[server.index(after: equals)..<at].split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let base = String(server[server.index(after: at)...])
        let admin = try call("POST", "\(base)/Users/AuthenticateByName", token: nil, body: ["Username": credentials[0], "Pw": credentials.count > 1 ? credentials[1] : ""])
        guard let adminToken = admin["AccessToken"] as? String else { throw Failure(description: "the administrator's sign-in answered no token") }
        let name = "ui-tests-\(UUID().uuidString.prefix(8).lowercased())"
        _ = try call("POST", "\(base)/Users/New", token: adminToken, body: ["Name": name])
        let auth = try call("POST", "\(base)/Users/AuthenticateByName", token: nil, body: ["Username": name, "Pw": ""])
        guard let token = auth["AccessToken"] as? String, let user = (auth["User"] as? [String: Any])?["Id"] as? String else {
            throw Failure(description: "the new account's sign-in answered no token")
        }
        let account = TestAccount(spec: "\(kind)=\(name):@\(base)", kind: kind, base: base, adminToken: adminToken, token: token, user: user)
        do {
            try FreshAccountWatchState.blank(kind: kind, base: base, user: user) { try call($0, $1, token: token, body: $2) }
        } catch {
            try? account.remove()
            throw error
        }
        return account
    }

    func remove() throws {
        _ = try Self.call("DELETE", "\(base)/Users/\(user)", token: adminToken, body: nil)
    }

    /// The episode `title` of `show` `seconds` in, unwatched, played just now: in Continue Watching.
    func setResume(_ show: String, _ title: String, seconds: Int) throws {
        guard let id = try episodes(of: show).first(where: { $0.name == title })?.id else {
            throw Failure(description: "the test server has no \(title)")
        }
        let date = ISO8601DateFormatter().string(from: Date())
        try setUserData((id, title), ["PlaybackPositionTicks": seconds * 10_000_000, "Played": false, "LastPlayedDate": date])
    }

    /// The episodes of the show `title`, every season's.
    private func episodes(of title: String) throws -> [(id: String, name: String)] {
        let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let found = try Self.call("GET", "\(base)/Users/\(user)/Items?Recursive=true&IncludeItemTypes=Series&SearchTerm=\(query)", token: token, body: nil)
        guard let show = (found["Items"] as? [[String: Any]])?.first(where: { $0["Name"] as? String == title })?["Id"] as? String else {
            throw Failure(description: "the test server has no show \(title)")
        }
        let episodes = try Self.call("GET", "\(base)/Shows/\(show)/Episodes?UserId=\(user)", token: token, body: nil)
        return ((episodes["Items"] as? [[String: Any]]) ?? []).compactMap { item in
            guard let id = item["Id"] as? String, let name = item["Name"] as? String else { return nil }
            return (id, name)
        }
    }

    private func setUserData(_ episode: (id: String, name: String), _ body: [String: Any]) throws {
        let path = kind == "jellyfin" ? "/UserItems/\(episode.id)/UserData?userId=\(user)" : "/Users/\(user)/Items/\(episode.id)/UserData"
        _ = try Self.call("POST", base + path, token: token, body: body)
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
