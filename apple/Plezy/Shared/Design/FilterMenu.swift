import SwiftUI
import PlezyKit

/// What a filter's capsule shows: its `name` ("Library", "Sort by"), the `text` on the capsule (the name until the
/// filter narrows what is shown, then the pick: "Movies"), the `spoken` label VoiceOver and the harness read ("Library:
/// Movies"), and whether it `narrowed` what is shown.
struct FilterChip {
    let name: String
    let text: String
    var spoken: String
    var narrowed = false

    init(name: String, text: String, spoken: String? = nil, narrowed: Bool = false) {
        self.name = name
        self.text = text
        self.spoken = spoken ?? "\(name): \(text)"
        self.narrowed = narrowed
    }
}

/// One option of a `FilterMenu`: its label, its detail where it has one (a library's server), whether it is selected,
/// the heading of the group it starts where the options come in groups (a server's name over its libraries; empty for a
/// group set apart by its divider alone), and the `symbol` it shows beside its label (a sort's direction, `arrow.up` or
/// `arrow.down`). Its accessibility identifier, `<id>.option.<i>`, ends in `.selected` while selected, then `.<symbol>`
/// where it has one, for the harness, which can't read a menu's checks.
struct FilterOption {
    let label: String
    var detail: String?
    let selected: Bool
    var heading: String?
    var symbol: String?

    func identifier(_ id: String, _ index: Int) -> String {
        "\(id).option.\(index)" + (selected ? ".selected" : "") + (selected ? symbol.map { ".\($0)" } ?? "" : "")
    }
}

extension Array where Element == FilterOption {
    /// The options' groups in order: each starts at an option with a heading (the first also without one), its
    /// options' indices.
    var groups: [(heading: String?, indices: Range<Int>)] {
        let starts = indices.filter { $0 == 0 || self[$0].heading != nil }
        return starts.enumerated().map { at, start in
            (self[start].heading, start..<(at + 1 < starts.count ? starts[at + 1] : count))
        }
    }
}

/// A filter: a capsule showing its chip's text (`FilterChip`) that opens its options. The one filter control of every
/// screen (Libraries' library, view, grouping and sort, Downloads' view and options), so a row of filters shares one
/// height, font and padding. With a `symbol` (the sort) the symbol comes before the text, and a compact header row
/// (`screenHeader` on iPhone) shows the symbol alone, without the chevron, but for a `named` filter (Library's library),
/// which shows its text there too, after its symbol where it has one; a compact row cuts the text short where it
/// gives the capsule less than its width. VoiceOver and the harness read the chip's spoken text as its label everywhere
/// ("Sort by: Title"), selected while it narrows what is shown. `id` is its accessibility identifier, each option's
/// `<id>.option.<i>`.
///
/// A native menu, where each option shows its detail, its symbol and a check while selected (`FilterMenuOptions`). On
/// iOS and tvOS a multi-select filter's menu stays open while
/// options are toggled (macOS menus close on every pick). The capsule is Liquid Glass (`glassCapsule`), as the window
/// toolbar's controls are, and so is Filters' (`FilterButton`): one shape, height and padding for both
/// (`roundGlassLabel`). On tvOS the menu opens from the capsule, and focus goes back to it as the menu closes.
struct FilterMenu: View {
    let chip: FilterChip
    var symbol: String?
    /// An image asset (a catalog source's brand mark) shown alone in place of the text, everywhere.
    var mark: String?
    let options: [FilterOption]
    /// The symbol alone, everywhere, the chip's text left to VoiceOver (Libraries' type, the row's least used filter).
    var symbolOnly = false
    /// The text shows in a compact row too (Library's library, named in the row): the one filter there that does. Its
    /// symbol shows beside its name in every form of the row, so it never comes and goes as the type or view changes.
    var named = false
    /// Its turn to show its symbol alone in a row that gives way a step at a time (`symbolRank`, `HeaderRank`); nil,
    /// only in a compact row.
    var rank: Int?
    var multiSelect = false
    let id: String
    /// Where the screen keeps the capsule's focus, under `id`; nil where none does.
    var focus: FocusState<String?>.Binding?
    let onSelect: (Int) -> Void

    @Environment(\.compactFilters) private var compact
    @Environment(\.symbolRank) private var symbolRank

    var body: some View {
        control
            #if os(tvOS)
            .fixedSize()
            #else
            #if os(macOS)
            // The Mac's menu button keeps the width its first label took, as its accessibility frame (159 pt for "Codec
            // Samples" over the 107 pt capsule "Movies" draws once picked): a new one for each text.
            .id(chip.text)
            #endif
            // A compact row narrows the capsule, which cuts its text short.
            .fixedSize(horizontal: false, vertical: true)
            #endif
            .accessibilityLabel(chip.spoken)
            .accessibilityAddTraits(chip.narrowed ? .isSelected : [])
            .accessibilityIdentifier(id)
            .trackingFocus(focus, as: id)
    }

