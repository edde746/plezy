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

  var body: some View {
    List {
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
        searchResultsSections
      }
    }
    .navigationTitle("Search")
    .instrumentScreen("SearchableView")
    .instrumentState("resultCount", in: "SearchableView", value: results.count)
    .instrumentState("isSearching", in: "SearchableView", value: isSearching)
    .onAppear {
      if !hasAppeared {
        hasAppeared = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          isInputFocused = true
        }
      }
    }
  }

  @ViewBuilder
  private var searchResultsSections: some View {
    let artists = results.filter { $0.isArtist }
    let albums = results.filter { $0.isAlbum }
    let tracks = results.filter { $0.isTrack }

    if !artists.isEmpty {
      Section("Artists") {
        ForEach(artists) { item in
          NavigationLink(destination: MusicQuickActionSheet(item: item)) {
            SearchResultRow(item: item, isCircular: true)
          }
        }
      }
    }

    if !albums.isEmpty {
      Section("Albums") {
        ForEach(albums) { item in
          NavigationLink(destination: MusicQuickActionSheet(item: item)) {
            SearchResultRow(item: item)
          }
        }
      }
    }

    if !tracks.isEmpty {
      Section("Songs") {
        ForEach(tracks) { item in
          NavigationLink(destination: MusicQuickActionSheet(item: item)) {
            SearchResultRow(item: item)
          }
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
}

struct SearchResultRow: View {
  let item: MusicItem
  var isCircular: Bool = false

  var body: some View {
    HStack(spacing: 10) {
      CachedThumbnailView(
        urlString: PlexWatchClient.shared.thumbnailUrl(item.thumb),
        size: 36
      )
      .clipShape(isCircular ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 4)))

      VStack(alignment: .leading, spacing: 2) {
        Text(item.title)
          .font(.body)
          .lineLimit(1)
        if let sub = item.subtitle {
          Text(sub)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
  }
}
