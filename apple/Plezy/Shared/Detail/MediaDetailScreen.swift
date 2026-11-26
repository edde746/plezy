import SwiftUI
import PlezyKit

/// A movie's, show's, season's or episode's detail (`MediaDetailStore`): a spinner until the item (or the card it was
/// opened from) shows, the unavailable state when it fails (with Retry when the fetch may work again), then on a TV
/// the full-screen page (`DetailTvPage`),
/// elsewhere the page laid out per window (`DetailPage`). The store's messages show as toasts; once the item is deleted
/// the page leaves (`leavesWhenGone`). A shuffle's queue loading shows the loading dialog, its Cancel the store's.
struct MediaDetailScreen: View {
    let app: AppModel
    private let route: RouteMediaDetail

    @State private var model: StoreModel<MediaDetailStore, MediaDetailUiState>?
    @State private var message: String?
    @State private var watchlist: StoreModel<DetailWatchlistStore, DetailWatchlistUi?>?

    init(app: AppModel, route: RouteMediaDetail) {
        self.app = app
        self.route = route
        _model = State(initialValue: StoreModel(app.session.mediaDetail(route: route)) { $0.state })
        _watchlist = State(initialValue: StoreModel(app.session.detailWatchlist(route: route)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let navigate: (any Route) -> Void = { app.navigator.navigate(route: $0) }
            let tv = app.appearance.state.tv
            // One spinner until there is an item to show.
            let loading = state.load != .error && (state.hero == nil || state.load != .content)
            ZStack {
                if state.load == .error {
                    ErrorStateView(message: T.shared.messages.mediaUnavailable, onRetry: state.canRetry ? { model.store.retry() } : nil)
                        .accessibilityIdentifier("detail.error")
                } else if let hero = state.hero, state.load == .content {
                    if tv {
                        DetailTvPage(
                            state: state, hero: hero, store: model.store, menu: app.session.mediaActions.menu,
                            appearance: app.appearance.state, navigate: navigate,
                            menuShown: app.menu.open != nil || app.menu.prompt != nil
                        )
                    } else {
                        #if !os(tvOS)
                        DetailPage(state: state, hero: hero, store: model.store, menu: app.session.mediaActions.menu, navigate: navigate)
                        #endif
                    }
                }
                if loading {
                    LoadingStateView().accessibilityIdentifier("detail.loading")
                }
            }
            .toast(message, id: "detail.message") { message = nil }
            // While a play queue loads: its title, a spinner and Cancel.
            .progressSheet(
                state.launching, isPresented: state.launching != nil, id: "launching.dialog",
                cancel: SheetAction(title: T.shared.common.cancel, id: "launching.cancel", action: model.store.cancelLaunch)
            ) {
                ProgressView().largeSpinner()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("detail.screen")
            .task { await model.state.observe() }
            .task { await watchlist?.state.observe() }
            .environment(watchlist)
            .onChange(of: watchlist?.state.state?.message) { _, text in
                guard let text else { return }
                message = text
                watchlist?.store.messageShown()
            }
            .onChange(of: state.message, initial: true) { _, text in
                guard let text else { return }
                message = text
                model.store.messageShown()
            }
            .leavesWhenGone(state.gone, route: route, app: app)
        }
    }
}

extension View {
    /// Leaves `route`'s screen once its content is `gone` (deleted), while it is the top screen: at once, or as soon as
    /// it is again (a screen or sheet over it closed, its destination shown again). Apple TV builds a pushed screen
    /// twice: the navigator's own top, read as it leaves, keeps the second copy from leaving the screen under it too.
    func leavesWhenGone(_ gone: Bool, route: any Route, app: AppModel) -> some View {
        let top = app.backStack.last.map { RouteKey(route: $0) == RouteKey(route: route) } ?? false
        return onChange(of: gone && top, initial: true) { _, leave in
            guard leave, RouteKey(route: app.navigator.current) == RouteKey(route: route) else { return }
            _ = app.navigator.back()
        }
    }
}

#if !os(tvOS)
/// The detail page on a phone, a tablet or the Mac, laid out as the Apple TV app's pages: one scrolling column on phones
/// and narrow windows (`DetailNarrowLayout`), the details and a show's or season's episodes side by side over the
/// backdrop on wide windows (`DetailWideLayout`). The system's navigation bar carries Back (the title is the page's
/// own, `titleInContent`; on the Mac also the window's), and on phones the cast button across from it
/// (`castInTopBar`).
/// A deep link's episode row or season chip (`MediaDetailUiState.initialFocus`) is scrolled to and focused once.
private struct DetailPage: View {
    let state: MediaDetailUiState
    let hero: DetailHeroUi
    let store: MediaDetailStore
    let menu: MediaMenu
    let navigate: (any Route) -> Void

    /// The episode row or season chip a deep link focuses first (`MediaDetailUiState.initialFocus`): "ep/<id>",
    /// "season/<id>".
    @FocusState private var focus: String?
    @State private var initialApplied = false
    /// The toasts' band at the screen's foot (`toastRoom`): the layouts take the page's height as it is without a toast,
    /// so nothing moves under one.
    @Environment(\.toastRoom) private var toastRoom

    var body: some View {
        GeometryReader { geometry in
            #if os(iOS)
            let sidebar = UIDevice.current.userInterfaceIdiom == .phone ? 0 : geometry.safeAreaInsets.leading
            #else
            let sidebar = geometry.safeAreaInsets.leading
            #endif
            let window = geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing
            let size = CGSize(width: geometry.size.width, height: geometry.size.height + toastRoom)
            let parts = DetailParts(state: state, hero: hero, store: store, menu: menu, navigate: navigate, focus: $focus)
            ScrollViewReader { reader in
                Group {
                    if geometry.size.width >= DetailMetrics.widePageWidth, window >= DetailMetrics.wideWindowWidth {
                        DetailWideLayout(parts: parts, size: size, top: geometry.safeAreaInsets.top, sidebar: sidebar)
                    } else {
                        DetailNarrowLayout(parts: parts, width: size.width, height: size.height, insets: geometry.safeAreaInsets, sidebar: sidebar)
                    }
                }
                .task(id: state.initialFocus) { await applyInitialFocus(reader) }
            }
        }
        .navigationTitle(hero.title)
        .inlineNavigationTitle()
        .titleInContent()
        .castInTopBar(id: "detail.castTo")
    }

    /// Scrolls a deep link's episode row (else the season chips) to the middle of the page and focuses it, once.
    private func applyInitialFocus(_ reader: ScrollViewProxy) async {
        guard let target = state.initialFocus, !initialApplied else { return }
        initialApplied = true
        let key: String
        let anchor: String
        if let episodeId = target.episodeId {
            key = "ep/\(episodeId)"
            anchor = episodeId
        } else if let index = target.seasonIndex?.intValue, index < state.seasons.count {
            key = "season/\(state.seasons[index].id)"
            anchor = "seasons"
        } else {
            return
        }
        // The rows lay out a turn after the state that names them: scroll then, and again once the page has settled.
        for delay in [300, 400, 500] {
            try? await Task.sleep(for: .milliseconds(delay))
            reader.scrollTo(anchor, anchor: .center)
        }
        focus = key
    }
}

/// The metrics the detail page's layouts share.
enum DetailMetrics {
    /// Windows at least this wide whose page is at least `widePageWidth` put the details and the episodes side by side.
    static let wideWindowWidth: CGFloat = 1000
    static let widePageWidth: CGFloat = 840
    /// The details' column on wide windows is at most this wide.
    static let infoMaxWidth: CGFloat = 560
    /// The episodes' column on wide windows is at most this wide.
    static let episodesMaxWidth: CGFloat = 960
    /// An episode row's inset around its thumbnail and text: its hover and focus fill reach this far.
    static let rowInset: CGFloat = 12
}

/// What both layouts draw, from the page's state.
@MainActor
private struct DetailParts {
    let state: MediaDetailUiState
    let hero: DetailHeroUi
    let store: MediaDetailStore
    let menu: MediaMenu
    let navigate: (any Route) -> Void
    let focus: FocusState<String?>.Binding

    var hasEpisodes: Bool { state.kind == .show }

    /// The headline, under the poster where the item has no backdrop.
    func headline(centred: Bool, logoWidth: CGFloat) -> some View {
        VStack(alignment: centred ? .center : .leading, spacing: 20) {
            if hero.backdrops.isEmpty, let poster = hero.poster {
                RemoteImage(artwork: poster)
                    .background(Palette.surfaceContainerHigh)
                    .frame(width: centred ? 120 : 160, height: (centred ? 120 : 160) * 1.5)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
                    .accessibilityHidden(true)
            }
            DetailHeadline(state: state, hero: hero, store: store, menu: menu, centred: centred, logoWidth: logoWidth)
        }
    }

    func episodes(thumbnailWidth: CGFloat) -> some View {
        DetailEpisodesSection(state: state, store: store, menu: menu, thumbnailWidth: thumbnailWidth, focus: focus)
    }

    /// The cast, the extras and the related hubs, each a shelf; then the information.
    func shelves() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            if !state.cast.isEmpty {
                DetailCastRow(cast: state.cast, store: store, navigate: navigate)
            }
            if !state.extras.isEmpty {
                DetailExtrasRow(extras: state.extras, store: store, menu: menu)
            }
            ForEach(state.related, id: \.id) { hub in
                HubShelf(
                    hub: hub,
                    onOpen: { card in if let route = store.relatedRoute(cardId: card.id) { navigate(route) } },
                    onMenu: { card in
                        if let item = store.relatedItem(cardId: card.id) {
                            menu.open(item: item, place: store.menuPlace, extras: [], playTrailer: nil, onRow: [])
                        }
                    },
                    onViewAll: { if let route = store.relatedHubRoute(hubId: hub.id) { navigate(route) } }
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("detail.related")
            }
        }
    }
}

/// Phones and narrow windows: one scrolling page. The backdrop across the top, under the navigation bar, fading to the
/// background under the title; the title, the metadata line, the ratings and the actions centred over its foot; then
/// the overview, a show's season chips and the season's episodes, the cast, the extras, the related hubs and the
/// information. Once the title has scrolled under the navigation bar (on the Mac the toolbar), a bar with it fades in
/// over the page (`titleBand`). While the item loads (`itemLoading`) only the backdrop and the title show: the rest comes
/// in together once it has landed.
private struct DetailNarrowLayout: View {
    let parts: DetailParts
    let width: CGFloat
    let height: CGFloat
    let insets: EdgeInsets
    let sidebar: CGFloat

