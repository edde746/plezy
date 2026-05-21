import Foundation

actor PlexClient {
    private let session: URLSession
    private var baseURL: String
    private var token: String
    private let clientIdentifier: String
    private var machineIdentifier: String?
    private var serverId: String?
    private var serverName: String?

    init(baseURL: String, token: String, clientIdentifier: String,
         serverId: String? = nil, serverName: String? = nil) {
        self.baseURL = baseURL
        self.token = token
        self.clientIdentifier = clientIdentifier
        self.serverId = serverId
        self.serverName = serverName

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "X-Plex-Product": "Vibe",
            "X-Plex-Client-Identifier": clientIdentifier,
            "X-Plex-Platform": "tvOS",
            "X-Plex-Device": "Apple TV",
            "X-Plex-Token": token
        ]
        self.session = URLSession(configuration: config)
    }

    func updateToken(_ newToken: String) {
        token = newToken
    }

    func updateBaseURL(_ newURL: String) {
        baseURL = newURL
    }

    func setServerInfo(id: String, name: String) {
        serverId = id
        serverName = name
    }

    // MARK: - Base Request Helpers

    private func buildURL(_ path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        let urlString = path.hasPrefix("http") ? path : "\(baseURL)\(path)"
        if let queryItems, !queryItems.isEmpty {
            var components = URLComponents(string: urlString)
            var existing = components?.queryItems ?? []
            existing.append(contentsOf: queryItems)
            components?.queryItems = existing
            return components?.url
        }
        return URL(string: urlString)
    }

    /// Maximum response size (50 MB) to prevent memory exhaustion from oversized payloads.
    private static let maxResponseSize = 50 * 1024 * 1024

    private func fetchJSON(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> [String: Any] {
        guard let url = buildURL(path, queryItems: queryItems) else {
            throw PlexClientError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if statusCode == 401 {
                throw PlexClientError.unauthorized
            }
            throw PlexClientError.httpError(statusCode)
        }

        guard data.count <= Self.maxResponseSize else {
            throw PlexClientError.parseError
        }

        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    private func postRequest(_ path: String, queryItems: [URLQueryItem]? = nil) async throws {
        guard let url = buildURL(path, queryItems: queryItems) else {
            throw PlexClientError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PlexClientError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    private func putRequest(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> Bool {
        guard let url = buildURL(path, queryItems: queryItems) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (_, response) = try await session.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    private func deleteRequest(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> Bool {
        guard let url = buildURL(path, queryItems: queryItems) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (_, response) = try await session.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    private func parseMetadataArray(from container: [String: Any]) -> [PlexMetadata] {
        guard let metadataJson = container["Metadata"] as? [[String: Any]] else { return [] }
        return metadataJson.compactMap { itemJson in
            guard let data = try? JSONSerialization.data(withJSONObject: itemJson),
                  var item = try? JSONDecoder().decode(PlexMetadata.self, from: data) else {
                return nil
            }
            item.serverId = serverId
            item.serverName = serverName
            if let guids = itemJson["Guid"] as? [[String: Any]] {
                item.tmdbId = PlexMetadata.extractTmdbId(from: guids)
                item.imdbId = PlexMetadata.extractImdbId(from: guids)
            }
            if let ratings = itemJson["Rating"] as? [[String: Any]] {
                item.imdbRating = PlexMetadata.extractImdbRating(from: ratings)
            }
            return item
        }
    }

    private func getMediaContainer(from json: [String: Any]) -> [String: Any]? {
        json["MediaContainer"] as? [String: Any]
    }

    // MARK: - Server Identity

    func getMachineIdentifier() async throws -> String {
        if let machineIdentifier { return machineIdentifier }
        let json = try await fetchJSON("/")
        guard let container = getMediaContainer(from: json),
              let identifier = container["machineIdentifier"] as? String else {
            throw PlexClientError.parseError
        }
        machineIdentifier = identifier
        return identifier
    }

    func buildMetadataUri(_ ratingKey: String) async throws -> String {
        let identifier = try await getMachineIdentifier()
        return "server://\(identifier)/com.plexapp.plugins.library/library/metadata/\(ratingKey)"
    }

    // MARK: - Libraries

    func getLibraries() async throws -> [PlexLibrary] {
        let json = try await fetchJSON("/library/sections")
        guard let container = getMediaContainer(from: json),
              let directories = container["Directory"] as? [[String: Any]] else {
            return []
        }
        return directories.compactMap { dirJson in
            guard let data = try? JSONSerialization.data(withJSONObject: dirJson),
                  var library = try? JSONDecoder().decode(PlexLibrary.self, from: data) else {
                return nil
            }
            library.serverId = serverId
            library.serverName = serverName
            return library
        }
    }

    func getLibraryContent(
        sectionId: String, start: Int? = nil, size: Int? = nil,
        sort: String? = nil, filters: [String: String]? = nil
    ) async throws -> [PlexMetadata] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "includeGuids", value: "1")
        ]
        if let start { queryItems.append(URLQueryItem(name: "X-Plex-Container-Start", value: "\(start)")) }
        if let size { queryItems.append(URLQueryItem(name: "X-Plex-Container-Size", value: "\(size)")) }
        if let sort { queryItems.append(URLQueryItem(name: "sort", value: sort)) }
        filters?.forEach { key, value in
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        let json = try await fetchJSON("/library/sections/\(sectionId)/all", queryItems: queryItems)
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    /// Fetches all content in a library section featuring a specific person.
    /// - Parameters:
    ///   - sectionId: The library section ID
    ///   - personId: The Plex person/actor ID
    ///   - role: The role filter key ("actor", "director", "producer")
    func getContentByPerson(sectionId: String, personId: Int, role: String) async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/library/sections/\(sectionId)/all", queryItems: [
            URLQueryItem(name: "includeGuids", value: "1"),
            URLQueryItem(name: role, value: "\(personId)")
        ])
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    func getLibraryTotalCount(sectionId: String) async throws -> Int {
        let json = try await fetchJSON("/library/sections/\(sectionId)/all", queryItems: [
            URLQueryItem(name: "X-Plex-Container-Start", value: "0"),
            URLQueryItem(name: "X-Plex-Container-Size", value: "0")
        ])
        guard let container = getMediaContainer(from: json) else { return 0 }
        return container["totalSize"] as? Int ?? container["size"] as? Int ?? 0
    }

    func getLibraryFilters(sectionId: String) async throws -> [PlexFilter] {
        let json = try await fetchJSON("/library/sections/\(sectionId)/filters")
        guard let container = getMediaContainer(from: json),
              let filtersJson = container["Filter"] as? [[String: Any]] ?? container["Directory"] as? [[String: Any]] else {
            return []
        }
        return filtersJson.compactMap { PlexFilter.from(json: $0) }
    }

    func getFilterValues(filterKey: String) async throws -> [PlexFilterValue] {
        let json = try await fetchJSON(filterKey)
        guard let container = getMediaContainer(from: json),
              let valuesJson = container["Directory"] as? [[String: Any]] else {
            return []
        }
        return valuesJson.compactMap { PlexFilterValue.from(json: $0) }
    }

    func getLibrarySorts(sectionId: String) async throws -> [PlexSort] {
        let json = try await fetchJSON("/library/sections/\(sectionId)/sorts")
        guard let container = getMediaContainer(from: json),
              let sortsJson = container["Sort"] as? [[String: Any]] ?? container["Directory"] as? [[String: Any]] else {
            return []
        }
        return sortsJson.compactMap { PlexSort.from(json: $0) }
    }

    // MARK: - Metadata

    func getMetadata(ratingKey: String) async throws -> PlexMetadata? {
        let json = try await fetchJSON("/library/metadata/\(ratingKey)", queryItems: [
            URLQueryItem(name: "includeGuids", value: "1"),
            URLQueryItem(name: "includeMarkers", value: "1"),
            URLQueryItem(name: "includeChapters", value: "1"),
            URLQueryItem(name: "includeOnDeck", value: "1"),
            URLQueryItem(name: "includeCollections", value: "1")
        ])
        guard let container = getMediaContainer(from: json) else { return nil }
        return parseMetadataArray(from: container).first
    }

    func getMetadataWithOnDeck(ratingKey: String) async throws -> (metadata: PlexMetadata?, onDeck: PlexMetadata?) {
        let json = try await fetchJSON("/library/metadata/\(ratingKey)", queryItems: [
            URLQueryItem(name: "includeGuids", value: "1"),
            URLQueryItem(name: "includeOnDeck", value: "1"),
            URLQueryItem(name: "includeCollections", value: "1")
        ])
        guard let container = getMediaContainer(from: json) else { return (nil, nil) }
        let items = parseMetadataArray(from: container)
        let metadata = items.first

        // Parse OnDeck from Hub
        var onDeck: PlexMetadata? = nil
        if let hubsJson = container["Hub"] as? [[String: Any]] {
            for hub in hubsJson {
                if let hubType = hub["context"] as? String, hubType.contains("ondeck"),
                   let metaArray = hub["Metadata"] as? [[String: Any]],
                   let onDeckJson = metaArray.first,
                   let data = try? JSONSerialization.data(withJSONObject: onDeckJson) {
                    var parsed = try? JSONDecoder().decode(PlexMetadata.self, from: data)
                    parsed?.serverId = serverId
                    parsed?.serverName = serverName
                    onDeck = parsed
                }
            }
        }

        return (metadata, onDeck)
    }

    func getChildren(ratingKey: String) async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/library/metadata/\(ratingKey)/children")
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    func getExtras(ratingKey: String) async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/library/metadata/\(ratingKey)/extras")
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    func getFileInfo(ratingKey: String) async throws -> PlexFileInfo? {
        let json = try await fetchJSON("/library/metadata/\(ratingKey)")
        return PlexFileInfo.from(json: json)
    }

    // MARK: - Search & Discovery

    func search(query: String, limit: Int = 10) async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/hubs/search", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: "\(limit)")
        ])
        guard let container = getMediaContainer(from: json),
              let hubs = container["Hub"] as? [[String: Any]] else {
            return []
        }

        var results: [PlexMetadata] = []
        for hub in hubs {
            let type = hub["type"] as? String ?? ""
            guard type == "movie" || type == "show" || type == "episode" else { continue }
            if let metadataArray = hub["Metadata"] as? [[String: Any]] {
                for itemJson in metadataArray {
                    if let data = try? JSONSerialization.data(withJSONObject: itemJson),
                       var item = try? JSONDecoder().decode(PlexMetadata.self, from: data) {
                        item.serverId = serverId
                        item.serverName = serverName
                        results.append(item)
                    }
                }
            }
        }
        return results
    }

    func getRecentlyAdded(limit: Int = 50) async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/library/recentlyAdded", queryItems: [
            URLQueryItem(name: "X-Plex-Container-Size", value: "\(limit)"),
            URLQueryItem(name: "includeGuids", value: "1")
        ])
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    func getOnDeck() async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/library/onDeck", queryItems: [
            URLQueryItem(name: "includeGuids", value: "1")
        ])
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    func getGlobalHubs(limit: Int = 15) async throws -> [PlexHub] {
        let json = try await fetchJSON("/hubs", queryItems: [
            URLQueryItem(name: "count", value: "\(limit)"),
            URLQueryItem(name: "includeEmpty", value: "0"),
            URLQueryItem(name: "includeGuids", value: "1")
        ])
        guard let container = getMediaContainer(from: json),
              let hubsJson = container["Hub"] as? [[String: Any]] else {
            return []
        }
        return hubsJson.compactMap { PlexHub.from(json: $0, serverId: serverId, serverName: serverName) }
    }

    func getLibraryHubs(sectionId: String, limit: Int = 15) async throws -> [PlexHub] {
        let json = try await fetchJSON("/hubs/sections/\(sectionId)", queryItems: [
            URLQueryItem(name: "count", value: "\(limit)"),
            URLQueryItem(name: "includeEmpty", value: "0"),
            URLQueryItem(name: "includeGuids", value: "1")
        ])
        guard let container = getMediaContainer(from: json),
              let hubsJson = container["Hub"] as? [[String: Any]] else {
            return []
        }
        return hubsJson.compactMap { PlexHub.from(json: $0, serverId: serverId, serverName: serverName) }
    }

    func getHubContent(hubKey: String) async throws -> [PlexMetadata] {
        let json = try await fetchJSON(hubKey)
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    // MARK: - Quality

    enum VideoQuality: String, CaseIterable {
        case original, high4K, high, medium, low

        var displayTitle: String {
            switch self {
            case .original: return "Original"
            case .high4K:   return "High (4K)"
            case .high:     return "High (1080p)"
            case .medium:   return "Medium (1080p)"
            case .low:      return "Low (720p)"
            }
        }

        var detail: String? {
            switch self {
            case .original: return nil
            case .high4K:   return "20 Mbps"
            case .high:     return "20 Mbps"
            case .medium:   return "10 Mbps"
            case .low:      return "4 Mbps"
            }
        }

        var maxVideoBitrate: Int? {
            switch self {
            case .original: return nil
            case .high4K:   return 20000
            case .high:     return 20000
            case .medium:   return 10000
            case .low:      return 4000
            }
        }

        var videoResolution: String? {
            switch self {
            case .original: return nil
            case .high4K:   return "3840x2160"
            case .high:     return "1920x1080"
            case .medium:   return "1920x1080"
            case .low:      return "1280x720"
            }
        }
    }

    // MARK: - Playback

    struct VideoPlaybackData {
        let videoURL: URL
        let directVideoURL: URL
        let ratingKey: String
        let partKey: String
        let partId: Int
        let duration: Int
        var audioStreams: [MediaStream]
        var subtitleStreams: [MediaStream]
        var chapters: [PlexChapter]
        var markers: [PlexMarker]
        var isDolbyVision: Bool = false
        var isHDR10: Bool = false
        var videoFrameRate: Float = 0
        var container: String = ""
    }

    struct MediaStream: Identifiable {
        let id: Int
        let streamType: Int
        let codec: String?
        let displayTitle: String?
        let language: String?
        let languageCode: String?
        let selected: Bool
        let isDefault: Bool
        let isForced: Bool
        let index: Int?
        /// Non-nil for external (sidecar) subtitle files — path like `/library/streams/{id}`
        let key: String?

        var isExternal: Bool { key != nil && !(key!.isEmpty) }

        /// Full URL for fetching an external subtitle file from Plex.
        func subtitleURL(baseURL: String, token: String) -> String? {
            guard let key, !key.isEmpty else { return nil }
            let ext: String
            switch (codec ?? "").lowercased() {
            case "ass":        ext = "ass"
            case "ssa":        ext = "ssa"
            case "webvtt","vtt": ext = "vtt"
            case "pgs","hdmv_pgs_subtitle": ext = "sup"
            default:           ext = "srt"
            }
            return "\(baseURL)\(key).\(ext)?X-Plex-Token=\(token)"
        }

        /// Fallback URL without extension for servers that don't handle the extension.
        func subtitleURLNoExt(baseURL: String, token: String) -> String? {
            guard let key, !key.isEmpty else { return nil }
            return "\(baseURL)\(key)?X-Plex-Token=\(token)"
        }
    }

    struct PlexChapter {
        let id: Int
        let startTimeOffset: Int
        let endTimeOffset: Int
        let title: String?
        let thumb: String?
    }

    struct PlexMarker {
        let type: String
        let startTimeOffset: Int
        let endTimeOffset: Int
    }

    func getVideoPlaybackData(ratingKey: String, mediaIndex: Int = 0) async throws -> VideoPlaybackData {
        let json = try await fetchJSON("/library/metadata/\(ratingKey)", queryItems: [
            URLQueryItem(name: "includeChapters", value: "1"),
            URLQueryItem(name: "includeMarkers", value: "1")
        ])

        guard let container = getMediaContainer(from: json),
              let metadataArray = container["Metadata"] as? [[String: Any]],
              let metadata = metadataArray.first,
              let mediaArray = metadata["Media"] as? [[String: Any]],
              mediaIndex < mediaArray.count else {
            throw PlexClientError.parseError
        }

        let media = mediaArray[mediaIndex]
        let duration = metadata["duration"] as? Int ?? media["duration"] as? Int ?? 0
        let mediaContainer = (media["container"] as? String ?? "").lowercased()

        guard let parts = media["Part"] as? [[String: Any]],
              let part = parts.first,
              let partKey = part["key"] as? String,
              let partId = part["id"] as? Int else {
            throw PlexClientError.parseError
        }

        // Direct file URL — mpv plays everything at original quality, no transcoding needed
        let directString: String
        if partKey.hasPrefix("http") {
            directString = partKey
        } else {
            let separator = partKey.contains("?") ? "&" : "?"
            directString = "\(baseURL)\(partKey)\(separator)X-Plex-Token=\(token)"
        }
        guard let videoURL = URL(string: directString) else {
            throw PlexClientError.invalidURL
        }

        // Parse streams
        var audioStreams: [MediaStream] = []
        var subtitleStreams: [MediaStream] = []
        if let streams = part["Stream"] as? [[String: Any]] {
            for stream in streams {
                let streamType = stream["streamType"] as? Int ?? 0
                let mediaStream = MediaStream(
                    id: stream["id"] as? Int ?? 0,
                    streamType: streamType,
                    codec: stream["codec"] as? String,
                    displayTitle: stream["displayTitle"] as? String,
                    language: stream["language"] as? String,
                    languageCode: stream["languageCode"] as? String,
                    selected: stream["selected"] as? Bool ?? false,
                    isDefault: stream["default"] as? Bool ?? false,
                    isForced: stream["forced"] as? Bool ?? false,
                    index: stream["index"] as? Int,
                    key: stream["key"] as? String
                )
                if streamType == 2 { audioStreams.append(mediaStream) }
                else if streamType == 3 { subtitleStreams.append(mediaStream) }
            }
        }

        // Parse chapters
        var chapters: [PlexChapter] = []
        if let chapterArray = metadata["Chapter"] as? [[String: Any]] {
            chapters = chapterArray.enumerated().map { idx, ch in
                PlexChapter(
                    id: ch["id"] as? Int ?? idx,
                    startTimeOffset: ch["startTimeOffset"] as? Int ?? 0,
                    endTimeOffset: ch["endTimeOffset"] as? Int ?? 0,
                    title: ch["tag"] as? String,
                    thumb: ch["thumb"] as? String
                )
            }
        }

        // Parse markers (intro/credits)
        var markers: [PlexMarker] = []
        if let markerArray = metadata["Marker"] as? [[String: Any]] {
            markers = markerArray.compactMap { m in
                guard let type = m["type"] as? String else { return nil }
                return PlexMarker(
                    type: type,
                    startTimeOffset: m["startTimeOffset"] as? Int ?? 0,
                    endTimeOffset: m["endTimeOffset"] as? Int ?? 0
                )
            }
        }

        // Parse video stream info for display criteria
        var isDolbyVision = false
        var isHDR10 = false
        var videoFrameRate: Float = 0
        if let streams = part["Stream"] as? [[String: Any]] {
            for stream in streams where (stream["streamType"] as? Int) == 1 {
                // Dolby Vision detection — check multiple indicators
                let doviPresent = stream["DOVIPresent"] as? Bool ?? false
                let doviBLPresent = stream["DOVIBLPresent"] as? Bool ?? false
                let doviProfile = stream["DOVIProfile"] as? Int
                let displayTitle = stream["displayTitle"] as? String ?? ""
                let extDisplayTitle = stream["extendedDisplayTitle"] as? String ?? ""
                isDolbyVision = doviPresent || doviBLPresent
                    || doviProfile != nil
                    || displayTitle.localizedCaseInsensitiveContains("Dolby Vision")
                    || extDisplayTitle.localizedCaseInsensitiveContains("Dolby Vision")

                let colorTrc = stream["colorTrc"] as? String ?? ""
                isHDR10 = !isDolbyVision && (colorTrc.contains("smpte2084") || colorTrc.contains("pq"))
                if let fps = stream["frameRate"] as? String {
                    videoFrameRate = Float(fps) ?? 0
                } else if let fpsDouble = stream["frameRate"] as? Double {
                    videoFrameRate = Float(fpsDouble)
                }
                break
            }
        }
        // Fallback FPS from media container
        if videoFrameRate == 0 {
            if let fpsStr = media["videoFrameRate"] as? String {
                videoFrameRate = fpsStr == "24p" ? 23.976 : fpsStr == "PAL" ? 25 : fpsStr == "NTSC" ? 29.97 : 0
            }
        }

        return VideoPlaybackData(
            videoURL: videoURL,
            directVideoURL: videoURL,
            ratingKey: ratingKey,
            partKey: partKey,
            partId: partId,
            duration: duration,
            audioStreams: audioStreams, subtitleStreams: subtitleStreams,
            chapters: chapters, markers: markers,
            isDolbyVision: isDolbyVision,
            isHDR10: isHDR10,
            videoFrameRate: videoFrameRate,
            container: mediaContainer
        )
    }

    /// Tell the Plex server which audio/subtitle streams are selected for a
    /// given media part. This must be called BEFORE starting a transcode so
    /// the server knows which subtitle to burn and which audio to include.
    func setStreamSelection(partId: Int, audioStreamID: Int? = nil, subtitleStreamID: Int? = nil) async {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "allParts", value: "1"),
        ]
        if let audioStreamID {
            queryItems.append(URLQueryItem(name: "audioStreamID", value: "\(audioStreamID)"))
        }
        if let subtitleStreamID {
            queryItems.append(URLQueryItem(name: "subtitleStreamID", value: "\(subtitleStreamID)"))
        } else {
            // Setting to 0 tells the server to deselect subtitles
            queryItems.append(URLQueryItem(name: "subtitleStreamID", value: "0"))
        }
        _ = try? await putRequest("/library/parts/\(partId)", queryItems: queryItems)
    }

    struct TranscodeResult {
        let url: URL
        let sessionId: String
    }

    func transcodeVideoURL(ratingKey: String, quality: VideoQuality) async throws -> TranscodeResult? {
        guard let bitrate = quality.maxVideoBitrate,
              let resolution = quality.videoResolution else { return nil }

        let session = UUID().uuidString

        // Same query items are sent to the decision endpoint (to set up
        // the server-side transcode session) and then reused for the
        // start.m3u8 URL that mpv fetches.
        // Declare HEVC + 10-bit support so Plex uses HEVC for transcoding
        // (preserves HDR10 when server hardware supports it) and prefers
        // direct-streaming the video track when bitrate is within limits
        // (preserves everything including Dolby Vision).
        let profileExtra = [
            "append-transcode-target-codec(type=videoProfile&context=streaming&protocol=hls&videoCodec=hevc)",
            "add-limitation(scope=videoCodec&scopeName=hevc&type=upperBound&name=video.bitDepth&value=10&isRequired=false)",
            "add-limitation(scope=videoCodec&scopeName=hevc&type=upperBound&name=video.width&value=3840&isRequired=false)",
            "add-limitation(scope=videoCodec&scopeName=hevc&type=upperBound&name=video.height&value=2160&isRequired=false)",
        ].joined(separator: "+")

        let queryItems = [
            URLQueryItem(name: "hasMDE", value: "1"),
            URLQueryItem(name: "path", value: "/library/metadata/\(ratingKey)"),
            URLQueryItem(name: "mediaIndex", value: "0"),
            URLQueryItem(name: "partIndex", value: "0"),
            URLQueryItem(name: "protocol", value: "hls"),
            URLQueryItem(name: "fastSeek", value: "1"),
            URLQueryItem(name: "directPlay", value: "0"),
            URLQueryItem(name: "directStream", value: "1"),
            URLQueryItem(name: "directStreamAudio", value: "1"),
            URLQueryItem(name: "copyts", value: "1"),
            URLQueryItem(name: "videoResolution", value: resolution),
            URLQueryItem(name: "maxVideoBitrate", value: "\(bitrate)"),
            URLQueryItem(name: "subtitleSize", value: "100"),
            URLQueryItem(name: "audioBoost", value: "100"),
            URLQueryItem(name: "location", value: "lan"),
            URLQueryItem(name: "autoAdjustQuality", value: "0"),
            URLQueryItem(name: "mediaBufferSize", value: "102400"),
            URLQueryItem(name: "subtitles", value: "burn"),
            URLQueryItem(name: "session", value: session),
            URLQueryItem(name: "X-Plex-Session-Identifier", value: session),
            URLQueryItem(name: "X-Plex-Client-Identifier", value: clientIdentifier),
            URLQueryItem(name: "X-Plex-Product", value: "Vibe"),
            URLQueryItem(name: "X-Plex-Platform", value: "tvOS"),
            URLQueryItem(name: "X-Plex-Client-Profile-Extra", value: profileExtra),
        ]

        // Call the decision endpoint to set up the transcode session.
        // Note: audio/subtitle selection must be set via PUT /library/parts/{partId}
        // BEFORE calling this method — the decision endpoint reads from the part metadata.
        _ = try await fetchJSON("/video/:/transcode/universal/decision", queryItems: queryItems)

        // Build the start.m3u8 URL with the full set of params.
        var components = URLComponents(string: "\(baseURL)/video/:/transcode/universal/start.m3u8")
        var params = queryItems
        params.append(URLQueryItem(name: "X-Plex-Token", value: token))
        components?.queryItems = params
        guard let url = components?.url else { return nil }
        return TranscodeResult(url: url, sessionId: session)
    }

    /// Constructs an HLS direct stream URL for AVPlayer playback.
    /// Plex remuxes the file to HLS without re-encoding video/audio.
    func directStreamHLSURL(ratingKey: String) async throws -> URL? {
        let session = UUID().uuidString

        let profileExtra = [
            "append-transcode-target-codec(type=videoProfile&context=streaming&protocol=hls&videoCodec=hevc)",
            "add-limitation(scope=videoCodec&scopeName=hevc&type=upperBound&name=video.bitDepth&value=10&isRequired=false)",
            "add-limitation(scope=videoCodec&scopeName=hevc&type=upperBound&name=video.width&value=3840&isRequired=false)",
            "add-limitation(scope=videoCodec&scopeName=hevc&type=upperBound&name=video.height&value=2160&isRequired=false)",
        ].joined(separator: "+")

        let queryItems = [
            URLQueryItem(name: "hasMDE", value: "1"),
            URLQueryItem(name: "path", value: "/library/metadata/\(ratingKey)"),
            URLQueryItem(name: "mediaIndex", value: "0"),
            URLQueryItem(name: "partIndex", value: "0"),
            URLQueryItem(name: "protocol", value: "hls"),
            URLQueryItem(name: "fastSeek", value: "1"),
            URLQueryItem(name: "directPlay", value: "0"),
            URLQueryItem(name: "directStream", value: "1"),
            URLQueryItem(name: "directStreamAudio", value: "1"),
            URLQueryItem(name: "copyts", value: "1"),
            URLQueryItem(name: "subtitleSize", value: "100"),
            URLQueryItem(name: "audioBoost", value: "100"),
            URLQueryItem(name: "location", value: "lan"),
            URLQueryItem(name: "autoAdjustQuality", value: "0"),
            URLQueryItem(name: "mediaBufferSize", value: "102400"),
            URLQueryItem(name: "session", value: session),
            URLQueryItem(name: "X-Plex-Session-Identifier", value: session),
            URLQueryItem(name: "X-Plex-Client-Identifier", value: clientIdentifier),
            URLQueryItem(name: "X-Plex-Product", value: "Vibe"),
            URLQueryItem(name: "X-Plex-Platform", value: "tvOS"),
            URLQueryItem(name: "X-Plex-Client-Profile-Extra", value: profileExtra),
        ]

        _ = try await fetchJSON("/video/:/transcode/universal/decision", queryItems: queryItems)

        var components = URLComponents(string: "\(baseURL)/video/:/transcode/universal/start.m3u8")
        var params = queryItems
        params.append(URLQueryItem(name: "X-Plex-Token", value: token))
        components?.queryItems = params
        return components?.url
    }

    func getThumbnailURL(_ thumbPath: String?) -> URL? {
        guard let thumbPath, !thumbPath.isEmpty else { return nil }
        let urlString = thumbPath.hasPrefix("http") ? thumbPath : "\(baseURL)\(thumbPath)?X-Plex-Token=\(token)"
        return URL(string: urlString)
    }

    // MARK: - Progress & Watch State

    func updateProgress(ratingKey: String, time: Int, state: String, duration: Int? = nil, session: String? = nil) async throws {
        var queryItems = [
            URLQueryItem(name: "ratingKey", value: ratingKey),
            URLQueryItem(name: "time", value: "\(time)"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "key", value: "/library/metadata/\(ratingKey)")
        ]
        if let duration {
            queryItems.append(URLQueryItem(name: "duration", value: "\(duration)"))
        }
        if let session {
            queryItems.append(URLQueryItem(name: "X-Plex-Session-Identifier", value: session))
        }
        try await postRequest("/:/timeline", queryItems: queryItems)
    }

    func markAsWatched(ratingKey: String) async throws {
        _ = try await fetchJSON("/:/scrobble", queryItems: [
            URLQueryItem(name: "identifier", value: "com.plexapp.plugins.library"),
            URLQueryItem(name: "key", value: ratingKey)
        ])
    }

    func markAsUnwatched(ratingKey: String) async throws {
        _ = try await fetchJSON("/:/unscrobble", queryItems: [
            URLQueryItem(name: "identifier", value: "com.plexapp.plugins.library"),
            URLQueryItem(name: "key", value: ratingKey)
        ])
    }

    func removeFromOnDeck(ratingKey: String) async throws {
        _ = try await putRequest("/actions/removeFromContinueWatching", queryItems: [
            URLQueryItem(name: "ratingKey", value: ratingKey)
        ])
    }

    // MARK: - Stream Selection

    func selectStreams(partId: Int, audioStreamID: Int? = nil, subtitleStreamID: Int? = nil, allParts: Bool = false) async throws -> Bool {
        var queryItems: [URLQueryItem] = []
        if let audioStreamID {
            queryItems.append(URLQueryItem(name: "audioStreamID", value: "\(audioStreamID)"))
        }
        if let subtitleStreamID {
            queryItems.append(URLQueryItem(name: "subtitleStreamID", value: "\(subtitleStreamID)"))
        }
        if allParts {
            queryItems.append(URLQueryItem(name: "allParts", value: "1"))
        }
        return try await putRequest("/library/parts/\(partId)", queryItems: queryItems)
    }

    // MARK: - Playlists

    func getPlaylists(playlistType: String = "video") async throws -> [PlexPlaylist] {
        let json = try await fetchJSON("/playlists", queryItems: [
            URLQueryItem(name: "playlistType", value: playlistType)
        ])
        guard let container = getMediaContainer(from: json),
              let playlistsJson = container["Metadata"] as? [[String: Any]] else {
            return []
        }
        return playlistsJson.compactMap { pJson in
            guard let data = try? JSONSerialization.data(withJSONObject: pJson),
                  var playlist = try? JSONDecoder().decode(PlexPlaylist.self, from: data) else {
                return nil
            }
            playlist.serverId = serverId
            playlist.serverName = serverName
            return playlist
        }
    }

    func getPlaylistItems(playlistId: String) async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/playlists/\(playlistId)/items")
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    // MARK: - Collections

    func getLibraryCollections(sectionId: String) async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/library/sections/\(sectionId)/collections")
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    func getCollectionItems(collectionId: String) async throws -> [PlexMetadata] {
        let json = try await fetchJSON("/library/collections/\(collectionId)/children")
        guard let container = getMediaContainer(from: json) else { return [] }
        return parseMetadataArray(from: container)
    }

    // MARK: - Play Queues

    struct PlayQueueResponse {
        let playQueueID: Int
        let items: [PlexMetadata]
        let selectedItemIndex: Int
    }

    func createPlayQueue(uri: String? = nil, type: String = "video", key: String? = nil) async throws -> PlayQueueResponse? {
        var queryItems = [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "shuffle", value: "0"),
            URLQueryItem(name: "repeat", value: "0"),
            URLQueryItem(name: "continuous", value: "1")
        ]
        if let uri { queryItems.append(URLQueryItem(name: "uri", value: uri)) }
        if let key { queryItems.append(URLQueryItem(name: "key", value: key)) }

        guard let url = buildURL("/playQueues", queryItems: queryItems) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")

        let (data, _) = try await session.data(for: request)
        guard data.count <= Self.maxResponseSize else { throw PlexClientError.parseError }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let container = json["MediaContainer"] as? [String: Any] else { return nil }

        let playQueueID = container["playQueueID"] as? Int ?? 0
        let selectedIndex = container["playQueueSelectedItemOffset"] as? Int ?? 0
        let items = parseMetadataArray(from: container)

        return PlayQueueResponse(playQueueID: playQueueID, items: items, selectedItemIndex: selectedIndex)
    }

    // MARK: - Server Management

    func scanLibrary(sectionId: String) async throws {
        _ = try await fetchJSON("/library/sections/\(sectionId)/refresh")
    }

    func deleteMediaItem(ratingKey: String) async throws -> Bool {
        try await deleteRequest("/library/metadata/\(ratingKey)")
    }
}

enum PlexClientError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case parseError
    case notAuthenticated
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .httpError(let code): return "Server error (\(code))"
        case .parseError: return "Failed to parse server response"
        case .notAuthenticated: return "Not signed in"
        case .unauthorized: return "Session expired. Please sign in again."
        }
    }

    var isAuthError: Bool {
        switch self {
        case .unauthorized, .notAuthenticated: return true
        default: return false
        }
    }
}
