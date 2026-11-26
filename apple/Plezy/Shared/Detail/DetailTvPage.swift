import SwiftUI
import PlezyKit

/// The detail page on a TV (Apple TV, Force TV mode): the backdrop across the whole screen, darkened from the leading
/// side and the foot; the foreground column at the leading side (the information block: the logo or title, an
/// episode's own title, the metadata line with the scores, three lines of the summary; then the action row and, under
/// it at its leading edge, the track status it plays with); under them the rail: the season chips and the selected
/// season's episodes, the cast, the extras and the related hubs. The information block shows as soon as the item does
/// (the card's while the server's loads); the actions (their room kept meanwhile) and the rail come in whole once the
/// page is `ready`, Play focused. While an episode card has focus the hero, Play and the track status follow that
/// episode (`MediaDetailStore.focusEpisode`); focus anywhere else gives them back to the item. Selecting the
/// information block opens the details sheet (`DetailInfoSheet`).
struct DetailTvPage: View {
    let state: MediaDetailUiState
    let hero: DetailHeroUi
    let store: MediaDetailStore
    let menu: MediaMenu
    let appearance: Appearance
    let navigate: (any Route) -> Void
    /// The shared menu (or its question) is up over the app.
    let menuShown: Bool

    /// The information block's key in `focus`; an episode card's is `detail.episode.<id>`.
    private static let infoKey = "detail.info"
    private static let episodePrefix = "detail.episode."

    @FocusState private var focus: String?
    /// What had focus as an overlay came up: it gets focus back once the overlay goes (the panel or menu leaves focus
    /// to the screen's first view as it closes).
    @State private var focusBeforeOverlay: String?
    @State private var showingDetails = false
    @Environment(\.dimens) private var dimens

