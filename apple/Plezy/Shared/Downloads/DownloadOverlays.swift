#if !os(tvOS)
import SwiftUI
import PlezyKit

extension View {
    /// The download flows' dialogs over the app, wherever they are asked from (the Downloads screen, a detail screen,
    /// a menu): the open question of `downloads.dialogs` and the progress of a deletion that takes a while
    /// (`downloads.deletion`). Placed on the shell, and on iPhone's Now Playing (a full-screen cover, which the shell
    /// can't present over: the shell's then `presenting` false). Nothing without downloads.
    func downloadOverlays(_ downloads: AppDownloads?, presenting: Bool = true) -> some View {
        modifier(DownloadOverlays(downloads: downloads, presenting: presenting))
    }
}

/// A download dialog (`DownloadDialog`) answered through `DownloadDialogs`, as the system asks:
/// - Options: an action sheet (`entriesDialog`) of its rows; with its switch (Include Specials), a form of the switch
///   over the rows (`DownloadDialogForm`);
/// - Count: a form of the number field, the reason a number was refused under it, and the confirm button;
/// - Confirm: the system alert of the message, Cancel (or its own label: the cancelled download's Delete) and the
///   confirm button, destructive when it removes something; with its switch (Delete synced downloads), a form.
///
/// A deletion still running after half a second (`SmartDeletion`) shows in a `progressSheet` nothing dismisses: a
/// spinner and "Deleting…" until the deletion reports its progress, then "Deleting <title> (2 of 5)", a bar, the
/// percent and the step it is on.
///
/// Closing a dialog without an answer is `cancel`. Accessibility identifiers: `downloads.dialog` (the forms), the rows
/// `downloads.dialog.option.<index>`, `downloads.dialog.switch`, `downloads.dialog.count`, `downloads.dialog.confirm`,
/// `downloads.dialog.cancel`, `downloads.deleting`.
private struct DownloadOverlays: ViewModifier {
    @State private var dialog: StoreObserver<DownloadDialog?>?
    @State private var deletion: StoreObserver<DeletionDialog?>?
    private let dialogs: DownloadDialogs?
    private let presenting: Bool

    init(downloads: AppDownloads?, presenting: Bool) {
        dialogs = downloads?.dialogs
        self.presenting = presenting
        _dialog = State(initialValue: downloads.map { StoreObserver($0.dialogs.dialog) })
        _deletion = State(initialValue: downloads.map { StoreObserver($0.deletion.dialog) })
    }

    func body(content: Content) -> some View {
        let open = presenting ? dialog?.state.map { onEnum(of: $0) } : nil
        let deleting = presenting ? deletion?.state : nil
        let cancel: () -> Void = { dialogs?.cancel() }
        let options: DownloadDialogOptions? = if case .options(let options) = open, options.toggle == nil { options } else { nil }
        let confirm: DownloadDialogConfirm? = if case .confirm(let confirm) = open, confirm.`switch` == nil { confirm } else { nil }
        let form = presenting && options == nil && confirm == nil ? dialog?.state.map(FormDialog.init) : nil
        content
            .entriesDialog(
                options?.title,
                isPresented: options != nil,
                entries: (options?.options ?? []).enumerated().map { index, option in
                    // A row's detail (a quality's estimated size) follows its label: an action sheet's rows are one line.
                    let label = [option.label, option.detail].compactMap { $0 }.joined(separator: T.shared.detail.listSeparator)
                    return ItemMenuEntry(label: label, systemImage: option.icon.systemImage, id: "downloads.dialog.option.\(index)") {
                        dialogs?.choose(index: Int32(index))
                    }
                },
                probe: "downloads.dialog.option",
                onCancel: cancel
            )
            .confirmation(
                confirm.map {
                    Confirmation(
                        title: $0.title, message: $0.message, confirmLabel: $0.confirmLabel, cancelLabel: $0.cancelLabel,
                        destructive: $0.destructive, confirmId: "downloads.dialog.confirm", cancelId: "downloads.dialog.cancel"
                    )
                },
                onConfirm: { dialogs?.confirm() },
                onCancel: cancel
            )
            .appSheet(item: form, onDismiss: cancel) { form in
                if let dialogs { DownloadDialogForm(dialog: form.dialog, dialogs: dialogs) }
            }
            .progressSheet(deleting?.label, isPresented: deleting != nil, id: "downloads.deleting", cancel: nil) {
                if let deleting { DeletionProgress(deletion: deleting) }
            }
            .task { await dialog?.observe() }
            .task { await deletion?.observe() }
    }
}

