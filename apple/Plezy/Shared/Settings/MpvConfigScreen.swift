import SwiftUI
import PlezyKit

/// mpv.conf: the one document, as a monospace text editor (iOS, macOS) or, on Apple TV, one field per line with
/// Remove line and Add line; the Linux note; then the presets (Save as Preset..., each preset loading on a press, with
/// Delete). Edits save on their own, debounced by the store; Back waits for the last one and stays, saying so, when
/// it failed (on Apple TV, whose Back the system handles, a page left writes what is pending as it goes).
/// Harness names: `settings.mpv.<text|line.i|line.i.number|line.i.remove|addLine|savePreset|preset.i|preset.i.delete>`.
struct MpvConfigScreen: View {
    let app: AppModel

    @State private var model: SettingsStoreModel<any MpvConfigStore, MpvConfigUiState>?

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: .retained(
            app: app, route: route, key: "settings.mpv",
            create: { app.session.settings.mpvConfig() },
            flow: { $0.state },
            release: { $0.release() }
        ))
    }

    var body: some View {
        if let model {
            MpvConfigContent(app: app, model: model)
        }
    }
}

private struct MpvConfigContent: View {
    let app: AppModel
    let model: SettingsStoreModel<any MpvConfigStore, MpvConfigUiState>

    @State private var text = ""
    @State private var toast: String?
    @State private var naming = false
    @State private var deleting: String?
    /// The line editor's field with focus, by line.
    @FocusState private var focusedLine: Int?
    /// The line Add line asked for, focused once the store has added it.
    @State private var addedLine: Int?

    var body: some View {
        let state = model.state.state
        let store = model.store
        let mpv = T.shared.mpvConfig
        SettingsPageFrame(title: mpv.title, id: SettingsPageId.mpvConfig.probe) {
            Form {
                Section {
                    #if os(tvOS)
                    lineRows(state, store)
                    #else
                    if state.lineEditor {
                        lineRows(state, store)
                    } else {
                        TextEditor(text: $text)
                            .font(.footnote.monospaced())
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .frame(minHeight: 240)
                            .overlay(alignment: .topLeading) {
                                if text.isEmpty {
                                    Text(mpv.configPlaceholder)
                                        .font(.footnote.monospaced())
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }
                            .accessibilityIdentifier("settings.mpv.text")
                    }
                    #endif
                } footer: {
                    if let note = state.linuxNote {
                        Text(note)
                            .foregroundStyle(Palette.onSurfaceVariant)
                    }
                }
                Section {
                    Button { naming = true } label: { Label(mpv.saveAsPreset, systemImage: SettingIcon.save.systemImage) }
                        .disabled(!state.canSavePreset)
                        .accessibilityIdentifier("settings.mpv.savePreset")
                    ForEach(Array(state.presets.enumerated()), id: \.element) { index, name in
                        HStack {
                            Button { store.loadPreset(name: name) } label: {
                                Label(name, systemImage: SettingIcon.folder.systemImage)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .accessibilityIdentifier("settings.mpv.preset.\(index)")
                            Button(role: .destructive) { deleting = name } label: { Image(systemName: "trash").destructiveLabel() }
                                .accessibilityLabel(mpv.deletePreset)
                                .accessibilityIdentifier("settings.mpv.preset.\(index).delete")
                                #if !os(tvOS)
                                .buttonStyle(.borderless)
                                #endif
                        }
                    }
                } header: {
                    Text(mpv.presets)
                        .foregroundStyle(Palette.onSurfaceVariant)
                } footer: {
                    if state.presets.isEmpty {
                        Text(mpv.noPresets)
                            .foregroundStyle(Palette.onSurfaceVariant)
                    }
                }
            }
            .settingsForm()
        }
        #if !os(tvOS)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: leave) { Image(systemName: "chevron.backward") }
                    .accessibilityLabel(T.shared.nav.back)
                    .accessibilityIdentifier("settings.mpv.back")
            }
        }
        #endif
        .appSheet(isPresented: $naming) {
            SettingTextSheet(
                row: SettingTextRow(
                    id: "presetName", title: mpv.presetName, caption: nil, value: "", fieldLabel: mpv.presetName,
                    hint: mpv.presetNameHint, resetLabel: nil, monospace: false, icon: nil
                ),
                onSave: { name in
                    if !name.trimmingCharacters(in: .whitespaces).isEmpty { savePreset(name) }
                    return nil
                },
                onReset: { "" },
                onClose: { naming = false }
            )
        }
        .confirmation(
            deleting.map { _ in
                Confirmation(
                    title: mpv.deletePreset, message: mpv.confirmDeletePreset, confirmLabel: mpv.deletePreset,
                    cancelLabel: T.shared.common.cancel, confirmId: "settings.confirm.ok", cancelId: "settings.confirm.cancel"
                )
            },
            onConfirm: {
                if let name = deleting { store.deletePreset(name: name) }
                deleting = nil
            },
            onCancel: { deleting = nil }
        )
        .toast(toast, id: "settings.toast") { toast = nil }
        .onChange(of: state.text, initial: true) { _, stored in
            if text != stored { text = stored }
        }
        .onChange(of: text) { _, typed in
            if typed != model.state.state.text { store.edit(text: typed) }
        }
        .task { await model.state.observe() }
        .task {
            for await message in store.messages { toast = message.text }
        }
        #if os(tvOS)
        .onDisappear { Task { _ = await Self.flush(UncheckedBox(store)) } }
        #endif
    }

