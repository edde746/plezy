import Combine
import os
import Sparkle
import SwiftUI
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "updates")

/// Sparkle for the notarized DMG: the feed and the key that signs every update are in Info.plist (SUFeedURL,
/// SUPublicEDKey), and Sparkle checks only when asked (SUEnableAutomaticChecks off): the launch's background check
/// (`UpdatePrompt`, while auto_check_updates_on_startup is on) and the app menu's Check for Updates. Sparkle runs only
/// where this install's updater is it (`updaterFor`: a DMG build not installed by Homebrew, whose installs Homebrew
/// updates) and never in Debug builds (local runs, the UI tests). One per process.
@MainActor
final class AppUpdater {
    static let shared = AppUpdater()

    /// This install's updater: Sparkle (`.native`), or the GitHub release check of a Homebrew install (`.github`).
    let updater: Updater
    let controller: SPUStandardUpdaterController
    /// Whether Sparkle runs: its updater, in a Release build.
    let started: Bool

    private init() {
        let bundle = Bundle.main.bundlePath
        updater = UpdaterKt.updaterFor(flavor: ApplePlatform.flavor, installation: InstallationMac(bundlePath: bundle))
        #if DEBUG
        started = false
        #else
        started = updater == .native
        #endif
        controller = SPUStandardUpdaterController(startingUpdater: started, updaterDelegate: nil, userDriverDelegate: nil)
        log.notice("updater \(String(describing: self.updater), privacy: .public) for \(bundle, privacy: .public); Sparkle \(self.started ? "started" : "not started", privacy: .public)")
    }

    /// Sparkle's background check: its window shows only when the feed has a newer build.
    func checkInBackground() {
        guard started else { return }
        controller.updater.checkForUpdatesInBackground()
    }
}

/// The app menu's Check for Updates item, enabled while Sparkle can check.
struct CheckForUpdatesButton: View {
    @ObservedObject private var model: CheckForUpdatesModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        model = CheckForUpdatesModel(updater: updater)
    }

    var body: some View {
        Button(T.shared.app.checkForUpdates) { updater.checkForUpdates() }
            .disabled(!model.canCheckForUpdates)
    }
}

@MainActor
private final class CheckForUpdatesModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
    }
}
