//
//  StorageService.swift
//  Plezy tvOS
//
//  Handles persistent storage using UserDefaults and Keychain
//

import Foundation
import SwiftUI
import Combine

class StorageService: ObservableObject {
    private let defaults = UserDefaults.standard

    // Storage keys
    private enum Keys {
        static let plexToken = "plexToken"
        static let selectedServer = "selectedServer"
        static let currentUserUUID = "currentUserUUID"
        static let selectedLibrary = "selectedLibrary"
        static let theme = "theme"
        static let autoPlayNext = "autoPlayNext"
        static let subtitleSize = "subtitleSize"
        static let audioLanguage = "audioLanguage"
        static let subtitleLanguage = "subtitleLanguage"
    }

    // MARK: - Published Properties

    @Published var plexToken: String?
    @Published var selectedServer: Data?
    @Published var currentUserUUID: String?
    @Published var selectedLibrary: String?

    // MARK: - Initialization

    @MainActor
    func loadStoredData() async {
        plexToken = defaults.string(forKey: Keys.plexToken)
        selectedServer = defaults.data(forKey: Keys.selectedServer)
        currentUserUUID = defaults.string(forKey: Keys.currentUserUUID)
        selectedLibrary = defaults.string(forKey: Keys.selectedLibrary)
    }

    // MARK: - Authentication

    @MainActor
    func savePlexToken(_ token: String) async {
        defaults.set(token, forKey: Keys.plexToken)
        plexToken = token
    }

    @MainActor
    func saveSelectedServer(_ server: PlexServer) async {
        if let data = try? JSONEncoder().encode(server) {
            defaults.set(data, forKey: Keys.selectedServer)
            selectedServer = data
        }
    }

    @MainActor
    func saveCurrentUserUUID(_ uuid: String) async {
        defaults.set(uuid, forKey: Keys.currentUserUUID)
        currentUserUUID = uuid
    }

    // MARK: - Library

    @MainActor
    func saveSelectedLibrary(_ libraryKey: String) async {
        defaults.set(libraryKey, forKey: Keys.selectedLibrary)
        selectedLibrary = libraryKey
    }

    // MARK: - Clear Data

    @MainActor
    func clearAll() async {
        defaults.removeObject(forKey: Keys.plexToken)
        defaults.removeObject(forKey: Keys.selectedServer)
        defaults.removeObject(forKey: Keys.currentUserUUID)
        defaults.removeObject(forKey: Keys.selectedLibrary)

        plexToken = nil
        selectedServer = nil
        currentUserUUID = nil
        selectedLibrary = nil
    }
}
