import SwiftUI
import PlezyKit

/// The ways to add a connection (`AppSession.addConnection`): Sign in with Plex, Connect to Jellyfin, Connect to Emby
/// and, for a profile, Borrow from another profile, each a row with its mark, title and subtitle.
struct AddConnectionScreen: View {
    let app: AppModel
    private let title: String
    private let options: [AddConnectionOption]


    init(app: AppModel, route: any Route) {
        self.app = app
        let pair = app.session.addConnection(route: route)
        title = (pair?.first as? String) ?? ""
        options = (pair?.second as? [AddConnectionOption]) ?? []
    }

    var body: some View {
        Form {
            Section {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    AccountOptionRow(title: option.title, subtitle: option.subtitle, id: "addconnection.option.\(index)") {
                        if let backend = option.backend {
                            BackendMark(backend: backend, size: 28)
                        } else {
                            // The backends' marks' size: tvOS's title font drew it over the row's text.
                            Image(systemName: "square.and.arrow.down.on.square").resizable().scaledToFit().frame(width: 28, height: 28)
                        }
                    } action: {
                        app.navigator.navigate(route: option.route)
                    }
                }
            }
        }
        .settingsForm()
        .pageTitle(title)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("addconnection.screen")
    }
}

/// Borrowing another profile's connection (`BorrowStore`): the explanation, then the connections other profiles lend
/// (each with its mark, label, the profile it comes from and a lock where that profile has a PIN); a spinner while they
/// load, the failure with Retry, or "Nothing to borrow yet".
struct BorrowConnectionScreen: View {
    @State private var model: StoreModel<BorrowStore, BorrowUiState>?

