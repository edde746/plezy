import Observation
import os
import PlezyKit
import SwiftUI

private let log = Logger(subsystem: "com.edde746.plezy", category: "updates")

/// The product's updates (`AppUpdates`) and the dialog of the GitHub release its launch check finds: the launch's check
/// runs once per process (`checkAtLaunch`), on the Mac Sparkle's background check where Sparkle is this install's
/// updater (`AppUpdater`), else the GitHub release check (a Homebrew install, the GitHub release's IPA). Debug builds
/// (local runs, the UI tests) never check. Built once per process with the root (`RootModel.updates`).
@MainActor
@Observable
final class UpdatePrompt {
    /// The newer release the dialog offers, or nil.
    private(set) var offer: ReleaseUpdate?

    @ObservationIgnored private var updates: AppUpdates?

    /// The launch's check on `graph`, the first time only (the updater is logged in Debug builds too).
    func checkAtLaunch(graph: AppGraph) {
        guard updates == nil else { return }
        let updates = AppUpdates(graph: graph, installation: Self.installation)
        self.updates = updates
        log.notice("updater \(String(describing: updates.updater), privacy: .public); launch check \(Self.checksAtLaunch ? "on" : "off (Debug)", privacy: .public)")
        guard Self.checksAtLaunch else { return }
        _ = updates.checkAtLaunch(
            native: {
                #if os(macOS)
                AppUpdater.shared.checkInBackground()
                #endif
            },
            offer: { [weak self] update in self?.offer = update }
        )
    }

    #if DEBUG
    static let checksAtLaunch = false
    #else
    static let checksAtLaunch = true
    #endif

    /// Offers the release no more (Skip This Version).
    func skip() {
        guard let offer, let updates else { return }
        self.offer = nil
        _ = updates.skip(version: offer.latestVersion)
    }

    /// Opens the release's page (View Release).
    func viewRelease() {
        guard let offer else { return }
        self.offer = nil
        ApplePlatform.openURL(offer.releaseUrl)
    }

    func dismiss() {
        offer = nil
    }

    /// Where this app is installed: the Mac's bundle (a Homebrew install checks the GitHub release), elsewhere nothing
    /// more than the platform.
    static var installation: Installation {
        #if os(macOS)
        InstallationMac(bundlePath: Bundle.main.bundlePath)
        #else
        InstallationOther.shared
        #endif
    }
}

extension View {
    /// The dialog of `prompt`'s release, as the system's alert: "Update Available", the new and the running version and
    /// the release's notes; Later, Skip This Version, and View Release, which opens the release's page.
    func updatePrompt(_ prompt: UpdatePrompt) -> some View {
        alert(
            T.shared.update.available,
            isPresented: Binding(get: { prompt.offer != nil }, set: { if !$0 { prompt.dismiss() } }),
            presenting: prompt.offer
        ) { _ in
            #if os(tvOS)
            // Apple TV builds are the App Store's (no updater) and have no browser: the dialog never shows there.
            Button(T.shared.update.viewRelease) { prompt.viewRelease() }
                .accessibilityIdentifier("update.view")
            #else
            Button(T.shared.update.viewRelease) { prompt.viewRelease() }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("update.view")
            #endif
            Button(T.shared.update.skipVersion) { prompt.skip() }
                .accessibilityIdentifier("update.skip")
            Button(T.shared.common.later, role: .cancel) { prompt.dismiss() }
                .accessibilityIdentifier("update.later")
        } message: { update in
            Text(updateMessage(update))
        }
    }
}

/// The versions, then the release's notes, cut after 600 characters (the release's page has them all).
private func updateMessage(_ update: ReleaseUpdate) -> String {
    let versions = T.shared.update.versionAvailable(version: update.latestVersion) + "\n"
        + T.shared.update.currentVersion(version: update.currentVersion)
    let notes = update.releaseNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !notes.isEmpty else { return versions }
    let limit = 600
    return versions + "\n\n" + (notes.count > limit ? String(notes.prefix(limit)) + "…" : notes)
}
