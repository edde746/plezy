import SwiftUI
import PlezyKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The building blocks of the Settings screens, all native: a grouped `Form` on black, rows that open something,
/// switches (`Toggle`), menus (`Picker`; on tvOS a row that opens its values as a list) and modal forms in sheets.
/// Every text comes from the shared stores or `T`. A row's title and subtitle show whole, and on iOS and macOS its
/// control (or value) stays beside them while they keep a readable column, else goes under them (`SettingsRowLayout`).
/// A form's text field shows its hint inside it (`prompt`) and hides a label that would only repeat the hint
/// (`labelsHidden`): a Mac form draws a field's label at the row's start, beside the text.

extension View {
    /// A settings page: a grouped form on the black background, a readable column on wide windows and TV. In a sheet
    /// (`appSheet`) on iOS and the Mac the form keeps the sheet's own background, which the sheet's title and button
    /// bars have too. A page with nothing to focus at the moment (`idle`: loading, its actions disabled while one runs)
    /// holds focus on Apple TV (`holdsBackFocus`).
    func settingsForm(idle: Bool = false) -> some View {
        modifier(SettingsFormStyle(idle: idle))
    }
}

private struct SettingsFormStyle: ViewModifier {
    let idle: Bool

    @Environment(\.isInSheet) private var isInSheet
    #if os(macOS)
    @Environment(\.formSetsSheetHeight) private var setsSheetHeight
    #endif

    func body(content: Content) -> some View {
        content
            .formStyle(.grouped)
            #if os(tvOS)
            // A focused row's platter reaches past the column's edge: the form doesn't cut it off.
            .scrollClipDisabled()
            // Off the top safe area's edge, so the form doesn't run up under the navigation bar: there the focus
            // scrolled a row moved to from below to under the page's title, out of sight (`pageTitle`'s mask), its top
            // taken for the form's.
            .padding(.top, 1)
            #else
            .scrollContentBackground(blackPage ? .hidden : .automatic)
            #endif
            #if os(macOS)
            .modifier(SheetHeightFromForm(active: setsSheetHeight))
            #endif
            .readableColumn()
            .background(blackPage ? Palette.background : .clear)
            .holdsBackFocus(idle)
    }

    /// The page's own black: not in an iOS or Mac sheet, whose background is the system's as every sheet's is (Liquid
    /// Glass while an iPhone's sheet is partway up); Apple TV's forms cover the screen or sit on a panel's surface.
    private var blackPage: Bool {
        #if os(tvOS)
        true
        #else
        !isInSheet
        #endif
    }
}

extension View {
    /// A list or form as a column centred in wide windows and on TV, as wide as the window on phones. Narrower than
    /// the width it is centred in (the iPhone Duo's inner screen beside the vertical bar), the column keeps off the
    /// window's sides, so nothing in it is beside the bar (`verticalBarEdge`, `screenSides`).
    func readableColumn() -> some View {
        modifier(ReadableColumn())
    }
}

private struct ReadableColumn: ViewModifier {
    @Environment(\.formFactor) private var formFactor
    /// The column is narrower than the width it is centred in.
    @State private var narrower = false

    func body(content: Content) -> some View {
        let width = maxWidth
        content
            .transformEnvironment(\.verticalBarEdge) { if narrower { $0 = nil } }
            .frame(maxWidth: width)
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: Bool.self) { $0.size.width > width } action: { narrower = $0 }
    }

    private var maxWidth: CGFloat {
        switch formFactor {
        case .compact: .infinity
        case .regular: 720
        case .tv: 1200
        }
    }
}

/// A row's title, optional subtitle and optional `error` (why the setting doesn't take effect), in the error colour,
/// each shown whole: as many lines as its text takes at the width given. In a disabled row (a switch that takes no
/// change) the text fades, as the system's disabled controls do. The subtitle is set as code under
/// `settingsSubtitleMonospaced` (a pattern's value).
struct SettingsRowText: View {
    let title: String
    let subtitle: String?
    var error: String?
    /// The title in the error colour: a row that destroys something (Reset Settings).
    var destructive = false

