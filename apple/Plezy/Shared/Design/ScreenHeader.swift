#if !os(tvOS)
import SwiftUI

/// A screen's header row on iPhone, iPad and the Mac: its filters and actions, pinned at the top of the screen while the
/// content under it scrolls. Every screen follows these rules:
///
/// 1. The row is the top of the screen and stays there over the content, which scrolls on its own under it. On iOS 26
///    and later the row is the screen's bar (`safeAreaBar`), clear: the content scrolls up under it and the status bar
///    or the navigation bar above it and fades out there to the background (`ScrollEdgeFade`, from the window's top to
///    just past the row), the one scroll edge of every screen with a row, the system's own hidden (Library's pager
///    tells the row when its shown page is scrolled, `drawnScrollEdge`). On the Mac's band the band's fade is under it
///    (rule 4). Elsewhere (before iOS 26, under the Mac's toolbar) it is stacked above the content, opaque. Libraries,
///    Discover, Downloads, Search and Live TV (pushed over Home, its tabs) have one. A screen with nothing to filter or
///    act on (Settings; Detail, whose actions sit under its title; Home, whose shortcuts are chips under Continue
///    Watching, its content fading the same way under the status bar, `softTopEdge`) has none, and a row with nothing to
///    show takes no room (Addons on iOS with one type, its Install in the bar).
/// 2. The filters lead the row (`screenHeader(filters:actions:)`), side by side, each at its own width while they fit;
///    on a phone a filter with a symbol shows the symbol alone, without its chevron (`compactFilters`: Library's view,
///    sort and Filters, Downloads' sort and Filters), but Library's library, which names the library, its symbol
///    before the name while that fits (`FilterMenu.named`), and Library's type shows its symbol alone everywhere,
///    last. Discover's type, catalog and filters; Library's library, view, sort, filters and type; Downloads' view;
///    Addons' type; Live TV's tabs. On iOS nothing in the row is cut short where it can move, at every text size: the
///    filters that don't fit go on more lines, beside the actions while each shows whole there, else with the actions
///    on a line of their own under them (`HeaderLine`). A screen whose filters are too many for a phone's line
///    (Libraries', Live TV's) keeps them on one line instead (`scrolls`, on iPad and the Mac too): in the width the
///    actions leave, from the page's leading edge, the actions beside them; on iPad and the Mac each filter with a
///    symbol shows it alone where they don't all fit whole (as on a phone); then the widest filter's text is cut short
///    to fit (`FittingRow`: Library's name, the last to give way, which on a phone Library's Shuffle makes room for in
///    its ⋯ menu where the name would show fewer than its first twelve characters, `leadRoom`), and on a phone where
///    even that doesn't fit (a large text size) the line scrolls sideways. A line that scrolls sideways ends at the
///    safe area beside iOS 27.1's vertical bar (`clearOfVerticalBar`), under none of the bar's column. On the Mac,
///    whose row on the band is as tall as the band, the widest is cut short past that (`FittingRow`), so the row never
///    runs past the window. A screen whose row is one control lays it out itself (`screenHeader(row:)`: Search's
///    field).
/// 3. The actions (Library's Shuffle and ⋯, Downloads' Pause all and Resume all, Addons' Install, Live TV's search,
///    favourites and refresh) go where the platform puts a screen's actions: in the bar where the screen shows one
///    with its title: any pushed iOS screen (the navigation bar), a pushed Mac screen on macOS 26 and later (the window
///    toolbar, titled, at its trailing end); where iOS 27.1's vertical bar shows (`verticalBarEdge`, the iPhone Duo's
///    screens, told by the window's traits), in its column as toolbar items, beside the tabs; else at the trailing end
///    of the row's first line, centred on it with the filters: on iPhone, whose destinations show no bar, on iPad's
///    destinations on iOS 26 and later, beside the sidebar, whose row sits on the empty bar's line, or under the
///    floating tab bar, right under its tabs (`destinationChrome`; in the bar under the floating tab bar the actions
///    stood a line above the filters), each in glass as tall as
///    the filters and in their font, an icon alone in a circle, an icon with its title where the screen asks
///    (`titledActions`: Downloads') in a capsule; on the Mac's band (a top-level destination, whose toolbar holds
///    navigation alone) and before macOS 26 in one glass capsule, as a bar groups its buttons, icons with their titles.
/// 4. The Mac's toolbar draws no background over any screen. On macOS 26 and later, while a screen's content is
///    scrolled up under the toolbar's band, it fades there to the window's black, most at the top, so the band's
///    buttons and controls stay readable over it (`windowToolbarBand`, public API alone: macOS has no public
///    progressive blur); at rest the band shows what it did. On a top-level destination (the sidebar's,
///    `destinationChrome`) the row sits on the band, level with the window's buttons (`toolbarBand`), the content
///    right under the band at rest, so no empty band shows above it, and the row draws the fade under its controls,
///    its own background clear; while the sidebar is hidden the window's buttons and the sidebar's toggle sit over the
///    band's leading end and the row starts past them. The row's empty parts there are the window's title bar
///    (`WindowDragArea`). On a pushed page (Settings' Addons) and before macOS 26 the row sits under the toolbar,
///    opaque.
extension View {
    /// `self` under the screen's header row: `filters` at its leading end, `actions` at its trailing end or in the bar
    /// (the rules above). `column` keeps the row to the readable column of a list under it (Addons); `titledActions`
    /// shows the actions' titles beside their icons in iPhone's row too (Downloads' Pause all and Resume all, which an
    /// icon alone doesn't tell apart); `scrolls` keeps the row to one line, its widest filter cut short to fit, on a
    /// phone scrolling sideways where even that doesn't (Libraries', Live TV's); `leadRoom` hears the room the first
    /// filter has on that line beside the others (`FittingRow`'s `onLeadRoom`: Library's name).
    func screenHeader(
        column: Bool = false,
        titledActions: Bool = false,
        scrolls: Bool = false,
        leadRoom: (@MainActor @Sendable (CGFloat) -> Void)? = nil,
        @ViewBuilder filters: () -> some View,
        @ViewBuilder actions: () -> some View
    ) -> some View {
        modifier(
            ScreenHeader(
                column: column,
                titledActions: titledActions,
                scrolls: scrolls,
                row: FittingRow(onLeadRoom: leadRoom, spacing: HeaderMetrics.spacing, wraps: HeaderMetrics.wraps && !scrolls) { filters() },
                actions: actions()
            )
        )
    }

