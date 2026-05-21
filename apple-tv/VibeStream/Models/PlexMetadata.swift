import Foundation

enum PlexMediaType: String, Codable, Hashable {
    case movie
    case show
    case season
    case episode
    case artist
    case album
    case track
    case collection
    case playlist
    case clip
    case photo
    case unknown

    init(from string: String?) {
        self = PlexMediaType(rawValue: string ?? "") ?? .unknown
    }

    var isVideo: Bool { self == .movie || self == .episode || self == .clip }
    var isShowRelated: Bool { self == .show || self == .season || self == .episode }
    var isMusic: Bool { self == .artist || self == .album || self == .track }
    var isPlayable: Bool { isVideo || self == .track }
}

enum EpisodePosterMode: String, Codable {
    case showPoster
    case episodeThumb
}

struct PlexMetadata: Codable, Identifiable, Hashable {
    let ratingKey: String
    let key: String
    let type: String
    let title: String
    var guid: String?
    var studio: String?
    var titleSort: String?
    var contentRating: String?
    var summary: String?
    var ratingImage: String?
    var audienceRatingImage: String?
    var originallyAvailableAt: String?
    var thumb: String?
    var art: String?
    var grandparentTitle: String?
    var grandparentThumb: String?
    var grandparentArt: String?
    var grandparentRatingKey: String?
    var parentTitle: String?
    var parentThumb: String?
    var parentRatingKey: String?
    var grandparentTheme: String?
    var editionTitle: String?
    var subtype: String?
    var audioLanguage: String?
    var subtitleLanguage: String?
    var clearLogo: String?
    var rating: Double?
    var audienceRating: Double?
    var year: Int?
    var duration: Int?
    var addedAt: Int?
    var updatedAt: Int?
    var lastViewedAt: Int?
    var viewOffset: Int?
    var viewCount: Int?
    var leafCount: Int?
    var viewedLeafCount: Int?
    var childCount: Int?
    var parentIndex: Int?
    var index: Int?
    var playlistItemID: Int?
    var playQueueItemID: Int?
    var librarySectionID: Int?
    var role: [PlexRole]?
    var director: [PlexRole]?
    var collection: [PlexTag]?
    var genre: [PlexTag]?

    // Multi-server support
    var serverId: String?
    var serverName: String?

    // Not from JSON — set during parsing
    var imdbRating: Double?
    var tmdbId: String?
    var imdbId: String?

    var id: String { globalKey }

    var globalKey: String {
        if let serverId {
            return "\(serverId):\(ratingKey)"
        }
        return ratingKey
    }

    var mediaType: PlexMediaType { PlexMediaType(from: type) }

    var displayTitle: String {
        switch mediaType {
        case .episode, .season:
            return grandparentTitle ?? title
        default:
            return title
        }
    }

    var displaySubtitle: String? {
        switch mediaType {
        case .episode:
            if let parentIndex, let index {
                return "S\(parentIndex)E\(index) - \(title)"
            }
            return title
        case .season:
            return title
        default:
            return nil
        }
    }

    var isWatched: Bool {
        if mediaType == .show || mediaType == .season {
            if let leafCount, let viewedLeafCount, leafCount > 0 {
                return viewedLeafCount >= leafCount
            }
            return false
        }
        return (viewCount ?? 0) > 0
    }

    var unwatchedCount: Int? {
        guard let leafCount, let viewedLeafCount else { return nil }
        let remaining = leafCount - viewedLeafCount
        return remaining > 0 ? remaining : nil
    }

    var watchProgress: Double? {
        guard let viewOffset, let duration, duration > 0 else { return nil }
        let progress = Double(viewOffset) / Double(duration)
        return progress > 0 && progress < 1 ? progress : nil
    }

    var usesWideAspectRatio: Bool {
        mediaType == .episode || mediaType == .clip
    }

    func posterThumb(mode: EpisodePosterMode = .showPoster) -> String? {
        switch mediaType {
        case .episode:
            return mode == .episodeThumb ? thumb : (grandparentThumb ?? thumb)
        case .season:
            return thumb ?? parentThumb
        default:
            return thumb
        }
    }

