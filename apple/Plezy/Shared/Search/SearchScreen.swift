import SwiftUI
import PlezyKit

/// Search across the servers (`SearchStore`): on iPhone, iPad and the Mac the header row's field (a glass capsule with
/// the search symbol, a spinner while a search runs and, holding text, Clear; focused as the screen opens and on ⌘F,
/// `SearchStore.focusField`) and the kind
/// filter (All, each kind found, People, a `FilterMenu`) when the results span more than one; on Apple TV the system's
/// search field (`searchable`) with the filter in a row over the results. Then the results as plain list rows, titles (`SearchMediaRow`: selecting one does what selecting the title does anywhere,
/// `SearchStore.open`, a long press its menu) and people (`SearchPersonRow`) in rank order, under All in groups headed
/// by their kind (`SearchResultGroup`: Movies, Shows, People…). Before a query, the
/// prompt; while the first answer comes, a spinner; then no results, or the failure with Retry. Partial and failed
/// searches show as toasts. On Apple TV the system's keyboard's Search scrolls the first result to the middle and
/// focuses it once it shows (`focusFirstResult`). Elsewhere the field is `SearchField`: a keyboard's Escape in it
/// empties it, empty it goes on to the shell; a keyboard's Down goes to the kind filter or the first result (`fieldDown`).
struct SearchScreen: View {
    let app: AppModel

    @State private var model: StoreModel<SearchStore, SearchUiState>?
    #if os(tvOS)
    /// The system search field's text.
    @State private var query: String
    #endif
    @State private var message: String?
    @FocusState private var focus: String?
    /// The first result's key a landed submit focuses, until it shows and takes focus.
    @State private var landedFocus: String?
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var screenSides

    private static let fieldKey = "search.field"

    init(app: AppModel, route: any Route) {
        self.app = app
        let model = StoreModel(app.session.search(route: route)) { $0.state }
        _model = State(initialValue: model)
        #if os(tvOS)
        _query = State(initialValue: model?.state.state.query ?? "")
        #endif
    }

    var body: some View {
        if let model {
            let state = model.state.state
            content(model, state)
                .toast(message, id: "search.message") { message = nil }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("search.screen")
                .task { await model.state.observe() }
                .task {
                    for await text in model.store.messages { message = text }
                }
                .task {
                    for await _ in model.store.focusFirstResult {
                        // The store's own state: the mirror may not have caught up with the results that just landed.
                        if let first = model.store.state.value.results.first { landedFocus = Self.resultKey(first) }
                    }
                }
                .onChange(of: focus) { _, key in if key != nil, key == landedFocus { landedFocus = nil } }
                // ⌘F (`AppCommands`): the field.
                .task {
                    for await _ in model.store.fieldFocusRequests { focus = Self.fieldKey }
                }
        }
    }

