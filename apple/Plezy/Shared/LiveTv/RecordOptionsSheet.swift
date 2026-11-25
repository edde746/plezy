import SwiftUI
import PlezyKit

/// The Record Options sheet (`RecordOptionsUiState`), a modal settings form: "Record options" (or "Edit rule") over
/// the airing's or rule's title; the rule entries as a choice (a checkmark on the picked one) when the template offers
/// several; "Save to" and its library (a picker when there is a choice); one row per setting (a switch, a picker, a
/// text field; a number field takes digits only), or the airings type when there are none; Cancel and Record (or
/// Save), off while saving.
///
/// Accessibility identifiers: `livetv.record`, `livetv.record.entry.<index>`, `livetv.record.target`,
/// `livetv.record.setting.<id>`, `livetv.record.cancel`, `livetv.record.save`.
struct RecordOptionsSheet: View {
    let store: RecordOptionsStore

    @State private var observer: StoreObserver<RecordOptionsUiState>

    init(store: RecordOptionsStore) {
        self.store = store
        _observer = State(initialValue: StoreObserver(store.state))
    }

    var body: some View {
        let state = observer.state
        let cancel = SheetAction(title: state.cancelLabel, id: "livetv.record.cancel", enabled: !state.saving) { store.cancel() }
        let save = SheetAction(title: state.saveLabel, id: "livetv.record.save", enabled: !state.saving) { store.save() }
        SheetPage(id: "livetv.record", title: state.title, cancel: cancel, confirm: save) {
            Form {
                Section {
                    ForEach(Array(state.entries.enumerated()), id: \.offset) { index, entry in
                        Button { store.selectEntry(index: Int32(index)) } label: {
                            HStack {
                                Text(entry.title).frame(maxWidth: .infinity, alignment: .leading)
                                if entry.selected {
                                    Image(systemName: "checkmark").fontWeight(.semibold).foregroundStyle(Palette.primary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .formRowButtonStyle()
                        .disabled(state.saving)
                        .accessibilityAddTraits(entry.selected ? .isSelected : [])
                        .accessibilityIdentifier("livetv.record.entry.\(index)")
                    }
                } header: {
                    Text(state.subtitle)
                }
                Section {
                    if let target = state.target {
                        if target.options.isEmpty {
                            LabeledContent(target.label, value: target.value)
                                .accessibilityIdentifier("livetv.record.target")
                        } else {
                            SettingsChoicePicker(
                                row: SettingChoiceRow(
                                    id: "target", title: target.label, caption: nil,
                                    options: target.options.map {
                                        SettingChoiceOption(id: String($0.sectionId), label: $0.title, selected: $0.selected, subtitle: nil)
                                    },
                                    unselectedLabel: target.value, enabled: !state.saving, icon: nil
                                ),
                                id: "livetv.record.target",
                                valueBeside: true
                            ) { id in
                                if let section = Int32(id) { store.selectTarget(sectionId: section) }
                            }
                        }
                    }
                }
                Section {
                    if let empty = state.emptyText {
                        Text(empty).mutedForeground()
                    }
                    ForEach(Array(state.settings.enumerated()), id: \.offset) { _, row in
                        settingRow(row, enabled: !state.saving)
                    }
                }
                SheetActionsSection(actions: [save, cancel])
            }
            .settingsForm(idle: state.saving)
        }
        .task { await observer.observe() }
    }

    @ViewBuilder
    private func settingRow(_ row: any RecordSettingRow, enabled: Bool) -> some View {
        let id = "livetv.record.setting.\(row.id)"
        switch onEnum(of: row) {
        case .toggle(let toggle):
            SettingsToggleRow(title: toggle.label, subtitle: toggle.summary, checked: toggle.checked, id: id, enabled: enabled) {
                store.setToggle(id: toggle.id, checked: $0)
            }
        case .choice(let choice):
            SettingsChoicePicker(
                row: SettingChoiceRow(
                    id: choice.id, title: choice.label, caption: choice.summary,
                    options: choice.options.map { SettingChoiceOption(id: $0.value, label: $0.label, selected: $0.selected, subtitle: nil) },
                    unselectedLabel: choice.value, enabled: enabled, icon: nil
                ),
                id: id,
                valueBeside: true
            ) { store.setChoice(id: choice.id, value: $0) }
        case .field(let field):
            RecordTextField(field: field, id: id) { store.setText(id: field.id, text: $0) }
                .disabled(!enabled)
        }
    }
}

/// A text setting: its label (and summary) over a field holding the store's text; a number field shows the number pad.
private struct RecordTextField: View {
    let field: RecordSettingRowField
    let id: String
    let onChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SettingsRowText(title: field.label, subtitle: field.summary)
            TextField(field.label, text: Binding(get: { field.text }, set: onChange))
                .labelsHidden()
                #if os(iOS)
                .keyboardType(field.numeric ? .numbersAndPunctuation : .default)
                #endif
                .accessibilityIdentifier(id)
        }
    }
}
