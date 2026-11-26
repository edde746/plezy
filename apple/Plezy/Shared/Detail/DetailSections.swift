import SwiftUI
import PlezyKit

#if !os(tvOS)
/// The top of the details on a phone, a tablet or the Mac: the title (its logo where it has one), an episode's own
/// title, one metadata line (the year or air date, the certification, the runtime, the quality labels, the size, the
/// edition), the genres, the ratings row (each source's logo and score), the action row (`DetailActionRow`, with the
/// download and the track status; Rate is in its ⋯) and the overview (three lines, then More). On phones (`centred`)
/// everything but the overview is centred under the backdrop. While the item loads (`itemLoading`) the title shows
/// alone: what follows it comes in together once the item has landed, so nothing it brings moves the page.
struct DetailHeadline: View {
    let state: MediaDetailUiState
    let hero: DetailHeroUi
    let store: MediaDetailStore
    let menu: MediaMenu
    let centred: Bool
    /// The widest the logo may be.
    let logoWidth: CGFloat

    var body: some View {
        let alignment: HorizontalAlignment = centred ? .center : .leading
        let textAlignment: TextAlignment = centred ? .center : .leading
        VStack(alignment: alignment, spacing: 14) {
            VStack(alignment: alignment, spacing: 4) {
                DetailTitleArt(hero: hero, centered: centred, maxWidth: logoWidth, maxHeight: centred ? 140 : 180, fontSize: 34)
                    .anchorPreference(key: DetailTitleFrame.self, value: .bounds) { $0 }
                if let episodeTitle = hero.episodeTitle {
                    Text(episodeTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.onBackground)
                        .multilineTextAlignment(textAlignment)
                }
            }
            if !state.itemLoading {
                VStack(alignment: alignment, spacing: 8) {
                    let facts = hero.metadata + hero.qualityLabels + [hero.sizeLabel, hero.edition].compactMap { $0 }
                    if !facts.isEmpty {
                        FactsLine(alignment: alignment) {
                            ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                                if index > 0 {
                                    Text("·").lineLimit(1).frame(minWidth: 0).clipped()
                                }
                                Text(fact).fixedSize()
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Self.secondary)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(facts.joined(separator: ", "))
                        .accessibilityIdentifier("detail.facts")
                    }
                    if !hero.genres.isEmpty {
                        Text(hero.genres.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(Self.secondary)
                            .multilineTextAlignment(textAlignment)
                            .accessibilityIdentifier("detail.genres")
                    }
                    if !hero.ratings.isEmpty {
                        RatingsStrip(ratings: hero.ratings, weight: .semibold, alignment: alignment)
                            .foregroundStyle(Palette.onBackground)
                    }
                }
                DetailActionRow(actions: state.actions, kind: state.kind, store: store, menu: menu, download: state.download)
                if state.tracks != nil || state.tracksLoading {
                    TrackStatusLine(tracks: state.tracks, fontSize: 12.5)
                }
                if let summary = hero.summary {
                    DetailOverview(text: summary, color: Self.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: centred ? .center : .leading)
    }

    /// The facts', genres' and overview's colour, over the backdrop's foot.
    private static var secondary: Color { Palette.onBackdropVariant }
}

/// The headline's facts on as many lines as they need, a line breaking only between two facts: its children are the
/// facts with a separator between each two (fact, separator, fact, …). A separator shows only between two facts on one
/// line; at a break it takes no room, so no line ends or starts with one. Each line at the leading edge, or centred.
private struct FactsLine: Layout {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: lines.map(\.width).max() ?? 0, height: lines.map(\.height).reduce(0, +))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        var placed = Set<Int>()
        for line in arrange(width: bounds.width, subviews: subviews) {
            var x = alignment == .center ? bounds.minX + (bounds.width - line.width) / 2 : bounds.minX
            for (position, index) in line.indices.enumerated() {
                if position > 0 { x += spacing }
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                placed.insert(index)
                x += size.width
            }
            y += line.height
        }
        // The separators at the breaks: no room, so nothing shows.
        for index in subviews.indices where !placed.contains(index) {
            subviews[index].place(at: CGPoint(x: bounds.minX, y: bounds.minY), proposal: .zero)
        }
    }

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// The lines: each fact (even indices) with the separator before it, where both fit on the line.
    private func arrange(width: CGFloat, subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for index in stride(from: 0, to: subviews.count, by: 2) {
            let fact = subviews[index].sizeThatFits(.unspecified)
            if line.indices.isEmpty {
                line = Line(indices: [index], width: fact.width, height: fact.height)
                continue
            }
            let separator = subviews[index - 1].sizeThatFits(.unspecified)
            let needed = line.width + spacing + separator.width + spacing + fact.width
            if needed > width {
                lines.append(line)
                line = Line(indices: [index], width: fact.width, height: fact.height)
            } else {
                line.indices += [index - 1, index]
                line.width = needed
                line.height = max(line.height, separator.height, fact.height)
            }
        }
        if !line.indices.isEmpty { lines.append(line) }
        return lines
    }
}

/// A show's or season's episodes: the season chips (a show's, `DetailSeasonChips`, the first name starting where the
/// rows' thumbnails do), then the selected season's
/// episodes (`DetailEpisodeRow`), each part's spinner, error with Retry or empty text in its place. Reaching the last
/// row loads the next page; its failure shows Retry at the tail. For a deep link's first focus the chips scroll to as
/// "seasons" and each row by its episode id, and they take `focus` as "season/<id>" and "ep/<id>" (a row's ⋯ on the Mac
/// "epmenu/<id>"). On the Mac a controller's X opens the focused row's menu under its ⋯: one opener for the list, not a
/// focused value per row.
///
/// On the Mac the rows are buttons, which take keyboard focus, only while the keyboard is in the list (`keyboard`): every
/// focusable view is an item of the window's focus store, which SwiftUI rebuilds, with the window's preferences, each
/// time the lazy list makes or drops a row, so a scroll's frames over rows that are buttons ran past a 120 Hz display's
/// 8.3 ms. Otherwise a row and its ⋯ answer a click as their buttons do (`EpisodeClick`), and with the system's
/// keyboard navigation on a one-point stop at the list's top takes the keyboard in: it turns the rows into buttons and
/// gives the focus to the first row on screen. A deep link's row to focus does so at once. Focus leaving the rows turns
/// them back.
struct DetailEpisodesSection: View {
    let state: MediaDetailUiState
    let store: MediaDetailStore
    let menu: MediaMenu
    let thumbnailWidth: CGFloat
    let focus: FocusState<String?>.Binding

    #if os(macOS)
    @State private var anchors = EpisodeMenuAnchors()
    /// The keyboard is in the list: its rows and ⋯s are buttons, which take focus.
    @State private var keyboard = false
    /// The stop at the list's top has the focus and passes it on to a row (`enter`).
    @State private var entering = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if state.kind == .show, state.seasonsLoad != .content || !state.seasons.isEmpty {
                switch state.seasonsLoad {
                case .loading:
                    DetailSectionSpinner()
                case .error:
                    DetailSectionError(message: T.shared.messages.seasonsLoadFailed, onRetry: store.retrySeasons)
                case .empty:
                    DetailSectionEmpty(message: T.shared.messages.noSeasonsFound)
                default:
                    DetailSeasonChips(
                        seasons: state.seasons, selected: Int(state.selectedSeason), nameStart: DetailMetrics.rowInset,
                        onMenu: { store.openSeasonMenu($0, in: menu) }, focus: focus
                    ) {
                        store.selectSeason(index: Int32($0))
                    }
                    .id("seasons")
                    episodes
                }
            } else if state.seasonsLoad == .loading && state.episodes == nil {
                DetailSectionSpinner()
            } else {
                episodes
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail.episodes")
        #if os(macOS)
        .onChange(of: state.initialFocus?.episodeId, initial: true) { _, id in
            if id != nil, NSApp.isFullKeyboardAccessEnabled { keyboard = true }
        }
        .onChange(of: focus.wrappedValue) { _, key in
            if key == Self.entry {
                enter()
            } else if keyboard, !entering, !Self.inList(key) {
                keyboard = false
            }
        }
        #endif
    }

    @ViewBuilder
    private var episodes: some View {
        if let list = state.episodes {
            switch list.load {
            case .loading:
                DetailSectionSpinner()
            case .error:
                DetailSectionError(message: T.shared.messages.episodesLoadFailed, onRetry: store.retryEpisodes)
            case .empty:
                DetailSectionEmpty(message: T.shared.messages.noEpisodesFound)
            default:
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(list.rows, id: \.id) { row in
                        episodeRow(row)
                            .onAppear {
                                if list.hasMore, !list.moreFailed, row == list.rows.last { store.loadMoreEpisodes() }
                            }
                    }
                    if list.moreFailed {
                        DetailSectionError(message: T.shared.messages.episodesLoadFailed, onRetry: store.retryEpisodes)
                    } else if list.hasMore {
                        DetailSectionSpinner()
                    }
                }
                #if os(macOS)
                .coordinateSpace(.named(EpisodeMenuAnchors.space))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { [anchors] in anchors.list = $0 }
                .overlay(alignment: .top) { keyboardEntry }
                .itemMenuOpener(focusedEpisodeMenu, focused: focusedEpisode != nil)
                #endif
            }
        } else {
            DetailSectionSpinner()
        }
    }

    @ViewBuilder
    private func episodeRow(_ row: EpisodeRowUi) -> some View {
        #if os(macOS)
        DetailEpisodeRow(
            row: row, store: store, menu: menu, thumbnailWidth: thumbnailWidth, focus: focus, anchors: anchors, keyboard: keyboard
        )
        #else
        DetailEpisodeRow(row: row, store: store, menu: menu, thumbnailWidth: thumbnailWidth, focus: focus)
        #endif
    }

    #if os(macOS)
    /// The episode whose row has focus.
    private var focusedEpisode: String? {
        guard let key = focus.wrappedValue, key.hasPrefix("ep/") else { return nil }
        return String(key.dropFirst(3))
    }

    /// Opens the focused row's menu under its ⋯.
    private var focusedEpisodeMenu: () -> Void {
        let episode = focusedEpisode
        return { [anchors, store, menu] in
            guard let episode else { return }
            MenuAnchor.frame = anchors.frame(of: episode)
            store.openEpisodeMenu(episode, in: menu)
        }
    }

    /// The focus key of the stop at the list's top (`keyboardEntry`).
    private static let entry = "episodes"

    /// A row's or a ⋯'s focus key.
    private static func inList(_ key: String?) -> Bool {
        key?.hasPrefix("ep/") == true || key?.hasPrefix("epmenu/") == true
    }

    /// Where the keyboard comes into the list while its rows aren't buttons: a point at its top, in the key view loop
    /// with the system's keyboard navigation on, as the first row is with it on.
    @ViewBuilder
    private var keyboardEntry: some View {
        if !keyboard, NSApp.isFullKeyboardAccessEnabled {
            Color.clear
                .frame(height: 1)
                .focusable()
                .focusEffectDisabled()
                .focused(focus, equals: Self.entry)
                .accessibilityHidden(true)
        }
    }

    /// Turns the rows into buttons, then gives the focus to the first row on screen (by its ⋯'s place), once they are.
    private func enter() {
        guard let rows = state.episodes?.rows, let first = rows.first else { return }
        let shown = rows.first { anchors.frame(of: $0.id).map { $0.minY >= 0 } ?? false } ?? first
        entering = true
        keyboard = true
        DispatchQueue.main.async {
            focus.wrappedValue = "ep/\(shown.id)"
            entering = false
        }
    }
    #endif
}

#if os(macOS)
/// Where each episode row's ⋯ is, by episode id, kept out of the views' state: each ⋯'s place in the list (`space`),
/// which a scroll doesn't change, and the list's place in its window, which changes on every frame of one. A row's ⋯,
/// VoiceOver's Show menu and a controller's X on the focused row open the episode's menu under its ⋯.
@MainActor
final class EpisodeMenuAnchors {
    /// The list's coordinate space.
    static let space = "episodeList"

