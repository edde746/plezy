import SwiftUI
import PlezyKit

/// A catalog title's detail, laid out as a media item's detail page: the backdrop full
/// bleed across the top (on iPhone, fading into the page under the title) or behind the whole page (iPad, the Mac,
/// Apple TV: dark at the leading edge and the bottom), then the headline: the clear logo (recoloured on a light theme,
/// `logo: .title`) or the title, the tagline, the metadata line and genres, the stats, the action row (Watchlist,
/// Request, Watch trailer as buttons with their symbols and words, once the detail has settled: the lines it adds would
/// move them under a press; on Apple TV focus starts on the first), the overview (three lines, the rest on a press);
/// then the library availability, the cast as a shelf, the information (background, facts, recommenders, ratings,
/// schedule, crew, tags with spoilers behind "Show spoiler tags"), the outbound links (none on Apple TV), the related
/// titles and More like this. Centred on iPhone, at the leading edge in a readable column elsewhere. The opening item
/// shows at once and the full detail fills in when it comes; the store's one-off message shows as a toast. Request
/// opens the Seerr request sheet over it.
struct CatalogDetailScreen: View {
    let app: AppModel

    @State private var model: StoreModel<CatalogDetailStore, CatalogDetailUiState>?
    @State private var actions: CatalogActions
    @Environment(\.formFactor) private var formFactor
    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides
    /// The toasts' band at the screen's foot (`toastRoom`): its height is the page's still, so nothing moves under a toast.
    @Environment(\.toastRoom) private var toastRoom

    init(app: AppModel, route: RouteCatalogDetail) {
        self.app = app
        let actions = CatalogActions(app: app)
        _actions = State(initialValue: actions)
        _model = State(initialValue: StoreModel(app.session.catalogDetail(route: route, host: actions.host)) { $0.state })
    }

    var body: some View {
        if let model {
            let state = model.state.state
            let related = state.related.map { $0.toMediaItem() }
            let narrow = formFactor == .compact
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height + toastRoom
                let backdropHeight = narrow ? min(width * 9 / 16 + proxy.safeAreaInsets.top, height * 0.6) : height * 0.75
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: dimens.sectionSpacing * 1.5) {
                        CatalogHeadline(state: state, store: model.store, app: app, centred: narrow)
                            .padding(.top, narrow ? max(backdropHeight - proxy.safeAreaInsets.top - 140, 0) : backdropHeight * 0.35)
                            .padding(sides.insets)
                        CatalogSections(
                            state: state, store: model.store, actions: actions,
                            navigate: { app.navigator.navigate(route: $0) }
                        )
                        if !related.isEmpty {
                            RelatedRow(state: state, items: related, actions: actions)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, dimens.sectionSpacing * 2)
                    .background(alignment: .top) {
                        // On iPhone the backdrop scrolls away with the headline, as Detail's: left behind the page,
                        // the cast and facts scrolled over it and their grey words sat on the picture.
                        if narrow {
                            // The headline starts 140 pt above the picture's foot; the safe area's top is the bars'.
                            CatalogBackdrop(
                                url: state.item.backdropFor(targetPx: Int32(width * 2)), height: backdropHeight,
                                narrow: (barFoot: proxy.safeAreaInsets.top, headline: backdropHeight - 140)
                            )
                                .padding(.top, -proxy.safeAreaInsets.top)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .background(alignment: .top) {
                    if !narrow {
                        CatalogBackdrop(url: state.item.backdropFor(targetPx: Int32(width * 2)), height: height, narrow: nil)
                    }
                }
                #if os(iOS)
                // As Detail's: once the title has scrolled under the status bar and Back, a bar naming the page.
                .titleBand(state.title, top: proxy.safeAreaInsets.top)
                #endif
            }
            #if !os(tvOS)
            // Pushed with no title on Apple TV, as Detail is: the hero names the screen.
            .navigationTitle(state.title)
            .inlineNavigationTitle()
            .titleInContent()
            #endif
            .toast(state.message, id: "catalogDetail.message", onShown: model.store.messageShown)
            .toast(actions.message, id: "catalog.message") { actions.message = nil }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("catalogDetail.screen")
            .task { await model.state.observe() }
            .task(id: related.map(\.id)) { await actions.prepare(related) }
        }
    }
}

/// The title's backdrop, full bleed: on iPhone (`narrow`) across the top (`height`), scrolling with the page (its caller
/// lifts it under the status bar), dimmed under the bars down to `barFoot` and from the headline's top (`headline`, both
/// in points from its top) to the background at its foot (`HeroScrim.top`); elsewhere behind the whole page, dark at
/// the leading edge and the bottom so the details read over it.
private struct CatalogBackdrop: View {
    let url: String?
    let height: CGFloat
    let narrow: (barFoot: CGFloat, headline: CGFloat)?

