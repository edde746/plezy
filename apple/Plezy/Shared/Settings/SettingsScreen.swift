import SwiftUI
import PlezyKit
import Nuke
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Settings: the hub (`Route.Settings`, the tab's root) or a page pushed over it (`Route.SettingsPage`). Row pages
/// draw through one renderer (`SettingsRowsPage`); Theme, Custom theme, mpv.conf, External player, Keyboard shortcuts
/// (the Mac's: the hub offers it on desktops only), Logs, Manage libraries and Licenses have screens
/// of their own.
struct SettingsScreen: View {
    let app: AppModel
    let route: any Route

    var body: some View {
        let pageRoute = route as? RouteSettingsPage
        let page = pageRoute?.page ?? .hub
        let arg = pageRoute?.arg
        switch page {
        case .hub, .general, .appearance, .videoPlayback, .subtitleStyling, .about, .accountPreferences:
            SettingsRowsPage(app: app, route: route, page: page, arg: arg)
        case .theme:
            ThemePickerScreen(app: app, route: route)
        case .customTheme:
            #if os(tvOS)
            CustomThemeEditorRoute(app: app, route: route)
            #else
            EmptyView() // a sheet over the theme picker here (`ThemePickerScreen`)
            #endif
        case .mpvConfig:
            MpvConfigScreen(app: app, route: route)
        case .externalPlayer:
            ExternalPlayerScreen(app: app, route: route)
        case .keyboardShortcuts:
            #if os(macOS)
            KeyboardShortcutsScreen(app: app, route: route)
            #else
            EmptyView() // never offered off the Mac (`SettingsFacts.keyboardShortcutsSupported`)
            #endif
        case .manageLibraries:
            ManageLibrariesScreen(app: app)
        case .logs:
            LogsScreen(app: app, route: route)
        case .licenses:
            LicensesScreen(app: app, route: route, name: arg)
        }
    }
}

extension SettingsPageId {
    /// The page's accessibility identifier: `settings.screen` for the hub (the shell's), else `settings.page.<page>`.
    var probe: String {
        switch self {
        case .hub: "settings.screen"
        case .general: "settings.page.general"
        case .appearance: "settings.page.appearance"
        case .videoPlayback: "settings.page.video_playback"
        case .subtitleStyling: "settings.page.subtitle_styling"
        case .about: "settings.page.about"
        case .theme: "settings.page.theme"
        case .customTheme: "settings.page.custom_theme"
        case .mpvConfig: "settings.page.mpv_config"
        case .externalPlayer: "settings.page.external_player"
        case .keyboardShortcuts: "settings.page.keyboard_shortcuts"
        case .logs: "settings.page.logs"
        case .manageLibraries: "settings.page.manage_libraries"
        case .licenses: "settings.page.licenses"
        case .accountPreferences: "settings.page.account_preferences"
        }
    }
}

/// A settings store kept for its route while the route is on a stack (`PlezyNavigator.retain`) and released once it
/// leaves every stack, with its state mirrored for the views. Obtained once per appearance of the route: a page
/// covered by another and shown again finds its store, and the row it had focused (`lastFocused`), as it left them.
@MainActor
final class SettingsStoreModel<Store, State> {
    let store: Store
    let state: StoreObserver<State>
    /// tvOS: the row focused last, focused again when the page shows again.
    var lastFocused: String?
    /// The page has shown once: a later appearance is a return to it.
    var appeared = false
    private let releaseStore: (Store) -> Void

    private init(store: Store, state: StoreObserver<State>, release: @escaping (Store) -> Void) {
        self.store = store
        self.state = state
        releaseStore = release
    }

    /// The model kept for `route` under `key`, made by `create` on first use (its state `flow`) and released by
    /// `release`; nil while the route is on no stack (a popped page still draws while it animates out).
    static func retained(
        app: AppModel, route: any Route, key: String,
        create: @escaping () -> Store, flow: @escaping (Store) -> SkieSwiftStateFlow<State>, release: @escaping (Store) -> Void
    ) -> SettingsStoreModel? {
        // The navigator calls both on the main thread: `create` within this call, `release` as the route leaves.
        let value = app.navigator.retain(
            route: route,
            key: key,
            create: {
                let model: SettingsStoreModel = MainActor.assumeIsolated {
                    let store = create()
                    return SettingsStoreModel(store: store, state: StoreObserver(flow(store)), release: release)
                }
                return model
            },
            release: { value in
                guard let model = value as? SettingsStoreModel else { return }
                MainActor.assumeIsolated { model.releaseStore(model.store) }
            }
        )
        return value as? SettingsStoreModel
    }

    /// A model its presenter owns rather than a route (a sheet's: the custom theme editor on iOS and macOS), made at
    /// once by `create` (its state `flow`); the presenter calls `release()` once the sheet closes.
    static func owned(
        create: () -> Store, flow: (Store) -> SkieSwiftStateFlow<State>, release: @escaping (Store) -> Void
    ) -> SettingsStoreModel {
        let store = create()
        return SettingsStoreModel(store: store, state: StoreObserver(flow(store)), release: release)
    }

    /// Releases an `owned` model's store.
    func release() {
        releaseStore(store)
    }
}

/// A settings page's frame: the hub's title as a settings page's large navigation title (the destination chrome shows
/// Settings' bar with it on iPhone; on iPad the hub's form shows it at the top of its column, `settingsTitleInContent`;
/// Apple TV's tab bar names the hub), a pushed page's in the navigation bar. `id` is the page's
/// accessibility identifier.
struct SettingsPageFrame<Content: View>: View {
    let title: String
    var hub = false
    let id: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if hub {
                content()
                    .navigationTitle(title)
            } else {
                content()
                    .pageTitle(title)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(id)
    }
}

/// A page drawn from rows (`SettingsPageId.rows`): its store's groups as a grouped form, each row bound to its store
/// by id; the store's events act here (`SettingsEvents`), and on the Mac's hub the download location's dialog and
/// outcome (`DownloadLocationOverlay`). On Apple TV focus comes back to the row that had it last when the page shows
/// again (back from a page), else goes to the first row; the hub, a tab's root, leaves focus on the tab bar where it is
/// (the tab picked there, or the app starting on Settings until its servers are online): taken from the bar into a
/// screen the tab bar then leaves, focus fell to another tab's screen with the bar out of Up's reach. Focus moved down
/// from the bar into the page (its tab picked again) lands on the row that had it last too, else the first row.
private struct SettingsRowsPage: View {
    let app: AppModel
    let page: SettingsPageId

    @State private var model: SettingsStoreModel<any SettingsPageStore, SettingsPageUiState>?

    init(app: AppModel, route: any Route, page: SettingsPageId, arg: String?) {
        self.app = app
        self.page = page
        _model = State(initialValue: .retained(
            app: app, route: route, key: "settings.page",
            create: { app.session.settings.page(id: page, arg: arg) },
            flow: { $0.state },
            release: { $0.release() }
        ))
    }

    var body: some View {
        if let model {
            SettingsRowsContent(app: app, model: model, page: page)
        }
    }
}

private struct SettingsRowsContent: View {
    let app: AppModel
    let model: SettingsStoreModel<any SettingsPageStore, SettingsPageUiState>
    let page: SettingsPageId

    @FocusState private var focused: String?
    #if os(iOS)
    /// iPad: the hub names itself at the top of its column, its bar empty (`settingsTitleInContent`).
    @Environment(\.settingsTitleInContent) private var titleInContent
    #endif

    var body: some View {
        let state = model.state.state
        let store = model.store
        let groups = shownGroups(state)
        SettingsPageFrame(title: state.title, hub: page == .hub, id: page.probe) {
            if state.loading {
                LoadingStateView()
            } else if let empty = state.empty {
                EmptyStateView(message: empty.body ?? "", title: empty.title, systemImage: empty.icon.systemImage) {
                    if let retry = empty.retryLabel {
                        Button(retry) { store.activate(id: SettingsEmptyState.companion.RETRY_ID) }
                            .buttonProminence(.primary)
                            .accessibilityIdentifier("settings.retry")
                    }
                }
            } else {
                Form {
                    #if os(iOS)
                    if page == .hub, titleInContent {
                        Section {} header: {
                            Text(state.title)
                                .font(.largeTitle.bold())
                                .foregroundStyle(Palette.onBackground)
                                .textCase(nil)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("settings.title")
                        }
                    }
                    #endif
                    if page == .hub { SettingsProfileSection(app: app) }
                    if let header = state.header {
                        Section {
                            if page == .about { AboutHeader(header: header) } else { SettingsNote(text: header) }
                        }
                        .listRowBackground(Color.clear)
                    }
                    ForEach(groups, id: \.group.id) { shown in
                        Section {
                            ForEach(shown.rows, id: \.id) { row in
                                SettingRowView(app: app, row: row, store: store)
                                    .focused($focused, equals: row.id)
                            }
                        } header: {
                            if let header = shown.group.header { Text(header) }
                        } footer: {
                            // What every row of the group does, said once.
                            if let footer = shown.group.footer {
                                Text(footer).accessibilityIdentifier("settings.group.\(shown.group.id).footer")
                            }
                        }
                    }
                }
                .settingsForm()
                #if os(tvOS)
                // Focus coming down from the tab bar (the tab picked again after another) lands on the row that had it
                // last, else the top row, not the row under the bar.
                .defaultFocus($focused, model.lastFocused ?? groups.first?.rows.first?.id, priority: .userInitiated)
                #endif
            }
        }
        .modifier(SettingsEvents(app: app, events: store.events, store: store))
        #if os(macOS)
        .modifier(DownloadLocationOverlay(model: page == .hub ? app.session.downloadLocation : nil))
        #endif
        .task { await model.state.observe() }
        .onAppear {
            if model.appeared { store.resumed() }
            model.appeared = true
        }
        #if os(tvOS)
        .onChange(of: focused) { _, row in
            if let row { model.lastFocused = row }
        }
        .task(id: state.loading) {
            guard !state.loading, page != .hub || !FocusRestore.focusInTabBar else { return }
            let target = model.lastFocused ?? groups.first?.rows.first?.id
            await FocusRestore.restore($focused, to: target, hold: 0.5, replacing: model.lastFocused != nil)
        }
        #endif
    }

    /// The groups with the rows that show: a slot row whose provider draws nothing is left out, and a group left
    /// without rows with it, so the grouped corners stay right.
    private func shownGroups(_ state: SettingsPageUiState) -> [ShownGroup] {
        state.groups.compactMap { group in
            let rows = group.rows.filter { row in
                guard let slot = row as? SettingSlotRow else { return true }
                return SettingsSlots.shown(slot.slot, app: app)
            }
            return rows.isEmpty ? nil : ShownGroup(group: group, rows: rows)
        }
    }
}

private struct ShownGroup {
    let group: SettingsGroup
    let rows: [any SettingRow]
}

/// Text above a page's groups (account preferences' header, a note), in the footnote style.
struct SettingsNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .mutedForeground()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The hub's first section, the running profile in one row (as iOS Settings' account card): its avatar, its name with a
/// lock where a PIN guards it, Switch Profile under it and a chevron; the row opens the profile picker (the hub's Manage
/// profiles row opens it too, to manage them); off while a switch runs. Identifier `settings.profile.switch`.
private struct SettingsProfileSection: View {
    let app: AppModel

