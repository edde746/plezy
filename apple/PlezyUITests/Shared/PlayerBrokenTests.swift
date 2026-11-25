import XCTest
#if os(iOS)
import UIKit
#endif

/// The player's broken behaviours, each test asserting what the player should do, with shots and notes of what it does:
///
/// - Skip Intro over an episode's Intro chapter (Maestro Show's episodes: Intro 0–15 s, Episode 15–75 s, Credits
///   75–90 s), Skip Credits over the last episode's credits, up next over the credits of an episode with one after it.
/// - iPhone: paused, the controls stay up; played again, they hide on their timer.
/// - iPhone: Previous past 3 s says it restarts the episode, and at the start (paused) plays the episode before.
/// - iPhone (and the iPhone Duo): the picture keeps clear of the sensor housing, inside the controls' safe area.
/// - iPhone (the Duo's narrow landscape): the sleep timer's "Still watching?" card holds its texts whole, clear of the
///   centre transport.
/// - iPhone: locked, a tap shows "Hold to unlock" on a dark pill that reads over the picture; a held finger unlocks.
/// - Mac: the Live TV player's top bar shows no ghost "Plezy" under the channel's title.
/// - Apple TV: Up and Down on the remote zap the live channels.
/// - Apple TV: Skip Intro goes while a panel is open and is back as it closes.
/// - iPhone and the Mac: a shuffled movie library and Yume Anime's first episode from Continue Watching offer Next.
///
/// Each episode test signs in as a new account of the test server (`PLEZY_SERVER`, `--dev-server`'s
/// `<kind>=<user>:<password>@<url>`, an administrator; the default Jellyfin without it), on which nothing is played but
/// what the test sets, and deletes it as it ends; Live TV signs in as the server's account itself.
final class PlayerBrokenTests: PlezyUITestCase {
    private var account: BrokenTestAccount?
    private var notes = 0

    private static var server: String {
        let value = ProcessInfo.processInfo.environment["PLEZY_SERVER"] ?? ""
        return value.isEmpty ? "jellyfin=maestro:maestro@http://192.168.0.15:28096" : value
    }

    private static var kind: String { String(server.prefix { $0 != "=" }) }

    /// Every shot named after its test (`testKey`), its failure shot too: the run keeps one file per name.
    override func shot(_ name: String, of source: (any XCUIScreenshotProviding)? = nil) {
        super.shot("\(testKey) \(name)", of: source)
    }

