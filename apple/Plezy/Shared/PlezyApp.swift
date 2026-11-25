import SwiftUI
import PlezyKit

#if os(iOS) || os(tvOS)
import UIKit
#endif

@main
struct PlezyApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    /// Sparkle, for the DMG build (AppKit/Updates.swift).
    private let updater = AppUpdater.shared
    #elseif os(iOS)
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif

    /// The process's start: the shared core, then the root session or a `--dev` session. One per process: the video
    /// surface can only live in one view hierarchy, so there is one window.
    @State private var launch = AppLaunch()

    init() {
        ArtworkPipeline.setUp()
        MemoryWarnings.observe()
        #if os(iOS) || os(tvOS)
        PlaybackAudioSession.setUpForTheApp()
        // Game controllers move through the app from launch on (the Mac's once its application exists).
        GamepadInput.shared.start()
        #endif
        #if os(tvOS)
        // A screen's focus restore ends at the user's first move after it was asked for.
        FocusRestore.countUserMoves()
        // Page titles in the primary text colour, white: in the dark appearance tvOS draws a navigation bar's title in
        // white at 25 % (`_UINavigationBarTVVisualStyle`'s default title colour), #404040 on the black pages, 2.0:1.
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.label]
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        Window(T.shared.app.name, id: "main") {
            // The window narrows no further than the sidebar beside a screen's least readable width: past it a settings
            // row broke its title after every letter.
            LaunchView(launch: launch)
                .frame(minWidth: 680)
                // Closing the window or quitting waits for the app's teardown (`AppDelegate.applicationShouldTerminate`).
                .onAppear { appDelegate.shutdown = { [launch] in await launch.shutdown() } }
        }
        .defaultSize(width: 1280, height: 720)
        // The toolbar no taller than the row of the window's buttons, and navigation only: on the top-level screens,
        // whose toolbar holds no title, the screen's header row sits on its band (`screenHeader`); pushed screens keep
        // their back button and title there.
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            // View → Show Sidebar / Hide Sidebar (⌃⌘S).
            SidebarCommands()
            CommandGroup(after: .appInfo) {
                // A Homebrew install, whose updates Homebrew makes, has no Sparkle to ask.
                if updater.updater == .native {
                    CheckForUpdatesButton(updater: updater.controller.updater)
                }
            }
            AppCommands()
        }
        #else
        WindowGroup {
            LaunchView(launch: launch)
        }
        #if os(iOS)
        .commands { AppCommands() }
        #endif
        #endif
    }
}

/// The window's content for each launch phase, in the app's theme and with the window's form factor.
struct LaunchView: View {
    let launch: AppLaunch

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.displayScale) private var displayScale
    #if os(macOS)
    /// Whether the app is frontmost: the Mac's scene stays active behind another app.
    @State private var frontmost = NSApplication.shared.isActive
    #endif

    /// The interface language: the strings are read as the views build, so a new language builds every view again, and
    /// a right-to-left language lays out right to left.
    @State private var language = StoreObserver(InterfaceLocale.shared.tag)

    var body: some View {
        let tag = language.state as String
        Group {
            switch launch.phase {
            case .starting:
                StartingView(startup: launch.startup)
            case .product(let root):
                RootView(root: root)
            #if DEBUG
            case .dev(let app): SessionShell(app: app)
            #endif
            case .failed:
                ErrorStateView(message: T.shared.app.launchFailed, title: T.shared.app.name)
            case .startFailed(let failure):
                StartupFailureView(failure: failure, onRetry: launch.retryStart, onReset: { try await launch.resetData() })
            }
        }
        .announcementProbe()
        // The whole window, its safe area included (a TV's overscan inset): the display the artwork budgets are for.
        .onGeometryChange(for: CGSize.self) {
            CGSize(width: $0.size.width + $0.safeAreaInsets.leading + $0.safeAreaInsets.trailing,
                   height: $0.size.height + $0.safeAreaInsets.top + $0.safeAreaInsets.bottom)
        } action: { ArtworkPipeline.fit(points: $0, scale: displayScale) }
        #if DEBUG
        .displayProbes()
        #endif
        .id(tag)
        // Numbers, percentages and dates format in the interface language too, not the system's.
        .environment(\.locale, Locale(identifier: tag))
        .environment(\.layoutDirection, InterfaceLocale.shared.isRightToLeft(tag: tag) ? .rightToLeft : .leftToRight)
        .task { await language.observe() }
        .formFactorEnvironment()
        .verticalBarEnvironment()
        .plezyTheme()
        #if os(iOS)
        .dismissesKeyboard()
        .offersExternalScreen()
        #endif
        .background(Palette.background)
        // The shared core's foreground: the scene's phase from the start. Background is the home screen, or the app
        // running on for audio or picture in picture; inactive is a passing overlay (Control Center, the app switcher),
        // but on the Mac, where it counts as background. The Mac's scene stays active while another app is frontmost,
        // so there the app's own activation decides too; the window's occlusion, reported apart, says whether it can be
        // seen.
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                #if os(macOS)
                frontmost = NSApp.isActive
                if NSApp.isActive { launch.onForeground() }
                #else
                launch.onForeground()
                #endif
            case .background:
                launch.onBackground()
            #if os(macOS)
            case .inactive:
                launch.onBackground()
            #endif
            default:
                break
            }
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            frontmost = true
            if scenePhase == .active { launch.onForeground() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            frontmost = false
            launch.onBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeOcclusionStateNotification)) { _ in
            launch.onWindowVisibleChanged(NSApp.occlusionState.contains(.visible))
        }
        .onAppear {
            // The app may have become active before this view could hear of it.
            frontmost = NSApp.isActive
            launch.onWindowVisibleChanged(NSApp.occlusionState.contains(.visible))
        }
        #endif
        #if !os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in launch.onTerminate() }
        #endif
        .environment(\.appActive, appActive)
        // The URLs the app is asked to open (the Info.plist's `plezy` URL type), and in a DEBUG dev session the
        // development links (`AppModel.followDevLink`). On the Mac a link that starts the app opens its window and
        // arrives here too.
        .onOpenURL { url in launch.openLink(url.absoluteString) }
    }
}

