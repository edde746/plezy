import AppKit

/// The Mac's arrow keys (and so a controller's D-pad, `GamepadInput`) between the window's focusable views: an arrow
/// that no view in the window took (a text field's caret, a list's selection, the player's seek) comes up the window's
/// responder chain to this responder, which moves the keyboard's focus to the focusable view nearest the focused one that
/// way, as an iPad's keyboard focus does. It picks from the window's key view loop, Tab's order. The view focus lands on,
/// by an arrow or by Tab, scrolls into view: a row of cards follows Tab to its View all card. Return that no view took
/// (no default button, no text) presses the focused control, as Space does: Return selects, as on the other desktops.
@MainActor
final class ArrowFocus: NSResponder {
    static let shared = ArrowFocus()

    private var observer: NSObjectProtocol?
    private var tabMonitor: Any?

    /// Puts the responder after each app window as it becomes key (and the key window now), and follows Tab: once, as
    /// the app starts.
    static func install() {
        shared.observer = shared.followAppWindows()
        shared.tabMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // On the main thread, before the event goes to its window, which moves focus on Tab: the focused view is
            // revealed once it has.
            nonisolated(unsafe) let event = event
            MainActor.assumeIsolated {
                if event.keyCode == tab, event.modifierFlags.isDisjoint(with: [.command, .control, .option]) {
                    DispatchQueue.main.async { MainActor.assumeIsolated { revealFocus() } }
                }
            }
            return event
        }
    }

    private static let tab: UInt16 = 48

    /// The key window's focused view scrolled into view.
    private static func revealFocus() {
        guard let window = NSApp.keyWindow, let focused = window.firstResponder as? NSView,
              focused !== window.contentView else { return }
        reveal(focused, in: window)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == Self.return, event.modifierFlags.isDisjoint(with: [.command, .control, .option, .shift]),
           let window = event.window, let focused = window.firstResponder as? NSView, focused !== window.contentView,
           !(focused is NSText) {
            if !event.isARepeat {
                MacKey.space.post(down: true)
                MacKey.space.post(down: false)
            }
            return
        }
        guard let direction = Direction(event), let window = event.window, move(direction, in: window) else {
            return super.keyDown(with: event)
        }
    }

    private static let `return`: UInt16 = 36

    enum Direction {
        case up, down, left, right

        /// An arrow key without ⌘, ⌃, ⌥ or ⇧ (its numeric pad and function flags are the arrows' own).
        init?(_ event: NSEvent) {
            guard event.modifierFlags.isDisjoint(with: [.command, .control, .option, .shift]) else { return nil }
            switch event.keyCode {
            case 126: self = .up
            case 125: self = .down
            case 123: self = .left
            case 124: self = .right
            default: return nil
            }
        }
    }

    /// Focus onto the key view loop's view nearest the focused view toward `direction`; false where there is none. A view
    /// out of sight in a scrolled row or page counts: focused, it scrolls into view, as with Tab.
    private func move(_ direction: Direction, in window: NSWindow) -> Bool {
        guard let focused = window.firstResponder as? NSView, focused !== window.contentView else { return false }
        let from = Self.frame(of: focused)
        var loop: [NSView] = []
        var next = focused.nextValidKeyView
        while let view = next, view !== focused, loop.count < 1000 {
            loop.append(view)
            next = view.nextValidKeyView
        }
        let best = loop.compactMap { view -> (NSView, CGFloat)? in
            let to = Self.frame(of: view)
            guard !to.isEmpty, let score = Self.score(from: from, to: to, direction: direction) else { return nil }
            return (view, score)
        }.min { $0.1 < $1.1 }
        guard let target = best?.0, window.makeFirstResponder(target) else { return false }
        Self.reveal(target, in: window)
        return true
    }

    /// Scrolls every scroll view whose content holds the view's place (a row of cards, then the page) to show it whole,
    /// with room around it for its focus ring and what goes with it (a card's title under its artwork), and its width
    /// again to each side: a lazy row makes its next card only once that card comes into view, and Tab and the arrows
    /// reach only the cards it has made.
    private static func reveal(_ view: NSView, in window: NSWindow) {
        guard let content = window.contentView else { return }
        let rect = view.convert(view.bounds, to: nil)
        var found: [NSScrollView] = []
        Self.scrollViews(in: content, into: &found)
        for scroll in found {
            guard let document = scroll.documentView else { continue }
            let place = document.convert(rect, from: nil)
            guard document.bounds.contains(place) else { continue }
            let room = place.insetBy(dx: -(place.width + revealMargin), dy: -revealMargin)
            document.scrollToVisible(room.intersection(document.bounds))
        }
    }

    private static let revealMargin: CGFloat = 48

    private static func scrollViews(in view: NSView, into found: inout [NSScrollView]) {
        if let scroll = view as? NSScrollView { found.append(scroll) }
        for subview in view.subviews where !subview.isHidden {
            scrollViews(in: subview, into: &found)
        }
    }

    /// The view's frame in the window, its y down from the top as the screen reads.
    private static func frame(of view: NSView) -> CGRect {
        let rect = view.convert(view.bounds, to: nil)
        let height = view.window?.contentView?.frame.height ?? 0
        return CGRect(x: rect.minX, y: height - rect.maxY, width: rect.width, height: rect.height)
    }

    /// How far `to` is from `from` toward `direction`: the distance along the press plus twice the distance across it;
    /// nil when `to` isn't that way.
    private static func score(from: CGRect, to: CGRect, direction: Direction) -> CGFloat? {
        let along: CGFloat
        let across: CGFloat
        switch direction {
        case .up: (along, across) = (from.minY - to.maxY, abs(to.midX - from.midX))
        case .down: (along, across) = (to.minY - from.maxY, abs(to.midX - from.midX))
        case .left: (along, across) = (from.minX - to.maxX, abs(to.midY - from.midY))
        case .right: (along, across) = (to.minX - from.maxX, abs(to.midY - from.midY))
        }
        guard along > -1 else { return nil }
        return max(along, 0) + 2 * across
    }
}
