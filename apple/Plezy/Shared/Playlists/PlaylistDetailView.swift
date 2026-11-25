import SwiftUI
import PlezyKit

/// A playlist (`Route.PlaylistDetail`), titled in the navigation bar: "Smart Playlist" for a smart one, its action row
/// (`ActionRow`: Play, the cast button (`CastButton`), Shuffle with its label, Delete; where the row has no room Shuffle
/// round, then Shuffle and Delete behind ⋯, as the music pages' `MusicActions`), then its entries. A smart playlist is a
/// read-only grid whose cards play the playlist from themselves. Another is a
/// list of rows: the row plays from itself and its menu (a long press, a right click) is the item's.
/// Edit (`playlist.edit`, offered while the playlist can be edited) reorders and removes rows, each change shown at
/// once, the rows' menus off: on iPhone and iPad the list's own Edit mode (the bar's Edit and Done, the rows' grips and
/// minus); on the Mac Edit and Done in the toolbar, a handle per row dragged onto another row (`TrackDragHandle`) and a
/// ✕; on Apple TV Edit and Done in the action row, a ✕ per row and a handle that starts move mode (Up and Down move the
/// row, the handle again saves, Back puts it back). Back (Escape on the Mac) leaves move mode, then Edit mode. Focus
/// starts on the first row's entry (on Apple TV on Play, as on Compose TV). Identifiers as the Compose screen's: `playlist`,
/// `playlist.<play|cast|shuffle|delete|more|edit|retry>`, `playlist.row.<i>[.handle|.remove]`. While the playlist
/// loads, its spinner alone (`playlist.loading`).
struct PlaylistDetailView: View {
    let app: AppModel
    let route: RoutePlaylistDetail

    @State private var model: StoreModel<PlaylistDetailStore, PlaylistDetailState>?
    /// The focused row's entry, by row key.
    @FocusState private var focus: String?
    /// The first row has had its first focus.
    @State private var firstFocused = false
    @Environment(\.dimens) private var dimens
    @Environment(\.formFactor) private var formFactor
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    #endif

    init(app: AppModel, route: RoutePlaylistDetail) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.playlistDetail(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let store = model.store
            Group {
                if state.loading {
                    // Nothing laid out until the playlist is in: its actions and rows show whole.
                    LoadingStateView().accessibilityIdentifier("playlist.loading")
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        header(state, store)
                            .padding(.horizontal, dimens.screenPadding)
                            .padding(.bottom, 8)
                            // Move mode leaves the moving row's handle alone to focus: Up and Down move the row.
                            .disabled(state.moving != nil)
                        content(state, store)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if state.loadingMore {
                    ProgressView().padding(24)
                } else if state.moreError != nil {
                    Button(T.shared.common.retry, action: store.retryMore)
                        .buttonProminence(.primary)
                        .padding(16)
                        .accessibilityIdentifier("playlist.retry")
                }
            }
            #if !os(tvOS)
            .toolbar { editToolbar(state, store) }
            #endif
            #if os(iOS)
            .environment(\.editMode, $editMode)
            .onChange(of: editMode) { _, mode in store.edit(on: mode.isEditing) }
            // The store leaves Edit mode itself when the playlist can't be changed any more (offline, a change on its way).
            .onChange(of: state.editing) { _, editing in
                if !editing { editMode = .inactive }
            }
            #endif
            .backAction(backAction(state, store))
            #if os(tvOS)
            // The playlist comes after the screen: Play takes focus as it arrives (the first row where there is no
            // Play), once, as on Compose TV. Not a default focus, which would follow the first row as move mode moves it
            // and drop the moving handle's focus.
            .task(id: state.rows.first?.key) {
                guard !firstFocused, let first = state.rows.first?.key else { return }
                firstFocused = true
                await FocusRestore.restore($focus, to: state.canPlay ? Self.playKey : first)
            }
            #else
            .defaultFocus($focus, state.rows.first?.key)
            #endif
            .pageTitle(state.title)
            .castInTopBar(id: "playlist.cast")
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("playlist")
            .task { await model.state.observe() }
        }
    }

    /// Back (the remote's Menu, Escape): move mode puts its row back, then Edit mode ends; nil leaves the screen.
    private func backAction(_ state: PlaylistDetailState, _ store: PlaylistDetailStore) -> (() -> Void)? {
        if state.moving != nil { return { _ = store.cancelMove() } }
        if state.editing { return { setEditing(false, store) } }
        return nil
    }

