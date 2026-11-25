import SwiftUI
import PlezyKit

/// A question the store words before a change it can't undo (ending a watch-together room, deleting from the server),
/// with the identifiers of its answers: confirm and cancel, and where the question offers one, an `alternative` before
/// confirm that is never destructive, or a `toggle`, the confirm that also does more. An empty `message` shows the title
/// alone.
struct Confirmation: Identifiable {
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    var destructive = true
    let confirmId: String
    let cancelId: String
    var alternative: (label: String, id: String)?
    /// What a delete takes with it, said after the message.
    var warning: String?
    /// The confirm that also does what the store's switch says (delete the downloads too), after the plain confirm.
    var toggle: ConfirmationToggle?

    var id: String { "\(confirmId)\u{0}\(title)" }
}

/// A confirmation's second confirm: its label, the line that says what leaving it out keeps (after the message), and
/// its identifier.
struct ConfirmationToggle {
    let label: String
    let description: String
    let id: String
}

extension View {
    /// Asks `confirmation` while it is set, in the system alert: its `alternative` (`onAlternative`) first where it has
    /// one, then confirm (`onConfirm`), its `toggle` (`onToggledConfirm`) where it has one, and Cancel. Dismissing it
    /// (Cancel, the remote's Menu, Escape) is `onCancel`; a button's answer runs once, and never a cancel after it.
    func confirmation(
        _ confirmation: Confirmation?,
        onConfirm: @escaping () -> Void,
        onAlternative: @escaping () -> Void = {},
        onToggledConfirm: @escaping () -> Void = {},
        onCancel: @escaping () -> Void
    ) -> some View {
        modifier(ConfirmationAlert(
            confirmation: confirmation,
            onConfirm: onConfirm, onAlternative: onAlternative, onToggledConfirm: onToggledConfirm, onCancel: onCancel
        ))
    }

    /// Asks for a line of text while `isPresented` (a new playlist's name, what to search on a host), in the system
    /// alert: `title`, `message` where given, the field (`placeholder` in it, empty as it shows, identified
    /// `<id>.field`), then `confirmLabel` (`<id>.ok`) and Cancel (`<id>.cancel`). Confirm (or Return in the field)
    /// runs `onSubmit` with the text; Cancel, Escape and the remote's Menu run `onCancel`, never after a submit.
    func textPrompt(
        _ title: String,
        isPresented: Bool,
        message: String? = nil,
        placeholder: String,
        confirmLabel: String,
        id: String,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        modifier(TextPrompt(
            title: title, isPresented: isPresented, message: message, placeholder: placeholder, confirmLabel: confirmLabel, id: id,
            onSubmit: onSubmit, onCancel: onCancel
        ))
    }
}

private struct ConfirmationAlert: ViewModifier {
    let confirmation: Confirmation?
    let onConfirm: () -> Void
    let onAlternative: () -> Void
    let onToggledConfirm: () -> Void
    let onCancel: () -> Void

    /// Answered since the alert showed (a button, or a cancel already reported): a later closing is no cancel.
    @State private var answered = false

    func body(content: Content) -> some View {
        content.alert(
            confirmation?.title ?? "",
            isPresented: Binding(get: { confirmation != nil }, set: { shown in
                guard !shown else { return }
                // The system closes the alert before or after it runs the button's action, and may report its closing
                // twice: past both, once.
                Task { @MainActor in
                    if !answered { answer(onCancel) }
                }
            }),
            presenting: confirmation
        ) { confirmation in
            if let alternative = confirmation.alternative {
                Button(alternative.label) { answer(onAlternative) }
                    .accessibilityIdentifier(alternative.id)
            }
            #if os(macOS)
            // The Mac's alert draws a destructive button's red label on a red tint, which doesn't read (least of all in
            // a dark theme): there a destructive question keeps its confirm plain and makes Cancel the default button,
            // so Return keeps what the question would remove.
            let role: ButtonRole? = nil
            #else
            let role: ButtonRole? = confirmation.destructive ? .destructive : nil
            #endif
            Button(confirmation.confirmLabel, role: role) { answer(onConfirm) }
                .accessibilityIdentifier(confirmation.confirmId)
            if let toggle = confirmation.toggle {
                Button(toggle.label, role: role) { answer(onToggledConfirm) }
                    .accessibilityIdentifier(toggle.id)
            }
            Button(confirmation.cancelLabel, role: .cancel) { answer(onCancel) }
                #if os(macOS)
                .keyboardShortcut(confirmation.destructive ? .defaultAction : nil)
                #endif
                .accessibilityIdentifier(confirmation.cancelId)
        } message: { confirmation in
            let message = [confirmation.message, confirmation.warning ?? "", confirmation.toggle?.description ?? ""]
                .filter { !$0.isEmpty }.joined(separator: "\n\n")
            if !message.isEmpty { Text(message) }
        }
        .onChange(of: confirmation?.id) { _, shown in
            if shown != nil { answered = false }
        }
    }

    private func answer(_ action: () -> Void) {
        answered = true
        action()
    }
}

private struct TextPrompt: ViewModifier {
    let title: String
    let isPresented: Bool
    let message: String?
    let placeholder: String
    let confirmLabel: String
    let id: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    /// Submitted since the alert showed: its closing is no cancel.
    @State private var submitted = false

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: Binding(get: { isPresented }, set: { shown in
                guard !shown else { return }
                // The system closes the alert before or after it runs the button's action: past both.
                Task { @MainActor in
                    if !submitted { onCancel() }
                    submitted = false
                }
            })) {
                TextField(placeholder, text: $text)
                    .onSubmit(submit)
                    .accessibilityIdentifier("\(id).field")
                Button(confirmLabel, action: submit)
                    .accessibilityIdentifier("\(id).ok")
                Button(T.shared.common.cancel, role: .cancel) {}
                    .accessibilityIdentifier("\(id).cancel")
            } message: {
                if let message { Text(message) }
            }
            .onChange(of: isPresented) { _, shown in
                guard shown else { return }
                text = ""
                submitted = false
            }
    }

    private func submit() {
        guard !submitted else { return }
        submitted = true
        onSubmit(text)
    }
}
