import AppKit
import SwiftUI

/// The window while the player is up (macOS), as QuickTime Player has it: no toolbar (whose back button and title
/// belong to the screen under the player), the video under the whole window, the title bar transparent and without
/// its title (the player draws the title beside the window's buttons), and those buttons coming and going with the
/// controls. Everything is handed back as it was when the player goes.
///
/// Full screen hides the title bar until the pointer reaches the top edge, where it comes down under the menu bar (the
/// screens keep its buttons shown, `FullScreenWindowButtons`; with the toolbar hidden here they hide as AppKit has them).
/// The player's title row keeps the window's buttons there all the same: copies of them
/// (`NSWindow.standardWindowButton(_:for:)`: they act on the window and grey out while it isn't key, as the title
/// bar's do) where the title bar has them in a window, which the title row hosts (`PlayerWindowButtons`), so they
/// fade with the controls. Minimize is greyed out, as in AppKit's full-screen title bar (a full-screen window can't be
/// minimized); zoom leaves full screen. AppKit draws the buttons' symbols on hover only in its own title bar, so the
/// copies show none. The title bar that comes down in full screen keeps its own buttons: it is opaque (the screens'
/// is see-through, `FullScreenTitleBar`) and covers the title row, copies and all, under the menu bar, so one set shows
/// either way (without them it would come down empty while the controls show). The copies come as the window starts
/// into full screen, under the title bar's own, so the buttons stay through AppKit's transition; they go once the
/// window is out, where the title bar's own sit in the same place: leaving shows no jump.
///
/// It also tells the player when the window enters or leaves full screen, whoever asked (the green button, the View
/// menu, the player's own button), so the store's keymap and full-screen button follow, and where the pointer goes
/// when it leaves the player's views for something that isn't them. Out of the window's frame, the pointer left the
/// player. Still over the window, it is under a window of its own: the app's (a button's tooltip, the zoom button's
/// menu) belong to the controls the pointer was on, so nothing changes; another app's (the menu bar that comes down in
/// full screen) are no part of the controls, which stay and hide on their timer as at rest. A menu AppKit tracks (the
/// controls' menus) is the exception: AppKit reports the pointer leaving the player's area for it only once it has
/// closed, the pointer still where the pick left it, out of the window's frame when the menu hung below the window.
/// The pointer hasn't left the player then, the menu took it there: it is off the controls, which stay up on their
/// timer, so a pick shows in them wherever the menu hung.
struct PlayerWindowChrome: NSViewRepresentable {
    let controlsVisible: Bool
    let onFullscreenChange: (Bool) -> Void
    /// The copies of the window's buttons from the moment the window starts into full screen until it's out, else nil.
    let onWindowButtons: (PlayerWindowButtons?) -> Void
    /// The pointer out of the window's frame.
    let onPointerExit: () -> Void
    /// The pointer moving over the player, over the controls or not; also off the controls but not out of the player:
    /// under another app's window over the window, or where a menu that closed left it. SwiftUI's hover can't tell the
    /// moves: it ends as the pointer hides with the controls (`NSCursor.setHiddenUntilMouseMoves`) and reports none of
    /// the moves after.
    let onPointerMove: () -> Void

    func makeNSView(context: Context) -> ChromeView {
        let view = ChromeView()
        view.onFullscreenChange = onFullscreenChange
        view.onWindowButtons = onWindowButtons
        view.onPointerExit = onPointerExit
        view.onPointerMove = onPointerMove
        return view
    }

    func updateNSView(_ view: ChromeView, context: Context) {
        view.onFullscreenChange = onFullscreenChange
        view.onWindowButtons = onWindowButtons
        view.onPointerExit = onPointerExit
        view.onPointerMove = onPointerMove
        view.controlsVisible = controlsVisible
    }

    static func dismantleNSView(_ view: ChromeView, coordinator: ()) {
        view.restore()
    }

    final class ChromeView: NSView {
        var onFullscreenChange: ((Bool) -> Void)?
        var onWindowButtons: ((PlayerWindowButtons?) -> Void)?
        var onPointerExit: (() -> Void)?
        var onPointerMove: (() -> Void)?
        var controlsVisible = true {
            didSet { if controlsVisible != oldValue { updateTitleBarButtons() } }
        }

