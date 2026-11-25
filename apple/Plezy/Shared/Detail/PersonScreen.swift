import SwiftUI
import PlezyKit

/// An actor's screen (`PersonStore`), titled with their name in its header, not in the navigation bar
/// (`pageTitle(_:inContent:)`: on Apple TV the bar's title would take the room the header shows in): their round
/// portrait beside the name and the character they played, the facts (born, died, birthplace), the biography (three
/// lines, then More),
/// then "N titles" over the grid of their titles on that server (`PagedGrid`, each card telling VoiceOver its row and
/// column). A title opens its screen; its item menu is the shared one (a long press, a right click, a held Select).
/// Focus moves through the system's focus engine: Up from the grid's first row
/// reaches the biography's More, then the navigation bar; Back leaves. Until the details and the first page of titles
/// are in (`PersonUiState.settled`) the screen shows its spinner alone (`person.loading`).
struct PersonScreen: View {
    let app: AppModel

    @State private var model: StoreModel<PersonStore, PersonUiState>?
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var screenSides

    init(app: AppModel, route: RoutePerson) {
        self.app = app
        _model = State(initialValue: StoreModel(app.session.person(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            Group {
                if state.settled {
                    page(model, state)
                } else {
                    // Nothing laid out until the details and the titles are in: the page shows whole, where it stays.
                    LoadingStateView().accessibilityIdentifier("person.loading")
                }
            }
            .pageTitle(state.name, inContent: true)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("person.screen")
            .task { await model.state.observe() }
        }
    }

    private func page(_ model: StoreModel<PersonStore, PersonUiState>, _ state: PersonUiState) -> some View {
        let appearance = app.appearance.state
        return GeometryReader { proxy in
            let unit = dimens.unit
            let tv = appearance.tv
            let sides = screenSides.leading
            let width = proxy.size.width - 2 * sides
            let cells = dimens.grid(width: width, shape: .poster, appearance: appearance)
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16 * unit) {
                    PersonHeader(image: state.image, name: state.name, subtitle: state.characterName, id: "person")
                    if !state.facts.isEmpty {
                        DetailInformation(rows: state.facts)
                    }
                    if let biography = state.biography {
                        DetailOverview(text: biography, id: "person.biography")
                    }
                    if let count = state.titleCount {
                        Text(count)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Palette.onBackground)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("person.count")
                    }
                    PagedGrid(
                        grid: state.grid, shape: .poster, cells: cells, emptyMessage: T.shared.discover.noContentAvailable,
                        caption: !(tv && appearance.tvFullCardLayout),
                        onOpen: { card in if let route = model.store.routeFor(cardId: card.id) { app.navigator.navigate(route: route) } },
                        onMenu: { card in
                            if let item = model.store.item(cardId: card.id) {
                                app.session.mediaActions.menu.open(
                                    item: item,
                                    place: MenuPlace(continueWatching: false, collectionId: nil, seriesId: nil, albumId: nil, artistId: nil),
                                    extras: [],
                                    playTrailer: nil,
                                    onRow: []
                                )
                            }
                        },
                        onReach: { model.store.ensureLoaded(index: Int32($0)) },
                        onRetry: model.store.retry
                    )
                }
                .padding(.horizontal, sides)
                .padding(.vertical, dimens.sectionSpacing)
            }
            .scrollIndicators(.hidden)
            .personTitleBar(state.name, top: proxy.safeAreaInsets.top)
        }
    }
}

/// A person page's header: their round portrait beside their name and `subtitle` (the character they played, what they
/// are known for). Identifiers `<id>.header` and `<id>.name`.
struct PersonHeader: View {
    let image: Artwork?
    let name: String
    let subtitle: String?
    let id: String

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        HStack(spacing: 16 * unit) {
            ZStack {
                Palette.surfaceContainerHighest
                RemoteImage(artwork: image) { failed in
                    if failed { ArtworkPlaceholder(kind: .person) }
                }
            }
            .frame(width: 80 * unit, height: 80 * unit)
            .clipShape(Circle())
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4 * unit) {
                PageHeading(title: name, id: "\(id).name")
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.onSurfaceVariant)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(iOS)
        .anchorPreference(key: DetailTitleFrame.self, value: .bounds) { $0 }
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(id).header")
    }
}

extension View {
    /// On iOS, Detail's title bar (`DetailTitleBar`) behind the navigation bar's buttons, `top` tall, once the page's
    /// header (`PersonHeader`) starts going under them: Back sits over the portrait's corner, so the bar's material comes
    /// with the first points the page scrolls, and its title as the name goes under it. Elsewhere the page as it is.
    @ViewBuilder
    func personTitleBar(_ title: String, top: CGFloat) -> some View {
        #if os(iOS)
        overlayPreferenceValue(DetailTitleFrame.self) { anchor in
            GeometryReader { overlay in
                let head = anchor.map { overlay[$0].minY } ?? .infinity
                DetailTitleBar(title: title, height: top, shown: min(max((top - head) / 40, 0), 1))
            }
            .ignoresSafeArea()
        }
        #else
        self
        #endif
    }
}
