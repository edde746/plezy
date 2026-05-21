import AVFoundation
import SwiftUI
import UIKit

// MARK: - Dominant Color Extraction

private extension UIImage {
    func dominantColor(darkened: CGFloat = 0.35) -> Color {
        guard let cgImage = self.cgImage else { return .black }
        let size = 40
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: size * size * 4)
        guard let context = CGContext(
            data: &pixelData, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: size * 4, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .black }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        var totalR: CGFloat = 0, totalG: CGFloat = 0, totalB: CGFloat = 0, totalWeight: CGFloat = 0
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = CGFloat(pixelData[i]) / 255.0
            let g = CGFloat(pixelData[i + 1]) / 255.0
            let b = CGFloat(pixelData[i + 2]) / 255.0
            let maxC = max(r, g, b), minC = min(r, g, b)
            let saturation = maxC > 0 ? (maxC - minC) / maxC : 0
            let weight = saturation * (1.0 - abs(maxC - 0.5) * 0.5) + 0.1
            totalR += r * weight; totalG += g * weight; totalB += b * weight; totalWeight += weight
        }
        guard totalWeight > 0 else { return .black }
        return Color(
            red: (totalR / totalWeight) * darkened,
            green: (totalG / totalWeight) * darkened,
            blue: (totalB / totalWeight) * darkened
        )
    }
}

// MARK: - Scroll Offset Tracking

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - MediaDetailView

struct MediaDetailView: View {
    let ratingKey: String

    @Environment(AppState.self) private var appState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var viewModel = MediaDetailViewModel()
    @State private var selectedSeasonKey: String?
    @State private var currentEpisodeRatingKey: String?
    @State private var backgroundTint: Color?
    @State private var logoURL: String?
    @State private var logoResolved = false
    @State private var networkName: String?
    @State private var awardBadge: AwardBadge?
    @FocusState private var isSummaryFocused: Bool
    @FocusState private var isActionButtonsFocused: Bool
    @FocusState private var isPlayButtonFocused: Bool

    // Hero transition animation state
    @State private var heroTransition: NavigationCoordinator.HeroTransition?
    @State private var hasAnimatedIn = false

    // Auto-preview player handed off from home screen or fetched on detail page
    @State private var previewPlayer: AVPlayer?
    @State private var isPreviewFullScreen = false
    @State private var previewManager = HeroPreviewManager()
    /// Guards against re-entering full-screen immediately after exiting
    @State private var canEnterFullScreen = false

    // Mark watched confirmation state
    @State private var showWatchedConfirmation = false

    // Download state
    @State private var showDeleteConfirmation = false
    @State private var isQueuingDownload = false

    // Cast focus memory
    @State private var lastFocusedCastIndex: Int?
    @State private var selectedPerson: PlexRole?

    // Episode carousel focus
    @FocusState private var focusedEpisodeKey: String?
    @State private var showSeasonPicker = false
    @State private var pendingSeasonEpisodeKey: String?
    @State private var carouselSeasonOverride: String?
    @State private var scrollToEpisodes = false
    @State private var pendingEpisodeFocus: String?

    @Namespace private var actionButtonsNamespace

    // Scroll-driven backdrop parallax
    @State private var contentScrollOffset: CGFloat = 0

    // Two-phase movie layout
    @State private var isContentBrowsing = false
    @State private var isExitTrapEnabled = false
    @FocusState private var isContentBrowseExitFocused: Bool

    private var effectiveTint: Color {
        backgroundTint ?? coordinator.backgroundTint
    }

    // Animated layout parameters: start at home-like values, animate to detail values
    private var heroHorizontalPadding: CGFloat { hasAnimatedIn ? 50 : 80 }
    private var logoMaxWidth: CGFloat { hasAnimatedIn ? 500 : 400 }
    private var logoMaxHeight: CGFloat { hasAnimatedIn ? 167 : 133 }

    /// Shifts the backdrop image up as the user scrolls down,
    /// keeping the gradient aligned with visible content for readability.
    private var backdropOffset: CGFloat {
        guard contentScrollOffset < 0 else { return 0 }
        return max(contentScrollOffset * 0.7, -500)
    }

    /// Whether the user has scrolled down to the episode carousel or cast area,
    /// used to darken the background for better text readability.
    private var isLowerContentFocused: Bool {
        focusedEpisodeKey != nil
    }

    /// Whether the movie has any content for the browse phase (View 2).
    private var hasMovieContentForBrowsing: Bool {
        guard viewModel.metadata?.mediaType == .movie else { return false }
        return !viewModel.trailers.isEmpty
            || !viewModel.bonusContent.isEmpty
            || !viewModel.collectionItems.isEmpty
            || viewModel.metadata?.role?.isEmpty == false
    }

    /// The metadata to display — use full metadata when available,
    /// fall back to hero transition data for instant display.
    /// Also checks coordinator's transition directly (before onAppear consumes it).
    private var displayMetadata: PlexMetadata? {
        viewModel.metadata ?? heroTransition?.metadata ?? coordinator.heroTransition?.metadata
    }

    /// Whether full metadata has loaded (controls detail-only content visibility).
    /// Also true on error so the user isn't stuck on a blank screen.
    private var isFullyLoaded: Bool {
        (viewModel.metadata != nil && !viewModel.isLoading) || viewModel.error != nil
    }

    /// Season label driven by which episode is focused in the carousel.
    /// Falls back to a manual override (from season picker), then the current episode's season.
    private var carouselSeasonTitle: String? {
        if let key = focusedEpisodeKey,
           let episode = viewModel.episodes.first(where: { $0.ratingKey == key }) {
            return episode.parentTitle
        }
        if let override = carouselSeasonOverride {
            return override
        }
        // Use the active episode's season, then fall back to metadata or first episode
        return viewModel.activeEpisode?.parentTitle
            ?? viewModel.metadata?.parentTitle
            ?? viewModel.episodes.first?.parentTitle
            ?? viewModel.seasons.first?.title
    }

    private var client: PlexClient? {
        guard let server = appState.activeServer, let token = appState.authToken else { return nil }
        return PlexClient(
            baseURL: server.baseURL,
            token: server.accessToken ?? token,
            clientIdentifier: appState.clientIdentifier,
            serverId: server.clientIdentifier,
            serverName: server.name
        )
    }

