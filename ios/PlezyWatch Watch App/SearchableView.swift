import SwiftUI
import WatchKit

/// Immediately presents the system text input (dictation/scribble) on appear,
/// then shows search results inline.
struct SearchableView: View {
    @State private var searchText = ""
    @State private var committedQuery = ""
    @State private var results: [MusicItem] = []
    @State private var isSearching = false
    @State private var hasAppeared = false
    @FocusState private var isInputFocused: Bool
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        List {
            // Search input field — auto-focuses to trigger system dictation
            Section {
                TextField("Search music…", text: $searchText)
                    .focused($isInputFocused)
                    .onSubmit {
                        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        committedQuery = trimmed
                        performSearch(trimmed)
                    }
            }

            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if !committedQuery.isEmpty && results.isEmpty {
                Text("No results for \"\(committedQuery)\"")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else if !results.isEmpty {
                let artists = results.filter { $0.isArtist }
                let albums = results.filter { $0.isAlbum }
                let tracks = results.filter { $0.isTrack }

                if !artists.isEmpty {
                    Section("Artists") {
                        ForEach(artists) { item in
                            NavigationLink(destination: ArtistDetailView(artist: item)) {
                                HStack(spacing: 10) {
                                    CachedThumbnailView(
                                        urlString: PlexWatchClient.shared.thumbnailUrl(item.thumb),
                                        size: 36
                                    )
                                    .clipShape(Circle())
                                    Text(item.title)
                                        .font(.body)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }

                if !albums.isEmpty {
                    Section("Albums") {
                        ForEach(albums) { item in
                            NavigationLink(destination: TrackListView(albumKey: item.ratingKey, albumTitle: item.title)) {
                                HStack(spacing: 10) {
                                    CachedThumbnailView(
                                        urlString: PlexWatchClient.shared.thumbnailUrl(item.thumb),
                                        size: 36
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.body)
                                            .lineLimit(1)
                                        if let artist = item.artist {
                                            Text(artist)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if !tracks.isEmpty {
                    Section("Songs") {
                        ForEach(tracks) { item in
                            Button(action: { playTrackRadio(item) }) {
                                HStack(spacing: 10) {
                                    CachedThumbnailView(
                                        urlString: PlexWatchClient.shared.thumbnailUrl(item.thumb),
                                        size: 36
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.body)
                                            .lineLimit(1)
                                        if let artist = item.artist {
                                            Text(artist)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search")
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                // Small delay lets the view finish layout before presenting input
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isInputFocused = true
                }
            }
        }
    }

    private func performSearch(_ query: String) {
        isSearching = true
        Task {
            let items = await PlexWatchClient.shared.search(query: query)
            await MainActor.run {
                results = items
                isSearching = false
            }
        }
    }

    private func playTrackRadio(_ item: MusicItem) {
        WKInterfaceDevice.current().play(.click)
        Task {
            let client = PlexWatchClient.shared
            let (radioResult, _) = await client.createRadioStation(ratingKey: item.ratingKey)
            guard let result = radioResult else {
                WKInterfaceDevice.current().play(.failure)
                return
            }
            let queueItems = await result.toQueueItems(client: client)
            guard !queueItems.isEmpty else {
                WKInterfaceDevice.current().play(.failure)
                return
            }
            let queueRef = result.toQueueReference(client: client)
            await MainActor.run {
                connectivity.startLocalPlayback()
                WatchAudioPlayer.shared.loadQueue(queueItems, queueRef: queueRef)
            }
            RecentlyPlayedManager.shared.record(
                ratingKey: item.ratingKey,
                title: item.title,
                type: .station,
                thumb: item.thumb
            )
        }
    }
}
