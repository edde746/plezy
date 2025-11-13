//
//  PlezyApp.swift
//  Plezy tvOS
//
//  Main application entry point for Plezy tvOS client
//

import SwiftUI
import AVFoundation

@main
struct PlezyApp: App {
    @StateObject private var authService = PlexAuthService()
    @StateObject private var settingsService = SettingsService()
    @StateObject private var storageService = StorageService()

    init() {
        // Configure audio session for media playback
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(settingsService)
                .environmentObject(storageService)
                .preferredColorScheme(settingsService.theme.colorScheme)
        }
    }

    private func configureAudioSession() {
        #if os(tvOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay
            ])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
        #endif
    }
}
