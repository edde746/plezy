import Foundation

actor OmdbService {
    static let shared = OmdbService()

    private let apiKey = APIKeys.omdbAPIKey
    private let baseURL = "https://www.omdbapi.com/"
    /// Maximum response size (1 MB) to prevent memory exhaustion.
    private static let maxResponseSize = 1 * 1024 * 1024

    private var memoryCache: [String: AwardBadge?] = [:]
    private var diskCachePath: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("award_cache_v2.json")
    }
    private var diskCache: [String: CachedAward]?

    /// Cache entry with timestamp for expiration
    private struct CachedAward: Codable {
        let badge: AwardBadge
        let cachedAt: Date
    }

    /// Cache entries expire after 14 days so new awards are picked up
    private static let cacheExpiration: TimeInterval = 14 * 24 * 60 * 60

    /// Clears both memory and disk caches, forcing fresh fetches
    func clearCache() {
        memoryCache.removeAll()
        diskCache = nil
        try? FileManager.default.removeItem(at: diskCachePath)
    }

    func getAward(imdbId: String) async -> AwardBadge? {
        if let cached = memoryCache[imdbId] {
            return cached
        }

        let disk = loadDiskCache()
        if let cached = disk[imdbId] {
            // Check expiration
            if Date().timeIntervalSince(cached.cachedAt) < Self.cacheExpiration {
                if cached.badge.tier == 0 {
                    memoryCache[imdbId] = nil
                    return nil
                }
                memoryCache[imdbId] = cached.badge
                return cached.badge
            }
            // Expired — fall through to re-fetch
        }

        let badge = await fetchAward(imdbId: imdbId)
        memoryCache[imdbId] = badge
        saveToDiskCache(imdbId: imdbId, badge: badge)
        return badge
    }

    private func fetchAward(imdbId: String) async -> AwardBadge? {
        guard !apiKey.contains("PLACEHOLDER") else { return nil }
        guard let url = URL(string: "\(baseURL)?apikey=\(apiKey)&i=\(imdbId)") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count <= Self.maxResponseSize else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let awardsText = json?["Awards"] as? String,
                  awardsText != "N/A" else { return nil }
            return parseAwards(awardsText)
        } catch { }
        return nil
    }

    private func parseAwards(_ text: String) -> AwardBadge? {
        let lowered = text.lowercased()

        if lowered.contains("won") && lowered.contains("oscar") {
            return AwardBadge(text: "Oscar\u{00AE} Winner", tier: 1)
        }
        if lowered.contains("nominated") && lowered.contains("oscar") {
            return AwardBadge(text: "Oscar\u{00AE} Nominee", tier: 2)
        }
        if lowered.contains("won") && lowered.contains("primetime emmy") {
            return AwardBadge(text: "Emmy Winner", tier: 3)
        }
        if lowered.contains("nominated") && lowered.contains("primetime emmy") {
            return AwardBadge(text: "Emmy Nominee", tier: 4)
        }
        if lowered.contains("won") && lowered.contains("golden globe") {
            return AwardBadge(text: "Golden Globe Winner", tier: 5)
        }
        if lowered.contains("nominated") && lowered.contains("golden globe") {
            return AwardBadge(text: "Golden Globe Nominee", tier: 6)
        }
        if lowered.contains("won") && lowered.contains("bafta") {
            return AwardBadge(text: "BAFTA Winner", tier: 7)
        }
        if lowered.contains("won") && (lowered.contains("cannes") || lowered.contains("palme")) {
            return AwardBadge(text: "Cannes Winner", tier: 8)
        }

        if let range = text.range(of: #"(\d+) wins?"#, options: .regularExpression) {
            let match = String(text[range])
            if let num = Int(match.prefix(while: { $0.isNumber })), num >= 5 {
                return AwardBadge(text: "\(num) Award Wins", tier: 9)
            }
        }

        return nil
    }

    // MARK: - Disk Cache

    private func loadDiskCache() -> [String: CachedAward] {
        if let cached = diskCache { return cached }
        guard let data = try? Data(contentsOf: diskCachePath),
              let decoded = try? JSONDecoder().decode([String: CachedAward].self, from: data) else {
            diskCache = [:]
            return [:]
        }
        diskCache = decoded
        return decoded
    }

    private func saveToDiskCache(imdbId: String, badge: AwardBadge?) {
        var cache = loadDiskCache()
        let entry = CachedAward(
            badge: badge ?? AwardBadge(text: "", tier: 0),
            cachedAt: Date()
        )
        cache[imdbId] = entry
        diskCache = cache
        if let data = try? JSONEncoder().encode(cache) {
            try? data.write(to: diskCachePath, options: .atomic)
        }
    }
}
