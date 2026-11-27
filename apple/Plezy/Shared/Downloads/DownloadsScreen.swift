#if !os(tvOS)
import SwiftUI
import PlezyKit

/// Downloads (iPhone, iPad, the Mac; Apple TV keeps no files and shows no Downloads), its own destination, over the
/// session's `DownloadsStore`: the screen's header row (`screenHeader`) of what shows (Manage, TV Shows,
/// Movies, Music) and on a content tab its grouping,
/// sort (the field picked again turns its direction around; Clear) and Filters (a form: `DownloadsFiltersSheet`); its
/// actions Retry failed (while a download failed) and Sync rules, titled. Then the selected tab: Manage's tree, a list
/// whose rows' actions are in their ⋯, their context menu and on iOS their swipes (`DownloadTreeView`), or the
/// downloaded titles as the grid or list of the View mode setting, in library sections, collection folders (a long
/// press or right click for their menu), albums with their tracks, or tracks; the empty state, with Reset filters while
/// filters hide everything. A movie, show or season opens its detail from the downloads, a collection folder its offline
/// collection screen; an episode plays.
/// Feedback shows as a toast. A controller's shoulder buttons step what shows. The Downloads tab picked again while it
/// shows brings the shown list back to its top (`scrollToTopRequests`).
///
/// Accessibility identifiers: `downloads.screen`, `downloads.tab` (what shows, its options
/// `downloads.tab.option.<i>`),
/// `downloads.grouping`, `downloads.sort`, `downloads.filters`, `downloads.retryFailed`, `downloads.syncRules`,
/// `downloads.items`, the cards `card.<global key>`, `downloads.album.<key>`, `downloads.track.<key>`,
/// `downloads.empty`, `downloads.message`.
struct DownloadsScreen: View {
    let app: AppModel

    @State private var store: DownloadsStore?
    @State private var observer: StoreObserver<DownloadsUiState>?
    @State private var filtering = false
    /// The open tab's options' state, for its filters in the header row.
    @State private var options: StoreObserver<DownloadsOptionsState>?
    /// The times the Downloads tab was picked again while it showed (`PlezyNavigator.reselected`).
    @State private var reselections = 0

    init(app: AppModel) {
        self.app = app
        let store = app.session.downloadsStore()
        _store = State(initialValue: store)
        _observer = State(initialValue: store.map { StoreObserver($0.state) })
    }

