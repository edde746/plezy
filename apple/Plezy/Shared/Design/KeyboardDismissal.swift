#if os(iOS)
import SwiftUI
import UIKit

extension View {
    /// The keyboard goes away as in the system's apps: on a scroll, and on a tap anywhere off the line of the field being
    /// edited (its clear button and the capsule around it stay with the field), while the tap still acts on what it
    /// lands on: a tap on a result or a row opens it at once. Set once on the window's content (`LaunchView`), it holds
    /// for every screen and sheet in the window: the settings' fields, the watch-together code.
    func dismissesKeyboard() -> some View {
        scrollDismissesKeyboard(.immediately)
            .background(KeyboardDismissalProbe())
    }
}

/// Puts a `KeyboardDismissal`'s tap on the window it is in; it takes no touch of its own.
private struct KeyboardDismissalProbe: UIViewRepresentable {
    func makeUIView(context: Context) -> Probe {
        let probe = Probe()
        probe.isUserInteractionEnabled = false
        return probe
    }

    func updateUIView(_ view: Probe, context: Context) {}

    final class Probe: UIView {
        private let dismissal = KeyboardDismissal()

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            window?.removeGestureRecognizer(dismissal.tap)
            newWindow?.addGestureRecognizer(dismissal.tap)
        }
    }
}

/// A tap on the window that ends the editing of the text field or view being edited. It recognizes beside every other
/// gesture and lets the touches through (`cancelsTouchesInView`), so the control under it acts too, and it takes no
/// touch while nothing is edited: another first responder (the player's key view, which takes a hardware keyboard's
/// keys) keeps its place.
@MainActor
private final class KeyboardDismissal: NSObject, UIGestureRecognizerDelegate {
    let tap = UITapGestureRecognizer()

    /// The text field or view that began editing last.
    private weak var editing: UIView?

    override init() {
        super.init()
        tap.addTarget(self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        tap.delaysTouchesEnded = false
        tap.delegate = self
        for name in [UITextField.textDidBeginEditingNotification, UITextView.textDidBeginEditingNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(beganEditing(_:)), name: name, object: nil)
        }
    }

    @objc private func beganEditing(_ notification: Notification) {
        editing = notification.object as? UIView
    }

    /// Ends the editing once the tap has reached what it landed on: the keyboard going away resizes a sheet and moves
    /// a list's rows, which would cancel a row's tap still on its way (a language added from the languages' search).
    @objc private func endEditing() {
        DispatchQueue.main.async { [weak self] in self?.editing?.resignFirstResponder() }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let editing, editing.isFirstResponder, editing.window === tap.view else { return false }
        // The field's line: its height again above and below its middle, which takes in the capsule around it.
        let line = editing.convert(editing.bounds, to: nil)
        return abs(touch.location(in: nil).y - line.midY) > line.height
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
#endif