    @Environment(\.isEnabled) private var enabled
    @Environment(\.settingsSubtitleMonospaced) private var monospaced

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .destructiveLabel(destructive, rest: Palette.error)
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(monospaced ? .footnote.monospaced() : .footnote)
                    .mutedForeground()
            }
            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
            }
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .opacity(enabled ? 1 : 0.45)
    }
}

extension EnvironmentValues {
    /// A settings row's subtitle is code (a pattern's value), set in a monospace face (`SettingsRowText`).
    @Entry var settingsSubtitleMonospaced = false
}

/// A row's leading icon: `systemImage` in the muted colour (`mutedForeground`), or `tint` (an update waiting), `width`
/// wide.
struct SettingsRowIcon: View {
    let systemImage: String
    var tint: Color?
    let width: CGFloat

    var body: some View {
        let image = Image(systemName: systemImage).frame(width: width).accessibilityHidden(true)
        if let tint {
            image.foregroundStyle(tint)
        } else {
            image.mutedForeground()
        }
    }
}

/// A row that opens something (a section, a list, a page outside the app): its icon, `title`, `subtitle` and `error`
/// (`SettingsRowText`), an `accessory` (a colour's swatch) and a `value` on the trailing side and `trailingSymbol` (a
/// chevron, as a navigation link has; an arrow for a page outside the app), the value and symbol beside the text or
/// under it (`SettingsRowLayout`; on tvOS always beside). On iOS and macOS the value sits beside the title only while
/// the title keeps one line beside it (`SettingsRowLayout.fitsBeside`); else it leads the subtitle. The whole row is the
/// button; `id` is its accessibility identifier. While `busy` a spinner replaces the value and symbol and a press does
/// nothing; `destructive` paints the title in the error colour, `iconTint` the icon.
struct SettingsLinkRow<Accessory: View>: View {
    let title: String
    var subtitle: String?
    var value: String?
    var error: String?
    var systemImage: String?
    var trailingSymbol: String? = "chevron.forward"
    var busy = false
    var destructive = false
    var iconTint: Color?
    let id: String
    let action: () -> Void
    @ViewBuilder var accessory: () -> Accessory

    #if !os(tvOS)
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var width: CGFloat?
    #endif

    var body: some View {
        Button { if !busy { action() } } label: {
            #if os(tvOS)
            HStack(spacing: 12) {
                if let systemImage {
                    SettingsRowIcon(systemImage: systemImage, tint: iconTint, width: 48)
                }
                SettingsRowText(title: title, subtitle: subtitle, error: error, destructive: destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing(value: value)
            }
            .contentShape(Rectangle())
            #else
            let beside = value.map {
                SettingsRowLayout.fitsBeside(
                    title: title, value: $0, width: width, markWidth: trailingSymbol == nil ? 0 : 26, dynamicTypeSize: dynamicTypeSize
                )
            } ?? true
            let shownSubtitle = beside ? subtitle : [value, subtitle].compactMap { $0 }.joined(separator: "\n")
            HStack(spacing: 12) {
                if let systemImage {
                    SettingsRowIcon(systemImage: systemImage, tint: iconTint, width: 28)
                }
                SettingsRowLayout(
                    leastTextWidth: SettingsRowLayout.leastTextWidth(title: title, subtitle: shownSubtitle, dynamicTypeSize: dynamicTypeSize),
                    spacing: 12
                ) {
                    SettingsRowText(title: title, subtitle: shownSubtitle, error: error, destructive: destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 12) { trailing(value: beside ? value : nil) }
                }
                .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { width = $0 }
            }
            .contentShape(Rectangle())
            #endif
        }
        .formRowButtonStyle()
        .accessibilityIdentifier(id)
    }

    /// The accessory, the value, whole (several lines where it is wider than the row), and the symbol, which
    /// accessibility leaves out (a page outside the app is a link: `isLink`); a spinner while busy.
    @ViewBuilder
    private func trailing(value: String?) -> some View {
        accessory()
        if busy {
            ProgressView()
                .controlSize(.small)
        } else {
            if let value {
                Text(value)
                    .multilineTextAlignment(.trailing)
                    .mutedForeground()
            }
            if let trailingSymbol {
                Image(systemName: trailingSymbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
    }
}

extension SettingsLinkRow where Accessory == EmptyView {
    init(
        title: String, subtitle: String? = nil, value: String? = nil, error: String? = nil, systemImage: String? = nil,
        trailingSymbol: String? = "chevron.forward", busy: Bool = false, destructive: Bool = false, iconTint: Color? = nil,
        id: String, action: @escaping () -> Void
    ) {
        self.init(
            title: title, subtitle: subtitle, value: value, error: error, systemImage: systemImage, trailingSymbol: trailingSymbol,
            busy: busy, destructive: destructive, iconTint: iconTint, id: id, action: action, accessory: { EmptyView() }
        )
    }
}

/// An on/off setting: the system switch with the row's title and subtitle, on iOS and macOS beside them or under them
/// (`SettingsControlRow`). VoiceOver and UI tests read it as a switch named by the title whose value is 1 while on. Not
/// `enabled`, it is the system's disabled switch: it keeps `checked`, takes no change and, on tvOS, no focus.
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    let checked: Bool
    let id: String
    var enabled = true
    var systemImage: String?
    let onChange: (Bool) -> Void

    var body: some View {
        let isOn = Binding(get: { checked }, set: { onChange($0) })
        #if os(tvOS)
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                if let systemImage { SettingsRowIcon(systemImage: systemImage, width: 48) }
                SettingsRowText(title: title, subtitle: subtitle)
            }
        }
        .accessibilityIdentifier(id)
        .disabled(!enabled)
        #else
        SettingsControlRow(title: title, subtitle: subtitle, systemImage: systemImage) {
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Palette.switchOn)
                .accessibilityIdentifier(id)
        }
        .disabled(!enabled)
        #endif
    }
}