    var frames: [String: CGRect] = [:]
    var list: CGRect = .zero

    /// The ⋯ of `id`'s row in its window, as the list was last laid out.
    func frame(of id: String) -> CGRect? {
        frames[id]?.offsetBy(dx: list.minX, dy: list.minY)
    }
}

/// An episode row's or its ⋯'s click while it isn't a button (`DetailEpisodesSection`): its button's look, dimmed while
/// pressed, over the shape its button takes clicks in (`radius`), and one element to accessibility, a button whose
/// press runs `action`.
private struct EpisodeClick: ViewModifier {
    let radius: CGFloat
    let action: () -> Void

    @GestureState private var pressed = false

    func body(content: Content) -> some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .opacity(pressed ? 0.7 : 1)
            .onTapGesture(perform: action)
            .simultaneousGesture(LongPressGesture(minimumDuration: .infinity).updating($pressed) { down, state, _ in state = down })
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, action)
    }
}
#endif

/// An episode as a free-flowing row, no card: its 16:9 thumbnail (`EpisodeThumbnail`), the download's icon (online),
/// "N. Title", the metadata (up to two lines, broken only between its facts, so the audio and size at its end still
/// show) and two lines of the summary; hover, keyboard focus and a press lay a subtle fill behind the whole row.
/// Selecting it plays it; its menu (a long press, a right click, the ⋯ beside it) is the episode's shared menu. On the Mac
/// the row and its ⋯ are buttons only while the keyboard is in the list (`keyboard`, `DetailEpisodesSection`).
struct DetailEpisodeRow: View {
    let row: EpisodeRowUi
    let store: MediaDetailStore
    let menu: MediaMenu
    let thumbnailWidth: CGFloat
    /// The page's focus: the row is "ep/<id>" in it.
    let focus: FocusState<String?>.Binding
    #if os(macOS)
    /// Where the list's ⋯s are, this row's kept as it moves.
    let anchors: EpisodeMenuAnchors
    /// The keyboard is in the list: the row and its ⋯ are buttons, "ep/<id>" and "epmenu/<id>" in `focus`.
    let keyboard: Bool
    #endif

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        HStack(spacing: 0) {
            Group {
                #if os(macOS)
                if keyboard {
                    Button(action: play) { label }
                        .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: Radius.small + DetailMetrics.rowInset))
                        .focused(focus, equals: "ep/\(row.id)")
                } else {
                    label.modifier(EpisodeClick(radius: Radius.small + DetailMetrics.rowInset, action: play))
                }
                #else
                Button(action: play) { label }
                    .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: Radius.small + DetailMetrics.rowInset))
                    .focused(focus, equals: "ep/\(row.id)")
                #endif
            }
            // The download's state first (its icon says it to the eye only), then the watch state where the row has one.
            .accessibilityValue(([row.download?.label].compactMap { $0 } + (row.progress != nil || row.watched ? row.metadata : [])).joined(separator: ", "))
            .accessibilityIdentifier("detail.episode.\(row.id)")
            #if !os(iOS)
            // The list publishes the controller's opener for its focused row (`DetailEpisodesSection`); VoiceOver's
            // Show menu opens under the row's ⋯, whose place the list keeps.
            .mediaMenuTrigger(
                { store.openEpisodeMenu(row.id, in: menu) }, item: row, opener: false,
                anchor: { [anchors, id = row.id] in anchors.frame(of: id) }
            )
            #endif
            let dots = Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 44)
                .contentShape(Rectangle())
            #if os(macOS)
            // A plain button opening the episode's menu, the system's menu, under itself as its pull-down (`MenuAnchor`).
            // Drawn by SwiftUI alone: a `Menu` or a system-styled button would put an AppKit control in every row, which
            // AppKit hit-tests for the pointer and measures for the window's drag area on every frame of a scroll.
            Group {
                if keyboard {
                    Button(action: openMenuUnderDots) {
                        dots.focusRing(radius: Radius.small)
                    }
                    .buttonStyle(PressDimButtonStyle())
                    .focused(focus, equals: "epmenu/\(row.id)")
                } else {
                    dots.modifier(EpisodeClick(radius: 0, action: openMenuUnderDots))
                }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(EpisodeMenuAnchors.space)) } action: { [anchors, id = row.id] in
                anchors.frames[id] = $0
            }
            .foregroundStyle(Palette.onSurfaceVariant)
            .accessibilityLabel(T.shared.common.options)
            .accessibilityIdentifier("detail.episode.\(row.id).menu")
            #else
            // The system's menu, its entries read as it shows (`SystemItemMenu`).
            dots.modifier(SystemItemMenu(open: { store.openEpisodeMenu(row.id, in: menu) }, item: row, kind: .menu))
                .menuIndicator(.hidden)
                .buttonStyle(.borderless)
                .foregroundStyle(Palette.onSurfaceVariant)
                .accessibilityLabel(T.shared.common.options)
                .accessibilityIdentifier("detail.episode.\(row.id).menu")
            #endif
        }
    }

    private func play() {
        store.playEpisode(episodeId: row.id)
    }

    #if os(macOS)
    private func openMenuUnderDots() {
        MenuAnchor.frame = anchors.frame(of: row.id)
        MenuAnchor.pullDown = true
        store.openEpisodeMenu(row.id, in: menu)
    }
    #endif

    /// The thumbnail and the texts: the row's button's label.
    private var label: some View {
        HStack(alignment: .center, spacing: DetailMetrics.rowInset) {
            EpisodeThumbnail(row: row, size: CGSize(width: thumbnailWidth, height: thumbnailWidth * 9 / 16))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let download = row.download { EpisodeDownloadIcon(download: download) }
                    Text(row.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                if !row.metadata.isEmpty {
                    // No-break spaces inside each fact: a line breaks between "1080p" and "AAC Stereo", never
                    // inside "November 13, 2026".
                    Text(row.metadata.map { $0.replacingOccurrences(of: " ", with: "\u{00A0}") }.joined(separator: " · "))
                        .font(.caption)
                        .backdropMutedForeground()
                        .lineLimit(2)
                }
                if let summary = row.summary {
                    Text(summary)
                        .font(.caption)
                        .backdropMutedForeground()
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DetailMetrics.rowInset)
        .contentShape(Rectangle())
                .contentShape(Rectangle())
        #if os(iOS)
        // The long press's menu lifts the thumbnail alone, the texts left in place: the menu sits on a layer
        // over the whole row that draws the thumbnail again, since the system hides the view a context menu
        // is on while it lifts it. Inside the label, so a tap anywhere on the row still plays it.
        .overlay {
            EpisodeThumbnail(row: row, size: CGSize(width: thumbnailWidth, height: thumbnailWidth * 9 / 16))
                .padding(DetailMetrics.rowInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .contentShape(.interaction, Rectangle())
                .contentShape(
                    .contextMenuPreview,
                    LeadingThumbnailShape(
                        inset: DetailMetrics.rowInset,
                        size: CGSize(width: thumbnailWidth, height: thumbnailWidth * 9 / 16),
                        radius: Radius.small,
                        rightToLeft: layoutDirection == .rightToLeft
                    )
                )
                .mediaMenuTrigger({ store.openEpisodeMenu(row.id, in: menu) }, item: row)
        }
        #endif
    }
}

/// An episode's download in its row: a small spinner while it is being queued, else its status icon, muted (a little
/// larger while downloading, its ring filling).
private struct EpisodeDownloadIcon: View {
    let download: EpisodeDownloadUi

    var body: some View {
        if download.queueing {
            ProgressView().controlSize(.mini).frame(width: 12, height: 12)
        } else if let status = download.status {
            let downloading = status == .downloading
            DownloadStatusIcon(status: status, progress: download.progress.map { Double($0.floatValue) }, size: downloading ? 14 : 12)
                .opacity(0.7)
        }
    }
}

#endif

/// The cast as a shelf ("Cast") of round portraits with the name (two lines) and the role under each; selecting one
/// with a person id opens their screen.
struct DetailCastRow: View {
    let cast: [CastUi]
    let store: MediaDetailStore
    let navigate: (any Route) -> Void

    @Environment(\.dimens) private var dimens

    var body: some View {
        ShelfRow(title: T.shared.discover.cast, items: Array(cast.enumerated()), id: \.offset) { entry in
            // The size of the catalog detail's cast portraits.
            DetailCastCard(member: entry.element, width: dimens.posterWidth * 0.8) {
                if let route = store.castRoute(index: Int32(entry.offset)) { navigate(route) }
            }
            .accessibilityIdentifier("detail.cast.\(entry.offset)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail.cast")
    }
}

/// The overview, three lines until More opens the rest (Less closes it again), in `color` (the muted text colour by
/// default); More shows only where the text runs past three lines, its press reaching out of the layout to a 44 pt
/// target on touch screens.
struct DetailOverview: View {
    let text: String
    var id = "detail.overview"
    var color: Color?

    @State private var expanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var shownHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(color ?? Palette.onSurfaceVariant)
                .lineLimit(expanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { shownHeight = $0 }
                .background {
                    Text(text)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
                }
                .accessibilityIdentifier(id)
            if expanded || fullHeight > shownHeight + 1 {
                Button { withAnimation(.easeOut(duration: 0.2)) { expanded.toggle() } } label: {
                    Text(expanded ? T.shared.discover.less : T.shared.discover.more)
                        .font(.subheadline.weight(.semibold))
                        #if os(iOS)
                        .padding(.horizontal, Self.reach.width)
                        .padding(.vertical, Self.reach.height)
                        .contentShape(Rectangle())
                        #endif
                }
                // On Apple TV a pill, as every text button there; elsewhere a text button.
                #if os(tvOS)
                .pillButtonStyle()
                #else
                .buttonStyle(.borderless)
                #endif
                #if os(iOS)
                .padding(.horizontal, -Self.reach.width)
                .padding(.vertical, -Self.reach.height)
                #endif
                .accessibilityIdentifier("\(id).toggle")
            }
        }
    }

    #if os(iOS)
    /// Taken past the word on each side, out of the layout: 18 pt of text becomes a 44 pt target.
    private static let reach = CGSize(width: 8, height: 13)
    #endif
}

/// A section still loading: a spinner, centred.
struct DetailSectionSpinner: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(24)
            .accessibilityIdentifier("detail.section.loading")
    }
}

