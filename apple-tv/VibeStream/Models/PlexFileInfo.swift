import Foundation

struct PlexFileInfo {
    // Media level
    var container: String?
    var videoCodec: String?
    var videoResolution: String?
    var videoFrameRate: String?
    var videoProfile: String?
    var width: Int?
    var height: Int?
    var bitrate: Int?
    var duration: Int?
    var audioChannels: Int?
    var aspectRatio: Double?
    var audioCodec: String?
    var audioProfile: String?
    var optimizedForStreaming: Bool?
    var has64bitOffsets: Bool?

    // Part level
    var filePath: String?
    var fileSize: Int?

    // Stream level
    var colorSpace: String?
    var colorRange: String?
    var colorPrimaries: String?
    var colorTrc: String?
    var chromaSubsampling: String?
    var audioChannelLayout: String?
    var frameRate: Double?
    var bitDepth: Int?

    // Format badge detection
    var doviPresent: Bool?
    var videoDisplayTitle: String?
    var audioDisplayTitle: String?
    var audioExtendedDisplayTitle: String?
    var hasDolbyAtmos: Bool = false
    var hasClosedCaptions: Bool = false
    var hasSDH: Bool = false
    var hasAudioDescription: Bool = false

    // MARK: - Resolution
    var is4K: Bool { (width ?? 0) >= 3840 || videoResolution == "4k" }
    var isHD: Bool { !is4K && ((width ?? 0) >= 1280 || videoResolution == "1080" || videoResolution == "720") }
    var isSD: Bool { !is4K && !isHD }

    // MARK: - HDR
    var isDolbyVision: Bool {
        doviPresent == true ||
        (colorTrc?.lowercased().contains("dovi") ?? false) ||
        (videoProfile?.lowercased().contains("dovi") ?? false)
    }

    var isHDR10: Bool {
        !isDolbyVision && !isHDR10Plus && (
            (colorTrc?.lowercased().contains("smpte2084") ?? false) ||
            (colorTrc?.lowercased().contains("pq") ?? false) ||
            (colorSpace?.lowercased().contains("bt2020") ?? false)
        )
    }

    var isHDR10Plus: Bool {
        !isDolbyVision && (
            (videoDisplayTitle?.contains("HDR10+") ?? false) ||
            (videoProfile?.lowercased().contains("hdr10+") ?? false)
        )
    }

    var isHLG: Bool {
        !isDolbyVision && !isHDR10 &&
        (colorTrc?.lowercased().contains("hlg") ?? false ||
         colorTrc?.lowercased().contains("arib-std-b67") ?? false)
    }

    // MARK: - Audio
    var isDolbyAtmos: Bool {
        hasDolbyAtmos ||
        (audioExtendedDisplayTitle?.lowercased().contains("atmos") ?? false) ||
        (audioDisplayTitle?.lowercased().contains("atmos") ?? false) ||
        // Heuristic: TrueHD 7.1+ without explicit profile is likely Atmos
        // (most modern TrueHD 7.1 carries Atmos spatial metadata)
        (audioCodec?.lowercased() == "truehd" && (audioChannels ?? 0) >= 8 && (audioProfile ?? "").isEmpty)
    }

    var isDolbyDigitalPlus: Bool { audioCodec?.lowercased() == "eac3" }
    var isDolbyDigital: Bool { audioCodec?.lowercased() == "ac3" }
    var isDTSHD: Bool {
        let codec = audioCodec?.lowercased() ?? ""
        let profile = audioProfile?.lowercased() ?? ""
        return codec == "dca" && (profile == "ma" || profile == "hra")
    }

    var is71: Bool { (audioChannels ?? 0) >= 8 }
    var is51: Bool { !is71 && (audioChannels ?? 0) >= 6 }

    // MARK: - Formatted Strings
    var fileSizeFormatted: String? {
        guard let fileSize, fileSize > 0 else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }

