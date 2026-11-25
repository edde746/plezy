import AppKit
import SwiftUI

/// The scroll wheel over the player's video (macOS): `onWheel` gets its notches scrolled up, which the player sends the
/// store as pixels (`InputEvent.Wheel`, 20 a notch: a point of volume a notch, up louder), as the Compose desktop player does on
/// Windows and Linux. A mouse wheel's click is one notch however fast it turned (macOS accelerates its delta); a
/// trackpad's or Magic Mouse's scroll is a notch per 100 points, as mpv's own Mac input counts it (`deltaY` × 0.1), its
/// momentum after the fingers lift left out. The direction is the device's, as a mouse wheel's on Windows and Linux:
/// the wheel turned away, or two fingers moved up, is louder, also where natural scrolling (the Mac's default) turns
/// the event's delta round. Over the controls the wheel does nothing.
///
/// SwiftUI has no scroll-wheel event, and an AppKit view that took the wheel would sit in the video's way for its
/// clicks and hovers. So this view takes no events: it watches the app's scroll events in its window while the pointer
/// is on the video (`onVideo`, the video's hover) and keeps those the store used.
struct PlayerScrollWheel: NSViewRepresentable {
    let onVideo: Bool
    /// Notches scrolled up; whether the store used them.
    let onWheel: (Double) -> Bool

    func makeNSView(context: Context) -> WheelView {
        let view = WheelView()
        updateNSView(view, context: context)
        return view
    }

    func updateNSView(_ view: WheelView, context: Context) {
        view.onVideo = onVideo
        view.onWheel = onWheel
    }

    static func dismantleNSView(_ view: WheelView, coordinator: ()) {
        view.stopWatching()
    }

    final class WheelView: NSView {
        var onVideo = false
        var onWheel: ((Double) -> Bool)?
        private var monitor: Any?

        // Clicks and hovers belong to the video's layer above.
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stopWatching()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                // On the main thread, before the event goes to its window.
                let windowNumber = event.windowNumber
                let notches = WheelView.notches(event)
                let used = MainActor.assumeIsolated { self?.wheel(notches, inWindow: windowNumber) ?? false }
                return used ? nil : event
            }
        }

        func stopWatching() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        private func wheel(_ notches: Double?, inWindow windowNumber: Int) -> Bool {
            guard onVideo, let notches, let window, window.windowNumber == windowNumber else { return false }
            return onWheel?(notches) ?? false
        }

        /// A scroll event's notches scrolled up on the device (natural scrolling undone), nil for none: a horizontal
        /// scroll, momentum, a gesture's start.
        nonisolated static func notches(_ event: NSEvent) -> Double? {
            guard event.momentumPhase.isEmpty, event.deltaY != 0 else { return nil }
            let up = event.isDirectionInvertedFromDevice ? -event.deltaY : event.deltaY
            if event.hasPreciseScrollingDeltas { return Double(up) * 0.1 }
            return up > 0 ? 1 : -1
        }
    }
}
