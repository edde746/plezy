import SwiftUI
import PlezyKit

/// Browse: the items as the grid or the list (the View mode setting), the alphabet index in the grid's trailing
/// margin, or the folder tree. Its grouping, sort and filters are in the screen's header row (`LibrariesScreen`).
struct BrowseTab: View {
    let app: AppModel
    let browse: LibraryBrowseStore
    let store: LibrariesScreenStore

    @State private var state: StoreObserver<BrowseUiState>?
    /// The grid's last alphabet jump (Plex: a letter's first item).
    @State private var jump: GridJump?
    /// The letter last jumped to (Plex): the index marks it until the user moves the grid, wherever the jump's row
    /// leaves the scroll position's letter.
    @State private var pinned: String?
    /// A letter of the index has focus (Apple TV, the Mac): a reload of the items leaves focus there.
    @State private var indexFocused = false
    /// Asks the grid to take focus back on a visible item (Left or Back from the index on Apple TV).
    @State private var gridFocusRequest = 0
    /// The index's letters as last shown: a reload empties the items (and the store's letters with them), and the index
    /// stays through it so focus on it does too.
    @State private var heldLetters: [String] = []
    @Environment(\.screenSides) private var sides

    var body: some View {
        let observer = state ?? StoreObserver(browse.state)
        let current = observer.state
        let letters = current.alphaLetters.isEmpty && current.load == .loading ? heldLetters : current.alphaLetters
        let index = current.grouping != .folders && !letters.isEmpty
        let mark = pinned ?? current.currentLetter
        HStack(spacing: 0) {
            Group {
                if current.load == .error {
                    ErrorStateView(message: current.error ?? "") { browse.reload() }
                } else if current.grouping == .folders {
                    FolderTreeList(store: store, state: current) { browse.reload() }
                } else if current.load == .loading {
                    LoadingStateView().accessibilityIdentifier("libraries.items.loading")
                } else if let letter = current.emptyLetter {
                    // The index stays beside it: the letter picked again clears it.
                    EmptyStateView(message: T.shared.libraries.noTitlesStartWith(letter: letter), systemImage: "magnifyingglass")
                } else if current.load == .empty && current.filtersActive {
                    EmptyStateView(message: T.shared.libraries.noItemsMatchFilters, systemImage: "line.3.horizontal.decrease.circle") {
                        Button(T.shared.libraries.resetFilters) { browse.applyFilters(filters: [], libraryKey: browse.libraryKey) }
                            .buttonProminence(.primary)
                    }
                } else if current.load == .empty {
                    EmptyStateView(message: T.shared.libraries.thisLibraryIsEmpty, systemImage: "folder")
                } else {
                    LibraryPagedGrid(
                        app: app, total: Int(current.total), card: { current.card(index: Int32($0)) }, shape: current.shape,
                        caption: !(app.appearance.state.tv && app.appearance.state.tvFullCardLayout) || current.captionsAlways,
                        jump: jump, jumps: browse, claimsFocus: !indexFocused, focusRequest: gridFocusRequest,
                        trailingRoom: index ? AlphabetIndex.room(side: sides.trailing) : 0,
                        onLayout: { browse.setLayout(columns: Int32($0), visibleRows: Int32($1)) },
                        onVisible: { browse.visibleRange(first: Int32($0), count: Int32($1)) },
                        onScrolling: { browse.setScrolling(value: $0) },
                        onMove: { pinned = nil },
                        onMissing: { browse.ensureIndexLoaded(index: Int32($0)) },
                        onOpen: { store.open(cardId: $0.id) },
                        onMenu: { store.menu(cardId: $0.id) }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The letter filtering the list (Jellyfin, Emby), named over the grid with its Clear.
            .safeAreaInset(edge: .top, spacing: 0) {
                if let letter = current.filterLetter {
                    LetterFilterButton(letter: letter) { browse.clearLetter() }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, sides.leading)
                        .padding(.vertical, 4)
                }
            }
            // In the grid's trailing margin, as the system's section index: the grid counts its columns on the margin
            // the index sits in. Beside the grid, not over it, so a drag down it never reaches the grid's scrolling.
            if index {
                AlphabetIndex(
                    letters: letters, current: mark, rows: { browse.alphaRows(count: Int32($0)) },
                    focused: $indexFocused, onLetter: pick
                ) { gridFocusRequest += 1 }
                    .padding(.trailing, AlphabetIndex.gap(side: sides.trailing))
                    #if os(macOS)
                    // Clear of the window's rounded corner too.
                    .padding(.bottom, AlphabetIndex.gap(side: sides.trailing))
                    #endif
            }
        }
        #if os(tvOS)
        // The index's margin is the safe area past the grid's trailing edge.
        .ignoresSafeArea(.container, edges: index ? .trailing : [])
        #endif
        .onChange(of: current.alphaLetters, initial: true) { _, letters in
            if !letters.isEmpty || current.load != .loading { heldLetters = letters }
        }
        .task {
            state = observer
            await observer.observe()
        }
    }

    /// A letter of the index: Plex scrolls to its first item, loading its page; Jellyfin and Emby filter (the store).
    private func pick(_ letter: String) {
        guard let index = browse.selectLetter(letter: letter).map({ Int(truncating: $0) }) else { return }
        browse.ensureIndexLoaded(index: Int32(index))
        jump = GridJump(index: index, serial: (jump?.serial ?? 0) + 1)
        pinned = letter
    }
}

/// Collections and Playlists: their items page by page.
struct PagedTab<Item: AnyObject>: View {
    let app: AppModel
    let tab: LibraryPagedTabStore<Item>
    let store: LibrariesScreenStore
    let empty: String

    @State private var state: StoreObserver<PagedGridUiState>?

    var body: some View {
        let observer = state ?? StoreObserver(tab.state)
        let current = observer.state
        Group {
            switch current.load {
            case .loading: LoadingStateView()
            case .error: ErrorStateView(message: current.error ?? "") { tab.reload() }
            case .empty: EmptyStateView(message: empty, systemImage: "rectangle.stack")
            default:
                LibraryPagedGrid(
                    app: app, total: Int(current.total), card: { current.card(index: Int32($0)) }, shape: current.shape,
                    caption: !(app.appearance.state.tv && app.appearance.state.tvFullCardLayout) || current.shape == .square,
                    onMissing: { tab.ensureIndexLoaded(index: Int32($0)) },
                    onOpen: { store.open(cardId: $0.id) },
                    onMenu: { store.menu(cardId: $0.id) }
                )
            }
        }
        .task {
            state = observer
            await observer.observe()
        }
    }
}

/// `total` cells, `card` each (a blank card until it loads, which asks for its page), as many columns of `PosterCard`s
/// as fit between the screen's sides (the density setting picks their width), or the list (the View mode setting).
/// `trailingRoom`: how much of the trailing side lies past the grid's own frame (the alphabet index's lane), counted for
/// the columns too; less than none where the frame reaches past the side.
/// Cells and focus are keyed by the card's id, an unloaded slot by its index: a live refetch that moves the focused item
/// to another shown cell keeps focus on it. The artwork two rows past the visible ones is fetched ahead. `jump` scrolls
/// to an index (the alphabet's) over 300 ms, easing in and out, a newer jump taking over; the store's `jumps` (a live
/// refetch keeping the first visible item in view) at once. Real scrolling, a drag or the deceleration after it,
/// reaches `onScrolling` (iOS 18, macOS 15, Apple TV); `onMove` hears the user move the grid: a drag, or focus moving
/// between its cards (Apple TV). Apple TV: focus enters on the first item once it loads, not while another
/// control holds it; `focusRequest` changing puts it on a visible item.
struct LibraryPagedGrid: View {
    let app: AppModel
    let total: Int
    let card: (Int) -> MediaCardUi?
    let shape: CardShape_
    var caption = true
    var jump: GridJump?
    var jumps: LibraryBrowseStore?
    var claimsFocus = true
    var focusRequest = 0
    var trailingRoom: CGFloat = 0
    var onLayout: (Int, Int) -> Void = { _, _ in }
    var onVisible: (Int, Int) -> Void = { _, _ in }
    var onScrolling: (Bool) -> Void = { _ in }
    var onMove: () -> Void = {}
    let onMissing: (Int) -> Void
    let onOpen: (MediaCardUi) -> Void
    let onMenu: (MediaCardUi) -> Void

    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides
    @Environment(\.displayScale) private var displayScale
    @Environment(\.libraryTabActive) private var active
    @Environment(\.tabBarHoldsFocus) private var tabBarHoldsFocus
    /// The cells shown now, out of the view's state: a cell coming or going redraws no other.
    @State private var shown = ShownCells()
    /// The grid's focused cell, by its item's id: a live refetch that moves the item keeps focus on it.
    @FocusState private var cellFocus: String?
    /// Jumps so far: a jump's settling scroll stands down once a newer one started.
    @State private var jumpGeneration = 0
    /// The newest jump once its animation ran: scrolled to exactly.
    @State private var settled: GridJump?
    #if os(tvOS)
    /// The cell focus was last on, by its index and its item's id: coming back to the grid (Menu from the screen a card
    /// opened) puts focus back there, whether or not the system has restored it yet when the grid's first focus runs.
    @State private var lastFocus: (index: Int, id: String)?
    #endif
    #if os(iOS)
    /// Holds the screen at its full refresh rate while the grid moves.
    @State private var fullRate = FullRateLink()
    #endif

    var body: some View {
        let appearance = app.appearance.state
        let list = appearance.viewMode == .list
        GeometryReader { proxy in
            let layout = dimens.grid(width: proxy.size.width + trailingRoom - sides.horizontal, shape: shape, appearance: appearance)
            ScrollViewReader { scroller in
                ScrollView(.vertical) {
                    Group {
                        if list {
                            LazyVStack(alignment: .leading, spacing: 0) { cells(layout: layout, list: true) }
                        } else {
                            CardGrid(cells: layout) { cells(layout: layout, list: false) }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: sides.leading, bottom: 0, trailing: sides.trailing - trailingRoom))
                    // Room for the focused card to lift (tvOS) or its focus ring.
                    .padding(.vertical, dimens.focusRoom + 4)
                    .scrollsBackToTop()
                }
                .scrollIndicators(.hidden)
                #if os(iOS)
                .reportsScrolling(onScrolling, moved: onMove) { fullRate.running = $0 }
                .onDisappear { fullRate.running = false }
                #else
                .reportsScrolling(onScrolling, moved: onMove)
                #endif
                .onChange(of: jump) { _, jump in
                    guard let jump else { return }
                    jumpGeneration += 1
                    let generation = jumpGeneration
                    withAnimation(.easeInOut(duration: 0.3)) { scroller.scrollTo(key(jump.index), anchor: .top) }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        if generation == jumpGeneration { settled = jump }
                    }
                }
                // An animated scroll across a lazy grid can stop short of rows it hadn't laid out, and the target's page
                // may have loaded meanwhile (its cell's id with it): the newest jump ends exactly on its row.
                .onChange(of: settled) { _, jump in
                    if let jump { scroller.scrollTo(key(jump.index), anchor: .top) }
                }
                .task(id: jumps.map { ObjectIdentifier($0) }) {
                    guard let jumps else { return }
                    for await index in jumps.jumps { scroller.scrollTo(key(Int(truncating: index)), anchor: .top) }
                }
            }

            .onAppear {
                let rows = max(1, Int(proxy.size.height / max(layout.cell / CGFloat(shape.aspect) + layout.spacing, 1)))
                onLayout(list ? 1 : layout.columns, rows)
            }
        }
        // Down from the header row lands on the grid.
        .shelfFocusSection()
        #if os(tvOS)
        // Focus enters on the first item once it loads, unless a controller's shoulder button put it on the view menu; back
        // from a screen a card opened, on that card if it is still there.
        .task(id: "\(card(0) != nil)|\(claimsFocus)|\(active)|\(tabBarHoldsFocus)") {
            guard !list, claimsFocus, active, !tabBarHoldsFocus, let first = card(0) else { return }
            let back = lastFocus.flatMap { last in card(last.index)?.id == last.id ? last.id : nil }
            await FocusRestore.restore($cellFocus, to: back ?? first.id, hold: 1)
        }
        .onChange(of: focusRequest) {
            if let first = shown.indices.min(), let item = card(first) { cellFocus = item.id }
        }
        .onChange(of: cellFocus) { old, new in
            if let new, let index = shown.indices.first(where: { card($0)?.id == new }) { lastFocus = (index, new) }
            if old != nil, new != nil { onMove() }
        }
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("libraries.grid")
    }

    /// The cell at `index`'s identity: its card's id, or its slot while it isn't loaded.
    private func key(_ index: Int) -> String { card(index)?.id ?? "slot.\(index)" }

    @ViewBuilder
    private func cells(layout: GridCells, list: Bool) -> some View {
        ForEach(0..<total, id: \.self) { index in
            let item = card(index)
            Group {
                if let item {
                    if list {
                        MediaListRow(
                            card: item, shape: shape, density: app.appearance.state.libraryDensity,
                            onOpen: { onOpen(item) }, onMenu: { onMenu(item) }
                        )
                    } else {
                        PosterCard(
                            card: item, shape: shape, width: layout.cell, caption: caption,
                            focus: CardFocus(binding: $cellFocus, key: item.id), onOpen: { onOpen(item) }, onMenu: { onMenu(item) }
                        )
                    }
                } else {
                    BlankCard(shape: shape, width: list ? nil : layout.cell)
                        .onAppear { onMissing(index) }
                }
            }
            .id(key(index))
            // A live refetch put another item in the focused cell, whose view goes with its id: focus follows the item
            // to where it went, if shown, once the system has let go of the cell.
            .onChange(of: item?.id) { old, _ in
                guard let old, cellFocus == old, shown.indices.contains(where: { card($0)?.id == old }) else { return }
                Task { await FocusRestore.restore($cellFocus, to: old, hold: 1, replacing: true) }
            }
            #if os(tvOS)
            // Down from a card with none under it, above a short last row, lands on the last card: the
            // focus engine finds nothing straight below.
            .onMoveCommand { direction in
                guard direction == .down, !list, let last = shortRowTarget(from: index, columns: layout.columns, total: total) else { return }
                cellFocus = card(last)?.id
            }
            #endif
            .onAppear {
                shown.indices.insert(index)
                guard let first = shown.indices.min(), let last = shown.indices.max() else { return }
                onVisible(first, shown.indices.count)
                prefetch(first: first, last: last, layout: layout, list: list)
            }
            .onDisappear { shown.indices.remove(index) }
        }
    }

    /// The artwork from the first visible item to two rows past the visible ones, at the cell's size: of the loaded items
    /// there, those not asked for as the last cell showed.
    private func prefetch(first: Int, last: Int, layout: GridCells, list: Bool) {
        guard !list else { return }
        let loaded = (first..<min(total, last + 1 + layout.columns * 2)).filter { card($0) != nil }
        let artworks = loaded.filter { !shown.prefetched.contains($0) }.compactMap { card($0)?.artwork }
        shown.prefetched = Set(loaded)
        guard !artworks.isEmpty else { return }
        let appearance = app.appearance.state
        ArtworkPrefetch.start(
            artworks, size: CGSize(width: layout.cell, height: layout.cell / CGFloat(shape.aspect)), displayScale: displayScale,
            tv: appearance.tv, visualEffects: appearance.visualEffects
        )
    }
}

/// A grid's shown cells by index, and the items whose artwork it last fetched ahead (`LibraryPagedGrid`).
private final class ShownCells {
    var indices: Set<Int> = []
    var prefetched: Set<Int> = []
}

#if os(iOS)
/// A display link that only asks for 120 Hz while it runs. On a ProMotion screen UIKit lets a scroll view's slower
/// phases (the end of a deceleration, the bounce at an edge, the moment a drag catches a moving grid) drop to 60–80
/// Hz, which a grid of artwork shows as stutter; a request for the full rate keeps them at 120 Hz.
@MainActor
private final class FullRateLink: NSObject {
    private var link: CADisplayLink?