    #if !os(tvOS)
    /// Edit and Done in the bar: `PlaylistEditButton` on iPhone and iPad, a button on the Mac (Apple TV's is in
    /// the action row).
    @ToolbarContentBuilder
    private func editToolbar(_ state: PlaylistDetailState, _ store: PlaylistDetailStore) -> some ToolbarContent {
        #if os(iOS)
        if state.editable || editMode.isEditing {
            ToolbarItem(placement: .topBarTrailing) {
                PlaylistEditButton(editMode: $editMode, id: "playlist.edit")
            }
        }
        #elseif os(macOS)
        if state.editable || state.editing {
            // The window toolbar's trailing end, past Back (macOS 26 lines its items up after Back).
            if #available(macOS 26, *) {
                ToolbarSpacer(.flexible)
                ToolbarItem { editToggle(state, store) }
            } else {
                ToolbarItem(placement: .primaryAction) { editToggle(state, store) }
            }
        }
        #endif
    }
    #endif

    #if !os(iOS)
    private func editToggle(_ state: PlaylistDetailState, _ store: PlaylistDetailStore) -> some View {
        #if os(tvOS)
        EditDoneButton(editing: state.editing, id: "playlist.edit", focus: $focus, focusKey: Self.editKey) {
            setEditing(!state.editing, store)
        }
        #else
        Button(state.editing ? T.shared.common.doneEditing : T.shared.common.edit) { store.edit(on: !state.editing) }
            // Escape is Done: with no view focused (keyboard navigation off) the page's own Escape (`backAction`)
            // never runs, and the window's Back would leave the page in Edit mode.
            .keyboardShortcut(state.editing ? .cancelAction : nil)
            .accessibilityIdentifier("playlist.edit")
        #endif
    }
    #endif

    /// Edit mode on or off; on Apple TV focus stays on Edit and Done (the rows' handles and ✕ coming or going would
    /// take it).
    private func setEditing(_ on: Bool, _ store: PlaylistDetailStore) {
        store.edit(on: on)
        #if os(tvOS)
        // Replacing: the row tvOS may hand focus to as the rows' handles appear is one of `focus`'s too.
        Task { await FocusRestore.restore($focus, to: Self.editKey, replacing: true) }
        #endif
    }

    #if os(tvOS)
    /// Edit and Done's focus key, beside the rows' keys.
    private static let editKey = "playlist.edit"
    #endif

    /// Play's focus key, beside the rows' keys: Apple TV opens the page on it.
    private static let playKey = "playlist.play"

    /// How much of the action row shows on its own, as the music pages' (`MusicActions`): Shuffle with its label, then
    /// as a round button, then Shuffle and Delete behind ⋯.
    private enum ActionLevel {
        case full, iconShuffle, folded
    }

    private func header(_ state: PlaylistDetailState, _ store: PlaylistDetailStore) -> some View {
        HStack(spacing: 12) {
            if state.canPlay || state.canDelete {
                // The widest row that fits.
                ViewThatFits(in: .horizontal) {
                    actions(state, store, .full)
                    actions(state, store, .iconShuffle)
                    actions(state, store, .folded)
                }
            }
            if state.smart {
                Text(T.shared.playlists.smartPlaylist)
                    .font(.subheadline)
                    .foregroundStyle(Palette.onSurfaceVariant)
            }
        }
        .padding(.vertical, 8)
        .shelfFocusSection()
    }

    private func actions(_ state: PlaylistDetailState, _ store: PlaylistDetailStore, _ level: ActionLevel) -> some View {
        ActionRow(spacing: 12) {
            if state.canPlay {
                ActionButton(
                    title: T.shared.common.play, id: "playlist.play", prominence: .primary, systemImage: "play.fill", fullWidth: false
                ) { store.play(shuffle: false) }
                .focused($focus, equals: Self.playKey)
                if formFactor != .compact {
                    CastButton(look: .detail, id: "playlist.cast")
                }
            }
            if level == .folded {
                #if os(tvOS)
                if state.editable || state.editing {
                    editToggle(state, store)
                }
                #endif
                ActionMenuButton(entries: menu(state, store), probe: "playlist.more")
            } else {
                if state.canPlay {
                    if level == .full {
                        ActionButton(title: T.shared.common.shuffle, id: "playlist.shuffle", systemImage: "shuffle", fullWidth: false) { store.play(shuffle: true) }
                    } else {
                        IconButton(systemImage: "shuffle", label: T.shared.common.shuffle, id: "playlist.shuffle") { store.play(shuffle: true) }
                    }
                }
                // Play, Cast, Shuffle, Edit, Delete: the music playlist page's order.
                #if os(tvOS)
                if state.editable || state.editing {
                    editToggle(state, store)
                }
                #endif
                if state.canDelete {
                    IconButton(systemImage: "trash", label: T.shared.playlists.delete, id: "playlist.delete", action: store.delete)
                        .symbolStyle(Palette.error)
                }
            }
        }
    }

    /// Shuffle and Delete as ⋯'s entries.
    private func menu(_ state: PlaylistDetailState, _ store: PlaylistDetailStore) -> [ItemMenuEntry] {
        var entries: [ItemMenuEntry] = []
        if state.canPlay {
            entries.append(ItemMenuEntry(label: T.shared.common.shuffle, systemImage: "shuffle", id: "playlist.shuffle") { store.play(shuffle: true) })
        }
        if state.canDelete {
            entries.append(ItemMenuEntry(label: T.shared.playlists.delete, systemImage: "trash", id: "playlist.delete", destructive: true, action: store.delete))
        }
        return entries
    }

    @ViewBuilder
    private func content(_ state: PlaylistDetailState, _ store: PlaylistDetailStore) -> some View {
        if let error = state.error {
            ErrorStateView(message: error, onRetry: store.load)
        } else if state.empty {
            EmptyStateView(message: T.shared.playlists.emptyPlaylist, systemImage: "list.and.film")
        } else if state.smart {
            SmartPlaylistGrid(app: app, state: state, store: store)
        } else {
            #if os(iOS)
            PlaylistRows(rows: state.rows, editing: editMode.isEditing, moving: nil, store: store, focus: $focus)
            #else
            PlaylistRows(rows: state.rows, editing: state.editing, moving: state.moving?.intValue, store: store, focus: $focus)
            #endif
        }
    }
}