extension LaunchView {
    /// Whether the app is in use: its scene active and, on the Mac, the app frontmost.
    private var appActive: Bool {
        #if os(macOS)
        scenePhase == .active && frontmost
        #else
        scenePhase == .active
        #endif
    }
}

extension EnvironmentValues {
    /// Whether the app is in use (`LaunchView`), and under the player its screens not (`AppShell`): the artwork timers
    /// (the hero's pages, the backdrops' rotation) hold still while it isn't and start their wait anew when it is again.
    @Entry var appActive = true
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The app's teardown for a quit (`AppLaunch.shutdown`), set once the window is up.
    var shutdown: (() async -> Void)?
    private var shuttingDown = false

    /// The window is the app; closing it quits instead of leaving audio playing with no window.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// A quit (Cmd-Q, the menu, the last window closed, the system's logout) waits for the app's teardown: the
    /// playback's last report and the trackers' stop reach their servers before the process ends. The windows go at
    /// once, so the quit reads as instant.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let shutdown else { return .terminateNow }
        if shuttingDown { return .terminateLater }
        shuttingDown = true
        for window in sender.windows { window.orderOut(nil) }
        Task { @MainActor in
            await shutdown()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    /// The system's chrome in the theme's appearance (`ThemeState`): the window's title bar and toolbar, its sheets,
    /// alerts and file panels, the menus and popovers, Sparkle's windows. Set before the window opens, so its first
    /// frame has it too.
    func applicationWillFinishLaunching(_ notification: Notification) {
        _ = ThemeState.shared
    }

    /// SwiftUI opens the window on the open-application event LaunchServices sends. Started without one (the binary
    /// run from a shell, or by a UI test), the app would run with no window at all: it asks itself to reopen, which
    /// opens the window as a click on its Dock icon does. The toolbar's band takes the title bar's double click
    /// (`TitleBarDoubleClick`); the window's Escape goes back (`WindowBack`); arrows no view takes move focus
    /// (`ArrowFocus`); arrows and Tab hide the pointer (`KeyboardPointer`); game controllers move through the app
    /// (`GamepadInput`).
    func applicationDidFinishLaunching(_ notification: Notification) {
        TitleBarDoubleClick.install()
        // Before WindowBack, which then goes between the window and it: Escape comes to WindowBack right after the window.
        ArrowFocus.install()
        WindowBack.install()
        KeyboardPointer.install()
        GamepadInput.shared.start()
        DispatchQueue.main.async {
            guard !NSApp.windows.contains(where: \.isVisible) else { return }
            let reopen = NSAppleEventDescriptor(
                eventClass: AEEventClass(kCoreEventClass),
                eventID: AEEventID(kAEReopenApplication),
                targetDescriptor: NSAppleEventDescriptor(processIdentifier: ProcessInfo.processInfo.processIdentifier),
                returnID: AEReturnID(kAutoGenerateReturnID),
                transactionID: AETransactionID(kAnyTransactionID)
            )
            _ = try? reopen.sendEvent(options: [.noReply], timeout: 1)
        }
    }
}
#endif

#if os(iOS)
/// The app's delegate on iPhone and iPad: the orientations the window may take (`PlayerOrientation`), the external
/// display's scene (`ExternalDisplay`) and the background downloads' wake-ups.
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// The system woke or relaunched the app for the events of a background session's downloads: the transport calls
    /// `completionHandler` once it has handled them.
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        BackgroundTransport.handleEvents(of: identifier, completion: completionHandler)
    }
}
#endif
