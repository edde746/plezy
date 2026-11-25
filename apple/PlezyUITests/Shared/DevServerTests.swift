import XCTest

/// A development session signed into a media server (`--dev-server`): the run gives the server as `PLEZY_DEV_SERVER`
/// (`jellyfin=<user>:<password>@<url>`, passed as `TEST_RUNNER_PLEZY_DEV_SERVER`). The session signs in, binds the
/// server to its profile and logs the server's libraries; a sign-in that fails ends the launch, so the shell showing
/// after it is the sign-in's success.
final class DevServerTests: PlezyUITestCase {
    func testSignsIntoTheServer() throws {
        let server = try XCTUnwrap(
            ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"].flatMap { $0.isEmpty ? nil : $0 },
            "PLEZY_DEV_SERVER names the server"
        )
        launchDev(arguments: ["--dev-server", server])
        require("home.screen", timeout: 60, "after the launch")
        // The sign-in and the bind run after the shell shows: give them time, then check the app still runs.
        sleep(15)
        XCTAssertEqual(app.state, .runningForeground, "the app ended: the sign-in failed")
        shot("signed-in")
    }
}
