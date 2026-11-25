import SwiftUI
import PlezyKit

#if os(tvOS)
/// The Apple TV's panels, where the system player (AVKit) puts their equivalents. A menu (Subtitles, Audio, Options)
/// opens as AVKit's transport-bar menus do: a glass card above its button, its trailing edge on the button's
/// (`PlayerOverlay` places it), the menu's name at its top, then its rows (a check on the current one), and in the track
/// menus More subtitles, Search subtitles and the delay after a divider, the audio menu's settings after its delay (as
/// the options list theirs: a page opens in place, Menu goes back to the audio). A track takes effect and closes the
/// menu, as a pick from a menu does; a held Select on a subtitle row shows that track as the second subtitle, or removes
/// it, and the menu stays open, the second's row carrying the "2" badge (`PlayerMenuContent.Entry.hold`). More subtitles
/// opens its languages in place, a language its subtitles (a pick adds the subtitle, selects it and closes the menu;
/// Menu goes back a page); the subtitle search, a delay opens in place. The Options menu lists the player's options:
/// an option with a page opens its choices in place (a pick closes the menu, Menu goes back to the options: the version
/// and quality in two groups, the sleep timer under its banner, the file info), a switch flips where it is (the playback
/// info's among them); watch together's row opens the room panel in place (`WatchTVSessionPanel`; Menu closes the menu
/// from there).
///
/// The chapters and the queue open as AVKit's info panel: their tabs over a glass card across the bottom (their
/// thumbnails in a row, the current one first in view), the transport bar out of the way (`TVControls` hides). Down from
/// the timeline, or a swipe down, opens it on its first tab; moving along the tabs switches them; Up from the tabs or
/// Menu closes it. Focus stays inside while either is open (`TVControls` steps aside), and goes back to what opened it as
/// it closes, as AVKit's does: the menu's button, the timeline for the tabs (`PlayerFocus.panelOpener`).
struct PlayerTVPanel: View {
    let tab: PlayerPanelTab
    let state: PlayerUiState
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    /// AVKit's menus are 450 pt across; the options' rows hold a symbol, a label and a value, so a little wider.
    static let menuWidth: CGFloat = 520
    /// The file info's card, which holds two columns of fields.
    static let fileInfoWidth: CGFloat = 1100
    @State private var rowsHeight: CGFloat?
    /// How far the card's rows have scrolled, back to 0 as a page opens (`rows`).
    @State private var rowsOffset: CGFloat = 0