    var durationFormatted: String? {
        guard let duration else { return nil }
        let totalSeconds = duration / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    enum CodingKeys: String, CodingKey {
        case ratingKey, key, type, title, guid, studio, titleSort, contentRating
        case summary, ratingImage, audienceRatingImage, originallyAvailableAt
        case thumb, art, grandparentTitle, grandparentThumb, grandparentArt
        case grandparentRatingKey, parentTitle, parentThumb, parentRatingKey
        case grandparentTheme, editionTitle, subtype, audioLanguage, subtitleLanguage, clearLogo
        case rating, audienceRating, year, duration, addedAt, updatedAt
        case lastViewedAt, viewOffset, viewCount, leafCount, viewedLeafCount
        case childCount, parentIndex, index, playlistItemID, playQueueItemID
        case librarySectionID, serverId, serverName
        case role = "Role"
        case director = "Director"
        case collection = "Collection"
        case genre = "Genre"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ratingKey = try container.decode(String.self, forKey: .ratingKey)
        key = try container.decode(String.self, forKey: .key)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        guid = try container.decodeIfPresent(String.self, forKey: .guid)
        studio = try container.decodeIfPresent(String.self, forKey: .studio)
        titleSort = try container.decodeIfPresent(String.self, forKey: .titleSort)
        contentRating = try container.decodeIfPresent(String.self, forKey: .contentRating)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        ratingImage = try container.decodeIfPresent(String.self, forKey: .ratingImage)
        audienceRatingImage = try container.decodeIfPresent(String.self, forKey: .audienceRatingImage)
        originallyAvailableAt = try container.decodeIfPresent(String.self, forKey: .originallyAvailableAt)
        thumb = try container.decodeIfPresent(String.self, forKey: .thumb)
        art = try container.decodeIfPresent(String.self, forKey: .art)
        grandparentTitle = try container.decodeIfPresent(String.self, forKey: .grandparentTitle)
        grandparentThumb = try container.decodeIfPresent(String.self, forKey: .grandparentThumb)
        grandparentArt = try container.decodeIfPresent(String.self, forKey: .grandparentArt)
        grandparentRatingKey = try container.decodeIfPresent(String.self, forKey: .grandparentRatingKey)
        parentTitle = try container.decodeIfPresent(String.self, forKey: .parentTitle)
        parentThumb = try container.decodeIfPresent(String.self, forKey: .parentThumb)
        parentRatingKey = try container.decodeIfPresent(String.self, forKey: .parentRatingKey)
        grandparentTheme = try container.decodeIfPresent(String.self, forKey: .grandparentTheme)
        editionTitle = try container.decodeIfPresent(String.self, forKey: .editionTitle)
        subtype = try container.decodeIfPresent(String.self, forKey: .subtype)
        audioLanguage = try container.decodeIfPresent(String.self, forKey: .audioLanguage)
        subtitleLanguage = try container.decodeIfPresent(String.self, forKey: .subtitleLanguage)
        clearLogo = try container.decodeIfPresent(String.self, forKey: .clearLogo)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        audienceRating = try container.decodeIfPresent(Double.self, forKey: .audienceRating)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        addedAt = try container.decodeIfPresent(Int.self, forKey: .addedAt)
        updatedAt = try container.decodeIfPresent(Int.self, forKey: .updatedAt)
        lastViewedAt = try container.decodeIfPresent(Int.self, forKey: .lastViewedAt)
        viewOffset = try container.decodeIfPresent(Int.self, forKey: .viewOffset)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount)
        leafCount = try container.decodeIfPresent(Int.self, forKey: .leafCount)
        viewedLeafCount = try container.decodeIfPresent(Int.self, forKey: .viewedLeafCount)
        childCount = try container.decodeIfPresent(Int.self, forKey: .childCount)
        parentIndex = try container.decodeIfPresent(Int.self, forKey: .parentIndex)
        index = try container.decodeIfPresent(Int.self, forKey: .index)
        playlistItemID = try container.decodeIfPresent(Int.self, forKey: .playlistItemID)
        playQueueItemID = try container.decodeIfPresent(Int.self, forKey: .playQueueItemID)
        librarySectionID = try container.decodeIfPresent(Int.self, forKey: .librarySectionID)
        role = try container.decodeIfPresent([PlexRole].self, forKey: .role)
        director = try container.decodeIfPresent([PlexRole].self, forKey: .director)
        collection = try container.decodeIfPresent([PlexTag].self, forKey: .collection)
        genre = try container.decodeIfPresent([PlexTag].self, forKey: .genre)
        serverId = try container.decodeIfPresent(String.self, forKey: .serverId)
        serverName = try container.decodeIfPresent(String.self, forKey: .serverName)
    }

