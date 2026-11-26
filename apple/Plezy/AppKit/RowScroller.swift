import AppKit
import SwiftUI

/// The AppKit scroll view under a row that scrolls sideways (`SideScroll`), scrolled to an offset as SwiftUI can't
/// before macOS 15: a page at a time by the row's buttons, along with a drag, and by a mouse's wheel. A row finds its
/// scroll view through `RowScrollerAnchor` in its content.
@MainActor
final class RowScroller {
    fileprivate weak var scrollView: NSScrollView?
    /// The offset a drag started from.
    private var dragFrom: CGFloat?
    private var monitor: Any?

    /// Scrolls a page, the visible width `less` the given points (at least half of it), towards the end (`forward`) or
    /// back towards the start, animated.
    func page(forward: Bool, less: CGFloat) {
        guard let clip = scrollView?.contentView else { return }
        // The clip reaches under the sidebar, its content inset from there.
        let width = clip.bounds.width - clip.contentInsets.left - clip.contentInsets.right
        let step = max(width - less, width / 2)
        scroll(to: clip.bounds.origin.x + (forward ? step : -step), duration: Self.pageDuration)
    }

    /// The row follows a drag `translation` points along it from where the drag started.
    func drag(by translation: CGFloat) {
        guard let clip = scrollView?.contentView else { return }
        let from = dragFrom ?? clip.bounds.origin.x
        dragFrom = from
        scroll(to: from - translation, duration: 0)
    }

    /// A drag let go `translation` points along the row, its speed carrying it to `flingTo`: the row glides on there.
    func endDrag(by translation: CGFloat, flingTo: CGFloat) {
        defer { dragFrom = nil }
        guard let from = dragFrom, abs(flingTo - translation) > 1 else { return }
        scroll(to: from - flingTo, duration: Self.flingDuration)
    }

    /// Takes a mouse's wheel turned over the row (`over`, its hover) to scroll it along; the pointer leaving it, or
    /// the row going, gives the wheel back to the page.
    func followWheel(_ over: Bool) {
        if over, monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                // On the main thread, before the event goes to its window.
                nonisolated(unsafe) let event = event
                return MainActor.assumeIsolated { self?.wheel(event) ?? false } ? nil : event
            }
        } else if !over, let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    /// A mouse wheel's turn up or down over the row (not a trackpad's or a Magic Mouse's scroll, which have precise
    /// deltas and their own sideways swipe, nor shift and the wheel, which macOS sends sideways already) sent to the row
    /// as the same turn sideways, so it scrolls as the page would by it. Up scrolls back. Nothing at the end it would
    /// scroll towards: the page takes it. True where the row took it.
    private func wheel(_ event: NSEvent) -> Bool {
        guard let scrollView, let window = scrollView.window, event.window === window, !event.hasPreciseScrollingDeltas,
              event.deltaX == 0, event.deltaY != 0,
              scrollView.bounds.contains(scrollView.convert(event.locationInWindow, from: nil)) else { return false }
        let clip = scrollView.contentView
        let (start, end) = range(of: clip)
        let x = clip.bounds.origin.x
        guard event.deltaY > 0 ? x > start + 0.5 : x < end - 0.5, let sideways = Self.sideways(event) else { return false }
        scrollView.scrollWheel(with: sideways)
        return true
    }

    /// `event` with its vertical scroll moved to the horizontal axis.
    private static func sideways(_ event: NSEvent) -> NSEvent? {
        guard let copy = event.cgEvent?.copy() else { return nil }
        let pairs: [(CGEventField, CGEventField)] = [
            (.scrollWheelEventDeltaAxis1, .scrollWheelEventDeltaAxis2),
            (.scrollWheelEventPointDeltaAxis1, .scrollWheelEventPointDeltaAxis2),
        ]
        for (vertical, horizontal) in pairs {
            copy.setIntegerValueField(horizontal, value: copy.getIntegerValueField(vertical))
            copy.setIntegerValueField(vertical, value: 0)
        }
        copy.setDoubleValueField(
            .scrollWheelEventFixedPtDeltaAxis2, value: copy.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        )
        copy.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 0)
        return NSEvent(cgEvent: copy)
    }

    /// Scrolls the row to `x`, kept within its content, over `duration` (0: at once), easing out. A scroll started
    /// meanwhile takes over from wherever this one has come to.
    private func scroll(to x: CGFloat, duration: TimeInterval) {
        guard let scrollView else { return }
        let clip = scrollView.contentView
        let (start, end) = range(of: clip)
        let target = NSPoint(x: min(max(x, start), end), y: clip.bounds.origin.y)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            clip.animator().setBoundsOrigin(target)
        }
        scrollView.reflectScrolledClipView(clip)
    }

    /// The offsets the row scrolls between: its start's and its end's.
    private func range(of clip: NSClipView) -> (CGFloat, CGFloat) {
        let document = clip.documentRect
        let start = document.minX - clip.contentInsets.left
        return (start, max(document.maxX + clip.contentInsets.right - clip.bounds.width, start))
    }

    private static let pageDuration: TimeInterval = 0.35
    private static let flingDuration: TimeInterval = 0.5
}

/// A view of no size in a row's content that hands the row's `RowScroller` the scroll view it is in. It takes no events.
struct RowScrollerAnchor: NSViewRepresentable {
    let scroller: RowScroller

    func makeNSView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.scroller = scroller
        return view
    }

    func updateNSView(_ view: AnchorView, context: Context) {
        view.scroller = scroller
        view.attach()
    }

    final class AnchorView: NSView {
        var scroller: RowScroller?

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            attach()
        }

        func attach() {
            if let scrollView = enclosingScrollView { scroller?.scrollView = scrollView }
        }
    }
}