    /// The test's short name: `-[PlayerBrokenTests testSkipIntroShowsInTheIntroChapter]` → `intro`.
    private var testKey: String {
        let keys = [
            "testSkipIntro": "intro", "testSkipCredits": "credits", "testUpNext": "upnext", "testPausedControls": "paused",
            "testPrevious": "previous", "testPictureKeeps": "housing", "testStillWatching": "stillwatching",
            "testLiveTopBar": "livebar", "testRemoteUpAndDown": "zap", "testShuffled": "shuffle", "testAnimeFrom": "anime",
        ]
        let method = name.split(separator: " ").last.map { String($0.dropLast()) } ?? name
        return keys.first { method.hasPrefix($0.key) }?.value ?? method
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

    // MARK: - Skip Intro, Skip Credits, up next

    /// Maestro Episode 2 from its start: Skip Intro (`player.skip`, its label naming the intro) shows within the Intro
    /// chapter (0–15 s), by itself as the playback enters it or with the controls brought up.
    func testSkipIntroShowsInTheIntroChapter() throws {
        try openEpisode("Maestro Episode 2")
        guard waitForFirstFrame() else { return }
        let seen = watchForPrompt("player.skip", labelled: "intro", until: 15, "skip intro")
        if seen == nil { XCTFail("no Skip Intro (player.skip) through the Intro chapter (0–15 s): \(stateReading)") }
    }

    #if os(tvOS)
    /// Apple TV: Skip Intro, shown in Maestro Episode 2's Intro chapter, goes while a panel is open (Down from the
    /// timeline opens it) and is back with the controls as the panel closes (Up from its tabs), still in the chapter.
    func testSkipIntroHidesUnderAnOpenPanel() throws {
        try openEpisode("Maestro Episode 2")
        guard waitForFirstFrame() else { return }
        guard watchForPrompt("player.skip", labelled: "intro", until: 15, "skip intro") != nil else {
            return fail("no Skip Intro (player.skip) through the Intro chapter (0–15 s): \(stateReading)")
        }
        raiseControls()
        let tabs = ["chapters", "queue"].map { "player.panel.\($0)" }
        for _ in 0..<3 where !tabs.contains(where: { element($0).exists }) {
            XCUIRemote.shared.press(.down)
            _ = waitUntil(3) { tabs.contains { self.element($0).exists } }
        }
        guard tabs.contains(where: { element($0).exists }) else { return fail("Down opens no panel: \(stateReading)") }
        _ = element("player.skip").waitForNonExistence(timeout: 5)
        shot("skip intro under the panel")
        if element("player.skip").exists { fail("Skip Intro shows over the open panel") }
        // Up from a card goes to the tabs; Up from a tab closes the panel.
        for _ in 0..<4 where !tabs.contains(focusedId) {
            XCUIRemote.shared.press(.up)
            _ = waitUntil(1) { tabs.contains(self.focusedId) }
        }
        guard tabs.contains(focusedId) else { return fail("no panel tab took focus: focus on \(focusedId)") }
        XCUIRemote.shared.press(.up)
        guard waitUntil(5, { !tabs.contains { self.element($0).exists } }) else { return fail("Up from the panel's tabs leaves it open") }
        raiseControls()
        if !element("player.skip").exists(within: 5) { fail("Skip Intro isn't back as the panel closed: \(stateReading)") }
        shot("skip intro after the panel")
    }

    private var focusedId: String {
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
        return (try? focused.snapshot())?.identifier ?? "nothing"
    }
    #endif

    #if !os(tvOS)
    /// The last episode (S2E2 Second Season Finale), its Credits chapter (75–90 s) picked from the chapters: Skip
    /// Credits (`player.skip`, its label naming the credits) shows there.
    func testSkipCreditsOnTheLastEpisode() throws {
        try openEpisode("Second Season Finale")
        guard waitForFirstFrame() else { return }
        _ = waitUntil(10) { self.position() >= 2 }
        guard seekToChapter("Credits", "skip credits") else { return }
        let seen = watchForPrompt("player.skip", labelled: "credit", until: 89.5, "skip credits")
        if seen == nil { XCTFail("no Skip Credits (player.skip) over the last episode's Credits chapter (75–90 s): \(stateReading)") }
    }

    /// Maestro Episode 2's Credits chapter (75–90 s), Episode 3 after it: up next (`player.upNext`) shows there.
    func testUpNextAtTheCredits() throws {
        try openEpisode("Maestro Episode 2")
        guard waitForFirstFrame() else { return }
        _ = waitUntil(10) { self.position() >= 2 }
        guard seekToChapter("Credits", "up next") else { return }
        let seen = watchForPrompt("player.upNext", labelled: nil, until: 89.5, "up next")
        if seen == nil { XCTFail("no up next (player.upNext) over Episode 2's Credits chapter (75–90 s): \(stateReading)") }
    }
    #endif

    #if os(iOS)
    // MARK: - iPhone: paused controls

    /// Paused with the controls up, they stay up for 8 s (Play/Pause still there); played again, they hide on their
    /// timer within 8 s.
    func testPausedControlsStayUp() throws {
        try openEpisode("Maestro Episode 2")
        guard waitForFirstFrame() else { return }
        _ = waitUntil(10) { self.position() >= 3 }
        tapControl("player.playPause")
        guard waitUntil(5, { self.playPauseLabel == "Play" }) else {
            return fail("the video didn't pause: \(stateReading)")
        }
        let paused = Date()
        shot("paused 0s controls")
        var hidAt: Double?
        var midShot = false
        var samples: [String] = []
        while Date().timeIntervalSince(paused) < 8.5 {
            let elapsed = Date().timeIntervalSince(paused)
            let controls = state("controls")
            let playPause = element("player.playPause").exists
            samples.append(String(format: "%.1fs controls=%@ playPause=%@", elapsed, controls, playPause ? "yes" : "no"))
            if hidAt == nil, controls == "false" || !playPause {
                hidAt = elapsed
                shot(String(format: "paused %.1fs controls gone", elapsed))
            }
            if !midShot, elapsed >= 4 {
                midShot = true
                shot("paused 4s")
            }
            // Sampled every quarter second over the 8.5 s the controls must stay up.
            Thread.sleep(forTimeInterval: 0.25)
        }
        shot("paused 8s")
        note("paused controls", samples.joined(separator: "\n") + "\nstate: \(stateReading)")
        if let hidAt { XCTFail(String(format: "paused, the controls went down %.1f s after the pause (Play/Pause gone)", hidAt)) }

        tapControl("player.playPause")
        let played = Date()
        if !waitUntil(5, { self.playPauseLabel == "Pause" || self.state("controls") == "false" }) {
            fail("Play didn't play: \(stateReading)")
        }
        let hid = waitUntil(10) { self.state("controls") == "false" }
        let after = Date().timeIntervalSince(played)
        shot("played controls")
        note("played controls", String(format: "after Play: controls down=%@ %.1f s after Play; %@", hid ? "yes" : "no", after, stateReading))
        if !hid || after > 8 { XCTFail(String(format: "played again, the controls stay up %.1f s after Play", after)) }
    }

    // MARK: - iPhone: Previous

    /// S2E1 paused at about 0:05: Previous says it restarts the episode (its label or value); pressed, it restarts it;
    /// pressed again at the start, paused, it plays the episode before (the title changes).
    func testPreviousSaysItRestartsAndGoesBackAtTheStart() throws {
        try openEpisode("Second Season Opener")
        guard waitForFirstFrame() else { return }
        _ = waitUntil(20) { self.position() >= 5 }
        tapControl("player.playPause")
        if !waitUntil(5, { self.playPauseLabel == "Play" }) { fail("the video didn't pause: \(stateReading)") }
        raiseControls()
        let before = state("item")
        guard let previous = try? element("player.previous").snapshot() else {
            return fail("no player.previous with the controls up: \(stateReading)")
        }
        let words = "\(previous.label) \(previous.value as? String ?? "")"
        shot("previous at 0-05 paused")
        note("previous past 3s", "at \(position()) s, '\(before)': player.previous label='\(previous.label)' value='\(previous.value as? String ?? "")' enabled=\(previous.isEnabled)\n" + controlsReading())
        if !words.lowercased().contains("restart") {
            XCTFail("past 3 s Previous restarts the episode but reads '\(words.trimmingCharacters(in: .whitespaces))': nothing says it restarts")
        }

        tapControl("player.previous")
        _ = waitUntil(5) { self.state("item") != before || self.position() <= 1.5 }
        raiseControls()
        shot("after first previous")
        let first = state("item")
        let restartedAt = position()
        note("after first previous", "item '\(first)' at \(restartedAt) s, Play/Pause '\(playPauseLabel)'\n" + controlsReading())
        if first == before, restartedAt > 1.5 { XCTFail("Previous at 0:05 neither restarted nor went back: at \(restartedAt) s") }

        // At the start, paused: the episode before.
        if playPauseLabel != "Play" {
            tapControl("player.playPause")
            _ = waitUntil(5) { self.playPauseLabel == "Play" }
        }
        let atStart = position()
        note("second previous", "pressing Previous again at \(atStart) s, paused=\(playPauseLabel == "Play"), item '\(state("item"))'")
        // Jellyfin's own client queues a series from the episode played on: with nothing before it, Previous is off at
        // the start, as it must be.
        guard element("player.previous").isEnabled else {
            note("second previous", "Previous is off at the start: the queue holds nothing before '\(first)'")
            return
        }
        tapControl("player.previous")
        let went = waitUntil(30) { let now = self.state("item"); return !now.isEmpty && now != first }
        // The new episode's picture loads before the shot; nothing signals it.
        sleep(3)
        raiseControls()
        shot("after second previous")
        note("after second previous", "item '\(state("item"))' at \(position()) s\n" + controlsReading())
        if !went { XCTFail("Previous at \(atStart) s while paused leaves the player on '\(first)': \(stateReading)") }
    }

    // MARK: - iPhone and Duo: the picture and the sensor housing

    /// The picture keeps clear of the sensor housing: inside the safe area the controls keep to (`player.bar.top`, 16 pt
    /// in from it). Either the picture (aspect-fit 16:9 in `player.surface`) lies inside it, or the screen shows black
    /// beside it, under the housing.
    func testPictureKeepsClearOfTheSensorHousing() throws {
        try openEpisode("Maestro Episode 2")
        guard waitForFirstFrame() else { return }
        // The controls that came up with the player hide on their 5 s timer: let them go and bring them up again, so
        // their bar is read early in a fresh 5 s, before the shot and the slower reads.
        _ = waitUntil(12) { self.state("controls") == "false" }
        raiseControls()
        guard let bar = try? element("player.bar.top").snapshot().frame else {
            return fail("no player.bar.top with the controls up: \(stateReading)")
        }
        shot("player controls up")
        let window = app.windows.firstMatch.frame
        let video = element("player.video").frame
        let surface = element("player.surface").exists ? element("player.surface").frame : video
        let safe = CGRect(x: bar.minX - 16, y: window.minY, width: bar.width + 32, height: window.height)
        let picture = Self.aspectFit(CGSize(width: 16, height: 9), in: surface)
        let frames = ["player.back", "player.title", "player.scrub", "player.playPause", "player.more"].map { id -> String in
            guard let found = try? element(id).snapshot() else { return "\(id)=absent" }
            return "\(id)=\(found.frame)"
        }
        note("housing frames", "window=\(window) player.video=\(video) player.surface=\(surface) player.bar.top=\(bar)\n"
            + "safe area the controls keep to: x \(safe.minX)–\(safe.maxX); 16:9 picture in the surface: \(picture)\n" + frames.joined(separator: "\n"))

        _ = waitUntil(12) { self.state("controls") == "false" }
        // The controls' fade ends before the shot and the pixel reads.
        sleep(1)
        shot("player controls down")
        var black: [String: Double] = [:]
        if safe.minX > window.minX + 1 { black["leading"] = brightShare(in: CGRect(x: window.minX, y: window.minY, width: safe.minX - window.minX, height: window.height)) }
        if safe.maxX < window.maxX - 1 { black["trailing"] = brightShare(in: CGRect(x: safe.maxX, y: window.minY, width: window.maxX - safe.maxX, height: window.height)) }
        note("housing pixels", "share of bright pixels beside the safe area (middle 40 % of the height): \(black)")
        let pictureInside = picture.minX >= safe.minX - 1 && picture.maxX <= safe.maxX + 1
        let bandsBlack = black.values.allSatisfy { $0 < 0.02 }
        if !pictureInside && !bandsBlack {
            XCTFail("the picture runs past the safe area the controls keep to (x \(safe.minX)–\(safe.maxX)): the 16:9 picture spans x \(picture.minX)–\(picture.maxX) in player.surface \(surface), and the screen beside the safe area shows it (bright share \(black))")
        }
    }

    // MARK: - iPhone (Duo): "Still watching?"

    /// The sleep timer (fast timers: 5 minutes run out in 30 s) asks "Still watching?"; with the controls up its card
    /// holds "Still watching?" and its Continue and Pause whole, and clears the centre transport.
    func testStillWatchingCardFitsBesideTheTransport() throws {
        try openEpisode("Maestro Episode 2", settings: ["player.fastTimers=true"])
        executionTimeAllowance = 900
        guard waitForFirstFrame() else { return }
        _ = waitUntil(10) { self.position() >= 2 }
        pickSleepTimer("5 minutes")
        if !waitUntil(5, { self.state("sleep") != "none" }) { return fail("picking 5 minutes starts no sleep timer: \(stateReading)") }
        let card = element("player.stillWatching")
        guard card.exists(within: 75) else { return fail("the sleep timer ran out without asking: \(stateReading)") }
        // The card's entrance animation ends before the shot.
        sleep(1)
        shot("still watching")
        note("still watching as it came", cardReading())
        raiseControls()
        // The controls' fade-in ends before the shot.
        sleep(1)
        shot("still watching controls up")
        // The frames first: the reading after them takes long enough on a slow simulator for the card to run out.
        guard let frame = try? card.snapshot().frame else { return fail("the card went before the controls came up") }
        let buttons = ["player.stillWatching.keepWatching", "player.stillWatching.pause"].map { try? element($0).snapshot().frame }
        let transport = ["player.previous", "player.playPause", "player.next"].compactMap { try? element($0).snapshot().frame }
        note("still watching controls up", cardReading())
        let titleFont = UIFont.preferredFont(forTextStyle: .headline)
        let buttonFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .semibold)
        let titleWidth = ceil(("Still watching?" as NSString).size(withAttributes: [.font: titleFont]).width)
        if frame.width - 32 < titleWidth - 1 {
            XCTFail("the card is \(frame.width) pt wide: \(frame.width - 32) pt inside it for 'Still watching?', which needs \(titleWidth)")
        }
        for ((id, text), button) in zip([("player.stillWatching.keepWatching", "Continue"), ("player.stillWatching.pause", "Pause")], buttons) {
            guard let button else {
                XCTFail("the card has no \(id)")
                continue
            }
            let needs = ceil((text as NSString).size(withAttributes: [.font: buttonFont]).width) + 24
            if button.width < needs - 1 { XCTFail("\(id) is \(button.width) pt wide; '\(text)' needs \(needs)") }
        }
        if let overlap = transport.first(where: { $0.intersects(frame) }) {
            XCTFail("the card \(frame) overlaps the centre transport at \(overlap)")
        }
    }

