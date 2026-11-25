import AppKit
import SwiftUI

/// The window's title bar on the toolbar's band where nothing there takes a click: over the band of a screen
/// (`windowToolbarBand`). What the screen draws over it on the band takes its own clicks: SwiftUI's hit test gives them
/// to the control first. A drag moves the window (`performDrag`), a click in an inactive window acts at once, as on the title
/// bar, and a double click does what the title bar's does (`TitleBarDoubleClick`).
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView {
        DragView()
    }

    func updateNSView(_ nsView: DragView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            // A double click's second press moves nothing: its release is the title bar's double click.
            guard event.clickCount != 2 else { return }
            window?.performDrag(with: event)
        }

        override func isAccessibilityElement() -> Bool { false }
    }
}

/// A double click on the toolbar's band where nothing takes it does what a double click on the title bar does, as
/// System Settings → Desktop & Dock has it (`AppleActionOnDoubleClick`): zoom (`Maximize`), fill, which has no public
/// API and zooms too, minimize, or nothing; unset, the older `AppleMiniaturizeOnDoubleClick` minimizes, else it zooms.
///
/// The window's content reaches up under its transparent title bar, so a click on the band lands on the content's views
/// (`WindowDragArea`, a screen's scroll view, a toolbar's space). Through macOS 27.0 a gesture on the window's frame view
/// took every double click there, whatever view it landed on. On macOS 27.2 the title bar's own view has that gesture,
/// which a click on the content never reaches, and no double click on the band's empty parts did anything, the toolbar's
/// spaces included. So the app acts once the double click's release has gone through the window, and only where macOS
/// hasn't: macOS's zoom and fill have changed the window's frame by then, and its minimize, which starts a moment later,
/// and the app's make one.
@MainActor
enum TitleBarDoubleClick {
    private static var monitor: Any?

    /// Watches the app's clicks from launch on.
    static func install() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { event in
            // On the main thread, before the event goes to its window.
            MainActor.assumeIsolated { released(event) }
            return event
        }
    }

    private static func released(_ event: NSEvent) {
        guard event.clickCount == 2, let window = event.window, onEmptyBand(event.locationInWindow, of: window) else { return }
        let frame = window.frame
        // After the release has gone through the window, where macOS's own double click acts.
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if window.frame == frame { act(on: window) }
            }
        }
    }

    /// Whether a click at `point` (in the window) is on the band, the title bar's height of a window whose content
    /// reaches up under it, outside full screen, and on nothing there that takes a click: on a `WindowDragArea`, or on
    /// the title bar's own views but the window's buttons and the toolbar's items. Anywhere else in the content (a
    /// control on the band, the player's video) the click is the content's.
    private static func onEmptyBand(_ point: NSPoint, of window: NSWindow) -> Bool {
        guard window.styleMask.contains(.fullSizeContentView), !window.styleMask.contains(.fullScreen),
              point.y >= window.contentLayoutRect.maxY,
              let content = window.contentView, let frameView = content.superview,
              // The frame view is the window's top view: its hit test takes the point in the window.
              let hit = frameView.hitTest(point)
        else { return false }
        if hit is WindowDragArea.DragView { return true }
        if hit.isDescendant(of: content) { return false }
        if window.toolbar?.items.contains(where: { $0.view.map(hit.isDescendant(of:)) ?? false }) == true { return false }
        // The window's buttons take their clicks; its title, a label, is the title bar's.
        return !sequence(first: hit, next: \.superview).contains { view in
            guard let control = view as? NSControl else { return false }
            guard let label = control as? NSTextField else { return true }
            return label.isEditable || label.isSelectable
        }
    }

    private static func act(on window: NSWindow) {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "AppleActionOnDoubleClick") {
        case "Minimize": window.performMiniaturize(nil)
        case "None": break
        case nil where defaults.bool(forKey: "AppleMiniaturizeOnDoubleClick"): window.performMiniaturize(nil)
        default: window.performZoom(nil)
        }
    }
}

/// The title bar in full screen as in a window: see-through, the screen's content (its artwork, the
/// sidebar) running up under the toolbar's band and the toolbar's items over it. In full screen AppKit moves the title
/// bar and the toolbar into a window of their own over the top of the screen (`NSToolbarFullScreenWindow`) and draws
/// the title bar's background there, opaque, in the window's background colour (a dark grey in the app's dark
/// appearance), whatever `titlebarAppearsTransparent` and SwiftUI's toolbar background say: a band as tall as the
/// toolbar across the whole screen, the content laid out under it hidden (macOS 27.2). AppKit's own switch for it,
/// `NSWindow`'s `titlebarAppearsTransparentWhenFullscreen`, has no public API; the Mac app ships outside the Mac App
/// Store, where private API is acceptable (Plezy-Bridging-Header.h). Where AppKit has no such switch nothing changes.
/// AppKit reads it as it sets up the title bar's transparency: on the way into full screen, and in full screen as
/// `titlebarAppearsTransparent` is set.
@MainActor
enum FullScreenTitleBar {
    private static let key = "titlebarAppearsTransparentWhenFullscreen"

