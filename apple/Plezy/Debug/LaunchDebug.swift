import Foundation
import OSLog
import PlezyKit

#if os(iOS) || os(tvOS)
import AVFoundation
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

private let log = Logger(subsystem: "com.edde746.plezy", category: "app")

extension LaunchOptions {
    /// The development options a Debug build reads (`parse`), the same on every platform (the dev module's
    /// `DevLaunch.parse`, which lists them): `--dev` and the session options that need it, and `--dev-slow-start` for
    /// the product's start. Here `--dev-data <name>` keeps the dev session's database under the app's caches,
    /// `--dev-discord` shows on the Mac, and while a session runs the link `plezy://dev-setting?<key>=<value>` (the spec
    /// percent-encoded as the query) applies a `--dev-setting` at once (`AppModel.followDevLink`).
    ///
    /// Pass them after the app on the command line (`xcrun simctl launch booted com.edde746.plezy --dev …`, the Mac
    /// binary's arguments, or a UI test's `launchArguments`). Other arguments are the system's (Xcode adds `-NS…` pairs)
    /// and are left alone; an unknown `--dev…` option fails the launch. On the Mac, AppKit takes unknown values for
    /// documents to open and then opens no window, unless `-NSTreatUnknownArgumentsAsOpen NO` comes first.
    mutating func parseDev(_ arguments: [String]) throws(Failure) {
        let launch: DevLaunch
        do {
            launch = try DevLaunch.companion.parse(args: arguments)
        } catch {
            throw Failure(message: error.localizedDescription)
        }
        dev = launch
        devSlowStartMillis = launch.slowStartMillis
    }
}

extension AppLaunch {
    /// A `--dev` launch: a local graph (`AppBootstrap.local`), the launch's device settings, then the session's app
    /// (`Phase.dev`) on the destination `--dev-open` names. A step of the session's launch that fails later (its
    /// sign-in, its play) is logged and ends the process with status 1: an exit writes no crash report, which Xcode
    /// would blame on every UI test of the app running on the Mac at that moment.
    func startDev(_ launch: DevLaunch) async {
        let version = ApplePlatform.appVersion
        // `--dev-data`: the dev database in the caches, apart from the product's.
        let directory = launch.data.map {
            Self.caches.appending(path: "dev-data/\($0)", directoryHint: .isDirectory).path(percentEncoded: false)
        }
        // The graph opens the database: off the main thread.
        let devLaunch = UncheckedBox(launch)
        let boot = await Task.detached(priority: .userInitiated) {
            UncheckedBox(AppBootstrap.companion.local(
                database: directory.map { DatabaseFactory(directory: $0) } ?? DatabaseFactory.companion.inMemory(),
                flavor: ApplePlatform.flavor,
                appVersion: version,
                http: devLaunch.value.httpClient(appVersion: version)
            ))
        }.value.value
        // Crash reports only where the launch names an endpoint, never the build's.
        attach(boot, crashReports: boot.crashReports(
            channel: ReleaseChannel.companion.DEVELOPMENT, dsn: launch.crashReports ?? ""
        ))
        do {
            try await Self.applyDevSettings(UncheckedBox(boot.graph), UncheckedBox(launch))
            let platform = AppleAppPlatform(discordApplicationId: launch.discord)
            let session = boot.graph.devAppSession(launch: launch, platform: platform) { reason in
                log.error("dev launch failed: \(reason, privacy: .public)")
                exit(1)
            }
            phase = .dev(AppModel(session, platform: platform))
        } catch {
            fail(error.localizedDescription)
        }
    }

    /// The `--dev-setting` device settings, run before any screen exists, off the main actor.
    nonisolated private static func applyDevSettings(_ graph: UncheckedBox<AppGraph>, _ launch: UncheckedBox<DevLaunch>) async throws {
        try await graph.value.applyDevSettings(settings: launch.value.settings)
    }
}

extension AppModel {
    /// A dev session's app takes the links the system hands it (`AppLaunch.openLink`): an external player's return link
    /// (`ExternalPlayerService.handleCallbackUrl`), `plezy://dev-setting?<key>=<value>` (`followDevSettingLink`),
    /// `plezy://dev-gamepad?…` (`followDevGamepadLink`),
    /// `plezy://dev-crash` (`followDevCrashLink`), on iOS and tvOS `plezy://dev-route-change?reason=<n>`
    /// (`PlaybackAudioSession.followDevRouteChangeLink`) and on tvOS `plezy://dev-increase-contrast?on=<true|false>`
    /// (`followDevIncreaseContrastLink`); any other link goes to the session's link queue (`AppLinks.open`), as the
    /// product's do.
    func followDevLink(_ url: String) {
        if ExternalPlayerService.companion.isReturnLink(url: url) {
            _ = session.externalPlayers?.handleCallbackUrl(url: url)
            return
        }
        if followDevSettingLink(url) { return }
        if followDevCrashLink(url) { return }
        if followDevGamepadLink(url) { return }
        #if os(iOS) || os(tvOS)
        if PlaybackAudioSession.followDevRouteChangeLink(url) { return }
        #endif
        #if os(tvOS)
        if followDevIncreaseContrastLink(url) { return }
        #endif
        #if os(iOS)
        if followDevNewWindowLink(url) { return }
        #endif
        session.links.open(url: url)
    }

