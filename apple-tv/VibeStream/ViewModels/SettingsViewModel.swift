import Foundation
import Observation
import UIKit

enum AppIconVariant: String, CaseIterable, Identifiable {
    case `default` = "default"
    case j = "JIcon"
    case b = "BIcon"
    case m = "MIcon"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .j:       return "J"
        case .b:       return "B"
        case .m:       return "M"
        }
    }

    /// Asset catalog image name for the preview shown in Settings
    var previewImageName: String {
        switch self {
        case .default: return "AppLogo"
        case .j:       return "AppIcon-J"
        case .b:       return "AppIcon-B"
        case .m:       return "AppIcon-M"
        }
    }

    /// Asset catalog image name used in the splash screen
    var splashImageName: String {
        switch self {
        case .default: return "AppLogo"
        case .j:       return "AppIcon-J"
        case .b:       return "AppIcon-B"
        case .m:       return "AppIcon-M"
        }
    }

    /// Name passed to setAlternateIconName — nil for default (primary icon)
    var alternateIconName: String? {
        switch self {
        case .default: return nil
        case .j:       return "JIcon"
        case .b:       return "BIcon"
        case .m:       return "MIcon"
        }
    }
}

enum PreviewAudioMode: String, CaseIterable, Identifiable {
    case fullScreenOnly = "fullScreenOnly"
    case low = "low"
    case full = "full"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .fullScreenOnly: return "Full Screen Only"
        case .low:            return "30%"
        case .full:           return "100%"
        }
    }

    var detail: String? {
        switch self {
        case .fullScreenOnly: return "Audio only plays when the preview is full screened"
        case .low:            return "Plays at 30% volume while browsing"
        case .full:           return "Plays at full volume while browsing"
        }
    }
}

enum EpisodeViewMode: String, CaseIterable, Identifiable {
    case carousel = "carousel"
    case list = "list"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .carousel: return "Carousel"
        case .list:     return "List"
        }
    }

    var detail: String? {
        switch self {
        case .carousel: return "Horizontal scrolling cards"
        case .list:     return "Vertical episode list"
        }
    }

    /// Read the current setting from UserDefaults.
    static var current: EpisodeViewMode {
        if let raw = UserDefaults.standard.string(forKey: "episodeViewMode"),
           let mode = EpisodeViewMode(rawValue: raw) {
            return mode
        }
        return .carousel
    }
}

enum VideoPlayerType: String, CaseIterable, Identifiable {
    case mpv = "mpv"
    case vlc = "vlc"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .mpv: return "MPV"
        case .vlc: return "VLC"
        }
    }

    var detail: String {
        switch self {
        case .mpv: return "Direct play all formats. Full subtitle and shader support."
        case .vlc: return "VLC player. Best Dolby Vision and HDR compatibility."
        }
    }

    static var current: VideoPlayerType {
        if let raw = UserDefaults.standard.string(forKey: "videoPlayerType"),
           let type = VideoPlayerType(rawValue: raw) {
            return type
        }
        return .mpv
    }
}

@Observable
final class SettingsViewModel {
    var autoPlayNext: Bool = UserDefaults.standard.bool(forKey: "autoPlayNext") {
        didSet { UserDefaults.standard.set(autoPlayNext, forKey: "autoPlayNext") }
    }

    var autoPreview: Bool = {
        if UserDefaults.standard.object(forKey: "autoPreview") == nil { return true }
        return UserDefaults.standard.bool(forKey: "autoPreview")
    }() {
        didSet { UserDefaults.standard.set(autoPreview, forKey: "autoPreview") }
    }

    var previewAudioMode: PreviewAudioMode = {
        if let raw = UserDefaults.standard.string(forKey: "previewAudioMode"),
           let mode = PreviewAudioMode(rawValue: raw) {
            return mode
        }
        return .fullScreenOnly
    }() {
        didSet { UserDefaults.standard.set(previewAudioMode.rawValue, forKey: "previewAudioMode") }
    }

    var defaultVideoQuality: PlexClient.VideoQuality = {
        if let raw = UserDefaults.standard.string(forKey: "defaultVideoQuality"),
           let quality = PlexClient.VideoQuality(rawValue: raw) {
            return quality
        }
        return .original
    }() {
        didSet { UserDefaults.standard.set(defaultVideoQuality.rawValue, forKey: "defaultVideoQuality") }
    }

    var episodeViewMode: EpisodeViewMode = .current {
        didSet { UserDefaults.standard.set(episodeViewMode.rawValue, forKey: "episodeViewMode") }
    }

    var videoPlayerType: VideoPlayerType {
        get { VideoPlayerType.current }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "videoPlayerType") }
    }

    var selectedAppIcon: AppIconVariant = {
        if let raw = UserDefaults.standard.string(forKey: "selectedAppIcon"),
           let variant = AppIconVariant(rawValue: raw) {
            return variant
        }
        return .default
    }() {
        didSet { UserDefaults.standard.set(selectedAppIcon.rawValue, forKey: "selectedAppIcon") }
    }

    let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    var cacheSizeText: String = "Calculating..."
    var cacheCleared = false

    @MainActor
    func changeAppIcon(to variant: AppIconVariant) {
        selectedAppIcon = variant
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(variant.alternateIconName)
    }

    func loadCacheSize() async {
        let size = await ImageLoader.shared.cacheSize()
        cacheSizeText = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    func clearImageCache() async {
        await ImageLoader.shared.clearCache()
        cacheSizeText = "0 bytes"
        cacheCleared = true
    }

    func signOut(appState: AppState) {
        appState.signOut()
    }
}