    @Environment(\.screenSides) private var sides
    @Environment(\.dimens) private var dimens
    @Environment(\.formFactor) private var formFactor

    var body: some View {
        let hero = parts.hero
        let backdrop = !hero.backdrops.isEmpty
        let heroHeight = min(width * 9 / 16, height / 2) + insets.top
        let top = max(heroHeight - 96, insets.top + 12)
        let backdropHeight = heroHeight + 40
        let logoWidth = min((width - sides.horizontal) * 0.8, DetailMetrics.infoMaxWidth)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Leading-aligned: the backdrop is wider than the page by the trailing safe area (iOS 27.1's vertical
                // bar, a sensor housing); centred, the headline would sit off the page's centre, under that bar.
                ZStack(alignment: .topLeading) {
                    if backdrop {
                        // The safe area's top is the status bar's and the navigation bar's: the bars' foot.
                        DetailBackdrop(backdrops: hero.backdrops, style: .top(barFoot: insets.top / backdropHeight, headline: top / backdropHeight), sidebar: sidebar)
                            .frame(width: insets.leading + width + insets.trailing, height: backdropHeight)
                            .padding(.leading, -insets.leading)
                    }
                    parts.headline(centred: true, logoWidth: logoWidth)
                        .padding(sides.insets)
                        .frame(width: width)
                        .padding(.top, backdrop ? top : insets.top + 12)
                }
                if !parts.state.itemLoading {
                    if parts.hasEpisodes {
                        parts.episodes(thumbnailWidth: formFactor == .compact ? 128 : 176)
                            .padding(.leading, sides.leading - DetailMetrics.rowInset)
                            .padding(.trailing, sides.trailing - DetailMetrics.rowInset)
                            .padding(.top, dimens.sectionSpacing)
                    }
                    parts.shelves()
                        .padding(.top, dimens.sectionSpacing)
                    if !parts.state.info.isEmpty {
                        DetailInformation(rows: parts.state.info)
                            .padding(sides.insets)
                            .padding(.top, dimens.sectionSpacing)
                    }
                }
            }
            .frame(width: width, alignment: .leading)
            .padding(.leading, insets.leading)
            .padding(.bottom, dimens.sectionSpacing * 2)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: [.top, .horizontal])
        .titleBand(hero.title, top: insets.top)
    }
}

