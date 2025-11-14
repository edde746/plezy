//
//  HomeView.swift
//  Plezy tvOS
//
//  Home screen with featured content and continue watching
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: PlexAuthService
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var onDeck: [PlexMetadata] = []
    @State private var hubs: [PlexHub] = []
    @State private var isLoading = true
    @State private var selectedMedia: PlexMetadata?
    @State private var playingMedia: PlexMetadata?
    @State private var showServerSelection = false
    @State private var noServerSelected = false
    @State private var errorMessage: String?
    @State private var currentHeroIndex = 0
    @State private var heroProgress: Double = 0.0
    @State private var heroTimer: Timer?
    @Namespace private var focusNamespace

    private let heroDisplayDuration: TimeInterval = 7.0 // 7 seconds per item
    private let heroTimerInterval: TimeInterval = 0.05 // 50ms updates for smooth progress

    private let cache = CacheService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                HomeViewSkeleton()
            } else if let error = errorMessage {
                VStack(spacing: 30) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 80))
                        .foregroundColor(.red)

                    Text("Error Loading Content")
                        .font(.title)
                        .foregroundColor(.white)

                    Text(error)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 100)

                    HStack(spacing: 20) {
                        Button {
                            print("🔄 [HomeView] Retry button tapped")
                            Task {
                                await loadContent()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.title3)
                        }
                        .buttonStyle(ClearGlassButtonStyle())
                    }
                }
            } else if noServerSelected {
                VStack(spacing: 30) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)

                    Text("No Server Selected")
                        .font(.title)
                        .foregroundColor(.white)

                    Text("Please select a Plex server to start watching")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button {
                        showServerSelection = true
                    } label: {
                        HStack {
                            Image(systemName: "server.rack")
                            Text("Select Server")
                        }
                        .font(.title2)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                    }
                    .buttonStyle(CardButtonStyle())
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        // Hero Banner
                        if !onDeck.isEmpty {
                            HeroBanner(
                                focusNamespace: _focusNamespace,
                                items: onDeck,
                                currentIndex: $currentHeroIndex,
                                progress: $heroProgress,
                                onNavigate: navigateHero
                            ) { media in
                                print("🎯 [HomeView] Hero play button tapped for: \(media.title)")
                                print("🎯 [HomeView] Setting playingMedia to trigger fullScreenCover")
                                playingMedia = media
                                print("🎯 [HomeView] playingMedia set to: \(String(describing: playingMedia?.title))")
                            }
                        }

                        // Continue Watching
                        if !onDeck.isEmpty {
                            ContinueWatchingShelf(items: onDeck) { media in
                                print("🎯 [HomeView] Continue Watching item tapped for: \(media.title)")
                                print("🎯 [HomeView] Setting playingMedia to trigger fullScreenCover")
                                playingMedia = media
                                print("🎯 [HomeView] playingMedia set to: \(String(describing: playingMedia?.title))")
                            }
                        }

                        // Hubs
                        ForEach(hubs) { hub in
                            if let items = hub.metadata, !items.isEmpty {
                                MediaShelf(title: hub.title, items: items) { media in
                                    print("🎯 [HomeView] Hub '\(hub.title)' item tapped for: \(media.title)")
                                    print("🎯 [HomeView] Setting selectedMedia to trigger sheet")
                                    selectedMedia = media
                                    print("🎯 [HomeView] selectedMedia set to: \(String(describing: selectedMedia?.title))")
                                }
                            } else {
                                // Debug: Show why hub is not displaying
                                let _ = print("🏠 [HomeView] Skipping hub '\(hub.title)' - has metadata: \(hub.metadata != nil), count: \(hub.metadata?.count ?? 0)")
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .focusScope(focusNamespace)
            }

            // Offline banner overlay
            VStack {
                OfflineBanner()
                Spacer()
            }
        }
        .onAppear {
            print("🏠 [HomeView] View appeared")
            startHeroTimer()
        }
        .onDisappear {
            stopHeroTimer()
        }
        .task {
            print("🏠 [HomeView] .task modifier triggered")
            await loadContent()
        }
        .sheet(item: $selectedMedia) { media in
            let _ = print("📱 [HomeView] Sheet presenting MediaDetailView for: \(media.title)")
            MediaDetailView(media: media)
                .environmentObject(authService)
                .onAppear {
                    print("📱 [HomeView] MediaDetailView appeared for: \(media.title)")
                }
        }
        .fullScreenCover(item: $playingMedia) { media in
            let _ = print("🎬 [HomeView] FullScreenCover presenting VideoPlayerView for: \(media.title)")
            VideoPlayerView(media: media)
                .environmentObject(authService)
                .onAppear {
                    print("🎬 [HomeView] VideoPlayerView appeared for: \(media.title)")
                }
        }
        .sheet(isPresented: $showServerSelection) {
            ServerSelectionView()
        }
        .onChange(of: authService.selectedServer) { _, newServer in
            if newServer != nil {
                Task {
                    await loadContent()
                }
            }
        }
    }

    private func startHeroTimer() {
        heroTimer = Timer.scheduledTimer(withTimeInterval: heroTimerInterval, repeats: true) { _ in
            if !onDeck.isEmpty {
                heroProgress += heroTimerInterval / heroDisplayDuration

                if heroProgress >= 1.0 {
                    // Move to next item with smooth transition
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentHeroIndex = (currentHeroIndex + 1) % min(onDeck.count, 5)
                    }
                    heroProgress = 0.0
                }
            }
        }
    }

    private func stopHeroTimer() {
        heroTimer?.invalidate()
        heroTimer = nil
    }

    private func resetHeroProgress() {
        heroProgress = 0.0
    }

    private func navigateHero(to index: Int) {
        guard index >= 0 && index < min(onDeck.count, 5) else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            currentHeroIndex = index
        }
        resetHeroProgress()
    }

    private func loadContent() async {
        print("🏠 [HomeView] loadContent called")
        print("🏠 [HomeView] currentClient exists: \(authService.currentClient != nil)")

        guard let client = authService.currentClient,
              let serverID = authService.selectedServer?.clientIdentifier else {
            print("🏠 [HomeView] No client available, showing no server selected")
            isLoading = false
            noServerSelected = true
            return
        }

        let cacheKey = CacheService.homeKey(serverID: serverID)

        // Check cache first
        if let cached: (onDeck: [PlexMetadata], hubs: [PlexHub]) = cache.get(cacheKey) {
            print("🏠 [HomeView] Using cached content")
            self.onDeck = cached.onDeck
            self.hubs = cached.hubs
            isLoading = false
            noServerSelected = false
            return
        }

        print("🏠 [HomeView] Client available, loading fresh content...")
        isLoading = true
        noServerSelected = false
        errorMessage = nil

        async let onDeckTask = client.getOnDeck()
        async let hubsTask = client.getHubs()

        do {
            print("🏠 [HomeView] Fetching on deck and hubs...")
            let fetchedOnDeck = try await onDeckTask
            let fetchedHubs = try await hubsTask

            self.onDeck = fetchedOnDeck
            self.hubs = fetchedHubs

            // Cache the results
            cache.set(cacheKey, value: (onDeck: fetchedOnDeck, hubs: fetchedHubs))

            print("🏠 [HomeView] Content loaded successfully. OnDeck: \(self.onDeck.count), Hubs: \(self.hubs.count)")
            errorMessage = nil
        } catch {
            print("🔴 [HomeView] Error loading content: \(error)")
            print("🔴 [HomeView] Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
        print("🏠 [HomeView] loadContent complete")
    }

    private func refreshContent() async {
        guard let serverID = authService.selectedServer?.clientIdentifier else {
            return
        }

        print("🔄 [HomeView] Refreshing content...")

        // Invalidate cache
        let cacheKey = CacheService.homeKey(serverID: serverID)
        cache.invalidate(cacheKey)

        // Reload content
        await loadContent()
    }
}

struct MediaShelf: View {
    let title: String
    let items: [PlexMetadata]
    let onSelect: (PlexMetadata) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 38, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding(.horizontal, 80)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(items) { item in
                        MediaCard(media: item) {
                            onSelect(item)
                        }
                        .padding(.vertical, 30) // Padding for focus scale
                    }
                }
                .padding(.horizontal, 80)
            }
            .clipped()
        }
    }
}

