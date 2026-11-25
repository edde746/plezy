import SwiftUI
import PlezyKit

/// A focus key of the guide (tvOS): a time navigation chip, a channel's cell, or a program's block (by its row's channel
/// and its place across the grid).
enum GuideFocusKey: Hashable {
    case nav(GuideTimeNavItem)
    case channel(Int32)
    case program(Int32, Double)
}

/// The Live TV guide (`GuideUiState`), as the TV guide is built: the time navigation as chips (◀ two hours back, the day
/// and the window's start, which opens the day picker (on Apple TV the system's menu), ▶ two hours on; a spinner while
/// a later window loads), then the time ruler over the channels, each a row of its airings on the window's time. The
/// ruler stays at the top as the channels scroll under it and the channel column at the leading edge as the time
/// scrolls, a time scrolled past the column held whole beside it until the next pushes it off; the grid stays clear of
/// iOS 27.1's vertical bar (`clearOfVerticalBar`); the line at now runs
/// through the ruler and the rows. A channel's cell shows its logo (else its number and name) and a star on a
/// favourite; an airing's block its title (the recording dot before it, NEW after it) and its episode or "{start} ·
/// {length}" (the start alone where that doesn't fit), the one on air a step lighter, a past one's title muted, its text
/// kept in view when it began before the time shown, none where the block shows too little of itself for it. The sizes
/// are `GuideLayout`'s, in the shared layouts' units (`Dimens.unit`).
///
/// - A channel's cell tunes it; its context menu (a long press, Select held, a secondary click) offers Watch Channel,
///   Favorite (checked on a favourite: `toggleFavorite`) and, while something airs on it, View details
///   (`longPressProgram` on `GuideRowChannel.airing`), where it can be recorded.
/// - A block opens the airing's details, on Apple TV tunes an airing on now (`tapProgram`); on Apple TV Select held
///   opens its details (`longPressProgram`).
/// - tvOS: the system's focus engine moves between the cells (`SurfaceButtonStyle`); each row is a focus section. The
///   store's jumps (a search result) put focus on their channel or airing (`focusRequest`), `entryRequest` on the first
///   channel's cell. Moving into the time navigation lands on the day chip, wherever focus comes from. A focused block
///   begun before the time shown brings the time back to its start, so it shows whole beside the channel column.
/// - The store's scrolls (`GuideUiState.scroll`: to now as a window loads, to a search result) are performed once each.
///
/// Accessibility identifiers: `livetv.guide`, `livetv.guide.loading`, `livetv.guide.earlier`, `livetv.guide.day`,
/// `livetv.guide.later`, `livetv.guide.grid`, `livetv.guide.channel.<channel index>` (its label the channel's name, its
/// value "Favorites" on a favourite), `livetv.guide.watch`, `livetv.guide.favorite` and `livetv.guide.details` (the
/// context menu's entries),
/// `livetv.guide.program.<channel index>.<block index>` (its label the title, its value the times),
/// `livetv.guide.menu.<index>`, `livetv.guide.menu.back` (Apple TV: a day's slot `livetv.guide.menu.<day>.<slot>`).
struct GuideView: View {
    let app: AppModel
    let state: GuideUiState
    let store: GuideStore
    /// Bumped to put focus on the first channel's cell (tvOS).
    let entryRequest: Int

    @Environment(\.dimens) private var dimens
    @Environment(\.formFactor) private var formFactor
    @Environment(\.screenSides) private var sides
    @FocusState private var focus: GuideFocusKey?
    /// How far the grid is scrolled, in points.
    @State private var scrolled = CGPoint.zero
    /// The grid's visible area, in points.
    @State private var viewport = CGSize.zero
    /// A scroll the store asked for before the grid was measured.
    @State private var pendingScroll: GuideScroll?