extension SettingsToggleRow {
    /// The switch of a store's `SettingToggleRow`.
    init(row: SettingToggleRow, id: String, onChange: @escaping (Bool) -> Void) {
        self.init(
            title: row.title, subtitle: row.subtitle, checked: row.checked, id: id, enabled: row.enabled,
            systemImage: row.icon?.systemImage, onChange: onChange
        )
    }
}

#if os(tvOS)
/// A stepper's value on tvOS: the focusable value between two chevrons, each pointing its way along the reading
/// direction; the remote's press towards the forward one (Right, Left in a right-to-left language) steps it up, the
/// other down; held, the press steps again after 400 ms and every 100 ms after that (`HeldArrowRepeat`). Up and Down
/// leave it; Select runs `onSelect`. Focused, it fills with the accent. With `focus`, the value
/// is that focus state's element `id`. To VoiceOver the value is an adjustable element named `title` (harness name
/// `id`), between the chevrons as buttons named for their step in the interface language: "Decrease" and "Increase",
/// or for a `channel` (a colour's hue) "Decrease Hue" and "Increase Hue".
struct TVStepperValue: View {
    let title: String
    let value: String
    let id: String
    var channel: String?
    var focus: FocusState<String?>.Binding?
    var onSelect: (() -> Void)?
    let onStep: (Bool) -> Void

    @FocusState private var ownFocus: Bool
    @Environment(\.layoutDirection) private var layoutDirection

    private var focused: Bool {
        focus.map { $0.wrappedValue == id } ?? ownFocus
    }

    var body: some View {
        let strings = T.shared.accessibility
        HStack(spacing: 16) {
            step(up: false, systemImage: "chevron.backward", label: channel.map { strings.decreaseValue(label: $0) } ?? strings.decrease)
            valueText
                .accessibilityLabel(title)
                .accessibilityValue(value)
                .accessibilityAdjustableAction { onStep($0 == .increment) }
                .accessibilityIdentifier(id)
            step(up: true, systemImage: "chevron.forward", label: channel.map { strings.increaseValue(label: $0) } ?? strings.increase)
        }
        .font(.headline)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .foregroundStyle(focused ? Palette.onPrimary : Palette.onBackground)
        .background(focused ? Palette.primary : Palette.surfaceContainerHigh, in: Capsule())
        .scaleEffect(focused ? 1.05 : 1)
        .effectsAnimation(.easeOut(duration: 0.15), value: focused)
        .onMoveCommand { direction in
            switch direction {
            case .left: onStep(layoutDirection == .rightToLeft)
            case .right: onStep(layoutDirection == .leftToRight)
            default: break
            }
        }
        .background(HeldArrowRepeat(active: focused) { right in onStep(right == (layoutDirection == .leftToRight)) })
    }