    var body: some View {
        if let store, let observer {
            let state = observer.state
            let tab = state.tab
            Group {
                if let tab {
                    DownloadsTabContent(tab: tab, store: store, app: app) { open($0) }
                } else {
                    DownloadTreeView(rows: state.tree, empty: state.emptyTree, onToggle: { store.toggle(key: $0) }, onOpen: { open($0) }) { node, action in
                        store.perform(node: node, action: action)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .screenHeader(titledActions: true) {
                filters(store: store, state: state)
            } actions: {
                if state.retryFailed {
                    Button(action: store.retryFailed) { Label(state.retryFailedLabel, systemImage: "arrow.clockwise") }
                        .accessibilityIdentifier("downloads.retryFailed")
                }
                Button { app.navigator.navigate(route: RouteSyncRules.shared) } label: {
                    Label(state.syncRulesLabel, systemImage: "arrow.triangle.2.circlepath")
                }
                .accessibilityIdentifier("downloads.syncRules")
            }
            #if !os(macOS)
            .appSheet(isPresented: $filtering) {
                if let options = store.options[state.selected] {
                    DownloadsFiltersSheet(store: store, options: options) { filtering = false }
                }
            }
            #endif
            .toast(state.message?.message, id: "downloads.message", isError: state.message?.isError == true, onShown: store.messageShown)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("downloads.screen")
            .gamepadTabs(tabs: { DownloadsTab.allCases }, selected: { observer.state.selected }) { store.select(tab: $0) }
            .task(id: state.selected) {
                guard let tabOptions = store.options[state.selected] else {
                    options = nil
                    return
                }
                let made = StoreObserver(tabOptions.state)
                options = made
                await made.observe()
            }
            .task { await observer.observe() }
            .environment(\.scrollToTopRequests, reselections)
            .task {
                for await destination in app.navigator.reselected where destination == .downloads { reselections += 1 }
            }
        }
    }

    /// What shows, and a content tab's grouping, sort and filters.
    @ViewBuilder
    private func filters(store: DownloadsStore, state: DownloadsUiState) -> some View {
        let tabs = DownloadsTab.allCases
        FilterMenu(
            chip: FilterChip(name: state.title, text: state.selected.label),
            options: tabs.map { FilterOption(label: $0.label, selected: $0 == state.selected) },
            id: "downloads.tab"
        ) { store.select(tab: tabs[$0]) }
        if let tabOptions = store.options[state.selected], let options = options?.state {
            let groupings = state.selected.groupings
            if groupings.count > 1 {
                FilterMenu(
                    chip: FilterChip(name: T.shared.libraries.groupings.title, text: options.grouping.label),
                    options: groupings.map { FilterOption(label: $0.label, selected: $0 == options.grouping) },
                    id: "downloads.grouping"
                ) { tabOptions.selectGrouping(grouping: groupings[$0]) }
            }
            let sorts = tabOptions.sortOptions
            FilterMenu(
                chip: FilterChip(name: T.shared.libraries.sortBy, text: options.sortLabel, narrowed: options.sort != nil),
                symbol: options.sort == nil ? "arrow.up.arrow.down" : options.sortDescending ? "arrow.down" : "arrow.up",
                options: sorts.map { FilterOption(label: $0.title, selected: $0.key == options.sort?.key) }
                    + (options.sort != nil ? [FilterOption(label: T.shared.common.clear, selected: false)] : []),
                id: "downloads.sort"
            ) { index in
                if index < sorts.count { tabOptions.selectSort(sort: sorts[index]) } else { tabOptions.clearSort() }
            }
            FilterButton(
                chip: FilterChip(name: T.shared.libraries.filters, text: options.filtersLabel, narrowed: options.hasActiveFilters),
                symbol: "line.3.horizontal.decrease",
                id: "downloads.filters"
            ) { filtering = true }
            #if os(macOS)
            .popover(isPresented: $filtering, arrowEdge: .bottom) {
                DownloadsFiltersSheet(store: store, options: tabOptions) { filtering = false }
            }
            #endif
        }
    }

    private func open(_ item: MediaItem) {
        switch item.kind {
        case .movie, .show, .season, .collection:
            guard let serverId = item.serverId else { return }
            if item.isDownloadsFolder {
                app.navigator.navigate(route: RouteCollectionDetail(serverId: serverId, collectionId: item.id, offline: true))
            } else {
                app.navigator.navigate(route: RouteMediaDetail(
                    serverId: serverId, itemId: item.id, initialSeasonId: nil, initialEpisodeId: nil, offline: true
                ))
            }
        default:
            _ = app.session.playDownloaded(item: item)
        }
    }
}

/// A content tab's titles (`DownloadsContent`).
private struct DownloadsTabContent: View {
    let tab: DownloadsTabState
    let store: DownloadsStore
    let app: AppModel
    let onOpen: (MediaItem) -> Void

    @Environment(\.screenSides) private var sides

    var body: some View {
        switch onEnum(of: tab.content) {
        case .empty(let empty):
            EmptyStateView(message: empty.description_ ?? empty.title, title: empty.description_ == nil ? nil : empty.title, systemImage: "arrow.down.circle") {
                if let label = empty.actionLabel {
                    Button(label) { store.options[tab.tab]?.resetFilters() }
                        .buttonProminence(.primary)
                        .accessibilityIdentifier("downloads.resetFilters")
                }
            }
            .accessibilityIdentifier("downloads.empty")
        case .grid(let grid):
            DownloadsItems(items: grid.items, store: store, app: app, onOpen: onOpen)
        case .sections(let shown):
            DownloadsItems(items: [], sections: shown.sections, store: store, app: app, onOpen: onOpen)
        case .albums(let albums):
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(albums.rows.enumerated()), id: \.offset) { _, row in
                        switch onEnum(of: row) {
                        case .album(let album):
                            AlbumHeader(album: album.album, artwork: album.artworkPath ?? store.artworkOf(item: album.album))
                        case .track(let track):
                            DownloadedTrackRow(track: track.item, showAlbum: false) {
                                app.session.musicScreens.playDownloaded(tracks: track.tracks, index: track.index, album: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, sides.leading)
                .padding(.bottom, 24)
                .scrollsBackToTop()
            }
            .accessibilityIdentifier("downloads.items")
        case .tracks(let tracks):
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(tracks.tracks.enumerated()), id: \.element.globalKey) { index, track in
                        DownloadedTrackRow(track: track, showAlbum: true) {
                            app.session.musicScreens.playDownloaded(tracks: tracks.tracks, index: Int32(index), album: false)
                        }
                    }
                }
                .padding(.horizontal, sides.leading)
                .padding(.bottom, 24)
                .scrollsBackToTop()
            }
            .accessibilityIdentifier("downloads.items")
        }
    }
}

/// Downloaded titles as cards (`DownloadsStore.card`) in the grid the View mode setting, library density and grid
/// spacing make, or as a list; `sections` (the library grouping) each under its title and server. A tap opens the title
/// (`onOpen`); a collection folder's menu (long press, right click) marks its titles watched or unwatched and deletes
/// its downloads.
private struct DownloadsItems: View {
    let items: [MediaItem]
    var sections: [DownloadsLibrarySection] = []
    let store: DownloadsStore
    let app: AppModel
    let onOpen: (MediaItem) -> Void

    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides

