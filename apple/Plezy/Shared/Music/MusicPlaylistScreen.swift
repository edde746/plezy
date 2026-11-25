import SwiftUI
import PlezyKit

/// An audio playlist (`MusicPlaylistStore`): its header with Play, Shuffle, its download actions (Download, or Manage
/// and Remove its sync rule; none on Apple TV or offline) and ⋯ with Delete Playlist (`music.playlist.delete`, which
/// asks first; a regular playlist of a connected server), then its tracks as rows, each led by its artwork (the
/// equalizer over the current one's) with "Artist · Album" under its title. A row plays the playlist from it; its ⋯ (a
/// long press, a right click) opens the track's item menu.
/// Edit (`music.playlist.edit`, offered while the playlist can be edited) reorders and removes rows, each change shown
/// at once: on iPhone and iPad the list's own Edit mode (the bar's Edit and Done, the rows' grips and minus); on the
/// Mac Edit and Done in the toolbar, a handle per row dragged onto another row (`TrackDragHandle`) and a ×; on Apple TV
/// Edit and Done in the header's row, keeping focus as they switch, a × per row and a handle that starts move mode (Up
/// and Down move the row, the handle again saves, Back puts it back). Back (Escape on the Mac) leaves Edit mode, on
/// Apple TV focus back on Edit. Rows are `music.track.<i>`, their
/// handles and × `music.track.<i>.handle` and `.remove`.
struct MusicPlaylistScreen: View {
    let app: AppModel
    let route: RouteMusicPlaylist

    @State private var model: StoreModel<MusicPlaylistStore, MusicPlaylistUiState>?
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var screenSides
    #endif
    #if os(tvOS)
    /// The focused row, by key: a removed row's focus goes to the row taking its place.
    @FocusState private var focus: String?
    /// Play has had the page's first focus.
    @State private var openedOnPlay = false
    #endif

