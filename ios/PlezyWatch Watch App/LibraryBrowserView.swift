import SwiftUI
import WatchKit

// MARK: - Library Home (Apple Music-style categories)

struct LibraryBrowserView: View {
    @State private var libraries: [LibrarySection] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if libraries.isEmpty {
                ContentUnavailableView("No Music Libraries", systemImage: "music.note.house")
            } else if libraries.count == 1 {
                // Single library: go straight to categories
                LibraryCategoryView(sectionId: libraries[0].key, libraryTitle: libraries[0].title)
            } else {
                List(libraries) { library in
                    NavigationLink(destination: LibraryCategoryView(sectionId: library.key, libraryTitle: library.title)) {
                        Label(library.title, systemImage: "music.note.list")
                    }
                }
                .navigationTitle("Libraries")
            }
        }
        .task {
            libraries = await PlexWatchClient.shared.getMusicLibraries()
            isLoading = false
        }
    }
}

struct LibraryCategoryView: View {
    let sectionId: String
    let libraryTitle: String

    var body: some View {
        List {
            NavigationLink(destination: ArtistListView(sectionId: sectionId)) {
                Label("Artists", systemImage: "music.mic")
            }
            NavigationLink(destination: AlbumGridView(sectionId: sectionId)) {
                Label("Albums", systemImage: "square.stack")
            }
            NavigationLink(destination: PlaylistListView()) {
                Label("Playlists", systemImage: "music.note.list")
            }
        }
        .navigationTitle(libraryTitle)
    }
}

// MARK: - Artist List (alphabetical sections)

struct ArtistListView: View {
    let sectionId: String
    @State private var artists: [MusicItem] = []
    @State private var isLoading = true