    /// `self` under a header row of `filters` alone.
    func screenHeader(column: Bool = false, @ViewBuilder filters: () -> some View) -> some View {
        screenHeader(column: column, filters: filters, actions: { EmptyView() })
    }

    /// `self` under a header row that is `row` alone, laid out as it lays itself out (Search's field).
    func screenHeader(@ViewBuilder row: () -> some View) -> some View {
        modifier(ScreenHeader(column: false, titledActions: false, row: row(), actions: EmptyView()))
    }
}

/// Sizes of the header row and its glass controls.
enum HeaderMetrics {
    /// A Mac glass capsule's height, a compact toolbar's buttons'.
    static let controlHeight: CGFloat = 28
    /// A glass capsule's label from its rounded ends (`roundGlassLabel`).
    static let capsuleInset: CGFloat = 12
    /// Between the row's controls.
    static let spacing: CGFloat = 8
    /// Above and below a row off the toolbar's band.
    static let verticalPadding: CGFloat = 8
    #if os(iOS)
    /// The text of the row's glass controls, the filters' and the actions': with `controlInset` above and below a line
    /// of it, it sets their height.
    static let controlFont = Font.subheadline.weight(.medium)
    /// A glass capsule's padding above and below a line of `controlFont` (`roundGlassLabel`), at every text size (32 pt
    /// tall at the default size): an icon's glass circle takes it too, so it is as tall as the filters.
    static let controlInset: CGFloat = 7
    /// The row's controls go on more lines where they don't fit side by side whole: the row grows with them.
    static let wraps = true
    #endif
    #if os(macOS)
    /// Where the window's buttons and the sidebar's toggle end on the toolbar's band, from the window's leading edge,
    /// with a gap after them: a row on the band starts past it while the sidebar is hidden.
    static let bandButtonsEnd: CGFloat = 140
    /// The Mac's row on the toolbar's band is as tall as the band: the widest control is cut short instead.
    static let wraps = false
    #endif
}

/// The screen shows a header row: on the Mac's band, where the row draws the band's fade under its controls and the
/// screen draws none over it (`windowToolbarBand`; the bar naming a detail page draws it under itself too,
/// `titleBand`); on iOS, where the row's bar carries the soft edge (`softTopEdge`).
struct HeaderRowKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private struct ScreenHeader<Row: View, Actions: View>: ViewModifier {
    let column: Bool
    let titledActions: Bool
    var scrolls = false
    let row: Row
    let actions: Actions