    init(
        ratingKey: String, key: String, type: String, title: String,
        guid: String? = nil, studio: String? = nil, titleSort: String? = nil,
        contentRating: String? = nil, summary: String? = nil,
        ratingImage: String? = nil, audienceRatingImage: String? = nil,
        originallyAvailableAt: String? = nil, thumb: String? = nil,
        art: String? = nil, grandparentTitle: String? = nil,
        grandparentThumb: String? = nil, grandparentArt: String? = nil,
        grandparentRatingKey: String? = nil, parentTitle: String? = nil,
        parentThumb: String? = nil, parentRatingKey: String? = nil,
        grandparentTheme: String? = nil, editionTitle: String? = nil,
        subtype: String? = nil, audioLanguage: String? = nil,
        subtitleLanguage: String? = nil, clearLogo: String? = nil,
        rating: Double? = nil, audienceRating: Double? = nil,
        year: Int? = nil, duration: Int? = nil, addedAt: Int? = nil,
        updatedAt: Int? = nil, lastViewedAt: Int? = nil,
        viewOffset: Int? = nil, viewCount: Int? = nil,
        leafCount: Int? = nil, viewedLeafCount: Int? = nil,
        childCount: Int? = nil, parentIndex: Int? = nil,
        index: Int? = nil, playlistItemID: Int? = nil,
        playQueueItemID: Int? = nil, librarySectionID: Int? = nil,
        role: [PlexRole]? = nil, director: [PlexRole]? = nil,
        collection: [PlexTag]? = nil, genre: [PlexTag]? = nil,
        serverId: String? = nil, serverName: String? = nil, imdbRating: Double? = nil,
        imdbId: String? = nil
    ) {
        self.ratingKey = ratingKey
        self.key = key
        self.type = type
        self.title = title
        self.guid = guid
        self.studio = studio
        self.titleSort = titleSort
        self.contentRating = contentRating
        self.summary = summary
        self.ratingImage = ratingImage
        self.audienceRatingImage = audienceRatingImage
        self.originallyAvailableAt = originallyAvailableAt
        self.thumb = thumb
        self.art = art
        self.grandparentTitle = grandparentTitle
        self.grandparentThumb = grandparentThumb
        self.grandparentArt = grandparentArt
        self.grandparentRatingKey = grandparentRatingKey
        self.parentTitle = parentTitle
        self.parentThumb = parentThumb
        self.parentRatingKey = parentRatingKey
        self.grandparentTheme = grandparentTheme
        self.editionTitle = editionTitle
        self.subtype = subtype
        self.audioLanguage = audioLanguage
        self.subtitleLanguage = subtitleLanguage
        self.clearLogo = clearLogo
        self.rating = rating
        self.audienceRating = audienceRating
        self.year = year
        self.duration = duration
        self.addedAt = addedAt
        self.updatedAt = updatedAt
        self.lastViewedAt = lastViewedAt
        self.viewOffset = viewOffset
        self.viewCount = viewCount
        self.leafCount = leafCount
        self.viewedLeafCount = viewedLeafCount
        self.childCount = childCount
        self.parentIndex = parentIndex
        self.index = index
        self.playlistItemID = playlistItemID
        self.playQueueItemID = playQueueItemID
        self.librarySectionID = librarySectionID
        self.role = role
        self.director = director
        self.collection = collection
        self.genre = genre
        self.serverId = serverId
        self.serverName = serverName
        self.imdbRating = imdbRating
        self.imdbId = imdbId
    }

    static func extractTmdbId(from guidArray: [[String: Any]]) -> String? {
        for guid in guidArray {
            if let id = guid["id"] as? String, id.hasPrefix("tmdb://") {
                return String(id.dropFirst("tmdb://".count))
            }
        }
        return nil
    }

    static func extractImdbId(from guidArray: [[String: Any]]) -> String? {
        for guid in guidArray {
            if let id = guid["id"] as? String, id.hasPrefix("imdb://") {
                return String(id.dropFirst("imdb://".count))
            }
        }
        return nil
    }

    static func extractImdbRating(from ratingArray: [[String: Any]]) -> Double? {
        for rating in ratingArray {
            if let image = rating["image"] as? String, image.contains("imdb://"),
               let value = rating["value"] as? Double {
                return value
            }
        }
        return nil
    }

    static func == (lhs: PlexMetadata, rhs: PlexMetadata) -> Bool {
        lhs.ratingKey == rhs.ratingKey && lhs.serverId == rhs.serverId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ratingKey)
        hasher.combine(serverId)
    }
}