    /// The value, focusable, bound to `focus` when given, else to its own state.
    @ViewBuilder private var valueText: some View {
        let text = Text(value).lineLimit(1).monospacedDigit().frame(minWidth: 180).focusable()
        if let focus {
            selectable(text.focused(focus, equals: id))
        } else {
            selectable(text.focused($ownFocus))
        }
    }

    /// `view` with Select running `onSelect`, when there is one.
    @ViewBuilder private func selectable(_ view: some View) -> some View {
        if let onSelect { view.onTapGesture(perform: onSelect) } else { view }
    }

    private func step(up: Bool, systemImage: String, label: String) -> some View {
        Image(systemName: systemImage)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onStep(up) }
    }
}

/// The remote's Left or Right held while `active` (the stepper focused): `onRepeat(right)` after 400 ms and every
/// 100 ms after that until it is let go (`KeyRepeat`), the press's own step being the move command's. The focus
/// engine repeats no move for a held arrow. A press recognizer on the window sees the arrows of whatever has focus
/// within it, and takes them only while `active`; it lets every press through.
private struct HeldArrowRepeat: UIViewRepresentable {
    let active: Bool
    let onRepeat: (Bool) -> Void

    func makeUIView(context: Context) -> HoldView {
        HoldView()
    }

    func updateUIView(_ view: HoldView, context: Context) {
        view.active = active
        view.onRepeat = onRepeat
    }

    static func dismantleUIView(_ view: HoldView, coordinator: ()) {
        view.detach()
    }

    final class HoldView: UIView, UIGestureRecognizerDelegate {
        var active = false {
            didSet { if !active { repeater.stop() } }
        }
        var onRepeat: (Bool) -> Void = { _ in }
        private let repeater = KeyRepeat(delayMillis: KeyRepeat.companion.ARROW_DELAY_MILLIS, intervalMillis: KeyRepeat.companion.ARROW_INTERVAL_MILLIS)
        private var right = false
        private lazy var recognizer: UILongPressGestureRecognizer = {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(pressed))
            recognizer.allowedPressTypes = [UIPress.PressType.leftArrow, .rightArrow].map { NSNumber(value: $0.rawValue) }
            recognizer.minimumPressDuration = 0
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            return recognizer
        }()

        override func didMoveToWindow() {
            super.didMoveToWindow()
            recognizer.view?.removeGestureRecognizer(recognizer)
            window?.addGestureRecognizer(recognizer)
        }

        func detach() {
            repeater.stop()
            recognizer.view?.removeGestureRecognizer(recognizer)
        }

