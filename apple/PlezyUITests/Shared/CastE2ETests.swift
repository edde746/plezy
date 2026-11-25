import XCTest

/// Casting between two devices on the network, no development receiver or sender: run on demand, the receiver's run
/// beside the sender's, each driven by its run's values (they skip without them).
///
/// This device as the receiver (`PLEZY_CAST_WAIT`: how long it waits for a sender's pairing question, in seconds). Its
/// question's code goes to `receiver-code.txt` in `PLEZY_CAST_SHARE` (a folder both runs reach), else in the run's
/// exchange folder; Allow takes the cast. Then the cast's player (the video player, or music's Now Playing) shows
/// "Casting from <sender>", and it stays up `PLEZY_CAST_HOLD` seconds (default 60), a shot every 10 s, until the cast
/// ends (the player gone). Signed in to `PLEZY_DEV_SERVER` where set.
final class CastE2EReceiverTests: CastE2ETestCase {
    func testReceiveACast() throws {
        guard let wait = Self.seconds("PLEZY_CAST_WAIT") else { throw XCTSkip("PLEZY_CAST_WAIT not set: a two-device run's") }
        let hold = Self.seconds("PLEZY_CAST_HOLD") ?? 60
        // The wait and the hold, and the launch and the player's start around them: past the run's 5 min allowance.
        executionTimeAllowance = wait + hold + 300
        let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        launchDev(
            arguments: (server.isEmpty ? [] : ["--dev-server", server]) + ["--dev-open", "settings"]
        )
        let code = require("cast.prompt.code", timeout: wait, "a sender's pairing question")
        let text = Self.text(code)
        write(text, to: "receiver-code.txt")
        shot("receiver prompt")
        activate("cast.prompt.allow", "Allow")
        if !waitUntil(10, { !self.element("cast.prompt.allow").exists }) { fail("Allow leaves the question up") }

        let video = element("player.castingFrom")
        let music = element("music.np.castingFrom")
        let found = waitUntil(90) {
            if video.exists || music.exists { return true }
            self.openNowPlaying()
            self.raiseControls()
            _ = waitUntil(1) { video.exists || music.exists }
            return video.exists || music.exists
        }
        if !found { fail("no player says Casting from after Allow") }
        let line = video.exists ? video : music
        XCTAssertTrue(Self.text(line).hasPrefix("Casting from"), "the line reads \(Self.text(line))")
        shot("casting from")

        let deadline = Date().addingTimeInterval(hold)
        var index = 0
        while Date() < deadline {
            // Holds the cast and checks every 10 s whether it ended: the interval is the observation period.
            Thread.sleep(forTimeInterval: 10)
            if !element("player.video").exists && !element("music.np.screen").exists && !musicBar.exists {
                shot("cast ended")
                return
            }
            index += 1
            shot("holding \(index)")
        }
    }

    /// The Mac's playback bar, iPhone and iPad's mini-player: the music cast plays there.
    private var musicBar: XCUIElement {
        element("music.bar").exists ? element("music.bar") : element("music.mini")
    }

    /// Music's Now Playing from its bar, where the cast plays music and Now Playing isn't up.
    private func openNowPlaying() {
        guard !element("music.np.screen").exists else { return }
        for id in ["music.bar.open", "music.mini.open"] where element(id).exists {
            #if os(macOS)
            element(id).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
            #elseif os(iOS)
            element(id).tap()
            #endif
            return
        }
    }

    /// The video player's controls up where they are down: the line is in them.
    private func raiseControls() {
        guard element("player.video").exists, !element("player.title").exists else { return }
        #if os(tvOS)
        XCUIRemote.shared.press(.select)
        #elseif os(macOS)
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).hover()
        #else
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        #endif
    }
}

#if os(iOS)
/// This iPhone as the sender to a receiver on the network named `PLEZY_CAST_TARGET` (a row of the picker whose label
/// contains it), signed in to `PLEZY_DEV_SERVER`. The pairing code goes to `sender-code.txt` (`PLEZY_CAST_SHARE`, else
/// the exchange folder) and must equal the receiver's `receiver-code.txt`, so a fresh pairing needs a folder both runs
/// reach.
final class CastE2ESenderTests: CastE2ETestCase {
    /// Sine Album cast: Play plays it on the target; the bar opens the controls, Play/Pause answers, Next moves to
    /// another track; Disconnect ends it.
    func testCastAlbum() throws {
        let target = try requireTarget()
        launchDev(arguments: ["--dev-server", try requireServer(), "--dev-open-music", "album=Sine Album"])
        require("music.cast", timeout: 90, "the album's cast button")
        pair(button: "music.cast", target: target)
        activate("music.play", "the album's Play")
        require("cast.bar.playPause", timeout: 60, "the bar's Play/Pause once \(target) plays")
        shot("bar")
        activate("cast.bar.open", "the bar")
        require("cast.controls", timeout: 10, "the controls")
        let title = require("cast.controls.title", timeout: 10, "the controls' title")
        _ = waitUntil(15) { !title.label.isEmpty }
        let first = title.label
        shot("controls")
        let control = element("cast.controls.playPause")
        let before = control.label
        activate("cast.controls.playPause", "Play/Pause")
        if !waitUntil(15, { control.label != before }) { fail("Play/Pause still reads \(before): \(target) didn't answer") }
        shot("paused")
        activate("cast.controls.playPause", "Play/Pause")
        if !waitUntil(15, { control.label == before }) { fail("Play/Pause doesn't play again") }
        activate("cast.controls.next", "Next")
        if !waitUntil(30, { title.label != first && !title.label.isEmpty }) { fail("Next leaves the title at \(first)") }
        shot("next track")
        reveal("cast.controls.disconnect", "Disconnect")
        activate("cast.controls.disconnect", "Disconnect")
        if !waitUntil(15, { !self.element("cast.bar").exists }) { fail("the cast bar stays after Disconnect") }
        shot("disconnected")
    }

