import SwiftUI
import PlezyKit
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// One row of a row page, bound to `store` by its id: a switch, a choice (a menu, segments; on tvOS a list), a slider
/// (on tvOS a Left/Right value), a link, or a row that opens its dialog (a number, a checklist, a text, a colour). A slot row is drawn by its provider (`SettingsSlots`) from `app`. Harness name: `settings.row.<id>`.
struct SettingRowView: View {
    let app: AppModel
    let row: any SettingRow
    let store: any SettingsPageStore

    var body: some View {
        let probe = "settings.row.\(row.id)"
        switch onEnum(of: row) {
        case .settingToggleRow(let toggle):
            SettingsToggleRow(row: toggle, id: probe) { store.toggle(id: toggle.id, checked: $0) }
        case .settingValueRow(let valueRow):
            valueRowView(valueRow, probe: probe)
        case .settingSliderRow(let slider):
            SettingSliderItem(row: slider, id: probe) { store.setSlider(id: slider.id, value: $0) }
        case .settingColorRow(let color):
            SettingsDialogRow(title: color.title, subtitle: color.hex, icon: color.icon, id: probe) {
                ColorSwatch(color: SettingsHsv(hex: color.hex).color, size: 28)
            } sheet: { close in
                SettingColorSheet(row: color, onSave: { store.setColor(id: color.id, hex: $0) }, onClose: close)
            }
        case .settingSlotRow(let slot):
            SettingsSlots.row(slot.slot, app: app, id: probe)
        }
    }

    /// A row that shows its setting's value: beside the title while short (`trailingValue`), else in `subtitle`.
    @ViewBuilder
    private func valueRowView(_ row: any SettingValueRow, probe: String) -> some View {
        switch onEnum(of: row) {
        case .settingChoiceRow(let choice):
            SettingsChoicePicker(row: choice, id: probe) { store.choose(id: choice.id, optionId: $0) }
        case .settingNumberRow(let number):
            SettingsDialogRow(title: number.title, subtitle: number.subtitle, value: number.trailingValue, icon: number.icon, id: probe) { close in
                SettingNumberSheet(
                    row: number,
                    onCheck: { store.checkNumber(id: number.id, text: $0) },
                    onSave: { store.setNumber(id: number.id, text: $0) },
                    onClose: close
                )
            }
        case .settingLinkRow(let link):
            SettingsLinkRow(
                title: link.title,
                subtitle: link.subtitle,
                value: link.trailingValue,
                systemImage: link.icon?.systemImage,
                trailingSymbol: link.trailing == .chevron ? "chevron.forward" : link.trailing == .external ? "arrow.up.right" : nil,
                busy: link.busy,
                destructive: link.destructive,
                iconTint: link.accent ? SettingsColors.warning : link.destructive ? Palette.error : nil,
                id: probe
            ) {
                store.activate(id: link.id)
            }
            .disabled(!link.enabled)
        case .settingChecklistRow(let checklist):
            SettingsDialogRow(title: checklist.title, subtitle: checklist.subtitle, value: checklist.trailingValue, icon: checklist.icon, id: probe) { close in
                SettingChecklistSheet(row: checklist, onSave: { store.setChecked(id: checklist.id, checkedIds: $0) }, onClose: close)
            }
        case .settingTextRow(let text):
            // A pattern's value is its subtitle, set as code.
            SettingsDialogRow(title: text.title, subtitle: text.subtitle, value: text.trailingValue, icon: text.icon, id: probe) { close in
                SettingTextSheet(
                    row: text,
                    onCheck: { store.checkText(id: text.id, text: $0) },
                    onSave: { store.submitText(id: text.id, text: $0) },
                    onReset: { store.resetText(id: text.id) },
                    onClose: close
                )
            }
            .environment(\.settingsSubtitleMonospaced, text.monospace)
        }
    }
}

enum SettingsColors {
    /// An update waiting: the warning colour.
    static let warning = Color(rgb: 0xFFB300)
}

/// A row that opens `sheet` (its close passed in): its icon, title, subtitle, `value`, `accessory` and a chevron.
struct SettingsDialogRow<Accessory: View, Sheet: View>: View {
    let title: String
    let subtitle: String?
    var value: String?
    let icon: SettingIcon?
    let id: String
    @ViewBuilder var accessory: () -> Accessory
    @ViewBuilder var sheet: (_ close: @escaping () -> Void) -> Sheet

