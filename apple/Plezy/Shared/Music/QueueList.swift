import SwiftUI
import PlezyKit

/// The queue (`QueueUi`): the whole playback order as a `List`, the played rows dimmed, each row with its track's
/// artwork (the album placeholder without, the current one darkened under the equalizer) and a bold title on the
/// current one, each with its artist and length, no album track numbers. A tap (Select) plays a row. On
/// iPhone and iPad the list's own editing reorders (a long-press drag, or Edit's handles) and deletes (a swipe, or Edit's
/// minus); the Mac drags a row by its handle onto another to reorder (`TrackDragHandle`) and has a × per row; Apple TV
/// has the × alone. It opens scrolled to the current row
/// and follows the playing track while the user hasn't scrolled more than a row and a half away from it. Empty, it says
/// "No items available". Shared by the queue sheet, the wide layout's inline panel and the Mac's queue panes.
struct QueueList: View {
    let queue: QueueUi
    let playing: Bool
    let store: NowPlayingStore
    /// The sheet: focus goes to the current row as it opens (a remote or keyboard has somewhere to be, and the remote's
    /// Menu reaches the sheet). The wide layout's inline queue leaves focus where it is.
    var focusCurrent = false

    @FocusState private var rowFocus: String?

    var body: some View {
        if queue.rows.isEmpty {
            Text(T.shared.messages.noItemsAvailable)
                .font(.subheadline)
                .foregroundStyle(Palette.onSurfaceVariant)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            ScrollViewReader { reader in
                List {
                    ForEach(queue.rows, id: \.key) { row in
                        #if os(macOS)
                        let index = row.index
                        HStack(spacing: 4) {
                            TrackDragHandle(key: row.key, id: "music.queue.\(index).handle")
                            queueRow(row)
                        }
                        .id(row.key)
                        .listRowInsets(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 8))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        // A row dragged by its handle onto this one takes its place.
                        .dropDestination(for: String.self) { keys, _ in
                            guard let key = keys.first, let from = queue.rows.firstIndex(where: { $0.key == key }),
                                  from != Int(index) else { return false }
                            store.reorder(from: Int32(from), to: index)
                            return true
                        }
                        #else
                        queueRow(row)
                            .id(row.key)
                            .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
                            .listRowBackground(Color.clear)
                            #if !os(tvOS)
                            .listRowSeparator(.hidden)
                            #endif
                        #endif
                    }
                    #if os(iOS)
                    .onMove { from, to in
                        guard let source = from.first else { return }
                        // `to` counts the row's own slot: a move down lands one before it.
                        let target = to > source ? to - 1 : to
                        store.reorder(from: Int32(source), to: Int32(target))
                    }
                    .onDelete { offsets in
                        for index in offsets.sorted(by: >) { store.removeAt(index: Int32(index)) }
                    }
                    #endif
                }
                .listStyle(.plain)
                #if !os(tvOS)
                .scrollContentBackground(.hidden)
                #endif
                .modifier(FollowCurrentRow(rows: queue.rows, currentIndex: Int(queue.currentIndex), reader: reader))
                .task {
                    guard focusCurrent, queue.rows.indices.contains(Int(queue.currentIndex)) else { return }
                    // Once the sheet has slid in.
                    try? await Task.sleep(for: .milliseconds(300))
                    rowFocus = queue.rows[Int(queue.currentIndex)].key
                }
            }
            .accessibilityIdentifier("music.queue")
        }
    }

    private func queueRow(_ row: TrackRowUi) -> some View {
        let index = row.index
        return TrackRow(
            title: row.title, subtitle: row.subtitle, duration: row.duration,
            isCurrent: index == queue.currentIndex, playing: playing, dimmed: row.dimmed,
            showsArtwork: true, artwork: row.artwork,
            onRemove: Self.removeButton ? { store.removeAt(index: index) } : nil,
            focus: ($rowFocus, row.key),
            id: "music.queue.\(index)"
        ) { store.jumpTo(index: index) }
    }

    /// A × per row where the list has no swipe: the Mac and Apple TV.
    private static var removeButton: Bool {
        #if os(iOS)
        false
        #else
        true
        #endif
    }

    /// A row's height for the follow logic: its artwork, the row's padding above and below it, and its insets.
    static let rowHeight: CGFloat = TrackRow.artworkSide + 16 + 2
}

/// Scrolls the queue to the current row as it opens, then to each new current row while the list still sits within a
/// row and a half of where the previous current row is at the top (rows are of one height, so that place is the row's
/// index times its height, within the list's scroll range): a list the user scrolled away stays where they put it.
private struct FollowCurrentRow: ViewModifier {
    let rows: [TrackRowUi]
    let currentIndex: Int
    let reader: ScrollViewProxy

    @State private var geometry = QueueScroll(offset: 0, maxOffset: 0)

    func body(content: Content) -> some View {
        let rowHeight = QueueList.rowHeight
        content
            .onAppear { scroll(to: currentIndex, animated: false) }
            .onChange(of: currentIndex) { previous, index in
                let anchor = min(max(CGFloat(previous) * rowHeight, 0), geometry.maxOffset)
                guard previous < 0 || abs(anchor - geometry.offset) <= rowHeight * 1.5 else { return }
                scroll(to: index, animated: true)
            }
            .modifier(QueueScrollWatch { geometry = $0 })
    }