/// A section that failed: what failed and Retry.
struct DetailSectionError: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ErrorLine(text: message)
            ActionButton(title: T.shared.common.retry, id: "detail.section.retry", fullWidth: false, action: onRetry)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
}

/// A section with nothing in it: its text, muted and centred.
struct DetailSectionEmpty: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundStyle(Palette.onSurfaceVariant)
            .frame(maxWidth: .infinity)
            .padding(16)
    }
}

/// A show's seasons as a row of chips scrolling sideways, as the Apple TV app draws its tabs: no fill at rest, the
/// row's focus fill while focused; the selected one's name semibold in the text colour, the others' regular and dimmed;
/// a check marks a watched season and a ring of its watched share a partly watched one (`SeasonRing`), which VoiceOver
/// reads as the chip's value. A chip selects its season (on tvOS as focus lands on it, so passing through the row
/// lands on the selected chip and the next season is one Right); its menu (a long press, a right click, a held Select)
/// is the season's shared menu (`onMenu`, by season id: mark watched, download, delete). `nameStart` is where the first
/// name starts from the row's leading edge. The row opens scrolled to show the selected chip; on the Mac in the row's
/// middle, clear of the fades and scroll buttons at its ends (`SideScroll`), the seasons before and after it in sight.
struct DetailSeasonChips: View {
    let seasons: [SeasonTabUi]
    let selected: Int
    var nameStart: CGFloat = 0
    var onMenu: ((String) -> Void)?
    var focus: FocusState<String?>.Binding?
    let onSelect: (Int) -> Void

