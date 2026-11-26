import SwiftUI
import PlezyKit

#if !os(tvOS)
/// The room a header row's layout reports for its first filter (`screenHeader`'s `leadRoom`), observed by the screen.
@MainActor @Observable
final class HeaderRoom {
    var width: CGFloat?
}
#endif

/// Libraries' views, the view menu's options (`LibraryViewMenu`): the selected library's tabs; `selected` is the one
/// shown, `onSelect` shows another.
struct LibraryViews {
    let labels: [String]
    let selected: Int
    let onSelect: (Int) -> Void
}

/// Libraries' view menu: a filter capsule naming the library's tab shown, listing them all (`libraries.view`, its
/// options `libraries.view.option.<i>`); where the header row gives way, its symbol alone (`HeaderRank.view`): one
/// symbol whatever the tab. Not drawn while there is only one tab.
struct LibraryViewMenu: View {
    let views: LibraryViews

    @Environment(\.compactFilters) private var compact
    @Environment(\.symbolRank) private var symbolRank

    var body: some View {
        if views.labels.count > 1 {
            let shown = min(views.selected, views.labels.count - 1)
            FilterMenu(
                chip: FilterChip(name: T.shared.libraries.title, text: views.labels[shown]),
                symbol: compact || symbolRank >= HeaderRank.view ? "rectangle.3.group" : nil,
                options: views.labels.enumerated().map { FilterOption(label: $0.element, selected: $0.offset == views.selected) },
                rank: HeaderRank.view,
                id: "libraries.view",
                onSelect: views.onSelect
            )
        }
    }
}

/// Libraries: the screen's header row (`screenHeader`; tvOS: `FilterRow`) of filters, the library (named, its libraries
/// each with its server's name where they come from several; on the Mac its name alone, the sidebar picking the
/// library), the view (the library's tabs: `LibraryViewMenu`) and on Browse its sort, filters and
/// grouping, on one line (`scrolls`), where the other filters give way to their symbols before the library's name does:
/// first the Mac's Shuffle and ⋯ show their icons alone, then the sort its symbol, then the view, then Filters and the
/// type (`HeaderRank`), and only then is the name cut short; at its trailing end Shuffle and the ⋯ menu's Manage
/// libraries and Refresh (tvOS: a button each), on a phone Shuffle the ⋯ menu's first entry instead where the row would
/// leave the library's name fewer than its first twelve characters (`shuffleInMenu`).
/// Under it the selected tab,
/// each tab once shown kept mounted (its scroll and focus survive a visit to another), which iPhone and iPad swipe
/// between. A controller's shoulder buttons step the tabs, focus on the view menu, whose tab then takes no first focus
/// (`tabBarHoldsFocus`).
///
/// Accessibility identifiers: `libraries.screen`, `libraries.library`, `libraries.view`, `libraries.grouping`,
/// `libraries.sort` (each with `.option.<i>`), `libraries.filters`, `libraries.shuffle`, `libraries.more`,
/// `libraries.manage`, `libraries.refresh`; the tabs' content `libraries.recommended`, `libraries.grid`,
/// `libraries.folders`, each a container of its own.
struct LibrariesScreen: View {
    let app: AppModel
    let model: StoreModel<LibrariesScreenStore, LibrariesUiState>

    /// The tabs shown since the library was picked, kept mounted.
    @State private var mounted: Set<LibraryTab> = []
    @State private var filtering = false
    /// Browse's state while Browse shows, for its filters in the header row.
    @State private var browseState: StoreObserver<BrowseUiState>?
    #if os(iOS)
    /// The page the tabs' pager rests on (iPhone, iPad), following the selected tab and selecting the one swiped to.
    @State private var page: LibraryTab?
    /// The pages whose content is scrolled up under the top of the screen, each by its own (`tabs`).
    @State private var scrolledTabs: Set<LibraryTab> = []
    /// The safe area at the pager's sides, which its pages take inside them (`tabs`).
    @State private var pageSides = EdgeInsets()
    #endif
    #if !os(tvOS)
    /// On a phone what the row gives up to the ⋯ menu, the first of `overflowOrder`, the row's first entries there:
    /// Shuffle, then the sort (a long name beside the picker's symbol, Codec Samples; a large text size), the view,
    /// Filters and the type, one at a time, each where the row left the library's name fewer than its first twelve
    /// characters (`placeOverflow`). iPad's and the Mac's rows show the other filters' symbols alone first
    /// (`screenHeader`); there the row reported the picker's own width as its room, which kept Shuffle in the menu with
    /// the row's room to spare.
    @State private var overflow = 0
    @Environment(\.formFactor) private var formFactor
    /// The header row's room for the library picker beside the other filters, as the row reports it (`leadRoom`).
    @State private var nameRoom = HeaderRoom()
    /// The library picker's size showing the first twelve characters of the library's name (all of a shorter one),
    /// without its symbol.
    @State private var nameNeed = CGSize.zero
    #endif
    /// The tab a controller's shoulder button changed to, focus on the view menu: its content takes no first focus.
    @State private var shoulderTab: LibraryTab?
    @FocusState private var viewMenuFocused: Bool