    private var control: some View {
        Menu {
            FilterMenuOptions(options: options, multiSelect: multiSelect, id: id, onSelect: onSelect)
        } label: {
            FilterCapsule(
                text: chip.text, symbol: symbol, mark: mark, symbolOnly: symbolOnly,
                compact: compact || rank.map { $0 <= symbolRank } == true, named: named
            )
            .glassLabel()
        }
        .menuStyle(.button)
        // The capsule draws its own chevron; the Mac would add its indicator beside it.
        .menuIndicator(.hidden)
        .roundGlassControl(.capsule, menu: true)
    }
}

/// A filter's capsule label: the symbol where it has one, the text (not beside a symbol where `symbolOnly`, nor in a
/// `compact` row but where `named`; never beside a `mark`, which shows alone), a chevron, but for a symbol alone in a
/// compact row; a line of the text tall, however tall its symbol or mark, so every capsule of a row has one height. A
/// `named` capsule in a compact row cuts its text short where it is given less than its width. Also the label of a
/// filter button that opens a sheet rather than a menu (Libraries' and Downloads' Filters) and of Apple TV's filters'
/// menu (`LibraryFiltersMenu`). On the Mac a symbol before the text is part of the text: a menu's label that starts
/// with an image and a text was read as an image and a title, each its own control as tall as itself (12 and 16 pt
/// beside the 28 pt capsules), not the capsule.
struct FilterCapsule: View {
    let text: String
    var symbol: String?
    var mark: String?
    var symbolOnly = false
    var compact = false
    var named = false
    /// Draws the trailing chevron of a capsule that opens a menu or a sheet; false for a capsule that acts at once.
    var chevron = true

    /// The mark's side: a line of the capsule's text.
    #if os(tvOS)
    @ScaledMetric(relativeTo: .body) private var markSide: CGFloat = 36
    #else
    @ScaledMetric(relativeTo: .subheadline) private var markSide: CGFloat = 18
    #endif

    var body: some View {
        LineTall {
            Text(verbatim: " ").hidden()
            if let mark {
                line(chevron: true) {
                    Image(mark)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: markSide, height: markSide)
                }
            } else if let symbol, symbolAlone {
                line(chevron: !compact) { Image(systemName: symbol) }
            } else {
                line(chevron: chevron) {
                    #if os(macOS)
                    if let symbol {
                        Text("\(Image(systemName: symbol)) \(text)").lineLimit(1)
                    } else {
                        Text(text).lineLimit(1)
                    }
                    #else
                    if let symbol { Image(systemName: symbol) }
                    Text(text).lineLimit(1)
                    #endif
                }
            }
        }
        #if os(iOS)
        // tvOS keeps the system's button font: the capsule matches the buttons beside it; on the Mac the capsules take
        // the toolbar's (`glassCapsuleLabel`).
        .font(HeaderMetrics.controlFont)
        #endif
    }

    /// Its symbol shows alone.
    private var symbolAlone: Bool {
        symbolOnly || compact && !named
    }

    /// A symbol alone without its chevron (a compact row's): drawn as a circle (`glassLabel`).
    var round: Bool {
        mark == nil && symbol != nil && symbolAlone && compact
    }

    /// The capsule in its glass's padding (`roundGlassLabel`): where it is `round` a circle as tall as a capsule, so a
    /// row's round filters are as wide as they are tall, every one the size of the row's round actions, its symbol in
    /// its middle; else a capsule as wide as its content.
    @ViewBuilder
    func glassLabel() -> some View {
        #if os(tvOS)
        roundGlassLabel(.capsule)
        #else
        if round {
            AsWideAsTall { roundGlassLabel(.capsule) }.contentShape(Circle())
        } else {
            roundGlassLabel(.capsule)
        }
        #endif
    }

    /// `content`, then the chevron where `chevron`.
    private func line(chevron: Bool, @ViewBuilder _ content: () -> some View) -> some View {
        HStack(spacing: 6) {
            content()
            if chevron {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Its first view (a line of text, unseen) sets its height; the second is laid on it at its leading end, centred down
/// it, as wide as it takes, its symbol drawn past the line where it is taller: a symbol taller than the text (the
/// type's) made its capsule 1.3 pt taller than the row's others.
private struct LineTall: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let line = subviews.first?.sizeThatFits(.unspecified) else { return .zero }
        let content = subviews.count > 1 ? subviews[1].sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) : .zero
        return CGSize(width: max(line.width, content.width), height: line.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            subview.place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(width: bounds.width, height: nil))
        }
    }
}

#if !os(tvOS)
/// Its one view centred in a square as wide as the view is tall, drawn past the square's sides where it is wider (a
/// symbol in a capsule's padding, which is clear).
private struct AsWideAsTall: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = subviews.first?.sizeThatFits(.unspecified).height ?? 0
        return CGSize(width: height, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: .unspecified)
    }
}
#endif

