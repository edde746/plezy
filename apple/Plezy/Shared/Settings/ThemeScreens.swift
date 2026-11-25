import SwiftUI
import PlezyKit

/// The theme picker: the themes in their groups (Built-in; Presets and Custom where the Supporter perks are offered),
/// each with its swatch, a lock on a locked perk, its note and a check on the one that paints. Custom also opens the
/// editor (a chevron says so): a sheet on iOS and macOS, a pushed page on Apple TV. A pick applies at once. On Apple TV
/// the theme that paints is focused first. Harness names: `settings.theme.<mode>`.
struct ThemePickerScreen: View {
    let app: AppModel

    @State private var model: SettingsStoreModel<ThemePickerPage, ThemePickerUiState>?

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: .retained(
            app: app, route: route, key: "settings.theme",
            create: { app.session.settings.themePicker() },
            flow: { $0.state },
            release: { $0.release() }
        ))
    }

    var body: some View {
        if let model {
            ThemePickerContent(app: app, model: model)
        }
    }
}

private struct ThemePickerContent: View {
    let app: AppModel
    let model: SettingsStoreModel<ThemePickerPage, ThemePickerUiState>

    @FocusState private var focused: String?
    #if os(tvOS)
    /// The theme that paints as focus was last given to it: given again only when it changes (the store's first
    /// state, read before the stored theme, has the default), not as the picker shows again after the editor.
    @State private var focusGiven: ThemeMode?
    #endif
    @State private var supporterOpen = false
    #if !os(tvOS)
    @State private var editor: CustomThemeEditorItem?
    @Environment(\.colorScheme) private var colorScheme
    #endif

    var body: some View {
        let state = model.state.state
        let store = model.store
        SettingsPageFrame(title: T.shared.settings.theme, id: SettingsPageId.theme.probe) {
            Form {
                ForEach(state.groups, id: \.id) { group in
                    Section {
                        ForEach(group.rows, id: \.mode) { row in
                            ThemeRow(row: row) { store.choose(mode: row.mode) }
                                .focused($focused, equals: row.mode.key)
                        }
                    } header: {
                        if let header = group.header { Text(header) }
                    }
                }
            }
            .settingsForm()
        }
        .task { await model.state.observe() }
        .task {
            for await event in store.events {
                switch onEnum(of: event) {
                case .openEditor:
                    #if os(tvOS)
                    app.navigator.navigate(route: RouteSettingsPage(page: .customTheme, arg: nil))
                    #else
                    editor = CustomThemeEditorItem(model: .owned(
                        create: { app.session.settings.customThemeEditor(systemDark: colorScheme == .dark) },
                        flow: { $0.state },
                        release: { $0.release() }
                    ))
                    #endif
                case .openSupporter:
                    supporterOpen = true
                }
            }
        }
        .appSheet(isPresented: $supporterOpen) {
            SupporterSheet(store: app.session.supporterSheet) {
                supporterOpen = false
                store.supporterClosed(unlocked: app.session.supporter.unlocked.value.boolValue)
            }
        }
        #if !os(tvOS)
        .appSheet(item: editor, size: .fullHeightForm, onDismiss: closeEditor) { item in
            NavigationStack {
                CustomThemeEditorForm(model: item.model, onClose: closeEditor)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SettingsPageId.customTheme.probe)
            }
        }
        #endif
        #if os(tvOS)
        .task(id: state.focusedMode) {
            let mode = state.focusedMode
            guard focusGiven != mode else { return }
            focusGiven = mode
            await FocusRestore.restore($focused, to: mode.key, replacing: true)
        }
        #endif
    }

    #if !os(tvOS)
    private func closeEditor() {
        editor?.model.release()
        editor = nil
    }
    #endif
}

extension ThemeMode {
    /// The theme's stored name, lower case: its harness name's end.
    var key: String {
        switch self {
        case .system: "system"
        case .light: "light"
        case .dark: "dark"
        case .oled: "oled"
        case .ember: "ember"
        case .glacier: "glacier"
        case .forest: "forest"
        case .plum: "plum"
        case .paper: "paper"
        case .custom: "custom"
        }
    }
}

