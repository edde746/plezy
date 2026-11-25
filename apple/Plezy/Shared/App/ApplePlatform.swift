import Foundation
import PlezyKit

#if os(macOS)
import AppKit
import SystemConfiguration
#else
import AVKit
import UIKit
#endif
#if os(iOS)
import SafariServices
#endif

/// What the app needs from the Apple platform it runs on, as `PlezyPlatform` is for the Compose apps. Main thread.
@MainActor
enum ApplePlatform {
    /// The version About shows and the HTTP client sends (`User-Agent: Plezy/<version>`).
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    /// The build as a failed start's record names it: `version+build` (CFBundleVersion).
    static var buildLabel: String {
        guard let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else { return appVersion }
        return "\(appVersion)+\(build)"
    }

    /// Where this build is distributed: Info.plist's `PlezyFlavor`, a `BuildFlavor` constant's name (project.yml's
    /// PLEZY_APPLE_FLAVOR: the App Store's iOS and tvOS builds STORE, the GitHub release's IPA and the Mac's DMG SIDELOADED).
    nonisolated static var flavor: BuildFlavor {
        switch Bundle.main.object(forInfoDictionaryKey: "PlezyFlavor") as? String {
        case "STORE": .store
        case "AMAZON": .amazon
        case "SIDELOADED": .sideloaded
        case let name: fatalError("Info.plist's PlezyFlavor is \(name ?? "missing"), not a BuildFlavor")
        }
    }

    /// This device as a `DevicePlatform` name: macOS, tvOS, or iPadOS on an iPad and iOS on an iPhone.
    static var devicePlatform: String {
        let devices = DevicePlatform.shared
        #if os(macOS)
        return devices.MACOS
        #elseif os(tvOS)
        return devices.TVOS
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? devices.IPADOS : devices.IOS
        #endif
    }

    /// Where this build is distributed, as its crash reports name it: its flavor's on this device.
    static var releaseChannel: ReleaseChannel {
        ReleaseChannel.companion.of(flavor: flavor, platform: devicePlatform, arch: nil)
    }

    /// Opens the web link `url` outside the app: the browser, or the app that claims it. False for anything but an
    /// `http`/`https` link (`WebUrl.isWeb`; on a Mac a `file:` link would open the file or launch the app it names), and
    /// on Apple TV, which has no browser.
    @discardableResult
    static func openURL(_ url: String) -> Bool {
        #if os(tvOS)
        return false
        #else
        guard WebUrl.shared.isWeb(url: url), let url = URL(string: url) else { return false }
        #if os(macOS)
        return NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        return true
        #endif
        #endif
    }
}

/// The shared app's platform port (`AppPlatform`) on Apple platforms: the device's kind, player profile and actions,
/// `ApplePlatform`'s values, and a new `ApplePlayback` (a surface and its engine, Now Playing, the display output, the
/// audio session) for each playback. One per process.
@MainActor
final class AppleAppPlatform: @preconcurrency AppPlatform {
    /// The kind of device the shared output policy decides for: a Mac is a desktop (the display mode switches only
    /// while the player is fullscreen), an iPhone or iPad a handheld, an Apple TV a TV. The app's own `FormFactor`
    /// (Design/Dimens.swift) is the layout's size class, hence the module prefix.
    var formFactor: PlezyKit.FormFactor {
        #if os(tvOS)
        .tv
        #elseif os(macOS)
        .desktop
        #else
        .handheld
        #endif
    }

    /// An Apple TV: no downloads, and Menu at the app's root goes to the system's home screen.
    var appleTv: Bool {
        #if os(tvOS)
        true
        #else
        false
        #endif
    }

    /// No Apple device the app runs on is low-end enough to trim its caches.
    var lowEndHardware: Bool { false }

    /// Never a car's display: that is Android Automotive.
    var automotive: Bool { false }