    var body: some View {
        let appearance = app.appearance.state
        GeometryReader { proxy in
            let width = proxy.size.width - sides.leading - sides.trailing
            let first = items.first ?? sections.first?.items.first
            let shape = first.map { store.card(item: $0).shape } ?? .poster
            let grid = dimens.grid(width: width, shape: shape, appearance: appearance)
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 12) {
                    if !items.isEmpty {
                        cells(items, grid: grid, shape: shape, list: appearance.viewMode == .list, density: appearance.libraryDensity)
                    }
                    ForEach(sections, id: \.key) { section in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Palette.onBackground)
                                .accessibilityAddTraits(.isHeader)
                            if let subtitle = section.subtitle {
                                Text(subtitle).font(.caption).foregroundStyle(Palette.onSurfaceVariant)
                            }
                        }
                        .padding(.top, 12)
                        cells(section.items, grid: grid, shape: shape, list: false, density: appearance.libraryDensity)
                    }
                }
                .padding(.horizontal, sides.leading)
                .padding(.bottom, 24)
                .scrollsBackToTop()
            }
            .scrollIndicators(.hidden)
        }
        .accessibilityIdentifier("downloads.items")
    }

    @ViewBuilder
    private func cells(_ items: [MediaItem], grid: GridCells, shape: CardShape_, list: Bool, density: Int32) -> some View {
        if list {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(items, id: \.globalKey) { item in
                    let card = store.card(item: item)
                    openable(item, MediaListRow(card: card, shape: card.shape, density: density, onOpen: nil, menu: []))
                }
            }
        } else {
            CardGrid(cells: grid) {
                ForEach(items, id: \.globalKey) { item in
                    openable(item, PosterCard(card: store.card(item: item), shape: shape, width: grid.cell))
                }
            }
        }
    }

    @ViewBuilder
    private func openable(_ item: MediaItem, _ view: some View) -> some View {
        if item.isDownloadsFolder {
            let entries = DetailDownloadKt.downloadsFolderMenuEntries(folder: item).map { entry in
                ItemMenuEntry(label: entry.label, id: "downloads.folderMenu.\(entry.id)", destructive: entry.destructive) {
                    store.performFolder(folder: item, entry: entry)
                }
            }
            view
                .contentShape(Rectangle())
                .onTapGesture { onOpen(item) }
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onOpen(item) }
                .accessibilityActions(entries)
                .itemMenu(entries: entries, probe: "downloads.folderMenu")
        } else {
            view
                .contentShape(Rectangle())
                .onTapGesture { onOpen(item) }
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onOpen(item) }
        }
    }
}

