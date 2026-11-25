#if os(macOS)
import SwiftUI
import PlezyKit

/// Settings' Download location row, the Mac's (iPhone and iPad keep downloads in the app's own container): the folder
/// downloads go to (`DownloadLocationModel`) under its title; it opens the location's dialog (`DownloadLocationOverlay`,
/// on the hub). Harness name: `id`.
struct DownloadLocationRow: View {
    let id: String

    @State private var location: StoreObserver<DownloadLocationUiState>
    private let model: DownloadLocationModel

    init(model: DownloadLocationModel, id: String) {
        self.model = model
        self.id = id
        _location = State(initialValue: StoreObserver(model.state))
    }

    var body: some View {
        let state = location.state
        SettingsLinkRow(
            title: state.rowTitle, subtitle: state.rowSubtitle, value: state.rowTrailingValue,
            systemImage: SettingIcon.folder.systemImage, id: id
        ) {
            model.openDialog()
        }
        .task { await location.observe() }
    }
}

/// The download location's dialog and outcome over the settings hub, outside its form: the folder now, Select folder
/// (the folder panel) and, for a custom folder, Reset to default; then "Download location changed" or "Selected folder
/// is not writable" as a toast. Nothing without downloads (`model` nil). Harness names:
/// `settings.downloads.location.<select|reset|cancel>`, `settings.downloads.location.message`.
struct DownloadLocationOverlay: ViewModifier {
    let model: DownloadLocationModel?
    @State private var state: StoreObserver<DownloadLocationUiState>?

    init(model: DownloadLocationModel?) {
        self.model = model
        _state = State(initialValue: model.map { StoreObserver($0.state) })
    }

    func body(content: Content) -> some View {
        let location = state?.state
        content
            .confirmation(
                location.flatMap { state in
                    state.dialogOpen ? Confirmation(
                        title: state.dialogTitle,
                        message: "\(state.description_)\n\n\(state.currentPathLine)",
                        confirmLabel: state.selectLabel,
                        cancelLabel: T.shared.common.cancel,
                        destructive: false,
                        confirmId: "settings.downloads.location.select",
                        cancelId: "settings.downloads.location.cancel",
                        alternative: state.offersReset ? (state.resetLabel, "settings.downloads.location.reset") : nil
                    ) : nil
                },
                onConfirm: { model?.selectFolder() },
                onAlternative: { model?.reset() },
                onCancel: { model?.closeDialog() }
            )
            .toast(
                location?.message?.message, id: "settings.downloads.location.message",
                isError: location?.message?.isError == true
            ) { model?.messageShown() }
            .task { await state?.observe() }
    }
}
#endif