    #if os(iOS)
    /// The screen's bar holds none of its items (`destinationBarEmpty`): the actions go in the row.
    @Environment(\.destinationBarEmpty) private var barEmpty
    /// The navigation bar's items go in iOS 27.1's vertical bar's column, with the tabs: the actions go there too.
    @Environment(\.verticalBarEdge) private var verticalBar
    /// Whether the screen's content is scrolled up under the row, where the screen tells it (Library's pager, whose
    /// pages scroll each on its own); nil where the row follows the content's scroll view.
    @Environment(\.drawnScrollEdge) private var drawnEdge
    /// The content is scrolled up under the row.
    @State private var scrolled = false
    #elseif os(macOS)
    @Environment(\.toolbarBand) private var band
    #endif

    func body(content: Content) -> some View {
        let hasActions = Actions.self != EmptyView.self
        let actionsInRow = hasActions && !actionsInBar
        let hasRow = Row.self != EmptyView.self || actionsInRow
        let headerRow = HeaderRow(
            column: column, titledActions: titledActions, scrolls: scrolls, row: row, actions: actionsInRow ? actions : nil
        )
        // The content as one view. A modifier on a screen's content goes into each of its views, into each branch of
        // a screen that switches between them (Search's hint, spinner and results), so a row laid over it was made anew
        // at each switch: Search's field lost the keyboard after the first letter typed (iOS 26.5 and 27.0).
        let screen = VStack(spacing: 0) { content }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        Group {
            #if os(iOS)
            if #available(iOS 26, *) {
                // The row is the screen's bar: the content scrolls up under it and fades there to the background
                // (`ScrollEdgeFade`), the one scroll edge of every screen with a row, the system's own hidden. No bar
                // without a row: an empty one takes the navigation bar's effect away.
                if hasRow {
                    screen
                        .scrollEdgeEffectHidden(true, for: .top)
                        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 0.5 } action: {
                            scrolled = $1
                        }
                        .safeAreaBar(edge: .top, spacing: 0) {
                            // Last in the accessibility order, after the content, where iOS 26 puts it: the accessibility
                            // hit test takes the last element under a point, and iOS 27 puts the bar first while the
                            // content's scroll view reaches up under it (Home's buttons and Discover's filters were not
                            // hittable there, though a tap reached them). Its glass stops taking touches while a
                            // menu is open (`OpenItemMenu`): a card's menu can open over the row.
                            headerRow
                                .environment(\.drawnScrollEdge, drawnEdge ?? scrolled)
                                .accessibilitySortPriority(-1)
                        }
                } else {
                    screen
                }
            } else {
                stacked(screen, row: hasRow ? headerRow : nil)
            }
            #else
            stacked(screen, row: hasRow ? headerRow : nil)
            #endif
        }
        .modifier(BarActions(actions: hasActions && actionsInBar ? actions : nil))
        #if os(macOS)
        // On the band: the row in the band, the content under it, faded where it scrolls up under the row's controls
        // (`windowToolbarBand`).
        .ignoresSafeArea(.container, edges: band != nil && hasRow ? .top : [])
        .preference(key: HeaderRowKey.self, value: band != nil && hasRow)
        #else
        .preference(key: HeaderRowKey.self, value: hasRow)
        #endif
    }

    /// The row above the content, which scrolls under it only where the row lies over it (the Mac's band).
    private func stacked<Screen: View, HeaderView: View>(_ screen: Screen, row: HeaderView?) -> some View {
        VStack(spacing: 0) {
            if let row {
                // Over the content, which the Mac draws up under the band as it scrolls: the row's controls stay on
                // top, seen and clicked.
                row.zIndex(1)
            }
            screen
        }
    }

    /// The screen shows a bar, which takes the actions: iOS's navigation bar (pushed iOS screens; iPad's destinations'
    /// is empty), and iOS 27.1's vertical bar's column on every screen where it shows (the iPhone Duo's), as toolbar
    /// items beside the tabs; the Mac's window toolbar over a pushed screen (macOS 26 and later). On the Mac's band (a
    /// top-level destination) the toolbar holds navigation alone, and the actions end the row there.
    private var actionsInBar: Bool {
        #if os(iOS)
        return !barEmpty || verticalBar != nil
        #else
        if #available(macOS 26, *) { return band == nil }
        return false
        #endif
    }
}