/// A dialog the form shows, compared as the store's values are (a refused number's new reason is a new dialog).
private struct FormDialog: Equatable {
    let dialog: any DownloadDialog

    static func == (lhs: FormDialog, rhs: FormDialog) -> Bool {
        (lhs.dialog as AnyObject).isEqual(rhs.dialog)
    }
}

/// A download dialog with a switch, or a number to type, as a form: the switch (its symbol, label and subtitle) over the
/// options' rows or the confirm's message; the number field with the reason a number was refused. Cancel and the
/// confirm button in the bar (tvOS has no downloads).
private struct DownloadDialogForm: View {
    let dialog: DownloadDialog
    let dialogs: DownloadDialogs

    @State private var count = ""
    @FocusState private var countFocused: Bool

    var body: some View {
        let kind = onEnum(of: dialog)
        SheetPage(id: "downloads.dialog", title: dialog.title, cancel: cancelAction, confirm: confirmAction) {
            Form {
                switch kind {
                case .options(let options):
                    if let toggle = options.toggle { switchRow(toggle) }
                    Section {
                        ForEach(Array(options.options.enumerated()), id: \.offset) { index, option in
                            Button { dialogs.choose(index: Int32(index)) } label: {
                                Label(option.label, systemImage: option.icon.systemImage)
                            }
                            .accessibilityIdentifier("downloads.dialog.option.\(index)")
                        }
                    }
                case .count(let entry):
                    Section {
                        TextField(entry.hint, text: $count)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .focused($countFocused)
                            .onSubmit { dialogs.submitCount(text: count) }
                            .accessibilityIdentifier("downloads.dialog.count")
                            .formFieldRow()
                    } footer: {
                        if let error = entry.error { ErrorLine(text: error) }
                    }
                case .confirm(let confirm):
                    if !confirm.message.isEmpty {
                        Section { Text(confirm.message) }
                    }
                    if let toggle = confirm.`switch` { switchRow(toggle) }
                }
            }
            .settingsForm()
        }
        .task { countFocused = true }
    }

    private var cancelAction: SheetAction {
        let kind = onEnum(of: dialog)
        let label = if case .confirm(let confirm) = kind { confirm.cancelLabel } else { T.shared.common.cancel }
        return SheetAction(title: label, id: "downloads.dialog.cancel") { dialogs.cancel() }
    }

    private var confirmAction: SheetAction? {
        switch onEnum(of: dialog) {
        case .options: nil
        case .count(let entry): SheetAction(title: entry.confirmLabel, id: "downloads.dialog.confirm") { dialogs.submitCount(text: count) }
        case .confirm(let confirm):
            SheetAction(title: confirm.confirmLabel, id: "downloads.dialog.confirm", role: confirm.destructive ? .destructive : nil) {
                dialogs.confirm()
            }
        }
    }

    private func switchRow(_ toggle: DownloadDialogSwitch) -> some View {
        Toggle(isOn: Binding(get: { toggle.value }, set: { dialogs.setToggle(value: $0) })) {
            Label {
                Text(toggle.label)
                if let subtitle = toggle.subtitle { Text(subtitle) }
            } icon: {
                if let icon = toggle.icon { Image(systemName: icon.systemImage) }
            }
        }
        .accessibilityIdentifier("downloads.dialog.switch")
    }
}

/// A deletion's progress: a spinner until it reports how far it is, then a bar, the step it is on and the percent.
private struct DeletionProgress: View {
    let deletion: DeletionDialog

    var body: some View {
        if let fraction = deletion.fraction {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: Double(truncating: fraction))
                HStack {
                    if let operation = deletion.operation {
                        Text(operation).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if let percent = deletion.percentLabel {
                        Text(percent)
                    }
                }
                .font(.footnote)
                .mutedForeground()
            }
        } else {
            ProgressView()
        }
    }
}
#endif