    private var groupedArtists: [(String, [MusicItem])] {
        let grouped = Dictionary(grouping: artists) { item -> String in
            let first = item.title.folding(options: .diacriticInsensitive, locale: .current)
                .prefix(1).uppercased()
            if first.isEmpty { return "#" }
            return first.first?.isLetter == true ? String(first) : "#"
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if artists.isEmpty {
                ContentUnavailableView("No Artists", systemImage: "music.mic")
            } else {
                List {
                    ForEach(groupedArtists, id: \.0) { letter, items in
                        Section(header: Text(letter)) {
                            ForEach(items) { artist in
                                NavigationLink(destination: ArtistDetailView(artist: artist)) {
                                    HStack(spacing: 10) {
                                        CachedThumbnailView(
                                            urlString: PlexWatchClient.shared.thumbnailUrl(artist.thumb),
                                            size: 40
                                        )
                                        .clipShape(Circle())
                                        Text(artist.title)
                                            .font(.body)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Artists")
        .task {
            artists = await PlexWatchClient.shared.getArtists(sectionId: sectionId)
            isLoading = false
        }
    }
}

// MARK: - Artist Detail (albums + actions)

struct ArtistDetailView: View {
    let artist: MusicItem
    @State private var albums: [MusicItem] = []
    @State private var isLoading = true
    @State private var isActioning = false
    @State private var errorMessage: String?
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                List {
                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        Button(action: { playAll(shuffle: false) }) {
                            if isActioning {
                                ProgressView()
                            } else {
                                Label("Play All", systemImage: "play.fill")
                            }
                        }
                        .disabled(isActioning)
                        Button(action: { playAll(shuffle: true) }) {
                            Label("Shuffle All", systemImage: "shuffle")
                        }
                        .disabled(isActioning)
                        Button(action: { startRadio() }) {
                            Label("Artist Radio", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .disabled(isActioning)
                    }

                    Section("Albums") {
                        ForEach(albums) { album in
                            NavigationLink(destination: TrackListView(albumKey: album.ratingKey, albumTitle: album.title)) {
                                HStack(spacing: 10) {
                                    CachedThumbnailView(
                                        urlString: PlexWatchClient.shared.thumbnailUrl(album.thumb),
                                        size: 44
                                    )
                                    Text(album.title)
                                        .font(.body)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(artist.title)
        .task {
            albums = await PlexWatchClient.shared.getAlbums(ratingKey: artist.ratingKey)
            isLoading = false
        }
    }

    private func playAll(shuffle: Bool) {
        WKInterfaceDevice.current().play(.click)
        isActioning = true
        errorMessage = nil
        Task {
            guard PlexWatchClient.shared.hasCredentials else {
                await MainActor.run { errorMessage = "No server credentials"; isActioning = false }
                return
            }

            guard let result = await PlexWatchClient.shared.createPlayAllQueue(ratingKey: artist.ratingKey) else {
                await MainActor.run { errorMessage = "Failed to create play queue"; isActioning = false }
                WKInterfaceDevice.current().play(.failure)
                return
            }

            let client = PlexWatchClient.shared
            let queueItems = await result.toQueueItems(client: client)
            rlog("[PlexWatch] Play all: \(result.items.count) items from API, \(queueItems.count) playable")

            if queueItems.isEmpty {
                for item in result.items {
                    rlog("[PlexWatch] Item '\(item.title)' partKey=\(item.partKey ?? "nil") type=\(item.type)")
                }
                await MainActor.run { errorMessage = "No playable tracks found (\(result.items.count) items had no stream info)"; isActioning = false }
                WKInterfaceDevice.current().play(.failure)
                return
            }

            await MainActor.run {
                connectivity.startLocalPlayback()
                WatchAudioPlayer.shared.loadQueue(queueItems)
                if shuffle { WatchAudioPlayer.shared.toggleShuffle() }
                isActioning = false
            }
            RecentlyPlayedManager.shared.record(
                ratingKey: artist.ratingKey,
                title: artist.title,
                type: .artist,
                thumb: albums.first?.thumb ?? artist.thumb
            )
        }
    }

    private func startRadio() {
        WKInterfaceDevice.current().play(.click)
        isActioning = true
        errorMessage = nil
        Task {
            let client = PlexWatchClient.shared
            let (radioResult, radioError) = await client.createRadioStation(ratingKey: artist.ratingKey)
            guard let result = radioResult else {
                await MainActor.run { errorMessage = "Radio failed: \(radioError ?? "unknown")"; isActioning = false }
                WKInterfaceDevice.current().play(.failure)
                return
            }

            let apiCount = result.items.count
            let withPartKey = result.items.filter { $0.partKey != nil }.count
            let queueItems = await result.toQueueItems(client: client)
            let detail = "api:\(apiCount) pk:\(withPartKey) playable:\(queueItems.count)"
            rlog("[PlexWatch] Radio: \(detail)")

            if queueItems.isEmpty {
                let sample = result.items.prefix(2).map { "\($0.ratingKey):\($0.type)" }.joined(separator: ",")
                await MainActor.run { errorMessage = "No playable tracks (\(detail) [\(sample)])"; isActioning = false }
                WKInterfaceDevice.current().play(.failure)
                return
            }

            let queueRef = result.toQueueReference(client: client)
            await MainActor.run {
                connectivity.startLocalPlayback()
                WatchAudioPlayer.shared.loadQueue(queueItems, queueRef: queueRef)
                isActioning = false
            }
            RecentlyPlayedManager.shared.record(
                ratingKey: artist.ratingKey,
                title: artist.title,
                type: .station,
                thumb: albums.first?.thumb ?? artist.thumb
            )
        }
    }
}

// MARK: - Album Grid (alphabetical sections)

struct AlbumGridView: View {
    let sectionId: String
    @State private var albums: [MusicItem] = []
    @State private var isLoading = true

    private var groupedAlbums: [(String, [MusicItem])] {
        let grouped = Dictionary(grouping: albums) { item -> String in
            let first = item.title.folding(options: .diacriticInsensitive, locale: .current)
                .prefix(1).uppercased()
            if first.isEmpty { return "#" }
            return first.first?.isLetter == true ? String(first) : "#"
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if albums.isEmpty {
                ContentUnavailableView("No Albums", systemImage: "square.stack")
            } else {
                List {
                    ForEach(groupedAlbums, id: \.0) { letter, items in
                        Section(header: Text(letter)) {
                            ForEach(items) { album in
                                NavigationLink(destination: TrackListView(albumKey: album.ratingKey, albumTitle: album.title)) {
                                    HStack(spacing: 10) {
                                        CachedThumbnailView(
                                            urlString: PlexWatchClient.shared.thumbnailUrl(album.thumb),
                                            size: 44
                                        )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(album.title)
                                                .font(.body)
                                                .lineLimit(2)
                                            if let artist = album.artist {
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
                }
            }
        }
        .navigationTitle("Albums")
        .task {
            albums = await PlexWatchClient.shared.getAllAlbums(sectionId: sectionId)
            isLoading = false
        }
    }
}

// MARK: - Playlist List

struct PlaylistListView: View {
    @State private var playlists: [MusicItem] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if playlists.isEmpty {
                ContentUnavailableView("No Playlists", systemImage: "music.note.list")
            } else {
                List(playlists) { playlist in
                    NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                        HStack(spacing: 10) {
                            CachedThumbnailView(
                                urlString: PlexWatchClient.shared.thumbnailUrl(playlist.thumb),
                                size: 44
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(playlist.title)
                                    .font(.body)
                                    .lineLimit(2)
                                if let sub = playlist.artist {
                                    Text(sub)
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
        .navigationTitle("Playlists")
        .task {
            playlists = await PlexWatchClient.shared.getPlaylists()
            isLoading = false
        }
    }
}

// MARK: - Playlist Detail

struct PlaylistDetailView: View {
    let playlist: MusicItem
    @State private var tracks: [MusicItem] = []
    @State private var isLoading = true
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                List {
                    Section {
                        Button(action: { playPlaylist(shuffle: false) }) {
                            Label("Play", systemImage: "play.fill")
                        }
                        Button(action: { playPlaylist(shuffle: true) }) {
                            Label("Shuffle", systemImage: "shuffle")
                        }
                    }

                    Section {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            Button(action: { playFrom(index: index) }) {
                                HStack(spacing: 10) {
                                    CachedThumbnailView(
                                        urlString: PlexWatchClient.shared.thumbnailUrl(track.thumb),
                                        size: 36
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title)
                                            .font(.body)
                                            .lineLimit(1)
                                        if let artist = track.artist {
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
        .navigationTitle(playlist.title)
        .task {
            tracks = await PlexWatchClient.shared.getPlaylistItems(ratingKey: playlist.ratingKey)
            isLoading = false
        }
    }

    private func playPlaylist(shuffle: Bool) {
        WKInterfaceDevice.current().play(.click)
        Task {
            if let result = await PlexWatchClient.shared.createPlaylistQueue(ratingKey: playlist.ratingKey, shuffle: shuffle) {
                let client = PlexWatchClient.shared
                let queueItems = await result.toQueueItems(client: client)
                if !queueItems.isEmpty {
                    await MainActor.run {
                        connectivity.startLocalPlayback()
                        WatchAudioPlayer.shared.loadQueue(queueItems)
                    }
                    RecentlyPlayedManager.shared.record(
                        ratingKey: playlist.ratingKey,
                        title: playlist.title,
                        type: .album,
                        thumb: playlist.thumb
                    )
                }
            }
        }
    }

    private func playFrom(index: Int) {
        WKInterfaceDevice.current().play(.click)
        Task {
            if let result = await PlexWatchClient.shared.createPlaylistQueue(ratingKey: playlist.ratingKey) {
                let client = PlexWatchClient.shared
                let queueItems = await result.toQueueItems(client: client)
                if !queueItems.isEmpty {
                    await MainActor.run {
                        connectivity.startLocalPlayback()
                        WatchAudioPlayer.shared.loadQueue(queueItems, startIndex: min(index, queueItems.count - 1))
                    }
                }
            }
        }
    }
}

// MARK: - Track List (album detail)

struct TrackListView: View {
    let albumKey: String
    let albumTitle: String
    @State private var tracks: [MusicItem] = []
    @State private var isLoading = true
    @State private var isActioning = false
    @State private var errorMessage: String?
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                List {
                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        Button(action: { playAlbum(shuffle: false) }) {
                            if isActioning {
                                ProgressView()
                            } else {
                                Label("Play", systemImage: "play.fill")
                            }
                        }
                        .disabled(isActioning)
                        Button(action: { playAlbum(shuffle: true) }) {
                            Label("Shuffle", systemImage: "shuffle")
                        }
                        .disabled(isActioning)
                    }

                    Section {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            Button(action: { playFrom(index: index) }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.body)
                                        .lineLimit(2)
                                    if let artist = track.artist {
                                        Text(artist)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle(albumTitle)
        .task {
            tracks = await PlexWatchClient.shared.getTracks(ratingKey: albumKey)
            isLoading = false
        }
    }

    private func playAlbum(shuffle: Bool) {
        WKInterfaceDevice.current().play(.click)
        isActioning = true
        errorMessage = nil
        Task {
            guard PlexWatchClient.shared.hasCredentials else {
                await MainActor.run { errorMessage = "No server credentials"; isActioning = false }
                return
            }

            guard let result = await PlexWatchClient.shared.createPlayAllQueue(ratingKey: albumKey) else {
                await MainActor.run { errorMessage = "Failed to create play queue"; isActioning = false }
                WKInterfaceDevice.current().play(.failure)
                return
            }

            let client = PlexWatchClient.shared
            let queueItems = await result.toQueueItems(client: client)
            rlog("[PlexWatch] Album play: \(result.items.count) items, \(queueItems.count) playable")

            if queueItems.isEmpty {
                for item in result.items {
                    rlog("[PlexWatch] Item '\(item.title)' partKey=\(item.partKey ?? "nil") type=\(item.type)")
                }
                await MainActor.run { errorMessage = "No playable tracks (\(result.items.count) items had no stream)"; isActioning = false }
                WKInterfaceDevice.current().play(.failure)
                return
            }

            await MainActor.run {
                connectivity.startLocalPlayback()
                WatchAudioPlayer.shared.loadQueue(queueItems)
                if shuffle { WatchAudioPlayer.shared.toggleShuffle() }
                isActioning = false
            }
            RecentlyPlayedManager.shared.record(
                ratingKey: albumKey,
                title: albumTitle,
                type: .album,
                thumb: tracks.first?.thumb
            )
        }
    }

    private func playFrom(index: Int) {
        WKInterfaceDevice.current().play(.click)
        isActioning = true
        errorMessage = nil
        Task {
            guard let result = await PlexWatchClient.shared.createPlayAllQueue(ratingKey: albumKey) else {
                await MainActor.run { errorMessage = "Failed to create play queue"; isActioning = false }
                WKInterfaceDevice.current().play(.failure)
                return
            }

            let client = PlexWatchClient.shared
            let queueItems = await result.toQueueItems(client: client)
            if queueItems.isEmpty {
                await MainActor.run { errorMessage = "No playable tracks"; isActioning = false }
                WKInterfaceDevice.current().play(.failure)
                return
            }

            await MainActor.run {
                connectivity.startLocalPlayback()
                WatchAudioPlayer.shared.loadQueue(queueItems, startIndex: min(index, queueItems.count - 1))
                isActioning = false
            }
        }
    }
}
