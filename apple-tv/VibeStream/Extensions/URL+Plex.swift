import Foundation

extension URL {
    func withPlexToken(_ token: String) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "X-Plex-Token", value: token))
        components.queryItems = items
        return components.url ?? self
    }

    func withQueryItems(_ items: [String: String]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        var existing = components.queryItems ?? []
        for (key, value) in items {
            existing.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = existing
        return components.url ?? self
    }
}

extension String {
    func asPlexImageURL(baseURL: String, token: String) -> URL? {
        if hasPrefix("http") {
            return URL(string: self)
        }
        return URL(string: "\(baseURL)\(self)?X-Plex-Token=\(token)")
    }
}
