import Foundation

enum ControlMode: Int, Codable {
    case hostOnly = 0
    case anyone = 1
}

struct WatchSession: Identifiable {
    let sessionId: String
    let peerId: String
    let isHost: Bool
    var participants: [Participant]
    var controlMode: ControlMode
    var currentMediaRatingKey: String?
    var currentMediaTitle: String?
    var isActive: Bool

    var id: String { sessionId }

    struct Participant: Identifiable, Hashable {
        let peerId: String
        let displayName: String
        let isHost: Bool

        var id: String { peerId }
    }
}
