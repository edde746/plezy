#if os(iOS)
import Observation
import OSLog
import SwiftUI
import UIKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "display")

/// An external screen (a cable to a TV or monitor, AirPlay to an Apple TV) the app shows the video on rather than
/// mirroring the device: the system gives the app a scene for the screen (`ExternalDisplaySceneDelegate`: before iOS 27
/// as the screen comes, through `AppDelegate`; from iOS 27 while a window offers it, `offersExternalScreen`), whose
/// window is black until a playback's video moves there (`VideoSurface.placeVideo`). The player's controls stay on the
/// device. One at a time, as the system connects them.
@MainActor
@Observable
final class ExternalDisplay {
    static let shared = ExternalDisplay()

    /// The view the video goes into on the external screen; nil while none is connected.
    private(set) var videoHost: UIView?
    @ObservationIgnored private var window: UIWindow?
    @ObservationIgnored private weak var scene: UIWindowScene?

    private init() {}

    /// A scene session of an external screen: the non-interactive role, or the interactive one, deprecated since iOS
    /// 16, by its raw name.
    nonisolated static func isExternal(_ role: UISceneSession.Role) -> Bool {
        role == .windowExternalDisplayNonInteractive || role.rawValue == "UIWindowSceneSessionRoleExternalDisplay"
    }

    /// The external screen's scene: `ExternalDisplaySceneDelegate`'s.
    static var sceneConfiguration: UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "External Display", sessionRole: .windowExternalDisplayNonInteractive)
        configuration.delegateClass = ExternalDisplaySceneDelegate.self
        return configuration
    }

    /// The external screen's scene connected: its window, black, the video's host.
    fileprivate func connect(_ scene: UIWindowScene) -> UIWindow {
        let controller = UIViewController()
        controller.view.backgroundColor = .black
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.backgroundColor = .black
        window.isHidden = false
        self.window?.isHidden = true
        self.window = window
        self.scene = scene
        videoHost = controller.view
        log.notice("external screen connected: \(Int(scene.screen.bounds.width), privacy: .public)x\(Int(scene.screen.bounds.height), privacy: .public)")
        return window
    }

    /// The external screen's scene went: the video goes back to the device.
    fileprivate func disconnect(_ scene: UIScene) {
        guard scene === self.scene else { return }
        window?.isHidden = true
        window = nil
        self.scene = nil
        videoHost = nil
        log.notice("external screen disconnected")
    }
}

/// The external screen's scene (`ExternalDisplay`).
final class ExternalDisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene, ExternalDisplay.isExternal(session.role) else { return }
        window = ExternalDisplay.shared.connect(scene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        ExternalDisplay.shared.disconnect(scene)
        window = nil
    }
}

extension View {
    /// From iOS 27 the system connects an external screen's scene only while a view controller offers it (a scene
    /// accessory), and mirrors the device otherwise. Set once on the window's content (`LaunchView`): the window's root
    /// view controller offers it for as long as the window lasts, so the screen stays black outside playback, as on
    /// earlier systems. An iPhone or iPad app on a Mac or Apple Vision Pro has no external screen, and the API is
    /// unavailable there.
    func offersExternalScreen() -> some View {
        background(ExternalScreenOffer())
    }
}

/// Registers `offersExternalScreen`'s scene accessory on the root view controller of the window it is in.
private struct ExternalScreenOffer: UIViewRepresentable {
    func makeUIView(context: Context) -> Probe {
        let probe = Probe()
        probe.isUserInteractionEnabled = false
        return probe
    }

    func updateUIView(_ view: Probe, context: Context) {}

    final class Probe: UIView {
        private weak var controller: UIViewController?
        /// The `UISceneAccessoryRegistration` on `controller`.
        private var registration: NSObject?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard #available(iOS 27, *), !ProcessInfo.processInfo.isiOSAppOnMac, !ProcessInfo.processInfo.isiOSAppOnVision,
                  window?.rootViewController !== controller
            else { return }
            if let registration = registration as? UISceneAccessoryRegistration {
                controller?.unregisterSceneAccessory(registration)
            }
            controller = window?.rootViewController
            registration = controller?.registerSceneAccessory(.externalNonInteractive(sceneConfiguration: ExternalDisplay.sceneConfiguration))
        }
    }
}

extension AppDelegate {
    /// An external screen's session gets the external display's scene; the app's own gets a configuration without a
    /// delegate class, which SwiftUI fills in with its own (handing it SwiftUI's configuration back would have SwiftUI
    /// wrap its own delegate in itself, without end).
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let role = connectingSceneSession.role
        return ExternalDisplay.isExternal(role) ? ExternalDisplay.sceneConfiguration : UISceneConfiguration(name: nil, sessionRole: role)
    }
}
#endif