    private func scroll(to index: Int, animated: Bool) {
        guard rows.indices.contains(index) else { return }
        let key = rows[index].key
        if animated {
            withAnimation(.easeOut(duration: 0.25)) { reader.scrollTo(key, anchor: .top) }
        } else {
            reader.scrollTo(key, anchor: .top)
        }
    }
}

/// Where the queue's list is scrolled to, and how far it can go.
private struct QueueScroll: Equatable {
    let offset: CGFloat
    let maxOffset: CGFloat
}

/// Reports the list's scroll position (Apple TV, macOS 15 and iOS 18 and later; before, the list always follows).
private struct QueueScrollWatch: ViewModifier {
    let onChange: (QueueScroll) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18, macOS 15, *) {
            content.onScrollGeometryChange(for: QueueScroll.self) { geometry in
                QueueScroll(
                    offset: geometry.contentOffset.y + geometry.contentInsets.top,
                    maxOffset: max(geometry.contentSize.height - geometry.containerSize.height, 0)
                )
            } action: { _, scroll in
                onChange(scroll)
            }
        } else {
            content
        }
    }
}

/// The queue: on iPhone and iPad a `SheetPage` titled "Queue" with the track count over the list, Close (iPad) and Edit
/// in the bar and Shuffle, Repeat and Clear upcoming (`controls`) at its end; on Apple TV and the Mac the
/// same title and controls over the list, in Apple TV's trailing panel (the remote's Menu closing it) and in the Mac's
/// side panel and full-window player (`MacNowPlaying`), which close it themselves. Under a Queue | Lyrics picker that
/// names it already (the Mac's side panel, `showsTitle` false) the count heads it alone.
struct QueueSheet: View {
    let queue: QueueUi
    let playing: Bool
    let store: NowPlayingStore
    var showsTitle = true
    let onClose: () -> Void

    var body: some View {
        #if os(tvOS) || os(macOS)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    if showsTitle {
                        Text(T.shared.music.queue)
                            .font(.title3.bold())
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text(queue.count)
                        .font(.footnote)
                        .foregroundStyle(Palette.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                controls
            }
            .shelfFocusSection()
            #if os(macOS)
            .padding(.horizontal, 16)
            #endif
            // The Mac's panes sit beside the screen in use: focus stays where it is.
            QueueList(queue: queue, playing: playing, store: store, focusCurrent: !isMac)
                .frame(maxHeight: .infinity)
        }
        #else
        SheetPage(title: T.shared.music.queue, close: SheetAction(title: T.shared.nav.close, id: "music.queue.close", action: onClose)) {
            QueueList(queue: queue, playing: playing, store: store, focusCurrent: true)
                .modifier(CountBar(count: queue.count))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton().accessibilityIdentifier("music.queue.edit")
                    }
                    ToolbarItemGroup(placement: .primaryAction) { controls }
                }
        }
        #endif
    }

    private var isMac: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }

    /// Shuffle and Repeat, toggles in Now Playing's look (on a filled disc while on, muted while off), and Clear upcoming:
    /// in the sheet's bar on iPhone and iPad, Now Playing's round buttons over the list on Apple TV and the Mac.
    @ViewBuilder
    private var controls: some View {
        #if os(iOS)
        Button(action: store.toggleShuffle) { Image(systemName: "shuffle").toggleDisc(queue.shuffled, diameter: 32) }
            .accessibilityLabel(T.shared.common.shuffle)
            .toggleState(queue.shuffled)
            .accessibilityIdentifier("music.queue.shuffle")
        Button(action: store.cycleRepeat) { Image(systemName: queue.repeatMode.systemImage).toggleDisc(queue.repeatMode != .off, diameter: 32) }
            .accessibilityLabel(queue.repeatMode.label)
            .toggleState(queue.repeatMode != .off)
            .accessibilityIdentifier("music.queue.repeat")
        Button(T.shared.music.clearQueue, systemImage: "text.badge.xmark", action: store.clearUpcoming)
            .accessibilityIdentifier("music.queue.clear")
        #else
        MusicIconButton(systemImage: "shuffle", label: T.shared.common.shuffle, size: 16, id: "music.queue.shuffle", isOn: queue.shuffled, action: store.toggleShuffle)
        MusicIconButton(
            systemImage: queue.repeatMode.systemImage, label: queue.repeatMode.label, size: 16, id: "music.queue.repeat",
            isOn: queue.repeatMode != .off, action: store.cycleRepeat
        )
        MusicIconButton(systemImage: "text.badge.xmark", label: T.shared.music.clearQueue, size: 16, id: "music.queue.clear", action: store.clearUpcoming)
        #endif
    }
}

#if os(iOS)
/// The track count over the queue's list: on iOS 26 and later a bar of the sheet's (`safeAreaBar`), so the rows that
/// scroll up under it fade there, as under the navigation bar, rather than print through the count (the list opens
/// scrolled to the current row: at large text sizes the rows before it sit under the count).
private struct CountBar: ViewModifier {
    let count: String

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.safeAreaBar(edge: .top, spacing: 0) { line }
        } else {
            content.safeAreaInset(edge: .top, spacing: 0) { line.background(.bar) }
        }
    }

    private var line: some View {
        Text(count)
            .font(.footnote)
            .foregroundStyle(Palette.onSurfaceVariant)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
    }
}
#endif
