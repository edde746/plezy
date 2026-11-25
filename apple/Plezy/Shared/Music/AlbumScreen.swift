import SwiftUI
import PlezyKit

/// An album (`AlbumStore`): its header (cover, title, the artist that opens the artist, "year · N tracks · length")
/// with Play, Shuffle, Instant Mix and the album's ⋯, then its tracks as rows ("Disc N" over each disc's on
/// a multi-disc album). A row plays the album from it; the current track's row shows the equalizer.
struct AlbumScreen: View {
    let app: AppModel
    let route: RouteMusicAlbum

    @State private var model: StoreModel<AlbumStore, AlbumUiState>?

    init(app: AppModel, route: RouteMusicAlbum) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.musicAlbum(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            let menu = app.session.mediaActions.menu
            MusicDetailScroll(title: state.header?.title ?? "", identifier: "music.album", loading: state.load == .loading) { width, height in
                VStack(alignment: .leading, spacing: 8) {
                    if let header = state.header {
                        MusicDetailHeader(header: header, width: width, onArtist: store.openArtist) {
                            MusicActions(
                                onPlay: store.play, onShuffle: store.shuffle,
                                onInstantMix: state.instantMix ? store.instantMix : nil,
                                onMenu: { extras, onRow in
                                    guard let item = store.item else { return }
                                    menu.open(item: item, place: store.menuPlace, extras: extras, playTrailer: nil, onRow: onRow)
                                },
                                menuProbe: "music.album.more",
                                extrasOnRow: Self.downloadOnRow(state)
                            ) {
                                #if !os(tvOS)
                                if let download = state.download {
                                    DetailDownloadButton(spec: download, onPress: store.download)
                                }
                                #endif
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    if state.load == .content {
                        AlbumTracks(store: store, state: state, menu: menu)
                    } else {
                        MusicLoadState(load: state.load, error: state.error, onRetry: store.retry)
                    }
                }
            }
            .task { await model.state.observe() }
        }
    }

    /// The album's download button on the row (not on Apple TV), whose entries its ⋯ leaves out.
    private static func downloadOnRow(_ state: AlbumUiState) -> Set<RowAction> {
        #if os(tvOS)
        []
        #else
        state.download != nil ? [.download] : []
        #endif
    }
}

private struct AlbumTracks: View {
    let store: AlbumStore
    let state: AlbumUiState
    let menu: MediaMenu

    var body: some View {
        LazyVStack(spacing: 2) {
            ForEach(Array(state.rows.enumerated()), id: \.offset) { _, row in
                switch onEnum(of: row) {
                case .discHeader(let header):
                    Text(header.label)
                        .font(.headline)
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.top, 16)
                        .padding(.bottom, 4)
                        .accessibilityAddTraits(.isHeader)
                case .track(let track):
                    let row = track.row
                    let index = Int(row.index)
                    TrackRow(
                        title: row.title, subtitle: row.subtitle, number: row.trackNumber, duration: row.duration,
                        isCurrent: row.globalKey == state.playingKey, playing: state.playing,
                        onMenu: {
                            guard let item = store.track(index: Int32(index)) else { return }
                            menu.open(item: item, place: store.menuPlace, extras: [], playTrailer: nil, onRow: [])
                        },
                        id: "music.track.\(index)"
                    ) { store.playFrom(index: Int32(index)) }
                }
            }
        }
    }
}