/// A smart playlist's entries as the library grid lays its cards out: a card plays the playlist from itself.
private struct SmartPlaylistGrid: View {
    let app: AppModel
    let state: PlaylistDetailState
    let store: PlaylistDetailStore

    @Environment(\.dimens) private var dimens

    var body: some View {
        let cards = state.rows.map(\.card)
        let appearance = app.appearance.state
        GeometryReader { proxy in
            let shape = state.audio
                ? CardShape_.square
                : TvLayoutKt.hubShape(items: cards.map { $0.shape }, episodeThumbnails: appearance.episodeThumbnails)
            let grid = dimens.grid(width: proxy.size.width - 2 * dimens.screenPadding, shape: shape, appearance: appearance)
            ScrollView(.vertical) {
                MediaGrid(
                    items: cards, shape: shape, cells: grid,
                    onOpen: { card in cards.firstIndex(of: card).map { store.playFrom(index: Int32($0)) } },
                    onMenu: { card in cards.firstIndex(of: card).map { store.openMenu(index: Int32($0)) } }
                )
                .padding(.horizontal, dimens.screenPadding)
                .padding(.bottom, 72)
            }
        }
    }
}

/// A playlist's rows. iPhone and iPad: a list, whose Edit mode reorders (its grips) and removes (its minus or a swipe)
/// rows. The Mac: a row dragged by its handle onto another row takes its place. Apple TV: the focus engine keeps move
/// mode's focused handle in view.
private struct PlaylistRows: View {
    let rows: [PlaylistRow]
    let editing: Bool
    let moving: Int?
    let store: PlaylistDetailStore
    let focus: FocusState<String?>.Binding

    var body: some View {
        #if os(iOS)
        List {
            ForEach(Array(rows.enumerated()), id: \.element.key) { index, row in
                rowView(row, index)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            // Edit mode's alone: outside it a long press opens the item's menu and a swipe scrolls.
            .onMove(perform: editing ? { from, to in
                guard let source = from.first else { return }
                // `to` counts the row's own slot: a move down lands one before it.
                store.move(from: Int32(source), to: Int32(to > source ? to - 1 : to))
            } : nil)
            .onDelete(perform: editing ? { offsets in
                // One row at a time: a swipe or a minus.
                if let index = offsets.first { store.remove(index: Int32(index)) }
            } : nil)
            Color.clear.frame(height: 72)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        #else
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.key) { index, row in
                    rowView(row, index)
                        #if os(macOS)
                        // A row dragged by its handle onto this one takes its place.
                        .dropDestination(for: String.self) { keys, _ in
                            guard editing, let key = keys.first, let from = rows.firstIndex(where: { $0.key == key }),
                                  from != index else { return false }
                            store.move(from: Int32(from), to: Int32(index))
                            return true
                        }
                        #endif
                        .id(row.key)
                }
            }
            .padding(.bottom, 72)
            .animation(.easeOut(duration: 0.2), value: rows.map(\.key))
        }
        .shelfFocusSection()
        #endif
    }

    private func rowView(_ row: PlaylistRow, _ index: Int) -> some View {
        PlaylistRowView(
            row: row, index: index, editing: editing, moving: moving == index, moveMode: moving != nil, store: store, focus: focus,
            onRemove: { remove(index) }
        )
    }

    /// Removes the row at `index`; focus goes to the row that takes its place (the one before it at the end), not lost
    /// with its ✕.
    private func remove(_ index: Int) {
        let next = rows.indices.contains(index + 1) ? rows[index + 1].key : index > 0 ? rows[index - 1].key : nil
        store.remove(index: Int32(index))
        Task { await FocusRestore.restore(focus, to: next) }
    }
}