/// A downloaded album over its tracks: its artwork (120 pt), title, artist and year.
private struct AlbumHeader: View {
    let album: MediaItem
    let artwork: String?

    var body: some View {
        HStack(spacing: 16) {
            RemoteImage(url: artwork) { failed in
                if failed { ArtworkPlaceholder(kind: .album) }
            }
            .background(Palette.surfaceContainerHighest)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(album.displayTitle)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.onBackground)
                    .lineLimit(2)
                let detail = [album.parentTitle, album.year.map { "\($0)" }].compactMap { $0 }.joined(separator: " · ")
                if !detail.isEmpty {
                    Text(detail).font(.caption).foregroundStyle(Palette.onSurfaceVariant).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("downloads.album.\(album.globalKey)")
    }
}

/// A downloaded track: its number (none in the flat list: numbers are the album's), title, artist (and album in the
/// flat list) and length. A press plays it among its downloaded siblings, offline (`MusicScreens.playDownloaded`).
private struct DownloadedTrackRow: View {
    let track: MediaItem
    let showAlbum: Bool
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(showAlbum ? "" : track.trackNumber.map { "\($0)" } ?? "")
                .font(.caption)
                .foregroundStyle(Palette.onSurfaceVariant)
                .frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.displayTitle).font(.subheadline).foregroundStyle(Palette.onBackground).lineLimit(1)
                let detail = (showAlbum ? [track.trackArtistTitle, track.albumTitle] : [track.trackArtistTitle])
                    .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
                if !detail.isEmpty {
                    Text(detail).font(.caption).foregroundStyle(Palette.onSurfaceVariant).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let duration = track.durationMs {
                let seconds = duration.int64Value / 1000
                Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.onSurfaceVariant)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: onPlay)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onPlay() }
        .accessibilityIdentifier("downloads.track.\(track.globalKey)")
    }
}

/// A content tab's filters: Clear all, Unwatched (Any, Yes, No) and Library (its summary; a page listing each library
/// holding downloads, all of them kept or excluded).
/// - iPhone, iPad: a settings form in the app's sheet (`appSheet`), Clear all first while a filter is on; Unwatched is one
///   row that steps Any, Yes, No on a press (Left and Right step it with the arrow keys). Each change applies at once.
///   Closes by Close or a swipe.
/// - Mac: a popover from the Filters capsule (`FiltersPopover`); Unwatched is a menu, Library's page replaces the
///   fields in the popover, Back (or Escape) over it returns. Edits are staged and go to the tab once as it closes
///   (Escape, a click outside), only when they changed.
///
/// Accessibility identifiers: `downloads.filtersSheet`, `downloads.filters.clearAll`, `downloads.filters.back` (Mac),
/// `downloads.filters.<field>`, `downloads.filters.all`, `downloads.filters.exclude`, `downloads.filters.value.<i>`,
/// `sheet.close`.
private struct DownloadsFiltersSheet: View {
    let store: DownloadsStore
    let options: DownloadsTabOptions
    let onClose: () -> Void

    @State private var observer: StoreObserver<DownloadsOptionsState>
    @State private var downloads: StoreObserver<DownloadsUiState>
    #if os(macOS)
    /// The filters as edited, applied as the popover closes.
    @State private var staged: [LibraryFilter]
    /// The filters as the popover opened.
    private let opened: [LibraryFilter]
    /// The field whose page the popover shows; nil for the fields.
    @State private var page: MediaFilter?

    private typealias Edit = LibraryFilterEditingKt
    #endif

