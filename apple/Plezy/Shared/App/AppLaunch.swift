import AVFoundation
import MediaAccessibility
import Network
import Observation
import os
import OSLog
import PlezyKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "app")

/// The process's start (the composition root): builds the shared core off the main thread, then the product's root
/// session, or in DEBUG builds a `--dev` session (`LaunchOptions`).
@MainActor
@Observable
final class AppLaunch {
    enum Phase {
        /// The shared core is being built (the database opens), or a `--dev` session is being set up.
        case starting
        /// The product: the root session decides the screens.
        case product(RootModel)
        #if DEBUG
        case dev(AppModel)
        #endif
        /// The launch can't start (a `--dev` launch's arguments or settings): the screen says so in the interface
        /// language (`app.launchFailed`), the log says why.
        case failed
        /// The product's core couldn't be built (`StartupFailedException`): the startup failure screen, whose Retry
        /// starts again (`retryStart`).
        case startFailed(StartupFailureRecord)
    }

    /// Leaving `.starting` (the session up, or the launch failed) follows the link that arrived meanwhile.
    var phase: Phase = .starting {
        didSet {
            if case .starting = oldValue { followPendingLink() }
        }
    }

    /// The product's start, for the splash: begun once the launch has read its options, before the bootstrap; nil
    /// before then and for a `--dev` session.
    private(set) var startup: StoreObserver<StartupUiState>?

    @ObservationIgnored private var boot: AppBootstrap?
    /// The network's path: the shared core hears whether it's up and metered (`AppGraph.network`).
    @ObservationIgnored private let network = NWPathMonitor()
    /// A link the system handed the app while the core was starting: followed once the session is up.
    @ObservationIgnored private var pendingLink: String?
    /// Whether the scene is in the foreground, for the core that is still starting when the first phase arrives.
    @ObservationIgnored private var inForeground = false
    #if os(macOS)
    /// Whether the window can be seen, whichever app is frontmost, for the core that is still starting; nil before the
    /// first report.
    @ObservationIgnored private var windowVisible: Bool?
    #endif

    init() {
        // The shared core's log lines go to the unified log from the start, before the core exists.
        Log.shared.sink = UnifiedLogSink()
        // The system's settings the shared code follows, before anything reads them (`SystemInputs`): the user's
        // preferred languages, the interface's (the app's own first where the system's
        // per-app language setting is used); the Region setting, which streams' country lists are checked against and
        // a per-app language leaves as it is; the caption and audio-description settings, for the track choice.
        let media = Self.mediaAccessibility()
        SystemInputs.shared.report(
            languages: Locale.preferredLanguages,
            region: Locale.current.region?.identifier,
            captions: media.captions,
            audioDescriptions: media.audioDescriptions
        )
        followMediaAccessibility()
        Task { await start() }
    }

    /// The caption and audio-description settings again whenever MediaAccessibility says either changed.
    private func followMediaAccessibility() {
        for name in [kMACaptionAppearanceSettingsChangedNotification, kMAAudibleMediaSettingsChangedNotification] {
            _ = NotificationCenter.default.addObserver(forName: Notification.Name(name as String), object: nil, queue: .main) { _ in
                MainActor.assumeIsolated {
                    let media = Self.mediaAccessibility()
                    SystemMediaAccessibility.shared.report(captions: media.captions, audioDescriptions: media.audioDescriptions)
                }
            }
        }
    }

    /// Closed Captions + SDH is the `alwaysOn` display type; Audio Descriptions puts "describes video" among the
    /// preferred characteristics of audible media.
    private static func mediaAccessibility() -> (captions: Bool, audioDescriptions: Bool) {
        let audible = MAAudibleMediaCopyPreferredCharacteristics().takeRetainedValue() as? [String] ?? []
        return (
            MACaptionAppearanceGetDisplayType(.user) == .alwaysOn,
            audible.contains(AVMediaCharacteristic.describesVideoForAccessibility.rawValue)
        )
    }

    /// The app came to the foreground (`AppBootstrap.onForeground`).
    func onForeground() {
        inForeground = true
        boot?.onForeground()
    }

    /// The app went to the background (or, on the Mac, another app is frontmost).
    func onBackground() {
        inForeground = false
        boot?.onBackground()
    }

