import SwiftUI
import PlezyKit

/// A new local profile (`AddProfileStore`): its name, its optional PIN (Set PIN; once set, PIN set with Change and
/// Remove), then Continue, which stores it and opens its Add connection, and Cancel. On Apple TV, once the PIN pad has
/// been opened, focus comes back to the PIN row as it closes (`pinFocus`).
struct AddProfileScreen: View {
    @State private var model: StoreModel<AddProfileStore, AddProfileUiState>?
    @FocusState private var focus: ProfileFormFocus?
    @State private var pinAsked = false

    init(app: AppModel, route: any Route) {
        _model = State(initialValue: StoreModel(app.session.addProfile(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            let profiles = T.shared.profiles
            Form {
                Section(profiles.profileNameLabel) {
                    StoreText(value: state.name, send: { store.setName(text: $0) }) { text in
                        TextField(profiles.profileNameLabel, text: text, prompt: Text(profiles.profileNameHint))
                            .labelsHidden()
                            .submitLabel(.done)
                            .onSubmit { store.save() }
                            .accessibilityIdentifier("addprofile.name")
                            .focused($focus, equals: .name)
                            .formFieldRow()
                    }
                    if state.nameRequired {
                        Text(T.shared.addServer.required).font(.footnote).foregroundStyle(Palette.error)
                    }
                }
                Section {
                    PinRow(pinSet: state.pinSet, focus: $focus, set: { pinAsked = true; store.setPin() }, clear: store.clearPin)
                } header: {
                    Text(profiles.pinProtectionOptional)
                } footer: {
                    Text(profiles.pinExplain)
                }
                Section {
                    Button(profiles.continueButton) { store.save() }
                        .disabled(state.busy || state.name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("addprofile.continue")
                    Button(T.shared.common.cancel) { store.cancel() }
                        .accessibilityIdentifier("addprofile.cancel")
                }
                .formRowButtonStyle()
            }
            .settingsForm()
            .pinFocus($focus, asked: pinAsked, pinSet: state.pinSet)
            .pageTitle(profiles.newProfile)
            .toast(state.message, id: "addprofile.message") { store.messageShown() }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("addprofile.screen")
            .task { await model.state.observe() }
        }
    }
}

/// Where a profile's form puts focus: its name field, or its PIN row (Set PIN, or Change once set).
enum ProfileFormFocus: Hashable {
    case name
    case pin
}

extension View {
    /// On Apple TV, once the PIN pad has been `asked` for, focus goes to the PIN row as the PIN is set or removed
    /// (`pinSet` changes): the button focused before (Set PIN, Change or Remove) is gone, and the focus engine would
    /// fall back to the form's first field as the pad closes.
    @ViewBuilder
    func pinFocus(_ focus: FocusState<ProfileFormFocus?>.Binding, asked: Bool, pinSet: Bool) -> some View {
        #if os(tvOS)
        task(id: pinSet) {
            if asked { await FocusRestore.restore(focus, to: .pin, replacing: true) }
        }
        #else
        self
        #endif
    }
}

/// A local profile's PIN: Set PIN, or once set "PIN set" with Change and Remove (on Apple TV glass pills, which show
/// focus as the app's other TV buttons do; a borderless button there shows none).
private struct PinRow: View {
    let pinSet: Bool
    let focus: FocusState<ProfileFormFocus?>.Binding
    let set: () -> Void
    let clear: () -> Void

    var body: some View {
        let profiles = T.shared.profiles
        if pinSet {
            LabeledContent {
                HStack(spacing: 12) {
                    Button(profiles.changePin, action: set)
                        .focused(focus, equals: .pin)
                        .accessibilityIdentifier("profile.pin.change")
                    Button(role: destructiveRole(pill: true), action: clear) { Text(profiles.removePin).destructiveLabel(pill: true) }
                        .accessibilityIdentifier("profile.pin.remove")
                }
                #if os(tvOS)
                .pillButtonStyle()
                #else
                .buttonStyle(.borderless)
                #endif
            } label: {
                Label(profiles.pinSet, systemImage: "lock.fill")
            }

        } else {
            Button(action: set) {
                Label(profiles.setPin, systemImage: "lock")
            }
            .formRowButtonStyle()
            .focused(focus, equals: .pin)
            .accessibilityIdentifier("profile.pin.set")
        }
    }
}

/// A profile's detail (`ProfileDetailStore`): its name (a local one's editable, saved on Return), its PIN (a Plex Home
/// user's managed on plex.tv: the note alone), its connections with their menus (Make default, Edit, Remove; the Plex
/// Home account's Sign out), Add, and a local profile's Delete profile. On Apple TV focus comes back to the PIN row
/// once its pad or Remove has been used (`pinFocus`).
struct ProfileDetailScreen: View {
    @State private var model: StoreModel<ProfileDetailStore, ProfileDetailUiState>?
    @FocusState private var focus: ProfileFormFocus?
    @State private var pinAsked = false

    init(app: AppModel, route: any Route) {
        _model = State(initialValue: StoreModel(app.session.profileDetail(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            let profiles = T.shared.profiles
            Form {
                Section {
                    ProfileAvatar(name: state.title, url: state.avatarUrl, size: 96)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                Section(profiles.profileNameLabel) {
                    if state.local {
                        StoreText(value: state.name, send: { store.setName(text: $0) }) { text in
                            TextField(profiles.profileNameLabel, text: text, prompt: Text(profiles.profileNameHint))
                                .labelsHidden()
                                .submitLabel(.done)
                                .onSubmit { store.saveName() }
                                .accessibilityIdentifier("profile.name")
                                .focused($focus, equals: .name)
                                .formFieldRow()
                        }
                    } else {
                        Text(state.name)
                    }
                }
                Section(profiles.pinProtectionLabel) {
                    if let note = state.pinNote {
                        Text(note).mutedForeground()
                    } else {
                        PinRow(
                            pinSet: state.pinSet,
                            focus: $focus,
                            set: { pinAsked = true; store.setPin() },
                            clear: { pinAsked = true; store.clearPin() }
                        )
                    }
                }
                Section(profiles.connectionsLabel) {
                    if state.connections.isEmpty {
                        Text(profiles.noConnectionsHint).mutedForeground()
                    }
                    ForEach(Array(state.connections.enumerated()), id: \.element.connectionId) { index, connection in
                        ConnectionRow(connection: connection, index: index, store: store)
                    }
                    Button(action: store.addConnection) {
                        Label(profiles.add, systemImage: "plus")
                    }
                    .formRowButtonStyle()
                    .accessibilityIdentifier("profile.add")
                }
                if state.local {
                    Section {
                        Button(role: .destructive, action: store.delete) { Text(profiles.deleteProfileButton).destructiveLabel() }
                            .formRowButtonStyle()
                            .accessibilityIdentifier("profile.delete")
                    }
                }
            }
            .settingsForm()
            .pinFocus($focus, asked: pinAsked, pinSet: state.pinSet)
            .pageTitle(state.title)
            .confirmation(
                state.confirm?.dialog,
                onConfirm: { store.setConfirmToggle(checked: false); store.confirm() },
                onToggledConfirm: { store.setConfirmToggle(checked: true); store.confirm() },
                onCancel: store.dismissConfirm
            )
            .toast(state.message, id: "profile.message") { store.messageShown() }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("profile.screen")
            .task { await model.state.observe() }
        }
    }
}

/// A connection of the profile: its backend's mark, label and subtitle, and its menu.
private struct ConnectionRow: View {
    let connection: ProfileConnectionUi
    let index: Int
    let store: ProfileDetailStore

    var body: some View {
        HStack(spacing: 16) {
            BackendMark(backend: connection.backend, size: 24)
            SettingsRowText(title: connection.label, subtitle: connection.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("profile.connection.\(index)")
            ItemMenuButton(label: connection.label, entries: entries, probe: "profile.connection.\(index).menu")
        }
    }

    private var entries: [ItemMenuEntry] {
        let profiles = T.shared.profiles
        let id = connection.connectionId
        if connection.plexHomeAccount {
            return [ItemMenuEntry(label: profiles.signOut, systemImage: "rectangle.portrait.and.arrow.right", destructive: true) {
                store.signOut(connectionId: id)
            }]
        }
        var entries: [ItemMenuEntry] = []
        if !connection.isDefault {
            entries.append(ItemMenuEntry(label: profiles.makeDefault, systemImage: "star") { store.makeDefault(connectionId: id) })
        }
        if connection.editable {
            entries.append(ItemMenuEntry(label: T.shared.common.edit, systemImage: "pencil") { store.edit(connectionId: id) })
        }
        entries.append(ItemMenuEntry(label: profiles.removeConnection, systemImage: "trash", destructive: true) {
            store.remove(connectionId: id)
        })
        return entries
    }
}