    var running = false {
        didSet {
            guard running != oldValue else { return }
            if running {
                let link = CADisplayLink(target: self, selector: #selector(tick))
                link.preferredFrameRateRange = CAFrameRateRange(minimum: 120, maximum: 120, preferred: 120)
                link.add(to: .main, forMode: .common)
                self.link = link
            } else {
                link?.invalidate()
                link = nil
            }
        }
    }

    @objc private func tick() {}
}
#endif

/// An alphabet jump of the grid: to the item at `index`; `serial` tells two jumps to one index apart.
struct GridJump: Equatable {
    let index: Int
    let serial: Int
}

#if os(tvOS)
/// Where Down goes from the item at `index` of a grid of `columns` across `total` items when the last row is too short to
/// have an item under it: the last item. Nil when there is one under it, or no row below.
private func shortRowTarget(from index: Int, columns: Int, total: Int) -> Int? {
    guard columns > 1, index + columns >= total, index / columns < (total - 1) / columns else { return nil }
    return total - 1
}
#endif

private extension View {
    /// Whether the user is scrolling this scroll view (a drag, the deceleration after it), reported as it changes;
    /// `moved` as a drag starts; `moving` whether it moves at all (a finger on it, or any scrolling or bounce).
    @ViewBuilder
    func reportsScrolling(_ report: @escaping (Bool) -> Void, moved: @escaping () -> Void, moving: @escaping (Bool) -> Void = { _ in }) -> some View {
        if #available(iOS 18, macOS 15, *) {
            onScrollPhaseChange { _, phase in
                report(phase == .interacting || phase == .decelerating)
                if phase == .interacting { moved() }
                moving(phase != .idle)
            }
        } else {
            self
        }
    }
}

/// The alphabet index in the grid's trailing margin, drawn as the system's list section index is:
/// the letters in small semibold type of the tint down a narrow column, no fill. A row per letter where each gets
/// `minRow`, else the shared rows for the rows there are (`LibraryBrowseStore.alphaRows`, which a pick never moves):
/// some letters alone, each run of letters between them one row drawn as a dot, as the system's index collapses runs.
/// The current letter (the grid's, or the one filtering it) shows in place of its run's dot, on a round fill of the
/// tint no taller than its row, so the letter to pick again to clear a filter shows.
/// - iOS and macOS: a touch, a click or a drag picks the letter under it at once, a run's row sharing its height among
///   its letters (`alphaLetterDown`), so every letter is reachable whatever the index's height; a touch on a run's row
///   that shows the current letter picks that letter while it stays in the row, so a tap clears a filter there too.
///   While it is down, the letter under it shows in a round bubble beside the index and in its run's row. VoiceOver
///   reads each row as a button: a letter, or a run named by its ends with an action per letter. The Mac: a click then
///   gives the index the keyboard, whose Up and Down step through every letter.
/// - tvOS: each letter takes focus (a white surface under it, as a panel's rows; the screen has room for every letter):
///   Up and Down jump 150 ms after the last move, Select at once; Left and the remote's Menu go back to the grid
///   (`onLeave`).
private struct AlphabetIndex: View {
    let letters: [String]
    let current: String?
    /// The rows for a number of rows, where every letter doesn't get one.
    let rows: (Int) -> [[String]]
    @Binding var focused: Bool
    let onLetter: (String) -> Void
    let onLeave: () -> Void

