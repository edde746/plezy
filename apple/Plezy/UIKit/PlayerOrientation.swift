#if os(iOS)
import OSLog
import PlezyKit
import SwiftUI
import UIKit

private let log = Logger(subsystem: "com.edde746.plezy", category: "player")

/// The player's orientation on an iPhone or iPad, by the shared rule (`PlayerOrientationRules`): while the rotation lock
/// (`rotation_locked`) is on, the player turns to landscape as it opens (either side, as the device is held, and it
/// turns over with the device); while it is off every orientation the app declares is allowed and the player follows
/// the device; leaving the player allows them all again and gives back the orientation the app had before.
///
/// The app delegate answers UIKit with `supported` (`AppDelegate.application(_:supportedInterfaceOrientationsFor:)`);
/// a change asks the window scene to turn (`requestGeometryUpdate`), one turn at a time: UIKit drops a turn asked for
/// while another is under way, with no error. A turn is under way until its window has the shape of one of its
/// orientations (or it failed) and no transition is: neither a size transition of the player's cover (`Transitions`)
/// nor the top view controller's (`transitionCoordinator`), each until its coordinator completes it. The scene's
/// geometry (`effectiveGeometry`, observed) tells when to look, not where the scene is: during a turn it reads the new
/// orientation, then the old one again until about 0.2 s after the turn's transition has completed, while the window
/// has the new shape throughout (the iOS 26.5 simulator; the 27.0 one read portrait 0.6 s into a landscape turn).
@MainActor
enum PlayerOrientation {
    /// What the app allows now: every orientation the app declares (Info.plist), else landscape while the player holds
    /// it.
    private(set) static var supported = declared
    /// The orientation the app had as the player opened; nil while the player is closed.
    private static var before: UIInterfaceOrientation?
    /// The rotation lock setting (`rotation_locked`), as the player last reported it.
    private static var rotationLocked = true
    /// The turn asked of the scene that is still under way: its number, the orientations it asked for, whether the
    /// window has one of their shapes or the turn failed (`done`), and the watch on the scene's geometry.
    private static var inFlight: (number: Int, mask: UIInterfaceOrientationMask, done: Bool, watch: NSKeyValueObservation)?
    /// Turns asked of the scene so far, which number them.
    private static var turns = 0
    /// The transitions under way that a turn waits for, by coordinator: the player's cover's size transitions
    /// (`Transitions`: a turn, asked for or the device's) and the top view controller's (`transitionCoordinator`: its
    /// presentation, or a turn).
    private static var transitions: Set<ObjectIdentifier> = []
    /// The turn asked for while another was under way (the latest one), asked of the scene once none is.
    private static var waiting: Turn?

    private struct Turn {
        /// What the app allows from this turn on (`supported`).
        let supported: UIInterfaceOrientationMask
        /// The orientations the scene is asked to turn to.
        let mask: UIInterfaceOrientationMask
        let why: String
    }

