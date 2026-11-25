import SwiftUI
import PlezyKit

/// A hub's View all (`Route.HubDetail`): its spinner alone until the hub's items and sorts are in
/// (`HubDetailState.settled`, `hubDetail.loading`); then the hub's title over the grid with its Sort (`FilterMenu`) at
/// the title row's trailing end, level with the title and scrolling away with it, then every item in as many columns of
/// the card width as fit (in the list view mode as the library's list rows); a hub that pages lazily loads its next
/// page once its end comes into view. iOS's bar shows no title, the row naming the page (`titleInContent`); Apple TV's
/// shows none either. A failed first load shows the error with Retry, a
/// failed later page Retry under the grid. Continue Watching's cards play directly. tvOS: the first card takes focus
/// once there is one, unless the user moved first; the title row is a focus section, so Up from the grid's top row
/// reaches the Sort; Menu goes back to the hub's shelf.
struct HubDetailView: View {
    let app: AppModel
    let route: RouteHubDetail

    @State private var model: StoreModel<HubDetailStore, HubDetailState>?
    @State private var firstFocus = ScreenFirstFocus(pending: true)
    @FocusState private var focus: String?
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides

    init(app: AppModel, route: RouteHubDetail) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.hubDetail(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            Group {
                if state.settled {
                    content(state: state, store: store)
                } else {
                    LoadingStateView().accessibilityIdentifier("hubDetail.loading")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            #if !os(tvOS)
            .pageTitle(state.title)
            .titleInContent()
            #endif
            .copyPicker(app: app)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("hubDetail")
            #if os(tvOS)
            .firstFocus(firstFocus, to: state.cards.first.map(\.id), isTop: app.isTop(route), focus: $focus)
            #endif
            .task { await model.state.observe() }
        }
    }

    @ViewBuilder
    private func content(state: HubDetailState, store: HubDetailStore) -> some View {
        if state.items.isEmpty {
            Group {
                if let error = state.error {
                    ErrorStateView(message: error, onRetry: store.retry)
                } else if state.loading {
                    LoadingStateView()
                } else {
                    EmptyStateView(message: T.shared.hubDetail.noItemsFound, systemImage: "rectangle.stack")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            grid(state: state, store: store)
        }
    }

    /// The hub's title with its Sort at the row's end (`PageHeading`).
    private func titleRow(state: HubDetailState, store: HubDetailStore) -> some View {
        PageHeading(title: state.title, id: "hubDetail.title") {
            if !state.sortOptions.isEmpty {
                ViewAllSort(choices: state.sortChoices, sort: state.sort, descending: state.descending, id: "hubDetail.sort", onPick: store.pickSort)
            }
        }
        .padding(sides.insets)
        #if os(tvOS)
        // From side to side: Up from any column of the grid's top row reaches the Sort.
        .focusSection()
        #endif
    }

    private func grid(state: HubDetailState, store: HubDetailStore) -> some View {
        let appearance = app.appearance.state
        let playDirectly = route.hubId == HomeStore.companion.CONTINUE_WATCHING_ID
        let shape = TvLayoutKt.hubShape(items: state.cards.map { $0.shape }, episodeThumbnails: appearance.episodeThumbnails)
        let open: (MediaCardUi) -> Void = { card in
            if let item = store.item(cardId: card.id) { app.session.mediaActions.open(item: item, playDirectly: playDirectly) }
        }
        let menu: (MediaCardUi) -> Void = { card in
            if let item = store.item(cardId: card.id) {
                app.session.mediaActions.menu.open(
                    item: item,
                    place: MenuPlace(continueWatching: playDirectly, collectionId: nil, seriesId: nil, albumId: nil, artistId: nil),
                    extras: [], playTrailer: nil, onRow: []
                )
            }
        }
        return GeometryReader { proxy in
            let cells = dimens.grid(width: proxy.size.width - sides.leading - sides.trailing, shape: shape, appearance: appearance)
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    titleRow(state: state, store: store)
                        .padding(.top, dimens.sectionSpacing)
                    // The library's view mode: its list's rows, else its grid.
                    Group {
                        if appearance.viewMode == .list {
                            MediaList(items: state.cards, shape: shape, density: appearance.libraryDensity, onOpen: open, onMenu: menu)
                        } else {
                            CardGrid(cells: cells) {
                                ForEach(state.cards, id: \.id) { card in
                                    PosterCard(
                                        card: card, shape: shape, width: cells.cell, focus: CardFocus(binding: $focus, key: card.id),
                                        onOpen: { open(card) }, onMenu: { menu(card) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(sides.insets)
                    // Room for the focused card to lift (tvOS) or its focus ring.
                    .padding(.vertical, dimens.focusRoom + 4)
                    // The grid's end coming into view asks for the next page, where the hub pages lazily.
                    Color.clear.frame(height: 1).onAppear { store.nearEnd() }
                    if state.pageLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.vertical, 16)
                    } else if state.pageFailed {
                        ActionButton(
                            title: T.shared.common.retry, id: "hubDetail.retry", systemImage: "arrow.clockwise", fullWidth: false,
                            action: store.retryPage
                        )
                        .frame(maxWidth: .infinity)
                        #if os(tvOS)
                        // As wide as the grid: Down from a card in any column reaches Retry.
                        .focusSection()
                        #endif
                        .padding(.vertical, 16)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

/// A View all's Sort as a filter (a hub's, an Explore shelf's): the order in effect after its direction's arrow (Sort
/// while the page keeps its own order); its menu, as Libraries' sort, starts with Clear, Ascending and Descending while an
/// order is set, then under Sort By each order it offers, the one in effect checked (the orders alone while none is); an
/// order picked from the page's own takes its own direction, another while one is set keeps the direction. On a phone
/// its symbol alone, as in a header row.
struct ViewAllSort: View {
    let choices: [MenuOption]
    let sort: MediaSort?
    let descending: Bool
    let id: String
    let onPick: (Int32) -> Void

    @Environment(\.formFactor) private var formFactor

    var body: some View {
        FilterMenu(
            chip: FilterChip(name: T.shared.libraries.sortBy, text: sort?.title ?? T.shared.libraries.sort, spoken: sort == nil ? T.shared.libraries.sort : nil, narrowed: sort != nil),
            symbol: sort == nil ? "arrow.up.arrow.down" : descending ? "arrow.down" : "arrow.up",
            options: choices.map { FilterOption(label: $0.label, selected: $0.selected, heading: $0.heading, symbol: $0.icon?.systemImage) },
            id: id
        ) { onPick(Int32($0)) }
        .environment(\.compactFilters, formFactor == .compact)
    }
}
