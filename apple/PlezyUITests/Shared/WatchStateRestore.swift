import XCTest

/// The test server's watch state of the item a test class's `--dev` launches play, put back as it was when the class
/// ends. A test that plays a shared item (`--dev-play`, Maestro Episode 2) moves its resume point and its last played
/// date, and the Continue Watching tests need it where the server's seed leaves it (70 s, in progress).
///
/// For a Jellyfin `--dev-server` (`jellyfin=<user>:<password>@<url>`) and a `--dev-play` naming that kind and an item
/// id (`jellyfin:<32 hex digits>`); other servers and plays by title are left as they are. The class's first launch of
/// the item reads its state (`UserData`) and clears its resume point, so the class starts at the item's start
/// whatever other runs left (a player test resumed at 70 s has 20 s to play); its later tests find the item as the
/// last one left it. The class's teardown (`PlezyUITestCase.tearDown()`) stops the app, so that no progress report of
/// its comes after, and writes each state back.
@MainActor
enum WatchStateRestore {
    /// The items whose state goes back as the class ends: the server, signed in, and the state to write.
    private static var pending: [String: (server: Server, state: Data)] = [:]

    /// Keeps the state of the item `arguments` play; the failure to report, if any.
    static func keep(_ arguments: [String]) -> String? {
        guard let spec = value(after: "--dev-server", in: arguments), spec.hasPrefix("jellyfin="),
              let play = value(after: "--dev-play", in: arguments)?.removingPercentEncoding,
              play.hasPrefix("jellyfin:") else { return nil }
        let item = String(play.dropFirst("jellyfin:".count))
        guard item.count == 32, item.allSatisfy(\.isHexDigit), pending[item] == nil else { return nil }
        guard let server = Server(spec: spec) else { return "the test server's sign-in for \(spec) failed" }
        guard let state = server.userData(item) else { return "the test server has no watch state for \(item)" }
        var restored: [String: Any] = [
            "PlaybackPositionTicks": state["PlaybackPositionTicks"] ?? 0,
            "Played": state["Played"] ?? false,
            "PlayCount": state["PlayCount"] ?? 0,
        ]
        if let date = state["LastPlayedDate"] { restored["LastPlayedDate"] = date }
        guard let body = try? JSONSerialization.data(withJSONObject: restored),
              let start = try? JSONSerialization.data(withJSONObject: ["PlaybackPositionTicks": 0, "Played": false]) else {
            return "no JSON for \(state)"
        }
        guard server.setUserData(item, start) else { return "clearing the resume point of \(item) failed" }
        pending[item] = (server, body)
        return nil
    }

    /// Stops the app and writes every kept state back; the failures to report.
    static func restoreAll() -> [String] {
        guard !pending.isEmpty else { return [] }
        XCUIApplication().terminate()
        // A report the app sent just before it stopped lands first.
        Thread.sleep(forTimeInterval: 1)
        let failures = pending.compactMap { item, kept in
            kept.server.setUserData(item, kept.state) ? nil : "putting back the watch state of \(item) failed"
        }
        pending = [:]
        return failures
    }

    private static func value(after option: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: option), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    /// A Jellyfin test server, signed in as the spec's user.
    private struct Server {
        let url: String
        let token: String
        let userId: String

        /// `jellyfin=<user>:<password>@<url>`; nil when the sign-in fails.
        init?(spec: String) {
            guard let at = spec.lastIndex(of: "@") else { return nil }
            let credentials = spec[spec.index(spec.startIndex, offsetBy: "jellyfin=".count)..<at]
                .split(separator: ":", maxSplits: 1).map(String.init)
            url = String(spec[spec.index(after: at)...])
            let signIn = try? JSONSerialization.data(withJSONObject: [
                "Username": credentials.first ?? "", "Pw": credentials.count > 1 ? credentials[1] : "",
            ])
            guard let auth = Self.call(url, "/Users/AuthenticateByName", method: "POST", token: nil, body: signIn),
                  let token = auth["AccessToken"] as? String,
                  let userId = (auth["User"] as? [String: Any])?["Id"] as? String else { return nil }
            self.token = token
            self.userId = userId
        }

        func userData(_ item: String) -> [String: Any]? {
            Self.call(url, "/UserItems/\(item)/UserData?userId=\(userId)", method: "GET", token: token, body: nil)
        }

        func setUserData(_ item: String, _ body: Data) -> Bool {
            Self.call(url, "/UserItems/\(item)/UserData?userId=\(userId)", method: "POST", token: token, body: body) != nil
        }

        /// `method` `path` on the server, waited for; its JSON answer (an empty one for none), nil when it failed.
        private static func call(_ base: String, _ path: String, method: String, token: String?, body: Data?) -> [String: Any]? {
            guard let url = URL(string: base + path) else { return nil }
            var request = URLRequest(url: url, timeoutInterval: 15)
            request.httpMethod = method
            var auth = #"MediaBrowser Client="Plezy UI tests", Device="ui-tests", DeviceId="plezy-ui-tests-watch-state", Version="1""#
            if let token { auth += #", Token="\#(token)""# }
            request.setValue(auth, forHTTPHeaderField: "Authorization")
            if let body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = body
            }
            let done = DispatchSemaphore(value: 0)
            nonisolated(unsafe) var answer: [String: Any]?
            URLSession.shared.dataTask(with: request) { data, response, _ in
                if let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) {
                    answer = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
                }
                done.signal()
            }.resume()
            done.wait()
            return answer
        }
    }
}