    var body: some View {
        VStack(alignment: .leading, spacing: formFactor == .tv ? 24 : 8) {
            timeNavigation
            if state.showsFullSpinner {
                LoadingStateView().accessibilityIdentifier("livetv.guide.loading")
            } else {
                grid
                    .opacity(state.showsReloadOverlay ? 0.6 : 1)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("livetv.guide")
        #if os(tvOS)
        .task(id: EntryFocus(request: entryRequest, ready: !state.showsFullSpinner)) {
            guard entryRequest > 0, !state.showsFullSpinner, let first = firstChannel else { return }
            await FocusRestore.restore($focus, to: .channel(first), hold: 1.5, replacing: true)
        }
        .onChange(of: state.focusRequest) { _, _ in
            guard let target = storeFocus else { return }
            Task { @MainActor in await FocusRestore.restore($focus, to: target, hold: 1, replacing: true) }
        }
        #endif
    }

    // MARK: Time navigation

    private var timeNavigation: some View {
        HStack(spacing: formFactor == .tv ? 16 : 8) {
            LiveTvChip(id: "livetv.guide.earlier", action: { store.selectTimeNav(item: .earlier) }) {
                Image(systemName: "chevron.backward")
            }
            .focused($focus, equals: .nav(.earlier))
            LiveTvMenuChip(id: "livetv.guide.day") { dayMenuEntries } label: { dayChipLabel }
                // A menu's label isn't read as its name.
                .accessibilityLabel(Text(verbatim: dayChipText))
                .focused($focus, equals: .nav(.day))
            LiveTvChip(id: "livetv.guide.later", action: { store.selectTimeNav(item: .later) }) {
                Image(systemName: "chevron.forward")
            }
            .focused($focus, equals: .nav(.later))
            if state.showsReloadOverlay { ProgressView() }
        }
        #if !os(tvOS)
        .glassGroup(spacing: 8)
        #endif
        .padding(.leading, sides.leading)
        .padding(.trailing, sides.trailing)
        .padding(.vertical, dimens.focusRoom)
        .shelfFocusSection()
        #if os(tvOS)
        // Into the row on its day chip, not on the chip nearest the focus: the system's glass buttons pad ◀ and ▶ wider
        // than their glyphs, so over the first channel's cell sits ◀ as much as the day.
        .defaultFocus($focus, .nav(.day), priority: .userInitiated)
        #endif
    }

    /// "Now" on the live window, else the window's day and time ("Tomorrow · 6:00 AM").
    private var dayChipText: String { [state.dayLabel, state.timeLabel].compactMap { $0 }.joined(separator: " · ") }

    private var dayChipLabel: some View {
        HStack(spacing: 6) {
            Text(verbatim: dayChipText)
            Image(systemName: "chevron.down").imageScale(.small)
        }
    }

    /// The day picker in the system's menu: "Now", then each day as a submenu of its time slots, on Apple TV a checkmark
    /// on the pick shown ("Now" on the live window, else the window's day). Elsewhere the chip names it: a submenu takes
    /// no check there (the Mac draws none, iOS indents that day alone). Built with the screen, so the days follow the
    /// window and the date. Identifiers `livetv.guide.menu.<day>`, a slot's `livetv.guide.menu.<day>.<slot>`.
    @ViewBuilder
    private var dayMenuEntries: some View {
        let slots = GuideWindowKt.guideTimeSlots()
        ForEach(Array(store.dayChoices().enumerated()), id: \.offset) { index, choice in
            if let day = choice.epochDay?.int64Value {
                Menu {
                    ForEach(Array(slots.enumerated()), id: \.offset) { slotIndex, slot in
                        Button(slot.label) { store.pickSlot(epochDay: day, slot: slot) }
                            .accessibilityIdentifier("livetv.guide.menu.\(index).\(slotIndex)")
                    }
                } label: {
                    #if os(tvOS)
                    if choice.selected {
                        Label(choice.label, systemImage: "checkmark")
                    } else {
                        Text(choice.label)
                    }
                    #else
                    Text(choice.label)
                    #endif
                }
                .accessibilityIdentifier("livetv.guide.menu.\(index)")
            } else {
                Button { store.pickDay(choice: choice) } label: {
                    #if os(tvOS)
                    if choice.selected {
                        Label(choice.label, systemImage: "checkmark")
                    } else {
                        Text(choice.label)
                    }
                    #else
                    Text(choice.label)
                    #endif
                }
                .accessibilityIdentifier("livetv.guide.menu.\(index)")
            }
        }
    }

    // MARK: Grid

    private var grid: some View {
        let unit = dimens.unit
        let layout = GuideLayout.shared
        let contentWidth = (layout.CHANNEL_COLUMN_WIDTH + layout.GRID_WIDTH) * unit
        return ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(state.rows, id: \.guideKey) { row in
                            switch onEnum(of: row) {
                            case .sourceHeader(let header):
                                sourceHeader(header)
                            case .channel(let channel):
                                channelRow(channel)
                            }
                        }
                    } header: {
                        ruler
                    }
                }
                .frame(width: contentWidth, alignment: .leading)
                .onGeometryChange(for: CGPoint.self) { geometry in
                    let frame = geometry.frame(in: .scrollView)
                    return CGPoint(x: max(0, -frame.minX).rounded(), y: max(0, -frame.minY).rounded())
                } action: { scrolled = $0 }
                .id(Self.contentId)
            }
            .scrollIndicators(.hidden)
            // Fewer channels than fill the area lie from its top, not centred.
            .defaultScrollAnchor(.topLeading)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                viewport = size
                if let pending = pendingScroll, size.width > 0 {
                    pendingScroll = nil
                    perform(pending, proxy: proxy)
                }
            }
            .onChange(of: state.scroll?.id, initial: true) {
                guard let scroll = state.scroll else { return }
                if viewport.width > 0 {
                    perform(scroll, proxy: proxy)
                } else {
                    pendingScroll = scroll
                }
            }
            // The store names what is in view (the day pill and the time beside it).
            .onChange(of: scrolled.x) { reportView() }
            .onChange(of: viewport.width) { reportView() }
            #if os(tvOS)
            // The focus engine counts a block under the channel column held over the airings (one begun before the time
            // shown) as in view: the time scrolls back to its start, so the focused block shows whole.
            .onChange(of: focus) { _, key in
                guard case .program(_, let left) = key, left < Double(scrolled.x / unit) else { return }
                perform(GuideScroll(id: 0, rowTop: nil, horizontal: GuideHorizontalScrollToProgram(left: left)), proxy: proxy)
            }
            #endif
            .accessibilityIdentifier("livetv.guide.grid")
        }
        // The grid scrolls sideways: it would run on under iOS 27.1's vertical bar, its airings under the bar's buttons.
        .clearOfVerticalBar()
    }

    /// The half hours' times over the programs, the line at now through them behind the times, which the background
    /// cuts out around their text (the line never crosses a time); the corner over the channel column held at the leading
    /// edge. Opaque, so the rows scroll under it unseen. A time whose mark has scrolled under the corner is held whole
    /// beside it until the next time comes up to it, then goes under the corner whole: never cut (`TimeSpan.held`).
    private var ruler: some View {
        let unit = dimens.unit
        let layout = GuideLayout.shared
        let channelWidth = layout.CHANNEL_COLUMN_WIDTH * unit
        let marks = state.timeMarks
        return TimeLayout {
            if let now = state.nowOffset?.doubleValue {
                Palette.live
                    .layoutValue(key: TimeSpan.self, value: nowSpan(now))
            }
            ForEach(Array(marks.enumerated()), id: \.element.epochSeconds) { index, mark in
                let next = index + 1 < marks.count ? channelWidth + marks[index + 1].left * unit : .infinity
                Text(mark.label)
                    .font(formFactor == .tv ? .callout : .caption)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .lineLimit(1)
                    .padding(.horizontal, 4 * unit)
                    .background(Palette.background)
                    .padding(.leading, 4 * unit)
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .layoutValue(
                        key: TimeSpan.self,
                        value: TimeSpan(x: channelWidth + mark.left * unit, width: layout.SLOT_WIDTH * unit, held: scrolled.x + channelWidth, next: next)
                    )
            }
            // Its background reaches back to the content's leading edge: what has scrolled past the column never shows
            // in the margin before it (Apple TV's grid draws past its leading edge).
            Palette.background
                .padding(.leading, -scrolled.x)
                .layoutValue(key: TimeSpan.self, value: TimeSpan(x: scrolled.x, width: channelWidth))
        }
        .frame(width: (layout.CHANNEL_COLUMN_WIDTH + layout.GRID_WIDTH) * unit, height: layout.TIME_HEADER_HEIGHT * unit)
        .background(Palette.background)
        .accessibilityHidden(true)
    }

    /// A source's header (its server and lineup), held at the leading edge.
    private func sourceHeader(_ header: GuideRowSourceHeader) -> some View {
        let unit = dimens.unit
        let layout = GuideLayout.shared
        return TimeLayout {
            Text(header.label)
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.onSurfaceVariant)
                .lineLimit(1)
                .padding(.leading, 8 * unit)
                .frame(maxHeight: .infinity, alignment: .leading)
                .layoutValue(key: TimeSpan.self, value: TimeSpan(x: scrolled.x, width: 2 * layout.SLOT_WIDTH * unit))
        }
        .frame(width: (layout.CHANNEL_COLUMN_WIDTH + layout.GRID_WIDTH) * unit, height: header.height * unit)
        .accessibilityAddTraits(.isHeader)
    }

    /// A channel: its airings' blocks on the window's time over the line at now, and its cell held at the leading edge
    /// over them. A focus section (tvOS).
    private func channelRow(_ row: GuideRowChannel) -> some View {
        let unit = dimens.unit
        let layout = GuideLayout.shared
        let gap = Self.gap * unit
        let channelWidth = layout.CHANNEL_COLUMN_WIDTH * unit
        return TimeLayout {
            if row.programs.isEmpty {
                Text(T.shared.liveTv.noPrograms)
                    .font(.caption)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .padding(.leading, 12 * unit)
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .layoutValue(key: TimeSpan.self, value: TimeSpan(x: scrolled.x + channelWidth, width: 2 * layout.SLOT_WIDTH * unit))
            }
            ForEach(Array(row.programs.enumerated()), id: \.offset) { index, cell in
                GuideProgramButton(
                    cell: cell, unit: unit, gap: gap, textInset: textInset(cell),
                    run: state.nowOffset.map { CGFloat($0.doubleValue - cell.left) * unit },
                    id: "livetv.guide.program.\(row.channelIndex).\(index)"
                ) {
                    store.tapProgram(channelIndex: row.channelIndex, program: cell.program)
                } onHold: {
                    store.longPressProgram(channelIndex: row.channelIndex, program: cell.program)
                }
                .focused($focus, equals: .program(row.channelIndex, cell.left))
                #if os(tvOS)
                // An airing that starts under the held channel cell overlaps it, so the focus engine finds nothing to
                // its left: Left goes to the channel.
                .onMoveCommand { direction in
                    if direction == .left, channelWidth + cell.left * unit < scrolled.x + channelWidth + gap {
                        focus = .channel(row.channelIndex)
                    }
                }
                #endif
                .layoutValue(key: TimeSpan.self, value: TimeSpan(x: channelWidth + cell.left * unit, width: max(cell.width * unit - gap, 1)))
            }
            GuideChannelButton(app: app, row: row, unit: unit) {
                store.tapChannel(channelIndex: row.channelIndex)
            } onToggleFavorite: {
                store.toggleFavorite(channelIndex: row.channelIndex)
            } onDetails: { airing in
                store.longPressProgram(channelIndex: row.channelIndex, program: airing)
            }
            .focused($focus, equals: .channel(row.channelIndex))
            .padding(.trailing, gap)
            // Back to the content's leading edge, as the ruler's corner.
            .background(Palette.background.padding(.leading, -scrolled.x))
            .layoutValue(key: TimeSpan.self, value: TimeSpan(x: scrolled.x, width: channelWidth))
        }
        .padding(.bottom, gap)
        .frame(width: (layout.CHANNEL_COLUMN_WIDTH + layout.GRID_WIDTH) * unit, height: row.height * unit, alignment: .topLeading)
        .background(alignment: .topLeading) {
            if let now = state.nowOffset?.doubleValue {
                Palette.live
                    .frame(width: nowSpan(now).width, height: row.height * unit)
                    .offset(x: nowSpan(now).x)
            }
        }
        .shelfFocusSection()
    }

    // MARK: Scrolls and focus

    /// The line at now across the content: `GuideLayout.NOW_LINE_WIDTH` wide, centred on now.
    private func nowSpan(_ now: Double) -> TimeSpan {
        let unit = dimens.unit
        let layout = GuideLayout.shared
        let width = layout.NOW_LINE_WIDTH * unit
        return TimeSpan(x: (layout.CHANNEL_COLUMN_WIDTH + now) * unit - width / 2, width: width)
    }

    /// How far in a block's text starts so a block begun before the time shown keeps its title in view; nil when the
    /// block shows too little of itself for its text.
    private func textInset(_ cell: GuideProgramCell) -> CGFloat? {
        let unit = dimens.unit
        let inset = GuideLayoutKt.guideBlockTextInset(left: cell.left, width: cell.width, scrollOffset: Double(scrolled.x / unit), gap: Self.gap)
        return inset.map { CGFloat($0.doubleValue) * unit }
    }

    /// Tells the store the airings in view, in `GuideLayout`'s units: from the scroll on, past the channel column.
    private func reportView() {
        guard viewport.width > 0 else { return }
        let unit = dimens.unit
        store.setView(start: Double(scrolled.x / unit), width: Double(viewport.width / unit) - GuideLayout.shared.CHANNEL_COLUMN_WIDTH)
    }

    /// Performs a scroll the store asked for: the row into view, the time to now or to the block, in `GuideLayout`'s
    /// units over the area under the ruler and past the channel column.
    private func perform(_ scroll: GuideScroll, proxy: ScrollViewProxy) {
        let unit = dimens.unit
        let layout = GuideLayout.shared
        let maxX = Double(((layout.CHANNEL_COLUMN_WIDTH + layout.GRID_WIDTH) * unit - viewport.width) / unit)
        let maxY = Double((layout.TIME_HEADER_HEIGHT + state.contentHeight) * unit - viewport.height) / Double(unit)
        let viewWidth = Double(viewport.width / unit) - layout.CHANNEL_COLUMN_WIDTH
        let viewHeight = Double(viewport.height / unit) - layout.TIME_HEADER_HEIGHT
        var x = Double(scrolled.x / unit)
        var y = Double(scrolled.y / unit)
        if let top = scroll.rowTop?.doubleValue,
           let target = GuideLayoutKt.guideRowScrollOffset(rowTop: top, viewportTop: y, viewportHeight: viewHeight, maxScroll: maxY)?.doubleValue {
            y = target
        }
        if let horizontal = scroll.horizontal {
            switch onEnum(of: horizontal) {
            case .toNow(let now):
                x = GuideLayoutKt.guideScrollToNowOffset(nowOffset: now.nowOffset, viewportWidth: viewWidth, maxScroll: maxX)
            case .toProgram(let program):
                if let target = GuideLayoutKt.guideProgramScrollOffset(left: program.left, currentOffset: x, viewportWidth: viewWidth, maxScroll: maxX)?.doubleValue {
                    x = target
                }
            }
        }
        let anchor = UnitPoint(x: maxX > 0 ? min(max(x / maxX, 0), 1) : 0, y: maxY > 0 ? min(max(y / maxY, 0), 1) : 0)
        withAnimation(.easeOut(duration: Double(layout.VERTICAL_SCROLL_MILLIS) / 1000)) {
            proxy.scrollTo(Self.contentId, anchor: anchor)
        }
    }

    /// The first channel's index in the order shown.
    private var firstChannel: Int32? {
        for row in state.rows {
            if case .channel(let channel) = onEnum(of: row) { return channel.channelIndex }
        }
        return nil
    }

    /// Where the store's focus is in the grid (a jump's channel or airing); nil elsewhere.
    private var storeFocus: GuideFocusKey? {
        let target = state.focus
        guard target.zone() == .grid else { return nil }
        if target.column == .channel { return .channel(target.channelIndex) }
        for row in state.rows {
            guard case .channel(let channel) = onEnum(of: row), channel.channelIndex == target.channelIndex else { continue }
            if let cell = channel.programs.first(where: { $0.program == target.program }) {
                return .program(target.channelIndex, cell.left)
            }
            return .channel(target.channelIndex)
        }
        return nil
    }

    private static let contentId = "livetv.guide.content"
    /// Between two blocks, sideways and down, in units.
    private static let gap = 4.0
}