    @ViewBuilder
    private func personFilmographySheetContent() -> some View {
        if let person = selectedPerson {
            PersonFilmographySheet(
                person: person,
                sectionId: String(viewModel.metadata?.librarySectionID ?? 0),
                baseURL: appState.activeServer?.baseURL ?? "",
                token: appState.serverToken,
                onSelectItem: { item in
                    selectedPerson = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        coordinator.showMediaDetail(ratingKey: item.ratingKey)
                    }
                }
            )
        }
    }

    var body: some View {
        Group {
            if let metadata = displayMetadata {
                contentView(metadata: metadata)
            } else if let error = viewModel.error {
                ErrorStateView(
                    message: error,
                    retryAction: {
                        if let client {
                            await viewModel.load(ratingKey: ratingKey, client: client)
                        }
                    }
                )
            } else {
                // Seamless loading state — just the tinted background, no spinner
                Color.clear.focusable()
            }
        }
        .background(effectiveTint)
        .sheet(isPresented: Binding(
            get: { selectedPerson != nil },
            set: { if !$0 { selectedPerson = nil } }
        ), content: personFilmographySheetContent)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // Consume hero transition data from the coordinator
            if let transition = coordinator.heroTransition {
                heroTransition = transition
                backgroundTint = transition.backgroundColor
                // Pre-set logo state from the transition to avoid re-fetching
                switch transition.logoSource {
                case .tmdbURL(let url):
                    logoURL = url
                    logoResolved = true
                case .plexClearLogo:
                    logoResolved = true
                case .textOnly:
                    logoResolved = true
                }
                // Pick up preview player for continued trailer playback
                if let player = transition.previewPlayer {
                    HeroPreviewManager.applyBrowsingVolume(to: player)
                    previewPlayer = player
                    enableFullScreenAfterDelay()
                }
                coordinator.heroTransition = nil
                // For movies, skip the layout animation — content fades in at final position.
                // For shows, animate from home-like to detail layout.
                if transition.metadata.mediaType == .movie {
                    hasAnimatedIn = true
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            hasAnimatedIn = true
                        }
                    }
                }
            } else {
                hasAnimatedIn = true
            }
        }
        .task(id: appState.connectionStatus) {
            guard appState.connectionStatus == .connected else { return }
            guard let client else { return }

            // Phase 1: Load core metadata (play button, title, etc.)
            await viewModel.load(ratingKey: ratingKey, client: client)
            // If an episode redirected to its show, use the episode key for carousel
            if let redirectedKey = viewModel.redirectedEpisodeKey {
                currentEpisodeRatingKey = redirectedKey
            } else if viewModel.metadata?.mediaType == .episode {
                currentEpisodeRatingKey = ratingKey
            }

            if let meta = viewModel.metadata {
                let useCarousel = EpisodeViewMode.current == .carousel
                if useCarousel {
                    // Carousel mode: load all episodes across every season
                    if meta.mediaType == .show {
                        await viewModel.loadAllEpisodesForCarousel(
                            showRatingKey: meta.ratingKey, client: client
                        )
                    } else if meta.mediaType == .season, let showKey = meta.parentRatingKey {
                        await viewModel.loadAllEpisodesForCarousel(
                            showRatingKey: showKey, client: client
                        )
                    }
                } else {
                    // List mode: load seasons + auto-select appropriate season
                    await loadInitialSeasonsForList(meta: meta, client: client)
                }
            }

            // Yield so SwiftUI can render the UI with metadata
            await Task.yield()

            // Phase 2: Load secondary data in parallel (non-blocking)
            guard let metadata = viewModel.metadata else { return }

            async let backdropTask: Void = extractBackdropColor()
            async let enrichTask: Void = loadEnrichmentData(for: metadata, client: client)
            async let previewTask: Void = startAutoPreviewIfNeeded(client: client)

            _ = await (backdropTask, enrichTask, previewTask)

            // All data loaded and view settled — now apply pending episode focus
            if let key = pendingEpisodeFocus {
                pendingEpisodeFocus = nil
                scrollToEpisodes = true
                // One more yield to let SwiftUI finish layout after all the data updates
                await Task.yield()
                focusedEpisodeKey = key
            }
        }
        .onChange(of: previewManager.isActive) {
            // Pick up player from manager when it becomes active
            if previewManager.isActive, let player = previewManager.player, previewPlayer == nil {
                previewPlayer = player
                enableFullScreenAfterDelay()
            }
        }
        .onChange(of: isFullyLoaded) { _, loaded in
            // When the loading placeholder disappears, SwiftUI's focus engine
            // can pick a geometrically-nearby button (e.g. Watched) instead of
            // honoring .prefersDefaultFocus on Play. Force it explicitly,
            // deferred a runloop so the button has rendered before we bind focus.
            guard loaded else { return }
            DispatchQueue.main.async {
                isPlayButtonFocused = true
            }
        }
        .onChange(of: contentScrollOffset) {
            // Stop preview when user scrolls down past the hero area
            if contentScrollOffset < -150, previewPlayer != nil, !isPreviewFullScreen {
                stopPreview()
            }
        }
        .onChange(of: coordinator.isPresentingPlayer) {
            if coordinator.isPresentingPlayer {
                stopPreview()
            } else {
                // Player dismissed — refresh episode data and update active episode
                Task {
                    guard let client else { return }
                    let playedKey = coordinator.playerRatingKey
                    await viewModel.reloadAfterWatchedChange(client: client)
                    // Update active episode to the one just played
                    if let playedKey,
                       let played = viewModel.episodes.first(where: { $0.ratingKey == playedKey }) {
                        currentEpisodeRatingKey = playedKey
                        // Refetch full episode metadata for the active episode
                        if let epResult = try? await client.getMetadataWithOnDeck(ratingKey: playedKey) {
                            viewModel.updateActiveEpisode(epResult.metadata, fileInfo: try? await client.getFileInfo(ratingKey: playedKey))
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            guard previewPlayer != nil else { return }
            if isPreviewFullScreen {
                exitPreviewFullScreen()
            }
            // Fade out the preview to reveal the wallpaper underneath
            withAnimation(.easeInOut(duration: 0.6)) {
                previewPlayer?.pause()
                previewPlayer = nil
                isPreviewFullScreen = false
                canEnterFullScreen = false
            }
            previewManager.cleanup()
        }
        .onDisappear {
            stopPreview()
        }
    }

    private func stopPreview() {
        previewManager.cleanup()
        previewPlayer?.pause()
        previewPlayer = nil
        isPreviewFullScreen = false
        canEnterFullScreen = false
    }

    private func enableFullScreenAfterDelay() {
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            canEnterFullScreen = true
        }
    }

    /// List mode: load seasons and auto-select the appropriate one.
    private func loadInitialSeasonsForList(meta: PlexMetadata, client: PlexClient) async {
        switch meta.mediaType {
        case .show:
            // Seasons already loaded in viewModel.load(), just auto-select first
            if let firstSeason = viewModel.seasons.first {
                selectedSeasonKey = firstSeason.ratingKey
                await viewModel.loadEpisodes(seasonRatingKey: firstSeason.ratingKey, client: client)
            }
        case .episode:
            // Load seasons from the show, then select this episode's season
            if let showKey = meta.grandparentRatingKey {
                await viewModel.loadSeasonsForShow(showRatingKey: showKey, client: client)
            }
            let seasonKey = meta.parentRatingKey
            if let seasonKey, viewModel.seasons.contains(where: { $0.ratingKey == seasonKey }) {
                selectedSeasonKey = seasonKey
                await viewModel.loadEpisodes(seasonRatingKey: seasonKey, client: client)
            } else if let firstSeason = viewModel.seasons.first {
                selectedSeasonKey = firstSeason.ratingKey
                await viewModel.loadEpisodes(seasonRatingKey: firstSeason.ratingKey, client: client)
            }
            // Mark for focus after all loading completes
            pendingEpisodeFocus = ratingKey
        case .season:
            // Load seasons from the parent show, select this season
            if let showKey = meta.parentRatingKey {
                await viewModel.loadSeasonsForShow(showRatingKey: showKey, client: client)
            }
            selectedSeasonKey = meta.ratingKey
            // Episodes already loaded in viewModel.load() for .season type
        default:
            break
        }
    }

    private func extractBackdropColor() async {
        guard let metadata = viewModel.metadata,
              let path = metadata.art ?? metadata.grandparentArt,
              !path.isEmpty,
              let baseURL = appState.activeServer?.baseURL else { return }
        let token = appState.serverToken

        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        guard let url = URL(string: "\(baseURL)/photo/:/transcode?width=100&height=60&minSize=1&upscale=1&url=\(encodedPath)&X-Plex-Token=\(token)") else { return }

        guard let image = await ImageLoader.shared.loadImage(from: url, token: token) else { return }
        let color = image.dominantColor()

        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundTint = color
        }
    }

    private func resolveShowIds(for item: PlexMetadata) async -> (tmdbId: String?, imdbId: String?, mediaType: String) {
        if item.type == "episode" || item.type == "season" {
            let showKey = item.grandparentRatingKey ?? item.parentRatingKey
            if let showKey, let client,
               let showMeta = try? await client.getMetadata(ratingKey: showKey) {
                return (showMeta.tmdbId, showMeta.imdbId, "show")
            }
            return (nil, nil, "show")
        }
        let mediaType = item.type == "show" ? "show" : "movie"
        return (item.tmdbId, item.imdbId, mediaType)
    }

    /// Loads logo, network name, and award badge without blocking the main UI.
    private func loadEnrichmentData(for metadata: PlexMetadata, client: PlexClient) async {
        let resolved = await resolveShowIds(for: metadata)

        async let awardFetch: AwardBadge? = {
            guard let imdbId = resolved.imdbId, !imdbId.isEmpty else { return nil }
            return await OmdbService.shared.getAward(imdbId: imdbId)
        }()

        async let logoFetch: String? = {
            guard let tmdbId = resolved.tmdbId, !tmdbId.isEmpty, metadata.clearLogo == nil else { return nil }
            return await TmdbService.shared.getLogoURL(tmdbId: tmdbId, mediaType: resolved.mediaType)
        }()

        async let networkFetch: String? = {
            guard let tmdbId = resolved.tmdbId, !tmdbId.isEmpty else { return nil }
            return await TmdbService.shared.getNetworkName(tmdbId: tmdbId, mediaType: resolved.mediaType)
        }()

        let (award, logo, network) = await (awardFetch, logoFetch, networkFetch)
        awardBadge = award
        if let logo { logoURL = logo }
        networkName = network
        logoResolved = true
    }

    private func startAutoPreviewIfNeeded(client: PlexClient) async {
        guard previewPlayer == nil else { return }
        let autoPreviewEnabled = UserDefaults.standard.object(forKey: "autoPreview") == nil
            || UserDefaults.standard.bool(forKey: "autoPreview")
        guard autoPreviewEnabled else { return }
        previewManager.onHeroChanged(ratingKey: ratingKey, client: client)
    }

    @ViewBuilder
    private func contentView(metadata: PlexMetadata) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                // Focus anchor while viewModel loads. Without it, the screen
                // has no focusable element (Play button isn't rendered yet,
                // and for movies it's disabled+invisible), so the Menu button
                // bubbles up to tvOS and exits the app instead of popping the
                // NavigationStack. Disappears once isFullyLoaded; focus then
                // transitions to the Play button via .prefersDefaultFocus.
                if !isFullyLoaded {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .focusable()
                }

                // Backdrop — behind the ScrollView, fills edge to edge
                GeometryReader { _ in
                    ZStack {
                        PlexImage(
                            path: metadata.art ?? metadata.grandparentArt,
                            token: appState.serverToken,
                            baseURL: appState.activeServer?.baseURL ?? "",
                            width: 1920,
                            aspectRatio: 16/9,
                            tmdbId: metadata.tmdbId,
                            mediaType: metadata.type
                        )
                        .ignoresSafeArea()

                        // Continue trailer preview from home screen
                        // Falls back to coordinator's transition player on the very first frame
                        // (before onAppear has fired) to avoid a flash of the static backdrop.
                        if let player = previewPlayer ?? coordinator.heroTransition?.previewPlayer {
                            HeroPreviewPlayerView(player: player)
                                .ignoresSafeArea()
                                .transition(.opacity)
                        }
                    }
                    .overlay {
                        // Bottom gradient — hidden in full-screen preview mode
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.35),
                                .init(color: effectiveTint.opacity(0.5), location: 0.6),
                                .init(color: effectiveTint.opacity(0.9), location: 0.78),
                                .init(color: effectiveTint, location: 0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .opacity(isPreviewFullScreen ? 0 : 1)
                    }
                    .overlay(alignment: .leading) {
                        // Left gradient for text legibility against bright backdrops
                        LinearGradient(
                            colors: [effectiveTint.opacity(0.8), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 900)
                        .opacity(isPreviewFullScreen ? 0 : 1)
                    }
                }
                .frame(height: isPreviewFullScreen ? proxy.size.height : proxy.size.height * 0.72)
                .offset(y: isPreviewFullScreen ? 0 : backdropOffset)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .animation(.easeInOut(duration: 0.4), value: isPreviewFullScreen)
                .opacity(isContentBrowsing ? 0 : 1)
                .animation(.easeInOut(duration: 0.4), value: isContentBrowsing)

                // Scrollable content over the backdrop
                ScrollViewReader { outerProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Scroll tracking anchor — invisible, reports position for backdrop parallax
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("detailScroll")).minY
                            )
                        }
                        .frame(height: 0)

                        if metadata.mediaType.isShowRelated {
                            // Fixed spacer so the logo always starts at the same vertical position
                            Color.clear
                                .frame(height: proxy.size.height * 0.50)

                            // Show hero info
                            VStack(alignment: .leading, spacing: 12) {
                                if isFullyLoaded {
                                    showHeroContent(metadata: viewModel.metadata ?? metadata)
                                }
                            }
                            .padding(.horizontal, heroHorizontalPadding)
                            .animation(.easeInOut(duration: 0.45), value: hasAnimatedIn)
                            .id("heroSection")

                            // Show action buttons
                            if isFullyLoaded {
                                actionButtons(metadata: viewModel.metadata ?? metadata)
                                    .padding(.horizontal, heroHorizontalPadding)
                                    .padding(.top, 20)
                            }
                        } else {
                            // Movie: bottom-align content so the play button stays
                            // at a consistent position regardless of description length.
                            // The overlay positions content at the bottom of a fixed-height
                            // region without stretching any internal spacing.
                            Color.clear
                                .frame(height: proxy.size.height * 0.88)
                                .overlay(alignment: .bottomLeading) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        movieHeroContent(metadata: viewModel.metadata ?? metadata)

                                        actionButtons(metadata: viewModel.metadata ?? metadata)
                                            .padding(.top, 8)
                                            .disabled(!isFullyLoaded)
                                    }
                                    .padding(.horizontal, heroHorizontalPadding)
                                    .opacity(isFullyLoaded ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.45), value: isFullyLoaded)
                                }
                                .transaction { $0.animation = nil }
                                .id("heroSection")
                        }

                        // Detail-only content — fades in once full metadata loads
                        if isFullyLoaded {
                            Group {
                                // Director (not shown for episodes — it's a show-level field)
                                if let directorName = metadata.director?.first?.tag, metadata.mediaType != .episode, metadata.mediaType != .movie {
                                    Text("Directed by \(directorName)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.6))
                                        .padding(.horizontal, heroHorizontalPadding)
                                        .padding(.top, 8)
                                }

                                // Episodes — view mode driven by user setting
                                if !viewModel.episodes.isEmpty {
                                    let isEpisode = viewModel.metadata?.mediaType == .episode
                                    let isShowOrSeason = viewModel.metadata?.mediaType == .season || viewModel.metadata?.mediaType == .show
                                    if isEpisode || isShowOrSeason {
                                        let useCarousel = EpisodeViewMode.current == .carousel

                                        // Season pills — show in list mode for show/episode pages
                                        // (carousel mode has its own built-in season picker)
                                        if !useCarousel && !viewModel.seasons.isEmpty {
                                            seasonSection
                                        }

                                        if useCarousel {
                                            episodeCarouselSection
                                        } else {
                                            episodeSection
                                                .id("episodeSection")
                                        }
                                    }
                                } else if !viewModel.seasons.isEmpty && EpisodeViewMode.current != .carousel {
                                    // Before episodes are loaded — show season pills so user can select
                                    // (only in list mode; carousel loads all episodes itself)
                                    seasonSection
                                }

                                // Cast row
                                if let roles = metadata.role, !roles.isEmpty, metadata.mediaType != .movie {
                                    CastRow(
                                        roles: roles,
                                        baseURL: appState.activeServer?.baseURL ?? "",
                                        token: appState.serverToken,
                                        lastFocusedIndex: $lastFocusedCastIndex,
                                        onSelect: { person in
                                            selectedPerson = person
                                        }
                                    )
                                    .padding(.top, 30)
                                    .focusSection()
                                }

                                // Trailers & Extras
                                if !viewModel.extras.isEmpty, metadata.mediaType != .movie {
                                    ExtrasRow(
                                        extras: viewModel.extras,
                                        baseURL: appState.activeServer?.baseURL ?? "",
                                        token: appState.serverToken,
                                        onSelect: { extra in
                                            coordinator.playMedia(ratingKey: extra.ratingKey, resumeOffset: 0)
                                        }
                                    )
                                    .padding(.top, 30)
                                    .focusSection()
                                }

                                // Collection row
                                if !viewModel.collectionItems.isEmpty, let collectionTitle = viewModel.collectionTitle, metadata.mediaType != .movie {
                                    CollectionRow(
                                        title: collectionTitle,
                                        items: viewModel.collectionItems,
                                        baseURL: appState.activeServer?.baseURL ?? "",
                                        token: appState.serverToken,
                                        onSelect: { item in
                                            coordinator.showMediaDetail(ratingKey: item.ratingKey)
                                        }
                                    )
                                    .padding(.top, 30)
                                    .focusSection()
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 60)
                }
                .background {
                    // Darkens the entire background when the episode carousel is focused,
                    // making episode names easier to read. Fades out when focus moves back up.
                    Color.black
                        .opacity(isLowerContentFocused ? 0.5 : 0.0)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.35), value: isLowerContentFocused)
                }
                .coordinateSpace(name: "detailScroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    contentScrollOffset = value
                }
                .scrollClipDisabled()
                .onChange(of: isSummaryFocused) { _, focused in
                    if focused {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            outerProxy.scrollTo("heroSection", anchor: .top)
                        }
                    }
                }
                .onChange(of: scrollToEpisodes) { _, shouldScroll in
                    if shouldScroll {
                        scrollToEpisodes = false
                        withAnimation(.easeInOut(duration: 0.35)) {
                            outerProxy.scrollTo("episodeSection", anchor: .top)
                        }
                    }
                }
                .onChange(of: isActionButtonsFocused) { wasFocused, isFocused in
                    // Scroll back to hero when focus returns from episodes (shows only).
                    // Movies use the two-phase layout and don't need this.
                    if !wasFocused && isFocused,
                       viewModel.metadata?.mediaType != .movie,
                       contentScrollOffset < -50 {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            outerProxy.scrollTo("heroSection", anchor: .top)
                        }
                    }
                }
                .offset(y: isContentBrowsing ? -300 : 0)
                .opacity(isPreviewFullScreen || isContentBrowsing ? 0 : 1)
                .animation(.easeOut(duration: 0.25), value: isContentBrowsing)
                } // ScrollViewReader

                // Movie content browse view (View 2)
                if isContentBrowsing, let fullMeta = viewModel.metadata, fullMeta.mediaType == .movie {
                    movieContentBrowseView(metadata: fullMeta)
                        .background(effectiveTint.opacity(0.95))
                        .transition(.opacity.animation(.easeInOut(duration: 0.45)))
                        .zIndex(1)
                }

                // Full-screen preview overlay — captures focus and exits on down
                if isPreviewFullScreen {
                    Color.clear
                        .ignoresSafeArea()
                        .focusable()
                        .onMoveCommand { direction in
                            if direction == .down {
                                exitPreviewFullScreen()
                            }
                        }
                        .onExitCommand {
                            exitPreviewFullScreen()
                        }
                }

                // Scroll-up hint — shown at top when preview is playing (not full-screen)
                if previewPlayer != nil, !isPreviewFullScreen {
                    VStack(spacing: 6) {
                        Image(systemName: "chevron.compact.up")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Scroll Up to Full Screen")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 50)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: previewPlayer != nil)
                }

                // Scroll-down hint — pinned to bottom of screen for movies
                if isFullyLoaded, !isPreviewFullScreen,
                   viewModel.metadata?.mediaType == .movie, hasMovieContentForBrowsing {
                    VStack(spacing: 6) {
                        Text("Scroll Down for Trailers & Extras")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.compact.down")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea()
                    .offset(y: isContentBrowsing ? -300 : 0)
                    .opacity(isContentBrowsing ? 0 : 1)
                    .animation(.easeOut(duration: 0.25), value: isContentBrowsing)
                    .animation(.easeInOut(duration: 0.4), value: isFullyLoaded)
                    .allowsHitTesting(false)
                }
            }
        }
    }

    private func enterPreviewFullScreen() {
        guard canEnterFullScreen, let player = previewPlayer else { return }
        // Full screen always plays at 100%
        player.isMuted = false
        player.volume = 1.0
        withAnimation(.easeInOut(duration: 0.4)) {
            isPreviewFullScreen = true
        }
    }

    private func exitPreviewFullScreen() {
        if let player = previewPlayer {
            HeroPreviewManager.applyBrowsingVolume(to: player)
        }
        canEnterFullScreen = false
        withAnimation(.easeInOut(duration: 0.4)) {
            isPreviewFullScreen = false
        }
        // Re-enable after a brief cooldown so the same swipe-up doesn't re-trigger
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            canEnterFullScreen = true
        }
    }

    @ViewBuilder
    private var seasonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Seasons")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(viewModel.seasons) { season in
                        SeasonPill(
                            season: season,
                            isSelected: selectedSeasonKey == season.ratingKey,
                            token: appState.serverToken,
                            baseURL: appState.activeServer?.baseURL ?? "",
                            onSelect: {
                                selectedSeasonKey = season.ratingKey
                                Task {
                                    if let client {
                                        await viewModel.loadEpisodes(
                                            seasonRatingKey: season.ratingKey,
                                            client: client
                                        )
                                        scrollToEpisodes = true
                                        // Move focus to the first episode in the loaded season
                                        focusedEpisodeKey = viewModel.episodes.first?.ratingKey
                                    }
                                }
                            }
                        )
                    }
                }
                .focusSection()
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
            }
        }
        .padding(.top, 30)
    }

    @ViewBuilder
    private var episodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Episodes")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 50)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.episodes) { episode in
                    EpisodeRow(
                        episode: episode,
                        isFocused: focusedEpisodeKey == episode.ratingKey,
                        token: appState.serverToken,
                        baseURL: appState.activeServer?.baseURL ?? "",
                        onSelect: {
                            coordinator.playMedia(ratingKey: episode.ratingKey, resumeOffset: episode.viewOffset)
                        }
                    )
                    .focusable()
                    .focused($focusedEpisodeKey, equals: episode.ratingKey)
                }
            }
            .focusSection()
            .defaultFocus($focusedEpisodeKey, currentEpisodeRatingKey)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var episodeCarouselSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Season label — updates based on focused episode, tappable to pick season
            if let seasonTitle = carouselSeasonTitle {
                if viewModel.seasons.count > 1 {
                    SeasonDropdownLabel(title: seasonTitle) {
                        showSeasonPicker = true
                    }
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: seasonTitle)
                    .padding(.horizontal, 50)
                } else {
                    Text(seasonTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 50)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: seasonTitle)
                }
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        ForEach(viewModel.episodes) { episode in
                            EpisodeCarouselCard(
                                episode: episode,
                                isFocused: focusedEpisodeKey == episode.ratingKey,
                                token: appState.serverToken,
                                baseURL: appState.activeServer?.baseURL ?? ""
                            )
                            .focusable()
                            .focused($focusedEpisodeKey, equals: episode.ratingKey)
                            .onPlayPauseCommand { switchToEpisode(episode) }
                            .onTapGesture { switchToEpisode(episode) }
                            .id(episode.ratingKey)
                        }
                    }
                    .padding(.horizontal, 50)
                    .padding(.vertical, 40)
                }
                .defaultFocus($focusedEpisodeKey, currentEpisodeRatingKey ?? ratingKey)
                .focusSection()
                .onChange(of: focusedEpisodeKey) { _, newKey in
                    if let key = newKey,
                       let episode = viewModel.episodes.first(where: { $0.ratingKey == key }) {
                        carouselSeasonOverride = episode.parentTitle
                    }
                    pendingSeasonEpisodeKey = nil
                }
                .onChange(of: viewModel.episodes) { _, _ in
                    scrollToCurrentEpisode(proxy: proxy)
                }
                .onChange(of: currentEpisodeRatingKey) { _, newKey in
                    if let key = newKey {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(key, anchor: .center)
                        }
                    }
                }
                .onAppear {
                    scrollToCurrentEpisode(proxy: proxy)
                }
                .sheet(isPresented: $showSeasonPicker, onDismiss: {
                    guard let key = pendingSeasonEpisodeKey else { return }
                    // Scroll carousel to the first episode of the selected season,
                    // then programmatically move focus there
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(key, anchor: .leading)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            focusedEpisodeKey = key
                        }
                    }
                }) {
                    SeasonPickerSheet(
                        seasons: viewModel.seasons,
                        currentSeasonTitle: carouselSeasonTitle,
                        onSelect: { season in
                            if let firstEpisode = viewModel.episodes.first(where: { $0.parentRatingKey == season.ratingKey }) {
                                pendingSeasonEpisodeKey = firstEpisode.ratingKey
                                carouselSeasonOverride = season.title
                            }
                            showSeasonPicker = false
                        }
                    )
                }
            }
        }
        .padding(.top, 20)
    }

    private func switchToEpisode(_ episode: PlexMetadata) {
        coordinator.playMedia(ratingKey: episode.ratingKey, resumeOffset: episode.viewOffset)
    }

    private func scrollToCurrentEpisode(proxy: ScrollViewProxy) {
        let targetKey = currentEpisodeRatingKey ?? ratingKey
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            proxy.scrollTo(targetKey, anchor: .center)
        }
    }

    @ViewBuilder
    private func actionButtonContent(metadata: PlexMetadata) -> some View {
        HStack(spacing: 16) {
            if let playKey = viewModel.playableRatingKey {
                Button {
                    let offset = viewModel.activeEpisode?.viewOffset ?? viewModel.onDeckEpisode?.viewOffset ?? metadata.viewOffset
                    coordinator.playMedia(ratingKey: playKey, resumeOffset: offset)
                } label: {
                    if metadata.mediaType == .movie,
                       let progress = metadata.watchProgress,
                       let duration = metadata.duration,
                       let viewOffset = metadata.viewOffset {
                        ResumeButtonLabel(
                            progress: progress,
                            remainingText: (duration - viewOffset).shortDurationFormatted
                        )
                    } else if let ep = viewModel.activeEpisode,
                              let progress = ep.watchProgress,
                              let duration = ep.duration,
                              let viewOffset = ep.viewOffset {
                        ResumeButtonLabel(
                            progress: progress,
                            remainingText: (duration - viewOffset).shortDurationFormatted
                        )
                    } else {
                        Label(viewModel.playButtonTitle, systemImage: "play.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .prefersDefaultFocus(in: actionButtonsNamespace)
                .focused($isPlayButtonFocused)
            }

            if metadata.mediaType == .movie,
               let viewOffset = metadata.viewOffset, viewOffset > 0,
               let playKey = viewModel.playableRatingKey {
                Button {
                    coordinator.playMedia(ratingKey: playKey, resumeOffset: 0)
                } label: {
                    RestartButtonLabel()
                }
                .buttonStyle(.bordered)
            }

            if let trailer = viewModel.firstTrailer {
                Button {
                    coordinator.playMedia(ratingKey: trailer.ratingKey, resumeOffset: 0)
                } label: {
                    TrailerButtonLabel()
                }
                .buttonStyle(.bordered)
            }

            Button {
                Task {
                    if let client {
                        // For shows, mark the active episode (not the whole show)
                        let targetKey = viewModel.activeEpisode?.ratingKey ?? metadata.ratingKey
                        let targetIsWatched = viewModel.activeEpisode?.isWatched ?? metadata.isWatched
                        if targetIsWatched {
                            await viewModel.markUnwatched(ratingKey: targetKey, client: client)
                        } else {
                            await viewModel.markWatched(ratingKey: targetKey, client: client)
                            // Show confirmation animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                showWatchedConfirmation = true
                            }
                            // Auto-dismiss after 1.5 seconds
                            Task {
                                try? await Task.sleep(for: .seconds(1.5))
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showWatchedConfirmation = false
                                }
                            }
                        }
                    }
                }
            } label: {
                WatchedButtonLabel(isWatched: viewModel.activeEpisode?.isWatched ?? metadata.isWatched)
            }
            .buttonStyle(.bordered)
            .overlay {
                if showWatchedConfirmation {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            downloadButton(metadata: metadata)
        }
    }

    @ViewBuilder
    private func downloadButton(metadata: PlexMetadata) -> some View {
        let item = DownloadManager.shared.downloads.first { $0.globalKey == metadata.globalKey }
        let status = item?.status

        Button {
            switch status {
            case .queued:
                DownloadManager.shared.cancelDownload(globalKey: metadata.globalKey)
            case .downloading:
                DownloadManager.shared.pauseDownload(globalKey: metadata.globalKey)
            case .paused:
                DownloadManager.shared.retryDownload(globalKey: metadata.globalKey, token: appState.serverToken)
            case .completed:
                showDeleteConfirmation = true
            case .failed:
                DownloadManager.shared.deleteDownload(globalKey: metadata.globalKey)
                Task { await queueDownload(metadata: metadata) }
            case .cancelled, .partial, .none:
                Task { await queueDownload(metadata: metadata) }
            }
        } label: {
            DownloadButtonLabel(
                status: status,
                progress: item?.progress ?? 0
            )
        }
        .buttonStyle(.bordered)
        .disabled(isQueuingDownload && status == nil)
        .confirmationDialog("Remove Download", isPresented: $showDeleteConfirmation) {
            Button("Remove Download", role: .destructive) {
                DownloadManager.shared.deleteDownload(globalKey: metadata.globalKey)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the downloaded file for \"\(metadata.displayTitle)\".")
        }
    }

    private func queueDownload(metadata: PlexMetadata) async {
        guard let client, !isQueuingDownload else { return }
        isQueuingDownload = true
        defer { isQueuingDownload = false }
        do {
            let playbackData = try await client.getVideoPlaybackData(ratingKey: metadata.ratingKey)
            DownloadManager.shared.queueDownload(metadata: metadata, videoURL: playbackData.videoURL, token: appState.serverToken)
        } catch {
            // Silently fail — user can retry
        }
    }

    /// Unified movie/other hero: logo, genre, summary, media info — Apple TV+ style.
    @ViewBuilder
    private func movieHeroContent(metadata: PlexMetadata) -> some View {
        // Award badge
        if let badge = awardBadge {
            AwardBadgeView(badge: badge, contentYear: metadata.year)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.4))
                        .padding(.horizontal, -4)
                        .padding(.vertical, -2)
                )
        }

        // Logo
        if let clearLogo = metadata.clearLogo, !clearLogo.isEmpty {
            PlexImage(
                path: clearLogo,
                token: appState.serverToken,
                baseURL: appState.activeServer?.baseURL ?? "",
                width: logoMaxWidth,
                aspectRatio: 3
            )
            .clipShape(Rectangle())
        } else if let logoURLString = logoURL, let url = URL(string: logoURLString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: logoMaxWidth, maxHeight: logoMaxHeight)
                default:
                    EmptyView()
                }
            }
        } else if logoResolved {
            Text(metadata.displayTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
        }

        // Genre line
        HStack(spacing: 12) {
            if let genres = metadata.genre, !genres.isEmpty {
                Text(genres.prefix(3).map(\.tag).joined(separator: " · "))
            }
            if let network = networkName {
                NetworkLogo(name: network)
            }
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.white.opacity(0.9))

        // Summary paragraph
        if let summary = metadata.summary, !summary.isEmpty {
            Text(summary)
                .font(.subheadline)
                .fontWeight(.light)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(4)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.4, alignment: .leading)
        }

        // Media info line — year, duration, content rating, ratings, badges inline
        HStack(spacing: 16) {
            if let year = metadata.year {
                Text(String(year))
            }
            if let duration = metadata.durationFormatted {
                Text(duration)
            }
            if let contentRating = metadata.contentRating {
                Text(contentRating)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.7), lineWidth: 1)
                    )
            }
            if let imdbRating = metadata.imdbRating {
                HStack(spacing: 6) {
                    Image("imdb-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .accessibilityHidden(true)
                    Text(String(format: "%.1f", imdbRating))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("IMDb rating: \(String(format: "%.1f", imdbRating)) out of 10")
            }
            if let rating = metadata.rating,
               metadata.ratingImage?.contains("rottentomatoes") == true {
                HStack(spacing: 6) {
                    Image(metadata.ratingImage?.contains("rating.rotten") == true ? "rt-rotten" : "rt-fresh")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .accessibilityHidden(true)
                    Text(String(format: "%.0f%%", rating * 10))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Critic score: \(String(format: "%.0f", rating * 10)) percent")
            }
            if let audienceRating = metadata.audienceRating,
               metadata.audienceRatingImage?.contains("rottentomatoes") == true {
                HStack(spacing: 6) {
                    Image(metadata.audienceRatingImage?.contains("spilled") == true ? "rt-spilled" : "rt-upright")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .accessibilityHidden(true)
                    Text(String(format: "%.0f%%", audienceRating * 10))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Audience score: \(String(format: "%.0f", audienceRating * 10)) percent")
            }
            // Format badges inline
            if let fileInfo = viewModel.fileInfo {
                FormatBadgeRow(fileInfo: fileInfo, editionTitle: metadata.editionTitle)
            }
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.white.opacity(0.9))
    }

    /// Unified show hero: logo, genre, episode info, media badges — all in one block.
    @ViewBuilder
    private func showHeroContent(metadata: PlexMetadata) -> some View {
        // Award badge
        if let badge = awardBadge {
            AwardBadgeView(badge: badge, contentYear: metadata.year)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.4))
                        .padding(.horizontal, -4)
                        .padding(.vertical, -2)
                )
        }

        // Logo
        if let clearLogo = metadata.clearLogo, !clearLogo.isEmpty {
            PlexImage(
                path: clearLogo,
                token: appState.serverToken,
                baseURL: appState.activeServer?.baseURL ?? "",
                width: logoMaxWidth,
                aspectRatio: 3
            )
            .clipShape(Rectangle())
        } else if let logoURLString = logoURL, let url = URL(string: logoURLString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: logoMaxWidth, maxHeight: logoMaxHeight)
                default:
                    EmptyView()
                }
            }
        } else if logoResolved {
            Text(metadata.displayTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
        }

        showGenreLine(metadata: metadata)
        showEpisodeParagraph(metadata: metadata)
        showEpisodeMediaInfo(metadata: metadata)
    }

    // MARK: - Show Hero Info Components

    @ViewBuilder
    private func showGenreLine(metadata: PlexMetadata) -> some View {
        HStack(spacing: 12) {
            if let genres = metadata.genre, !genres.isEmpty {
                Text(genres.prefix(3).map(\.tag).joined(separator: " · "))
            }
            if let network = networkName {
                NetworkLogo(name: network)
            }
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.white.opacity(0.9))
    }

    @ViewBuilder
    private func showEpisodeParagraph(metadata: PlexMetadata) -> some View {
        Group {
            if viewModel.showNeverWatched {
                // Show-level summary for never-watched shows (max 4 lines)
                if let summary = metadata.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.callout)
                        .fontWeight(.light)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(4)
                }
            } else if let episode = viewModel.activeEpisode {
                // Episode info: "S1, E5 · Episode Name: description"
                let seasonNum = episode.parentIndex ?? 1
                let episodeNum = episode.index ?? 1
                let prefix = "S\(seasonNum), E\(episodeNum)"
                let title = episode.title
                let summary = episode.summary ?? ""
                let text = summary.isEmpty
                    ? "\(prefix) · \(title)"
                    : "\(prefix) · \(title): \(summary)"

                Text(text)
                    .font(.callout)
                    .fontWeight(.light)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(4)
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.4, alignment: .leading)
    }

    @ViewBuilder
    private func showEpisodeMediaInfo(metadata: PlexMetadata) -> some View {
        let ep = viewModel.activeEpisode
        let epFileInfo = viewModel.activeEpisodeFileInfo

        HStack(spacing: 16) {
            // Year — from episode air date, fallback to show year
            if let episode = ep,
               let airDate = episode.originallyAvailableAt,
               let yearStr = airDate.split(separator: "-").first,
               let year = Int(yearStr) {
                Text(String(year))
            } else if let year = metadata.year {
                Text(String(year))
            }
            // Duration — from active episode
            if let episode = ep,
               let duration = episode.durationFormatted {
                Text(duration)
            }
            // Content rating — from show or episode metadata
            if let contentRating = metadata.contentRating {
                Text(contentRating)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.7), lineWidth: 1)
                    )
            }
            // IMDb rating — from show metadata
            if let imdbRating = metadata.imdbRating {
                HStack(spacing: 6) {
                    Image("imdb-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .accessibilityHidden(true)
                    Text(String(format: "%.1f", imdbRating))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("IMDb rating: \(String(format: "%.1f", imdbRating)) out of 10")
            }
            // RT Critic — from metadata
            if let rating = metadata.rating,
               metadata.ratingImage?.contains("rottentomatoes") == true {
                HStack(spacing: 6) {
                    Image(metadata.ratingImage?.contains("rating.rotten") == true ? "rt-rotten" : "rt-fresh")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .accessibilityHidden(true)
                    Text(String(format: "%.0f%%", rating * 10))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Critic score: \(String(format: "%.0f", rating * 10)) percent")
            }
            // RT Audience — from metadata
            if let audienceRating = metadata.audienceRating,
               metadata.audienceRatingImage?.contains("rottentomatoes") == true {
                HStack(spacing: 6) {
                    Image(metadata.audienceRatingImage?.contains("spilled") == true ? "rt-spilled" : "rt-upright")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .accessibilityHidden(true)
                    Text(String(format: "%.0f%%", audienceRating * 10))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Audience score: \(String(format: "%.0f", audienceRating * 10)) percent")
            }
            // Format badges inline — from active episode's file info
            if let fileInfo = epFileInfo {
                FormatBadgeRow(fileInfo: fileInfo, editionTitle: nil)
            }
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.white.opacity(0.9))
    }

    // MARK: - Movie Content Browse (View 2)

    @ViewBuilder
    private func movieContentBrowseView(metadata: PlexMetadata) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Centered logo
                HStack {
                    Spacer()
                    if let clearLogo = metadata.clearLogo, !clearLogo.isEmpty {
                        PlexImage(
                            path: clearLogo,
                            token: appState.serverToken,
                            baseURL: appState.activeServer?.baseURL ?? "",
                            width: 350,
                            aspectRatio: 3
                        )
                        .clipShape(Rectangle())
                    } else if let logoURLString = logoURL, let url = URL(string: logoURLString) {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 350, maxHeight: 117)
                            }
                        }
                    } else if logoResolved {
                        Text(metadata.displayTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding(.top, 40)

                // Invisible exit trap — when focus moves above the first carousel,
                // it lands here and triggers the transition back to View 1.
                // Always present for stable layout; focusable only after delay
                // so it doesn't steal focus on appearance.
                Color.clear
                    .frame(height: 1)
                    .focusable(isExitTrapEnabled)
                    .focused($isContentBrowseExitFocused)

                // Trailers carousel
                if !viewModel.trailers.isEmpty {
                    ExtrasRow(
                        extras: viewModel.trailers,
                        baseURL: appState.activeServer?.baseURL ?? "",
                        token: appState.serverToken,
                        onSelect: { extra in
                            coordinator.playMedia(ratingKey: extra.ratingKey, resumeOffset: 0)
                        },
                        title: "Trailers",
                        cardWidth: 450
                    )
                    .focusSection()
                }

                // Bonus Content carousel
                if !viewModel.bonusContent.isEmpty {
                    ExtrasRow(
                        extras: viewModel.bonusContent,
                        baseURL: appState.activeServer?.baseURL ?? "",
                        token: appState.serverToken,
                        onSelect: { extra in
                            coordinator.playMedia(ratingKey: extra.ratingKey, resumeOffset: 0)
                        },
                        title: "Bonus Content",
                        cardWidth: 450
                    )
                    .focusSection()
                }

                // Related Movies carousel
                if !viewModel.collectionItems.isEmpty, let collectionTitle = viewModel.collectionTitle {
                    CollectionRow(
                        title: collectionTitle,
                        items: viewModel.collectionItems,
                        baseURL: appState.activeServer?.baseURL ?? "",
                        token: appState.serverToken,
                        onSelect: { item in
                            coordinator.showMediaDetail(ratingKey: item.ratingKey)
                        }
                    )
                    .focusSection()
                }

                // Cast & Crew carousel
                if let roles = metadata.role, !roles.isEmpty {
                    CastRow(
                        roles: roles,
                        baseURL: appState.activeServer?.baseURL ?? "",
                        token: appState.serverToken,
                        lastFocusedIndex: $lastFocusedCastIndex,
                        iconSize: 240,
                        onSelect: { person in
                            selectedPerson = person
                        }
                    )
                    .focusSection()
                }
            }
            .padding(.bottom, 60)
        }
        .onExitCommand {
            withAnimation(.easeOut(duration: 0.25)) {
                isContentBrowsing = false
            }
        }
        .onChange(of: isContentBrowseExitFocused) { _, focused in
            if focused {
                withAnimation(.easeOut(duration: 0.25)) {
                    isContentBrowsing = false
                    isExitTrapEnabled = false
                }
            }
        }
        .onAppear {
            // Enable exit trap after focus has settled on a carousel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isExitTrapEnabled = true
            }
        }
        .onDisappear {
            isExitTrapEnabled = false
        }
    }

    @ViewBuilder
    private func actionButtons(metadata: PlexMetadata) -> some View {
        // HStack + Spacer makes the focus area span full screen width
        // so episodes at any horizontal position can navigate up to here.
        // The buttons stay visually left-aligned.
        HStack {
            if #available(tvOS 26.0, *) {
                GlassEffectContainer {
                    actionButtonContent(metadata: metadata)
                }
            } else {
                actionButtonContent(metadata: metadata)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.black.opacity(0.4))
                    )
            }
            Spacer()
        }
        .focusScope(actionButtonsNamespace)
        .focused($isActionButtonsFocused)
        .focusSection()
        .onMoveCommand { direction in
            if direction == .up { enterPreviewFullScreen() }
            if direction == .down && hasMovieContentForBrowsing {
                withAnimation(.easeInOut(duration: 0.45)) {
                    isContentBrowsing = true
                }
            }
        }
    }

    private func episodeAccessibilityLabel(_ episode: PlexMetadata) -> String {
        var parts: [String] = []
        if let index = episode.index {
            parts.append("Episode \(index)")
        }
        parts.append(episode.title)
        if let duration = episode.durationFormatted {
            parts.append(duration)
        }
        if episode.isWatched {
            parts.append("Watched")
        } else if let progress = episode.watchProgress {
            parts.append("\(Int(progress * 100))% watched")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Season Pill (focusable, no Button)

private struct SeasonPill: View {
    let season: PlexMetadata
    let isSelected: Bool
    let token: String
    let baseURL: String
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            PlexImage(
                path: season.thumb,
                token: token,
                baseURL: baseURL,
                width: 180,
                aspectRatio: 2/3
            )
            Text(season.title)
                .font(.caption)
                .lineLimit(1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? .white : (isSelected ? .accentColor : .clear), lineWidth: isFocused ? 4 : (isSelected ? 2 : 0))
        )
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand { onSelect() }
        .onTapGesture { onSelect() }
    }
}

