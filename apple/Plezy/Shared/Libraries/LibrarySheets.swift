import SwiftUI
import PlezyKit

#if !os(tvOS)
/// Browse's filter editor: Clear all, then the library's fields. A yes/no field picks Any, Yes or No; every other
/// field opens a page of its own (values to include or exclude with a search past 15, dates, text or numbers with their
/// match modes), its summary beside it. Edits are staged and go to the store once, as the editor closes (but by Cancel),
/// only when they changed, and only to the library the editor opened on. Apple TV has the filters' menu instead
/// (`LibraryFiltersMenu`).
/// - iPhone, iPad: a settings form in the app's sheet (`appSheet`), Clear all first while any is set; a yes/no field is one
///   row that steps Any, Yes, No on a press (Left and Right step it with the arrow keys). Apply in its bar commits the
///   edits, Cancel drops them; a swipe down closes it as Apply does.
/// - Mac: a popover from the Filters capsule (`BrowseFilters`), titled, Clear all at the title's trailing end; a yes/no
///   field is a menu (Any, Yes, No); a field's page replaces the fields in the popover, Back (or Escape) over it returns.
///   Closes by Escape or a click outside it.
///
/// Accessibility identifiers: `libraries.filters.sheet`, `libraries.filters.clear`, `libraries.filters.back` (Mac),
/// `libraries.filter.<field>`, `libraries.value.all`, `libraries.value.<title>`, `libraries.values.retry`,
/// `libraries.exclude`, `libraries.date.all`, `libraries.date.<days>.<older>`, `libraries.text.all`,
/// `libraries.match.<op>`, `libraries.range.from`, `libraries.range.to`, `libraries.filters.cancel`,
/// `libraries.filters.apply`.
struct LibraryFiltersSheet: View {
    let browse: LibraryBrowseStore
    let onClose: () -> Void

    @State private var staged: [LibraryFilter]
    /// The filters as the editor opened, to tell an edit from none.
    private let opened: [LibraryFilter]
    /// The library the editor opened on.
    private let libraryKey: String
    #if os(macOS)
    /// The field whose page the popover shows; nil for the fields.
    @State private var page: MediaFilter?
    #endif

    private typealias Edit = LibraryFilterEditingKt

    init(browse: LibraryBrowseStore, onClose: @escaping () -> Void) {
        self.browse = browse
        self.onClose = onClose
        opened = browse.state.value.selectedFilters
        libraryKey = browse.libraryKey
        _staged = State(initialValue: opened)
    }

    var body: some View {
        editor
            .onDisappear {
                if staged != opened { browse.applyFilters(filters: staged, libraryKey: libraryKey) }
            }
    }

    #if os(macOS)
    private var editor: some View {
        FiltersPopover(
            pageTitle: page?.title,
            ids: FiltersPopoverIds(sheet: "libraries.filters.sheet", clear: "libraries.filters.clear", back: "libraries.filters.back"),
            canClear: !staged.isEmpty,
            onClear: { staged = [] },
            onBack: { page = nil },
            onClose: onClose
        ) {
            if let page {
                FilterFieldPage(browse: browse, field: page, staged: $staged)
            } else {
                Form {
                    Section { fields }
                }
                .settingsForm()
            }
        }
    }
    #else
    private var editor: some View {
        let cancel = SheetAction(title: T.shared.common.cancel, id: "libraries.filters.cancel") {
            staged = opened
            onClose()
        }
        let apply = SheetAction(title: T.shared.common.apply, id: "libraries.filters.apply", action: onClose)
        return SheetPage(id: "libraries.filters.sheet", title: T.shared.libraries.filters, cancel: cancel, confirm: apply) {
            Form {
                if !staged.isEmpty {
                    Section {
                        Button(T.shared.libraries.clearAll, role: .destructive) { staged = [] }
                            .accessibilityIdentifier("libraries.filters.clear")
                    }
                }
                Section { fields }
            }
            .settingsForm()
        }
    }
    #endif

    /// The library's fields, each a row with its value or summary.
    private var fields: some View {
        ForEach(browse.state.value.filters, id: \.filter) { field in
            if field.isBoolean {
                booleanRow(field)
            } else {
                fieldRow(field)
            }
        }
    }

