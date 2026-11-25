import Foundation
import OSLog
import PlezyKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The shared core's `ExternalPlayerLauncher` on Apple platforms (`AppleAppPlatform.externalPlayers`, one per process):
/// each launch's attempts (`KnownPlayers.attempts`) in turn until one starts.
///
/// - iPhone, iPad and Apple TV: a URL opens in the app that handles its scheme. The open isn't gated on `canOpenURL`,
///   which answers false for any scheme the Info.plist's `LSApplicationQueriesSchemes` doesn't list (every custom
///   player's); the open itself reports a missing handler. On iPhone and iPad, VLC, Infuse and Outplayer get
///   x-callback-url return links (`plezy://external-player/…`) that bring the result back through the app's link
///   handling.
/// - Mac: a program on `PATH` starts with the URL as its argument (`open -a VLC`, `mpv`); a URL opens in its handler
///   once Launch Services says there is one.
///
/// Detection asks the same questions (`ApplePlayerInstallProbe`). Nothing here logs a URL.
@MainActor
final class ApplePlayerApps: @preconcurrency ExternalPlayerLauncher {
    #if os(macOS)
    let platform: ExternalPlayerPlatform = .macos
    #elseif os(tvOS)
    let platform: ExternalPlayerPlatform = .tvos
    #else
    let platform: ExternalPlayerPlatform = .ios
    #endif

    let probe: any PlayerInstallProbe = ApplePlayerInstallProbe()

    private let log = Logger(subsystem: "com.edde746.plezy", category: "external-players")

    /// Starts `launch` (SKIE exposes the Kotlin `suspend fun launch` as this async requirement). Nothing reports back
    /// here: an x-callback player's result comes as a link.
    nonisolated func __launch(launch: ExternalPlayerLaunch, ended: @escaping (ExternalPlaybackResult) -> Void) async throws -> ExternalLaunchStatus {
        await start(UncheckedBox(launch.attempts)).value
    }

    private func start(_ attempts: UncheckedBox<[ExternalPlayerAttempt]>) async -> UncheckedBox<ExternalLaunchStatus> {
        for attempt in attempts.value where await run(attempt) {
            return UncheckedBox(.launched)
        }
        log.notice("no attempt of \(attempts.value.count) started")
        return UncheckedBox(.notInstalled)
    }

    private func run(_ attempt: ExternalPlayerAttempt) async -> Bool {
        if let open = attempt as? ExternalPlayerAttemptOpenUrl {
            guard let url = URL(string: open.url) else { return false }
            #if os(macOS)
            if open.checkHandler && NSWorkspace.shared.urlForApplication(toOpen: url) == nil { return false }
            let opened = NSWorkspace.shared.open(url)
            #else
            if open.checkHandler && !UIApplication.shared.canOpenURL(url) { return false }
            let opened = await UIApplication.shared.open(url)
            #endif
            log.notice("\(url.scheme ?? "", privacy: .public) link opened: \(opened)")
            return opened
        }
        if let command = attempt as? ExternalPlayerAttemptCommand {
            #if os(macOS)
            return start(command.command)
            #else
            return false
            #endif
        }
        return false
    }

    #if os(macOS)
    /// Starts `command` (a program on `PATH` or a path, then its arguments), its output discarded; false when there's no
    /// such program or it can't start.
    private func start(_ command: [String]) -> Bool {
        guard let name = command.first, let program = ApplePlayerInstallProbe.program(name) else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: program)
        process.arguments = Array(command.dropFirst())
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            log.notice("started \(name, privacy: .public)")
            return true
        } catch {
            log.notice("\(name, privacy: .public) didn't start")
            return false
        }
    }
    #endif
}

/// The host lookups behind external player detection (`KnownPlayers.detect`) on Apple platforms.
final class ApplePlayerInstallProbe: PlayerInstallProbe, @unchecked Sendable {
    let environment: [String: String] = ProcessInfo.processInfo.environment

    func __commandExists(command: String) async throws -> KotlinBoolean {
        #if os(macOS)
        KotlinBoolean(bool: Self.program(command) != nil)
        #else
        KotlinBoolean(bool: false)
        #endif
    }

    func __fileExists(path: String) async throws -> KotlinBoolean {
        KotlinBoolean(bool: FileManager.default.fileExists(atPath: path))
    }

    /// Launch Services' answer: the database `open -a` resolves through.
    func __applicationInstalled(bundleId: String) async throws -> KotlinBoolean {
        #if os(macOS)
        KotlinBoolean(bool: NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) != nil)
        #else
        KotlinBoolean(bool: false)
        #endif
    }

    /// On iPhone, iPad and Apple TV only the schemes the Info.plist declares can be asked about (VLC's, Infuse's,
    /// Outplayer's), so the answer is truthful for the known players.
    func __schemeHasHandler(scheme: String) async throws -> KotlinBoolean {
        guard let url = URL(string: scheme) else { return KotlinBoolean(bool: false) }
        let handled = await MainActor.run {
            #if os(macOS)
            NSWorkspace.shared.urlForApplication(toOpen: url) != nil
            #else
            UIApplication.shared.canOpenURL(url)
            #endif
        }
        return KotlinBoolean(bool: handled)
    }

    #if os(macOS)
    /// `name`'s executable: a path as it is, else the first on `PATH`, as the shell's `command -v` finds it.
    static func program(_ name: String) -> String? {
        let files = FileManager.default
        if name.contains("/") { return files.isExecutableFile(atPath: name) ? name : nil }
        let path = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        return path.split(separator: ":").map { "\($0)/\(name)" }.first { files.isExecutableFile(atPath: $0) }
    }
    #endif
}