/// The screen's `actions` in the bar, at its trailing end: iOS's navigation bar; the Mac's window toolbar over a pushed
/// screen (macOS 26 and later), past a flexible space (its items line up at the leading end, after Back), titled.
private struct BarActions<Actions: View>: ViewModifier {
    let actions: Actions?

    func body(content: Content) -> some View {
        #if os(macOS)
        if let actions {
            if #available(macOS 26, *) {
                content.toolbar {
                    ToolbarSpacer(.flexible)
                    ToolbarItemGroup { actions.labelStyle(.titleAndIcon) }
                }
            } else {
                content
            }
        } else {
            content
        }
        #else
        content.toolbar {
            if let actions {
                ToolbarItemGroup(placement: .primaryAction) { actions }
            }
        }
        #endif
    }
}

/// The header row: `row` at its leading end, `actions` (where they aren't in the bar) at its trailing end. Clear where
/// the content fades under it (iOS 26 and later, where it is the screen's bar; the Mac's band); else opaque, so the
/// content scrolled up under it never shows through.
private struct HeaderRow<Row: View, Actions: View>: View {
    let column: Bool
    let titledActions: Bool
    let scrolls: Bool
    let row: Row
    let actions: Actions?

    @Environment(\.formFactor) private var formFactor
    #if os(macOS)
    @Environment(\.toolbarBand) private var band
    /// The row's leading edge in the window.
    @State private var windowX: CGFloat?
    /// The row's width, as laid out (`LineForms`).
    @State private var width: CGFloat?
    #endif

    var body: some View {
        // The sides where the line is: in its column, the column's.
        let line = ScreenSidesReader { sides in
            // A one-line row on iPad and the Mac gives way with its actions, whose titles go first (`HeaderRank`); a
            // phone's actions show their icons alone already, and its filters give way inside their strip.
            if scrolls && !scrolling {
                #if os(macOS)
                LineForms(width: width) { headerLine(sides) }
                #else
                HeaderForms(ranks: HeaderRank.lineForms) { headerLine(sides) }
                #endif
            } else {
                headerLine(sides)
            }
        }
        Group {
            if column { line.readableColumn() } else { line }
        }
        #if os(macOS)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .frame(height: band)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            if let band { BandFade(band: band) }
        }
        .background {
            if band != nil { WindowDragArea() }
        }
        .background(band == nil ? Palette.background : .clear)
        #else
        .background(fill)
        .background(alignment: .top) {
            if let drawnEdge {
                // Under the row, the lowest of its lines as measured, from the window's top.
                ScrollEdgeFade.under(rowFrame.maxY, shown: drawnEdge)
                    .offset(y: -rowFrame.minY)
            }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rowFrame = $0 }
        #endif
    }

    /// The filters and the actions on one line, the page's sides around it.
    private func headerLine(_ sides: ScreenSides) -> some View {
        HeaderLine(spacing: HeaderMetrics.spacing, padding: verticalPadding, actions: actions != nil, wraps: HeaderMetrics.wraps && !scrolling) {
            filters(leading: leadingInset(sides))
            if let actions { ActionGroup(titled: titledActions) { actions } }
        }
        .environment(\.compactFilters, formFactor == .compact && !scrolls)
        .padding(.leading, leadingInset(sides))
        .padding(.trailing, sides.trailing)
        #if os(macOS)
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minX } action: { windowX = $0 }
        #endif
    }

    #if os(iOS)
    /// The content is scrolled up under the row (`drawnScrollEdge`): the fade under it shows (iOS 26 and later).
    @Environment(\.drawnScrollEdge) private var drawnEdge
    /// The row's frame in the window.
    @State private var rowFrame = CGRect.zero

    /// None on iOS 26 and later, where the row is the screen's bar over the soft edge; before, the screen's black.
    private var fill: Color {
        if #available(iOS 26, *) { return .clear }
        return Palette.background
    }
    #endif

    /// Above and below the row's controls; none on the Mac's band, whose height is the row's.
    private var verticalPadding: CGFloat {
        #if os(macOS)
        band == nil ? HeaderMetrics.verticalPadding : 0
        #else
        HeaderMetrics.verticalPadding
        #endif
    }

    /// The row's filters scroll sideways (`scrolls`): on a phone.
    private var scrolling: Bool {
        scrolls && formFactor == .compact
    }

    /// The filters (Search's field): one row of glass. The actions stay out of it: on iOS a menu's entries over a group
    /// that holds a glass menu went to the group's glass (`glassGroup`). A row kept to one line (`scrolls`) gives way a
    /// step at a time, the first form that fits (`HeaderForms`): everything whole; then the actions' titles (the Mac's:
    /// Library's Shuffle, then its ⋯); then the filters ranked to give way (`symbolRank`: Library's sort, then its view,
    /// then its Filters and type) each showing its symbol alone, the named one (Library's library) keeping its symbol
    /// and name; then every filter with a symbol showing it alone (`compactFilters`), the widest left, Library's name,
    /// cut short (`FittingRow`). So the name is cut only once every other control is its symbol. On iPad and the Mac
    /// the whole line takes those forms (`body`); on a phone, whose actions show their icons alone, its filters do, in
    /// a line that scrolls sideways where even the last doesn't fit (`FilterStrip`).
    @ViewBuilder
    private func filters(leading: CGFloat) -> some View {
        let glass = row.glassGroup(spacing: HeaderMetrics.spacing)
        if scrolling {
            FilterStrip(leading: leading, padding: verticalPadding) { HeaderForms(ranks: HeaderRank.filterForms) { glass } }
        } else {
            glass
        }
    }

    /// The page's leading side (`sides`), and on the Mac's band while the sidebar is hidden (the row starting at the
    /// window's leading edge) whatever the window's buttons and the sidebar's toggle need.
    private func leadingInset(_ sides: ScreenSides) -> CGFloat {
        let side = sides.leading
        #if os(macOS)
        guard band != nil, let windowX else { return side }
        return max(side, HeaderMetrics.bandButtonsEnd - windowX)
        #else
        return side
        #endif
    }
}

