#if os(iOS)
import UIKit

/// A UIKit button whose system menu (Liquid Glass on 26) is its primary action: the player's track and options menus
/// (`NativeMenuButton`) and iPhone's More menu (`MoreMenuAnchor`). UIKit tells a button when its menu shows and goes,
/// which a SwiftUI `Menu` doesn't: `onOpen` and `onClose` hear it, and `runAfterClose` holds what an entry opens (a
/// popover, a sheet) until the menu has gone.
class SystemMenuButton: UIButton {
    var onOpen: (() -> Void)?
    var onClose: (() -> Void)?
    private(set) var menuShown = false
    /// The menu's dismissal is under way: its end runs what waits (`flushAfterClose`).
    private var closing = false
    /// What runs once the menu has gone (an entry that opens a popover).
    private var afterClose: (() -> Void)?

    /// Runs `action` once the menu has gone. UIKit doesn't promise whether an entry's handler runs before the menu
    /// starts to go, during its dismissal or after it: while the menu shows or goes, its dismissal's end runs
    /// `action`; once it has gone, it runs now.
    func runAfterClose(_ action: @escaping () -> Void) {
        afterClose = action
        if !menuShown, !closing { flushAfterClose() }
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willDisplayMenuFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        // No first responder while the menu shows: with one (the player's key view, `HardwareKeys`, or before it
        // SwiftUI's hosting view), UIKit brings the software keyboard up with the menu when no hardware keyboard
        // is attached. The key view takes first responder back once the menu has gone.
        _ = UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: self, for: nil)
        super.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)
        menuShown = true
        onOpen?()
    }

    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        willEndFor configuration: UIContextMenuConfiguration,
        animator: (any UIContextMenuInteractionAnimating)?
    ) {
        super.contextMenuInteraction(interaction, willEndFor: configuration, animator: animator)
        menuShown = false
        closing = true
        onClose?()
        if let animator {
            animator.addCompletion { [weak self] in self?.closed() }
        } else {
            DispatchQueue.main.async { [weak self] in self?.closed() }
        }
    }

    private func closed() {
        closing = false
        flushAfterClose()
    }

    private func flushAfterClose() {
        guard !menuShown, let action = afterClose else { return }
        afterClose = nil
        action()
    }
}
#endif