    var body: some View {
        GeometryReader { proxy in
            let unit = dimens.unit
            let tvScale = TvScale.shared.of(height: Double(proxy.size.height / unit))
            let scale = tvScale * unit
            let sides = TvRailLayout.shared.horizontalInset(scale: tvScale) * unit
            let width = proxy.size.width
            ZStack(alignment: .topLeading) {
                backdrop
                    .frame(width: proxy.size.width, height: proxy.size.height)
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
                        foreground(scale: scale, tvScale: tvScale)
                            .frame(maxWidth: width * 0.55, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, sides)
                            // The hero's bottom sits at 60 % of the screen; a taller block grows down from the
                            // title-safe area's top (60 pt) rather than up past it.
                            .padding(.top, 60)
                            .frame(minHeight: proxy.size.height * 0.6, alignment: .bottomLeading)
                        if state.ready {
                            rails(sides: sides)
                                .padding(.top, 16 * scale)
                                .padding(.bottom, 32 * scale)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
        }
        .ignoresSafeArea()
        .defaultFocus($focus, DetailActionRow.playKey)
        .task(id: state.ready) {
            guard state.ready else { return }
            await FocusRestore.restore($focus, to: DetailActionRow.playKey, hold: 1)
        }
        .onChange(of: focus) { _, key in
            // An overlay takes focus away; the hero keeps the episode under it.
            guard !overlayShown else { return }
            store.focusEpisode(episodeId: key.flatMap(Self.episodeId))
        }
        .onChange(of: overlayShown) { _, shown in
            if shown {
                focusBeforeOverlay = focus
            } else if let key = focusBeforeOverlay {
                focusBeforeOverlay = nil
                Task { await FocusRestore.restore($focus, to: key, replacing: true) }
            }
        }
        .appSheet(isPresented: $showingDetails, id: "detail.infoPanel", size: .panel) {
            DetailInfoSheet(hero: hero) { showingDetails = false }
        }
    }

    private var backdrop: some View {
        let background = Palette.background
        return ZStack {
            Palette.background
            CyclingBackdrop(backdrops: hero.backdrops, alignment: .top)
            LinearGradient(
                stops: [
                    .init(color: background.opacity(0.92), location: 0),
                    .init(color: background.opacity(0.6), location: 0.4),
                    .init(color: background.opacity(0), location: 0.75),
                ],
                startPoint: .leading, endPoint: .trailing
            )
            LinearGradient(
                stops: [
                    .init(color: background.opacity(0), location: 0.35),
                    .init(color: background.opacity(0.85), location: 0.75),
                    .init(color: background, location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private func foreground(scale: CGFloat, tvScale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { showingDetails = true } label: {
                info(scale: scale, tvScale: tvScale)
            }
            .buttonStyle(DetailInfoBlockStyle(radius: 8 * scale))
            .focused($focus, equals: Self.infoKey)
            .focusEffectDisabled()
            .accessibilityLabel(infoLabel)
            .accessibilityHint(T.shared.mediaMenu.viewDetails)
            .accessibilityIdentifier("detail.info")
            // The actions keep their room until the page is ready, so the block above doesn't move as they come in.
            VStack(alignment: .leading, spacing: 0) {
                DetailActionRow(actions: state.actions, kind: state.kind, store: store, menu: menu, download: state.download, focus: $focus)
                    .padding(.top, 10 * scale)
                    .shelfFocusSection()
                if state.tracks != nil || state.tracksLoading {
                    TrackStatusLine(tracks: state.tracks, fontSize: 15 * scale)
                        .padding(.top, 12 * scale)
                }
            }
            .opacity(state.ready ? 1 : 0)
            .disabled(!state.ready)
            .accessibilityHidden(!state.ready)
        }
    }

    /// The information block: the logo or title, an episode's own title, the metadata line (the year or air date, the
    /// certification, the runtime, then the scores on the one line) and three lines of the summary.
    private func info(scale: CGFloat, tvScale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            DetailTitleArt(hero: hero, centered: false, maxWidth: 790 * scale, maxHeight: 220 * scale, fontSize: 56 * scale)
            if let episodeTitle = hero.episodeTitle {
                Text(episodeTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.onBackground)
                    .lineLimit(1)
                    .padding(.top, 4 * scale)
            }
            if !hero.metadata.isEmpty || !hero.ratings.isEmpty {
                HStack(spacing: 0) {
                    Text(hero.metadata.joined(separator: "  •  ") + (hero.metadata.isEmpty || hero.ratings.isEmpty ? "" : "  •  "))
                        .layoutPriority(1)
                    RatingsStrip(
                        ratings: hero.ratings, textSize: 18 * tvScale, weight: .semibold, iconSize: 18 * tvScale,
                        iconGap: 4 * tvScale, entryGap: 12 * tvScale, oneLine: true
                    )
                }
                .font(.headline)
                .foregroundStyle(Palette.onBackground)
                .lineLimit(1)
                .padding(.top, 6 * scale)
            }
            if let summary = hero.summary {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .lineLimit(3)
                    .lineSpacing(4 * scale)
                    .padding(.top, 4 * scale)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The information block read as one: the title, the episode's title, the metadata, the genres, the summary.
    private var infoLabel: String {
        ([hero.title, hero.episodeTitle].compactMap { $0 } + hero.metadata + hero.genres + [hero.summary].compactMap { $0 })
            .joined(separator: ", ")
    }

    /// An overlay over the app takes focus from the page: the shared menu, its question, the details sheet.
    private var overlayShown: Bool { menuShown || showingDetails }

    /// The episode id of an episode card's focus key; nil for any other key.
    private static func episodeId(_ key: String) -> String? {
        key.hasPrefix(episodePrefix) ? String(key.dropFirst(episodePrefix.count)) : nil
    }

    /// The rail's shelves: the episodes (`episodesRail`), the cast, the extras (a held Select opens an extra's menu)
    /// and the related hubs (ending in View all where they have more).
    @ViewBuilder
    private func rails(sides: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: dimens.sectionSpacing) {
            if state.kind == .show {
                episodesRail(sides: sides)
            }
            if !state.cast.isEmpty {
                DetailCastRow(cast: state.cast, store: store, navigate: navigate)
            }
            if !state.extras.isEmpty {
                DetailExtrasRow(extras: state.extras, store: store, menu: menu, caption: !appearance.tvFullCardLayout)
            }
            ForEach(state.related, id: \.id) { hub in
                HubShelf(
                    hub: hub, caption: !appearance.tvFullCardLayout,
                    onOpen: { card in if let route = store.relatedRoute(cardId: card.id) { navigate(route) } },
                    onMenu: { card in
                        if let item = store.relatedItem(cardId: card.id) {
                            menu.open(item: item, place: store.menuPlace, extras: [], playTrailer: nil, onRow: [])
                        }
                    },
                    onViewAll: { if let route = store.relatedHubRoute(hubId: hub.id) { navigate(route) } }
                )
            }
        }
        .environment(\.dimens.screenPadding, sides)
    }

    /// The episode of `list` focus enters the row on: the route's (`initialEpisodeId`), else the on-deck one, else the
    /// first.
    private func initialEpisode(in list: EpisodeListUi) -> String? {
        (list.rows.first { $0.id == state.initialEpisodeId } ?? list.rows.first { $0.onDeck } ?? list.rows.first)?.id
    }

    private func railHeader(_ title: String, sides: CGFloat) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Palette.onBackground)
            .lineLimit(1)
            .accessibilityAddTraits(.isHeader)
            .padding(.horizontal, sides)
    }

    /// The season chips (a show's), then the selected season's episodes as cards; the next page loads as the last card
    /// shows. A heading names the season only where no chips do. The heading, the chips and a section's states sit
    /// `headerGap` apart; the cards `headingGap` under what is over them.
    @ViewBuilder
    private func episodesRail(sides: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Self.headerGap) {
            let chips = state.kind == .show && state.seasonsLoad == .content && state.seasons.count > 1
            if !chips {
                let season = state.seasons.indices.contains(Int(state.selectedSeason)) ? state.seasons[Int(state.selectedSeason)].title : nil
                railHeader(season ?? T.shared.libraries.groupings.episodes, sides: sides)
            }
            if state.kind == .show {
                switch state.seasonsLoad {
                case .loading:
                    DetailSectionSpinner()
                case .error:
                    DetailSectionError(message: T.shared.messages.seasonsLoadFailed, onRetry: store.retrySeasons)
                case .empty:
                    DetailSectionEmpty(message: T.shared.messages.noSeasonsFound)
                default:
                    if state.seasons.count > 1 {
                        DetailSeasonChips(
                            seasons: state.seasons, selected: Int(state.selectedSeason), nameStart: sides,
                            onMenu: { store.openSeasonMenu($0, in: menu) }, focus: $focus
                        ) {
                            store.selectSeason(index: Int32($0))
                        }
                    }
                }
            }
            if let list = state.episodes {
                switch list.load {
                case .loading:
                    DetailSectionSpinner()
                case .error:
                    DetailSectionError(message: T.shared.messages.episodesLoadFailed, onRetry: store.retryEpisodes)
                case .empty:
                    DetailSectionEmpty(message: T.shared.messages.noEpisodesFound)
                default:
                    ScrollViewReader { reader in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(alignment: .top, spacing: dimens.gutter) {
                                ForEach(list.rows, id: \.id) { row in
                                    DetailTvEpisodeCard(row: row, store: store, menu: menu, focus: $focus, key: Self.episodePrefix + row.id)
                                        .id(row.id)
                                        .onAppear {
                                            if list.hasMore, !list.moreFailed, row == list.rows.last { store.loadMoreEpisodes() }
                                        }
                                }
                                if list.moreFailed {
                                    Button(T.shared.common.retry, action: store.retryEpisodes)
                                        .accessibilityIdentifier("detail.section.retry")
                                } else if list.hasMore {
                                    ProgressView().frame(width: dimens.cardWidth(.wide) / 2)
                                }
                            }
                            .padding(.horizontal, sides)
                            .padding(.top, dimens.headingGap - Self.headerGap)
                            .padding(.bottom, dimens.focusRoom)
                        }
                        .scrollClipDisabled()
                        .shelfFocusSection()
                        // Moving down into the row lands on the episode the route names, else the on-deck one, else the
                        // first; the row opens scrolled to it.
                        .defaultFocus($focus, initialEpisode(in: list).map { Self.episodePrefix + $0 }, priority: .userInitiated)
                        .task(id: "\(state.selectedSeason)-\(initialEpisode(in: list) ?? "")") {
                            guard let initial = initialEpisode(in: list) else { return }
                            // Once the row has laid its cards out.
                            try? await Task.sleep(for: .milliseconds(100))
                            reader.scrollTo(initial, anchor: .leading)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("detail.episodes")
    }

    /// Between the episodes' heading, the season chips and a section's states.
    #if os(tvOS)
    private static let headerGap: CGFloat = 12
    #else
    private static let headerGap: CGFloat = 8
    #endif
}

/// An episode's card on the TV rail: its still (`EpisodeThumbnail`, with its progress or watched check) in the card
/// button style, then "N. Title" and the metadata. Selecting it plays it; a long press of Select opens the episode's
/// shared menu. It takes focus as `key` of the page's `focus`.
private struct DetailTvEpisodeCard: View {
    let row: EpisodeRowUi
    let store: MediaDetailStore
    let menu: MediaMenu
    let focus: FocusState<String?>.Binding
    let key: String

    @Environment(\.dimens) private var dimens

    var body: some View {
        let width = dimens.cardWidth(.wide)
        VStack(alignment: .leading, spacing: PosterCard.captionGap) {
            Button(action: { store.playEpisode(episodeId: row.id) }) {
                EpisodeThumbnail(row: row, size: CGSize(width: width, height: width * 9 / 16))
                    .focusRing(radius: Radius.medium)
            }
            .cardButtonStyle()
            .focused(focus, equals: key)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(row.title)
            .accessibilityValue(row.metadata.joined(separator: ", "))
            .accessibilityIdentifier("detail.episode.\(row.id)")
            .mediaMenuTrigger({ store.openEpisodeMenu(row.id, in: menu) }, item: row)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.onBackground)
                    .lineLimit(1)
                Text(row.metadata.prefix(2).joined(separator: " · ").ifEmpty(" "))
                    .font(.caption)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .lineLimit(1)
            }
            .accessibilityHidden(true)
        }
        .frame(width: width, alignment: .leading)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

/// The TV hero's information block as one button: no look of its own; focused, a light fill (the text colour at the
/// focus fill's alpha) with `radius` corners around it, without growing.
private struct DetailInfoBlockStyle: ButtonStyle {
    let radius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        Block(configuration: configuration, radius: radius)
    }

    private struct Block: View {
        let configuration: Configuration
        let radius: CGFloat
        @Environment(\.isFocused) private var focused

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            configuration.label
                .padding(radius)
                .background(Palette.onBackground.opacity(focused ? 0.12 : 0), in: shape)
                .contentShape(shape)
                .padding(-radius)
                .effectsAnimation(.easeOut(duration: 0.15), value: focused)
                #if os(tvOS)
                .tvPressed(configuration.isPressed)
                #else
                .opacity(configuration.isPressed ? 0.7 : 1)
                .focusRing(radius: radius)
                #endif
        }
    }
}

/// Everything the TV hero holds, none of it cut (the hero sheds and truncates): the title, an episode's own title, the
/// metadata and every quality label "  •  "-joined and wrapping, every score, the genres and the whole summary. The
/// body is one focus stop that Up and Down scroll by half its height. Its panel is `detail.infoPanel`.
struct DetailInfoSheet: View {
    let hero: DetailHeroUi
    let onClose: () -> Void

    @State private var viewport: CGFloat = 0
    @State private var content: CGFloat = 0
    @State private var page = 0
    @FocusState private var focused: Bool
    @Environment(\.dimens) private var dimens

    var body: some View {
        let unit = dimens.unit
        let step = max(viewport / 2, 1)
        let lastPage = content > viewport ? Int(((content - viewport) / step).rounded(.up)) : 0
        SheetPage(id: "detail.infoSheet", title: hero.title, close: SheetAction(title: T.shared.common.close, id: "detail.infoSheet.close", action: onClose)) {
            ScrollViewReader { reader in
                ScrollView(.vertical) {
                    ZStack(alignment: .topLeading) {
                        // A mark every half page, for Up and Down to scroll to.
                        ForEach(0...lastPage, id: \.self) { mark in
                            Color.clear.frame(width: 1, height: 1).id(mark).padding(.top, CGFloat(mark) * step)
                        }
                        details(unit: unit)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { content = $0 }
                    }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewport = $0 }
                #if !os(iOS)
                .focusable()
                .focused($focused)
                .focusEffectDisabled()
                .onMoveCommand { direction in
                    let next = switch direction {
                    case .up: max(page - 1, 0)
                    case .down: min(page + 1, lastPage)
                    default: page
                    }
                    guard next != page else { return }
                    page = next
                    withAnimation(.easeOut(duration: 0.15)) { reader.scrollTo(next, anchor: .top) }
                }
                #endif
            }
        }
        .task { focused = true }
    }

    private func details(unit: CGFloat) -> some View {
        let labels = hero.metadata + hero.qualityLabels
        return VStack(alignment: .leading, spacing: 0) {
            if let episodeTitle = hero.episodeTitle, !episodeTitle.isEmpty {
                Text(episodeTitle)
                    .font(.callout.weight(.bold))
                    .padding(.bottom, 6 * unit)
            }
            if !labels.isEmpty {
                Text(labels.joined(separator: "  •  "))
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !hero.ratings.isEmpty {
                RatingsStrip(ratings: hero.ratings, textSize: 14, weight: .semibold, iconSize: 14)
                    .padding(.top, labels.isEmpty ? 0 : 6 * unit)
            }
            if !hero.genres.isEmpty {
                Text(hero.genres.joined(separator: "  •  "))
                    .font(.subheadline)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8 * unit)
            }
            if let summary = hero.summary, !summary.isEmpty {
                Text(summary)
                    .font(.callout)
                    .lineSpacing(8 * unit)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16 * unit)
            }
        }
        .foregroundStyle(Palette.onBackground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 4 * unit, leading: 16 * unit, bottom: 24 * unit, trailing: 16 * unit))
    }
}
