import CoreGraphics

/// Where AppKit's full-screen title bar window (`NSToolbarFullScreenWindow`) is: resting over the top of the
/// full-screen window, see-through, or down under the menu bar, which the pointer at the screen's top edge brings. It
/// rests with its top at the full-screen window's top and comes down below it. The full-screen window's top is the
/// screen's top, except on a screen with a camera housing, where the window ends below the housing (its height varies
/// with the Mac and the display's scaling) and the resting title bar with it: its top below the screen's is no sign it
/// came down. So the window's own frame tells, whatever the housing.
enum FullScreenTitleBarPlacement {
    /// Whether the title bar window (`titleBar`, at `alpha`) is down over the full-screen window whose frame is `window`.
    static func isDown(titleBar: CGRect, alpha: CGFloat, window: CGRect) -> Bool {
        alpha > 0 && titleBar.maxY < window.maxY
    }
}