#if !os(tvOS)
/// A filter capsule that opens a sheet or a popover (`action`) rather than a menu: Libraries' and Downloads' Filters,
/// whose fields need pages, and Browse's sort on iPhone and iPad (`fills` off). Drawn and read as `FilterMenu`'s capsule,
/// but filled white while a filter is set (`chip.narrowed`, where it `fills`): the capsule itself shows it, also on a
/// phone, where it shows its symbol alone, without the count.
struct FilterButton: View {
    let chip: FilterChip
    var symbol: String?
    var fills = true
    /// The capsule's chevron: false where the tap acts at once rather than opening options.
    var chevron = true
    /// Its turn to show its symbol alone in a row that gives way a filter at a time (`FilterMenu.rank`).
    var rank: Int?
    let id: String
    var focus: FocusState<String?>.Binding?
    let action: () -> Void

    @Environment(\.compactFilters) private var compact
    @Environment(\.symbolRank) private var symbolRank

    var body: some View {
        Button(action: action) {
            FilterCapsule(text: chip.text, symbol: symbol, compact: compact || rank.map { $0 <= symbolRank } == true, chevron: chevron)
                .glassLabel()
        }
        .glassCapsule(filled: fills && chip.narrowed)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(chip.spoken)
        .accessibilityAddTraits(chip.narrowed ? .isSelected : [])
        .accessibilityIdentifier(id)
        .trackingFocus(focus, as: id)
    }
}
#endif

/// A filter's options in a native menu (`FilterMenu`, Apple TV's `LibraryFiltersMenu`): each a button with its detail
/// and its symbol where it has one (a sort's direction), `<id>.option.<i>`; a selected one is a toggle that is on, so
/// the menu draws its check in the menu's own place before the label (a Mac menu shows no item icon, so a check drawn
/// as one would be lost, and iOS and tvOS would push the label aside for it). A group with a heading follows a
/// divider under its heading as a line of its own (an empty heading: the divider alone); on Apple TV in a section under
/// it. iOS and the Mac drop the accessibility identifiers of a section's items, so there the heading is not a section.
/// On iOS and tvOS a multi-select filter's menu stays open while options are toggled (macOS menus close on every pick).
struct FilterMenuOptions: View {
    let options: [FilterOption]
    var multiSelect = false
    let id: String
    let onSelect: (Int) -> Void

    var body: some View {
        ForEach(options.groups, id: \.indices.lowerBound) { group in
            if let heading = group.heading {
                #if os(tvOS)
                if heading.isEmpty {
                    Section { buttons(group.indices) }
                } else {
                    Section(heading) { buttons(group.indices) }
                }
                #else
                if group.indices.lowerBound > 0 { Divider() }
                if !heading.isEmpty { Text(heading).accessibilityAddTraits(.isHeader) }
                buttons(group.indices)
                #endif
            } else {
                buttons(group.indices)
            }
        }
    }

    @ViewBuilder
    private func buttons(_ indices: Range<Int>) -> some View {
        ForEach(indices, id: \.self) { index in
            let option = options[index]
            Group {
                if option.selected {
                    Toggle(isOn: Binding(get: { true }, set: { _ in onSelect(index) })) { optionLabel(option) }
                } else {
                    Button { onSelect(index) } label: { optionLabel(option) }
                }
            }
            .accessibilityIdentifier(option.identifier(id, index))
            #if !os(macOS)
            .menuActionDismissBehavior(multiSelect ? .disabled : .automatic)
            #endif
        }
    }

    /// The option's text, with its symbol where it has one (a Mac menu shows an item's symbol only when asked).
    @ViewBuilder
    private func optionLabel(_ option: FilterOption) -> some View {
        if let symbol = option.symbol {
            Label { optionText(option) } icon: { Image(systemName: symbol) }
                .labelStyle(.titleAndIcon)
        } else {
            optionText(option)
        }
    }

    @ViewBuilder
    private func optionText(_ option: FilterOption) -> some View {
        Text(option.label)
        if let detail = option.detail {
            Text(detail)
        }
    }
}

#if os(tvOS)
/// The row of filters above a screen's content on tvOS (iOS and the Mac: `screenHeader`), starting at the content's
/// leading edge, `trailing` (the screen's actions) at its trailing end: it wraps and is the screen's focus section above
/// the content, full width so Down from anywhere on the tab bar lands on it; a scroll view there would be the screen's
/// first one, which reaches up under the tab bar, its content with it, and a focus section that tall kept Up from ever
/// leaving the row for the tab bar.
struct FilterRow<Content: View, Trailing: View>: View {
    @ViewBuilder let content: () -> Content
    @ViewBuilder let trailing: () -> Trailing

    @Environment(\.screenSides) private var sides

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            FlowLayout(spacing: 24) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 24) { trailing() }
        }
        // The capsules' glass, one row of it.
        .glassGroup(spacing: 24)
        .padding(sides.insets)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .shelfFocusSection()
    }
}

extension FilterRow where Trailing == EmptyView {
    init(@ViewBuilder content: @escaping () -> Content) {
        self.init(content: content, trailing: { EmptyView() })
    }
}
#endif

private extension View {
    @ViewBuilder
    func trackingFocus(_ focus: FocusState<String?>.Binding?, as id: String) -> some View {
        if let focus {
            focused(focus, equals: id)
        } else {
            self
        }
    }
}
