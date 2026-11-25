#if os(iOS)
import XCTest

/// The host's side of a Watch Together room shared across devices: the session hosts the room `PLEZY_WATCH_ROOM` (a
/// fresh code, `--dev-watch-room`) on the relay `PLEZY_WATCH_RELAY` (`watch_party_relay_url`), signed in with
/// `PLEZY_DEV_SERVER` (`--dev-server`'s `<kind>=<user>:<password>@<url>`), and plays `PLEZY_PLAY` (`--dev-play`'s
/// `<server>:<item>`) in it, which the room shares. Skipped without them.
///
/// The player pauses at once, so the media waits for the others; once the room pill counts `PLEZY_WATCH_PEOPLE` (default
/// 3) the host plays, pauses, drags the timeline 30 s on and plays again from the player's controls, `PLEZY_WATCH_STEP`
/// seconds apart (default 12), so the guests' players show each change, and stays in the room a step more.
final class WatchProofHostTests: PlezyUITestCase {
    func testHostPausesSeeksAndPlays() throws {
        let env = ProcessInfo.processInfo.environment
        func value(_ name: String) -> String? { env[name].flatMap { $0.isEmpty ? nil : $0 } }
        guard let code = value("PLEZY_WATCH_ROOM"), let relay = value("PLEZY_WATCH_RELAY"),
              let server = value("PLEZY_DEV_SERVER"), let play = value("PLEZY_PLAY") else {
            throw XCTSkip("needs PLEZY_WATCH_ROOM, PLEZY_WATCH_RELAY, PLEZY_DEV_SERVER and PLEZY_PLAY")
        }
        let people = Int(value("PLEZY_WATCH_PEOPLE") ?? "") ?? 3
        let step = UInt32(value("PLEZY_WATCH_STEP") ?? "") ?? 12
        launchDev(
            settings: ["watch_party_relay_url=\(relay)"],
            arguments: ["--dev-server", server, "--dev-watch-room", code, "--dev-play", play]
        )
        require("player.video", timeout: 120, "the player opening on \(play)")
        // Lets the player start before its controls are raised; nothing signals it.
        sleep(5)
        raiseControls()
        require("player.watch", timeout: 60, "the room pill")
        // A host's play in a room opens paused for the room to start; one that started before the room did plays.
        press("Pause", required: false)
        _ = waitUntil(5) { self.element("player.playPause").label == "Play" }
        shot("host-paused-waiting")

        // The guests join: the pill counts them ("3 participants, Connected, You are the host").
        let deadline = Date().addingTimeInterval(900)
        var count = pillValue()
        while !count.hasPrefix("\(people) ") {
            if Date() > deadline { fail("the room pill never counted \(people): \(count)") }
            _ = waitUntil(3, every: 1) { self.pillValue().hasPrefix("\(people) ") }
            count = pillValue()
        }
        shot("host-room-full")
        // The guests' players open the room's media.
        sleep(step * 2)

        press("Play", required: false)
        // Holds each state a step so the guests' players show the change.
        sleep(step)
        raiseControls()
        shot("host-playing")

        press("Pause")
        _ = waitUntil(5) { self.element("player.playPause").label == "Play" }
        let paused = position()
        shot("host-paused")
        // Holds each state a step so the guests' players show the change.
        sleep(step)

        // An iPhone's transport has no skip buttons: the timeline is dragged 30 s on.
        seek(from: paused, by: 30)
        _ = waitUntil(5) { abs(self.position() - paused - 30) <= 3 }
        let skipped = position()
        shot("host-seeked")
        XCTAssertEqual(skipped - paused, 30, accuracy: 3, "a drag on the timeline moves the paused player 30 s on")
        // Holds each state a step so the guests' players show the change.
        sleep(step)

        press("Play")
        // Holds each state a step so the guests' players show the change, the position advancing meanwhile.
        sleep(step)
        raiseControls()
        shot("host-playing-again")
        XCTAssertGreaterThan(position(), skipped, "the player plays on from the new position")
        // Stays in the room a step more so the guests see the last change.
        sleep(step)
    }

    /// Taps play/pause when its action is `action` ("Play" or "Pause"); otherwise fails the test, or with `required`
    /// false leaves the player as it is. The controls are raised again if they went down meanwhile.
    private func press(_ action: String, required: Bool = true) {
        let button = element("player.playPause")
        for _ in 0..<3 {
            raiseControls()
            guard button.exists(within: 3), button.isHittable else { continue }
            let label = button.label
            if label != action {
                if required { fail("play/pause offers \(label), not \(action)") }
                return
            }
            if button.isHittable {
                button.tap()
                return
            }
        }
        if required { fail("play/pause: not on screen after raising the controls three times") }
    }

    /// The room pill's accessibility value, raising the controls first.
    private func pillValue() -> String {
        raiseControls()
        return element("player.watch").value as? String ?? ""
    }

    /// Drags the timeline from `from` seconds to `by` seconds later, its length read from its value ("0:17 / 3:00"),
    /// raising the controls first.
    private func seek(from: Double, by: Double) {
        raiseControls()
        let scrub = require("player.scrub", timeout: 5, "the timeline")
        let total = seconds(String((scrub.value as? String ?? "").split(separator: "/").last ?? ""))
        if total <= 0 { fail("the timeline's length: \(scrub.value ?? "none")") }
        let start = scrub.coordinate(withNormalizedOffset: CGVector(dx: from / total, dy: 0.5))
        let end = scrub.coordinate(withNormalizedOffset: CGVector(dx: (from + by) / total, dy: 0.5))
        start.press(forDuration: 0.4, thenDragTo: end)
    }

    private func seconds(_ label: String) -> Double {
        label.trimmingCharacters(in: .whitespaces).split(separator: ":").reduce(0) { $0 * 60 + (Double($1) ?? 0) }
    }

    /// Shows the controls if they went down.
    private func raiseControls() {
        let control = element("player.playPause")
        if control.exists && control.isHittable { return }
        element("player.video").tap()
        _ = control.exists(within: 3)
    }

    /// The player's position in seconds, from its `m:ss` or `h:mm:ss` label.
    private func position() -> Double {
        raiseControls()
        let label = require("player.position", timeout: 5, "the position").label
        return label.split(separator: ":").reduce(0) { $0 * 60 + (Double($1) ?? 0) }
    }
}
#endif