/// Where the detail's title (its logo or name) is, for the bar that names the page once it has scrolled away.
struct DetailTitleFrame: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

extension View {
    /// Lays the bar naming the page (`DetailTitleBar`, `title`) over it, behind the navigation bar's (the Mac's
    /// toolbar's) buttons, `top` tall (the safe area's top), showing as the page's title (`DetailTitleFrame`) scrolls
    /// under it: its material whole once the title's top is 16 points under it, so the title never shows faded under the
    /// status bar or beside Back, then its own title over the 40 points past the page title's foot. Over the page, so
    /// nothing under it moves as it shows. On the Mac the bar sits on the toolbar's band
    /// over the band's fade, which it draws under itself as a header row does (`HeaderRowKey`): the screen's fade,
    /// drawn over the screen, covered the bar and its title, the title near black on the band.
    func titleBand(_ title: String, top: CGFloat) -> some View {
        overlayPreferenceValue(DetailTitleFrame.self) { anchor in
            GeometryReader { proxy in
                let frame = anchor.map { proxy[$0] }
                let head = frame?.minY ?? .infinity
                let foot = frame?.maxY ?? .infinity
                DetailTitleBar(
                    title: title, height: top, shown: min(max((top - foot) / 40, 0), 1), cover: min(max((top - head) / 16, 0), 1)
                )
            }
            #if os(macOS)
            .background(alignment: .top) { TitleBandFade(height: top) }
            #endif
            // From the screen's top, as the page's own coordinates are; on the Mac clear of the sidebar, which the
            // leading safe area holds.
            .ignoresSafeArea(edges: DetailTitleBar.reach)
        }
        #if os(macOS)
        .preference(key: HeaderRowKey.self, value: true)
        #endif
    }

