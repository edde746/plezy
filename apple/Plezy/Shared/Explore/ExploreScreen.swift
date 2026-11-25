import SwiftUI
import PlezyKit

/// Explore: a header row of filters over the active catalog source's shelves (`HubShelf`). The
/// row leads with the source switcher (`explore.source`, a `FilterMenu` of the connected sources, while two or more
/// are), then on iPhone, iPad and the Mac the inline search field, whose results replace the shelves while it holds
/// text, and Refresh (also ⌘R and pull to refresh); on Apple TV (`FilterRow`, reachable in every state) the switcher,
/// then Search (the source's search screen) and Refresh. The page's title is the source's name, "Explore" while none is
/// connected. Loading shelves while the source loads, the error with Retry or the empty state in their place. A card
/// opens the title's detail; its menu is the catalog's (`CatalogActions`). A shelf with more opens its View all from
/// its heading's link or its last card. tvOS: the first card takes focus once there is one, unless the user moved first.
/// iPhone, iPad and the Mac: as Explore shows (its tab, a screen over it closing) focus goes to the search's first result
/// while a search has some, the keyboard staying down, else to the search field while a search is on; without a search
/// to the first shelf's card focus last left there, else its first. Up from the first shelf reaches the search field.
struct ExploreScreen: View {
    let app: AppModel
    let route: any Route

    @State private var model: StoreModel<ExploreStore, ExploreUiState>?
    @State private var actions: CatalogActions
    @State private var firstFocus = ScreenFirstFocus(pending: true)
    @FocusState private var focus: String?
    @Environment(\.dimens) private var dimens

    /// The search field's key in `focus`.
    private static let searchField = "explore.search"

    init(app: AppModel, route: any Route) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.explore(route: route)) { $0.state })
        _actions = State(initialValue: CatalogActions(app: app))
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            let content = ExploreContent(state: state, tv: app.appearance.state.tv)
            page(state: state, store: store, content: content)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .navigationTitle(state.title)
                .inlineNavigationTitle()
                .toast(actions.message, id: "catalog.message") { actions.message = nil }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("explore.screen")
                #if os(tvOS)
                .firstFocus(firstFocus, to: firstCard(content.hubs), isTop: app.isTop(route), focus: $focus, hold: 1.5)
                #else
                .task(id: app.isTop(route)) {
                    guard app.isTop(route) else { return }
                    // Once the page's views are in place to take focus.
                    try? await Task.sleep(for: .milliseconds(300))
                    if !Task.isCancelled { focusOnShow(model) }
                }
                .onChange(of: focus) { _, key in
                    if let key, let hub = content.hubs.first, key.hasPrefix("\(hub.id)|") { FirstShelfFocus.of(store).key = key }
                }
                #endif
                .onAppear { store.ensureFresh() }
                .task { await model.state.observe() }
                .task(id: content.itemIds + (state.search?.resultIds ?? [])) {
                    await actions.prepare(content.items + (state.search?.results ?? []))
                }
        }
    }

    @ViewBuilder
    private func page(state: ExploreUiState, store: ExploreStore, content: ExploreContent) -> some View {
        #if os(tvOS)
        VStack(spacing: 0) {
            FilterRow {
                if state.showsSwitcher { SourceFilter(state: state, store: store) }
            } trailing: {
                if let active = state.sources.first(where: \.selected) {
                    IconButton(systemImage: "magnifyingglass", label: T.shared.common.search, id: "explore.searchScreen") {
                        app.navigator.navigate(route: RouteCatalogSearch(source: active.id))
                    }
                }
                IconButton(systemImage: "arrow.clockwise", label: T.shared.common.refresh, id: "explore.refresh", action: store.refresh)
            }
            shelves(store: store, content: content)
        }
        #else
        Group {
            if let search = state.search {
                CatalogSearchResults(search: search, appearance: app.appearance.state, actions: actions, onRetry: store.refresh, focus: $focus)
            } else {
                shelves(store: store, content: content)
                    .refreshable {
                        // The spinner holds until the refresh's load lands; the shelves stay meanwhile.
                        store.refresh()
                        for await value in store.state where !value.refreshing { break }
                    }
            }
        }
        .screenHeader(filters: {
            if state.showsSwitcher { SourceFilter(state: state, store: store) }
            SearchField(
                text: state.searchText, hint: state.searchHint, id: Self.searchField, clearId: "\(Self.searchField).clear",
                onChange: store.setSearchText, onSubmit: { _ = store.submitSearch() }, focus: $focus
            )
            .frame(minWidth: 180, maxWidth: 360)
        }, actions: {
            Button(T.shared.common.refresh, systemImage: "arrow.clockwise", action: store.refresh)
                .keyboardShortcut("r", modifiers: .command)
                .accessibilityIdentifier("explore.refresh")
        })
        #endif
    }

    private func shelves(store: ExploreStore, content: ExploreContent) -> some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: dimens.sectionSpacing) {
                switch content.load {
                case .content:
                    ForEach(content.hubs, id: \.id) { hub in
                        HubShelf(
                            hub: hub, focus: $focus, onOpen: actions.open(card:), menu: actions.menu(card:),
                            onViewAll: { app.navigator.navigate(route: RouteExploreRow(hubId: hub.id, title: hub.title)) }
                        )
                        #if !os(tvOS)
                        .onKeyPress(.upArrow) {
                            guard hub.id == content.hubs.first?.id else { return .ignored }
                            focus = Self.searchField
                            return .handled
                        }
                        #endif
                    }
                case .loading:
                    LoadingShelves()
                default:
                    BrowsePlaceholder(
                        load: content.load, error: content.error, onRetry: store.retry, emptyMessage: content.emptyMessage, emptySymbol: "safari"
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                }
            }
            .padding(.top, Self.topGap)
            .padding(.bottom, dimens.sectionSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .scrollMemory(ScrollMemory.of(store))
    }

    private func firstCard(_ hubs: [HubUi]) -> String? {
        guard let hub = hubs.first, let card = hub.items.first else { return nil }
        return HubShelf.focusKey(hub: hub, card: card)
    }

    /// The shelves' room under the header row.
    #if os(tvOS)
    private static let topGap: CGFloat = 12
    #else
    private static let topGap: CGFloat = 8
    #endif

    #if !os(tvOS)
    /// Focus as Explore shows: the search's first result, else its field while a search is on; without one the first
    /// shelf's card focus last left there (`FirstShelfFocus`), else its first.
    private func focusOnShow(_ model: StoreModel<ExploreStore, ExploreUiState>) {
        let state = model.state.state
        if let search = state.search {
            focus = search.results.first?.id ?? Self.searchField
            return
        }
        guard let hub = ExploreContent(state: state, tv: false).hubs.first, !hub.items.isEmpty else { return }
        let keys = hub.items.map { HubShelf.focusKey(hub: hub, card: $0) }
        focus = FirstShelfFocus.of(model.store).key.flatMap { keys.contains($0) ? $0 : nil } ?? keys[0]
    }
    #endif
}

