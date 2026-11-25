#if os(macOS)
import SwiftUI
import AppKit
import Carbon.HIToolbox
import PlezyKit

/// Keyboard shortcuts (the Mac): one row per player action in default order, its id under its name and its keys in
/// a chip; a press opens the recorder. Reset in the toolbar asks first, then puts back every default.
/// Harness names: `settings.keys.<reset|row.<action>>`.
struct KeyboardShortcutsScreen: View {
    let app: AppModel

    @State private var model: SettingsStoreModel<KeyboardShortcutsPage, KeyboardShortcutsUiState>?

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: .retained(
            app: app, route: route, key: "settings.keys",
            create: { app.session.settings.keyboardShortcuts() },
            flow: { $0.state },
            release: { $0.release() }
        ))
    }

    var body: some View {
        if let model {
            KeyboardShortcutsContent(model: model)
        }
    }
}

private struct KeyboardShortcutsContent: View {
    let model: SettingsStoreModel<KeyboardShortcutsPage, KeyboardShortcutsUiState>

    @State private var recording: String?
    @State private var resetting = false
    @State private var toast: String?

    var body: some View {
        let state = model.state.state
        let store = model.store
        SettingsPageFrame(title: T.shared.settings.keyboardShortcuts, id: SettingsPageId.keyboardShortcuts.probe) {
            Form {
                Section {
                    ForEach(state.rows, id: \.actionId) { row in
                        SettingsLinkRow(title: row.title, subtitle: row.actionId, trailingSymbol: nil, id: "settings.keys.row.\(row.actionId)") {
                            recording = row.actionId
                        } accessory: {
                            KeyChip(keys: row.keys, unset: row.unset)
                        }
                    }
                }
            }
            .settingsForm()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(T.shared.common.reset) { resetting = true }
                    .accessibilityIdentifier("settings.keys.reset")
            }
        }
        .appSheet(item: recording, onDismiss: { recording = nil }) { actionId in
            if let row = state.rows.first(where: { $0.actionId == actionId }) {
                ShortcutRecorderSheet(title: row.title, recorder: store.recorder(actionId: actionId)) { recording = nil }
            }
        }
        .confirmation(
            resetting
                ? Confirmation(
                    title: T.shared.settings.resetToDefault, message: T.shared.settings.resetShortcutsConfirm,
                    confirmLabel: T.shared.common.reset, cancelLabel: T.shared.common.cancel,
                    confirmId: "settings.confirm.ok", cancelId: "settings.confirm.cancel"
                )
                : nil,
            onConfirm: {
                resetting = false
                store.resetAll()
            },
            onCancel: { resetting = false }
        )
        .toast(toast, id: "settings.toast") { toast = nil }
        .task { await model.state.observe() }
        .task {
            for await message in store.messages { toast = message.text }
        }
    }
}

/// A hotkey as it reads ("⌘ + →"), monospace in a bordered chip; "No shortcut set" dimmed when `unset`.
private struct KeyChip: View {
    let keys: String
    let unset: Bool

    var body: some View {
        Text(keys)
            .font(.body.monospaced())
            .foregroundStyle(unset ? AnyShapeStyle(Palette.onSurfaceVariant) : AnyShapeStyle(.primary))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.outline, lineWidth: 1))
    }
}

/// The recorder: "Press the shortcut now" over the shortcut it would save; the next key pressed with its modifiers (a
/// modifier alone waits for the key; Escape closes it, Tab moves on) becomes the shared recorder's edit, as its USB HID
/// usage, and so does Clear shortcut. Save stores the edit: saved, or taken by another action ("already assigned", the
/// page's toast), closes the sheet; a failure ("Error") keeps it open to retry. Cancel discards it.
/// Harness names: `settings.keys.<capture|clear|save|cancel|error>`.
private struct ShortcutRecorderSheet: View {
    let title: String
    let onClose: () -> Void
    /// Kept for the sheet's life: the page rebuilds this view, which must keep its edit.
    @State private var recorder: ShortcutRecorder
    @State private var observed: StoreObserver<ShortcutRecorderUiState>
    @State private var monitor: Any?