    var body: some View {
        if tab.isPanelTab {
            tabs
        } else {
            let shape = RoundedRectangle(cornerRadius: 40, style: .continuous)
            // The first row's focus lift keeps clear of the title.
            VStack(alignment: .leading, spacing: 16) {
                Text(state.menu.map { state.menuTitle(menu: $0) } ?? "")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.onVideoSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 32)
                content
            }
            .padding(.vertical, 24)
            .frame(width: state.menu == .fileInfo ? Self.fileInfoWidth : Self.menuWidth)
            // The file info's small text and tonal cards read over a darker glass, as the panel's do, whatever the
            // video under it shows.
            .background(state.menu == .fileInfo ? Color.black.opacity(0.45) : .clear, in: shape)
            .playerGlass(in: shape)
            .focusSection()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("player.menu")
            .onChange(of: state.menu) { rowsOffset = 0 }
        }
    }

    // MARK: The tabs across the bottom

    /// The tabs there are: the chapters and the queue where the video has them.
    static func tabs(_ state: PlayerUiState) -> [PlayerPanelTab] {
        var tabs = [PlayerPanelTab]()
        if !state.chapters.isEmpty { tabs.append(.chapters) }
        if !state.queue.isEmpty { tabs.append(.queue) }
        return tabs
    }

    /// Opens the panel across the bottom on `tab` (the chapters or the queue), or switches it there.
    static func open(_ tab: PlayerPanelTab, state: PlayerUiState, store: PlayerStore) {
        store.dispatch(command: PlayerCommandOpenMenu(menu: tab == .chapters ? .chapters : .queue))
    }

    private var tabs: some View {
        let shape = RoundedRectangle(cornerRadius: 40, style: .continuous)
        return VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 16) {
                ForEach(Self.tabs(state), id: \.self) { tab in
                    Button(label(tab)) {}
                        .buttonStyle(PanelTabStyle(selected: tab == self.tab))
                        .focused(focus, equals: .panelTab(tab))
                        // Up from the tab's content lands on the tab shown, not on whichever lies above: the others
                        // take focus only from along the tabs.
                        .disabled(!focusOnTabs && tab != self.tab)
                        .onMoveCommand { if $0 == .up { close() } }
                        .accessibilityAddTraits(tab == self.tab ? .isSelected : [])
                        .accessibilityIdentifier("player.panel.\(tab.identifier)")
                }
            }
            // Across the panel's width, so Up from a card far to the right of the tabs still reaches them.
            .frame(maxWidth: .infinity, alignment: .leading)
            .focusSection()
            Group {
                switch tab {
                case .chapters:
                    PanelItems(items: state.chapters.map(PanelItems.Item.init), playing: !state.paused, focus: focus) { index in
                        if let command = state.chapters[index].command { store.dispatch(command: command) }
                    }
                    .accessibilityIdentifier("player.chapters.panel")
                default:
                    PanelItems(items: state.queue.map(PanelItems.Item.init), playing: !state.paused, focus: focus) { index in
                        store.dispatch(command: PlayerCommandPlayQueueItem(key: state.queue[index].key))
                    }
                    .accessibilityIdentifier("player.queue.panel")
                }
            }
            .frame(width: PlayerMetrics.panelWidth, alignment: .leading)
            // Its small text reads over a darker glass, whatever the video under it shows.
            .background(Color.black.opacity(0.45), in: shape)
            .playerGlass(in: shape)
        }
        // Moving along the tabs switches them, as AVKit's do.
        .onChange(of: focus.wrappedValue) { _, focused in
            if case .panelTab(let tab) = focused, tab != self.tab { Self.open(tab, state: state, store: store) }
        }
    }

    /// Focus is on one of the tabs.
    private var focusOnTabs: Bool {
        if case .panelTab = focus.wrappedValue { true } else { false }
    }

    private func label(_ tab: PlayerPanelTab) -> String {
        tab == .chapters ? T.shared.videoControls.chapters : T.shared.videoControls.queue
    }

    /// Up from the tabs closes the panel.
    private func close() {
        store.dispatch(command: PlayerCommandCloseMenu.shared)
    }

    // MARK: A menu's card

    @ViewBuilder
    private var content: some View {
        switch state.menu {
        case .subtitleDelay:
            DelayControl(delay: state.subtitleDelay, store: store, focus: focus)
        case .audioDelay:
            DelayControl(delay: state.audioDelay, store: store, focus: focus)
        case .customSpeed:
            CustomSpeedControl(speed: state.customSpeed, store: store, focus: focus)
        case .options:
            rows {
                ForEach(Array(state.menuOptions.enumerated()), id: \.offset) { _, option in
                    optionRow(option)
                }
            }
        case .watchTogether:
            if let watch = state.watch {
                WatchTVSessionPanel(watch: watch, store: store, focus: focus)
            }
        case .versions:
            if let versions = state.versions {
                let picks = (versions.showsVersions ? versions.versions : []) + versions.qualities
                rows {
                    if versions.showsVersions {
                        groupHeader(T.shared.videoControls.versionColumnHeader)
                        choiceRows(PlayerMenuContent.choices(versions.versions, store: store), offset: 0)
                    }
                    if !versions.qualities.isEmpty {
                        groupHeader(T.shared.videoControls.qualityColumnHeader)
                        choiceRows(PlayerMenuContent.choices(versions.qualities, store: store), offset: picks.count - versions.qualities.count)
                    }
                }
            }
        case .sleepTimer:
            let entries = PlayerMenuContent(.sleepTimer, state: state, store: store).entries
            let stopAt = entries.filter { !($0.command is PlayerCommandSetSleepTimer) }
            let durations = entries.filter { $0.command is PlayerCommandSetSleepTimer }
            rows {
                if let banner = state.sleepTimer {
                    Text(banner.text)
                        .font(.callout)
                        .padding(.horizontal, 20)
                        .accessibilityIdentifier("player.sleep.active")
                    if let extend = banner.extend {
                        PanelRow(label: extend, detail: nil, symbol: "plus", chevron: false, selected: false) {
                            store.dispatch(command: PlayerCommandExtendSleepTimer.shared)
                        }
                        .accessibilityIdentifier("player.sleep.extend")
                    }
                    Divider().padding(.vertical, 8)
                }
                groupHeader(T.shared.videoControls.sleepTimerStopAtHeader)
                choiceRows(stopAt, offset: 0)
                groupHeader(T.shared.videoControls.sleepTimerDurationHeader)
                choiceRows(durations, offset: stopAt.count)
            }
        case .subtitleSearch:
            if let search = state.subtitleSearch {
                SubtitleSearchRows(search: search, store: store, focus: focus)
            }
        case .fileInfo:
            if let info = state.fileInfo, !info.loading {
                if let error = info.error {
                    Text(error).foregroundStyle(.secondary).padding(32)
                } else if let file = info.info {
                    FileInfoContent(info: file, title: info.title, probe: "player.fileInfo", first: PanelFocus(focus: focus, value: .menuItem(0)))
                        .frame(maxHeight: 760)
                }
            } else {
                ProgressView().frame(maxWidth: .infinity).padding(32)
            }
        case .some(let menu):
            let content = PlayerMenuContent(menu, state: state, store: store)
            rows {
                choiceRows(content.entries, offset: 0)
                if content.more != nil || content.search || content.delay != nil {
                    Divider().padding(.vertical, 8)
                }
                if let more = content.more {
                    PanelRow(label: InterfaceLocale.shared.menuTitle(text: T.shared.player.menu.moreSubtitles), detail: nil, value: more, symbol: "plus.bubble", selected: false) {
                        store.dispatch(command: PlayerCommandOpenMenu(menu: .moreSubtitles))
                    }
                    .focused(focus, equals: .moreSubtitles)
                    .accessibilityIdentifier("player.menu.more")
                }
                if content.search {
                    PanelRow(label: InterfaceLocale.shared.menuTitle(text: T.shared.videoControls.searchSubtitles), detail: nil, symbol: "magnifyingglass", chevron: false, selected: false) {
                        store.dispatch(command: PlayerCommandOpenMenu(menu: .subtitleSearch))
                    }
                    .accessibilityIdentifier("player.menu.search")
                }
                if let delay = content.delay {
                    PanelRow(label: InterfaceLocale.shared.menuTitle(text: delay.title), detail: nil, value: delay.label, symbol: "timer", selected: false) {
                        store.dispatch(command: PlayerCommandOpenMenu(menu: delay.menu))
                    }
                    .accessibilityIdentifier("player.menu.delay")
                }
                if menu == .audio {
                    ForEach(Array(state.audioOptions.enumerated()), id: \.offset) { _, option in
                        optionRow(option)
                    }
                }
            }
            // Each page's rows are its own: a page opens scrolled to its top, and focus set on its row lands on a new
            // row (a row kept from the page before, relabelled, looked focused while no element reported focus).
            .id(menu)
        case nil:
            // The tabs across the bottom (`body`).
            EmptyView()
        }
    }

    /// A card's rows, in from its edges as AVKit's menus have them: the card as tall as its rows (`rowsHeight`, as they
    /// last measured), scrolling past `maxRowsHeight`; a scroll view alone takes the whole of it, a tall card round two
    /// rows. Rows that fit sit `restInset` in from the card's title and foot, with no fade. Rows that scroll sit
    /// `scrollEdge` in, and those scrolled past the top or the bottom fade out over it, starting 8 pt under the card's
    /// title and ending in the card's bottom padding. Under the title the outer `titleClear` of it shows nothing, so no
    /// line scrolled half past it reads as cut there; at the foot, while rows follow (the rows' height past the scrolled
    /// offset and the card), the fade runs `moreFade`, so the last row in view fades plainly away: a sign of more.
    private func rows<Rows: View>(@ViewBuilder _ rows: () -> Rows) -> some View {
        let edge = Self.scrollEdge
        let clear = Self.titleClear
        let limit = Self.maxRowsHeight
        let fits = (rowsHeight ?? limit) + 2 * Self.restInset <= limit
        let inset = fits ? Self.restInset : edge
        let full = (rowsHeight ?? limit) + 2 * inset
        let height = min(full, limit)
        let foot = full - rowsOffset - height > edge ? Self.moreFade : edge
        return ScrollView {
            VStack(alignment: .leading, spacing: 4) { rows() }
                // The rows' height and how far they have scrolled, from their frame in the scroll view.
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: { frame in
                    rowsHeight = frame.height
                    rowsOffset = max(0, inset - frame.minY)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, inset)
        }
        .frame(height: height)
        .mask {
            Group {
                if fits {
                    Color.black
                } else {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0), .init(color: .clear, location: clear / height),
                            .init(color: .black, location: edge / height), .init(color: .black, location: 1 - foot / height),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            // Only the scrolled edges fade: a focused row's lift reaches past the sides.
            .padding(.horizontal, -40)
        }
        // The fades reach into the 16 pt gap under the title (kept 8 pt clear of it) and the card's 24 pt bottom padding.
        .padding(.top, -8)
        .padding(.bottom, -20)
    }

    /// The most a card's rows take before they scroll: a card that tall still clears the screen's top safe area over
    /// the transport bar's buttons, and holds a subtitle menu of five tracks, Off and the sync whole.
    private static let maxRowsHeight: CGFloat = 660
    /// How far rows that fit sit in from the card's title and foot (`rows`).
    private static let restInset: CGFloat = 12
    /// The fade at a card's scrolled edges, and how much of the top one shows nothing (`rows`).
    private static let scrollEdge: CGFloat = 36
    private static let titleClear: CGFloat = 12
    /// The fade at a card's foot while rows follow: past a row's height, so the last row in view fades through.
    private static let moreFade: CGFloat = 120

    /// A group's name over its rows (Version, Quality; Stop at, Duration).
    private func groupHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.onVideoSecondary)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .accessibilityAddTraits(.isHeader)
    }

    /// An option's row (`PlayerFocus.option`): with its value and, for one with a page, a chevron; a page opens in place,
    /// a switch flips where it is, a row to read does nothing.
    private func optionRow(_ option: PlayerOption) -> some View {
        PanelRow(
            label: InterfaceLocale.shared.menuTitle(text: option.label),
            detail: option.detail,
            // A dimmed switch says why ("Not HDR"), not its state.
            value: option.value.isEmpty || !option.enabled ? nil : option.value,
            symbol: option.id.systemImage,
            chevron: option.page != nil,
            selected: false
        ) {
            if let page = option.page {
                store.dispatch(command: PlayerCommandOpenMenu(menu: page))
            } else if let toggle = option.toggle {
                store.dispatch(command: toggle)
            }
        }
        .disabled(!option.enabled)
        .focused(focus, equals: .option(option.id))
        .accessibilityIdentifier(option.id.identifier)
    }

    /// Entries as rows (`player.menu.item.<i>`, from `offset` on), focusable as `PlayerFocus.menuItem`; one that opens a
    /// page (the speeds' Custom) with the chevron, its empty value.
    private func choiceRows(_ entries: [PlayerMenuContent.Entry], offset: Int) -> some View {
        ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
            PanelRow(
                label: entry.label,
                detail: entry.detail,
                value: entry.value ?? (entry.command is PlayerCommandOpenMenu ? "" : nil),
                selected: entry.selected,
                second: entry.second,
                hold: entry.hold,
                action: entry.perform
            )
            .disabled(!entry.enabled)
            .focused(focus, equals: .menuItem(offset + index))
            .accessibilityIdentifier("player.menu.item.\(offset + index)")
        }
    }
}