    /// The player's keymap profile and timings, with the platform's double-click interval. Apple TV's Select on the
    /// video pauses as it shows the controls, as the system player's does.
    var playerConfig: PlayerConfig {
        #if os(tvOS)
        PlayerConfig.companion.defaults(profile: .tv, doubleClickIntervalMillis: 300, escapeLeavesFullscreen: false, remoteSelectPauses: true)
        #elseif os(macOS)
        PlayerConfig.companion.defaults(
            profile: .desktop,
            doubleClickIntervalMillis: Int64(NSEvent.doubleClickInterval * 1000),
            escapeLeavesFullscreen: false,
            remoteSelectPauses: false
        )
        #else
        // UIKit's double-tap recognizer waits about this long for the second tap.
        PlayerConfig.companion.defaults(profile: .touch, doubleClickIntervalMillis: 300, escapeLeavesFullscreen: true, remoteSelectPauses: false)
        #endif
    }

    func createPlayback(settings: DeviceSettings) -> any PlatformPlayback {
        let playback = ApplePlayback(settings: settings, speeds: playerConfig.speeds.map(\.doubleValue))
        #if os(iOS)
        playback.surface.pictureInPicture.autoPipOn = AppSettings.shared.autoPipOn(
            stored: settings.autoPip,
            supportsPictureInPicture: AVPictureInPictureController.isPictureInPictureSupported(),
            isMacOs: false
        )
        #elseif os(macOS)
        playback.surface.pictureInPicture.autoPipOn = AppSettings.shared.autoPipOn(stored: settings.autoPip, supportsPictureInPicture: true, isMacOs: true)
        #endif
        return playback
    }

    /// The music player: its own MPVKit handle (`AppleMpvAudioCore`), apart from every playback's video engine.
    func createMusicAudioPlayer() -> any AudioPlayer {
        AppleMpvAudioCore.player()
    }

