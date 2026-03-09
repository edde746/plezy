import SwiftUI
import WatchKit

/// Shows search results for a given query. Starts searching immediately on appear.
struct SearchResultsView: View {
    let query: String
    @State private var results: [MusicItem] = []
    @State private var isSearching = true
    @State private var errorMessage: String?
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        List {
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if isSearching {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            } else if results.isEmpty {
                Section {
                    Text("No results found")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            } else {
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
                            Button(action: { handleTrackTap(item) }) {
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
        .navigationTitle(query)
        .onAppear { performSearch() }
    }

    private func performSearch() {
        isSearching = true
        Task {
            let items = await PlexWatchClient.shared.search(query: query)
            await MainActor.run {
                results = items
                isSearching = false
            }
        }
    }

    private func handleTrackTap(_ item: MusicItem) {
        WKInterfaceDevice.current().play(.click)
        errorMessage = nil
        Task {
            let client = PlexWatchClient.shared
            let (radioResult, radioError) = await client.createRadioStation(ratingKey: item.ratingKey)
            guard let result = radioResult else {
                await MainActor.run { errorMessage = "Radio: \(radioError ?? "unknown error")" }
                WKInterfaceDevice.current().play(.failure)
                return
            }
            let queueItems = await result.toQueueItems(client: client)
            if queueItems.isEmpty {
                await MainActor.run { errorMessage = "No playable tracks" }
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

/// Sheet that immediately presents a text field for dictation/scribble input
struct SearchInputSheet: View {
    var onSubmit: (String) -> Void
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            TextField("Search", text: $text)
                .focused($isFocused)
                .onSubmit {
                    guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    dismiss()
                    onSubmit(text)
                }
        }
        .padding()
        .onAppear { isFocused = true }
    }
}