    @ViewBuilder
    private func content(_ model: StoreModel<SearchStore, SearchUiState>, _ state: SearchUiState) -> some View {
        #if os(tvOS)
        VStack(alignment: .leading, spacing: 12 * dimens.unit) {
            kindMenu(model, state)
            results(model, state)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .searchable(text: $query, prompt: Text(T.shared.search.hint))
        .onChange(of: query) { _, text in model.store.setQuery(value: text) }
        // The query first: the `onChange` of the last key typed can run after the submit.
        .onSubmit(of: .search) {
            model.store.setQuery(value: query)
            model.store.submit()
        }
        #else
        results(model, state)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .screenHeader(row: {
                HStack(spacing: HeaderMetrics.spacing) {
                    SearchField(
                        text: state.query, hint: T.shared.search.hint, id: Self.fieldKey, clearId: "search.clear",
                        onChange: { model.store.setQuery(value: $0) },
                        onSubmit: model.store.submit, searching: state.searching, focus: $focus, onDown: { fieldDown(model) }
                    )
                    #if os(macOS)
                    .frame(minWidth: 200, idealWidth: 480, maxWidth: 480)
                    #else
                    .frame(maxWidth: dimens.contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    #endif
                    kindMenu(model, state)
                }
            })
            .onAppear { if state.query.isEmpty { focus = Self.fieldKey } }
        #endif
    }

    /// The kind filter (All, each kind found, People) as the header row's filter (`FilterMenu`; on tvOS in a
    /// `FilterRow` over the results), where the results span more than one kind: the selected kind on its capsule.
    @ViewBuilder
    private func kindMenu(_ model: StoreModel<SearchStore, SearchUiState>, _ state: SearchUiState) -> some View {
        if !state.filters.isEmpty {
            let selected = state.filters.firstIndex { ($0 as AnyObject).isEqual(state.filter) } ?? 0
            let name = T.shared.search.searchYourMedia
            let menu = FilterMenu(
                chip: FilterChip(name: name, text: state.filters[selected].label, narrowed: selected != 0),
                options: state.filters.enumerated().map { index, filter in FilterOption(label: filter.label, selected: index == selected) },
                id: "search.filter",
                focus: $focus
            ) { index in
                if state.filters.indices.contains(index) { model.store.selectFilter(filter: state.filters[index]) }
            }
            #if os(tvOS)
            FilterRow { menu }
            #else
            menu
            #endif
        }
    }

    #if !os(tvOS)
    /// A keyboard's Down in the field: to the kind filter, else the first result, once results show and no search runs.
    /// False leaves the key to the field.
    private func fieldDown(_ model: StoreModel<SearchStore, SearchUiState>) -> Bool {
        let state = model.state.state
        guard let first = state.results.first, !state.searching else { return false }
        if !state.filters.isEmpty {
            focus = "search.filter"
        } else {
            focus = Self.resultKey(first)
        }
        return true
    }
    #endif

    @ViewBuilder
    private func results(_ model: StoreModel<SearchStore, SearchUiState>, _ state: SearchUiState) -> some View {
        if !state.results.isEmpty {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(state.groups.enumerated()), id: \.element.title) { index, group in
                            if let title = group.title {
                                groupHeading(title, first: index == 0)
                                    .accessibilityIdentifier("search.group.\(index)")
                            }
                            ForEach(group.results, id: \.key) { result in
                                let key = Self.resultKey(result)
                                resultRow(model, result)
                                    .focused($focus, equals: key)
                                    .id(key)
                                    .onAppear { if landedFocus == key { focus = key } }
                            }
                        }
                    }
                    .padding(.horizontal, screenSides.leading - ListRowLayout.companion.PADDING * dimens.unit)
                    .padding(.bottom, dimens.sectionSpacing)
                }
                .scrollIndicators(.hidden)
                .overlay(alignment: .top) {
                    if state.searching { ProgressView().padding(8) }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("search.results")
                .onChange(of: landedFocus, initial: true) { _, key in
                    guard let key else { return }
                    proxy.scrollTo(key, anchor: .center)
                    focus = key
                }
            }
        } else {
            switch state.phase {
            case .searching:
                LoadingStateView().accessibilityIdentifier("search.loading")
            case .empty:
                EmptyStateView(message: T.shared.messages.noResultsFound, systemImage: "magnifyingglass")
                    .accessibilityIdentifier("search.empty")
            case .failed where state.sessionExpired != nil:
                // Retry can't help an expired sign-in: say so, naming the server, and offer it again, focused as Retry is.
                ErrorStateView(
                    message: state.sessionExpired ?? "", title: T.shared.search.sessionExpired, systemImage: "lock",
                    retryLabel: T.shared.connections.signInAgain, retrySystemImage: nil, onRetry: { app.session.signInAgain() }
                )
                .accessibilityIdentifier("search.sessionExpired")
            case .failed:
                ErrorStateView(message: T.shared.explore.searchFailed, onRetry: model.store.refresh)
                    .accessibilityIdentifier("search.failed")
            default:
                EmptyStateView(message: T.shared.search.enterTitleActorOrKeyword, systemImage: "magnifyingglass")
                    .accessibilityIdentifier("search.prompt")
            }
        }
    }

    @ViewBuilder
    private func resultRow(_ model: StoreModel<SearchStore, SearchUiState>, _ result: any SearchResultUi) -> some View {
        let density = app.appearance.state.libraryDensity
        switch onEnum(of: result) {
        case .media(let media):
            SearchMediaRow(
                result: media, density: density, action: { model.store.open(key: media.key) },
                onMenu: { model.store.menu(key: media.key) }
            )
        case .person(let person):
            SearchPersonRow(result: person, density: density, action: { app.navigator.navigate(route: person.route) })
        }
    }

    /// A kind's heading over its results (All's groups, `SearchResultGroup`), lined up with the rows' artwork.
    private func groupHeading(_ title: String, first: Bool) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Palette.onBackground)
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
            .padding(.horizontal, ListRowLayout.companion.PADDING * dimens.unit)
            .padding(.top, first ? 0 : dimens.sectionSpacing)
            .padding(.bottom, dimens.headingGap)
    }

    private static func resultKey(_ result: any SearchResultUi) -> String { "search.result.\(result.key)" }
}

/// A title among the results, as a library's list row (`ListRowLayout`): the artwork, then the title (two lines), the
/// caption, the summary and, where it tells copies apart, the server and library it lives in after the backend's mark
/// (a wide row gives up a summary line for it). The text follows Dynamic Type as the subheadline does, the title and
/// caption whole at the accessibility sizes.
private struct SearchMediaRow: View {
    let result: SearchResultUiMedia
    let density: Int32
    let action: () -> Void
    let onMenu: () -> Void

    @Environment(\.dimens) private var dimens
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1

