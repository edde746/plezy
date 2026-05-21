import TVServices

class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent() async -> TVTopShelfContent? {
        let defaults = UserDefaults(suiteName: "group.com.amaze.vibestream")
        guard let baseURL = defaults?.string(forKey: "topshelf_server_url"),
              let token = defaults?.string(forKey: "topshelf_token") else {
            return nil
        }

        // Try trending movies first (cached by main app)
        if let trending = loadTrendingSection(baseURL: baseURL, token: token, defaults: defaults) {
            return trending
        }

        // Fallback: Continue Watching from Plex on-deck
        let clientId = defaults?.string(forKey: "topshelf_client_identifier") ?? UUID().uuidString
        let serverId = defaults?.string(forKey: "topshelf_server_id") ?? ""
        let serverName = defaults?.string(forKey: "topshelf_server_name") ?? ""
        return await loadOnDeckSection(baseURL: baseURL, token: token, clientId: clientId, serverId: serverId, serverName: serverName)
    }

    // MARK: - Trending Movies (from cache)

    private func loadTrendingSection(baseURL: String, token: String, defaults: UserDefaults?) -> TVTopShelfContent? {
        guard let cached = defaults?.array(forKey: "topshelf_trending") as? [[String: String]],
              !cached.isEmpty else {
            return nil
        }

        let items = cached.compactMap { entry -> TVTopShelfSectionedItem? in
            guard let ratingKey = entry["ratingKey"],
                  let title = entry["title"],
                  let thumbPath = entry["thumbPath"], !thumbPath.isEmpty else {
                return nil
            }

            let item = TVTopShelfSectionedItem(identifier: ratingKey)
            item.title = title
            item.imageShape = .poster

            // Build poster image URL via Plex transcoder
            let imageURLString: String
            if thumbPath.hasPrefix("http") {
                imageURLString = thumbPath
            } else if let encoded = thumbPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                imageURLString = "\(baseURL)/photo/:/transcode?width=600&height=900&minSize=1&upscale=1&url=\(encoded)&X-Plex-Token=\(token)"
            } else {
                imageURLString = "\(baseURL)\(thumbPath)?X-Plex-Token=\(token)"
            }
            if let imageURL = URL(string: imageURLString) {
                item.setImageURL(imageURL, for: .screenScale2x)
            }

            // Deep link to detail page
            var urlComponents = URLComponents()
            urlComponents.scheme = "vibestream"
            urlComponents.host = "detail"
            urlComponents.queryItems = [
                URLQueryItem(name: "ratingKey", value: ratingKey)
            ]
            if let url = urlComponents.url {
                item.displayAction = TVTopShelfAction(url: url)
                item.playAction = TVTopShelfAction(url: url)
            }

            return item
        }

        guard !items.isEmpty else { return nil }

        let section = TVTopShelfItemCollection(items: items)
        section.title = "Trending Movies"
        return TVTopShelfSectionedContent(sections: [section])
    }

    // MARK: - Continue Watching (fallback)

    private func loadOnDeckSection(baseURL: String, token: String, clientId: String, serverId: String, serverName: String) async -> TVTopShelfContent? {
        let client = PlexClient(
            baseURL: baseURL,
            token: token,
            clientIdentifier: clientId,
            serverId: serverId,
            serverName: serverName
        )

        do {
            let onDeck = try await client.getOnDeck()
            guard !onDeck.isEmpty else { return nil }

            let items = onDeck.prefix(10).map { metadata -> TVTopShelfSectionedItem in
                let item = TVTopShelfSectionedItem(identifier: metadata.ratingKey)
                item.imageShape = .poster
                if let subtitle = metadata.displaySubtitle {
                    item.title = "\(metadata.displayTitle) — \(subtitle)"
                } else {
                    item.title = metadata.displayTitle
                }

                if let thumbPath = metadata.posterThumb() {
                    let imageURLString: String
                    if thumbPath.hasPrefix("http") {
                        imageURLString = thumbPath
                    } else if let encoded = thumbPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                        imageURLString = "\(baseURL)/photo/:/transcode?width=600&height=900&minSize=1&upscale=1&url=\(encoded)&X-Plex-Token=\(token)"
                    } else {
                        imageURLString = "\(baseURL)\(thumbPath)?X-Plex-Token=\(token)"
                    }
                    if let imageURL = URL(string: imageURLString) {
                        item.setImageURL(imageURL, for: .screenScale2x)
                    }
                }

                var urlComponents = URLComponents()
                urlComponents.scheme = "vibestream"
                urlComponents.host = "play"
                urlComponents.queryItems = [
                    URLQueryItem(name: "ratingKey", value: metadata.ratingKey)
                ]
                if let url = urlComponents.url {
                    item.displayAction = TVTopShelfAction(url: url)
                    item.playAction = TVTopShelfAction(url: url)
                }

                return item
            }

            let section = TVTopShelfItemCollection(items: items)
            section.title = "Continue Watching"
            return TVTopShelfSectionedContent(sections: [section])
        } catch {
            return nil
        }
    }
}