    @State private var open = false

    var body: some View {
        SettingsLinkRow(
            title: title, subtitle: subtitle, value: value, systemImage: icon?.systemImage, id: id, action: { open = true }, accessory: accessory
        )
        .appSheet(isPresented: $open) {
            sheet { open = false }
        }
    }
}

extension SettingsDialogRow where Accessory == EmptyView {
    init(
        title: String, subtitle: String?, value: String? = nil, icon: SettingIcon?, id: String,
        @ViewBuilder sheet: @escaping (_ close: @escaping () -> Void) -> Sheet
    ) {
        self.init(title: title, subtitle: subtitle, value: value, icon: icon, id: id, accessory: { EmptyView() }, sheet: sheet)
    }
}

/// A continuous setting: the row's title and value over the system's slider (every move writes), its end labels
/// under it; on tvOS, which has no slider, the value between chevrons that Left and Right move one division
/// (`TVStepperValue`). Harness name: `[id]` on the slider (tvOS: the value).
private struct SettingSliderItem: View {
    let row: SettingSliderRow
    let id: String
    let onChange: (Double) -> Void

    /// The slider follows the finger at once; the store's value, once written, replaces it.
    @State private var value: Double

    init(row: SettingSliderRow, id: String, onChange: @escaping (Double) -> Void) {
        self.row = row
        self.id = id
        self.onChange = onChange
        _value = State(initialValue: row.value)
    }

    /// One division of the slider (a twentieth of its range when it is continuous).
    private var step: Double {
        (row.max - row.min) / Double(row.steps > 0 ? row.steps : 20)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let systemImage = row.icon?.systemImage {
                    #if os(tvOS)
                    SettingsRowIcon(systemImage: systemImage, width: 48)
                    #else
                    SettingsRowIcon(systemImage: systemImage, width: 28)
                    #endif
                }
                Text(row.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                #if os(tvOS)
                TVStepperValue(title: row.title, value: row.valueLabel ?? String(format: "%.1f", row.value), id: id) { up in
                    let next = Swift.min(Swift.max(row.value + (up ? step : -step), row.min), row.max)
                    if next != row.value { onChange(next) }
                }
                #else
                if let label = row.valueLabel {
                    Text(label)
                        .monospacedDigit()
                        .mutedForeground()
                }
                #endif
            }
            #if !os(tvOS)
            Group {
                if row.steps > 0 {
                    Slider(value: $value, in: row.min...row.max, step: step) { Text(row.title) }
                } else {
                    Slider(value: $value, in: row.min...row.max) { Text(row.title) }
                }
            }
            .labelsHidden()
            .tint(Palette.primary)
            .accessibilityIdentifier(id)
            .onChange(of: value) { _, moved in
                if moved != row.value { onChange(moved) }
            }
            #endif
            if row.startLabel != nil || row.endLabel != nil {
                HStack {
                    Text(row.startLabel ?? "")
                    Spacer()
                    Text(row.endLabel ?? "")
                }
                .font(.footnote)
                .mutedForeground()
            }
        }
        .padding(.vertical, 4)
        .onChange(of: row.value) { _, stored in value = stored }
    }
}

/// A number setting's dialog: by touch and keyboard a number field with the row's unit, focused as the dialog opens,
/// on tvOS the value between chevrons that Left and Right step within the row's bounds, focused as the dialog opens,
/// Select moving to Save; both show the row's hint. While typing the field shows `onCheck`'s word on the text (not a
/// number, out of bounds) in the hint's place. Save hands the text to `onSave`: an error it returns shows under the
/// field and the dialog stays open; none closes it. Harness names:
/// `settings.number.<field|spinner|hint|error|save|cancel>`.
private struct SettingNumberSheet: View {
    let row: SettingNumberRow
    let onCheck: (String) -> String?
    let onSave: (String) -> String?
    let onClose: () -> Void

    @State private var text: String
    @State private var value: Int32
    @State private var error: String?
    @FocusState private var focus: String?

    init(row: SettingNumberRow, onCheck: @escaping (String) -> String?, onSave: @escaping (String) -> String?, onClose: @escaping () -> Void) {
        self.row = row
        self.onCheck = onCheck
        self.onSave = onSave
        self.onClose = onClose
        _text = State(initialValue: String(row.value))
        _value = State(initialValue: Swift.min(Swift.max(row.value, row.min), row.max))
    }

