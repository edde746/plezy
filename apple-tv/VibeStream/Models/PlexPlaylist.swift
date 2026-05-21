import Foundation

struct PlexPlaylist: Codable, Identifiable, Hashable {
    let ratingKey: String
    let key: String
    let type: String
    let title: String
    let playlistType: String
    var summary: String?
    var composite: String?
    var content: String?
    var guid: String?
    var thumb: String?
    var smart: Bool
    var duration: Int?
    var leafCount: Int?
    var addedAt: Int?
    var updatedAt: Int?
    var lastViewedAt: Int?
    var viewCount: Int?
    var serverId: String?
    var serverName: String?

    var id: String { globalKey }

    var globalKey: String {
        if let serverId {
            return "\(serverId):\(ratingKey)"
        }
        return ratingKey
    }

    var displayImage: String? { composite ?? thumb }
    var displayTitle: String { title }
    var isEditable: Bool { !smart }
}