        @objc private func pressed(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                let right = right
                repeater.hold { [weak self] in
                    // Run on the main thread (the repeat's main scope).
                    MainActor.assumeIsolated { self?.onRepeat(right) }
                }
            case .ended, .cancelled, .failed:
                repeater.stop()
            default:
                break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
            guard active else { return false }
            right = press.type == .rightArrow
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
#endif

/// A setting with a fixed list of values (`SettingChoiceRow`): on iOS and macOS the title, then the menu showing a short
/// value beside it (`SettingsControlRow`); a long value shows under the title (`row.subtitle`) and the menu beside it is
/// its symbol alone. On iOS the whole row is the menu's button, at least 44 pt tall, so a press anywhere on it opens the
/// values; on macOS the system's menu picker sits beside the title. On tvOS, whose menu picker in a form shows the value
/// alone, without the row's title, a row like the others (title, subtitle and value) that opens the values as a list,
/// the chosen one checked (`SettingChoiceList`). `onSelect` takes the option's id. Not `row.enabled`, it is dimmed and
/// doesn't open.
///
/// With `valueBeside` (a form outside Settings, such as a request's options), the value always sits beside the title,
/// however long, and the subtitle is the caption alone.
///
/// Accessibility identifiers: `id`; on tvOS the list's values `<id>.option.<option id>`.
struct SettingsChoicePicker: View {
    let row: SettingChoiceRow
    let id: String
    var valueBeside = false
    let onSelect: (String) -> Void

    #if os(tvOS)
    @State private var choosing = false
    #elseif os(iOS)
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The width the row's text and value share, measured; nil before the first layout.
    @State private var width: CGFloat?
    #endif

    private var subtitle: String? { valueBeside ? row.caption : row.subtitle }
    private var trailingValue: String? { valueBeside ? row.valueLabel : row.trailingValue }

    var body: some View {
        #if os(tvOS)
        SettingsLinkRow(
            title: row.title, subtitle: subtitle, value: trailingValue, systemImage: row.icon?.systemImage, id: id
        ) { choosing = true }
            .appSheet(isPresented: $choosing) {
                SettingChoiceList(row: row, id: id) { optionId in
                    choosing = false
                    onSelect(optionId)
                } onClose: {
                    choosing = false
                }
            }
            .disabled(!row.enabled)
        #elseif os(iOS)
        // In Settings a short value stays beside the title only while the title keeps one line beside it.
        let beside = valueBeside || trailingValue.map {
            SettingsRowLayout.fitsBeside(title: row.title, value: $0, width: width, markWidth: 14, dynamicTypeSize: dynamicTypeSize)
        } ?? true
        let shownSubtitle = beside ? subtitle : [trailingValue, subtitle].compactMap { $0 }.joined(separator: "\n")
        Menu {
            Picker(row.title, selection: selection) { options }
                .pickerStyle(.inline)
                .labelsHidden()
        } label: {
            SettingsControlRow(title: row.title, subtitle: shownSubtitle, systemImage: row.icon?.systemImage) {
                // The menu picker's look: the value in the tint, then the up-down mark.
                HStack(spacing: 4) {
                    if beside, let trailingValue { Text(trailingValue) }
                    Image(systemName: "chevron.up.chevron.down").imageScale(.small)
                }
                .foregroundStyle(.tint)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        // Measured outside the menu: its label is laid out at its own ideal width.
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { width = $0 - (row.icon == nil ? 0 : 40) }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .accessibilityLabel(row.title)
        .accessibilityValue(row.valueLabel)
        .accessibilityIdentifier(id)
        .disabled(!row.enabled)
        #else
        SettingsControlRow(title: row.title, subtitle: subtitle, systemImage: row.icon?.systemImage) {
            if trailingValue != nil {
                Picker(row.title, selection: selection) { options }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                    .accessibilityIdentifier(id)
            } else {
                Menu {
                    Picker(row.title, selection: selection) { options }
                        .pickerStyle(.inline)
                        .labelsHidden()
                } label: {
                    Image(systemName: "chevron.up.chevron.down").contentShape(Rectangle())
                }
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel(row.title)
                .accessibilityValue(row.valueLabel)
                .accessibilityIdentifier(id)
            }
        }
        .disabled(!row.enabled)
        #endif
    }

    #if !os(tvOS)
    /// The menu's value: the chosen option; with none chosen (the interface language following the device's) the one
    /// the row shows (`valueLabel`), else an entry of its own showing it, which picks nothing.
    private var selection: Binding<String> {
        Binding(get: { shownOption?.id ?? Self.unchosen }, set: { if $0 != Self.unchosen { onSelect($0) } })
    }

    private var shownOption: SettingChoiceOption? {
        row.options.first(where: \.selected) ?? row.options.first { $0.label == row.valueLabel }
    }

    private static let unchosen = "\u{0}unchosen"

    @ViewBuilder
    private var options: some View {
        if shownOption == nil, !row.valueLabel.isEmpty {
            Text(row.valueLabel).tag(Self.unchosen)
        }
        ForEach(row.options, id: \.id) { option in
            Text(option.label).tag(option.id)
        }
    }
    #endif
}

#if !os(tvOS)
/// A settings row on iOS and macOS laid out by the rows' rule (`SettingsRowLayout`) rather than by the form: the icon
/// `systemImage` where given, then `title`, `subtitle` and `error` (`SettingsRowText`) and `trailing` (a switch, a menu,
/// a value and its stepper, a link's value and chevron), `spacing` apart.
struct SettingsControlRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    var error: String?
    var systemImage: String?
    var spacing: CGFloat = 8
    @ViewBuilder let trailing: () -> Trailing

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .frame(width: 28)
                    .mutedForeground()
                    .accessibilityHidden(true)
            }
            SettingsRowLayout(
                leastTextWidth: SettingsRowLayout.leastTextWidth(title: title, subtitle: subtitle, dynamicTypeSize: dynamicTypeSize),
                spacing: spacing
            ) {
                SettingsRowText(title: title, subtitle: subtitle, error: error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: spacing) { trailing() }
            }
        }
    }
}