    init(store: DownloadsStore, options: DownloadsTabOptions, onClose: @escaping () -> Void) {
        self.store = store
        self.options = options
        self.onClose = onClose
        _observer = State(initialValue: StoreObserver(options.state))
        _downloads = State(initialValue: StoreObserver(store.state))
        #if os(macOS)
        let filters = options.state.value.filters
        opened = filters
        _staged = State(initialValue: filters)
        #endif
    }

    var body: some View {
        editor
            .task { await observer.observe() }
            .task { await downloads.observe() }
    }

    #if os(macOS)
    private var editor: some View {
        let state = observer.state
        let libraryValues = downloads.state.libraryFilterValues
        let edited = state.doCopy(grouping: state.grouping, sort: state.sort, sortDescending: state.sortDescending, filters: staged)
        return FiltersPopover(
            pageTitle: page?.title,
            ids: FiltersPopoverIds(sheet: "downloads.filtersSheet", clear: "downloads.filters.clearAll", back: "downloads.filters.back"),
            canClear: !staged.isEmpty,
            onClear: { staged = [] },
            onBack: { page = nil },
            onClose: onClose
        ) {
            if let page {
                DownloadsLibraryFilterPage(
                    filter: page,
                    values: libraryValues,
                    clause: edited.libraryFilter,
                    onAll: { staged = staged.filter { $0.field != page.filter } },
                    onExcluded: { staged = Edit.withFilterExcluded(filters: staged, field: page.filter, exclude: $0) },
                    onToggle: { value in
                        staged = Edit.toggleFilterValue(
                            filters: staged, field: page.filter, value: value,
                            exclude: Edit.isFilterExcluded(filters: staged, field: page.filter)
                        )
                    }
                )
            } else {
                Form {
                    Section {
                        ForEach(options.filterDefinitions, id: \.filter) { filter in
                            if filter.isBoolean {
                                unwatchedPicker(filter)
                            } else {
                                // A Mac form draws a button as a push button across the row: plain, with a link's chevron.
                                Button { page = filter } label: {
                                    LabeledContent(filter.title) {
                                        HStack(spacing: 6) {
                                            Text(edited.filterSummary(filter: filter, libraryValues: libraryValues) ?? "")
                                            Image(systemName: "chevron.forward").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                                        }
                                    }
                                    .foregroundStyle(Palette.onBackground)
                                    .contentShape(Rectangle())
                                }
                                .formRowButtonStyle()
                                .accessibilityIdentifier("downloads.filters.\(filter.filter)")
                            }
                        }
                    }
                }
                .settingsForm()
            }
        }
        .onDisappear {
            if staged != opened { options.setFilters(filters: staged) }
        }
    }

