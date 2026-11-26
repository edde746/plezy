import Foundation

/// A new account on a test server comes with no watch records of its own, yet on the lab's Jellyfin it can start with
/// the records of accounts removed before it (Maestro Episode 2 played, left by the test that last made and removed an
/// account). The tests that make their own account blank it right after making it, so each starts from nothing watched,
/// started or played lately, and then sets what it needs.
enum FreshAccountWatchState {
    /// What the server's API answers a call: `method` `url` with a JSON `body`, signed in as the new account.
    typealias Call = (_ method: String, _ url: String, _ body: [String: Any]?) throws -> [String: Any]

    /// The played date a blanked item keeps: the API can't clear one, and a date this old is out of every Next Up and
    /// Continue Watching cutoff.
    private static let longAgo = "2001-01-01T00:00:00.0000000Z"

    /// Sets every video and track of `user`'s libraries that is played, started or played since 2001 back to unplayed,
    /// at its start, played in 2001. `kind` is `jellyfin` or `emby` (their user-data endpoints differ).
    static func blank(kind: String, base: String, user: String, call: Call) throws {
        let found = try call("GET", "\(base)/Users/\(user)/Items?Recursive=true&IncludeItemTypes=Movie,Episode,Video,MusicVideo,Audio&Fields=UserData&EnableImages=false", nil)
        for item in found["Items"] as? [[String: Any]] ?? [] {
            guard let id = item["Id"] as? String, let data = item["UserData"] as? [String: Any] else { continue }
            let played = data["Played"] as? Bool ?? false
            let position = data["PlaybackPositionTicks"] as? Int ?? 0
            let lastPlayed = data["LastPlayedDate"] as? String ?? ""
            guard played || position > 0 || lastPlayed.prefix(4) > "2001" else { continue }
            let path = kind == "jellyfin" ? "/UserItems/\(id)/UserData?userId=\(user)" : "/Users/\(user)/Items/\(id)/UserData"
            _ = try call("POST", base + path, ["Played": false, "PlaybackPositionTicks": 0, "PlayCount": 0, "LastPlayedDate": longAgo])
        }
    }
}