    /// A field that opens its page, its summary beside its title.
    @ViewBuilder
    private func fieldRow(_ field: MediaFilter) -> some View {
        let summary = Text(Edit.filterFieldSummary(filter: field, clauses: staged, serverId: browse.serverId, libraryKey: browse.libraryKey) ?? "")
        #if os(macOS)
        // A Mac form draws a button as a push button across the row: the row is plain, with a navigation link's chevron.
        Button { page = field } label: {
            LabeledContent(field.title) {
                HStack(spacing: 6) {
                    summary
                    Image(systemName: "chevron.forward").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .accessibilityIdentifier("libraries.filter.\(field.filter)")
        #else
        NavigationLink {
            FilterFieldPage(browse: browse, field: field, staged: $staged)
        } label: {
            LabeledContent(field.title) { summary }
        }
        .accessibilityIdentifier("libraries.filter.\(field.filter)")
        #endif
    }

    /// A yes/no field: Any, Yes, No (No where the field can be negated). The Mac picks one from a menu; iPhone and iPad
    /// step through them on a press, Left and Right step back and forth.
    @ViewBuilder
    private func booleanRow(_ field: MediaFilter) -> some View {
        let value = Edit.booleanFilterState(filters: staged, field: field.filter)
        let states = booleanStates(field)
        #if os(macOS)
        Picker(field.title, selection: Binding(
            get: { value },
            set: { staged = Edit.withBooleanFilter(filters: staged, field: field.filter, state: $0) }
        )) {
            ForEach(states, id: \.self) { Text(booleanLabel($0)).tag($0) }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("libraries.filter.\(field.filter)")
        #else
        let at = states.firstIndex(of: value) ?? 0
        let step = { (delta: Int) in
            let next = states[(at + delta + states.count) % states.count]
            staged = Edit.withBooleanFilter(filters: staged, field: field.filter, state: next)
        }
        let label = booleanLabel(value)
        Button { step(1) } label: {
            LabeledContent(field.title) { Text(label) }
        }
        .horizontalSteps(step)
        .accessibilityValue(label)
        .accessibilityIdentifier("libraries.filter.\(field.filter)")
        #endif
    }
}
#endif

#if os(tvOS)
/// Browse's filters on Apple TV: a filter capsule (`libraries.filters`, read as `FilterMenu`'s) that opens the system's
/// menu, each pick applied at once. Clear all first while any is set, then the library's fields, each with its summary:
/// a yes/no field a submenu of Any, Yes, No; a value list a submenu that stays open while its values are toggled, All
/// and, where the field can be negated, Include and Exclude above them (the values load as the capsule shows); a date a
/// submenu of its windows; text and numbers, which need typing, their page over the screen (`FilterFieldPage`), applied
/// as it closes. The submenus are `libraries.filter.<field>`, their options `libraries.filter.<field>.option.<i>`.
struct LibraryFiltersMenu: View {
    let browse: LibraryBrowseStore
    let state: BrowseUiState

    /// The value lists' values by field, once loaded.
    @State private var values: [String: [MediaFilterValue]] = [:]
    /// The value lists that failed to load.
    @State private var failed: Set<String> = []
    /// The field whose page shows.
    @State private var page: MediaFilter?

    private typealias Edit = LibraryFilterEditingKt

    var body: some View {
        let chip = FilterChip(name: T.shared.libraries.filters, text: state.filtersLabel, narrowed: state.filtersActive)
        Menu {
            if !state.selectedFilters.isEmpty {
                Section {
                    Button(T.shared.libraries.clearAll, role: .destructive) { apply([]) }
                        .accessibilityIdentifier("libraries.filters.clear")
                }
            }
            ForEach(state.filters, id: \.filter) { field in
                entry(field)
            }
        } label: {
            FilterCapsule(text: chip.text, symbol: "line.3.horizontal.decrease")
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .roundGlassControl(.capsule, menu: true)
        .fixedSize()
        .accessibilityLabel(chip.spoken)
        .accessibilityAddTraits(chip.narrowed ? .isSelected : [])
        .accessibilityIdentifier("libraries.filters")
        .task(id: state.filters.filter { $0.editorKind == .valueList }.map(\.filter)) { await loadValues() }
        .appSheet(isPresented: Binding(get: { page != nil }, set: { if !$0 { page = nil } })) {
            if let page { FilterPageCover(browse: browse, field: page) }
        }
    }

    @ViewBuilder
    private func entry(_ field: MediaFilter) -> some View {
        let id = "libraries.filter.\(field.filter)"
        let label = Text(field.title)
        let summary = Edit.filterFieldSummary(
            filter: field, clauses: state.selectedFilters, serverId: browse.serverId, libraryKey: browse.libraryKey
        ).map { Text($0) }
        switch field.editorKind {
        case .toggle:
            let value = Edit.booleanFilterState(filters: state.selectedFilters, field: field.filter)
            let states = booleanStates(field)
            Menu {
                FilterMenuOptions(options: states.map { FilterOption(label: booleanLabel($0), selected: $0 == value) }, id: id) {
                    apply(Edit.withBooleanFilter(filters: current, field: field.filter, state: states[$0]))
                }
            } label: {
                label
                Text(booleanLabel(value))
            }
            .accessibilityIdentifier(id)
        case .valueList:
            Menu {
                valueOptions(field, id: id)
            } label: {
                label
                summary
            }
            .accessibilityIdentifier(id)
        case .date:
            let clause = state.selectedFilters.first { $0.field == field.filter }
            let windows = [false, true].flatMap { older in Edit.RELATIVE_DATE_WINDOWS.map { (window: $0, older: older) } }
            let options = [FilterOption(label: T.shared.libraries.all, selected: clause == nil)] + windows.map { window in
                FilterOption(
                    label: Edit.relativeDateLabel(value: window.window, older: window.older),
                    selected: clause?.op == (window.older ? LibraryFilterOperator.atMost : .atLeast) && clause?.values.first == window.window
                )
            }
            Menu {
                FilterMenuOptions(options: options, id: id) { index in
                    let window = index == 0 ? nil : windows[index - 1]
                    apply(Edit.withDateWindow(filters: current, field: field.filter, window: window?.window, older: window?.older ?? false))
                }
            } label: {
                label
                summary
            }
            .accessibilityIdentifier(id)
        default:
            Button { page = field } label: {
                label
                summary
            }
            .accessibilityIdentifier(id)
        }
    }

    /// A value list's options: All, Include and Exclude where the field can be negated, then its values; a failed
    /// load's retry, the line saying there are none, or a spinner's line while they load.
    @ViewBuilder
    private func valueOptions(_ field: MediaFilter, id: String) -> some View {
        let selected = Edit.selectedFilterValues(filters: state.selectedFilters, field: field.filter)
        let excluded = Edit.isFilterExcluded(filters: state.selectedFilters, field: field.filter)
        let shown = values[field.filter] ?? []
        let modes = field.supportsExclusion ? [false, true] : []
        let options = [FilterOption(label: T.shared.libraries.all, selected: selected.isEmpty)]
            + modes.map { exclude in
                FilterOption(
                    label: exclude ? T.shared.libraries.advancedFilters.exclude : T.shared.libraries.advancedFilters.include,
                    selected: exclude == excluded, heading: exclude ? nil : T.shared.libraries.filters
                )
            }
            + shown.enumerated().map { index, value in
                FilterOption(
                    label: value.title, selected: selected.contains(browse.valueId(filter: field, value: value)),
                    heading: index == 0 ? field.title : nil
                )
            }
        FilterMenuOptions(options: options, multiSelect: true, id: id) { index in
            if index == 0 {
                apply(current.filter { $0.field != field.filter })
            } else if index <= modes.count {
                apply(Edit.withFilterExcluded(filters: current, field: field.filter, exclude: modes[index - 1]))
            } else {
                let value = browse.valueId(filter: field, value: shown[index - 1 - modes.count])
                let exclude = Edit.isFilterExcluded(filters: current, field: field.filter)
                apply(Edit.toggleFilterValue(filters: current, field: field.filter, value: value, exclude: exclude))
            }
        }
        if failed.contains(field.filter) {
            Button(T.shared.errors.unableToLoad(context: field.title)) { Task { await loadValues() } }
                .accessibilityIdentifier("libraries.values.retry")
        } else if let loaded = values[field.filter], loaded.isEmpty {
            Text(T.shared.libraries.advancedFilters.noValues)
        } else if values[field.filter] == nil {
            Text(T.shared.common.loading)
        }
    }

    /// The filters as they are now, which a pick edits: the state shown may be a moment behind a pick before it.
    private var current: [LibraryFilter] { browse.state.value.selectedFilters }

    private func apply(_ filters: [LibraryFilter]) {
        browse.applyFilters(filters: filters, libraryKey: browse.libraryKey)
    }

    /// Loads the value lists not loaded yet.
    private func loadValues() async {
        // The Kotlin store and filters aren't Sendable; `filterValues` runs on the main thread, so they stay there.
        nonisolated(unsafe) let browse = browse
        for field in state.filters where field.editorKind == .valueList && values[field.filter] == nil {
            nonisolated(unsafe) let field = field
            failed.remove(field.filter)
            do {
                values[field.filter] = try await browse.filterValues(filter: field)
            } catch {
                failed.insert(field.filter)
            }
        }
    }
}

/// A text or number field's page over the screen (`LibraryFiltersMenu`): its edits staged, applied as it closes (the
/// remote's Menu), only when they changed.
private struct FilterPageCover: View {
    let browse: LibraryBrowseStore
    let field: MediaFilter

    @State private var staged: [LibraryFilter]
    private let libraryKey: String

    init(browse: LibraryBrowseStore, field: MediaFilter) {
        self.browse = browse
        self.field = field
        libraryKey = browse.libraryKey
        _staged = State(initialValue: browse.state.value.selectedFilters)
    }

    var body: some View {
        NavigationStack {
            FilterFieldPage(browse: browse, field: field, staged: $staged)
        }
        .onDisappear { browse.applyFilters(filters: staged, libraryKey: libraryKey) }
    }
}
#endif

/// The states a yes/no field picks from: Any, Yes, and No where the field can be negated.
private func booleanStates(_ field: MediaFilter) -> [BooleanFilterState] {
    field.supportsExclusion ? [.any, .yes, .no] : [.any, .yes]
}

private func booleanLabel(_ state: BooleanFilterState) -> String {
    state == .yes ? T.shared.libraries.advancedFilters.yes
        : state == .no ? T.shared.libraries.advancedFilters.no : T.shared.libraries.advancedFilters.any
}

/// A field's page: values, a date window, or text and numbers.
private struct FilterFieldPage: View {
    let browse: LibraryBrowseStore
    let field: MediaFilter
    @Binding var staged: [LibraryFilter]

    var body: some View {
        Form {
            switch field.editorKind {
            case .valueList: ValuesPage(browse: browse, field: field, staged: $staged)
            case .date: DatePage(field: field, staged: $staged)
            default: TextValuePage(field: field, staged: $staged)
            }
        }
        .settingsForm()
        .pageTitle(field.title)
    }
}

/// A row that picks one of a page's choices: its label, a check while it is the one picked. Plain on the Mac, whose
/// form draws a button as a push button across the row.
private struct ChoiceRow: View {
    let label: String
    let selected: Bool
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer(minLength: 8)
                if selected { Image(systemName: "checkmark").foregroundStyle(Palette.primary) }
            }
            .contentShape(Rectangle())
        }
        .formRowButtonStyle()
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}

/// A value list: All, Include or Exclude where the field can be negated, then the values, each checked while picked
/// (a search over them past 15).
private struct ValuesPage: View {
    let browse: LibraryBrowseStore
    let field: MediaFilter
    @Binding var staged: [LibraryFilter]

    @State private var values: [MediaFilterValue]?
    @State private var failed = false
    @State private var query = ""

    private typealias Edit = LibraryFilterEditingKt

    var body: some View {
        let selected = Edit.selectedFilterValues(filters: staged, field: field.filter)
        let excluded = Edit.isFilterExcluded(filters: staged, field: field.filter)
        Section {
            ChoiceRow(label: T.shared.libraries.all, selected: selected.isEmpty, id: "libraries.value.all") {
                staged = staged.filter { $0.field != field.filter }
            }
            if field.supportsExclusion {
                Picker(T.shared.libraries.filters, selection: Binding(
                    get: { excluded },
                    set: { staged = Edit.withFilterExcluded(filters: staged, field: field.filter, exclude: $0) }
                )) {
                    Text(T.shared.libraries.advancedFilters.include).tag(false)
                    Text(T.shared.libraries.advancedFilters.exclude).tag(true)
                }
                .horizontalSteps { staged = Edit.withFilterExcluded(filters: staged, field: field.filter, exclude: $0 > 0) }
                .accessibilityIdentifier("libraries.exclude")
            }
        }
        Section {
            if failed {
                Button(T.shared.errors.unableToLoad(context: field.title)) { Task { await load() } }
                    .accessibilityIdentifier("libraries.values.retry")
            } else if let values {
                if values.count > 15 {
                    TextField(T.shared.libraries.advancedFilters.searchValues, text: $query)
                        .formFieldRow()
                }
                let shown = values.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
                if shown.isEmpty { Text(T.shared.libraries.advancedFilters.noValues).mutedForeground() }
                ForEach(shown, id: \.key) { value in
                    let id = browse.valueId(filter: field, value: value)
                    ChoiceRow(label: value.title, selected: selected.contains(id), id: "libraries.value.\(value.title)") {
                        staged = Edit.toggleFilterValue(filters: staged, field: field.filter, value: id, exclude: excluded)
                    }
                }
            } else {
                ProgressView().frame(maxWidth: .infinity).task { await load() }
            }
        }
    }

    private func load() async {
        failed = false
        // The Kotlin store and filter aren't Sendable; `filterValues` runs on the main thread, so they stay there.
        nonisolated(unsafe) let browse = browse
        nonisolated(unsafe) let field = field
        do {
            values = try await browse.filterValues(filter: field)
        } catch {
            failed = true
        }
    }
}

/// A date: All, the last 7/30/90 days and year, then older than each.
private struct DatePage: View {
    let field: MediaFilter
    @Binding var staged: [LibraryFilter]

    private typealias Edit = LibraryFilterEditingKt

    var body: some View {
        let clause = staged.first { $0.field == field.filter }
        Section {
            ChoiceRow(label: T.shared.libraries.all, selected: clause == nil, id: "libraries.date.all") {
                staged = Edit.withDateWindow(filters: staged, field: field.filter, window: nil, older: false)
            }
        }
        ForEach([false, true], id: \.self) { older in
            Section {
                ForEach(Edit.RELATIVE_DATE_WINDOWS, id: \.self) { window in
                    let op: LibraryFilterOperator = older ? .atMost : .atLeast
                    ChoiceRow(
                        label: Edit.relativeDateLabel(value: window, older: older),
                        selected: clause?.op == op && clause?.values.first == window,
                        id: "libraries.date.\(window).\(older)"
                    ) {
                        staged = Edit.withDateWindow(filters: staged, field: field.filter, window: window, older: older)
                    }
                }
            }
        }
    }
}

/// Text and numbers: All, the text (a range of numbers, in its unit), then the match modes the field supports.
private struct TextValuePage: View {
    let field: MediaFilter
    @Binding var staged: [LibraryFilter]

    @State private var text = ""
    @State private var from = ""
    @State private var to = ""
    @State private var picked: LibraryFilterOperator?

    private typealias Edit = LibraryFilterEditingKt

    var body: some View {
        let mode = picked ?? Edit.textMatchModes(filter: field).first!
        let clause = staged.first { $0.field == field.filter }
        Section {
            ChoiceRow(label: T.shared.libraries.all, selected: clause == nil, id: "libraries.text.all") {
                text = ""
                from = ""
                to = ""
                staged = staged.filter { $0.field != field.filter }
            }
        }
        if field.editorKind == .number {
            Section {
                numberField(T.shared.libraries.advancedFilters.from, text: $from, id: "libraries.range.from")
                numberField(T.shared.libraries.advancedFilters.to, text: $to, id: "libraries.range.to")
            }
            .onAppear {
                from = bound(.atLeast)
                to = bound(.atMost)
            }
        } else {
            Section {
                TextField(T.shared.libraries.advancedFilters.textHint, text: $text)
                    .onChange(of: text) { staged = Edit.withTextMatch(filters: staged, field: field.filter, text: text, op: mode) }
                    .formFieldRow()
            }
            Section {
                ForEach(Edit.textMatchModes(filter: field), id: \.self) { op in
                    ChoiceRow(label: Edit.textMatchLabel(op: op), selected: op == mode, id: "libraries.match.\(op.id)") {
                        picked = op
                        staged = Edit.withTextMatch(filters: staged, field: field.filter, text: text, op: op)
                    }
                }
            }
        }
    }

    /// The stored bound shown back in the unit it was typed in; empty when unset.
    private func bound(_ op: LibraryFilterOperator) -> String {
        Edit.numberBound(filters: staged, field: field.filter, op: op, unit: field.unit).map { "\($0.int64Value)" } ?? ""
    }

    private func numberField(_ label: String, text: Binding<String>, id: String) -> some View {
        LabeledContent(label) {
            HStack {
                TextField(label, text: text)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier(id)
                    .onChange(of: text.wrappedValue) {
                        // Digits only on every platform: a hardware keyboard or the tvOS one types anything.
                        let digits = text.wrappedValue.filter(\.isASCII).filter(\.isNumber)
                        if digits != text.wrappedValue {
                            text.wrappedValue = digits
                            return
                        }
                        staged = Edit.withNumberRange(
                            filters: staged, field: field.filter, from: Int64(from).map { KotlinLong(value: $0) },
                            to: Int64(to).map { KotlinLong(value: $0) }, unit: field.unit
                        )
                    }
                if let suffix = field.unit.suffix { Text(suffix).mutedForeground() }
            }
        }
    }
}

extension View {
    /// Left and Right on this focused row as `step(-1)` and `step(1)`: the remote's moves on Apple TV, the arrow keys
    /// elsewhere.
    func horizontalSteps(_ step: @escaping (Int) -> Void) -> some View {
        #if os(tvOS)
        onMoveCommand { direction in
            if direction == .left { step(-1) } else if direction == .right { step(1) }
        }
        #else
        onKeyPress(.leftArrow) {
            step(-1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            step(1)
            return .handled
        }
        #endif
    }
}

#if os(macOS)
/// The accessibility identifiers of a `FiltersPopover`: the popover, its Clear all, its Back.
struct FiltersPopoverIds {
    let sheet: String
    let clear: String
    let back: String
}

/// A Mac filter editor (Libraries', Downloads'): a popover from its Filters capsule, titled Filters with Clear all at
/// the title's trailing end; while a field's page shows (`pageTitle`), Back and the page's title instead. Escape steps
/// back from a page, then closes (`onClose`); a click outside closes it too. `content` is the fields' form or the page.
/// A form as tall as its rows up to the most a settings sheet's takes (`SheetHeightFromForm`, macOS 15 and later),
/// else a fixed height, as wide as a settings sheet's narrowest form column.
struct FiltersPopover<Content: View>: View {
    let pageTitle: String?
    let ids: FiltersPopoverIds
    let canClear: Bool
    let onClear: () -> Void
    let onBack: () -> Void
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if let pageTitle {
                    Button(T.shared.nav.back, systemImage: "chevron.backward", action: onBack)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier(ids.back)
                    Text(pageTitle).font(.headline).lineLimit(1)
                    Spacer(minLength: 8)
                } else {
                    Text(T.shared.libraries.filters).font(.headline)
                    Spacer(minLength: 8)
                    Button(T.shared.libraries.clearAll, action: onClear)
                        .buttonStyle(.borderless)
                        .disabled(!canClear)
                        .accessibilityIdentifier(ids.clear)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            content()
        }
        .frame(width: 380, height: Self.formSetsHeight ? nil : SheetSize.formMaxHeight)
        .environment(\.isInSheet, true)
        .environment(\.formSetsSheetHeight, Self.formSetsHeight)
        .background(PopoverEscape { if pageTitle != nil { onBack() } else { onClose() } })
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ids.sheet)
    }

    private static var formSetsHeight: Bool {
        if #available(macOS 15, *) { return true }
        return false
    }
}

/// Makes the popover it is in the key window as it shows, `action` taking its Escape (where no text field has the
/// keyboard). A popover's panel becomes key only for a text field, so Escape went to the window under it, whose Back
/// left the screen, rather than closing the popover.
private struct PopoverEscape: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> EscapeView { EscapeView() }

    func updateNSView(_ view: EscapeView, context: Context) {
        view.action = action
    }

    final class EscapeView: NSView {
        var action: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // Once the popover has ordered its panel in.
            Task { [weak self] in
                guard let self, let window else { return }
                window.makeKey()
                window.makeFirstResponder(self)
            }
        }

        override func cancelOperation(_ sender: Any?) {
            action?()
        }

        override func keyDown(with event: NSEvent) {
            if event.keyCode == 53 { action?() } else { super.keyDown(with: event) }
        }
    }
}
#endif