#if os(macOS)
/// The band's fade under the row (`ScrollEdgeFade`), shown while the content is scrolled up under it: a view of its own,
/// so a scroll that shows or hides it makes nothing else of the row again, whose layout is the costliest of the screen.
private struct BandFade: View {
    let band: CGFloat

    @Environment(\.bandScrolled) private var scrolled

    var body: some View {
        ScrollEdgeFade.under(band, shown: scrolled)
    }
}
#endif

/// A phone's row of filters on one line (`header.filters`), from the page's leading edge, `leading` before the row,
/// their glass whole in the line's `padding` above and below. The row is given the strip's width, which its widest
/// filter's text gives way to (`FittingRow`: Library's name, the others showing their symbols alone); where it still
/// doesn't fit (a large text size) it scrolls sideways. It fades out over `fade` at an end where more of it lies past
/// that end: at the trailing end until it is scrolled to its last filter, at the leading end once it is scrolled from
/// its first, so it reads as scrolling and no filter is cut sharp. Beside iOS 27.1's vertical bar it ends at the safe
/// area (`clearOfVerticalBar`).
private struct FilterStrip<Content: View>: View {
    let leading: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: Content

    /// More of the strip lies past its ends.
    @State private var more = Ends()
    /// The strip's width, nil until measured.
    @State private var width: CGFloat?

    private let fade: CGFloat = 24

    var body: some View {
        ScrollView(.horizontal) {
            Proposing(width: width.map { max($0 - leading, 0) }) { content }
                .onGeometryChange(for: Ends.self) { proxy in
                    let frame = proxy.frame(in: .scrollView)
                    let width = proxy.bounds(of: .scrollView)?.width ?? frame.maxX
                    return Ends(leading: frame.minX < leading - 0.5, trailing: frame.maxX > width + 0.5)
                } action: { more = $0 }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.leading, leading, for: .scrollContent)
        .contentMargins(.vertical, padding, for: .scrollContent)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .mask {
            HStack(spacing: 0) {
                edge(shown: more.leading, from: .leading)
                Rectangle()
                edge(shown: more.trailing, from: .trailing)
            }
            .animation(.easeOut(duration: 0.2), value: more)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("header.filters")
        .clearOfVerticalBar()
        .padding(.leading, -leading)
        .padding(.vertical, -padding)
    }

    /// The mask's `fade` at one end: clear at the strip's `end` where `shown`, opaque inward; else opaque.
    private func edge(shown: Bool, from end: UnitPoint) -> some View {
        LinearGradient(
            colors: [.black.opacity(shown ? 0 : 1), .black],
            startPoint: end,
            endPoint: end == .leading ? .trailing : .leading
        )
        .frame(width: fade)
    }

    private struct Ends: Equatable {
        var leading = false
        var trailing = false
    }
}

/// Its one view proposed `width` across (where nil, what it is proposed itself), at the size the view takes, which may
/// be wider: a scroll view's content proposed the visible width.
private struct Proposing: Layout {
    let width: CGFloat?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(ProposedViewSize(width: width ?? proposal.width, height: proposal.height)) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(
            at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(width: width ?? bounds.width, height: bounds.height)
        )
    }
}