    @State private var height: CGFloat = 0
    /// The letter last jumped to here: Up and Down step from it.
    @State private var picked: String?
    #if os(tvOS)
    @FocusState private var focus: String?
    @State private var settle: Task<Void, Never>?
    #else
    /// The letter under the finger or pointer while it is down, and where: a drag jumps once per letter it moves onto,
    /// so a pause on a letter doesn't pick it again (Jellyfin and Emby: a letter picked again clears its filter).
    @State private var touch: Touch?
    #endif
    #if os(macOS)
    @FocusState private var keyboard: Bool
    #endif

    /// A touch on the index: the letter under it and where it is; the row it came down on and, where that row is a run
    /// showing the current letter, that letter, which the touch picks while it stays in the row.
    private struct Touch {
        let letter: String
        let y: CGFloat
        let row: Int
        let pinned: String?
    }

    private static let width: CGFloat = {
        #if os(tvOS)
        48
        #else
        18
        #endif
    }()

    /// The round fill under the current letter, where its row is as tall.
    private static let markSize: CGFloat = {
        #if os(tvOS)
        36
        #else
        16
        #endif
    }()

    /// The least height of a row (iOS, macOS): a shorter index draws fewer rows.
    private static let minRow: CGFloat = 20

    /// The bubble showing the letter under the finger.
    private static let bubble: CGFloat = 44