    /// The TV line editor: a row per line, then Add line, which puts focus in the new line's field (Select opens its
    /// keyboard).
    @ViewBuilder
    private func lineRows(_ state: MpvConfigUiState, _ store: any MpvConfigStore) -> some View {
        ForEach(Array(state.lines.enumerated()), id: \.offset) { index, line in
            ConfigLine(index: index, line: line, store: store, focus: $focusedLine)
        }
        Button {
            addedLine = state.lines.count
            store.addLine()
        } label: { Label(T.shared.mpvConfig.addLine, systemImage: "plus") }
            .accessibilityIdentifier("settings.mpv.addLine")
            .onChange(of: state.lines.count) { _, count in
                guard let added = addedLine, added < count else { return }
                addedLine = nil
                focusedLine = added
            }
    }

    /// Back: once what is pending is written; a write that failed keeps the page, saying so.
    private func leave() {
        let store = UncheckedBox(model.store)
        Task {
            if await Self.flush(store) {
                app.navigator.back()
            } else {
                toast = T.shared.settings.saveFailed
            }
        }
    }

    /// Writes what is pending, after the last edit; then stores the document as the preset `name`.
    private func savePreset(_ name: String) {
        let store = UncheckedBox(model.store)
        Task {
            if await Self.flush(store) {
                store.value.savePreset(name: name.trimmingCharacters(in: .whitespaces))
            } else {
                toast = T.shared.settings.saveFailed
            }
        }
    }

    /// The store's pending write, awaited; false when it failed.
    nonisolated private static func flush(_ store: UncheckedBox<any MpvConfigStore>) async -> Bool {
        (try? await store.value.flush())?.boolValue ?? false
    }
}

/// One line of the Apple TV line editor: its number, the line in a field (a pasted text's lines become rows) and
/// Remove line, a round button of its own: a plain button makes the form's whole row the button on Apple TV, which
/// turns white behind the number and the field as it takes focus.
private struct ConfigLine: View {
    let index: Int
    let line: String
    let store: any MpvConfigStore
    let focus: FocusState<Int?>.Binding

    @State private var text: String

    init(index: Int, line: String, store: any MpvConfigStore, focus: FocusState<Int?>.Binding) {
        self.index = index
        self.line = line
        self.store = store
        self.focus = focus
        _text = State(initialValue: line)
    }

    var body: some View {
        HStack(spacing: 16) {
            Text("\(index + 1)")
                .font(.body.monospaced())
                .mutedForeground()
                .frame(width: 48, alignment: .trailing)
                .accessibilityIdentifier("settings.mpv.line.\(index).number")
            TextField(T.shared.mpvConfig.lineHint, text: $text, prompt: Text(T.shared.mpvConfig.lineHint))
                .font(.body.monospaced())
                .autocorrectionDisabled()
                .focused(focus, equals: index)
                .accessibilityIdentifier("settings.mpv.line.\(index)")
            IconButton(systemImage: "xmark", label: T.shared.mpvConfig.removeLine, id: "settings.mpv.line.\(index).remove") {
                store.removeLine(index: Int32(index))
            }
        }
        .onChange(of: line) { _, stored in
            if text != stored { text = stored }
        }
        .onChange(of: text) { _, typed in
            if typed != line { store.editLine(index: Int32(index), text: typed) }
        }
    }
}
