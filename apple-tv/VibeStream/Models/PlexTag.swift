import Foundation

struct PlexTag: Codable, Identifiable, Hashable {
    let tag: String
    var id: Int?
    var filter: String?

    var displayName: String { tag }
}