    var body: some View {
        let state = model.state.state
        Group {
            #if os(tvOS)
            VStack(alignment: .leading, spacing: 0) {
                // The actions as an action row's circles: each symbol in the row's square, so they are one size
                // whatever each symbol's shape.
                FilterRow { filters(state) } trailing: { tvActions(state).environment(\.actionRow, true) }
                content(state)
                    .environment(\.tabBarHoldsFocus, shoulderTab != nil && shoulderTab == state.tab)
            }
            #else
            content(state)
                .environment(\.tabBarHoldsFocus, shoulderTab != nil && shoulderTab == state.tab)
                .screenHeader(
                    scrolls: true,
                    leadRoom: formFactor == .compact && state.selected != nil && state.load == .content ? reportNameRoom() : nil,
                    filters: { filters(state) },
                    actions: { actions(state) }
                )
                #if os(iOS)
                // The header row draws the scroll edge the system can't give the pager's pages (`tabs`).
                .environment(\.drawnScrollEdge, scrolledTabs.contains(state.tab))
                #endif
                .onChange(of: nameRoom.width) { placeOverflow() }
                .onChange(of: nameNeed) { placeOverflow() }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("libraries.screen")
        // Only while Libraries is the top screen, not under one pushed over it (the Mac's Manage libraries).
        .gamepadTabs(
            enabled: state.load == .content && state.selected != nil && app.backStack.last is RouteLibraries,
            tabs: { model.state.state.tabs },
            selected: { model.state.state.tab }
        ) { tab in
            shoulderTab = tab
            model.store.selectTab(tab: tab)
            viewMenuFocused = true
        }
        #if os(iOS)
        .appSheet(isPresented: $filtering) {
            if let browse = model.store.browse() {
                LibraryFiltersSheet(browse: browse) { filtering = false }
            }
        }
        #endif
        .onChange(of: state.selected?.globalKey, initial: true) {
            mounted = [state.tab]
            #if os(iOS)
            // The pager is made anew, each page at its top.
            scrolledTabs = []
            #endif
        }
        .onChange(of: state.tab) { _, tab in mounted.insert(tab) }
        .task(id: state.load == .content && state.tab == .browse ? state.selected?.globalKey : nil) {
            guard state.load == .content, state.tab == .browse, let browse = model.store.browse() else {
                browseState = nil
                return
            }
            let observer = StoreObserver(browse.state)
            browseState = observer
            await observer.observe()
        }
    }

    /// The view menu's options: the library's tabs while one shows. The menu comes with the library's
    /// name and content, the row filling at once, so it holds no place while they load.
    private func views(_ state: LibrariesUiState) -> LibraryViews {
        let tabs = state.load == .content && state.selected != nil ? state.tabs : []
        return LibraryViews(labels: tabs.map(\.label), selected: tabs.firstIndex(of: state.tab) ?? 0) { index in
            model.store.selectTab(tab: tabs[index])
        }
    }

    @ViewBuilder
    private func filters(_ state: LibrariesUiState) -> some View {
        #if os(tvOS)
        if let selected = state.selected, state.load == .content {
            libraryMenu(state, selected: selected)
        }
        LibraryViewMenu(views: views(state))
            .focused($viewMenuFocused)
        if state.load == .content, state.tab == .browse, let browse = model.store.browse(), let browseState {
            BrowseFilters(browse: browse, observer: browseState, filtering: $filtering)
        }
        #else
        let moved = overflowed(state)
        Group {
            if let selected = state.selected, state.load == .content {
                #if os(macOS)
                libraryTitle(selected)
                #else
                libraryMenu(state, selected: selected)
                #endif
            }
            if !moved.contains(.view) {
                LibraryViewMenu(views: views(state))
                    .focused($viewMenuFocused)
            }
            if state.load == .content, state.tab == .browse, let browse = model.store.browse(), let browseState {
                BrowseFilters(browse: browse, observer: browseState, filtering: $filtering, moved: moved)
            }
        }
        // With a filter in the ⋯ menu every other one shows its symbol: else the row could show a label again in the
        // room the moved one freed, and give it back.
        .transformEnvironment(\.compactFilters) { if moved.count > 1 { $0 = true } }
        #endif
    }

    #if os(macOS)
    /// The Mac's library, named at the row's start: its sidebar lists the libraries and picks one, so the row has no
    /// picker of its own.
    private func libraryTitle(_ selected: MediaLibrary) -> some View {
        Text(selected.title)
            .font(.title3.weight(.semibold))
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("libraries.library")
    }
    #else
    /// The library picker, named in the row (`named`): the visible libraries in order, under their servers' names where
    /// the list groups them by server (`state.entries`' headers), else each with its server's name where they come from
    /// several. Its symbol shows while every filter of the row shows whole, the first thing the row gives up
    /// (`FilterMenu.named`); its name is the last.
    private func libraryMenu(_ state: LibrariesUiState, selected: MediaLibrary) -> some View {
        var rows: [LibraryListEntryRow] = []
        var options: [FilterOption] = []
        var heading: String?
        for entry in state.entries {
            if let header = entry as? LibraryListEntryHeader {
                heading = header.serverName
            } else if let row = entry.libraryRow {
                rows.append(row)
                options.append(FilterOption(
                    label: row.library.title, detail: row.showServerName ? row.library.serverName : nil,
                    selected: row.library.globalKey == selected.globalKey, heading: heading
                ))
                heading = nil
            }
        }
        let menu = FilterMenu(
            chip: FilterChip(name: T.shared.libraries.selectLibrary, text: selected.title, spoken: selected.title),
            symbol: selected.kind.librarySymbol,
            options: options,
            named: true,
            id: "libraries.library"
        ) { model.store.selectLibrary(globalKey: rows[$0].library.globalKey) }
        #if os(tvOS)
        return menu
        #else
        // The picker as it shows the name's first twelve characters, unseen, measured.
        return menu.background {
            FilterCapsule(text: String(selected.title.prefix(12)), symbol: selected.kind.librarySymbol, compact: true, named: true)
                .roundGlassLabel(.capsule)
                .fixedSize()
                .hidden()
                .accessibilityHidden(true)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { nameNeed = $0 }
        }
        #endif
    }
    #endif

    #if !os(tvOS)
    /// Keeps the header row's room for the library picker beside the other filters (`leadRoom`) in `nameRoom`, a
    /// reference the row's layout writes to after it lays out (a copy of a `State` taken in `body` kept nothing).
    private func reportNameRoom() -> @MainActor @Sendable (CGFloat) -> Void {
        let nameRoom = nameRoom
        return { room in
            if nameRoom.width != room { nameRoom.width = room }
        }
    }

    /// What the row gives up to the ⋯ menu, in order, of what it shows: Shuffle, the sort, the view, Filters, the type.
    private func overflowOrder(_ state: LibrariesUiState) -> [HeaderOverflow] {
        let browse = state.load == .content && state.tab == .browse ? browseState?.state : nil
        var order: [HeaderOverflow] = []
        if state.canShuffle { order.append(.shuffle) }
        if browse?.showsSort == true { order.append(.sort) }
        if views(state).labels.count > 1 { order.append(.view) }
        if browse?.showsFilters == true { order.append(.filters) }
        if (browse?.groupings.count ?? 0) > 1 { order.append(.type) }
        return order
    }

    /// What is in the ⋯ menu now: on a phone, the first `overflow` of `overflowOrder`.
    private func overflowed(_ state: LibrariesUiState) -> [HeaderOverflow] {
        formFactor == .compact ? Array(overflowOrder(state).prefix(overflow)) : []
    }

    /// One more of the row goes into the ⋯ menu where the row's room for the library picker (`nameRoom`) is less than it
    /// needs to show the name's first twelve characters (`nameNeed`); the last one moved comes back once the row has
    /// that room beside it, a circle as tall as the picker (every one is by then), and the row's spacing.
    private func placeOverflow() {
        guard let room = nameRoom.width, nameNeed.width > 0 else { return }
        if room < nameNeed.width, overflow < overflowOrder(model.state.state).count {
            overflow += 1
        } else if overflow > 0, room - nameNeed.height - HeaderMetrics.spacing >= nameNeed.width {
            overflow -= 1
        }
    }

    /// Shuffle, then the ⋯ menu: what the row has no room for (`overflowed`, each as the row's control would: a filter
    /// a menu of its options, Filters the sheet), Manage libraries, Refresh.
    @ViewBuilder
    private func actions(_ state: LibrariesUiState) -> some View {
        let moved = overflowed(state)
        if state.canShuffle && !moved.contains(.shuffle) {
            Button { model.store.shuffle() } label: {
                Label(T.shared.libraries.shuffleLibrary, systemImage: "shuffle")
            }
            .headerActionRank(HeaderRank.shuffle)
            .accessibilityLabel(T.shared.libraries.shuffleLibrary)
            .accessibilityIdentifier("libraries.shuffle")
        }
        Menu {
            ForEach(moved, id: \.self) { item in
                overflowEntry(item, state)
            }
            if !state.libraries.isEmpty {
                Button(action: manage) { Label(T.shared.libraries.manageLibraries, systemImage: "pencil") }
                    .accessibilityIdentifier("libraries.manage")
            }
            Button { model.store.refresh() } label: { Label(T.shared.common.refresh, systemImage: "arrow.clockwise") }
                .accessibilityIdentifier("libraries.refresh")
        } label: {
            Label(T.shared.common.options, systemImage: "ellipsis")
                .headerActionRank(HeaderRank.more)
        }
        .menuIndicator(.hidden)
        .accessibilityLabel(T.shared.common.options)
        .accessibilityIdentifier("libraries.more")
    }

    /// The ⋯ menu's entry for `item`, under the row control's identifier and read as it.
    @ViewBuilder
    private func overflowEntry(_ item: HeaderOverflow, _ state: LibrariesUiState) -> some View {
        let browse = model.store.browse()
        let choices = browse.flatMap { browse in browseState.map { BrowseChoices(browse: browse, state: $0.state) } }
        switch item {
        case .shuffle:
            Button { model.store.shuffle() } label: { Label(T.shared.libraries.shuffleLibrary, systemImage: "shuffle") }
                .accessibilityIdentifier("libraries.shuffle")
        case .view:
            let views = views(state)
            let shown = min(views.selected, views.labels.count - 1)
            Menu {
                FilterMenuOptions(
                    options: views.labels.enumerated().map { FilterOption(label: $0.element, selected: $0.offset == views.selected) },
                    id: "libraries.view",
                    onSelect: views.onSelect
                )
            } label: {
                Label(FilterChip(name: T.shared.libraries.title, text: views.labels[shown]).spoken, systemImage: "rectangle.3.group")
            }
            .accessibilityIdentifier("libraries.view")
        case .sort:
            if let choices {
                Menu {
                    FilterMenuOptions(options: choices.sortOptions, id: "libraries.sort", onSelect: choices.pickSort)
                } label: {
                    Label(choices.sortChip.spoken, systemImage: choices.sortSymbol)
                }
                .accessibilityIdentifier("libraries.sort")
            }
        case .filters:
            if let choices {
                Button { filtering = true } label: { Label(choices.filtersChip.spoken, systemImage: BrowseChoices.filtersSymbol) }
                    .accessibilityIdentifier("libraries.filters")
            }
        case .type:
            if let choices {
                Menu {
                    FilterMenuOptions(options: choices.typeOptions, id: "libraries.grouping", onSelect: choices.pickType)
                } label: {
                    Label(choices.typeChip.spoken, systemImage: BrowseChoices.typeSymbol)
                }
                .accessibilityIdentifier("libraries.grouping")
            }
        }
    }
    #else
    /// Apple TV's actions, a button each.
    @ViewBuilder
    private func tvActions(_ state: LibrariesUiState) -> some View {
        if state.canShuffle {
            IconButton(systemImage: "shuffle", label: T.shared.libraries.shuffleLibrary, id: "libraries.shuffle") { model.store.shuffle() }
        }
        if !state.libraries.isEmpty {
            IconButton(systemImage: "pencil", label: T.shared.libraries.manageLibraries, id: "libraries.manage", action: manage)
        }
        IconButton(systemImage: "arrow.clockwise", label: T.shared.common.refresh, id: "libraries.refresh") { model.store.refresh() }
    }
    #endif

    /// Manage libraries, its settings page.
    private func manage() {
        app.navigator.navigate(route: RouteSettingsPage(page: .manageLibraries, arg: nil))
    }

    @ViewBuilder
    private func content(_ state: LibrariesUiState) -> some View {
        switch state.load {
        case .loading:
            LoadingStateView().accessibilityIdentifier("libraries.loading")
        case .error:
            ErrorStateView(message: state.error ?? T.shared.errors.unableToLoad(context: T.shared.libraries.title)) { model.store.refresh() }
        case .noLibraries:
            EmptyStateView(message: T.shared.libraries.noLibrariesFound, systemImage: "play.rectangle.on.rectangle")
        case .allHidden:
            EmptyStateView(message: T.shared.libraries.allLibrariesHidden, systemImage: "eye.slash") {
                Button(T.shared.libraries.manageLibraries, action: manage)
                    .buttonProminence(.primary)
            }
        default:
            if let key = state.selected?.globalKey {
                tabs(state).id(key)
            }
        }
    }

    /// The library's tabs: on iPhone and iPad pages side by side that a swipe moves between (a paging scroll view, which,
    /// unlike a paging tab view, never recycles a page: each keeps its scroll position, and leaves a shelf's own swipe
    /// to the shelf), elsewhere stacked with the selected one on top; each tab shown since the library was picked stays
    /// mounted, the others are drawn empty until shown. The header row draws the scroll edge (`drawnScrollEdge`) while
    /// the shown page's own content is scrolled up under the top of the screen (`scrolledTabs`): on iOS 26 and later
    /// the system gives its soft edge to the outermost scroll view under the bars, the pager, which never scrolls up or
    /// down and so never shows it, and never to a page's own (iOS 27.0: neither the pager's edge shown nor a bar of a
    /// page's own drew it); without, posters ran sharp under the status bar and the header row. The pager keeps its
    /// offset in points as its width changes (turned, iPad's sidebar shown or hidden, also under a pushed screen), which
    /// would show the page shifted by the change: it scrolls back to its page. Its pages span its whole width,
    /// the safe area at its sides inside each page, so a page's leading edge is the pager's (with the safe area as the
    /// scroll view's insets, a scroll to a page with insets at both sides stops short of them).
    @ViewBuilder
    private func tabs(_ state: LibrariesUiState) -> some View {
        #if os(iOS)
        ScrollViewReader { scroller in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(state.tabs, id: \.self) { tab in
                        tabPage(tab, active: tab == state.tab)
                            .safeAreaPadding(EdgeInsets(top: 0, leading: pageSides.leading, bottom: 0, trailing: pageSides.trailing))
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { _ in
                    scroller.scrollTo(model.state.state.tab, anchor: .leading)
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.container, edges: .horizontal)
            .onGeometryChange(for: EdgeInsets.self) { $0.safeAreaInsets } action: { pageSides = $0 }
            .initialPage(state.tabs.firstIndex(of: state.tab) ?? 0, of: state.tabs.count)
            .scrollPosition(id: $page)
            .onChange(of: state.tab, initial: true) { _, tab in
                if page != tab { page = tab }
            }
            .onChange(of: page) { _, tab in
                if let tab, tab != model.state.state.tab { model.store.selectTab(tab: tab) }
            }
        }
        #else
        ZStack {
            ForEach(state.tabs, id: \.self) { tab in
                tabPage(tab, active: tab == state.tab)
            }
        }
        #endif
    }

    @ViewBuilder
    private func tabPage(_ tab: LibraryTab, active: Bool) -> some View {
        Group {
            if mounted.contains(tab) || active {
                LibraryTabContent(app: app, store: model.store, tab: tab)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.libraryTabActive, active)
        #if os(iOS)
        .onScrolledUnderTop { scrolled in
            if scrolled { scrolledTabs.insert(tab) } else { scrolledTabs.remove(tab) }
        }
        #endif
        #if !os(iOS)
        // Out of sight, out of reach: no focus or clicks for a tab under the shown one.
        .opacity(active ? 1 : 0)
        .allowsHitTesting(active)
        .disabled(!active)
        #endif
        // VoiceOver reads the tab shown alone.
        .accessibilityHidden(!active)
    }
}

#if os(iOS)
private extension View {
    /// A paging scroll view of `count` pages opens on page `index`: a fresh library's tab is Browse, not the first page,
    /// and the position set as the pager first shows doesn't scroll it before its pages are laid out.
    @ViewBuilder
    func initialPage(_ index: Int, of count: Int) -> some View {
        let anchor = UnitPoint(x: count > 1 ? CGFloat(index) / CGFloat(count - 1) : 0, y: 0.5)
        if #available(iOS 18, *) {
            defaultScrollAnchor(anchor, for: .initialOffset)
        } else {
            defaultScrollAnchor(anchor)
        }
    }

    /// `action` with whether this page's own content is scrolled up under the top of the screen, as that changes (iOS
    /// 26 and later, where the pager draws the scroll edge for it).
    @ViewBuilder
    func onScrolledUnderTop(_ action: @escaping (Bool) -> Void) -> some View {
        if #available(iOS 26, *) {
            onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 0.5 } action: { action($1) }
        } else {
            self
        }
    }
}
#endif

