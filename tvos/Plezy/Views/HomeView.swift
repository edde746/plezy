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

            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading content...")
                        .foregroundColor(.gray)
                        .padding(.top)
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
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Hero with Continue Watching overlay
                            ZStack(alignment: .bottom) {
                                // Hero Banner (fullscreen)
                                if !onDeck.isEmpty {
                                    HeroBanner(items: onDeck, currentIndex: $currentHeroIndex) { media in
                                        selectedMedia = media
                                    }
                                    .frame(height: geometry.size.height)
                                }

                                // Continue Watching overlaid at bottom
                                if !onDeck.isEmpty {
                                    ContinueWatchingShelf(items: onDeck) { media in
                                        selectedMedia = media
                                    }
                                    .padding(.bottom, 60)
                                }
                            }
                            .frame(height: geometry.size.height)

                            // Hubs section
                            VStack(alignment: .leading, spacing: 40) {
                                ForEach(hubs) { hub in
                                    if let items = hub.metadata, !items.isEmpty {
                                        MediaShelf(title: hub.title, items: items) { media in
                                            selectedMedia = media
                                        }
                                    } else {
                                        // Debug: Show why hub is not displaying
                                        let _ = print("🏠 [HomeView] Skipping hub '\(hub.title)' - has metadata: \(hub.metadata != nil), count: \(hub.metadata?.count ?? 0)")
                                    }
                                }
                            }
                            .padding(.top, 40)
                            .padding(.bottom, 40)
                            .background(Color.black)
                        }
                    }
                }
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
                .font(.system(size: 38, weight: .bold, design: .default))
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
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(isFocused ? 0.5 : 0.0), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.5), radius: isFocused ? 30 : 15, x: 0, y: isFocused ? 15 : 8)
                .scaleEffect(isFocused ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)

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

            ZStack {
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
                                    .font(.system(size: 72, weight: .heavy, design: .default))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: 500, maxHeight: 140, alignment: .leading)
                        } else {
                            Text(item.type == "episode" ? (item.grandparentTitle ?? item.title) : item.title)
                                .font(.system(size: 72, weight: .heavy, design: .default))
                                .foregroundColor(.white)
                                .lineLimit(2)
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
                            }
                        }

                        if let summary = item.summary {
                            Text(summary)
                                .font(.system(size: 24, weight: .regular, design: .default))
                                .foregroundColor(.white.opacity(0.85))
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

                // Navigation buttons
                HStack {
                    // Previous button
                    if currentIndex > 0 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentIndex -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 40)
                    }

                    Spacer()

                    // Next button
                    if currentIndex < heroItems.count - 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentIndex += 1
                            }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 40)
                    }
                }
                .padding(.bottom, 100)

                // Pagination dots
                HStack(spacing: 12) {
                    ForEach(0..<heroItems.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.orange : Color.white.opacity(0.5))
                            .frame(width: 12, height: 12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 30)
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
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(items) { item in
                        LandscapeMediaCard(media: item) {
                            onSelect(item)
                        }
                    }
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 20)
            }
        }
        .padding(.top, 30)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6), Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial.opacity(0.3))
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
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(isFocused ? 0.6 : 0.0), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.6), radius: isFocused ? 35 : 18, x: 0, y: isFocused ? 18 : 10)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)

                // Progress bar below card
                if media.progress > 0 && media.progress < 0.98 {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 500, height: 4)

                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 500 * media.progress, height: 4)
                    }
                    .cornerRadius(2)
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
