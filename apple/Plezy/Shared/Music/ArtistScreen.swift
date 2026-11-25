import SwiftUI
import PlezyKit

/// An artist (`ArtistStore`): the circular portrait, name, genres and bio with Play, Shuffle and Instant Mix, then the
/// discography as square album cards: one grid, or titled sections (Albums, Singles & EPs, Live, Compilations). A card
/// opens its album; its long press, right click or long Select the album's item menu (the shared `MediaMenu`).
struct ArtistScreen: View {
    let app: AppModel
    let route: RouteMusicArtist

    @State private var model: StoreModel<ArtistStore, ArtistUiState>?
    @Environment(\.dimens) private var dimens

    init(app: AppModel, route: RouteMusicArtist) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.musicArtist(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            let appearance = app.appearance.state
            MusicDetailScroll(title: state.header?.title ?? "", identifier: "music.artist", loading: state.load == .loading) { width, height in
                let unit = dimens.unit
                VStack(alignment: .leading, spacing: 12 * unit) {
                    if let header = state.header {
                        MusicDetailHeader(
                            header: header, width: width, placeholder: .artist, compactArtwork: 140, wideAlignment: .center
                        ) {
                            MusicActions(onPlay: store.play, onShuffle: store.shuffle, onInstantMix: state.instantMix ? store.instantMix : nil)
                        }
                        .padding(.bottom, 8 * unit)
                    }
                    if state.load == .content {
                        let grid = dimens.grid(width: width, shape: .square, appearance: appearance)
                        ForEach(Array(state.sections.enumerated()), id: \.offset) { _, section in
                            if let title = section.title {
                                Text(title)
                                    .font(.title2.bold())
                                    .foregroundStyle(Palette.onBackground)
                                    .accessibilityAddTraits(.isHeader)
                                    .padding(.top, 8 * unit)
                            }
                            MediaGrid(
                                items: section.cards, shape: .square, cells: grid,
                                onOpen: { store.open(cardId: $0.id) },
                                onMenu: { card in
                                    guard let item = store.card(cardId: card.id) else { return }
                                    app.session.mediaActions.menu.open(item: item, place: store.menuPlace, extras: [], playTrailer: nil, onRow: [])
                                }
                            )
                        }
                    } else {
                        MusicLoadState(load: state.load, error: state.error, onRetry: store.retry)
                    }
                }
            }
            .task { await model.state.observe() }
        }
    }
}
