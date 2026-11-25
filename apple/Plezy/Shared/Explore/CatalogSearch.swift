import SwiftUI
import PlezyKit

/// One catalog source's search (Explore's Search on a TV, where no field shares the spotlight): the field (as Search's:
/// the system's on Apple TV, else `SearchField`), then the prompt, the results as a list of catalog cards, the failure or
/// the empty answer. The keyboard's search (a TV's editing done) searches at once.
struct CatalogSearchScreen: View {
    let app: AppModel

    @State private var model: StoreModel<CatalogSearchStore, CatalogSearchUiState>?
    #if os(tvOS)
    /// The system search field's text.
    @State private var query = ""
    #endif
    @State private var actions: CatalogActions
    @Environment(\.screenSides) private var screenSides

    init(app: AppModel, route: RouteCatalogSearch) {
        self.app = app
        _model = State(initialValue: StoreModel(app.session.catalogSearch(route: route)) { $0.state })
        _actions = State(initialValue: CatalogActions(app: app))
    }

    var body: some View {
        if let model {
            let state = model.state.state
            VStack(alignment: .leading, spacing: 12) {
                #if !os(tvOS)
                SearchField(
                    text: state.query, hint: state.title, id: "catalogSearch.field", clearId: "catalogSearch.field.clear",
                    onChange: model.store.setQuery,
                    onSubmit: { _ = model.store.submit() }
                )
                .padding(.horizontal, screenSides.leading)
                #endif
                CatalogSearchResults(search: state.body, appearance: app.appearance.state, actions: actions, onRetry: model.store.retry)
            }
            #if os(tvOS)
            .searchable(text: $query, prompt: Text(state.title))
            .onChange(of: query) { _, text in model.store.setQuery(text: text) }
            // The query first: the `onChange` of the last key typed can run after the submit.
            .onSubmit(of: .search) {
                model.store.setQuery(text: query)
                _ = model.store.submit()
            }
            #endif
            .padding(.top, 8)
            .navigationTitle(state.title)
            .inlineNavigationTitle()
            .toast(actions.message, id: "catalog.message") { actions.message = nil }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("catalogSearch.screen")
            .task { await model.state.observe() }
            .task(id: state.body.resultIds) { await actions.prepare(state.body.results) }
        }
    }
}

/// Where a catalog search stands (`CatalogSearchBody`): a spinner while it runs, the prompt before any query, the
/// failure or the empty answer as a message, else the results as a list of catalog cards, each with the screen's
/// `focus` as its id.
struct CatalogSearchResults: View {
    let search: CatalogSearchBody
    let appearance: Appearance
    let actions: CatalogActions
    let onRetry: () -> Void
    var focus: FocusState<String?>.Binding?

    @Environment(\.screenSides) private var screenSides

    var body: some View {
        Group {
            switch onEnum(of: search) {
            case .loading:
                LoadingStateView()
            case .idle(let idle):
                if let prompt = idle.prompt {
                    EmptyStateView(message: prompt, systemImage: "magnifyingglass")
                } else {
                    Color.clear
                }
            case .failed(let failed):
                ErrorStateView(message: failed.text, onRetry: onRetry)
            case .empty(let empty):
                EmptyStateView(message: empty.text, systemImage: "magnifyingglass")
            case .results(let results):
                ScrollView(.vertical) {
                    MediaList(
                        items: results.items.compactMap { $0.toCatalogCard(posterPx: 240, backdropPx: 1280) }, shape: .poster,
                        density: appearance.libraryDensity, onOpen: actions.open(card:), menu: actions.menu(card:), focus: focus
                    )
                    .padding(.horizontal, screenSides.leading)
                }
                .accessibilityIdentifier("catalogSearch.results")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

extension CatalogSearchBody {
    /// The results' catalog stand-ins; none in any other state.
    var results: [MediaItem] {
        if case .results(let results) = onEnum(of: self) { results.items } else { [] }
    }

    var resultIds: [String] { results.map(\.id) }
}
