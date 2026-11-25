import AppKit
import SwiftUI

/// The Mac's Back: Escape (and a controller's B, `GamepadInput`) that nothing in the window took, its sheets', menus',
/// overlays' and screens' own Escape first. It goes up the window's responder chain to this responder, after the window,
/// which acts on the key's release (`action`), as the keyboard's Back does on the other desktops: a release whose press
/// it didn't see (a sheet or menu closed on the press) does nothing, so one press never closes two things. With no view
/// focused in the window, where the window would take Escape itself (only to leave full screen), the press comes here
/// once the window's own shortcuts (a menu's or dialog's Cancel) have passed on it (`unfocusedEscape`).
@MainActor
final class WindowBack: NSResponder {
    static let shared = WindowBack()

    /// The running app's Back (`gamepadInput`); `keyboard` is false for a controller's B.
    var action: (@MainActor (_ keyboard: Bool) -> Void)?

    /// The press this responder saw until its release: whether a controller's B typed it.
    private var pressedByGamepad: Bool?
    /// The timestamps of the Escape events a controller's B posted.
    private var gamepadStamps: [TimeInterval] = []
    private var observer: NSObjectProtocol?
    private var menuObservers: [NSObjectProtocol] = []
    private var monitor: Any?
    /// The menu open now (a card's, a menu button's, the menu bar's), which a controller's B closes.
    private weak var openMenu: NSMenu?

    /// Puts the responder after each app window as it becomes key (and the key window now): once, as the app starts.
    static func install() {
        shared.observer = shared.followAppWindows()
        shared.menuObservers = [NSMenu.didBeginTrackingNotification, NSMenu.didEndTrackingNotification].map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { notification in
                // Delivered on the main queue.
                nonisolated(unsafe) let menu = notification.object as? NSMenu
                let begins = name == NSMenu.didBeginTrackingNotification
                MainActor.assumeIsolated { shared.openMenu = begins ? menu : nil }
            }
        }
        shared.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // On the main thread, before the event goes to its window.
            nonisolated(unsafe) let event = event
            return MainActor.assumeIsolated { shared.unfocusedEscape(event) } ? nil : event
        }
    }

    /// A controller's B: Escape, pressed and released, which the window's handlers take first and which this responder
    /// takes as Back wherever the keyboard's Escape would only leave full screen. An open menu, whose tracking takes no
    /// posted key, it closes, as the keyboard's Escape does, and goes no further.
    static func pressFromGamepad() {
        if let menu = shared.openMenu {
            shared.openMenu = nil
            return menu.cancelTracking()
        }
        let stamp = ProcessInfo.processInfo.systemUptime
        shared.gamepadStamps = (shared.gamepadStamps + [stamp]).suffix(4)
        for down in [true, false] {
            if let event = MacKey.escape.event(down: down, timestamp: stamp) { NSApp.postEvent(event, atStart: false) }
        }
    }

    /// Escape in an app window where no view has focus: the window's shortcuts take it first, else it is this
    /// responder's press. True when it went to either, so the window doesn't take it as well.
    private func unfocusedEscape(_ event: NSEvent) -> Bool {
        guard event.keyCode == Self.escape, let window = event.window, window.firstResponder === window,
              window.nextResponder === self else { return false }
        if !window.performKeyEquivalent(with: event) { press(event) }
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == Self.escape else { return super.keyDown(with: event) }
        press(event)
    }

    // The key-binding command Escape is when a view interpreted it.
    override func cancelOperation(_ sender: Any?) {
        guard let event = NSApp.currentEvent, event.type == .keyDown, event.keyCode == Self.escape else { return }
        press(event)
    }

    override func keyUp(with event: NSEvent) {
        guard event.keyCode == Self.escape else { return super.keyUp(with: event) }
        guard let gamepad = pressedByGamepad else { return }
        pressedByGamepad = nil
        action?(!gamepad)
    }

    private func press(_ event: NSEvent) {
        // A held key's repeats are the same press. A posted event's timestamp comes back rounded to the system clock's
        // ticks.
        if !event.isARepeat { pressedByGamepad = gamepadStamps.contains { abs($0 - event.timestamp) < 0.001 } }
    }

    private static let escape: UInt16 = 53
}

extension NSResponder {
    /// Puts this responder right after each app window in its responder chain as the window becomes key (and after the
    /// key window now), where the keys no view in the window took come: an app window's, not a sheet's or a panel's,
    /// which close themselves on Escape. The observer is the caller's to keep.
    @MainActor
    func followAppWindows() -> NSObjectProtocol {
        // The app's responders live as long as the app.
        nonisolated(unsafe) let responder = self
        let observer = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { notification in
            // Delivered on the main queue.
            nonisolated(unsafe) let window = notification.object as? NSWindow
            MainActor.assumeIsolated { responder.follow(window) }
        }
        follow(NSApp.keyWindow)
        return observer
    }

    @MainActor
    private func follow(_ window: NSWindow?) {
        guard let window, window.sheetParent == nil, !(window is NSPanel) else { return }
        var responder: NSResponder? = window.nextResponder
        while let next = responder {
            if next === self { return }
            responder = next.nextResponder
        }
        nextResponder = window.nextResponder
        window.nextResponder = self
    }
}

/// The pointer while the keyboard or a controller moves focus: an arrow key or Tab hides it until the mouse moves, as
/// does a controller's press (`GamepadInput`); clicks still go where it points. Return and Escape, which only press or
/// dismiss, leave it. The player hides and shows it with its controls, and takes the arrows itself: there the keys leave
/// it to the player (`playerShown`).
@MainActor
enum KeyboardPointer {
    /// The player is up (`gamepadInput`).
    static var playerShown = false
    private static var monitor: Any?

    /// Watches the app's keys from launch on.
    static func install() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // On the main thread, before the event goes to its window.
            nonisolated(unsafe) let event = event
            MainActor.assumeIsolated {
                if navigates(event), !playerShown { hide() }
            }
            return event
        }
    }

    static func hide() {
        NSCursor.setHiddenUntilMouseMoves(true)
    }

    /// An arrow key or Tab without ⌘, ⌃ or ⌥: a move of focus.
    private static func navigates(_ event: NSEvent) -> Bool {
        let keys: Set<UInt16> = [48, 123, 124, 125, 126]
        return keys.contains(event.keyCode) && event.modifierFlags.intersection([.command, .control, .option]).isEmpty
    }
}