private extension PlayerPanelTab {
    /// The tab's accessibility identifier: `player.panel.chapters`.
    var identifier: String {
        switch self {
        case .chapters: "chapters"
        case .queue: "queue"
        case .subtitles: "subtitles"
        case .audio: "audio"
        case .options: "options"
        }
    }
}

/// The chapters' or the queue's row of the panel across the bottom, as AVKit's chapters: each item a 16:9 thumbnail on
/// the system's card (lifted under focus), its title and its detail under it (the chapter's start, the episode's line);
/// an unwatched episode's thumbnail blurred past recognition while spoilers are hidden. The item playing carries the
/// now-playing mark over its thumbnail (`nowPlayingMark`, as the iPhone's and the Mac's lists and the music queue mark
/// theirs; moving while `playing`), its title bold, its title where every item's starts. The current item is scrolled
/// into view as the row shows. A pick seeks to the chapter or plays the entry; a chapter this device may not seek to (a
/// guest in a host-only room) is off.
private struct PanelItems: View {
    struct Item {
        let title: String
        let detail: String?
        let imageUrl: String?
        let placeholder: PlaceholderKind
        let current: Bool
        var spoiler = false
        var enabled = true

        init(_ chapter: ChapterItem) {
            title = chapter.title
            detail = chapter.start
            imageUrl = chapter.imageUrl
            placeholder = .movie
            current = chapter.current
            enabled = chapter.command != nil
        }

