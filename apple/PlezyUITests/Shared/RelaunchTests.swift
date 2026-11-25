import XCTest

/// The app started, quit and started again, six times over: each start of a `--dev` session reaches Home with the app
/// in front and, where `PLEZY_DEV_SERVER` names the run's server, Home's rows from it (the session signed in). On
/// iPhone and iPad every start connects the window's scene to the scene session the system keeps between runs, where a
/// scene setup that hands SwiftUI its own scene delegate as the app's makes SwiftUI wrap that delegate in itself until
/// the stack overflows.
final class RelaunchTests: PlezyUITestCase {
    func testStartsAgainAfterEachQuit() {
        let server = ProcessInfo.processInfo.environment["PLEZY_DEV_SERVER"] ?? ""
        let hubRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'hub.'")).firstMatch
        for start in 1...6 {
            launchDev(arguments: server.isEmpty ? [] : ["--dev-server", server])
            require("home.screen", timeout: 60, "start \(start)")
            if !server.isEmpty, !hubRow.exists(within: 60) {
                fail("start \(start): no row from the server on Home after 60 s")
            }
            XCTAssertEqual(app.state, .runningForeground, "start \(start): the app is in front")
            shot("home start \(start)")
            app.terminate()
        }
    }
}