struct MediaCard: View {
    let media: PlexMetadata
    let action: () -> Void
    @FocusState private var isFocused: Bool
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster image
                ZStack(alignment: .bottomLeading) {
                    CachedAsyncImage(url: posterURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(2/3, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 300, height: 450)

                    // Progress indicator with Liquid Glass styling
                    if media.progress > 0 && media.progress < 0.98 {
                        VStack(spacing: 0) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.3)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.95)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * media.progress)
                                        .shadow(color: .white.opacity(0.3), radius: 1)
                                }
                            }
                            .frame(height: 4)
                        }
                    }

                    // Watched indicator
                    if media.isWatched {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                            .padding(15)
                    }
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                colors: isFocused ? [.white.opacity(0.6), .white.opacity(0.3)] : [.clear, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 3 : 0
                        )
                )
                .shadow(color: .black.opacity(isFocused ? 0.6 : 0.4), radius: isFocused ? 30 : 15, x: 0, y: isFocused ? 15 : 8)

                // Title
                Text(media.title)
                    .font(.system(size: 22, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 300, alignment: .leading)
                    .padding(.top, 10)

                // Metadata
                if let year = media.year {
                    Text(String(year))
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .foregroundColor(.gray)
                        .frame(width: 300, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .focusable()
        .scaleEffect(isFocused ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var label = media.title
        if let year = media.year {
            label += ", \(year)"
        }
        if media.type == "episode", let show = media.grandparentTitle {
            label = "\(show), \(media.title)"
            label += " \(media.formatSeasonEpisode())"
        }
        return label
    }

    private var accessibilityHint: String {
        if media.isWatched {
            return "Watched. Double tap to view details"
        } else if media.progress > 0 {
            let percent = Int(media.progress * 100)
            return "\(percent)% watched. Double tap to view details"
        } else {
            return "Double tap to view details"
        }
    }

    private var posterURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url else {
            return nil
        }

        // Use grandparentThumb for TV episodes (show poster), otherwise use thumb
        let imagePath: String?
        if media.type == "episode", let grandparentThumb = media.grandparentThumb {
            imagePath = grandparentThumb
        } else {
            imagePath = media.thumb
        }

        guard let thumb = imagePath else {
            return nil
        }

        var urlString = baseURL.absoluteString + thumb
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }
}

// MARK: - Hero Banner

struct HeroBanner: View {
    var focusNamespace: Namespace.ID
    let items: [PlexMetadata]
    @Binding var currentIndex: Int
    @Binding var progress: Double
    let onNavigate: (Int) -> Void
    let onSelect: (PlexMetadata) -> Void
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        let heroItems = Array(items.prefix(5))

        if currentIndex < heroItems.count {
            let item = heroItems[currentIndex]

            ZStack(alignment: .top) {
                // Background art with transition
                TabView(selection: $currentIndex) {
                    ForEach(0..<heroItems.count, id: \.self) { index in
                        CachedAsyncImage(url: artURL(for: heroItems[index])) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(height: 600)
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 600)
                .ignoresSafeArea()
                .focusEffectDisabled()

                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 600)

                // Content
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    // Show logo or title
                    if item.type == "episode", let clearLogo = item.clearLogo, let logoURL = logoURL(for: clearLogo) {
                        CachedAsyncImage(url: logoURL) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            Text(item.grandparentTitle ?? item.title)
                                .font(.system(size: 72, weight: .heavy, design: .default))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: 500, maxHeight: 140, alignment: .leading)
                    } else {
                        Text(item.type == "episode" ? (item.grandparentTitle ?? item.title) : item.title)
                            .font(.system(size: 72, weight: .heavy, design: .default))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .frame(maxWidth: 700, alignment: .leading)
                    }

                    // Episode info for TV shows
                    if item.type == "episode" {
                        HStack(spacing: 10) {
                            Text(item.formatSeasonEpisode())
                                .font(.system(size: 28, weight: .medium, design: .default))
                                .foregroundColor(.white)
                            Text("·")
                                .foregroundColor(.white.opacity(0.7))
                            Text(item.title)
                                .font(.system(size: 28, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }

                    // Synopsis with maxWidth
                    if let summary = item.summary {
                        Text(summary)
                            .font(.system(size: 24, weight: .regular, design: .default))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(3)
                            .frame(maxWidth: 900, alignment: .leading)
                    }

                    // Pill-shaped play button with clear Liquid Glass (fixed position)
                    HStack {
                        Button {
                            onSelect(item)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                Text(item.progress > 0 ? "Resume" : "Play")
                                    .font(.system(size: 24, weight: .semibold))
                            }
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.clearGlass)
                        .prefersDefaultFocus(in: focusNamespace)

                        Spacer()
                    }
                    .padding(.top, 10)

                    // Watch progress indicator with Liquid Glass (for media in progress)
                    if item.progress > 0 && item.progress < 0.98 {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .opacity(0.3)
                                .frame(height: 4)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.95)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 800 * item.progress, height: 4)
                                .shadow(color: .white.opacity(0.4), radius: 2)
                        }
                        .frame(width: 800)
                        .padding(.top, 5)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 120)
                .frame(height: 600, alignment: .bottom)

                // Pagination dots at bottom with expanding countdown
                HStack(spacing: 12) {
                    ForEach(0..<heroItems.count, id: \.self) { index in
                        ZStack {
                            // Background dot
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)

                            // Expanding progress ring for current item
                            if index == currentIndex {
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(
                                        Color.white,
                                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                    )
                                    .frame(width: 14, height: 14)
                                    .rotationEffect(.degrees(-90))
                                    .shadow(color: .white.opacity(0.5), radius: 2)
                            }

                            // Filled dot for completed items
                            if index < currentIndex {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 40)
            }
            .frame(height: 600)
        }
    }

    private func artURL(for media: PlexMetadata) -> URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let art = media.art else {
            return nil
        }

        var urlString = baseURL.absoluteString + art
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }

    private func logoURL(for clearLogo: String) -> URL? {
        // clearLogo already includes the full URL from the Image array
        if clearLogo.starts(with: "http") {
            return URL(string: clearLogo)
        }

        // Fallback to building URL if it's a relative path
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url else {
            return nil
        }

        var urlString = baseURL.absoluteString + clearLogo
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }
}