    /// What lies past the grid's trailing side, where the index can sit too: tvOS's 80 pt safe area, which the screen
    /// opens to it.
    private static let outside: CGFloat = {
        #if os(tvOS)
        80
        #else
        0
        #endif
    }()

    /// The space after the index: it sits in the middle of the trailing margin (the screen's `side` and what lies past
    /// it) where that has room for it. The Mac: a whole `side` from the window's edge and its rounded corner.
    static func gap(side: CGFloat) -> CGFloat {
        #if os(macOS)
        side
        #else
        max((side + outside - width) / 2, 0)
        #endif
    }

    /// What the index and the space after it take of the grid's trailing `side`, which the grid counts its columns on;
    /// less than none where the index sits past it (tvOS), the grid's frame then reaching past its side. The Mac: none,
    /// the index sitting past the grid's own side.
    static func room(side: CGFloat) -> CGFloat {
        #if os(macOS)
        0
        #else
        min(width + gap(side: side), side + outside) - outside
        #endif
    }

    /// The rows drawn: a letter each where each gets `minRow` (always on tvOS), else `rows` for the rows there are.
    private var shown: [[String]] {
        #if !os(tvOS)
        let count = Int((height - 16) / Self.minRow)
        if height > 0 && letters.count > count { return rows(max(count, 1)) }
        #endif
        return letters.map { [$0] }
    }

