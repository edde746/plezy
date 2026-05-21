import Foundation

struct PlexHub: Identifiable, Hashable {
    let hubKey: String
    let title: String
    let type: String
    let hubIdentifier: String?
    let size: Int
    let more: Bool
    let items: [PlexMetadata]
    var serverId: String?
    var serverName: String?

    var id: String { hubKey + (hubIdentifier ?? "") }

    init(
        hubKey: String, title: String, type: String,
        hubIdentifier: String? = nil, size: Int, more: Bool,
        items: [PlexMetadata], serverId: String? = nil, serverName: String? = nil
    ) {
        self.hubKey = hubKey
        self.title = title
        self.type = type
        self.hubIdentifier = hubIdentifier
        self.size = size
        self.more = more
        self.items = items
        self.serverId = serverId
        self.serverName = serverName
    }

    static func from(json: [String: Any], serverId: String?, serverName: String?) -> PlexHub? {
        guard let hubKey = json["key"] as? String ?? json["hubKey"] as? String,
              let title = json["title"] as? String,
              let type = json["type"] as? String else {
            return nil
        }

        let size = json["size"] as? Int ?? 0
        let more = json["more"] as? Bool ?? false
        let hubIdentifier = json["hubIdentifier"] as? String

        var items: [PlexMetadata] = []

        let metadataArray = json["Metadata"] as? [[String: Any]] ?? json["Directory"] as? [[String: Any]] ?? []
        for itemJson in metadataArray {
            if let data = try? JSONSerialization.data(withJSONObject: itemJson),
               var metadata = try? JSONDecoder().decode(PlexMetadata.self, from: data) {
                metadata.serverId = serverId
                metadata.serverName = serverName
                if let guids = itemJson["Guid"] as? [[String: Any]] {
                    metadata.tmdbId = PlexMetadata.extractTmdbId(from: guids)
                    metadata.imdbId = PlexMetadata.extractImdbId(from: guids)
                }
                items.append(metadata)
            }
        }

        return PlexHub(
            hubKey: hubKey, title: title, type: type,
            hubIdentifier: hubIdentifier, size: size, more: more,
            items: items, serverId: serverId, serverName: serverName
        )
    }
}