    @Environment(\.formFactor) private var formFactor

    var body: some View {
        let inset = ChipMetrics.inset(formFactor)
        ScrollViewReader { proxy in
            SideScroll {
                HStack(spacing: formFactor == .tv ? 8 : 4) {
                    ForEach(Array(seasons.enumerated()), id: \.element.id) { index, season in
                        chip(season, index: index)
                            .id(index)
                    }
                }
                .padding(.horizontal, max(nameStart - inset, 0))
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
            .clearOfVerticalBar()
            #if os(macOS)
            .onAppear { proxy.scrollTo(selected, anchor: .center) }
            #else
            .onAppear { proxy.scrollTo(selected) }
            #endif
        }
        .shelfFocusSection()
        // Moving into the row lands on the selected chip, so passing through it selects nothing.
        .modifier(SelectedChipFocus(focus: focus, key: seasons.indices.contains(selected) ? "season/\(seasons[selected].id)" : nil))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail.seasons")
    }

    private func chip(_ season: SeasonTabUi, index: Int) -> some View {
        let height = ChipMetrics.height(formFactor)
        let isSelected = index == selected
        return Button { if !isSelected { onSelect(index) } } label: {
            SeasonChipLabel(title: season.title, selected: isSelected, watched: season.watched, progress: season.progress?.doubleValue)
                .padding(.horizontal, ChipMetrics.inset(formFactor))
                .frame(minHeight: height)
                .contentShape(Capsule())
                #if os(iOS)
                // The page's own colour behind the chip gives it a body when a long press lifts it for its menu.
                .background(Palette.background, in: Capsule())
                .contentShape(.contextMenuPreview, Capsule())
                #endif
        }
        .buttonStyle(SurfaceButtonStyle(fill: .clear, radius: height / 2))
        .accessibilityLabel(season.title)
        .accessibilityValue(Self.value(of: season))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("detail.season.\(index)")
        .modifier(SeasonFocus(focus: focus, key: "season/\(season.id)", select: isSelected ? nil : { onSelect(index) }))
        .mediaMenuTrigger(onMenu.map { open in { open(season.id) } }, item: season)
    }

    /// What VoiceOver says of a season's progress: watched, the share watched, or nothing.
    private static func value(of season: SeasonTabUi) -> String {
        if season.watched { return T.shared.accessibility.mediaCardWatched }
        guard let progress = season.progress?.doubleValue else { return "" }
        return T.shared.accessibility.mediaCardPartiallyWatched(percent: String(Int((progress * 100).rounded())))
    }
}

private struct SelectedChipFocus: ViewModifier {
    let focus: FocusState<String?>.Binding?
    let key: String?