    #if os(macOS)
    /// The app is quitting: the running app ends after a playback's last report and its trackers' stop went out
    /// (`RootSession.shutdown`, `AppSession.shutdownForExit`).
    func shutdown() async {
        do {
            switch phase {
            case .product(let root):
                try await Self.shutdown(UncheckedBox(root.root))
            #if DEBUG
            case .dev(let model):
                try await Self.shutdownForExit(UncheckedBox(model.session))
                model.session.close()
            #endif
            default:
                break
            }
        } catch {
            log.error("The quit's teardown failed: \(error)")
        }
    }

    // The shared core's suspending calls with their Kotlin values boxed (`UncheckedBox`); they run on the main thread.

    nonisolated private static func shutdown(_ root: UncheckedBox<RootSession>) async throws {
        try await root.value.shutdown()
    }

    #if DEBUG
    nonisolated private static func shutdownForExit(_ session: UncheckedBox<AppSession>) async throws {
        try await session.value.shutdownForExit()
    }
    #endif
    #else
    /// The process is ending: the running app closes, so a playback's last report and its trackers' stop go out
    /// (`RootSession.close`).
    func onTerminate() {
        if case .product(let root) = phase { root.root.close() }
    }
    #endif

    #if os(macOS)
    /// The window can be seen, or no longer can (minimized, hidden, covered whole), whichever app is frontmost and whether
    /// or not the app is active (`AppGraph.visible`).
    func onWindowVisibleChanged(_ visible: Bool) {
        windowVisible = visible
        boot?.onWindowVisibleChanged(visible: visible)
    }
    #endif

    /// Follows a link the system handed the app (`plezy://`): the product's root session takes it
    /// (`RootSession.openUrl`); while the core starts, it waits. In DEBUG builds a dev session's app follows it at once
    /// (`AppModel.followDevLink`).
    func openLink(_ url: String) {
        switch phase {
        case .product(let root):
            root.root.openUrl(url: url)
        #if DEBUG
        case .dev(let app): app.followDevLink(url)
        #endif
        case .starting:
            pendingLink = url
        case .failed, .startFailed:
            break
        }
    }

    /// The link that arrived while the core was starting, now that the session is up.
    private func followPendingLink() {
        guard let link = pendingLink else { return }
        pendingLink = nil
        openLink(link)
    }

    private func start() async {
        let options: LaunchOptions
        do {
            options = try LaunchOptions.current()
        } catch {
            return fail(error.message)
        }
        #if DEBUG
        if let dev = options.dev, dev.dev { return await startDev(dev) }
        #endif
        let version = ApplePlatform.appVersion
        let buildLabel = ApplePlatform.buildLabel
        // The product's start begins before the core, so the splash can name its steps.
        let startup = Startup(slowStartMillis: options.devSlowStartMillis)
        self.startup = StoreObserver(startup.state)
        let productStart = UncheckedBox(startup)
        // A Debug build's core ends the app when one of its coroutines throws; a release build's reports it and runs on.
        #if DEBUG
        let development = true
        #else
        let development = false
        #endif
        // The graph opens the database: off the main thread. The first start imports the earlier releases' data. A
        // full disk is recovered from by discarding the downloader's partial files (Apple TV has no downloads).
        #if os(tvOS)
        let downloadTempDirectory: String? = nil
        #else
        let downloadTempDirectory: String? = AppleDownloadPlatform.tempDirectoryPath
        #endif
        let built = await Task.detached(priority: .userInitiated) { () -> UncheckedBox<AnyObject> in
            do {
                return UncheckedBox(try AppBootstrap.companion.product(
                    database: DatabaseFactory(),
                    secrets: KeychainSecretStore(),
                    flavor: ApplePlatform.flavor,
                    appVersion: version,
                    startup: productStart.value,
                    development: development,
                    earlierRelease: EarlierReleaseLocations.companion.apple(),
                    downloadTempDirectory: downloadTempDirectory,
                    buildLabel: buildLabel
                ))
            } catch {
                // The only exception the core declares: anything else ends the process as a crash.
                guard let failed = (error as NSError).kotlinException as? StartupFailedException else { fatalError("\(error)") }
                return UncheckedBox(failed.record)
            }
        }.value.value
        guard let boot = built as? AppBootstrap else {
            if let record = built as? StartupFailureRecord {
                log.error("start failed: \(record.headline, privacy: .public)")
                phase = .startFailed(record)
            }
            return
        }
        // Crash reports to this build's endpoint (a release build's; others have none) while this device's switch is on.
        attach(boot, crashReports: boot.crashReports(
            channel: ApplePlatform.releaseChannel, dsn: BuildCrashReportConfig.shared.config.dsn
        ))
        phase = .product(RootModel(boot: boot, platform: AppleAppPlatform(), startup: startup))
    }

