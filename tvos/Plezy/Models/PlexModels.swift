//
//  PlexModels.swift
//  Plezy tvOS
//
//  Plex API data models
//

import Foundation

// MARK: - Authentication

struct PlexPin: Codable {
    let id: Int
    let code: String
    let authToken: String?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case authToken = "authToken"
    }
}

struct PlexUser: Codable {
    let id: Int
    let uuid: String
    let username: String
    let title: String
    let email: String?
    let thumb: String?
    let authToken: String?
}

// MARK: - Server & Connections

struct PlexServer: Codable, Identifiable, Equatable {
    let name: String
    let product: String
    let productVersion: String
    let platform: String
    let platformVersion: String
    let device: String
    let clientIdentifier: String
    let createdAt: Date?
    let lastSeenAt: Date?
    let provides: String
    let ownerId: Int?
    let sourceTitle: String?
    let publicAddress: String?
    let accessToken: String?
    let owned: Bool?
    let home: Bool?
    let synced: Bool?
    let relay: Bool?
    let presence: Bool?
    let httpsRequired: Bool?
    let publicAddressMatches: Bool?
    let dnsRebindingProtection: Bool?
    let natLoopbackSupported: Bool?
    let connections: [PlexConnection]

    var id: String { clientIdentifier }

    // Computed properties with default values
    var isOwned: Bool { owned ?? false }
    var isHome: Bool { home ?? false }

    enum CodingKeys: String, CodingKey {
        case name, product, productVersion, platform, platformVersion
        case device, clientIdentifier, createdAt, lastSeenAt, provides
        case ownerId, sourceTitle, publicAddress, accessToken
        case owned, home, synced, relay, presence, httpsRequired
        case publicAddressMatches, dnsRebindingProtection, natLoopbackSupported
        case connections
    }
}

struct PlexConnection: Codable, Identifiable, Equatable {
    let `protocol`: String
    let address: String
    let port: Int
    let uri: String
    let local: Bool
    let relay: Bool
    let IPv6: Bool

    var id: String { uri }

    var url: URL? {
        URL(string: uri)
    }

    var connectionType: ConnectionType {
        if relay { return .relay }
        if local { return .local }
        return .remote
    }

    enum ConnectionType: Int, Comparable {
        case local = 0
        case remote = 1
        case relay = 2

        static func < (lhs: ConnectionType, rhs: ConnectionType) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Library & Content

struct PlexLibrary: Codable, Identifiable {
    let key: String
    let title: String
    let type: String
    let agent: String?
    let scanner: String?
    let language: String?
    let uuid: String
    let updatedAt: Int?
    let createdAt: Int?
    let scannedAt: Int?
    let thumb: String?
    let art: String?

    var id: String { key }

    var mediaType: MediaType {
        MediaType(rawValue: type) ?? .unknown
    }

    enum MediaType: String {
        case movie
        case show
        case artist
        case photo
        case unknown
    }
}

struct PlexMetadata: Codable, Identifiable {
    let ratingKey: String
    let key: String
    let guid: String?
    let studio: String?
    let type: String
    let title: String
    let titleSort: String?
    let librarySectionTitle: String?
    let librarySectionID: Int?
    let librarySectionKey: String?
    let contentRating: String?
    let summary: String?
    let rating: Double?
    let audienceRating: Double?
    let year: Int?
    let tagline: String?
    let thumb: String?
    let art: String?
    let duration: Int?
    let originallyAvailableAt: String?
    let addedAt: Int?
    let updatedAt: Int?
    let audienceRatingImage: String?
    let primaryExtraKey: String?
    let ratingImage: String?

    // Progress tracking
    let viewOffset: Int?
    let viewCount: Int?
    let lastViewedAt: Int?

    // TV Show hierarchy
    let grandparentRatingKey: String?
    let grandparentKey: String?
    let grandparentTitle: String?
    let grandparentThumb: String?
    let grandparentArt: String?
    let parentRatingKey: String?
    let parentKey: String?
    let parentTitle: String?
    let parentThumb: String?
    let parentIndex: Int?
    let index: Int?

    // Counts for shows/seasons
    let childCount: Int?
    let leafCount: Int?
    let viewedLeafCount: Int?

    // Media info
    let media: [PlexMedia]?
    let role: [PlexRole]?
    let genre: [PlexTag]?
    let director: [PlexTag]?
    let writer: [PlexTag]?
    let country: [PlexTag]?

    // Images (for clearLogo, etc.)
    let Image: [PlexImage]?

    var id: String { ratingKey }

    // Extract clearLogo from Image array
    var clearLogo: String? {
        Image?.first(where: { $0.type == "clearLogo" })?.url
    }

    var isWatched: Bool {
        if let viewCount = viewCount, viewCount > 0 {
            return true
        }
        if let leafCount = leafCount, let viewedLeafCount = viewedLeafCount {
            return leafCount == viewedLeafCount && leafCount > 0
        }
        return false
    }

    var progress: Double {
        guard let duration = duration, duration > 0,
              let viewOffset = viewOffset else {
            return 0
        }
        return Double(viewOffset) / Double(duration)
    }

