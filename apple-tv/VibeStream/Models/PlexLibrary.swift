import Foundation

struct PlexLibrary: Codable, Identifiable, Hashable {
    let key: String
    let title: String
    let type: String
    var agent: String?
    var scanner: String?
    var language: String?
    var uuid: String?
    var updatedAt: Int?
    var createdAt: Int?
    var hidden: Int?
    var serverId: String?
    var serverName: String?

    var id: String { globalKey }

    var globalKey: String {
        if let serverId {
            return "\(serverId):\(key)"
        }
        return key
    }

    var isHidden: Bool { hidden == 1 }

    var mediaType: PlexMediaType { PlexMediaType(from: type) }
}