    func body(content: Content) -> some View {
        if let focus, let key {
            content.defaultFocus(focus, key, priority: .userInitiated)
        } else {
            content
        }
    }
}

/// A season chip's name in the chips' font (`ChipMetrics`), cut short past `ChipMetrics.maxNameWidth`; the selected
/// one's semibold, the others' regular and dimmed but while focused; after the name a watched season's checkmark, in
/// the name's font, weight and colour, so only the weight tells which season is selected, or a partly watched season's
/// ring of its `progress` in the checkmark's place and size.
private struct SeasonChipLabel: View {
    let title: String
    let selected: Bool
    let watched: Bool
    let progress: Double?

    @Environment(\.isFocused) private var focused
    @Environment(\.formFactor) private var formFactor

    var body: some View {
        let font = ChipMetrics.font(formFactor)
        HStack(spacing: formFactor == .tv ? 10 : 5) {
            // The semibold name sets the width, so a pick moves no chip.
            Text(title).font(font.weight(.semibold)).chipName(maxWidth: ChipMetrics.maxNameWidth(formFactor)).hidden()
                .overlay { Text(title).font(font.weight(selected ? .semibold : .regular)).lineLimit(1) }
            if watched {
                // As wide at either weight, as the name is.
                Image(systemName: "checkmark").font(font.weight(.semibold)).hidden()
                    .overlay { Image(systemName: "checkmark").font(font.weight(selected ? .semibold : .regular)) }
                    .accessibilityHidden(true)
            } else if let progress {
                Image(systemName: "checkmark").font(font.weight(.semibold)).hidden()
                    .overlay { SeasonRing(fraction: progress, onFill: focused) }
                    .accessibilityHidden(true)
            }
        }
        .opacity(selected || focused ? 1 : 0.8)
    }
}

/// How much of a season is watched, as a ring the checkmark's size: `fraction` of it in the accent, clockwise from the
/// top (counter-clockwise right to left), over a faint full track. On a focused chip's fill (`onFill`, Apple TV) in the
/// label's colour there: the base themes' accent is the text colour, which that fill takes.
private struct SeasonRing: View {
    let fraction: Double
    let onFill: Bool