    var displayTitle: String {
        if type == "episode", let grandparentTitle = grandparentTitle {
            let seasonEpisode = formatSeasonEpisode()
            return "\(grandparentTitle) - \(seasonEpisode) - \(title)"
        }
        return title
    }

    func formatSeasonEpisode() -> String {
        let season = parentIndex ?? 0
        let episode = index ?? 0
        return String(format: "S%02dE%02d", season, episode)
    }

    // Format for Continue Watching: "S1, E2 • 45m"
    var episodeInfo: String {
        if type == "episode" {
            let season = parentIndex ?? 0
            let episode = index ?? 0
            var info = "S\(season), E\(episode)"

            // Add runtime in minutes
            if let duration = duration, duration > 0 {
                let minutes = duration / 60000 // Convert milliseconds to minutes
                info += " • \(minutes)m"
            }

            return info
        }
        return ""
    }

    // Helper to get runtime in minutes
    var runtimeMinutes: Int? {
        guard let duration = duration, duration > 0 else {
            return nil
        }
        return duration / 60000
    }
}

struct PlexMedia: Codable {
    let id: Int
    let duration: Int?
    let bitrate: Int?
    let width: Int?
    let height: Int?
    let aspectRatio: Double?
    let audioChannels: Int?
    let audioCodec: String?
    let videoCodec: String?
    let videoResolution: String?
    let container: String?
    let videoFrameRate: String?
    let optimizedForStreaming: Bool?
    let has64bitOffsets: Bool?
    let videoProfile: String?
    let part: [PlexPart]?
}

struct PlexPart: Codable {
    let id: Int
    let key: String
    let duration: Int?
    let file: String?
    let size: Int?
    let container: String?
    let optimizedForStreaming: Bool?
    let has64bitOffsets: Bool?
    let stream: [PlexStream]?
}

struct PlexStream: Codable {
    let id: Int
    let streamType: Int
    let selected: Bool?
    let `default`: Bool?
    let codec: String?
    let index: Int?
    let bitrate: Int?
    let language: String?
    let languageTag: String?
    let languageCode: String?
    let displayTitle: String?
    let extendedDisplayTitle: String?
    let title: String?
    let key: String?

    // Video streams
    let width: Int?
    let height: Int?
    let frameRate: Double?
    let profile: String?
    let level: Int?

    // Audio streams
    let channels: Int?
    let audioChannelLayout: String?
    let samplingRate: Int?

    // Subtitle streams
    let format: String?
    let forced: Bool?

    var streamTypeEnum: StreamType {
        StreamType(rawValue: streamType) ?? .unknown
    }

    enum StreamType: Int {
        case unknown = 0
        case video = 1
        case audio = 2
        case subtitle = 3
    }
}

struct PlexRole: Codable {
    let tag: String
    let role: String?
    let thumb: String?
}

struct PlexTag: Codable {
    let tag: String
}

struct PlexImage: Codable {
    let type: String
    let url: String
}

// MARK: - Hubs (Content Discovery)

struct PlexHub: Codable, Identifiable {
    let hubKey: String?
    let key: String?
    let title: String
    let type: String
    let hubIdentifier: String?
    let size: Int?
    let more: Bool?
    let style: String?
    let promoted: Bool?
    let metadata: [PlexMetadata]?

    enum CodingKeys: String, CodingKey {
        case hubKey
        case key
        case title
        case type
        case hubIdentifier
        case size
        case more
        case style
        case promoted
        case metadata = "Metadata"
    }

    var id: String {
        hubKey ?? key ?? UUID().uuidString
    }
}

// MARK: - Chapters

struct PlexChapter: Codable, Identifiable {
    let id: Int
    let index: Int
    let startTimeOffset: Int
    let endTimeOffset: Int
    let title: String?
    let thumb: String?

    var startTime: TimeInterval {
        TimeInterval(startTimeOffset) / 1000.0
    }

    var endTime: TimeInterval {
        TimeInterval(endTimeOffset) / 1000.0
    }
}

// MARK: - API Response Wrappers

struct PlexResponse<T: Codable>: Codable {
    let MediaContainer: PlexMediaContainer<T>
}

struct PlexMediaContainer<T: Codable>: Codable {
    let size: Int?
    let allowSync: Bool?
    let identifier: String?
    let mediaTagPrefix: String?
    let mediaTagVersion: Int?
    let metadata: [T]?
    let hub: [PlexHub]?
    let directory: [T]?

    enum CodingKeys: String, CodingKey {
        case size, allowSync, identifier, mediaTagPrefix, mediaTagVersion
        case metadata = "Metadata"
        case hub = "Hub"
        case directory = "Directory"
    }

    var items: [T] {
        metadata ?? directory ?? []
    }
}

// MARK: - User Profiles

struct PlexHomeUser: Codable, Identifiable {
    let id: Int
    let uuid: String
    let admin: Bool
    let guest: Bool
    let restricted: Bool
    let protected: Bool
    let title: String
    let username: String?
    let email: String?
    let thumb: String?

    var requiresPin: Bool {
        protected
    }
}