extension EnvironmentValues {
    /// The Libraries tab shown (its siblings stay mounted out of sight): only it claims focus.
    @Entry var libraryTabActive = true
    /// A controller's shoulder button changed Libraries to this tab and put focus on the view menu: the tab's content
    /// takes no first focus.
    @Entry var tabBarHoldsFocus = false
    /// The times the Libraries tab was picked again while it showed (`LibrariesDestination`): each brings the shown
    /// tab's or the downloads' scroll views back to their tops (`scrollsBackToTop`).
    @Entry var scrollToTopRequests = 0
}

extension View {
    /// A scroll view's content that goes back to its top each time `scrollToTopRequests` counts, while its Libraries tab
    /// shows: a mark above the content, scrolled to.
    func scrollsBackToTop() -> some View { modifier(ScrollsBackToTop()) }
}

private struct ScrollsBackToTop: ViewModifier {
    @Environment(\.scrollToTopRequests) private var requests
    @Environment(\.libraryTabActive) private var active

    func body(content: Content) -> some View {
        ScrollViewReader { scroller in
            VStack(alignment: .leading, spacing: 0) {
                Color.clear.frame(height: 0).id(Self.top)
                content
            }
            .onChange(of: requests) {
                if active { withAnimation { scroller.scrollTo(Self.top, anchor: .top) } }
            }
        }
    }