    init(app: AppModel, route: RouteMusicPlaylist) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.musicPlaylist(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            page(model.state.state, model.store)
                .task { await model.state.observe() }
        }
    }

    #if os(iOS)
    /// A list rather than `MusicDetailScroll`'s stack, the header its first row: the list's Edit mode reorders and
    /// removes the rows, the header staying where it is.
    private func page(_ state: MusicPlaylistUiState, _ store: MusicPlaylistStore) -> some View {
        Group {
            if state.load == .loading {
                LoadingStateView().accessibilityIdentifier("music.loading")
            } else {
                GeometryReader { proxy in
                    let sides = max(screenSides.leading, dimens.screenPadding)
                    List {
                        if let header = state.header {
                            self.header(header, state, store, width: proxy.size.width - 2 * sides)
                                .listRowInsets(EdgeInsets(top: 8, leading: sides, bottom: 16, trailing: sides))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        if state.load == .content {
                            ForEach(state.rows, id: \.key) { row in
                                trackRow(row, state, store, editing: editMode.isEditing)
                                    .listRowInsets(EdgeInsets(top: 1, leading: sides, bottom: 1, trailing: sides))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            // Edit mode's alone: outside it a long press opens the track's menu and a swipe scrolls.
                            .onMove(perform: editMode.isEditing ? { from, to in
                                guard let source = from.first else { return }
                                // `to` counts the row's own slot: a move down lands one before it.
                                store.move(from: Int32(source), to: Int32(to > source ? to - 1 : to))
                            } : nil)
                            .onDelete(perform: editMode.isEditing ? { offsets in
                                // One row at a time: a swipe or a minus.
                                if let index = offsets.first { store.remove(index: Int32(index)) }
                            } : nil)
                        } else {
                            MusicLoadState(load: state.load, error: state.error, onRetry: store.retry)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(state.header?.title ?? "")
        .inlineNavigationTitle()
        .titleInContent()
        .castInTopBar(id: "music.cast")
        .toolbar {
            if state.editable || editMode.isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    PlaylistEditButton(editMode: $editMode, id: "music.playlist.edit")
                }
            }
        }
        .environment(\.editMode, $editMode)
        .onChange(of: editMode) { _, mode in store.edit(on: mode.isEditing) }
        // The store leaves Edit mode itself when the playlist can't be changed any more (offline).
        .onChange(of: state.editing) { _, editing in
            if !editing { editMode = .inactive }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("music.playlist")
    }
    #else
    private func page(_ state: MusicPlaylistUiState, _ store: MusicPlaylistStore) -> some View {
        let moving = state.moving?.intValue
        return MusicDetailScroll(title: state.header?.title ?? "", identifier: "music.playlist", loading: state.load == .loading) { width, _ in
            VStack(alignment: .leading, spacing: 8) {
                if let header = state.header {
                    self.header(header, state, store, width: width)
                        .padding(.bottom, 8)
                        // Move mode leaves the moving row's handle alone to focus: Up and Down move the row.
                        .disabled(moving != nil)
                }
                if state.load == .content {
                    ScrollViewReader { reader in
                        LazyVStack(spacing: 2) {
                            ForEach(state.rows, id: \.key) { row in
                                editableRow(row, state, store, moving: moving)
                                    .id(row.key)
                            }
                        }
                        .onChange(of: moving) { _, index in
                            if let index, state.rows.indices.contains(index) {
                                withAnimation { reader.scrollTo(state.rows[index].key, anchor: .center) }
                            }
                        }
                    }
                } else {
                    MusicLoadState(load: state.load, error: state.error, onRetry: store.retry)
                }
            }
        }
        #if os(macOS)
        .toolbar {
            if state.editable || state.editing {
                // The window toolbar's trailing end, past Back (macOS 26 lines its items up after Back).
                if #available(macOS 26, *) {
                    ToolbarSpacer(.flexible)
                    ToolbarItem { editToggle(state, store) }
                } else {
                    ToolbarItem(placement: .primaryAction) { editToggle(state, store) }
                }
            }
        }
        #endif
        .backAction(backAction(state, store))
        #if os(tvOS)
        // The header comes after the screen: Play takes focus as it arrives, once.
        .task(id: state.header != nil) {
            guard !openedOnPlay, state.header != nil else { return }
            openedOnPlay = true
            await FocusRestore.restore($focus, to: Self.playKey)
        }
        #endif
    }

    /// Back (the remote's Menu, Escape): move mode puts its row back, then Edit mode ends; nil leaves the screen.
    private func backAction(_ state: MusicPlaylistUiState, _ store: MusicPlaylistStore) -> (() -> Void)? {
        if state.moving != nil { return { _ = store.cancelMove() } }
        #if os(tvOS)
        if state.editing { return { setEditing(false, store) } }
        #else
        if state.editing { return { store.edit(on: false) } }
        #endif
        return nil
    }

    #if os(macOS)
    private func editToggle(_ state: MusicPlaylistUiState, _ store: MusicPlaylistStore) -> some View {
        Button(state.editing ? T.shared.common.doneEditing : T.shared.common.edit) { store.edit(on: !state.editing) }
            // Escape is Done: with no view focused (keyboard navigation off) the page's own Escape (`backAction`)
            // never runs, and the window's Back would leave the page in Edit mode.
            .keyboardShortcut(state.editing ? .cancelAction : nil)
            .accessibilityIdentifier("music.playlist.edit")
    }
    #endif

    /// A row with Edit mode's handle before it: dragged onto another row (the Mac), or selected for move mode (Apple
    /// TV), the moving row tinted and ringed in the accent.
    private func editableRow(_ row: TrackRowUi, _ state: MusicPlaylistUiState, _ store: MusicPlaylistStore, moving: Int?) -> some View {
        let index = Int(row.index)
        let shape = RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
        return HStack(spacing: 4) {
            if state.editing {
                #if os(macOS)
                TrackDragHandle(key: row.key, id: "music.track.\(index).handle")
                #else
                let isMoving = moving == index
                MoveModeHandle(
                    title: row.title, id: "music.track.\(index).handle", moving: isMoving, moveMode: moving != nil,
                    onSelect: { if isMoving { store.confirmMove() } else { store.startMove(index: Int32(index)) } },
                    onStep: { _ = store.step(delta: $0) }
                )
                #endif
            }
            trackRow(row, state, store, editing: state.editing)
                .disabled(moving != nil)
        }
        #if os(tvOS)
        // The row's height for the handle (`MoveModeHandle`), which fills it.
        .fixedSize(horizontal: false, vertical: true)
        #endif
        .background(moving == index ? Palette.primary.opacity(0.2) : .clear, in: shape)
        .overlay {
            if moving == index { shape.strokeBorder(Palette.primary, lineWidth: 2.5) }
        }
        #if os(macOS)
        // A row dragged by its handle onto this one takes its place.
        .dropDestination(for: String.self) { keys, _ in
            guard state.editing, let key = keys.first, let from = state.rows.firstIndex(where: { $0.key == key }),
                  from != index else { return false }
            store.move(from: Int32(from), to: Int32(index))
            return true
        }
        #endif
    }
    #endif

    private func header(_ header: MusicHeaderUi, _ state: MusicPlaylistUiState, _ store: MusicPlaylistStore, width: CGFloat) -> some View {
        MusicDetailHeader(header: header, width: width, placeholder: .playlist) {
            MusicActions(
                onPlay: store.play, onShuffle: store.shuffle, onInstantMix: nil, menuProbe: "music.playlist.more",
                menuEntries: state.canDelete
                    ? [ItemMenuEntry(label: T.shared.playlists.delete, systemImage: "trash", id: "music.playlist.delete", destructive: true, action: store.delete)]
                    : [],
                playFocus: playFocus
            ) {
                #if os(tvOS)
                if state.editable || state.editing {
                    EditDoneButton(editing: state.editing, id: "music.playlist.edit", focus: $focus, focusKey: Self.editKey) {
                        setEditing(!state.editing, store)
                    }
                }
                #else
                ForEach(state.downloads, id: \.entry.id) { action in
                    IconButton(
                        systemImage: action.button.icon.systemImage,
                        label: action.button.tooltip ?? T.shared.downloads.downloadNow,
                        id: "music.playlist.\(action.entry.id)"
                    ) { store.download(entry: action.entry) }
                    .tint(action.button.tint.color)
                }
                #endif
            }
        }
    }

    #if os(tvOS)
    /// The focus key of Edit and Done.
    private static let editKey = "music.playlist.edit"

    /// Play's focus key: the page opens on Play, as on Compose TV.
    private static let playKey = "music.play"

    private var playFocus: (binding: FocusState<String?>.Binding, key: String)? { ($focus, Self.playKey) }
    #else
    private var playFocus: (binding: FocusState<String?>.Binding, key: String)? { nil }
    #endif

    #if os(tvOS)

    /// Edit mode on or off, focus staying on Edit and Done (the rows' handles and ✕ coming or going would take it).
    private func setEditing(_ on: Bool, _ store: MusicPlaylistStore) {
        store.edit(on: on)
        // Replacing: the row tvOS hands focus to as the rows' handles appear is one of `focus`'s too.
        Task { await FocusRestore.restore($focus, to: Self.editKey, replacing: true) }
    }
    #endif

    /// A track's row; in Edit mode without its menu, and on the Mac and Apple TV with a × in the menu's place.
    private func trackRow(_ row: TrackRowUi, _ state: MusicPlaylistUiState, _ store: MusicPlaylistStore, editing: Bool) -> some View {
        let index = row.index
        #if os(iOS)
        let onRemove: (() -> Void)? = nil
        #else
        let onRemove: (() -> Void)? = editing && state.moving == nil ? { remove(Int(index), state, store) } : nil
        #endif
        #if os(tvOS)
        let focus: (binding: FocusState<String?>.Binding, key: String)? = ($focus, row.key)
        #else
        let focus: (binding: FocusState<String?>.Binding, key: String)? = nil
        #endif
        return TrackRow(
            title: row.title, subtitle: row.subtitle, duration: row.duration,
            isCurrent: row.globalKey == state.playingKey, playing: state.playing,
            showsArtwork: true, artwork: row.artwork,
            onMenu: editing ? nil : {
                guard let item = store.track(index: index) else { return }
                app.session.mediaActions.menu.open(item: item, place: .anywhere, extras: [], playTrailer: nil, onRow: [])
            },
            onRemove: onRemove,
            removeLabel: T.shared.playlists.removeItem,
            focus: focus,
            id: "music.track.\(index)"
        ) { store.playFrom(index: index) }
    }

    #if !os(iOS)
    /// Removes the row at `index`; on Apple TV focus goes to the row that takes its place (the one before it at the
    /// end), not lost with its ×.
    private func remove(_ index: Int, _ state: MusicPlaylistUiState, _ store: MusicPlaylistStore) {
        #if os(tvOS)
        let rows = state.rows
        let next = rows.indices.contains(index + 1) ? rows[index + 1].key : index > 0 ? rows[index - 1].key : nil
        store.remove(index: Int32(index))
        Task { await FocusRestore.restore($focus, to: next) }
        #else
        store.remove(index: Int32(index))
        #endif
    }
    #endif
}