    @Environment(\.formFactor) private var formFactor
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        let width: CGFloat = formFactor == .tv ? 3.5 : 2
        ZStack {
            Circle().stroke(.quaternary, lineWidth: width)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(onFill ? AnyShapeStyle(.primary) : AnyShapeStyle(Palette.primary), style: StrokeStyle(lineWidth: width, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: layoutDirection == .rightToLeft ? -1 : 1)
        }
        .padding(width / 2 + 1)
        .aspectRatio(1, contentMode: .fit)
    }
}

/// A season chip's place in the page's focus (`key`), where there is one; on tvOS the chip picks its season as focus
/// lands on it (`select`).
private struct SeasonFocus: ViewModifier {
    let focus: FocusState<String?>.Binding?
    let key: String
    let select: (() -> Void)?

    @FocusState private var own: Bool

    func body(content: Content) -> some View {
        Group {
            if let focus { content.focused(focus, equals: key) } else { content.focused($own) }
        }
        #if os(tvOS)
        .onChange(of: focus?.wrappedValue == key || own) { _, focused in if focused { select?() } }
        #endif
    }
}

#if os(iOS)
/// A row's thumbnail as a long press's menu lifts it: `size` at `inset` from the row's leading edge, centred down the
/// row, its corners `radius`.
struct LeadingThumbnailShape: Shape {
    let inset: CGFloat
    let size: CGSize
    let radius: CGFloat
    let rightToLeft: Bool