    #if os(macOS)
    /// A scroll view's content whose page names itself (`DetailTitleFrame`), the scroll view `viewport` tall: taller
    /// than the scroll view, but not by enough for its title to go the 40 points under the bar that show the bar whole
    /// (`titleBand`), it gets that room at its foot, so the bar never stops part way, covering the page's title
    /// without naming the page. Content that fits doesn't scroll, and its title never goes under the bar.
    func titleScrollRoom(viewport: CGFloat) -> some View {
        modifier(TitleScrollRoom(viewport: viewport))
    }
    #endif
}

#if os(macOS)
private struct TitleScrollRoom: ViewModifier {
    let viewport: CGFloat

    /// The content's own height and its title's foot in it.
    @State private var natural: CGFloat = 0
    @State private var foot: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .backgroundPreferenceValue(DetailTitleFrame.self) { anchor in
                GeometryReader { proxy in
                    Color.clear.onChange(of: anchor.map { proxy[$0].maxY } ?? 0, initial: true) { _, y in foot = y }
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { natural = $0 }
            .frame(minHeight: natural > viewport ? max(natural, viewport + foot + 40) : nil, alignment: .top)
    }
}
#endif

#if os(macOS)
/// The toolbar's band under the bar naming the page (`titleBand`), `height` tall, as the screen draws it where no row
/// sits on it (`windowToolbarBand`, macOS 26 and later): the fade of the content scrolled up under it, and the title
/// bar's drag area.
private struct TitleBandFade: View {
    let height: CGFloat

    @Environment(\.bandScrolled) private var scrolled

    var body: some View {
        if #available(macOS 26, *) {
            ZStack(alignment: .top) {
                ScrollEdgeFade.under(height, shown: scrolled)
                WindowDragArea().frame(height: height)
            }
        }
    }
}
#endif

/// The bar behind the navigation bar's (the Mac's toolbar's) buttons, `height` tall: the bar material with the item's
/// `title`, as much as `shown` (0 to 1, fading in over the 40 points the page scrolls once its title has gone under
/// the bar), as the Apple TV app's pages: the material over the first half, covering the page's own title, then the
/// bar's title over the second, so the two titles never show at once. The material shows at least as much as `cover`
/// (how far the page's title has started under the bar, `titleBand`), so the part of the title under the bar is hidden
/// from the start. On iOS the title is centred between Back and the
/// cast button; on the Mac it follows Back, where the toolbar puts a title. Over the page: it takes no room and no
/// touches. Identifier `detail.titleBar`, its value how far it shows. Person pages show it from their header's top
/// (`personTitleBar`); every other page through `titleBand`.
struct DetailTitleBar: View {
    let title: String
    let height: CGFloat
    let shown: CGFloat
    var cover: CGFloat = 0

