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

private func groupedByFirstLetter(_ items: [MusicItem]) -> [(String, [MusicItem])] {
  let grouped = Dictionary(grouping: items) { item -> String in
    let first = item.title.folding(options: .diacriticInsensitive, locale: .current)
      .prefix(1).uppercased()
    if first.isEmpty { return "#" }
    return first.first?.isLetter == true ? String(first) : "#"
  }
  return grouped.sorted { $0.key < $1.key }
}

// MARK: - Artist List (alphabetical sections)

struct ArtistListView: View {
  let sectionId: String
  @State private var artists: [MusicItem] = []
  @State private var isLoading = true
  @EnvironmentObject var connectivity: WatchConnectivityManager

  private var groupedArtists: [(String, [MusicItem])] {
    groupedByFirstLetter(artists)
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
                .contextMenu {
                  Button("Artist Radio") {
                    Task {
                      _ = await MusicPlaybackCoordinator.shared.play(
                        item: artist,
                        style: .radio,
                        connectivity: connectivity
                      )
                    }
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
    isActioning = true
    errorMessage = nil
    Task {
      let error = await MusicPlaybackCoordinator.shared.play(
        item: artist,
        style: .playAll(shuffle: shuffle),
        connectivity: connectivity
      )
      await MainActor.run {
        errorMessage = error
        isActioning = false
      }
    }
  }

  private func startRadio() {
    isActioning = true
    errorMessage = nil
    Task {
      let error = await MusicPlaybackCoordinator.shared.play(
        item: artist,
        style: .radio,
        connectivity: connectivity
      )
      await MainActor.run {
        errorMessage = error
        isActioning = false
      }
    }
  }
}

// MARK: - Album Grid (alphabetical sections)

struct AlbumGridView: View {
  let sectionId: String
  @State private var albums: [MusicItem] = []
  @State private var isLoading = true

  private var groupedAlbums: [(String, [MusicItem])] {
    groupedByFirstLetter(albums)
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
            Button(action: { play(shuffle: false) }) {
              if isActioning {
                ProgressView()
              } else {
                Label("Play", systemImage: "play.fill")
              }
            }
            .disabled(isActioning)
            Button(action: { play(shuffle: true) }) {
              Label("Shuffle", systemImage: "shuffle")
            }
            .disabled(isActioning)
          }

          Section {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
              Button(action: { play(startIndex: index) }) {
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

  private func play(shuffle: Bool = false, startIndex: Int = 0) {
    guard !isActioning else { return }
    isActioning = true
    errorMessage = nil
    Task {
      let error = await MusicPlaybackCoordinator.shared.playPlaylist(
        playlist,
        shuffle: shuffle,
        startIndex: startIndex,
        connectivity: connectivity
      )
      await MainActor.run {
        errorMessage = error
        isActioning = false
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
            Button(action: { startAlbumRadio() }) {
              Label("Album Radio", systemImage: "antenna.radiowaves.left.and.right")
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

  private var albumItem: MusicItem {
    MusicItem(
      ratingKey: albumKey,
      title: albumTitle,
      type: "album",
      artist: tracks.first?.artist,
      album: nil,
      thumb: tracks.first?.thumb,
      duration: nil,
      partKey: nil,
      parentRatingKey: nil,
      grandparentRatingKey: tracks.first?.grandparentRatingKey
    )
  }

  private func playAlbum(shuffle: Bool) {
    isActioning = true
    errorMessage = nil
    Task {
      let error = await MusicPlaybackCoordinator.shared.play(
        item: albumItem,
        style: .playAll(shuffle: shuffle),
        connectivity: connectivity
      )
      await MainActor.run {
        errorMessage = error
        isActioning = false
      }
    }
  }

  private func startAlbumRadio() {
    isActioning = true
    errorMessage = nil
    Task {
      let error = await MusicPlaybackCoordinator.shared.play(
        item: albumItem,
        style: .radio,
        connectivity: connectivity
      )
      await MainActor.run {
        errorMessage = error
        isActioning = false
      }
    }
  }

  private func playFrom(index: Int) {
    isActioning = true
    errorMessage = nil
    Task {
      let error = await MusicPlaybackCoordinator.shared.play(
        item: albumItem,
        style: .singleTrack(index: index),
        connectivity: connectivity
      )
      await MainActor.run {
        errorMessage = error
        isActioning = false
      }
    }
  }
}
