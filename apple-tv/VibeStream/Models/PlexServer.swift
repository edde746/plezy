import Foundation

struct PlexConnection: Codable, Hashable {
    let uri: String
    let `protocol`: String?
    let address: String?
    let port: Int?
    let local: Bool?
    let relay: Bool?

    var isSecure: Bool { `protocol` == "https" || uri.hasPrefix("https") }
}

struct PlexServer: Codable, Identifiable, Hashable {
    let name: String
    let clientIdentifier: String
    let connections: [PlexConnection]
    var activeConnectionUri: String?
    let owned: Bool?
    let sourceTitle: String?
    let accessToken: String?
    let machineIdentifier: String?

    var id: String { clientIdentifier }

    var baseURL: String {
        activeConnectionUri ?? connections.first?.uri ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case name, clientIdentifier, connections, activeConnectionUri
        case owned, sourceTitle, accessToken, machineIdentifier
    }
}