    #if os(macOS)
    static let reach: Edge.Set = .top
    /// Where the toolbar's title starts past Back, from the page's leading edge.
    private static let titleStart: CGFloat = 48
    #else
    static let reach: Edge.Set = .all
    #endif

    var body: some View {
        if shown > 0 || cover > 0 {
            VStack(spacing: 0) {
                #if os(macOS)
                ZStack(alignment: .leading) {
                    Rectangle().fill(.bar)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(Palette.onBackground)
                        // Past Back, as the toolbar's own title.
                        .padding(.leading, Self.titleStart)
                        .padding(.trailing, 16)
                        .opacity(max(shown * 2 - 1, 0))
                }
                .frame(height: height)
                Divider()
                #else
                ZStack(alignment: .bottom) {
                    Rectangle().fill(.bar)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        // Clear of Back and the cast button at the bar's sides.
                        .padding(.horizontal, 72)
                        .frame(height: 44)
                        .padding(.bottom, 4)
                        .opacity(max(shown * 2 - 1, 0))
                }
                .frame(height: height)
                // A soft foot, as a scroll edge's: what scrolls under the bar fades into it rather than being cut.
                Rectangle().fill(.bar)
                    .frame(height: 16)
                    .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                #endif
            }
            .opacity(max(min(shown * 2, 1), cover))
            .ignoresSafeArea(edges: Self.reach)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(String(format: "%.2f", shown))
            .accessibilityIdentifier("detail.titleBar")
        }
    }
}

/// Wide windows: the backdrop behind the whole window, dark at the leading edge and the bottom. The details in a
/// column at the leading edge (at most `DetailMetrics.infoMaxWidth`) with the shelves and the information under them;
/// a show's episodes in a column beside them, the backdrop dimmed under them. A movie's details start
/// lower, under the backdrop's picture. On the Mac each column is a focus section, and once the details' title has
/// scrolled under the toolbar (`top` tall), a bar with it fades in over the page (`titleBand`). While the item loads
/// (`itemLoading`) only the backdrop and the title show.
private struct DetailWideLayout: View {
    let parts: DetailParts
    let size: CGSize
    let top: CGFloat
    let sidebar: CGFloat

    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides

    var body: some View {
        let series = parts.hasEpisodes
        let usable = max(size.width - sides.horizontal, 0)
        let gap: CGFloat = 40
        let infoWidth = series ? min(max(usable * 0.4, 340), DetailMetrics.infoMaxWidth) : min(usable, DetailMetrics.infoMaxWidth)
        let columnWidth = series ? infoWidth : usable
        let episodesWidth = min(max(usable - infoWidth - gap, 0), DetailMetrics.episodesMaxWidth)
        let reach = dimens.focusRoom
        let columnTop: CGFloat = series || parts.hero.backdrops.isEmpty ? 16 : max(size.height * 0.3, 16)
        HStack(alignment: .top, spacing: gap - 2 * reach) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    parts.headline(centred: false, logoWidth: infoWidth)
                        .frame(width: infoWidth, alignment: .leading)
                    if !parts.state.itemLoading {
                        // The shelves scroll across the column, their headings at its start.
                        parts.shelves()
                            .environment(\.dimens.screenPadding, 0)
                            .padding(.vertical, 8)
                        if !parts.state.info.isEmpty {
                            DetailInformation(rows: parts.state.info).frame(width: infoWidth, alignment: .leading)
                        }
                    }
                }
                .frame(width: columnWidth, alignment: .leading)
                .padding(.top, columnTop)
                .padding(.bottom, dimens.sectionSpacing * 2)
                .padding(.horizontal, reach)
                #if os(macOS)
                .titleScrollRoom(viewport: size.height)
                #endif
            }
            .scrollIndicators(.hidden)
            .frame(width: columnWidth + 2 * reach)
            .shelfFocusSection()
            if series && !parts.state.itemLoading {
                ScrollView {
                    parts.episodes(thumbnailWidth: 176)
                        .padding(.horizontal, reach)
                        .padding(.vertical, 16)
                        .padding(.bottom, dimens.sectionSpacing * 2)
                }
                .scrollIndicators(.hidden)
                .frame(width: episodesWidth + 2 * reach)
                .shelfFocusSection()
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, sides.leading - reach)
        .padding(.trailing, sides.trailing - reach)
        .background {
            DetailBackdrop(backdrops: parts.hero.backdrops, style: .wide(dimmed: series), sidebar: sidebar).ignoresSafeArea()
        }
        #if os(macOS)
        .titleBand(parts.hero.title, top: top)
        #endif
    }
}