/// The settings rows' rule on iOS and macOS, for a row of two subviews, its text and its trailing part (a control, a
/// value): the trailing part at its ideal size beside the text, both on the row's centre line, `spacing` apart, while
/// that leaves the text at least `leastTextWidth`; otherwise the trailing part under the text, `stackedGap` below it at
/// the row's trailing edge (as wide as the row at most), and the text as wide as the row. tvOS's rows, 1200 pt wide,
/// keep their stacks.
struct SettingsRowLayout: Layout {
    let leastTextWidth: CGFloat
    var spacing: CGFloat = 8

    /// How far under the text the trailing part goes.
    static let stackedGap: CGFloat = 8

    /// The narrowest text column the trailing part stays beside, for a row titled `title` (in `titleStyle`, the body
    /// font unless given) with `subtitle` (footnote) at `dynamicTypeSize` (iOS; the Mac's text has one size): 8 em of
    /// the title's font, some 16 characters a line, two or three words; or the widest word of the title or subtitle in
    /// its font, where wider. Measured once per row's text and size: each row's body asks again.
    @MainActor
    static func leastTextWidth(
        title: String, subtitle: String?, titleStyle: PlatformFont.TextStyle = .body, dynamicTypeSize: DynamicTypeSize
    ) -> CGFloat {
        let key = TextWidthKey(title: title, subtitle: subtitle, titleStyle: titleStyle, dynamicTypeSize: dynamicTypeSize)
        if let width = leastTextWidths[key] { return width }
        #if os(iOS)
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let titleFont = UIFont.preferredFont(forTextStyle: titleStyle, compatibleWith: traits)
        let footnote = UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traits)
        #else
        let titleFont = NSFont.preferredFont(forTextStyle: titleStyle)
        let footnote = NSFont.preferredFont(forTextStyle: .footnote)
        #endif
        let width = max(8 * titleFont.pointSize, widestWord(title, font: titleFont), subtitle.map { widestWord($0, font: footnote) } ?? 0)
        leastTextWidths[key] = width
        return width
    }

    private struct TextWidthKey: Hashable {
        let title: String
        let subtitle: String?
        let titleStyle: PlatformFont.TextStyle
        let dynamicTypeSize: DynamicTypeSize
    }

    @MainActor private static var leastTextWidths: [TextWidthKey: CGFloat] = [:]

    /// Whether `title` keeps one line beside `value` (body font, at `dynamicTypeSize`) and a trailing mark `markWidth`
    /// wide in a row `width` wide, 12 pt apart: where it doesn't, the value goes under the title. Unmeasured: beside.
    static func fitsBeside(title: String, value: String, width: CGFloat?, markWidth: CGFloat, dynamicTypeSize: DynamicTypeSize) -> Bool {
        guard let width else { return true }
        #if os(iOS)
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
        #else
        let font = NSFont.preferredFont(forTextStyle: .body)
        #endif
        let titleWidth = (title as NSString).size(withAttributes: [.font: font]).width
        let valueWidth = (value as NSString).size(withAttributes: [.font: font]).width
        return titleWidth + 12 + valueWidth + (markWidth > 0 ? 12 + markWidth : 0) <= width
    }

    /// The width of `text`'s widest piece that a line can't break inside (a word with its punctuation; in Japanese,
    /// a character or a few), in `font`.
    private static func widestWord(_ text: String, font: PlatformFont) -> CGFloat {
        let string = text as NSString
        let tokenizer = CFStringTokenizerCreate(nil, text as CFString, CFRange(location: 0, length: string.length), kCFStringTokenizerUnitLineBreak, nil)
        var widest: CGFloat = 0
        while CFStringTokenizerAdvanceToNextToken(tokenizer) != [] {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let word = string.substring(with: NSRange(location: range.location, length: range.length)).trimmingCharacters(in: .whitespacesAndNewlines)
            widest = max(widest, (word as NSString).size(withAttributes: [.font: font]).width)
        }
        return widest.rounded(.up)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let text = subviews.first else { return .zero }
        guard subviews.count > 1 else { return text.sizeThatFits(proposal) }
        let trailing = subviews[1]
        let ideal = trailing.sizeThatFits(.unspecified)
        guard let width = proposal.width else {
            let textSize = text.sizeThatFits(.unspecified)
            return CGSize(width: textSize.width + spacing + ideal.width, height: max(textSize.height, ideal.height))
        }
        if let textWidth = besideWidth(width, trailing: ideal) {
            return CGSize(width: width, height: max(text.sizeThatFits(ProposedViewSize(width: textWidth, height: nil)).height, ideal.height))
        }
        let textHeight = text.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        let trailingHeight = trailing.sizeThatFits(ProposedViewSize(width: min(ideal.width, width), height: nil)).height
        return CGSize(width: width, height: textHeight + Self.stackedGap + trailingHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let text = subviews.first else { return }
        guard subviews.count > 1 else { return text.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size)) }
        let trailing = subviews[1]
        let ideal = trailing.sizeThatFits(.unspecified)
        if let textWidth = besideWidth(bounds.width, trailing: ideal) {
            text.place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(width: textWidth, height: nil))
            trailing.place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing, proposal: ProposedViewSize(ideal))
        } else {
            let full = ProposedViewSize(width: bounds.width, height: nil)
            let textHeight = text.sizeThatFits(full).height
            text.place(at: bounds.origin, anchor: .topLeading, proposal: full)
            trailing.place(
                at: CGPoint(x: bounds.maxX, y: bounds.minY + textHeight + Self.stackedGap), anchor: .topTrailing,
                proposal: ProposedViewSize(width: min(ideal.width, bounds.width), height: nil)
            )
        }
    }

    /// The text's width beside the trailing part at its ideal size, where that leaves the text `leastTextWidth`.
    private func besideWidth(_ width: CGFloat, trailing: CGSize) -> CGFloat? {
        let textWidth = width - spacing - trailing.width
        return textWidth >= leastTextWidth ? textWidth : nil
    }
}

