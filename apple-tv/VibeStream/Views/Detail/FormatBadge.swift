import SwiftUI

enum FormatBadgeType: Hashable {
    case contentRating(String) // PG-13, R, TV-MA
    case resolution(String) // 4K, HD, SD (text fallback)
    case ultraHD             // 4K icon
    case fullHD              // 1080P icon
    case hdr(String)         // HLG (text), Dolby Vision (icon)
    case hdrIcon             // HDR/HDR10 icon
    case hdr10Plus           // HDR10+ icon
    case audio(String)       // 5.1, 7.1
    case dolbyAtmos
    case dolbyDigitalPlus
    case dolbyDigital
    case dtsHD
    case edition(String)     // Edition badge with asset name
    case closedCaptions
    case sdh
    case audioDescription

    /// Maps Plex contentRating strings to asset catalog image names.
    private static let ratingAssetMap: [String: String] = [
        "G": "rating-usg",
        "PG": "rating-uspg",
        "PG-13": "rating-uspg-13",
        "R": "rating-usr",
        "NC-17": "rating-usnc-17",
        "NR": "rating-usnr",
        "Not Rated": "rating-usnr",
        "Unrated": "rating-usnr",
        "TV-Y": "rating-ustv-y",
        "TV-G": "rating-ustv-g",
        "TV-PG": "rating-ustv-pg",
        "TV-14": "rating-ustv-14",
        "TV-MA": "rating-ustv-ma",
    ]

    var label: String {
        switch self {
        case .contentRating(let s): return s
        case .resolution(let s): return s
        case .ultraHD: return "4K"
        case .fullHD: return "1080P"
        case .hdr(let s): return s
        case .hdrIcon: return "HDR"
        case .hdr10Plus: return "HDR10+"
        case .audio(let s): return s
        case .dolbyAtmos: return "Atmos"
        case .dolbyDigitalPlus: return "DD+"
        case .dolbyDigital: return "DD"
        case .dtsHD: return "DTS-HD"
        case .edition(let s): return s
        case .closedCaptions: return "CC"
        case .sdh: return "SDH"
        case .audioDescription: return "AD"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .contentRating(let s): return "Rated \(s)"
        case .resolution(let s): return s == "4K" ? "4K Ultra HD" : s
        case .ultraHD: return "4K Ultra HD"
        case .fullHD: return "1080P Full HD"
        case .hdr(let s): return s
        case .hdrIcon: return "HDR"
        case .hdr10Plus: return "HDR10 Plus"
        case .audio(let s): return "\(s) surround sound"
        case .dolbyAtmos: return "Dolby Atmos"
        case .dolbyDigitalPlus: return "Dolby Digital Plus"
        case .dolbyDigital: return "Dolby Digital"
        case .dtsHD: return "DTS HD Master Audio"
        case .edition(let s): return "\(s) Edition"
        case .closedCaptions: return "Closed Captions"
        case .sdh: return "Subtitles for the Deaf and Hard of Hearing"
        case .audioDescription: return "Audio Description"
        }
    }

    var icon: String? {
        switch self {
        case .contentRating(let s): return Self.ratingAssetMap[s]
        case .ultraHD: return "ultrahd"
        case .fullHD: return "1080p"
        case .hdrIcon: return "hdr"
        case .hdr10Plus: return "hdr10plus"
        case .hdr(let s) where s == "Dolby Vision": return "dolbyvision"
        case .dolbyAtmos: return "dolbyatmos"
        case .dolbyDigitalPlus: return "dolbydigitalplus"
        case .dolbyDigital: return "dolbydigital"
        case .dtsHD: return "dtshd"
        case .edition(let s): return s
        default: return nil
        }
    }

    /// Badges that should display only their icon with no text label.
    var isIconOnly: Bool {
        icon != nil
    }

