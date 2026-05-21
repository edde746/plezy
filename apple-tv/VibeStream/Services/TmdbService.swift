import Foundation

actor TmdbService {
    static let shared = TmdbService()

    private let apiKey = APIKeys.tmdbAPIKey
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    /// Maximum response size (5 MB) to prevent memory exhaustion.
    private static let maxResponseSize = 5 * 1024 * 1024
    private var posterCache: [String: String] = [:]
    private var backdropCache: [String: String] = [:]
    private var logoCache: [String: String] = [:]
    private var networkCache: [String: String] = [:]

    func getPosterURL(tmdbId: String, mediaType: String = "movie") async -> String? {
        if let cached = posterCache[tmdbId] { return cached }

        let endpoint = mediaType == "show" ? "tv" : "movie"
        guard let url = URL(string: "\(baseURL)/\(endpoint)/\(tmdbId)?api_key=\(apiKey)") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count <= Self.maxResponseSize else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let posterPath = json?["poster_path"] as? String {
                let fullURL = "\(imageBaseURL)/w780\(posterPath)"
                posterCache[tmdbId] = fullURL
                return fullURL
            }
        } catch { }
        return nil
    }

    func getLogoURL(tmdbId: String, mediaType: String = "movie") async -> String? {
        if let cached = logoCache[tmdbId] { return cached }

        let endpoint = mediaType == "show" ? "tv" : "movie"
        guard let url = URL(string: "\(baseURL)/\(endpoint)/\(tmdbId)/images?api_key=\(apiKey)&include_image_language=en,null") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count <= Self.maxResponseSize else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let logos = json?["logos"] as? [[String: Any]], !logos.isEmpty {
                // Only use English or language-neutral logos
                let english = logos.first { ($0["iso_639_1"] as? String) == "en" }
                let neutral = logos.first { ($0["iso_639_1"] as? String) == nil || ($0["iso_639_1"] as? String) == "null" }
                guard let best = english ?? neutral else { return nil }
                if let filePath = best["file_path"] as? String {
                    let fullURL = "\(imageBaseURL)/original\(filePath)"
                    logoCache[tmdbId] = fullURL
                    return fullURL
                }
            }
        } catch { }
        return nil
    }

    /// Returns the streaming network/service name for a movie or TV show.
    /// - For TV shows: uses the ``networks`` array from TMDB's TV details.
    /// - For movies: uses the first ``flatrate`` watch provider (US region).
    func getNetworkName(tmdbId: String, mediaType: String = "movie") async -> String? {
        let cacheKey = "\(mediaType)-\(tmdbId)"
        if let cached = networkCache[cacheKey] { return cached }

        if mediaType == "show" {
            // TV shows: fetch details and extract the first network
            guard let url = URL(string: "\(baseURL)/tv/\(tmdbId)?api_key=\(apiKey)") else { return nil }
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 5
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200,
                      data.count <= Self.maxResponseSize else { return nil }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let networks = json?["networks"] as? [[String: Any]],
                   let name = networks.first?["name"] as? String {
                    networkCache[cacheKey] = name
                    return name
                }
            } catch { }
        } else {
            // Movies: fetch watch providers and extract the first flatrate provider (US)
            guard let url = URL(string: "\(baseURL)/movie/\(tmdbId)/watch/providers?api_key=\(apiKey)") else { return nil }
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 5
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200,
                      data.count <= Self.maxResponseSize else { return nil }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let results = json?["results"] as? [String: Any],
                   let us = results["US"] as? [String: Any],
                   let flatrate = us["flatrate"] as? [[String: Any]],
                   let name = flatrate.first?["provider_name"] as? String {
                    networkCache[cacheKey] = name
                    return name
                }
            } catch { }
        }
        return nil
    }

    func getBackdropURL(tmdbId: String, mediaType: String = "movie") async -> String? {
        if let cached = backdropCache[tmdbId] { return cached }

        let endpoint = mediaType == "show" ? "tv" : "movie"
        guard let url = URL(string: "\(baseURL)/\(endpoint)/\(tmdbId)/images?api_key=\(apiKey)&include_image_language=en,null") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count <= Self.maxResponseSize else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let backdrops = json?["backdrops"] as? [[String: Any]], !backdrops.isEmpty {
                // Prefer language-neutral (no text) backdrops to avoid burned-in logos/titles
                let neutral = backdrops.first { ($0["iso_639_1"] as? String) == nil || ($0["iso_639_1"] as? String) == "null" }
                if let best = neutral ?? backdrops.first,
                   let filePath = best["file_path"] as? String {
                    let fullURL = "\(imageBaseURL)/original\(filePath)"
                    backdropCache[tmdbId] = fullURL
                    return fullURL
                }
            }
        } catch { }
        return nil
    }

    /// Fetch trending TMDB IDs for a media type.
    /// - Parameters:
    ///   - mediaType: "movie" or "tv"
    ///   - page: Page number (1-based, 20 results per page)
    /// - Returns: Array of TMDB ID strings in trending order, or empty on failure.
    func getTrending(mediaType: String, page: Int = 1) async -> [String] {
        guard let url = URL(string: "\(baseURL)/trending/\(mediaType)/week?api_key=\(apiKey)&page=\(page)") else { return [] }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count <= Self.maxResponseSize else { return [] }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let results = json?["results"] as? [[String: Any]] else { return [] }
            return results.compactMap { item in
                if let id = item["id"] as? Int {
                    return String(id)
                }
                return nil
            }
        } catch { }
        return []
    }

}