    init(app: AppModel, route: any Route) {
        _model = State(initialValue: StoreModel(app.session.borrowConnection(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let profiles = T.shared.profiles
            Group {
                if state.loading {
                    LoadingStateView()
                } else if state.failed {
                    ErrorStateView(message: profiles.borrowLoadFailed, onRetry: model.store.retry)
                } else if state.candidates.isEmpty {
                    EmptyStateView(message: profiles.borrowEmptySubtitle, title: profiles.borrowEmpty, systemImage: "person.2")
                } else {
                    Form {
                        Section {
                            ForEach(state.candidates, id: \.index) { candidate in
                                AccountOptionRow(
                                    title: candidate.label, subtitle: candidate.from, enabled: !state.busy,
                                    id: "borrow.option.\(candidate.index)"
                                ) {
                                    ZStack(alignment: .bottomTrailing) {
                                        BackendMark(backend: candidate.backend, size: 28)
                                        if candidate.locked {
                                            Image(systemName: "lock.fill").font(.caption2).offset(x: 6, y: 4)
                                        }
                                    }
                                } action: {
                                    model.store.borrow(index: candidate.index)
                                }
                            }
                        } footer: {
                            Text(profiles.borrowExplain)
                        }
                    }
                    .settingsForm(idle: state.busy)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .pageTitle(state.title)
            .toast(state.message, id: "borrow.message") { model.store.messageShown() }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("borrow.screen")
            .task { await model.state.observe() }
        }
    }
}

/// A Jellyfin or Emby connection's URLs (`EditConnectionStore`), one per line, and Save.
struct EditConnectionScreen: View {
    @State private var model: StoreModel<EditConnectionStore, EditConnectionUiState>?

    init(app: AppModel, route: any Route) {
        _model = State(initialValue: StoreModel(app.session.editConnection(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            Form {
                Section {
                    StoreText(value: state.urls, send: { model.store.setUrls(text: $0) }) { text in
                        UrlsField(text: text, id: "editconnection.urls", multiline: true)
                            .disabled(state.busy)
                    }
                } header: {
                    Text(T.shared.addServer.serverUrls)
                } footer: {
                    Text(state.intro)
                }
                if let error = state.error {
                    Section { ErrorLine(text: error) }
                }
                Section {
                    if state.busy {
                        ProgressLine(text: nil)
                    } else {
                        Button(T.shared.common.save) { model.store.save() }
                            .formRowButtonStyle()
                            .accessibilityIdentifier("editconnection.save")
                    }
                }
            }
            .settingsForm(idle: state.busy)
            .pageTitle(state.title)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("editconnection.screen")
            .task { await model.state.observe() }
        }
    }
}

/// The server URLs field: no capitals or corrections, the URL keyboard. `multiline`: one URL a line, as many lines as
/// it holds (Return starts a line); else one line, commas between URLs, Return submits (`onSubmit`).
private struct UrlsField: View {
    let text: Binding<String>
    let id: String
    var multiline = false
    var onSubmit: () -> Void = {}

    var body: some View {
        TextField(
            T.shared.addServer.serverUrls, text: text, prompt: Text(verbatim: "https://jellyfin.example.com"),
            axis: multiline ? .vertical : .horizontal
        )
            .labelsHidden()
            .lineLimit(multiline ? 1...4 : 1...1)
            .autocorrectionDisabled()
            #if !os(macOS)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            #endif
            .submitLabel(.go)
            .onSubmit(onSubmit)
            .accessibilityIdentifier(id)
            .formFieldRow()
    }
}

/// Adding a Jellyfin or Emby server (`AddMediaBrowserStore`). Before a probe: the URLs, the servers found on the LAN
/// (and the stored ones) and Find server. After it: the server's card with Change, username, password, Sign in and,
/// where the server has it, Use Quick Connect. While Quick Connect waits, its code replaces the form, with Cancel
/// focused. A TV starts on the URLs field; the form moves focus where the store says (`focusUsername`, `focusPassword`
/// when signing in again, `focusCancel`).
struct AddMediaBrowserScreen: View {
    @State private var model: StoreModel<AddMediaBrowserStore, AddMediaBrowserUiState>?
    @FocusState private var focus: Field?

    private enum Field: Hashable { case urls, username, password, cancel }

    init(app: AppModel, route: any Route) {
        _model = State(initialValue: StoreModel(app.session.addMediaBrowser(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            Group {
                if let code = state.quickConnectCode {
                    quickConnect(code, store: model.store)
                } else {
                    form(state, store: model.store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .pageTitle(state.title)
            .onChange(of: state.focusUsername) { focus = .username }
            .onChange(of: state.focusPassword) { focus = .password }
            .onChange(of: state.focusCancel) { focus = .cancel }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("addserver.screen")
            .task { await model.state.observe() }
            .task {
                #if os(tvOS)
                focus = .urls
                #endif
            }
        }
    }

    private func form(_ state: AddMediaBrowserUiState, store: AddMediaBrowserStore) -> some View {
        let add = T.shared.addServer
        let product = state.dialect.productName
        return Form {
            Section {
                StoreText(value: state.urls, send: { store.setUrls(text: $0) }) { text in
                    UrlsField(text: text, id: "addserver.url") {
                        if state.server == nil { store.findServer() }
                    }
                    .focused($focus, equals: .urls)
                    .disabled(state.busy)
                }
                if state.urlRequired {
                    Text(add.enterMediaBrowserUrlError(product: product)).font(.footnote).foregroundStyle(Palette.error)
                }
            } header: {
                Text(add.serverUrls)
            } footer: {
                if state.server == nil { Text(add.serverUrlsHelper) }
            }
            if let server = state.server {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "checkmark.icloud.fill").font(.title2).accessibilityHidden(true)
                        SettingsRowText(title: server.name, subtitle: server.version)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(add.change) { store.changeServer() }
                            // On Apple TV a pill, as every text button there; elsewhere a text button.
                            #if os(tvOS)
                            .pillButtonStyle()
                            #else
                            .buttonStyle(.borderless)
                            #endif
                            .disabled(state.busy)
                            .accessibilityIdentifier("addserver.change")
                    }
                    .accessibilityIdentifier("addserver.server")
                }
                Section {
                    StoreText(value: state.username, send: { store.setUsername(text: $0) }) { text in
                        TextField(add.username, text: text, prompt: Text(add.username))
                            .labelsHidden()
                            .autocorrectionDisabled()
                            #if !os(macOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .submitLabel(.next)
                            .onSubmit { focus = .password }
                            .focused($focus, equals: .username)
                            .disabled(state.busy)
                            .accessibilityIdentifier("addserver.username")
                            .formFieldRow()
                    }
                    if state.usernameRequired {
                        Text(add.required).font(.footnote).foregroundStyle(Palette.error)
                    }
                    StoreText(value: state.password, send: { store.setPassword(text: $0) }) { text in
                        SecureField(add.password, text: text, prompt: Text(add.password))
                            .labelsHidden()
                            .submitLabel(.go)
                            .onSubmit { store.signIn() }
                            .focused($focus, equals: .password)
                            .disabled(state.busy)
                            .accessibilityIdentifier("addserver.password")
                            .formFieldRow()
                    }
                }
            } else if !state.localServers.isEmpty || state.discovering {
                Section(add.localMediaBrowserServers(product: product)) {
                    if state.discovering {
                        ProgressLine(text: add.searchingLocalMediaBrowserServers(product: product))
                    }
                    ForEach(Array(state.localServers.enumerated()), id: \.element.id) { index, server in
                        AccountOptionRow(
                            title: server.name, subtitle: server.address,
                            detail: state.addedServerIds.contains(server.id) ? add.alreadyAdded : nil,
                            enabled: !state.busy, id: "addserver.local.\(index)"
                        ) {
                            Image(systemName: "server.rack").font(.title3)
                        } action: {
                            store.useLocalServer(server: server)
                        }
                    }
                }
            }
            if let error = state.error {
                Section { ErrorLine(text: error).accessibilityIdentifier("addserver.error") }
            }
            Section {
                if state.busy {
                    ProgressLine(text: nil).accessibilityIdentifier("addserver.busy")
                } else if state.server == nil {
                    Button { store.findServer() } label: {
                        Label(add.findServer, systemImage: "magnifyingglass")
                    }
                    .formRowButtonStyle()
                    .accessibilityIdentifier("addserver.find")
                } else {
                    Button { store.signIn() } label: {
                        Label(add.signIn, systemImage: "arrow.right.circle")
                    }
                    .formRowButtonStyle()
                    .accessibilityIdentifier("addserver.signin")
                    if state.quickConnectAvailable {
                        Button { store.startQuickConnect() } label: {
                            Label(T.shared.auth.useQuickConnect, systemImage: "qrcode.viewfinder")
                        }
                        .formRowButtonStyle()
                        .accessibilityIdentifier("addserver.quickconnect")
                    }
                }
            }
        }
        .settingsForm()
    }

    /// Quick Connect waiting for approval, a device-code page: the instructions, the code (`CodeText`), its progress
    /// line and Cancel.
    private func quickConnect(_ code: String, store: AddMediaBrowserStore) -> some View {
        let auth = T.shared.auth
        return AccountPage(title: auth.quickConnect, intro: auth.quickConnectInstructions) {
            CodeText(code: code, id: "addserver.qc.code")
            ProgressLine(text: auth.quickConnectWaiting)
            ActionButton(title: auth.quickConnectCancel, id: "addserver.qc.cancel", systemImage: "xmark", fullWidth: false) {
                store.cancelQuickConnect()
            }
            .focused($focus, equals: .cancel)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("addserver.qc")
        .task {
            focus = .cancel
        }
    }
}