/// The platform's font, for measuring a row's words (`SettingsRowLayout`).
#if os(iOS)
typealias PlatformFont = UIFont
#else
typealias PlatformFont = NSFont
#endif
#endif

#if os(tvOS)
/// A setting's values as a list in a form, as tvOS's own Settings lists them: the chosen one checked and focused first;
/// picking one closes the list, as Menu does without picking.
private struct SettingChoiceList: View {
    let row: SettingChoiceRow
    let id: String
    let onPick: (String) -> Void
    let onClose: () -> Void

    @FocusState private var focused: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(row.options, id: \.id) { option in
                        Button { onPick(option.id) } label: {
                            HStack(spacing: 24) {
                                Text(option.label).frame(maxWidth: .infinity, alignment: .leading)
                                if option.selected { Image(systemName: "checkmark").accessibilityHidden(true) }
                            }
                        }
                        .focused($focused, equals: option.id)
                        .accessibilityAddTraits(option.selected ? .isSelected : [])
                        .accessibilityIdentifier("\(id).option.\(option.id)")
                    }
                } footer: {
                    if let caption = row.caption { Text(caption) }
                }
            }
            .settingsForm()
            .pageTitle(row.title)
            .defaultFocus($focused, row.options.first(where: \.selected)?.id)
        }
        .backAction(onClose)
    }
}
#endif
