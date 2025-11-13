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
                        // Continue Watching
                        if !onDeck.isEmpty {
                            MediaShelf(title: "Continue Watching", items: onDeck) { media in
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
        .task {
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

    private func loadContent() async {
        guard let client = authService.currentClient else {
            isLoading = false
            noServerSelected = true
            return
        }

        isLoading = true
        noServerSelected = false

        async let onDeckTask = client.getOnDeck()
        async let hubsTask = client.getHubs()

        do {
            self.onDeck = try await onDeckTask
            self.hubs = try await hubsTask
        } catch {
            print("Error loading content: \(error)")
        }

        isLoading = false
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
                            .aspectRatio(2/3, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(2/3, contentMode: .fill)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 300, height: 450)
                    .clipped()

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
              let baseURL = connection.url,
              let thumb = media.thumb else {
            return nil
        }

        var urlString = baseURL.absoluteString + thumb
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