    /// Whether `window`'s title bar is see-through in full screen; nil where AppKit has no such switch.
    static func isTransparent(_ window: NSWindow) -> Bool? {
        window.responds(to: NSSelectorFromString(key)) ? window.value(forKey: key) as? Bool : nil
    }

    /// Makes `window`'s title bar see-through in full screen (`transparent`) or opaque, at once where the window is full
    /// screen.
    static func setTransparent(_ transparent: Bool, _ window: NSWindow) {
        guard let current = isTransparent(window), current != transparent else { return }
        window.setValue(transparent, forKey: key)
        guard window.styleMask.contains(.fullScreen) else { return }
        let shown = window.titlebarAppearsTransparent
        window.titlebarAppearsTransparent = !shown
        window.titlebarAppearsTransparent = shown
    }
}

/// The window's buttons in full screen as in a window: close, minimize and zoom at the top left, where the window has
/// them, the toolbar's sidebar toggle and Back to their right. AppKit keeps its own in the full-screen title bar
/// (`NSToolbarFullScreenWindow`), in their place, but faded out, disabled and left out of the accessibility tree until
/// the pointer at the top edge brings the menu bar down, when they come down with the title bar under it, faded in. No
/// API keeps them shown, and AppKit's private reveal amounts (the title bar container's `buttonRevealAmount`, each
/// button's `revealAmount`) don't either: set to 1, the buttons opaque, they took clicks but drew nothing (macOS 27.2).
/// So, as the player's title row has them (`PlayerWindowChrome`), the full-screen title bar gets copies of them
/// (`NSWindow.standardWindowButton(_:for:)`, public API) where its own sit: they act on the window (close closes it,
/// zoom leaves full screen) and minimize is greyed out, as AppKit's own in full screen (a full-screen window can't be
/// minimized); AppKit draws the buttons' symbols on hover only on its own, so the copies show none. One set at a time:
/// the copies hide while AppKit's own show (the title bar down under the menu bar), and they go with the screens'
/// toolbar (the player up, whose title row has copies of its own) and as the window leaves full screen. While the title
/// bar is down the screens come down with it (`FullScreenTitleBarDrop`).
@MainActor
final class FullScreenWindowButtons {
    private static var kept: FullScreenWindowButtons?
    private static let kinds: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

    private weak var window: NSWindow?
    private var observers: [NSObjectProtocol] = []
    private var toolbarShown: NSKeyValueObservation?
    /// AppKit's own close button, which fades in and out with the title bar.
    private weak var ownClose: NSButton?
    private var ownFade: NSKeyValueObservation?
    private var copies: [NSButton] = []
    /// AppKit's full-screen title bar windows (`NSToolbarFullScreenWindow`): the toolbar's, resting over the top of the
    /// window, and the title bar the pointer at the screen's top edge brings down under the menu bar.
    private var titleBarWindows: [NSWindow] = []
    private var titleBarMoves: [NSObjectProtocol] = []
    private var titleBarFades: [NSKeyValueObservation] = []

    /// Keeps `window`'s buttons shown in full screen from now on.
    static func keep(in window: NSWindow) {
        guard kept?.window !== window else { return }
        kept = FullScreenWindowButtons(window)
    }