    private static let top = "scrollsBackToTop.top"
}

extension MediaKind {
    /// A library's kind icon: in the sidebar, on Home's chips and in Libraries' picker.
    var librarySymbol: String {
        switch self {
        case .show: "tv"
        case .artist: "music.note"
        case .photo: "photo.on.rectangle"
        default: "film"
        }
    }
}

/// Browse's filters in the header row, read from Browse's state here rather than by the screen: the grid's pages arriving
/// change that state, and the row, whose layout is the screen's costliest, is made again only where what the filters
/// show changed (`BrowseFilterControls`, compared by its `==`). Not `.equatable()`: that makes the controls one view,
/// which the row stacked one above the other.
private struct BrowseFilters: View {
    let browse: LibraryBrowseStore
    let observer: StoreObserver<BrowseUiState>
    @Binding var filtering: Bool
    var moved: [HeaderOverflow] = []

    var body: some View {
        BrowseFilterControls(browse: browse, state: observer.state, filtering: $filtering, moved: moved)
    }
}

/// Browse's filters: the sort, its options Clear (while a sort is picked), Ascending and Descending
/// for the field shown (the direction in effect checked), then under Sort By the fields (the one shown checked; another
/// keeps the direction, or from the unsorted state takes its own), on iPhone and iPad in a popover (`SortOptionsList`);
/// Filters, its count while any is set, which
/// opens the editor (`filtering`): on the Mac in a popover under it (`LibraryFiltersSheet`), on iPhone and iPad in the
/// screen's sheet; on Apple TV it is the filters' menu (`LibraryFiltersMenu`); and last the type (the grouping), its
/// symbol alone, the same whatever the type and none of the library's or the view's, VoiceOver reading its name and pick.
private struct BrowseFilterControls: View {
    let browse: LibraryBrowseStore
    let state: BrowseUiState
    @Binding var filtering: Bool
    /// The filters the row gave up to its ⋯ menu (a phone's at a large text size), not drawn here.
    var moved: [HeaderOverflow] = []

