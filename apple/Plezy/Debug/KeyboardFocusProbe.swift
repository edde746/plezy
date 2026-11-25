#if os(macOS)
import AppKit
import SwiftUI

/// Debug builds on the Mac: the element with the keyboard's focus, for the UI tests (`app.keyboardFocus`'s label:
/// `focus=` and its accessibility identifier, else its role, else `none`; prefixed, as a query by identifier matches a
/// label too). XCUITest's `hasKeyboardFocus` can't tell: on macOS 27 every row of the sidebar reports it whatever has
/// focus, and a SwiftUI view made focusable (a card, the player's timeline) never does. The focused element is looked
/// at four times a second, as no state of the app's changes with focus, and the label redrawn only as it changes and
/// twice more after: redrawn four times a second, the probe held the window at its width while it was dragged
/// narrower. The label is read as it redraws, where a focused text field reads as the field, though not at once (on
/// the first redraw after it took focus, as its cell, as everywhere outside a redraw).
struct KeyboardFocusProbe: View {
    @State private var watch = FocusWatch()
    @State private var reads = 0

    var body: some View {
        // Read again with each change of `reads`.
        let _ = reads
        let reading = Self.focused
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: "focus=\(reading)"))
            .accessibilityIdentifier("app.keyboardFocus")
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
                if watch.changed(NSApp.accessibilityFocusedUIElement as AnyObject?) { reads += 1 }
            }
    }

    private static var focused: String {
        guard let element = NSApp.accessibilityFocusedUIElement as? NSObject else { return "none" }
        let id = element.responds(to: NSSelectorFromString("accessibilityIdentifier"))
            ? element.value(forKey: "accessibilityIdentifier") as? String : nil
        if let id, !id.isEmpty { return id }
        let role = element.responds(to: NSSelectorFromString("accessibilityRole")) ? element.value(forKey: "accessibilityRole") as? String : nil
        return role ?? String(describing: type(of: element))
    }

    /// The focused element last looked at, kept outside SwiftUI's state so a look that finds it unchanged redraws nothing.
    private final class FocusWatch {
        private weak var last: AnyObject?
        private var hadOne = false
        private var more = 0

        /// Whether the probe reads again: `element` is another than the one looked at last time, or was one of the
        /// last two times.
        func changed(_ element: AnyObject?) -> Bool {
            if element !== last || (element != nil) != hadOne { more = 3 }
            last = element
            hadOne = element != nil
            guard more > 0 else { return false }
            more -= 1
            return true
        }
    }
}
#endif