    var body: some View {
        let drawn = shown
        let mark = height > 0 ? min(Self.markSize, (height - 16) / CGFloat(max(drawn.count, 1))) : Self.markSize
        VStack(spacing: 0) {
            ForEach(drawn, id: \.self) { row in
                entry(row, mark: mark)
            }
        }
        .frame(width: Self.width)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 8)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        #if os(tvOS)
        .focusSection()
        .onMoveCommand { direction in
            switch direction {
            case .up, .down:
                settle?.cancel()
                settle = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    // Focus coming to rest on the current letter picks nothing: picked, Jellyfin's would clear.
                    guard !Task.isCancelled, let letter = focus, letter != current else { return }
                    jump(letter)
                }
            case .left:
                onLeave()
            default:
                break
            }
        }
        .onExitCommand(perform: onLeave)
        .onChange(of: focus) { _, letter in focused = letter != nil }
        #else
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let fraction = (drag.location.y - 8) / max(height - 16, 1)
                    let row = min(max(Int(fraction * CGFloat(drawn.count)), 0), drawn.count - 1)
                    let start = touch ?? Touch(
                        letter: "", y: 0, row: row,
                        pinned: current.flatMap { drawn[row].count > 1 && drawn[row].contains($0) ? $0 : nil }
                    )
                    let pinned = row == start.row ? start.pinned : nil
                    let letter = pinned ?? LibraryRulesKt.alphaLetterDown(rows: drawn, fraction: Double(fraction))
                    let moved = letter != touch?.letter
                    touch = Touch(letter: letter, y: min(max(drag.location.y, 8), max(height - 8, 8)), row: start.row, pinned: start.pinned)
                    if moved { jump(letter) }
                }
                .onEnded { _ in
                    touch = nil
                    #if os(macOS)
                    keyboard = true
                    #endif
                }
        )
        // Beside the index, clear of the finger on it.
        .overlay(alignment: .topLeading) {
            if let touch {
                Text(touch.letter)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Palette.onPrimary)
                    .frame(width: Self.bubble, height: Self.bubble)
                    .background(Palette.primary, in: Circle())
                    .offset(x: -(Self.bubble + 12), y: touch.y - Self.bubble / 2)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        #endif
        #if os(macOS)
        .focusable()
        .focusEffectDisabled()
        .focused($keyboard)
        .onKeyPress(.upArrow) { step(-1) }
        .onKeyPress(.downArrow) { step(1) }
        .onChange(of: keyboard) { _, has in focused = has }
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityLabel(T.shared.accessibility.alphabetNavigation)
        .accessibilityIdentifier("libraries.alpha")
    }

    /// Picks `letter`, the current one too: Jellyfin and Emby clear their letter when it is picked again.
    private func jump(_ letter: String) {
        picked = letter
        onLetter(letter)
    }

    #if os(macOS)
    private func step(_ delta: Int) -> KeyPress.Result {
        guard let from = letters.firstIndex(of: picked ?? current ?? "") else { return .ignored }
        let to = min(max(from + delta, 0), letters.count - 1)
        if to != from { jump(letters[to]) }
        return .handled
    }
    #endif

    @ViewBuilder
    private func entry(_ row: [String], mark: CGFloat) -> some View {
        let first = row[0]
        #if os(tvOS)
        Button {
            settle?.cancel()
            picked = first
            onLetter(first)
        } label: {
            IndexLetter(text: first, applied: first == current, mark: mark).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: Radius.small))
        .focused($focus, equals: first)
        .accessibilityAddTraits(first == current ? .isSelected : [])
        .accessibilityIdentifier("libraries.alpha.\(first)")
        #else
        let last = row[row.count - 1]
        let run = row.count > 1
        // A run's row shows the letter touched or current in it, else its dot.
        let letter = run ? [touch?.letter, current].compactMap { $0 }.first { row.contains($0) } : first
        let applied = letter != nil && letter == current
        IndexLetter(text: letter ?? "•", applied: applied, mark: mark)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(run ? "\(first)–\(last)" : first)
            .accessibilityAddTraits(applied ? [.isButton, .isSelected] : .isButton)
            .accessibilityAction { jump(letter ?? first) }
            .accessibilityActions {
                if run {
                    ForEach(row, id: \.self) { each in Button(each) { jump(each) } }
                }
            }
            .accessibilityIdentifier("libraries.alpha.\(run ? "\(first)-\(last)" : first)")
        #endif
    }
}