/// `content` in the first of its forms that fits the width it is given: at each of `ranks` (`symbolRank`), then with
/// every filter its symbol and every action its icon (`compactFilters`), the last whether it fits or not. Each choice
/// is between two forms: a ViewThatFits of three or more views hung an iPad in landscape for good as a library was
/// picked (the main thread laying the header out), where one of two never did. A ViewThatFits proposed no width
/// takes its first form, so each nested one is tried at its first form's width, and the outer one keeps the first form
/// that fits all the same.
private struct HeaderForms<Content: View>: View {
    let ranks: ArraySlice<Int>
    let content: Content

    init(ranks: [Int], @ViewBuilder content: () -> Content) {
        self.init(slice: ranks[...], content: content())
    }

    private init(slice: ArraySlice<Int>, content: Content) {
        ranks = slice
        self.content = content
    }

    var body: some View {
        if let rank = ranks.first {
            ViewThatFits(in: .horizontal) {
                content.environment(\.symbolRank, rank)
                HeaderForms(slice: ranks.dropFirst(), content: content)
            }
        } else {
            content
                .environment(\.symbolRank, Int.max)
                .environment(\.compactFilters, true)
        }
    }
}

#if os(macOS)
/// A one-line row's forms on the Mac (`HeaderForms` of `HeaderRank.lineForms`), where the row is mostly wide enough
/// for its first: that form alone while it fits whole, else every form in turn. Choosing among the forms
/// (`ViewThatFits`) makes each of them anew whenever the row changes (a library opening, its sorts arriving), 100 to
/// 300 ms of the Mac's main thread each time; the first form alone is only updated. The first form's own width is
/// measured while it shows (`FormFit`), and every form shows once that is more than the row's width, until the row is
/// that wide again: the choice never depends on which shows, so it settles at once. `width` is the row's frame as laid
/// out (`HeaderRow`'s), not a width it is placed in: SwiftUI places a view in other sizes too, to find its alignment
/// guides, and a choice made on those went back and forth for good. Not on iPad: there, measuring the row's width
/// left an iPad turned to landscape never finishing its animations for UI tests. Not hidden while the width is unknown
/// (its first frame, which a row too narrow for its first form shows cut short): the Mac's accessibility kept the
/// frames of the row's menus from then, or reported each menu twice.
private struct LineForms<Content: View>: View {
    let width: CGFloat?
    @ViewBuilder let content: Content

    /// The first form's own width, as last measured while it showed.
    @State private var need: CGFloat?

    var body: some View {
        let first = if let need, let width { need <= width + 0.5 } else { true }
        FormFit(measures: first, need: $need) {
            if first {
                content.environment(\.symbolRank, 0)
            } else {
                HeaderForms(ranks: HeaderRank.lineForms) { content }
            }
        }
    }
}

/// Its one view at the size it is given, and where it `measures`, the view's own width in `need` (after the update
/// under way: SwiftUI's state changes in the next one).
private struct FormFit: Layout {
    let measures: Bool
    let need: Binding<CGFloat?>

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(proposal) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let view = subviews.first else { return }
        if measures {
            let own = view.sizeThatFits(.unspecified).width
            if own != need.wrappedValue {
                let need = need
                Task { @MainActor in
                    if need.wrappedValue != own { need.wrappedValue = own }
                }
            }
        }
        view.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
    }
}
#endif

extension View {
    /// A header action whose title gives way at `rank` (`HeaderRank`) in a one-line row: from then on its icon alone.
    /// The Mac's alone, whose actions show their titles; elsewhere they show their icons alone already.
    @ViewBuilder
    func headerActionRank(_ rank: Int) -> some View {
        #if os(macOS)
        modifier(HeaderActionTitle(rank: rank))
        #else
        self
        #endif
    }
}

#if os(macOS)
private struct HeaderActionTitle: ViewModifier {
    let rank: Int

    @Environment(\.symbolRank) private var symbolRank