    var body: some View {
        let save = SheetAction(title: T.shared.common.save, id: "settings.number.save") {
            #if os(tvOS)
            error = onSave(String(value))
            #else
            error = onSave(text)
            #endif
            if error == nil { onClose() }
        }
        let cancel = SheetAction(title: T.shared.common.cancel, id: "settings.number.cancel", action: onClose)
        #if os(tvOS)
        let first = "settings.number.spinner"
        #else
        let first = "settings.number.field"
        #endif
        SheetPage(title: row.title, cancel: cancel, confirm: save) {
            Form {
                Section {
                    #if os(tvOS)
                    TVStepperValue(title: row.title, value: "\(value) \(row.suffix)", id: first, focus: $focus, onSelect: { focus = save.id }) { up in
                        value = Swift.min(Swift.max(value + (up ? 1 : -1), row.min), row.max)
                        error = nil
                    }
                    .frame(maxWidth: .infinity)
                    #else
                    HStack {
                        TextField(row.title, text: $text, prompt: Text(row.hint))
                            .labelsHidden()
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .focused($focus, equals: first)
                            .onSubmit(save.action)
                            .accessibilityIdentifier(first)
                        Text(row.suffix).mutedForeground()
                    }
                    #endif
                } footer: {
                    if let error {
                        Text(error)
                            .foregroundStyle(Palette.error)
                            .accessibilityIdentifier("settings.number.error")
                    } else {
                        // The theme's muted colour: the system's footer grey is barely visible on Apple TV's black.
                        Text(row.hint)
                            .foregroundStyle(Palette.onSurfaceVariant)
                            .accessibilityIdentifier("settings.number.hint")
                    }
                }
                SheetActionsSection(actions: [save, cancel], focus: $focus)
            }
            .settingsForm()
            #if os(tvOS)
            .defaultFocus($focus, first)
            #endif
        }
        .backAction(onClose)
        .onChange(of: text) { error = onCheck(text) }
        .task { await FocusRestore.restore($focus, to: first) }
    }
}

/// A checklist's dialog: a row per option, ticked when checked, a locked one ticked and disabled. Save hands `onSave`
/// the ticked ids in the options' order; Cancel stores nothing. Harness names:
/// `settings.checklist.option.<i>`, `settings.checklist.<save|cancel>`.
private struct SettingChecklistSheet: View {
    let row: SettingChecklistRow
    let onSave: ([String]) -> Void
    let onClose: () -> Void

    @State private var checked: Set<String>

    init(row: SettingChecklistRow, onSave: @escaping ([String]) -> Void, onClose: @escaping () -> Void) {
        self.row = row
        self.onSave = onSave
        self.onClose = onClose
        _checked = State(initialValue: Set(row.options.filter { $0.checked || $0.locked }.map(\.id)))
    }

    var body: some View {
        let save = SheetAction(title: T.shared.common.save, id: "settings.checklist.save") {
            onSave(row.options.map(\.id).filter(checked.contains))
            onClose()
        }
        let cancel = SheetAction(title: T.shared.common.cancel, id: "settings.checklist.cancel", action: onClose)
        SheetPage(title: row.title, cancel: cancel, confirm: save) {
            Form {
                Section {
                    ForEach(Array(row.options.enumerated()), id: \.element.id) { index, option in
                        let on = checked.contains(option.id)
                        Button {
                            if on { checked.remove(option.id) } else { checked.insert(option.id) }
                        } label: {
                            HStack(spacing: 16) {
                                SettingsRowText(title: option.label, subtitle: option.subtitle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(on ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(.tertiary))
                                    .accessibilityHidden(true)
                            }
                            .contentShape(Rectangle())
                        }
                        .formRowButtonStyle()
                        .disabled(option.locked)
                        .accessibilityAddTraits(on ? .isSelected : [])
                        .accessibilityIdentifier("settings.checklist.option.\(index)")
                    }
                } footer: {
                    Text(row.valueLabel)
                }
                SheetActionsSection(actions: [save, cancel])
            }
            .settingsForm()
        }
        .backAction(onClose)
    }
}

/// A text setting's dialog: the field labelled with the row's field label and hint, starting at the stored text
/// (monospace for a pattern), focused as the dialog opens on iOS and macOS. While typing the field shows `onCheck`'s
/// word on the text (a pattern that isn't one) in the subtitle's place. Save hands the text, untrimmed, to `onSave`:
/// an error it returns shows under the field and the dialog stays open; none closes it. With a reset label, that
/// action fills the field with `onReset`'s default (nothing stored yet), or closes the dialog when `onReset` stored the
/// reset itself (nil). Harness names: `settings.text.<field|error|reset|save|cancel>`.
struct SettingTextSheet: View {
    let row: SettingTextRow
    let onCheck: (String) -> String?
    let onSave: (String) -> String?
    let onReset: () -> String?
    let onClose: () -> Void