// MARK: - Continue Watching Shelf

struct ContinueWatchingShelf: View {
    let items: [PlexMetadata]
    let onSelect: (PlexMetadata) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Continue Watching")
                .font(.system(size: 38, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding(.horizontal, 80)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(items) { item in
                        LandscapeMediaCard(media: item) {
                            onSelect(item)
                        }
                        .padding(.vertical, 40) // Padding for focus scale
                    }
                }
                .padding(.horizontal, 80)
            }
            .clipped()
        }
    }
}

// MARK: - Landscape Media Card

struct LandscapeMediaCard: View {
    let media: PlexMetadata
    let action: () -> Void
    @FocusState private var isFocused: Bool
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Background art
                ZStack(alignment: .bottomLeading) {
                    CachedAsyncImage(url: artURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 500, height: 280)
                    .clipped()

                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Show logo in bottom left corner
                    if media.type == "episode" {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            HStack {
                                if let logoURL = showLogoURL {
                                    CachedAsyncImage(url: logoURL) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    } placeholder: {
                                        EmptyView()
                                    }
                                    .frame(maxWidth: 180, maxHeight: 60)
                                }
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                colors: isFocused ? [.white.opacity(0.7), .white.opacity(0.4)] : [.clear, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 3 : 0
                        )
                )
                .shadow(color: .black.opacity(isFocused ? 0.7 : 0.5), radius: isFocused ? 35 : 18, x: 0, y: isFocused ? 18 : 10)

                // Progress bar below card with Liquid Glass styling
                if media.progress > 0 && media.progress < 0.98 {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)
                            .frame(width: 500, height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 500 * media.progress, height: 4)
                            .shadow(color: .white.opacity(0.3), radius: 1)
                    }
                }

                // Episode info below card
                if media.type == "episode" {
                    Text(media.episodeInfo)
                        .font(.system(size: 24, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 500, alignment: .leading)
                        .padding(.top, 10)
                } else {
                    // Title for movies
                    Text(media.title)
                        .font(.system(size: 24, weight: .medium, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(width: 500, alignment: .leading)
                        .padding(.top, 10)
                }
            }
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .focusable()
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("In progress. Double tap to continue watching")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        if media.type == "episode", let show = media.grandparentTitle {
            var label = "\(show), \(media.title)"
            label += " \(media.formatSeasonEpisode())"
            if media.progress > 0 {
                let percent = Int(media.progress * 100)
                label += ", \(percent)% watched"
            }
            return label
        } else {
            var label = media.title
            if media.progress > 0 {
                let percent = Int(media.progress * 100)
                label += ", \(percent)% watched"
            }
            return label
        }
    }

    private var artURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let art = media.art else {
            return nil
        }

        var urlString = baseURL.absoluteString + art
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }

    private var showLogoURL: URL? {
        guard media.type == "episode",
              let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let clearLogo = media.clearLogo else {
            return nil
        }

        // clearLogo already includes the full URL from the Image array
        if clearLogo.starts(with: "http") {
            return URL(string: clearLogo)
        }

        // Fallback to building URL if it's a relative path
        var urlString = baseURL.absoluteString + clearLogo
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }
}

#Preview {
    HomeView()
        .environmentObject(PlexAuthService())
        .environmentObject(SettingsService())
}