    @ViewBuilder
    func body(content: Content) -> some View {
        if rank <= symbolRank {
            content.labelStyle(.iconOnly)
        } else {
            content
        }
    }
}
#endif

/// The row's line: the row's own view (the first child) at the leading end in the width the actions leave, the
/// actions (the last child, where `actions`) at the trailing end at their own width, centred on one line, `padding`
/// above and below. Where the row `wraps` (iOS, `HeaderMetrics.wraps`, but a row that scrolls) and its view doesn't fit
/// beside the actions on one line, it goes on more lines there, the actions centred on its first, as long as every
/// control of it shows whole beside them (Library's view, type and sort beside the Calendar in a long language); else
/// it has the whole width and the actions go on a line of their own under it, `spacing` below, at the trailing end
/// (Downloads' titled actions beside its view menu at a large text size). No height at all while nothing in it has any
/// (Addons on iOS with one type, Install in the bar), so a row with nothing to show leaves no gap.
private struct HeaderLine: Layout {
    let spacing: CGFloat
    let padding: CGFloat
    let actions: Bool
    let wraps: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let (row, trailing) = split(subviews)
        let trailingSize = trailing?.sizeThatFits(.unspecified) ?? .zero
        let width: CGFloat
        if let proposed = proposal.width, proposed.isFinite {
            width = proposed
        } else {
            width = (row?.sizeThatFits(.unspecified).width ?? 0) + gap(trailingSize.width) + trailingSize.width
        }
        if let row, let trailing, under(row, trailingSize.width, in: width) {
            let rowHeight = row.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
            let trailingHeight = trailing.sizeThatFits(ProposedViewSize(width: min(trailingSize.width, width), height: nil)).height
            return CGSize(width: width, height: rowHeight + spacing + trailingHeight + 2 * padding)
        }
        let rowHeight = row?.sizeThatFits(ProposedViewSize(width: rowWidth(width, trailingSize.width), height: nil)).height ?? 0
        let height = max(rowHeight, trailingSize.height)
        return CGSize(width: width, height: height > 0 ? height + 2 * padding : 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let (row, trailing) = split(subviews)
        let trailingSize = trailing?.sizeThatFits(.unspecified) ?? .zero
        if let row, let trailing, under(row, trailingSize.width, in: bounds.width) {
            let rowProposal = ProposedViewSize(width: bounds.width, height: nil)
            row.place(at: CGPoint(x: bounds.minX, y: bounds.minY + padding), anchor: .topLeading, proposal: rowProposal)
            trailing.place(
                at: CGPoint(x: bounds.maxX, y: bounds.minY + padding + row.sizeThatFits(rowProposal).height + spacing),
                anchor: .topTrailing,
                proposal: ProposedViewSize(width: min(trailingSize.width, bounds.width), height: nil)
            )
            return
        }
        let rowProposal = ProposedViewSize(width: rowWidth(bounds.width, trailingSize.width), height: nil)
        // The row's first line: its tallest control on one line, or the actions where they are taller.
        let rowHeight = row?.sizeThatFits(rowProposal).height ?? 0
        let firstLine = max(min(rowHeight, row?.sizeThatFits(.unspecified).height ?? 0), trailingSize.height)
        trailing?.place(
            at: CGPoint(x: bounds.maxX, y: bounds.minY + padding + firstLine / 2),
            anchor: .trailing,
            proposal: ProposedViewSize(trailingSize)
        )
        row?.place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: rowProposal)
    }

    /// The row's view and the actions' (the last child, where there are actions).
    private func split(_ subviews: Subviews) -> (row: LayoutSubview?, actions: LayoutSubview?) {
        guard actions, let last = subviews.last else { return (subviews.first, nil) }
        return (subviews.count > 1 ? subviews.first : nil, last)
    }

    /// The gap before actions `width` wide: none while they show nothing.
    private func gap(_ width: CGFloat) -> CGFloat {
        width > 0 ? spacing : 0
    }

    private func rowWidth(_ width: CGFloat, _ actionsWidth: CGFloat) -> CGFloat {
        max(width - actionsWidth - gap(actionsWidth), 0)
    }

    /// The actions, `actionsWidth` wide, go under `row` in a line `width` wide: where the row wraps and its view,
    /// showing something, neither fits beside them on one line nor shows every control whole there on more lines. A
    /// wrapping row is as wide as the width it is given only where it cuts a control short to that width; one whose
    /// line just fills it goes under too, which shows it whole all the same.
    private func under(_ row: LayoutSubview, _ actionsWidth: CGFloat, in width: CGFloat) -> Bool {
        guard wraps, actionsWidth > 0 else { return false }
        let own = row.sizeThatFits(.unspecified).width
        guard own > 0, own + spacing + actionsWidth > width else { return false }
        let beside = rowWidth(width, actionsWidth)
        return row.sizeThatFits(ProposedViewSize(width: beside, height: nil)).width >= beside - 0.5
    }
}

