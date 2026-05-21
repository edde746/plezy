import Foundation

enum DownloadStatus: String, Codable {
    case queued
    case downloading
    case paused
    case completed
    case failed
    case cancelled
    case partial
}

struct DownloadItem: Identifiable, Codable {
    let globalKey: String
    let ratingKey: String
    let serverId: String
    let title: String
    let type: String
    var status: DownloadStatus
    var progress: Double
    var downloadedBytes: Int64
    var totalBytes: Int64
    var errorMessage: String?
    var localFilePath: String?
    var thumbPath: String?
    var addedAt: Date
    var videoURL: String?
    var speed: Double = 0 // bytes per second, transient

    // Poster metadata (optional for backward compatibility with existing persisted data)
    var thumb: String?
    var grandparentThumb: String?
    var grandparentTitle: String?
    var grandparentRatingKey: String?
    var episodeTitle: String?
    var parentTitle: String?
    var parentIndex: Int?
    var index: Int?
    var year: Int?

    // Exclude `speed` from persistence — it's only meaningful during an active session
    enum CodingKeys: String, CodingKey {
        case globalKey, ratingKey, serverId, title, type, status, progress
        case downloadedBytes, totalBytes, errorMessage, localFilePath, thumbPath, addedAt, videoURL
        case thumb, grandparentThumb, grandparentTitle, grandparentRatingKey
        case episodeTitle, parentTitle, parentIndex, index, year
    }

    var id: String { globalKey }

    var progressPercent: Double { progress * 100 }

    /// Fallback thumb path derived from ratingKey — works even for items
    /// persisted before the thumb field was added.
    private var fallbackThumb: String {
        "/library/metadata/\(ratingKey)/thumb"
    }

    /// Best poster path: show poster for episodes, item thumb for movies.
    /// Falls back to a ratingKey-based path so old downloads still show art.
    var posterPath: String {
        if type == "episode" {
            return grandparentThumb ?? thumb ?? fallbackThumb
        }
        return thumb ?? fallbackThumb
    }

    /// Formatted episode label, e.g. "Season 1 · E3 · Episode Title"
    var episodeLabel: String? {
        guard type == "episode" else { return nil }
        var parts: [String] = []
        if let season = parentTitle {
            parts.append(season)
        } else if let s = parentIndex {
            parts.append("Season \(s)")
        }
        if let e = index {
            parts.append("E\(e)")
        }
        if let epTitle = episodeTitle {
            parts.append(epTitle)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var speedFormatted: String {
        guard speed > 0 else { return "" }
        let mbps = speed * 8 / 1_000_000
        if mbps >= 10 {
            return String(format: "%.0f Mbps", mbps)
        } else {
            return String(format: "%.1f Mbps", mbps)
        }
    }

    var downloadedFormatted: String {
        ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
    }

    var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
}

struct DownloadProgress {
    let globalKey: String
    let status: DownloadStatus
    let progress: Double
    let downloadedBytes: Int64
    let totalBytes: Int64
    let speed: Double
    var errorMessage: String?
    var currentFile: String?
    var thumbPath: String?
}