        init(_ entry: QueueItem) {
            title = entry.title
            detail = entry.subtitle
            imageUrl = entry.imageUrl
            placeholder = .episode
            current = entry.current
            spoiler = entry.spoiler
        }
    }

    let items: [Item]
    let playing: Bool
    let focus: FocusState<PlayerFocus?>.Binding
    let pick: (Int) -> Void

    private static let thumbnail = CGSize(width: 320, height: 180)

    var body: some View {
        ScrollViewReader { scroller in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 40) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 12) {
                            Button { pick(index) } label: {
                                RemoteImage(url: item.imageUrl, blurred: item.spoiler) { failed in
                                    // The playing item's mark stands alone: no placeholder symbol under its bars.
                                    if failed && !item.current { ArtworkPlaceholder(kind: item.placeholder) }
                                }
                                .frame(width: Self.thumbnail.width, height: Self.thumbnail.height)
                                .nowPlayingMark(item.current, playing: playing, scale: 3)
                                .clipped()
                            }
                            .buttonStyle(.card)
                            .disabled(!item.enabled)
                            .focused(focus, equals: .panelItem(index))
                            .accessibilityLabel(item.title)
                            .accessibilityValue([item.current ? T.shared.player.nowPlaying : nil, item.detail].compactMap { $0 }.joined(separator: ", "))
                            .accessibilityAddTraits(item.current ? .isSelected : [])
                            .accessibilityIdentifier("player.menu.item.\(index)")
                            Text(item.title)
                                .fontWeight(item.current ? .bold : .regular)
                                .font(.caption)
                                .lineLimit(1)
                            if let detail = item.detail {
                                Text(detail).font(.caption2).foregroundStyle(Palette.onVideoSecondary).lineLimit(1)
                            }
                        }
                        .frame(width: Self.thumbnail.width, alignment: .leading)
                        .id(index)
                    }
                }
                .padding(.horizontal, PlayerMetrics.panelPadding)
                .padding(.vertical, 32)
            }
            .scrollClipDisabled()
            // The row as tall as its cards (the panel fits its content): a horizontal scroll view takes all the height
            // it's offered.
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                if let current = items.firstIndex(where: \.current) { scroller.scrollTo(current, anchor: .center) }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// The info panel's tab, as AVKit's: a pill of the panel's material (the player's glass over the darker tint the panel
/// sets its small text on, so the name reads over a light picture), lighter while it is the tab shown, white with black
/// text under focus, shrinking a little while clicked (`tvPressed`).
struct PanelTabStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, selected: selected)
    }

    private struct Face: View {
        let configuration: Configuration
        let selected: Bool
        @Environment(\.isFocused) private var focused

        var body: some View {
            configuration.label
                .font(.callout.weight(.medium))
                .foregroundStyle(focused ? Color.black : Palette.onVideo)
                .padding(.horizontal, 34)
                .padding(.vertical, 17)
                .background {
                    ZStack {
                        Capsule().fill(Color.black.opacity(0.45))
                        Capsule().fill(focused ? Palette.onVideo : Palette.onVideo.opacity(selected ? 0.25 : 0.08))
                    }
                }
                .playerGlass(in: Capsule())
                .effectsAnimation(.easeOut(duration: 0.15), value: focused)
                .tvPressed(configuration.isPressed)
        }
    }
}