        private static let kinds: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

        private weak var styled: NSWindow?
        private var saved: (
            titleVisibility: NSWindow.TitleVisibility, transparent: Bool, fullSizeContent: Bool, toolbar: Bool?,
            fullScreenTransparent: Bool?
        )?
        private var observers: [NSObjectProtocol] = []
        /// The title bar's own buttons, taken before there are copies: while the copies are in the window,
        /// `standardWindowButton` returns them instead.
        private var titleBarButtons: [NSButton] = []
        /// The copies, from the moment the window starts into full screen until it is out of it.
        private var copies: PlayerWindowButtons?
        private var phase = Phase.window
        /// Where the pointer was when the app's last menu closed, until the next exit (`mouseExited`).
        private var menuLeftPointer: NSPoint?
        /// AppKit's full-screen title bar windows while the window is full screen (`passClicksUnderTheTitleBar`), with
        /// what tells their moves and fades.
        private var titleBarWindows: [NSWindow] = []
        private var titleBarWindowMoves: [NSObjectProtocol] = []
        private var titleBarWindowFades: [NSKeyValueObservation] = []
        /// The window's title shown again while the player is up: SwiftUI shows it for the screen under the player as
        /// that screen's title comes back (Watch Together's room past its lobby), over the player's own title row.
        private var titleShown: NSKeyValueObservation?

        /// The window in and out of full screen, as its notifications tell.
        private enum Phase {
            case window, entering, fullScreen, leaving
        }

