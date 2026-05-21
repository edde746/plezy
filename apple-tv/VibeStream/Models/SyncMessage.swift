import Foundation

enum SyncMessageType: String, Codable {
    case play
    case pause
    case seek
    case buffering
    case positionSync
    case rate
    case join
    case leave
    case sessionConfig
    case ping
    case pong
    case mediaSwitch
    case hostExitedPlayer
    case playerReady
}

struct SyncMessage: Codable {
    let type: SyncMessageType
    let timestamp: Int64
    var positionMs: Int?
    var bufferingState: Bool?
    var rate: Double?
    var peerId: String?
    var displayName: String?
    var isHost: Bool?
    var controlMode: Int?
    var pingId: Int?
    var ratingKey: String?
    var serverId: String?
    var mediaTitle: String?
    var isPlaying: Bool?

    enum CodingKeys: String, CodingKey {
        case type = "t"
        case timestamp = "ts"
        case positionMs = "pos"
        case bufferingState = "buf"
        case rate = "r"
        case peerId = "pid"
        case displayName = "name"
        case isHost = "host"
        case controlMode = "ctrl"
        case pingId = "ping"
        case ratingKey = "rk"
        case serverId = "sid"
        case mediaTitle = "title"
        case isPlaying = "pl"
    }

    static func play(position: Int? = nil, peerId: String) -> SyncMessage {
        SyncMessage(type: .play, timestamp: currentTimestamp(), positionMs: position, peerId: peerId)
    }

    static func pause(peerId: String) -> SyncMessage {
        SyncMessage(type: .pause, timestamp: currentTimestamp(), peerId: peerId)
    }

    static func seek(position: Int, peerId: String) -> SyncMessage {
        SyncMessage(type: .seek, timestamp: currentTimestamp(), positionMs: position, peerId: peerId)
    }

    static func buffering(state: Bool, peerId: String) -> SyncMessage {
        SyncMessage(type: .buffering, timestamp: currentTimestamp(), bufferingState: state, peerId: peerId)
    }

    static func positionSync(position: Int, isPlaying: Bool, peerId: String) -> SyncMessage {
        SyncMessage(type: .positionSync, timestamp: currentTimestamp(), positionMs: position, peerId: peerId, isPlaying: isPlaying)
    }

    static func rateChange(rate: Double, peerId: String) -> SyncMessage {
        SyncMessage(type: .rate, timestamp: currentTimestamp(), rate: rate, peerId: peerId)
    }

    static func join(peerId: String, displayName: String, isHost: Bool) -> SyncMessage {
        SyncMessage(type: .join, timestamp: currentTimestamp(), peerId: peerId, displayName: displayName, isHost: isHost)
    }

    static func leave(peerId: String) -> SyncMessage {
        SyncMessage(type: .leave, timestamp: currentTimestamp(), peerId: peerId)
    }

    static func sessionConfig(
        peerId: String, position: Int, isPlaying: Bool,
        playbackRate: Double, controlMode: ControlMode
    ) -> SyncMessage {
        SyncMessage(
            type: .sessionConfig, timestamp: currentTimestamp(),
            positionMs: position, bufferingState: !isPlaying,
            rate: playbackRate, peerId: peerId, controlMode: controlMode.rawValue
        )
    }

    static func ping(id: Int, peerId: String) -> SyncMessage {
        SyncMessage(type: .ping, timestamp: currentTimestamp(), peerId: peerId, pingId: id)
    }

    static func pong(id: Int, peerId: String) -> SyncMessage {
        SyncMessage(type: .pong, timestamp: currentTimestamp(), peerId: peerId, pingId: id)
    }

    static func mediaSwitch(ratingKey: String, serverId: String, title: String, peerId: String) -> SyncMessage {
        SyncMessage(
            type: .mediaSwitch, timestamp: currentTimestamp(),
            peerId: peerId, ratingKey: ratingKey, serverId: serverId, mediaTitle: title
        )
    }

    static func hostExitedPlayer(peerId: String) -> SyncMessage {
        SyncMessage(type: .hostExitedPlayer, timestamp: currentTimestamp(), peerId: peerId)
    }

    static func playerReady(ready: Bool, peerId: String) -> SyncMessage {
        SyncMessage(type: .playerReady, timestamp: currentTimestamp(), bufferingState: ready, peerId: peerId)
    }

    private static func currentTimestamp() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}

// MARK: - Relay Protocol Messages

enum RelayMessageType: String, Codable {
    case create
    case join
    case broadcast
    case sendTo
    case ping
    // Server → Client
    case created
    case joined
    case peerJoined
    case peerLeft
    case message
    case error
    case pong
}

struct RelayMessage: Codable {
    let type: RelayMessageType
    var sessionId: String?
    var peerId: String?
    var peers: [String]?
    var payload: String?
    var to: String?
    var from: String?
    var code: String?
    var message: String?
}
