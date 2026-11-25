import XCTest

/// Quitting the Mac app while a video plays ends its server session first: a `--dev` session signed in with
/// `PLEZY_DEV_SERVER` (a Jellyfin's `jellyfin=<user>:<password>@<url>`, the user an administrator, who sees every
/// session) plays `PLEZY_PLAY` (`jellyfin:<item id>`, an item longer than the server's minimum resume duration, five
/// minutes: the test server's Codec Numbered Chapters). While it plays the server lists it playing; after Cmd-Q the
/// server plays nothing of it any more (the stopped report arrived, not a session left to time out) and keeps a resume
/// point no earlier than the one the progress reports left: a stop at 0 would have cleared it. Skipped without them.
final class QuitTests: PlezyUITestCase {
    func testQuitReportsThePlaybackStoppedAtItsPosition() throws {
        let env = ProcessInfo.processInfo.environment
        guard let server = env["PLEZY_DEV_SERVER"], !server.isEmpty, let play = env["PLEZY_PLAY"]?.removingPercentEncoding else {
            throw XCTSkip("PLEZY_DEV_SERVER and PLEZY_PLAY name the Jellyfin and the item to play")
        }
        let jellyfin = try Jellyfin(spec: server)
        let item = try XCTUnwrap(play.split(separator: ":", maxSplits: 1).last.map(String.init), "PLEZY_PLAY is jellyfin:<item id>")
        // An item under the server's minimum resume duration is marked played at 0 by its first progress report.
        let length = try jellyfin.runtimeSeconds(item)
        if length < 300 { return XCTFail("PLEZY_PLAY plays \(Int(length)) s; the test needs an item over five minutes") }
        // From the start, so the resume point after the quit is this run's.
        try jellyfin.markUnplayed(item)

        launchDev(arguments: ["--dev-server", server, "--dev-play", play])
        require("player.video", timeout: 90, "the player opening on \(play)")
        XCTAssertTrue(waitUntil(30, every: 0.5) { (try? jellyfin.playing(item)) == true }, "the server lists the video playing")
        // Past 5 % of the item (21 s), where the server keeps a resume point.
        _ = waitUntil(90, every: 2) { ((try? jellyfin.positionSeconds(item)) ?? 0) > 21 }
        shot("playing")
        let reported = try jellyfin.positionSeconds(item)
        XCTAssertGreaterThan(reported, 21, "the progress reports' resume point")

        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 30), "the app quit")
        XCTAssertTrue(waitUntil(5, every: 0.5) { (try? jellyfin.playing(item)) == false }, "the server heard the stop: nothing of it plays")
        XCTAssertGreaterThanOrEqual(try jellyfin.positionSeconds(item), reported, "the stop carried the position the video reached")
    }
}

/// A Jellyfin server as the test reads it: signed in as the spec's user.
private struct Jellyfin {
    let url: String
    let token: String
    let userId: String

    init(spec: String) throws {
        // jellyfin=<user>:<password>@<url>
        guard spec.hasPrefix("jellyfin="), let at = spec.firstIndex(of: "@") else {
            throw XCTSkip("PLEZY_DEV_SERVER is not a Jellyfin: \(spec)")
        }
        let credentials = spec[spec.index(spec.startIndex, offsetBy: 9)..<at].split(separator: ":", maxSplits: 1).map(String.init)
        url = String(spec[spec.index(after: at)...])
        let body = try JSONSerialization.data(withJSONObject: ["Username": credentials[0], "Pw": credentials.count > 1 ? credentials[1] : ""])
        let auth = try Self.json(Self.request(url, "/Users/AuthenticateByName", method: "POST", body: body, token: nil))
        token = try XCTUnwrap(auth["AccessToken"] as? String)
        userId = try XCTUnwrap((auth["User"] as? [String: Any])?["Id"] as? String)
    }

    func markUnplayed(_ item: String) throws {
        _ = try Self.request(url, "/UserPlayedItems/\(item)?userId=\(userId)", method: "DELETE", body: nil, token: token)
    }

    /// Whether a session on the server plays [item] now.
    func playing(_ item: String) throws -> Bool {
        let data = try Self.request(url, "/Sessions", method: "GET", body: nil, token: token)
        let sessions = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        return sessions.contains { (($0["NowPlayingItem"] as? [String: Any])?["Id"] as? String)?.lowercased() == item.lowercased() }
    }

    /// The resume point the server keeps for the user in [item].
    func positionSeconds(_ item: String) throws -> Double {
        let found = try Self.json(Self.request(url, "/Items/\(item)?userId=\(userId)", method: "GET", body: nil, token: token))
        let ticks = ((found["UserData"] as? [String: Any])?["PlaybackPositionTicks"] as? NSNumber)?.doubleValue ?? 0
        return ticks / 10_000_000
    }

    /// [item]'s length.
    func runtimeSeconds(_ item: String) throws -> Double {
        let found = try Self.json(Self.request(url, "/Items/\(item)?userId=\(userId)", method: "GET", body: nil, token: token))
        return ((found["RunTimeTicks"] as? NSNumber)?.doubleValue ?? 0) / 10_000_000
    }

    private static func json(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private static func request(_ base: String, _ path: String, method: String, body: Data?, token: String?) throws -> Data {
        var request = URLRequest(url: try XCTUnwrap(URL(string: base + path)), timeoutInterval: 15)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var auth = #"MediaBrowser Client="PlezyUITests", Device="ui-test", DeviceId="plezy-ui-test-quit", Version="1""#
        if let token { auth += #", Token="\#(token)""# }
        request.setValue(auth, forHTTPHeaderField: "Authorization")
        let done = DispatchSemaphore(value: 0)
        var result: Result<Data, Error> = .failure(URLError(.timedOut))
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                result = .failure(error)
            } else if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
                result = .failure(URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "\(method) \(path): HTTP \(status)"]))
            } else {
                result = .success(data ?? Data())
            }
            done.signal()
        }.resume()
        done.wait()
        return try result.get()
    }
}