        // Clicks belong to the player above.
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if trackingAreas.isEmpty {
                // The player's whole area, which lies under the whole window, the title bar included.
                let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect]
                addTrackingArea(NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil))
            }
            if let window { style(window) } else { restore() }
        }

        // The tracking area's own events stay here: the responder chain above is SwiftUI's, with tracking of its own.
        override func mouseEntered(with event: NSEvent) {}

        override func mouseMoved(with event: NSEvent) {
            onPointerMove?()
        }

        override func mouseExited(with event: NSEvent) {
            guard let window else { return }
            let location = NSEvent.mouseLocation
            let menuLeftPointer = self.menuLeftPointer
            self.menuLeftPointer = nil
            if location == menuLeftPointer {
                // The exit for a menu that has closed, the pointer not moved since: off the controls.
                onPointerMove?()
                return
            }
            // A pointer location is a pixel's corner, so the frame is taken as `NSMouseInRect` does, its top edge in
            // (the pointer pushed against the screen's top edge in full screen sits on it), unlike `contains`.
            if !NSMouseInRect(location, window.frame, false) {
                onPointerExit?()
            } else if NSApp.window(withWindowNumber: NSWindow.windowNumber(at: location, belowWindowWithWindowNumber: 0)) == nil {
                onPointerMove?()
            }
        }

        private func style(_ window: NSWindow) {
            guard styled !== window else { return }
            restore()
            styled = window
            saved = (
                window.titleVisibility,
                window.titlebarAppearsTransparent,
                window.styleMask.contains(.fullSizeContentView),
                window.toolbar?.isVisible,
                FullScreenTitleBar.isTransparent(window)
            )
            // The toolbar goes (the screens' back button and title under the player); the title bar stays for the
            // window's buttons, without its title, opaque in full screen, where it comes down over the title row.
            window.toolbar?.isVisible = false
            window.titleVisibility = .hidden
            titleShown = window.observe(\.titleVisibility) { [weak self] window, _ in
                MainActor.assumeIsolated {
                    guard let self, window.titleVisibility != .hidden else { return }
                    // Hidden again; what SwiftUI asked for goes back with the rest as the player goes.
                    self.saved?.titleVisibility = window.titleVisibility
                    window.titleVisibility = .hidden
                }
            }
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            FullScreenTitleBar.setTransparent(false, window)
            titleBarButtons = Self.kinds.compactMap { window.standardWindowButton($0) }
            let center = NotificationCenter.default
            let names = [
                NSWindow.willEnterFullScreenNotification, NSWindow.didEnterFullScreenNotification,
                NSWindow.willExitFullScreenNotification, NSWindow.didExitFullScreenNotification,
            ]
            observers = names.map {
                center.addObserver(forName: $0, object: window, queue: .main) { [weak self] notification in
                    let name = notification.name
                    MainActor.assumeIsolated { self?.fullScreenChanged(name) }
                }
            }
            // Any of the app's menus, posted on the main thread: taken as it comes, before the exit AppKit reports
            // after it.
            observers.append(center.addObserver(forName: NSMenu.didEndTrackingNotification, object: nil, queue: nil) { [weak self] _ in
                MainActor.assumeIsolated { self?.menuLeftPointer = NSEvent.mouseLocation }
            })
            // Zoomed (maximized) or not: the buttons stay with a zoomed window (`updateTitleBarButtons`).
            observers.append(center.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.updateTitleBarButtons() }
            })
            phase = window.styleMask.contains(.fullScreen) ? .fullScreen : .window
            reportFullscreen()
            if phase == .fullScreen {
                showCopies()
                passClicksUnderTheTitleBar()
            }
            updateTitleBarButtons()
        }

        /// Hands the window back as it was.
        func restore() {
            observers.forEach(NotificationCenter.default.removeObserver)
            observers = []
            titleShown = nil
            releaseTitleBarWindows()
            if let copies {
                copies.view.removeFromSuperview()
                self.copies = nil
                publishCopies()
            }
            phase = .window
            guard let window = styled, let saved else { return }
            titleBarButtons.forEach { $0.isHidden = false }
            titleBarButtons = []
            window.titleVisibility = saved.titleVisibility
            window.titlebarAppearsTransparent = saved.transparent
            if !saved.fullSizeContent { window.styleMask.remove(.fullSizeContentView) }
            if let toolbar = saved.toolbar { window.toolbar?.isVisible = toolbar }
            if let transparent = saved.fullScreenTransparent { FullScreenTitleBar.setTransparent(transparent, window) }
            styled = nil
            self.saved = nil
        }

        private func reportFullscreen() {
            guard let window = styled else { return }
            onFullscreenChange?(window.styleMask.contains(.fullScreen))
        }

        private func fullScreenChanged(_ name: NSNotification.Name) {
            switch name {
            case NSWindow.willEnterFullScreenNotification:
                phase = .entering
                showCopies()
            case NSWindow.didEnterFullScreenNotification:
                phase = .fullScreen
                reportFullscreen()
                showCopies()
                passClicksUnderTheTitleBar()
            case NSWindow.willExitFullScreenNotification:
                phase = .leaving
            default:
                phase = .window
                releaseTitleBarWindows()
                // Gone in the same pass as the title bar's own come back in their place.
                copies?.view.removeFromSuperview()
                copies = nil
                publishCopies()
                reportFullscreen()
                // Taken again, should AppKit have made new ones for the window.
                if let window = styled { titleBarButtons = Self.kinds.compactMap { window.standardWindowButton($0) } }
            }
            updateTitleBarButtons()
        }

        /// In a window, and on the way into full screen (the copies under them), the title bar's buttons come and go
        /// with the controls, and stay while the window is zoomed (maximized). In full screen they stay with the title
        /// bar, which shows only when it comes down; on the way out the copies alone, until the window is out.
        private func updateTitleBarButtons() {
            let hidden = switch phase {
            case .window, .entering: !controlsVisible && styled?.isZoomed != true
            case .fullScreen: false
            case .leaving: copies != nil
            }
            for button in titleBarButtons where button.isHidden != hidden { button.isHidden = hidden }
        }

        /// In full screen AppKit keeps the title bar in a window of its own (`NSToolbarFullScreenWindow`) that comes down
        /// under the menu bar when the pointer reaches the top edge. When the window went full screen with its toolbar
        /// (the screens', which hides under the player; the player opened in full screen, or the toolbar hidden but
        /// there as the window went in), that window stays over the top of the window while up, see-through, and takes
        /// every click there, the player's title row's included. So while it isn't down under the menu bar and faded in
        /// (`FullScreenTitleBarPlacement`), it lets clicks through to the player.
        private func passClicksUnderTheTitleBar() {
            guard let kind = NSClassFromString("NSToolbarFullScreenWindow") else { return }
            let center = NotificationCenter.default
            for titleBar in NSApp.windows where titleBar.isKind(of: kind) && !titleBarWindows.contains(titleBar) {
                titleBarWindows.append(titleBar)
                titleBarWindowMoves.append(center.addObserver(forName: NSWindow.didMoveNotification, object: titleBar, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.updateTitleBarWindows() }
                })
                titleBarWindowFades.append(titleBar.observe(\.alphaValue) { [weak self] _, _ in
                    MainActor.assumeIsolated { self?.updateTitleBarWindows() }
                })
            }
            updateTitleBarWindows()
        }

        private func updateTitleBarWindows() {
            guard let window = styled else { return }
            for titleBar in titleBarWindows {
                let down = FullScreenTitleBarPlacement.isDown(titleBar: titleBar.frame, alpha: titleBar.alphaValue, window: window.frame)
                if titleBar.ignoresMouseEvents == down { titleBar.ignoresMouseEvents = !down }
            }
        }

        private func releaseTitleBarWindows() {
            titleBarWindowMoves.forEach(NotificationCenter.default.removeObserver)
            titleBarWindowMoves = []
            titleBarWindowFades = []
            titleBarWindows.forEach { $0.ignoresMouseEvents = false }
            titleBarWindows = []
        }

        /// Copies of the title bar's buttons where it has them: in the window as it starts into full screen, or (the
        /// player opened in full screen) in the full-screen title bar, which has them in the same place.
        private func showCopies() {
            guard copies == nil, let window = styled, titleBarButtons.count == Self.kinds.count,
                let titleBar = titleBarButtons[0].superview
            else { return }
            let buttons = Self.kinds.compactMap { NSWindow.standardWindowButton($0, for: window.styleMask) }
            guard buttons.count == Self.kinds.count else { return }
            buttons[1].isEnabled = false
            let close = titleBarButtons[0]
            let own = close.convert(close.bounds, to: titleBar)
            let spacing = titleBarButtons[1].frame.minX - close.frame.minX
            let size = buttons[0].frame.size
            let view = NSView(frame: NSRect(x: 0, y: 0, width: 2 * spacing + size.width, height: size.height))
            for (index, button) in buttons.enumerated() {
                button.setFrameOrigin(NSPoint(x: CGFloat(index) * spacing, y: 0))
                view.addSubview(button)
            }
            let top = titleBar.isFlipped ? own.minY : titleBar.bounds.height - own.maxY
            copies = PlayerWindowButtons(
                view: view,
                origin: CGPoint(x: close.convert(close.bounds, to: nil).minX, y: top + (own.height - size.height) / 2),
                rowHeight: titleBar.bounds.height
            )
            publishCopies()
        }

        /// The copies go to the player's title row on the next pass: this can run in the middle of SwiftUI's update
        /// (the view moving to its window).
        private func publishCopies() {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.onWindowButtons?(self.copies)
            }
        }
    }
}