// MARK: - Resume Button Label

private struct ResumeButtonLabel: View {
    let progress: Double
    let remainingText: String
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.fill")
            Capsule()
                .fill(isFocused ? Color.gray.opacity(0.4) : Color.white.opacity(0.3))
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(isFocused ? .black : .white)
                            .frame(width: geo.size.width * min(max(progress, 0), 1))
                    }
                }
                .clipShape(Capsule())
                .frame(width: 100, height: 6)
            Text(remainingText)
        }
    }
}

// MARK: - Restart Button Label

private struct RestartButtonLabel: View {
    var body: some View {
        Image(systemName: "arrow.counterclockwise")
    }
}

// MARK: - Watched Button Label

private struct WatchedButtonLabel: View {
    let isWatched: Bool

    var body: some View {
        Image(systemName: isWatched ? "eye.slash" : "eye")
    }
}

// MARK: - Download Button Label

private struct DownloadButtonLabel: View {
    let status: DownloadStatus?
    let progress: Double

    private var tint: Color? {
        switch status {
        case .paused: return .yellow
        case .completed: return .green
        case .failed: return .red
        default: return nil
        }
    }

    var body: some View {
        downloadIcon
            .foregroundStyle(tint ?? .primary)
    }

    @ViewBuilder
    private var downloadIcon: some View {
        switch status {
        case .downloading:
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: max(progress, 0.02))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "arrow.down")
                    .font(.system(size: 14, weight: .bold))
            }
            .frame(width: 30, height: 30)
        case .queued:
            Image(systemName: "clock")
        case .paused:
            Image(systemName: "pause.circle")
        case .completed:
            Image(systemName: "checkmark.circle")
        case .failed:
            Image(systemName: "exclamationmark.circle")
        case .cancelled, .partial, .none:
            Image(systemName: "arrow.down.circle")
        }
    }
}