    @State private var text: String
    @State private var error: String?
    @FocusState private var focus: String?

    init(
        row: SettingTextRow, onCheck: @escaping (String) -> String? = { _ in nil }, onSave: @escaping (String) -> String?,
        onReset: @escaping () -> String?, onClose: @escaping () -> Void
    ) {
        self.row = row
        self.onCheck = onCheck
        self.onSave = onSave
        self.onReset = onReset
        self.onClose = onClose
        _text = State(initialValue: row.value)
    }

    var body: some View {
        let save = SheetAction(title: T.shared.common.save, id: "settings.text.save") {
            error = onSave(text)
            if error == nil { onClose() }
        }
        let reset = row.resetLabel.map { label in
            SheetAction(title: label, id: "settings.text.reset") {
                if let value = onReset() { text = value } else { onClose() }
            }
        }
        let cancel = SheetAction(title: T.shared.common.cancel, id: "settings.text.cancel", action: onClose)
        SheetPage(title: row.title, cancel: cancel, confirm: save) {
            Form {
                Section {
                    TextField(row.fieldLabel, text: $text, prompt: Text(row.hint))
                        .labelsHidden()
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .font(row.monospace ? .body.monospaced() : .body)
                        .focused($focus, equals: "settings.text.field")
                        .onSubmit(save.action)
                        .accessibilityIdentifier("settings.text.field")
                        .formFieldRow()
                } header: {
                    Text(row.fieldLabel)
                } footer: {
                    if let error {
                        Text(error)
                            .foregroundStyle(Palette.error)
                            .accessibilityIdentifier("settings.text.error")
                    } else if let caption = row.caption {
                        Text(caption)
                    }
                }
                #if !os(tvOS)
                if let reset {
                    Section {
                        Button(reset.title, action: reset.action)
                            .accessibilityIdentifier(reset.id)
                    }
                }
                #endif
                SheetActionsSection(actions: [save] + (reset.map { [$0] } ?? []) + [cancel])
            }
            .settingsForm()
        }
        .backAction(onClose)
        .onChange(of: text) { error = onCheck(text) }
        #if !os(tvOS)
        .task { await FocusRestore.restore($focus, to: "settings.text.field") }
        #endif
    }
}

/// A colour setting's dialog: the colour beside its code, the system's colour picker (iOS, macOS) or, on tvOS, hue,
/// saturation and brightness values that Left and Right move, and the primary swatches. Save stores `#RRGGBB` through
/// `onSave` when the colour changed. Harness names: `settings.color.<picker|swatch.i|hue|saturation|brightness|save>`.
private struct SettingColorSheet: View {
    let row: SettingColorRow
    let onSave: (String) -> Void
    let onClose: () -> Void

    @State private var hsv: SettingsHsv

    init(row: SettingColorRow, onSave: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.row = row
        self.onSave = onSave
        self.onClose = onClose
        _hsv = State(initialValue: SettingsHsv(hex: row.hex))
    }

