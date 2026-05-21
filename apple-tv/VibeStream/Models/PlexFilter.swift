import Foundation

struct PlexFilter: Identifiable, Hashable {
    let filter: String
    let filterType: String
    let key: String
    let title: String
    let type: String

    var id: String { key }

    static func from(json: [String: Any]) -> PlexFilter? {
        guard let filter = json["filter"] as? String,
              let filterType = json["filterType"] as? String ?? json["type"] as? String,
              let key = json["key"] as? String,
              let title = json["title"] as? String else {
            return nil
        }
        return PlexFilter(
            filter: filter,
            filterType: filterType,
            key: key,
            title: title,
            type: json["type"] as? String ?? filterType
        )
    }
}

struct PlexFilterValue: Identifiable, Hashable {
    let key: String
    let title: String
    var type: String?

    var id: String { key }

    static func from(json: [String: Any]) -> PlexFilterValue? {
        guard let key = json["key"] as? String ?? json["fastKey"] as? String,
              let title = json["title"] as? String else {
            return nil
        }
        return PlexFilterValue(key: key, title: title, type: json["type"] as? String)
    }
}
