import Foundation

struct PlexRole: Codable, Identifiable, Hashable {
    var id: Int?
    var count: Int?
    var filter: String?
    var tagKey: String?
    var role: String?
    var thumb: String?
    let tag: String

    var displayName: String { tag }
    var displayRole: String? { role }
}