    var body: some View {
        let hex = hsv.hex(alpha: false)
        let save = SheetAction(title: T.shared.common.save, id: "settings.color.save") {
            if hex != SettingsHsv(hex: row.hex).hex(alpha: false) { onSave(hex) }
            onClose()
        }
        let cancel = SheetAction(title: T.shared.common.cancel, id: "settings.color.cancel", action: onClose)
        SheetPage(title: row.title, cancel: cancel, confirm: save) {
            Form {
                Section {
                    HStack(spacing: 16) {
                        ColorSwatch(color: hsv.color, size: 40)
                        Text(hex).font(.title3.monospaced())
                    }
                    #if !os(tvOS)
                    ColorPicker(row.title, selection: Binding(get: { hsv.color }, set: { hsv = SettingsHsv(color: $0) }), supportsOpacity: false)
                        .accessibilityIdentifier("settings.color.picker")
                    #endif
                }
                Section {
                    SwatchGrid(swatches: SettingsHsv.primarySwatches, selected: hex, probe: "settings.color.swatch") {
                        hsv = SettingsHsv(hex: $0)
                    }
                }
                #if os(tvOS)
                Section {
                    HsvValues(hsv: $hsv, opacity: false)
                }
                #endif
                SheetActionsSection(actions: [save, cancel])
            }
            .settingsForm()
        }
        .backAction(onClose)
    }
}

/// A colour as a circle, `size` across, with a hairline ring.
struct ColorSwatch: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Palette.outline, lineWidth: 1))
            .accessibilityHidden(true)
    }
}

/// Colours to pick (`#RRGGBB` or `#AARRGGBB`), the one equal to `selected` ringed in the accent; `onPick` takes its code.
/// Harness names: `[probe].<i>`.
struct SwatchGrid: View {
    let swatches: [String]
    let selected: String
    let probe: String
    let onPick: (String) -> Void

    var body: some View {
        #if os(tvOS)
        let size: CGFloat = 56
        #else
        let size: CGFloat = 32
        #endif
        // Each swatch is drawn `size` with its ring 3 pt outside; on iOS it takes taps in 44 pt (its column's least
        // width), the rows' gap shrinking by as much as the target grows, so the swatches sit where they would.
        #if os(iOS)
        let target: CGFloat = 44
        #else
        let target: CGFloat = size + 6
        #endif
        LazyVGrid(columns: [GridItem(.adaptive(minimum: size + 12), spacing: 12)], spacing: 12 - (target - size - 6)) {
            ForEach(Array(swatches.enumerated()), id: \.offset) { index, swatch in
                Button { onPick(swatch) } label: {
                    ColorSwatch(color: SettingsHsv(hex: swatch).color, size: size)
                        .padding(3)
                        .overlay(Circle().strokeBorder(swatch.caseInsensitiveCompare(selected) == .orderedSame ? Palette.primary : .clear, lineWidth: 2))
                        .frame(minWidth: target, minHeight: target)
                        .contentShape(Rectangle())
                }
                .cardButtonStyle(circular: true)
                .accessibilityLabel(swatch)
                .accessibilityIdentifier("\(probe).\(index)")
            }
        }
        .padding(.vertical, 4)
    }
}

#if os(tvOS)
/// Hue (0–360°), saturation and brightness (0–100 %), 5 a press, and with `opacity` opacity (5 % a press), as values
/// Left and Right move, VoiceOver naming each value's steps after it ("Decrease Hue"); then the colour's six hex digits
/// after a `#`, hex digits only: six of them set the colour (its opacity kept), and a value's step writes them anew,
/// upper case. Harness names: `settings.hsv.<hue|saturation|brightness|opacity|hex>`.
struct HsvValues: View {
    @Binding var hsv: SettingsHsv
    let opacity: Bool

    /// The hex field's text: the colour's digits, or what is being typed.
    @State private var hex = ""

    var body: some View {
        let strings = T.shared.accessibility
        value(strings.hue, "\(Int(hsv.hue))°", "settings.hsv.hue") { up in
            hsv.hue = (hsv.hue + (up ? 5 : -5) + 360).truncatingRemainder(dividingBy: 360)
        }
        value(strings.saturation, "\(Int((hsv.saturation * 100).rounded()))%", "settings.hsv.saturation") { up in
            hsv.saturation = Swift.min(Swift.max(hsv.saturation + (up ? 0.05 : -0.05), 0), 1)
        }
        value(strings.brightness, "\(Int((hsv.brightness * 100).rounded()))%", "settings.hsv.brightness") { up in
            hsv.brightness = Swift.min(Swift.max(hsv.brightness + (up ? 0.05 : -0.05), 0), 1)
        }
        if opacity {
            value(T.shared.themeEditor.opacity, "\(Int((hsv.opacity * 100).rounded()))%", "settings.hsv.opacity") { up in
                hsv.opacity = Swift.min(Swift.max(hsv.opacity + (up ? 0.05 : -0.05), 0), 1)
            }
        }
        HStack(spacing: 8) {
            Text(verbatim: "#").monospaced().accessibilityHidden(true)
            TextField(strings.hexColor, text: $hex)
                .monospaced()
                .accessibilityLabel(strings.hexColor)
                .accessibilityIdentifier("settings.hsv.hex")
        }
        .onChange(of: hsv, initial: true) {
            let digits = String(hsv.hex(alpha: false).dropFirst())
            if digits.caseInsensitiveCompare(hex) != .orderedSame { hex = digits }
        }
        .onChange(of: hex) { _, typed in
            let digits = String(typed.filter(\.isHexDigit).prefix(6))
            if digits != typed {
                hex = digits
            } else if digits.count == 6 {
                var typedColour = SettingsHsv(hex: digits)
                typedColour.opacity = hsv.opacity
                if typedColour.hex(alpha: false) != hsv.hex(alpha: false) { hsv = typedColour }
            }
        }
    }

