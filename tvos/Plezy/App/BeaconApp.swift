//
//  BeaconApp.swift
//  Beacon tvOS
//
//  Main application entry point for Beacon tvOS client
//

import SwiftUI
import AVFoundation
import Combine

@main
struct BeaconApp: App {
    @StateObject private var authService = PlexAuthService()
    @StateObject private var settingsService = SettingsService()
    @StateObject private var storageService = StorageService()

    init() {
        print("🚀🚀🚀 [APP] Beacon app is starting up! 🚀🚀🚀")
        // Configure audio session for media playback
        configureAudioSession()
        print("🚀🚀🚀 [APP] Audio session configured 🚀🚀🚀")
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