/// A row of the panel: a check on the current choice (the "2" badge on the second subtitle's), the label and its detail
/// line; or a row's own `symbol` with a value, and a chevron for a row that opens more. Under focus it turns white with
/// black text, as the system player's rows do; a click shrinks it a little (`tvPressed`). A row with a `hold` runs it on
/// a held Select (`PanelRowStyle`), the click that ends the press doing nothing, and offers it to VoiceOver by its name.
struct PanelRow: View {
    let label: String
    let detail: String?
    var value: String?
    /// The row's own symbol, shown always (the delay's timer, an option's); without one, a check on the selected row.
    var symbol: String?
    var chevron = true
    let selected: Bool
    /// The subtitle track showing as the second subtitle: its badge where the check goes, named for VoiceOver.
    var second = false
    var hold: PlayerMenuContent.Hold?
    let action: () -> Void
    @State private var press = HeldPress()

    var body: some View {
        Button {
            if press.held { press.held = false } else { action() }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: second ? PlayerMenuContent.secondBadgeSymbol : symbol ?? "checkmark")
                    .font(.body.weight(.semibold))
                    .opacity(selected || second || symbol != nil ? 1 : 0)
                    .frame(width: 36)
                // Label and value on one line where both fit whole; else the value goes under the label (as Settings'
                // values do), never cut short. The detail wraps to two lines.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) {
                        texts(value: nil)
                        Spacer(minLength: 16)
                        if let value { valueText(value).fixedSize() }
                    }
                    texts(value: value).frame(maxWidth: .infinity, alignment: .leading)
                }
                if value != nil, chevron {
                    Image(systemName: "chevron.forward").font(.body.weight(.semibold)).opacity(0.7)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PanelRowStyle(hold: hold.map { (press: press, action: $0.perform) }))
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityActions {
            if let hold, let name = hold.name { Button(name, action: hold.perform) }
        }
    }

    /// The label over the detail (and over `value` where it doesn't fit beside them).
    private func texts(value: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.body).lineLimit(1).fixedSize(horizontal: true, vertical: false)
            if let value { valueText(value) }
            if let detail {
                Text(detail).font(.caption).opacity(0.7).lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func valueText(_ value: String) -> some View {
        Text(value).font(.body.monospacedDigit()).opacity(0.7).lineLimit(1)
    }

    /// The value, the badge's name and the detail. Both value and detail: the Make host row's value is the action, its
    /// detail the participant's status. A detail after either is isolated: it can start with a track's or a device's
    /// name.
    private var accessibilityValue: String {
        let lead = [value, second ? T.shared.player.track.second : nil].compactMap { $0 }
        let tail = detail.map { lead.isEmpty ? $0 : IsolateKt.isolate(text: $0) }
        return (lead + [tail].compactMap { $0 }).joined(separator: T.shared.detail.listSeparator)
    }
}