/// The copies of the window's buttons from the moment the window starts into full screen until it's out
/// (`PlayerWindowChrome`), for the player's title row to host (`PlayerWindowButtonsHost`).
struct PlayerWindowButtons: Equatable {
    /// Close, minimize and zoom, laid out side by side.
    let view: NSView
    /// Where `view` goes: from the window's leading edge and its top.
    let origin: CGPoint
    /// The title bar's height, which the title row keeps in full screen.
    let rowHeight: CGFloat

    /// A title bar's height without a toolbar: the title row's in full screen should the copies not be there yet.
    @MainActor static var titleBarHeight: CGFloat { NSWindow.frameRect(forContentRect: .zero, styleMask: .titled).height }
}

/// Hosts `PlayerWindowButtons`' view, at its size. A host on its way out (the controls fading) gives the view up to
/// the next one.
struct PlayerWindowButtonsHost: NSViewRepresentable {
    let buttons: PlayerWindowButtons

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ host: NSView, context: Context) {
        guard buttons.view.superview !== host else { return }
        buttons.view.setFrameOrigin(.zero)
        host.addSubview(buttons.view)
    }
}

extension EnvironmentValues {
    /// The window's buttons for the player's title row in full screen (`PlayerWindowChrome`).
    @Entry var playerWindowButtons: PlayerWindowButtons? = nil
}
