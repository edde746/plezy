import SwiftUI
import PlezyKit

/// Manage libraries (`SettingsPageId.MANAGE_LIBRARIES`) over the Libraries destination's store (`AppSession.libraries`):
/// every library in the Libraries order, each a switch for whether it shows, its server under its name where they come
/// from several. On iPhone, iPad and the Mac the list's own drag reorders it (`onMove`); every row's context menu
/// (a long press, a right click, a held Select on Apple TV) has Move up and Move down where the library can go, then,
/// where the user administers its server, the admin actions, each asked first in an alert. Each change goes to the store
/// at once.
///
/// Accessibility identifiers: `settings.libraries.row.<i>` (the switch), the menu's `.up`, `.down` and `.<action>`
/// (`scan`, `analyze`, `refresh_metadata`, `empty_trash`).
struct ManageLibrariesScreen: View {
    let app: AppModel

    @State private var model: StoreModel<LibrariesScreenStore, LibrariesUiState>?
    @State private var asking: (library: MediaLibrary, action: LibraryAdminAction)?

    init(app: AppModel) {
        self.app = app
        _model = State(initialValue: StoreModel(app.session.libraries()) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let libraries = state.libraries
            let multiple = Set(libraries.compactMap(\.serverId)).count > 1
            SettingsPageFrame(title: T.shared.libraries.manageLibraries, id: SettingsPageId.manageLibraries.probe) {
                Form {
                    Section {
                        ForEach(Array(libraries.enumerated()), id: \.element.globalKey) { index, library in
                            let id = "settings.libraries.row.\(index)"
                            SettingsToggleRow(
                                title: library.title,
                                subtitle: multiple ? library.serverName : nil,
                                checked: !state.hiddenKeys.contains(library.globalKey),
                                id: id
                            ) { model.store.setHidden(globalKey: library.globalKey, hide: !$0) }
                            .contextMenu { menu(model.store, library, index: index, count: libraries.count, id: id) }
                        }
                        #if !os(tvOS)
                        .onMove { from, to in
                            guard let source = from.first else { return }
                            // `to` counts the list with the row still in place; the store takes the index it ends at.
                            model.store.moveLibrary(globalKey: libraries[source].globalKey, toIndex: Int32(to > source ? to - 1 : to))
                        }
                        #endif
                    } footer: {
                        #if !os(tvOS)
                        if libraries.count > 1 { Text(T.shared.libraries.dragToReorder) }
                        #endif
                    }
                }
                .settingsForm()
            }
            .confirmation(
                asking.map { ask in
                    Confirmation(
                        title: ask.action.confirmTitle, message: ask.action.confirmMessage(library: ask.library),
                        confirmLabel: ask.action.label, cancelLabel: T.shared.common.cancel, destructive: ask.action.destructive,
                        confirmId: "libraries.admin.confirm", cancelId: "libraries.admin.cancel"
                    )
                },
                onConfirm: {
                    if let ask = asking { model.store.runAdminAction(library: ask.library, action: ask.action) }
                    asking = nil
                },
                onCancel: { asking = nil }
            )
            .task { await model.state.observe() }
        }
    }

    /// Move up and Move down where `library` can go, then its admin actions.
    @ViewBuilder
    private func menu(_ store: LibrariesScreenStore, _ library: MediaLibrary, index: Int, count: Int, id: String) -> some View {
        if index > 0 {
            Button { store.moveLibrary(globalKey: library.globalKey, toIndex: Int32(index - 1)) } label: {
                Label(T.shared.libraries.moveUp, systemImage: "arrow.up")
            }
            .accessibilityIdentifier("\(id).up")
        }
        if index < count - 1 {
            Button { store.moveLibrary(globalKey: library.globalKey, toIndex: Int32(index + 1)) } label: {
                Label(T.shared.libraries.moveDown, systemImage: "arrow.down")
            }
            .accessibilityIdentifier("\(id).down")
        }
        ForEach(store.adminActions(library: library), id: \.self) { action in
            Button(role: action.destructive ? .destructive : nil) { asking = (library, action) } label: {
                Label(action.label, systemImage: action.systemImage)
            }
            .accessibilityIdentifier("\(id).\(action.name.lowercased())")
        }
    }
}

extension LibraryAdminAction {
    /// The action's symbol in a library's menu.
    var systemImage: String {
        switch self {
        case .scan: "arrow.clockwise"
        case .analyze: "chart.bar.xaxis"
        case .refreshMetadata: "arrow.triangle.2.circlepath"
        default: "trash"
        }
    }
}
