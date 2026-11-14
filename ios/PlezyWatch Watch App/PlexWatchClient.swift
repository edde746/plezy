import Foundation
import Network
import Security

extension Notification.Name {
  static let plexCredentialsDidChange = Notification.Name("plexCredentialsDidChange")
  static let plexCredentialsExpired = Notification.Name("plexCredentialsExpired")
}

/// Lightweight Plex API client for Apple Watch
/// Handles direct communication with the Plex server for independent operation
class PlexWatchClient {
  static let shared = PlexWatchClient()

  private let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 25
    config.timeoutIntervalForResource = 45
    return URLSession(configuration: config)
  }()
  /// Pre-Keychain home of the credentials, read once to migrate them.
  private let legacyCredentialsKey = "plexServerCredentials"
  private let signedOutKey = "plexSignedOutOnWatch"

  /// Guards everything below it: these are read from whichever thread a
  /// network callback lands on.
  private let stateLock = NSLock()
  private var loadedCredentials = false
  private var storedCredentials: Credentials?
  private var cachedMusicSectionId: String?
  private var cachedStreamingBase: String?
  private var cachedStreamingBaseAt: Date?
  private var cachedApiBase: String?
  private var cachedApiBaseAt: Date?
  private var serverUnreachable = false
  private var lastDiscoveryAt: Date?
  /// How often plex.tv may be asked for the server's addresses.
  private let discoveryInterval: TimeInterval = 2 * 60

  /// A base can go stale without the network visibly changing, for example
  /// when the server's address moves. Past this age it is probed again.
  private let streamingBaseTtl: TimeInterval = 5 * 60
  private let pathMonitor = NWPathMonitor()

  struct Credentials: Codable {
    let serverUrl: String
    let token: String
    var machineIdentifier: String?
    /// The server's remote addresses, from the phone. Its own address is
    /// usually the LAN one, which is no use on a run with only the watch.
    var fallbackUrls: [String]?
    /// Typed in on the watch rather than handed over by the phone, so the
    /// phone signing out says nothing about it.
    var isManual: Bool?
  }

  init() {
    // Whichever base answered on the last network says nothing about this
    // one: a LAN address picked at home is unreachable on cellular.
    pathMonitor.pathUpdateHandler = { [weak self] _ in
      self?.invalidateStreamingBase()
    }
    pathMonitor.start(queue: DispatchQueue(label: "plezy.watch.network-path", qos: .utility))
  }

  /// Stored server credentials for independent operation
  var credentials: Credentials? {
    get {
      stateLock.lock()
      defer { stateLock.unlock() }
      if !loadedCredentials {
        storedCredentials = loadCredentials()
        loadedCredentials = true
        if let token = storedCredentials?.token { WatchInstrument.registerSecret(token) }
      }
      return storedCredentials
    }
    set {
      stateLock.lock()
      defer { stateLock.unlock() }
      let serverChanged = storedCredentials?.serverUrl != newValue?.serverUrl
      loadedCredentials = true
      storedCredentials = newValue
      cachedStreamingBase = nil
      cachedStreamingBaseAt = nil
      cachedApiBase = nil
      cachedApiBaseAt = nil
      if serverChanged { cachedMusicSectionId = nil }
      if let newValue {
        WatchInstrument.registerSecret(newValue.token)
        if let data = try? JSONEncoder().encode(newValue), !WatchKeychain.save(data) {
          WatchInstrument.plex("Could not store credentials in the Keychain")
        }
      } else {
        WatchKeychain.delete()
      }
    }
  }

  var hasCredentials: Bool { credentials != nil }

  /// The owner signed out on this watch, so the phone must not sign it back
  /// in until they ask. Survives relaunch: the phone's application context
  /// still holds the token and is re-delivered on every launch.
  var isSignedOutOnWatch: Bool {
    UserDefaults.standard.bool(forKey: signedOutKey)
  }

  func allowPhoneCredentials() {
    UserDefaults.standard.removeObject(forKey: signedOutKey)
  }

  private func loadCredentials() -> Credentials? {
    let decoder = JSONDecoder()
    if let data = WatchKeychain.load() {
      UserDefaults.standard.removeObject(forKey: legacyCredentialsKey)
      return try? decoder.decode(Credentials.self, from: data)
    }
    guard let legacy = UserDefaults.standard.data(forKey: legacyCredentialsKey) else { return nil }
    // Removing the old copy before the new one is safely stored would sign
    // the owner out, so a failed write leaves it for the next launch.
    if WatchKeychain.save(legacy) {
      UserDefaults.standard.removeObject(forKey: legacyCredentialsKey)
    }
    return try? decoder.decode(Credentials.self, from: legacy)
  }

  /// Save credentials for standalone watch use (persists across reboots).
  func saveCredentials(
    serverUrl: String,
    token: String,
    machineIdentifier: String? = nil,
    fallbackUrls: [String]? = nil,
    isManual: Bool = false
  ) {
    let current = credentials
    let preservedMachineId = current?.serverUrl == serverUrl ? current?.machineIdentifier : nil
    credentials = Credentials(
      serverUrl: serverUrl,
      token: token,
      machineIdentifier: machineIdentifier ?? preservedMachineId,
      fallbackUrls: fallbackUrls ?? (current?.serverUrl == serverUrl ? current?.fallbackUrls : nil),
      isManual: isManual
    )
    if isManual { allowPhoneCredentials() }
    NotificationCenter.default.post(name: .plexCredentialsDidChange, object: nil)
    Task { await fetchMachineIdentifier() }
  }

  func clearCredentials() {
    credentials = nil
    setCachedMusicSectionId(nil)
    NotificationCenter.default.post(name: .plexCredentialsDidChange, object: nil)
  }

  /// Sign out because the owner asked to on this watch.
  func signOutOnWatch() {
    UserDefaults.standard.set(true, forKey: signedOutKey)
    clearCredentials()
  }

  private func setCachedMusicSectionId(_ id: String?) {
    stateLock.lock()
    cachedMusicSectionId = id
    stateLock.unlock()
  }

  /// Human-readable server label for UI (host from plex.direct or URL).
  var serverDisplayName: String {
    guard let url = credentials?.serverUrl, let parsed = URL(string: url) else { return "Plex" }
    let host = parsed.host ?? parsed.absoluteString
    if host.contains(".plex.direct"), let prefix = host.split(separator: ".").first {
      return String(prefix).replacingOccurrences(of: "-", with: ".")
    }
    return host
  }

  // MARK: - API Methods

  /// Fetch and cache the server's machine identifier (needed for radio stations)
  @discardableResult
  func fetchMachineIdentifier() async -> String? {
    guard let creds = credentials else {
      WatchInstrument.plex("fetchMachineIdentifier: no credentials")
      return nil
    }
    if let cached = creds.machineIdentifier {
      WatchInstrument.plex("fetchMachineIdentifier: using cached \(cached)")
      return cached
    }

    WatchInstrument.plex("fetchMachineIdentifier: fetching from \(creds.serverUrl)/identity")
    guard let json = await get("/identity") else {
      WatchInstrument.plex("fetchMachineIdentifier: /identity request failed")
      return nil
    }
    if let container = json["MediaContainer"] as? [String: Any],
      let machineId = container["machineIdentifier"] as? String
    {
      // Read again rather than writing back what was captured before the
      // await: a sign-out or new server in between must not be undone.
      if var latest = credentials, latest.serverUrl == creds.serverUrl {
        latest.machineIdentifier = machineId
        credentials = latest
      }
      WatchInstrument.plex("fetchMachineIdentifier: got \(machineId)")
      return machineId
    }
    WatchInstrument.plex("fetchMachineIdentifier: unexpected response: \(json)")
    return nil
  }

  /// Get all libraries
  func getLibraries() async -> [LibrarySection] {
    guard let json = await get("/library/sections") else { return [] }
    guard let container = json["MediaContainer"] as? [String: Any],
      let directories = container["Directory"] as? [[String: Any]]
    else { return [] }

    return directories.compactMap { dir in
      guard let key = dir["key"] as? String,
        let title = dir["title"] as? String,
        let type = dir["type"] as? String
      else { return nil }
      return LibrarySection(key: key, title: title, type: type)
    }
  }

  /// Get music libraries only
  func getMusicLibraries() async -> [LibrarySection] {
    await getLibraries().filter { $0.type == "artist" }
  }

  /// Cached first music library section id (avoids repeated /library/sections round-trips).
  func musicSectionId() async -> String? {
    stateLock.lock()
    let cached = cachedMusicSectionId
    stateLock.unlock()
    if let cached { return cached }
    let serverUrl = credentials?.serverUrl
    let sectionId = await getMusicLibraries().first?.key
    if credentials?.serverUrl == serverUrl { setCachedMusicSectionId(sectionId) }
    return sectionId
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
      let metadata = container["Metadata"] as? [[String: Any]]
    else { return [] }

    return metadata.compactMap { dict -> MusicItem? in
      guard let ratingKey = dict["ratingKey"] as? String,
        let title = dict["title"] as? String
      else { return nil }
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

    guard let base = await apiBase() else { return nil }
    let urlString = "\(base)/playQueues?\(params)&X-Plex-Token=\(creds.token)"
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
        let container = json["MediaContainer"] as? [String: Any]
      else { return nil }

      let queueId = container["playQueueID"] as? Int ?? 0
      let metadata = container["Metadata"] as? [[String: Any]] ?? []
      let items = metadata.compactMap { parseMusicItem($0) }
      WatchInstrument.plex("Created playlist queue \(queueId) with \(items.count) items")

      return PlayQueueResult(playQueueId: queueId, items: items)
    } catch {
      WatchInstrument.plex("Create playlist queue error: \(error)")
      return nil
    }
  }

  /// Recently played artists from library sort order (lastViewedAt).
  func getRecentlyPlayedArtists(limit: Int = 12) async -> [MusicItem] {
    if let sectionId = await musicSectionId() {
      let fromLibrary = await getMetadataList(
        "/library/sections/\(sectionId)/all?type=8&sort=lastViewedAt:desc&limit=\(limit)"
      )
      if !fromLibrary.isEmpty { return fromLibrary }
    }

    // Fallback: derive unique artists from play history
    let history = await getPlayHistory(limit: limit * 3)
    var seen = Set<String>()
    var artists: [MusicItem] = []
    for track in history {
      guard let key = track.grandparentRatingKey, let name = track.artist else { continue }
      guard seen.insert(key).inserted else { continue }
      artists.append(
        MusicItem(
          ratingKey: key,
          title: name,
          type: "artist",
          artist: name,
          album: nil,
          thumb: track.thumb,
          duration: nil,
          partKey: nil,
          parentRatingKey: nil,
          grandparentRatingKey: key
        ))
      if artists.count >= limit { break }
    }
    return artists
  }

  /// Recently played albums.
  func getRecentlyPlayedAlbums(limit: Int = 10) async -> [MusicItem] {
    guard let sectionId = await musicSectionId() else { return [] }
    return await getMetadataList(
      "/library/sections/\(sectionId)/all?type=9&sort=lastViewedAt:desc&limit=\(limit)"
    )
  }

  /// Play history from Plex — most accurate source for what was actually listened to.
  func getPlayHistory(limit: Int = 20) async -> [MusicItem] {
    guard let json = await get("/status/sessions/history/all?sort=viewedAt:desc&X-Plex-Container-Size=\(limit)") else {
      return []
    }
    guard let container = json["MediaContainer"] as? [String: Any],
      let metadata = container["Metadata"] as? [[String: Any]]
    else { return [] }

    let tracks = metadata.compactMap { dict -> MusicItem? in
      guard (dict["type"] as? String) == "track" else { return nil }
      return parseMusicItem(dict)
    }
    // Plex may ignore container size on this endpoint — always cap client-side.
    return Array(tracks.prefix(limit))
  }

  /// Search across all content
  func search(query: String) async -> [MusicItem] {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&=+?#")
    let encoded = query.addingPercentEncoding(withAllowedCharacters: allowed) ?? query
    guard let json = await get("/hubs/search?query=\(encoded)&limit=20") else { return [] }
    guard let container = json["MediaContainer"] as? [String: Any],
      let hubs = container["Hub"] as? [[String: Any]]
    else { return [] }

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

  /// HTTP headers AVPlayer should send for Plex media URLs.
  func playbackHeaders(token: String) -> [String: String] {
    [
      "X-Plex-Token": token,
      "X-Plex-Client-Identifier": clientIdentifier,
      "X-Plex-Product": "Plezy",
      "X-Plex-Version": "1.0",
      "Accept": "*/*",
    ]
  }

  /// Pick a base URL that works for AVPlayer media streaming (probe LAN + plex.direct).
  func streamingBase() async -> String {
    if let cached = freshStreamingBase() { return cached }
    if let base = await firstAnsweringOrDiscover(streamBaseCandidates) {
      WatchInstrument.plex("streamingBase: using \(base)")
      setStreamingBase(base)
      return base
    }
    // Not cached: nothing answered, so the next track should look again.
    return credentials?.serverUrl ?? ""
  }

  /// Forget the chosen bases, so the next request probes for one again.
  func invalidateStreamingBase() {
    stateLock.lock()
    cachedStreamingBase = nil
    cachedStreamingBaseAt = nil
    cachedApiBase = nil
    cachedApiBaseAt = nil
    stateLock.unlock()
  }

  /// Where API requests go: the phone's address, or the first of the
  /// server's remote addresses that answers when it doesn't. Nil when
  /// nothing answers, so the caller fails now rather than after a timeout.
  ///
  /// The phone hands over whatever address it is using, which at home is
  /// the LAN one. Out on a run with only the watch, on cellular, that
  /// address goes nowhere.
  func apiBase() async -> String? {
    guard let creds = credentials else { return nil }
    if let fresh = freshApiBase() { return fresh }
    guard let base = await firstAnsweringOrDiscover([creds.serverUrl] + (creds.fallbackUrls ?? [])) else {
      stateLock.lock()
      serverUnreachable = true
      stateLock.unlock()
      return nil
    }
    WatchInstrument.plex("apiBase: using \(base)")
    stateLock.lock()
    cachedApiBase = base
    cachedApiBaseAt = Date()
    serverUnreachable = false
    stateLock.unlock()
    return base
  }

  /// Whether the last look for an address found none that answered, for
  /// telling the owner why nothing played.
  var isServerUnreachable: Bool {
    stateLock.lock()
    defer { stateLock.unlock() }
    return serverUnreachable
  }

  /// The first of [candidates] that answers, then the addresses plex.tv
  /// lists for the server if none does.
  private func firstAnsweringOrDiscover(_ candidates: [String]) async -> String? {
    let usable = candidates.filter { onLocalNetwork || !Self.isPrivateAddress($0) }
    if let base = await firstAnswering(usable) { return base }
    let discovered = await discoverRemoteUrls().filter { !usable.contains($0) }
    return await firstAnswering(discovered)
  }

  /// The first of [candidates], in order of preference, that answers.
  ///
  /// All are asked at once. Asked one by one, each address that went
  /// nowhere cost the whole timeout before the next was tried.
  private func firstAnswering(_ candidates: [String]) async -> String? {
    guard !candidates.isEmpty else { return nil }
    return await withTaskGroup(of: (Int, Bool).self) { group in
      for (index, base) in candidates.enumerated() {
        group.addTask { (index, await self.probeStreamingBase(base)) }
      }
      var answered = [Bool?](repeating: nil, count: candidates.count)
      for await (index, ok) in group {
        answered[index] = ok
        if !ok { WatchInstrument.plex("unreachable \(candidates[index])") }
        // Settled once everything preferred over the best answer so
        // far has failed.
        if let best = answered.firstIndex(where: { $0 != false }), answered[best] == true {
          group.cancelAll()
          return candidates[best]
        }
      }
      return nil
    }
  }

  /// Whether the watch is on Wi-Fi or borrowing the phone's connection,
  /// either of which may reach the home network. On cellular alone a
  /// private address goes nowhere, and only costs a timeout to find out.
  private var onLocalNetwork: Bool {
    let path = pathMonitor.currentPath
    return !path.usesInterfaceType(.cellular) || path.usesInterfaceType(.wifi)
  }

  /// A LAN address, written as an IP or as a plex.direct name for one.
  static func isPrivateAddress(_ base: String) -> Bool {
    guard let host = URL(string: base)?.host?.lowercased() else { return false }
    let label =
      host.hasSuffix(".plex.direct")
      ? host.split(separator: ".").first.map { $0.replacingOccurrences(of: "-", with: ".") } ?? ""
      : host
    let octets = label.split(separator: ".").compactMap { UInt8($0) }
    return octets.count == 4 && label.split(separator: ".").count == 4 && isPrivateIPv4(octets)
  }

  /// The server's remote addresses as plex.tv lists them, kept for next time.
  ///
  /// The phone passes these on when it signs the watch in, but only when it
  /// gets the chance, and only a recent build does. plex.tv answers wherever
  /// the watch has a connection. It accepts only the owner's token, so for a
  /// server shared with the owner this finds nothing.
  private func discoverRemoteUrls() async -> [String] {
    guard let creds = credentials, let machineId = creds.machineIdentifier else { return [] }
    stateLock.lock()
    let recentlyAsked = lastDiscoveryAt.map { Date().timeIntervalSince($0) < discoveryInterval } ?? false
    if !recentlyAsked { lastDiscoveryAt = Date() }
    stateLock.unlock()
    guard !recentlyAsked,
      let url = URL(string: "https://clients.plex.tv/api/v2/resources?includeHttps=1&includeRelay=1")
    else {
      return []
    }
    var request = URLRequest(url: url)
    request.timeoutInterval = 15
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(creds.token, forHTTPHeaderField: "X-Plex-Token")
    request.setValue(clientIdentifier, forHTTPHeaderField: "X-Plex-Client-Identifier")
    request.setValue("Plezy", forHTTPHeaderField: "X-Plex-Product")
    do {
      let (data, response) = try await session.data(for: request)
      guard (response as? HTTPURLResponse)?.statusCode == 200,
        let resources = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
        let server = resources.first(where: { $0["clientIdentifier"] as? String == machineId })
      else {
        WatchInstrument.plex("discoverRemoteUrls: plex.tv does not list this server for this token")
        return []
      }
      let remote = (server["connections"] as? [[String: Any]] ?? []).filter {
        $0["local"] as? Bool != true && $0["protocol"] as? String == "https" && $0["IPv6"] as? Bool != true
      }
      let isRelay: ([String: Any]) -> Bool = { $0["relay"] as? Bool == true }
      let urls = (remote.filter { !isRelay($0) } + remote.filter(isRelay)).compactMap { $0["uri"] as? String }
      WatchInstrument.plex("discoverRemoteUrls: \(urls.count) remote addresses")
      if !urls.isEmpty, var latest = credentials, latest.token == creds.token,
        latest.serverUrl == creds.serverUrl, latest.fallbackUrls != urls
      {
        latest.fallbackUrls = urls
        credentials = latest
      }
      return urls
    } catch {
      WatchInstrument.plex("discoverRemoteUrls: \(error.localizedDescription)")
      return []
    }
  }

  /// The last address that answered, for callers that cannot wait to probe.
  var currentApiBase: String {
    freshApiBase() ?? credentials?.serverUrl ?? ""
  }

  private func freshApiBase() -> String? {
    stateLock.lock()
    defer { stateLock.unlock() }
    guard let cachedApiBase, let cachedApiBaseAt,
      Date().timeIntervalSince(cachedApiBaseAt) < streamingBaseTtl
    else { return nil }
    return cachedApiBase
  }

  private func freshStreamingBase() -> String? {
    stateLock.lock()
    defer { stateLock.unlock() }
    guard let cachedStreamingBase, let cachedStreamingBaseAt,
      Date().timeIntervalSince(cachedStreamingBaseAt) < streamingBaseTtl
    else { return nil }
    return cachedStreamingBase
  }

  private func setStreamingBase(_ base: String) {
    stateLock.lock()
    cachedStreamingBase = base
    cachedStreamingBaseAt = Date()
    stateLock.unlock()
  }

  private var streamBaseCandidates: [String] {
    guard let creds = credentials else { return [] }
    var bases = Self.localDirectBaseUrls(from: creds.serverUrl)
    bases.append(creds.serverUrl)
    bases.append(contentsOf: creds.fallbackUrls ?? [])
    var seen = Set<String>()
    return bases.filter { seen.insert($0).inserted }
  }

  /// LAN IP variants from `https://192-168-1-20.<id>.plex.direct:32400`.
  ///
  /// Only for private addresses. This swaps TLS for plain HTTP, which is
  /// tolerable on the owner's LAN and not across the internet, and a public
  /// plex.direct host is exactly what a phone away from home hands over.
  static func localDirectBaseUrls(from serverUrl: String) -> [String] {
    guard let url = URL(string: serverUrl),
      let host = url.host?.lowercased(),
      host.hasSuffix(".plex.direct")
    else { return [] }
    let prefix = host.split(separator: ".", maxSplits: 1).first.map(String.init) ?? ""
    let octets = prefix.split(separator: "-").compactMap { UInt8($0) }
    guard octets.count == 4, prefix.split(separator: "-").count == 4, isPrivateIPv4(octets) else {
      return []
    }
    let ip = octets.map(String.init).joined(separator: ".")
    let port = url.port ?? 32400
    // Plex serves HTTP on LAN; HTTPS to the raw IP fails cert validation on watchOS.
    return ["http://\(ip):\(port)"]
  }

  /// RFC 1918: 10/8, 172.16/12, 192.168/16.
  static func isPrivateIPv4(_ octets: [UInt8]) -> Bool {
    guard octets.count == 4 else { return false }
    switch (octets[0], octets[1]) {
    case (10, _): return true
    case (172, 16...31): return true
    case (192, 168): return true
    default: return false
    }
  }

  /// Whether [base] answers as the server we signed in to.
  ///
  /// `/identity` needs no token, and none is sent: on a foreign network a
  /// private address can be anybody's machine, and this is the request that
  /// finds out. A host that cannot prove it is our server is not used, which
  /// is why an unknown machine id fails the plain-HTTP candidates.
  private func probeStreamingBase(_ base: String) async -> Bool {
    guard let url = URL(string: "\(base)/identity") else { return false }
    var request = URLRequest(url: url)
    // Generous for a cold cellular radio; candidates are probed together.
    request.timeoutInterval = 8
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    do {
      let (data, response) = try await session.data(for: request)
      guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
      let isPlainHttp = base.hasPrefix("http://")
      guard let expected = credentials?.machineIdentifier else { return !isPlainHttp }
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      let container = json?["MediaContainer"] as? [String: Any]
      return container?["machineIdentifier"] as? String == expected
    } catch {
      return false
    }
  }

  private func partStreamUrl(_ partKey: String, base: String) -> String? {
    guard let creds = credentials else { return nil }
    return "\(base)\(partKey)?X-Plex-Token=\(creds.token)"
  }

  /// Create a play queue from a track/album/artist URI
  func createPlayQueue(uri: String, shuffle: Bool = false, continuous: Bool = false) async -> PlayQueueResult? {
    guard let creds = credentials else {
      WatchInstrument.plex("No credentials for createPlayQueue")
      return nil
    }

    guard let base = await apiBase() else { return nil }
    var components = URLComponents(string: "\(base)/playQueues")
    var queryItems = [
      URLQueryItem(name: "type", value: "audio"),
      URLQueryItem(name: "uri", value: uri),
      URLQueryItem(name: "X-Plex-Token", value: creds.token),
    ]
    if shuffle { queryItems.append(URLQueryItem(name: "shuffle", value: "1")) }
    if continuous { queryItems.append(URLQueryItem(name: "continuous", value: "1")) }
    components?.queryItems = queryItems

    guard let url = components?.url else {
      WatchInstrument.plex("Failed to build play queue URL from: \(base)/playQueues")
      return nil
    }

    WatchInstrument.plex("POST /playQueues uri=\(uri)")

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
        WatchInstrument.plex("Create queue HTTP \(http.statusCode): \(body.prefix(200))")
        return nil
      }
      guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let container = json["MediaContainer"] as? [String: Any]
      else {
        WatchInstrument.plex("Create queue: unexpected JSON structure")
        return nil
      }

      let queueId = container["playQueueID"] as? Int ?? 0
      let metadata = container["Metadata"] as? [[String: Any]] ?? []
      let items = metadata.compactMap { parseMusicItem($0) }
      WatchInstrument.plex("Created queue \(queueId) with \(items.count) items (keys: \(Array(container.keys)))")

      return PlayQueueResult(playQueueId: queueId, items: items)
    } catch {
      WatchInstrument.plex("Create queue error: \(error)")
      return nil
    }
  }

  /// Create a radio station from a track/album/artist
  /// Returns (result, errorDetail) — errorDetail is non-nil on failure for UI display
  func createRadioStation(ratingKey: String) async -> (PlayQueueResult?, String?) {
    WatchInstrument.plex("createRadioStation: ratingKey=\(ratingKey), hasCredentials=\(hasCredentials)")

    guard hasCredentials else {
      return (nil, "No credentials")
    }

    let machineId = await fetchMachineIdentifier()
    guard let machineId else {
      return (nil, "Can't reach server (/identity failed)")
    }

    guard var result = await station(machineId: machineId, ratingKey: ratingKey) else {
      return (nil, "Server rejected radio request")
    }
    // Plex builds stations from an artist or a track; an album's or a
    // playlist's comes back empty, so start from the album's artist or a
    // track picked from the playlist.
    if result.items.isEmpty, let seed = await stationSeed(for: ratingKey),
      let seeded = await station(machineId: machineId, ratingKey: seed)
    {
      result = seeded
    }
    if result.items.isEmpty {
      return (nil, "Radio returned no tracks")
    }
    WatchInstrument.plex("createRadioStation: \(result.items.count) items, queueId=\(result.playQueueId)")
    return (result, nil)
  }

  private func station(machineId: String, ratingKey: String) async -> PlayQueueResult? {
    let uri =
      "server://\(machineId)/com.plexapp.plugins.library/library/metadata/\(ratingKey)/station/\(UUID().uuidString)?type=10"
    WatchInstrument.plex("createRadioStation: uri=\(uri)")
    guard var result = await createPlayQueue(uri: uri, shuffle: true, continuous: true) else { return nil }
    if result.items.isEmpty, result.playQueueId > 0, let fetched = await fetchPlayQueue(queueId: result.playQueueId) {
      result = fetched
    }
    return result
  }

  private func stationSeed(for ratingKey: String) async -> String? {
    guard let json = await get("/library/metadata/\(ratingKey)"),
      let item = ((json["MediaContainer"] as? [String: Any])?["Metadata"] as? [[String: Any]])?.first
    else { return nil }
    switch item["type"] as? String {
    case "album":
      return (item["parentRatingKey"] as? String) ?? (item["parentRatingKey"] as? Int).map(String.init)
    case "playlist":
      let count = (item["leafCount"] as? Int) ?? 0
      guard count > 0,
        let page = await get(
          "/playlists/\(ratingKey)/items?X-Plex-Container-Start=\(Int.random(in: 0..<count))&X-Plex-Container-Size=1"),
        let track = ((page["MediaContainer"] as? [String: Any])?["Metadata"] as? [[String: Any]])?.first
      else { return nil }
      return (track["ratingKey"] as? String) ?? (track["ratingKey"] as? Int).map(String.init)
    default:
      return nil
    }
  }

  /// Fetch an existing play queue by id (Plex sometimes omits Metadata on create).
  ///
  /// With [center], the queue is read around that entry. A radio station has
  /// no end: it starts with five tracks and adds five each time it is read
  /// centred on its last one. Read without a center it stays the length it is.
  func fetchPlayQueue(queueId: Int, center: Int? = nil, window: Int = 200) async -> PlayQueueResult? {
    guard credentials != nil else { return nil }
    let path =
      center.map { "/playQueues/\(queueId)?window=\(window)&includeBefore=1&includeAfter=1&center=\($0)" }
      ?? "/playQueues/\(queueId)"
    guard let json = await get(path) else { return nil }
    guard let container = json["MediaContainer"] as? [String: Any] else { return nil }
    let metadata = container["Metadata"] as? [[String: Any]] ?? []
    let items = metadata.compactMap { parseMusicItem($0) }
    WatchInstrument.plex("fetchPlayQueue \(queueId): \(items.count) items")
    guard !items.isEmpty else { return nil }
    return PlayQueueResult(playQueueId: queueId, items: items)
  }

  /// Create a play queue for an album or artist (play all tracks)
  func createPlayAllQueue(ratingKey: String, shuffle: Bool = false) async -> PlayQueueResult? {
    guard let machineId = await fetchMachineIdentifier() else {
      WatchInstrument.plex("No machine identifier for play all")
      return nil
    }
    let uri = "server://\(machineId)/com.plexapp.plugins.library/library/metadata/\(ratingKey)"
    WatchInstrument.plex("Creating play all queue with uri: \(uri)")
    return await createPlayQueue(uri: uri, shuffle: shuffle)
  }

  /// Resolve a watch-playable stream URL. Direct part URLs for MP3/AAC; transcode for FLAC etc.
  func resolveStreamUrl(ratingKey: String, partKey: String? = nil) async -> String? {
    guard credentials != nil else { return nil }

    if let watch = await resolveStreamUrlOnWatch(ratingKey: ratingKey, partKey: partKey) {
      return watch
    }

    if let phone = await requestPhoneStreamUrl(ratingKey: ratingKey) {
      return phone
    }

    return nil
  }

  /// A fresh stream for [ratingKey] that starts [offset] seconds in, for
  /// picking a track back up after its stream was cut off.
  ///
  /// `startsAt` is where the returned stream's zero is: [offset] for a
  /// transcode, which Plex starts from there, and 0 for a direct file, which
  /// the caller seeks within instead.
  func resolveResumeStream(ratingKey: String, at offset: Double) async -> (url: String, startsAt: Double)? {
    let base = await streamingBase()
    let streamInfo = await fetchStreamInfo(ratingKey: ratingKey)
    if let partKey = streamInfo?.partKey,
      Self.shouldDirectPlay(codec: streamInfo?.audioCodec, container: streamInfo?.container),
      let url = partStreamUrl(partKey, base: base)
    {
      return (url, 0)
    }
    if let url = await buildMusicTranscodeUrl(ratingKey: ratingKey, base: base, offset: offset) {
      return (url, offset)
    }
    return nil
  }

  private func resolveStreamUrlOnWatch(ratingKey: String, partKey: String?) async -> String? {
    let base = await streamingBase()

    let streamInfo = await fetchStreamInfo(ratingKey: ratingKey)
    let resolvedPartKey = partKey ?? streamInfo?.partKey
    let codec = streamInfo?.audioCodec
    let container = streamInfo?.container

    if let resolvedPartKey, Self.shouldDirectPlay(codec: codec, container: container) {
      WatchInstrument.plex(
        "resolveStreamUrl(direct) ratingKey=\(ratingKey) codec=\(codec ?? container ?? "?") base=\(base)")
      return partStreamUrl(resolvedPartKey, base: base)
    }

    if let transcodeUrl = await buildMusicTranscodeUrl(ratingKey: ratingKey, base: base) {
      return transcodeUrl
    }

    if let hlsUrl = await buildHlsTranscodeUrl(ratingKey: ratingKey, base: base) {
      return hlsUrl
    }

    guard let resolvedPartKey else { return nil }
    WatchInstrument.plex("resolveStreamUrl(direct fallback) partKey=\(resolvedPartKey.prefix(40)) base=\(base)")
    return partStreamUrl(resolvedPartKey, base: base)
  }

  private func requestPhoneStreamUrl(ratingKey: String) async -> String? {
    guard let streamUrl = await WatchConnectivityManager.shared.requestStreamUrl(ratingKey: ratingKey) else {
      return nil
    }
    WatchInstrument.plex("resolveStreamUrl(phone) ratingKey=\(ratingKey)")
    return streamUrl
  }

  private func transcodeLocation(for base: String) -> String {
    if base.contains(".plex.direct") { return "wan" }
    if base.hasPrefix("http://") || base.hasPrefix("https://") {
      guard let host = URL(string: base)?.host?.lowercased() else { return "lan" }
      if host.contains("plex.direct") || host.contains("plex.tv") { return "wan" }
    }
    return "lan"
  }

  private static func shouldDirectPlay(codec: String?, container: String?) -> Bool {
    let c = codec?.lowercased()
    let k = container?.lowercased()
    if c == "mp3" || c == "aac" || c == "alac" { return true }
    if k == "mp3" || k == "m4a" || k == "aac" { return true }
    return false
  }

  private func buildMusicTranscodeUrl(ratingKey: String, base: String, offset: Double = 0) async -> String? {
    guard let creds = credentials else { return nil }

    let profileExtra =
      "add-transcode-target(type=musicProfile&context=streaming" + "&protocol=http&container=mp3&audioCodec=mp3)"

    let sessionIdentifier = UUID().uuidString
    let transcodeSessionId = UUID().uuidString

    var params: [String: String] = [
      "hasMDE": "1",
      "path": "/library/metadata/\(ratingKey)",
      "mediaIndex": "0",
      "partIndex": "0",
      "protocol": "http",
      "directPlay": "0",
      "directStream": "0",
      "location": transcodeLocation(for: base),
      "musicBitrate": "192",
      "session": transcodeSessionId,
      "X-Plex-Session-Identifier": sessionIdentifier,
      "X-Plex-Client-Profile-Extra": profileExtra,
      "X-Plex-Client-Profile-Name": "Generic",
      "X-Plex-Product": "Plezy",
      "X-Plex-Version": "1.0",
      "X-Plex-Client-Identifier": clientIdentifier,
      "X-Plex-Platform": "Generic",
      "X-Plex-Device": "Watch",
      "X-Plex-Token": creds.token,
    ]

    if offset > 0 { params["offset"] = String(Int(offset)) }

    return await startUrlAfterDecision(
      label: "music",
      decisionEndpoint: "/music/:/transcode/universal/decision",
      startEndpoint: "/music/:/transcode/universal/start.mp3",
      params: params,
      ratingKey: ratingKey,
      base: base
    )
  }

  /// HLS transcode fallback — AVPlayer on watchOS handles HLS better than raw FLAC/MP3 parts.
  private func buildHlsTranscodeUrl(ratingKey: String, base: String) async -> String? {
    guard let creds = credentials else { return nil }

    let profileExtra =
      "add-transcode-target(type=videoProfile&context=streaming"
      + "&protocol=hls&container=mkv&videoCodec=h264&audioCodec=aac&maxVideoBitrate=2000)"

    let sessionIdentifier = UUID().uuidString
    let transcodeSessionId = UUID().uuidString

    let params: [String: String] = [
      "hasMDE": "1",
      "path": "/library/metadata/\(ratingKey)",
      "mediaIndex": "0",
      "partIndex": "0",
      "protocol": "hls",
      "fastSeek": "1",
      "directPlay": "0",
      "directStream": "0",
      "location": transcodeLocation(for: base),
      "subtitles": "none",
      "session": transcodeSessionId,
      "X-Plex-Session-Identifier": sessionIdentifier,
      "X-Plex-Client-Profile-Extra": profileExtra,
      "X-Plex-Client-Profile-Name": "Generic",
      "X-Plex-Product": "Plezy",
      "X-Plex-Version": "1.0",
      "X-Plex-Client-Identifier": clientIdentifier,
      "X-Plex-Platform": "Generic",
      "X-Plex-Device": "Watch",
      "X-Plex-Token": creds.token,
    ]

    return await startUrlAfterDecision(
      label: "hls",
      decisionEndpoint: "/video/:/transcode/universal/decision",
      startEndpoint: "/video/:/transcode/universal/start.m3u8",
      params: params,
      ratingKey: ratingKey,
      base: base
    )
  }

  /// Ask for a transcode decision, then build the start URL on whichever base
  /// actually answered. Later candidates are only tried once the preferred
  /// base has failed, so the first one is not a safe assumption.
  private func startUrlAfterDecision(
    label: String,
    decisionEndpoint: String,
    startEndpoint: String,
    params: [String: String],
    ratingKey: String,
    base: String
  ) async -> String? {
    let bases = [base] + streamBaseCandidates.filter { $0 != base }
    guard
      let decision = await plexGET(
        endpoint: decisionEndpoint,
        params: params,
        baseCandidates: bases,
        usePlexStartEncoding: false
      )
    else {
      WatchInstrument.plex("\(label) transcode decision failed ratingKey=\(ratingKey)")
      return nil
    }
    guard transcodeDecisionSucceeded(decision.json) else {
      WatchInstrument.plex("\(label) transcode decision rejected ratingKey=\(ratingKey)")
      return nil
    }
    guard
      let startUrl = plexURL(
        endpoint: startEndpoint,
        params: params,
        baseUrl: decision.base,
        usePlexStartEncoding: true
      )?.absoluteString
    else { return nil }
    WatchInstrument.plex("resolveStreamUrl(\(label)) ratingKey=\(ratingKey) base=\(decision.base)")
    return startUrl
  }

  private func plexURL(
    endpoint: String,
    params: [String: String],
    baseUrl: String? = nil,
    usePlexStartEncoding: Bool = true
  ) -> URL? {
    guard let creds = credentials else { return nil }
    let chosen = baseUrl ?? currentApiBase
    let base = chosen.hasSuffix("/") ? String(chosen.dropLast()) : chosen
    let encode = usePlexStartEncoding ? plexEncode : standardEncode
    let query =
      params
      .sorted { $0.key < $1.key }
      .map { "\(encode($0.key))=\(encode($0.value))" }
      .joined(separator: "&")
    return URL(string: "\(base)\(endpoint)?\(query)")
  }

  /// Dart [Uri.encodeComponent] — used on the transcode *decision* request.
  private func standardEncode(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~")
    return value.unicodeScalars.map { scalar -> String in
      if allowed.contains(scalar) { return String(scalar) }
      return String(format: "%%%02X", scalar.value)
    }.joined()
  }

  /// Percent-encode matching Plex Web / the Dart client (encodeComponent + paren fixes).
  private func plexEncode(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~")
    let encoded = value.unicodeScalars.map { scalar -> String in
      if allowed.contains(scalar) { return String(scalar) }
      return String(format: "%%%02X", scalar.value)
    }.joined()
    return
      encoded
      .replacingOccurrences(of: "(", with: "%28")
      .replacingOccurrences(of: ")", with: "%29")
      .replacingOccurrences(of: "*", with: "%2A")
      .replacingOccurrences(of: "'", with: "%27")
      .replacingOccurrences(of: "!", with: "%21")
  }

  private func plexGET(
    endpoint: String,
    params: [String: String],
    baseCandidates: [String]? = nil,
    usePlexStartEncoding: Bool = false
  ) async -> (json: [String: Any], base: String)? {
    let bases: [String]
    if let baseCandidates {
      bases = baseCandidates
    } else {
      guard let base = await apiBase() else { return nil }
      bases = [base]
    }
    for base in bases {
      if let result = await plexGETOnce(
        endpoint: endpoint,
        params: params,
        baseUrl: base,
        usePlexStartEncoding: usePlexStartEncoding
      ) {
        return (result, base)
      }
    }
    return nil
  }

  private func plexGETOnce(
    endpoint: String,
    params: [String: String],
    baseUrl: String,
    usePlexStartEncoding: Bool = false
  ) async -> [String: Any]? {
    guard
      let url = plexURL(
        endpoint: endpoint,
        params: params,
        baseUrl: baseUrl,
        usePlexStartEncoding: usePlexStartEncoding
      )
    else {
      WatchInstrument.plex("plexGET invalid URL endpoint=\(endpoint) base=\(baseUrl)")
      return nil
    }

    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("en", forHTTPHeaderField: "Accept-Language")

    do {
      let (data, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else { return nil }
      guard http.statusCode == 200 else {
        let body = String(data: data, encoding: .utf8) ?? ""
        WatchInstrument.plex("plexGET \(endpoint) HTTP \(http.statusCode) base=\(baseUrl) \(body.prefix(120))")
        return nil
      }
      return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    } catch {
      WatchInstrument.plex("plexGET \(endpoint): \(error.localizedDescription)")
      return nil
    }
  }

  private func transcodeDecisionSucceeded(_ json: [String: Any]) -> Bool {
    let container = (json["MediaContainer"] as? [String: Any]) ?? json
    let codes = ["generalDecisionCode", "transcodeDecisionCode", "mdeDecisionCode"]
    for key in codes {
      if let code = flexibleInt(container[key]), code >= 2000 {
        WatchInstrument.plex("transcode decision error \(key)=\(code)")
        return false
      }
    }
    return true
  }

  private func flexibleInt(_ value: Any?) -> Int? {
    if let intValue = value as? Int { return intValue }
    if let stringValue = value as? String { return Int(stringValue) }
    return nil
  }

  private struct StreamInfo {
    let partKey: String
    let audioCodec: String?
    let container: String?
  }

  /// Fetch part key + codec for a track (one metadata round-trip).
  private func fetchStreamInfo(ratingKey: String) async -> StreamInfo? {
    guard let json = await get("/library/metadata/\(ratingKey)") else {
      WatchInstrument.plex("fetchStreamInfo(\(ratingKey)): GET failed")
      return nil
    }
    guard let container = json["MediaContainer"] as? [String: Any],
      let metadata = container["Metadata"] as? [[String: Any]],
      let track = metadata.first
    else {
      WatchInstrument.plex("fetchStreamInfo(\(ratingKey)): no Metadata in response")
      return nil
    }
    guard let media = (track["Media"] as? [[String: Any]])?.first,
      let part = (media["Part"] as? [[String: Any]])?.first,
      let partKey = part["key"] as? String
    else {
      WatchInstrument.plex("fetchStreamInfo(\(ratingKey)): missing Media/Part")
      return nil
    }
    let info = StreamInfo(
      partKey: partKey,
      audioCodec: media["audioCodec"] as? String,
      container: media["container"] as? String
    )
    WatchInstrument.plex("fetchStreamInfo(\(ratingKey)): \(partKey) codec=\(info.audioCodec ?? "?")")
    return info
  }

  /// Fetch the partKey for a track by loading its full metadata
  func fetchPartKey(ratingKey: String) async -> String? {
    await fetchStreamInfo(ratingKey: ratingKey)?.partKey
  }

  /// Enrich MusicItems that are missing partKey by fetching their full metadata
  func enrichWithPartKeys(_ items: [MusicItem]) async -> [MusicItem] {
    let needEnrichment = items.filter { $0.partKey == nil }
    WatchInstrument.plex(
      "enrichWithPartKeys: \(items.count) items, \(items.count - needEnrichment.count) already have partKey, \(needEnrichment.count) need fetch"
    )

    guard !needEnrichment.isEmpty else { return items }

    // Fetch missing partKeys sequentially to avoid overwhelming the Watch network stack
    var fetched: [String: String] = [:]
    for item in needEnrichment {
      if let partKey = await fetchPartKey(ratingKey: item.ratingKey) {
        fetched[item.ratingKey] = partKey
      } else {
        WatchInstrument.plex("enrichWithPartKeys: FAILED for \(item.ratingKey) '\(item.title)'")
      }
    }

    WatchInstrument.plex("enrichWithPartKeys: fetched \(fetched.count)/\(needEnrichment.count) partKeys")

    return items.map { item in
      if item.partKey != nil { return item }
      guard let partKey = fetched[item.ratingKey] else { return item }
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
        grandparentRatingKey: item.grandparentRatingKey,
        playQueueItemID: item.playQueueItemID
      )
    }
  }

  /// Build a thumbnail URL
  func thumbnailUrl(_ thumb: String?) -> String? {
    guard let thumb, let creds = credentials else { return nil }
    let path = thumb.hasPrefix("/") ? String(thumb.dropFirst()) : thumb
    return "\(currentApiBase)/\(path)?X-Plex-Token=\(creds.token)"
  }

  // MARK: - Private

  private func get(_ path: String) async -> [String: Any]? {
    let span = WatchInstrument.begin("plex.GET", detail: path)
    defer { span.end() }
    guard let creds = credentials else {
      WatchInstrument.plex("GET \(path): no credentials")
      return nil
    }
    let separator = path.contains("?") ? "&" : "?"
    guard let base = await apiBase() else {
      WatchInstrument.plex("GET \(path): no address for the server answers")
      return nil
    }
    let urlString = "\(base)\(path)\(separator)X-Plex-Token=\(creds.token)"
    guard let url = URL(string: urlString) else {
      WatchInstrument.plex("GET \(path): invalid URL")
      return nil
    }

    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    do {
      let (data, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        WatchInstrument.plex("GET \(path): no HTTP response")
        return nil
      }
      guard http.statusCode == 200 else {
        let body = String(data: data, encoding: .utf8) ?? ""
        WatchInstrument.plex("GET \(path): HTTP \(http.statusCode) \(body.prefix(200))")
        if http.statusCode == 401 {
          WatchInstrument.plex("Token expired or invalid — clearing credentials")
          DispatchQueue.main.async {
            // A later response must not sign out credentials that
            // arrived after the ones this request used.
            guard self.credentials?.token == creds.token else { return }
            self.credentials = nil
            self.setCachedMusicSectionId(nil)
            NotificationCenter.default.post(name: .plexCredentialsExpired, object: nil)
          }
        }
        return nil
      }
      return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    } catch {
      WatchInstrument.plex("GET \(path) error: \(error)")
      // The address that answered a minute ago may be the LAN one the
      // watch has just walked away from.
      invalidateStreamingBase()
      return nil
    }
  }

  private func getMetadataList(_ path: String) async -> [MusicItem] {
    guard let json = await get(path) else { return [] }
    guard let container = json["MediaContainer"] as? [String: Any],
      let metadata = container["Metadata"] as? [[String: Any]]
    else { return [] }
    return metadata.compactMap { parseMusicItem($0) }
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
      let part = (media["Part"] as? [[String: Any]])?.first
    {
      partKey = part["key"] as? String
    }

    // parentRatingKey / grandparentRatingKey can also be Int
    let parentRK: String?
    if let s = dict["parentRatingKey"] as? String {
      parentRK = s
    } else if let n = dict["parentRatingKey"] as? Int {
      parentRK = String(n)
    } else {
      parentRK = nil
    }

    let grandparentRK: String?
    if let s = dict["grandparentRatingKey"] as? String {
      grandparentRK = s
    } else if let n = dict["grandparentRatingKey"] as? Int {
      grandparentRK = String(n)
    } else {
      grandparentRK = nil
    }

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
      grandparentRatingKey: grandparentRK,
      playQueueItemID: dict["playQueueItemID"] as? Int
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
  /// This entry's id within a play queue, when it came from one. A station
  /// grows only when it is read centred on its last entry, by this id.
  let playQueueItemID: Int?

  init(
    ratingKey: String,
    title: String,
    type: String,
    artist: String? = nil,
    album: String? = nil,
    thumb: String? = nil,
    duration: Double? = nil,
    partKey: String? = nil,
    parentRatingKey: String? = nil,
    grandparentRatingKey: String? = nil,
    playQueueItemID: Int? = nil
  ) {
    self.ratingKey = ratingKey
    self.title = title
    self.type = type
    self.artist = artist
    self.album = album
    self.thumb = thumb
    self.duration = duration
    self.partKey = partKey
    self.parentRatingKey = parentRatingKey
    self.grandparentRatingKey = grandparentRatingKey
    self.playQueueItemID = playQueueItemID
  }

  /// The track behind a queue entry, for starting something from it.
  init(trackOf item: QueueItem) {
    self.init(
      ratingKey: item.id,
      title: item.title,
      type: "track",
      artist: item.artist,
      album: item.album,
      duration: item.duration * 1000,
      parentRatingKey: item.parentRatingKey,
      grandparentRatingKey: item.grandparentRatingKey
    )
  }

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
  func toQueueItem(client: PlexWatchClient) async -> QueueItem? {
    guard let streamUrl = await client.resolveStreamUrl(ratingKey: ratingKey, partKey: partKey) else { return nil }
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

  /// Resolve stream URLs for the first few tracks; keep the full catalog for lazy advance.
  func prepareForPlayback(client: PlexWatchClient, prefetchCount: Int = 2, startIndex: Int = 0) async
    -> PreparedPlaybackQueue?
  {
    let enriched = await client.enrichWithPartKeys(items)
    guard !enriched.isEmpty else { return nil }

    let start = min(max(startIndex, 0), enriched.count - 1)
    let prefetch = min(max(prefetchCount, 1), enriched.count - start)
    var queueItems: [QueueItem] = []
    queueItems.reserveCapacity(prefetch)
    for index in start..<(start + prefetch) {
      if let item = await enriched[index].toQueueItem(client: client) {
        queueItems.append(item)
      }
    }
    guard !queueItems.isEmpty else { return nil }
    // The last entry already turned into a QueueItem, not the first: the
    // catalog carries on from here, and starting earlier replays the rest
    // of the prefetch.
    return PreparedPlaybackQueue(queueItems: queueItems, catalog: enriched, catalogIndex: start + prefetch - 1)
  }

  /// Build a PlayQueueReference from this result for fetching more tracks.
  func toQueueReference(isContinuous: Bool = false) -> PlayQueueReference {
    PlayQueueReference(playQueueId: playQueueId, isContinuous: isContinuous)
  }
}

struct PreparedPlaybackQueue {
  let queueItems: [QueueItem]
  let catalog: [MusicItem]
  let catalogIndex: Int
}

/// The Plex credentials, kept in the Keychain rather than UserDefaults, whose
/// plist is readable in any unencrypted backup or device dump.
private enum WatchKeychain {
  private static let service = "plezy.watch.plex-credentials"
  private static let account = "default"

  private static var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }

  static func load() -> Data? {
    var lookup = query
    lookup[kSecReturnData as String] = true
    lookup[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    guard SecItemCopyMatching(lookup as CFDictionary, &result) == errSecSuccess else { return nil }
    return result as? Data
  }

  /// After first unlock rather than when unlocked: playback goes on with the
  /// watch locked on the wrist, and the next track needs the token.
  @discardableResult
  static func save(_ data: Data) -> Bool {
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecSuccess { return true }
    guard status == errSecItemNotFound else { return false }
    let added = query.merging(attributes) { $1 }
    return SecItemAdd(added as CFDictionary, nil) == errSecSuccess
  }

  static func delete() {
    SecItemDelete(query as CFDictionary)
  }
}