    #if os(iOS)
    @State private var sorting = false
    #endif

    var body: some View {
        let choices = BrowseChoices(browse: browse, state: state)
        if state.showsSort && !moved.contains(.sort) {
            #if os(iOS)
            FilterButton(chip: choices.sortChip, symbol: choices.sortSymbol, fills: false, rank: HeaderRank.sort, id: "libraries.sort") { sorting = true }
                .popover(isPresented: $sorting) {
                    SortOptionsList(options: choices.sortOptions, id: "libraries.sort") { index in
                        sorting = false
                        choices.pickSort(index)
                    }
                }
            #else
            FilterMenu(chip: choices.sortChip, symbol: choices.sortSymbol, options: choices.sortOptions, rank: HeaderRank.sort, id: "libraries.sort", onSelect: choices.pickSort)
            #endif
        }
        if state.showsFilters && !moved.contains(.filters) {
            #if os(tvOS)
            LibraryFiltersMenu(browse: browse, state: state)
            #else
            FilterButton(chip: choices.filtersChip, symbol: BrowseChoices.filtersSymbol, rank: HeaderRank.filters, id: "libraries.filters") { filtering = true }
            #if os(macOS)
            .popover(isPresented: $filtering, arrowEdge: .bottom) {
                LibraryFiltersSheet(browse: browse) { filtering = false }
            }
            #endif
            #endif
        }
        if state.groupings.count > 1 && !moved.contains(.type) {
            FilterMenu(
                chip: choices.typeChip,
                symbol: BrowseChoices.typeSymbol,
                options: choices.typeOptions,
                symbolOnly: true,
                rank: HeaderRank.filters,
                id: "libraries.grouping",
                onSelect: choices.pickType
            )
        }
    }
}

