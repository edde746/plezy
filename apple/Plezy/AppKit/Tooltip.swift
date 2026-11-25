import AppKit
import SwiftUI

/// AppKit's tooltip over a control (`tooltip(_:)`): how the Mac's controls drawn as a symbol alone show their names.
/// SwiftUI's `.help` misses or strands tooltips in the window's content: none on the player's buttons and its speed
/// menu in their custom styles; on Detail's plain glass buttons (macOS 27) none on Share when the
/// pointer came onto it after resting in the window's middle since the screen opened (5 of 6), none on Share when the
/// pointer came back after resting on it until its tooltip showed (6 of 6), and the library button's tooltip staying up
/// 5 s after the pointer left it (6 of 6). This view's tooltip showed in each of those cases. The window's toolbar
/// items keep `.help`, which shows there (Streams' Refresh, 12 of 12). The text is this view's own `toolTip`, set again
/// only when it changes; the view takes no clicks, hovers or scrolls, which go on to the control.
struct Tooltip: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> TooltipView {
        TooltipView()
    }

    func updateNSView(_ view: TooltipView, context: Context) {
        let tip = text.isEmpty ? nil : text
        if view.toolTip != tip { view.toolTip = tip }
    }

    final class TooltipView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}

extension View {
    /// `text` as the control's tooltip (`Tooltip`, laid over it), none while it is empty. VoiceOver reads the control's
    /// own label, not the tooltip.
    func tooltip(_ text: String) -> some View {
        overlay { Tooltip(text: text).accessibilityHidden(true) }
    }
}