    /// Live TV's first channel in view cast: its program's cast button pairs, Watch Channel tunes it on the target, the
    /// bar names the channel's program; Stop ends the playback.
    func testCastLiveChannel() throws {
        let target = try requireTarget()
        launchDev(arguments: ["--dev-server", try requireServer(), "--dev-open", "live_tv"])
        require("livetv.guide.channel.0", timeout: 90, "the guide's channels")
        let channelEnd = element("livetv.guide.channel.0").frame.maxX
        let program = (0..<16).lazy.map { self.element("livetv.guide.program.0.\($0)") }
            .first { $0.exists && $0.frame.minX >= channelEnd - 1 && $0.isHittable }
        guard let program else { return fail("no program of the first channel in view") }
        program.tap()
        require("livetv.details", timeout: 10, "the program's details")
        pair(button: "livetv.details.cast", target: target)
        let watch = ["livetv.details.action.watch", "livetv.details.action.play"].first { element($0).exists }
        guard let watch else { return fail("the details offer no Watch Channel or Play") }
        activate(watch, "Watch Channel")
        require("cast.bar.playPause", timeout: 60, "the bar's Play/Pause once \(target) plays the channel")
        let bar = element("cast.bar.open").label
        XCTAssertFalse(bar.contains("Ready to cast"), "the bar shows what plays: \(bar)")
        shot("bar live")
        activate("cast.bar.open", "the bar")
        reveal("cast.controls.stop", "Stop")
        shot("controls live")
        activate("cast.controls.stop", "Stop")
        if !waitUntil(15, { !self.element("cast.bar.playPause").exists }) { fail("the bar still plays after Stop") }
        shot("stopped")
        reveal("cast.controls.disconnect", "Disconnect")
        activate("cast.controls.disconnect", "Disconnect")
    }

    /// The cast button `button` opens the picker; the target's row starts pairing, whose code is written and must match
    /// the receiver's within 60 s; once the receiver allows, the picker closes and the bar names the target.
    private func pair(button: String, target: String) {
        activate(button, "the cast button")
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'cast.picker.device.' AND label CONTAINS %@", target)).firstMatch
        if !row.exists(within: 60) { fail("the picker lists no \(target) within 60 s") }
        shot("picker")
        remove("receiver-code.txt")
        activate(row.identifier, "\(target)'s row")
        let code = element("cast.pairing.code")
        // A receiver that remembers this sender connects without asking.
        if code.exists(within: 15) {
            let text = Self.text(code)
            write(text, to: "sender-code.txt")
            shot("pairing")
            var receiver: String?
            if !waitUntil(60, { receiver = read("receiver-code.txt"); return receiver != nil }) {
                return fail("the receiver's code never came to receiver-code.txt within 60 s")
            }
            XCTAssertEqual(text, receiver, "both devices show the same code")
        }
        if !waitUntil(120, { !self.element("cast.picker.thisDevice").exists && !code.exists }) {
            fail("the picker stays up: \(target) didn't allow this device")
        }
        let bar = require("cast.bar.open", timeout: 30, "the cast bar once \(target) is the target")
        XCTAssertTrue(bar.label.contains(target), "the bar names \(target): \(bar.label)")
    }

    private func requireTarget() throws -> String {
        let target = ProcessInfo.processInfo.environment["PLEZY_CAST_TARGET"] ?? ""
        if target.isEmpty { throw XCTSkip("PLEZY_CAST_TARGET not set: a two-device run's") }
        return target
    }

    private func requireServer() throws -> String {
        let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        if server.isEmpty { throw XCTSkip("PLEZY_DEV_SERVER not set: a two-device run's") }
        return server
    }
}
#endif

/// What both sides share: the folder the codes go through and reading an element's text.
class CastE2ETestCase: CastTestCase {
    /// `PLEZY_CAST_SHARE`, else the run's exchange folder.
    private static var share: URL? {
        let environment = ProcessInfo.processInfo.environment
        let path = [environment["PLEZY_CAST_SHARE"], environment["PLEZY_EXCHANGE"]].compactMap { $0 }.first { !$0.isEmpty }
        return path.map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    static func seconds(_ name: String) -> TimeInterval? {
        ProcessInfo.processInfo.environment[name].flatMap(TimeInterval.init)
    }

    /// A Mac's text reads as its value, elsewhere as its label.
    static func text(_ element: XCUIElement) -> String {
        element.label.isEmpty ? (element.value as? String ?? "") : element.label
    }

    func write(_ text: String, to name: String) {
        guard let share = Self.share else { return }
        do {
            try FileManager.default.createDirectory(at: share, withIntermediateDirectories: true)
            try text.write(to: share.appendingPathComponent(name), atomically: true, encoding: .utf8)
        } catch {
            fail("can't write \(name) in \(share.path): \(error)")
        }
    }

    func read(_ name: String) -> String? {
        guard let share = Self.share else { return nil }
        return try? String(contentsOf: share.appendingPathComponent(name), encoding: .utf8)
    }

    func remove(_ name: String) {
        guard let share = Self.share else { return }
        try? FileManager.default.removeItem(at: share.appendingPathComponent(name))
    }
}
