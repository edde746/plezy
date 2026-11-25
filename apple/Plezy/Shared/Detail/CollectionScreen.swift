import SwiftUI
import PlezyKit

/// A collection's screen (`CollectionStore`), titled in its header (on iOS not in the navigation bar,
/// `titleInContent`): its backgrounds in turn behind the top where it has any (`Backdrop`), its poster
/// beside (on a phone above) the title, the meta line ("12 items · 1999–2021 · PG-13"), the summary (three lines, then More), Play and
/// Shuffle, then the paged grid of its items (square for music; each card telling VoiceOver its row and column). An item
/// opens its screen; its menu offers Remove from collection. Play and Shuffle show the loading dialog while the queue
/// loads; the store's messages show as toasts. Opened from a downloads folder (`CollectionUiState.offline`) it lists the
/// downloaded titles with their local artwork, has no item menus, and offers Mark as watched or unwatched and Delete
/// downloads (asked first; once deleted the screen goes back). Until the collection and its first page of items are in
/// (`CollectionUiState.settled`) the screen shows its spinner alone (`collection.loading`).
struct CollectionScreen: View {
    let app: AppModel
    private let route: RouteCollectionDetail
    private let collectionId: String

    @State private var model: StoreModel<CollectionStore, CollectionUiState>?
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var screenSides

    init(app: AppModel, route: RouteCollectionDetail) {
        self.app = app
        self.route = route
        collectionId = route.collectionId
        _model = State(initialValue: StoreModel(app.session.collection(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            Group {
                if state.settled {
                    page(model, state)
                } else {
                    // Nothing laid out until the collection and its first items are in: the page shows whole.
                    LoadingStateView().accessibilityIdentifier("collection.loading")
                }
            }
            .pageTitle(state.title, inContent: true)
            .toast(state.message, id: "collection.message", onShown: model.store.messageShown)
            .confirmation(
                state.offline?.confirmingDelete == true
                    ? Confirmation(
                        title: T.shared.downloads.deleteCollectionDownloadsConfirm(title: state.title), message: "",
                        confirmLabel: T.shared.downloads.deleteCollectionDownloads, cancelLabel: T.shared.common.cancel,
                        confirmId: "collection.offline.delete.confirm", cancelId: "collection.offline.delete.cancel"
                    )
                    : nil,
                onConfirm: { model.store.confirmDelete(confirmed: true) },
                onCancel: { model.store.confirmDelete(confirmed: false) }
            )
            // Its downloads deleted, the folder is gone: back to where it was opened from.
            .leavesWhenGone(state.gone, route: route, app: app)
            // While a play queue loads: its title, a spinner and Cancel.
            .progressSheet(
                state.launching, isPresented: state.launching != nil, id: "launching.dialog",
                cancel: SheetAction(title: T.shared.common.cancel, id: "launching.cancel", action: model.store.cancelLaunch)
            ) {
                ProgressView().largeSpinner()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("collection.screen")
            .task { await model.state.observe() }
        }
    }

    private func page(_ model: StoreModel<CollectionStore, CollectionUiState>, _ state: CollectionUiState) -> some View {
        let appearance = app.appearance.state
        return GeometryReader { proxy in
            let unit = dimens.unit
            let tv = appearance.tv
            let sides = screenSides.leading
            let width = proxy.size.width - 2 * sides
            let shape: CardShape_ = state.square ? .square : .poster
            let cells = dimens.grid(width: width, shape: shape, appearance: appearance)
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20 * unit) {
                    CollectionHeader(state: state, compact: !tv && width < 600, onPlay: model.store.play, onShuffle: model.store.shuffle)
                    if let offline = state.offline, !state.grid.items.isEmpty {
                        // A downloads folder: its downloaded titles' marks and their deletion from the device. Side by
                        // side where both labels fit whole, else one over the other across the page.
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12 * unit) { offlineActions(offline, model, fullWidth: false) }
                            VStack(spacing: 12 * unit) { offlineActions(offline, model, fullWidth: true) }
                        }
                        .glassGroup(spacing: 12 * unit)
                    }
                    PagedGrid(
                        grid: state.grid, shape: shape, cells: cells, emptyMessage: T.shared.collections.empty,
                        caption: !(tv && appearance.tvFullCardLayout),
                        onOpen: { card in if let route = model.store.routeFor(cardId: card.id) { app.navigator.navigate(route: route) } },
                        // Inside the collection, an item's menu offers Remove from collection.
                        onMenu: { card in
                            if let item = model.store.item(cardId: card.id) {
                                app.session.mediaActions.menu.open(
                                    item: item,
                                    place: MenuPlace(continueWatching: false, collectionId: collectionId, seriesId: nil, albumId: nil, artistId: nil),
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
        }
        .background(alignment: .top) {
            if !state.backdrops.isEmpty { Backdrop(key: collectionId, backdrops: state.backdrops) }
        }
    }

    @ViewBuilder
    private func offlineActions(_ offline: OfflineCollectionUi, _ model: StoreModel<CollectionStore, CollectionUiState>, fullWidth: Bool) -> some View {
        ActionButton(
            title: offline.allWatched ? T.shared.mediaMenu.markAsUnwatched : T.shared.mediaMenu.markAsWatched,
            id: "collection.offline.watched",
            systemImage: watchedSymbol(offline.allWatched),
            fullWidth: fullWidth,
            action: model.store.toggleWatched
        )
        ActionButton(
            title: T.shared.downloads.deleteCollectionDownloads, id: "collection.offline.delete",
            prominence: .destructive, systemImage: "trash", fullWidth: fullWidth, action: model.store.deleteDownloads
        )
    }
}

private struct CollectionHeader: View {
    let state: CollectionUiState
    let compact: Bool
    let onPlay: () -> Void
    let onShuffle: () -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        let layout = compact ? AnyLayout(VStackLayout(spacing: 16 * unit)) : AnyLayout(HStackLayout(alignment: .top, spacing: 24 * unit))
        layout {
            ZStack {
                Palette.surfaceContainerHighest
                RemoteImage(artwork: state.poster) { failed in
                    if failed { ArtworkPlaceholder(kind: .collection) }
                }
            }
            .frame(width: 140 * unit, height: (state.square ? 140 : 210) * unit)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small * unit, style: .continuous))
            .accessibilityHidden(true)
            VStack(alignment: compact ? .center : .leading, spacing: 8 * unit) {
                PageHeading(title: state.title, id: "collection.title")
                    .multilineTextAlignment(compact ? .center : .leading)
                if let meta = state.metaLine {
                    Text(meta)
                        .font(.subheadline)
                        .foregroundStyle(Palette.onSurfaceVariant)
                }
                if let summary = state.summary {
                    DetailOverview(text: summary, id: "collection.summary")
                }
                if state.canPlay {
                    ActionRow(spacing: 12 * unit) {
                        ActionButton(
                            title: T.shared.common.play, id: "collection.play", prominence: .primary, systemImage: "play.fill",
                            fullWidth: false, action: onPlay
                        )
                        IconButton(systemImage: "shuffle", label: T.shared.common.shuffle, id: "collection.shuffle", action: onShuffle)
                    }
                    .padding(.top, 4 * unit)
                }
            }
            .frame(maxWidth: compact ? .infinity : nil, alignment: compact ? .center : .leading)
        }
        .frame(maxWidth: .infinity, alignment: compact ? .center : .leading)
    }
}