/// One press of a row's Select (`PanelRow`): whether it ran the row's hold, so the click that ends it does nothing.
@MainActor
final class HeldPress {
    var held = false
}

/// A panel row's look, and its `hold`: Select down for half a second, as long as the system's long press takes, runs
/// the action and marks the press held. A row that can't be picked dims.
struct PanelRowStyle: ButtonStyle {
    var hold: (press: HeldPress, action: () -> Void)?

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, hold: hold)
    }

    private struct Face: View {
        let configuration: Configuration
        let hold: (press: HeldPress, action: () -> Void)?
        @Environment(\.isFocused) private var focused
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            configuration.label
                .foregroundStyle(focused ? Color.black : Palette.onVideo)
                .background(Capsule().fill(focused ? Palette.onVideo : .clear))
                .opacity(enabled ? 1 : 0.45)
                .effectsAnimation(.easeOut(duration: 0.15), value: focused)
                .tvPressed(configuration.isPressed)
                .task(id: configuration.isPressed) {
                    guard configuration.isPressed, let hold else { return }
                    hold.press.held = false
                    // Let go before: a click.
                    do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
                    hold.press.held = true
                    hold.action()
                }
        }
    }
}

/// A delay: − value + (disabled at the ends of the range; VoiceOver names them by the way they move the delay,
/// "Subtitle delay: earlier") and Reset, disabled at zero, under the card's title, the delay's name. A − or + held past
/// half a second steps a second at once and then every 200 ms until let go, the click that ends the hold doing nothing.
private struct DelayControl: View {
    let delay: DelayState
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 32) {
                step("minus", label: delay.decreaseLabel, id: "player.delay.decrease", command: delay.decrease, held: -1)
                    .disabled(!delay.canDecrease)
                    .focused(focus, equals: .delayDecrease)
                Text(delay.label)
                    .font(.title2.monospacedDigit())
                    .frame(minWidth: 200)
                    .accessibilityIdentifier("player.delay")
                step("plus", label: delay.increaseLabel, id: "player.delay.increase", command: delay.increase, held: 1)
                    .disabled(!delay.canIncrease)
            }
            Button(T.shared.player.menu.reset) { store.dispatch(command: delay.reset) }
                .playerActionStyle()
                .disabled(!delay.canReset)
                .accessibilityIdentifier("player.delay.reset")
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    /// − or +: `command` one step; held, `held` seconds a step.
    private func step(_ symbol: String, label: String, id: String, command: any PlayerCommand, held: Double) -> some View {
        let subtitles = delay.menu == .subtitleDelay
        return PlayerIconButton(systemImage: symbol, label: label, value: delay.label, id: id) {
            store.dispatch(command: command)
        } repeating: {
            store.dispatch(command: subtitles ? PlayerCommandAdjustSubtitleDelay(deltaSeconds: held) : PlayerCommandAdjustAudioDelay(deltaSeconds: held))
        }
    }
}

