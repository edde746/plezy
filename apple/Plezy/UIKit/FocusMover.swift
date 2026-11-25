#if os(iOS)
import PlezyKit
import UIKit

/// A controller's moves and presses on iPhone and iPad (`GamepadInput`), which UIKit hands to no focus engine there, as
/// Apple TV's does: moved through the window's focus system (an iPad's keyboard focus), to the focusable item nearest
/// the focused one in the press's direction, and A presses the focused item. Without a focus system (no keyboard focus
/// on the device) nothing moves.
@MainActor
enum FocusMover {
    static func move(_ key: InputKey) {
        guard let window, let system = UIFocusSystem.focusSystem(for: window) else { return }
        guard let focused = system.focusedItem, let from = frame(of: focused, in: window) else {
            // Nothing focused yet: the window's first focus.
            system.requestFocusUpdate(to: window)
            system.updateFocusIfNeeded()
            return
        }
        let candidates = items(in: window, within: window.bounds).filter { ($0 as AnyObject) !== (focused as AnyObject) && $0.canBecomeFocused }
        let best = candidates.compactMap { item in
            frame(of: item, in: window).flatMap { to in score(from: from, to: to, key: key).map { (item, $0) } }
        }.min { $0.1 < $1.1 }
        guard let target = best?.0 else { return }
        system.requestFocusUpdate(to: target)
        system.updateFocusIfNeeded()
    }

    /// Presses the focused item, as Return does a focused control.
    static func activate() {
        guard let window, let focused = UIFocusSystem.focusSystem(for: window)?.focusedItem else { return }
        if let control = focused as? UIControl {
            control.sendActions(for: .primaryActionTriggered)
        } else if let object = focused as? NSObject {
            _ = object.accessibilityActivate()
        }
    }

    private static var window: UIWindow? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
    }

    /// The focus items under `container` intersecting `rect` (in the window), through nested containers.
    private static func items(in container: UIFocusItemContainer, within rect: CGRect) -> [UIFocusItem] {
        guard let window else { return [] }
        let local = window.convert(rect, to: container.coordinateSpace)
        var found: [UIFocusItem] = []
        for item in container.focusItems(in: local) {
            found.append(item)
            if let nested = (item as? UIFocusEnvironment)?.focusItemContainer, (nested as AnyObject) !== (container as AnyObject) {
                found += items(in: nested, within: rect)
            }
        }
        return found
    }

    private static func frame(of item: UIFocusItem, in window: UIWindow) -> CGRect? {
        guard let space = item.parentFocusEnvironment?.focusItemContainer?.coordinateSpace else { return nil }
        return space.convert(item.frame, to: window)
    }

    /// How far `to` is from `from` toward `key`: the distance along the press plus twice the distance across it; nil
    /// when `to` isn't that way.
    private static func score(from: CGRect, to: CGRect, key: InputKey) -> CGFloat? {
        let along: CGFloat
        let across: CGFloat
        switch key {
        case .up: (along, across) = (from.minY - to.maxY, abs(to.midX - from.midX))
        case .down: (along, across) = (to.minY - from.maxY, abs(to.midX - from.midX))
        case .left: (along, across) = (from.minX - to.maxX, abs(to.midY - from.midY))
        case .right: (along, across) = (to.minX - from.maxX, abs(to.midY - from.midY))
        default: return nil
        }
        guard along > -1 else { return nil }
        return max(along, 0) + 2 * across
    }
}
#endif