/// SwiftUI compares views on the main actor, where the store lives. Equal while what the controls show and pick from is
/// (the fields `BrowseChoices` and the controls read), whatever the grid's cards.
extension BrowseFilterControls: @preconcurrency Equatable {
    static func == (lhs: BrowseFilterControls, rhs: BrowseFilterControls) -> Bool {
        let a = lhs.state, b = rhs.state
        return lhs.browse === rhs.browse && lhs.moved == rhs.moved && a.grouping == b.grouping && a.groupings == b.groupings
            && a.filters == b.filters && a.selectedFilters == b.selectedFilters && a.sorts == b.sorts && a.sort == b.sort
            && a.sortDescending == b.sortDescending
    }
}

/// What Libraries' header row gives up to its ⋯ menu on a phone where even its symbols leave the library's name too
/// little room, in this order (`LibrariesScreen.overflow`).
enum HeaderOverflow: Hashable {
    case shuffle, sort, view, filters, type
}

/// Browse's choices as its filters show them, in the row (`BrowseFilters`) or in the ⋯ menu: the sort's chip, symbol
/// and options, Clear (while a sort is picked), Ascending and Descending for the field shown (the direction in effect
/// checked), then under Sort By the fields (the one shown checked; another keeps the direction, or from the unsorted
/// state takes its own); Filters' chip; the type's chip and options.
struct BrowseChoices {
    let browse: LibraryBrowseStore
    let state: BrowseUiState

