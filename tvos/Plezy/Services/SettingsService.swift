//
//  SettingsService.swift
//  Beacon tvOS
//
//  Manages app settings and preferences
//

import Foundation
import SwiftUI
import Combine

class SettingsService: ObservableObject {
    private let defaults = UserDefaults.standard

    // Storage keys
    private enum Keys {
        static let themeMode = "themeMode"
        static let autoPlayNext = "autoPlayNext"
        static let subtitleSize = "subtitleSize"
        static let skipIntroEnabled = "skipIntroEnabled"
        static let skipCreditsEnabled = "skipCreditsEnabled"
        static let audioLanguage = "audioLanguage"
        static let subtitleLanguage = "subtitleLanguage"
        static let autoSelectAudio = "autoSelectAudio"
        static let autoSelectSubtitles = "autoSelectSubtitles"
    }

    // MARK: - Published Settings

    @Published var theme: ThemeMode {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.themeMode)
        }
    }

    @Published var autoPlayNext: Bool {
        didSet {
            defaults.set(autoPlayNext, forKey: Keys.autoPlayNext)
        }
    }

    @Published var subtitleSize: Double {
        didSet {
            defaults.set(subtitleSize, forKey: Keys.subtitleSize)
        }
    }

    @Published var skipIntroEnabled: Bool {
        didSet {
            defaults.set(skipIntroEnabled, forKey: Keys.skipIntroEnabled)
        }
    }

    @Published var skipCreditsEnabled: Bool {
        didSet {
            defaults.set(skipCreditsEnabled, forKey: Keys.skipCreditsEnabled)
        }
    }

    @Published var audioLanguage: String? {
        didSet {
            defaults.set(audioLanguage, forKey: Keys.audioLanguage)
        }
    }

    @Published var subtitleLanguage: String? {
        didSet {
            defaults.set(subtitleLanguage, forKey: Keys.subtitleLanguage)
        }
    }

    @Published var autoSelectAudio: Bool {
        didSet {
            defaults.set(autoSelectAudio, forKey: Keys.autoSelectAudio)
        }
    }

    @Published var autoSelectSubtitles: Bool {
        didSet {
            defaults.set(autoSelectSubtitles, forKey: Keys.autoSelectSubtitles)
        }
    }

    // MARK: - Initialization

    init() {
        self.theme = ThemeMode(rawValue: defaults.string(forKey: Keys.themeMode) ?? "system") ?? .system
        self.autoPlayNext = defaults.bool(forKey: Keys.autoPlayNext)
        self.subtitleSize = defaults.double(forKey: Keys.subtitleSize) != 0 ? defaults.double(forKey: Keys.subtitleSize) : 1.0
        self.skipIntroEnabled = defaults.bool(forKey: Keys.skipIntroEnabled)
        self.skipCreditsEnabled = defaults.bool(forKey: Keys.skipCreditsEnabled)
        self.audioLanguage = defaults.string(forKey: Keys.audioLanguage)
        self.subtitleLanguage = defaults.string(forKey: Keys.subtitleLanguage)
        self.autoSelectAudio = defaults.bool(forKey: Keys.autoSelectAudio)
        self.autoSelectSubtitles = defaults.bool(forKey: Keys.autoSelectSubtitles)

        // Set defaults for new installations
        if defaults.object(forKey: Keys.autoPlayNext) == nil {
            self.autoPlayNext = true
        }
        if defaults.object(forKey: Keys.autoSelectAudio) == nil {
            self.autoSelectAudio = true
        }
    }

    // MARK: - Theme

    enum ThemeMode: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"

        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }

        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
    }
}
