//
//  HomeView.swift
//  Plezy tvOS
//
//  Home screen with featured content and continue watching
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: PlexAuthService
    @State private var onDeck: [PlexMetadata] = []
    @State private var hubs: [PlexHub] = []
    @State private var isLoading = true
    @State private var selectedMedia: PlexMetadata?
    @State private var showServerSelection = false
    @State private var noServerSelected = false
    @State private var currentHeroIndex = 0
    @State private var heroTimer: Timer?

    private let cache = CacheService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Welcome to Plezy")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)

                            if let serverName = authService.selectedServer?.name {
                                Text(serverName)
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()

                        // Refresh button
                        if !isLoading {
                            Button {
                                Task {
                                    await refreshContent()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 25)
                                .padding(.vertical, 15)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 40)

                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Loading content...")
                                .foregroundColor(.gray)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
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
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        // Hero Banner
                        if !onDeck.isEmpty {
                            HeroBanner(items: onDeck, currentIndex: $currentHeroIndex) { media in
                                selectedMedia = media
                            }
                        }

                        // Continue Watching
                        if !onDeck.isEmpty {
                            ContinueWatchingShelf(items: onDeck) { media in
                                selectedMedia = media
                            }
                        }

                        // Hubs
                        ForEach(hubs) { hub in
                            if let items = hub.metadata, !items.isEmpty {
                                MediaShelf(title: hub.title, items: items) { media in
                                    selectedMedia = media
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
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
            MediaDetailView(media: media)
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
        heroTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                if !onDeck.isEmpty {
                    currentHeroIndex = (currentHeroIndex + 1) % min(onDeck.count, 5)
                }
            }
        }
    }

    private func stopHeroTimer() {
        heroTimer?.invalidate()
        heroTimer = nil
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
        } catch {
            print("🔴 [HomeView] Error loading content: \(error)")
            print("🔴 [HomeView] Error details: \(error.localizedDescription)")
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 80)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(items) { item in
                        MediaCard(media: item) {
                            onSelect(item)
                        }
                    }
                }
                .padding(.horizontal, 80)
            }
        }
    }
}

struct MediaCard: View {
    let media: PlexMetadata
    let action: () -> Void
    @State private var isFocused = false
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Poster image
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: posterURL) { image in
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

                    // Progress indicator
                    if media.progress > 0 && media.progress < 0.98 {
                        VStack(spacing: 0) {
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * media.progress)
                            }
                            .frame(height: 6)
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
                .cornerRadius(10)
                .shadow(radius: isFocused ? 20 : 10)
                .scaleEffect(isFocused ? 1.05 : 1.0)

                // Title
                Text(media.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 300, alignment: .leading)
                    .padding(.top, 10)

                // Metadata
                if let year = media.year {
                    Text(String(year))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: 300, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
        .onFocusChange(true) { focused in
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = focused
            }
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
    let items: [PlexMetadata]
    @Binding var currentIndex: Int
    let onSelect: (PlexMetadata) -> Void
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        let heroItems = Array(items.prefix(5))

        if currentIndex < heroItems.count {
            let item = heroItems[currentIndex]

            Button {
                onSelect(item)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    // Background art
                    AsyncImage(url: artURL(for: item)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 600)
                    .clipped()

                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Content
                    VStack(alignment: .leading, spacing: 15) {
                        // Show logo or title
                        if item.type == "episode", let clearLogo = item.clearLogo, let logoURL = logoURL(for: clearLogo) {
                            AsyncImage(url: logoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                Text(item.grandparentTitle ?? item.title)
                                    .font(.system(size: 56, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: 500, maxHeight: 120, alignment: .leading)
                        } else {
                            Text(item.type == "episode" ? (item.grandparentTitle ?? item.title) : item.title)
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }

                        // Episode info for TV shows
                        if item.type == "episode" {
                            HStack(spacing: 10) {
                                Text(item.formatSeasonEpisode())
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text("·")
                                    .foregroundColor(.white.opacity(0.7))
                                Text(item.title)
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }

                        if let summary = item.summary {
                            Text(summary)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                        }

                        HStack(spacing: 20) {
                            Button {
                                onSelect(item)
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text(item.progress > 0 ? "Resume" : "Play")
                                }
                                .font(.title2)
                                .padding(.horizontal, 50)
                                .padding(.vertical, 15)
                            }
                            .buttonStyle(CardButtonStyle())
                        }

                        // Progress indicator
                        if item.progress > 0 && item.progress < 0.98 {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 4)

                                    Rectangle()
                                        .fill(Color.orange)
                                        .frame(width: geometry.size.width * item.progress, height: 4)
                                }
                            }
                            .frame(height: 4)
                            .frame(maxWidth: 800)
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.bottom, 60)
                }
            }
            .buttonStyle(.plain)
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 80)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(items) { item in
                        LandscapeMediaCard(media: item) {
                            onSelect(item)
                        }
                    }
                }
                .padding(.horizontal, 80)
            }
        }
    }
}

// MARK: - Landscape Media Card

struct LandscapeMediaCard: View {
    let media: PlexMetadata
    let action: () -> Void
    @State private var isFocused = false
    @EnvironmentObject var authService: PlexAuthService

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Background art
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: artURL) { image in
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

                    // Progress indicator
                    if media.progress > 0 && media.progress < 0.98 {
                        VStack {
                            Spacer()
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 6)

                                    Rectangle()
                                        .fill(Color.orange)
                                        .frame(width: geometry.size.width * media.progress, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }

                    // Play icon overlay (center)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(isFocused ? 1.0 : 0.7))

                    // Show logo in bottom left corner
                    if media.type == "episode" {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            HStack {
                                if let logoURL = showLogoURL {
                                    AsyncImage(url: logoURL) { image in
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
                .cornerRadius(10)
                .shadow(radius: isFocused ? 20 : 10)
                .scaleEffect(isFocused ? 1.05 : 1.0)

                // Episode info below card
                if media.type == "episode" {
                    Text(media.episodeInfo)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 500, alignment: .leading)
                        .padding(.top, 10)
                } else {
                    // Title for movies
                    Text(media.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(width: 500, alignment: .leading)
                        .padding(.top, 10)
                }
            }
        }
        .buttonStyle(.plain)
        .onFocusChange(true) { focused in
            withAnimation(.easeInOut(duration: 0.2)) {
                isFocused = focused
            }
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