    private func value(_ title: String, _ label: String, _ id: String, step: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(title).frame(maxWidth: .infinity, alignment: .leading).accessibilityHidden(true)
            TVStepperValue(title: title, value: label, id: id, channel: title, onStep: step)
        }
    }
}
#endif

/// A colour as hue (0–360), saturation, brightness and opacity (0–1), and its codes.
struct SettingsHsv: Equatable {
    var hue: Double
    var saturation: Double
    var brightness: Double
    var opacity: Double = 1

    init(hue: Double, saturation: Double, brightness: Double, opacity: Double = 1) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.opacity = opacity
    }

    /// `#RRGGBB` or `#AARRGGBB` (the `#` optional); anything else black.
    init(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard let value = UInt32(digits, radix: 16), digits.count == 6 || digits.count == 8 else {
            self.init(hue: 0, saturation: 0, brightness: 0)
            return
        }
        let alpha = digits.count == 8 ? Double((value >> 24) & 0xFF) / 255 : 1
        self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255, alpha: alpha)
    }

    /// The colour the system's colour picker chose, in sRGB.
    init(color: Color) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 1
        #if os(macOS)
        if let srgb = NSColor(color).usingColorSpace(.sRGB) {
            srgb.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        }
        #else
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        self.init(red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
    }

    private init(red: Double, green: Double, blue: Double, alpha: Double) {
        let maxC = Swift.max(red, green, blue)
        let minC = Swift.min(red, green, blue)
        let delta = maxC - minC
        var hue: Double
        if delta == 0 {
            hue = 0
        } else if maxC == red {
            hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxC == green {
            hue = 60 * ((blue - red) / delta + 2)
        } else {
            hue = 60 * ((red - green) / delta + 4)
        }
        if hue < 0 { hue += 360 }
        self.init(hue: hue, saturation: maxC == 0 ? 0 : delta / maxC, brightness: maxC, opacity: alpha)
    }

    var color: Color {
        Color(hue: hue / 360, saturation: saturation, brightness: brightness, opacity: opacity)
    }

    /// The colour as `#RRGGBB`, or with `alpha` `#AARRGGBB`, upper case.
    func hex(alpha: Bool) -> String {
        let c = brightness * saturation
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        let (r, g, b): (Double, Double, Double) = switch hue {
        case ..<60: (c, x, 0)
        case ..<120: (x, c, 0)
        case ..<180: (0, c, x)
        case ..<240: (0, x, c)
        case ..<300: (x, 0, c)
        default: (c, 0, x)
        }
        func byte(_ value: Double) -> Int { Int(((value + m) * 255).rounded()) }
        let rgb = String(format: "%02X%02X%02X", byte(r), byte(g), byte(b))
        return alpha ? String(format: "#%02X", Int((opacity * 255).rounded())) + rgb : "#" + rgb
    }

    /// Material's primary swatches, then white and black: the colour dialog's quick picks.
    static let primarySwatches = [
        "#F44336", "#E91E63", "#9C27B0", "#673AB7", "#3F51B5", "#2196F3", "#03A9F4", "#00BCD4", "#009688", "#4CAF50",
        "#8BC34A", "#CDDC39", "#FFEB3B", "#FFC107", "#FF9800", "#FF5722", "#795548", "#9E9E9E", "#607D8B", "#FFFFFF",
        "#000000",
    ]
}