    init(title: String, recorder: ShortcutRecorder, onClose: @escaping () -> Void) {
        self.title = title
        self.onClose = onClose
        _recorder = State(initialValue: recorder)
        _observed = State(initialValue: StoreObserver(recorder.state))
    }

    var body: some View {
        let state = observed.state
        let hotkeys = T.shared.hotkeys
        let clear = SheetAction(
            title: hotkeys.clearShortcut, id: "settings.keys.clear", role: .destructive, enabled: !state.unset && !state.saving
        ) { recorder.clear() }
        let cancel = SheetAction(title: T.shared.common.cancel, id: "settings.keys.cancel", enabled: !state.saving, action: onClose)
        let save = SheetAction(title: T.shared.common.save, id: "settings.keys.save", enabled: state.canSave) {
            let box = UncheckedBox(recorder)
            Task {
                if await Self.save(box)?.closesRecorder == true { onClose() }
            }
        }
        SheetPage(title: hotkeys.setShortcutFor(actionName: title), cancel: cancel, confirm: save) {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Text(hotkeys.recordingShortcut).font(.title3)
                        Text("\(hotkeys.currentShortcut) \(state.keys)").font(.body.monospaced()).mutedForeground()
                    }
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("settings.keys.capture")
                } footer: {
                    if state.failed {
                        Text(T.shared.common.error)
                            .foregroundStyle(Palette.error)
                            .accessibilityIdentifier("settings.keys.error")
                    }
                }
                Section {
                    Button(clear.title, role: .destructive, action: clear.action)
                        .disabled(!clear.enabled)
                        .accessibilityIdentifier(clear.id)
                }
            }
            .settingsForm()
        }
        .task { await observed.observe() }
        .onAppear(perform: startCapture)
        .onDisappear(perform: stopCapture)
    }

    /// Takes the window's key presses while the recorder is open: Escape and Tab go on to the sheet, a modifier alone
    /// is a flags change and never comes here, and any other key is captured and swallowed.
    private func startCapture() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) || event.keyCode == UInt16(kVK_Tab) { return event }
            let key = (code: event.keyCode, flags: event.modifierFlags)
            MainActor.assumeIsolated { capture(keyCode: key.code, flags: key.flags) }
            return nil
        }
    }

    private func stopCapture() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private func capture(keyCode: UInt16, flags: NSEvent.ModifierFlags) {
        guard let hid = Self.hidUsages[Int(keyCode)] else { return }
        var modifiers = Set<String>()
        if flags.contains(.option) { modifiers.insert("alt") }
        if flags.contains(.control) { modifiers.insert("control") }
        if flags.contains(.shift) { modifiers.insert("shift") }
        if flags.contains(.command) { modifiers.insert("meta") }
        recorder.capture(hidUsage: hid, modifiers: modifiers)
    }

    nonisolated private static func save(_ recorder: UncheckedBox<ShortcutRecorder>) async -> ShortcutResult? {
        try? await recorder.value.save()
    }

    /// The USB HID usage (keyboard page 0x07) of each Mac virtual key code: what shortcuts are stored as, the same key
    /// on every platform.
    private static let hidUsages: [Int: Int64] = [
        kVK_ANSI_A: 0x0007_0004, kVK_ANSI_B: 0x0007_0005, kVK_ANSI_C: 0x0007_0006, kVK_ANSI_D: 0x0007_0007,
        kVK_ANSI_E: 0x0007_0008, kVK_ANSI_F: 0x0007_0009, kVK_ANSI_G: 0x0007_000A, kVK_ANSI_H: 0x0007_000B,
        kVK_ANSI_I: 0x0007_000C, kVK_ANSI_J: 0x0007_000D, kVK_ANSI_K: 0x0007_000E, kVK_ANSI_L: 0x0007_000F,
        kVK_ANSI_M: 0x0007_0010, kVK_ANSI_N: 0x0007_0011, kVK_ANSI_O: 0x0007_0012, kVK_ANSI_P: 0x0007_0013,
        kVK_ANSI_Q: 0x0007_0014, kVK_ANSI_R: 0x0007_0015, kVK_ANSI_S: 0x0007_0016, kVK_ANSI_T: 0x0007_0017,
        kVK_ANSI_U: 0x0007_0018, kVK_ANSI_V: 0x0007_0019, kVK_ANSI_W: 0x0007_001A, kVK_ANSI_X: 0x0007_001B,
        kVK_ANSI_Y: 0x0007_001C, kVK_ANSI_Z: 0x0007_001D,
        kVK_ANSI_1: 0x0007_001E, kVK_ANSI_2: 0x0007_001F, kVK_ANSI_3: 0x0007_0020, kVK_ANSI_4: 0x0007_0021,
        kVK_ANSI_5: 0x0007_0022, kVK_ANSI_6: 0x0007_0023, kVK_ANSI_7: 0x0007_0024, kVK_ANSI_8: 0x0007_0025,
        kVK_ANSI_9: 0x0007_0026, kVK_ANSI_0: 0x0007_0027,
        kVK_Return: 0x0007_0028, kVK_Delete: 0x0007_002A, kVK_Space: 0x0007_002C,
        kVK_ANSI_Minus: 0x0007_002D, kVK_ANSI_Equal: 0x0007_002E, kVK_ANSI_LeftBracket: 0x0007_002F,
        kVK_ANSI_RightBracket: 0x0007_0030, kVK_ANSI_Backslash: 0x0007_0031, kVK_ANSI_Semicolon: 0x0007_0033,
        kVK_ANSI_Quote: 0x0007_0034, kVK_ANSI_Grave: 0x0007_0035, kVK_ANSI_Comma: 0x0007_0036,
        kVK_ANSI_Period: 0x0007_0037, kVK_ANSI_Slash: 0x0007_0038, kVK_CapsLock: 0x0007_0039,
        kVK_F1: 0x0007_003A, kVK_F2: 0x0007_003B, kVK_F3: 0x0007_003C, kVK_F4: 0x0007_003D, kVK_F5: 0x0007_003E,
        kVK_F6: 0x0007_003F, kVK_F7: 0x0007_0040, kVK_F8: 0x0007_0041, kVK_F9: 0x0007_0042, kVK_F10: 0x0007_0043,
        kVK_F11: 0x0007_0044, kVK_F12: 0x0007_0045,
        kVK_Help: 0x0007_0049, kVK_Home: 0x0007_004A, kVK_PageUp: 0x0007_004B, kVK_ForwardDelete: 0x0007_004C,
        kVK_End: 0x0007_004D, kVK_PageDown: 0x0007_004E,
        kVK_RightArrow: 0x0007_004F, kVK_LeftArrow: 0x0007_0050, kVK_DownArrow: 0x0007_0051, kVK_UpArrow: 0x0007_0052,
        kVK_ANSI_KeypadClear: 0x0007_0053, kVK_ANSI_KeypadDivide: 0x0007_0054, kVK_ANSI_KeypadMultiply: 0x0007_0055,
        kVK_ANSI_KeypadMinus: 0x0007_0056, kVK_ANSI_KeypadPlus: 0x0007_0057, kVK_ANSI_KeypadEnter: 0x0007_0058,
        kVK_ANSI_Keypad1: 0x0007_0059, kVK_ANSI_Keypad2: 0x0007_005A, kVK_ANSI_Keypad3: 0x0007_005B,
        kVK_ANSI_Keypad4: 0x0007_005C, kVK_ANSI_Keypad5: 0x0007_005D, kVK_ANSI_Keypad6: 0x0007_005E,
        kVK_ANSI_Keypad7: 0x0007_005F, kVK_ANSI_Keypad8: 0x0007_0060, kVK_ANSI_Keypad9: 0x0007_0061,
        kVK_ANSI_Keypad0: 0x0007_0062, kVK_ANSI_KeypadDecimal: 0x0007_0063,
    ]
}
#endif