    var body: some View {
        let card = result.card
        let unit = dimens.unit
        let text = unit * textScale
        let whole = dynamicTypeSize.isAccessibilitySize
        let row = ListRowLayout.companion
        let layout = row.of(density: density, shape: card.shape)
        SearchRowButton(id: "search.result.\(card.id)", label: result.label, value: card.accessibilityState, action: action, onMenu: onMenu, menuItem: card) {
            HStack(alignment: .top, spacing: row.ARTWORK_GAP * unit) {
                CardArtwork(card: card, size: CGSize(width: layout.artworkWidth * unit, height: layout.artworkHeight * unit))
                    .clipShape(CardArtworkShape(circular: card.placeholder.circular))
                VStack(alignment: .leading, spacing: 4 * unit) {
                    Text(card.title)
                        .font(.system(size: row.titleSize(density: density) * text, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(whole ? nil : 2)
                    if let caption = card.caption {
                        Text(caption)
                            .font(.system(size: row.subtitleSize(density: density) * text, weight: .medium))
                            .mutedForeground()
                            .lineLimit(whole ? nil : 1)
                    }
                    if let summary = card.summary {
                        let lines = Int(row.summaryLines(density: density))
                        Text(summary)
                            .font(.system(size: row.metadataSize(density: density) * text))
                            .mutedForeground()
                            .opacity(0.7)
                            .lineLimit(result.source != nil && card.shape == .wide && lines > 1 ? lines - 1 : lines)
                    }
                    if let source = result.source {
                        SearchSourceLine(backend: result.backend, text: source, size: row.metadataSize(density: density) * text)
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// A person among the results: their portrait, round (0.6 of the artwork column), in the media rows' artwork column so
/// the names line up, then the name (two lines), the credit ("Actor") and the server after its backend's mark; the text
/// as the media rows' (`SearchMediaRow`).
private struct SearchPersonRow: View {
    let result: SearchResultUiPerson
    let density: Int32
    let action: () -> Void

    @Environment(\.dimens) private var dimens
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1

    var body: some View {
        let unit = dimens.unit
        let text = unit * textScale
        let row = ListRowLayout.companion
        let layout = row.of(density: density, shape: .poster)
        let avatar = layout.artworkWidth * 0.6 * unit
        SearchRowButton(id: "search.person.\(result.key)", label: result.name, value: result.credit ?? "", action: action) {
            HStack(alignment: .center, spacing: row.ARTWORK_GAP * unit) {
                ZStack {
                    Palette.surfaceContainerHighest
                    RemoteImage(artwork: result.image) { failed in
                        if failed { ArtworkPlaceholder(kind: .person) }
                    }
                }
                .frame(width: avatar, height: avatar)
                .clipShape(Circle())
                .frame(width: layout.artworkWidth * unit)
                VStack(alignment: .leading, spacing: 4 * unit) {
                    Text(result.name)
                        .font(.system(size: row.titleSize(density: density) * text, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    if let credit = result.credit {
                        Text(credit)
                            .font(.system(size: row.metadataSize(density: density) * text))
                            .mutedForeground()
                            .lineLimit(1)
                    }
                    if let source = result.source {
                        SearchSourceLine(backend: result.backend, text: source, size: row.metadataSize(density: density) * text)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Where a result lives ("Home server • Movies"), muted after its backend's mark.
private struct SearchSourceLine: View {
    let backend: BackendKind
    let text: String
    let size: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            BackendMark(backend: backend, size: size + 2)
            Text(text).lineLimit(1)
        }
        .font(.system(size: size))
        .mutedForeground()
        .opacity(0.6)
        .padding(.top, 2)
    }
}

/// A result's row as one button, a plain list row: the list row's padding, the app's row focus fill, one element to
/// accessibility; `onMenu`, where given, its menu (a long press, a held Select, a right click). On the Mac, Return and
/// Space press the focused row: focus a submit lands on it (`landedFocus`) is SwiftUI's alone, with the window's
/// hosting view AppKit's first responder, and the button took neither key there.
private struct SearchRowButton<Content: View>: View {
    let id: String
    let label: String
    let value: String
    let action: () -> Void
    var onMenu: (() -> Void)?
    /// What `onMenu`'s menu is of.
    var menuItem: AnyHashable = ""
    @ViewBuilder let content: () -> Content

    @Environment(\.dimens) private var dimens

    var body: some View {
        Button(action: action) {
            content()
                .padding(ListRowLayout.companion.PADDING * dimens.unit)
                .contentShape(Rectangle())
        }
        .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: Radius.small * dimens.unit))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(id)
        .mediaMenuTrigger(onMenu, item: menuItem)
        #if os(macOS)
        .onKeyPress(keys: [.return, .space]) { _ in
            action()
            return .handled
        }
        #endif
    }
}
