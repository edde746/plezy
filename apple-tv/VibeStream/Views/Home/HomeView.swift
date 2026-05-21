import SwiftUI
import UIKit
import AVFoundation

// MARK: - Dominant Color Extraction

private extension UIImage {
    /// Extracts the dominant color from the image by sampling pixels.
    /// Returns a darkened version suitable for backgrounds.
    func dominantColor(darkened: CGFloat = 0.35) -> Color {
        guard let cgImage = self.cgImage else { return .black }

        let size = 40
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: size * size * 4)

        guard let context = CGContext(
            data: &pixelData,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .black }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var totalWeight: CGFloat = 0

        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = CGFloat(pixelData[i]) / 255.0
            let g = CGFloat(pixelData[i + 1]) / 255.0
            let b = CGFloat(pixelData[i + 2]) / 255.0

            let maxC = max(r, g, b)
            let minC = min(r, g, b)
            let saturation = maxC > 0 ? (maxC - minC) / maxC : 0
            let brightness = maxC

            // Prefer saturated, mid-brightness pixels
            let weight = saturation * (1.0 - abs(brightness - 0.5) * 0.5) + 0.1

            totalR += r * weight
            totalG += g * weight
            totalB += b * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return .black }

        let avgR = (totalR / totalWeight) * darkened
        let avgG = (totalG / totalWeight) * darkened
        let avgB = (totalB / totalWeight) * darkened

        return Color(red: avgR, green: avgG, blue: avgB)
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(MediaFocusModel.self) private var focusModel
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var viewModel = HomeViewModel()
    @State private var previewManager = HeroPreviewManager()
    @State private var heroLogoURL: String?
    @State private var heroLogoImage: UIImage?
    @State private var heroLogoResolved = false

    // Decoupled display state — the hero area renders displayedHero,
    // not heroItem directly. This lets us batch-update everything at
    // once with a cross-fade instead of piecemeal updates.
    @State private var displayedHero: PlexMetadata?
    @State private var heroContentOpacity: Double = 0

    // Fixed background — no per-item color swapping
    private let heroGradientColor = Color(white: 0.08)

    // Long-press context menu state
    @State private var longPressItem: PlexMetadata?
    @State private var longPressIsContinueWatching = false
    @State private var showLongPressOverlay = false

    // Suppresses preview replay when backing out of detail page for the same item
    @State private var suppressedPreviewKey: String?
    @State private var contentReady = false

    // Caches so revisiting a previously focused item is instant
    @State private var colorCache: [String: Color] = [:]
    @State private var logoURLCache: [String: String] = [:]  // ratingKey -> logoURL ("" = no logo)
    @State private var tmdbIdCache: [String: (tmdbId: String?, imdbId: String?, mediaType: String)] = [:]
    @State private var heroAwardBadge: AwardBadge?
    @State private var awardCache: [String: AwardBadge?] = [:]

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

    /// Index of the "Recently Added Movies" hub — trending rows are inserted after it.
    /// Falls back to first "Recently Added" hub, or 0 if none found.
    private var trendingInsertionIndex: Int {
        // First, try to find "Recently Added" with "Movies" specifically
        if let movieIndex = viewModel.hubs.firstIndex(where: {
            let title = $0.title.lowercased()
            return title.contains("recently added") && title.contains("movie")
        }) {
            return movieIndex
        }
        // Fallback: first "Recently Added" hub of any type
        if let firstIndex = viewModel.hubs.firstIndex(where: {
            $0.title.localizedCaseInsensitiveContains("Recently Added")
        }) {
            return firstIndex
        }
        return 0
    }

    /// The item to display in the hero area — the currently focused card, or the first available item
    private var heroItem: PlexMetadata? {
        focusModel.focusedMedia
            ?? viewModel.continueWatching.first
            ?? viewModel.hubs.first(where: { !$0.items.isEmpty })?.items.first
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                // Hero backdrop — renders displayedHero (not heroItem) to avoid
                // piecemeal updates. Updated via batch cross-fade.
                if let hero = displayedHero {
                    GeometryReader { _ in
                        ZStack {
                            PlexImage(
                                path: hero.art ?? hero.grandparentArt ?? hero.thumb,
                                token: appState.serverToken,
                                baseURL: appState.activeServer?.baseURL ?? "",
                                width: 1920,
                                aspectRatio: 16.0 / 9.0,
                                tmdbId: hero.tmdbId,
                                mediaType: hero.type
                            )
                            .ignoresSafeArea()

                            if let player = previewManager.player, previewManager.isActive {
                                HeroPreviewPlayerView(player: player)
                                    .ignoresSafeArea()
                                    .transition(.opacity)
                            }
                        }
                    }
                    .frame(height: proxy.size.height * 0.75)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .opacity(heroContentOpacity)
                    .id(hero.ratingKey)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.6), value: previewManager.isActive)
                }

                // Permanent gradients — never transition, always visible
                ZStack(alignment: .leading) {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: heroGradientColor.opacity(0.3), location: 0.35),
                            .init(color: heroGradientColor.opacity(0.7), location: 0.45),
                            .init(color: heroGradientColor.opacity(0.95), location: 0.55),
                            .init(color: heroGradientColor, location: 0.65)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    LinearGradient(
                        colors: [heroGradientColor.opacity(0.6), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 700)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    // Hero info overlay — sits in the lower portion of the hero backdrop
                    if let hero = displayedHero {
                        heroInfoView(for: hero)
                            .frame(maxWidth: proxy.size.width * 0.55, alignment: .leading)
                            .padding(.horizontal, 80)
                            .padding(.bottom, 20)
                            .opacity(heroContentOpacity)
                            .id(hero.ratingKey)
                            .transition(.opacity)
                    }

                    // Scrollable carousel rows — takes the bottom half of the screen
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 40) {
                            // Continue Watching
                            if !viewModel.continueWatching.isEmpty {
                                ContinueWatchingRow(
                                    items: viewModel.continueWatching,
                                    baseURL: appState.activeServer?.baseURL ?? "",
                                    token: appState.serverToken,
                                    onItemSelected: { item in
                                        guard !showLongPressOverlay else { return }
                                        captureHeroTransition(for: item)
                                        coordinator.showMediaDetail(ratingKey: item.ratingKey)
                                    },
                                    onItemLongPressed: { item in
                                        showContextMenu(for: item, isContinueWatching: true)
                                    }
                                )
                            }

                            // Hub Carousels with Top 10 Trending inserted after Recently Added
                            ForEach(Array(viewModel.hubs.enumerated()), id: \.element.id) { index, hub in
                                HubRow(
                                    title: hub.title,
                                    items: hub.items,
                                    baseURL: appState.activeServer?.baseURL ?? "",
                                    token: appState.serverToken,
                                    onItemSelected: { item in
                                        guard !showLongPressOverlay else { return }
                                        captureHeroTransition(for: item)
                                        coordinator.showMediaDetail(ratingKey: item.ratingKey)
                                    },
                                    onItemLongPressed: { item in
                                        showContextMenu(for: item, isContinueWatching: false)
                                    },
                                    onSeeAll: {
                                        coordinator.showHubDetail(hubKey: hub.hubKey, title: hub.title)
                                    }
                                )

                                // Insert trending rows after the last "Recently Added" hub
                                if trendingInsertionIndex == index {
                                    if !viewModel.trendingMovies.isEmpty {
                                        TrendingRow(
                                            title: "Top 10 Trending Movies",
                                            items: viewModel.trendingMovies,
                                            baseURL: appState.activeServer?.baseURL ?? "",
                                            token: appState.serverToken,
                                            onItemSelected: { item in
                                                guard !showLongPressOverlay else { return }
                                                captureHeroTransition(for: item)
                                                coordinator.showMediaDetail(ratingKey: item.ratingKey)
                                            },
                                            onItemLongPressed: { item in
                                                showContextMenu(for: item, isContinueWatching: false)
                                            }
                                        )
                                    }

                                    if !viewModel.trendingShows.isEmpty {
                                        TrendingRow(
                                            title: "Top 10 Trending Shows",
                                            items: viewModel.trendingShows,
                                            baseURL: appState.activeServer?.baseURL ?? "",
                                            token: appState.serverToken,
                                            onItemSelected: { item in
                                                guard !showLongPressOverlay else { return }
                                                captureHeroTransition(for: item)
                                                coordinator.showMediaDetail(ratingKey: item.ratingKey)
                                            },
                                            onItemLongPressed: { item in
                                                showContextMenu(for: item, isContinueWatching: false)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .frame(height: proxy.size.height * 0.55)
                }
            }
        }
        .background(heroGradientColor)
        .ignoresSafeArea(edges: .top)
        .disabled(showLongPressOverlay)
        .opacity(contentReady ? 1 : 0)
        .animation(.easeIn(duration: 0.4), value: contentReady)
        .overlay {
            if showLongPressOverlay, let item = longPressItem {
                LongPressOverlay(
                    item: item,
                    baseURL: appState.activeServer?.baseURL ?? "",
                    token: appState.serverToken,
                    isContinueWatching: longPressIsContinueWatching,
                    onDismiss: {
                        showLongPressOverlay = false
                    },
                    onResume: { offset in
                        showLongPressOverlay = false
                        coordinator.playMedia(ratingKey: item.ratingKey, resumeOffset: offset)
                    },
                    onPlayFromBeginning: {
                        showLongPressOverlay = false
                        coordinator.playMedia(ratingKey: item.ratingKey, resumeOffset: 0)
                    },
                    onPlay: {
                        showLongPressOverlay = false
                        coordinator.playMedia(ratingKey: item.ratingKey)
                    },
                    onRemoveFromContinueWatching: {
                        showLongPressOverlay = false
                        Task {
                            if let client {
                                try? await client.removeFromOnDeck(ratingKey: item.ratingKey)
                                await viewModel.refresh(client: client, serverIdentifier: appState.activeServer?.clientIdentifier ?? "default")
                            }
                        }
                    },
                    onMarkWatched: {
                        showLongPressOverlay = false
                        Task {
                            if let client {
                                try? await client.markAsWatched(ratingKey: item.ratingKey)
                                await viewModel.refresh(client: client, serverIdentifier: appState.activeServer?.clientIdentifier ?? "default")
                            }
                        }
                    },
                    onMarkUnwatched: {
                        showLongPressOverlay = false
                        Task {
                            if let client {
                                try? await client.markAsUnwatched(ratingKey: item.ratingKey)
                                await viewModel.refresh(client: client, serverIdentifier: appState.activeServer?.clientIdentifier ?? "default")
                            }
                        }
                    },
                    onMoreInfo: {
                        showLongPressOverlay = false
                        captureHeroTransition(for: item)
                        coordinator.showMediaDetail(ratingKey: item.ratingKey)
                    }
                )
                .transition(AnyTransition.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showLongPressOverlay)
        .task(id: appState.connectionStatus) {
            guard appState.connectionStatus == .connected else { return }
            if let client, viewModel.hubs.isEmpty {
                await viewModel.loadHubs(client: client, serverIdentifier: appState.activeServer?.clientIdentifier ?? "default")
            }
            if !contentReady && !viewModel.hubs.isEmpty {
                withAnimation(.easeIn(duration: 0.4)) {
                    contentReady = true
                }
            }
        }
        .task(id: coordinator.homeRefreshTrigger) {
            guard coordinator.homeRefreshTrigger > 0,
                  appState.connectionStatus == .connected,
                  let client else { return }
            await viewModel.refresh(client: client, serverIdentifier: appState.activeServer?.clientIdentifier ?? "default")
        }
        .task(id: heroItem?.ratingKey) {
            previewManager.stop()
            heroAwardBadge = nil

            guard let hero = heroItem else { return }
            let key = hero.ratingKey
            let isFirstHero = displayedHero == nil

            // Clear suppression when focus moves to a different item
            if key != suppressedPreviewKey {
                suppressedPreviewKey = nil
            }

            // --- Resolve all data before committing ---

            // Pre-load backdrop in parallel with other data
            async let backdropPreload: Void = preloadHeroBackdrop(for: hero)

            // Resolve show-level IDs for episodes/seasons (needed for logo + award)
            let resolved: (tmdbId: String?, imdbId: String?, mediaType: String)
            if let cached = tmdbIdCache[key] {
                resolved = cached
            } else {
                resolved = await resolveShowIds(for: hero)
                tmdbIdCache[key] = resolved
            }

            guard !Task.isCancelled else { return }

            // Now that we have the resolved IMDb ID, start award fetch in parallel
            let resolvedImdbId = resolved.imdbId
            async let awardPreload: AwardBadge? = {
                guard let imdbId = resolvedImdbId, !imdbId.isEmpty else { return nil }
                if let cached = awardCache[imdbId] { return cached }
                return await OmdbService.shared.getAward(imdbId: imdbId)
            }()

            // Color: use cache or extract
            let newColor: Color
            if let cachedColor = colorCache[key] {
                newColor = cachedColor
            } else {
                newColor = await extractColor(for: hero)
                colorCache[key] = newColor
            }

            // Bail early if user scrolled away during color extraction
            guard !Task.isCancelled else { return }

            // Logo URL: use cache or fetch
            var newLogoURL: String? = nil
            var newLogoResolved = false
            if let cachedLogo = logoURLCache[key] {
                newLogoURL = cachedLogo.isEmpty ? nil : cachedLogo
                newLogoResolved = true
            } else if hero.clearLogo != nil {
                newLogoResolved = true
                logoURLCache[key] = ""
            } else {
                if let tmdbId = resolved.tmdbId, !tmdbId.isEmpty {
                    newLogoURL = await TmdbService.shared.getLogoURL(tmdbId: tmdbId, mediaType: resolved.mediaType)
                }
                logoURLCache[key] = newLogoURL ?? ""
                newLogoResolved = true
            }

            // Bail early if user scrolled away during logo URL fetch
            guard !Task.isCancelled else { return }

            // Pre-load the actual logo image so it renders instantly on commit
            // (no AsyncImage/PlexImage loading delay).
            var newLogoImage: UIImage? = nil
            if let clearLogo = hero.clearLogo, !clearLogo.isEmpty {
                newLogoImage = await loadPlexLogo(path: clearLogo)
            } else if let urlString = newLogoURL, let url = URL(string: urlString) {
                newLogoImage = await ImageLoader.shared.loadImage(from: url)
            }

            // Bail early if user scrolled away during logo image download
            guard !Task.isCancelled else { return }

            // Wait for backdrop and award pre-loads to finish
            await backdropPreload
            let resolvedAward = await awardPreload
            if let imdbId = resolvedImdbId, !imdbId.isEmpty {
                awardCache[imdbId] = resolvedAward
            }

            // Bail early if user scrolled away during preloads
            guard !Task.isCancelled else { return }

            // Verify we're still focused on this hero (task may have been superseded)
            guard heroItem?.ratingKey == key else { return }

            // --- Batch-commit all state at once ---

            // Cache color for detail page transitions
            coordinator.backgroundTint = newColor

            if isFirstHero {
                // First hero — set everything, then fade in
                displayedHero = hero
                heroLogoURL = newLogoURL
                heroLogoImage = newLogoImage
                heroLogoResolved = newLogoResolved
                heroAwardBadge = resolvedAward
                withAnimation(.easeIn(duration: 0.4)) {
                    heroContentOpacity = 1
                }
            } else {
                // Cross-fade: .id() + .transition(.opacity) on the views
                // makes SwiftUI remove the old view and insert the new one,
                // so the old backdrop fades out while the new one fades in.
                withAnimation(.easeInOut(duration: 0.35)) {
                    displayedHero = hero
                    heroLogoURL = newLogoURL
                    heroLogoImage = newLogoImage
                    heroLogoResolved = newLogoResolved
                    heroAwardBadge = resolvedAward
                }
            }

            // Start auto-preview timer (if enabled and not suppressed)
            let autoPreviewEnabled = UserDefaults.standard.object(forKey: "autoPreview") == nil
                || UserDefaults.standard.bool(forKey: "autoPreview")
            if autoPreviewEnabled, suppressedPreviewKey != key, let client {
                previewManager.onHeroChanged(ratingKey: key, client: client)
            }
        }
        .onDisappear {
            previewManager.cleanup()
        }
    }

    /// Extracts the dominant color from a hero item's artwork. Returns the
    /// color without modifying any state so callers can batch-commit.
    private func extractColor(for hero: PlexMetadata) async -> Color {
        guard let path = hero.art ?? hero.grandparentArt ?? hero.thumb,
              !path.isEmpty,
              let baseURL = appState.activeServer?.baseURL else { return .black }
        let token = appState.serverToken

        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        guard let url = URL(string: "\(baseURL)/photo/:/transcode?width=100&height=60&minSize=1&upscale=1&url=\(encodedPath)&X-Plex-Token=\(token)") else { return .black }

        guard let image = await ImageLoader.shared.loadImage(from: url, token: token) else { return .black }
        return image.dominantColor()
    }

    /// Loads a Plex clear-logo image via the transcoder at the dimensions
    /// used by heroInfoView, returning the UIImage for direct rendering.
    private func loadPlexLogo(path: String) async -> UIImage? {
        guard let baseURL = appState.activeServer?.baseURL else { return nil }
        let token = appState.serverToken
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        let scaledWidth = 400 * 2
        let scaledHeight = Int(400.0 / 3.0) * 2
        guard let url = URL(string: "\(baseURL)/photo/:/transcode?width=\(scaledWidth)&height=\(scaledHeight)&minSize=1&upscale=1&url=\(encodedPath)&X-Plex-Token=\(token)") else { return nil }
        return await ImageLoader.shared.loadImage(from: url, token: token)
    }

    /// Pre-loads the hero backdrop image into ImageLoader's memory cache so
    /// that PlexImage renders it instantly when displayedHero is committed
    /// (no loading spinner visible during the cross-fade).
    private func preloadHeroBackdrop(for hero: PlexMetadata) async {
        let path = hero.art ?? hero.grandparentArt ?? hero.thumb
        guard let path, !path.isEmpty else { return }

        // Match PlexImage's preferTmdbBackdrop logic (aspect > 1, width >= 600, tmdbId set)
        if let tmdbId = hero.tmdbId, !tmdbId.isEmpty {
            let tmdbType = (hero.type == "show" || hero.type == "episode" || hero.type == "season") ? "show" : "movie"
            if let tmdbURL = await TmdbService.shared.getBackdropURL(tmdbId: tmdbId, mediaType: tmdbType),
               let url = URL(string: tmdbURL),
               let _ = await ImageLoader.shared.loadImage(from: url) {
                return
            }
        }

        // Fallback: Plex transcoded image at the same dimensions PlexImage will request
        guard let baseURL = appState.activeServer?.baseURL else { return }
        let token = appState.serverToken
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        let scaledWidth = 1920 * 2
        let scaledHeight = Int(1920.0 / (16.0 / 9.0)) * 2
        guard let url = URL(string: "\(baseURL)/photo/:/transcode?width=\(scaledWidth)&height=\(scaledHeight)&minSize=1&upscale=1&url=\(encodedPath)&X-Plex-Token=\(token)") else { return }
        _ = await ImageLoader.shared.loadImage(from: url, token: token)
    }

    @ViewBuilder
    private func heroInfoView(for item: PlexMetadata) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Logo rendered from the pre-loaded UIImage — no PlexImage/AsyncImage
            // loading delay, so it appears simultaneously with the backdrop and color.
            if let logoImage = heroLogoImage {
                Image(uiImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 133)
            } else if heroLogoResolved {
                Text(item.displayTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                if let year = item.year {
                    Text(String(year))
                        .foregroundStyle(.white.opacity(0.9))
                }
                if let contentRating = item.contentRating {
                    Text(contentRating)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        )
                        .foregroundStyle(.white.opacity(0.9))
                }
                if let duration = item.durationFormatted {
                    Text(duration)
                        .foregroundStyle(.white.opacity(0.9))
                }
                if let rating = item.rating {
                    HStack(spacing: 6) {
                        Image("imdb-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        Text(String(format: "%.1f", rating))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
            }
            .font(.callout)

            if let summary = item.summary, !summary.isEmpty {
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            if let badge = heroAwardBadge {
                AwardBadgeView(badge: badge, contentYear: item.year)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: heroAwardBadge?.text)
            }
        }
    }

    private func showContextMenu(for item: PlexMetadata, isContinueWatching: Bool) {
        previewManager.stop()
        longPressItem = item
        longPressIsContinueWatching = isContinueWatching
        showLongPressOverlay = true
    }

    /// Captures the current hero data into `coordinator.heroTransition` so the
    /// detail view can display it immediately without a loading gap.
    private func captureHeroTransition(for item: PlexMetadata) {
        suppressedPreviewKey = item.ratingKey
        let logoSource: NavigationCoordinator.HeroTransition.LogoSource
        if let clearLogo = item.clearLogo, !clearLogo.isEmpty {
            logoSource = .plexClearLogo(clearLogo)
        } else if let cachedLogo = logoURLCache[item.ratingKey], !cachedLogo.isEmpty {
            logoSource = .tmdbURL(cachedLogo)
        } else if let url = heroLogoURL, !url.isEmpty {
            logoSource = .tmdbURL(url)
        } else {
            logoSource = .textOnly
        }
        // Detach the preview player if it's playing for this item; otherwise stop it
        // to prevent a leaked AVPlayer from continuing to play audio in the background.
        let previewPlayer: AVPlayer?
        if previewManager.isActive, displayedHero?.ratingKey == item.ratingKey {
            previewPlayer = previewManager.detachPlayer()
        } else {
            previewManager.stop()
            previewPlayer = nil
        }
        coordinator.heroTransition = NavigationCoordinator.HeroTransition(
            metadata: item,
            logoSource: logoSource,
            backgroundColor: colorCache[item.ratingKey] ?? heroGradientColor,
            previewPlayer: previewPlayer
        )
    }

    /// For episodes/seasons, fetch the parent show's metadata to get show-level IDs.
    /// Episodes carry the episode's own TMDB/IMDB IDs (or none), which don't work for
    /// logo lookups or award badge fetches — we need the show-level IDs.
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
}