    var durationFormatted: String? {
        guard let duration, duration > 0 else { return nil }
        let totalSeconds = duration / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var bitrateFormatted: String? {
        guard let bitrate, bitrate > 0 else { return nil }
        if bitrate >= 1000 {
            return String(format: "%.1f Mbps", Double(bitrate) / 1000.0)
        }
        return "\(bitrate) kbps"
    }

    var resolutionFormatted: String? {
        guard let width, let height else { return nil }
        return "\(width)x\(height)"
    }

    var frameRateFormatted: String? {
        if let frameRate {
            return String(format: "%.3f fps", frameRate)
        }
        if let videoFrameRate {
            return videoFrameRate
        }
        return nil
    }

    var audioChannelsFormatted: String? {
        guard let audioChannels else { return nil }
        switch audioChannels {
        case 8: return "7.1"
        case 6: return "5.1"
        case 2: return "Stereo"
        case 1: return "Mono"
        default: return "\(audioChannels) ch"
        }
    }

    // MARK: - Parse from Plex API response
    static func from(json: [String: Any]) -> PlexFileInfo? {
        guard let mediaContainer = json["MediaContainer"] as? [String: Any],
              let metadataArray = mediaContainer["Metadata"] as? [[String: Any]],
              let metadata = metadataArray.first,
              let mediaArray = metadata["Media"] as? [[String: Any]],
              let media = mediaArray.first else {
            return nil
        }

        var info = PlexFileInfo()
        info.container = media["container"] as? String
        info.videoCodec = media["videoCodec"] as? String
        info.videoResolution = media["videoResolution"] as? String
        info.videoFrameRate = media["videoFrameRate"] as? String
        info.videoProfile = media["videoProfile"] as? String
        info.width = media["width"] as? Int
        info.height = media["height"] as? Int
        info.bitrate = media["bitrate"] as? Int
        info.duration = media["duration"] as? Int
        info.audioChannels = media["audioChannels"] as? Int
        info.aspectRatio = media["aspectRatio"] as? Double
        info.audioCodec = media["audioCodec"] as? String
        info.audioProfile = media["audioProfile"] as? String
        info.optimizedForStreaming = media["optimizedForStreaming"] as? Bool
        info.has64bitOffsets = media["has64bitOffsets"] as? Bool

        // Part level
        if let parts = media["Part"] as? [[String: Any]], let part = parts.first {
            info.filePath = part["file"] as? String
            info.fileSize = part["size"] as? Int

            // Stream level
            if let streams = part["Stream"] as? [[String: Any]] {
                for stream in streams {
                    let streamType = stream["streamType"] as? Int
                    if streamType == 1 { // Video
                        info.colorSpace = stream["colorSpace"] as? String
                        info.colorRange = stream["colorRange"] as? String
                        info.colorPrimaries = stream["colorPrimaries"] as? String
                        info.colorTrc = stream["colorTrc"] as? String
                        info.chromaSubsampling = stream["chromaSubsampling"] as? String
                        info.frameRate = stream["frameRate"] as? Double
                        info.bitDepth = stream["bitDepth"] as? Int
                        info.doviPresent = stream["DOVIPresent"] as? Bool
                        info.videoDisplayTitle = stream["displayTitle"] as? String
                    } else if streamType == 2 { // Audio
                        info.audioDisplayTitle = stream["displayTitle"] as? String
                        info.audioExtendedDisplayTitle = stream["extendedDisplayTitle"] as? String
                        info.audioChannelLayout = stream["audioChannelLayout"] as? String
                        if let extTitle = info.audioExtendedDisplayTitle?.lowercased(),
                           extTitle.contains("atmos") {
                            info.hasDolbyAtmos = true
                        }
                    } else if streamType == 3 { // Subtitle
                        let codec = stream["codec"] as? String ?? ""
                        let title = (stream["displayTitle"] as? String ?? "").lowercased()
                        if codec == "cc" || title.contains("cc") {
                            info.hasClosedCaptions = true
                        }
                        if title.contains("sdh") {
                            info.hasSDH = true
                        }
                        if title.contains("audio description") || title.contains("ad") {
                            info.hasAudioDescription = true
                        }
                    }
                }
            }
        }

        return info
    }
}