    func path(in rect: CGRect) -> Path {
        let x = rightToLeft ? rect.maxX - inset - size.width : rect.minX + inset
        let frame = CGRect(x: x, y: rect.midY - size.height / 2, width: size.width, height: size.height)
        return RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: frame)
    }
}
#endif

/// An episode's still, `size` points: blurred while spoilers are hidden, the icon on the surface without one, the
/// watched check at its top trailing corner, the progress along its foot (`ArtworkProgress`). The still is asked for at
/// that size as the row is made, not a layout pass later.
struct EpisodeThumbnail: View {
    let row: EpisodeRowUi
    let size: CGSize

    var body: some View {
        ZStack {
            Palette.surfaceContainerHighest
            RemoteImage(artwork: row.thumb, blurred: row.blurThumb, size: size) { failed in
                if failed { ArtworkPlaceholder(kind: .episode) }
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .topTrailing) {
            if row.watched, row.progress == nil {
                // White on the scrim whatever the theme, as a card's (`CardArtwork`): it sits on the artwork.
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Palette.scrim.opacity(0.55))
                    .font(.body)
                    .padding(6)
                    .accessibilityLabel(T.shared.accessibility.mediaCardWatched)
            }
        }
        .overlay {
            if let progress = row.progress {
                ArtworkProgress(value: progress.doubleValue)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
    }
}

/// A cast member's card: the round portrait (the person placeholder without one), then the name (two lines,
/// broken between words) with the role right under it, centred under the portrait as the catalog's cast. The card is
/// `width` wide, or as wide as the name's longest word where the text size makes that wider, so no word is broken or cut.
struct DetailCastCard: View {
    let member: CastUi
    let width: CGFloat
    let action: () -> Void

    /// The name's longest word at the current text size.
    @State private var wordWidth: CGFloat = 0

    private static let nameFont = Font.subheadline.weight(.semibold)

    var body: some View {
        let width = max(self.width, ceil(wordWidth))
        VStack(alignment: .center, spacing: PosterCard.captionGap) {
            Button(action: action) {
                RemoteImage(artwork: member.image) { failed in
                    if failed { ArtworkPlaceholder(kind: .person) }
                }
                .frame(width: width, height: width)
                .background(Palette.surfaceContainerHighest)
                .clipShape(Circle())
                .contentShape(Circle())
                .focusRing(radius: width / 2)
            }
            .cardButtonStyle(circular: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(member.name)
            .accessibilityValue(member.role ?? "")
            VStack(alignment: .center, spacing: 2) {
                Text(member.name)
                    .font(Self.nameFont)
                    .foregroundStyle(Palette.onBackground)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .background(alignment: .top) {
                        ZStack(alignment: .leading) {
                            ForEach(Array(member.name.split(whereSeparator: \.isWhitespace).enumerated()), id: \.offset) { _, word in
                                Text(word).font(Self.nameFont).fixedSize()
                            }
                        }
                        .fixedSize()
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { wordWidth = $0 }
                    }
                if let role = member.role {
                    Text(role)
                        .font(.caption)
                        .foregroundStyle(Palette.onSurfaceVariant)
                        .lineLimit(1)
                }
            }
            .accessibilityHidden(true)
        }
        .frame(width: width, alignment: .top)
    }
}

/// The extras ("Extras") as a shelf of cards (`caption` as theirs): each plays; its menu (a long press, a right click,
/// a held Select) is the extra's shared menu where it has one (online).
struct DetailExtrasRow: View {
    let extras: [MediaCardUi]
    let store: MediaDetailStore
    let menu: MediaMenu
    var caption = true

    var body: some View {
        ShelfRow(title: T.shared.discover.extras, items: extras, id: \.id) { card in
            PosterCard(
                card: card, shape: card.shape, caption: caption, onOpen: { store.playExtra(cardId: card.id) },
                onMenu: store.extraItem(cardId: card.id).map { item in
                    { menu.open(item: item, place: store.menuPlace, extras: [], playTrailer: nil, onRow: []) }
                }
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail.extras")
    }
}

/// The information: studio, directors and rating, each label muted beside its value.
struct DetailInformation: View {
    let rows: [InfoRowUi]

    @Environment(\.formFactor) private var formFactor

    var body: some View {
        let tv = formFactor == .tv
        Grid(alignment: .topLeading, horizontalSpacing: tv ? 24 : 12, verticalSpacing: tv ? 12 : 6) {
            ForEach(rows, id: \.label) { row in
                GridRow {
                    Text(row.label).foregroundStyle(Palette.onSurfaceVariant)
                    Text(row.value).foregroundStyle(Palette.onBackground).fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .font(tv ? .callout : .subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(tvOS)
        // One focus stop, so the page scrolls to it.
        .focusable()
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail.info")
    }
}