    /// Enters or leaves full screen: the Mac's window. iOS and tvOS always play full screen.
    func setFullscreen(fullscreen: Bool) {
        #if os(macOS)
        guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: \.isVisible) else { return }
        if window.styleMask.contains(.fullScreen) != fullscreen { window.toggleFullScreen(nil) }
        #endif
    }

    /// No always-on-top on Apple platforms: the Mac's player has no such button (`AppPlatform.keepsOnTop`).
    var keepsOnTop: Bool { false }

    func setAlwaysOnTop(onTop: Bool) {}

    /// The Mac's window is in full screen (`AppPlatform.isFullscreen`); iOS and tvOS have no window to change.
    var isFullscreen: Bool {
        #if os(macOS)
        return (NSApp.keyWindow ?? NSApp.windows.first(where: \.isVisible))?.styleMask.contains(.fullScreen) == true
        #else
        return false
        #endif
    }

    /// The screen's brightness and the system's volume the player's swipes change: iPhone and iPad (`TouchLevels`);
    /// the Mac and Apple TV have no swipes on the video.
    var deviceLevels: (any DeviceLevels)? {
        #if os(iOS)
        TouchLevels.shared
        #else
        nil
        #endif
    }

    func openUrl(url: String) -> Bool {
        ApplePlatform.openURL(url)
    }

    #if os(iOS)
    /// The Safari view an in-app `openUrl(url:mode:)` presented, until `closeInAppBrowser()` or the user's Done.
    private weak var safari: SFSafariViewController?
    #endif

    /// Opens the web link `url` as `mode` asks: on iPhone and iPad an in-app mode presents it in a Safari view
    /// (`SFSafariViewController`) over the top screen, the external one opens it outside the app (`openURL`). The
    /// Mac and Apple TV have no in-app view: false there for an in-app mode, and false where no screen shows to present
    /// over.
    func openUrl(url: String, mode: BrowserMode) -> Bool {
        guard mode == .inAppBrowser || mode == .inAppWebView else { return ApplePlatform.openURL(url) }
        #if os(iOS)
        guard WebUrl.shared.isWeb(url: url), let target = URL(string: url) else { return false }
        let scene = UIApplication.shared.connectedScenes.lazy
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        guard let top else { return false }
        let view = SFSafariViewController(url: target)
        top.present(view, animated: true)
        safari = view
        return true
        #else
        return false
        #endif
    }

    /// Dismisses the Safari view `openUrl(url:mode:)` presented, if it still shows: iPhone and iPad.
    func closeInAppBrowser() {
        #if os(iOS)
        safari?.dismiss(animated: true)
        safari = nil
        #endif
    }

    func setClipboardText(text: String, sensitive: Bool) {
        Pasteboard.copy(text, sensitive: sensitive)
    }

    func deviceFeatures() -> DeviceFeatures {
        ApplePlatform.deviceFeatures
    }

    func videoCapabilities() -> VideoCapabilities {
        ApplePlatform.videoCapabilities
    }

    /// External players on this device: plays hand off to the selected one while `use_external_player` is on.
    let externalPlayers: (any ExternalPlayerLauncher)? = ApplePlayerApps()

    /// Discord's Rich Presence: the Mac speaks to the Discord app there (`MacDiscordPresence`, one for the process) as
    /// the Discord application the platform was made with, and without one has none (no Discord switch, nothing
    /// connects); iPhone, iPad and Apple TV have no Discord to speak to.
    let discordPresence: (any DiscordPresenceHost)?

    /// What the app calls this device to media servers and companion devices: the OS, its version, the model and the
    /// name the user gave the device (an iPhone without the device-name entitlement reports its model).
    let device: DeviceIdentity

    /// The platform, Rich Presence on the Mac showing as the Discord application `discordApplicationId`: by default
    /// this build's (`BuildDiscordConfig`), a dev session's its `--dev-discord`.
    init(discordApplicationId: String? = BuildDiscordConfig.shared.config.applicationId) {
        #if os(macOS)
        discordPresence = discordApplicationId.map { MacDiscordPresence(applicationId: $0) }
        #else
        discordPresence = nil
        #endif
        device = Self.deviceIdentity()
    }

    private static func deviceIdentity() -> DeviceIdentity {
        // The system's own description (`Version 18.2 (Build 22C150)`), as the earlier releases sent it.
        let version = ProcessInfo.processInfo.operatingSystemVersionString
        #if os(macOS)
        return DeviceIdentity(platform: "macOS", platformVersion: version, deviceModel: hardwareModel(),
                              deviceName: SCDynamicStoreCopyComputerName(nil, nil) as String?, isTv: false)
        #elseif os(tvOS)
        return DeviceIdentity(platform: "tvOS", platformVersion: version, deviceModel: "Apple TV",
                              deviceName: UIDevice.current.name, isTv: true)
        #else
        return DeviceIdentity(platform: "iOS", platformVersion: version, deviceModel: UIDevice.current.model,
                              deviceName: UIDevice.current.name, isTv: false)
        #endif
    }

    /// The Logs header's system and hardware lines: on iPhone, iPad and Apple TV the system version and the machine
    /// identifier (`iPhone15,2`); the Mac's `device` already names its model.
    func diagnostics() -> [String] {
        #if os(macOS)
        return []
        #else
        var system = utsname()
        uname(&system)
        let machine = withUnsafeBytes(of: &system.machine) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
        return ["\(device.platform) \(UIDevice.current.systemVersion)", machine]
        #endif
    }

    #if os(macOS)
    /// The Mac's model identifier (`MacBookPro18,3`); nil when the system doesn't say.
    private static func hardwareModel() -> String? {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var model = [UInt8](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &model, &size, nil, 0) == 0 else { return nil }
        return String(decoding: model.prefix { $0 != 0 }, as: UTF8.self)
    }
    #endif

    /// Where this app is installed (`UpdatePrompt.installation`) in builds that check for updates; none in Debug
    /// builds, which never check.
    var installation: Installation? {
        UpdatePrompt.checksAtLaunch ? UpdatePrompt.installation : nil
    }

    /// The system's save and open dialogs (`fileExporter`, `fileImporter`): everywhere but Apple TV, which has none.
    var hasFileDialogs: Bool {
        #if os(tvOS)
        false
        #else
        true
        #endif
    }

    /// The player's shaders: the presets' files in the bundle's `shaders` folder, mpv reading them where they are, and
    /// the imported ones in Application Support's `custom_shaders` (the app's own folder there on the Mac), where the
    /// earlier releases kept them.
    let shaderFiles: (any ShaderFiles)? = {
        let support = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
            ?? NSHomeDirectory() + "/Library/Application Support"
        let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
            ?? NSHomeDirectory() + "/Library/Caches"
        #if os(macOS)
        let app = "/" + (Bundle.main.bundleIdentifier ?? "com.edde746.plezy")
        #else
        let app = ""
        #endif
        return ShaderDirectories(
            renderer: .libplacebo,
            bundled: BundledShadersDirectory(path: Bundle.main.resourcePath! + "/shaders"),
            cacheDirectory: caches + app + "/shaders",
            customDirectory: support + app + "/custom_shaders"
        )
    }()

    /// The TV's home screen beside the app (`AppPlatform.homeScreen`): the Apple TV's Top Shelf; iOS, iPadOS and macOS
    /// have none.
    #if os(tvOS)
    let homeScreen: (any HomeScreen)? = TopShelfPublisher()
    #else
    var homeScreen: (any HomeScreen)? { nil }
    #endif

    /// The music session's Now Playing (`AppPlatform.musicControls`), one for the process beside each video playback's
    /// own: music shows as audio with next and previous, never the skip buttons. On Apple TV the
    /// shell hands it the remote's Play/Pause that no screen takes (`AppShell`).
    static let musicNowPlaying = NowPlayingCenter()

    var musicControls: (any MediaControlsHost)? { Self.musicNowPlaying }

    /// Music's OS glue beyond Now Playing: none on Apple platforms (`AppleMusicSystem`).
    let musicSystem: any MusicSystem = AppleMusicSystem()
    let notificationPermission: any NotificationPermission = NoNotificationPermission()

    /// DNS-SD for casting (`AppPlatform.castDiscovery`): Bonjour, for the type Info.plist's NSBonjourServices lists.
    let castDiscovery: (any CastDiscovery)? = BonjourCastDiscovery()

    /// Downloads on this device (`AppPlatform.downloads`): iPhone, iPad and the Mac (`AppleDownloads`); Apple TV has
    /// none, its storage being a cache the system purges.
    #if os(tvOS)
    var downloads: (any PlatformDownloads)? { nil }
    #else
    let downloads: (any PlatformDownloads)? = AppleDownloads()
    #endif

    /// The Supporter perks (`AppPlatform.supporter`): the build's mode, the App Store, the alternate icons.
    let supporter: SupporterPlatform = AppleSupporter.platform()

    /// Every file under `folder` in the app bundle's resources (`AppPlatform.bundledTexts`), at any depth, its path
    /// relative to `folder` and its text as UTF-8, sorted by path; none when the bundle has no such folder. The shared
    /// core calls it off the main thread, so it is nonisolated: it only reads the bundle.
    nonisolated func bundledTexts(folder: String) -> [BundledText] {
        guard let root = Bundle.main.resourceURL?.appendingPathComponent(folder),
              let paths = FileManager.default.enumerator(atPath: root.path) else { return [] }
        return paths.compactMap { $0 as? String }.compactMap { path -> BundledText? in
            var directory: ObjCBool = false
            let file = root.appendingPathComponent(path).path
            guard FileManager.default.fileExists(atPath: file, isDirectory: &directory), !directory.boolValue,
                  let data = FileManager.default.contents(atPath: file) else { return nil }
            return BundledText(path: path, text: String(decoding: data, as: UTF8.self))
        }.sorted { $0.path < $1.path }
    }

    /// Leaves the app: Close with nothing left to go back to. Only a Mac app quits itself; iOS and tvOS leave that
    /// to the system (the Home button, the remote's TV button).
    func exit() {
        #if os(macOS)
        NSApp.terminate(nil)
        #endif
    }
}

/// Music's OS glue on Apple platforms (`AppPlatform.musicSystem`): there is no car service to ask (CarPlay isn't
/// supported) and hardware media keys reach the music session through
/// `MPRemoteCommandCenter` (`NowPlayingCenter`), so taking raw key events too would run each command twice.
/// Nothing to ask (`AppPlatform.notificationPermission`): neither downloads nor music post a notification that needs it.
private final class NoNotificationPermission: NotificationPermission {
    nonisolated func __ensure() async throws {}
}

private final class AppleMusicSystem: MusicSystem {
    var car: (any CarRestrictionsSource)? { nil }

    func setHardwareKeyHandler(handler: ((MusicKey, KeyPhase) -> KotlinBoolean)?) {}
}