    #if os(iOS)
    /// The surface ownership test's second window: the link `plezy://dev-new-window` asks iPadOS for another window of
    /// the app, as its app menu's New Window does. False when `url` is another link.
    private func followDevNewWindowLink(_ url: String) -> Bool {
        guard let components = URLComponents(string: url), components.scheme == "plezy", components.host == "dev-new-window" else {
            return false
        }
        log.notice("dev new window link: asking for another window")
        UIApplication.shared.activateSceneSession(for: UISceneSessionActivationRequest(role: .windowApplication)) { error in
            log.error("dev new window link: \(error.localizedDescription, privacy: .public)")
        }
        return true
    }
    #endif

    /// The crash reporting tests' crash: the link `plezy://dev-crash` throws the dev module's crash probe (a Kotlin
    /// exception whose message holds a URL with a token) into this call, which nothing catches, so the
    /// process ends as it does on a Kotlin crash; `plezy://dev-crash?kind=hang` instead blocks the main thread for 10 s,
    /// long enough for the crash reporter's app hang detection. False when `url` is another link.
    private func followDevCrashLink(_ url: String) -> Bool {
        guard let components = URLComponents(string: url), components.scheme == "plezy", components.host == "dev-crash" else {
            return false
        }
        if components.queryItems?.first(where: { $0.name == "kind" })?.value == "hang" {
            log.notice("dev crash link: blocking the main thread")
            Thread.sleep(forTimeInterval: 10)
            return true
        }
        log.notice("dev crash link: crashing")
        DevCrash.shared.crash()
        return true
    }

    /// A UI test's game controller, which a test machine has none of: the link `plezy://dev-gamepad?press=<button>`
    /// presses and releases a button (`hold=<ms>` later, default 80; with `after=<ms>`, that much later, on run loop
    /// timers, which an open menu's tracking runs while it holds back the next link), `down=<button>` or `up=<button>` one
    /// half of it,
    /// `stick=<x>,<y>` puts the left stick there, `disconnect` takes the controller away (after `down`'s press when both
    /// are given, at once, as a controller unplugged with the button held). Each goes into the controller
    /// bridge where the GameController handlers' presses do (`GamepadInput.button`). Buttons: `dpadUp`, `dpadDown`,
    /// `dpadLeft`, `dpadRight`, `a`, `b`, `x`, `leftShoulder`, `rightShoulder`. False when `url` is another link.
    private func followDevGamepadLink(_ url: String) -> Bool {
        guard let components = URLComponents(string: url), components.scheme == "plezy", components.host == "dev-gamepad" else {
            return false
        }
        let buttons: [String: GamepadButton] = [
            "dpadUp": .dpadUp, "dpadDown": .dpadDown, "dpadLeft": .dpadLeft, "dpadRight": .dpadRight, "a": .a, "b": .b,
            "x": .x, "leftShoulder": .leftShoulder, "rightShoulder": .rightShoulder,
        ]
        let query = Dictionary((components.queryItems ?? []).map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
        log.notice("dev gamepad link: \(components.query ?? "", privacy: .public)")
        #if os(macOS)
        let responder = NSApp.keyWindow?.firstResponder.map { String(describing: type(of: $0)) } ?? "none"
        log.notice("""
            dev gamepad link: first responder \(responder, privacy: .public), active \(NSApp.isActive), \
            keyboard navigation \(NSApp.isFullKeyboardAccessEnabled)
            """)
        #endif
        let input = GamepadInput.shared
        if let name = query["press"], let button = buttons[name] {
            let hold = Int(query["hold"] ?? "") ?? 80
            nonisolated(unsafe) let held = button
            if let after = Int(query["after"] ?? ""), after > 0 {
                for (delay, down) in [(after, true), (after + hold, false)] {
                    let timer = Timer(timeInterval: Double(delay) / 1000, repeats: false) { _ in
                        // On the main run loop.
                        MainActor.assumeIsolated { input.button(held, down: down) }
                    }
                    RunLoop.main.add(timer, forMode: .common)
                }
                return true
            }
            input.button(button, down: true)
            // Released on the main actor, where it was pressed.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(hold))
                input.button(held, down: false)
            }
        } else if let name = query["down"], let button = buttons[name] {
            input.button(button, down: true)
            if query["disconnect"] != nil { input.disconnected() }
        } else if let name = query["up"], let button = buttons[name] {
            input.button(button, down: false)
        } else if let stick = query["stick"] {
            let axes = stick.split(separator: ",").compactMap { Float($0) }
            if axes.count == 2 { input.stick(x: axes[0], y: axes[1]) }
        } else if query["disconnect"] != nil {
            input.disconnected()
        } else {
            log.error("dev gamepad link: nothing to do in \(url, privacy: .public)")
        }
        return true
    }