/// The custom speed: − value + (disabled at the ends of the player's range; VoiceOver names them Slower and Faster), a
/// step of the store's each, and Normal, disabled at 1×, under the card's title. A − or + held past half a second steps
/// a quarter at once and then every 200 ms until let go (the speed shortcuts' step), the click that ends the hold doing
/// nothing. Each change applies at once, as a preset's pick does.
private struct CustomSpeedControl: View {
    let speed: SpeedControl
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 32) {
                step("minus", label: speed.decreaseLabel, id: "player.speed.decrease", command: speed.decrease, held: PlayerCommandSpeedDown.shared)
                    .disabled(!speed.canDecrease)
                    .focused(focus, equals: .speedDecrease)
                Text(speed.label)
                    .font(.title2.monospacedDigit())
                    .frame(minWidth: 200)
                    .accessibilityIdentifier("player.speed")
                step("plus", label: speed.increaseLabel, id: "player.speed.increase", command: speed.increase, held: PlayerCommandSpeedUp.shared)
                    .disabled(!speed.canIncrease)
            }
            // Each line a focus section across the card: Down from − or + reaches Normal, which lies between them, and
            // Up from Normal comes back.
            .frame(maxWidth: .infinity)
            .focusSection()
            Button(T.shared.player.speed.normal) { store.dispatch(command: speed.reset) }
                .playerActionStyle()
                .disabled(!speed.canReset)
                .accessibilityIdentifier("player.speed.reset")
                .frame(maxWidth: .infinity)
                .focusSection()
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    /// − or +: `command` one step; held, `held` (a quarter) a step.
    private func step(_ symbol: String, label: String, id: String, command: any PlayerCommand, held: any PlayerCommand) -> some View {
        PlayerIconButton(systemImage: symbol, label: label, value: speed.label, id: id) {
            store.dispatch(command: command)
        } repeating: {
            store.dispatch(command: held)
        }
    }
}