    private static var declared: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
    }

    /// The player's cover came up (`shown`, with the rotation lock as it is) or went.
    static func playerShown(_ shown: Bool, rotationLocked: Bool) {
        self.rotationLocked = rotationLocked
        guard let scene = activeScene else { return }
        if shown {
            guard before == nil else { return }
            before = scene.effectiveGeometry.interfaceOrientation
            follow(in: scene)
        } else if let before {
            self.before = nil
            guard PlayerOrientationRules.shared.onExit(platformOwnsOrientation: false) != nil else { return }
            ask(Turn(supported: declared, mask: mask(of: before), why: "player closed: back to \(before.rawValue)"), in: scene)
        }
    }

    /// The rotation lock changed while the player shows (its button, the settings).
    static func rotationLockChanged(_ locked: Bool) {
        guard locked != rotationLocked else { return }
        rotationLocked = locked
        guard before != nil, let scene = activeScene else { return }
        follow(in: scene)
    }

    /// Landscape while the rotation lock is on; every declared orientation, as the device is held, while it is off.
    private static func follow(in scene: UIWindowScene) {
        switch PlayerOrientationRules.shared.whilePlaying(rotationLocked: rotationLocked, platformOwnsOrientation: false) {
        case .landscape:
            ask(Turn(supported: .landscape, mask: .landscape, why: "rotation locked: landscape"), in: scene)
        default:
            ask(Turn(supported: declared, mask: declared, why: "rotation unlocked: every orientation"), in: scene)
        }
    }

    /// Asks the scene for `turn` now, or once no turn is under way. A window that already has the shape of one of the
    /// turn's orientations has nothing to turn, so nothing is in flight after it.
    private static func ask(_ turn: Turn, in scene: UIWindowScene) {
        let top = topController(of: scene)
        if let coordinator = top?.transitionCoordinator { track(coordinator, "the top view controller's transition") }
        guard inFlight == nil, transitions.isEmpty else {
            waiting = turn
            log.notice("player orientation: \(turn.why, privacy: .public), once the turn under way has ended")
            return
        }
        supported = turn.supported
        log.notice("player orientation: \(turn.why, privacy: .public)")
        // The player's cover is presented over the root: UIKit asks the top one.
        top?.setNeedsUpdateOfSupportedInterfaceOrientations()
        guard !shows(turn.mask, in: scene) else { return }
        turns += 1
        let number = turns
        let watch = scene.observe(\.effectiveGeometry) { @Sendable scene, _ in
            Task { @MainActor in settle(in: scene) }
        }
        inFlight = (number, turn.mask, false, watch)
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: turn.mask)) { error in
            log.error("player orientation: the turn failed: \(String(describing: error), privacy: .public)")
            Task { @MainActor in
                guard inFlight?.number == number else { return }
                inFlight?.done = true
                settle(in: scene)
            }
        }
    }

    /// Something changed (the scene's geometry, a transition ended, the turn failed): once the turn in flight is done
    /// and no transition is under way, the turn has ended and the one waiting, if any, is asked for.
    private static func settle(in scene: UIWindowScene) {
        if let coordinator = topController(of: scene)?.transitionCoordinator {
            track(coordinator, "the top view controller's transition")
        }
        if let inFlight, !inFlight.done, shows(inFlight.mask, in: scene) { self.inFlight?.done = true }
        guard transitions.isEmpty else { return }
        if let inFlight {
            guard inFlight.done else { return }
            inFlight.watch.invalidate()
            self.inFlight = nil
            log.notice("player orientation: turn \(inFlight.number) ended")
        }
        guard let waiting else { return }
        self.waiting = nil
        ask(waiting, in: scene)
    }

    /// Counts `coordinator`'s transition (`what`) as under way until the coordinator completes it.
    private static func track(_ coordinator: any UIViewControllerTransitionCoordinator, _ what: String) {
        let id = ObjectIdentifier(coordinator as AnyObject)
        guard transitions.insert(id).inserted else { return }
        let queued = coordinator.animate(alongsideTransition: nil) { _ in
            MainActor.assumeIsolated {
                guard transitions.remove(id) != nil else { return }
                log.notice("player orientation: \(what, privacy: .public) ended")
                if let scene = activeScene { settle(in: scene) }
            }
        }
        if queued {
            log.notice("player orientation: \(what, privacy: .public) is under way")
        } else {
            transitions.remove(id)
        }
    }

    /// The scene's window has the shape of one of `mask`'s orientations (landscape: wider than tall).
    private static func shows(_ mask: UIInterfaceOrientationMask, in scene: UIWindowScene) -> Bool {
        guard let size = scene.keyWindow?.bounds.size else { return false }
        return !mask.isDisjoint(with: size.width > size.height ? .landscape : [.portrait, .portraitUpsideDown])
    }

    /// The view controller UIKit asks about orientations: the top one presented (the player's cover is presented over
    /// the root).
    private static func topController(of scene: UIWindowScene) -> UIViewController? {
        var top = scene.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    /// Reports the player's cover's size transitions to `PlayerOrientation`: the cover's hosting controller forwards
    /// `viewWillTransition(to:with:)` to this child, and a turn animates as one.
    struct Transitions: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> Controller { Controller() }
        func updateUIViewController(_ controller: Controller, context: Context) {}

        final class Controller: UIViewController {
            override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
                super.viewWillTransition(to: size, with: coordinator)
                PlayerOrientation.track(coordinator, "the cover's turn to \(Int(size.width))x\(Int(size.height))")
            }
        }
    }

    private static func mask(of orientation: UIInterfaceOrientation) -> UIInterfaceOrientationMask {
        switch orientation {
        case .landscapeLeft: .landscapeLeft
        case .landscapeRight: .landscapeRight
        case .portraitUpsideDown: .portraitUpsideDown
        default: .portrait
        }
    }

    private static var activeScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .filter { !ExternalDisplay.isExternal($0.session.role) }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        PlayerOrientation.supported
    }
}
#endif
