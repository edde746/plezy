import SwiftUI
import WatchKit

// MARK: - Quick action sheet for a music item

struct MusicQuickActionSheet: View {
  let item: MusicItem
  @EnvironmentObject var connectivity: WatchConnectivityManager
  @Environment(\.dismiss) private var dismiss
  @State private var isLoading = false
  @State private var errorMessage: String?

  var body: some View {
    List {
      headerSection

      if let errorMessage {
        Section {
          Text(errorMessage)
            .font(.caption2)
            .foregroundStyle(.red)
        }
      }

      Section {
        if item.isArtist {
          actionRow("Artist Radio", icon: "antenna.radiowaves.left.and.right", tint: .blue) {
            await run(.radio)
          }
          actionRow("Play All", icon: "play.fill") {
            await run(.playAll(shuffle: false))
          }
          actionRow("Shuffle All", icon: "shuffle") {
            await run(.playAll(shuffle: true))
          }
        } else if item.isAlbum {
          actionRow("Play Album", icon: "play.fill") {
            await run(.playAll(shuffle: false))
          }
          actionRow("Shuffle Album", icon: "shuffle") {
            await run(.playAll(shuffle: true))
          }
          actionRow("Album Radio", icon: "antenna.radiowaves.left.and.right", tint: .blue) {
            await run(.radio)
          }
        } else if item.isTrack {
          actionRow("Play Track", icon: "play.fill") {
            await run(.singleTrack())
          }
          actionRow("Track Radio", icon: "antenna.radiowaves.left.and.right", tint: .blue) {
            await run(.radio)
          }
        }
      }

      if item.isArtist {
        Section {
          NavigationLink(destination: ArtistDetailView(artist: item)) {
            Label("Browse Albums", systemImage: "square.stack")
          }
        }
      } else if item.isAlbum {
        Section {
          NavigationLink(destination: TrackListView(albumKey: item.ratingKey, albumTitle: item.title)) {
            Label("Browse Tracks", systemImage: "music.note.list")
          }
        }
      }
    }
    .navigationTitle(item.title)
    .instrumentScreen("MusicQuickActionSheet", detail: { item.title })
  }

  @ViewBuilder
  private var headerSection: some View {
    Section {
      HStack(spacing: 12) {
        CachedThumbnailView(
          urlString: PlexWatchClient.shared.thumbnailUrl(item.thumb),
          size: 52
        )
        .clipShape(item.isArtist ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 6)))

        VStack(alignment: .leading, spacing: 2) {
          Text(item.title)
            .font(.headline)
            .lineLimit(2)
          if let sub = item.subtitle ?? item.artist {
            Text(sub)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
      }
      .listRowBackground(Color.clear)
    }
  }

  private func actionRow(
    _ title: String,
    icon: String,
    tint: Color = .primary,
    action: @escaping () async -> Void
  ) -> some View {
    Button(action: {
      guard !isLoading else { return }
      isLoading = true
      errorMessage = nil
      Task {
        await action()
        await MainActor.run {
          isLoading = false
          if errorMessage == nil { dismiss() }
        }
      }
    }) {
      HStack {
        Label(title, systemImage: icon)
          .foregroundStyle(tint)
        Spacer()
        if isLoading {
          ProgressView()
            .scaleEffect(0.7)
        }
      }
    }
    .disabled(isLoading)
  }

  private func run(_ style: MusicPlaybackCoordinator.PlayStyle) async {
    let error = await MusicPlaybackCoordinator.shared.play(
      item: item,
      style: style,
      connectivity: connectivity
    )
    await MainActor.run { errorMessage = error }
  }
}

// MARK: - Recent artist chip (horizontal home strip)

struct RecentArtistChip: View {
  let item: RecentlyPlayedManager.RecentItem
  var isLoading: Bool = false
  let onRadio: () -> Void
  let onPlayAll: () -> Void

  var body: some View {
    Button(action: onRadio) {
      VStack(spacing: 4) {
        ZStack {
          CachedThumbnailView(
            urlString: PlexWatchClient.shared.thumbnailUrl(item.thumb),
            size: 52
          )
          .clipShape(Circle())
          .overlay(alignment: .bottomTrailing) {
            if !isLoading {
              Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .padding(3)
                .background(Circle().fill(Color.blue))
                .offset(x: 2, y: 2)
            }
          }

          if isLoading {
            Circle()
              .fill(Color.black.opacity(0.45))
              .frame(width: 52, height: 52)
            ProgressView()
              .scaleEffect(0.8)
          }
        }

        Text(item.title)
          .font(.system(size: 10))
          .lineLimit(2)
          .minimumScaleFactor(0.75)
          .multilineTextAlignment(.center)
          .frame(width: 64)
      }
    }
    .buttonStyle(.plain)
    .disabled(isLoading)
    .contextMenu {
      Button(action: onRadio) {
        Label("Artist Radio", systemImage: "antenna.radiowaves.left.and.right")
      }
      Button(action: onPlayAll) {
        Label("Play All", systemImage: "play.fill")
      }
    }
  }
}

// MARK: - Recent item row with play-style hint

struct RecentItemRow: View {
  let item: RecentlyPlayedManager.RecentItem
  var isLoading: Bool = false
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 10) {
        ZStack {
          CachedThumbnailView(
            urlString: PlexWatchClient.shared.thumbnailUrl(item.thumb),
            size: 40
          )
          .clipShape(item.type == .artist ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 4)))
          .opacity(isLoading ? 0.4 : 1)

          if isLoading {
            ProgressView().scaleEffect(0.7)
          }
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(item.title)
            .font(.body)
            .lineLimit(1)
          Text(item.detailLabel)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 0)

        if !isLoading {
          Image(systemName: item.actionIcon)
            .font(.caption)
            .foregroundStyle(.blue)
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(isLoading)
  }
}

// MARK: - Helpers

extension RecentlyPlayedManager.RecentItem {
  var asMusicItem: MusicItem? {
    guard type == .artist else { return nil }
    return MusicItem(ratingKey: ratingKey, title: title, type: "artist", thumb: thumb)
  }

  var detailLabel: String {
    if let subtitle, !subtitle.isEmpty { return subtitle }
    switch playStyle {
    case .artistRadio: return "Artist Radio"
    case .albumRadio: return "Album Radio"
    case .trackRadio: return "Track Radio"
    case .playAll(let shuffle): return shuffle ? "Shuffle" : type.rawValue.capitalized
    }
  }

  var actionIcon: String {
    switch playStyle {
    case .artistRadio, .albumRadio, .trackRadio:
      return "antenna.radiowaves.left.and.right"
    case .playAll(let shuffle):
      return shuffle ? "shuffle" : "play.fill"
    }
  }
}

/// Type-erased shape helper for conditional clip shapes.
struct AnyShape: Shape {
  private let pathBuilder: (CGRect) -> Path

  init<S: Shape>(_ shape: S) {
    pathBuilder = { rect in shape.path(in: rect) }
  }

  func path(in rect: CGRect) -> Path {
    pathBuilder(rect)
  }
}