/// A row of the alphabet index: its letter (a run's dot), on a round fill `mark` wide while `applied`. iOS and the Mac:
/// a fill of the tint under the letter in the tint's text colour. tvOS, where a focused letter sits on the white
/// surface: focused, the letter turns the surface's text colour and the applied one keeps a ring of it; at rest the
/// applied letter sits on a round tint of the accent. So focused, applied, and both read apart.
private struct IndexLetter: View {
    let text: String
    let applied: Bool
    let mark: CGFloat

    @Environment(\.onFocusedSurface) private var onSurface

    var body: some View {
        Text(text)
            #if os(tvOS)
            .font(.caption.weight(.semibold))
            .foregroundStyle(onSurface ? Palette.onFocusedSurface : Palette.primary)
            #else
            .font(.caption2.weight(.semibold))
            .foregroundStyle(applied ? Palette.onPrimary : Palette.primary)
            #endif
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .background {
                if applied {
                    #if os(tvOS)
                    if onSurface {
                        Circle().strokeBorder(Palette.onFocusedSurface, lineWidth: 3).frame(width: mark, height: mark)
                    } else {
                        Circle().fill(Palette.primary.opacity(0.3)).frame(width: mark, height: mark)
                    }
                    #else
                    Circle().fill(Palette.primary).frame(width: mark, height: mark)
                    #endif
                }
            }
    }
}

