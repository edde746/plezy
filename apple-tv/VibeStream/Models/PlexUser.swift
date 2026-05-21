import Foundation

struct PlexUser: Codable, Identifiable, Hashable {
    let id: Int
    let uuid: String?
    let username: String?
    let title: String
    let email: String?
    let thumb: String?
    let hasPassword: Bool?
    let restricted: Bool?
    let home: Bool?
    let admin: Bool?

    var displayName: String { title.isEmpty ? (username ?? "User") : title }

    enum CodingKeys: String, CodingKey {
        case id, uuid, username, title, email, thumb
        case hasPassword, restricted, home, admin
    }
}

struct PlexHome: Codable {
    let users: [PlexHomeUser]
}

struct PlexHomeUser: Codable, Identifiable, Hashable {
    let id: Int
    let uuid: String
    let title: String
    let username: String?
    let thumb: String?
    let hasPassword: Bool?
    let restricted: Bool?
    let admin: Bool?
    let protected: Bool?

    var displayName: String { title.isEmpty ? (username ?? "User") : title }
}