/// The actions at the row's trailing end. On iPhone each is glass as tall as the filters, in their font
/// (`ActionLabelStyle`): an icon alone a circle, an icon with its title a capsule as the filters are
/// (`roundGlassLabel`); on more lines where they don't fit side by side (`FittingRow`). On the Mac they share one
/// glass capsule, as a bar groups its buttons, each its icon and title. No glass at all while none shows (Downloads
/// with nothing to pause or resume).
private struct ActionGroup<Content: View>: View {
    let titled: Bool
    @ViewBuilder let content: Content

    var body: some View {
        #if os(macOS)
        // With each label's half inset, the capsule's ends get a whole one.
        CapsuleRow(ends: HeaderMetrics.capsuleInset / 2) { content }
            .labelStyle(.titleAndIcon)
            .buttonStyle(TitledActionStyle())
            .glassCapsule()
        #else
        // Each label draws its own glass.
        FittingRow(spacing: HeaderMetrics.spacing, wraps: HeaderMetrics.wraps) { content }
            .labelStyle(ActionLabelStyle(titled: titled))
            .font(HeaderMetrics.controlFont)
            .buttonStyle(.plain)
        #endif
    }
}

#if os(macOS)
/// Its children side by side at their own sizes, centred on one line, `ends` before the first and after the last; no
/// size at all without children.
private struct CapsuleRow: Layout {
    let ends: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return CGSize(width: sizes.map(\.width).reduce(0, +) + 2 * ends, height: sizes.map(\.height).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX + ends
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            subview.place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(size))
            x += size.width
        }
    }
}

/// An action in the Mac's capsule: its icon and title in the toolbar's font, half a capsule's inset each side.
private struct TitledActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glassCapsuleLabel(ends: [])
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension EnvironmentValues {
    /// The toolbar's band (its height) over a top-level destination's screen, whose header row sits on it
    /// (`destinationChrome`, macOS 26 and later); nil on a pushed screen.
    @Entry var toolbarBand: CGFloat?
    /// The screen's content is scrolled up under the toolbar's band, which fades it (`windowToolbarBand`).
    @Entry var bandScrolled = false
}
#else
/// An action's label in iPhone's row: where `titled` its icon and title in a glass capsule as a filter's
/// (`roundGlassLabel`), else its icon alone in a glass circle as tall as a filter's capsule: a line of the label's
/// text, unseen, with the capsule's padding above and below (`controlInset`), as wide as that is tall. An icon alone
/// without the text came out shorter than the filters (a pencil 29 pt against their 32, iOS 26.5 and 27.0), and in the
/// glass button style's capsule wider than tall (43 by 32 pt), which cut Library's view menu short beside the Calendar
/// on a 402 pt wide iPhone.
private struct ActionLabelStyle: LabelStyle {
    let titled: Bool

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if titled {
            Label(configuration).labelStyle(.titleAndIcon).lineLimit(1)
                .roundGlassLabel(.capsule)
                .glassCapsule()
        } else {
            Square {
                ZStack {
                    Text(verbatim: " ").hidden()
                    configuration.icon
                }
                .padding(.vertical, HeaderMetrics.controlInset)
            }
            .contentShape(Circle())
            .glassCircle()
        }
    }
}

/// Its one view centred in a square as wide as the view is tall, or as tall as it is wide where it is wider.
private struct Square: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = subviews.first?.sizeThatFits(.unspecified) ?? .zero
        let side = max(size.width, size.height)
        return CGSize(width: side, height: side)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: .unspecified)
    }
}

extension EnvironmentValues {
    /// The content is scrolled up under the header row, whose fade (`ScrollEdgeFade`) shows while true. Set by a screen
    /// whose pages scroll each on their own (Library's paged tabs, `LibrariesScreen.tabs`), for its shown page; nil
    /// elsewhere, where the row follows the content's scroll view itself.
    @Entry var drawnScrollEdge: Bool? = nil
}
#endif
#endif