    #if os(tvOS)
    /// A UI test's Increase Contrast on Apple TV, which its simulator can't turn on (`simctl ui … increase_contrast`
    /// answers that the tvOS runtime doesn't support it): the link `plezy://dev-increase-contrast?on=<true|false>`
    /// sets or clears the contrast trait of every window of the app (`traitOverrides.accessibilityContrast`), the trait
    /// the setting changes, from which SwiftUI's `colorSchemeContrast` and the app's colours (`Color(_:increased:)`)
    /// resolve. False when `url` is another link.
    private func followDevIncreaseContrastLink(_ url: String) -> Bool {
        guard let components = URLComponents(string: url), components.scheme == "plezy", components.host == "dev-increase-contrast" else {
            return false
        }
        let on = components.queryItems?.first(where: { $0.name == "on" })?.value == "true"
        log.notice("dev increase contrast link: \(on, privacy: .public)")
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                if on {
                    window.traitOverrides.accessibilityContrast = .high
                } else {
                    window.traitOverrides.remove(UITraitAccessibilityContrast.self)
                }
            }
        }
        return true
    }
    #endif

    /// A dev session's device setting changed while it runs, as `--dev-setting` sets one at the start: the link
    /// `plezy://dev-setting?<key>=<value>` carries the setting's spec, percent-encoded, as its query (a UI test
    /// opens it in the app under test: the subtitle style changed over the paused player). The dev module's
    /// `DevSetting.parse` reads it and `applyDevSettings` applies it at once; a spec it refuses is logged. False when
    /// `url` is another link.
    private func followDevSettingLink(_ url: String) -> Bool {
        guard let components = URLComponents(string: url), components.scheme == "plezy", components.host == "dev-setting" else {
            return false
        }
        let spec = components.query ?? ""
        let setting: DevSetting
        do {
            setting = try DevSettingCompanion.shared.parse(spec: spec)
        } catch {
            log.error("dev setting link: \(error.localizedDescription, privacy: .public)")
            return true
        }
        log.notice("dev setting link: \(setting.key, privacy: .public)=\(setting.value, privacy: .public)")
        let call = (graph: UncheckedBox(graph), settings: UncheckedBox([setting]))
        Task {
            do {
                try await Self.applyDevSettings(call.graph, call.settings)
            } catch {
                log.error("dev setting link: \(error.localizedDescription, privacy: .public)")
            }
        }
        return true
    }

    /// The dev module's `applyDevSettings`, off the main actor as the dev start runs it.
    nonisolated private static func applyDevSettings(_ graph: UncheckedBox<AppGraph>, _ settings: UncheckedBox<[DevSetting]>) async throws {
        try await graph.value.applyDevSettings(settings: settings.value)
    }
}

#if os(iOS) || os(tvOS)
private let playerLog = Logger(subsystem: "com.edde746.plezy", category: "player")

extension PlaybackAudioSession {
    /// A UI test's audio route change, which a simulator can't make (it has no headphones to plug in or out): the link
    /// `plezy://dev-route-change?reason=<AVAudioSession.RouteChangeReason raw value>`, which a dev session follows
    /// (`AppModel.followDevLink`), posts the session's `routeChangeNotification` with that reason, as the system does.
    /// False when `url` is another link.
    static func followDevRouteChangeLink(_ url: String) -> Bool {
        guard let components = URLComponents(string: url), components.scheme == "plezy", components.host == "dev-route-change" else {
            return false
        }
        guard let reason = components.queryItems?.first(where: { $0.name == "reason" })?.value.flatMap(UInt.init) else {
            playerLog.error("dev route change link without a reason: \(url, privacy: .public)")
            return true
        }
        playerLog.notice("dev route change link: reason \(reason, privacy: .public)")
        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionRouteChangeReasonKey: reason]
        )
        return true
    }
}
#endif
