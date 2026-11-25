import SwiftUI
import PlezyKit

/// Connecting the profile's Seerr account, a form in steps: the instance's address (Continue probes it), then signing in
/// to the instance that answered (its card with Change, Plex, the open credential form, the other methods) or the Quick
/// Connect code with Cancel. The inline error under the step; a spinner on the active button while busy. The screen
/// closes once the account is kept.
struct SeerrConnectScreen: View {
    let app: AppModel
    let route: RouteSeerrConnect

    @State private var model: StoreModel<SeerrConnectStore, SeerrConnectUiState>?
    @FocusState private var field: String?
    /// The fields' text as typed: the store's state comes back a frame later, which a field bound to it straight would
    /// take for an edit and undo each keystroke with. The store's text replaces a field's only while that field isn't
    /// being typed in: an echo of a keystroke that arrives after the next one would drop that one ("h:/92.168…").
    @State private var url = ""
    @State private var identifier = ""
    @State private var password = ""

    init(app: AppModel, route: RouteSeerrConnect) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.seerrConnect(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            Form {
                switch onEnum(of: state.step) {
                case .url(let step):
                    Section {
                        TextField(step.label, text: $url.sending { store.setUrl(text: $0) }, prompt: Text(step.hint))
                            #if os(iOS)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()
                            .focused($field, equals: "url")
                            .onSubmit(store.probe)
                            .accessibilityIdentifier("seerrConnect.url")
                            .formFieldRow()
                    } footer: {
                        Text(step.helper)
                    }
                    errorSection(state.error)
                    Section {
                        busyButton(step.continueLabel, id: "seerrConnect.continue", busy: state.busy, action: store.probe)
                    }
                case .signIn(let signIn):
                    Section {
                        LabeledContent(signIn.instanceLabel, value: signIn.baseUrl)
                        Button(signIn.changeLabel, action: store.changeServer).accessibilityIdentifier("seerrConnect.change")
                    }
                    if let message = signIn.noMethodsMessage {
                        Section { Text(message).foregroundStyle(Palette.error) }
                    }
                    if let plex = signIn.plexLabel {
                        Section { busyButton(plex, id: "seerrConnect.plex", busy: state.busy, action: store.signInWithPlex) }
                    }
                    if let form = signIn.form {
                        credentialForm(form, store: store, busy: state.busy)
                    }
                    errorSection(state.error)
                    if !signIn.methods.isEmpty {
                        Section {
                            ForEach(signIn.methods, id: \.kind) { method in
                                Button(method.label) {
                                    store.chooseForm(kind: method.kind)
                                    // The new form starts from the store's fields (cleared), before the identifier
                                    // takes focus, after which the store's text no longer replaces what it shows.
                                    let form = credentials(store.state.value)
                                    identifier = form?.identifier ?? ""
                                    password = form?.password ?? ""
                                    field = "identifier"
                                }
                                .accessibilityIdentifier("seerrConnect.method.\(method.kind.name.lowercased())")
                            }
                        }
                    }
                case .quickConnect(let quick):
                    Section {
                        CodeText(code: quick.code, id: "seerrConnect.code")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    errorSection(state.error)
                    Section {
                        Button(quick.cancelLabel, action: store.cancelQuickConnect).accessibilityIdentifier("seerrConnect.cancelQuickConnect")
                    }
                }
            }
            .settingsForm()
            .disabled(state.busy)
            .navigationTitle(state.title)
            .inlineNavigationTitle()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("seerrConnect.screen")
            .task { await model.state.observe() }
            .onChange(of: stepUrl(state), initial: true) { _, stored in
                if let stored, stored != url, field != "url" { url = stored }
            }
            .onChange(of: credentials(state)?.identifier, initial: true) { _, stored in
                if let stored, stored != identifier, field != "identifier" { identifier = stored }
            }
            .onChange(of: credentials(state)?.password, initial: true) { _, stored in
                if let stored, stored != password, field != "password" { password = stored }
            }
            .task { field = "url" }
            .onChange(of: state.done) {
                if state.done { _ = app.navigator.pop(route: route) }
            }
        }
    }

    private func stepUrl(_ state: SeerrConnectUiState) -> String? {
        if case .url(let step) = onEnum(of: state.step) { step.url } else { nil }
    }

    private func credentials(_ state: SeerrConnectUiState) -> SeerrCredentialForm? {
        if case .signIn(let signIn) = onEnum(of: state.step) { signIn.form } else { nil }
    }

    @ViewBuilder
    private func credentialForm(_ form: SeerrCredentialForm, store: SeerrConnectStore, busy: Bool) -> some View {
        Section {
            TextField(form.identifierLabel, text: $identifier.sending { store.setIdentifier(text: $0) })
                #if os(iOS)
                .textContentType(form.identifierIsEmail ? .emailAddress : .username)
                .keyboardType(form.identifierIsEmail ? .emailAddress : .default)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .focused($field, equals: "identifier")
                .onSubmit { field = "password" }
                .accessibilityIdentifier("seerrConnect.identifier")
                .formFieldRow()
            if let error = form.identifierError { Text(error).foregroundStyle(Palette.error) }
            SecureField(form.passwordLabel, text: $password.sending { store.setPassword(text: $0) })
                .textContentType(.password)
                .focused($field, equals: "password")
                .onSubmit(store.signIn)
                .accessibilityIdentifier("seerrConnect.password")
                .formFieldRow()
            if let error = form.passwordError { Text(error).foregroundStyle(Palette.error) }
        }
        Section {
            busyButton(form.signInLabel, id: "seerrConnect.signIn", busy: busy, action: store.signIn)
            if let quick = form.quickConnectLabel {
                Button(quick, action: store.startQuickConnect).accessibilityIdentifier("seerrConnect.quickConnect")
            }
        }
    }

    @ViewBuilder
    private func errorSection(_ error: String?) -> some View {
        if let error {
            Section { ErrorLine(text: error) }
        }
    }

    private func busyButton(_ title: String, id: String, busy: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                if busy { ProgressView().controlSize(.small) }
            }
        }
        .accessibilityIdentifier(id)
    }
}