    // MARK: - iPhone: the locked screen

    /// Locked from the options menu (in landscape on iPhone), the picture playing: a tap shows "Hold to unlock"
    /// (`player.unlock`) on a dark pill, whose ground stays dark enough over what is under it (the frame on iPhone, the
    /// letterbox on the iPad's taller screen) for its white text to read 4.5:1 over white; a finger held on it 1.6 s
    /// unlocks, the controls back. Mid-hold shots come from a run's RECORD=1 screen.mp4.
    func testHoldOnThePillUnlocks() throws {
        try openEpisode("Maestro Episode 2")
        guard waitForFirstFrame() else { return }
        _ = waitUntil(10) { self.position() >= 2 }
        guard openMenu("player.more") else { return }
        guard let lock = menuEntry("Lock Screen") else { return fail("the options menu has no Lock Screen") }
        lock.tap()
        let shield = element("player.lockShield")
        guard shield.exists(within: 5) else { return fail("Lock screen locks nothing: \(stateReading)") }
        let unlock = element("player.unlock")
        for _ in 0..<2 where !unlock.exists {
            shield.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap()
            _ = unlock.exists(within: 2)
        }
        guard let pill = try? unlock.snapshot() else { return fail("a tap on the locked screen shows no player.unlock") }
        if pill.label != "Hold to unlock" { fail("the pill reads '\(pill.label)', not 'Hold to unlock'") }
        shot("locked pill")
        // Black 60 % over white is grey 102; white text reads 4.5:1 down to grey 118.
        guard let ground = medianGrey(in: pill.frame) else { return fail("the screen's pixels under player.unlock \(pill.frame) are unreadable") }
        note("pill ground", "player.unlock \(pill.frame): median grey \(ground)")
        if ground > 118 { fail("the pill's ground is grey \(ground) over the frame: its white text reads under 4.5:1") }
        // The pill goes 3 s after it showed: once gone, a tap shows it again with the whole 3 s ahead for the hold (a
        // hold that starts as the pill goes falls on the shield).
        if !waitUntil(5, { !unlock.exists }) { return fail("player.unlock is still up 5 s after it showed") }
        shield.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap()
        guard unlock.exists(within: 2) else { return fail("a second tap on the locked screen shows no player.unlock") }
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: pill.frame.midX, dy: pill.frame.midY)).press(forDuration: 1.6)
        if !waitUntil(3, { !shield.exists }) { return fail("a 1.6 s hold on the pill leaves the screen locked: \(stateReading)") }
        raiseControls()
        shot("after the hold")
        if !element("player.playPause").exists(within: 3) { fail("unlocked, the controls aren't back: \(stateReading)") }
    }
    #endif

    #if os(macOS)
    // MARK: - Mac: Live TV's top bar

    /// The first channel tuned, its controls up: the top bar shows the channel's title and no "Plezy" (the window's
    /// title) under or beside it.
    func testLiveTopBarShowsNoGhostTitle() throws {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open", "live_tv"])
        continueAfterFailure = true
        let channel = require("livetv.guide.channel.0", timeout: 90, "the guide's channels")
        sleep(3)
        channel.click()
        guard require("player.video", timeout: 30, "the player").exists else { return }
        sleep(6)
        hoverControls()
        shot("live player top bar")
        let window = app.windows.firstMatch
        let top = window.frame.minY + 120
        var inTop: [String] = []
        var ghosts: [String] = []
        func walk(_ node: any XCUIElementSnapshot) {
            let words = [node.label, node.title, node.value as? String ?? ""].filter { !$0.isEmpty }
            if node.frame.minY < top, node.elementType != .window, node.elementType != .menuBar, node.elementType != .menuBarItem,
               node.elementType != .menuItem, node.elementType != .menu, !words.isEmpty {
                inTop.append("\(node.elementType.rawValue) id='\(node.identifier)' \(words) \(node.frame)")
                if words.contains("Plezy") { ghosts.append("\(node.elementType.rawValue) id='\(node.identifier)' at \(node.frame)") }
            }
            node.children.forEach(walk)
        }
        if let root = try? window.snapshot() { walk(root) }
        note("live top bar", "window title '\(window.title)' frame \(window.frame)\nelements in the top 120 pt:\n" + inTop.joined(separator: "\n"))
        if !ghosts.isEmpty { XCTFail("the live player's top shows 'Plezy': \(ghosts)") }
    }
    #endif

    #if os(tvOS)
    // MARK: - Apple TV: zapping

    /// The first channel tuned, the controls gone down: Up zaps to another channel (the video's label, the channel,
    /// changes), Down zaps back.
    func testRemoteUpAndDownZapLiveChannels() throws {
        launchDev(arguments: ["--dev-server", Self.server, "--dev-open", "live_tv"])
        continueAfterFailure = true
        let channel = require("livetv.guide.channel.0", timeout: 90, "the guide's channels")
        _ = waitUntil(5) { self.tvHasFocus(channel) }
        for _ in 0..<3 where !tvHasFocus(channel) {
            XCUIRemote.shared.press(.left)
            _ = waitUntil(1) { self.tvHasFocus(channel) }
        }
        if !tvHasFocus(channel) { return fail("the first channel takes no focus") }
        XCUIRemote.shared.press(.select)
        let video = require("player.video", timeout: 30, "the player")
        guard waitUntil(30, { !video.label.isEmpty }) else { return fail("the video names no channel") }
        let tuned = video.label
        // The channel playing (a live stream can take half a minute to open) before the remote's presses.
        if !waitUntil(60, { self.state("firstFrame") == "true" }) { return fail("the channel never plays: \(stateReading)") }
        // The live picture settles before the shot; nothing signals it.
        sleep(3)
        shot("live playing")
        _ = waitUntil(20) { self.state("controls") == "false" }
        shot("live controls down")
        note("live tuned", "video '\(tuned)'; \(stateReading)")
        XCUIRemote.shared.press(.up)
        let zapped = waitUntil(15) { !video.label.isEmpty && video.label != tuned }
        // The new channel's picture settles before the shot.
        sleep(2)
        shot("live after up")
        note("live after up", "video '\(video.label)' (was '\(tuned)'); title \(element("player.title").exists ? element("player.title").label : "absent"); \(stateReading)")
        if !zapped { XCTFail("Up with the controls down leaves the channel at '\(tuned)': \(stateReading)") }
        let up = video.label
        _ = waitUntil(20) { self.state("controls") == "false" }
        XCUIRemote.shared.press(.down)
        let back = waitUntil(15) { video.label != up }
        // The new channel's picture settles before the shot.
        sleep(2)
        shot("live after down")
        note("live after down", "video '\(video.label)' (after Up '\(up)', first '\(tuned)'); \(stateReading)")
        if !back { XCTFail("Down leaves the channel at '\(up)': \(stateReading)") }
    }

    private func tvHasFocus(_ target: XCUIElement) -> Bool {
        guard target.exists else { return false }
        if target.hasFocus { return true }
        if target.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch.exists { return true }
        let cell = app.cells.containing(.any, identifier: target.identifier).firstMatch
        return cell.exists && cell.hasFocus
    }
    #endif

    #if !os(tvOS)
    // MARK: - Next in a shuffled library and from Continue Watching

    /// Movies → Shuffle: the player offers Previous and Next, Next enabled (the queue has more films).
    func testShuffledMoviesOfferNext() throws {
        try launchAsNewAccount(["--dev-open", "libraries"])
        require("libraries.screen", timeout: 60, "Libraries")
        LibrarySteps(test: self).pickLibrary("Movies")
        _ = waitUntil(5) { self.element("libraries.shuffle").exists || self.element("libraries.more").exists }
        shot("movies")
        pressShuffle()
        #if os(iOS)
        XCUIDevice.shared.orientation = .landscapeLeft
        #endif
        guard require("player.video", timeout: 90, "the shuffled player").exists, waitForFirstFrame() else { return }
        _ = waitUntil(10) { self.position() >= 3 }
        raiseControls()
        note("shuffle controls", controlsReading())
        requireNext("in the shuffled movies")
        shot("shuffle controls")
    }

    /// Yume Anime's first episode, 40 s in, from Continue Watching: Next is enabled within 2 s of the first frame and
    /// again some 9 s in.
    func testAnimeFromContinueWatchingOffersNext() throws {
        try launchAsNewAccount([]) { try $0.setResume("Yume Anime", "Yume Dawn", seconds: 40) }
        let hub = require("hub.continue_watching", timeout: 60, "Continue Watching")
        let card = hub.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'card.'")).firstMatch
        if !card.exists(within: 30) { return fail("Continue Watching holds no card") }
        // The row's layout and artwork settle before the scroll and the shot; nothing signals it.
        sleep(2)
        #if os(iOS)
        let screen = app.windows.firstMatch.frame
        for _ in 0..<6 where !screen.contains(card.frame) {
            let towardsEnd = card.frame.maxX > screen.maxX
            let from = hub.coordinate(withNormalizedOffset: CGVector(dx: towardsEnd ? 0.7 : 0.3, dy: 0.5))
            let to = hub.coordinate(withNormalizedOffset: CGVector(dx: towardsEnd ? 0.37 : 0.63, dy: 0.5))
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.3)
            _ = waitUntil(1) { screen.contains(card.frame) }
        }
        #endif
        shot("anime continue watching")
        note("anime card", "\(card.label) / \(card.value as? String ?? "")")
        #if os(iOS)
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        #else
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).click()
        #endif
        guard require("player.video", timeout: 90, "the player").exists else { return }
        guard waitUntil(30, { self.state("firstFrame") == "true" }) else { return fail("no first frame: \(stateReading)") }
        let first = Date()
        raiseControls()
        let early = controlsReading()
        let earlyAt = Date().timeIntervalSince(first)
        shot("anime first frame controls")
        note("anime first frame", String(format: "%.1f s after the first frame:\n", earlyAt) + early)
        requireNext(String(format: "%.1f s after the first frame", earlyAt))
        // The second check comes 9 s after the first frame, whatever the first one took.
        let wait = 9 - Date().timeIntervalSince(first)
        if wait > 0 { Thread.sleep(forTimeInterval: wait) }
        raiseControls()
        let lateAt = Date().timeIntervalSince(first)
        shot("anime 9s controls")
        note("anime 9s", String(format: "%.1f s after the first frame:\n", lateAt) + controlsReading())
        requireNext(String(format: "%.1f s after the first frame", lateAt))
    }

    /// Fails unless Previous and Next show and Next is enabled; notes what they read.
    private func requireNext(_ when: String) {
        raiseControls()
        let previous = try? element("player.previous").snapshot()
        let next = try? element("player.next").snapshot()
        note("checked", "\(when): player.previous \(previous.map { "'\($0.label)' enabled=\($0.isEnabled)" } ?? "absent"); "
            + "player.next \(next.map { "'\($0.label)' enabled=\($0.isEnabled)" } ?? "absent"); controls=\(state("controls"))")
        if previous == nil { XCTFail("\(when): no player.previous") }
        guard let next else { return XCTFail("\(when): no player.next") }
        if !next.isEnabled { XCTFail("\(when): player.next is disabled; Now Playing: \(reading(element("player.nowPlaying")))") }
    }

    /// Library's Shuffle: in the header row, else (a phone's narrow row) in its ⋯ menu.
    private func pressShuffle() {
        let shuffle = element("libraries.shuffle")
        #if os(macOS)
        guard shuffle.exists(within: 10) else { return fail("Movies offers no Shuffle") }
        shuffle.click()
        #else
        if !shuffle.exists(within: 5) {
            let more = require("libraries.more", timeout: 10, "the ⋯ menu")
            let glyph = more.images["ellipsis"]
            (glyph.exists ? glyph : more).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            guard shuffle.exists(within: 10) else { return fail("Movies offers no Shuffle, not in its ⋯ menu either") }
            shot("shuffle in more")
        }
        shuffle.tap()
        #endif
    }

    /// The chapters sheet's row named `chapter` picked: the playback seeks there and the sheet closes.
    private func seekToChapter(_ chapter: String, _ name: String) -> Bool {
        let sheet = element("player.chapters.sheet")
        for _ in 0..<3 where !sheet.exists {
            tapControl("player.chapters")
            _ = sheet.exists(within: 5)
        }
        guard sheet.exists else {
            fail("the chapters button opens no sheet: \(stateReading)")
            return false
        }
        _ = element("player.menu.item.0").exists(within: 5)
        let rows = (0..<20).map { element("player.menu.item.\($0)") }.prefix { $0.exists }
        guard let row = rows.first(where: { $0.label.contains(chapter) || $0.title.contains(chapter) }) else {
            fail("the chapters list no \(chapter): \(rows.map(\.label))")
            return false
        }
        let picked = row.label.isEmpty ? row.title : row.label
        shot("\(name) chapters")
        #if os(macOS)
        row.click()
        #else
        row.tap()
        #endif
        _ = waitUntil(5) { !sheet.exists }
        note("\(name) seek", "picked \(picked): at \(position()) s; \(stateReading)")
        return true
    }
    #endif

    // MARK: - Steps

    /// Signs in as a new account of the server and launches the app as it, with `arguments` after it, the test going on
    /// past a failed check (each check reports what it saw).
    private func launchAsNewAccount(settings: [String] = [], _ arguments: [String], prepare: (BrokenTestAccount) throws -> Void = { _ in }) throws {
        executionTimeAllowance = 600
        let account = try BrokenTestAccount.create(on: Self.server)
        self.account = account
        try prepare(account)
        launchDev(settings: settings, arguments: ["--dev-server", account.spec] + arguments)
        continueAfterFailure = true
    }

    /// The episode `title` opened directly (`--dev-play` by title) as a new account, from its start; a phone turned to
    /// landscape, which the player holds.
    private func openEpisode(_ title: String, settings: [String] = []) throws {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone { XCUIDevice.shared.orientation = .landscapeLeft }
        #endif
        try launchAsNewAccount(settings: settings, ["--dev-play", "\(Self.kind):\(title)"])
        require("player.video", timeout: 90, "the player opening on \(title)")
    }

    private func waitForFirstFrame() -> Bool {
        if waitUntil(30, { self.state("firstFrame") == "true" }) { return true }
        fail("no first frame: \(stateReading)")
        return false
    }

    /// Looks for the prompt `id` (its label containing `labelled`, any case, where given) twice a second until the
    /// position passes `until` s, the item playing changes or the player goes; once the position passes 4 s past the
    /// start of the watch (the prompt's own seconds) the controls come up, with which it shows too. Shots after the
    /// first look, as it shows (or with the controls up), and a note of every sample. Returns the label it showed with.
    private func watchForPrompt(_ id: String, labelled: String?, until: Double, _ name: String) -> String? {
        let start = position()
        let item = state("item")
        var samples: [String] = []
        var seen: String?
        var raised = false
        var first = true
        let deadline = Date().addingTimeInterval(120)
        while Date() < deadline, element("player.video").exists {
            let at = position()
            let prompt = element(id)
            let label = prompt.exists ? prompt.label : ""
            let now = state("item")
            samples.append(String(format: "%.1fs %@=%@ controls=%@", at, id, prompt.exists ? "'\(label)'" : "absent", state("controls"))
                + (now == item ? "" : " item='\(now)'"))
            if prompt.exists, labelled.map({ label.lowercased().contains($0) }) ?? true {
                seen = label
                shot("\(name) shown")
                break
            }
            if at >= until || now != item { break }
            if first {
                first = false
                shot("\(name) start")
                continue
            }
            if !raised, at >= start + 4 {
                raised = true
                raiseControls()
                shot("\(name) controls up")
                continue
            }
            // Samples twice a second while the position runs to `until`.
            Thread.sleep(forTimeInterval: 0.5)
        }
        if seen == nil { shot("\(name) end") }
        note("\(name) samples", samples.joined(separator: "\n") + "\nstate: \(stateReading)")
        return seen
    }

    /// Shows the controls if they went down: a tap on the video (iOS) while the store has them down, the pointer moved
    /// over the video (the Mac), Up (Apple TV).
    private func raiseControls() {
        #if os(macOS)
        hoverControls()
        #elseif os(tvOS)
        for _ in 0..<3 where state("controls") == "false" {
            XCUIRemote.shared.press(.up)
            _ = waitUntil(3) { self.state("controls") == "true" }
        }
        #else
        // While a card holds the centre transport's place (an iPhone Duo's still-watching card), Play/Pause isn't there.
        func up() -> Bool {
            state("controls") == "true" && (element("player.playPause").exists || element("player.stillWatching").exists)
        }
        for _ in 0..<3 where !up() {
            if state("controls") == "false" { element("player.video").tap() }
            _ = waitUntil(3) { up() }
        }
        #endif
    }

    #if os(macOS)
    /// The controls brought up by the pointer moving over the video (a hover where it already rests is no move).
    private func hoverControls() {
        let video = element("player.video")
        for _ in 0..<3 where state("controls") == "false" || !element("player.playPause").exists {
            video.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).hover()
            video.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
            _ = waitUntil(3) { self.state("controls") == "true" && self.element("player.playPause").exists }
        }
    }
    #endif

    #if !os(tvOS)
    /// A control tapped (clicked) where it shows, the controls brought up first (they hide on their timer).
    private func tapControl(_ id: String) {
        for _ in 0..<3 {
            raiseControls()
            #if os(macOS)
            let control = element(id)
            if control.exists(within: 3) {
                control.click()
                return
            }
            #else
            if let frame = try? element(id).snapshot().frame {
                app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
                return
            }
            _ = waitUntil(6) { self.state("controls") == "false" }
            #endif
        }
        fail("no \(id) to tap: \(stateReading)")
    }

    private var playPauseLabel: String {
        (try? element("player.playPause").snapshot().label) ?? ""
    }

    private func controlsReading() -> String {
        func read(_ id: String) -> String {
            guard let found = try? element(id).snapshot() else { return "\(id)=absent" }
            let value = found.value as? String ?? ""
            return "\(id)=\(found.label)\(value.isEmpty ? "" : " (\(value))") enabled=\(found.isEnabled)"
        }
        return ["player.title", "player.previous", "player.next", "player.playPause", "player.position", "player.remaining"].map(read).joined(separator: "; ")
            + "\nstate: \(stateReading)\nnowPlaying: \(reading(element("player.nowPlaying")))\nposition: \(position())"
    }
    #endif

    #if os(iOS)
    /// The still-watching card's frames and texts, with the transport's.
    private func cardReading() -> String {
        let ids = ["player.stillWatching", "player.stillWatching.countdown", "player.stillWatching.keepWatching", "player.stillWatching.pause",
                   "player.previous", "player.playPause", "player.next", "player.upNext", "player.skip"]
        let parts = ids.map { id -> String in
            guard let found = try? element(id).snapshot() else { return "\(id)=absent" }
            return "\(id) '\(found.label)' \(found.frame)"
        }
        let texts = (try? element("player.stillWatching").snapshot().children.map { "\($0.elementType.rawValue) '\($0.label)' \($0.frame)" }) ?? []
        return parts.joined(separator: "\n") + "\ncard's children:\n" + texts.joined(separator: "\n") + "\nstate: \(stateReading)"
    }

    /// The options menu's Sleep Timer (title-cased, as Apple menus show English), then its `choice`.
    private func pickSleepTimer(_ choice: String) {
        guard openMenu("player.more") else { return }
        guard let page = menuEntry("Sleep Timer") else { return fail("the options menu has no Sleep Timer") }
        page.tap()
        guard let entry = menuEntry(choice) else { return fail("the sleep timer menu has no \(choice)") }
        entry.tap()
    }

    /// Taps the menu button `id`: tapped again from scratch where its tap came as the controls went and opened nothing.
    private func openMenu(_ id: String) -> Bool {
        for attempt in 0..<3 {
            if attempt > 0, state("controls") == "true" { _ = waitUntil(6) { self.state("controls") == "false" } }
            raiseControls()
            guard let frame = try? element(id).snapshot().frame else { continue }
            // The options button reports the frame of the whole capsule of menu buttons it ends: tapped at its end.
            let x = frame.width > 60 ? frame.maxX - 22 : frame.midX
            app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: frame.midY)).tap()
            if app.collectionViews.firstMatch.exists(within: 3) { return true }
        }
        fail("\(id) opens no menu: \(stateReading)")
        return false
    }

    /// The open menu's entry `label` (an entry with a second line counts by its first), dragged into the menu's view
    /// where an iPhone's menu holds it out of view (PlayerSheetsTests' `optionalEntry`).
    private func menuEntry(_ label: String) -> XCUIElement? {
        let match = app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", label, "\(label),")).firstMatch
        let phone = UIDevice.current.userInterfaceIdiom == .phone
        let found = match.exists(within: 5)
        guard found || phone, let menu = app.collectionViews.allElementsBoundByIndex
            .filter({ $0.exists && $0.frame.width < app.frame.width }).min(by: { $0.frame.width < $1.frame.width }) else {
            return found ? match : nil
        }
        let list = menu.frame.insetBy(dx: 0, dy: 8)
        let view = CGRect(x: list.minX, y: list.minY, width: list.width, height: list.height * (phone ? 0.75 : 1))
        func drag(_ distance: CGFloat) {
            let distance = max(-view.height * 0.8, min(view.height * 0.8, distance))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: view.midX, dy: view.midY + distance / 2))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -distance)), withVelocity: .slow, thenHoldForDuration: 0.3)
            // The list's scroll settles before its entries are compared.
            Thread.sleep(forTimeInterval: 0.5)
        }
        let entries = { (try? menu.snapshot().children.map(\.frame)) ?? [] }
        var downTheList = true
        for _ in 0..<16 {
            guard match.exists else {
                let before = entries()
                drag(downTheList ? view.height / 2 : -view.height / 2)
                if !match.exists, entries() == before {
                    if !downTheList { return nil }
                    downTheList = false
                }
                continue
            }
            var frame = match.frame
            for _ in 0..<10 {
                // The entry's frame is read until it stops moving.
                Thread.sleep(forTimeInterval: 0.2)
                guard match.exists, match.frame != frame else { break }
                frame = match.frame
            }
            if frame.height > 0, frame.minY >= view.minY, frame.maxY <= view.maxY { return match }
            drag(frame.midY - view.midY)
        }
        return match.exists ? match : nil
    }

    /// The share of pixels brighter than a dark grey in `area` (window points) of the screen as the device shows it,
    /// over the middle 40 % of its height (clear of a letterbox's bars).
    private func brightShare(in area: CGRect) -> Double {
        let band = CGRect(x: area.minX, y: area.minY + area.height * 0.3, width: area.width, height: area.height * 0.4)
        guard let pixels = greys(in: band) else { return 1 }
        return Double(pixels.reduce(0) { $0 + ($1 > 40 ? 1 : 0) }) / Double(max(pixels.count, 1))
    }

    /// The median grey (0–255) of a capsule's inside, `area` in window points, clear of its round ends.
    private func medianGrey(in area: CGRect) -> Int? {
        guard let pixels = greys(in: area.insetBy(dx: area.height / 2, dy: 2)), !pixels.isEmpty else { return nil }
        return Int(pixels.sorted()[pixels.count / 2])
    }

    /// The grey of each pixel in `area` (window points) of the screen as the device shows it. The app's first window
    /// can be an empty one (the iPad's is 0 × 0): the screen's width is its widest.
    private func greys(in area: CGRect) -> [UInt8]? {
        let image = Self.upright(XCUIScreen.main.screenshot().image)
        guard let cgImage = image.cgImage,
              let screenWidth = app.windows.allElementsBoundByIndex.map(\.frame.width).max(), screenWidth > 0 else { return nil }
        let scale = CGFloat(cgImage.width) / screenWidth
        let band = CGRect(x: area.minX * scale, y: area.minY * scale, width: area.width * scale, height: area.height * scale).integral
        guard let crop = cgImage.cropping(to: band) else { return nil }
        let width = crop.width, height = crop.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    /// `image` as the device shows it: a portrait-shaped capture of a landscape screen turned a quarter.
    private static func upright(_ image: UIImage) -> UIImage {
        let orientation = XCUIDevice.shared.orientation
        guard orientation.isLandscape, let cgImage = image.cgImage, cgImage.height > cgImage.width else { return image }
        let turned = UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation == .landscapeLeft ? .left : .right)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: turned.size.width * image.scale, height: turned.size.height * image.scale)
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in turned.draw(in: CGRect(origin: .zero, size: size)) }
    }

    private static func aspectFit(_ aspect: CGSize, in frame: CGRect) -> CGRect {
        let scale = min(frame.width / aspect.width, frame.height / aspect.height)
        let size = CGSize(width: aspect.width * scale, height: aspect.height * scale)
        return CGRect(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2, width: size.width, height: size.height)
    }
    #endif

    // MARK: - Probes

    /// A probe's reading: its value, else (the Mac reports no plain element's value) its label.
    private func reading(_ probe: XCUIElement) -> String {
        guard let found = try? probe.snapshot() else { return "absent" }
        if let value = found.value as? String, !value.isEmpty { return value }
        return found.label
    }

    private var stateReading: String { reading(element("player.state")) }

    private func state(_ key: String) -> String {
        stateReading.components(separatedBy: "; ").first { $0.hasPrefix("\(key)=") }.map { String($0.dropFirst(key.count + 1)) } ?? ""
    }

    /// The position in seconds (`player.livePosition`: `position=12.3`).
    private func position() -> Double {
        Double(reading(element("player.livePosition")).dropFirst("position=".count)) ?? -1
    }

    /// A note in the run's report, `name` numbered in the order taken.
    private func note(_ name: String, _ text: String) {
        notes += 1
        let attachment = XCTAttachment(string: text)
        attachment.name = String(format: "note %@ %02d %@", testKey, notes, name)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

/// A new account on a Jellyfin or Emby test server, added by the spec's administrator: every library, Maestro Show's
/// and Yume Anime's episodes unplayed, no password. `remove()` deletes it.
private struct BrokenTestAccount {
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

    static func create(on server: String) throws -> BrokenTestAccount {
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
        let account = BrokenTestAccount(spec: "\(kind)=\(name):@\(base)", kind: kind, base: base, adminToken: adminToken, token: token, user: user)
        // A new Jellyfin account can come with the watch state of an account deleted before it.
        for show in ["Maestro Show", "Yume Anime"] {
            for episode in try account.episodes(of: show) {
                try account.setUserData(episode, ["PlaybackPositionTicks": 0, "Played": false])
            }
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