#if !os(tvOS)
/// The card focus last left in Explore's first shelf, kept beside the screen's store (`of`) as `ScrollMemory` is: the
/// view, built again whenever its tab shows again, puts focus back on it.
@MainActor
private final class FirstShelfFocus {
    var key: String?

    private static let memories = NSMapTable<AnyObject, FirstShelfFocus>.weakToStrongObjects()

    static func of(_ store: AnyObject) -> FirstShelfFocus {
        if let memory = memories.object(forKey: store) { return memory }
        let memory = FirstShelfFocus()
        memories.setObject(memory, forKey: store)
        return memory
    }
}
#endif

/// Explore's state as the hub views take it: the shelves as rows of catalog cards (`toHubUi`), the load state, and
/// the error's or empty state's text.
@MainActor
private struct ExploreContent {
    let hubs: [HubUi]
    let items: [MediaItem]
    let load: LoadState
    let error: String?
    let emptyMessage: String

    init(state: ExploreUiState, tv: Bool) {
        var rows: [ExploreRow] = []
        var load = LoadState.content
        var error: String?
        var empty = ""
        switch onEnum(of: state.body) {
        case .rows(let body): rows = body.rows
        case .loading: load = .loading
        case .failed(let failed):
            load = .error
            error = failed.text
        case .empty(let body):
            load = .empty
            empty = body.text
        }
        let posterPx: Int32 = tv ? 500 : 360
        let backdropPx: Int32 = tv ? 1920 : 1280
        hubs = rows.map { $0.toHubUi(posterPx: posterPx, backdropPx: backdropPx) }
        items = rows.flatMap(\.hub.items)
        self.load = load
        self.error = error
        emptyMessage = empty
    }

    /// The cards' ids, which the menus are read again for when they change.
    var itemIds: [String] { items.map(\.id) }
}

/// The source switcher, the header row's first filter (`explore.source`): every connected source in the store's fixed
/// order, the shown one selected; picking one shows its shelves. The capsule shows the shown source's mark alone (its
/// name is the spoken label), so the search field beside it gets the room; the menu names every source.
private struct SourceFilter: View {
    let state: ExploreUiState
    let store: ExploreStore

    var body: some View {
        let active = state.sources.first(where: \.selected)
        FilterMenu(
            chip: FilterChip(name: T.shared.explore.selectSource, text: state.title, spoken: "\(T.shared.explore.selectSource): \(state.title)"),
            mark: active.map { "mark.\($0.id.id)" },
            options: state.sources.map { FilterOption(label: $0.name, selected: $0.selected) },
            id: "explore.source"
        ) { index in
            store.selectSource(id: state.sources[index].id)
        }
    }
}

/// A catalog source's brand mark (`SourceMarks`), in the text colour around it.
struct SourceMark: View {
    let id: CatalogSourceId
    var size: CGFloat = 20

    var body: some View {
        Image("mark.\(id.id)")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