    static let filtersSymbol = "line.3.horizontal.decrease"
    static let typeSymbol = "square.on.circle"

    var sortChip: FilterChip {
        FilterChip(name: T.shared.libraries.sortBy, text: state.shownSort?.title ?? T.shared.libraries.sort, narrowed: state.sort != nil)
    }

    var sortSymbol: String {
        state.shownSort == nil ? "arrow.up.arrow.down" : state.shownDescending ? "arrow.down" : "arrow.up"
    }

    private var clear: [FilterOption] {
        state.sort != nil ? [FilterOption(label: T.shared.common.clear, selected: false, symbol: "xmark")] : []
    }

    private var directions: [FilterOption] {
        state.shownSort == nil ? [] : [false, true].map { descending in
            FilterOption(
                label: descending ? T.shared.libraries.descending : T.shared.libraries.ascending,
                selected: descending == state.shownDescending,
                // After Clear, a group of their own.
                heading: clear.isEmpty || descending ? nil : "",
                symbol: descending ? "arrow.down" : "arrow.up"
            )
        }
    }

    var sortOptions: [FilterOption] {
        let shown = state.shownSort
        let fields = state.sorts.enumerated().map { index, sort in
            FilterOption(label: sort.title, selected: sort.key == shown?.key, heading: index == 0 && shown != nil ? T.shared.libraries.sortBy : nil)
        }
        return clear + directions + fields
    }

    func pickSort(_ index: Int) {
        let clear = clear.count, directions = directions.count
        if index < clear {
            browse.applySort(sort: nil, descending: false)
        } else if index < clear + directions {
            browse.pickDirection(descending: index - clear == 1)
        } else {
            browse.pickSort(sort: state.sorts[index - clear - directions])
        }
    }

    var filtersChip: FilterChip {
        FilterChip(name: T.shared.libraries.filters, text: state.filtersLabel, narrowed: state.filtersActive)
    }

    var typeChip: FilterChip {
        FilterChip(name: T.shared.libraries.groupings.title, text: state.grouping.label)
    }

    var typeOptions: [FilterOption] {
        state.groupings.map { FilterOption(label: $0.label, selected: $0 == state.grouping) }
    }

    func pickType(_ index: Int) {
        browse.setGrouping(grouping: state.groupings[index])
    }
}