    /// The startup failure screen's Retry: the start runs again from its first step.
    func retryStart() {
        phase = .starting
        Task { await start() }
    }

    /// The startup failure screen's Reset app data, once the user confirmed it: the saved data the start couldn't use is
    /// reset (`AppBootstrap.resetData`; nothing has the database open, the start failed opening it), then the start runs
    /// again, as a first run. Apple TV has no downloads.
    func resetData() async throws {
        #if os(tvOS)
        let downloads: DownloadStoragePlatform? = nil
        let downloadTempDirectory: String? = nil
        #else
        let downloads: DownloadStoragePlatform? = DownloadStoragePlatform.companion.apple()
        let downloadTempDirectory: String? = AppleDownloadPlatform.tempDirectoryPath
        #endif
        try await AppBootstrap.companion.resetData(
            database: DatabaseFactory(), secrets: KeychainSecretStore(), downloads: downloads, downloadTempDirectory: downloadTempDirectory
        )
        retryStart()
    }

    /// Files the app can download again: the Caches directory, on the Mac (whose Caches
    /// every app shares) the app's own folder there.
    static var caches: URL {
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(filePath: NSTemporaryDirectory(), directoryHint: .isDirectory)
        #if os(macOS)
        url.append(path: Bundle.main.bundleIdentifier ?? "com.edde746.plezy", directoryHint: .isDirectory)
        #endif
        return url
    }

    /// The built core, product or dev: it hears the scene's state so far and the network, and `crashReports` (the launch's endpoint) follow this device's switch.
    func attach(_ boot: AppBootstrap, crashReports: CrashReports) {
        self.boot = boot
        if inForeground { boot.onForeground() }
        #if os(macOS)
        if let windowVisible { boot.onWindowVisibleChanged(visible: windowVisible) }
        #endif
        watchNetwork()
        Task { await CrashReporting.follow(crashReports) }
    }

    /// Tells the shared core how the network is (online, and whether the path is expensive or constrained) as it changes.
    private func watchNetwork() {
        network.pathUpdateHandler = { [weak self] path in
            let satisfied = path.status == .satisfied
            let metered = path.isExpensive || path.isConstrained
            Task { @MainActor in
                self?.boot?.onNetworkChanged(online: satisfied, metered: metered)
            }
        }
        network.start(queue: .main)
    }

    /// The launch can't start: `reason` (English, a developer's text) goes to the log alone.
    func fail(_ reason: String) {
        log.error("launch failed: \(reason, privacy: .public)")
        phase = .failed
    }
}

/// The shared core's log (`Log`) in the unified log beside the app's own lines: subsystem com.edde746.plezy, the
/// shared tag (`RootSession`) as the category. Info goes in as notice, the level the system keeps (as the app's own
/// lines), where `log show` and a sysdiagnose find it. The shared `Redactor` has already taken the secrets out, so the
/// text is public.
private final class UnifiedLogSink: NSObject, LogSink {
    private let loggers = OSAllocatedUnfairLock(initialState: [String: Logger]())

    func write(level: Log.Level, tag: String, message: String, error: String?) {
        let logger = loggers.withLock { loggers in
            if let logger = loggers[tag] { return logger }
            let logger = Logger(subsystem: "com.edde746.plezy", category: tag)
            loggers[tag] = logger
            return logger
        }
        let text = error.map { "\(message)\n\($0)" } ?? message
        switch level {
        case .debug: logger.debug("\(text, privacy: .public)")
        case .info: logger.notice("\(text, privacy: .public)")
        case .warn: logger.warning("\(text, privacy: .public)")
        default: logger.error("\(text, privacy: .public)")
        }
    }
}
