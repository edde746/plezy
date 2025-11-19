//
//  HomeView.swift
//  Beacon tvOS
//
//  Home screen with full-screen hero background and overlaid content
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: PlexAuthService
    @EnvironmentObject var tabCoordinator: TabCoordinator
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var onDeck: [PlexMetadata] = []
    @State private var recentlyAdded: [PlexMetadata] = []
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
    @State private var scrollOffset: CGFloat = 0
    @State private var shouldShowHero = true
    @Namespace private var focusNamespace

    private let heroDisplayDuration: TimeInterval = 7.0
    private let heroTimerInterval: TimeInterval = 0.05

    private let cache = CacheService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                HomeViewSkeleton()
            } else if let error = errorMessage {
                errorView(error: error)
            } else if noServerSelected {
                noServerView
            } else {
                fullScreenHeroLayout
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

    // MARK: - Full-Screen Hero Layout

    private var fullScreenHeroLayout: some View {
        ZStack {
            // Layer 1: Full-screen hero background (recently added)
            if !recentlyAdded.isEmpty && shouldShowHero {
                FullScreenHeroBackground(
                    items: recentlyAdded,
                    currentIndex: $currentHeroIndex
                )
            }

            // Layer 2: Hero overlay with metadata (recently added)
            if !recentlyAdded.isEmpty && shouldShowHero {
                VStack {
                    Spacer()

                    FullScreenHeroOverlay(
                        item: recentlyAdded[currentHeroIndex]
                    )
                    .padding(.bottom, 450)
                }
            }

            // Layer 3: Scrollable content area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Spacer to push content down - make it fill the screen
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 700)

                    // Continue Watching section
                    if !onDeck.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Continue Watching")
                                .font(.system(size: 40, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .padding(.horizontal, 90)
                                .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)

                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 30) {
                                    ForEach(onDeck) { item in
                                        ContinueWatchingCard(media: item) {
                                            print("🎯 [HomeView] Continue watching item tapped: \(item.title)")
                                            playingMedia = item
                                        }
                                    }
                                }
                                .padding(.horizontal, 90)
                            }
                        }
                        .padding(.bottom, 60)
                    }

                    // Other hub rows
                    ForEach(hubs.filter { !$0.title.lowercased().contains("recently added") && !$0.title.lowercased().contains("on deck") }) { hub in
                        if let items = hub.metadata, !items.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                Text(hub.title)
                                    .font(.system(size: 40, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 90)
                                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 30) {
                                        ForEach(items) { item in
                                            ContinueWatchingCard(media: item) {
                                                print("🎯 [HomeView] Hub item tapped: \(item.title)")
                                                selectedMedia = item
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 90)
                                }
                            }
                            .focusSection()
                            .padding(.bottom, 60)
                        }
                    }

                    // Bottom padding - add extra space to allow scrolling past Continue Watching
                    Color.clear.frame(height: 600)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
                // Hide hero when scrolled past the spacer (approximately when Continue Watching becomes visible)
                withAnimation(.easeInOut(duration: 0.3)) {
                    shouldShowHero = value > -480
                }
            }
        }
        .ignoresSafeArea()
        .focusScope(focusNamespace)
    }

    // MARK: - Error & No Server Views

    private func errorView(error: String) -> some View {
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
    }

    private var noServerView: some View {
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
    }

    // MARK: - Hero Timer Management

    private func startHeroTimer() {
        heroTimer = Timer.scheduledTimer(withTimeInterval: heroTimerInterval, repeats: true) { _ in
            if !recentlyAdded.isEmpty {
                heroProgress += heroTimerInterval / heroDisplayDuration

                if heroProgress >= 1.0 {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentHeroIndex = (currentHeroIndex + 1) % recentlyAdded.count
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
        guard index >= 0 && index < recentlyAdded.count else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            currentHeroIndex = index
        }
        resetHeroProgress()
    }

    // MARK: - Content Loading

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

            // Extract recently added from hubs
            if let recentlyAddedHub = cached.hubs.first(where: { $0.title.lowercased().contains("recently added") || $0.title.lowercased().contains("recent") }),
               let items = recentlyAddedHub.metadata {
                self.recentlyAdded = items
            }

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

            // Extract recently added from hubs
            if let recentlyAddedHub = fetchedHubs.first(where: { $0.title.lowercased().contains("recently added") || $0.title.lowercased().contains("recent") }),
               let items = recentlyAddedHub.metadata {
                self.recentlyAdded = items
                print("🏠 [HomeView] Recently Added items: \(items.count)")
            }

            // Cache the results
            cache.set(cacheKey, value: (onDeck: fetchedOnDeck, hubs: fetchedHubs))

            print("🏠 [HomeView] Content loaded successfully. OnDeck: \(self.onDeck.count), Hubs: \(self.hubs.count), RecentlyAdded: \(self.recentlyAdded.count)")
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

// MARK: - Full-Screen Hero Background

struct FullScreenHeroBackground: View {
    let items: [PlexMetadata]
    @Binding var currentIndex: Int
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sliding background images
                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        CachedAsyncImage(url: artURL(for: item)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    }
                }
                .offset(x: -CGFloat(currentIndex) * geometry.size.width)
                .animation(.easeInOut(duration: 0.6), value: currentIndex)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
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
}

// MARK: - Full-Screen Hero Overlay

struct FullScreenHeroOverlay: View {
    let item: PlexMetadata
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Show logo or title in fixed-height container
            VStack(alignment: .leading) {
                if let clearLogo = item.clearLogo, let logoURL = logoURL(for: clearLogo) {
                    CachedAsyncImage(url: logoURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Text(item.type == "episode" ? (item.grandparentTitle ?? item.title) : item.title)
                            .font(.system(size: 76, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 4)
                    }
                    .frame(maxWidth: 600, maxHeight: 180, alignment: .leading)
                    .id("\(item.id)-\(clearLogo)") // Force refresh when item changes
                } else {
                    Text(item.type == "episode" ? (item.grandparentTitle ?? item.title) : item.title)
                        .font(.system(size: 76, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 4)
                        .frame(maxWidth: 900, alignment: .leading)
                }
            }
            .frame(height: 180, alignment: .leading) // Fixed height for logo

            // Metadata line
            HStack(spacing: 10) {
                Text(item.type == "movie" ? "Movie" : "TV Show")
                    .font(.system(size: 24, weight: .medium, design: .default))
                    .foregroundColor(.white)

                if item.audienceRating != nil || item.contentRating != nil || item.year != nil {
                    ForEach(metadataComponents(for: item), id: \.self) { component in
                        Text("·")
                            .foregroundColor(.white.opacity(0.7))
                        Text(component)
                            .font(.system(size: 24, weight: .medium, design: .default))
                            .foregroundColor(.white)
                    }
                }
            }

            // Description
            if let summary = item.summary {
                if item.type == "episode", let parentIndex = item.parentIndex, let index = item.index {
                    (Text("S\(parentIndex), E\(index): ")
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(.white) +
                    Text(summary)
                        .font(.system(size: 28, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.9)))
                        .lineLimit(3)
                        .frame(maxWidth: 1000, alignment: .leading)
                        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 2)
                } else {
                    Text(summary)
                        .font(.system(size: 28, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                        .frame(maxWidth: 1000, alignment: .leading)
                        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 2)
                }
            }

        }
        .padding(.horizontal, 90)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func logoURL(for clearLogo: String) -> URL? {
        if clearLogo.starts(with: "http") {
            return URL(string: clearLogo)
        }

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

    private func metadataComponents(for item: PlexMetadata) -> [String] {
        var components: [String] = []

        if let rating = item.audienceRating {
            components.append("★ \(String(format: "%.1f", rating))")
        }

        if let contentRating = item.contentRating {
            components.append(contentRating)
        }

        if let year = item.year {
            components.append(String(year))
        }

        return components
    }
}

// MARK: - Top Navigation Menu

struct TopNavigationMenu: View {
    @EnvironmentObject var tabCoordinator: TabCoordinator

    var body: some View {
        HStack(spacing: 40) {
            ForEach(TabSelection.allCases, id: \.self) { tab in
                TopMenuItem(
                    tab: tab,
                    isSelected: tabCoordinator.selectedTab == tab,
                    action: {
                        tabCoordinator.select(tab)
                    }
                )
            }

            Spacer()
        }
        .padding(.horizontal, 90)
        .padding(.vertical, 20)
    }
}

struct TopMenuItem: View {
    let tab: TabSelection
    let isSelected: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(tab.rawValue)
                    .font(.system(size: 28, weight: isSelected ? .bold : .semibold, design: .default))
                    .foregroundColor(.white)

                if isSelected {
                    Capsule()
                        .fill(Color.beaconGradient)
                        .frame(height: 4)
                        .shadow(color: Color.beaconPurple.opacity(0.8), radius: 8, x: 0, y: 0)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(height: 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .shadow(
            color: isFocused ? Color.white.opacity(0.5) : Color.clear,
            radius: isFocused ? 20 : 0,
            x: 0,
            y: 0
        )
    }
}

// MARK: - Continue Watching Card Component

struct ContinueWatchingCard: View {
    let media: PlexMetadata
    let action: () -> Void
    @EnvironmentObject var authService: PlexAuthService
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Entire card wrapped in a single ZStack with consistent clipping
                ZStack(alignment: .bottomLeading) {
                    // Background image
                    CachedAsyncImage(url: artURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(.regularMaterial.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 56))
                                    .foregroundStyle(.tertiary)
                            )
                    }
                    .frame(width: 410, height: 231)

                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Logo/Title overlay
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        HStack {
                            if let logoURL = logoURL, let clearLogo = media.clearLogo {
                                CachedAsyncImage(url: logoURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    Text(media.type == "episode" ? (media.grandparentTitle ?? media.title) : media.title)
                                        .font(.system(size: 22, weight: .bold, design: .default))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                                }
                                .frame(maxWidth: 180, maxHeight: 60)
                                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
                                .id("\(media.id)-\(clearLogo)")
                            } else {
                                Text(media.type == "episode" ? (media.grandparentTitle ?? media.title) : media.title)
                                    .font(.system(size: 22, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                                    .frame(maxWidth: 180, alignment: .leading)
                            }
                            Spacer()
                        }
                        .padding(.leading, 20)
                        .padding(.bottom, 20)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge, style: .continuous))
                .shadow(
                    color: .black.opacity(isFocused ? 0.5 : 0.3),
                    radius: isFocused ? 25 : 12,
                    x: 0,
                    y: isFocused ? 12 : 6
                )
                .scaleEffect(isFocused ? 1.08 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)

                // Progress bar below card (outside the clipped ZStack)
                if media.progress > 0 && media.progress < 0.98 {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.regularMaterial)
                            .opacity(0.4)
                            .frame(width: 410, height: 5)

                        Capsule()
                            .fill(Color.beaconGradient)
                            .frame(width: 410 * media.progress, height: 5)
                            .shadow(color: Color.beaconMagenta.opacity(0.6), radius: 4, x: 0, y: 0)
                    }
                    .padding(.top, isFocused ? 18 : 8)
                }

                // Label below card with episode info or title
                if media.type == "episode" {
                    Text(media.episodeInfo)
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 410, alignment: .leading)
                        .padding(.top, media.progress > 0 && media.progress < 0.98 ? 12 : (isFocused ? 22 : 12))
                } else {
                    Text(media.title)
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(width: 410, alignment: .leading)
                        .padding(.top, media.progress > 0 && media.progress < 0.98 ? 12 : (isFocused ? 22 : 12))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand {
            action()
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

    private var logoURL: URL? {
        guard let server = authService.selectedServer,
              let connection = server.connections.first,
              let baseURL = connection.url,
              let clearLogo = media.clearLogo else {
            return nil
        }

        if clearLogo.starts(with: "http") {
            return URL(string: clearLogo)
        }

        var urlString = baseURL.absoluteString + clearLogo
        if let token = server.accessToken {
            urlString += "?X-Plex-Token=\(token)"
        }

        return URL(string: urlString)
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    HomeView()
        .environmentObject(PlexAuthService())
        .environmentObject(SettingsService())
}
