import XCTest

/// A server's item through the playback session on Apple TV: a `--dev` session signs into the server
/// `PLEZY_DEV_SERVER` names (`--dev-server`'s `<kind>=<user>:<password>@<url>`) and plays `PLEZY_DEV_PLAY`
/// (`--dev-play`'s `<server>:<item>`). It plays for 32 s, the remote's play/pause pauses it, and Menu leaves the player
/// (the first press may only hide the controls). The server's saved position is the run's to check.
final class PlayServerTests: PlezyUITestCase {
    func testPlayPauseAndLeave() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let server = environment["PLEZY_DEV_SERVER"], let play = environment["PLEZY_DEV_PLAY"] else {
            throw XCTSkip("needs PLEZY_DEV_SERVER and PLEZY_DEV_PLAY")
        }
        launchDev(arguments: ["--dev-server", server, "--dev-play", play])
        require("player.video", timeout: 90, "once the server's item opens")
        // It plays for 32 s before the pause.
        sleep(32)
        shot("playing")
        XCUIRemote.shared.press(.playPause)
        // The pause lands before the shot; nothing on screen signals it.
        sleep(2)
        shot("paused")
        XCUIRemote.shared.press(.menu)
        if !element("player.video").waitForNonExistence(timeout: 5) { XCUIRemote.shared.press(.menu) }
        _ = element("player.video").waitForNonExistence(timeout: 10)
        shot("closed")
        XCTAssertFalse(element("player.video").exists, "the player is left")
    }
}
