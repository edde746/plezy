import Foundation

/// Lightweight Plex API client for Apple Watch
/// Handles direct communication with the Plex server for independent operation
class PlexWatchClient {
    static let shared = PlexWatchClient()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()
    private let credentialsKey = "plexServerCredentials"

    struct Credentials: Codable {
        let serverUrl: String
        let token: String
        var machineIdentifier: String?
    }

    /// Stored server credentials for independent operation
    var credentials: Credentials? {
        get {
            guard let data = UserDefaults.standard.data(forKey: credentialsKey) else { return nil }
            return try? JSONDecoder().decode(Credentials.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: credentialsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: credentialsKey)
            }
        }
    }

    var hasCredentials: Bool { credentials != nil }

    /// Save credentials from a queue transfer
    func saveCredentials(serverUrl: String, token: String) {
        credentials = Credentials(serverUrl: serverUrl, token: token)
        // Fetch machine identifier in the background
        Task { await fetchMachineIdentifier() }
    }

    // MARK: - API Methods

    /// Fetch and cache the server's machine identifier (needed for radio stations)
    @discardableResult
    func fetchMachineIdentifier() async -> String? {
        guard var creds = credentials else {
            rlog("[PlexWatch] fetchMachineIdentifier: no credentials")
            return nil
        }
        if let cached = creds.machineIdentifier {
            rlog("[PlexWatch] fetchMachineIdentifier: using cached \(cached)")
            return cached
        }

        rlog("[PlexWatch] fetchMachineIdentifier: fetching from \(creds.serverUrl)/identity")
        guard let json = await get("/identity") else {
            rlog("[PlexWatch] fetchMachineIdentifier: /identity request failed")
            return nil
        }
        if let container = json["MediaContainer"] as? [String: Any],
           let machineId = container["machineIdentifier"] as? String {
            creds.machineIdentifier = machineId
            credentials = creds
            rlog("[PlexWatch] fetchMachineIdentifier: got \(machineId)")
            return machineId
        }
        rlog("[PlexWatch] fetchMachineIdentifier: unexpected response: \(json)")
        return nil
    }

    /// Get all libraries
    func getLibraries() async -> [LibrarySection] {
        guard let json = await get("/library/sections") else { return [] }
        guard let container = json["MediaContainer"] as? [String: Any],
              let directories = container["Directory"] as? [[String: Any]] else { return [] }

        return directories.compactMap { dir in
            guard let key = dir["key"] as? String,
                  let title = dir["title"] as? String,
                  let type = dir["type"] as? String else { return nil }
            return LibrarySection(key: key, title: title, type: type)
        }
    }

    /// Get music libraries only
    func getMusicLibraries() async -> [LibrarySection] {
        await getLibraries().filter { $0.type == "artist" }
    }

    /// Get artists in a music library
    func getArtists(sectionId: String) async -> [MusicItem] {
        await getMetadataList("/library/sections/\(sectionId)/all?type=8")
    }

    /// Get albums for an artist
    func getAlbums(ratingKey: String) async -> [MusicItem] {
        await getMetadataList("/library/metadata/\(ratingKey)/children")
    }

    /// Get tracks for an album
    func getTracks(ratingKey: String) async -> [MusicItem] {
        await getMetadataList("/library/metadata/\(ratingKey)/children")
    }

    /// Get all albums in a music library
    func getAllAlbums(sectionId: String) async -> [MusicItem] {
        await getMetadataList("/library/sections/\(sectionId)/all?type=9&sort=titleSort")
    }

    /// Get playlists (audio only)
    func getPlaylists() async -> [MusicItem] {
        guard let json = await get("/playlists?playlistType=audio") else { return [] }
        guard let container = json["MediaContainer"] as? [String: Any],
              let metadata = container["Metadata"] as? [[String: Any]] else { return [] }

        return metadata.compactMap { dict -> MusicItem? in
            guard let ratingKey = dict["ratingKey"] as? String,
                  let title = dict["title"] as? String else { return nil }
            let duration = dict["duration"] as? Double
            let thumb = dict["composite"] as? String ?? dict["thumb"] as? String
            let leafCount = dict["leafCount"] as? Int
            return MusicItem(
                ratingKey: ratingKey,
                title: title,
                type: "playlist",
                artist: leafCount != nil ? "\(leafCount!) tracks" : nil,
                album: nil,
                thumb: thumb,
                duration: duration,
                partKey: nil,
                parentRatingKey: nil,
                grandparentRatingKey: nil
            )
        }
    }

    /// Get tracks in a playlist
    func getPlaylistItems(ratingKey: String) async -> [MusicItem] {
        await getMetadataList("/playlists/\(ratingKey)/items")
    }

    /// Create a play queue from a playlist
    func createPlaylistQueue(ratingKey: String, shuffle: Bool = false) async -> PlayQueueResult? {
        guard let creds = credentials else { return nil }

        var params = "type=audio&playlistID=\(ratingKey)"
        if shuffle { params += "&shuffle=1" }

        let urlString = "\(creds.serverUrl)/playQueues?\(params)&X-Plex-Token=\(creds.token)"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        request.setValue("Plezy", forHTTPHeaderField: "X-Plex-Product")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let container = json["MediaContainer"] as? [String: Any] else { return nil }

            let queueId = container["playQueueID"] as? Int ?? 0
            let metadata = container["Metadata"] as? [[String: Any]] ?? []
            let items = metadata.compactMap { parseMusicItem($0) }
            rlog("[PlexWatch] Created playlist queue \(queueId) with \(items.count) items")

            return PlayQueueResult(playQueueId: queueId, items: items)
        } catch {
            rlog("[PlexWatch] Create playlist queue error: \(error)")
            return nil
        }
    }

    /// Search across all content
    func search(query: String) async -> [MusicItem] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let json = await get("/hubs/search?query=\(encoded)&limit=20") else { return [] }
        guard let container = json["MediaContainer"] as? [String: Any],
              let hubs = container["Hub"] as? [[String: Any]] else { return [] }

        var results: [MusicItem] = []
        for hub in hubs {
            guard let metadata = hub["Metadata"] as? [[String: Any]] else { continue }
            let items = metadata.compactMap { parseMusicItem($0) }
            results.append(contentsOf: items)
        }
        return results
    }

    /// Plex client identifier for API requests
    var clientIdentifier: String {
        if let stored = UserDefaults.standard.string(forKey: "plexClientId") {
            return stored
        }
        let id = "plezy-watch-\(UUID().uuidString.prefix(8))"
        UserDefaults.standard.set(id, forKey: "plexClientId")
        return id
    }

    /// Create a play queue from a track/album/artist URI
    func createPlayQueue(uri: String, shuffle: Bool = false, continuous: Bool = false) async -> PlayQueueResult? {
        guard let creds = credentials else {
            rlog("[PlexWatch] No credentials for createPlayQueue")
            return nil
        }

        var components = URLComponents(string: "\(creds.serverUrl)/playQueues")
        var queryItems = [
            URLQueryItem(name: "type", value: "audio"),
            URLQueryItem(name: "uri", value: uri),
            URLQueryItem(name: "X-Plex-Token", value: creds.token),
        ]
        if shuffle { queryItems.append(URLQueryItem(name: "shuffle", value: "1")) }
        if continuous { queryItems.append(URLQueryItem(name: "continuous", value: "1")) }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            rlog("[PlexWatch] Failed to build play queue URL from: \(creds.serverUrl)/playQueues")
            return nil
        }

        rlog("[PlexWatch] POST \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
        request.setValue("Plezy", forHTTPHeaderField: "X-Plex-Product")
        request.setValue("Watch", forHTTPHeaderField: "X-Plex-Device")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            guard http.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                rlog("[PlexWatch] Create queue HTTP \(http.statusCode): \(body.prefix(200))")
                return nil
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let container = json["MediaContainer"] as? [String: Any] else {
                rlog("[PlexWatch] Create queue: unexpected JSON structure")
                return nil
            }

            let queueId = container["playQueueID"] as? Int ?? 0
            var metadata = container["Metadata"] as? [[String: Any]] ?? []
            rlog("[PlexWatch] Queue \(queueId): \(metadata.count) items in POST response (keys: \(Array(container.keys).sorted()))")

            // Plex radio/station queues often return empty on POST — fetch tracks with GET
            if metadata.isEmpty && queueId > 0 {
                rlog("[PlexWatch] Queue empty on POST, fetching tracks via GET /playQueues/\(queueId)")
                if let fetched = await fetchPlayQueueTracks(queueId: queueId) {
                    metadata = fetched
                    rlog("[PlexWatch] GET returned \(metadata.count) tracks")
                }
            }

            if let first = metadata.first {
                rlog("[PlexWatch] First track: ratingKey=\(first["ratingKey"] ?? "nil") type=\(first["type"] ?? "nil") title=\(first["title"] ?? "nil")")
            }

            let items = metadata.compactMap { parseMusicItem($0) }
            rlog("[PlexWatch] Created queue \(queueId) with \(items.count) items (parsed from \(metadata.count) metadata entries)")

            return PlayQueueResult(playQueueId: queueId, items: items)
        } catch {
            rlog("[PlexWatch] Create queue error: \(error)")
            return nil
        }
    }

    /// Create a radio station from a track/album/artist
    /// Returns (result, errorDetail) — errorDetail is non-nil on failure for UI display
    func createRadioStation(ratingKey: String) async -> (PlayQueueResult?, String?) {
        rlog("[PlexWatch] createRadioStation: ratingKey=\(ratingKey), hasCredentials=\(hasCredentials)")

        guard hasCredentials else {
            return (nil, "No credentials")
        }

        let machineId = await fetchMachineIdentifier()
        guard let machineId else {
            return (nil, "Can't reach server (/identity failed)")
        }

        // Use /nearest endpoint for true radio — sonic analysis finds similar tracks across artists.
        // The /station URI suffix creates empty queues; /nearest actually populates them.
        // Use raw ? and = here — URLComponents will percent-encode them properly.
        let uri = "server://\(machineId)/com.plexapp.plugins.library/library/metadata/\(ratingKey)/nearest?limit=50"
        rlog("[PlexWatch] createRadioStation: uri=\(uri) (nearest + shuffle + continuous)")
        if let result = await createPlayQueue(uri: uri, shuffle: true, continuous: true),
           !result.items.isEmpty {
            rlog("[PlexWatch] createRadioStation: \(result.items.count) items, queueId=\(result.playQueueId)")
            return (result, nil)
        }

        // Fallback: play all artist/album tracks shuffled if nearest returns empty
        rlog("[PlexWatch] createRadioStation: nearest empty, falling back to play-all")
        let fallbackUri = "server://\(machineId)/com.plexapp.plugins.library/library/metadata/\(ratingKey)"
        if let result = await createPlayQueue(uri: fallbackUri, shuffle: true, continuous: true),
           !result.items.isEmpty {
            rlog("[PlexWatch] createRadioStation: fallback returned \(result.items.count) items")
            return (result, nil)
        }

        return (nil, "No tracks found")
    }

    /// Fetch tracks from an existing play queue by ID
    private func fetchPlayQueueTracks(queueId: Int) async -> [[String: Any]]? {
        guard let creds = credentials else { return nil }
        let urlString = "\(creds.serverUrl)/playQueues/\(queueId)?X-Plex-Token=\(creds.token)"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                rlog("[PlexWatch] GET playQueue/\(queueId): HTTP \(code)")
                return nil
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let container = json["MediaContainer"] as? [String: Any] else {
                rlog("[PlexWatch] GET playQueue/\(queueId): bad JSON")
                return nil
            }
            let metadata = container["Metadata"] as? [[String: Any]] ?? []
            rlog("[PlexWatch] GET playQueue/\(queueId): \(metadata.count) items, container keys: \(Array(container.keys).sorted())")
            if metadata.isEmpty {
                let raw = String(data: data, encoding: .utf8) ?? ""
                rlog("[PlexWatch] GET playQueue/\(queueId) still empty: \(raw.prefix(500))")
            }
            return metadata.isEmpty ? nil : metadata
        } catch {
            rlog("[PlexWatch] GET playQueue/\(queueId) error: \(error)")
            return nil
        }
    }

    /// Create a play queue for an album or artist (play all tracks)
    func createPlayAllQueue(ratingKey: String, type: String = "audio") async -> PlayQueueResult? {
        guard let machineId = await fetchMachineIdentifier() else {
            rlog("[PlexWatch] No machine identifier for play all")
            return nil
        }
        let uri = "server://\(machineId)/com.plexapp.plugins.library/library/metadata/\(ratingKey)"
        rlog("[PlexWatch] Creating play all queue with uri: \(uri)")
        return await createPlayQueue(uri: uri)
    }

    /// Build a transcoded stream URL for Watch playback.
    /// Uses Plex music transcode to convert FLAC/high-bitrate to AAC 320kbps,
    /// which streams reliably on Watch and matches AirPods max quality.
    func streamUrl(ratingKey: String) -> String? {
        guard let creds = credentials else { return nil }
        let session = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)
        let profileExtra = "add-transcode-target(type=musicProfile&context=streaming&protocol=http&container=mp4&audioCodec=aac)"
        var components = URLComponents(string: "\(creds.serverUrl)/music/:/transcode/universal/start")
        components?.queryItems = [
            URLQueryItem(name: "hasMDE", value: "1"),
            URLQueryItem(name: "path", value: "/library/metadata/\(ratingKey)"),
            URLQueryItem(name: "mediaIndex", value: "0"),
            URLQueryItem(name: "partIndex", value: "0"),
            URLQueryItem(name: "musicBitrate", value: "320"),
            URLQueryItem(name: "directStreamAudio", value: "0"),
            URLQueryItem(name: "mediaBufferSize", value: "12288"),
            URLQueryItem(name: "protocol", value: "http"),
            URLQueryItem(name: "directPlay", value: "0"),
            URLQueryItem(name: "directStream", value: "0"),
            URLQueryItem(name: "session", value: String(session)),
            URLQueryItem(name: "X-Plex-Client-Profile-Extra", value: profileExtra),
            URLQueryItem(name: "X-Plex-Client-Identifier", value: "PlezyWatch"),
            URLQueryItem(name: "X-Plex-Token", value: creds.token),
            URLQueryItem(name: "X-Plex-Product", value: "Plezy"),
            URLQueryItem(name: "X-Plex-Platform", value: "iOS"),
        ]
        return components?.url?.absoluteString
    }

    /// Fetch the partKey for a track by loading its full metadata
    func fetchPartKey(ratingKey: String) async -> String? {
        guard let json = await get("/library/metadata/\(ratingKey)") else {
            rlog("[PlexWatch] fetchPartKey(\(ratingKey)): GET failed")
            return nil
        }
        guard let container = json["MediaContainer"] as? [String: Any],
              let metadata = container["Metadata"] as? [[String: Any]],
              let track = metadata.first else {
            rlog("[PlexWatch] fetchPartKey(\(ratingKey)): no Metadata in response, keys: \(json.keys)")
            return nil
        }
        guard let media = (track["Media"] as? [[String: Any]])?.first,
              let part = (media["Part"] as? [[String: Any]])?.first,
              let partKey = part["key"] as? String else {
            let hasMedia = track["Media"] != nil
            rlog("[PlexWatch] fetchPartKey(\(ratingKey)): hasMedia=\(hasMedia), track keys: \(Array(track.keys).prefix(10))")
            return nil
        }
        rlog("[PlexWatch] fetchPartKey(\(ratingKey)): OK \(partKey)")
        return partKey
    }

    /// Enrich MusicItems that are missing partKey by fetching their full metadata
    func enrichWithPartKeys(_ items: [MusicItem]) async -> [MusicItem] {
        let needEnrichment = items.filter { $0.partKey == nil }
        rlog("[PlexWatch] enrichWithPartKeys: \(items.count) items, \(items.count - needEnrichment.count) already have partKey, \(needEnrichment.count) need fetch")

        guard !needEnrichment.isEmpty else { return items }

        // Fetch missing partKeys sequentially to avoid overwhelming the Watch network stack
        var fetched: [String: String] = [:]
        for item in needEnrichment {
            if let partKey = await fetchPartKey(ratingKey: item.ratingKey) {
                fetched[item.ratingKey] = partKey
            } else {
                rlog("[PlexWatch] enrichWithPartKeys: FAILED for \(item.ratingKey) '\(item.title)'")
            }
        }

        rlog("[PlexWatch] enrichWithPartKeys: fetched \(fetched.count)/\(needEnrichment.count) partKeys")

        return items.compactMap { item in
            if item.partKey != nil { return item }
            guard let partKey = fetched[item.ratingKey] else { return nil }
            return MusicItem(
                ratingKey: item.ratingKey,
                title: item.title,
                type: item.type,
                artist: item.artist,
                album: item.album,
                thumb: item.thumb,
                duration: item.duration,
                partKey: partKey,
                parentRatingKey: item.parentRatingKey,
                grandparentRatingKey: item.grandparentRatingKey
            )
        }
    }

    /// Build a thumbnail URL
    func thumbnailUrl(_ thumb: String?) -> String? {
        guard let thumb, let creds = credentials else { return nil }
        let path = thumb.hasPrefix("/") ? String(thumb.dropFirst()) : thumb
        return "\(creds.serverUrl)/\(path)?X-Plex-Token=\(creds.token)"
    }

    // MARK: - Private

    private func get(_ path: String) async -> [String: Any]? {
        guard let creds = credentials else {
            rlog("[PlexWatch] GET \(path): no credentials")
            return nil
        }
        let separator = path.contains("?") ? "&" : "?"
        let urlString = "\(creds.serverUrl)\(path)\(separator)X-Plex-Token=\(creds.token)"
        guard let url = URL(string: urlString) else {
            rlog("[PlexWatch] GET \(path): invalid URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                rlog("[PlexWatch] GET \(path): no HTTP response")
                return nil
            }
            guard http.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                rlog("[PlexWatch] GET \(path): HTTP \(http.statusCode) \(body.prefix(200))")
                if http.statusCode == 401 {
                    rlog("[PlexWatch] Token expired or invalid — clearing credentials")
                    DispatchQueue.main.async { self.credentials = nil }
                }
                return nil
            }
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            rlog("[PlexWatch] GET \(path) error: \(error)")
            return nil
        }
    }

    private func getMetadataList(_ path: String) async -> [MusicItem] {
        guard let json = await get(path) else { return [] }
        guard let container = json["MediaContainer"] as? [String: Any],
              let metadata = container["Metadata"] as? [[String: Any]] else { return [] }
        return metadata.compactMap { parseMusicItem($0) }
    }

    /// Parse a Plex metadata dict into a MusicItem (public for use in WatchAudioPlayer)
    func parseMusicItemPublic(_ dict: [String: Any]) -> MusicItem? {
        parseMusicItem(dict)
    }

    private func parseMusicItem(_ dict: [String: Any]) -> MusicItem? {
        // ratingKey can be String or Int depending on the Plex API endpoint
        let ratingKey: String
        if let s = dict["ratingKey"] as? String {
            ratingKey = s
        } else if let n = dict["ratingKey"] as? Int {
            ratingKey = String(n)
        } else {
            return nil
        }
        guard let title = dict["title"] as? String else { return nil }

        let type = dict["type"] as? String ?? "track"

        // Extract stream info for tracks
        var partKey: String?
        if let media = (dict["Media"] as? [[String: Any]])?.first,
           let part = (media["Part"] as? [[String: Any]])?.first {
            partKey = part["key"] as? String
        }

        // parentRatingKey / grandparentRatingKey can also be Int
        let parentRK: String?
        if let s = dict["parentRatingKey"] as? String { parentRK = s }
        else if let n = dict["parentRatingKey"] as? Int { parentRK = String(n) }
        else { parentRK = nil }

        let grandparentRK: String?
        if let s = dict["grandparentRatingKey"] as? String { grandparentRK = s }
        else if let n = dict["grandparentRatingKey"] as? Int { grandparentRK = String(n) }
        else { grandparentRK = nil }

        return MusicItem(
            ratingKey: ratingKey,
            title: title,
            type: type,
            artist: dict["grandparentTitle"] as? String ?? dict["parentTitle"] as? String,
            album: dict["parentTitle"] as? String,
            thumb: dict["thumb"] as? String ?? dict["parentThumb"] as? String,
            duration: dict["duration"] as? Double,
            partKey: partKey,
            parentRatingKey: parentRK,
            grandparentRatingKey: grandparentRK
        )
    }
}