/// When the guide gives focus to its first channel: asked for, once its rows show.
private struct EntryFocus: Hashable {
    let request: Int
    let ready: Bool
}

extension GuideRow {
    /// A row's identity in the grid: its source's label, or its channel's place.
    var guideKey: String {
        switch onEnum(of: self) {
        case .sourceHeader(let header): "source:\(header.label)"
        case .channel(let channel): "channel:\(channel.channelIndex)"
        }
    }
}

/// A channel's cell: its logo, else its number over its name, a star at the corner on a favourite. Its context menu
/// tunes it, adds it to the favourites or takes it off, and opens what airs on it now.
private struct GuideChannelButton: View {
    let app: AppModel
    let row: GuideRowChannel
    let unit: CGFloat
    let action: () -> Void
    let onToggleFavorite: () -> Void
    let onDetails: (LiveTvProgram) -> Void

    var body: some View {
        let channel = row.channel
        Button(action: action) {
            RemoteImage(
                artwork: app.liveTvArtwork(serverId: channel.serverId, path: channel.thumb, kind: .thumb),
                contentMode: .fit
            ) { _ in
                VStack(spacing: 0) {
                    if let number = channel.number {
                        Text(number).font(.caption2).opacity(0.7)
                    }
                    Text(channel.displayName).font(.caption.weight(.medium)).multilineTextAlignment(.center)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 8 * unit)
            .padding(.vertical, 4 * unit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing) {
                if row.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .accentForeground()
                        .padding(4 * unit)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SurfaceButtonStyle(fill: Palette.surfaceContainer, radius: Radius.small * unit))
        .itemMenu(entries: menu, probe: "livetv.guide.channelMenu")
        .accessibilityLabel(channel.displayName)
        .accessibilityValue(row.isFavorite ? T.shared.liveTv.favorites : "")
        .accessibilityIdentifier("livetv.guide.channel.\(row.channelIndex)")
    }
}

extension GuideChannelButton {
    /// Watch Channel, Favorite (checked on a favourite), and View details while something airs on it.
    private var menu: [ItemMenuEntry] {
        var entries = [
            ItemMenuEntry(label: T.shared.liveTv.watchChannel, systemImage: "play.tv", id: "livetv.guide.watch", action: action),
            ItemMenuEntry(label: T.shared.liveTv.favorite, systemImage: "star", id: "livetv.guide.favorite", selected: row.isFavorite, action: onToggleFavorite),
        ]
        if let airing = row.airing {
            entries.append(ItemMenuEntry(label: T.shared.mediaMenu.viewDetails, systemImage: "info.circle", id: "livetv.guide.details") { onDetails(airing) })
        }
        return entries
    }
}

/// An airing's block: the title (the recording dot before it, NEW after it) over the episode or the times (the start
/// alone where the times don't fit), its text `textInset` in, none without room for it (nil); the one on air a step
/// lighter, opaque, so the line at now behind the row never crosses its text, how far it has run (`run`, points from
/// its start) a bar along its foot in its text's colour; a past one's title as muted as its times but on Apple TV's
/// focused surface. On Apple TV Select held runs `onHold`.
private struct GuideProgramButton: View {
    let cell: GuideProgramCell
    let unit: CGFloat
    let gap: CGFloat
    let textInset: CGFloat?
    let run: CGFloat?
    let id: String
    let action: () -> Void
    let onHold: () -> Void

    var body: some View {
        let button = Button(action: action) {
            ZStack(alignment: .leading) {
                if let textInset {
                    GuideProgramText(cell: cell, unit: unit)
                        .padding(.leading, textInset)
                        .padding(.trailing, CGFloat(GuideLayout.shared.TEXT_PADDING) * unit)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .overlay(alignment: .bottomLeading) {
                if cell.timing == .airing, let run {
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(.foreground)
                            .frame(width: min(max(run, 0), proxy.size.width), height: GuideLayout.shared.NOW_LINE_WIDTH * unit)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SurfaceButtonStyle(fill: fill, radius: Radius.small * unit))
        .accessibilityLabel(cell.title)
        .accessibilityValue(cell.timeText ?? "")
        .accessibilityIdentifier(id)
        #if os(tvOS)
        button.onLongPressGesture(minimumDuration: 0.5, perform: onHold)
        #else
        button
        #endif
    }

    private var fill: Color {
        cell.timing == .airing ? Palette.surfaceContainerHigh : Palette.surfaceContainer
    }
}

/// A block's lines (`GuideProgramButton`): a past airing's title muted unless it sits on Apple TV's focused surface.
private struct GuideProgramText: View {
    let cell: GuideProgramCell
    let unit: CGFloat
    @Environment(\.onFocusedSurface) private var onFocusedSurface

    var body: some View {
        VStack(alignment: .leading, spacing: 2 * unit) {
            HStack(spacing: 4 * unit) {
                if cell.isRecordingScheduled {
                    Circle()
                        .fill(Palette.live)
                        .frame(width: 8 * unit, height: 8 * unit)
                        .accessibilityLabel(T.shared.liveTv.recordingScheduled)
                }
                Text(cell.title)
                    .font(.subheadline.weight(.medium))
                    .opacity(cell.timing == .past && !onFocusedSurface ? Self.muted : 1)
                if cell.isPremiere { BadgeView(text: T.shared.liveTv.premiereBadge, emphasis: .strong) }
            }
            Group {
                if let subtitle = cell.subtitle {
                    Text(subtitle)
                } else if let times = cell.timeText, let start = cell.startText {
                    ViewThatFits(in: .horizontal) {
                        Text(times)
                        Text(start)
                    }
                }
            }
            .font(.caption)
            .opacity(Self.muted)
        }
        .lineLimit(1)
    }

    /// The times' strength, and a past title's.
    private static let muted = 0.7
}

/// Where a view of a `TimeLayout` goes: `x` points from the content's leading edge, `width` wide. A ruler's time is
/// `held` there (the edge of the corner over the channel column) while its own `x` has scrolled past it, whole at its own
/// width, until the next time's `next` comes up to its end, which pushes it off: each time's text starts 8 pt into its
/// view, so the two texts stay 8 pt apart.
private struct TimeSpan: LayoutValueKey {
    static let defaultValue = TimeSpan(x: 0, width: 0)

    let x: CGFloat
    let width: CGFloat
    var held: CGFloat?
    var next: CGFloat = .infinity
}

/// Lays its views out across the time, each at its `TimeSpan` from the leading edge and as tall as the layout; the layout
/// takes the size it is offered. A held time sits where it is held while the next time leaves it room there, and once it
/// doesn't, wholly before the held edge (under the corner drawn there), never partly.
private struct TimeLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let span = subview[TimeSpan.self]
            var x = span.x
            var width = span.width
            if let held = span.held, held > span.x {
                width = subview.sizeThatFits(.unspecified).width
                x = span.next - width >= held ? held : held - width
            }
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY), anchor: .topLeading,
                proposal: ProposedViewSize(width: width, height: bounds.height)
            )
        }
    }
}