/// One theme, built like a `SettingsChoicePicker` option: its swatch in the icon's place, name and note, its value
/// beside them (Custom: "Not created"), a lock when it is a locked perk (picking it opens the Supporter sheet), a check
/// on the theme that paints; Custom, which opens its editor, a chevron.
private struct ThemeRow: View {
    let row: ThemeRowUi
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            HStack(spacing: 16) {
                ThemeSwatch(palette: row.palette, split: row.splitPalette)
                SettingsRowText(title: row.label, subtitle: row.note)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let value = row.value {
                    Text(value).mutedForeground()
                }
                if row.locked {
                    Image(systemName: "lock.fill")
                        .mutedForeground()
                        .accessibilityLabel(T.shared.themeEditor.locked)
                }
                if row.selected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.primary)
                        .accessibilityHidden(true)
                }
                if row.mode == .custom, !row.locked {
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .mutedForeground()
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .accessibilityAddTraits(row.selected ? .isSelected : [])
        .accessibilityIdentifier("settings.theme.\(row.mode.key)")
    }
}

/// A theme's swatch, 36 pt: its background with its surface, text and accent in it; with `split` the left half
/// `palette`'s and the right half `split`'s (System: light and dark); without a palette an empty slot with "+"
/// (Custom not created yet).
private struct ThemeSwatch: View {
    let palette: PlezyKit.Palette?
    let split: PlezyKit.Palette?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10)
        Group {
            if let palette {
                HStack(spacing: 0) {
                    half(palette)
                    if let split { half(split) }
                }
                .clipShape(shape)
                .overlay(shape.strokeBorder(Color(argb: palette.outline), lineWidth: 1))
            } else {
                Image(systemName: "plus")
                    .font(.footnote)
                    .mutedForeground()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(shape.strokeBorder(Palette.onSurfaceVariant, lineWidth: 1.5))
            }
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }

    private func half(_ palette: PlezyKit.Palette) -> some View {
        VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2).fill(Color(argb: palette.surface)).frame(height: 6)
            RoundedRectangle(cornerRadius: 1).fill(Color(argb: palette.text)).frame(height: 3).padding(.horizontal, 2)
            Circle().fill(Color(argb: palette.accent)).frame(width: 8, height: 8)
        }
        .padding(5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(argb: palette.bg))
    }
}

#if os(tvOS)
/// Apple TV's custom theme editor, a page pushed over the theme picker, its store kept for the route (the editor told
/// the system is dark: Apple TV's System is).
struct CustomThemeEditorRoute: View {
    let app: AppModel

    @State private var model: SettingsStoreModel<CustomThemeEditorPage, CustomThemeEditorUiState>?

    init(app: AppModel, route: any Route) {
        self.app = app
        _model = State(initialValue: .retained(
            app: app, route: route, key: "settings.customTheme",
            create: { app.session.settings.customThemeEditor(systemDark: true) },
            flow: { $0.state },
            release: { $0.release() }
        ))
    }

    var body: some View {
        if let model {
            CustomThemeEditorForm(model: model) { app.navigator.back() }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SettingsPageId.customTheme.probe)
        }
    }
}
#else
/// The custom theme editor's sheet: its store, owned by the theme picker while the sheet is up; equal by identity.
struct CustomThemeEditorItem: Equatable {
    let model: SettingsStoreModel<CustomThemeEditorPage, CustomThemeEditorUiState>

    static func == (lhs: CustomThemeEditorItem, rhs: CustomThemeEditorItem) -> Bool {
        lhs.model === rhs.model
    }
}
#endif