    /// Whether the icon uses template rendering (black source images that
    /// need to be tinted white). Pre-rendered white PNGs skip this.
    var usesTemplateRendering: Bool {
        switch self {
        case .dolbyAtmos, .dolbyDigitalPlus, .dolbyDigital: return true
        case .hdr(let s) where s == "Dolby Vision": return true
        default: return false
        }
    }

    var iconHeight: CGFloat {
        switch self {
        case .dolbyAtmos: return 28
        case .hdr(let s) where s == "Dolby Vision": return 28
        case .contentRating(let s) where Self.ratingAssetMap[s] == "rating-usnr": return 34
        default: return 22
        }
    }

    var showsBorder: Bool {
        switch self {
        case .audio: return true
        default: return false
        }
    }
}

struct FormatBadge: View {
    let type: FormatBadgeType

    var body: some View {
        Group {
            if type.isIconOnly, let icon = type.icon {
                Image(icon)
                    .renderingMode(type.usesTemplateRendering ? .template : .original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: type.iconHeight)
            } else {
                Text(type.label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, type.isIconOnly ? 6 : 10)
        .padding(.vertical, 6)
        .overlay(
            Group {
                if type.showsBorder {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                }
            }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(type.accessibilityDescription)
    }
}

struct FormatBadgeRow: View {
    let fileInfo: PlexFileInfo
    var contentRating: String? = nil
    var editionTitle: String? = nil

    /// Maps a Plex edition title to the corresponding asset catalog name.
    private static let editionAssetMap: [String: String] = [
        "Anniversary Edition": "edition-anniversary-edition",
        "Collector's Edition": "edition-collectors-edition",
        "Director's Cut": "edition-directors-cut",
        "Extended Cut": "edition-extended-cut",
        "Extended Edition": "edition-extended-edition",
        "Final Cut": "edition-final-cut",
        "IMAX": "edition-imax",
        "IMAX Enhanced": "edition-imax",
        "Black and White": "edition-minus-color",
        "Open Matte": "edition-open-matte",
        "Remastered": "edition-remastered",
        "Restored": "edition-restored",
        "Signature Edition": "edition-signature-edition",
        "Special Edition": "edition-special-edition",
        "Theatrical Cut": "edition-theatrical-cut",
        "Theatrical": "edition-theatrical",
        "Ultimate Edition": "edition-ultimate-edition",
        "Uncut": "edition-uncut",
        "Unrated Edition": "edition-unrated-edition",
    ]

    var badges: [FormatBadgeType] {
        var result: [FormatBadgeType] = []

        // Content rating first
        if let contentRating {
            result.append(.contentRating(contentRating))
        }

        // Resolution
        if fileInfo.is4K {
            result.append(.ultraHD)
        } else if fileInfo.isHD {
            result.append(.fullHD)
        } else if fileInfo.isSD {
            result.append(.resolution("SD"))
        }

        // HDR
        if fileInfo.isDolbyVision {
            result.append(.hdr("Dolby Vision"))
        } else if fileInfo.isHDR10Plus {
            result.append(.hdr10Plus)
        } else if fileInfo.isHDR10 {
            result.append(.hdrIcon)
        } else if fileInfo.isHLG {
            result.append(.hdr("HLG"))
        }

        // Audio
        if fileInfo.isDolbyAtmos {
            result.append(.dolbyAtmos)
        }
        if fileInfo.isDolbyDigitalPlus {
            result.append(.dolbyDigitalPlus)
        } else if fileInfo.isDolbyDigital {
            result.append(.dolbyDigital)
        } else if fileInfo.isDTSHD {
            result.append(.dtsHD)
        }
        if fileInfo.is71 {
            result.append(.audio("7.1"))
        } else if fileInfo.is51 {
            result.append(.audio("5.1"))
        }

        // Edition (last)
        if let editionTitle,
           let assetName = Self.editionAssetMap[editionTitle] {
            result.append(.edition(assetName))
        }

        return result
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(badges, id: \.self) { badge in
                FormatBadge(type: badge)
            }
        }
    }
}
