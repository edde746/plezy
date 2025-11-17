//
//  HomeView.swift
//  Beacon tvOS
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
                                focusNamespace: focusNamespace,
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
                            .focusSection()
                        }

                        // Continue Watching
                        if !onDeck.isEmpty {
                            ContinueWatchingShelf(items: onDeck) { media in
                                print("🎯 [HomeView] Continue Watching item tapped for: \(media.title)")
                                print("🎯 [HomeView] Setting playingMedia to trigger fullScreenCover")
                                playingMedia = media
                                print("🎯 [HomeView] playingMedia set to: \(String(describing: playingMedia?.title))")
                            }
                            .focusSection()
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
                                .focusSection()
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
                    // Move to next item with smooth transition (no limit on items)
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentHeroIndex = (currentHeroIndex + 1) % onDeck.count
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
        guard index >= 0 && index < onDeck.count else { return }
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

        // Check cache first - enriched data with logos is cached
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
                // Poster image with Liquid Glass container
                ZStack(alignment: .bottomLeading) {
                    CachedAsyncImage(url: posterURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(.regularMaterial.opacity(0.3))
                            .aspectRatio(2/3, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.tertiary)
                            )
                    }
                    .frame(width: 300, height: 450)
                    .clipped()

                    // Progress indicator with Liquid Glass styling
                    if media.progress > 0 && media.progress < 0.98 {
                        VStack(spacing: 0) {
                            Spacer()
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    Capsule()
                                        .fill(.regularMaterial)
                                        .opacity(0.4)

                                    // Progress fill with Beacon gradient
                                    Capsule()
                                        .fill(Color.beaconGradient)
                                        .frame(width: geometry.size.width * media.progress)
                                        .shadow(color: Color.beaconMagenta.opacity(0.5), radius: 4, x: 0, y: 0)
                                }
                            }
                            .frame(height: 5)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                        }
                    }

                    // Watched indicator with Liquid Glass
                    if media.isWatched {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    .padding(12)
                            }
                            Spacer()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: isFocused ? [.white.opacity(0.8), .white.opacity(0.4)] : [.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 4 : 0
                        )
                )
                .shadow(color: .black.opacity(isFocused ? 0.7 : 0.5), radius: isFocused ? 35 : 18, x: 0, y: isFocused ? 18 : 10)

                // Title with vibrancy
                Text(media.title)
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 300, alignment: .leading)
                    .padding(.top, 12)

                // Metadata
                if let year = media.year {
                    Text(String(year))
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .foregroundStyle(.secondary)
                        .frame(width: 300, alignment: .leading)
                        .padding(.top, 2)
                }
            }
        }
        .buttonStyle(MediaCardButtonStyle(isFocused: $isFocused))
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
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
    @FocusState private var isHeroFocused: Bool

    // Calculate visible dot range (max 5 dots at a time)
    private func getVisibleDotRange() -> (start: Int, end: Int) {
        let totalItems = items.count
        if totalItems <= 5 {
            return (0, totalItems - 1)
        }

        // Center the active dot in a 5-dot window
        let halfWindow = 2
        var start = currentIndex - halfWindow
        var end = currentIndex + halfWindow

        // Adjust if we're near the edges
        if start < 0 {
            start = 0
            end = 4
        } else if end >= totalItems {
            end = totalItems - 1
            start = totalItems - 5
        }

        return (start, end)
    }

    // Get dot size based on position (smaller dots at edges when windowing)
    private func getDotSize(for index: Int, range: (start: Int, end: Int)) -> CGFloat {
        let totalItems = items.count
        if totalItems <= 5 {
            return 8.0
        }

        // Make edge dots smaller if there are more items beyond
        if (index == range.start && range.start > 0) ||
           (index == range.end && range.end < totalItems - 1) {
            return 5.0
        }

        return 8.0
    }

    var body: some View {
        if currentIndex < items.count {
            let item = items[currentIndex]

            ZStack(alignment: .top) {
                // Background art with transition and swipe gesture support
                TabView(selection: $currentIndex) {
                    ForEach(0..<items.count, id: \.self) { index in
                        CachedAsyncImage(url: artURL(for: items[index])) { image in
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
                .onChange(of: currentIndex) { _, _ in
                    // Reset progress when manually navigating
                    progress = 0.0
                }

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

                    // Show logo or title (for both movies and TV shows)
                    if let clearLogo = item.clearLogo, let logoURL = logoURL(for: clearLogo) {
                        CachedAsyncImage(url: logoURL) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            Text(item.type == "episode" ? (item.grandparentTitle ?? item.title) : item.title)
                                .font(.system(size: 72, weight: .heavy, design: .default))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: 500, maxHeight: 140, alignment: .leading)
                        .id("\(item.id)-\(clearLogo)") // Force view recreation when item or logo changes
                    } else {
                        Text(item.type == "episode" ? (item.grandparentTitle ?? item.title) : item.title)
                            .font(.system(size: 72, weight: .heavy, design: .default))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .frame(maxWidth: 700, alignment: .leading)
                    }

                    // Metadata line (content type, rating, content rating, year)
                    HStack(spacing: 10) {
                        // Content type
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

                    // Synopsis with episode info inline (Apple TV style)
                    if let summary = item.summary {
                        if item.type == "episode", let parentIndex = item.parentIndex, let index = item.index {
                            // Episode: Show "S1, E2: description"
                            (Text("S\(parentIndex), E\(index): ")
                                .font(.system(size: 24, weight: .semibold, design: .default))
                                .foregroundColor(.white) +
                            Text(summary)
                                .font(.system(size: 24, weight: .regular, design: .default))
                                .foregroundColor(.white.opacity(0.85)))
                                .lineLimit(3)
                                .frame(maxWidth: 900, alignment: .leading)
                        } else {
                            // Movie: Just show description
                            Text(summary)
                                .font(.system(size: 24, weight: .regular, design: .default))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(3)
                                .frame(maxWidth: 900, alignment: .leading)
                        }
                    }

                    // Smart play button with progress indicator (macOS style)
                    HStack {
                        Button {
                            onSelect(item)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 20, weight: .semibold))

                                if item.progress > 0 && item.progress < 0.98 {
                                    // Show progress indicator with Beacon gradient
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 50, height: 6)

                                        Capsule()
                                            .fill(Color.beaconGradient)
                                            .frame(width: 50 * item.progress, height: 6)
                                            .shadow(color: Color.beaconMagenta.opacity(0.6), radius: 3, x: 0, y: 0)
                                    }

                                    if let duration = item.duration, let viewOffset = item.viewOffset {
                                        let minutesLeft = Int((Double(duration - viewOffset) / 60000.0).rounded())
                                        Text("\(minutesLeft) min left")
                                            .font(.system(size: 24, weight: .semibold))
                                    }
                                } else {
                                    Text("Play")
                                        .font(.system(size: 24, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.clearGlass)
                        .prefersDefaultFocus(in: focusNamespace)

                        Spacer()
                    }
                    .padding(.top, 10)

                }
                .padding(.horizontal, 80)
                .padding(.bottom, 120)
                .frame(height: 600, alignment: .bottom)

                // macOS-style pagination indicators at bottom
                HStack(spacing: 8) {
                    let range = getVisibleDotRange()
                    ForEach(range.start...range.end, id: \.self) { index in
                        let isActive = index == currentIndex
                        let dotSize = getDotSize(for: index, range: range)

                        if isActive {
                            // Animated horizontal expanding bar for active page (macOS style)
                            let maxWidth = dotSize * 3.0 // 24px for normal, 15px for small
                            let fillWidth = dotSize + ((maxWidth - dotSize) * progress)

                            ZStack(alignment: .leading) {
                                // Background capsule
                                Capsule()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: maxWidth, height: dotSize)

                                // Animated fill
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: fillWidth, height: dotSize)
                            }
                            .animation(.linear(duration: 0.05), value: progress)
                        } else {
                            // Static dot for inactive pages
                            Capsule()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize, height: dotSize)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 40)
            }
            .frame(height: 600)
            .scaleEffect(isHeroFocused ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isHeroFocused)
            .focusable(true)
            .focused($isHeroFocused)
            .onKeyPress(.leftArrow) {
                // Navigate to previous page
                if currentIndex > 0 {
                    onNavigate(currentIndex - 1)
                } else {
                    // Wrap around to last page
                    onNavigate(items.count - 1)
                }
                return .handled
            }
            .onKeyPress(.rightArrow) {
                // Navigate to next page
                if currentIndex < items.count - 1 {
                    onNavigate(currentIndex + 1)
                } else {
                    // Wrap around to first page
                    onNavigate(0)
                }
                return .handled
            }
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

    private func metadataComponents(for item: PlexMetadata) -> [String] {
        var components: [String] = []

        // Add rating with star
        if let rating = item.audienceRating {
            components.append("★ \(String(format: "%.1f", rating))")
        }

        // Add content rating
        if let contentRating = item.contentRating {
            components.append(contentRating)
        }

        // Add year
        if let year = item.year {
            components.append(String(year))
        }

        return components
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
                // Background art with Liquid Glass overlay
                ZStack(alignment: .bottomLeading) {
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
                    .frame(width: 500, height: 280)
                    .clipped()

                    // Enhanced gradient overlay with vibrancy
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.75)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Show logo in bottom left corner (for both TV shows and movies)
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        HStack {
                            if let logoURL = logoURL, let clearLogo = media.clearLogo {
                                CachedAsyncImage(url: logoURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    // Show title while logo loads
                                    Text(media.type == "episode" ? (media.grandparentTitle ?? media.title) : media.title)
                                        .font(.system(size: 28, weight: .bold, design: .default))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                                }
                                .frame(maxWidth: 200, maxHeight: 70)
                                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
                                .id("\(media.id)-\(clearLogo)") // Force view recreation when logo changes
                            } else {
                                // Show title when logo is not available
                                Text(media.type == "episode" ? (media.grandparentTitle ?? media.title) : media.title)
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                                    .frame(maxWidth: 200, alignment: .leading)
                            }
                            Spacer()
                        }
                        .padding(.leading, 24)
                        .padding(.bottom, 24)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: isFocused ? [.white.opacity(0.85), .white.opacity(0.5)] : [.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 4 : 0
                        )
                )
                .shadow(color: .black.opacity(isFocused ? 0.75 : 0.55), radius: isFocused ? 40 : 20, x: 0, y: isFocused ? 20 : 12)

                // Progress bar below card with enhanced Liquid Glass styling
                if media.progress > 0 && media.progress < 0.98 {
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(.regularMaterial)
                            .opacity(0.4)
                            .frame(width: 500, height: 5)

                        // Progress fill with Beacon gradient
                        Capsule()
                            .fill(Color.beaconGradient)
                            .frame(width: 500 * media.progress, height: 5)
                            .shadow(color: Color.beaconMagenta.opacity(0.5), radius: 4, x: 0, y: 0)
                    }
                    .padding(.top, 8)
                }

                // Episode info below card with vibrancy
                if media.type == "episode" {
                    Text(media.episodeInfo)
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundStyle(.primary)
                        .frame(width: 500, alignment: .leading)
                        .padding(.top, 12)
                } else {
                    // Title for movies
                    Text(media.title)
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(width: 500, alignment: .leading)
                        .padding(.top, 12)
                }
            }
        }
        .buttonStyle(MediaCardButtonStyle(isFocused: $isFocused))
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
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

    private var logoURL: URL? {
        guard let server = authService.selectedServer,
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