// MARK: - Models

struct LibrarySection: Identifiable {
    let key: String
    let title: String
    let type: String
    var id: String { key }
}

struct MusicItem: Identifiable {
    let ratingKey: String
    let title: String
    let type: String  // artist, album, track
    let artist: String?
    let album: String?
    let thumb: String?
    let duration: Double?  // milliseconds
    let partKey: String?
    let parentRatingKey: String?
    let grandparentRatingKey: String?

    var id: String { ratingKey }

    var isArtist: Bool { type == "artist" }
    var isAlbum: Bool { type == "album" }
    var isTrack: Bool { type == "track" }
    var isPlaylist: Bool { type == "playlist" }

    var durationSeconds: Double { (duration ?? 0) / 1000.0 }

    var subtitle: String? {
        if isTrack { return artist }
        if isAlbum { return artist }
        return nil
    }

    /// Convert to a QueueItem for playback
    func toQueueItem(client: PlexWatchClient) -> QueueItem? {
        guard let streamUrl = client.streamUrl(ratingKey: ratingKey) else { return nil }
        guard let token = client.credentials?.token else { return nil }
        return QueueItem(from: [
            "id": ratingKey,
            "title": title,
            "artist": artist as Any,
            "album": album as Any,
            "albumArtUrl": client.thumbnailUrl(thumb) as Any,
            "streamUrl": streamUrl,
            "plexToken": token,
            "duration": durationSeconds,
            "parentRatingKey": parentRatingKey as Any,
            "grandparentRatingKey": grandparentRatingKey as Any,
        ])
    }
}

struct PlayQueueResult {
    let playQueueId: Int
    let items: [MusicItem]

    /// Convert all items to QueueItems for playback
    func toQueueItems(client: PlexWatchClient) -> [QueueItem] {
        return items.compactMap { $0.toQueueItem(client: client) }
    }

    /// Build a PlayQueueReference from this result for queue refreshing
    func toQueueReference(client: PlexWatchClient) -> PlayQueueReference? {
        guard let creds = client.credentials else { return nil }
        return PlayQueueReference(
            playQueueId: playQueueId,
            plexServerUrl: creds.serverUrl,
            plexToken: creds.token,
            currentIndex: 0
        )
    }
}