/// One entry: in Edit mode the handle (swap arrows in move mode; iPhone and iPad use the list's grip), the artwork
/// (square for a track), the title over its subtitle, the length, then in Edit mode ✕ (iPhone and iPad: the list's
/// minus); no card, a free-flowing row as an episode's. On Apple TV the length is inside the row's button, in its focus
/// highlight; elsewhere it sits beside the button. On iPhone and iPad a long press's menu lifts the artwork alone. Edit
/// mode turns the row's menu off. Move mode tints the row and rings it in the accent, and leaves only its handle to
/// focus.
private struct PlaylistRowView: View {
    let row: PlaylistRow
    let index: Int
    let editing: Bool
    let moving: Bool
    let moveMode: Bool
    let store: PlaylistDetailStore
    let focus: FocusState<String?>.Binding
    let onRemove: () -> Void

    @Environment(\.dimens) private var dimens
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        let unit = dimens.unit
        let shape = RoundedRectangle(cornerRadius: 12 * unit, style: .continuous)
        HStack(spacing: 8 * unit) {
            #if os(macOS)
            if editing {
                TrackDragHandle(key: row.key, id: "playlist.row.\(index).handle")
            }
            #elseif os(tvOS)
            if editing {
                MoveModeHandle(
                    title: row.card.title, id: "playlist.row.\(index).handle", moving: moving, moveMode: moveMode,
                    onSelect: { if moving { store.confirmMove() } else { store.startMove(index: Int32(index)) } },
                    onStep: { _ = store.step(delta: $0) }
                )
            }
            #endif
            Button(action: { store.playFrom(index: Int32(index)) }) {
                HStack(spacing: 12 * unit) {
                    CardArtwork(card: row.card, size: CGSize(width: 60 * unit, height: (row.square ? 60 : 90) * unit))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * unit, style: .continuous))
                    VStack(alignment: .leading, spacing: 2 * unit) {
                        Text(row.card.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(row.subtitle)
                            .font(.caption)
                            .mutedForeground()
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    #if os(tvOS)
                    duration(row, index)
                    #endif
                }
                .padding(4 * unit)
                .contentShape(Rectangle())
                #if os(iOS)
                // The long press's menu lifts the artwork alone, as an episode row's (`DetailEpisodeRow`).
                .overlay {
                    let size = CGSize(width: 60 * unit, height: (row.square ? 60 : 90) * unit)
                    CardArtwork(card: row.card, size: size)
                        .clipShape(RoundedRectangle(cornerRadius: 6 * unit, style: .continuous))
                        .padding(4 * unit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .contentShape(.interaction, Rectangle())
                        .contentShape(
                            .contextMenuPreview,
                            LeadingThumbnailShape(inset: 4 * unit, size: size, radius: 6 * unit, rightToLeft: layoutDirection == .rightToLeft)
                        )
                        .mediaMenuTrigger(editing ? nil : { store.openMenu(index: Int32(index)) }, item: row)
                }
                #endif
            }
            .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: 8 * unit))
            .disabled(moveMode)
            .focused(focus, equals: row.key)
            #if !os(iOS)
            .mediaMenuTrigger(editing ? nil : { store.openMenu(index: Int32(index)) }, item: row)
            #endif
            .accessibilityElement(children: .ignore)
            #if os(tvOS)
            // The length is inside the button there, so its label says it.
            .accessibilityLabel(([row.card.title, row.subtitle] + (row.duration.map { [$0] } ?? [])).joined(separator: ", "))
            #else
            .accessibilityLabel("\(row.card.title), \(row.subtitle)")
            #endif
            .accessibilityValue(row.card.accessibilityState)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("playlist.row.\(index)")
            #if !os(tvOS)
            duration(row, index)
            #endif
            #if !os(iOS)
            if editing, !moveMode {
                RowRemoveButton(label: T.shared.playlists.removeItem, id: "playlist.row.\(index).remove", action: onRemove)
            }
            #endif
        }
        #if os(tvOS)
        // The row's height for the handle (`MoveModeHandle`), which fills it.
        .fixedSize(horizontal: false, vertical: true)
        #endif
        .padding(8 * unit)
        .background(moving ? Palette.primary.opacity(0.2) : .clear, in: shape)
        .overlay {
            if moving { shape.strokeBorder(Palette.primary, lineWidth: 2.5) }
        }
        .padding(.horizontal, 8 * unit)
        .padding(.vertical, 4 * unit)
    }

    @ViewBuilder
    private func duration(_ row: PlaylistRow, _ index: Int) -> some View {
        if let duration = row.duration {
            Text(duration)
                .font(.caption)
                .mutedForeground()
                .fixedSize()
                .accessibilityIdentifier("playlist.row.\(index).duration")
        }
    }
}