/// Browse by folders: the root folders, each expanding in place, as a list. A plain folder's menu (a long press, a
/// right click, a held Select) plays or shuffles it; a pull reloads the tree from its root (iOS).
private struct FolderTreeList: View {
    let store: LibrariesScreenStore
    let state: BrowseUiState
    let onRetry: () -> Void

    @Environment(\.screenSides) private var sides

    var body: some View {
        if let tree = state.folders {
            if tree.load == .error {
                ErrorStateView(message: tree.error ?? "", onRetry: onRetry)
            } else if tree.rows.isEmpty && tree.load == .loading {
                LoadingStateView()
            } else if tree.rows.isEmpty {
                EmptyStateView(message: T.shared.libraries.noFoldersFound, systemImage: "folder")
            } else {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(tree.rows, id: \.id) { row in
                            Button { store.open(cardId: row.id) } label: { FolderRowLabel(row: row) }
                                .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: Radius.medium))
                                .itemMenu(entries: entries(row), probe: "libraries.folder.menu")
                                .accessibilityIdentifier("libraries.folder.\(row.title)")
                                .padding(.leading, CGFloat(row.depth) * 24)
                        }
                    }
                    .padding(sides.insets)
                    .padding(.vertical, 8)
                    .scrollsBackToTop()
                }
                .refreshable { store.refreshTab() }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("libraries.folders")
            }
        } else {
            LoadingStateView()
        }
    }

    /// A plain folder's Play and Shuffle, where the library plays folders.
    private func entries(_ row: FolderRowUi) -> [ItemMenuEntry] {
        guard row.folder, store.canPlayFolders else { return [] }
        return [
            ItemMenuEntry(label: T.shared.common.play, systemImage: "play.fill", id: "libraries.folder.menu.play") {
                store.playFolder(cardId: row.id, shuffle: false)
            },
            ItemMenuEntry(label: T.shared.common.shuffle, systemImage: "shuffle", id: "libraries.folder.menu.shuffle") {
                store.playFolder(cardId: row.id, shuffle: true)
            },
        ]
    }
}

/// A folder row: its chevron (a spinner while it opens), a folder's symbol and name, or an item's artwork, title,
/// subtitle and metadata, and the watched check.
private struct FolderRowLabel: View {
    let row: FolderRowUi