#if os(iOS)
/// Browse's sort options on iPhone and iPad, in a popover from the sort's capsule (a popover on iPhone too) rather than a
/// menu: rows as tall as their content, which scroll where the screen is shorter, so every option stays in reach however
/// many sorts the library has; a system menu shows about 13 rows and cuts off the rest with no way to scroll to them.
/// Each row reads as the menu's option (`FilterMenuOptions`): a check while selected, its symbol where it has one, the
/// same identifiers, a group after a divider under its heading; a pick closes it.
private struct SortOptionsList: View {
    let options: [FilterOption]
    let id: String
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(options.indices, id: \.self) { index in
                    let heading = options[index].heading
                    if index > 0 { Divider().padding(.leading, heading == nil ? 48 : 0) }
                    if let heading, !heading.isEmpty {
                        Text(heading)
                            .font(.footnote)
                            .mutedForeground()
                            .padding(.leading, 48)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                            .accessibilityAddTraits(.isHeader)
                    }
                    row(index)
                }
            }
            .padding(.vertical, 6)
        }
        .frame(width: 300)
        .presentationCompactAdaptation(.popover)
    }

    private func row(_ index: Int) -> some View {
        let option = options[index]
        return Button {
            onSelect(index)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .opacity(option.selected ? 1 : 0)
                    .accessibilityHidden(true)
                Text(option.label)
                Spacer(minLength: 8)
                if let symbol = option.symbol {
                    Image(systemName: symbol).accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(option.selected ? .isSelected : [])
        .accessibilityIdentifier(option.identifier(id, index))
    }
}
#endif

/// One tab of the selected library.
private struct LibraryTabContent: View {
    let app: AppModel
    let store: LibrariesScreenStore
    let tab: LibraryTab

    var body: some View {
        switch tab {
        case .recommended:
            if let recommended = store.recommended() { RecommendedTab(app: app, tab: recommended, store: store) }
        case .browse:
            if let browse = store.browse() { BrowseTab(app: app, browse: browse, store: store) }
        case .collections:
            if let collections = store.collections() {
                PagedTab(app: app, tab: collections, store: store, empty: T.shared.libraries.noCollections)
            }
        case .playlists:
            if let playlists = store.playlists() {
                PagedTab(app: app, tab: playlists, store: store, empty: T.shared.playlists.noPlaylists)
            }
        case .genres:
            if let genres = store.genres() { GenresTab(tab: genres, store: store) }
        }
    }
}

/// Recommended: the library's hubs as shelves (`HubShelf`); a card opens its item, its menu the item's; a hub with more
/// opens its View all. A pull reloads it (iOS). On Apple TV focus enters on the first card once they load.
private struct RecommendedTab: View {
    let app: AppModel
    let tab: LibraryRecommendedStore
    let store: LibrariesScreenStore

    @State private var state: StoreObserver<LibraryListUiState<HubUi>>?
    @FocusState private var cardFocus: String?
    @Environment(\.dimens) private var dimens
    @Environment(\.libraryTabActive) private var active
    @Environment(\.tabBarHoldsFocus) private var tabBarHoldsFocus

    var body: some View {
        let observer = state ?? StoreObserver(tab.state)
        let current = observer.state
        let hubs = current.items.compactMap { $0 as? HubUi }
        Group {
            switch current.load {
            case .loading:
                ScrollView(.vertical) { LoadingShelves(rows: 2).padding(.vertical, dimens.sectionSpacing / 2) }
            case .error:
                ErrorStateView(message: current.error ?? "") { tab.reload() }
            case .empty:
                EmptyStateView(message: T.shared.libraries.noRecommendations)
            default:
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: dimens.sectionSpacing) {
                        ForEach(hubs, id: \.id) { hub in
                            HubShelf(
                                hub: hub, caption: !(app.appearance.state.tv && app.appearance.state.tvFullCardLayout), focus: $cardFocus,
                                onOpen: { store.open(cardId: $0.id) }, onMenu: { store.menu(cardId: $0.id) },
                                onViewAll: { store.openHub(hubId: hub.id) }
                            )
                        }
                    }
                    .padding(.vertical, dimens.sectionSpacing / 2)
                    .scrollsBackToTop()
                }
                .scrollIndicators(.hidden)
                .refreshable { store.refreshTab() }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("libraries.recommended")
        #if os(tvOS)
        // Focus enters the tab on its first card once it loads, unless a shoulder button put it on the view menu.
        .task(id: "\(current.load)|\(active)|\(tabBarHoldsFocus)") {
            guard active, !tabBarHoldsFocus, let hub = hubs.first, let card = hub.items.first else { return }
            await FocusRestore.restore($cardFocus, to: HubShelf.focusKey(hub: hub, card: card), hold: 1)
        }
        #endif
        .task {
            state = observer
            await observer.observe()
        }
    }
}