/// The subtitle search (Plex) in the subtitle menu's card: the language (a menu of the languages) and the title
/// searched, then the results, a pick of which downloads it (one at a time), or the outcome. Opening it searches; an
/// edit of the title searches once it is submitted, a language pick at once.
private struct SubtitleSearchRows: View {
    let search: SubtitleSearchState
    let store: PlayerStore
    let focus: FocusState<PlayerFocus?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Menu {
                ForEach(Array(search.languages.enumerated()), id: \.offset) { _, language in
                    Button { store.dispatch(command: language.command) } label: {
                        if language.selected { Label(language.label, systemImage: "checkmark") } else { Text(language.label) }
                    }
                }
            } label: {
                Label(search.language, systemImage: "globe").lineLimit(1)
            }
            .accessibilityLabel(T.shared.videoControls.language)
            .accessibilityValue(search.language)
            .accessibilityIdentifier("player.search.language")
            SearchTitleField(search: search, store: store)
            if search.searching {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 24)
            } else {
                if let message = search.message {
                    Text(message).font(.caption).foregroundStyle(Palette.onVideoSecondary).padding(.horizontal, 20)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(search.results.enumerated()), id: \.offset) { index, result in
                            PanelRow(
                                label: result.label,
                                detail: result.detail,
                                symbol: search.downloading == result.key ? "arrow.down.circle" : nil,
                                chevron: false,
                                selected: false
                            ) {
                                store.dispatch(command: result.command)
                            }
                            .disabled(search.downloading != nil)
                            .focused(focus, equals: .menuItem(index))
                            .accessibilityIdentifier("player.menu.item.\(index)")
                        }
                    }
                }
                .frame(maxHeight: 480)
            }
        }
        .padding(.horizontal, 12)
    }
}

/// The searched title: the system's text entry, searching once the edit is submitted.
private struct SearchTitleField: View {
    let search: SubtitleSearchState
    let store: PlayerStore
    @State private var title: String?

    var body: some View {
        TextField(T.shared.videoControls.searchSubtitles, text: Binding(get: { title ?? search.title }, set: { title = $0 }))
            .onSubmit {
                store.dispatch(command: PlayerCommandSearchSubtitles(language: search.languageCode, title: title ?? search.title, now: true))
            }
            .accessibilityIdentifier("player.search.title")
    }
}

/// The file info's first field takes the remote's focus as the card opens.
private struct PanelFocus: ViewModifier {
    let focus: FocusState<PlayerFocus?>.Binding
    let value: PlayerFocus

    func body(content: Content) -> some View {
        content.focused(focus, equals: value)
    }
}
#endif