    var body: some View {
        HStack(spacing: 12) {
            if row.folder || row.expandable {
                Group {
                    if row.loading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: row.expanded ? "chevron.down" : "chevron.right")
                    }
                }
                .frame(width: 24)
                .foregroundStyle(.secondary)
            }
            if row.folder {
                Image(systemName: "folder.fill").foregroundStyle(Palette.primary)
                Text(row.title).font(.body.weight(.medium)).lineLimit(1)
            } else {
                RemoteImage(artwork: row.thumb) { failed in
                    if failed { ArtworkPlaceholder(kind: row.placeholder) }
                }
                .background(Palette.surfaceContainerHighest)
                .frame(width: row.wide ? 120 : 48, height: row.wide ? 68 : 72)
                .blur(radius: row.blurred ? 12 : 0)
                .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title).font(.body.weight(.medium)).lineLimit(1)
                    if let subtitle = row.subtitle { Text(subtitle).font(.footnote).mutedForeground() }
                    if let metadata = row.metadata { Text(metadata).font(.caption).mutedForeground() }
                }
            }
            Spacer(minLength: 0)
            if row.watched { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.primary) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, row.folder ? 10 : 6)
        .contentShape(Rectangle())
    }
}

/// Genres: a tile per genre, its art under its colour, as many columns as fit; a tile shows Browse filtered to it. A
/// pull reloads them (iOS).
struct GenresTab: View {
    let tab: LibraryGenresStore
    let store: LibrariesScreenStore

    @State private var state: StoreObserver<LibraryListUiState<GenreTileUi>>?
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides
    #if os(tvOS)
    @FocusState private var tileFocus: String?
    #endif

    var body: some View {
        let observer = state ?? StoreObserver(tab.state)
        let current = observer.state
        GeometryReader { proxy in
            switch current.load {
            case .loading: LoadingStateView()
            case .error: ErrorStateView(message: current.error ?? "") { tab.reload() }
            case .empty: EmptyStateView(message: T.shared.libraries.noGenres, systemImage: "theatermasks")
            default:
                let width = proxy.size.width - sides.horizontal
                let minimum = dimens.cardWidth(.wide) * 1.2
                let columns = max(2, Int((width + dimens.gutter) / (minimum + dimens.gutter)))
                let genres = current.items.compactMap { $0 as? GenreTileUi }
                ScrollView(.vertical) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: dimens.gutter), count: columns), spacing: dimens.gutter) {
                        ForEach(Array(genres.enumerated()), id: \.element.filterValue) { index, genre in
                            Button { store.openGenre(filterValue: genre.filterValue) } label: { GenreTile(genre: genre) }
                                .cardButtonStyle()
                                #if os(tvOS)
                                .focused($tileFocus, equals: genre.filterValue)
                                // Down from a tile with none under it, above a short last row, lands on the last tile.
                                .onMoveCommand { direction in
                                    guard direction == .down, let last = shortRowTarget(from: index, columns: columns, total: genres.count) else { return }
                                    tileFocus = genres[last].filterValue
                                }
                                #endif
                                .accessibilityIdentifier("libraries.genre.\(genre.title)")
                        }
                    }
                    .padding(sides.insets)
                    .padding(.vertical, dimens.focusRoom + 4)
                    .scrollsBackToTop()
                }
                .refreshable { store.refreshTab() }
            }
        }
        .shelfFocusSection()
        .task {
            state = observer
            await observer.observe()
        }
    }
}

private struct GenreTile: View {
    let genre: GenreTileUi

    var body: some View {
        let rgb = Int(genre.accentRgb)
        let accent = Color(red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
        ZStack {
            accent
            if let art = genre.art { RemoteImage(artwork: art) }
            accent.opacity(0.78)
            Text(genre.title)
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 3)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(12)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
    }
}

/// The letter filtering Browse (Jellyfin, Emby) over the grid, "Starting with M · Clear": a filter capsule, filled as a
/// set filter's is, that clears the letter (`libraries.letterFilter`). Apple TV: a capsule button of the focus surface.
private struct LetterFilterButton: View {
    let letter: String
    let clear: () -> Void

    var body: some View {
        let text = "\(T.shared.libraries.startingWith(letter: letter)) · \(T.shared.common.clear)"
        #if os(tvOS)
        Button(action: clear) {
            FilterCapsule(text: text, symbol: "xmark", chevron: false).padding(.horizontal, 20).padding(.vertical, 10)
        }
        .buttonStyle(SurfaceButtonStyle(radius: 999))
        .accessibilityIdentifier("libraries.letterFilter")
        #else
        FilterButton(chip: FilterChip(name: text, text: text, spoken: text, narrowed: true), symbol: "xmark", chevron: false, id: "libraries.letterFilter", action: clear)
            .environment(\.compactFilters, false)
        #endif
    }
}