    @Environment(\.formFactor) private var formFactor

    init(app: AppModel) {
        self.app = app
    }

    var body: some View {
        let state = app.userMenu.state
        let name = state.active?.name ?? T.shared.profiles.sectionTitle
        let avatarSize: CGFloat = formFactor == .tv ? 72 : 44
        Section {
            Button { app.navigator.navigate(route: RouteProfilePicker(required: false, manage: false)) } label: {
                HStack(spacing: 16) {
                    ProfileAvatar(name: name, url: state.active?.avatarUrl, size: avatarSize)
                    VStack(alignment: .leading, spacing: 2) {
                        title(name, locked: state.active?.locked == true)
                        Text(T.shared.screens.switchProfile).font(.footnote).mutedForeground()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .formRowButtonStyle()
            .disabled(state.switching)
            .accessibilityIdentifier("settings.profile.switch")
        }
    }

    private func title(_ name: String, locked: Bool) -> some View {
        HStack(spacing: 6) {
            Text(name).font(.headline).lineLimit(formFactor == .tv ? 1 : nil)
            if locked {
                Image(systemName: "lock.fill").font(.footnote).mutedForeground()
            }
        }
    }
}

/// The About page's head: the app's name over the store's `header` (its version, then what it is), centred.
private struct AboutHeader: View {
    let header: String

    var body: some View {
        VStack(spacing: 6) {
            Text(verbatim: "Plezy")
                .font(.largeTitle.bold())
            ForEach(Array(header.split(separator: "\n").enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.subheadline)
                    .mutedForeground()
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("settings.about.header")
    }
}

/// A dialog a settings store's events open: a question (`SettingsEvent.Confirm`), a found update, an uploaded log.
private enum SettingsDialog {
    case confirm(SettingsEventConfirm)
    case update(SettingsEventUpdateAvailable)
    case uploaded(String)
}

#if !os(tvOS)
/// A file the store hands over to save (`SettingsEvent.SaveFile`).
struct SettingsFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
#endif

/// Acts on a settings store's `events`: opens pages (`Route.SettingsPage`) and other features' screens, asks its
/// questions, edits a text (the relay), saves and opens files through the system's dialogs for `store` (Apple TV has
/// none, and the store offers no backup there), clears the image caches, shows messages as a toast
/// (`settings.toast`) and opens links. Harness names: `settings.confirm.<ok|cancel>`, `settings.toast`.
struct SettingsEvents: ViewModifier {
    let app: AppModel
    let events: SkieSwiftFlow<any SettingsEvent>
    let store: (any SettingsPageStore)?

    @State private var dialog: SettingsDialog?
    @State private var editing: SettingTextRow?
    @State private var toast: String?
    #if !os(tvOS)
    @State private var export: (name: String, file: SettingsFile)?
    @State private var importing = false
    #endif

    func body(content: Content) -> some View {
        content
            .task {
                for await event in events { handle(event) }
            }
            .toast(toast, id: "settings.toast") { toast = nil }
            .confirmation(confirmation, onConfirm: confirm, onCancel: { dialog = nil })
            .appSheet(item: editing, onDismiss: { editing = nil }) { row in
                SettingTextSheet(
                    row: row,
                    onCheck: { store?.checkText(id: row.id, text: $0) },
                    onSave: { store?.submitText(id: row.id, text: $0) },
                    onReset: { store?.resetText(id: row.id) },
                    onClose: { editing = nil }
                )
            }
            #if !os(tvOS)
            .fileExporter(
                isPresented: Binding(get: { export != nil }, set: { if !$0 { export = nil } }),
                document: export?.file,
                contentType: .json,
                defaultFilename: export?.name
            ) { result in
                switch result {
                case .success:
                    store?.exported(saved: true, error: nil)
                case .failure(let error):
                    // A dialog the user closed saves nothing and says nothing.
                    let cancelled = (error as? CocoaError)?.code == .userCancelled
                    store?.exported(saved: false, error: cancelled ? nil : T.shared.settings.saveFailed)
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json, .plainText, .data], allowsMultipleSelection: false) { result in
                guard case .success(let urls) = result, let url = urls.first else {
                    toast = T.shared.settings.importSettingsInvalidFile
                    return
                }
                Task {
                    if let text = await importedText(url) {
                        store?.imported(bytes: KotlinByteArray.of(Data(text.utf8)))
                    } else {
                        toast = T.shared.settings.importSettingsInvalidFile
                    }
                }
            } onCancellation: {
                store?.imported(bytes: nil)
            }
            #endif
    }

    private func handle(_ event: any SettingsEvent) {
        switch onEnum(of: event) {
        case .open(let open):
            app.navigator.navigate(route: RouteSettingsPage(page: open.page, arg: open.arg))
        case .openExternal(let external):
            SettingsSlots.openExternal(external.target, app: app)
        case .confirm(let question):
            dialog = .confirm(question)
        case .editText(let edit):
            editing = edit.row
        case .saveFile(let save):
            #if os(tvOS)
            store?.exported(saved: false, error: nil)
            #else
            export = (save.fileName, SettingsFile(data: save.bytes.data))
            #endif
        case .openFile:
            #if os(tvOS)
            store?.imported(bytes: nil)
            #else
            importing = true
            #endif
        case .clearImageCache:
            ImagePipeline.shared.cache.removeAll()
        case .message(let message):
            toast = message.text
        case .openUrl(let link):
            app.session.openUrl(url: link.url)
        case .updateAvailable(let update):
            dialog = .update(update)
        case .nativeUpdateCheck:
            // Sparkle checks in the foreground with its own window (the Mac's DMG installs; never in Debug builds).
            #if os(macOS)
            if AppUpdater.shared.started { AppUpdater.shared.controller.checkForUpdates(nil) }
            #else
            break
            #endif
        case .logsUploaded(let uploaded):
            dialog = .uploaded(uploaded.id)
        }
    }

    private var confirmation: Confirmation? {
        switch dialog {
        case nil:
            return nil
        case .confirm(let question):
            return Confirmation(
                title: question.title, message: question.message, confirmLabel: question.confirmLabel,
                cancelLabel: T.shared.common.cancel, destructive: question.destructive,
                confirmId: "settings.confirm.ok", cancelId: "settings.confirm.cancel"
            )
        case .update(let update):
            let found = T.shared.update.versionAvailable(version: update.version)
            return Confirmation(
                title: T.shared.settings.updateAvailable, message: [found, update.notes].compactMap { $0 }.joined(separator: "\n\n"),
                confirmLabel: update.url == nil ? T.shared.common.ok : T.shared.update.viewRelease, cancelLabel: T.shared.common.close,
                destructive: false, confirmId: "settings.update.view", cancelId: "settings.update.close"
            )
        case .uploaded(let id):
            #if os(tvOS)
            let confirmLabel = T.shared.common.ok
            #else
            let confirmLabel = T.shared.deepLinks.copyText
            #endif
            return Confirmation(
                title: T.shared.messages.logsUploaded, message: "\(T.shared.messages.logId): \(id)", confirmLabel: confirmLabel,
                cancelLabel: T.shared.common.close, destructive: false,
                confirmId: "settings.uploaded.copy", cancelId: "settings.uploaded.close"
            )
        }
    }

    private func confirm() {
        guard let shown = dialog else { return }
        dialog = nil
        switch shown {
        case .confirm(let question):
            store?.confirm(id: question.id)
        case .update(let update):
            if let url = update.url { app.session.openUrl(url: url) }
        case .uploaded(let id):
            copyToClipboard(id)
        }
    }
}

/// Puts `text` on the system's clipboard; Apple TV has none.
func copyToClipboard(_ text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #endif
}

extension KotlinByteArray {
    /// The bytes as `Data`.
    var data: Data {
        Data((0..<size).map { UInt8(bitPattern: get(index: $0)) })
    }

    /// `data` as a Kotlin byte array.
    static func of(_ data: Data) -> KotlinByteArray {
        let bytes = KotlinByteArray(size: Int32(data.count))
        for (index, byte) in data.enumerated() {
            bytes.set(index: Int32(index), value: Int8(bitPattern: byte))
        }
        return bytes
    }
}
