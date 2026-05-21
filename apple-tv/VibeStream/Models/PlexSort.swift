import Foundation

struct PlexSort: Identifiable, Hashable {
    let key: String
    let title: String
    var descKey: String?
    var defaultDirection: String?

    var id: String { key }

    var isDefaultDescending: Bool { defaultDirection == "desc" }

    func sortKey(descending: Bool) -> String {
        if descending {
            return descKey ?? "\(key):desc"
        }
        return key
    }

    static func from(json: [String: Any]) -> PlexSort? {
        guard let key = json["key"] as? String,
              let title = json["title"] as? String else {
            return nil
        }
        return PlexSort(
            key: key,
            title: title,
            descKey: json["descKey"] as? String,
            defaultDirection: json["defaultDirection"] as? String
        )
    }
}