    var body: some View {
        ZStack {
            if let url {
                RemoteImage(url: url, alignment: .top)
            }
            if let narrow {
                HeroScrim.top(Palette.background, barFoot: narrow.barFoot / height, headline: narrow.headline / height)
            } else {
                LinearGradient(
                    stops: [.init(color: Palette.background.opacity(0.9), location: 0), .init(color: Palette.background.opacity(0.2), location: 0.6)],
                    startPoint: .leading, endPoint: .trailing
                )
                LinearGradient(
                    stops: [.init(color: Palette.background.opacity(0), location: 0.3), .init(color: Palette.background, location: 1)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .ignoresSafeArea(edges: narrow == nil ? .all : .horizontal)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The headline: the clear logo (or the title where there is none, or until it comes), the tagline, the metadata line,
/// the genres and the stats, then the action row and the overview. `centred` on iPhone.
private struct CatalogHeadline: View {
    let state: CatalogDetailUiState
    let store: CatalogDetailStore
    let app: AppModel
    let centred: Bool

    @Environment(\.formFactor) private var formFactor
    /// The focused action, by name.
    @FocusState private var action: String?
    #if os(tvOS)
    /// The first action has had its first focus: coming back to the screen (from a library copy's detail) leaves focus
    /// where the focus engine returns it.
    @State private var focusedFirst = false
    #endif

    var body: some View {
        let alignment: HorizontalAlignment = centred ? .center : .leading
        let tv = formFactor == .tv
        VStack(alignment: alignment, spacing: tv ? 16 : 10) {
            #if os(iOS)
            titleArt
                .anchorPreference(key: DetailTitleFrame.self, value: .bounds) { $0 }
            #else
            titleArt
            #endif
            if let tagline = state.tagline {
                Text(tagline)
                    .font(.callout.italic())
                    .foregroundStyle(Palette.onSurfaceVariant)
            }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line.text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .accessibilityIdentifier(line.id)
            }
            if state.hasActions {
                actionRow.padding(.vertical, 4)
            }
            if let overview = state.overview {
                FoldedText(text: overview, lines: 3, id: "catalogDetail.overview")
            }
        }
        .multilineTextAlignment(centred ? .center : .leading)
        .frame(maxWidth: centred ? .infinity : (tv ? 1000 : 640), alignment: centred ? .center : .leading)
        #if os(tvOS)
        .task(id: firstAction) {
            guard !focusedFirst, firstAction != nil else { return }
            focusedFirst = true
            await FocusRestore.restore($action, to: firstAction, hold: 1.5)
        }
        // Request turning into Requested under the focus (a request sent from the sheet) hands focus to the first action
        // that takes a press: never left on a status label.
        .onChange(of: state.request?.enabled) { _, enabled in
            guard enabled == false, action == "request" || action == nil, let firstAction else { return }
            action = firstAction
        }
        #endif
    }

    /// The metadata line, the genres and the stats (`catalogDetail.stats`), each a line where the title has it.
    private var lines: [(id: String, text: String)] {
        [
            state.metaLine.map { (id: "catalogDetail.meta", text: $0) },
            state.genres.map { (id: "catalogDetail.genres", text: $0) },
            state.stats.isEmpty ? nil : (id: "catalogDetail.stats", text: state.stats.joined(separator: " · ")),
        ].compactMap { $0 }
    }

    /// The clear logo where the title has one, recoloured on a light theme; the title's name until it comes, or without.
    private var titleArt: some View {
        let name = Text(state.title)
            .font(formFactor == .compact ? .title.weight(.bold) : .largeTitle.weight(.bold))
            .foregroundStyle(Palette.onBackground)
            .lineLimit(3)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("catalogDetail.title")
        return Group {
            if let logo = state.item.logoUrl {
                RemoteImage(
                    artwork: Artwork.companion.fixed(url: logo), contentMode: .fit, alignment: centred ? .bottom : .bottomLeading,
                    logo: .title, placeholder: { _ in name }
                )
                .frame(maxWidth: formFactor == .tv ? 560 : 320)
                .frame(height: formFactor == .tv ? 160 : 100)
                .accessibilityLabel(state.title)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("catalogDetail.logo")
            } else {
                name
            }
        }
    }

    /// The bar's first action that takes a press, which focus starts on; none until the bar shows.
    private var firstAction: String? {
        if !state.hasActions {
            nil
        } else if state.watchlist != nil {
            "watchlist"
        } else if state.request?.enabled == true {
            "request"
        } else if state.hasTrailer {
            "trailer"
        } else {
            nil
        }
    }

    /// Watchlist, Request and Watch trailer, whichever apply, as one action row (`ActionRow`): each its symbol and words
    /// as Detail's Play is (the first prominent, the rest glass); where the width runs out, the first with its words and
    /// the rest round. A title Seerr has, or that is requested, shows that state where Request was, as a status label in
    /// the text colour, never a disabled button; Request is as wide as its widest state, so the actions beside it stay
    /// put when it turns into Requested.
    private var actionRow: some View {
        let spacing: CGFloat = formFactor == .tv ? 24 : 12
        return ViewThatFits(in: .horizontal) {
            ActionRow(spacing: spacing) { actions(labelled: true) }
            ActionRow(spacing: spacing) { actions(labelled: false) }
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }

    @ViewBuilder
    private func actions(labelled: Bool) -> some View {
        if let watchlist = state.watchlist {
            actionButton(
                "watchlist", title: watchlist.label, systemImage: watchlist.onWatchlist == true ? "bookmark.fill" : "bookmark",
                labelled: labelled, action: store.toggleWatchlist
            )
        }
        if let request = state.request {
            actionButton(
                "request", title: request.label, systemImage: Self.requestSymbol(request.blocked), labelled: labelled,
                status: !request.enabled,
                widthOf: request.states.map { (title: $0.label, systemImage: Self.requestSymbol($0.blocked) as String?) }
            ) {
                app.navigator.navigate(route: RouteSeerrRequest(tmdbId: request.tmdbId, kind: state.item.kind, title: request.title))
            }
        }
        if state.hasTrailer {
            actionButton(
                "trailer", title: T.shared.explore.detail.watchTrailer, systemImage: "play.rectangle", labelled: labelled,
                action: store.playTrailer
            )
        }
    }

    /// Request's symbol, or its state's when the title can't be requested.
    private static func requestSymbol(_ blocked: SeerrBlock?) -> String {
        switch blocked {
        case nil: "plus.circle"
        case .available, .partiallyAvailable: "checkmark.circle"
        case .processing, .requested: "clock"
        case .blocklisted: "nosign"
        }
    }

    /// An action of the row, `name` its focus key and its identifier's last part: a pill with its words where
    /// `labelled` or it is the first, else a round button; a `status` always its words, as a label.
    @ViewBuilder
    private func actionButton(
        _ name: String, title: String, systemImage: String, labelled: Bool, status: Bool = false,
        widthOf: [(title: String, systemImage: String?)] = [], action: @escaping () -> Void
    ) -> some View {
        let first = name == firstAction
        if status {
            ActionButton(
                title: title, id: "catalogDetail.\(name)", systemImage: systemImage, fullWidth: false, status: true,
                widthOf: widthOf, action: action
            )
        } else if labelled || first {
            ActionButton(
                title: title, id: "catalogDetail.\(name)", prominence: first ? .primary : .secondary,
                systemImage: systemImage, fullWidth: false, widthOf: widthOf, action: action
            )
            .buttonBorderShape(.capsule)
            .focused($action, equals: name)
        } else {
            IconButton(systemImage: systemImage, label: title, id: "catalogDetail.\(name)", action: action)
                .focused($action, equals: name)
        }
    }
}

/// Everything under the headline: the library, the cast, the information, the links and the related titles.
private struct CatalogSections: View {
    let state: CatalogDetailUiState
    let store: CatalogDetailStore
    let actions: CatalogActions
    let navigate: (any Route) -> Void

    @Environment(\.dimens) private var dimens
    @Environment(\.screenSides) private var sides

    var body: some View {
        VStack(alignment: .leading, spacing: dimens.sectionSpacing * 1.5) {
            // Not where Request's Available status already says Seerr has it.
            if !(state.library is CatalogLibrarySectionSaidByStatus) {
                LibrarySection(section: state.library) { copy in
                    guard let serverId = copy.item.serverId else { return }
                    navigate(RouteMediaDetail(
                        serverId: serverId, itemId: copy.item.id, initialSeasonId: nil, initialEpisodeId: nil, offline: false
                    ).seeded(item: copy.item))
                }
                .padding(sides.insets)
            }
            if !state.cast.isEmpty {
                ShelfRow(title: state.castTitle, items: Array(state.cast.enumerated()), id: \.offset) { index, member in
                    let person = state.personRoute(index: Int32(index))
                    CastCard(member: member, open: person.map { route -> () -> Void in { navigate(route) } })
                        .accessibilityIdentifier("catalogDetail.cast.\(index)")
                }
            }
            CatalogInformation(state: state, store: store)
                .padding(sides.insets)
            #if !os(tvOS)
            if !state.watchOnLinks.isEmpty {
                Links(title: T.shared.explore.detail.watchOn, links: state.watchOnLinks, open: store.openLink(url:))
                    .padding(sides.insets)
            }
            if !state.links.isEmpty {
                Links(title: T.shared.explore.detail.links, links: state.links, open: store.openLink(url:))
                    .padding(sides.insets)
            }
            #endif
            if !state.relations.isEmpty {
                Relations(relations: state.relations, open: actions.open)
                    .padding(sides.insets)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A section's heading, as the shelves' and the detail page's are.
private struct SectionHeading: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Palette.onBackground)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The information block, as the detail page's: the background (three lines, the rest on a press), then each fact as a
/// muted label beside its value (the facts, the ratings, the schedule, the crew, the tags; spoiler tags behind "Show
/// spoiler tags"), then the recommenders.
private struct CatalogInformation: View {
    let state: CatalogDetailUiState
    let store: CatalogDetailStore

    @Environment(\.formFactor) private var formFactor

    var body: some View {
        let tv = formFactor == .tv
        let facts = state.facts.map { (label: $0.label, value: $0.value) }
        let rows = rows
        let ratings = RatingBadgesKt.ratingChips(ratings: CommunityRatingsKt.withCommunityRatings(own: state.ratings, community: state.communityRatings))
        if !facts.isEmpty || !ratings.isEmpty || !rows.isEmpty || state.background != nil || !state.recommenders.isEmpty
            || state.tags?.canRevealSpoilers == true {
            VStack(alignment: .leading, spacing: tv ? 14 : 8) {
                if let background = state.background {
                    SectionHeading(title: T.shared.explore.detail.background)
                    FoldedText(text: background, lines: 3, id: "catalogDetail.background")
                }
                Grid(alignment: .topLeading, horizontalSpacing: tv ? 24 : 12, verticalSpacing: tv ? 12 : 6) {
                    ForEach(Array(facts.enumerated()), id: \.offset) { _, row in factRow(row) }
                    if !ratings.isEmpty {
                        GridRow {
                            Text(T.shared.explore.detail.ratings).foregroundStyle(Palette.onSurfaceVariant)
                            RatingChips(chips: ratings, tv: tv)
                        }
                    }
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in factRow(row) }
                }
                .font(tv ? .callout : .subheadline)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("catalogDetail.facts")
                if state.tags?.canRevealSpoilers == true {
                    ActionButton(
                        title: T.shared.explore.detail.revealSpoilerTags, id: "catalogDetail.revealSpoilers", systemImage: "eye",
                        fullWidth: false, action: store.revealSpoilerTags
                    )
                }
                ForEach(Array(state.recommenders.enumerated()), id: \.offset) { _, recommender in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommender.text).font(.subheadline.weight(.semibold))
                        if let note = recommender.note { Text(note).font(.subheadline) }
                    }
                    .foregroundStyle(Palette.onBackground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func factRow(_ row: (label: String, value: String)) -> some View {
        GridRow {
            Text(row.label).foregroundStyle(Palette.onSurfaceVariant)
            Text(row.value).foregroundStyle(Palette.onBackground).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The rows after the facts and the ratings: the schedule, the crew, the tags.
    private var rows: [(label: String, value: String)] {
        var rows: [(label: String, value: String)] = []
        if !state.schedule.isEmpty {
            rows.append((T.shared.explore.detail.schedule, state.schedule.joined(separator: " · ")))
        }
        rows += state.crew.map { (label: $0.label, value: $0.value) }
        if let tags = state.tags, !tags.visible.isEmpty {
            rows.append((T.shared.explore.detail.tags, tags.visible.joined(separator: ", ")))
        }
        return rows
    }
}

/// The Ratings row's scores (`ratingChips`): each its source's logo (named for VoiceOver) and its value as the source
/// writes it, or a star and the source's name with the score; the votes after it where the source counts them.
/// Wrapping. Harness name: `catalogDetail.ratings`, each score `catalogDetail.rating.<i>`.
private struct RatingChips: View {
    let chips: [RatingChip]
    let tv: Bool

    /// The logos' height: about the row's text's (subheadline; callout on Apple TV, where it is 31 pt).
    #if os(tvOS)
    @ScaledMetric(relativeTo: .callout) private var mark: CGFloat = 28
    #else
    @ScaledMetric(relativeTo: .subheadline) private var mark: CGFloat = 14
    #endif

    var body: some View {
        FlowLayout(spacing: tv ? 20 : 12, lineSpacing: 4) {
            ForEach(Array(chips.enumerated()), id: \.offset) { index, chip in
                HStack(spacing: tv ? 8 : 4) {
                    if let icon = chip.icon {
                        RatingLogo(icon: icon, height: mark)
                    } else {
                        Image(systemName: "star.fill").imageScale(.small)
                    }
                    Text(chip.label).monospacedDigit()
                }
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(Palette.onBackground)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(chip.icon != nil ? "\(chip.sourceLabel ?? "") \(chip.label)" : chip.label)
                .accessibilityIdentifier("catalogDetail.rating.\(index)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("catalogDetail.ratings")
    }
}

/// Text folded to `lines` lines; a press (a tap, a click, Select) unfolds it or folds it again. It takes focus either
/// way, so the remote can reach and read a long overview. Its words line up with the title above; the surface a press
/// or focus shows reaches `margin` past them.
private struct FoldedText: View {
    let text: String
    let lines: Int
    let id: String

    @State private var open = false

    #if os(tvOS)
    private static let margin: CGFloat = 16
    private static let reach: CGFloat = 0
    #else
    private static let margin: CGFloat = 4
    /// Taken past the text above and below, out of the layout, so a one-line overview is still a 44 pt target.
    private static let reach: CGFloat = 8
    #endif

    var body: some View {
        Button {
            open.toggle()
        } label: {
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(open ? nil : lines)
                .padding(Self.margin)
                .padding(.vertical, Self.reach)
                .contentShape(Rectangle())
        }
        #if os(tvOS)
        .buttonStyle(SurfaceButtonStyle(fill: .clear))
        #else
        .buttonStyle(PressDimButtonStyle())
        #endif
        .padding(-Self.margin)
        .padding(.vertical, -Self.reach)
        .accessibilityIdentifier(id)
    }
}

/// Outbound links under their heading: a button each, "Open on <site>".
private struct Links: View {
    let title: String
    let links: [CatalogDetailLink]
    let open: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(title: title)
            FlowLayout(spacing: 8) {
                ForEach(Array(links.enumerated()), id: \.offset) { _, link in
                    ActionButton(title: link.label, id: "catalogDetail.link.\(link.url)", systemImage: "arrow.up.right.square", fullWidth: false) {
                        open(link.url)
                    }
                }
            }
        }
    }
}

/// Where the title is in the libraries: checking, not there, couldn't check, or the copies under the page's section
/// heading (`SectionHeading`, at the page's edge as the others are) as an inset-grouped list section (a row each, a
/// focusable button: the server's backend mark as the row's icon, the library over the copy's quality and server, the
/// disclosure chevron; hairlines between the rows from the text's leading edge; selecting one opens its detail,
/// `onOpen`). On Apple TV the rows stand apart, as a tvOS list's.
private struct LibrarySection: View {
    let section: CatalogLibrarySection
    let onOpen: (CatalogLibraryCopy) -> Void

    var body: some View {
        let muted = Palette.onSurfaceVariant
        Group {
            switch onEnum(of: section) {
            case .checking:
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text(T.shared.explore.checkingLibrary).foregroundStyle(muted)
                }
            case .notInLibrary:
                note(T.shared.explore.notInLibrary, symbol: "info.circle.fill", color: muted)
            case .saidByStatus:
                EmptyView()
            case .unchecked(let unchecked):
                note(unchecked.text, symbol: "icloud.slash", color: muted)
            case .copies(let copies):
                VStack(alignment: .leading, spacing: LibraryRowMetrics.headerGap) {
                    SectionHeading(title: T.shared.explore.inTheseLibraries)
                    VStack(spacing: LibraryRowMetrics.rowGap) {
                        ForEach(Array(copies.copies.enumerated()), id: \.element.key) { index, copy in
                            #if !os(tvOS)
                            if index > 0 {
                                Divider().padding(.leading, LibraryRowMetrics.inset + LibraryRowMetrics.iconSide + LibraryRowMetrics.iconGap)
                            }
                            #endif
                            Button { onOpen(copy) } label: {
                                HStack(spacing: LibraryRowMetrics.iconGap) {
                                    BackendMark(backend: copy.backend, size: LibraryRowMetrics.iconSide)
                                        .mutedForeground()
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(copy.title).font(.body)
                                        if let subtitle = copy.subtitle {
                                            Text(subtitle).font(.subheadline).mutedForeground()
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.forward")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                        .accessibilityHidden(true)
                                }
                                .padding(.horizontal, LibraryRowMetrics.inset)
                                .padding(.vertical, LibraryRowMetrics.verticalPadding)
                                .frame(minHeight: LibraryRowMetrics.minHeight)
                            }
                            #if os(tvOS)
                            .buttonStyle(SurfaceButtonStyle(fill: Palette.surfaceContainer, radius: Radius.medium))
                            #else
                            .buttonStyle(SurfaceButtonStyle(fill: Palette.surfaceContainer, radius: 0))
                            #endif
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("catalogDetail.copy.\(copy.key)")
                        }
                    }
                    #if !os(tvOS)
                    .background(Palette.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: LibraryRowMetrics.radius, style: .continuous))
                    #endif
                    .frame(maxWidth: 640, alignment: .leading)
                    if let unchecked = copies.uncheckedNote {
                        note(unchecked, symbol: "icloud.slash", color: muted)
                    }
                }
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("catalogDetail.library")
    }

    private func note(_ text: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).accessibilityHidden(true)
            Text(text)
        }
        .foregroundStyle(color)
    }
}

/// The library section's list metrics, an inset-grouped list's: the row's text inset from the group's edge, its icon,
/// its least height; on Apple TV a tvOS list's larger rows, apart.
private enum LibraryRowMetrics {
    #if os(tvOS)
    static let inset: CGFloat = 24
    static let iconSide: CGFloat = 40
    static let iconGap: CGFloat = 20
    static let minHeight: CGFloat = 80
    static let verticalPadding: CGFloat = 12
    static let rowGap: CGFloat = 12
    static let headerGap: CGFloat = 16
    static let radius: CGFloat = Radius.medium
    #elseif os(macOS)
    static let inset: CGFloat = 12
    static let iconSide: CGFloat = 20
    static let iconGap: CGFloat = 10
    static let minHeight: CGFloat = 36
    static let verticalPadding: CGFloat = 6
    static let rowGap: CGFloat = 0
    static let headerGap: CGFloat = 8
    static let radius: CGFloat = 10
    #else
    static let inset: CGFloat = 16
    static let iconSide: CGFloat = 28
    static let iconGap: CGFloat = 14
    static let minHeight: CGFloat = 44
    static let verticalPadding: CGFloat = 8
    static let rowGap: CGFloat = 0
    static let headerGap: CGFloat = 6
    static let radius: CGFloat = 26
    #endif
}

/// A cast member as the detail page's cast card: the round portrait (its placeholder without one), then the name (two
/// lines) and the character or role. With `open` (a Seerr title's member, who has a person page) the portrait is a
/// button that opens it, as the library detail's cast card is; otherwise the card is focusable on tvOS so the remote
/// can move along the shelf.
private struct CastCard: View {
    let member: CatalogCastMember
    let open: (() -> Void)?

    @Environment(\.dimens) private var dimens

    var body: some View {
        let width = dimens.posterWidth * 0.8
        if let open {
            card(width) {
                Button(action: open) {
                    portrait(width)
                        .contentShape(Circle())
                        .focusRing(radius: width / 2)
                }
                .cardButtonStyle(circular: true)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(member.name)
                .accessibilityValue(member.secondary ?? "")
            }
            .accessibilityElement(children: .contain)
        } else {
            card(width) { portrait(width) }
                .accessibilityElement(children: .combine)
                #if os(tvOS)
                .focusable()
                #endif
        }
    }

    /// The portrait over the name and the role; beside a button portrait, the lines are the button's label already.
    private func card(_ width: CGFloat, @ViewBuilder top: () -> some View) -> some View {
        VStack(spacing: 6) {
            top()
            Group {
                Text(member.name).font(.subheadline.weight(.medium)).lineLimit(2).multilineTextAlignment(.center)
                if let secondary = member.secondary {
                    Text(secondary).font(.caption).foregroundStyle(Palette.onSurfaceVariant).lineLimit(1)
                }
            }
            .accessibilityHidden(open != nil)
        }
        .foregroundStyle(Palette.onBackground)
        .frame(width: width)
    }

    private func portrait(_ width: CGFloat) -> some View {
        RemoteImage(url: member.imageUrl) { failed in
            if failed { ArtworkPlaceholder(kind: .person) }
        }
        .frame(width: width, height: width)
        .background(Palette.surfaceContainerHighest)
        .clipShape(Circle())
    }
}

/// Franchise relations under their heading, a row each (a small poster, how it relates, `title • year`, a chevron); a
/// row opens its title.
private struct Relations: View {
    let relations: [CatalogRelationEntry]
    let open: (CatalogItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(title: T.shared.explore.detail.relatedTitles)
            VStack(spacing: 1) {
                ForEach(Array(relations.enumerated()), id: \.offset) { _, relation in
                    Button { open(relation.item) } label: {
                        HStack(spacing: 12) {
                            RemoteImage(url: relation.item.posterFor(targetPx: 120)) { failed in
                                if failed { ArtworkPlaceholder(kind: PlaceholderKindKt.placeholderKind(kind: relation.item.kind)) }
                            }
                            .frame(width: 40, height: 60)
                            .background(Palette.surfaceContainerHighest)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.extraSmall, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(relation.label).font(.caption).mutedForeground()
                                Text(relation.text).font(.subheadline).lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.forward").mutedForeground().accessibilityHidden(true)
                        }
                        .padding(8)
                    }
                    .buttonStyle(SurfaceButtonStyle(fill: Palette.surfaceContainer, radius: 0))
                    .accessibilityLabel("\(relation.label): \(relation.text)")
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
            .frame(maxWidth: 640, alignment: .leading)
        }
    }
}

/// More like this: the related titles as a shelf of catalog cards.
private struct RelatedRow: View {
    let state: CatalogDetailUiState
    let items: [MediaItem]
    let actions: CatalogActions

    var body: some View {
        let hub = HubUi(
            id: "catalog-related:\(state.item.source.id):\(state.item.identityKey)", title: T.shared.discover.moreLikeThis,
            items: items.compactMap { $0.toCatalogCard(posterPx: 360, backdropPx: 0) }, shape: .poster, more: false,
            continueWatching: false, serverName: nil, icon: .thumbUp, totalResults: nil
        )
        HubShelf(hub: hub, onOpen: actions.open(card:), menu: actions.menu(card:))
    }
}
