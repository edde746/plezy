import SwiftUI
import PlezyKit

/// An Explore shelf's View All, as a hub's View all (`HubDetailView`): its spinner alone
/// while every item loads (`exploreRow.loading`), then the shelf's title over the grid with its Sort (`ViewAllSort`) at
/// the title row's trailing end, scrolling away with it, then every item in as many columns of the card width as fit;
/// the error with Retry, or the empty state. The bar shows no title, the row naming the page (`titleInContent`). tvOS:
/// the first card takes focus once there is one, unless the user moved first; the title row is a focus section, so Up
/// from the grid's top row reaches the Sort.
struct ExploreRowScreen: View {
    let app: AppModel
    let route: RouteExploreRow

    @State private var model: StoreModel<ExploreRowStore, ExploreRowUiState>?
    @State private var actions: CatalogActions
    @State private var firstFocus = ScreenFirstFocus(pending: true)
    @FocusState private var focus: String?
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides

    init(app: AppModel, route: RouteExploreRow) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.exploreRow(route: route)) { $0.state })
        _actions = State(initialValue: CatalogActions(app: app))
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let items = state.body.items
            let tv = app.appearance.state.tv
            let cards = items.compactMap { $0.toCatalogCard(posterPx: tv ? 500 : 360, backdropPx: 1280) }
            Group {
                switch onEnum(of: state.body) {
                case .items(let body):
                    if body.loading {
                        LoadingStateView().accessibilityIdentifier("exploreRow.loading")
                    } else {
                        grid(cards, state: state, store: model.store)
                    }
                case .failed(let failed):
                    ErrorStateView(message: failed.text, onRetry: model.store.retry)
                case .empty(let empty):
                    EmptyStateView(message: empty.text, systemImage: "safari")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if !os(tvOS)
            .pageTitle(state.title)
            .titleInContent()
            #endif
            .toast(actions.message, id: "catalog.message") { actions.message = nil }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("exploreRow.screen")
            #if os(tvOS)
            .firstFocus(firstFocus, to: cards.first.map(\.id), isTop: app.isTop(route), focus: $focus)
            #endif
            .task { await model.state.observe() }
            .task(id: items.map(\.id)) { await actions.prepare(items) }
        }
    }

    private func grid(_ cards: [MediaCardUi], state: ExploreRowUiState, store: ExploreRowStore) -> some View {
        GeometryReader { proxy in
            let cells = dimens.grid(width: proxy.size.width - sides.horizontal, shape: .poster, appearance: app.appearance.state)
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    PageHeading(title: state.title, id: "exploreRow.title") {
                        ViewAllSort(choices: state.sortChoices, sort: state.sort, descending: state.descending, id: "exploreRow.sort", onPick: store.pickSort)
                    }
                    .padding(sides.insets)
                    #if os(tvOS)
                    // From side to side: Up from any column of the grid's top row reaches the Sort.
                    .focusSection()
                    #endif
                    .padding(.top, dimens.sectionSpacing)
                    CardGrid(cells: cells) {
                        ForEach(cards, id: \.id) { card in
                            PosterCard(
                                card: card, shape: .poster, width: cells.cell, focus: CardFocus(binding: $focus, key: card.id),
                                onOpen: { actions.open(card: card) }, menu: actions.menu(card: card)
                            )
                        }
                    }
                    .padding(sides.insets)
                    // Room for the focused card to lift (tvOS) or its focus ring.
                    .padding(.vertical, dimens.focusRoom + 4)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

extension ExploreRowBody {
    /// The grid's items; none while it shows the error or the empty state.
    var items: [MediaItem] {
        if case .items(let body) = onEnum(of: self) { body.items } else { [] }
    }
}