    private init(_ window: NSWindow) {
        self.window = window
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.update() }
            },
            center.addObserver(forName: NSWindow.willExitFullScreenNotification, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.removeCopies() }
            },
        ]
        update()
    }

    /// Copies in the full-screen title bar while the window shows the screens' toolbar, else none. Made afresh each
    /// time, from AppKit's own buttons as they are then: `standardWindowButton` finds the copies once they are there.
    private func update() {
        removeCopies()
        guard let window else { return }
        if toolbarShown == nil, let toolbar = window.toolbar {
            toolbarShown = toolbar.observe(\.isVisible) { [weak self] _, _ in
                // Once the rest of the change is done: the player hands the title bar back, which may remake it.
                DispatchQueue.main.async {
                    MainActor.assumeIsolated { self?.update() }
                }
            }
        }
        guard window.styleMask.contains(.fullScreen), window.toolbar?.isVisible != false else { return }
        let own = Self.kinds.compactMap { window.standardWindowButton($0) }
        guard own.count == Self.kinds.count, let titleBar = own[0].superview else { return }
        copies = zip(Self.kinds, own).compactMap { kind, button in
            guard let copy = NSWindow.standardWindowButton(kind, for: window.styleMask) else { return nil }
            copy.frame = button.frame
            titleBar.addSubview(copy)
            return copy
        }
        if copies.count == Self.kinds.count { copies[1].isEnabled = false }
        ownClose = own[0]
        ownFade = own[0].observe(\.alphaValue) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.followOwn() }
        }
        followOwn()
    }

    /// Follows every full-screen title bar window not yet followed (AppKit may make the one it brings down as it
    /// comes), then moves the screens with them.
    private func watchTitleBars() {
        guard let kind = NSClassFromString("NSToolbarFullScreenWindow") else { return }
        let center = NotificationCenter.default
        for titleBar in NSApp.windows where titleBar.isKind(of: kind) && !titleBarWindows.contains(titleBar) {
            titleBarWindows.append(titleBar)
            titleBarMoves.append(center.addObserver(forName: NSWindow.didMoveNotification, object: titleBar, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.followTitleBars() }
            })
            titleBarFades.append(titleBar.observe(\.alphaValue) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.followTitleBars() }
            })
        }
        followTitleBars()
    }

    /// The screens come down as far as a title bar window down over the window is (`FullScreenTitleBarPlacement`), and
    /// go back up with it. One that is off the window (AppKit keeps the one it brings down there, empty, until then)
    /// counts for nothing.
    private func followTitleBars() {
        guard let window else { return }
        let drop = titleBarWindows.map { titleBar in
            titleBar.frame.intersects(window.frame)
                && FullScreenTitleBarPlacement.isDown(titleBar: titleBar.frame, alpha: titleBar.alphaValue, window: window.frame)
                ? window.frame.maxY - titleBar.frame.maxY : 0
        }.max() ?? 0
        FullScreenTitleBarDrop.shared.set(drop)
    }

    /// The copies hidden while AppKit's own buttons show; the screens move with the title bar.
    private func followOwn() {
        let hidden = (ownClose?.alphaValue ?? 0) > 0
        for copy in copies where copy.isHidden != hidden { copy.isHidden = hidden }
        watchTitleBars()
    }

    private func removeCopies() {
        ownFade = nil
        copies.forEach { $0.removeFromSuperview() }
        copies = []
        titleBarMoves.forEach(NotificationCenter.default.removeObserver)
        titleBarMoves = []
        titleBarFades = []
        titleBarWindows = []
        FullScreenTitleBarDrop.shared.set(0)
    }
}

/// How far AppKit's full-screen title bar is down under the menu bar, which the pointer at the screen's top edge brings
/// (`FullScreenTitleBarPlacement`): 0 at rest and out of full screen. That title bar is opaque, with the window's
/// buttons alone, and comes down over the top of the window: the screens move down as far (`fullScreenTitleBarDrop`),
/// so it covers the toolbar's band, never the sidebar's rows or a screen's content, and they go back up with it.
@MainActor @Observable
final class FullScreenTitleBarDrop {
    static let shared = FullScreenTitleBarDrop()
    private(set) var height: CGFloat = 0

    func set(_ height: CGFloat) {
        guard height != self.height else { return }
        withAnimation(.easeOut(duration: 0.2)) { self.height = height }
    }
}

extension View {
    /// Moves the view down as far as the full-screen title bar has come down (`FullScreenTitleBarDrop`).
    func fullScreenTitleBarDrop() -> some View {
        modifier(TitleBarDropOffset())
    }
}

private struct TitleBarDropOffset: ViewModifier {
    func body(content: Content) -> some View {
        content.offset(y: FullScreenTitleBarDrop.shared.height)
    }
}

/// The full-screen title bar as the window's under a screen of `RouteStack`, whose toolbar draws no background
/// (`windowToolbarBand`): see-through (`FullScreenTitleBar`) while the window shows that toolbar (the player hides it
/// and keeps its own title bar opaque in full screen, `PlayerWindowChrome`), and with the window's buttons shown
/// (`FullScreenWindowButtons`).
struct WindowLikeFullScreenTitleBar: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowView {
        WindowView()
    }

    func updateNSView(_ nsView: WindowView, context: Context) {}

    final class WindowView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            FullScreenWindowButtons.keep(in: window)
            guard window.toolbar?.isVisible != false else { return }
            FullScreenTitleBar.setTransparent(true, window)
        }

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func isAccessibilityElement() -> Bool { false }
    }
}