// MARK: - Trailer Button Label

private struct TrailerButtonLabel: View {
    var body: some View {
        Image(systemName: "film")
    }
}

// MARK: - Episode Row (focusable, no Button)

private struct EpisodeRow: View {
    let episode: PlexMetadata
    let isFocused: Bool
    let token: String
    let baseURL: String
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            PlexImage(
                path: episode.thumb,
                token: token,
                baseURL: baseURL,
                width: 200,
                aspectRatio: 16/9
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if let index = episode.index {
                        Text("E\(index)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Text(episode.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                if let summary = episode.summary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }

                if let duration = episode.durationFormatted {
                    Text(duration)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }

                if let progress = episode.watchProgress {
                    ProgressBar(progress: progress)
                        .frame(height: 3)
                        .frame(maxWidth: 200)
                }
            }

            Spacer()

            if episode.isWatched {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFocused ? .white.opacity(0.25) : .clear)
                .padding(.horizontal, 40)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .onPlayPauseCommand { onSelect() }
        .onTapGesture { onSelect() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        if let index = episode.index {
            parts.append("Episode \(index)")
        }
        parts.append(episode.title)
        if let duration = episode.durationFormatted {
            parts.append(duration)
        }
        if episode.isWatched {
            parts.append("Watched")
        } else if let progress = episode.watchProgress {
            parts.append("\(Int(progress * 100))% watched")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Episode Carousel Card

private struct EpisodeCarouselCard: View {
    let episode: PlexMetadata
    let isFocused: Bool
    let token: String
    let baseURL: String

    private let cardWidth: CGFloat = 560

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                PlexImage(
                    path: episode.thumb,
                    token: token,
                    baseURL: baseURL,
                    width: cardWidth,
                    aspectRatio: 16/9
                )

                // Gradient scrim
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Bottom-left overlay: icon + progress bar + duration
                HStack(spacing: 8) {
                    // Play / Replay icon
                    Image(systemName: episode.isWatched ? "arrow.counterclockwise" : "play.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)

                    // Inline progress bar (in-progress only)
                    if let progress = episode.watchProgress {
                        Capsule()
                            .fill(.white.opacity(0.3))
                            .frame(width: 40, height: 4)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(.white)
                                    .frame(width: 40 * min(max(progress, 0), 1))
                            }
                    }

                    // Duration / remaining time
                    if let label = durationLabel {
                        Text(label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .frame(width: cardWidth, height: cardWidth / (16/9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .opacity(isFocused ? 1 : 0)
            )

            // -- Text below thumbnail --
            VStack(alignment: .leading, spacing: 4) {
                // "EPISODE 4"
                if let index = episode.index {
                    Text("EPISODE \(index)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1)
                }

                // Title
                Text(episode.title)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Summary
                if let summary = episode.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                }

                // Release date · Rating
                if let metaLine = episodeMetaLine {
                    Text(metaLine)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(width: cardWidth, alignment: .leading)
        }
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Release date and rating line, e.g. "Mar 4, 2025 · 8.5"
    private var episodeMetaLine: String? {
        var parts: [String] = []
        if let dateStr = episode.originallyAvailableAt,
           let date = ISO8601DateFormatter().date(from: dateStr + "T00:00:00Z") {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            parts.append(formatter.string(from: date))
        }
        if let rating = episode.rating {
            parts.append(String(format: "%.1f", rating))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Formatted duration label — remaining time when in-progress, total otherwise.
    private var durationLabel: String? {
        if episode.watchProgress != nil,
           let duration = episode.duration,
           let viewOffset = episode.viewOffset {
            let remainingMs = max(0, duration - viewOffset)
            return remainingMs.shortDurationFormatted
        }
        return episode.durationFormatted
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        if let index = episode.index {
            parts.append("Episode \(index)")
        }
        parts.append(episode.title)
        if episode.isWatched {
            parts.append("Watched")
        } else if let progress = episode.watchProgress {
            parts.append("\(Int(progress * 100))% watched")
        }
        if let label = durationLabel {
            parts.append(label)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Network Logo

private struct NetworkLogo: View {
    let name: String

    /// TMDB provider names that don't directly match file names.
    private static let nameOverrides: [String: String] = [
        "Amazon Prime Video": "amazon",
        "Amazon Video": "amazon",
        "Disney Plus": "disney+",
        "HBO Max": "hbo-max",
        "Paramount Plus": "paramount+",
        "Apple TV Plus": "apple-tv+",
        "BritBox UK": "britbox",
    ]

    /// Logos with compact shapes that need a larger frame to look balanced.
    private static let sizeOverrides: [String: CGFloat] = [
        "network-disney+": 45,
    ]

    private var assetName: String {
        let key = name.lowercased().replacingOccurrences(of: " ", with: "-")
        if let override = Self.nameOverrides[name] {
            return "network-" + override
        }
        return "network-" + key
    }

    private var logoHeight: CGFloat {
        Self.sizeOverrides[assetName] ?? 30
    }

    var body: some View {
        if let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(height: logoHeight)
                .accessibilityLabel(name)
        }
    }
}

// MARK: - Season Dropdown

private struct SeasonDropdownLabel: View {
    let title: String
    let onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? Color.white.opacity(0.25) : Color.clear)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            Spacer()
        }
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand { onSelect() }
        .onTapGesture { onSelect() }
    }
}

// MARK: - Season Picker Sheet

private struct SeasonPickerSheet: View {
    let seasons: [PlexMetadata]
    let currentSeasonTitle: String?
    let onSelect: (PlexMetadata) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSeasonKey: String?

    private var currentSeasonKey: String? {
        seasons.first(where: { $0.title == currentSeasonTitle })?.ratingKey
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Select Season")
                .font(.headline)
                .padding(.top, 40)
                .padding(.bottom, 24)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(seasons) { season in
                            let isCurrent = season.title == currentSeasonTitle
                            Button {
                                onSelect(season)
                            } label: {
                                HStack {
                                    Text(season.title)
                                        .font(.body)
                                        .fontWeight(isCurrent ? .bold : .regular)
                                    Spacer()
                                    if isCurrent {
                                        Image(systemName: "checkmark")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(SeasonPickerRowStyle(isCurrent: isCurrent))
                            .focused($focusedSeasonKey, equals: season.ratingKey)
                            .id(season.ratingKey)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .defaultFocus($focusedSeasonKey, currentSeasonKey)
                .onAppear {
                    if let key = currentSeasonKey {
                        proxy.scrollTo(key, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 600)
        .background(.ultraThinMaterial)
    }
}

private struct SeasonPickerRowStyle: ButtonStyle {
    let isCurrent: Bool
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white.opacity(0.3) : (isCurrent ? Color.white.opacity(0.1) : Color.clear))
            )
    }
}