/// The custom theme editor as a form: a live preview of the draft, "Start from" another theme, then the six colour
/// slots, each with its code to type and, on iOS and macOS, the system's colour picker; on Apple TV, which has none, a
/// slot opens a panel of the other themes' colours and the hue, saturation, brightness and opacity that Left and Right
/// move. Contrast warnings under the slots (they never block Save), Reset in the form; Save and Cancel in the sheet's
/// bar (on Apple TV the form's last buttons). Save stores the palette, makes Custom the theme and closes (`onClose`);
/// leaving with unsaved changes asks first, and the sheet takes no swipe away then.
/// Harness names: `settings.custom.<preview|startFrom|slot.i|slot.i.hex|swatch.i|reset|cancel|save|discard|keep>`.
struct CustomThemeEditorForm: View {
    let model: SettingsStoreModel<CustomThemeEditorPage, CustomThemeEditorUiState>
    let onClose: () -> Void

    @State private var discarding = false
    @State private var toast: String?
    #if os(tvOS)
    @State private var slotOpen = false
    #else
    /// The slot whose code is being typed and the text so far: the field shows what was typed, not the store's echo.
    @State private var typing: (slot: Int, text: String)?
    @FocusState private var hexFocus: Int?
    #endif

    var body: some View {
        let state = model.state.state
        let store = model.store
        let editor = T.shared.themeEditor
        let save = SheetAction(title: T.shared.common.save, id: "settings.custom.save", enabled: !state.saving) { store.save() }
        let cancel = SheetAction(title: T.shared.common.cancel, id: "settings.custom.cancel", enabled: !state.saving) { leave(state) }
        Form {
            Section {
                ThemePreview(palette: state.draft)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            Section {
                SettingsChoicePicker(
                    row: SettingChoiceRow(
                        id: "startFrom", title: editor.startFrom, caption: editor.startFromDescription,
                        options: state.startFromOptions, unselectedLabel: "", enabled: true, icon: .palette
                    ),
                    id: "settings.custom.startFrom"
                ) {
                    store.startFrom(optionId: $0)
                }
            }
            Section {
                ForEach(Array(state.slots.enumerated()), id: \.element.id) { index, slot in
                    slotRow(index, slot, state: state, store: store)
                }
            } header: {
                Text(editor.colors)
            } footer: {
                #if !os(tvOS)
                Text(editor.hexHint)
                    .foregroundStyle(typing != nil && state.hexInvalid ? Palette.error : Palette.onSurfaceVariant)
                #endif
            }
            if !state.warnings.isEmpty {
                Section {
                    ForEach(state.warnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .mutedForeground()
                    }
                }
            }
            Section {
                Button(role: .destructive) { store.reset() } label: { Text(T.shared.common.reset).destructiveLabel() }
                    .disabled(!state.dirty || state.saving)
                    .accessibilityIdentifier("settings.custom.reset")
            }
            SheetActionsSection(actions: [save, cancel])
        }
        .settingsForm()
        .pageTitle(editor.title)
        .sheetToolbar(cancel: cancel, confirm: save)
        .interactiveDismissDisabled(state.dirty)
        .backAction(state.dirty && !state.saved ? { discarding = true } : nil)
        #if os(tvOS)
        .trailingPanel(isPresented: $slotOpen, id: "settings.custom.slot.panel") {
            CustomThemeSlotPanel(model: model)
        }
        #else
        .onChange(of: hexFocus) { _, focused in
            if focused == nil, typing != nil {
                typing = nil
                store.submitHex()
            }
        }
        #endif
        .confirmation(
            discarding
                ? Confirmation(
                    title: editor.discardTitle, message: editor.discardMessage, confirmLabel: editor.discard,
                    cancelLabel: T.shared.common.cancel, confirmId: "settings.custom.discard", cancelId: "settings.custom.keep"
                )
                : nil,
            onConfirm: {
                discarding = false
                onClose()
            },
            onCancel: { discarding = false }
        )
        .toast(toast, id: "settings.toast") { toast = nil }
        .onChange(of: state.saved) { _, saved in
            if saved { onClose() }
        }
        .task { await model.state.observe() }
        .task {
            for await message in store.messages { toast = message.text }
        }
    }

    /// A colour slot: its name, its code and its colour. On iOS and macOS the code is a field (typing selects the slot;
    /// a valid code updates the draft) and the colour the system's colour picker; on Apple TV the row opens the slot's
    /// panel.
    @ViewBuilder
    private func slotRow(
        _ index: Int, _ slot: ColorSlotUi, state: CustomThemeEditorUiState, store: CustomThemeEditorPage
    ) -> some View {
        #if os(tvOS)
        SettingsLinkRow(
            title: slot.label, subtitle: slot.hex, systemImage: nil, id: "settings.custom.slot.\(index)",
            action: {
                store.selectSlot(index: Int32(index))
                slotOpen = true
            },
            accessory: { ColorSwatch(color: SettingsHsv(hex: slot.hex).color, size: 40) }
        )
        #else
        let select = {
            if index != Int(state.selectedSlot) { store.selectSlot(index: Int32(index)) }
        }
        let hex = Binding(
            get: { typing?.slot == index ? typing?.text ?? "" : slot.hex },
            set: { typed in
                select()
                typing = (index, typed)
                store.editHex(text: typed)
            }
        )
        let color = Binding(
            get: { SettingsHsv(hex: slot.hex).color },
            set: { picked in
                select()
                store.pickSwatch(hex: SettingsHsv(color: picked).hex(alpha: true))
            }
        )
        HStack(spacing: 12) {
            Text(slot.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField(slot.label, text: hex)
                .labelsHidden()
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
                .font(.body.monospaced())
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 130)
                .focused($hexFocus, equals: index)
                .onSubmit {
                    typing = nil
                    store.submitHex()
                }
                .accessibilityIdentifier("settings.custom.slot.\(index).hex")
            #if os(iOS)
            ColorWell(title: slot.label, color: color)
                .frame(width: 44, height: 44)
                .accessibilityIdentifier("settings.custom.slot.\(index).color")
            #else
            ColorPicker(slot.label, selection: color, supportsOpacity: true)
                .labelsHidden()
            #endif
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings.custom.slot.\(index)")
        #endif
    }

    /// Cancel: closes, unless there are changes to lose, which it asks about first.
    private func leave(_ state: CustomThemeEditorUiState) {
        if state.dirty { discarding = true } else { onClose() }
    }
}

#if os(tvOS)
/// Apple TV's panel for the selected colour slot: its colour and code, the other themes' colours, then hue, saturation,
/// brightness and opacity that Left and Right move, and the code to type (`HsvValues`). Every change goes to the draft
/// at once; Menu closes the panel.
private struct CustomThemeSlotPanel: View {
    let model: SettingsStoreModel<CustomThemeEditorPage, CustomThemeEditorUiState>

    var body: some View {
        let state = model.state.state
        let store = model.store
        let slot = state.slots.indices.contains(Int(state.selectedSlot)) ? state.slots[Int(state.selectedSlot)] : nil
        Form {
            Section {
                HStack(spacing: 24) {
                    ColorSwatch(color: SettingsHsv(hex: slot?.hex ?? "").color, size: 56)
                    Text(state.hexText).font(.title3.monospaced())
                }
            } header: {
                Text(slot?.label ?? "")
            }
            if !state.quickSwatches.isEmpty {
                Section(T.shared.themeEditor.fromOtherThemes) {
                    SwatchGrid(swatches: state.quickSwatches, selected: state.hexText, probe: "settings.custom.swatch") {
                        store.pickSwatch(hex: $0)
                    }
                }
            }
            Section {
                HsvValues(
                    hsv: Binding(
                        get: {
                            SettingsHsv(
                                hue: Double(state.hue), saturation: Double(state.saturation),
                                brightness: Double(state.brightness), opacity: Double(state.opacity)
                            )
                        },
                        set: {
                            store.setHsv(
                                hue: Float($0.hue), saturation: Float($0.saturation),
                                brightness: Float($0.brightness), opacity: Float($0.opacity)
                            )
                        }
                    ),
                    opacity: true
                )
            }
        }
        .settingsForm()
        .task { await model.state.observe() }
    }
}
#endif

/// The draft theme at work: two episode cards (one with its progress), a Play button, an Autoplay switch and a line of
/// secondary text, in the draft's colours.
private struct ThemePreview: View {
    let palette: PlezyKit.Palette

    var body: some View {
        let text = Color(argb: palette.text)
        let muted = Color(argb: palette.textMuted)
        let accent = Color(argb: palette.accent)
        let editor = T.shared.themeEditor
        VStack(alignment: .leading, spacing: 12) {
            Text(editor.preview).font(.subheadline.weight(.semibold)).foregroundStyle(muted)
            HStack(spacing: 12) {
                ForEach(1...2, id: \.self) { number in
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 8).fill(Color(argb: palette.outline).opacity(0.5)).frame(height: 48)
                        Text(editor.previewCardTitle(number: String(number))).font(.subheadline.weight(.semibold)).foregroundStyle(text)
                        Text(editor.previewCardSubtitle(minutes: String(number * 12))).font(.caption).foregroundStyle(muted)
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(text.opacity(0.2))
                                Rectangle().fill(accent).frame(width: proxy.size.width * (number == 1 ? 0.6 : 0.25))
                            }
                        }
                        .frame(height: 3)
                    }
                    .padding(10)
                    .background(Color(argb: palette.surface), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            HStack(spacing: 12) {
                Label(T.shared.common.play, systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(argb: palette.onAccent))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accent, in: Capsule())
                Spacer()
                Text(editor.previewSwitch).font(.subheadline).foregroundStyle(text)
                Capsule().fill(accent).frame(width: 44, height: 26)
                    .overlay(alignment: .trailing) { Circle().fill(Color(argb: palette.onAccent)).padding(3) }
            }
            Text(editor.previewMutedText).font(.caption).foregroundStyle(muted)
        }
        .padding(16)
        .background(Color(argb: palette.bg), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color(argb: palette.outline), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("settings.custom.preview")
    }
}

#if os(iOS)
/// The system colour well (opacity included), drawn its own 28 pt, taking taps in the 44 pt square around it: the
/// least target on a touch screen. Picking a colour sets `color`.
private struct ColorWell: UIViewRepresentable {
    let title: String
    @Binding var color: Color