/// The item's backgrounds in turn (`CyclingBackdrop`), fading into the page: `top` across the top of a narrow page
/// (`HeroScrim.top`), `wide` behind the whole window (dark at the leading edge and the bottom; dimmed under a show's
/// episodes). Under a sidebar (iPad's, the Mac's) it is dimmed from its leading edge to three times the sidebar's width,
/// so the sidebar's labels read over a bright picture.
struct DetailBackdrop: View {
    enum Style {
        case top(barFoot: CGFloat, headline: CGFloat)
        case wide(dimmed: Bool)
    }

    let backdrops: [Artwork]
    let style: Style
    let sidebar: CGFloat

    var body: some View {
        let black = Palette.background
        Color.clear
            .overlay { CyclingBackdrop(backdrops: backdrops, alignment: .top) }
            .clipped()
            .overlay {
                switch style {
                case .top(let barFoot, let headline):
                    HeroScrim.top(black, barFoot: barFoot, headline: headline)
                case .wide(let dimmed):
                    ZStack {
                        if dimmed { black.opacity(0.7) }
                        LinearGradient(
                            stops: [
                                .init(color: black.opacity(0.92), location: 0),
                                .init(color: black.opacity(0.75), location: 0.3),
                                .init(color: black.opacity(0.1), location: 0.65),
                                .init(color: black.opacity(0), location: 1),
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                        LinearGradient(
                            stops: [.init(color: black.opacity(0), location: 0.55), .init(color: black, location: 1)],
                            startPoint: .top, endPoint: .bottom
                        )
                    }
                }
            }
            .overlay(alignment: .leading) {
                if sidebar > 0 {
                    LinearGradient(colors: [black.opacity(0.95), black.opacity(0)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: sidebar * 3)
                }
            }
            .clipped()
            .background(black)
    }
}
#endif

/// The dimming of a narrow page's picture across its top (a media item's, a catalog title's), towards the background
/// (`color`) where something is drawn over it.
enum HeroScrim {
    /// Behind the status bar and the navigation bar, down to `barFoot` of the picture's height, so Back and the cast
    /// button (their glass takes the colour under it) stand ≥3:1 from it; and from `headline`, where the title starts,
    /// to its foot, the background there, so the title and the facts (the theme's text colour) stand ≥4.5:1 from it
    /// even on a white or a black picture. Clear between the two, each side easing into it so neither reads as a band's
    /// edge.
    static func top(_ color: Color, barFoot: CGFloat, headline: CGFloat) -> LinearGradient {
        let headline = max(min(headline, 0.9), 0.2)
        let bars = min(barFoot, headline)
        return LinearGradient(
            stops: [
                .init(color: color.opacity(0.6), location: 0),
                .init(color: color.opacity(0.55), location: bars),
                .init(color: color.opacity(0), location: bars + (headline - bars) / 2),
                .init(color: color.opacity(0.6), location: headline),
                .init(color: color.opacity(0.8), location: headline + (1 - headline) / 2),
                .init(color: color, location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }
}

/// The item's clear logo, fitted in `maxWidth` × `maxHeight`; without one (or when it fails) its title in bold, shrinking
/// to fit three lines.
struct DetailTitleArt: View {
    let hero: DetailHeroUi
    let centered: Bool
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let fontSize: CGFloat

    var body: some View {
        let title = Text(hero.title)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(Palette.onBackground)
            .multilineTextAlignment(centered ? .center : .leading)
            .lineLimit(3)
            .minimumScaleFactor(0.6)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("detail.title")
        if let logo = hero.logo {
            RemoteImage(artwork: logo, contentMode: .fit, alignment: centered ? .bottom : .bottomLeading, logo: .title) { failed in
                if failed { title.frame(maxHeight: .infinity, alignment: .bottom) }
            }
            .frame(maxWidth: maxWidth, minHeight: maxHeight / 2, maxHeight: maxHeight)
            .accessibilityElement()
            .accessibilityLabel(hero.title)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("detail.title")
        } else {
            title
        }
    }
}
