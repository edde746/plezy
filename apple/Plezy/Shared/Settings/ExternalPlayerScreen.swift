import SwiftUI
import PlezyKit

/// External player: "Use External Player"; while it is on, the players found on this device and the custom ones,
/// each with its check (a press selects it), a custom one with Delete, and "Add Custom Player", which asks for its
/// name, type and command or URL scheme. Harness names:
/// `settings.external.<enabled|player.<id>|delete.<id>|add|name|type|value|save|cancel>`.
struct ExternalPlayerScreen: View {
    let app: AppModel

    @State private var model: SettingsStoreModel<ExternalPlayerPage, ExternalPlayerUiState>?

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: .retained(
            app: app, route: route, key: "settings.external",
            create: { app.session.settings.externalPlayer() },
            flow: { $0.state },
            release: { $0.release() }
        ))
    }

    var body: some View {
        if let model {
            ExternalPlayerContent(model: model)
        }
    }
}

private struct ExternalPlayerContent: View {
    let model: SettingsStoreModel<ExternalPlayerPage, ExternalPlayerUiState>

    @State private var adding = false

    var body: some View {
        let state = model.state.state
        let store = model.store
        let external = T.shared.externalPlayer
        SettingsPageFrame(title: external.title, id: SettingsPageId.externalPlayer.probe) {
            Form {
                Section {
                    SettingsToggleRow(
                        title: external.useExternalPlayer, subtitle: external.useExternalPlayerDescription, checked: state.enabled,
                        id: "settings.external.enabled", systemImage: SettingIcon.openInNew.systemImage
                    ) {
                        store.setEnabled(enabled: $0)
                    }
                }
                if state.enabled {
                    Section(external.selectPlayer) {
                        ForEach(state.players, id: \.id) { player in
                            PlayerRow(player: player) { store.select(id: player.id) }
                        }
                    }
                    Section(external.customPlayers) {
                        ForEach(state.custom, id: \.id) { player in
                            HStack {
                                PlayerRow(player: player) { store.select(id: player.id) }
                                Button(role: .destructive) { store.delete(id: player.id) } label: { Image(systemName: "trash").destructiveLabel() }
                                    .accessibilityLabel(T.shared.common.delete)
                                    .accessibilityIdentifier("settings.external.delete.\(player.id)")
                                    #if !os(tvOS)
                                    .buttonStyle(.borderless)
                                    #endif
                            }
                        }
                        SettingsLinkRow(
                            title: external.addCustomPlayer, systemImage: SettingIcon.add.systemImage, trailingSymbol: nil,
                            id: "settings.external.add"
                        ) {
                            adding = true
                        }
                    }
                }
            }
            .settingsForm()
        }
        .appSheet(isPresented: $adding) {
            AddCustomPlayerSheet(state: state, onAdd: { store.addCustom(name: $0, type: $1, value: $2) }) { adding = false }
        }
        .task { await model.state.observe() }
    }
}

/// A player: its icon, name and check; a press selects it.
private struct PlayerRow: View {
    let player: ExternalPlayerRowUi
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: player.systemDefault ? "arrow.up.right.square" : "play.circle")
                    .mutedForeground()
                    .accessibilityHidden(true)
                Text(player.name).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: player.selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(player.selected ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(.tertiary))
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .accessibilityAddTraits(player.selected ? .isSelected : [])
        .accessibilityIdentifier("settings.external.player.\(player.id)")
    }
}

/// Add Custom Player: its name, its type (where there are two) and the value, labelled and hinted per type. Save adds
/// it and closes once both fields have text; else nothing happens.
private struct AddCustomPlayerSheet: View {
    let state: ExternalPlayerUiState
    let onAdd: (String, String, String) -> Bool
    let onClose: () -> Void

    @State private var name = ""
    @State private var value = ""
    @State private var type: String

    init(state: ExternalPlayerUiState, onAdd: @escaping (String, String, String) -> Bool, onClose: @escaping () -> Void) {
        self.state = state
        self.onAdd = onAdd
        self.onClose = onClose
        _type = State(initialValue: state.customTypes.first(where: \.selected)?.id ?? state.customTypes.first?.id ?? "")
    }

    var body: some View {
        let external = T.shared.externalPlayer
        let typeLabel = state.customTypes.first(where: { $0.id == type })?.label ?? ""
        let save = SheetAction(title: T.shared.common.save, id: "settings.external.save") {
            let trimmed = (name.trimmingCharacters(in: .whitespaces), value.trimmingCharacters(in: .whitespaces))
            if onAdd(trimmed.0, type, trimmed.1) { onClose() }
        }
        let cancel = SheetAction(title: T.shared.common.cancel, id: "settings.external.cancel", action: onClose)
        SheetPage(title: external.addCustomPlayer, cancel: cancel, confirm: save) {
            Form {
                Section(external.playerName) {
                    TextField(external.playerName, text: $name, prompt: Text(external.playerNameHint))
                        .labelsHidden()
                        .accessibilityIdentifier("settings.external.name")
                        .formFieldRow()
                }
                if state.customTypes.count > 1 {
                    Section {
                        Picker(external.addCustomPlayer, selection: $type) {
                            ForEach(state.customTypes, id: \.id) { option in
                                Text(option.label).tag(option.id)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .accessibilityIdentifier("settings.external.type")
                    }
                }
                Section(typeLabel) {
                    TextField(typeLabel, text: $value, prompt: Text(state.customValueHint[type] ?? ""))
                        .labelsHidden()
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .onSubmit(save.action)
                        .accessibilityIdentifier("settings.external.value")
                        .formFieldRow()
                }
                SheetActionsSection(actions: [save, cancel])
            }
            .settingsForm()
        }
        .backAction(onClose)
    }
}