    func makeUIView(context: Context) -> Holder {
        let holder = Holder()
        holder.well.title = title
        holder.well.supportsAlpha = true
        let coordinator = context.coordinator
        holder.well.addAction(UIAction { [weak well = holder.well] _ in
            if let picked = well?.selectedColor { coordinator.color.wrappedValue = Color(uiColor: picked) }
        }, for: .valueChanged)
        return holder
    }

    func updateUIView(_ holder: Holder, context: Context) {
        context.coordinator.color = $color
        holder.well.title = title
        holder.well.selectedColor = UIColor(color)
    }

    func makeCoordinator() -> Coordinator { Coordinator(color: $color) }

    final class Coordinator {
        var color: Binding<Color>
        init(color: Binding<Color>) { self.color = color }
    }

    /// 44 pt square, the well centred in it at the system's size, 28 pt; a touch anywhere in it goes to the well.
    final class Holder: UIView {
        let well = Well()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(well)
        }

        required init?(coder: NSCoder) { fatalError("not from a nib") }

        override var intrinsicContentSize: CGSize { CGSize(width: 44, height: 44) }

        override func layoutSubviews() {
            super.layoutSubviews()
            well.frame = CGRect(x: (bounds.width - 28) / 2, y: (bounds.height - 28) / 2, width: 28, height: 28)
        }

        /// A touch anywhere in the square goes to the well's own control, as a touch on its centre would.
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            guard self.point(inside: point, with: event) else { return nil }
            return well.hitTest(CGPoint(x: well.bounds.midX, y: well.bounds.midY), with: event) ?? well
        }
    }

    /// The well, counting a touch in its holder's square as inside it.
    final class Well: UIColorWell {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            guard let holder = superview else { return super.point(inside: point, with: event) }
            return holder.bounds.contains(convert(point, to: holder))
        }
    }
}
#endif
