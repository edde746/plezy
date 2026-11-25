import SwiftUI
import PlezyKit

/// A person's Seerr page, opened from a Seerr title's cast, laid out as the library's person page (`PersonScreen`):
/// titled with their name in its header, their round portrait beside the name and what they are known for, the facts
/// (born, died, birthplace), the biography (three lines, then More), then "N titles" over the grid of their titles as
/// Explore's catalog cards, Seerr's availability among their badges (`PagedGrid`). A title opens its catalog detail.
/// Until the first load ends (`SeerrPersonUiState.settled`) the spinner alone (`seerrPerson.loading`); a failed load
/// shows its error with Retry under the header. Focus moves through the system's focus engine.
struct SeerrPersonScreen: View {
    let app: AppModel

    @State private var model: StoreModel<SeerrPersonStore, SeerrPersonUiState>?
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var screenSides

    init(app: AppModel, route: RouteSeerrPerson) {
        self.app = app
        _model = State(initialValue: StoreModel(app.session.seerrPerson(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            Group {
                if state.settled {
                    page(model, state)
                } else {
                    LoadingStateView().accessibilityIdentifier("seerrPerson.loading")
                }
            }
            .pageTitle(state.name, inContent: true)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("seerrPerson.screen")
            .task { await model.state.observe() }
        }
    }

    private func page(_ model: StoreModel<SeerrPersonStore, SeerrPersonUiState>, _ state: SeerrPersonUiState) -> some View {
        let appearance = app.appearance.state
        return GeometryReader { proxy in
            let unit = dimens.unit
            let tv = appearance.tv
            let sides = screenSides.leading
            let cells = dimens.grid(width: proxy.size.width - 2 * sides, shape: .poster, appearance: appearance)
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16 * unit) {
                    PersonHeader(image: state.image, name: state.name, subtitle: state.department, id: "seerrPerson")
                    if !state.facts.isEmpty {
                        DetailInformation(rows: state.facts)
                    }
                    if let biography = state.biography {
                        DetailOverview(text: biography, id: "seerrPerson.biography")
                    }
                    if let count = state.titleCount {
                        Text(count)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Palette.onBackground)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("seerrPerson.count")
                    }
                    PagedGrid(
                        grid: state.grid(posterPx: tv ? 500 : 360), shape: .poster, cells: cells,
                        emptyMessage: T.shared.discover.noContentAvailable, caption: !(tv && appearance.tvFullCardLayout),
                        onOpen: { card in if let route = model.store.routeFor(cardId: card.id) { app.navigator.navigate(route: route) } },
                        onReach: { _ in },
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