    /// Unwatched: Any, Yes (unwatched only) or No (watched only), from a menu.
    private func unwatchedPicker(_ filter: MediaFilter) -> some View {
        let states: [BooleanFilterState] = [.any, .yes, .no]
        let labels = [T.shared.libraries.advancedFilters.any, T.shared.libraries.advancedFilters.yes, T.shared.libraries.advancedFilters.no]
        return Picker(filter.title, selection: Binding(
            get: { Edit.booleanFilterState(filters: staged, field: filter.filter) },
            set: { staged = Edit.withBooleanFilter(filters: staged, field: filter.filter, state: $0) }
        )) {
            ForEach(Array(states.enumerated()), id: \.offset) { index, state in Text(labels[index]).tag(state) }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("downloads.filters.\(filter.filter)")
    }
    #else
    private var editor: some View {
        let state = observer.state
        let libraryValues = downloads.state.libraryFilterValues
        let close = SheetAction(title: T.shared.common.close, id: "sheet.close", action: onClose)
        return SheetPage(id: "downloads.filtersSheet", title: T.shared.libraries.filters, close: close) {
            Form {
                if state.hasActiveFilters {
                    Section {
                        Button(T.shared.libraries.clearAll, role: .destructive) { options.resetFilters() }
                            .accessibilityIdentifier("downloads.filters.clearAll")
                    }
                }
                Section {
                    ForEach(options.filterDefinitions, id: \.filter) { filter in
                        if filter.isBoolean {
                            unwatchedRow(filter, state: state)
                        } else {
                            NavigationLink {
                                LibraryPage(options: options, filter: filter, values: libraryValues, observer: observer)
                            } label: {
                                LabeledContent(filter.title) { Text(state.filterSummary(filter: filter, libraryValues: libraryValues) ?? "") }
                            }
                            .accessibilityIdentifier("downloads.filters.\(filter.filter)")
                        }
                    }
                }
                SheetActionsSection(actions: [close])
            }
            .settingsForm()
        }
    }

    private func unwatchedRow(_ filter: MediaFilter, state: DownloadsOptionsState) -> some View {
        let states: [Bool?] = [nil, true, false]
        let labels = [T.shared.libraries.advancedFilters.any, T.shared.libraries.advancedFilters.yes, T.shared.libraries.advancedFilters.no]
        let at = states.firstIndex(of: state.unwatchedFilter?.boolValue) ?? 0
        let step = { (delta: Int) in
            options.setUnwatchedFilter(value: states[(at + delta + states.count) % states.count].map { KotlinBoolean(value: $0) })
        }
        return Button { step(1) } label: {
            LabeledContent(filter.title) { Text(labels[at]) }
        }
        .horizontalSteps(step)
        .accessibilityValue(labels[at])
        .accessibilityIdentifier("downloads.filters.\(filter.filter)")
    }

    /// The Library page of the sheet, each change applied to the tab at once.
    private struct LibraryPage: View {
        let options: DownloadsTabOptions
        let filter: MediaFilter
        let values: [MediaFilterValue]
        let observer: StoreObserver<DownloadsOptionsState>

        var body: some View {
            DownloadsLibraryFilterPage(
                filter: filter,
                values: values,
                clause: observer.state.libraryFilter,
                onAll: { options.clearLibraryFilter() },
                onExcluded: { options.setLibraryFilterExcluded(excluded: $0) },
                onToggle: { options.toggleLibraryFilterValue(value: $0) }
            )
            .pageTitle(filter.title)
        }
    }
    #endif
}

/// The Library filter's page: All, Include or Exclude, then each library holding downloads, checked while picked.
private struct DownloadsLibraryFilterPage: View {
    let filter: MediaFilter
    let values: [MediaFilterValue]
    /// The Library filter's clause as it stands.
    let clause: LibraryFilter?
    let onAll: () -> Void
    let onExcluded: (Bool) -> Void
    let onToggle: (String) -> Void

    var body: some View {
        let excluded = clause?.op.isNegated == true
        Form {
            Section {
                Button(action: onAll) { checked(T.shared.libraries.all, clause == nil) }
                    .formRowButtonStyle()
                    .accessibilityIdentifier("downloads.filters.all")
                if filter.supportsExclusion {
                    Picker(filter.title, selection: Binding(get: { excluded }, set: onExcluded)) {
                        Text(T.shared.libraries.advancedFilters.include).tag(false)
                        Text(T.shared.libraries.advancedFilters.exclude).tag(true)
                    }
                    .horizontalSteps { onExcluded($0 > 0) }
                    .accessibilityIdentifier("downloads.filters.exclude")
                }
            }
            Section {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    let picked = clause?.values.contains(value.key) == true
                    Button { onToggle(value.key) } label: { checked(value.title, picked) }
                        .formRowButtonStyle()
                        .accessibilityAddTraits(picked ? .isSelected : [])
                        .accessibilityIdentifier("downloads.filters.value.\(index)")
                }
            }
        }
        .settingsForm()
    }

    private func checked(_ label: String, _ on: Bool) -> some View {
        HStack {
            Text(label).foregroundStyle(Palette.onBackground)
            Spacer(minLength: 8)
            if on { Image(systemName: "checkmark").foregroundStyle(Palette.primary) }
        }
        .contentShape(Rectangle())
    }
}
#endif
